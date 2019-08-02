


#given a list of actions to do (in this example a list of Ids):
$IdsToProcess = New-Object System.Collections.ArrayList
  
        
#region process all pending ASYNC 

#Create runspace: you set here the number of concurrent connectionsm for example, 100
$n = 3
$runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1,$n)

#default connection limit is 2
[System.Net.ServicePointManager]::DefaultConnectionLimit = 1000
$runspacePool.Open()
$powershellThreads = @()

$IdsToProcess | ForEach-Object {
    Write-Progress -Activity "Adding Jobs" -Status $_.Id -PercentComplete (($UsersPending.IndexOf($_)/ $UsersPending.count)*100)
    $powershellInstance = [System.Management.Automation.Powershell]::Create()
    $command = {
                    param ($id)

                    #region CONSTANTS
                        #
                        # Example:
                        # $a = Invoke-WebRequest -Uri ($api + "DB") -Method GET -Headers $apiAuth -ContentType "application/json"
                        #
                        $api = "https://xxxxxxxxxxxxxx"
                        $apiAuth = @{"Authorization"="Basic xxxxxxx"}
                                                
                        $Now = (get-date).DayOfYear
                        $date = [string](get-date).Year + "-" + (get-date).Month + "-" + (get-date).Day
                        
                    #endregion

                    #region FUNCTIONS

                        # Pass any function that is not available in the server where it is running
                        # and it's needed within the code to run
                        function Get-ExampleData {
                            param([string]$param)                      
                            $result = Invoke-RestMethod -Uri ("https://xxxxx?param=" + $param) -Method GET -ContentType "application/json"
                            $result
                        }

                        function Proccess-ExampleData {
                            param([string]$id) 
                            
                            #do whatever the function must do

                            $result = ""

                            $result
                        }                        

                    #endregion

                    # MAIN

                    if(Get-ExampleData -param $id -eq $true)
                    {
                        Proccess-ExampleData($id)
                    }

              }
    [Void]$powershellInstance.AddScript($command)
    [Void]$powershellInstance.AddArgument($_)
    # more argumanets added here. Order is important (same as the one specified in the params in the command)
    # [Void]$powershellInstance.AddArgument($_.Trim())

    $powershellInstance.RunspacePool = $runspacePool
    $powershellThreads += New-Object PSObject -Property @{
        Pipe = $powershellInstance;
        Result = $powershellInstance.BeginInvoke()
    };
}

$seconds = 0
Do {
        Write-Progress -Activity "Awaiting task completion passed seconds: $seconds" -Status ("Waiting to complete: " + ($powershellThreads.Result.IsCompleted -eq $false).Count)
        Start-Sleep -Seconds 1
        $seconds = $seconds + 1
   }
While ($powershellThreads.Result.IsCompleted -contains $false)

$powershellThreadsCount = $powershellThreads.Count
$powershellThreadsCounter = 0
foreach ($powershellThread in $powershellThreads)
{
    $powershellThreadsCounter++
    Write-Progress -Activity "Resolving output" -Status ($powershellThreadsCounter) -PercentComplete (($powershellThreadsCounter/$powershellThreadsCount) * 100) -ParentId 1
    $result = $powershellThread.Pipe.EndInvoke($powershellThread.Result)
    $result | ForEach-Object {[Void]$results.Add($_)}
}


#endregion

$results