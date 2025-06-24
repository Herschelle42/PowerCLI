function Test-ClusterSharedStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ClusterName,

        [string[]]$ExcludePatterns = @('local', 'Local')  # Default exclusions for local storage
    )

    $cluster = Get-Cluster -Name $ClusterName -ErrorAction Stop
    $hosts = Get-VMHost -Location $cluster -ErrorAction Stop

    $datastoresPerHost = @{}

    foreach ($host in $hosts) {
        $datastores = Get-Datastore -VMHost $host | Where-Object {
            $dsName = $_.Name
            ($ExcludePatterns | Where-Object { $dsName -match $_ }) -eq $null
        }

        $datastoresPerHost[$host.Name] = $datastores.Name
    }

    # Build reference from first host
    $referenceHost = $datastoresPerHost.Keys | Select-Object -First 1
    $referenceStores = $datastoresPerHost[$referenceHost] | Sort-Object

    $results = foreach ($hostName in $datastoresPerHost.Keys) {
        $hostStores = $datastoresPerHost[$hostName] | Sort-Object

        $isMatch = ($hostStores -join '|') -eq ($referenceStores -join '|')

        [PSCustomObject]@{
            HostName           = $hostName
            MatchesReference   = $isMatch
            DatastoreCount     = $hostStores.Count
            MissingDatastores  = ($referenceStores | Where-Object { $_ -notin $hostStores }) -join ', '
            ExtraDatastores    = ($hostStores | Where-Object { $_ -notin $referenceStores }) -join ', '
        }
    }

    return $results
}
