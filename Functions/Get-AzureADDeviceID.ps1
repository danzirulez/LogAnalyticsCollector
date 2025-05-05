function Get-AzureADDeviceID {
    <#
    .SYNOPSIS
        Retrieves the Azure AD Device ID from the local registry and certificate store.

    .DESCRIPTION
        This function queries the registry and certificate store for Azure AD device information. 
        It retrieves the device ID from the machine's certificate subject, based on the thumbprint stored in the registry.

    .EXAMPLE
        $deviceID = Get-AzureADDeviceID
        Write-Output "Device ID: $deviceID"

    .NOTES
        Author: DanZi
        Last Updated: 2025-05-05
    #>

    try {
        # Define Cloud Domain Join information registry path
        $AzureADJoinInfoRegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"

        # Check if the registry path exists
        if (Test-Path -Path $AzureADJoinInfoRegistryKeyPath) {
            # Retrieve the child key name that is the thumbprint of the machine certificate containing the device identifier GUID
            $AzureADJoinInfoThumbprint = Get-ChildItem -Path $AzureADJoinInfoRegistryKeyPath | Select-Object -ExpandProperty "PSChildName"

            if ($AzureADJoinInfoThumbprint) {
                # Retrieve the machine certificate based on thumbprint from the registry key
                $AzureADJoinCertificate = Get-ChildItem -Path "Cert:\LocalMachine\My" -Recurse | Where-Object { $_.Thumbprint -eq $AzureADJoinInfoThumbprint }
                
                if ($AzureADJoinCertificate) {
                    # Extract the device identifier from the certificate subject
                    $AzureADDeviceID = ($AzureADJoinCertificate | Select-Object -ExpandProperty "Subject") -replace "CN=", ""
                    return $AzureADDeviceID
                } else {
                    Write-Warning "Machine certificate with thumbprint $AzureADJoinInfoThumbprint not found in the local certificate store."
                }
            } else {
                Write-Warning "Azure AD Join information thumbprint not found in registry."
            }
        } else {
            Write-Warning "Registry path not found: $AzureADJoinInfoRegistryKeyPath"
        }
    }
    catch {
        Write-Error "An error occurred while retrieving the Device ID: $_"
    }
}

