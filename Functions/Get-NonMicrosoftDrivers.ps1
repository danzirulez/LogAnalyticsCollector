function Get-NonMicrosoftDrivers {
    <#
    .SYNOPSIS
        Retrieves all non-Microsoft signed drivers installed on the system.

    .DESCRIPTION
        This function queries the `Win32_PnPSignedDriver` class to retrieve details about all non-Microsoft signed drivers on the system.
        It filters out drivers provided by Microsoft and returns information such as the driver name, version, date, device class, device ID, manufacturer, INF file name, and device location.

    .OUTPUTS
        Returns an array of custom objects containing the details of each non-Microsoft signed driver.

    .EXAMPLE
        Get-NonMicrosoftDrivers
        Retrieves and displays details for all non-Microsoft signed drivers installed on the system.

    .NOTES
        The `Win32_PnPSignedDriver` class is used to gather information about drivers installed on the system.
        Author: DanZi
        Last Updated: 2025-05-05
    #>

    [CmdletBinding()]
    param()

    try {
        # Query all signed drivers except Microsoft's
        $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver |
                   Where-Object { $_.DriverProviderName -ne 'Microsoft' } |
                   Select-Object ` 
                     @{Name='DriverName'; Expression = { $_.DeviceName }}, `  # Driver's device name
                     DriverVersion,                                          # Driver version
                     @{Name='DriverDate'; Expression = { $_.ConvertToDateTime($_.DriverDate) }}, # Driver date (converted to DateTime format)
                     DeviceClass,                                            # Driver's device class
                     DeviceID,                                               # Driver's device ID
                     Manufacturer,                                           # Manufacturer of the device
                     InfName,                                                # INF file name for the driver
                     Location                                                # Location of the device
       
        # Initialize an ArrayList to hold driver objects
        $list = [System.Collections.ArrayList]::new()

        # Iterate over each driver and add it to the list
        foreach ($d in $drivers) { 
            [void]$list.Add($d)
        }

        # Return the list of non-Microsoft signed drivers
        return $list
    }
    catch {
        # Handle any errors and issue a warning message
        Write-Warning "Failed to retrieve non-Microsoft drivers: $_"
        return $null  # Return null if an error occurs
    }
}
