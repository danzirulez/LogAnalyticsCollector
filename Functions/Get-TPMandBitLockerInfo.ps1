<#
.SYNOPSIS
    Retrieves TPM (Trusted Platform Module) and BitLocker information for the system.

.DESCRIPTION
    This function collects information about the system's TPM status (such as whether it is present, enabled, activated, etc.) and 
    gathers BitLocker details for all volumes on the system (such as volume status, encryption method, and protection status).
    
    If TPM or BitLocker information is unavailable, the function will return warnings but continue to provide available data.

.EXAMPLE
    Get-TPMandBitLockerInfo
    This command retrieves and returns the TPM and BitLocker information for the current system.

.NOTES
    - The `Get-Tpm` cmdlet requires the system to have TPM hardware and drivers installed.
    - The `Get-BitLockerVolume` cmdlet requires administrative privileges.
    - This function returns a custom object with TPM and BitLocker details, making it easy to further process or display the results.
#>

function Get-TPMandBitLockerInfo {
    [CmdletBinding()]
    param()

    # Initialize result object with default values
    $result = [PSCustomObject]@{
        TPM       = $null
        BitLocker = $null
    }

    # Attempt to retrieve TPM information
    try {
        $tpm = Get-Tpm
        $result.TPM = [PSCustomObject]@{
            TpmPresent       = $tpm.TpmPresent
            TpmReady         = $tpm.TpmReady
            TpmEnabled       = $tpm.TpmEnabled
            TpmActivated     = $tpm.TpmActivated
            TpmOwned         = $tpm.TpmOwned
            ManufacturerId   = $tpm.ManufacturerIdTxt
            ManufacturerVersion = $tpm.ManufacturerVersion
            ManagedAuthLevel = $tpm.ManagedAuthLevel
        }
    } catch {
        Write-Warning "TPM information could not be retrieved: $_"
    }

    # Attempt to retrieve BitLocker information for all volumes
    try {
        $volumes = Get-BitLockerVolume
        $blList = foreach ($vol in $volumes) {
            # Construct a custom object for each volume's BitLocker status
            [PSCustomObject]@{
                MountPoint        = $vol.MountPoint
                VolumeType        = $vol.VolumeType
                CapacityGB        = $vol.CapacityGB
                VolumeStatus      = $vol.VolumeStatus
                EncryptionMethod  = $vol.EncryptionMethod
                ProtectionStatus  = $vol.ProtectionStatus
                EncryptionPercent = $vol.EncryptionPercentage
                AutoUnlockEnabled = $vol.AutoUnlockEnabled
                KeyProtectors     = ($vol.KeyProtector | ForEach-Object { $_.KeyProtectorType }) -join ', '
            }
        }
        $result.BitLocker = $blList
    } catch {
        Write-Warning "BitLocker information could not be retrieved: $_"
        return $null
    }

    # Return the result containing both TPM and BitLocker details
    return $result
}
