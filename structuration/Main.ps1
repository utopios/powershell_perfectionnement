#. .\Desktop\Formation_powershell\structuration\MesFonctions.ps1

#Get-Salutation -nom "abadi"

if(-not (Get-Module -Name ModuleFonctions)) {
    Import-Module .\Desktop\Formation_powershell\structuration\ModuleFonctions
}
Get-Salutation -nom "abadi"