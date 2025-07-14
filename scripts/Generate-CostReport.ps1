#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.CostManagement, Az.Resources

<#
.SYNOPSIS
    Azure Cost Report Generator PowerShell Script

.DESCRIPTION
    This script generates cost reports for Azure subscriptions and resource groups
    using PowerShell and the Az modules.

.PARAMETER SubscriptionId
    The Azure subscription ID to generate reports for

.PARAMETER Environment
    The environment name (dev, staging, prod)

.PARAMETER ReportType
    The type of report to generate (daily, weekly, monthly)

.PARAMETER OutputPath
    The path to save the generated reports

.EXAMPLE
    .\Generate-CostReport.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -Environment "dev" -ReportType "daily"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment = 'dev',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('daily', 'weekly', 'monthly')]
    [string]$ReportType = 'daily',
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = './reports'
)

# Import required modules
try {
    Import-Module Az.Accounts -Force
    Import-Module Az.CostManagement -Force
    Import-Module Az.Resources -Force
    Write-Host "Required modules imported successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to import required modules: $_"
    exit 1
}

# Ensure we're connected to Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "No Azure context found. Please run Connect-AzAccount first." -ForegroundColor Red
        exit 1
    }
    
    # Set the subscription context
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "Using subscription: $SubscriptionId" -ForegroundColor Green
}
catch {
    Write-Error "Failed to set Azure context: $_"
    exit 1
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

function Get-CostData {
    param(
        [string]$Scope,
        [string]$ReportType
    )
    
    try {
        # Define time period
        $endDate = Get-Date
        switch ($ReportType) {
            'monthly' {
                $startDate = Get-Date $endDate.Year, $endDate.Month, 1
            }
            'weekly' {
                $startDate = $endDate.AddDays(-7)
            }
            default { # daily
                $startDate = $endDate.AddDays(-1)
            }
        }
        
        # Format dates for API
        $fromDate = $startDate.ToString('yyyy-MM-dd')
        $toDate = $endDate.ToString('yyyy-MM-dd')
        
        Write-Host "Fetching cost data from $fromDate to $toDate for scope: $Scope" -ForegroundColor Yellow
        
        # Create query definition
        $queryDefinition = @{
            Type = 'ActualCost'
            Timeframe = 'Custom'
            TimePeriod = @{
                From = $fromDate
                To = $toDate
            }
            Dataset = @{
                Granularity = 'Daily'
                Aggregation = @{
                    totalCost = @{
                        Name = 'PreTaxCost'
                        Function = 'Sum'
                    }
                }
                Grouping = @(
                    @{
                        Type = 'Dimension'
                        Name = 'ResourceGroup'
                    },
                    @{
                        Type = 'Dimension'
                        Name = 'ServiceName'
                    }
                )
            }
        }
        
        # Execute cost management query
        $result = Invoke-AzCostManagementQuery -Scope $Scope -Definition $queryDefinition
        
        return $result
    }
    catch {
        Write-Error "Failed to fetch cost data: $_"
        return $null
    }
}

function Export-CostDataToCsv {
    param(
        [object]$CostData,
        [string]$FilePath
    )
    
    try {
        if ($CostData -and $CostData.Row) {
            # Convert to objects for CSV export
            $costRecords = @()
            foreach ($row in $CostData.Row) {
                $record = [PSCustomObject]@{
                    Date = $row[0]
                    PreTaxCost = [decimal]$row[1]
                    Currency = $row[2]
                    ResourceGroup = $row[3]
                    ServiceName = $row[4]
                }
                $costRecords += $record
            }
            
            $costRecords | Export-Csv -Path $FilePath -NoTypeInformation
            Write-Host "Cost data exported to: $FilePath" -ForegroundColor Green
            
            return $costRecords
        }
        else {
            Write-Warning "No cost data to export"
            return @()
        }
    }
    catch {
        Write-Error "Failed to export cost data to CSV: $_"
        return @()
    }
}

function Export-CostDataToJson {
    param(
        [object[]]$CostRecords,
        [string]$FilePath
    )
    
    try {
        $CostRecords | ConvertTo-Json -Depth 3 | Out-File -FilePath $FilePath -Encoding utf8
        Write-Host "Cost data exported to: $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export cost data to JSON: $_"
    }
}

function Generate-SummaryReport {
    param(
        [object[]]$CostRecords,
        [string]$Environment,
        [string]$ReportType,
        [string]$FilePath
    )
    
    try {
        if ($CostRecords.Count -eq 0) {
            Write-Warning "No cost records to summarize"
            return
        }
        
        # Calculate summary statistics
        $totalCost = ($CostRecords | Measure-Object -Property PreTaxCost -Sum).Sum
        $avgDailyCost = ($CostRecords | Group-Object Date | ForEach-Object { 
            ($_.Group | Measure-Object -Property PreTaxCost -Sum).Sum 
        } | Measure-Object -Average).Average
        
        $resourceGroupCosts = $CostRecords | Group-Object ResourceGroup | ForEach-Object {
            [PSCustomObject]@{
                ResourceGroup = $_.Name
                TotalCost = ($_.Group | Measure-Object -Property PreTaxCost -Sum).Sum
            }
        } | Sort-Object TotalCost -Descending
        
        $serviceCosts = $CostRecords | Group-Object ServiceName | ForEach-Object {
            [PSCustomObject]@{
                ServiceName = $_.Name
                TotalCost = ($_.Group | Measure-Object -Property PreTaxCost -Sum).Sum
            }
        } | Sort-Object TotalCost -Descending
        
        # Create summary object
        $summary = [PSCustomObject]@{
            Environment = $Environment
            ReportType = $ReportType
            GeneratedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
            TotalCost = [math]::Round($totalCost, 2)
            AverageDailyCost = [math]::Round($avgDailyCost, 2)
            ResourceGroupCount = ($CostRecords | Select-Object ResourceGroup -Unique).Count
            ServiceCount = ($CostRecords | Select-Object ServiceName -Unique).Count
            TopResourceGroups = $resourceGroupCosts | Select-Object -First 5
            TopServices = $serviceCosts | Select-Object -First 5
        }
        
        $summary | ConvertTo-Json -Depth 3 | Out-File -FilePath $FilePath -Encoding utf8
        Write-Host "Summary report generated: $FilePath" -ForegroundColor Green
        
        # Display summary to console
        Write-Host "`n=== COST SUMMARY ===" -ForegroundColor Cyan
        Write-Host "Environment: $Environment" -ForegroundColor White
        Write-Host "Report Type: $ReportType" -ForegroundColor White
        Write-Host "Total Cost: $($summary.TotalCost)" -ForegroundColor Green
        Write-Host "Average Daily Cost: $($summary.AverageDailyCost)" -ForegroundColor Green
        Write-Host "Resource Groups: $($summary.ResourceGroupCount)" -ForegroundColor White
        Write-Host "Services: $($summary.ServiceCount)" -ForegroundColor White
        
        Write-Host "`nTop 5 Resource Groups by Cost:" -ForegroundColor Yellow
        $summary.TopResourceGroups | ForEach-Object {
            Write-Host "  $($_.ResourceGroup): $($_.TotalCost)" -ForegroundColor White
        }
        
        Write-Host "`nTop 5 Services by Cost:" -ForegroundColor Yellow
        $summary.TopServices | ForEach-Object {
            Write-Host "  $($_.ServiceName): $($_.TotalCost)" -ForegroundColor White
        }
    }
    catch {
        Write-Error "Failed to generate summary report: $_"
    }
}

# Main execution
Write-Host "Starting Azure Cost Report Generation" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor White
Write-Host "Report Type: $ReportType" -ForegroundColor White
Write-Host "Subscription: $SubscriptionId" -ForegroundColor White

# Define scope (subscription level)
$scope = "/subscriptions/$SubscriptionId"

# Fetch cost data
$costData = Get-CostData -Scope $scope -ReportType $ReportType

if ($costData) {
    # Generate timestamp for file names
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    
    # Export to CSV
    $csvFile = Join-Path $OutputPath "cost_data_${Environment}_${ReportType}_${timestamp}.csv"
    $costRecords = Export-CostDataToCsv -CostData $costData -FilePath $csvFile
    
    # Export to JSON
    $jsonFile = Join-Path $OutputPath "cost_data_${Environment}_${ReportType}_${timestamp}.json"
    Export-CostDataToJson -CostRecords $costRecords -FilePath $jsonFile
    
    # Generate summary report
    $summaryFile = Join-Path $OutputPath "cost_summary_${Environment}_${ReportType}_${timestamp}.json"
    Generate-SummaryReport -CostRecords $costRecords -Environment $Environment -ReportType $ReportType -FilePath $summaryFile
    
    Write-Host "`nCost report generation completed successfully!" -ForegroundColor Green
    Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
}
else {
    Write-Error "Failed to generate cost report - no data retrieved"
    exit 1
}
