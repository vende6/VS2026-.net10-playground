<#
.SYNOPSIS
    Azure Computer Vision Setup Script for Object Detection

.DESCRIPTION
    Automated PowerShell script to create Azure Computer Vision resource
    and configure authentication for object detection applications.
    Creates resource group, Computer Vision service, and assigns roles.

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
    .\setup-azure-vision.ps1
    Creates all Azure resources with default names

.EXAMPLE
    .\setup-azure-vision.ps1 -ResourceGroup "MyRG" -Location "westus"
    Creates resources with custom resource group name and location
#>

param(
    [string]$ResourceGroup = "ObjectDetectionRG",
    [string]$Location = "eastus",
    [string]$VisionResourceName = "objectdetection-vision-$(Get-Date -Format 'yyyyMMddHHmmss')"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Azure Computer Vision Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
try {
    $azVersion = az version 2>&1
    Write-Host "? Azure CLI found" -ForegroundColor Green
} catch {
    Write-Host "? Azure CLI is not installed" -ForegroundColor Red
    Write-Host "Please install from: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Login to Azure
Write-Host "? Logging in to Azure..." -ForegroundColor Yellow
az login --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "? Azure login failed" -ForegroundColor Red
    exit 1
}

Write-Host "? Successfully logged in to Azure" -ForegroundColor Green

# Get subscription ID
$SubscriptionId = az account show --query id --output tsv
Write-Host "? Using subscription: $SubscriptionId" -ForegroundColor Yellow

# Create Resource Group
Write-Host "? Creating resource group: $ResourceGroup in $Location..." -ForegroundColor Yellow
az group create `
    --name $ResourceGroup `
    --location $Location `
    --output none

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Resource group created: $ResourceGroup" -ForegroundColor Green
} else {
    Write-Host "? Failed to create resource group" -ForegroundColor Red
    exit 1
}

# Create Computer Vision Resource
Write-Host "? Creating Computer Vision resource: $VisionResourceName..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Gray

az cognitiveservices account create `
    --name $VisionResourceName `
    --resource-group $ResourceGroup `
    --kind ComputerVision `
    --sku S1 `
    --location $Location `
    --yes `
    --output none

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Computer Vision resource created: $VisionResourceName" -ForegroundColor Green
} else {
    Write-Host "? Failed to create Computer Vision resource" -ForegroundColor Red
    exit 1
}

# Get the endpoint
$VisionEndpoint = az cognitiveservices account show `
    --name $VisionResourceName `
    --resource-group $ResourceGroup `
    --query properties.endpoint `
    --output tsv

Write-Host "? Computer Vision endpoint: $VisionEndpoint" -ForegroundColor Green

# Get the key (for reference, though we use Managed Identity)
$VisionKey = az cognitiveservices account keys list `
    --name $VisionResourceName `
    --resource-group $ResourceGroup `
    --query key1 `
    --output tsv

# Get your user object ID for role assignment
$UserObjectId = az ad signed-in-user show --query id --output tsv

# Get the resource ID
$VisionResourceId = az cognitiveservices account show `
    --name $VisionResourceName `
    --resource-group $ResourceGroup `
    --query id `
    --output tsv

# Assign Cognitive Services User role to your user
Write-Host "? Assigning Cognitive Services User role to your account..." -ForegroundColor Yellow
az role assignment create `
    --role "Cognitive Services User" `
    --assignee $UserObjectId `
    --scope $VisionResourceId `
    --output none

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Role assigned successfully" -ForegroundColor Green
} else {
    Write-Host "? Failed to assign role (you may already have it)" -ForegroundColor Yellow
}

# Output summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resource Group: " -NoNewline; Write-Host $ResourceGroup -ForegroundColor Cyan
Write-Host "Location: " -NoNewline; Write-Host $Location -ForegroundColor Cyan
Write-Host "Computer Vision Resource: " -NoNewline; Write-Host $VisionResourceName -ForegroundColor Cyan
Write-Host "Endpoint: " -NoNewline; Write-Host $VisionEndpoint -ForegroundColor Cyan
Write-Host ""

Write-Host "Configuration for appsettings.json:" -ForegroundColor Yellow
Write-Host "--------------------" -ForegroundColor Gray
Write-Host @"
"AzureComputerVision": {
  "Endpoint": "$VisionEndpoint"
}
"@ -ForegroundColor White
Write-Host "--------------------" -ForegroundColor Gray
Write-Host ""

Write-Host "Environment Variable (for MAUI):" -ForegroundColor Yellow
Write-Host "--------------------" -ForegroundColor Gray
Write-Host "`$env:AZURE_COMPUTER_VISION_ENDPOINT=`"$VisionEndpoint`"" -ForegroundColor White
Write-Host "--------------------" -ForegroundColor Gray
Write-Host ""

Write-Host "For reference (use Managed Identity instead):" -ForegroundColor Yellow
Write-Host "Key: $VisionKey" -ForegroundColor Gray
Write-Host ""

# Save configuration to file
$ConfigFile = "azure-config.txt"
$ConfigContent = @"
Azure Computer Vision Configuration
====================================
Created: $(Get-Date)
Author: Damir

Resource Group: $ResourceGroup
Location: $Location
Subscription ID: $SubscriptionId
Computer Vision Resource: $VisionResourceName
Endpoint: $VisionEndpoint
Resource ID: $VisionResourceId

Blazor App Configuration (appsettings.json):
{
  "AzureComputerVision": {
    "Endpoint": "$VisionEndpoint"
  }
}

MAUI App Environment Variable (PowerShell):
`$env:AZURE_COMPUTER_VISION_ENDPOINT="$VisionEndpoint"

MAUI App Environment Variable (Bash):
export AZURE_COMPUTER_VISION_ENDPOINT="$VisionEndpoint"

Key (for reference - use Managed Identity instead):
$VisionKey
"@

$ConfigContent | Out-File -FilePath $ConfigFile -Encoding UTF8
Write-Host "? Configuration saved to: " -NoNewline -ForegroundColor Green
Write-Host $ConfigFile -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update ObjectDetectionBlazor/appsettings.json with the endpoint" -ForegroundColor White
Write-Host "2. Set environment variable for MAUI app" -ForegroundColor White
Write-Host "3. Ensure you're logged in with 'az login'" -ForegroundColor White
Write-Host "4. Test the applications!" -ForegroundColor White
Write-Host ""

# Prompt to update appsettings.json automatically
Write-Host "Would you like to automatically update appsettings.json now? (y/n): " -NoNewline -ForegroundColor Cyan
$response = Read-Host

if ($response -eq 'y' -or $response -eq 'Y') {
    $appsettingsPath = "ObjectDetectionBlazor\appsettings.json"
    
    if (Test-Path $appsettingsPath) {
        $appsettings = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
        $appsettings.AzureComputerVision.Endpoint = $VisionEndpoint
        $appsettings | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath
        
        Write-Host "? appsettings.json updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "? Could not find appsettings.json at $appsettingsPath" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Setup script completed!" -ForegroundColor Green
