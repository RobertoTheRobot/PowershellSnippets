
#
# Usage: $my_collection | Out-HashTable -key 'prop1' -value 'prop2'
#
Function Out-HashTable {
    param(
         [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$collection
        ,[Parameter(Position=1, Mandatory=$true, ValueFromPipeline = $false)][string]$key
        ,[Parameter(Position=2, Mandatory=$false, ValueFromPipeline = $false)][string]$value
    )

    Begin
    {
        $hashTable = @{}
    }
    Process
    {
        if($value) {
            $hashTable[$item.($key)] = $item.($value)
        } else {
            $hashTable[$item.($key)] = $item
        }
    }
    End
    {
        return $hashTable
    }
}


#
# Usage: $my_collection | TableTo-HashTable -key 'column1' -values @('column2','column3','column4')
#
Function TableTo-HashTable {
    param(
     [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$collection
    ,[Parameter(Position=1, Mandatory=$true, ValueFromPipeline = $false)][string]$key
    ,[Parameter(Position=2, Mandatory=$true, ValueFromPipeline = $false)][string[]]$values
    )

    Begin
    {
        $hashTable = @{}
    }
    Process
    {
        foreach($item in $collection)
        {       
            # If the key has value in this item
            if($item.($key))
            {   
                # If the key has not been created yet in the hashtable, create it with a empty arraylist value  
                if(!$hashTable[$item.($key)])  
                {
                    $hashTable[$item.($key)] = New-Object System.Collections.ArrayList
                } 
                        
                foreach($column in ($item.PSObject.Properties.Name | Where-Object { $_ -in $values}))
                {  
                    if($item.($column))
                    {                            
                        [void]$hashTable[$item.($key)].Add($item.($column))                            
                    }
                }  
            }           
        }
    }
    End
    {
        return $hashTable
    }
}
