

function Test-Credentials {
    $cred = Get-Credential #Read credentials
    $username = $cred.username
    $password = $cred.GetNetworkCredential().password
    
    # Get current domain using logged-on user's credentials
    $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
    $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)
    
    if ($null -eq $domain.name)
    {
        write-host "Authentication failed."
    }
    else
    {
        write-host ("Successfully authenticated with domain " + $domain.name)
    }
}

function Search-ByBitLockerKey {
    param([string]$key)
    
    # Example: SearchByBitLockerKey 5E75ECD5
    
    $BitLockerObjects = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -Properties 'msFVE-RecoveryPassword'
    $BitLockerObjects | Where-Object { $_.DistinguishedName -like ("*" + $key + "*")}
}

function Get-LocalDC ($domain) {
    	
	$ErrorActionPreference = 'SilentlyContinue'
	
    if ($domain)
    {
        $DomainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $domain)
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
        
        $Socks = New-Object System.Net.Sockets.TCPClient
        # Try 389
        $Connect = $Socks.BeginConnect(($Domain.FindDomainController()).name,389,$null,$null)
	
        #$TTWait = 
        $Connect.AsyncWaitHandle.WaitOne(250,$False) 
		
        If ($Socks.Connected) 
        {		
			return ($Domain.FindDomainController()).name
			$Null = $Socks.Close()
	    }
	}
	else
    {
    	$LocalDCs = ([System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()).Servers| Where-Object { $_.Domain -match $domain }    	
    	
    	$potentials = @()    	
    	
        ForEach ($LocalDC in $LocalDCs) 
        {    		
    		$Socks = New-Object System.Net.Sockets.TCPClient  
    		$Connect = $Socks.BeginConnect($LocalDC.Name,389,$null,$null)
            #$TTWait = 
            $Connect.AsyncWaitHandle.WaitOne(250,$False)     
    		
            If ($Socks.Connected) 
            {    		
    			$potentials += $LocalDC.Name
    			$Null = $Socks.Close()
    		}
    	}
    	
    	$DC = $potentials | Get-Random    	

    	Return $DC
    }
}

