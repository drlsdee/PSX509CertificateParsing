@{
    RootModule = 'PSX509CertificateParsing.psm1'
    ModuleVersion = '0.0.0.1'
    GUID = 'f46e0906-e83e-4589-a5dc-ae89c93b1c77'
    Author = 'drlsdee '
    CompanyName = 'Unknown'
    Copyright = '(c) 2020 drlsdee  <tracert0@gmail.com>. All rights reserved.'
    Description = 'A suite of PowerShell scripts for parsing various x509 certificate fields.'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'Convert-CertificateDName'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = 'Convert-CertificateIssuer', 'Convert-CertificateSubject'
    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/drlsdee/PSX509CertificateParsing'
            ReleaseNotes = 'Added build script. Added alias for the function "Convert-CertificateDName".'
        }
    }
}

