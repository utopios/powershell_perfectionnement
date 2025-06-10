$tasksRecuperees = @()
$tasks = Get-ScheduledTask | Select-Object -First 10
$tasks
foreach($task in $tasks) {
    $obj = [PSCustomObject]@{
        Nom = $task.TaskName
        Chemin = $task.TaskPath
        Auteur = $task.Author
        Action = $task.Actions.Execute
        Statut = (Get-ScheduledTaskInfo -TaskName $task.TaskName).LastTaskResult
    }
    $tasksRecuperees += $obj
}

 
# $tasksRecuperees | Select-Object Action, Statut

foreach($task in $tasksRecuperees) {
    $task | Add-Member -MemberType ScriptProperty -Name "EstRisquePotentiel" -Value {
        $this.Action -match '\.bat$|\.exe$|\.vbs|\.exe\"$'
    }
}
$tasksRecuperees