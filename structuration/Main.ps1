#. .\Desktop\Formation_powershell\structuration\MesFonctions.ps1

#Get-Salutation -nom "abadi"

if(-not (Get-Module -Name ModuleFonctions)) {
    Import-Module $PSScriptRoot\ModuleFonctions
}
Get-Salutation -nom "abadi"