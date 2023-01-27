<#
    .SYNOPSIS
    Starts a phish pullback.
    
    .DESCRIPTION
    Builds an email pullback search and can kick off a message purge if specified.
    
    .PARAMETER Ticket
    Cherwell ticket prompting the request. This will be used for the search name.
    
    .PARAMETER SearchName
    In lieu of a ticket number, a custom search name can be used.

    .PARAMETER Sender
    The sender address of the email to be searched.

    .PARAMETER Subject
    The message subject of the email to be searched.

    .PARAMETER SentAfter
    Search for message sent after this time.

    .PARAMETER SentBefore
    Search for message sent before this time.

    .PARAMETER FileExtension
    File extention to search for if applicable.

    .PARAMETER AutoPurge
    This will check the status of the search every three minutes and begin a purge upon completion.
    
    .EXAMPLE
    New-PhishPullbackRequest -Ticket 11223344 -Sender "al.gator@ufl.edu" -Subject "Do not open" -SentAfter "March 7 2022 7:00 AM" -AutoPurge
    New-PhishPullbackRequest -Ticket 11223355 -Sender "al.gator@ufl.edu" -Subject "Please close" -SentBefore "March 5 2022 8:00 AM" -FileExtenion PDF
    New-PhishPullbackRequest -SearchName "Pullback test" -Sender gl@ufl.edu -Subject "Not a test" -SentAfter "March 3 2022 7:00 AM" -SentBefore "March 3 2022 8:00 AM"
    
    .COMPONENT
    Requires Compliance Admin access in Office 365

    .NOTES
    Created on:     2022-03-07
    Created by:     Tony Raccioppi
    Organization:   University of Florida   
#>

function New-PhishPullbackRequest {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true,
            ParameterSetName = "Ticket")]
        [int]$Ticket,
        [Parameter(Mandatory = $true,
            ParameterSetName = "SearchName")]
        [string]$SearchName,
        [Parameter(Mandatory = $true)]
        [string]$Sender,
        [Parameter(Mandatory = $true)]
        [string]$Subject,
        [datetime]$SentAfter,
        [datetime]$SentBefore,
        [string]$FileExtension,
        [switch]$AutoPurge
    )

    # Validate input and set KQL format
    # KQL example string:
    # (c:c)(senderauthor="gatorlink@ufl.edu")(subjecttitle="Don't open this")(sent>2022-02-22T10:00:00)(filetype=pdf)

    if ($Ticket) {
        $SearchName = "Phish pullback $Ticket"
    }
    try {
        $null = [mailaddress]$Sender 
        $KQLSender = "(senderauthor=""$Sender"")"
    }
    catch {
        Write-Warning "'$Sender' isn't a valid email address. Exiting."
        break
    }
    $KQLCondition = "(c:c)"
    $KQLSubject = "(subjecttitle=""$Subject"")"
    if ($SentBefore) {
        $FormatSentBefore = Get-Date $SentBefore -Format "yyyy-MM-ddTHH:mm:ss"
        $KQLSentBefore = "(sent<$FormatSentBefore)"
    }
    if ($SentAfter) {
        $FormatSentAfter = Get-Date $SentAfter -Format "yyyy-MM-ddTHH:mm:ss"
        $KQLSentAfter = "(sent>$FormatSentAfter)"
    }
    if (($FormatSentBefore) -and ($FormatSentAfter)) {
        if ($FormatSentBefore -lt $FormatSentAfter) {
            Write-Warning "$FormatSentBefore is before $FormatSentAfter. Exiting script..."
            break
        }
    }
    if ($FileExtension) {
        $ExtRegex = "^[a-zA-Z0-9]*$"
        if ($FileExtension -like ".*") {
            $FileExtension = $FileExtension.Split('.')[1]
        }
        if ($FileExtension -notmatch $ExtRegex) {
            Write-Output "Invalid extension '$FileExtension'. Excluding from search."
            $FileExtension = $null
        }
        $KQLExtension = "(filetype=$FileExtension)"
    }

    $KQLQuery = $KQLCondition + $KQLSender + $KQLSubject + $KQLSentAfter + $KQLSentBefore + $KQLExtension

    # See if there's already a connection and connect if there isn't.
    if (!(Get-PSSession | Where-Object { ($_.ComputerName -like "*compliance.protection.out*") -and ($_.State -eq "Opened") })) {
        Write-Output "Connecting to Compliance Center. Please sign in with a Compliance Admin account."
        Connect-IPPSSession 
    }
    try { $null = Get-RetentionCompliancePolicy }
    catch {
        Write-Warning "Connection to Compliance Center failed. Exiting script..."
        break 
    }

    # Launch our compliance search
    New-ComplianceSearch -Name $SearchName -ExchangeLocation "All" -ContentMatchQuery $KQLQuery
    Start-ComplianceSearch -Identity $SearchName

    # Check search status every 3 minutes and start a purge if 'AutoPurge' was set
    if ($AutoPurge) {
        Write-Output "AutoPurge set. This will start a purge when the search is complete."
        do { 
            Start-Sleep -Seconds 180
            $CurStatus = (Get-ComplianceSearch -Identity $SearchName).Status
            if ($CurStatus -ne "Completed") {
                Write-Output "Status for $SearchName is $CurStatus. Checking again in 3 minutes ..."
            }
        } 
        Until ($CurStatus -eq "Completed")
        $FinishedTime = Get-Date -Format "yyyy-MM-dd HH:mm"
        Write-Output "$SearchName completed at $FinishedTime. Starting the purge."
        New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType SoftDelete -Confirm:$False
    }  
} 