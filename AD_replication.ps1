# Import AD module
Import-Module ActiveDirectory -ErrorAction Stop

# Configuration
$DeltaThresholdMinutes = 10

# Get all writable domain controllers (exclude RODCs)
$DomainControllers = Get-ADDomainController -Filter * | Where-Object { -not $_.IsReadOnly }

# Store replication status
$ReplicationStatus = @()

foreach ($DC in $DomainControllers) {
    try {
        $Partners = Get-ADReplicationPartnerMetadata -Target $DC.HostName -ErrorAction Stop

        foreach ($Partner in $Partners) {
            $DeltaMinutes = [math]::Round(((Get-Date) - $Partner.LastReplicationSuccess).TotalMinutes, 2)
            $Alert = if ($DeltaMinutes -gt $DeltaThresholdMinutes) { "⚠️ Delay > ${DeltaThresholdMinutes} mins" } else { "OK" }

            $Status = [PSCustomObject]@{
                SourceDC        = $Partner.Partner
                DestinationDC   = $DC.HostName
                LastSuccessSync = $Partner.LastReplicationSuccess
                DeltaMinutes    = $DeltaMinutes
                SyncStatus      = if ($Partner.LastReplicationResult -eq 0) { "Success" } else { "Error ($($Partner.LastReplicationResult))" }
                Alert           = $Alert
            }

            $ReplicationStatus += $Status
        }
    }
    catch {
        Write-Warning "⚠️ Could not retrieve replication metadata from $($DC.HostName): $_"
    }
}

# Display results
$ReplicationStatus | Sort-Object DeltaMinutes -Descending | Format-Table -AutoSize

# Summary alert
if ($ReplicationStatus.Alert -contains "⚠️ Delay > ${DeltaThresholdMinutes} mins") {
    Write-Host "`n❗ Replication delays detected (over ${DeltaThresholdMinutes} minutes)!" -ForegroundColor Yellow
} elseif ($ReplicationStatus.SyncStatus -contains "Error") {
    Write-Host "`n❗ Some replication connections have errors!" -ForegroundColor Red
} else {
    Write-Host "`n✅ All writable DCs are replicating within expected thresholds." -ForegroundColor Green
}
