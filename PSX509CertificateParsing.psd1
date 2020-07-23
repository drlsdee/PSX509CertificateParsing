@{
    RootModule = 'PSX509CertificateParsing.psm1'
    ModuleVersion = '0.0.0.0'
    GUID = 'f46e0906-e83e-4589-a5dc-ae89c93b1c77'
    Author = 'drlsdee '
    CompanyName = 'Unknown'
    Copyright = '(c) 2020 drlsdee  <tracert0@gmail.com>. All rights reserved.'
    Description = 'A suite of PowerShell scripts for parsing various x509 certificate fields.'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'Convert-CertificateDName'
    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/drlsdee/PSX509CertificateParsing'
            ReleaseNotes = '''Convert-CertificateDName.ps1'': the comment-help updated with a parameters description. Also some spelling fixes in comments and in verbose output messages ;) The module ''PSX509CertificateParsing.psm1'': added treating for the cases when the expected subfolders ''Functions'', ''Functions\Public'', ''Functions\Private'' were not found.'
        }
    }
}

