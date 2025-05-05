function Get-ScreenInfo {
    <#
    .SYNOPSIS
    Retrieves detailed information about connected monitors, including manufacturer, serial number, and manufacturing details.

    .DESCRIPTION
    This function queries the `WmiMonitorID` class for monitor details, such as the manufacturer, user-friendly name, serial number, and the year and week of manufacture.
    It also collects the computer's hostname, IP address, and the currently logged-in user.

    .OUTPUTS
    Returns a collection of custom objects containing monitor details, including manufacturer information, serial number, and more.

    .EXAMPLE
    Get-ScreenInfo
    Retrieves and displays information about the monitors connected to the system.

    .NOTES
    The `WmiMonitorID` class is used to gather information about connected monitors, and the `NetIPConfiguration` is used to get the computer's IP address.
    The manufacturer names are mapped using a predefined lookup table.
    #>

    [CmdletBinding()]
    param()

    # Manufacturer lookup table for monitor acronyms
    $acronymsTable = @{
        'ACI'='Asus (ASUSTeK Computer Inc.)'; 'ACR'='Acer America Corp.'; 'ACT'='Targa'; 
        'ADI'='ADI Corporation'; 'AMW'='AMW'; 'AOC'='AOC International (USA) Ltd.'; 
        'API'='Acer America Corp.'; 'APP'='Apple Computer Inc.'; 'ART'='ArtMedia'; 
        'AST'='AST Research'; 'AUO'='AU Optronics'; 'BMM'='BMM'; 
        'BNQ'='BenQ Corporation'; 'BOE'='BOE Display Technology'; 'CPL'='Compal Electronics Inc.'; 
        'CPQ'='COMPAQ Computer Corp.'; 'CTX'='CTX / Chuntex Electronic Co.'; 'DEC'='Digital Equipment Corporation'; 
        'DEL'='Dell Computer Corp.'; 'DPC'='Delta Electronics Inc.'; 'DWE'='Daewoo Telecom Ltd'; 
        'ECS'='ELITEGROUP Computer Systems'; 'EIZ'='EIZO'; 'EPI'='Envision Peripherals Inc.'; 
        'FCM'='Funai Electric Company of Taiwan'; 'FUS'='Fujitsu Siemens'; 'GSM'='LG Electronics Inc. (GoldStar Technology Inc.)'; 
        'GWY'='Gateway 2000'; 'HEI'='Hyundai Electronics Industries Co. Ltd.'; 'HIQ'='Hyundai ImageQuest'; 
        'HIT'='Hitachi'; 'HSD'='Hannspree Inc'; 'HSL'='Hansol Electronics'; 'HTC'='Hitachi Ltd. / Nissei Sangyo America Ltd.'; 
        'HWP'='Hewlett Packard (HP)'; 'IBM'='IBM PC Company'; 'ICL'='Fujitsu ICL'; 'IFS'='InFocus'; 
        'IQT'='Hyundai'; 'IVM'='Idek Iiyama North America Inc.'; 'KDS'='KDS USA'; 'KFC'='KFC Computek'; 
        'LEN'='Lenovo'; 'LGD'='LG Display'; 'LKM'='ADLAS / AZALEA'; 'LNK'='LINK Technologies Inc.'; 
        'LPL'='LG Philips'; 'LTN'='Lite-On'; 'MAG'='MAG InnoVision'; 'MAX'='Maxdata Computer GmbH'; 
        'MEI'='Panasonic Comm. & Systems Co.'; 'MEL'='Mitsubishi Electronics'; 'MIR'='Miro Computer Products AG'; 
        'MTC'='MITAC'; 'NAN'='NANAO'; 'NEC'='NEC Technologies Inc.'; 'NOK'='Nokia'; 'NVD'='Nvidia'; 
        'OQI'='OPTIQUEST'; 'PBN'='Packard Bell'; 'PCK'='Daewoo'; 'PDC'='Polaroid'; 'PGS'='Princeton Graphic Systems'; 
        'PHL'='Philips Consumer Electronics Co.'; 'PRT'='Princeton'; 'REL'='Relisys'; 'SAM'='Samsung'; 
        'SEC'='Seiko Epson Corporation'; 'SMC'='Samtron'; 'SMI'='Smile'; 'SNI'='Siemens Nixdorf'; 
        'SNY'='Sony Corporation'; 'SPT'='Sceptre'; 'SRC'='Shamrock Technology'; 'STN'='Samtron'; 
        'STP'='Sceptre'; 'TAT'='Tatung Co. of America Inc.'; 'TRL'='Royal Information Company'; 
        'TSB'='Toshiba Inc.'; 'UNM'='Unisys Corporation'; 'VSC'='ViewSonic Corporation'; 
        'WTC'='Wen Technology'; 'ZCM'='Zenith Data Systems'; 'HPN'='Hewlett Packard (HP)'
    }

    # Helper function to decode byte arrays into strings
    function Decode-String {
        param([byte[]]$bytes)
        try {
            return ([System.Text.Encoding]::ASCII.GetString($bytes)).Trim([char]0)
        } catch { return $null }
    }

    try {
        # Retrieve monitor information using WmiMonitorID
        $wmiMonitors = Get-WmiObject -Namespace root\wmi -Class WmiMonitorID

        # Get the system's IP address, excluding disconnected network adapters
        $hostIP = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -ne 'Disconnected' } | Select-Object -First 1).IPv4Address.IPAddress

        # Retrieve the currently logged-in user
        $user = (Get-CimInstance Win32_ComputerSystem).Username

        # Iterate through each monitor and build a custom object with relevant details
        $screens = foreach ($m in $wmiMonitors) {
            # Decode manufacturer name, friendly name, and serial number
            $manCode = Decode-String $m.ManufacturerName
            $friendly = Decode-String $m.UserFriendlyName
            $serial = Decode-String $m.SerialNumberID

            # Create a custom object for each monitor's details
            [PSCustomObject]@{
                Hostname          = $env:COMPUTERNAME
                IPAddress         = $hostIP
                LoggedOnUser      = $user
                Manufacturer      = ($acronymsTable[$manCode] -or 'Unknown')
                FriendlyName      = ($friendly -or 'Unknown')
                SerialNumber      = ($serial -or 'Unknown')
                YearOfManufacture = $m.YearOfManufacture
                WeekOfManufacture = $m.WeekOfManufacture
            }
        }

        return $screens
    }
    catch {
        Write-Warning "Failed to retrieve monitor info: $_"
        return $null  # Return null if an error occurs
    }
}
