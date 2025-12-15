# ========================================
# Quick Azure Setup - All Commands
# Author: Damir
# Date: 2025-01-15
# ========================================
# 
# Copy and paste these commands one by one into PowerShell
# 

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Configuration Variables
$RESOURCE_GROUP = "ObjectDetectionRG"
$LOCATION = "eastus"
$VISION_RESOURCE_NAME = "objectdetection-damir-$(Get-Date -Format 'yyyyMMddHHmm')"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Azure Computer Vision Quick Setup" -ForegroundColor Cyan
Write-Host "Author: Damir" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resource Group: $RESOURCE_GROUP" -ForegroundColor Yellow
Write-Host "Location: $LOCATION" -ForegroundColor Yellow
Write-Host "Resource Name: $VISION_RESOURCE_NAME" -ForegroundColor Yellow
Write-Host ""

# COMMAND 1: Login to Azure
Write-Host "STEP 1: Logging in to Azure..." -ForegroundColor Green
az login

# COMMAND 2: Create Resource Group
Write-Host ""
Write-Host "STEP 2: Creating Resource Group..." -ForegroundColor Green
az group create --name $RESOURCE_GROUP --location $LOCATION

# COMMAND 3: Create Computer Vision Resource
Write-Host ""
Write-Host "STEP 3: Creating Computer Vision Resource (this may take 1-2 minutes)..." -ForegroundColor Green
az cognitiveservices account create `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --kind ComputerVision `
  --sku S1 `
  --location $LOCATION `
  --yes

# COMMAND 4: Get Endpoint
Write-Host ""
Write-Host "STEP 4: Getting Endpoint URL..." -ForegroundColor Green
$ENDPOINT = az cognitiveservices account show `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query properties.endpoint `
  --output tsv

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Your Endpoint URL:" -ForegroundColor Green
Write-Host $ENDPOINT -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# COMMAND 5: Assign Permissions
Write-Host "STEP 5: Assigning Permissions..." -ForegroundColor Green
$USER_ID = az ad signed-in-user show --query id --output tsv
$RESOURCE_ID = az cognitiveservices account show `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query id `
  --output tsv

az role assignment create `
  --role "Cognitive Services User" `
  --assignee $USER_ID `
  --scope $RESOURCE_ID

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Azure Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# COMMAND 6: Update Blazor appsettings.json
Write-Host "STEP 6: Updating Blazor Configuration..." -ForegroundColor Green
$appsettingsPath = "ObjectDetectionBlazor\appsettings.json"
if (Test-Path $appsettingsPath) {
    $appsettings = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
    $appsettings.AzureComputerVision.Endpoint = $ENDPOINT
    $appsettings | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath
    Write-Host "? Blazor appsettings.json updated!" -ForegroundColor Green
} else {
    Write-Host "? Could not find appsettings.json" -ForegroundColor Yellow
}

# COMMAND 7: Set Environment Variable for MAUI
Write-Host ""
Write-Host "STEP 7: Setting Environment Variable for MAUI..." -ForegroundColor Green
$env:AZURE_COMPUTER_VISION_ENDPOINT = $ENDPOINT
Write-Host "? Environment variable set for current session!" -ForegroundColor Green
Write-Host ""
Write-Host "To make it permanent, add to your system or user environment variables:" -ForegroundColor Yellow
Write-Host "  Variable: AZURE_COMPUTER_VISION_ENDPOINT" -ForegroundColor White
Write-Host "  Value: $ENDPOINT" -ForegroundColor White
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resource Group: $RESOURCE_GROUP" -ForegroundColor White
Write-Host "Computer Vision: $VISION_RESOURCE_NAME" -ForegroundColor White
Write-Host "Endpoint: $ENDPOINT" -ForegroundColor Cyan
Write-Host ""
Write-Host "Blazor Config: Updated ?" -ForegroundColor Green
Write-Host "MAUI Env Var: Set for current session ?" -ForegroundColor Green
Write-Host ""

# Save configuration
Write-Host "Saving configuration to azure-config.txt..." -ForegroundColor Yellow
$configContent = @"
Azure Computer Vision Configuration
====================================
Created: $(Get-Date)
Author: Damir

Resource Group: $RESOURCE_GROUP
Location: $LOCATION
Computer Vision Resource: $VISION_RESOURCE_NAME
Endpoint: $ENDPOINT

Blazor Configuration:
  File: ObjectDetectionBlazor/appsettings.json
  Updated: Yes

MAUI Configuration:
  Environment Variable: AZURE_COMPUTER_VISION_ENDPOINT
  Value: $ENDPOINT

Next Steps:
1. Test Blazor: cd ObjectDetectionBlazor; dotnet run
2. Test MAUI: cd ObjectDetectionMaui; dotnet build
3. Navigate to: http://localhost:5000/objectdetection

Author: Damir
Repository: https://github.com/vende6/VS2026-.net10-playground
"@

$configContent | Out-File -FilePath "azure-config.txt" -Encoding UTF8
Write-Host "? Configuration saved to azure-config.txt" -ForegroundColor Green
Write-Host ""

# Test Commands
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Your Applications" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Blazor Web App:" -ForegroundColor Yellow
Write-Host "  cd ObjectDetectionBlazor" -ForegroundColor White
Write-Host "  dotnet run" -ForegroundColor White
Write-Host "  Open: http://localhost:5000/objectdetection" -ForegroundColor Cyan
Write-Host ""
Write-Host "MAUI App:" -ForegroundColor Yellow
Write-Host "  cd ObjectDetectionMaui" -ForegroundColor White
Write-Host "  dotnet build -f net10.0-windows10.0.19041.0" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "All Done! ??" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Author: Damir" -ForegroundColor Cyan
Write-Host "Repository: https://github.com/vende6/VS2026-.net10-playground" -ForegroundColor Cyan
Write-Host ""
