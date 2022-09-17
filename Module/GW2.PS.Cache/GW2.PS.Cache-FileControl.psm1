Function New-GW2CacheFile {
    [CMdletBinding(DefaultParameterSetName="UsingID")]
    param(
        [parameter(ParameterSetName="UsingID",ValueFromPipelineByPropertyName)]
        $ID=0,
        [parameter(ParameterSetName="TagName",ValueFromPipelineByPropertyName,Mandatory)]
        [string]$Name,
        [parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,ValueFromRemainingArguments)]
        $Value,
        [parameter(Mandatory)]
        [string]$APIEndpoint
    )

    Begin {
        $FolderPath = "{0}\{1}" -f (Get-GW2ConfigValue -Section Cache -Name Path),$APIEndpoint
        If (-Not (Test-path $FolderPath -ErrorAction SilentlyContinue)) {
            Write-Debug "Creating cache folder at $FolderPath"
            $Folder = New-Item -Path $FolderPath -ItemType Directory
        } else {
            $Folder = Get-Item -Path $FolderPath
        }
        $FileNames = @{}
    }

    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "TagName" {
                $FileName = "{0:00000000}.json" -f $Name
                $FileNames.$FileName += @([PSCustomObject]@{
                    'ID'=$Name
                    'Value'=$Value
                })
            }
            default {
                $FileName = "{0:00000000}.json" -f (Get-GW2CacheFileID -id $ID)
                $FileNames.$FileName += @([PSCustomObject]@{
                    'ID'=[string]$ID
                    'Value'=$Value
                })
            }
        }
        #return $value
    }

    End {
        ForEach ($FName in ($FileNames.Keys)) {
            $CacheFilePath="$($Folder.FullName)\$FName"
            If (Test-Path $CacheFilePath) {
                Write-Warning "Cache file for $FName already exists in $APIEndpoint"
            } else {
                Write-Debug "Putting $(($FileNames.$FName).Count) entries in cache file $CacheFilePath"
                New-GW2CacheFileContent -Roots ($FileNames.$FName) | Set-Content -Path $CacheFilePath
            }
        }
    }
}

Function Get-GW2CacheFileID {
    [cmdletbinding()]
    param([int]$ID=0)

    Process {
        $MaxItems = [double](Get-GW2ConfigValue -Section Cache -Name 'MaxItemsPerFile')
        Write-Debug "Finding ID: $MaxItems * Floor($ID/$MaxItems)"
        [int]($MaxItems * [Math]::Floor($ID / ($MaxItems)))
    }

}

Function New-GW2CacheEntry {
    param($Value=$null)

    If ($Value) {
        $StoreDate=(Get-Date)
    } else {
        $StoreDate="1/1/1980"
    }
    [PSCustomObject][ordered]@{
        "Entry"=$Value
        "LastUpdate"=[datetime]$StoreDate
        "LastTouch"=[datetime]$StoreDate
    }
}

Function New-GW2CacheFileContent {
    param([object[]]$Roots)

    $Base = [PSCustomObject][ordered]@{
        "CreationDate"="{0:yyyy-MM-dd HH:mm:ss}" -f (Get-Date)
        "Items"=[ordered]@{}
    }
    ForEach ($Root in ($Roots | Sort-Object ID)) {
        Write-Debug "Storing $($Root.ID)..."
        $Base.Items.([string]($Root.ID)) = (New-GW2CacheEntry -Value $Root.Value)
    }
    $Base | ConvertTo-JSON -Depth (Get-GW2ConfigValue -Section Cache -Name 'DefaultDepth')
}

