Function New-GW2CacheSettings {

    @{
        "Path" = "$env:TEMP\GW2.PS\Cache"
        "MinTouch" = 1440
        "MaxAge" = 2628000
        "MaxItemsPerFile" = 200
        "DefaultDepth" = 4
        "UseCache" = $true
    }

}

Function Set-GW2CachePath {
    param([string]$Path="$env:TEMP\GW2.PS\Cache")

    If (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
        $Dir = New-Item -Path $Path -ItemType Directory -ErrorAction SilentlyContinue
    }
    $Dir = Get-Item -Path $Path -ErrorAction SilentlyContinue
    If ($Dir) {
        Set-GW2ConfigValue -Section Cache -Name 'Path' -Value $Dir.FullName
    }
}

Function Set-GW2UseCache {
    param([switch]$Disable)

    Set-GW2ConfigValue -Section Cache -Name 'UseCache' -Value (-not $Disable)
}

