# Define the output CSV file path
$outputFile = "C:\DHCP_Leases.csv"

# Import the DHCP Server module (if not already imported)
Import-Module DhcpServer

# Retrieve all DHCP leases from the local DHCP server
$dhcpLeases = Get-DhcpServerv4Lease

# Select the required fields and rename them to match the headers
$selectedLeases = $dhcpLeases | Select-Object `
    @{Name='ScopeId'; Expression={ $_.ScopeId }},
    @{Name='IPAddress'; Expression={ $_.IPAddress }},
    @{Name='HostName'; Expression={ $_.HostName }},
    @{Name='ClientID'; Expression={ $_.ClientId }},
    @{Name='AddressState'; Expression={ $_.AddressState }}

# Export the data to a CSV file with a semicolon delimiter
$selectedLeases | Export-Csv -Path $outputFile -NoTypeInformation -Delimiter ';'

# Output a confirmation message
Write-Host "DHCP leases have been exported to $outputFile"
