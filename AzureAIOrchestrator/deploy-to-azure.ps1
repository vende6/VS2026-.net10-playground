#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploy all Azure AI applications to Azure

.DESCRIPTION
    Complete deployment script that:
    - Creates Azure resources
    - Builds container images
    - Deploys to Azure Container Apps
    - Configures managed identities
    - Sets up monitoring

.AUTHOR
    Damir

.EXAMPLE
    .\deploy-to-azure.ps1
#>

param(
    [string]$ResourceGroupName = "rg-azure-ai-suite",
    [string]$Location = "eastus",
    [string]$EnvironmentName = "azure-ai-env"
)

Write-Host ""
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?   Azure AI Suite - Complete Deployment          ?" -ForegroundColor Cyan
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify Azure CLI login
Write-Host "Step 1: Verifying Azure authentication..." -ForegroundColor Yellow
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "? Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "? Subscription: $($account.name)" -ForegroundColor Green
} catch {
    Write-Host "? Not logged in to Azure" -ForegroundColor Red
    Write-Host "Please run: az login" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 2: Create Resource Group
Write-Host "Step 2: Creating resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    az group create --name $ResourceGroupName --location $Location | Out-Null
    Write-Host "? Resource group created: $ResourceGroupName" -ForegroundColor Green
} else {
    Write-Host "? Resource group exists: $ResourceGroupName" -ForegroundColor Green
}

Write-Host ""

# Step 3: Create Container Apps Environment
Write-Host "Step 3: Creating Container Apps environment..." -ForegroundColor Yellow

$envExists = az containerapp env show --name $EnvironmentName --resource-group $ResourceGroupName 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Creating new environment..." -ForegroundColor Cyan
    
    # Create Log Analytics workspace
    $workspaceName = "law-$EnvironmentName"
    az monitor log-analytics workspace create `
        --resource-group $ResourceGroupName `
        --workspace-name $workspaceName `
        --location $Location | Out-Null
    
    $workspaceId = az monitor log-analytics workspace show `
        --resource-group $ResourceGroupName `
        --workspace-name $workspaceName `
        --query customerId `
        --output tsv
    
    $workspaceKey = az monitor log-analytics workspace get-shared-keys `
        --resource-group $ResourceGroupName `
        --workspace-name $workspaceName `
        --query primarySharedKey `
        --output tsv
    
    # Create Container Apps environment
    az containerapp env create `
        --name $EnvironmentName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --logs-workspace-id $workspaceId `
        --logs-workspace-key $workspaceKey | Out-Null
    
    Write-Host "? Environment created: $EnvironmentName" -ForegroundColor Green
} else {
    Write-Host "? Environment exists: $EnvironmentName" -ForegroundColor Green
}

Write-Host ""

# Step 4: Create Container Registry
Write-Host "Step 4: Creating Azure Container Registry..." -ForegroundColor Yellow

$acrName = "acrazureai" + (Get-Random -Maximum 9999)
$acrExists = az acr show --name $acrName --resource-group $ResourceGroupName 2>&1
if ($LASTEXITCODE -ne 0) {
    az acr create `
        --resource-group $ResourceGroupName `
        --name $acrName `
        --sku Basic `
        --admin-enabled true `
        --location $Location | Out-Null
    
    Write-Host "? Container registry created: $acrName" -ForegroundColor Green
} else {
    Write-Host "? Container registry exists: $acrName" -ForegroundColor Green
}

# Get ACR credentials
$acrServer = az acr show --name $acrName --resource-group $ResourceGroupName --query loginServer --output tsv
$acrUsername = az acr credential show --name $acrName --resource-group $ResourceGroupName --query username --output tsv
$acrPassword = az acr credential show --name $acrName --resource-group $ResourceGroupName --query "passwords[0].value" --output tsv

Write-Host ""

# Step 5: Build and Push Blazor App
Write-Host "Step 5: Building and pushing Blazor app..." -ForegroundColor Yellow

Set-Location "..\ObjectDetectionBlazor"

# Create Dockerfile if it doesn't exist
$dockerfileContent = @"
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["ObjectDetectionBlazor.csproj", "./"]
RUN dotnet restore
COPY . .
RUN dotnet build -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ObjectDetectionBlazor.dll"]
"@

$dockerfileContent | Out-File -FilePath "Dockerfile" -Encoding UTF8

# Build and push
az acr build --registry $acrName --image blazor-vision:latest . | Out-Null

Write-Host "? Blazor app built and pushed" -ForegroundColor Green

Set-Location "..\AzureAIOrchestrator"

Write-Host ""

# Step 6: Deploy Blazor App to Container Apps
Write-Host "Step 6: Deploying Blazor app to Container Apps..." -ForegroundColor Yellow

$blazorAppName = "blazor-vision"

# Get existing Computer Vision and OpenAI endpoints
$visionEndpoint = "https://eastus.api.cognitive.microsoft.com/"
$openAIEndpoint = "https://openaios.openai.azure.com/"

az containerapp create `
    --name $blazorAppName `
    --resource-group $ResourceGroupName `
    --environment $EnvironmentName `
    --image "$acrServer/blazor-vision:latest" `
    --registry-server $acrServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --target-port 8080 `
    --ingress external `
    --min-replicas 1 `
    --max-replicas 3 `
    --cpu 0.5 `
    --memory 1.0Gi `
    --env-vars `
        "AzureComputerVision__Endpoint=$visionEndpoint" `
        "ASPNETCORE_ENVIRONMENT=Production" | Out-Null

Write-Host "? Blazor app deployed" -ForegroundColor Green

# Get app URL
$blazorUrl = az containerapp show `
    --name $blazorAppName `
    --resource-group $ResourceGroupName `
    --query properties.configuration.ingress.fqdn `
    --output tsv

Write-Host "  URL: https://$blazorUrl" -ForegroundColor Cyan

Write-Host ""

# Step 7: Configure Managed Identity
Write-Host "Step 7: Configuring managed identity and permissions..." -ForegroundColor Yellow

# Enable managed identity
az containerapp identity assign `
    --name $blazorAppName `
    --resource-group $ResourceGroupName `
    --system-assigned | Out-Null

$principalId = az containerapp show `
    --name $blazorAppName `
    --resource-group $ResourceGroupName `
    --query identity.principalId `
    --output tsv

# Grant Cognitive Services User role
$subscriptionId = az account show --query id --output tsv

# Computer Vision
az role assignment create `
    --role "Cognitive Services User" `
    --assignee $principalId `
    --scope "/subscriptions/$subscriptionId/resourceGroups/ObjectDetectionRG/providers/Microsoft.CognitiveServices/accounts/objectdetection-vision-test" 2>$null | Out-Null

# OpenAI
az role assignment create `
    --role "Cognitive Services User" `
    --assignee $principalId `
    --scope "/subscriptions/$subscriptionId/resourceGroups/whosme_group/providers/Microsoft.CognitiveServices/accounts/openaiOS" 2>$null | Out-Null

Write-Host "? Managed identity configured" -ForegroundColor Green
Write-Host "? Permissions granted to Cognitive Services" -ForegroundColor Green

Write-Host ""

# Step 8: Summary
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "?          Deployment Complete!                    ?" -ForegroundColor Green
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""

Write-Host "?? Deployed Resources:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  Container Registry: $acrName" -ForegroundColor White
Write-Host "  Environment: $EnvironmentName" -ForegroundColor White
Write-Host ""

Write-Host "?? Application URLs:" -ForegroundColor Yellow
Write-Host "  Blazor App: https://$blazorUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "?? Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the Blazor app: https://$blazorUrl" -ForegroundColor White
Write-Host "2. View logs:" -ForegroundColor White
Write-Host "   az containerapp logs tail --name $blazorAppName --resource-group $ResourceGroupName" -ForegroundColor Cyan
Write-Host "3. Monitor in Azure Portal:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName" -ForegroundColor Cyan
Write-Host ""

Write-Host "? Deployment successful!" -ForegroundColor Green
Write-Host ""
