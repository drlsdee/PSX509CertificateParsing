param (
    # Path to folder with X509 certificate file (with extension '.cer')
    [Parameter()]
    [string]
    $PathToFolder,

    # Toggle verbose output
    [Parameter()]
    [switch]
    $Msg
)

function Test-CertDName {
    [CmdletBinding()]
    param (
        # Path to folder
        [Parameter()]
        [string]
        $PathToFolder
    )
    [string]$certFilePath = [System.IO.Directory]::EnumerateFiles($PathToFolder, '*.cer')[0]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$certTest = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromCertFile($certFilePath)
    [string[]]$moduleScripts = [System.IO.Directory]::EnumerateFiles($PSScriptRoot, '*.psm1')
    [string[]]$moduleNames = $moduleScripts.ForEach({
        [System.IO.Path]::GetFileNameWithoutExtension($_)
    })
    $moduleScripts.ForEach({
        Import-Module -Name $_
    })

    Write-Host -ForegroundColor Yellow -Object "Reading subject from certificate file: $certFilePath"
    Convert-CertificateDName -Certificate $certTest -Field Subject

    Write-Host -ForegroundColor Yellow -Object "Reading issuer from certificate file: $certFilePath"
    Convert-CertificateDName -Certificate $certTest -Field Issuer

    $moduleNames.ForEach({
        Remove-Module -Name $_
    })
}
Test-CertDName -PathToFolder $PathToFolder -Verbose:$Msg