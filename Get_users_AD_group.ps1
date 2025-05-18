# Import AD module
Import-Module ActiveDirectory -ErrorAction Stop

# Prompt for group name
$GroupName = Read-Host "Enter the name (SAMAccountName) of the AD group"

# Get all direct members of the group
$GroupMembers = Get-ADGroupMember -Identity $GroupName -ErrorAction Stop | Where-Object { $_.objectClass -eq 'user' }

# Display results
$GroupMembers | Select-Object Name, SamAccountName, DistinguishedName | Format-Table -AutoSize
