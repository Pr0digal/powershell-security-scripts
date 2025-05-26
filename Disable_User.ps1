# Requires the ActiveDirectory module
Import-Module ActiveDirectory

# Prompt for user identity
$userSam = Read-Host "Enter the SAM Account Name of the user to disable"

# Confirm action
$confirmation = Read-Host "Are you sure you want to disable the user '$userSam'? (Y/N)"
if ($confirmation -ne 'Y') {
    Write-Host "❌ Aborted by user."
    exit
}

# Get the user object
$user = Get-ADUser -Identity $userSam -Properties Enabled, DistinguishedName -ErrorAction SilentlyContinue
if (-not $user) {
    Write-Warning "⚠️ User '$userSam' not found."
    exit
}

# Show where the user is located in AD
Write-Host "📍 User found at: $($user.DistinguishedName)"

# Disable the user account
try {
    Disable-ADAccount -Identity $userSam
    Write-Host "✅ User '$userSam' has been disabled."
} catch {
    Write-Error "❌ Failed to disable user. Error: $_"
}
