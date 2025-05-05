function Get-BatteryInfo {
    <#
    .SYNOPSIS
    Retrieves detailed battery information for the system, including the designed capacity, full-charged capacity, and lifecycle percentage.

    .DESCRIPTION
    This function queries WMI to gather battery-related data:
    - Retrieves static battery information, such as device name, manufacturer, serial number, and designed capacity.
    - Queries the full-charged capacity for each battery.
    - Computes the lifecycle percentage based on the designed and full-charged capacities.
    
    If a battery's designed capacity is available, it calculates the percentage of the full-charged capacity relative to the designed capacity. It also handles the case where full-charged capacity data is missing.

    .OUTPUTS
    Returns an array of custom objects containing the battery device name, manufacturer, serial number, designed capacity, full-charged capacity, and lifecycle percentage (if available).

    .EXAMPLE
    Get-BatteryInfo
    Retrieves and displays detailed battery information including the lifecycle percentage of each battery.

    .NOTES
    This function uses the `BatteryStaticData` and `BatteryFullChargedCapacity` WMI classes to gather battery data.
    #>

    [CmdletBinding()]
    param()

    try {
        # Query static battery data
        $batteries = Get-WmiObject -Namespace "ROOT\WMI" -Class "BatteryStaticData" -ErrorAction SilentlyContinue |
                     Select-Object DeviceName, ManufactureName, SerialNumber, DesignedCapacity, InstanceName

        # Query full-charged capacity data
        $fullCaps = Get-WmiObject -Namespace "ROOT\WMI" -Class "BatteryFullChargedCapacity" -ErrorAction SilentlyContinue |
                    Select-Object InstanceName, FullChargedCapacity

        # Initialize ArrayList to hold battery data
        $list = [System.Collections.ArrayList]::new()

        # Iterate over each battery entry
        foreach ($bat in $batteries) {
            # Find matching full-charged entry based on InstanceName
            $match = $fullCaps | Where-Object { $_.InstanceName -eq $bat.InstanceName }

            if ($match) {
                # Add FullChargedCapacity and calculate lifecycle percentage
                $bat | Add-Member -MemberType NoteProperty -Name FullChargedCapacity -Value $match.FullChargedCapacity -Force
                $lifecycle = if ($bat.DesignedCapacity -gt 0) {
                    [math]::Round(100 * $match.FullChargedCapacity / $bat.DesignedCapacity, 0)  # Calculate lifecycle percentage
                } else { 
                    0  # If no designed capacity, set lifecycle percentage to 0
                }
                $bat | Add-Member -MemberType NoteProperty -Name LifecyclePercent -Value $lifecycle -Force
            } else {
                # If no match found, set FullChargedCapacity and LifecyclePercent to null
                $bat | Add-Member -MemberType NoteProperty -Name FullChargedCapacity -Value $null -Force
                $bat | Add-Member -MemberType NoteProperty -Name LifecyclePercent -Value $null -Force
            }

            # Add the battery object to the list
            [void]$list.Add($bat)
        }

        # Return the list of battery information
        return $list
    }
    catch {
        # Handle any errors and issue a warning
        Write-Warning "Failed to retrieve battery information: $_"
        return $null  # Return null if an error occurs
    }
}
