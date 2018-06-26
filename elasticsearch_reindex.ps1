
# dayli to monthly

$elasticUri = "http://192.168.0.160:9200/"

# Set details for source and dest indices

$indexPattren = "metricbeat-2017*"
$destIndex = $indexPattren.Replace("*","")
#$destIndex = "metricbeat-2017"



$res1 = invoke-restmethod ($elasticUri + $indexPattren)
$source = ($res1 | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty"} | Select-Object Name).Name | Where-Object { $_ -ne $destIndex}

$sourceObj = New-Object psobject -Property @{"index" = (New-Object System.Collections.ArrayList)}
$source | ForEach-Object { [void]$sourceObj.index.Add($_) }

$destObj = New-Object psobject -Property @{"index" = $destIndex}

$objQuery = New-Object psobject -Property @{"source" = $sourceObj; "dest" = $destObj}

#$objQuery | ConvertTo-Json


################
# REINDEX
################

# Trigger reindex action. This request will timeout.
Invoke-RestMethod ($elasticUri + "_reindex") -Method Post -Body ($objQuery | ConvertTo-Json) -ContentType 'application/json' -TimeoutSec 1 -ErrorAction SilentlyContinue

# Get tasks
# This assumes there is only one reindex task happening at the same time. Change this behaviour for a production service

Start-Sleep  -Seconds 1

$tasks = Invoke-RestMethod ($elasticUri + "_tasks/?pretty&detailed=true&actions=*reindex") -Method Get

$node = ($tasks.nodes | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).name
$taskId = ($tasks.nodes.($node).tasks[0] | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).name
$task = $tasks.nodes.($node).tasks.($taskId)


# Wait for task to complete
# re-check every n secconds

$n = 10

while($task -ne $null)
{
    Write-Progress ($task.action) -Status ($task.status.created.ToString() + " / " + $task.status.total.ToString()) -PercentComplete ($task.status.created *100 / $task.status.total)
    #Write-Host "Waiting for tasks to complete"
    Start-Sleep -Seconds $n
    $tasks = Invoke-RestMethod ($elasticUri + "_tasks/?pretty&detailed=true&actions=*reindex") -Method Get
    $node = ($tasks.nodes | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).name
    $taskId = ($tasks.nodes.aznLfmSaT1mCrgG_fdcODQ.tasks[0] | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).name
    $task = $null
    $task = $tasks.nodes.($node).tasks.($taskId)
}


# Check if it happened correctly

# to do



# Delete source indices

foreach($index in $source)
{
    Invoke-RestMethod -Uri ($elasticUri + $index) -Method Delete
}

