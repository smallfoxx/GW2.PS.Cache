Function Get-GW2CacheFileValue {
    [cmdletbinding()]
    param(
        [string]$APIValue,
        [hashtable]$APIParams,
        [string]$APIBase
    )

    Begin {
        $FolderPath = "{0}\{1}" -f (Get-GW2ConfigValue -Section Cache -Name Path),$APIValue
        $AllIDs = [System.Collections.ArrayList]@()
        $Filelist = @{}
    }

    Process {
        $ThisIDs = @($APIParams.ids -split ',')
        $AllIDs.AddRange($ThisIDs)
        Write-Debug "Processing $($ThisIDs.count) of $($AllIDs.count) IDS"
        ForEach ($id in $ThisIDs) {
            $FileID = Get-GW2CacheFileID -ID $id
            $Filelist.$FileID += @($id)
        }
       # throw ("Currently not impletmented")
    }

    End {
        $FoundEntries = [System.Collections.ArrayList]@()
        ForEach ($FileId in $Filelist.Keys) {
            IF (Test-Path "$FolderPath\$FileID.json") {
                Write-Debug "Pulling items from $FolderPath\$FileID.json"
                $FileContent = Get-Content "$FolderPath\$FileID.json" | ConvertFrom-Json
                $FileContent | Add-Member ScriptProperty IDs { ($this.Items | Get-Member -MemberType NoteProperty).Name }
                $FoundItemIDs = ($FileContent.IDs) | Where-Object { $_ -in ($Filelist.$FileId) } 
                $FoundItems = ForEach ($FoundID in $FoundItemIDs) {
                    $FileContent.Items.$FoundID.Entry
                }
                If ($FoundItems) {
                    Write-Debug "Found $($FoundItems.count) in $FileID"
                    $FoundEntries.AddRange(@($FoundItems))
                } 
            } else {
                Write-Debug "Missing file $FolderPath\$FileID.json"
            }
        }
        $FoundIds = $FoundEntries
        $MissingIds = $AllIDs | Where-Object { $_ -notin $FoundIds }
        If ($MissingIds) {
            Write-Debug "Getting $($MissingIds.count) of $($AllIDs.count) IDs from API that were not in CACHE"
            $WebResults = Get-GW2APIValue -APIValue $APIValue -SecureAPIKey $SecureAPIKey -APIParams @{ 'ids' = ($MissingIds -join ',') } -UseCache:$false
            $WebResults | Set-GW2CacheFileContent -APIEndpoint $APIValue
            $FoundEntries.AddRange(@($WebResults))
        } 
        Write-Output $FoundEntries
    }
}

Function Get-GW2CacheValue {
    [cmdletbinding()]
    param(
        [string]$APIValue,
        [securestring]$SecureAPIKey,
        [hashtable]$APIParams
    )

    Process {
       # try {
            If ($APIParams.count -gt 0) {
                Get-GW2CacheFileValue -APIValue $APIValue -APIParams $APIParams -ErrorAction Stop -APIBase $APIBase
            } else {
                Get-GW2APIValue -APIValue $APIValue -SecureAPIKey $SecureAPIKey -APIParams $APIParams -UseCache:$false
            }
       <# } catch {
            Write-Debug "Get CACHE value FAILED; trying API call"
            $WebResults = Get-GW2APIValue -APIValue $APIValue -SecureAPIKey $SecureAPIKey -APIParams $APIParams -UseCache:$false 
            $WebResults | Set-GW2CacheFileContent -APIEndpoint $APIValue 
            Write-Output $WebResults
        } #>
    }

}
