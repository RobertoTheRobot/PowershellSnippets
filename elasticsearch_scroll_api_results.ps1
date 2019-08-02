

# Using Scroll Elasticsearch  API

#region Functions to query Elasticsearch

function Get-ESContext {
    param([string]$server,[string]$port,[pscredential]$xpack_credential)
    $context = New-Object psobject
    $context | Add-Member NoteProperty 'host' $server
    $context | Add-Member NoteProperty 'port' $port
    $context | Add-Member NoteProperty 'credential' $xpack_credential
    $context
}

function Get-ESSearch {
    param([string]$index, [string]$body, [System.Object]$context)
    $q = $index + "/_search"
    if($null -eq $context.credential) {
        $res = Invoke-RestMethod -Uri ([string]::Format("https://{0}:{1}/{2}",$context.host,$context.port,$q)) -Body $body -Method Post
    } else {
        $res = Invoke-RestMethod -Uri ([string]::Format("https://{0}:{1}/{2}",$context.host,$context.port,$q)) -Body $body -Method Post -Credential $context.credential
    }
    $res
}

function Get-ESSearchScroll {
    param([string]$index, [string]$body, [string]$scrollTime, [System.Object]$context)
    #scrollTime ~ 1m / 5m ...
    $q = $index + "/_search?scroll=" + $scrollTime
    if($null -eq $context.credential) {
        $res = Invoke-RestMethod -Uri ([string]::Format("https://{0}:{1}/{2}",$context.host,$context.port,$q)) -Body $body -Method Post -ContentType "application/json"
    } else {
        $res = Invoke-RestMethod -Uri ([string]::Format("https://{0}:{1}/{2}",$context.host,$context.port,$q)) -Body $body -Method Post -Credential $context.credential -ContentType "application/json"
    }
    $res
}

function Get-ESSearchScroll_next {
    param([string]$scrollTime, [string]$pageToken, [System.Object]$context)
    #scrollTime ~ 1m / 5m ...
    $q = $index + "_search/scroll"

    $query = '{"scroll_id" : "' + $pageToken + '", "scroll" : "' + $scrollTime + '" }'
    if($null -eq $context.credential)
    {
        $res = Invoke-RestMethod -Uri ([string]::Format("https://{0}:{1}/{2}",$context.host,$context.port,$q)) -Body $query -Method Post -ContentType "application/json"
    }
    else
    {
        $res = Invoke-RestMethod -Uri ([string]::Format("https://{0}:{1}/{2}",$context.host,$context.port,$q)) -Body $query -Method Post -Credential $context.credential -ContentType "application/json"
    }
    $res
}


#endregion

# Create elasticsearch context (it uses credentials for x-pack security, leave empty for no xpack)

$esc = Get-ESContext -server "myelasticserver" -port 9200 -xpack_credential (get-credential)


$pageToken = ""
$pageTokenExists = $true
$size = 1000
$origin = "indexName"
$scrollTime = "1m"

$Result = New-Object System.Collections.ArrayList

while($pageTokenExists)
{
    if([string]::IsNullOrEmpty($pageToken))
    {
        $query = '{
            "size": '+$size+',
            "query": {
              ...
        }'

        $r = Get-ESSearchScroll -index $origin -body $query -scrollTime $scrollTime -context $esc
    }
    else
    {
        $r = Get-ESSearchScroll_next -pageToken $pageToken -scrollTime $scrollTime  -context $esc
    }

    $docs = $r.hits.hits

    if($docs.count -eq 0)
    {
        $pageTokenExists = $false
        break;
    }
    else
    {
        $pageTokenExists = $true
        $pageToken = $r._scroll_id
    }

    Write-Host ($origin + ":  - Getting data " + $docs.count) -ForegroundColor Yellow

    $t = $docs.count
    $i=0
    foreach($hit in $docs)
    {
        $i++
        Write-Progress -Activity ("Processing ") -Status ($hit._source.description) -PercentComplete ($i*100/$t)

        # Save here the details of the result needed for each document returned, in this example it only gets a single string field, but
        # you can create a custom object with the result and add it to the arraylist

        $info = $hit._source.description

        [void]$Result.Add($info)


        Clear-Variable 'info'
    }

}

$Result