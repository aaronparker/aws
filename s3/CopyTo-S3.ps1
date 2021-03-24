<#
    .SYNOPSIS
        Copy folder structure to an S3 bucket for apps
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $False)]
    [System.String] $SourcePath = "\\server\DeploymentShare\Applications",

    [Parameter(Mandatory = $False)]
    [System.String] $DestBucket = "s3://stealthpuppy01/apps",

    [Parameter(Mandatory = $False)]
    [System.String] $CsvFile = ".\Applications.csv",

    [Parameter(Mandatory = $False)]
    [System.Management.Automation.SwitchParameter] $DryRun,

    [Parameter(Mandatory = $False)]
    [System.Management.Automation.SwitchParameter] $WhatIf
)

# Get contents of applications CSV file
$AppsList = Get-Content -Path $CsvFile | ConvertFrom-Csv
If ($PSBoundParameters.ContainsKey("WhatIf")) { $DryRunCmd = "--dryrun" }

# Copy each folder to the S3 bucket
ForEach ($Application in $AppsList) {

    # Configure source and destination
    $source = Join-Path -Path $SourcePath -ChildPath $Application.Application
    $destination = "$DestBucket/$($Application.Vendor)/$($Application.Name)/$($Application.Version)"
    Write-Host "Application: $($Application.Application)" -ForegroundColor "Cyan"
    Write-Host "Source:      $source"
    Write-Host "Destination: $destination"

    try {
        $params = @{
            FilePath     = "aws"
            ArgumentList = "s3 cp `"$source`" `"$destination`" --recursive $DryRunCmd"
            PassThru     = $true
            ErrorAction  = "Stop"
            Wait         = $True
            NoNewWindow  = $True
        }
        If ($PSBoundParameters.ContainsKey("WhatIf")) { $params.WhatIf = $True }
        $result = Start-Process @params
    }
    catch {
        Write-Warning $_.Exception.Message
        Break
    }
    Write-Host "Complete."
}
