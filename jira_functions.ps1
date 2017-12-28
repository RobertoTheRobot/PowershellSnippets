
Add-Type @"  
using System.Net;  
using System.Security.Cryptography.X509Certificates;  
public class TrustAllCertsPolicy : ICertificatePolicy {  
    public bool CheckValidationResult(  
        ServicePoint srvPoint, X509Certificate certificate,  
        WebRequest request, int certificateProblem) {  
        return true;  
    }  
}  
"@  

[System.Net.ServicePointManager]::DnsRefreshTimeout = 0  
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null  
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy  
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls, [System.Net.SecurityProtocolType]::Tls12, [System.Net.SecurityProtocolType]::Tls11 


#helper functions
function Get-HttpBasicHeader($Credentials, $Headers = @{}) {
    $b64 = ConvertTo-Base64 "$($Credentials.UserName):$(ConvertTo-UnsecureString $Credentials.Password)"
    $Headers["X-Atlassian-Token"] = "nocheck"
    $Headers["Authorization"] = "Basic $b64"
    return $Headers
}
function ConvertTo-UnsecureString([System.Security.SecureString][parameter(mandatory=$true)]$SecurePassword) {
    $unmanagedString = [System.IntPtr]::Zero;
    try
    {
        $unmanagedString = [Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($SecurePassword)
        return [Runtime.InteropServices.Marshal]::PtrToStringUni($unmanagedString)
    }
    finally
    {
        [Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($unmanagedString)
    }
}
function ConvertTo-Base64($string) {
    $bytes  = [System.Text.Encoding]::UTF8.GetBytes($string);
    $encoded = [System.Convert]::ToBase64String($bytes);
    
    return $encoded;
}


$jiraUrl = "https://jira.mydomain.com/jira/rest/api/2/issue/"

#create ticket
function Jira-CreateTicket {
    param([string]$subject,[string]$body,[string]$parentTicket,[PSCredential]$credentials)

    #constants
    $assignee = '{username}'

    #jira stuff
    [String]$jira_projectKey = "{XXX}"
    [String]$jira_issueType = "Task"
    [String]$jira_summary = "summary"
    $jira_headers = Get-HttpBasicHeader $credentials

    $uri = $jiraUrl


    if(![string]::IsNullOrEmpty($parentTicket))
    {
        [String]$requestBody = '{"fields":{"project":{"key":"'+$jira_projectKey+'"},"parent":{"key": "' + $parentTicket + '"},"issuetype":{"id": "5"},"summary":"' + $subject + '","description":"' + $body + '","reporter":{"name": "palerts"},"assignee":{"name": "' + $assignee + '"}}}'    
        
    }
    else
    {
        [String]$requestBody = '{"fields":{"project":{"key":"'+$jira_projectKey+'"},"issuetype":{"id": "3"},"summary":"' + $subject + '","description":"' + $body + '","reporter":{"name": "palerts"},"assignee":{"name": "' + $assignee + '"}}}'
    }

    $Result = Invoke-RestMethod -URI $uri -Method Post -Headers $jira_headers  -ContentType "application/json" -Body $requestBody -UseBasicParsing

    $Result.key
}
#add label
Function Jira-AddLabel {
    param([string]$ticketId,[PSCredential]$credentials)

    $jira_headers = Get-HttpBasicHeader $credentials

    Write-Host ("Choose label: ")
    Write-Host ("   0 - break/fix")
    Write-Host ("   1 - escalation")
    Write-Host ("   2 - improvement")
    Write-Host ("   3 - maintenance")
    Write-Host ("   4 - other")

    $labelId = Read-Host (' ')

    switch($labelId)
    {
        "0" { $label = "break/fix"; break }
        "1" { $label = "escalation"; break }
        "2" { $label = "improvement"; break }
        "3" { $label = "maintenance"; break }
        default { $label = Read-Host ('Type your own label') }
    } 

    $label

    $uri = $jiraUrl + $ticketId 

    $body = '{ "fields": { "labels":["' + $label + '"] } } '
    
    Invoke-RestMethod -URI $uri -Method Put -Headers $jira_headers  -ContentType "application/json" -Body $body


}
#log time
Function Jira-LogWork {
    param([string]$ticketId,[int]$timeSpent,[string]$description,[PSCredential]$credentials)

    $jira_headers = Get-HttpBasicHeader $credentials

    $uri = $jiraUrl + $ticketId + "/worklog" 

    $body = '{"timeSpent": "' + $timeSpent.ToString() + 'm","comment": "' + $description + '"}'

    $Result = Invoke-RestMethod -URI $uri -Method Post -Headers $jira_headers  -ContentType "application/json" -Body $body
}
#close ticket
Function Jira-ResolveTicket {
    param([string]$ticketId,[PSCredential]$credentials)

    $jira_headers = Get-HttpBasicHeader $credentials

    $uri = $jiraUrl + $ticketId + "/transitions"

    $transitions =  Invoke-RestMethod -URI $uri -Method Get -Headers $jira_headers  -ContentType "application/json" 
    $transitionId = ($transitions.transitions | ? {$_.name -like 'Resolve Issue'}).id

    $body = ' {"transition": {"id": "' + $transitionId + '"}}'

    Invoke-RestMethod -URI $uri -Method Post -Headers $jira_headers  -ContentType "application/json" -Body $body
}
Function Jira-ReopenTicket {
    param([string]$ticketId,[PSCredential]$credentials)

    $jira_headers = Get-HttpBasicHeader $credentials

    $uri = $jiraUrl + $ticketId + "/transitions"

    $transitions =  Invoke-RestMethod -URI $uri -Method Get -Headers $jira_headers  -ContentType "application/json" 
    $transitionId = ($transitions.transitions | ? {$_.name -like 'Reopen Issue'}).id

    $body = ' {"transition": {"id": "' + $transitionId + '"}}'

    Invoke-RestMethod -URI $uri -Method Post -Headers $jira_headers  -ContentType "application/json" -Body $body
    }

Function Jira-CloseTicket {
    param([string]$ticketId,[PSCredential]$credentials)

    $jira_headers = Get-HttpBasicHeader $credentials

    $uri = $jiraUrl + $ticketId + "/transitions"
    $transitions =  Invoke-RestMethod -URI $uri -Method Get -Headers $jira_headers  -ContentType "application/json" 
    $transitionId = ($transitions.transitions | ? {$_.name -like 'Close Issue'}).id
    $body = ' {"transition": {"id": "' + $transitionId + '"}}'
    Invoke-RestMethod -URI $uri -Method Post -Headers $jira_headers  -ContentType "application/json" -Body $body
}


#To do everything at the same time
Function Jira-CreateLogClose {
    param([string]$subject,[string]$description,[int]$timeSpent,[PSCredential]$credentials)

    $ticket = Jira-CreateTicket -subject $subject -body $description -credentials $credentials

    write-host ("Created ticket: " + $ticket) -ForegroundColor Green
    Jira-AddLabel -ticketId $ticket -credentials $credentials
    Jira-LogWork -ticketId $ticket -timeSpent $timeSpent -description $description -credentials $credentials
    Jira-ResolveTicket -ticketId $ticket -credentials $credentials
    Jira-CloseTicket -ticketId $ticket -credentials $credentials

    $ticket
}