function Get-DellDockInfo {
    <#
    .SYNOPSIS
    Retrieves information about Dell docking stations installed on the system.

    .DESCRIPTION
    This function checks if the Dell OpenManage Inventory Agent is installed on the machine. 
    If it is, it retrieves the docking station information using the 'Dell_SoftwareIdentity' WMI class 
    in the 'root\Dell\SysInv' namespace. The function specifically filters out devices whose ElementName starts with "WD",
    typically representing Dell docking stations.

    If the Dell OpenManage Inventory Agent is not installed or the necessary WMI class is unavailable, 
    the function will return appropriate messages to inform the user.

    .PARAMETER None
    This function does not require any input parameters.

    .OUTPUTS
    Returns a collection of docking station objects, each containing:
        - ElementName
        - SerialNumber
        - VersionString
    If no docking stations are found, it returns $null.

    .EXAMPLE
    Get-DellDockInfo
    Retrieves a list of Dell docking stations (if installed) with their ElementName, SerialNumber, and VersionString.

    .NOTES
    Requires the Dell OpenManage Inventory Agent to be installed on the system. 
    This function is specific to Dell systems using the OpenManage software suite.

    #>
    
    # Define the path to the Dell System Management Agent executable.
    $dsiaPath = "C:\Program Files (x86)\Dell\SysMgt\dsia\bin\DsiaSrv32.exe"

    # Check if the Dell System Management Agent is installed.
    if (Test-Path $dsiaPath) {
        # Try to get the Dell_SoftwareIdentity WMI class.
        $class = Get-WmiObject -Class 'Dell_SoftwareIdentity' -Namespace 'root\Dell\SysInv' -ErrorAction SilentlyContinue
        
        # If the class exists, proceed with getting docking station information.
        if ($class) {
            # Get all docking stations that match the ElementName starting with "WD"
            $dockingStations = Get-WmiObject -Namespace 'root\Dell\SysInv' -Class 'Dell_SoftwareIdentity' |
                Where-Object { $_.ElementName -like "WD*" }

            # Return the selected properties for each docking station.
            return $dockingStations | Select-Object ElementName, SerialNumber, VersionString
        } else {
            # If the WMI class is not found, inform the user and return null.
            Write-Output "Dell_SoftwareIdentity class not found. Ensure Dell OpenManage Inventory is installed and configured."
            return $null
        }
    } else {
        # If the Dell System Management Agent is not installed, inform the user and return null.
        Write-Output "Dell OpenManage Inventory Agent is not installed. Please install the necessary software for docking station information."
        return $null
    }
}

