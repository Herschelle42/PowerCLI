function Test-ClusterSharedStorage {
<#
.EXAMPLE
  Get-Cluster | Test-ClusterSharedStorage | Sort Cluster, HostName | Export-Csv -NoTypeInformation -Path "..\reports\Cluster Shared Storage.csv"
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [string[]]$ExcludePatterns = @('local', 'Local')  # Default exclusions for local storage
    )

    process {
        $cluster = Get-Cluster -Name $Name -ErrorAction Stop
        $vmhostList = Get-VMHost -Location $cluster -ErrorAction Stop

        $datastoresPerHost = @{}

        foreach ($vmhost in $vmhostList) {
            $datastores = Get-Datastore -VMHost $vmhost | Where-Object {
                $dsName = $_.Name
            ($ExcludePatterns | Where-Object { $dsName -notmatch $_ -and $dsName -notmatch $vmhost.Name.substring(0, $vmhost.Name.indexOf(".")) })
            }

            $datastoresPerHost[$vmhost.Name] = $datastores.Name
        }

        # Build reference from first host
        $referenceHost = $datastoresPerHost.Keys | Select-Object -First 1
        $referenceStores = $datastoresPerHost[$referenceHost] | Sort-Object

        $results = foreach ($hostName in $datastoresPerHost.Keys) {
            $hostStores = $datastoresPerHost[$hostName] | Sort-Object

            $isMatch = ($hostStores -join '|') -eq ($referenceStores -join '|')

            [PSCustomObject]@{
                Cluster           = $Name
                HostName          = $hostName
                MatchesReference  = $isMatch
                DatastoreCount    = $hostStores.Count
                MissingDatastores = ($referenceStores | Where-Object { $_ -notin $hostStores }) -join ', '
                ExtraDatastores   = ($hostStores | Where-Object { $_ -notin $referenceStores }) -join ', '
            }
        }

        return $results
    }
}
