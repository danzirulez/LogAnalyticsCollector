<#
.SYNOPSIS
    Retrieves the Azure AD Tenant ID from the local registry on an Azure AD-joined device.

.DESCRIPTION
    This function queries the registry path where Azure AD tenant information is stored on Azure AD-joined devices.
    It returns the Tenant ID associated with the device's Azure AD registration.

.EXAMPLE
    $tenantID = Get-AzureADTenantID
    Write-Output "Tenant ID: $tenantID"

.NOTES
    Author: DanZi
    Last Updated: 2025-05-05
#>
function Get-AzureADTenantID {
    try {
        # Cloud Join information registry path
        $AzureADTenantInfoRegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo"
        
        # Check if the registry path exists
        if (Test-Path -Path $AzureADTenantInfoRegistryKeyPath) {
            # Retrieve the child key name that is the tenant ID for Azure AD
            $AzureADTenantID = Get-ChildItem -Path $AzureADTenantInfoRegistryKeyPath | Select-Object -ExpandProperty "PSChildName"
            
            if ($AzureADTenantID) {
                return $AzureADTenantID
            } else {
                Write-Warning "Tenant ID not found in registry under the expected path."
            }
        } else {
            Write-Warning "Registry path not found: $AzureADTenantInfoRegistryKeyPath"
        }
    }
    catch {
        Write-Error "An error occurred while retrieving the Tenant ID: $_"
    }
}

