# Import the Active Directory module
Import-Module ActiveDirectory

# Define the output file path
$outputFile = "C:\ADUserReport.csv"  # Change this to your desired file path

# Initialize an array to hold the user report
$userReport = @()

# Get all users from Active Directory
try {
    # Get all user objects with the specified properties
    $users = Get-ADUser -Filter * -Property DisplayName, Department, TelephoneNumber, EmailAddress, LastLogonDate
} catch {
    Write-Host "Error retrieving AD users: $_"
    exit 1
}

# Iterate through each user and collect their details
foreach ($user in $users) {
    try {
        # Check if the user has a last login time, otherwise set to "Never logged in"
        $lastLogon = if ($user.LastLogonDate) { $user.LastLogonDate } else { "Never logged in" }
        
        # Create a custom object to store the user details
        $userDetails = New-Object PSObject -Property @{
            "Name"          = $user.DisplayName
            "Department"    = $user.Department
            "PhoneNumber"   = $user.TelephoneNumber
            "EmailAddress"  = $user.EmailAddress
            "LastLogonDate" = $lastLogon
        }

        # Add the user details to the report array
        $userReport += $userDetails
    } catch {
        Write-Host "Error processing user $($user.SamAccountName): $_"
    }
}

# Export the user report to a CSV file
try {
    $userReport | Export-Csv -Path $outputFile -NoTypeInformation
    Write-Host "User report successfully exported to $outputFile"
} catch {
    Write-Host "Error exporting the report: $_"
}
