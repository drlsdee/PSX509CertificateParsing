[System.String]$functionsFolderPath = "$PSScriptRoot\Functions"
[System.String]$functionsFolderPathPrivate = "$functionsFolderPath\Private"
[System.String]$functionsFolderPathPublic = "$functionsFolderPath\Public"

[System.String[]]$functionsPublic = [System.IO.Directory]::GetFiles($functionsFolderPathPublic, '*.ps1')
[System.String[]]$functionsPrivate = [System.IO.Directory]::GetFiles($functionsFolderPathPrivate, '*.ps1')

@($functionsPrivate + $functionsPublic).ForEach({
    . $_
})

$functionsPublic.ForEach({
    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($_)
    Export-ModuleMember -Function $functionName
    try {
        $aliases = Get-Alias -Definition $functionName -ErrorAction Stop
        @($aliases).ForEach({
            Export-ModuleMember -Alias $_
        })
    }
    catch {
        Write-Warning -Message "The function `"$functionName`" has no aliases!"
    }
})