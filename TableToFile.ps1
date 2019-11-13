Function Save-TableToFile {
    <# 
    .SYNOPSIS 
    Saves DataTable content to a file 
    .DESCRIPTION 
    Saves DataTable content to a file. 
    .INPUTS 
    datatable 
        System.Data.DataTable
    filePath
        string
    .OUTPUTS 
       Void 
    .EXAMPLE 
    $dt | Save-TableToFile -filePath "c:\file.ext"

    Save-TableToFile -dataTable $dt -filePath "c:\file.ext"    
    .LINK 
    https://github.com/RobertoTheRobot
    #> 
    param(
         [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [System.Data.DataTable]$datatable
        ,[Parameter(Position=1, Mandatory=$true, ValueFromPipeline = $false)][string]$filePath
    )

    Begin
    {
    }
    Process
    {
        $writer = New-Object IO.StreamWriter $filePath
        $datatable.WriteXml($writer, [Data.XmlWriteMode]::WriteSchema)
        $writer.Close()
        $writer.Dispose()
    }
    End
    {
    }
}

Function Get-TableFromFile {
    <# 
    .SYNOPSIS 
    Get content of a Datatable from file 
    .DESCRIPTION 
    Get content of a Datatable from file. 
    .INPUTS 
    filePath
        string
    .OUTPUTS 
       System.Data.DataTable 
    .EXAMPLE 
    $dt = Get-TableFromFile -filePath C:\file.ext
    .LINK 
    https://github.com/RobertoTheRobot
    #>
    param(
         [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $false)][string]$filePath
    )

    Begin
    {
        $ds = New-Object Data.DataSet
    }
    Process
    {
        [void]$ds.ReadXml($filePath, [Data.XmlReadMode]::ReadSchema)
    }
    End
    {
        return $ds.Tables[0]
    } 
}

#
# Example working with tables:
#
# $dt = new-object Data.datatable
# $dt.TableName = "MyTable"
#
# $col =  new-object Data.DataColumn
# $col.ColumnName = "Col1"
# $col.DataType = [System.String]
# $dt.Columns.Add($col)
#
# $col =  new-object Data.DataColumn
# $col.ColumnName = "Col2"
# $col.DataType = [System.String]
# $dt.Columns.Add($col)
#
# $dr = $dt.NewRow() 
# $dr.Col1 = "foo"
# $dr.Col2 = "bar"
#
# $dt.Rows.Add($dr)
#
# $filePath = $env:USERPROFILE + "\Desktop\test.ext" 
# Save-TableToFile -datatable $dt -filePath $filePath
# $dt1 = Get-TableFromFile -filePath $filePath
