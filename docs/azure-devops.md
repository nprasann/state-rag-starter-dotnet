# Azure DevOps Deployment Guide

This repo includes an Azure DevOps pipeline that can provision Azure infrastructure with Bicep, build the .NET API into an OCI-compatible container image, deploy it to Azure Container Apps, smoke test it, and remove the infrastructure manually or on a schedule.

## Important Cost and Access Note

You can store this code in GitHub or Azure Repos without Azure cloud credits. You only need Azure billing/subscription access when you actually run the deploy or destroy stages against Azure.

For an agency environment, ask for one of these before deployment:

- An agency Azure subscription or sandbox subscription.
- An Azure DevOps service connection with permission to create resource groups and resources.
- Approval for Azure Container Apps, Azure Container Registry, Log Analytics, and Azure SQL Database.
- A secret value for the SQL administrator password stored in Azure DevOps, not in source code.

Your `nprasann` authentication can be used for GitHub/Azure DevOps source control work, but Azure infrastructure deployment requires an Azure subscription where that identity or the service principal has the right role assignments.

## What the Pipeline Creates

The default deployment creates:

| Resource | Purpose |
| --- | --- |
| Resource group | Holds all temporary app resources |
| Azure Container Registry | Stores the built OCI container image |
| Log Analytics workspace | Stores Container Apps logs |
| Azure Container Apps environment | Hosts the container app |
| Azure Container App | Runs the .NET API |
| Azure SQL server and database | Optional database foundation for future persistent storage |

The deployed app still uses the current in-memory code path. Azure SQL is provisioned as a forward-compatible infrastructure piece for the next app update.

## Files

| File | Purpose |
| --- | --- |
| `azure-pipelines.yml` | Azure DevOps pipeline as code |
| `infra/bicep/main.bicep` | Azure infrastructure as code |
| `Containerfile` | OCI-compatible container build file for Podman or Azure Container Registry build |
| `.dockerignore` | Excludes build output and repo-only files from container build context |

## Local Container Test with Podman

Azure Container Apps runs OCI-compatible containers. It does not run Podman as the cloud runtime, but Podman can build and run the same container image locally.

From the repo root:

```bash
podman build -t state-rag-starter-dotnet -f Containerfile .
podman run --rm -p 5000:8080 state-rag-starter-dotnet
```

Then test:

```bash
curl http://localhost:5000/health
```

## Create an Azure DevOps Project

1. Go to Azure DevOps.
2. Create a project, for example `state-rag-starter`.
3. Choose private or public based on agency policy.
4. Use Git as the version control system.

## Store the Code

You have two common options.

### Option A: Keep GitHub as Source

1. In Azure DevOps, go to **Pipelines**.
2. Create a new pipeline.
3. Choose **GitHub**.
4. Select `nprasann/state-rag-starter-dotnet`.
5. Choose **Existing Azure Pipelines YAML file**.
6. Select `/azure-pipelines.yml`.

### Option B: Import into Azure Repos

1. In Azure DevOps, go to **Repos**.
2. Choose **Import repository**.
3. Use the GitHub clone URL:

```text
https://github.com/nprasann/state-rag-starter-dotnet.git
```

4. Create a pipeline from `/azure-pipelines.yml`.

This option is often better when an agency wants all code inside its own Azure DevOps organization.

## Create the Azure Service Connection

1. In Azure DevOps, go to **Project settings**.
2. Open **Service connections**.
3. Create a new **Azure Resource Manager** service connection.
4. Use **Service principal** or **Workload identity federation**, depending on agency policy.
5. Scope it to the approved subscription.
6. Name it:

```text
sc-state-rag-dev
```

If your agency uses a different name, update the pipeline parameter `azureServiceConnection` when running the pipeline.

Minimum permissions depend on agency policy, but the service connection must be able to create and delete the resource group used by this project.

## Create Pipeline Secret Variables

In the Azure DevOps pipeline, add a secret variable:

```text
sqlAdminPassword
```

Use a strong password that meets Azure SQL requirements. Do not commit this value to source control.

The pipeline also uses this non-secret SQL admin login by default:

```text
sqladminuser
```

You can change that in `azure-pipelines.yml` or `infra/bicep/main.bicep`.

## Run a Deployment

Run the pipeline with:

```text
action = deploy
environmentName = dev
workloadName = state-rag
location = eastus
deployDatabase = true
```

The pipeline will:

1. Restore and build the .NET project.
2. Register required Azure providers.
3. Deploy base infrastructure with Bicep.
4. Build the container image in Azure Container Registry using `az acr build`.
5. Re-deploy the Container App with the built image.
6. Smoke test `/health`.

## Destroy Infrastructure Manually

Run the pipeline manually with:

```text
action = destroy
```

The destroy stage deletes the resource group:

```text
rg-state-rag-dev
```

That removes all resources created by this starter deployment.

## Scheduled Cleanup

The pipeline includes a nightly scheduled trigger:

```yaml
schedules:
- cron: '0 3 * * *'
  displayName: Nightly cleanup
```

Azure DevOps schedules use UTC. This cleanup run deletes the environment resource group. If your agency does not want automatic cleanup, remove or comment out the `schedules` block in `azure-pipelines.yml`.

Microsoft notes that scheduled triggers configured in the Azure DevOps UI can override YAML schedules. Keep schedules in one place to avoid surprises.

## Resource Naming

Default names use:

```text
workloadName = state-rag
environmentName = dev
```

The main resource group becomes:

```text
rg-state-rag-dev
```

Most resource names include a deterministic suffix to avoid Azure global naming conflicts.

## Agency Adoption Checklist

- Replace `nprasann` GitHub repo with the agency repo URL.
- Confirm .NET 10 is approved, or retarget the app to the approved .NET version.
- Confirm Azure Container Apps is approved.
- Confirm Azure Container Registry is approved.
- Confirm Azure SQL Database is approved.
- Confirm Log Analytics retention and location requirements.
- Replace public ingress with private networking if required.
- Replace public SQL firewall settings with private endpoint/network rules if required.
- Store all secrets in Azure DevOps secret variables or an approved secret store.
- Decide whether scheduled cleanup is allowed.

## Useful Microsoft References

- [Azure Container Apps quickstart](https://learn.microsoft.com/en-us/azure/container-apps/get-started)
- [Azure Container Apps environments](https://learn.microsoft.com/en-us/azure/container-apps/environment)
- [Azure Pipelines scheduled triggers](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/scheduled-triggers)
- [Azure Container Registry CLI quickstart](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli)
