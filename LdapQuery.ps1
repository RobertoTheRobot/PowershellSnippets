Function Get-LdapUserGroupsOfNames {
    param([string]$username)
    $res = $null
    $ldapPath = 'LDAP://XXXXXXXXXXXXXXX:636/dc=XXXXXX,dc=com'
    $directoryEntry = [System.DirectoryServices.DirectoryEntry]::new($ldapPath,$null,$null,"FastBind");
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher($directoryEntry);
    [Void]$directorySearcher.PropertiesToLoad.Add("*");
    $directorySearcher.Filter = "((cn=$username))"
    $res = $directorySearcher.FindAll() 
    if($res.count -eq 0)
    {
        Write-Host "User not found" -ForegroundColor Yellow
    } else {
        $res | ForEach-Object { $_.Properties.member } | Select-Object -Unique       
    }
}


Function Get-LdapUserPosixGroups {
    param([string]$username)
    $res = $null
    $ldapPath = 'LDAP://XXXXXXXXXXXXXXX:636/dc=XXXXXX,dc=com'
    $directoryEntry = [System.DirectoryServices.DirectoryEntry]::new($ldapPath,$null,$null,"FastBind");
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher($directoryEntry);
    [Void]$directorySearcher.PropertiesToLoad.Add("*");
    $directorySearcher.Filter = "((memberUid=$username))"
    $res = $directorySearcher.FindAll() 
    if($res.count -eq 0)
    {
        Write-Host "User not found" -ForegroundColor Yellow
    }
    else
    {                    
        $res | Foreach-Object { $_.Properties.cn } | Select-Object -Unique
    }
}


Function Get-LdapPosixGroupMembers {
    param([string]$groupname)
    $res = $null
    $ldapPath = 'LDAP://XXXXXXXXXXXXXXX:636/dc=XXXXXX,dc=com'
    $directoryEntry = [System.DirectoryServices.DirectoryEntry]::new($ldapPath,$null,$null,"FastBind");
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher($directoryEntry);
    [Void]$directorySearcher.PropertiesToLoad.Add("*");
    $directorySearcher.Filter = "((cn=$groupname))"
    $res = $directorySearcher.FindAll() 
    if($res.count -eq 0)
    {
        Write-Host "User not found" -ForegroundColor Yellow
    }
    else
    {
        Write-Host "Group found" -ForegroundColor Green
        Write-Host "Members:"
        $res | Foreach-Object { $_.Properties.memberuid.count }
    }
}
