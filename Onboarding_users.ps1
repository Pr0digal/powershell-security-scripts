# Requires the ActiveDirectory module
Import-Module ActiveDirectory

# Prompt for user info
$firstName = Read-Host "Enter First Name"
$lastName = Read-Host "Enter Last Name"
$email = Read-Host "Enter Email Address"
$description = Read-Host "Enter Description (e.g. job title, department)"

# Create samAccountName: firstname + first letter of lastname (lowercase)
$samAccountName = ($firstName + $lastName[0]).ToLower()

# Generate a 16-character secure password with complexity
function Generate-SecurePassword {
    $upper = 65..90 | ForEach-Object { [char]$_ }      # A-Z
    $lower = 97..122 | ForEach-Object { [char]$_ }     # a-z
    $digit = 48..57 | ForEach-Object { [char]$_ }      # 0-9
    $special = @('!', '@', '#', '$', '%', '^', '&', '*', '-', '_', '+', '=')

    $all = $upper + $lower + $digit + $special

    $password = -join (
        ($upper | Get-Random -Count 1) +
        ($lower | Get-Random -Count 1) +
        ($digit | Get-Random -Count 1) +
        ($special | Get-Random -Count 1) +
        ((1..12) | ForEach-Object { $all | Get-Random })
    )

    return $password
}

$passwordPlain = Generate-SecurePassword
if (-not $passwordPlain) {
    Write-Error "Password generation failed. Exiting."
    exit
}

$securePassword = ConvertTo-SecureString $passwordPlain -AsPlainText -Force

# Show the password once in a pop-up
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("Temporary Password (copy now):`n$passwordPlain", "User Password", "OK", "Info")

# Define UPN and OU path — update these for your environment
$userPrincipalName = "$samAccountName@test.local"
$userOU =  "CN=Users,DC=test,DC=local"  # Changed to default Users container

# Create the AD user
try {
    New-ADUser `
        -Name "$firstName $lastName" `
        -GivenName $firstName `
        -Surname $lastName `
        -SamAccountName $samAccountName `
        -UserPrincipalName $userPrincipalName `
        -EmailAddress $email `
        -Description $description `
        -AccountPassword $securePassword `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -ChangePasswordAtLogon $false `
        -Path $userOU

    Write-Host "`n✅ User '$samAccountName' created successfully." -ForegroundColor Green

    # List of groups to add (searched globally instead of a specific OU)
    $groupNames = @(
        "CyberArk",
        "Defender",
        "Domain Users" ,
        "Remote Desktop Users"
    )

    foreach ($groupName in $groupNames) {
        try {
            $group = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction Stop
            Add-ADGroupMember -Identity $group -Members $samAccountName
            Write-Host "➕ Added to group: $($group.Name)"
        } catch {
            Write-Warning "⚠️ Could not add to group '$groupName'. Error: $_"
        }
    }

} catch {
    Write-Error "`n❌ Failed to create user or assign groups: $_"
}

# Clean up plain password from memory
$passwordPlain = $null
[System.GC]::Collect()
