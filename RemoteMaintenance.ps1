<#
.SYNOPSIS
Remote Maintenance Script

.DESCRIPTION
This script performs remote maintenance tasks on multiple Windows Servers:
- Checks the status of installed services and generates a report.
- Installs software updates if the W32Time service is running.
- Reboots the server if required, with an option to schedule the reboot.
- Sets up a scheduled task to run this script weekly.

.PARAMETER Servers
List of servers to process.

.PARAMETER RebootOption
Option for rebooting: Now, Schedule, or Skip.

.PARAMETER RebootTime
Time to schedule the reboot if RebootOption is "Schedule".

.EXAMPLE
.\RemoteMaintenance.ps1 -Servers @("172.16.14.14") -RebootOption Schedule -RebootTime "2024-09-25T23:00:00"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string[]]$Servers = (172.16.14.14),
    [Parameter(Mandatory=$false)]
    [ValidateSet("Now", "Schedule", "Skip")]
    [string]$RebootOption = "Skip",
    [Parameter(Mandatory=$false)]
    [datetime]$RebootTime = (Get-Date).AddHours(1)
)

$ErrorActionPreference = "Stop"

$reportPath = "C:\Reports"

if (!(Test-Path $reportPath)) {
    New-Item -Path $reportPath -ItemType Directory
}

foreach ($server in $Servers) {
    Write-Host "Processing server: $server"

    Try {
        # Check the status of installed services
        $services = Get-Service -ComputerName $server
        # Output the services status to a CSV file
        $services | Select-Object Name, Status | Export-Csv -Path "$reportPath\$server-services.csv" -NoTypeInformation

        # Check if W32Time service is running
        $w32time = Get-Service -Name W32Time -ComputerName $server

        if ($w32time.Status -eq "Running") {
            Write-Host "W32Time service is running on $server. Installing software updates..."

            # Install software updates
            # Assuming PSWindowsUpdate module is installed on remote server
            Invoke-Command -ComputerName $server -ScriptBlock {
                Import-Module PSWindowsUpdate
                Get-WindowsUpdate -Install -AcceptAll -AutoReboot
            }
        } else {
            Write-Host "W32Time service is not running on $server. Skipping software updates."
        }

        # After updates, check if a reboot is required
        $rebootPending = Invoke-Command -ComputerName $server -ScriptBlock {
            $Pending = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) -ne $null
            return $Pending
        }

        if ($rebootPending) {
            Write-Host "Reboot is required on $server."

            switch ($RebootOption) {
                "Now" {
                    Restart-Computer -ComputerName $server -Force
                    Write-Host "$server is rebooting now."
                }
                "Schedule" {
                    # Create a scheduled task on the remote server to reboot at the specified time
                    $action = New-ScheduledTaskAction -Execute 'shutdown.exe' -Argument '-r -t 0'
                    $trigger = New-ScheduledTaskTrigger -Once -At $RebootTime
                    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
                    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
                    Register-ScheduledTask -TaskName "ScheduledReboot" -InputObject $task -ComputerName $server

                    Write-Host "Scheduled reboot for $server at $RebootTime."
                }
                "Skip" {
                    Write-Host "Reboot skipped for $server."
                }
            }
        } else {
            Write-Host "No reboot is required on $server."
        }
    } Catch {
        Write-Host "An error occurred while processing $server"
        # Log the error
        $_ | Out-File -FilePath "$reportPath\ErrorLog.txt" -Append
    }
}

# Set up a scheduled task to run this script weekly

# Path to the script
$scriptPath = "C:\Scripts\RemoteMaintenance.ps1"

# Create the action
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Create the trigger to run weekly
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 3am

# Create the principal
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the scheduled task
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal

# Register the scheduled task
Register-ScheduledTask -TaskName "WeeklyRemoteMaintenance" -InputObject $task

Write-Host "Scheduled task 'WeeklyRemoteMaintenance' has been created to run every week."
