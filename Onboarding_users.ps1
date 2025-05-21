# Requires ActiveDirectory module
Import-Module ActiveDirectory

# Prompt for user info
$firstName = Read-Host "Enter First Name"
$lastName = Read-Host "Enter Last Name"

# Generate short name (samAccountName)
$samAccountName = ($firstName + $lastName[0]).ToLower()

# Generate a 16-character complex password
Add-Type -AssemblyName System.Web
function Generate-SecurePassword {
    $upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lower = 'abcdefghijklmnopqrstuvwxyz'
    $digit = '0123456789'
    $special = '!@#$%^&*()-_=+[]{}|;:,.<>?'

    $all = $upper + $lower + $digit + $special

    $password = -join (
        ($upper | Get-Random -Count 1) +
        ($lower | Get-Random -Count 1) +
        ($digit | Get-Random -Count 1) +
        ($special | Get-Random -Count 1) +
        (-join ((1..12) | ForEach-Object { $all | Get-Random -Count 1 }))
    )

    return $password
}

$passwordPlain = Generate-SecurePassword
$securePassword = ConvertTo-SecureString $passwordPlain -AsPlainText -Force

# Show password ONCE in a secure message box
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("Password (copy now): `n$passwordPlain", "User Password", "OK", "Info")

# Set user details
$userPrincipalName = "$samAccountName@yourdomain.com"  # Replace with your actual domain
$ou = "OU=Users,DC=yourdomain,DC=com"  # Adjust the OU path accordingly

# Create the AD user
New-ADUser `
    -Name "$firstName $lastName" `
    -GivenName $firstName `
    -Surname $lastName `
    -SamAccountName $samAccountName `
    -UserPrincipalName $userPrincipalName `
    -AccountPassword $securePassword `
    -Enabled $true `
    -ChangePasswordAtLogon $true `
    -Path $ou

# Add to groups
$groups = @(
    "CyberArk Users",
    "2FA Users",
    "Domain Users",
    "Remote Desktop Users"
)

foreach ($group in $groups) {
    Add-ADGroupMember -Identity $group -Members $samAccountName
}

# Clear the plain password from memory
$passwordPlain = $null
[System.GC]::Collect()

Write-Host "`nUser $samAccountName created and added to default groups."
