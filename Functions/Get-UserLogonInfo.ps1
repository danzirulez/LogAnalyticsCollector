function Get-UserLogonInfo {
    <#
    .SYNOPSIS
        Retrieves user logon information, including the count of successful logon events for each user.

    .DESCRIPTION
        This function retrieves successful logon events (Event ID 4624) from the Security event log over the past specified number of days (default is 7 days).
        It processes the events, filtering out system and service accounts, and returns a list of usernames along with the count of logons.
    
        If the device is domain-joined, it attempts to resolve the username to its corresponding User Principal Name (UPN) using Active Directory.
        The function returns a list of unique users, their UPN, and the number of logons.

    .PARAMETER DaysBack
        The number of days to look back for logon events. The default value is 7 days.
    
    .OUTPUTS
        Returns a list of custom objects containing the UPN (User Principal Name) and the count of logons (LogonCount) for each user.

    .EXAMPLE
        Get-UserLogonInfo
        Retrieves user logon information from the past 7 days, including the UPN and logon count for each user.

    .EXAMPLE
        Get-UserLogonInfo -DaysBack 30
        Retrieves user logon information from the past 30 days, including the UPN and logon count for each user.

    .NOTES
        This function relies on Event ID 4624 from the Windows Security log to identify successful logons.
        If the machine is domain-joined, the function will attempt to resolve the logon username to the UPN using Active Directory.
        Author: DanZi
        Last Updated: 2025-05-05
    #>

    [CmdletBinding()]
    param(
        [int]$DaysBack = 7
    )

    # Helper function to convert DNS domain to BaseDN
    function Convert-DnsToBaseDN {
        param([string]$DnsDomain)
        return ($DnsDomain.Split('.') | ForEach-Object { "DC=$_" }) -join ','
    }

    # Define exclusion patterns for service and system accounts
    $excludedPatterns = @(
        '^ANONYMOUS LOGON$',
        '^NETWORK SERVICE$',
        '^LOCAL SERVICE$',
        '^SYSTEM$',
        '^DWM-',
        '^UMFD-',
        '^SA-',
        '\$$'  # Accounts ending with $
    )

    # Retrieve logon events (Event ID 4624) from the Security log
    $startTime = (Get-Date).AddDays(-$DaysBack)
    $events = Get-WinEvent -FilterHashtable @{
        LogName   = 'Security'
        Id        = 4624
        StartTime = $startTime
    }

    # Determine if the device is domain-joined
    $cs = Get-CimInstance Win32_ComputerSystem
    $isDomainJoined = $cs.PartOfDomain

    # Extract usernames from events and filter out excluded patterns
    $users = $events |
        ForEach-Object {
            $username = $_.Properties[5].Value
            if ($username -and -not ($excludedPatterns | Where-Object { $username -match $_ })) {
                $username
            }
        }

    # Group usernames and count occurrences
    $userGroups = $users | Group-Object | Select-Object Name, Count

    # Initialize DirectorySearcher for domain-joined devices
    if ($isDomainJoined) {
        $baseDn = Convert-DnsToBaseDN -DnsDomain $env:USERDNSDOMAIN
        $adRoot = [ADSI]"LDAP://$baseDn"
        $ds = New-Object System.DirectoryServices.DirectorySearcher($adRoot)
        $ds.PropertiesToLoad.Add('userPrincipalName') | Out-Null
    }

    # Compile the list of user logon information
    $userLogonList = [System.Collections.ArrayList]::new()
    foreach ($group in $userGroups) {
        $upn = $group.Name
        if ($isDomainJoined) {
            # Attempt to resolve the UPN using Active Directory (by sAMAccountName)
            $ds.Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$($group.Name)))"
            $result = $ds.FindOne()
            if ($result) {
                $upn = $result.Properties['userPrincipalname'][0]
            }
        }

        # Create a custom object to store UPN and LogonCount
        $userLogon = [PSCustomObject]@{
            UPN         = $upn
            LogonCount  = $group.Count
        }
        [void]$userLogonList.Add($userLogon)
    }

    return $userLogonList
}

