
Function Encrypt-Message {
    param(
     [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $false)] [string]$certificate_cn
    ,[Parameter(Position=1, Mandatory=$true, ValueFromPipeline = $true)][string]$message
    )

    Begin
    {
        $Cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=$certificate_cn*"}
    }
    Process
    {
        $encoded_message = [system.text.encoding]::UTF8.GetBytes($message)
        $encryptedBytes = $Cert.PublicKey.Key.Encrypt($encoded_message, $true)
        $encrypted_message = [System.Convert]::ToBase64String($encryptedBytes)
    }
    End
    {
        return $encrypted_message
    }
}

Function Decrypt-Message {
    param(
     [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $false)] [string]$certificate_cn
    ,[Parameter(Position=1, Mandatory=$true, ValueFromPipeline = $true)][string]$message
    )
    Begin
    {
        $Cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=$certificate_cn*"}
    }
    Process
    {
        $encryptedBytes = [System.Convert]::FromBase64String($message)
        $decryptedBytes = $Cert.PrivateKey.Decrypt($encryptedBytes, $true)
        $decrypted_message = [system.text.encoding]::UTF8.GetString($decryptedBytes)
    }
    End
    {
        return $decrypted_message
    }
}


# TEST:
# 
# $a = Encrypt-Message -certificate_cn localhost -message "this is a test"
# 
# Decrypt-Message -certificate_cn localhost -message $a
