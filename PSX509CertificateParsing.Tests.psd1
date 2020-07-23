@{
    psModuleExtensions  =   @(
        '.psm1'
        '.xaml'
        '.cdxml'
        '.dll'
    )

    psDirsShouldPresent =   @(
        'Functions'
        'Functions\Private'
        'Functions\Public'
    )

    psScriptAnalyzerRules   =   @{
        Severity    =   'Error'
        #   Error
        #   Information
        #   ParseError
        #   Warning
        IncludeRule =   @()
        ExcludeRule =   @(
            'PSAvoidTrailingWhitespace'
            'PSReviewUnusedParameter'
        )

        Manifest            =   @{
            Severity    = 'Warning'
            IncludeRule =   @()
            ExcludeRule =   @(
                'PSUseToExportFieldsInManifest'
            )
        }

        PrivateFunctions    =   @{
            Severity    =   'Error'
            #   Error
            #   Information
            #   ParseError
            #   Warning
            IncludeRule =   @()
            ExcludeRule =   @(
                'PSAvoidTrailingWhitespace'
                'PSReviewUnusedParameter'
                'PSUseApprovedVerbs'
                'PSUseSingularNouns'
            )
        }

        PublicFunctions    =   @{
            Severity    =   'Information'
            #   Error
            #   Information
            #   ParseError
            #   Warning
            IncludeRule =   @()
            ExcludeRule =   @(
                'PSReviewUnusedParameter'
            )
        }
    }
}
