<#
.SYNOPSIS
    Update Azure Computer Vision Endpoints Script

.DESCRIPTION
    PowerShell script to update Azure Computer Vision endpoints in configuration files.
    Retrieves endpoint from existing Azure resources or accepts manual input.
    Updates appsettings.json and sets environment variables.

.AUTHOR
    Damir

.VERSION
    1.0.0

.DATE
    2025-01-15

.REPOSITORY
    https://github.com/vende6/VS2026-.net10-playground

.LICENSE
    MIT License

.EXAMPLE
    .\update-azure-endpoints.ps1
    Updates endpoints from existing Azure resources interactively

.EXAMPLE
    .\update-azure-endpoints.ps1 -ResourceGroup "MyRG" -VisionResourceName "my-vision"
    Updates endpoints from specific Azure resource

.EXAMPLE
    .\update-azure-endpoints.ps1 -Endpoint "https://my-vision.cognitiveservices.azure.com/"
    Updates endpoints with a manually provided URL
#>

param(
    [string]$ResourceGroup,
    [string]$VisionResourceName,
    [string]$Endpoint
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Azure Endpoint Update Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Function to update JSON file
function Update-JsonEndpoint {
    param(
        [string]$FilePath,
        [string]$NewEndpoint
    )
    
    if (Test-Path $FilePath) {
        try {
            $json = Get-Content $FilePath -Raw | ConvertFrom-Json
            
            # Create AzureComputerVision object if it doesn't exist
            if (-not $json.AzureComputerVision) {
                $json | Add-Member -MemberType NoteProperty -Name "AzureComputerVision" -Value @{} -Force
            }
            
            # Update or add Endpoint property
            if ($json.AzureComputerVision.PSObject.Properties.Name -contains "Endpoint") {
                $json.AzureComputerVision.Endpoint = $NewEndpoint
            } else {
                $json.AzureComputerVision | Add-Member -MemberType NoteProperty -Name "Endpoint" -Value $NewEndpoint -Force
            }
            
            # Save with proper formatting
            $json | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
            Write-Host "  ? Updated: $FilePath" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "  ? Failed to update: $FilePath" -ForegroundColor Red
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "  ? File not found: $FilePath" -ForegroundColor Yellow
        return $false
    }
}

# Step 1: Determine the endpoint
$visionEndpoint = $Endpoint

if (-not $visionEndpoint) {
    # Check if Azure CLI is available
    try {
        $azVersion = az version 2>&1 | Out-Null
        $azCliAvailable = $LASTEXITCODE -eq 0
    } catch {
        $azCliAvailable = $false
    }

    if ($azCliAvailable) {
        Write-Host "?? Azure CLI detected" -ForegroundColor Green
        
        # Check if logged in
        try {
            $accountInfo = az account show 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "? Not logged in to Azure. Logging in..." -ForegroundColor Yellow
                az login --output none
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "? Azure login failed" -ForegroundColor Red
                    $azCliAvailable = $false
                }
            }
        } catch {
            $azCliAvailable = $false
        }
        
        if ($azCliAvailable) {
            # List available Computer Vision resources
            Write-Host "?? Searching for Computer Vision resources..." -ForegroundColor Yellow
            
            if ($ResourceGroup -and $VisionResourceName) {
                # Use provided resource group and name
                Write-Host "?? Using provided resource: $VisionResourceName in $ResourceGroup" -ForegroundColor Cyan
                
                $visionEndpoint = az cognitiveservices account show `
                    --name $VisionResourceName `
                    --resource-group $ResourceGroup `
                    --query properties.endpoint `
                    --output tsv 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "? Resource not found: $VisionResourceName in $ResourceGroup" -ForegroundColor Red
                    $visionEndpoint = $null
                }
            } else {
                # List all Computer Vision resources
                $visionResources = az cognitiveservices account list `
                    --query "[?kind=='ComputerVision'].{name:name, group:resourceGroup, endpoint:properties.endpoint}" `
                    --output json | ConvertFrom-Json
                
                if ($visionResources -and $visionResources.Count -gt 0) {
                    Write-Host ""
                    Write-Host "Found $($visionResources.Count) Computer Vision resource(s):" -ForegroundColor Green
                    Write-Host ""
                    
                    for ($i = 0; $i -lt $visionResources.Count; $i++) {
                        Write-Host "  [$($i + 1)] $($visionResources[$i].name)" -ForegroundColor Cyan
                        Write-Host "      Resource Group: $($visionResources[$i].group)" -ForegroundColor Gray
                        Write-Host "      Endpoint: $($visionResources[$i].endpoint)" -ForegroundColor Gray
                        Write-Host ""
                    }
                    
                    # Prompt user to select
                    if ($visionResources.Count -eq 1) {
                        Write-Host "Using the only available resource..." -ForegroundColor Yellow
                        $visionEndpoint = $visionResources[0].endpoint
                    } else {
                        do {
                            $selection = Read-Host "Select resource number (1-$($visionResources.Count)) or 'M' for manual entry"
                            
                            if ($selection -eq 'M' -or $selection -eq 'm') {
                                break
                            }
                            
                            $selectionNum = [int]$selection
                        } while ($selectionNum -lt 1 -or $selectionNum -gt $visionResources.Count)
                        
                        if ($selection -ne 'M' -and $selection -ne 'm') {
                            $visionEndpoint = $visionResources[$selectionNum - 1].endpoint
                        }
                    }
                } else {
                    Write-Host "? No Computer Vision resources found in your subscription" -ForegroundColor Yellow
                }
            }
        }
    }
    
    # If still no endpoint, prompt for manual entry
    if (-not $visionEndpoint) {
        Write-Host ""
        Write-Host "Please enter your Azure Computer Vision endpoint manually:" -ForegroundColor Yellow
        Write-Host "Example: https://your-resource-name.cognitiveservices.azure.com/" -ForegroundColor Gray
        $visionEndpoint = Read-Host "Endpoint URL"
    }
}

# Validate endpoint format
if (-not $visionEndpoint) {
    Write-Host "? No endpoint provided. Exiting." -ForegroundColor Red
    exit 1
}

if ($visionEndpoint -notmatch '^https?://') {
    Write-Host "? Warning: Endpoint should start with https:// or http://" -ForegroundColor Yellow
    Write-Host "Current value: $visionEndpoint" -ForegroundColor Gray
}

# Ensure endpoint ends with /
if (-not $visionEndpoint.EndsWith('/')) {
    $visionEndpoint = $visionEndpoint + '/'
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Updating Endpoints" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Target Endpoint: $visionEndpoint" -ForegroundColor Cyan
Write-Host ""

# Step 2: Update configuration files
Write-Host "?? Updating configuration files..." -ForegroundColor Yellow
Write-Host ""

$updateCount = 0
$failCount = 0

# Update Blazor appsettings.json
$blazorAppsettings = "ObjectDetectionBlazor\appsettings.json"
if (Update-JsonEndpoint -FilePath $blazorAppsettings -NewEndpoint $visionEndpoint) {
    $updateCount++
} else {
    $failCount++
}

# Update Blazor appsettings.Development.json if it exists
$blazorDevAppsettings = "ObjectDetectionBlazor\appsettings.Development.json"
if (Test-Path $blazorDevAppsettings) {
    if (Update-JsonEndpoint -FilePath $blazorDevAppsettings -NewEndpoint $visionEndpoint) {
        $updateCount++
    } else {
        $failCount++
    }
}

Write-Host ""

# Step 3: Set environment variables
Write-Host "?? Setting environment variables..." -ForegroundColor Yellow
Write-Host ""

try {
    # Set for current session
    $env:AZURE_COMPUTER_VISION_ENDPOINT = $visionEndpoint
    $env:AzureComputerVision__Endpoint = $visionEndpoint
    
    Write-Host "  ? Session variables set:" -ForegroundColor Green
    Write-Host "    - AZURE_COMPUTER_VISION_ENDPOINT" -ForegroundColor Gray
    Write-Host "    - AzureComputerVision__Endpoint" -ForegroundColor Gray
    Write-Host ""
    
    # Optionally set user environment variable
    Write-Host "Would you like to set these as permanent user environment variables? (y/n): " -NoNewline -ForegroundColor Cyan
    $setPermanent = Read-Host
    
    if ($setPermanent -eq 'y' -or $setPermanent -eq 'Y') {
        [System.Environment]::SetEnvironmentVariable("AZURE_COMPUTER_VISION_ENDPOINT", $visionEndpoint, "User")
        [System.Environment]::SetEnvironmentVariable("AzureComputerVision__Endpoint", $visionEndpoint, "User")
        Write-Host "  ? Permanent environment variables set" -ForegroundColor Green
    }
} catch {
    Write-Host "  ? Failed to set environment variables: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Step 4: Update azure-config.txt
Write-Host "?? Updating configuration file..." -ForegroundColor Yellow
$configFile = "azure-config.txt"

$configContent = @"
Azure Computer Vision Configuration
====================================
Updated: $(Get-Date)
Author: Damir

Computer Vision Endpoint: $visionEndpoint

Blazor App Configuration (appsettings.json):
{
  "AzureComputerVision": {
    "Endpoint": "$visionEndpoint"
  }
}

MAUI App Environment Variable (PowerShell):
`$env:AZURE_COMPUTER_VISION_ENDPOINT="$visionEndpoint"

MAUI App Environment Variable (Bash):
export AZURE_COMPUTER_VISION_ENDPOINT="$visionEndpoint"

.NET Configuration Environment Variable (PowerShell):
`$env:AzureComputerVision__Endpoint="$visionEndpoint"

.NET Configuration Environment Variable (Bash):
export AzureComputerVision__Endpoint="$visionEndpoint"

Authentication:
- Uses DefaultAzureCredential
- Supports Azure CLI, Visual Studio, Managed Identity
- Ensure you're logged in: az login

"@

$configContent | Out-File -FilePath $configFile -Encoding UTF8
Write-Host "  ? Configuration saved to: $configFile" -ForegroundColor Green
Write-Host ""

# Step 5: Summary
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Update Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  • Files updated: $updateCount" -ForegroundColor $(if ($updateCount -gt 0) { "Green" } else { "Gray" })
Write-Host "  • Files failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host "  • Endpoint: $visionEndpoint" -ForegroundColor Cyan
Write-Host ""

if ($updateCount -gt 0) {
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Verify you're logged in to Azure: " -NoNewline -ForegroundColor White
    Write-Host "az login" -ForegroundColor Cyan
    Write-Host "2. Test the Blazor app: " -NoNewline -ForegroundColor White
    Write-Host "cd ObjectDetectionBlazor; dotnet run" -ForegroundColor Cyan
    Write-Host "3. Test the MAUI app: " -NoNewline -ForegroundColor White
    Write-Host "cd ObjectDetectionMaui; dotnet build" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "? All endpoints have been updated successfully!" -ForegroundColor Green
} else {
    Write-Host "? No files were updated. Please check the errors above." -ForegroundColor Yellow
}

Write-Host ""
