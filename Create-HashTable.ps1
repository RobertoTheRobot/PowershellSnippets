
#
# Usage: $my_collection | Create-HashTable -key 'prop1' -value 'prop2'
#
Function Out-HashTable {
    param(
     [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$collection
    ,[Parameter(Position=1, Mandatory=$true, ValueFromPipeline = $false)][string]$key
    ,[Parameter(Position=2, Mandatory=$true, ValueFromPipeline = $false)][string]$value
    )

    Begin
    {
        $hashTable = @{}
    }
    Process
    {
        foreach($item in $collection)
        {
            if($hashTable[$item.($key)])
            {
                [void]$hashTable[$item.($key)].Add($item.($value))
            }
            else
            {
                $hashTable[$item.($key)] = New-Object System.Collections.ArrayList
                [void]$hashTable[$item.($key)].Add($item.($value))
            }
        }
    }
    End
    {
        return $hashTable
    }
}
