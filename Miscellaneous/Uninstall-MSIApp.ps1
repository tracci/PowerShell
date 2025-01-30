<#
    .SYNOPSIS
    Uninstalls an application installed via MSI.
    
    .DESCRIPTION
    Uninstalls an application installed via MSI, using information found in the
    registry. It will stop a process if specified and then uninstall any versions 
    of the application. Log file is placed in the %TEMP% folder of the user running
    the script.
    
    .PARAMETER AppName
    AppName is the name of the application, as outlined by the "Display Name" from the MSI.
    Example: "Cherwell Client" (Cherwell app)
    
    .PARAMETER Process
    The name of the process to stop prior to the uninstall, as outlined by the "ProcessName" value.
    Example: "Trebuchet.App" (Cherwell proc)
    
    .EXAMPLE
    Uninstall-Application -AppName "Cherwell Client"
    Uninstall-Application -AppName "Cherwell Client" -Process "Trebuchet.App"
    
    .COMPONENT
    Requires the application to have been installed via MSI.

    .NOTES
    Created on:     2021-11-10
    Created by:     tracci
    Organization:   public
#>

Function Uninstall-Application {

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [string]$Process
    )
    Process {
        $Timestamp = Get-Date -Format "yyyy-MM-dd_THHmmss"
        $LogFile = "$env:TEMP\$Timestamp-$AppName.log"
        $ProgramList = @( 
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", 
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" 
        )
        $Programs = Get-ItemProperty $ProgramList -EA 0
        $App = ($Programs | Where-Object { $_.DisplayName -eq $AppName -and $_.UninstallString -like "*msiexec*" }).PSChildName

        if ($Process) {
            try { Get-Process -Name $Process -ErrorAction Stop }
            catch { Write-Warning "$Process is not currently running. Continuing to uninstall..." }
            Get-Process | Where-Object { $_.ProcessName -eq $Process } | Stop-Process -Force
        }

        if ($App) {
            foreach ($a in $App) {
                $Params = @(
                    "/qn"
                    "/norestart"
                    "/X"
                    "$a"
                    "/L*V ""$LogFile"""
                )
                Start-Process "msiexec.exe" -ArgumentList $Params -Wait -NoNewWindow
            }
        }
        else {
            Write-Warning "$AppName not found. No changes made."
        }
    }
}