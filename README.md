# Azure FortiGate Single VM 

## Overview 

* Deploy a single PAYG FortiGate VM in Azure via Terraform with Azure DevOps CI/CD implementation and Terraform
* FortiGate next generation firewall leverages Azure Marketplace image for BYOL/PAYG deployments

## Architecture 

<insert architecture image here>

#### **Deployment overview**

* Azure Virtual Network
* Azure Subnets: 
* Accepts marketplace agreement for Fortinet FortiGate NGFW
  * ***Note: The PAYG license includes the [UTM bundle](https://www.fortinet.com/content/dam/fortinet/assets/data-sheets/FortiGate_VM_Azure.pdf)***
* x1 Single FGT VM with FGT features: (defied in `fgt_iac/fgtvm.conf` )
  * Sets timezone to London GMT
  * Mariner theme
  * Enable protocols on WAN/LAN interfaces: `ping https ssh fgfm`
  * Rest API admin profile
  * Loopback address for redundant BGP IPSec VPN tunnel interfaces
* x2 NICs
  * Primary WAN interface NIC-1
  * LAN interface NIC-2 
 * Azure Monitor resources:
   * VMinsights     


#### **Cost considerations**


## Pre-requisites

####  **Azure DevOps**

* Self-hosted agent with terraform binary installed (**optional** )
* Project: `Deploy-ZimCanIT-UKS-Single-Fortigate`
* AzureRM service connection to Azure Tenant
* Approval environment: `ZimCanIT-Approvers`
* [Variable group](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=azure-pipelines-ui%2Cyaml) named `zimcanit-global-deployment-spn` containing ADO deployment service principal env. variables and remote backend values
  * SPN env. vars: `ARM_CLIENT_ID` > `ARM_CLIENT_SECRET` > `ARM_SUBSCRIPTION_ID` > `ARM_SUBSCRIPTION_ID`
  * TFM state vars: `backend_resource_group_name` > `backend_storage_account_name` > `backend_container_name` > `backend_key`

#### **Terraform**

* Terraform Provider AzureRM >= 4.0.0
* Terraform binary >= 1.10.0

#### **Azure**

* Resource group containing an Azure Key Vault and Storage Account     
* [Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) sercrets:
  * FortiGate vm username: `fgt-vm-uname`
  * FortiGate vm password: `fgt-vm-pwd`
* [Storage account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal) used to store remote terraform state
  * Container: `terraform-state`
* Azure CLI commands for fortinet marketplace agreement
  * BYOL: `az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm --debug`
  * PAYG: `az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm_payg_2023_g2 --debug`
   
## Deployment 

* Update terraform values in `fgt_iac/variables.tf` and `fgt_iac/data.tf`
* Commit changes to this git-repo, this will automattically trigger the ADO pipeline: `Deploy-ZimCanIT-UKS-Single-Fortigate`
* Allow for the Azure DevOps `Terraform Plan`stage to complete and review the proposed deployment plan
* Accept the deployment request
* Review the Azure DevOps `Terraform Apply` stage output
* The terraform pipeline run will accept terms for PAYG/BYOL FGT image via `resource "azurerm_marketplace_agreement" "fortinet_agreement" {}`
* Retrive the authenitcation URL from the terraform output: `fortigate_vm_logon_page`
  * Expected output
```
fgt_ssh_auth = <ssh auth.>
fortigate_deployment_resource_group = <FGT deployment RG>
fortigate_vm_deployment_region = <FGT azure deployment resource>
fortigate_vm_logon_page = <authentication URL for FGT>
generate_restapi_token = <command to deploy a restAPI token>
lan_intf_private_ip = <LAN intf. private IP>
wan_intf_private_ip = <WAN intf. public IP>
```
* Login to FortiGate GUI and let your curiosity take over!
  * IDPS, Web application Firewall, Web filtering, BGP IPsec VPN tunnels, SD-WAN etc
  * Authentication credentials are stored in the key vault resource deployed as part of the pre-requisites

#### **Caveats**

* Delete the public IP resource lock prior to purging all resources in the Azure Portal
* Update the file: `fgt_iac/import.tf` to reference the existing azure marketplace image that is accepted after the first intial success Azure DevOps pipeline run
  * Import additional resources: (optional): FGT public ip and single vm resource group
