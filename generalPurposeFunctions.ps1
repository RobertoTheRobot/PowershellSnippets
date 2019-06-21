function Get-FileMetaData {  
    Param([string[]]$folder) 
    foreach($sFolder in $folder) 
        { 
        $a = 0 
        $objShell = New-Object -ComObject Shell.Application 
        $objFolder = $objShell.namespace($sFolder) 
        
        foreach ($File in $objFolder.items()) 
        {  
            $FileMetaData = New-Object PSOBJECT 
            for ($a ; $a  -le 266; $a++) 
            {  
                if($objFolder.getDetailsOf($File, $a)) 
                { 
                    $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  = 
                        $($objFolder.getDetailsOf($File, $a)) } 
                $FileMetaData | Add-Member $hash 
                $hash.clear()  
                } #end if 
            } #end for  
            $a=0 
            $FileMetaData 
        } #end foreach $file 
    } #end foreach $sfolder 
} 
   
function Get-ClipboardText(){
    Add-Type -AssemblyName System.Windows.Forms
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Multiline = $true
    $tb.Paste()
    ($tb.Text).Split("`n")
}

function Send-Email {
    param ([string] $sendTo, [string] $Subject ,[string] $body)
    $UserEmail = "noreply@myDomain.com"
    $smtpserver = "{smtpServerName}"
    
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($UserEmail,$sendTo,$Subject,$body)
    
}

function Convert-DiacriticCharacters {
    param(
        [string]$inputString
    )
    [string]$formD = $inputString.Normalize(
            [System.text.NormalizationForm]::FormD
    )
    $stringBuilder = new-object System.Text.StringBuilder
    for ($i = 0; $i -lt $formD.Length; $i++){
        $unicodeCategory = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($formD[$i])
        $nonSPacingMark = [System.Globalization.UnicodeCategory]::NonSpacingMark
        if($unicodeCategory -ne $nonSPacingMark){
            $stringBuilder.Append($formD[$i]) | out-null
        }
    }
    $stringBuilder.ToString().Normalize([System.text.NormalizationForm]::FormC)
}

function Convert-ToLatinCharacters {
    param([string]$inputString)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($inputString))
}

function Convert-IpToHexArray {
    param ([string]$ip)

    $ipArray = $ip.ToCharArray()
    $hexArr=@()

    $ipArray | ForEach-Object { $hexArr += "0x" + [Convert]::ToString([byte][char]$_,16) }

    return $hexArr
}