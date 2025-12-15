#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploy Azure AI apps using Azure Portal deployment
    
.DESCRIPTION
    Creates deployment guide and prepares apps for Azure deployment
#>

Write-Host ""
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?   Azure Deployment - Manual Setup Guide         ?" -ForegroundColor Cyan
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

Write-Host "?? AZURE DEPLOYMENT GUIDE" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????" -ForegroundColor Gray
Write-Host ""

Write-Host "Your apps are ready to deploy to Azure!" -ForegroundColor Green
Write-Host ""

Write-Host "?? RECOMMENDED: Use Visual Studio for Easy Deployment" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open ObjectDetectionBlazor project in Visual Studio" -ForegroundColor White
Write-Host "2. Right-click project ? Publish" -ForegroundColor White
Write-Host "3. Select 'Azure' ? 'Azure App Service (Windows)'" -ForegroundColor White
Write-Host "4. Create new App Service or select existing" -ForegroundColor White
Write-Host "5. Click Publish" -ForegroundColor White
Write-Host ""

Write-Host "?? ALTERNATIVE: Azure Portal Deployment" -ForegroundColor Yellow
Write-Host ""
Write-Host "Step 1: Create App Service" -ForegroundColor Cyan
Write-Host "-------" -ForegroundColor Gray
Write-Host "az webapp create \\" -ForegroundColor White
Write-Host "  --name blazor-vision-\$(Get-Random) \\" -ForegroundColor White
Write-Host "  --resource-group rg-azure-ai-suite \\" -ForegroundColor White
Write-Host "  --plan myappplan \\" -ForegroundColor White
Write-Host "  --runtime 'DOTNETCORE:8.0'" -ForegroundColor White
Write-Host ""

Write-Host "Step 2: Deploy Code" -ForegroundColor Cyan
Write-Host "-------" -ForegroundColor Gray
Write-Host "cd ObjectDetectionBlazor" -ForegroundColor White
Write-Host "dotnet publish -c Release -o ./publish" -ForegroundColor White
Write-Host "Compress-Archive -Path ./publish/* -DestinationPath ./app.zip" -ForegroundColor White
Write-Host "az webapp deployment source config-zip \\" -ForegroundColor White
Write-Host "  --resource-group rg-azure-ai-suite \\" -ForegroundColor White
Write-Host "  --name your-app-name \\" -ForegroundColor White
Write-Host "  --src ./app.zip" -ForegroundColor White
Write-Host ""

Write-Host "Step 3: Configure Settings" -ForegroundColor Cyan
Write-Host "-------" -ForegroundColor Gray
Write-Host "az webapp config appsettings set \\" -ForegroundColor White
Write-Host "  --name your-app-name \\" -ForegroundColor White
Write-Host "  --resource-group rg-azure-ai-suite \\" -ForegroundColor White
Write-Host "  --settings AzureComputerVision__Endpoint='https://eastus.api.cognitive.microsoft.com/'" -ForegroundColor White
Write-Host ""

Write-Host "?? CURRENT STATUS" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????" -ForegroundColor Gray
Write-Host ""

# Check if resource group exists
$rgName = "rg-azure-ai-suite"
$rgExists = az group exists --name $rgName
if ($rgExists -eq "true") {
    Write-Host "? Resource Group: $rgName (exists)" -ForegroundColor Green
    
    # List resources
    Write-Host ""
    Write-Host "Existing resources in $rgName" ":" -ForegroundColor Cyan
    az resource list --resource-group $rgName --query "[].{Name:name, Type:type, Location:location}" --output table
} else {
    Write-Host "? Resource Group: $rgName (not created yet)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Create it with:" -ForegroundColor White
    Write-Host "az group create --name $rgName --location eastus" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "?? AZURE SERVICES CONFIGURATION" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????" -ForegroundColor Gray
Write-Host ""

# Check existing services
Write-Host "Your existing Azure AI services:" -ForegroundColor Cyan
Write-Host ""

$visionResources = az cognitiveservices account list --query "[?kind=='ComputerVision'].{name:name, group:resourceGroup, endpoint:properties.endpoint}" --output json | ConvertFrom-Json

if ($visionResources) {
    Write-Host "Computer Vision:" -ForegroundColor White
    foreach ($resource in $visionResources) {
        Write-Host "  ? $($resource.name)" -ForegroundColor Green
        Write-Host "    Endpoint: $($resource.endpoint)" -ForegroundColor Gray
        Write-Host "    Resource Group: $($resource.group)" -ForegroundColor Gray
    }
}

Write-Host ""

$openaiResources = az cognitiveservices account list --query "[?kind=='OpenAI'].{name:name, group:resourceGroup, endpoint:properties.endpoint}" --output json | ConvertFrom-Json

if ($openaiResources) {
    Write-Host "Azure OpenAI:" -ForegroundColor White
    foreach ($resource in $openaiResources) {
        Write-Host "  ? $($resource.name)" -ForegroundColor Green
        Write-Host "    Endpoint: $($resource.endpoint)" -ForegroundColor Gray
        Write-Host "    Resource Group: $($resource.group)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "???????????????????????????????????????????????????????" -ForegroundColor Gray
Write-Host ""

Write-Host "? Your apps are ready to deploy!" -ForegroundColor Green
Write-Host ""
Write-Host "?? Documentation:" -ForegroundColor Yellow
Write-Host "  - See AZURE_DEPLOYMENT.md for detailed instructions" -ForegroundColor White
Write-Host "  - See AzureAIOrchestrator\README.md for Aspire deployment" -ForegroundColor White
Write-Host ""

Write-Host "?? TIP: Use Visual Studio's Publish feature for easiest deployment!" -ForegroundColor Cyan
Write-Host ""
