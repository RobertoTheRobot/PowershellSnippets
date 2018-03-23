

# This example shows how to use dynamic parameters in a Powershell function
Function Do-Something {
    [CmdletBinding()]
    param()
    DynamicParam {
        # get your liast of parameters, in this case is hardcoded, but could be any case of query
        $values = @("val_1","val_2") 
        $attributes = New-Object System.Management.Automation.ParameterAttribute
        $attributes.ParameterSetName = "__AllParameterSets"
        $attributes.Mandatory = $true
        $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($values)
        $attributeCollection.Add($ValidateSet)    
        $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("customParam", [String[]], $attributeCollection)
        $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("customParam", $dynParam1)
        return $paramDictionary 
    }

    Begin {}

    Process {
        #
        #
    }

    End {}

}