<#
.SYNOPSIS
    This is the function for parsing fields 'Issuer' and 'Subject' of X509 certificates. The function accepts on input both a certificate and a string. The function returns a hashtable.
.DESCRIPTION
    This is the function for parsing fields 'Issuer' and 'Subject' of X509 certificates. The function accepts at the input both an object of type "[System.Security.Cryptography.X509Certificates.X509Certificate2]" and a [System.String]. The function returns an object of type [System.Collections.Hashtable]. Each of the keys of the hashtable is the name of the corresponding attribute of the X509 certificate field 'Subject' or 'Issuer'. E.g. '@{ CN = 'The common name', O = 'Organization' ... }'
.EXAMPLE
    PS C:\> Convert-CertificateDName -Certificate $certTest
    The function parses the field 'Subject' (default) from the X509 certificate "$certTest".
.EXAMPLE
    PS C:\> Convert-CertificateDName -Certificate $certTest -Field Subject
    The function parses the field 'Subject' from the X509 certificate "$certTest".
.EXAMPLE
    PS C:\> Convert-CertificateDName -Certificate $certTest -Field Issuer
    The function parses the field 'Issuer' from the X509 certificate "$certTest".
.EXAMPLE
    PS C:\> Convert-CertificateDName -InputString $subjectAsString
    The function parses the string "$subjectAsString".
.EXAMPLE
    PS C:\> Convert-CertificateDName -InputString $subjectAsString -SkipEmpty
    The function parses the string "$subjectAsString". Empty values of the subject attributes (if any) will be skipped. I really don't think you will ever need this parameter.
.EXAMPLE
    PS C:\> Convert-CertificateDName -InputString $subjectAsString -SkipDuplicates
    The function parses the string "$subjectAsString". If the subject contains more than one attributes with similar names, only first value of each will be added to output. I really don't think you will ever need this parameter.
.INPUTS
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    [System.String]
.OUTPUTS
    [System.Collections.Hashtable]
.NOTES
    General notes
#>
function Convert-CertificateDName {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Certificate',
            Position = 0
        )]
        # Certificate.
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(
            ParameterSetName = 'Certificate',
            Position = 1
        )]
        [ValidateSet('Subject','Issuer')]
        # Subject or issuer; default is 'Subject'.
        [System.String]
        $Field = 'Subject',

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'String',
            Position = 0
        )]
        # Input string; maybe subject or issuer.
        [System.String]
        $InputString,

        [Parameter()]
        # The switch defines whether to skip empty values of 'Subject' or 'Issuer' fields attributes.
        [System.Management.Automation.SwitchParameter]
        $SkipEmpty,

        [Parameter()]
        # The switch defines whether to skip duplicated values of 'Subject' or 'Issuer' fields attributes.
        [System.Management.Automation.SwitchParameter]
        $SkipDuplicates,

        [Parameter(
            DontShow = $true
        )]
        # Pattern for empty attribute values
        [System.String]
        $PatternEmpty = "^[`'`" ]*$"
    )
    [System.String]$myName = "[$($MyInvocation.MyCommand.Name)]:"
    Write-Verbose -Message "$myName Starting function..."

    if ($InputString)
    {
        try {
            Write-Verbose -Message "$myName Try to cast string `"$InputString`" as field `"$Field`" of type `"[System.Security.Cryptography.X509Certificates.X500DistinguishedName]`"..."
            [System.Security.Cryptography.X509Certificates.X500DistinguishedName]$certDName = $InputString
        }
        # When the input string does not match the format of the 'Subject' or 'Issuer' string.
        catch [System.InvalidCastException] {
            Write-Warning -Message "$myName Cannot convert string `"$InputString`"! Exiting."
            return
        }
        # All other errors
        catch {
            throw
        }
    }
    else
    {
        Write-Verbose -Message "$myName Parsing the $Field of the given certificate with thumbprint `"$($Certificate.Thumbprint)`"..."
        [System.String]$certPropName = "$($Field)Name"
        [System.Security.Cryptography.X509Certificates.X500DistinguishedName]$certDName = $Certificate.$certPropName
    }
    
    Write-Verbose -Message "$myName $Field found: $($certDName.Name)"
    [System.String]$certDNameFormatted = $certDName.Format($true)
    [System.Char[]]$charsToExclude = $certDNameFormatted.ToCharArray().Where({
        [System.Char]::IsControl($_)
    }) | Select-Object -Unique

    [System.String[]]$certDNameSplitted = $certDNameFormatted.Split($charsToExclude).Where({
        -not [System.String]::IsNullOrEmpty($_)
    })
    Write-Verbose -Message "$myName The $Field is formatted. Found $($certDNameSplitted.Count) attributes total. Converting into hashtable..."
    
    [System.Collections.Hashtable]$certSubjectTable = @{}
    $certDNameSplitted.ForEach({
        [System.String[]]$attribSplitted = $_.Split('=')
        [System.String]$attributeName = $attribSplitted[0]
        if ($attribSplitted.Count -gt 2)
        {
            Write-Warning -Message "$myName The value of the attribute `"$attributeName`" contains the character `"=`"!"
            [System.String]$attributeValue = [System.String]::Join('=', $attribSplitted[0..($attribSplitted.Count - 1)])
        }
        else
        {
            [System.String]$attributeValue = $attribSplitted[1]
        }

        if (-not $certSubjectTable.ContainsKey($attributeName))
        {
            Write-Verbose -Message "$myName Adding attribute `"$attributeName`" with value `"$attributeValue`"..."
            $certSubjectTable.$attributeName = $attributeValue
        }
        elseif (-not $SkipDuplicates)
        {
            Write-Warning -Message "$myName The attribute name `"$attributeName`" has already been found earlier! Hovever, adding the value `"$attributeValue`" to the output..."
            [System.String[]]$certSubjectTable.$attributeName += $attributeValue
        }
        else
        {
            Write-Warning -Message "$myName The attribute `"$attributeName`" has already been included in the output with the value `"$($certSubjectTable.$attributeName)`". The duplicated value `"$attributeValue`" will be SKIPPED!"
        }
    })

    if (-not $SkipEmpty)
    {
        Write-Verbose -Message "$myName End of function."
        return $certSubjectTable
    }

    Write-Verbose -Message "$myName Cleaning up empty values..."
    [System.String[]]$keysAll = $certSubjectTable.Keys
    [System.Collections.Generic.List[System.String]]$keysToRemove = [System.Collections.Generic.List[System.String]]::new()
    $keysAll.ForEach({
        [System.String]$keyName = $_
        [System.String[]]$valuesAll = $certSubjectTable.$keyName
        [System.String[]]$valuesEmpty = $valuesAll.Where({
            [System.String]::IsNullOrWhiteSpace($_) -or `
            [System.String]::IsNullOrEmpty($_) -or `
            [regex]::IsMatch($_, $PatternEmpty)
        })
        if ($valuesEmpty)
        {
            Write-Warning -Message "$myName Found $($valuesEmpty.Count) empty values for attribute `"$keyName`"."
        }
        [System.String[]]$valuesFiltered = $valuesAll.Where({
            $_ -notin $valuesEmpty
        })
        if ($valuesFiltered)
        {
            Write-Verbose -Message "$myName The attribute `"$keyName`" contains values which are not empty. Filtering."
            $certSubjectTable.$keyName = $valuesFiltered
        }
        else {
            $keysToRemove.Add($keyName)
            Write-Warning -Message "$myName The attribute `"$keyName`" does not contains values! Skipping."
        }
    })

    if ($keysToRemove)
    {
        $keysToRemove.ToArray().ForEach({
            Write-Verbose -Message "$myName Removing the attribute `"$_`" with empty value from the output table..."
            $certSubjectTable.Remove($_)
        })
    }
    
    Write-Verbose -Message "$myName Returning the parsed Distinguished Name without empty attributes. End of function"
    return $certSubjectTable
}
