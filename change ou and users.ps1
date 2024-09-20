Import-Module ActiveDirectory
New-ADGroup -Name "Salgssjef" -GroupScope Global -GroupCategory Security -Path "OU=Salgs,OU=Users,OU=ITD-SERVER-STUFF,DC=fsi-vicaun05,DC=com"
New-ADGroup -Name "salgsrepresentanter" -GroupScope Global -GroupCategory Security -Path "OU=Salgs,OU=Users,OU=ITD-SERVER-STUFF,DC=fsi-vicaun05,DC=com"
Add-ADGroupMember -Identity "Salgs" -Members "Salgssjef","salgsrepresentanter"
# List of users to move
$userNames = @("Erik b. Johansen","Per s. Pedersen","Bjørn a. Olsen")

# Loop through each user and add them to the group
foreach ($name in $userNames) {
    $user = Get-ADUser -Filter "Name -eq '$name'"
    if ($user) {
        Add-ADGroupMember -Identity "salgsrepresentanter" -Members $user.SamAccountName
        Write-Host "Added $name to salgsrepresentanter group."
    } else {
        Write-Host "User $name not found in Active Directory."
    }
}
