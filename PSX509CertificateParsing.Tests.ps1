#Requires   -Module @{  ModuleName  =   'Pester';           ModuleVersion   =   '5.0.2'     }
#Requires   -Module @{  ModuleName  =   'PSScriptAnalyzer'; ModuleVersion   =   '1.19.0'    }

[string]$psTestDataPath         =   [System.IO.Path]::ChangeExtension($PSCommandPath, 'psd1')
if (-not [System.IO.File]::Exists($psTestDataPath)) {
    Write-Warning -Message "PowerShell data file not found: $psTestDataPath"
    return
}

$psTestData                     =   Import-PowerShellDataFile -Path $psTestDataPath
#   Constants
##  The module name:
[string]$psModuleName           =   [System.IO.Path]::GetFileNameWithoutExtension($PSScriptRoot)
##  The expected manifest name:
[string]$psManifestName         =   "$($psModuleName).psd1"
##  The expected module manifest path:
[string]$psManifestPath         =   [System.IO.Path]::Combine($PSScriptRoot, $psManifestName)

##  The expected root module names:
[string[]]$psRootNames          =   $psTestData.psModuleExtensions.ForEach({
    "$($psModuleName)$($_)"
})

##  The expected directory structure:
[string[]]$psDirsShouldPresent  =   $psTestData.psDirsShouldPresent.ForEach({
    [System.IO.Path]::Combine($PSScriptRoot, $_)
})

Describe "General tests for the module: $psModuleName" {
    Context "Inventory: $psModuleName" {
        [hashtable[]]$psTestCasesFolders    =   @()
        $psDirsShouldPresent.ForEach({
            $psTestCasesFolders +=  @{
                FolderPath      =   $_
            }
        })

        It "Subfolders should be present" -TestCases $psTestCasesFolders {
            param(
                $FolderPath
            )
            [bool]$folderExists =   [System.IO.Directory]::Exists($folderPath)
            $folderExists       |   Should -BeTrue
        }

        It "Subfolders should contain scripts" {
            [string[]]$psScriptFiles    =   $psDirsShouldPresent.ForEach({
                [System.IO.Directory]::EnumerateFiles($_, '*.ps1')
            })
            $psScriptFiles.Count        |   Should -BeGreaterThan 0
        }

        It "The module file or manifest should be present" {
            [string[]]$rootFilesPresent = $psRootNames.ForEach({
                [System.IO.Directory]::EnumerateFiles($PSScriptRoot, $_)
            })
            [bool]$psRootExists     =   [System.IO.File]::Exists($psManifestPath) -or $rootFilesPresent.Count -ne 0
            $psRootExists           |   Should -BeTrue
        }
    }

    Context "General tests of the scripts" {
        [string[]][string[]]$psScriptFiles  =   $psDirsShouldPresent.ForEach({
            [System.IO.Directory]::EnumerateFiles($_, '*.ps1')
        }) -notmatch '\.tests\.ps1$'

        [hashtable[]]$psTestCasesScripts    =   @()
        $psScriptFiles.ForEach({
            $psTestCasesScripts +=  @{
                ScriptPath      =   $_
            }
        })

        It "Dot-sourcing the scripts" -TestCases $psTestCasesScripts {
            param(
                $ScriptPath
            )
            $psDotSourceResult  =   . $ScriptPath
            $psDotSourceResult  |   Should -BeNullOrEmpty
        }

        It "Invoke PSScriptAnalyzer for scripts" -TestCases $psTestCasesScripts {
            param (
                $ScriptPath
            )
            Invoke-ScriptAnalyzer   -Path $ScriptPath `
                                    -ExcludeRule $psTestData.psScriptAnalyzerRules.ExcludeRule `
                                    -Severity $psTestData.psScriptAnalyzerRules.Severity `
                                    | Should -BeNullOrEmpty
        }
    }

    if ([System.IO.File]::Exists($psManifestPath)) {
        Context "Testing the manifest $psManifestName" {
            It "Invoke PSScriptAnalyzer for the module manifest: $psManifestName" {
                Invoke-ScriptAnalyzer   -Path $psManifestPath `
                                        -ExcludeRule $psTestData.psScriptAnalyzerRules.Manifest.ExcludeRule `
                                        -Severity $psTestData.psScriptAnalyzerRules.Manifest.Severity `
                                        | Should -BeNullOrEmpty
            }

            It "Read the manifest: $psManifestPath" {
                $psManifestData                 =   Import-PowerShellDataFile -Path $psManifestPath
                $psManifestData                 |   Should -BeOfType 'System.Collections.Hashtable'
                [string]$psManifestRootModule   =   $psManifestData.RootModule
                if ($psManifestRootModule)
                {
                    [System.IO.Path]::GetExtension($psManifestRootModule)   | Should -Not -BeIn @('.ps1', '.psd1')
                }
            }
        }
    }

    Context "Test load: $psModuleName" {
        It "Get-Module $psModuleName" {
            $psModuleInfo       =   Get-Module -Name $PSScriptRoot -ListAvailable
            $psModuleInfo       |   Should -BeOfType 'System.Management.Automation.PSModuleInfo'
        }

        It "Import and remove module $psModuleName" {
            $psImportResult             =   Import-Module -Name $PSScriptRoot
            $psImportResult             |   Should -BeNullOrEmpty
            $psModuleInfo               =   Get-Module -Name $psModuleName
            $psModuleInfo               |   Should -BeOfType 'System.Management.Automation.PSModuleInfo'
            $psModuleInfo.Name          |   Should -BeExactly $psModuleName
            $psModuleInfo.ModuleBase    |   Should -BeExactly $PSScriptRoot
        }
    }
}
