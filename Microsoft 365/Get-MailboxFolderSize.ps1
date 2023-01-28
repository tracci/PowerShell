<#
    .SYNOPSIS
    Gets mailbox folder size for a user.
    
    .DESCRIPTION
    Gets mailbox folder size for a user and outputs as requested. Size can be output as KB, MB, GB, or TB to two decimal places.
    
    .PARAMETER Mailbox
    Email address of the mailbox to check.

    .PARAMETER FolderScope
    Which mailbox folder to check: All (default), Calendar, DeletedItems, Inbox, JunkEmail, RecoverableItems.

    .PARAMETER OutputAs
    Which units to display size as: MB (default), KB, GB, or TB.

    .PARAMETER SortBy
    How to sort the output: Size (default), Items, or Folder

    .PARAMETER HideEmptyFolders
    If this is active, the report will exclude any folders where 'ItemsInFolder' is zero.

    .EXAMPLE
    Get-MailboxFolderSize -Mailbox alb.sure@domain.com
    Get-MailboxFolderSize -Mailbox alb.sure@domain.com -FolderScope RecoverableItems
    Get-MailboxFolderSize -Mailbox alb.sure@domain.com -FolderScope Inbox -OutputAs GB -HideEmptyFolders
    
    .COMPONENT
    Requires ExchangeOnline module v2.0.6-Preview7 or later for the Get-ConnectionInformation check

    .NOTES
    Created on:     2022-10-18
    Created by:     tracci
    Organization:   public 
#>

# Check for modules
#Requires -Modules @{ ModuleName="ExchangeOnlineManagement"; ModuleVersion="2.0.6" }

function Convert-Bytes {
    # This function is to convert the ExchangeOnline size output to an integer that we can work with.
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$FolderSize,
        [Parameter(Mandatory)]
        [ValidateSet("KB", "MB", "GB", "TB")]
        [string]$OutputAs
    )
    $ConvertTo = "1$OutputAs"
    $Regex = "(?<=\()(.*)(?=\))"                    # Get our bytes between the parentheses
    if ($FolderSize -match $Regex) {
        $Bytes = ($Matches[0]).Split(" ")[0]        # Split to remove 'bytes'
    }
    else {
        Write-Warning "No data"
        break
    }
    $TotBytes = $Bytes -replace ',', ''             # Remove commas to give us an integer
    [math]::Round(($TotBytes / $ConvertTo), 2)      # Convert to our output and round to two decimal places
}

function Get-MailboxFolderSize {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Mailbox,
        [ValidateSet("All", "Calendar", "DeletedItems", "Inbox", "JunkEmail", "RecoverableItems")]
        [string]$FolderScope,
        [ValidateSet("KB", "MB", "GB", "TB")]
        [string]$OutputAs,
        [ValidateSet("Folder", "Items", "Size")]
        [string]$SortBy,
        [switch]$HideEmptyFolders
    )

    # Set some default values if not provided
    if ([string]::IsNullOrEmpty($FolderScope)) { $FolderScope = "All" }
    if ([string]::IsNullOrEmpty($OutputAs)) { $OutputAs = "MB" }
    if ([string]::IsNullOrEmpty($SortBy)) { $SortBy = "Size" }

    $AllOutput = New-Object System.Collections.ArrayList

    if (!(Get-ConnectionInformation | Where-Object { $_.State -eq "Connected" })) {
        Connect-ExchangeOnline
    }

    if ($HideEmptyFolders) {
        try { 
            $MBStats = Get-ExoMailboxFolderStatistics $Mailbox -FolderScope $FolderScope -ErrorAction Stop | 
            Where-Object { $_.ItemsInFolder -gt 0 } | 
            Select-Object FolderPath, ItemsInFolder, FolderSize
        }
        catch { Write-Warning "Error: $($_.Exception.Message)" }
    }
    else {
        try { 
            $MBStats = Get-ExoMailboxFolderStatistics $Mailbox -FolderScope $FolderScope -ErrorAction Stop | 
            Select-Object FolderPath, ItemsInFolder, FolderSize
        }
        catch { Write-Warning "Error: $($_.Exception.Message)" }
    }
    if ($MBStats) {
        foreach ($i in $MBStats) {
            $Converted = Convert-Bytes -FolderSize $i.FolderSize -OutputAs $OutputAs
            $MBOutput = [PSCustomObject]@{
                Folder                   = "$Mailbox/Inbox$($i.FolderPath)"
                ItemsInFolder            = $i.ItemsInFolder
                "FolderSize ($OutputAs)" = $Converted
            }
            $null = $AllOutput.Add($MBOutput)
        }
        switch ($SortBy) {
            "Folder" { $AllOutput | Sort-Object Folder }
            "Items" { $AllOutput | Sort-Object ItemsInFolder -Descending }
            "Size" { $AllOutput | Sort-Object "FolderSize ($OutputAs)" -Descending }
        }
    }
}