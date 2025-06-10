function Get-Salutation() {
    param([string] $nom)
    return Get-Traduction -nom "abadi"
}

class Calculatrice {
    static [int] addition([int]$a, [int]$b) {
        return $a + $b
    }
}

function Get-Traduction() {
    param([string] $nom)
    return "traduction, $($nom) !!"
}

Export-ModuleMember -Function Get-Salutation