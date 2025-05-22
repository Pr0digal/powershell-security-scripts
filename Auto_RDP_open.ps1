# --- Configuration ---
$downloadsPath = "$env:USERPROFILE\Downloads"
$filter = '*.rdp'
$sessionTimeoutMinutes = 10

# --- FileSystemWatcher Setup ---
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $downloadsPath
$watcher.Filter = $filter
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'
$watcher.IncludeSubdirectories = $false

# --- Function to check if a file is locked ---
function Wait-ForFileUnlock {
    param (
        [string]$Path,
        [int]$TimeoutSeconds = 10
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            $stream = [System.IO.File]::Open($Path, 'Open', 'Read', 'None')
            $stream.Close()
            return $true
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
    return $false
}

# --- Define Event Handler ---
$action = {
    $rdpPath = $Event.SourceEventArgs.FullPath
    Write-Host "`n[RDP DETECTED] -> $rdpPath"

    if (Wait-ForFileUnlock -Path $rdpPath) {
        Write-Host "[READY] Opening RDP file..."
        $process = Start-Process "mstsc.exe" -ArgumentList "`"$rdpPath`"" -PassThru

        Start-Job -ScriptBlock {
            param($pid, $timeout)
            Start-Sleep -Seconds ($timeout * 60)
            try {
                $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($proc) {
                    Write-Host "[AUTO-CLOSE] Closing RDP session (PID: $pid)"
                    Stop-Process -Id $pid -Force
                }
            } catch {
                Write-Host "[INFO] RDP process already closed or not found."
            }
        } -ArgumentList $process.Id, $using:sessionTimeoutMinutes | Out-Null
    } else {
        Write-Host "[ERROR] File was not unlocked in time: $rdpPath"
    }
}

# --- Register the Event ---
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action | Out-Null

# --- Start Watching ---
$watcher.EnableRaisingEvents = $true
Write-Host "`n[WATCHING] Monitoring $downloadsPath for new RDP files..."
Write-Host "[INFO] Auto-closing RDP sessions after $sessionTimeoutMinutes minutes."
Write-Host "Press Ctrl+C to stop.`n"

# --- Keep Script Running ---
while ($true) {
    Start-Sleep -Seconds 1
}
