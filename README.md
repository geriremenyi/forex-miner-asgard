# forex-miner-asgard

Infrastructure as a code implementation for forex-miner.com. 

The repo's name is coming from the Norse mythology, in which [Asgard](https://en.wikipedia.org/wiki/Asgard) is a location associated with the gods, that includes Thor, Odin, and Loki.

### Local setup

In the project directory, you can run the following commands:

1. Clone this repo
```bash
# HTTPS
https://github.com/geriremenyi/forex-miner-asgard.git
# SSH
git@github.com:geriremenyi/forex-miner-asgard.git
```

2. Navigate to the root of the project and initialize PowerShell modules and Azure connection. For this run the following command in an __admin__ PowerShell window (PowerShell RunAs Administrator).
```powershell
# Initializing with login popup
./init.ps1
# Initializing with ApplicationId and ApplicationSecret (recommended when using your own Azure subscription)
init.ps1 -ApplicationId "{YourAppId}" -Secret "{YourAppSecret}" -Tenant "{YourAppTenant}"
```

For all PowerShell commands (including the module initializer) you can get the available parameters via:
```powershell
Get-Help .\init.ps1 # Or any other script
```

### Run

To run the whole cluster deployment.

1. Create the resource grou to deploy to. Note that the script defaults to the SubscriptionId which is used for the actual deployment of the resources behind [forex-miner.com](https://forex-miner.com) which you don't have access to. It is recommened to deploy everything to your Azure subscription. This is an idempotent script so if you alredy have the resource group in place it will leave as is.
```bash
New-AzureResourceGroup -Subscription "{YourSubscriptionId}"
# For all available parameters
Get-Help New-AzureResourceGroup
```

2. Run the actual deployment of the ARM templates
```powershell
New-ArmTemplateDeployment -Subscription "{YourSubscriptionId}"
# For all available parameters
Get-Help New-ArmTemplateDeployment
```

3. Add the created AKS cluster's managed identity as the owner of the resource group craeted at step 1. This makes sure that the AKS cluster can access resources within the resource group with managed identity
```powershell
Add-MSIToResourceGroup -Subscription "{YourSubscriptionId}"
# For all available parameters
Get-Help Add-MSIToResourceGroup
```

4. Initialize namespaces, routing, SSL certificate handlers etc. on the cluster.
```powershell
Invoke-AKSInitialization -Subscription "{YourSubscriptionId}"
# For all available parameters
Get-Help Invoke-AKSInitialization
```

## Deployment

This chapter guides you through the CI/CD setup and the deployment steps for the infrastructure.

### GitHub Actions

There are continuous integration and deployment steps setup as GitHub actions to be able to test on every pull-request and to be able to deliver the infra fast.

#### Continuous integration

All pull request opened against any branches triggers a continuous integration workflow to run.

The steps are defined in the [`continuous_integration.yaml` file](.github/workflows/continuous_integration.yaml).

Recently ran integrations can be found [here](https://github.com/geriremenyi/forex-miner-asgard/actions?query=workflow%3A"Continuous+Integration").

#### Continuous deployment

All changes on the [master branch](https://github.com/geriremenyi/forex-miner-asgard/tree/master) triggers a deployment which actually creates the cluster in the target subscription's resource group. ARM remplate deployment in theory idempotent action and all steps which were not idempotent were made that way via wrapper scripts. This should make sure that any change in the infra code will trigger a gradual update if possible.

The steps are defined in the [`continuous_deployment.yaml` file](.github/workflows/continuous_deployment.yaml).

Recently ran deployments can be found [here](https://github.com/geriremenyi/forex-miner-asgard/actions?query=workflow%3A"Continuous+Deployment").