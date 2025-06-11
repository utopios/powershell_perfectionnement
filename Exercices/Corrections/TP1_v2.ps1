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



function Copy-FileAdvanced {
    [CmdletBinding(
        DefaultParameterSetName = "Simple",
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateScript({
            foreach ($s in $_) {
                if (-not (Test-Path $s)) {
                    throw "Le fichier source '$s' n'existe pas."
                }
            }
            return $true
        })]
        [string[]]$Source,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateScript({
            $parent = Split-Path $_ -Parent
            if ($parent -and -not (Test-Path $parent)) {
                throw "Le dossier parent de destination '$parent' n'existe pas."
            }
            return $true
        })]
        [string]$Destination,

        # ParameterSet "Simple"
        [Parameter(ParameterSetName = "Simple")]
        [switch]$Overwrite,

        [Parameter(ParameterSetName = "Simple")]
        [switch]$CreateDestination,

        # ParameterSet "Filtered"
        [Parameter(ParameterSetName = "Filtered", Mandatory = $true)]
        [ValidateScript({
            try {
                [regex]::new($_) | Out-Null
                return $true
            }
            catch {
                throw "Le pattern de filtre '$_' n'est pas une expression régulière valide."
            }
        })]
        [string]$Filter,

        [Parameter(ParameterSetName = "Filtered")]
        [string[]]$ExcludePattern,

        [Parameter(ParameterSetName = "Filtered")]
        [ValidateRange(1, 10)]
        [int]$MaxDepth = 5,

        # ParameterSet "Backup"
        [Parameter(ParameterSetName = "Backup", Mandatory = $true)]
        [switch]$BackupExisting,

        [Parameter(ParameterSetName = "Backup")]
        [ValidatePattern('^\.(bak|old|backup|[0-9]{8})$')]
        [string]$BackupSuffix = ".bak",

        [Parameter(ParameterSetName = "Backup")]
        [switch]$CompressBackup,

        # Paramètres communs
        [switch]$Recurse,
        [switch]$PreserveTimestamps
    )

    begin {
        Write-Verbose "Mode de copie: $($PSCmdlet.ParameterSetName)"
        
        # Création du dossier de destination si nécessaire
        if ($CreateDestination -and -not (Test-Path $Destination)) {
            Write-Verbose "Création du dossier de destination: $Destination"
            New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        }
        
        $copiedFiles = @()
        $errors = @()
    }

    process {
        foreach ($sourceItem in $Source) {
            try {
                Write-Verbose "Traitement de: $sourceItem"
                
                # Déterminer si c'est un fichier ou un dossier
                $item = Get-Item $sourceItem
                
                if ($item.PSIsContainer) {
                    # Gestion des dossiers
                    if ($Recurse) {
                        $files = Get-ChildItem -Path $sourceItem -File -Recurse
                    } else {
                        $files = Get-ChildItem -Path $sourceItem -File
                    }
                } else {
                    # Fichier unique
                    $files = @($item)
                }
                
                foreach ($file in $files) {
                    $shouldCopy = $true
                    
                    # Application des filtres selon le ParameterSet
                    switch ($PSCmdlet.ParameterSetName) {
                        "Filtered" {
                            if ($Filter -and $file.Name -notmatch $Filter) {
                                $shouldCopy = $false
                                Write-Verbose "Fichier ignoré par le filtre: $($file.Name)"
                            }
                            
                            if ($ExcludePattern) {
                                foreach ($pattern in $ExcludePattern) {
                                    if ($file.Name -like $pattern) {
                                        $shouldCopy = $false
                                        Write-Verbose "Fichier exclu: $($file.Name)"
                                        break
                                    }
                                }
                            }
                        }
                    }
                    
                    if (-not $shouldCopy) { continue }
                    
                    # Calcul du chemin de destination
                    if ($item.PSIsContainer) {
                        $relativePath = $file.FullName.Substring($sourceItem.Length + 1)
                        $destFile = Join-Path $Destination $relativePath
                    } else {
                        $destFile = Join-Path $Destination $file.Name
                    }
                    
                    # Création du dossier parent si nécessaire
                    $destDir = Split-Path $destFile -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                    }
                    
                    # Gestion de la sauvegarde (ParameterSet Backup)
                    if ($PSCmdlet.ParameterSetName -eq "Backup" -and (Test-Path $destFile)) {
                        $backupFile = "$destFile$BackupSuffix"
                        Write-Verbose "Sauvegarde de $destFile vers $backupFile"
                        
                        if ($PSCmdlet.ShouldProcess($destFile, "Sauvegarder")) {
                            Copy-Item $destFile $backupFile -Force
                            
                            if ($CompressBackup) {
                                Write-Verbose "Compression de la sauvegarde"
                                Compress-Archive -Path $backupFile -DestinationPath "$backupFile.zip" -Force
                                Remove-Item $backupFile -Force
                            }
                        }
                    }
                    
                    # Vérification de l'écrasement
                    if ((Test-Path $destFile) -and -not $Overwrite -and $PSCmdlet.ParameterSetName -ne "Backup") {
                        Write-Warning "Le fichier $destFile existe déjà. Utilisez -Overwrite pour l'écraser."
                        continue
                    }
                    
                    # Copie du fichier
                    if ($PSCmdlet.ShouldProcess($file.FullName, "Copier vers $destFile")) {
                        Copy-Item $file.FullName $destFile -Force
                        
                        # Préservation des timestamps
                        if ($PreserveTimestamps) {
                            $destItem = Get-Item $destFile
                            $destItem.CreationTime = $file.CreationTime
                            $destItem.LastWriteTime = $file.LastWriteTime
                            $destItem.LastAccessTime = $file.LastAccessTime
                        }
                        
                        $copiedFiles += [PSCustomObject]@{
                            Source = $file.FullName
                            Destination = $destFile
                            Size = $file.Length
                            CopyTime = Get-Date
                        }
                        
                        Write-Verbose "Copié: $($file.FullName) -> $destFile"
                    }
                }
            }
            catch {
                $errors += [PSCustomObject]@{
                    Source = $sourceItem
                    Error = $_.Exception.Message
                    Time = Get-Date
                }
                Write-Error "Erreur lors de la copie de $sourceItem : $($_.Exception.Message)"
            }
        }
    }

    end {
        # Rapport final
        Write-Host "`n=== RAPPORT DE COPIE ===" -ForegroundColor Green
        Write-Host "Fichiers copiés: $($copiedFiles.Count)" -ForegroundColor Cyan
        Write-Host "Erreurs: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { "Red" } else { "Green" })
        
        if ($copiedFiles.Count -gt 0) {
            $totalSize = ($copiedFiles | Measure-Object -Property Size -Sum).Sum
            Write-Host "Taille totale: $([math]::Round($totalSize/1MB, 2)) MB" -ForegroundColor Cyan
        }
        
        # Retour des objets copiés
        return $copiedFiles
    }
}

Copy-FileAdvanced -Source .\Exercices -Destination .\ExercicesCopies -Overwrite -Verbose