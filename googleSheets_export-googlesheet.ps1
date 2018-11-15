
#########

# this is an example. It is not valid.
$clientId = "-----------.apps.googleusercontent.com";
$secret = "xXxXxXx";


Function Get-AuthorizationCode {

    $scope = "https://www.googleapis.com/auth/spreadsheets"
    $clientId = "-----------.apps.googleusercontent.com";
    start "https://accounts.google.com/o/oauth2/auth?client_id=$clientId&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=$scope&response_type=code"

}

Function Get-GoogleAccessToken {
    [CmdletBinding()]
    param (
    [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$AuthorizationCode,
    [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$clientId,
    [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$secret
    )

    
    $redirectURI = "urn:ietf:wg:oauth:2.0:oob";
        
    $tokenParams = @{
	        client_id=$clientId;
  	        client_secret=$secret;
            code=$AuthorizationCode;
	        grant_type='authorization_code';
	        redirect_uri=$redirectURI
	    }

    $token = Invoke-WebRequest -Uri "https://accounts.google.com/o/oauth2/token" -Method POST -Body $tokenParams | ConvertFrom-Json
    return $token    
}

Function Refresh-GoogleAccessToken {
    [CmdletBinding()]
    param (
    [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$refreshToken)
        
    $refreshTokenParams = @{
	      client_id=$clientId;
  	      client_secret=$secret;
              refresh_token=$refreshToken;
	      grant_type='refresh_token';
	    }

    $token = Invoke-WebRequest -Uri "https://accounts.google.com/o/oauth2/token" -Method POST -Body $refreshTokenParams | ConvertFrom-Json

    return $refreshedToken
}

function Export-GoogleSheet {
    [CmdletBinding()]
    param (
    [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$name,
    [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [System.Collections.ArrayList]$data,
    [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$accesstoken
    )


    # Create Spreadsheet and receive spreadsheet id (later it is updated)
    #POST https://sheets.googleapis.com/v4/spreadsheets

    $spreadsheetProperties = New-Object psobject -Property @{"title"=$name}
    $spreadsheet = New-Object psobject -Property @{"properties"=$spreadsheetProperties}

    try
    {
        $createdSpreadsheet = Invoke-RestMethod -Uri "https://sheets.googleapis.com/v4/spreadsheets" -Method Post -Body ($spreadsheet | convertto-json) -Headers @{"Authorization"=("Bearer " + $accesstoken)}  -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
    } catch {
        throw $_.Exception
    }

    ## update spreadsheet with data

    #build spreadsheet object

    $updateSheetObj = New-Object psobject -Property @{"range"="";"majorDimension"="ROWS";"values"=(New-Object System.Collections.ArrayList)}

    $columns = $data[0] | gm | ? {$_.MemberType -ne 'Method' }

    $updateSheetObj.values.Add($columns.Name)

    foreach($row in $data)
    {
        $o = @()
        foreach($column in $columns)
        {
            $o+= $row.($column.Name)
        }
        $updateSheetObj.values.Add($o)
    }

    $updateSheetObj.range = [string]::Format("Sheet1!A1:{0}{1}",[char]($columns.count+64),$updateSheetObj.values.Count)


    #update Spreadsheet

    try
    {
        $updatedSpreadsheet = Invoke-RestMethod -Uri ([string]::Format("https://sheets.googleapis.com/v4/spreadsheets/{0}/values/{1}?valueInputOption=USER_ENTERED",$createdSpreadsheet.spreadsheetId,$updateSheetObj.range)) -Method Put -Body ($updateSheetObj | convertto-json) -Headers @{"Authorization"=("Bearer " + $accesstoken)} -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
    } catch {
        throw $_.Exception
    }


    return $updatedSpreadsheet
}


# First time, it needs to create tha authorization code
# Get-AuthorizationCode

$AuthorizationCode = "xxxxxxxxxxxxxxxxxx"

$token = Get-GoogleAccessToken -AuthorizationCode $AuthorizationCode -clientId $clientId -secret $secret
$refresh = $token.refresh_token

# refresh token before it expires
$token = Refresh-GoogleAccessToken -refreshToken $refresh


#region Example Data

$data = New-Object System.Collections.ArrayList
$data.Add((New-Object psobject -Property @{"brand"="Ducati";"model"="Scrambler"}))
$data.Add((New-Object psobject -Property @{"brand"="Honda";"model"="VFR"}))

#endregion


$createdSpreadsheet = Export-GoogleSheet -data $data -name 'test_export_1' -accesstoken ($token.access_token)

start ([string]::Format("https://docs.google.com/spreadsheets/d/{0}/edit",$createdSpreadsheet.spreadsheetId))




