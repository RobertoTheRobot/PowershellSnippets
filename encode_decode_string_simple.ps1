
# Simple encode / decode message functions


function Add-LeftPad ($str, $len, $pad) {
    if(($len + 1) -ge $str.Length) {
        while (($len - 1) -ge $str.Length) {
            $str = ($pad + $str)
        }
    }
    return $str ;
}

function EncodeMessage {
    param([string] $message, [string] $password)
    
    $keyPadded = Add-LeftPad $password 32 "0"
    $keyBytes = [system.Text.Encoding]::UTF8.GetBytes($keyPadded)
     
    $secureString = ConvertTo-SecureString -String $message -AsPlainText -Force
    $codifiedMessage = $secureString | ConvertFrom-SecureString -Key $keyBytes
    
    $codifiedMessage
}

function DecodeMessage {
    param([string] $codifiedMessage, [string] $password)
    
    $keyPadded = Add-LeftPad $password 32 "0"
    $keyBytes = [system.Text.Encoding]::UTF8.GetBytes($keyPadded)
    
    $decodedMessage = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($codifiedMessage | ConvertTo-SecureString -Key ($keyBytes))))
    
    $decodedMessage
}


function StringToBase64 {
    param ([string] $str)
    [System.Convert]::ToBase64String([system.Text.Encoding]::UTF8.GetBytes($str))
}
    
function StringFromBase64 {
    param ([string] $str)
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($str))
}