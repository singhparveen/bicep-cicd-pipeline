# Setup: federated credentials, no secrets

These steps connect this repo to Azure so the workflow in `.github/workflows/deploy.yml` can deploy without storing a client secret. Every step is an Azure CLI or GitHub CLI command. The video does the same thing in the Azure portal.

You need:

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), signed in with `az login`
- [GitHub CLI](https://cli.github.com), signed in with `gh auth login`
- Your own copy of this repo (fork it, or create a new repo from it)

## 0. Set your values

```bash
GITHUB_OWNER="your-github-username"
GITHUB_REPO="bicep-cicd-pipeline"
APP_NAME="github-bicep-deploy"
LOCATION="canadacentral"
DEV_RG="rg-bicep-dev"
PROD_RG="rg-bicep-prod"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
```

If you change `DEV_RG` or `PROD_RG`, change the same names at the top of `deploy.yml`.

## 1. Resource groups

```bash
az group create --name "$DEV_RG" --location "$LOCATION"
az group create --name "$PROD_RG" --location "$LOCATION"
```

## 2. App registration and service principal

```bash
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
az ad sp create --id "$APP_ID"
```

## 3. Federated credentials

A federated credential tells Entra ID which GitHub workflows it should trust. The `subject` has to match the token GitHub sends **exactly**, character for character.

Check the subject prefix your repo uses:

```bash
SUB_PREFIX=$(gh api "repos/$GITHUB_OWNER/$GITHUB_REPO/actions/oidc/customization/sub" --jq .sub_claim_prefix)
echo "$SUB_PREFIX"
```

- Repos created before July 15, 2026 print the name-only format, for example `repo:singhparveen/bicep-cicd-pipeline`.
- Repos created after that date, and repos you've opted in, print the immutable format with IDs, for example `repo:singhparveen@42755757/bicep-cicd-pipeline@1282665726`.

Both jobs in the workflow use an environment, so GitHub sends an **environment** subject, not a branch subject. Create one credential per environment:

```bash
for ENV in dev prod; do
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"github-env-$ENV\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"${SUB_PREFIX}:environment:$ENV\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
done
```

If a login step fails with `AADSTS700213` (no matching federated identity record), open the failed run's log. The error message shows the subject GitHub actually sent. Compare it with the credential's subject and fix the difference.

## 4. Give the app access to both resource groups

```bash
for RG in "$DEV_RG" "$PROD_RG"; do
  az role assignment create \
    --assignee "$APP_ID" \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG"
done
```

The role is scoped to the two resource groups, not the whole subscription.

## 5. GitHub secrets

```bash
gh secret set AZURE_CLIENT_ID --repo "$GITHUB_OWNER/$GITHUB_REPO" --body "$APP_ID"
gh secret set AZURE_TENANT_ID --repo "$GITHUB_OWNER/$GITHUB_REPO" --body "$TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID --repo "$GITHUB_OWNER/$GITHUB_REPO" --body "$SUBSCRIPTION_ID"
```

These are identifiers, not passwords. There is no client secret anywhere in this setup.

## 6. Environments

Create `dev`, and create `prod` so it only accepts deployments from protected branches:

```bash
gh api -X PUT "repos/$GITHUB_OWNER/$GITHUB_REPO/environments/dev"

gh api -X PUT "repos/$GITHUB_OWNER/$GITHUB_REPO/environments/prod" --input - <<EOF
{
  "deployment_branch_policy": { "protected_branches": true, "custom_branch_policies": false }
}
EOF
```

Then protect `main` in **Settings > Branches** (for example, require a pull request before merging).

To make production wait for a person to approve it, add yourself as a required reviewer on `prod`:

```bash
REVIEWER_ID=$(gh api user --jq .id)
gh api -X PUT "repos/$GITHUB_OWNER/$GITHUB_REPO/environments/prod" --input - <<EOF
{
  "reviewers": [ { "type": "User", "id": $REVIEWER_ID } ],
  "deployment_branch_policy": { "protected_branches": true, "custom_branch_policies": false }
}
EOF
```

Required reviewers are available on public repositories on every GitHub plan. On private repositories on the Free, Pro or Team plans, they aren't available.

## 7. Run it

Push a commit to `main`, or run the workflow from the **Actions** tab. `deploy-dev` runs first. `deploy-prod` starts after dev succeeds, once the `prod` environment's rules are met.

## Clean up

```bash
az group delete --name "$DEV_RG" --yes --no-wait
az group delete --name "$PROD_RG" --yes --no-wait
az ad app delete --id "$APP_ID"
```
