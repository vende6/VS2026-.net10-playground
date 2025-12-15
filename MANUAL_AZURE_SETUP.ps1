# Azure Computer Vision Setup - Manual Commands
# Author: Damir
# Date: 2025-01-15
# 
# Azure CLI is installed (version 2.81.0)
# Run these commands in PowerShell to complete the setup

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Azure Computer Vision Manual Setup" -ForegroundColor Cyan
Write-Host "Author: Damir" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Configuration
$RESOURCE_GROUP = "ObjectDetectionRG"
$LOCATION = "eastus"
$VISION_RESOURCE_NAME = "objectdetection-damir-$(Get-Date -Format 'yyyyMMddHHmm')"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $RESOURCE_GROUP" -ForegroundColor White
Write-Host "  Location: $LOCATION" -ForegroundColor White
Write-Host "  Resource Name: $VISION_RESOURCE_NAME" -ForegroundColor White
Write-Host ""

# Step 1: Login
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 1: Login to Azure" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Running: az login" -ForegroundColor Yellow
Write-Host "A browser window will open for authentication..." -ForegroundColor Gray
Write-Host ""
Write-Host "Copy and run this command:" -ForegroundColor Green
Write-Host "az login" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter after you've logged in..." -ForegroundColor Yellow
Read-Host

# Step 2: Create Resource Group
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 2: Create Resource Group" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Copy and run this command:" -ForegroundColor Green
Write-Host "az group create --name $RESOURCE_GROUP --location $LOCATION" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter after resource group is created..." -ForegroundColor Yellow
Read-Host

# Step 3: Create Computer Vision Resource
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 3: Create Computer Vision Resource" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This may take 1-2 minutes..." -ForegroundColor Gray
Write-Host ""
Write-Host "Copy and run this command:" -ForegroundColor Green
Write-Host "az cognitiveservices account create ``" -ForegroundColor White
Write-Host "  --name $VISION_RESOURCE_NAME ``" -ForegroundColor White
Write-Host "  --resource-group $RESOURCE_GROUP ``" -ForegroundColor White
Write-Host "  --kind ComputerVision ``" -ForegroundColor White
Write-Host "  --sku S1 ``" -ForegroundColor White
Write-Host "  --location $LOCATION ``" -ForegroundColor White
Write-Host "  --yes" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter after Computer Vision is created..." -ForegroundColor Yellow
Read-Host

# Step 4: Get Endpoint
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 4: Get Endpoint URL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Copy and run this command:" -ForegroundColor Green
Write-Host "`$ENDPOINT = az cognitiveservices account show ``" -ForegroundColor White
Write-Host "  --name $VISION_RESOURCE_NAME ``" -ForegroundColor White
Write-Host "  --resource-group $RESOURCE_GROUP ``" -ForegroundColor White
Write-Host "  --query properties.endpoint ``" -ForegroundColor White
Write-Host "  --output tsv" -ForegroundColor White
Write-Host ""
Write-Host "Write-Host `"Your Endpoint: `$ENDPOINT`"" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter after you have your endpoint..." -ForegroundColor Yellow
Read-Host

# Step 5: Assign Permissions
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 5: Assign Permissions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Copy and run these commands:" -ForegroundColor Green
Write-Host ""
Write-Host "`$USER_ID = az ad signed-in-user show --query id --output tsv" -ForegroundColor White
Write-Host ""
Write-Host "`$RESOURCE_ID = az cognitiveservices account show ``" -ForegroundColor White
Write-Host "  --name $VISION_RESOURCE_NAME ``" -ForegroundColor White
Write-Host "  --resource-group $RESOURCE_GROUP ``" -ForegroundColor White
Write-Host "  --query id ``" -ForegroundColor White
Write-Host "  --output tsv" -ForegroundColor White
Write-Host ""
Write-Host "az role assignment create ``" -ForegroundColor White
Write-Host "  --role `"Cognitive Services User`" ``" -ForegroundColor White
Write-Host "  --assignee `$USER_ID ``" -ForegroundColor White
Write-Host "  --scope `$RESOURCE_ID" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter after permissions are assigned..." -ForegroundColor Yellow
Read-Host

# Step 6: Update Configuration
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 6: Update Application Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please update the following files with your endpoint:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. ObjectDetectionBlazor/appsettings.json" -ForegroundColor White
Write-Host "   Update: `"Endpoint`": `"<YOUR_ENDPOINT_HERE>`"" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Set environment variable for MAUI:" -ForegroundColor White
Write-Host "   `$env:AZURE_COMPUTER_VISION_ENDPOINT = `"<YOUR_ENDPOINT_HERE>`"" -ForegroundColor Gray
Write-Host ""
Write-Host "Or edit: ObjectDetectionMaui/Services/AzureObjectDetectionService.cs" -ForegroundColor White
Write-Host "   Line 22: Replace with your endpoint" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "Setup Guide Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary of commands to run:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. az login" -ForegroundColor Cyan
Write-Host "2. az group create --name $RESOURCE_GROUP --location $LOCATION" -ForegroundColor Cyan
Write-Host "3. az cognitiveservices account create (see above)" -ForegroundColor Cyan
Write-Host "4. Get endpoint and assign permissions (see above)" -ForegroundColor Cyan
Write-Host "5. Update your application configurations" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resource Name: $VISION_RESOURCE_NAME" -ForegroundColor Green
Write-Host ""
Write-Host "Test your apps:" -ForegroundColor Yellow
Write-Host "  Blazor: cd ObjectDetectionBlazor; dotnet run" -ForegroundColor White
Write-Host "  MAUI: cd ObjectDetectionMaui; dotnet build" -ForegroundColor White
Write-Host ""
