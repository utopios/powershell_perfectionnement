function Find-FileAdvanced {
    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param(
        # Paramètre commun - Chemin de recherche
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateScript({
            foreach ($p in $_) {
                if (-not (Test-Path $p)) {
                    throw "Le chemin '$p' n'existe pas ou n'est pas accessible."
                }
            }
            return $true
        })]
        [string[]]$Path,

        # ParameterSet "ByName" - Recherche par nom/extension
        [Parameter(ParameterSetName = "ByName")]
        [string]$Name,

        [Parameter(ParameterSetName = "ByName")]
        [ValidateScript({
            foreach ($ext in $_) {
                if ($ext -notmatch '^\.[a-zA-Z0-9]+$') {
                    throw "L'extension '$ext' doit être au format '.ext' (ex: .txt, .pdf)"
                }
            }
            return $true
        })]
        [string[]]$Extension,

        [Parameter(ParameterSetName = "ByName")]
        [switch]$Recurse,

        # ParameterSet "BySize" - Recherche par taille
        [Parameter(ParameterSetName = "BySize", Mandatory = $true)]
        [ValidateRange(0, [long]::MaxValue)]
        [long]$MinSize,

        [Parameter(ParameterSetName = "BySize")]
        [ValidateScript({
            if ($_ -le $MinSize) {
                throw "MaxSize ($_) doit être supérieur à MinSize ($MinSize)"
            }
            return $true
        })]
        [long]$MaxSize,

        [Parameter(ParameterSetName = "BySize")]
        [ValidateSet("B", "KB", "MB", "GB")]
        [string]$SizeUnit = "B",

        # ParameterSet "ByDate" - Recherche par dates
        [Parameter(ParameterSetName = "ByDate")]
        [datetime]$CreatedAfter,

        [Parameter(ParameterSetName = "ByDate")]
        [ValidateScript({
            if ($CreatedAfter -and $_ -le $CreatedAfter) {
                throw "CreatedBefore doit être postérieur à CreatedAfter"
            }
            return $true
        })]
        [datetime]$CreatedBefore,

        [Parameter(ParameterSetName = "ByDate")]
        [datetime]$ModifiedAfter,

        [Parameter(ParameterSetName = "ByDate")]
        [ValidateScript({
            if ($ModifiedAfter -and $_ -le $ModifiedAfter) {
                throw "ModifiedBefore doit être postérieur à ModifiedAfter"
            }
            return $true
        })]
        [datetime]$ModifiedBefore,

        # Paramètres communs
        [string[]]$Include,
        [string[]]$Exclude,
        [switch]$Hidden
    )

    begin {
        Write-Verbose "Début de la recherche avec le ParameterSet: $($PSCmdlet.ParameterSetName)"
        
        # Conversion des unités de taille
        $sizeMultiplier = switch ($SizeUnit) {
            "B" { 1 }
            "KB" { 1024 }
            "MB" { 1024 * 1024 }
            "GB" { 1024 * 1024 * 1024 }
            default { 1 }
        }
        
        if ($PSBoundParameters.ContainsKey('MinSize')) {
            $MinSize = $MinSize * $sizeMultiplier
        }
        if ($PSBoundParameters.ContainsKey('MaxSize')) {
            $MaxSize = $MaxSize * $sizeMultiplier
        }
    }

    process {
        foreach ($currentPath in $Path) {
            Write-Verbose "Recherche dans: $currentPath"
            
            # Paramètres de base pour Get-ChildItem
            $getChildItemParams = @{
                Path = $currentPath
                File = $true
                Force = $Hidden
            }
            
            if ($Recurse) {
                $getChildItemParams.Recurse = $true
            }
            
            # Récupération des fichiers
            $files = Get-ChildItem @getChildItemParams
            
            # Application des filtres selon le ParameterSet
            switch ($PSCmdlet.ParameterSetName) {
                "ByName" {
                    if ($Name) {
                        $files = $files | Where-Object { $_.Name -like "*$Name*" }
                    }
                    if ($Extension) {
                        $files = $files | Where-Object { $_.Extension -in $Extension }
                    }
                }
                
                "BySize" {
                    $files = $files | Where-Object { 
                        $_.Length -ge $MinSize -and 
                        ($MaxSize -eq 0 -or $_.Length -le $MaxSize)
                    }
                }
                
                "ByDate" {
                    if ($CreatedAfter) {
                        $files = $files | Where-Object { $_.CreationTime -gt $CreatedAfter }
                    }
                    if ($CreatedBefore) {
                        $files = $files | Where-Object { $_.CreationTime -lt $CreatedBefore }
                    }
                    if ($ModifiedAfter) {
                        $files = $files | Where-Object { $_.LastWriteTime -gt $ModifiedAfter }
                    }
                    if ($ModifiedBefore) {
                        $files = $files | Where-Object { $_.LastWriteTime -lt $ModifiedBefore }
                    }
                }
            }
            
            # Application des filtres Include/Exclude
            if ($Include) {
                $files = $files | Where-Object { 
                    $fileName = $_.Name
                    ($Include | ForEach-Object { $fileName -like $_ }) -contains $true
                }
            }
            
            if ($Exclude) {
                $files = $files | Where-Object { 
                    $fileName = $_.Name
                    ($Exclude | ForEach-Object { $fileName -like $_ }) -notcontains $true
                }
            }
            
            Write-Verbose "Trouvé $($files.Count) fichier(s) correspondant aux critères"
            $files
        }
    }
}