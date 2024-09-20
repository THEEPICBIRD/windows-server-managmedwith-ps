$csvPath = "C:\Users\vicaun\Documents\Users.csv"
$users = Import-Csv -Delimiter ';' -Path $csvPath
$domain = "fsi-vicaun05.com"

foreach ($user in $users) {
    try {
        $firstName = $user.FirstName
        $lastName = $user.LastName
        $middleInitial = $user.MiddleInitial
        $password = $user.Password
        $ou = $user.OrganizationalUnit
        $telephoneNumber = $user.TelephoneNumber

        # Correct typo in the OrganizationalUnit column
        if ($ou -eq "slags") {
            $ou = "Salgs"
        }

        # Handle special characters
        $sanitizedFirstName = $firstName -replace '[^a-zA-Z]', ''
        $sanitizedLastName = $lastName -replace '[^a-zA-Z]', ''

        # Generate username
        $usernameBase = ($sanitizedFirstName.Substring(0, 3) + $sanitizedLastName.Substring(0, 3)).ToLower()

        $existingUser = Get-ADUser -Filter { SamAccountName -like "$usernameBase*" }
        if ($existingUser) {
            $username = ($sanitizedFirstName.Substring(0, 3) + $sanitizedLastName.Substring(-3)).ToLower()
        } else {
            $username = $usernameBase
        }

        $fullName = "$firstName $middleInitial. $lastName"

        # Build the OU path according to the nested structure
        switch ($ou) {
            "Administrasjon" { $ouPath = "OU=Administrasjon,OU=Users,OU=ITD-SERVER-STUFF,DC=fsi-vicaun05,DC=com" }
            "Utviklings" { $ouPath = "OU=Utviklings,OU=Users,OU=ITD-SERVER-STUFF,DC=fsi-vicaun05,DC=com" }
            "Salgs" { $ouPath = "OU=Salgs,OU=Users,OU=ITD-SERVER-STUFF,DC=fsi-vicaun05,DC=com" }
            "IT" { $ouPath = "OU=IT,OU=Users,OU=ITD-SERVER-STUFF,DC=fsi-vicaun05,DC=com" }
            "Kunde Support" { $ouPath = "OU=Kunde Support,OU=Users,OU=ITD-SERVER-STUFF,DC=fsi-vicaun05,DC=com" }
            default { throw "OU $ou not found." }
        }

        # Verify the OU path
        if (-not (Get-ADOrganizationalUnit -Filter { DistinguishedName -eq $ouPath })) {
            throw "OU path $ouPath does not exist"
        }

        # Create the AD User
        New-ADUser -SamAccountName $username `
                   -UserPrincipalName "$username@$domain" `
                   -Name $fullName `
                   -GivenName $firstName `
                   -Surname $lastName `
                   -DisplayName $fullName `
                   -Path $ouPath `
                   -OfficePhone $telephoneNumber `
                   -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
                   -Enabled $true

        Write-Host "User $username created successfully."

    } catch {
        Write-Host "Error creating user for $($user.FirstName) $($user.LastName): $_"
        # Optionally, log the error to a file
        Add-Content -Path "error_log.txt" -Value "Error creating user for $($user.FirstName) $($user.LastName): $_"
    }
}
