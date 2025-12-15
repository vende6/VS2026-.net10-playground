#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Complete Azure deployment without Docker - Uses direct publish

.DESCRIPTION
    Deploys Blazor app to Azure App Service using direct publish (no containers needed)
#>

Write-Host ""
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?   Azure AI Suite - No-Docker Deployment         ?" -ForegroundColor Cyan
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

$appName = "blazor-vision-8940"
$resourceGroup = "rg-azure-ai-suite"

Write-Host "?? Deploying Blazor App to Azure..." -ForegroundColor Yellow
Write-Host ""

# Step 1: Build and publish locally
Write-Host "Step 1: Building application..." -ForegroundColor Cyan
Set-Location "..\ObjectDetectionBlazor"

dotnet publish -c Release -o ./publish

if ($LASTEXITCODE -ne 0) {
    Write-Host "? Build failed" -ForegroundColor Red
    exit 1
}

Write-Host "? Application built successfully" -ForegroundColor Green
Write-Host ""

# Step 2: Create ZIP package
Write-Host "Step 2: Creating deployment package..." -ForegroundColor Cyan
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force
Write-Host "? Package created" -ForegroundColor Green
Write-Host ""

# Step 3: Deploy to Azure
Write-Host "Step 3: Deploying to Azure App Service..." -ForegroundColor Cyan
Write-Host "  Target: $appName.azurewebsites.net" -ForegroundColor Gray
Write-Host ""

az webapp deploy `
    --resource-group $resourceGroup `
    --name $appName `
    --src-path ./deploy.zip `
    --type zip `
    --async false

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "? Deployment successful!" -ForegroundColor Green
    Write-Host ""
    
    # Step 4: Configure app settings
    Write-Host "Step 4: Configuring app settings..." -ForegroundColor Cyan
    
    az webapp config appsettings set `
        --name $appName `
        --resource-group $resourceGroup `
        --settings `
            "AzureComputerVision__Endpoint=https://eastus.api.cognitive.microsoft.com/" `
            "ASPNETCORE_ENVIRONMENT=Production" `
            "ASPNETCORE_URLS=http://+:8080" `
        --output none
    
    Write-Host "? App settings configured" -ForegroundColor Green
    Write-Host ""
    
    # Step 5: Enable managed identity
    Write-Host "Step 5: Enabling managed identity..." -ForegroundColor Cyan
    
    az webapp identity assign `
        --name $appName `
        --resource-group $resourceGroup `
        --output none
    
    $principalId = az webapp identity show `
        --name $appName `
        --resource-group $resourceGroup `
        --query principalId `
        --output tsv
    
    Write-Host "? Managed identity enabled" -ForegroundColor Green
    Write-Host "  Principal ID: $principalId" -ForegroundColor Gray
    Write-Host ""
    
    # Step 6: Grant permissions
    Write-Host "Step 6: Granting Azure AI permissions..." -ForegroundColor Cyan
    
    $subscriptionId = "13593b73-37f7-4d5a-bc81-1451e67a42f1"
    
    # Computer Vision
    az role assignment create `
        --role "Cognitive Services User" `
        --assignee $principalId `
        --scope "/subscriptions/$subscriptionId/resourceGroups/ObjectDetectionRG/providers/Microsoft.CognitiveServices/accounts/objectdetection-vision-test" `
        --output none 2>$null
    
    Write-Host "? Computer Vision access granted" -ForegroundColor Green
    
    # OpenAI
    az role assignment create `
        --role "Cognitive Services User" `
        --assignee $principalId `
        --scope "/subscriptions/$subscriptionId/resourceGroups/whosme_group/providers/Microsoft.CognitiveServices/accounts/openaiOS" `
        --output none 2>$null
    
    Write-Host "? OpenAI access granted" -ForegroundColor Green
    Write-Host ""
    
    # Cleanup
    Remove-Item ./deploy.zip -Force -ErrorAction SilentlyContinue
    Remove-Item ./publish -Recurse -Force -ErrorAction SilentlyContinue
    
    # Success!
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
    Write-Host "?          ?? Deployment Complete!                 ?" -ForegroundColor Green
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your Azure AI Object Detection app is now LIVE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? App URL:" -ForegroundColor Yellow
    Write-Host "   https://$appName.azurewebsites.net" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "?? Azure Portal:" -ForegroundColor Yellow
    Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "?? Test your app:" -ForegroundColor Yellow
    Write-Host "   1. Open https://$appName.azurewebsites.net" -ForegroundColor White
    Write-Host "   2. Upload an image" -ForegroundColor White
    Write-Host "   3. See AI-powered object detection in action!" -ForegroundColor White
    Write-Host ""
    Write-Host "?? View logs:" -ForegroundColor Yellow
    Write-Host "   az webapp log tail --name $appName --resource-group $resourceGroup" -ForegroundColor Cyan
    Write-Host ""
    
    # Open in browser
    Start-Sleep -Seconds 5
    Write-Host "Opening your app in browser..." -ForegroundColor Cyan
    start "https://$appName.azurewebsites.net"
    
} else {
    Write-Host "? Deployment failed" -ForegroundColor Red
    Write-Host "Check the error messages above" -ForegroundColor Yellow
}

Set-Location "..\AzureAIOrchestrator"
