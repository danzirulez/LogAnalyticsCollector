function Get-InstalledWindowsFeatures {
    <#
    .SYNOPSIS
    Retrieves a list of installed Windows features that are currently enabled.

    .DESCRIPTION
    This function queries the list of optional Windows features using the `Get-WindowsOptionalFeature` cmdlet.
    It filters and returns the enabled features, sorting them by the feature name. The result includes the feature name and its state.
    
    If an error occurs during retrieval, a warning is issued, and the function returns `$null`.

    .OUTPUTS
    Returns a list of custom objects containing the `FeatureName` and `State` of enabled Windows features.
    
    .EXAMPLE
    Get-InstalledWindowsFeatures
    Retrieves and displays a sorted list of all enabled Windows features.

    .NOTES
    The function utilizes the `Get-WindowsOptionalFeature` cmdlet, which requires Windows to be running in an online state.
    #>

    [CmdletBinding()]
    param()

    try {
        # Retrieve all Windows optional features that are enabled, and sort them by FeatureName
        return Get-WindowsOptionalFeature -Online |
            Where-Object { $_.State -eq 'Enabled' } |  # Filter for enabled features
            Sort-Object -Property FeatureName |         # Sort by feature name
            Select-Object -Property FeatureName, State -Unique  # Select unique features

    }
    catch {
        # Handle errors and issue a warning message
        Write-Warning "Failed to retrieve installed Windows features: $_"
        return $null  # Return null if an error occurs
    }
}
