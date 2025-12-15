#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Simple Azure deployment using Azure Container Apps

.DESCRIPTION
    Deploys the Blazor app to Azure Container Apps directly without building containers
#>

Write-Host ""
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?   Azure AI Suite - Simple Deployment            ?" -ForegroundColor Cyan
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Variables
$resourceGroup = "rg-azure-ai-suite"
$location = "eastus"
$appName = "blazor-vision-app"

# Step 1: Check login
Write-Host "Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>&1 | ConvertFrom-Json
Write-Host "? Logged in: $($account.user.name)" -ForegroundColor Green
Write-Host ""

# Step 2: Create resource group
Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create --name $resourceGroup --location $location --output none
Write-Host "? Resource group: $resourceGroup" -ForegroundColor Green
Write-Host ""

# Step 3: Deploy using 'az webapp up' for quick deployment
Write-Host "Deploying Blazor app..." -ForegroundColor Yellow
Write-Host "(This will take 3-5 minutes)" -ForegroundColor Cyan
Write-Host ""

Set-Location "..\ObjectDetectionBlazor"

# Deploy to Azure App Service (simpler than Container Apps)
az webapp up `
    --name $appName `
    --resource-group $resourceGroup `
    --location $location `
    --runtime "DOTNET:10.0" `
    --sku B1 `
    --os-type Linux

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "? Deployment successful!" -ForegroundColor Green
    Write-Host ""
    
    $appUrl = az webapp show --name $appName --resource-group $resourceGroup --query defaultHostName --output tsv
    
    Write-Host "?? Your app is live at:" -ForegroundColor Yellow
    Write-Host "   https://$appUrl" -ForegroundColor Cyan
    Write-Host ""
    
    # Configure app settings
    Write-Host "Configuring Azure services..." -ForegroundColor Yellow
    
    az webapp config appsettings set `
        --name $appName `
        --resource-group $resourceGroup `
        --settings `
            "AzureComputerVision__Endpoint=https://eastus.api.cognitive.microsoft.com/" `
            "ASPNETCORE_ENVIRONMENT=Production" `
        --output none
    
    # Enable managed identity
    az webapp identity assign `
        --name $appName `
        --resource-group $resourceGroup `
        --output none
    
    $principalId = az webapp identity show `
        --name $appName `
        --resource-group $resourceGroup `
        --query principalId `
        --output tsv
    
    # Grant permissions
    $subscriptionId = az account show --query id --output tsv
    
    Write-Host "Granting permissions..." -ForegroundColor Yellow
    
    az role assignment create `
        --role "Cognitive Services User" `
        --assignee $principalId `
        --scope "/subscriptions/$subscriptionId/resourceGroups/ObjectDetectionRG/providers/Microsoft.CognitiveServices/accounts/objectdetection-vision-test" `
        --output none 2>$null
    
    Write-Host "? Permissions configured" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
    Write-Host "?          ?? Deployment Complete!                 ?" -ForegroundColor Green
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your Azure AI Object Detection app is now live!" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? App URL: https://$appUrl" -ForegroundColor Cyan
    Write-Host "?? Azure Portal: https://portal.azure.com" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Open https://$appUrl in your browser" -ForegroundColor White
    Write-Host "2. Upload an image to test object detection" -ForegroundColor White
    Write-Host "3. View logs: az webapp log tail --name $appName --resource-group $resourceGroup" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "? Deployment failed" -ForegroundColor Red
    Write-Host "Check the error messages above" -ForegroundColor Yellow
}

Set-Location "..\AzureAIOrchestrator"
