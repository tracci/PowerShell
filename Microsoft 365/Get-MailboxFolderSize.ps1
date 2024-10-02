# Check for modules
#Requires -Modules @{ ModuleName="ExchangeOnlineManagement"; ModuleVersion="3.0.0" }

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

        .PARAMETER Archive
        If this is active, the report will generate folders from the user's archive mailbox.

        .PARAMETER ResultSize
        Set the folder result size. Default is 1000 folders. Use "Unlimited" to output all folders without limit.

        .EXAMPLE
        Get-MailboxFolderSize -Mailbox alb.sure@domain.com
        Get-MailboxFolderSize -Mailbox alb.sure@domain.com -FolderScope RecoverableItems
        Get-MailboxFolderSize -Mailbox alb.sure@domain.com -FolderScope Inbox -OutputAs GB -HideEmptyFolders
        Get-MailboxFolderSize -Mailbox alb.sure@domain.com -Archive
        Get-MailboxFolderSize -Mailbox alb.sure@domain.com -FolderScope All -OutputAs MB -HideEmptyFolders -ResultSize Unlimited
    
        .COMPONENT
        Requires ExchangeOnline module 3.0.0 or later for the Get-ConnectionInformation check

        .NOTES
        Created on:     2022-10-18
        Created by:     tracci
        Organization:   public 
    #>
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
        [switch]$HideEmptyFolders,
        [switch]$Archive,
        [string]$ResultSize
    )

    # Set some default values if not provided
    if ([string]::IsNullOrEmpty($FolderScope)) { $FolderScope = "All" }
    if ([string]::IsNullOrEmpty($OutputAs)) { $OutputAs = "MB" }
    if ([string]::IsNullOrEmpty($SortBy)) { $SortBy = "Size" }
    if ([string]::IsNullOrEmpty($ResultSize)) { $ResultSize = 1000 }

    $AllOutput = New-Object System.Collections.ArrayList

    if (!(Get-ConnectionInformation | Where-Object { $_.State -eq "Connected" })) {
        Connect-ExchangeOnline
    }

    if ($ResultSize -ne 'Unlimited') {
        try { $ResultSize = [int]::Parse($ResultSize) }
        catch {
            Write-Warning $_.Exception.Message 
            break
        }
        if ($ResultSize -le 0) {
            Write-Error "ResultSize must be greater than 0"
            break
        }
    }

    $FolderParams = @{
        Identity    = $Mailbox
        FolderScope = $FolderScope
        ResultSize  = $ResultSize
        ErrorAction = "Stop"
    }
    
    if ($Archive) {
        $ArchiveStatus = (Get-Mailbox $Mailbox).ArchiveDatabase
        if ($ArchiveStatus) {
            $FolderParams.Add("Archive", $true)
        }
        else { Write-Output "Archive mailbox not found for $Mailbox. Getting results for active mailbox..." }
    }
    
    $MinItems = 0
    if ($HideEmptyFolders) {
        $MinItems = 1
    }
   
    try { 
        $MBStats = Get-MailboxFolderStatistics @FolderParams |
        Where-Object { $_.ItemsInFolder -ge $MinItems } | 
        Select-Object Identity, FolderType, ItemsInFolder, FolderSize
    }
    catch { 
        Write-Warning "Error: $($_.Exception.Message)" 
        break
    }

    if ($MBStats) {
        if ($MBStats.Count -eq 1000) {
            Write-Warning "1000 folder limit. Use '-ResultSize Unlimited' for all folders."
        }
        foreach ($i in $MBStats) {
            $Converted = Convert-Bytes -FolderSize $i.FolderSize -OutputAs $OutputAs
            $MBOutput = [PSCustomObject]@{
                Folder                   = $i.Identity
                FolderType               = $i.FolderType
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
    else {
        Write-Output "No mailbox data found with those parameters."
    }
}