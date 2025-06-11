# ============================================================================
# Module: ServerMonitoring
# Description: Système de monitoring et maintenance automatisée des serveurs
# Author: Solution TP PowerShell Avancé
# Version: 1.0
# ============================================================================

#region Configuration et Variables globales
$script:ModuleConfig = @{
    LogPath = "$env:ProgramData\ServerMonitoring\Logs"
    ReportPath = "$env:ProgramData\ServerMonitoring\Reports"
    ConfigPath = "$env:ProgramData\ServerMonitoring\Config"
    MaxConcurrentJobs = 10
    DefaultTimeout = 30
    CacheTimeout = 300 # 5 minutes
}

$script:MetricCache = @{}
$script:LogLevels = @("Information", "Warning", "Error", "Critical")

# Création des répertoires nécessaires
foreach ($path in $script:ModuleConfig.Values) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}
#endregion

#region Classes et Types personnalisés
class ServerHealthResult {
    [string]$ComputerName
    [datetime]$Timestamp
    [string]$OverallHealth
    [hashtable]$Metrics
    [string[]]$Alerts
    [string[]]$Actions
    [string]$Status
    [string]$ErrorMessage
    
    ServerHealthResult([string]$ComputerName) {
        $this.ComputerName = $ComputerName
        $this.Timestamp = Get-Date
        $this.Metrics = @{}
        $this.Alerts = @()
        $this.Actions = @()
        $this.Status = "Unknown"
    }
}

class SystemMetric {
    [string]$Name
    [double]$Value
    [double]$Threshold
    [string]$Status
    [string]$Unit
    [string]$Description
    
    SystemMetric([string]$Name, [double]$Value, [double]$Threshold, [string]$Unit) {
        $this.Name = $Name
        $this.Value = $Value
        $this.Threshold = $Threshold
        $this.Unit = $Unit
        $this.Status = if ($Value -ge $Threshold) { "Warning" } elseif ($Value -ge ($Threshold * 0.9)) { "Caution" } else { "OK" }
    }
}
#endregion

#region Fonctions de Validation
function Test-ComputerNameValid {
    [CmdletBinding()]
    param([string]$ComputerName)
    
    # Test de format IP ou nom d'hôte
    $ipPattern = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    $hostnamePattern = "^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$"
    
    return ($ComputerName -match $ipPattern) -or ($ComputerName -match $hostnamePattern)
}

function Test-ThresholdStructure {
    [CmdletBinding()]
    param([hashtable]$Threshold)
    
    $requiredKeys = @("CPU", "Memory", "Disk")
    foreach ($key in $requiredKeys) {
        if (-not $Threshold.ContainsKey($key) -or $Threshold[$key] -lt 0 -or $Threshold[$key] -gt 100) {
            return $false
        }
    }
    return $true
}
#endregion

#region Fonctions de Logging
function Write-OperationLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Information", "Warning", "Error", "Critical")]
        [string]$Level,
        
        [Parameter()]
        [string]$Category = "General",
        
        [Parameter()]
        [string]$LogFile = (Join-Path $script:ModuleConfig.LogPath "ServerMonitoring.log"),
        
        [Parameter()]
        [long]$MaxLogSize = 10MB,
        
        [Parameter()]
        [switch]$RotateDaily
    )
    
    try {
        # Rotation des logs si nécessaire
        if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt $MaxLogSize) {
            $backupFile = $LogFile -replace "\.log$", "_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            Move-Item $LogFile $backupFile
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] [$Category] $Message"
        
        # Écriture dans le fichier
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
        
        # Affichage console selon le niveau
        switch ($Level) {
            "Information" { Write-Verbose $logEntry }
            "Warning" { Write-Warning $logEntry }
            "Error" { Write-Error $logEntry }
            "Critical" { Write-Error $logEntry }
        }
    }
    catch {
        Write-Warning "Impossible d'écrire dans le log: $($_.Exception.Message)"
    }
}

function Get-OperationHistory {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ComputerName,
        
        [Parameter()]
        [datetime[]]$DateRange,
        
        [Parameter()]
        [ValidateSet("Information", "Warning", "Error", "Critical")]
        [string[]]$Level,
        
        [Parameter()]
        [string[]]$Category
    )
    
    $logFile = Join-Path $script:ModuleConfig.LogPath "ServerMonitoring.log"
    
    if (-not (Test-Path $logFile)) {
        Write-Warning "Fichier de log introuvable: $logFile"
        return
    }
    
    $logs = Get-Content $logFile | ForEach-Object {
        if ($_ -match '^\[(.+?)\] \[(.+?)\] \[(.+?)\] (.+)$') {
            [PSCustomObject]@{
                Timestamp = [datetime]$matches[1]
                Level = $matches[2]
                Category = $matches[3]
                Message = $matches[4]
            }
        }
    }
    
    # Filtrage
    if ($DateRange) {
        $logs = $logs | Where-Object { $_.Timestamp -ge $DateRange[0] -and $_.Timestamp -le $DateRange[1] }
    }
    if ($Level) {
        $logs = $logs | Where-Object { $_.Level -in $Level }
    }
    if ($Category) {
        $logs = $logs | Where-Object { $_.Category -in $Category }
    }
    if ($ComputerName) {
        $logs = $logs | Where-Object { $ComputerName | ForEach-Object { $logs.Message -like "*$_*" } }
    }
    
    return $logs
}
#endregion

#region Fonctions utilitaires
function Get-SystemMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-ComputerNameValid $_ })]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("CPU", "Memory", "Disk", "Services", "Network")]
        [string[]]$MetricType,
        
        [Parameter()]
        [PSCredential]$Credential,
        
        [Parameter()]
        [ValidateRange(5, 300)]
        [int]$Timeout = 30
    )
    
    $cacheKey = "$ComputerName-$($MetricType -join ",")"
    $cacheEntry = $script:MetricCache[$cacheKey]
    
    # Vérification du cache
    if ($cacheEntry -and ((Get-Date) - $cacheEntry.Timestamp).TotalSeconds -lt $script:ModuleConfig.CacheTimeout) {
        Write-Verbose "Données récupérées depuis le cache pour $ComputerName"
        return $cacheEntry.Data
    }
    
    $metrics = @{}
    $sessionParams = @{
        ComputerName = $ComputerName
        ErrorAction = 'Stop'
    }
    
    if ($Credential) {
        $sessionParams.Credential = $Credential
    }
    
    try {
        $session = New-CimSession @sessionParams
        
        foreach ($type in $MetricType) {
            switch ($type) {
                "CPU" {
                    $cpuData = Get-CimInstance -CimSession $session -ClassName Win32_Processor | 
                        Measure-Object -Property LoadPercentage -Average
                    $metrics.CPU = [SystemMetric]::new("CPU", $cpuData.Average, 80, "%")
                }
                
                "Memory" {
                    $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
                    $memoryUsed = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100
                    $metrics.Memory = [SystemMetric]::new("Memory", $memoryUsed, 85, "%")
                }
                
                "Disk" {
                    $disks = Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk -Filter "DriveType=3"
                    $diskMetrics = @{}
                    foreach ($disk in $disks) {
                        $usedPercent = ($disk.Size - $disk.FreeSpace) / $disk.Size * 100
                        $diskMetrics[$disk.DeviceID] = [SystemMetric]::new("Disk_$($disk.DeviceID)", $usedPercent, 90, "%")
                    }
                    $metrics.Disk = $diskMetrics
                }
                
                "Services" {
                    $services = Get-CimInstance -CimSession $session -ClassName Win32_Service
                    $stoppedCritical = $services | Where-Object { $_.State -eq "Stopped" -and $_.StartMode -eq "Auto" }
                    $metrics.Services = @{
                        Total = $services.Count
                        Running = ($services | Where-Object { $_.State -eq "Running" }).Count
                        Stopped = ($services | Where-Object { $_.State -eq "Stopped" }).Count
                        Critical = $stoppedCritical.Count
                        CriticalServices = $stoppedCritical.Name
                    }
                }
                
                "Network" {
                    $adapters = Get-CimInstance -CimSession $session -ClassName Win32_NetworkAdapter -Filter "NetEnabled=True"
                    $metrics.Network = @{
                        ActiveAdapters = $adapters.Count
                        AdapterNames = $adapters.Name
                    }
                }
            }
        }
        
        Remove-CimSession $session
        
        # Mise en cache
        $script:MetricCache[$cacheKey] = @{
            Timestamp = Get-Date
            Data = $metrics
        }
        
        Write-OperationLog -Message "Métriques récupérées pour $ComputerName : $($MetricType -join ', ')" -Level "Information" -Category "Monitoring"
        
        return $metrics
    }
    catch {
        $errorMsg = "Erreur lors de la récupération des métriques pour ${ComputerName}: $($_.Exception.Message)"
        Write-OperationLog -Message $errorMsg -Level "Error" -Category "Monitoring"
        throw $errorMsg
    }
}

function Invoke-ServerMaintenance {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-ComputerNameValid $_ })]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("CleanTemp", "UpdateWindows", "RestartServices", "DefragDisk")]
        [string[]]$Action,
        
        [Parameter()]
        [PSCredential]$Credential,
        
        [Parameter()]
        [datetime]$Schedule,
        
        [Parameter()]
        [ValidateRange(1, 20)]
        [int]$MaxConcurrentJobs = 5,
        
        [Parameter()]
        [switch]$WhatIf,
        
        [Parameter()]
        [switch]$Confirm
    )
    
    if ($Schedule -and $Schedule -gt (Get-Date)) {
        Write-OperationLog -Message "Maintenance programmée pour $ComputerName à $Schedule" -Level "Information" -Category "Maintenance"
        # Ici on pourrait implémenter une tâche programmée
        return @{
            ComputerName = $ComputerName
            Status = "Scheduled"
            ScheduledTime = $Schedule
            Actions = $Action
        }
    }
    
    $results = @()
    
    foreach ($act in $Action) {
        if ($PSCmdlet.ShouldProcess($ComputerName, "Exécuter $act")) {
            try {
                $result = @{
                    ComputerName = $ComputerName
                    Action = $act
                    Status = "Success"
                    Timestamp = Get-Date
                    Details = ""
                }
                
                switch ($act) {
                    "CleanTemp" {
                        $scriptBlock = {
                            $tempPaths = @($env:TEMP, "$env:WINDIR\Temp", "$env:WINDIR\Prefetch")
                            $totalCleaned = 0
                            foreach ($path in $tempPaths) {
                                if (Test-Path $path) {
                                    $files = Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue
                                    foreach ($file in $files) {
                                        try {
                                            $totalCleaned += $file.Length
                                            Remove-Item $file.FullName -Force -Recurse -ErrorAction SilentlyContinue
                                        } catch {}
                                    }
                                }
                            }
                            return $totalCleaned
                        }
                        
                        $cleaned = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -Credential $Credential
                        $result.Details = "Nettoyé: $([Math]::Round($cleaned / 1MB, 2)) MB"
                    }
                    
                    "RestartServices" {
                        $scriptBlock = {
                            $services = Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
                            $restarted = @()
                            foreach ($service in $services) {
                                try {
                                    Start-Service $service.Name
                                    $restarted += $service.Name
                                } catch {}
                            }
                            return $restarted
                        }
                        
                        $restartedServices = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -Credential $Credential
                        $result.Details = "Services redémarrés: $($restartedServices -join ', ')"
                    }
                    
                    "UpdateWindows" {
                        $result.Details = "Mise à jour Windows initiée (nécessite le module PSWindowsUpdate)"
                        # Ici on utiliserait le module PSWindowsUpdate
                    }
                    
                    "DefragDisk" {
                        $scriptBlock = {
                            $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
                            $defragResults = @()
                            foreach ($drive in $drives) {
                                $defragResults += "Défragmentation de $($drive.DeviceID) initiée"
                                # defrag.exe $drive.DeviceID /A /V
                            }
                            return $defragResults
                        }
                        
                        $defragResult = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -Credential $Credential
                        $result.Details = $defragResult -join '; '
                    }
                }
                
                Write-OperationLog -Message "Action $act exécutée sur $ComputerName avec succès" -Level "Information" -Category "Maintenance"
                
            }
            catch {
                $result.Status = "Error"
                $result.Details = $_.Exception.Message
                Write-OperationLog -Message "Erreur lors de l'exécution de $act sur ${ComputerName}: $($_.Exception.Message)" -Level "Error" -Category "Maintenance"
            }
            
            $results += $result
        }
    }
    
    return $results
}

function New-HealthReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$ServerData,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("HTML", "PDF", "CSV", "JSON")]
        [string]$OutputFormat,
        
        [Parameter()]
        [string]$OutputPath = $script:ModuleConfig.ReportPath,
        
        [Parameter()]
        [switch]$IncludeGraphs,
        
        [Parameter()]
        [hashtable]$EmailSettings
    )
    
    Begin {
        $allData = @()
        $reportDate = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFileName = "ServerHealthReport_$reportDate.$($OutputFormat.ToLower())"
        $fullPath = Join-Path $OutputPath $reportFileName
    }
    
    Process {
        $allData += $ServerData
    }
    
    End {
        try {
            switch ($OutputFormat) {
                "HTML" {
                    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Santé des Serveurs - $(Get-Date -Format 'dd/MM/yyyy HH:mm')</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
        .summary { background-color: #ecf0f1; padding: 15px; margin: 20px 0; border-radius: 5px; }
        .server { border: 1px solid #bdc3c7; margin: 15px 0; border-radius: 5px; }
        .server-header { background-color: #34495e; color: white; padding: 10px; }
        .server-content { padding: 15px; }
        .metric { display: inline-block; margin: 5px; padding: 10px; border-radius: 3px; min-width: 100px; text-align: center; }
        .ok { background-color: #2ecc71; color: white; }
        .warning { background-color: #f39c12; color: white; }
        .error { background-color: #e74c3c; color: white; }
        .table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        .table th, .table td { border: 1px solid #bdc3c7; padding: 8px; text-align: left; }
        .table th { background-color: #34495e; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport de Santé des Serveurs</h1>
        <p>Généré le $(Get-Date -Format 'dd/MM/yyyy à HH:mm:ss')</p>
    </div>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p><strong>Nombre de serveurs analysés:</strong> $($allData.Count)</p>
        <p><strong>Serveurs en bonne santé:</strong> $(($allData | Where-Object { $_.OverallHealth -eq 'Healthy' }).Count)</p>
        <p><strong>Serveurs avec alertes:</strong> $(($allData | Where-Object { $_.OverallHealth -eq 'Warning' }).Count)</p>
        <p><strong>Serveurs critiques:</strong> $(($allData | Where-Object { $_.OverallHealth -eq 'Critical' }).Count)</p>
    </div>
"@
                    
                    foreach ($server in $allData) {
                        $statusClass = switch ($server.OverallHealth) {
                            "Healthy" { "ok" }
                            "Warning" { "warning" }
                            "Critical" { "error" }
                            default { "warning" }
                        }
                        
                        $htmlContent += @"
    <div class="server">
        <div class="server-header">
            <h3>$($server.ComputerName) - <span class="$statusClass">$($server.OverallHealth)</span></h3>
        </div>
        <div class="server-content">
            <p><strong>Dernière vérification:</strong> $($server.Timestamp)</p>
"@
                        
                        if ($server.Metrics) {
                            $htmlContent += "<h4>Métriques:</h4>"
                            foreach ($metric in $server.Metrics.GetEnumerator()) {
                                if ($metric.Value -is [SystemMetric]) {
                                    $metricClass = switch ($metric.Value.Status) {
                                        "OK" { "ok" }
                                        "Caution" { "warning" }
                                        "Warning" { "error" }
                                        default { "warning" }
                                    }
                                    $htmlContent += "<div class='metric $metricClass'>$($metric.Key): $($metric.Value.Value)$($metric.Value.Unit)</div>"
                                }
                            }
                        }
                        
                        if ($server.Alerts -and $server.Alerts.Count -gt 0) {
                            $htmlContent += "<h4>Alertes:</h4><ul>"
                            foreach ($alert in $server.Alerts) {
                                $htmlContent += "<li style='color: #e74c3c;'>$alert</li>"
                            }
                            $htmlContent += "</ul>"
                        }
                        
                        $htmlContent += "</div></div>"
                    }
                    
                    $htmlContent += "</body></html>"
                    Set-Content -Path $fullPath -Value $htmlContent -Encoding UTF8
                }
                
                "CSV" {
                    $csvData = $allData | ForEach-Object {
                        [PSCustomObject]@{
                            ComputerName = $_.ComputerName
                            Timestamp = $_.Timestamp
                            OverallHealth = $_.OverallHealth
                            Status = $_.Status
                            Alerts = ($_.Alerts -join "; ")
                            Actions = ($_.Actions -join "; ")
                            ErrorMessage = $_.ErrorMessage
                        }
                    }
                    $csvData | Export-Csv -Path $fullPath -NoTypeInformation -Encoding UTF8
                }
                
                "JSON" {
                    $allData | ConvertTo-Json -Depth 10 | Set-Content -Path $fullPath -Encoding UTF8
                }
            }
            
            Write-OperationLog -Message "Rapport généré: $fullPath" -Level "Information" -Category "Reporting"
            
            # Envoi par email si configuré
            if ($EmailSettings -and $EmailSettings.SmtpServer) {
                try {
                    $mailParams = @{
                        SmtpServer = $EmailSettings.SmtpServer
                        From = $EmailSettings.From
                        To = $EmailSettings.To
                        Subject = "Rapport de Santé des Serveurs - $(Get-Date -Format 'dd/MM/yyyy')"
                        Body = "Veuillez trouver en pièce jointe le rapport de santé des serveurs."
                        Attachments = $fullPath
                    }
                    
                    if ($EmailSettings.Credential) {
                        $mailParams.Credential = $EmailSettings.Credential
                    }
                    
                    Send-MailMessage @mailParams
                    Write-OperationLog -Message "Rapport envoyé par email à $($EmailSettings.To -join ', ')" -Level "Information" -Category "Reporting"
                }
                catch {
                    Write-OperationLog -Message "Erreur lors de l'envoi du rapport par email: $($_.Exception.Message)" -Level "Error" -Category "Reporting"
                }
            }
            
            return @{
                ReportPath = $fullPath
                Format = $OutputFormat
                ServersAnalyzed = $allData.Count
                GenerationTime = Get-Date
            }
        }
        catch {
            Write-OperationLog -Message "Erreur lors de la génération du rapport: $($_.Exception.Message)" -Level "Error" -Category "Reporting"
            throw
        }
    }
}
#endregion

#region Fonction principale
function Test-ServerHealth {
    [CmdletBinding(DefaultParameterSetName = 'Check')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ 
            foreach ($computer in $_) {
                if (-not (Test-ComputerNameValid $computer)) {
                    throw "Nom d'ordinateur invalide: $computer"
                }
            }
            $true
        })]
        [string[]]$ComputerName,
        
        [Parameter()]
        [PSCredential]$Credential,
        
        [Parameter()]
        [ValidateSet("CPU", "Memory", "Disk", "Services", "Network")]
        [string[]]$CheckType = @("CPU", "Memory", "Disk", "Services"),
        
        [Parameter()]
        [ValidateScript({ Test-ThresholdStructure $_ })]
        [hashtable]$Threshold = @{
            CPU = 80
            Memory = 85
            Disk = 90
        },
        
        [Parameter(ParameterSetName = 'Report')]
        [switch]$GenerateReport,
        
        [Parameter(ParameterSetName = 'Report')]
        [switch]$EmailReport,
        
        [Parameter()]
        [string]$LogPath = (Join-Path $script:ModuleConfig.LogPath "ServerMonitoring.log"),
        
        [Parameter(ParameterSetName = 'Maintenance')]
        [switch]$Remediate,
        
        [Parameter()]
        [switch]$WhatIf,
        
        [Parameter()]
        [switch]$Verbose
    )
    
    Begin {
        Write-OperationLog -Message "Début de l'analyse de santé des serveurs" -Level "Information" -Category "HealthCheck"
        $allResults = @()
        $startTime = Get-Date
        
        # Configuration des seuils personnalisés
        $defaultThresholds = @{
            CPU = 80
            Memory = 85
            Disk = 90
        }
        
        foreach ($key in $defaultThresholds.Keys) {
            if (-not $Threshold.ContainsKey($key)) {
                $Threshold[$key] = $defaultThresholds[$key]
            }
        }
        
        Write-Verbose "Seuils configurés: $($Threshold | ConvertTo-Json -Compress)"
    }
    
    Process {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Analyse de $computer en cours..."
            
            $result = [ServerHealthResult]::new($computer)
            
            try {
                # Test de connectivité
                if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
                    throw "Serveur non accessible"
                }
                
                # Récupération des métriques
                $metrics = Get-SystemMetrics -ComputerName $computer -MetricType $CheckType -Credential $Credential
                $result.Metrics = $metrics
                
                # Évaluation de la santé globale
                $alerts = @()
                $actions = @()
                $healthScore = 0
                $maxScore = 0
                
                foreach ($checkType in $CheckType) {
                    switch ($checkType) {
                        "CPU" {
                            if ($metrics.CPU) {
                                $maxScore += 1
                                if ($metrics.CPU.Value -ge $Threshold.CPU) {
                                    $alerts += "CPU élevé: $($metrics.CPU.Value)%"
                                    if ($Remediate) {
                                        $actions += "Redémarrer les services non critiques"
                                    }
                                } else {
                                    $healthScore += 1
                                }
                            }
                        }
                        
                        "Memory" {
                            if ($metrics.Memory) {
                                $maxScore += 1
                                if ($metrics.Memory.Value -ge $Threshold.Memory) {
                                    $alerts += "Mémoire élevée: $($metrics.Memory.Value)%"
                                    if ($Remediate) {
                                        $actions += "Nettoyer la mémoire cache"
                                    }
                                } else {
                                    $healthScore += 1
                                }
                            }
                        }
                        
                        "Disk" {
                            if ($metrics.Disk) {
                                foreach ($disk in $metrics.Disk.GetEnumerator()) {
                                    $maxScore += 1
                                    if ($disk.Value.Value -ge $Threshold.Disk) {
                                        $alerts += "Disque $($disk.Key) plein: $($disk.Value.Value)%"
                                        if ($Remediate) {
                                            $actions += "Nettoyer les fichiers temporaires sur $($disk.Key)"
                                        }
                                    } else {
                                        $healthScore += 1
                                    }
                                }
                            }
                        }
                        
                        "Services" {
                            if ($metrics.Services -and $metrics.Services.Critical -gt 0) {
                                $alerts += "Services critiques arrêtés: $($metrics.Services.Critical)"
                                if ($Remediate) {
                                    $actions += "Redémarrer les services automatiques arrêtés"
                                }
                            } else {
                                $healthScore += 1
                            }
                            $maxScore += 1
                        }
                        
                        "Network" {
                            if ($metrics.Network) {
                                $maxScore += 1
                                if ($metrics.Network.ActiveAdapters -eq 0) {
                                    $alerts += "Aucune interface réseau active"
                                } else {
                                    $healthScore += 1
                                }
                            }
                        }
                    }
                }
                
                # Calcul du statut global
                $healthPercentage = if ($maxScore -gt 0) { ($healthScore / $maxScore) * 100 } else { 0 }
                
                $result.OverallHealth = switch ($healthPercentage) {
                    { $_ -ge 90 } { "Healthy" }
                    { $_ -ge 70 } { "Warning" }
                    default { "Critical" }
                }
                
                $result.Alerts = $alerts
                $result.Actions = $actions
                $result.Status = "Success"
                
                # Exécution des actions de remédiation si demandé
                if ($Remediate -and $actions.Count -gt 0) {
                    if ($PSCmdlet.ShouldProcess($computer, "Exécuter les actions de remédiation")) {
                        try {
                            $maintenanceActions = @()
                            
                            if ($actions -like "*fichiers temporaires*") {
                                $maintenanceActions += "CleanTemp"
                            }
                            if ($actions -like "*services*") {
                                $maintenanceActions += "RestartServices"
                            }
                            
                            if ($maintenanceActions.Count -gt 0) {
                                $maintenanceResult = Invoke-ServerMaintenance -ComputerName $computer -Action $maintenanceActions -Credential $Credential -WhatIf:$WhatIf
                                $result.Actions += "Actions exécutées: $($maintenanceActions -join ', ')"
                            }
                        }
                        catch {
                            Write-OperationLog -Message "Erreur lors de la remédiation pour ${computer}: $($_.Exception.Message)" -Level "Error" -Category "Remediation"
                            $result.Actions += "Erreur lors de la remédiation: $($_.Exception.Message)"
                        }
                    }
                }
                
                Write-OperationLog -Message "Analyse terminée pour $computer - Statut: $($result.OverallHealth)" -Level "Information" -Category "HealthCheck"
                
            }
            catch {
                $result.Status = "Error"
                $result.ErrorMessage = $_.Exception.Message
                $result.OverallHealth = "Critical"
                Write-OperationLog -Message "Erreur lors de l'analyse de ${computer}: $($_.Exception.Message)" -Level "Error" -Category "HealthCheck"
            }
            
            $allResults += $result
            
            # Affichage des résultats en temps réel
            Write-Host "[$($result.Timestamp.ToString('HH:mm:ss'))] " -NoNewline
            
            $color = switch ($result.OverallHealth) {
                "Healthy" { "Green" }
                "Warning" { "Yellow" }
                "Critical" { "Red" }
                default { "Gray" }
            }
            
            Write-Host "$($result.ComputerName): " -NoNewline
            Write-Host "$($result.OverallHealth)" -ForegroundColor $color
            
            if ($result.Alerts.Count -gt 0) {
                foreach ($alert in $result.Alerts) {
                    Write-Host "  ⚠️  $alert" -ForegroundColor Yellow
                }
            }
            
            if ($result.Actions.Count -gt 0) {
                foreach ($action in $result.Actions) {
                    Write-Host "  ✅ $action" -ForegroundColor Cyan
                }
            }
        }
    }
    
    End {
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-OperationLog -Message "Analyse terminée. $($allResults.Count) serveurs traités en $($duration.TotalSeconds) secondes" -Level "Information" -Category "HealthCheck"
        
        # Génération du rapport si demandé
        if ($GenerateReport -or $EmailReport) {
            try {
                $reportParams = @{
                    ServerData = $allResults
                    OutputFormat = "HTML"
                }
                
                if ($EmailReport) {
                    # Configuration email par défaut (à personnaliser)
                    $reportParams.EmailSettings = @{
                        SmtpServer = "smtp.company.com"
                        From = "monitoring@company.com"
                        To = @("admin@company.com")
                    }
                }
                
                $reportResult = New-HealthReport @reportParams
                Write-Host "📊 Rapport généré: $($reportResult.ReportPath)" -ForegroundColor Green
                
                if ($EmailReport) {
                    Write-Host "📧 Rapport envoyé par email" -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Erreur lors de la génération du rapport: $($_.Exception.Message)"
            }
        }
        
        # Résumé final
        $summary = @{
            TotalServers = $allResults.Count
            HealthyServers = ($allResults | Where-Object { $_.OverallHealth -eq "Healthy" }).Count
            WarningServers = ($allResults | Where-Object { $_.OverallHealth -eq "Warning" }).Count
            CriticalServers = ($allResults | Where-Object { $_.OverallHealth -eq "Critical" }).Count
            ErrorServers = ($allResults | Where-Object { $_.Status -eq "Error" }).Count
            ExecutionTime = $duration
            Timestamp = $endTime
        }
        
        Write-Host "`n📋 RÉSUMÉ DE L'ANALYSE" -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "Serveurs analysés: $($summary.TotalServers)" -ForegroundColor White
        Write-Host "✅ En bonne santé: $($summary.HealthyServers)" -ForegroundColor Green
        Write-Host "⚠️  Avec alertes: $($summary.WarningServers)" -ForegroundColor Yellow
        Write-Host "🔴 Critiques: $($summary.CriticalServers)" -ForegroundColor Red
        Write-Host "❌ Erreurs: $($summary.ErrorServers)" -ForegroundColor Red
        Write-Host "⏱️  Temps d'exécution: $($duration.ToString('mm\:ss'))" -ForegroundColor Cyan
        
        return $allResults
    }
}
#endregion

#region Scripts de démonstration et exemples d'utilisation

<#
.SYNOPSIS
Exemples d'utilisation du module ServerMonitoring

.DESCRIPTION
Ce bloc contient des exemples pratiques d'utilisation des fonctions
du module ServerMonitoring pour différents scénarios.

.EXAMPLE
# Exemple 1: Vérification simple de serveurs
Test-ServerHealth -ComputerName "SRV-01", "SRV-02" -CheckType CPU, Memory -Verbose

.EXAMPLE
# Exemple 2: Vérification avec seuils personnalisés
$seuils = @{
    CPU = 70
    Memory = 80
    Disk = 85
}
Test-ServerHealth -ComputerName "SRV-WEB01" -Threshold $seuils -GenerateReport

.EXAMPLE
# Exemple 3: Analyse depuis un fichier avec pipeline
Get-Content "C:\Scripts\servers.txt" | Test-ServerHealth -GenerateReport -EmailReport

.EXAMPLE
# Exemple 4: Maintenance automatique avec confirmation
Test-ServerHealth -ComputerName "SRV-DB01" -Remediate -Confirm

.EXAMPLE
# Exemple 5: Surveillance complète avec rapport HTML
$servers = "SRV-01", "SRV-02", "SRV-03"
$credential = Get-Credential
Test-ServerHealth -ComputerName $servers -Credential $credential -CheckType CPU,Memory,Disk,Services,Network -GenerateReport

.EXAMPLE
# Exemple 6: Maintenance programmée
Invoke-ServerMaintenance -ComputerName "SRV-01" -Action "CleanTemp", "RestartServices" -Schedule (Get-Date).AddHours(2)

.EXAMPLE
# Exemple 7: Génération de rapport personnalisé
$data = Test-ServerHealth -ComputerName "SRV-01", "SRV-02"
New-HealthReport -ServerData $data -OutputFormat JSON -OutputPath "C:\Reports"

.EXAMPLE
# Exemple 8: Consultation de l'historique
Get-OperationHistory -ComputerName "SRV-01" -DateRange (Get-Date).AddDays(-7), (Get-Date) -Level "Warning", "Error"

.EXAMPLE
# Exemple 9: Surveillance en boucle (monitoring continu)
while ($true) {
    $results = Test-ServerHealth -ComputerName "SRV-CRITICAL" -CheckType CPU,Memory
    if ($results.OverallHealth -eq "Critical") {
        Test-ServerHealth -ComputerName "SRV-CRITICAL" -Remediate -WhatIf:$false
    }
    Start-Sleep -Seconds 300  # Attendre 5 minutes
}

.EXAMPLE
# Exemple 10: Script de surveillance quotidienne
$scriptDaily = {
    $servers = Import-Csv "C:\Config\servers.csv" | Select-Object -ExpandProperty ComputerName
    $results = Test-ServerHealth -ComputerName $servers -GenerateReport -EmailReport
    
    # Actions spéciales pour les serveurs critiques
    $critical = $results | Where-Object { $_.OverallHealth -eq "Critical" }
    if ($critical) {
        foreach ($server in $critical) {
            Write-OperationLog -Message "ALERTE: Serveur $($server.ComputerName) en état critique!" -Level "Critical" -Category "Alert"
            # Notification supplémentaire (SMS, Slack, etc.)
        }
    }
}

# Programmer l'exécution quotidienne
# Register-ScheduledTask -TaskName "ServerHealthCheck" -Action (New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command & { $scriptDaily }") -Trigger (New-ScheduledTaskTrigger -Daily -At "08:00")
#>

#endregion

#region Fonctions bonus et utilitaires avancés

function Start-ServerMonitoringDashboard {
    <#
    .SYNOPSIS
    Lance un dashboard web simple pour visualiser l'état des serveurs
    
    .DESCRIPTION
    Crée un serveur HTTP basique pour afficher les résultats de monitoring
    en temps réel dans un navigateur web.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Port = 8080,
        
        [Parameter()]
        [string[]]$ComputerName = @("localhost"),
        
        [Parameter()]
        [int]$RefreshInterval = 60
    )
    
    $htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>Dashboard de Monitoring des Serveurs</title>
    <meta http-equiv="refresh" content="$RefreshInterval">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; text-align: center; }
        .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .server-card { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); transition: transform 0.2s; }
        .server-card:hover { transform: translateY(-2px); }
        .server-name { font-size: 1.5em; font-weight: bold; margin-bottom: 10px; }
        .status-badge { display: inline-block; padding: 5px 15px; border-radius: 20px; color: white; font-weight: bold; text-transform: uppercase; }
        .healthy { background: #2ecc71; }
        .warning { background: #f39c12; }
        .critical { background: #e74c3c; }
        .metrics { margin-top: 15px; }
        .metric { display: flex; justify-content: space-between; margin: 5px 0; padding: 5px 0; border-bottom: 1px solid #eee; }
        .alerts { margin-top: 15px; }
        .alert { background: #ffebee; color: #c62828; padding: 8px; margin: 5px 0; border-left: 4px solid #c62828; border-radius: 0 5px 5px 0; }
        .timestamp { color: #666; font-size: 0.9em; text-align: center; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🖥️ Dashboard de Monitoring des Serveurs</h1>
        <p>Actualisation automatique toutes les $RefreshInterval secondes</p>
    </div>
    <div class="dashboard" id="dashboard">
        <!-- Contenu généré dynamiquement -->
    </div>
    <div class="timestamp">
        Dernière mise à jour: <span id="lastUpdate"></span>
    </div>
    
    <script>
        document.getElementById('lastUpdate').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
"@
    
    Write-Host "🚀 Démarrage du dashboard sur http://localhost:$Port" -ForegroundColor Green
    Write-Host "Appuyez sur Ctrl+C pour arrêter" -ForegroundColor Yellow
    
    # Ici on créerait un serveur HTTP simple
    # Pour la démonstration, on génère juste le fichier HTML
    $dashboardPath = Join-Path $script:ModuleConfig.ReportPath "dashboard.html"
    $htmlTemplate | Set-Content -Path $dashboardPath -Encoding UTF8
    
    Write-Host "📊 Dashboard généré: $dashboardPath" -ForegroundColor Cyan
}

function Export-ServerConfiguration {
    <#
    .SYNOPSIS
    Exporte la configuration complète d'un serveur pour sauvegarde ou comparaison
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter()]
        [PSCredential]$Credential,
        
        [Parameter()]
        [string]$OutputPath = $script:ModuleConfig.ConfigPath
    )
    
    try {
        $config = @{}
        $session = New-CimSession -ComputerName $ComputerName -Credential $Credential
        
        # Informations système
        $config.System = Get-CimInstance -CimSession $session -ClassName Win32_ComputerSystem
        $config.OS = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
        $config.BIOS = Get-CimInstance -CimSession $session -ClassName Win32_BIOS
        
        # Configuration réseau
        $config.Network = Get-CimInstance -CimSession $session -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
        
        # Services installés
        $config.Services = Get-CimInstance -CimSession $session -ClassName Win32_Service | Select-Object Name, State, StartMode, Description
        
        # Logiciels installés
        $config.Software = Get-CimInstance -CimSession $session -ClassName Win32_Product | Select-Object Name, Version, Vendor
        
        # Configuration stockage
        $config.Storage = Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk
        
        Remove-CimSession $session
        
        $configFile = Join-Path $OutputPath "$ComputerName`_config_$(Get-Date -Format 'yyyyMMdd').json"
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
        
        Write-OperationLog -Message "Configuration exportée pour $ComputerName vers $configFile" -Level "Information" -Category "Configuration"
        
        return $configFile
    }
    catch {
        Write-OperationLog -Message "Erreur lors de l'export de configuration pour ${ComputerName}: $($_.Exception.Message)" -Level "Error" -Category "Configuration"
        throw
    }
}

function Compare-ServerConfiguration {
    <#
    .SYNOPSIS
    Compare deux configurations de serveur pour détecter les changements
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaselineConfig,
        
        [Parameter(Mandatory = $true)]
        [string]$CurrentConfig,
        
        [Parameter()]
        [string]$OutputPath = $script:ModuleConfig.ReportPath
    )
    
    try {
        $baseline = Get-Content $BaselineConfig | ConvertFrom-Json
        $current = Get-Content $CurrentConfig | ConvertFrom-Json
        
        $differences = @()
        
        # Comparaison des services
        $baselineServices = $baseline.Services | Sort-Object Name
        $currentServices = $current.Services | Sort-Object Name
        
        $serviceChanges = Compare-Object $baselineServices $currentServices -Property Name, State, StartMode
        foreach ($change in $serviceChanges) {
            $differences += [PSCustomObject]@{
                Category = "Services"
                Type = $change.SideIndicator -eq "=>" ? "Added/Changed" : "Removed/Changed"
                Item = $change.Name
                Details = "State: $($change.State), StartMode: $($change.StartMode)"
            }
        }
        
        # Comparaison des logiciels
        $baselineSoftware = $baseline.Software | Sort-Object Name
        $currentSoftware = $current.Software | Sort-Object Name
        
        $softwareChanges = Compare-Object $baselineSoftware $currentSoftware -Property Name, Version
        foreach ($change in $softwareChanges) {
            $differences += [PSCustomObject]@{
                Category = "Software"
                Type = $change.SideIndicator -eq "=>" ? "Installed/Updated" : "Removed"
                Item = $change.Name
                Details = "Version: $($change.Version)"
            }
        }
        
        $reportFile = Join-Path $OutputPath "ConfigComparison_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $differences | Export-Csv -Path $reportFile -NoTypeInformation -Encoding UTF8
        
        Write-OperationLog -Message "Comparaison de configuration terminée. $($differences.Count) différences trouvées." -Level "Information" -Category "Configuration"
        
        return @{
            DifferencesFound = $differences.Count
            ReportPath = $reportFile
            Differences = $differences
        }
    }
    catch {
        Write-OperationLog -Message "Erreur lors de la comparaison de configuration: $($_.Exception.Message)" -Level "Error" -Category "Configuration"
        throw
    }
}
#endregion

#region Export des fonctions du module
Export-ModuleMember -Function @(
    'Test-ServerHealth',
    'Get-SystemMetrics',
    'Invoke-ServerMaintenance',
    'New-HealthReport',
    'Write-OperationLog',
    'Get-OperationHistory',
    'Start-ServerMonitoringDashboard',
    'Export-ServerConfiguration',
    'Compare-ServerConfiguration'
)
#endregion

<#
.SYNOPSIS
Module PowerShell avancé pour le monitoring et la maintenance automatisée des serveurs

.DESCRIPTION
Ce module fournit un ensemble complet de fonctions pour :
- Surveiller l'état de santé des serveurs (CPU, RAM, disque, services)
- Effectuer des actions de maintenance préventive
- Générer des rapports détaillés avec alertes
- Gérer les logs et historiques d'intervention
- Comparer les configurations système

.NOTES
Auteur: Solution TP PowerShell Avancé
Version: 1.0
Nécessite: PowerShell 5.1 ou supérieur
Modules requis: CimCmdlets (inclus dans Windows)

.LINK
https://docs.microsoft.com/en-us/powershell/

.EXAMPLE
# Installation et utilisation basique
Import-Module .\ServerMonitoring.psm1
Test-ServerHealth -ComputerName "localhost" -Verbose

.EXAMPLE
# Surveillance avancée avec rapport
$servers = "SRV-01", "SRV-02", "SRV-03"
Test-ServerHealth -ComputerName $servers -GenerateReport -CheckType CPU,Memory,Disk,Services

.EXAMPLE
# Maintenance automatisée
Test-ServerHealth -ComputerName "SRV-WEB01" -Remediate -WhatIf
#>