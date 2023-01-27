<#
    .SYNOPSIS
    Gets SMTP addresses set in AD and M365.
    
    .DESCRIPTION
    Grabs SMTP proxy addresses from an AD object, M365 email addresses from a mailbox, and outputs them.
    
    .PARAMETER Name
    SamAccountName of the user to check.
  
    .EXAMPLE
    Get-SMTPAddresses -Name alb.sure
    
    .COMPONENT
    Requires ActiveDirectory and ExchangeOnline modules

    .NOTES
    Created on:     2022-08-23
    Created by:     tracci
    Organization:   public 
#>

# Check for modules
#Requires -Modules ExchangeOnlineManagement, ActiveDirectory

function Get-SMTPAddresses {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    Process {

        $Addresses = New-Object System.Collections.ArrayList
        try { $ADInfo = Get-ADUser $Name -Properties ProxyAddresses }
        catch {
            Write-Warning "Error looking up $Name : $($_.Exception.Message)" 
            break
        }
        if (!($ADInfo.UserPrincipalName)) {
            Write-Warning "No UPN listed in AD for $Name."
            break
        }
        $ADProxies = $ADInfo.ProxyAddresses | Where-Object { $_ -like "smtp*" }
        try { $365Info = Get-Mailbox $ADInfo.UserPrincipalName -ErrorAction Stop }
        catch [System.Management.Automation.CommandNotFoundException] {
            Write-Warning "Command not found. Connecting to Exchange Online..."
            Connect-ExchangeOnline
            Write-Output "Please rerun the command for M365 addresses."
        }
        catch {
            Write-Warning "Didn't find an M365 mailbox for $($ADInfo.UserPrincipalName)"
        }
        $365Addresses = $365Info.EmailAddresses | Where-Object { $_ -like "smtp*" }

        if ($ADProxies) {
            foreach ($proxy in $ADProxies) {
                if ($proxy -cmatch "SMTP*") {
                    $Primary = $true
                }
                else {
                    $Primary = $false
                }
                $ADProtocol = $proxy.split(':')[0]
                $ADAddress = $proxy.split(':')[1]
                $ADProxyInfo = [PSCustomObject]@{
                    Source   = "AD"
                    Protocol = $ADProtocol
                    Address  = $ADAddress
                    Primary  = $Primary
                }
                $null = $Addresses.Add($ADProxyInfo)
            }
        }
        if ($365Addresses) {
            foreach ($add in $365Addresses) {
                if ($add -cmatch "SMTP*") {
                    $Primary = $true
                }
                else {
                    $Primary = $false
                }
                $365Protocol = $add.split(':')[0]
                $365Address = $add.split(':')[1]
                $365EmailInfo = [PSCustomObject]@{
                    Source   = "M365"
                    Protocol = $365Protocol
                    Address  = $365Address
                    Primary  = $Primary
                }
                $null = $Addresses.Add($365EmailInfo)
            }
        }
        Write-Output "`r`nAddresses for $($ADInfo.UserPrincipalName):"
        $Addresses | Sort-Object Source, @{Expression = { $_.Primary }; Ascending = $False }, Address
    }
}