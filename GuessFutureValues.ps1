class PredictedValue {
    [double]$MinValue
    [double]$MaxValue
}

class Measurement {
    [int] $Index
    [double]$RawValue
    [double]$HistoricalHighValue
    [double]$HistoricalLowValue
    [double]$HistoricalAverageValue
    [double]$HistoricalMedianValue
    [double]$HistoricalStandardDeviationValue
    [double]$Trend
    [PredictedValue]$PredicetedNextValue

    Measurement([int]$Index,[double]$RawValue,[double]$HistoricalHighValue,[double]$HistoricalLowValue,[double]$HistoricalAverageValue,[double]$HistoricalMedianValue,[double]$HistoricalStandardDeviationValue) {
        $this.Index                 = $Index
        $this.RawValue              = $RawValue
        $this.HistoricalHighValue   = $HistoricalHighValue
        $this.HistoricalLowValue    = $HistoricalLowValue     
        $this.HistoricalAverageValue = $HistoricalAverageValue   
        $this.HistoricalMedianValue  = $HistoricalMedianValue
        $this.HistoricalStandardDeviationValue = $HistoricalStandardDeviationValue

        # These values are calculated in a second round of calculations, so they are not included in the constructor
        $this.Trend = 0
        $this.PredicetedNextValue = [PredictedValue]::new()

    }
}

#region Functions

Function Extend-InputValues {
    param([HashTable]$inputCalculated,$historicalConstant)


    # This function will populate the trend and the predicted min and max value
    foreach($key in $inputCalculated.Keys)
    {
        $minCollection = New-Object System.Collections.ArrayList
        $maxCollection = New-Object System.Collections.ArrayList
        #$avgCollection = New-Object System.Collections.ArrayList
        #$medCollection = New-Object System.Collections.ArrayList
        #$devCollection = New-Object System.Collections.ArrayList

        $historicalConstant..0 | ForEach-Object {
            $index = $key - $_
            if($index -lt 0) { $index = 0 }

            [void]$minCollection.Add($inputCalculated[$index].HistoricalLowValue)
            [void]$maxCollection.Add($inputCalculated[$index].HistoricalHighValue)
            #[void]$avgCollection.Add($inputCalculated[$index].HistoricalAverageValue)
            #[void]$medCollection.Add($inputCalculated[$index].HistoricalMedianValue)
            #[void]$devCollection.Add($inputCalculated[$index].HistoricalStandardDeviationValue)
        }

        $inputCalculated[$key].PredicetedNextValue.MinValue = Get-Average $minCollection
        $inputCalculated[$key].PredicetedNextValue.MaxValue = Get-Average $maxCollection
    }
    return $inputCalculated
}

Function Get-InputCalculated {
    param($inputHash,$historicalConstant)

    $inputCalculated = @{}
    foreach ($key in $inputHash.Keys)
    {
        $inputCalculated.Add($key, (Get-CalculatedMeasurement -inputHash $inputHash -key $key -historicalConstant $historicalConstant))
    }

    return $inputCalculated
}

Function Get-CalculatedMeasurement {
    param($inputHash, $key, $historicalConstant)

    $historicalValues = Get-AllHistoricalValues -inputHash $inputHash -key $key -historicalConstant $historicalConstant | Sort-Object

    $low = $historicalValues[0]
    $high = $historicalValues[-1]
    $average = Get-Average $historicalValues
    $median = Get-Median $historicalValues
    $standardDeviation = Get-StandardDeviation $historicalValues

    $result = [Measurement]::New($key,$inputHash[$key],$high,$low,$average,$median,$standardDeviation)
    return $result
}

Function Get-AllHistoricalValues {
    param($inputHash,$key,$historicalConstant)

    $start = $key - $historicalConstant
    if($start -lt 0) {
        $start = 0
    }
    $all = New-Object System.Collections.ArrayList
    $start..$key | ForEach-Object { [void]$all.Add($inputHash[$_]) }

    return $all
}

Function Get-Median {
    <#
    .Synopsis
        Gets a median
    .Description
        Gets the median of a series of numbers
    .Example
        Get-Median 2,4,6,8
    .Link
        Get-Average
    .Link
        Get-StandardDeviation
    #>
    param(
    # The numbers to average
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [Double[]]
    $Number
    )
    
    begin {
        $numberSeries = @()
    }
    
    process {
        $numberSeries += $number
    }
    
    end {
        $sortedNumbers = @($numberSeries | Sort-Object)
        if ($numberSeries.Count % 2) {
            # Odd, pick the middle
            $sortedNumbers[($sortedNumbers.Count / 2) - 1]
        } else {
            # Even, average the middle two
            ($sortedNumbers[($sortedNumbers.Count / 2)] + $sortedNumbers[($sortedNumbers.Count / 2) - 1]) / 2
        }                        
    }
} 

Function Get-StandardDeviation {
    <#
    .Synopsis
        Gets the standard deviation of a series of numbers
    .Description
        Gets the standard deviation of a series of numbers
    .Example
        Get-StandardDeviation 2,4,6,8
    #>
    param(
    # The series of numbers
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [Double[]]
    $Number
    )
    
    begin {
        $numberSeries = @()
    }
    
    process {
        $numberSeries += $number
    }
    
    end {
        $scriptBlock = "
# Start the total at zero
`$total = 0
"
        foreach ($n in $numberSeries) {
            $scriptBlock += "
# Add $n to the total
`$total += $n
"            
        }
        
        $scriptBlock += "
# The average is the total divided by the number of items $($numberSeries.Count)
`$average = `$total / $($numberSeries.Count)
`$deviationTotal = 0
"


foreach ($n in $NumberSeries) {
            $scriptBlock += "
# Add $n to the total
`$deviationTotal += [Math]::Pow(($n - `$average), 2)
"            

}

        $scriptBlock += "
`$deviationAverage = `$deviationTotal / $($numberSeries.Count)
 
 
`$standardDeviation = [Math]::Sqrt(`$deviationAverage)
"

        $sb=  [ScriptBlock]::Create($scriptBlock)        
        
        $null = . $sb
        $standardDeviation
    }
} 

Function Get-Average {
    <#
    .Synopsis
        Gets an average
    .Description
        Gets an average of a series of numbers
    .Example
        Get-Average 2,4,6,8
    #>
    param(
    # The numbers to average
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [Double[]]
    $Number
    )
    
    begin {
        $numberSeries = New-Object Collections.ArrayList
    }
    
    process {
        $null = $numberSeries.AddRange($number)
    }
    
    end {
        $scriptBlock = "
# Start the total at zero
`$total = 0
"
        foreach ($n in $numberSeries) {
            $scriptBlock += "
# Add $n to the total
`$total += $n
"            
        }
        
        $scriptBlock += "
# The average is the total divided by the number of items $($numberSeries.Count)
`$average = `$total / $($numberSeries.Count)
"

        $sb=  [ScriptBlock]::Create($scriptBlock)        
        
        $null = . $sb
        $average
    }
} 

#endregion




# CONSTANTS

# Value to calculate historical values
$historicalConstant = 10

# input: collection of values key = time, value = value
$inputHash = @{}

# populate example
1..100 | ForEach-Object { $inputHash.Add($_,(Get-Average (Get-Process -Name Code).CPU)); sleep -Milliseconds 100 }

# START

$inputCalculated = Get-InputCalculated -inputHash $inputHash -historicalConstant $historicalConstant

$inputExtended = Extend-InputValues  -inputCalculated $inputCalculated


foreach($key in $inputExtended.Keys)
{
    if($inputExtended[$key+1].RawValue -ge $inputExtended[$key].PredicetedNextValue.MinValue -and
       $inputExtended[$key+1].RawValue -le $inputExtended[$key].PredicetedNextValue.MaxValue)
    {
        Write-Host $inputExtended[$key].RawValue -ForegroundColor Green
    } 
    else 
    {
        Write-Host $inputExtended[$key].RawValue -ForegroundColor Red
    }
}