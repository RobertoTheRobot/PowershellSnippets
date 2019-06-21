
# functions used to query a MSSQL or MySQL database

function QueryTo-MSSQL {
    param([string]$query)
    $connectionString = "Data Source={server};Initial Catalog={database};Integrated Security=False;User ID={user};Password={password}"

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $connectionString
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $query
    $SqlCmd.Connection = $SqlConnection
    $SqlCmd.CommandTimeout = 0
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    [void]$SqlAdapter.Fill( $DataSet)
    $SqlConnection.Close()   
    $DataSet.Tables[0]
}

function QueryTo-MySQL {
    param([string]$query)
    #$MySQLQuery = "SELECT id, givenname,surname,loginname,email FROM office.Staff WHERE off_duty = 0"
    $MySQLQuery = $query
    $MySQLAdminUserName = '{user}'
    $MySQLAdminPassword = '{password}'
    $MySQLDatabase = '{databaseName}'
    $MySQLHost = '{databaseServer}'
    
    $ConnectionString = "server=" + $MySQLHost + ";port=3306;uid=" + $MySQLAdminUserName + ";pwd=" + $MySQLAdminPassword + ";database="+$MySQLDatabase
    
    [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
    $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()
    $Command = New-Object MySql.Data.MySqlClient.MySqlCommand ($MySQLQuery, $Connection)
    $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter ($Command)
    $DataSet = New-Object System.Data.DataSet
    [void]$dataAdapter.Fill( $dataSet)
    $Connection.Close() 
    $DataSet.Tables[0]
    
}

function Run-StoredProcedureMSSQL {
    param([string]$param1, [string]$param2, [string]$param3)

    $connectionString = "Data Source={server};Initial Catalog={database};Integrated Security=False;User ID={user};Password={password}"
    $spName = "{storedProcedureName}"
    
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $connectionString
    $SqlConnection.Open()

    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandType=[System.Data.CommandType]'StoredProcedure'
    $SqlCmd.CommandText = $spName 
    $SqlCmd.Connection = $SqlConnection

    [void]$SqlCmd.Parameters.AddWithValue("@param1",$param1)
    [void]$SqlCmd.Parameters.AddWithValue("@param1",$param2)
    [void]$SqlCmd.Parameters.AddWithValue("@param1",$param3)

    $sqlreader = $SqlCmd.ExecuteReader()
    $sqlreader.Close()

    $SqlConnection.Close()
}

# Bulk upload datatable to MSSQL db
function Write-BulkDB {
    param([datatable]$datatable)

    $connectionString = "Data Source={server};Initial Catalog={database};Integrated Security=False;User ID={user};Password={password}"
    $tableName = "{tableName}"
    
    $sqlBulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($connectionString,[System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity)

    #if columns in datatable have different names than the columns in the SQL table, it has to be changed here
    $datatable.Columns | % { $sqlBulkCopy.ColumnMappings.Add($_.ColumnName,$_.ColumnName) }
    $sqlBulkCopy.BulkCopyTimeout = 600
    $sqlBulkCopy.DestinationTableName = $tableName
    $sqlBulkCopy.WriteToServer($datatable)
}





