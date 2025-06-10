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

$tasksRecuperees 
# $tasksRecuperees | Select-Object Action, Statut
