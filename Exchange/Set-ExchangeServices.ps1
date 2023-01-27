<#
    .SYNOPSIS
    Resets Exchange Services to start properly to address a known issue with Exchange patches.
    
    .DESCRIPTION
    Resets Exchange Services to start properly to address an issue with patches that cause the services to disable.
    Example known issue reports. 
    March 2021:
    https://support.microsoft.com/en-us/topic/description-of-the-security-update-for-microsoft-exchange-server-2019-2016-and-2013-march-2-2021-kb5000871-9800a6bb-0a21-4ee7-b9da-fa85b3e1d23b
    March 2022:
    https://support.microsoft.com/en-us/topic/description-of-the-security-update-for-microsoft-exchange-server-2013-march-8-2022-kb5010324-1cc1891e-5be1-4ee1-abad-3f3acbb82f9c
 
    .EXAMPLE
    Run this administratively to reset the services properly and then start them in order.
    
    .NOTES
    Created on:     2021-03-04
    Created by:     Pastebin "guest"
    Updated on:     2022-03-09
    Updated by:     tracci
    Organization:   public
    
    Script was originally posted to Pastebin and modified by tracci. Pastebin source is here:
    https://pastebin.com/ccVqupyb
#>

#Requires -RunAsAdministrator

try { Get-Service "MSExchangeServiceHost" -ErrorAction Stop }
catch { 
   Write-Output "Exchange Service Host not found. Please make sure this is run on an Exchange server."
   Write-Output "Stopping script..."
   break
}

# List of services that should start automatically
$AutoStart = (
    "MSExchangeADTopology",             # Active Directory Topology
    "MSExchangeAntispamUpdate",         # Anti-Spam Update
    "MSExchangeDagMgmt",                # DAG Management
    "MSExchangeDiagnostics",            # Diagnostics
    "MSExchangeEdgeSync",               # EdgeSync
    "MSExchangeFrontEndTransport",      # Frontend Transport
    "MSExchangeHM",                     # Health Manager
    "MSExchangeImap4",                  # IMAP4
    "MSExchangeIMAP4BE",                # IMAP4 Backend
    "MSExchangeIS",                     # Information Store
    "MSExchangeMailboxAssistants",      # Mailbox Assistants
    "MSExchangeMailboxReplication",     # Mailbox Replication
    "MSExchangeDelivery",               # Mailbox Transport Delivery
    "MSExchangeSubmission",             # Mailbox Transport Submission
    "MSExchangeRepl",                   # Replication
    "MSExchangeRPC",                    # RPC Client Access
    "MSExchangeFastSearch",             # Search
    "HostControllerService",            # Exchange Search Host Controller
    "MSExchangeServiceHost",            # Service Host
    "MSExchangeThrottling",             # Throttling
    "MSExchangeTransport",              # Transport
    "MSExchangeTransportLogSearch",     # Transport Log Search
    "MSExchangeUM",                     # Unified Messaging
    "MSExchangeUMCR",                   # Unified Messaging Call Router
    "FMS",                              # Microsoft Filtering Management Service
    "IISADMIN",                         # IIS Admin Service
    "RemoteRegistry",                   # Remote Registry
    "SearchExchangeTracing",            # Tracing Service for Search in Exchange
    "Winmgmt",                          # Windows Management Instrumentation
    "W3SVC"                             # World Wide Web Publishing Service
)

# List of services that should start manually
$ManualStart = (
    "MSExchangePop3",                   # POP3
    "MSExchangePOP3BE",                 # POP3 Backend
    "wsbexchange",                      # Exchange Server Extension for Windows Server Backup
    "AppIDSvc",                         # Application Identity
    "pla"                               # Performance Logs & Alerts
)

# Enable and start services
foreach ($x in $AutoStart) {
    Set-Service -Name $x -StartupType Automatic
    Write-Output "Enabling $x as automatic start..."
}

foreach ($y in $ManualStart) {
    Set-Service -Name $y -StartupType Manual
    Write-Output "Enabling $y as manual start..."
}

foreach ($z in $AutoStart) {
    Start-Service -Name $z
    Write-Output "Starting $z..."
}