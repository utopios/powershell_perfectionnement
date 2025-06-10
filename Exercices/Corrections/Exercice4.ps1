function Manage-UserAccount {
    [CmdletBinding(DefaultParameterSetName = "Create")]
    param(
        [Parameter( Mandatory = $true)]
        [string]$Username,
        [Parameter(ParameterSetName = "Create", Mandatory = $true)]
        [string]$Password,
        [Parameter(ParameterSetName = "Disable", Mandatory = $true)]
        [Switch]$Disable
    )
    
}