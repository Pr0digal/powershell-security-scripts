# Import the Active Directory module
Import-Module ActiveDirectory -ErrorAction Stop

# === CONFIGURATION ===
$EnableConfirmationPrompt = $true
$LogFile = "C:\Scripts\Logs\manual_user_removal_log.txt"

# === SETUP LOG ===
if (-not (Test-Path $LogFile)) {
    New-Item -Path $LogFile -ItemType File -Force | Out-Null
}
"`n[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] AD User Removal Script Started" | Out-File -FilePath $LogFile -Append

# === USER INPUT LOOP ===
do {
    $InputLine = Read-Host "Enter SAMAccountNames (comma-separated) or type 'exit' to quit"

    if ($InputLine.Trim().ToLower() -eq 'exit') {
        break
    }

    # Split input into individual usernames
    $UserList = $InputLine -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    foreach ($Username in $UserList) {
        try {
            $User = Get-ADUser -Identity $Username -ErrorAction Stop

            if ($EnableConfirmationPrompt) {
                $Confirm = Read-Host "Confirm deletion of user '$Username'? (Y/N)"
                if ($Confirm -ne 'Y') {
                    "$Username - Skipped by user confirmation." | Out-File -FilePath $LogFile -Append
                    continue
                }
            }

            Remove-ADUser -Identity $User.DistinguishedName -Confirm:$false -ErrorAction Stop
            "$Username - Successfully removed." | Out-File -FilePath $LogFile -Append
            Write-Host "$Username removed." -ForegroundColor Green
        }
        catch {
            "$Username - ERROR: $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
            Write-Host "Error removing $Username: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

} while ($true)

"`n[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Script complete." | Out-File -FilePath $LogFile -Append
