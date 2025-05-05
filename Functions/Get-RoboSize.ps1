<#
.SYNOPSIS
    Calculates the total size of files in a specified directory using `robocopy` to avoid recursively traversing the file system multiple times.
    
.DESCRIPTION
    This function uses `robocopy` in list-only mode (`/L`) to calculate the total size of files in a specified path. 
    It supports multi-threaded copying (`/MT`), meaning it can quickly process large directories by leveraging multiple threads.
    The function returns the total size in bytes, kilobytes, megabytes, and gigabytes, along with the time taken for the operation.
    
.PARAMETER Path
    The path to the directory for which the size should be calculated. This parameter is mandatory.

.PARAMETER DecimalPrecision
    Specifies the number of decimal places to display for size and elapsed time. Default is 2.

.PARAMETER Threads
    Defines the number of threads to use for the `robocopy` operation. The default is twice the number of processor cores, up to a maximum of 16 threads.

.EXAMPLE
    Get-RoboSize -Path "C:\MyFolder"
    This command will calculate the total size of files in `C:\MyFolder` and return the result in bytes, kilobytes, megabytes, and gigabytes.

.EXAMPLE
    Get-RoboSize -Path "C:\MyFolder" -DecimalPrecision 3 -Threads 8
    This command will calculate the size of `C:\MyFolder` with a precision of 3 decimal places and use 8 threads for the `robocopy` operation.

.NOTES
    Robocopy should be available in the system PATH for this function to work.
    The function returns a custom object with the calculated size in different units and the time taken to perform the calculation.
#>

function Get-RoboSize {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$DecimalPrecision = 2,

        [Parameter(Mandatory = $false)]
        [int]$Threads = ([Math]::Min(16, [Environment]::ProcessorCount * 2))
    )

    # Check if the provided path exists
    if (-not (Test-Path $Path)) {
        Write-Warning "The specified path '$Path' does not exist."
        return [PSCustomObject]@{
            Path        = $Path
            TotalBytes  = 0
            TotalKB     = 0
            TotalMB     = 0
            TotalGB     = 0
            TimeElapsed = 0
        }
    }

    # Ensure robocopy is available
    if (-not (Get-Command -Name 'robocopy' -ErrorAction SilentlyContinue)) {
        throw "The robocopy command is not available. Please ensure robocopy is installed and available in your PATH."
    }

    # Log the action
    Write-Verbose "Using robocopy to calculate the size of the path: '$Path'"

    # Prepare robocopy arguments
    $args = @(
        "/L", "/S", "/NJH", "/BYTES", "/FP", "/NC",
        "/NDL", "/TS", "/XJ", "/R:0", "/W:0", "/MT:$Threads"
    )

    # Start the time measurement
    [datetime]$startTime = Get-Date

    # Run robocopy and capture the output summary
    try {
        $summary = robocopy $Path NULL $args | Select-Object -Last 8
    } catch {
        throw "Robocopy encountered an error while processing the path '$Path'. $_"
    }

    # End the time measurement
    [datetime]$endTime = Get-Date

    # Parse the byte count from the summary output
    $byteCount = 0
    foreach ($line in $summary) {
        if ($line -match 'Bytes\s*:\s*(?<ByteCount>\d+)') {
            $byteCount = [decimal]$Matches['ByteCount']
            break
        }
    }

    # Return the formatted results as a custom object
    return [PSCustomObject]@{
        Path        = $Path
        TotalBytes  = $byteCount
        TotalKB     = [math]::Round($byteCount / 1KB, $DecimalPrecision)
        TotalMB     = [math]::Round($byteCount / 1MB, $DecimalPrecision)
        TotalGB     = [math]::Round($byteCount / 1GB, $DecimalPrecision)
        TimeElapsed = [math]::Round(($endTime - $startTime).TotalSeconds, $DecimalPrecision)
    }
}
