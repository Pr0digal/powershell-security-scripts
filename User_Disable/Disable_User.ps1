# Requires the ActiveDirectory module
Import-Module ActiveDirectory

# Function to disable a user and log action
function Disable-User {
    param (
        [string]$userSam
    )

    $user = Get-ADUser -Identity $userSam -Properties DistinguishedName -ErrorAction SilentlyContinue
    if (-not $user) {
        Write-Warning "⚠️ User '$userSam' not found."
        return
    }

    try {
        Disable-ADAccount -Identity $userSam
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "✅ User '$userSam' disabled at $timestamp"
        "$timestamp,Disabled,$userSam,$($user.DistinguishedName)" | Out-File -FilePath "user_offboarding_log.csv" -Append -Encoding utf8
    } catch {
        Write-Error "❌ Failed to disable user '$userSam'. Error: $_"
    }
}

# Prompt for mode: single or bulk
$mode = Read-Host "Run in (S)ingle or (B)ulk mode with CSV? [S/B]"

if ($mode -eq 'B') {
    $csvPath = Read-Host "Enter full path to CSV (must contain column 'samAccountName')"
    if (-Not (Test-Path $csvPath)) {
        Write-Error "❌ File not found: $csvPath"
        exit
    }
    $users = Import-Csv -Path $csvPath
    foreach ($user in $users) {
        Disable-User -userSam $user.samAccountName
    }
} else {
    # Prompt for user identity
    $userSam = Read-Host "Enter the SAM Account Name of the user to disable"

    # Confirm action
    $confirmation = Read-Host "Are you sure you want to disable the user '$userSam'? (Y/N)"
    if ($confirmation -ne 'Y') {
        Write-Host "❌ Aborted by user."
        exit
    }

    Disable-User -userSam $userSam
}
