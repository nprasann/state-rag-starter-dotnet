targetScope = 'subscription'

@description('Short workload name used in Azure resource names.')
param workloadName string = 'state-rag'

@description('Environment name such as dev, test, or sandbox.')
param environmentName string = 'dev'

@description('Azure region for all resources.')
param location string = 'eastus'

@description('Container image to deploy to Azure Container Apps.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Deploy Azure SQL Database. Set false if the agency does not approve or need database resources yet.')
param deployDatabase bool = true

@description('SQL administrator login. Required when deployDatabase is true.')
param sqlAdminLogin string = 'sqladminuser'

@secure()
@description('SQL administrator password. Store this as a secret variable in Azure DevOps.')
param sqlAdminPassword string

@description('Allow Azure services to access Azure SQL. Agencies may set this to false and replace it with private networking.')
param allowAzureSqlServices bool = true

@description('Minimum number of container replicas.')
param minReplicas int = 0

@description('Maximum number of container replicas.')
param maxReplicas int = 2

@description('Tags applied to Azure resources.')
param tags object = {
  project: 'state-rag-starter-dotnet'
  managedBy: 'azure-devops'
}

var normalizedWorkload = toLower(replace(workloadName, '-', ''))
var normalizedEnvironment = toLower(replace(environmentName, '-', ''))
var suffix = toLower(uniqueString(subscription().id, workloadName, environmentName))
var resourceGroupName = 'rg-${workloadName}-${environmentName}'
var logAnalyticsName = 'log-${workloadName}-${environmentName}-${suffix}'
var containerEnvironmentName = 'cae-${workloadName}-${environmentName}-${suffix}'
var containerAppName = 'ca-${workloadName}-${environmentName}-${suffix}'
var acrName = take('acr${normalizedWorkload}${normalizedEnvironment}${suffix}', 50)
var sqlServerName = 'sql-${workloadName}-${environmentName}-${suffix}'
var sqlDatabaseName = 'sqldb-${workloadName}-${environmentName}'
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  scope: rg
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  scope: rg
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

resource containerEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerEnvironmentName
  scope: rg
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01' = if (deployDatabase) {
  name: sqlServerName
  scope: rg
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01' = if (deployDatabase) {
  name: sqlDatabaseName
  parent: sqlServer
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

resource allowAzureSqlFirewall 'Microsoft.Sql/servers/firewallRules@2023-08-01' = if (deployDatabase && allowAzureSqlServices) {
  name: 'AllowAzureServices'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource containerApp 'Microsoft.App/containerApps@2025-01-01' = {
  name: containerAppName
  scope: rg
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: registry.properties.loginServer
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: containerImage
          env: [
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:8080'
            }
            {
              name: 'StateRag__StorageProvider'
              value: deployDatabase ? 'SqlServer' : 'InMemory'
            }
          ]
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, containerApp.id, acrPullRoleDefinitionId)
  scope: registry
  properties: {
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleDefinitionId
  }
}

output resourceGroupName string = rg.name
output containerRegistryName string = registry.name
output containerRegistryLoginServer string = registry.properties.loginServer
output containerAppName string = containerApp.name
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output sqlServerName string = deployDatabase ? sqlServer.name : ''
output sqlDatabaseName string = deployDatabase ? sqlDatabase.name : ''
