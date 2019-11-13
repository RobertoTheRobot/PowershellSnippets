Function Show-Progress {
    <# 
    .SYNOPSIS 
    Show a simple progress bar
    .DESCRIPTION 
    Show a simple progress bar inside a loop. This progress bar is highly innefficient, to be used only in cases where performance is not a concern. 
    .INPUTS 
    Collection 
        Collection being iterated in the loop
    Item
        Current item in loop
    .OUTPUTS 
       
    .EXAMPLE 
    foreach ($obj in $col)
    {
        Show Progress -Collection $col -Item $obj
        #...
    }
    .NOTES 
    
    .LINK 
    https://github.com/RobertoTheRobot
    #> 
    [CmdletBinding()] 
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $false)] [PSObject[]]$Collection,
        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline = $false)] [PSObject]$Item
    ) 
    Begin 
    { 
        $total = $Collection.count
        $i = $collection.IndexOf($Item) + 1
    }
    Process
    {
    }
    End
    {
        Write-Progress -Activity "Processing..." -Status ("{0} / {1}" -f $i,$total) -PercentComplete ($i*100/$total)
    }
}