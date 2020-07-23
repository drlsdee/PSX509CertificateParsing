function Enumerate-FilesByExtension {
    [CmdletBinding()]
    param (
        # Path to search
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [string]
        $Path,

        # Extension
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [string]
        $Pattern
    )
    switch -regex ($Pattern) {
        '^\.\w+$' {
            Write-Verbose -Message "Extension starts with dot: $Pattern"
            [string]$Pattern = "*$($Pattern)"
        }
        '^\*\.\w+$' {
            Write-Verbose -Message "Extension starts with an asterisk: $Pattern"
            [string]$Pattern = $Pattern
        }
        '^\w+$' {
            Write-Verbose -Message "Extension starts with letter or digit: $Pattern"
            [string]$Pattern = "*.$($Pattern)"
        }
    }
    Write-Verbose -Message "Pattern for search: $Pattern"
    [string[]]$fileList = [System.IO.Directory]::EnumerateFiles($Path, $Pattern)
    Write-Verbose -Message "Found $($fileList.Count) files with extension `"$Pattern`". Returning."
    return $fileList
}

function List-FunctionsAll {
    [CmdletBinding()]
    param (
        # Root folder
        [Parameter()]
        [string]
        $ModuleRoot = $PSScriptRoot,

        # Functions root folder
        [Parameter()]
        [string]
        $Functions = 'Functions',

        # Private functions root folder
        [Parameter()]
        [string]
        $FunctionsPublic = 'Public',

        # Public functions root folder
        [Parameter()]
        [string]
        $FunctionsPrivate = 'Private',

        # File extensions
        [Parameter()]
        [string[]]
        $Extensions = @('.ps1')
    )
    Write-Verbose "Module root: $ModuleRoot"
    [string]$functionsPath = [System.IO.Path]::Combine($ModuleRoot, $Functions)
    Write-Verbose -Message "Functions root: $functionsPath"
    [string]$functionsPublicPath = [System.IO.Path]::Combine($functionsPath, $FunctionsPublic)
    [string]$functionsPrivatePath = [System.IO.Path]::Combine($functionsPath, $FunctionsPrivate)
    Write-Verbose -Message "Public functions should be here: $functionsPublicPath"
    Write-Verbose -Message "Private functions should be here: $functionsPrivatePath"

    if
    (
        [System.IO.Directory]::Exists($functionsPublicPath) -and `
        [System.IO.Directory]::Exists($functionsPrivatePath)
    )
    {
        [string[]]$functionPublicFiles      = $Extensions.ForEach({
            Enumerate-FilesByExtension -Path $functionsPublicPath -Pattern $_
        }) | Select-Object -Unique # For case when the same extension is defined in several forms.
        Write-Verbose -Message "Found $($functionPublicFiles.Count) public functions"
        [string[]]$functionsPrivateFiles    = $Extensions.ForEach({
            Enumerate-FilesByExtension -Path $functionsPrivatePath -Pattern $_
        }) | Select-Object -Unique # For case when the same extension is defined in several forms.
        Write-Verbose -Message "Found $($functionsPrivateFiles.Count) private functions"    
    }
    elseif
    (
        [System.IO.Directory]::Exists($functionsPath)
    )
    {
        Write-Warning -Message "The root module folder `"$PSScriptRoot`" does not contain any subfolders where public and / or private functions are expected, but it does contain the subfolder `"$Functions`". Thus, all functions in that subfolder will be exported as public."
        [string[]]$functionPublicFiles      = $Extensions.ForEach({
            Enumerate-FilesByExtension -Path $functionsPath -Pattern $_
        }) | Select-Object -Unique # For case when the same extension is defined in several forms.
        [string[]]$functionsPrivateFiles    = @()
    }
    else {
        Write-Warning -Message "The root module folder `"$PSScriptRoot`" does not contain any subfolders where public and / or private functions are expected!"
        [string[]]$functionsPrivateFiles    = @()
        [string[]]$functionsPrivateFiles    = @()
    }

    [string[]]$functionsToExport = $functionPublicFiles.ForEach({
        [System.IO.Path]::GetFileNameWithoutExtension($_)
    })

    [hashtable]$tableOut = @{
        Import = @($functionsPrivateFiles + $functionPublicFiles)
        Export = $functionsToExport
    }

    return $tableOut
}

function Get-AllAliases {
    [CmdletBinding()]
    param (
        # List of function names
        [Parameter()]
        [string[]]
        $Functions
    )
    [System.Management.Automation.AliasInfo[]]$aliasesList = @()
    $Functions.ForEach({
        [string]$functionCurrent = $_
        try {
            $aliasInfo = Get-Alias -Definition $functionCurrent -ErrorAction Stop
            $aliasesList += $aliasInfo
        }
        catch {
            Write-Verbose -Message "The function `"$functionCurrent`" has no aliases!"
        }
    })
    return $aliasesList
}

(List-FunctionsAll).Import.ForEach({
    Write-Verbose -Message "Importing script: $_"
    . $_
})

(List-FunctionsAll).Export.ForEach({
    Write-Verbose -Message "Exporting function: $_"
    Export-ModuleMember -Function $_
})

(Get-AllAliases -Functions (List-FunctionsAll).Export).ForEach({
    Write-Verbose -Message "Exporting alias: $_"
    Export-ModuleMember -Alias $_
})
