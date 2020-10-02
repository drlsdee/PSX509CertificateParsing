function Split-DistinguishedName {
    [CmdletBinding()]
    param (
        # A string containing distinguished name
        [Parameter(Mandatory)]
        [string]
        $InputObject,

        # Order to join distinguished name back
        [Parameter()]
        [ValidateSet(
            'Forward',
            'Reverse',
            'None'
        )]
        [string]
        $Join,

        # Attributes to exclude
        [Parameter(ParameterSetName = 'Exclude')]
        [ValidateSet(
            'CN',
            'OU',
            'DC'
        )]
        [string[]]
        $ExcludeAttribute,

        # Attributes to preserve
        [Parameter(ParameterSetName = 'Preserve')]
        [ValidateSet(
            'CN',
            'OU',
            'DC'
        )]
        [string[]]
        $IncludeAttribute
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    #   Cast input string as [System.Security.Cryptography.X509Certificates.X500DistinguishedName]
    try {
        [System.Security.Cryptography.X509Certificates.X500DistinguishedName]$stringCasted  = [System.Security.Cryptography.X509Certificates.X500DistinguishedName]::new($InputObject)
    }
    catch [System.Security.Cryptography.CryptographicException] {
        throw "$myName String is invalid: `'$InputObject`'"
    }
    catch {
        throw $_
    }
    #   Format and split string and remove non-printable characters: '\p{C}'
    #   Thanks to: https://stackoverflow.com/a/40568888
    [string[]]$stringsFormatted  = $stringCasted.Format($true) -split '\n' -replace '\p{C}'
    switch ($true) {
        ($null -ne $ExcludeAttribute)   {
            Write-Verbose -Message "$myName EXCLUDE attributes: $($ExcludeAttribute -join ', ')"
            #   Create regex for excluding attributes:
            [regex]$attributesToExclude     = $ExcludeAttribute.ForEach({"^$_="}) -join '|'
            [string[]]$stringsFiltered      = $stringsFormatted -notmatch $attributesToExclude
        }
        ($null -ne $IncludeAttribute)   {
            Write-Verbose -Message "$myName Preserving ONLY following attributes: $($IncludeAttribute -join ', ')"
            #   Create regex for preserving attributes:
            [regex]$attributesToPreserve    = $IncludeAttribute.ForEach({"^$_="}) -join '|'
            [string[]]$stringsFiltered      = $stringsFormatted -match $attributesToPreserve
        }
        Default {
            Write-Verbose -Message "$myName None of the attributes will be filtered."
            [string[]]$stringsFiltered      = $stringsFormatted
        }
    }
    switch ($Join) {
        'Forward'   {
            Write-Verbose -Message "$myName Join strings in selected order: `'$Join`'. The function will return the filtered string joined in the same order as the input string."
            [string]$stringOld = [string]::Empty
            [string]$stringJoined = [string]::Empty
            for ( $i = 0; $i -lt $stringsFiltered.Count; $i ++ ) {
                [string]$stringCurrent = $stringsFiltered[$i]
                [string]$stringJoined = [string]::Join(',', [string[]]($stringCurrent, $stringOld).Where({$_}) )
                [string]$stringOld = $stringJoined
                Write-Debug -Message "$myName Current string: `'$stringJoined`'"
            }
            return $stringJoined
        }
        'Reverse'   {
            Write-Verbose -Message "$myName Join strings in selected order: `'$Join`'. The function will return the filtered string joined in the opposite order of the input string."
            [string]$stringOld = [string]::Empty
            [string]$stringJoined = [string]::Empty
            for ( $i = $stringsFiltered.Count - 1; $i -ge 0; $i -- ) {
                [string]$stringCurrent = $stringsFiltered[$i]
                [string]$stringJoined = [string]::Join(',', [string[]]($stringCurrent, $stringOld).Where({$_}) )
                [string]$stringOld = $stringJoined
                Write-Debug -Message "$myName Current string: `'$stringJoined`'"
            }
            return $stringJoined
        }
        'None'      {
            Write-Verbose -Message "$myName Join action selected: `'$Join`'. Returning splitted string."
            return $stringsFiltered
        }
        Default     {
            Write-Verbose -Message "$myName Join action not selected. Returning splitted string."
            return $stringsFiltered
        }
    }
}
