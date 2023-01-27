# Use Terraform for Azure Deployments
## Setup Az CLI
Run PowerShell as admin:   
```
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
```
In case there is a proxy:   
`(New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials`   

## Setup Choco
`Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))`   
Verify installation with:   
`choco -?`   

## Setup Terraforms
Using Chocolatey:   
`choco install terraform -y`   

## Login & Subs
`az login`
Set specific subscription:   
`az account set --subscription "<subscription_id_or_subscription_name>"`   

## Use Terraform
``` 
terraform init
terraform plan 
terraform apply
```
