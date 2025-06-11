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


function Remove-FilesByRule {
    [CmdletBinding(
        DefaultParameterSetName = "ByAge",
        SupportsShouldProcess = $true,
        ConfirmImpact = "High"
    )]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateScript({
            foreach ($p in $_) {
                if (-not (Test-Path $p)) {
                    throw "Le chemin '$p' n'existe pas."
                }
            }
            return $true
        })]
        [string[]]$Path,

        # ParameterSet "ByAge"
        [Parameter(ParameterSetName = "ByAge")]
        [ValidateScript({
            if ($_.TotalDays -le 0) {
                throw "OlderThan doit être une durée positive."
            }
            return $true
        })]
        [timespan]$OlderThan,

        [Parameter(ParameterSetName = "ByAge")]
        [ValidateScript({
            if ($_.TotalDays -le 0) {
                throw "NewerThan doit être une durée positive."
            }
            if ($OlderThan -and $_ -ge $OlderThan) {
                throw "NewerThan doit être inférieur à OlderThan."
            }
            return $true
        })]
        [timespan]$NewerThan,

        # ParameterSet "ByPattern"
        [Parameter(ParameterSetName = "ByPattern", Mandatory = $true)]
        [ValidateScript({
            try {
                [regex]::new($_) | Out-Null
                return $true
            }
            catch {
                throw "NamePattern '$_' n'est pas une expression régulière valide."
            }
        })]
        [string]$NamePattern,

        [Parameter(ParameterSetName = "ByPattern")]
        [ValidateScript({
            try {
                [regex]::new($_) | Out-Null
                return $true
            }
            catch {
                throw "ContentPattern '$_' n'est pas une expression régulière valide."
            }
        })]
        [string]$ContentPattern,

        # ParameterSet "BySize"
        [Parameter(ParameterSetName = "BySize")]
        [switch]$EmptyFiles,

        [Parameter(ParameterSetName = "BySize")]
        [ValidatePattern('^\d+[KMGT]?B$')]
        [string]$LargerThan,

        [Parameter(ParameterSetName = "BySize")]
        [ValidatePattern('^\d+[KMGT]?B$')]
        [string]$SmallerThan,

        # Paramètres communs
        [switch]$Recurse,
        [switch]$Force,
        [switch]$LogActions
    )

    begin {
        Write-Verbose "Mode de suppression: $($PSCmdlet.ParameterSetName)"
        
        # Fonction pour convertir les tailles
        function ConvertTo-Bytes {
            param([string]$SizeString)
            
            if ($SizeString -match '^(\d+)([KMGT]?)B$') {
                $number = [long]$matches[1]
                $unit = $matches[2]
                
                switch ($unit) {
                    'K' { return $number * 1KB }
                    'M' { return $number * 1MB }
                    'G' { return $number * 1GB }
                    'T' { return $number * 1TB }
                    default { return $number }
                }
            }
            return 0
        }
        
        # Conversion des tailles si nécessaire
        $largerThanBytes = if ($LargerThan) { ConvertTo-Bytes $LargerThan } else { 0 }
        $smallerThanBytes = if ($SmallerThan) { ConvertTo-Bytes $SmallerThan } else { [long]::MaxValue }
        
        $deletedFiles = @()
        $errors = @()
        $logFile = if ($LogActions) { Join-Path $env:TEMP "Remove-FilesByRule_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" }
        
        if ($LogActions) {
            "=== DÉBUT DE LA SUPPRESSION - $(Get-Date) ===" | Out-File $logFile
            Write-Verbose "Log des actions: $logFile"
        }
    }

    process {
        foreach ($currentPath in $Path) {
            Write-Verbose "Analyse du chemin: $currentPath"
            
            try {
                # Récupération des fichiers
                $getChildItemParams = @{
                    Path = $currentPath
                    File = $true
                    Force = $Force
                }
                
                if ($Recurse) {
                    $getChildItemParams.Recurse = $true
                }
                
                $files = Get-ChildItem @getChildItemParams
                Write-Verbose "Trouvé $($files.Count) fichier(s) à analyser"
                
                foreach ($file in $files) {
                    $shouldDelete = $false
                    $reason = ""
                    
                    # Application des règles selon le ParameterSet
                    switch ($PSCmdlet.ParameterSetName) {
                        "ByAge" {
                            $age = (Get-Date) - $file.LastWriteTime
                            
                            if ($OlderThan -and $age -gt $OlderThan) {
                                $shouldDelete = $true
                                $reason = "Plus ancien que $($OlderThan.Days) jour(s)"
                            }
                            elseif ($NewerThan -and $age -lt $NewerThan) {
                                $shouldDelete = $true
                                $reason = "Plus récent que $($NewerThan.Days) jour(s)"
                            }
                        }
                        
                        "ByPattern" {
                            if ($NamePattern -and $file.Name -match $NamePattern) {
                                $shouldDelete = $true
                                $reason = "Nom correspond au pattern: $NamePattern"
                            }
                            
                            if ($ContentPattern -and $file.Extension -in @('.txt', '.log', '.csv', '.json', '.xml')) {
                                try {
                                    $content = Get-Content $file.FullName -Raw -ErrorAction Stop
                                    if ($content -match $ContentPattern) {
                                        $shouldDelete = $true
                                        $reason += " / Contenu correspond au pattern: $ContentPattern"
                                    }
                                }
                                catch {
                                    Write-Verbose "Impossible de lire le contenu de: $($file.FullName)"
                                }
                            }
                        }
                        
                        "BySize" {
                            if ($EmptyFiles -and $file.Length -eq 0) {
                                $shouldDelete = $true
                                $reason = "Fichier vide"
                            }
                            elseif ($file.Length -gt $largerThanBytes) {
                                $shouldDelete = $true
                                $reason = "Taille supérieure à $LargerThan"
                            }
                            elseif ($file.Length -lt $smallerThanBytes) {
                                $shouldDelete = $true
                                $reason = "Taille inférieure à $SmallerThan"
                            }
                        }
                    }
                    
                    if ($shouldDelete) {
                        $fileInfo = [PSCustomObject]@{
                            FullName = $file.FullName
                            Name = $file.Name
                            Size = $file.Length
                            LastWriteTime = $file.LastWriteTime
                            Reason = $reason
                            DeleteTime = Get-Date
                        }
                        
                        if ($PSCmdlet.ShouldProcess($file.FullName, "Supprimer le fichier ($reason)")) {
                            try {
                                Remove-Item $file.FullName -Force
                                $deletedFiles += $fileInfo
                                Write-Verbose "Supprimé: $($file.FullName) - $reason"
                                
                                if ($LogActions) {
                                    "SUPPRIMÉ: $($file.FullName) - $reason - $(Get-Date)" | Out-File $logFile -Append
                                }
                            }
                            catch {
                                $errors += [PSCustomObject]@{
                                    File = $file.FullName
                                    Error = $_.Exception.Message
                                    Time = Get-Date
                                }
                                $errors += $error
                                Write-Error "Erreur lors de la suppression de $($file.FullName): $($_.Exception.Message)"
                                
                                if ($LogActions) {
                                    "ERREUR: $($file.FullName) - $($_.Exception.Message) - $(Get-Date)" | Out-File $logFile -Append
                                }
                            }
                        }
                    }
                }
            }
            catch {
                Write-Error "Erreur lors de l'analyse de $currentPath : $($_.Exception.Message)"
            }
        }
    }

    end {
        if ($LogActions) {
            "=== FIN DE LA SUPPRESSION - $(Get-Date) ===" | Out-File $logFile -Append
            "Fichiers supprimés: $($deletedFiles.Count)" | Out-File $logFile -Append
            "Erreurs: $($errors.Count)" | Out-File $logFile -Append
        }
        
        # Rapport final
        Write-Host "`n=== RAPPORT DE SUPPRESSION ===" -ForegroundColor Red
        Write-Host "Fichiers supprimés: $($deletedFiles.Count)" -ForegroundColor Yellow
        Write-Host "Erreurs: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { "Red" } else { "Green" })
        
        if ($deletedFiles.Count -gt 0) {
            $totalSize = ($deletedFiles | Measure-Object -Property Size -Sum).Sum
            Write-Host "Espace libéré: $([math]::Round($totalSize/1MB, 2)) MB" -ForegroundColor Green
        }
        
        if ($LogActions) {
            Write-Host "Log disponible: $logFile" -ForegroundColor Cyan
        }
        
        return $deletedFiles
    }
}

Copy-FileAdvanced -Source .\Exercices -Destination .\ExercicesCopies -Overwrite -Verbose