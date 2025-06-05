# --- Configuration ---
$downloadsPath = "C:\Users\Pr0digal\Downloads"
$filter = '*.rdp'

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
    Write-Host "Detected new RDP file: $rdpPath"

    if (Wait-ForFileUnlock -Path $rdpPath) {
        Write-Host "Opening RDP file: $rdpPath"
        Start-Process "mstsc.exe" -ArgumentList "`"$rdpPath`""
    } else {
        Write-Host "Timeout waiting for file unlock: $rdpPath"
    }
}

# --- Register the Event ---
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action | Out-Null

# --- Start Watching ---
$watcher.EnableRaisingEvents = $true
Write-Host "Monitoring $downloadsPath for new RDP files..."
Write-Host "Press Ctrl+C to stop."

# --- Keep Script Running ---
while ($true) {
    Start-Sleep -Seconds 1
}
