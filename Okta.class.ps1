enum OktaUserStatus {
    ACTIVE;
    PROVISIONED;
    STAGED;
    RECOVERY;
    DEPROVISIONED;
    PASSWORD_EXPIRED;
    LOCKED_OUT
}

Class Okta {
    <# 
    .SYNOPSIS 
    PS Object to manage Okta Rest API 
    .DESCRIPTION 
    Creates an Okta context object to be able to use Okta REST API.
        
    .EXAMPLE 
    $oktaContext = [Okta]::new($url,$apiKey)
    $oktaContext.GetUser($userId)
    $oktaContext.SearchGroupByType("OKTA_GROUP")
    #> 


    [string]$baseUrl
    [string]$apiKey
    [Hashtable]$headers


    # Constructor

    Okta([string]$baseUrl,[string]$apiToken) {
        $this.baseUrl = $baseUrl
        $this.apiKey = $apiToken

        $this.headers = @{}
        $this.headers.Add("Authorization",[string]::Format("SSWS {0}",$apiToken))
        $this.headers.Add("Accept","application/json")
        $this.headers.Add("Content-Type","application/json")

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }


    # Internal methods

    [PSCustomObject] invokeOktaAPIWithPagination ([string]$uriQuery,[Microsoft.PowerShell.Commands.WebRequestMethod]$Method) {

        $after = $null
        $limit = 1000
        $resultCount = 0
    
        $operator = "?"
        if($uriQuery.ToCharArray() -contains "?") { $operator = "&" }

        $result = New-Object System.Collections.ArrayList
               
        do {

            $uri = $this.baseUrl + $uriQuery + $operator + "limit=" + $limit
            if($after) 
            {
                $uri += ("&after=" + $after)
            }
            $res = Invoke-RestMethod -Uri $uri -Method $Method -Headers $this.headers

            $resultCount = $res.count

            if($resultCount -eq 1) 
            {
                [void]$result.Add($res)
            } 
            elseif ($resultCount -gt 1) 
            {
                [void]$result.AddRange($res)
                $after = $res[-1].id
            }

        } while($resultCount -eq $limit)
       
        return $result
      
    }


    # User Methods

    [PSCustomObject] GetUser([string]$userId) {
        # {{url}}/api/v1/users/{{userId}}

        $uri = [string]::Format("{0}/api/v1/users/{1}",$this.baseUrl,$userId)
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $this.headers                
    }

    [PSCustomObject] GetCurrentUser() {
        # {{url}}/api/v1/users/me

        $uri = [string]::Format("{0}/api/v1/users/me",$this.baseUrl)
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $this.headers                
    }

    [PSCustomObject] ListUsers() {
        # {{url}}/api/v1/users?limit=25

        return $this.invokeOktaAPIWithPagination("/api/v1/users","Get")              
    }

    [PSCustomObject] ListUsersByStatus([OktaUserStatus]$status) {
        # {{url}}/api/v1/users?filter=status eq "ACTIVE"&limit=25

        # status: ACTIVE / PROVISIONED / STAGED / RECOVERY / DEPROVISIONED / PASSWORD_EXPIRED / LOCKED_OUT

        $uriQuery = [string]::Format("/api/v1/users?filter=status eq `"{0}`"",$status)
        return $this.invokeOktaAPIWithPagination($uriQuery,"Get") 

    }

    [PSCustomObject] GetAssignedAppLinks([string]$userId) {
        # {{url}}/api/v1/users/{{userId}}/appLinks

        $uri = [string]::Format("{0}/api/v1/users/{1}/appLinks",$this.baseUrl,$userId)
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $this.headers                
    }

    [PSCustomObject] GetGroupsForUser([string]$userId) {
        # {{url}}/api/v1/users/{{userId}}/groups

        $uri = [string]::Format("{0}/api/v1/users/{1}/groups",$this.baseUrl,$userId)
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $this.headers                
    }

    [PSCustomObject] FindUser([string]$query) {
        # {{url}}/api/v1/users?q=user

        $uri = [string]::Format("{0}/api/v1/users?q={1}",$this.baseUrl,$query)
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $this.headers                
    }


    # Group Methods

    [PSCustomObject] GetGroup([string]$groupId) {
        # {{url}}/api/v1/groups/{{groupId}}

        $uri = [string]::Format("{0}/api/v1/groups/{1}",$this.baseUrl,$groupId)
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $this.headers                
    }

    [PSCustomObject] ListGroups() {
        # {{url}}/api/v1/groups/

       return $this.invokeOktaAPIWithPagination("/api/v1/groups/","Get")
    }

    [PSCustomObject] SearchGroup([string]$query) {
        # {{url}}/api/v1/groups?q=ever

        # not working for this request
        #$uriQuery = [string]::Format("/api/v1/groups?q={0}",$query)
        #return $this.invokeOktaAPIWithPagination($uriQuery,"Get")     
        
        $uri = [string]::Format("{0}/api/v1/groups?q={1}&limit=10000",$this.baseUrl,$query)
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $this.headers                  
    }

    [PSCustomObject] ListGroupByType([string]$type) {
        # {{url}}/api/v1/groups?filter=type eq "OKTA_GROUP"

        $uriQuery = [string]::Format("/api/v1/groups?filter=type eq `"{0}`"",$type)

        return $this.invokeOktaAPIWithPagination($uriQuery,"Get")             
    }

    [PSCustomObject] AddGroup([string]$name, [string]$description) {
        # {{url}}/api/v1/groups

        $uri = [string]::Format("{0}/api/v1/groups",$this.baseUrl)
        $profile = New-Object psobject -Property @{"name"=$name;"description"=$description}
        $body = New-Object psobject -Property @{"profile"=$profile}

        return Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json) -Headers $this.headers                
    }

    [PSCustomObject] UpdateGroup([string]$groupId, [string]$name, [string]$description) {
        # {{url}}/api/v1/groups/{{groupId}}

        $uri = [string]::Format("{0}/api/v1/groups/{1}",$this.baseUrl,$groupId)
        $profile = New-Object psobject -Property @{"name"=$name;"description"=$description}
        $body = New-Object psobject -Property @{"profile"=$profile}

        return Invoke-RestMethod -Uri $uri -Method Put -Body ($body | ConvertTo-Json) -Headers $this.headers                
    }

    [PSCustomObject] RemoveGroup([string]$groupId) {
        # {{url}}/api/v1/groups/{{groupId}}

        $uri = [string]::Format("{0}/api/v1/groups/{1}",$this.baseUrl,$groupId)

        return Invoke-RestMethod -Uri $uri -Method Delete -Headers $this.headers                
    }


    # Membership

    [PSCustomObject] AddUserToGroup([string]$userId,[string]$groupId) {
        # {{url}}/api/v1/groups/{{groupId}}/users/{{userId}}

        $uri = [string]::Format("{0}/api/v1/groups/{1}/users/{2}",$this.baseUrl,$groupId, $userId)
        return Invoke-RestMethod -Uri $uri -Method Put -Headers $this.headers                
    }

    [PSCustomObject] RemoveUserFromGroup([string]$userId,[string]$groupId) {
        # {{url}}/api/v1/groups/{{groupId}}/users/{{userId}}

        $uri = [string]::Format("{0}/api/v1/groups/{1}/users/{2}",$this.baseUrl,$groupId, $userId)
        return Invoke-RestMethod -Uri $uri -Method Delete -Headers $this.headers                
    }

    [PSCustomObject] ListGroupMembers([string]$groupId) {
        # {{url}}/api/v1/groups/{{groupId}}/users

        $uriQuery = [string]::Format("/api/v1/groups/{0}/users",$groupId)   
        return $this.invokeOktaAPIWithPagination($uriQuery,"Get")  
    }

    [PSCustomObject] ListUserGroups([string]$userId) {
        # {{url}}/api/v1/users/{{userId}}/groups

        $uriQuery = [string]::Format("/api/v1/users/{0}/groups",$userId)   
        return $this.invokeOktaAPIWithPagination($uriQuery,"Get")  
    }
}