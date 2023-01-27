
<#
    .SYNOPSIS
    Get SSL/TLS certificate information.
    
    .DESCRIPTION
    Get the SSL/TLS certificate information from a host using the OpenSSL utility.
    
    .PARAMETER Server
    FQDN or IP of the server to check. Host:port is acceptable input here.

    .PARAMETER Port
    The port of the service to check. Port 443 (HTTPS) is checked by default if this parameter is not specified.

    .EXAMPLE
    Get-CertInfo -Server www.google.com
    Get-CertInfo -Server ldap.domain.com -Port 636
    Get-CertInfo -Server ldap.domain.com:636
    Get-CertInfo 23.44.91.78
    
    .COMPONENT
    Requires OpenSSL to be installed. The script will check for it in: the PATH variable, Git default install path, and OpenSSL default install path.

    .NOTES
    Created on:     2022-11-17
    Created by:     tracci
    Organization:   public  
#>

function Get-CertInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Server,
        [int]$Port
    )
    Begin {
        # OpenSSL variables
        $NoTrace = Set-PSDebug -Trace 0
        $OpenSSL = Get-OpenSSLPath

        # Regex to get the data output from OpenSSL
        $NotBeforeRegex = [regex]"(?<=notBefore=)(.*)"
        $NotAfterRegex = [regex]"(?<=notAfter=)(.*)"
        $SerialRegex = [regex]"(?<=serial=)(.*)"
        $FPRegex = [regex]"(?<=SHA1 Fingerprint=)(.*)"
        $CNRegex = [regex]"(?<=CN = )(.*)"
    }
    Process {
        if ($Server -match ":") {
            try { [int]$Port = $Server.Split(':')[1] }
            catch { 
                Write-Warning "Invalid server input: $Server"
                break
            }
            $Server = $Server.Split(':')[0]
        }
        if (!($Port)) {
            [int]$Port = 443
        }
        $ConnectTo = $Server + ":" + $Port
        $CertInfo = $NoTrace | . $OpenSSL s_client -connect $ConnectTo 2>$null | . $OpenSSL x509 -noout -dates -subject -issuer -serial -fingerprint 2>$null
        if ($CertInfo) {
            if ($CertInfo.Count -eq 6) {

                # Make the data more presentable if we have the expected results
                $NotBeforeDate = Convert-CertTime -CertDate ($NotBeforeRegex.Matches($CertInfo[0])).Value
                $NotAfterDate = Convert-CertTime -CertDate ($NotAfterRegex.Matches($CertInfo[1])).Value
                $Subject = ($CNRegex.Matches($CertInfo[2])).Value
                $Issuer = ($CNRegex.Matches($CertInfo[3])).Value
                $Serial = ($SerialRegex.Matches($CertInfo[4])).Value
                $Fingerprint = (($FPRegex.Matches($CertInfo[5])).Value).Replace(":", "")
                $DaysToExpire = ((Get-Date $NotAfterDate) - (Get-Date)).Days
                
                # Note the time left until the certificate expires
                if ($DaysToExpire -lt 0) {
                    $Notice = "This certificate is expired!"
                }
                elseif ($DaysToExpire -eq 0) {
                    $Notice = "This certificate expires within 24 hours!"
                }
                elseif ($DaysToExpire -eq 1) {
                    $Notice = "This certificate expires in 1 day!"
                }
                else {
                    $Notice = "This certificate expires in $DaysToExpire days."
                }

                # Build a custom object for output
                $CertOutput = [PSCustomObject]@{
                    Subject     = $Subject
                    NotBefore   = $NotBeforeDate + " GMT"
                    NotAfter    = $NotAfterDate + " GMT"
                    Issuer      = $Issuer
                    Serial      = $Serial
                    Fingerprint = $Fingerprint
                    Notice      = $Notice
                }
                $CertOutput | Format-List
            }
            else {
                # Display the raw OpenSSL output if we have data but it's different than expected
                Write-Output "`r`nCertificate details for $ConnectTo :`r`n"
                $CertInfo
            }
        }
        else {
            Write-Output "`r`nNo certificate found for $ConnectTo."
        }
    }
}


<#
    .DESCRIPTION
    Looks for OpenSSL in the PATH variable, Git default install path, or OpenSSL default install path.
#>
function Get-OpenSSLPath {
    try {
        Set-PSDebug -Trace 0 | openssl version 1>$null
        $OpenSSLPath = $true 
    }
    catch { $OpenSSLPath = $false }
    if ($OpenSSLPath) {
        $OpenSSL = "openssl.exe"
    }
    else {
        $Paths = (
            "C:\Program Files\Git\usr\bin\openssl.exe",
            "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
        )
        foreach ($p in $Paths) {
            if (Test-Path $p) {
                $OpenSSL = $p
            }
        }
    }
    if (!($OpenSSL)) {
        Write-Warning "OpenSSL not found. If OpenSSL is installed, include it in your 'path' environment variable. Exiting."
        break
    }
    $OpenSSL
}

<#
    .DESCRIPTION
    Converts the certificate date/times into a format readable by PowerShell
#>
function Convert-CertTime {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$CertDate
    )
    Process {
        $CertDateArray = $CertDate.Split(' ')
        if ( ($CertDateArray).Count -gt 5 ) {
            $CertDateArray = $CertDateArray.Split('', [System.StringSplitOptions]::RemoveEmptyEntries)
        }
        if ( ($CertDateArray).Count -eq 5) {
            $ExpCertMo = $CertDateArray.Split(' ')[0]
            $ExpCertDay = $CertDateArray.Split(' ')[1]
            $ExpCertTime = $CertDateArray.Split(' ')[2]
            $ExpCertYear = $CertDateArray.Split(' ')[3]
            $FormattedDate = Get-Date "$ExpCertMo/$ExpCertDay/$ExpCertYear $ExpCertTime" -Format "yyyy-MM-dd HH:mm:ss"
        }
        else {
            Write-Warning "Cert date had fewer than the expected five values provided."
            break
        }
        $FormattedDate
    }
}