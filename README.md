# Bicep CI/CD pipeline with GitHub Actions

Deploy an Azure Bicep template from GitHub Actions without storing a client secret. GitHub signs in to Azure with OpenID Connect (OIDC) and a federated credential, deploys to **dev** on every push to `main`, and then deploys to **prod** once dev succeeds and the `prod` environment's rules are met.

This is the companion repo for **Bicep from Scratch, Episode 6** on [cloudwithsingh](https://youtube.com/@cloudwithsingh).

## What it deploys

One template, `main.bicep`, built from four modules:

| Module | Resources |
|---|---|
| `modules/nsg.bicep` | Network security group allowing HTTP and HTTPS |
| `modules/network.bicep` | Virtual network with one subnet per name in `subnetNames`, each attached to the NSG |
| `modules/storage.bicep` | Storage account, plus an optional blob container |
| `modules/webapp.bicep` | Linux App Service plan and web app, with the storage endpoint as an app setting |

`dev.bicepparam` and `prod.bicepparam` deploy the same template with different values. Prod gets geo-redundant storage, a blob container and a fourth subnet.

## How the pipeline works

```text
push to main
  -> deploy-dev   (environment: dev)   sign in with OIDC, what-if, deploy
  -> deploy-prod  (environment: prod)  waits for dev, then what-if and deploy
```

The workflow needs `permissions: id-token: write` so it can request a token from GitHub. Azure checks that token against the federated credentials on the app registration. Nothing in the repo or in GitHub Secrets is a password.

## Get started

1. Fork this repo, or create a new repo from it.
2. Follow [SETUP.md](./SETUP.md) to create the app registration, federated credentials, role assignments, GitHub secrets and environments.
3. Push a commit to `main`, or run **Deploy Bicep** from the **Actions** tab.

## Two errors you'll probably hit

Both show up as `AADSTS700213: No matching federated identity record found`. In both cases, the subject on the federated credential doesn't match the subject GitHub sent.

1. **The subject format.** Repos created after July 15, 2026 send a subject that includes the owner and repo IDs (`repo:owner@123/repo@456:...`). Older repos send names only (`repo:owner/repo:...`). The Azure portal may suggest the format with IDs. Use whichever format your repo actually sends. SETUP.md shows how to check.
2. **The environment subject.** As soon as a job has `environment: dev`, GitHub sends `...:environment:dev` instead of `...:ref:refs/heads/main`. Each environment needs its own federated credential.

## Cost and clean up

The web app runs on a **B1** App Service plan, which costs money while it exists, in each of the two resource groups. Delete everything when you're done:

```bash
az group delete --name rg-bicep-dev --yes --no-wait
az group delete --name rg-bicep-prod --yes --no-wait
```

To keep costs down while experimenting, set `planSku: 'F1'` on the `webapp` module in `main.bicep`.

## Notes

- `azure/arm-deploy@v2` targets Node 20. GitHub now runs it on Node 24 and logs a deprecation warning, but the deployment works.
- `modules/nsg.bicep` contains a commented-out `AllowSSH` rule. Uncomment it and run what-if to see the NSG reported as **Modify**. Don't deploy it as-is, because it opens SSH to the internet.
- The network module defines subnets inline, as shown in the video. For long-lived networks, Microsoft recommends [subnets as child resources](https://learn.microsoft.com/azure/azure-resource-manager/bicep/scenarios-virtual-networks) instead.

## Related

- [Deploy Bicep files with GitHub Actions](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-github-actions) (Microsoft Learn)
- [Workload identity federation](https://learn.microsoft.com/entra/workload-id/workload-identity-federation) (Microsoft Learn)
- [Azure Bicep from Scratch](https://parveensingh.com/azure-bicep-from-scratch), the written series on parveensingh.com
