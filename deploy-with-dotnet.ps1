#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploy using dotnet publish to Azure App Service

.DESCRIPTION
    Uses dotnet publish to build and deploy the Blazor app to Azure
#>

Write-Host ""
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?   Deploying with dotnet publish                  ?" -ForegroundColor Cyan
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$appName = "blazor-vision-8940"
$resourceGroup = "rg-azure-ai-suite"
$projectPath = "C:\Users\cyinide\source\repos\NewRepo\ObjectDetectionBlazor"

Set-Location $projectPath

try {
    # Step 1: Clean
    Write-Host "Step 1: Cleaning previous builds..." -ForegroundColor Yellow
    dotnet clean --nologo --verbosity quiet
    Remove-Item -Path .\publish -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path .\*.zip -Force -ErrorAction SilentlyContinue
    Write-Host "? Cleaned" -ForegroundColor Green
    Write-Host ""

    # Step 2: Restore packages
    Write-Host "Step 2: Restoring NuGet packages..." -ForegroundColor Yellow
    dotnet restore --nologo --verbosity quiet
    Write-Host "? Restored" -ForegroundColor Green
    Write-Host ""

    # Step 3: Publish
    Write-Host "Step 3: Publishing application..." -ForegroundColor Yellow
    Write-Host "  Configuration: Release" -ForegroundColor Gray
    Write-Host "  Target: net10.0" -ForegroundColor Gray
    Write-Host "  Output: ./publish" -ForegroundColor Gray
    Write-Host ""
    
    dotnet publish `
        -c Release `
        -o ./publish `
        --nologo `
        --verbosity normal `
        /p:UseAppHost=false
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }
    
    Write-Host ""
    Write-Host "? Published successfully" -ForegroundColor Green
    
    # Check publish folder
    $publishedFiles = Get-ChildItem -Path ./publish -Recurse -File
    Write-Host "  Files published: $($publishedFiles.Count)" -ForegroundColor Gray
    $totalSize = ($publishedFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  Total size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Gray
    Write-Host ""

    # Step 4: Create deployment package
    Write-Host "Step 4: Creating deployment package..." -ForegroundColor Yellow
    Compress-Archive -Path ./publish/* -DestinationPath ./app-deploy.zip -Force
    
    $zipSize = (Get-Item ./app-deploy.zip).Length / 1MB
    Write-Host "? Package created: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Green
    Write-Host ""

    # Step 5: Deploy to Azure
    Write-Host "Step 5: Deploying to Azure App Service..." -ForegroundColor Yellow
    Write-Host "  App Name: $appName" -ForegroundColor Gray
    Write-Host "  Resource Group: $resourceGroup" -ForegroundColor Gray
    Write-Host "  URL: https://$appName.azurewebsites.net" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  This will take 2-5 minutes..." -ForegroundColor Gray
    Write-Host ""

    # Use zip deploy
    az webapp deployment source config-zip `
        --resource-group $resourceGroup `
        --name $appName `
        --src ./app-deploy.zip
    
    Write-Host ""
    Write-Host "? Deployment initiated!" -ForegroundColor Green
    Write-Host ""

    # Step 6: Configure app
    Write-Host "Step 6: Configuring application..." -ForegroundColor Yellow
    
    # Set app settings
    az webapp config appsettings set `
        --name $appName `
        --resource-group $resourceGroup `
        --settings `
            "AzureComputerVision__Endpoint=https://eastus.api.cognitive.microsoft.com/" `
            "ASPNETCORE_ENVIRONMENT=Production" `
        --output none
    
    Write-Host "? App settings configured" -ForegroundColor Green
    
    # Enable managed identity
    az webapp identity assign `
        --name $appName `
        --resource-group $resourceGroup `
        --output none
    
    Write-Host "? Managed identity enabled" -ForegroundColor Green
    
    # Get principal ID
    $principalId = az webapp identity show `
        --name $appName `
        --resource-group $resourceGroup `
        --query principalId `
        --output tsv
    
    if ($principalId) {
        # Grant permissions
        az role assignment create `
            --role "Cognitive Services User" `
            --assignee $principalId `
            --scope "/subscriptions/13593b73-37f7-4d5a-bc81-1451e67a42f1/resourceGroups/ObjectDetectionRG/providers/Microsoft.CognitiveServices/accounts/objectdetection-vision-test" `
            --output none 2>$null
        
        Write-Host "? Azure AI permissions granted" -ForegroundColor Green
    }
    
    Write-Host ""

    # Step 7: Restart app
    Write-Host "Step 7: Restarting application..." -ForegroundColor Yellow
    az webapp restart --name $appName --resource-group $resourceGroup --output none
    Write-Host "? App restarted" -ForegroundColor Green
    Write-Host ""

    # Clean up
    Remove-Item ./app-deploy.zip -Force -ErrorAction SilentlyContinue

    # Success!
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
    Write-Host "?          ?? DEPLOYMENT SUCCESSFUL! ??            ?" -ForegroundColor Green
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your Azure AI Object Detection app is now LIVE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? App URL:" -ForegroundColor Yellow
    Write-Host "   https://$appName.azurewebsites.net" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "?? Test it now:" -ForegroundColor Yellow
    Write-Host "   1. Upload an image" -ForegroundColor White
    Write-Host "   2. See AI-powered object detection!" -ForegroundColor White
    Write-Host ""
    
    # Wait and open browser
    Write-Host "Waiting for app to warm up..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host "Opening in browser..." -ForegroundColor Cyan
    Start-Process "https://$appName.azurewebsites.net"

} catch {
    Write-Host ""
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Red
    Write-Host "?          ? DEPLOYMENT FAILED                     ?" -ForegroundColor Red
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check Azure login: az account show" -ForegroundColor White
    Write-Host "  2. Verify build: dotnet build -c Release" -ForegroundColor White
    Write-Host "  3. Check logs: az webapp log tail --name $appName --resource-group $resourceGroup" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Set-Location C:\Users\cyinide\source\repos\NewRepo
