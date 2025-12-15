# Azure Deployment Guide

**Author:** vende6  
**Repository:** https://github.com/vende6/VS2026-.net10-playground  
**License:** MIT  
**Created:** 2025-01-15  
**Version:** 1.0.0  

---

## Overview

This guide provides step-by-step Azure CLI commands to set up and deploy the Object Detection applications.

## Prerequisites

- Azure CLI installed ([Install Guide](https://docs.microsoft.com/cli/azure/install-azure-cli))
- Active Azure subscription
- .NET 10.0 SDK

## Step 1: Login to Azure

```bash
az login
```

## Step 2: Set Your Subscription (if you have multiple)

```bash
# List available subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"
```

## Step 3: Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="ObjectDetectionRG"
LOCATION="eastus"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

## Step 4: Create Computer Vision Resource

```bash
# Set variables
VISION_RESOURCE_NAME="objectdetection-vision-$(date +%s)"

# Create Computer Vision resource
az cognitiveservices account create \
  --name $VISION_RESOURCE_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind ComputerVision \
  --sku S1 \
  --location $LOCATION \
  --yes

# Get the endpoint
VISION_ENDPOINT=$(az cognitiveservices account show \
  --name $VISION_RESOURCE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint \
  --output tsv)

echo "Vision Endpoint: $VISION_ENDPOINT"
```

## Step 5: Configure Local Development Authentication

### Option A: Azure CLI Authentication (Recommended for local dev)

```bash
# Already logged in from Step 1
az login
```

### Option B: Assign Role to Your User Account

```bash
# Get your user object ID
USER_OBJECT_ID=$(az ad signed-in-user show --query id --output tsv)

# Get the resource ID
VISION_RESOURCE_ID=$(az cognitiveservices account show \
  --name $VISION_RESOURCE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id \
  --output tsv)

# Assign Cognitive Services User role
az role assignment create \
  --role "Cognitive Services User" \
  --assignee $USER_OBJECT_ID \
  --scope $VISION_RESOURCE_ID
```

## Step 6: Update Application Configuration

### For Blazor App

Edit `ObjectDetectionBlazor/appsettings.json`:

```json
{
  "AzureComputerVision": {
    "Endpoint": "YOUR_VISION_ENDPOINT_HERE"
  }
}
```

Or set it via environment variable:

```bash
# Windows PowerShell
$env:AzureComputerVision__Endpoint="$VISION_ENDPOINT"

# Linux/macOS
export AzureComputerVision__Endpoint="$VISION_ENDPOINT"
```

### For MAUI App

```bash
# Windows PowerShell
$env:AZURE_COMPUTER_VISION_ENDPOINT="$VISION_ENDPOINT"

# Linux/macOS
export AZURE_COMPUTER_VISION_ENDPOINT="$VISION_ENDPOINT"
```

## Step 7: Test Locally

```bash
# Test Blazor app
cd ObjectDetectionBlazor
dotnet run

# Test MAUI app (Windows)
cd ../ObjectDetectionMaui
dotnet build -f net10.0-windows10.0.19041.0
```

## Step 8: Deploy Blazor App to Azure App Service

```bash
# Set variables
APP_NAME="objectdetection-web-$(date +%s)"
APP_SERVICE_PLAN="objectdetection-plan"

# Create App Service Plan
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNET|10.0"

# Enable system-assigned managed identity
az webapp identity assign \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP

# Get the managed identity principal ID
MANAGED_IDENTITY_ID=$(az webapp identity show \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId \
  --output tsv)

# Assign Cognitive Services User role to the managed identity
az role assignment create \
  --role "Cognitive Services User" \
  --assignee $MANAGED_IDENTITY_ID \
  --scope $VISION_RESOURCE_ID

# Configure app settings
az webapp config appsettings set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings AzureComputerVision__Endpoint="$VISION_ENDPOINT"

# Deploy the app
cd ObjectDetectionBlazor
dotnet publish -c Release -o ./publish
cd publish
zip -r ../app.zip .
cd ..

az webapp deployment source config-zip \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --src app.zip

# Get the app URL
APP_URL=$(az webapp show \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query defaultHostName \
  --output tsv)

echo "App deployed to: https://$APP_URL"
```

## Step 9: Monitor and Troubleshoot

```bash
# View application logs
az webapp log tail \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP

# Check app status
az webapp show \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query state

# Restart the app if needed
az webapp restart \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP
```

## Step 10: Clean Up Resources (Optional)

```bash
# Delete the entire resource group and all resources
az group delete \
  --name $RESOURCE_GROUP \
  --yes \
  --no-wait
```

## Alternative: Deploy Using Container

```bash
# Build Docker image
cd ObjectDetectionBlazor
docker build -t objectdetection-blazor:latest .

# Create Azure Container Registry
ACR_NAME="objectdetectionacr$(date +%s)"
az acr create \
  --name $ACR_NAME \
  --resource-group $RESOURCE_GROUP \
  --sku Basic \
  --admin-enabled true

# Login to ACR
az acr login --name $ACR_NAME

# Tag and push image
docker tag objectdetection-blazor:latest $ACR_NAME.azurecr.io/objectdetection-blazor:latest
docker push $ACR_NAME.azurecr.io/objectdetection-blazor:latest

# Create web app from container
az webapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --deployment-container-image-name $ACR_NAME.azurecr.io/objectdetection-blazor:latest

# Configure container registry credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

az webapp config container set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/objectdetection-blazor:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD
```

## Security Best Practices

? **Use Managed Identity** - No credentials stored in code  
? **Least Privilege** - Only assign necessary permissions  
? **HTTPS Only** - Configure custom domain with SSL  
? **Monitor Access** - Enable Application Insights  
? **Rotate Keys** - Not applicable when using Managed Identity  

## Useful Commands

```bash
# Check role assignments
az role assignment list \
  --scope $VISION_RESOURCE_ID \
  --output table

# View Computer Vision metrics
az monitor metrics list \
  --resource $VISION_RESOURCE_ID \
  --metric "TotalCalls" \
  --output table

# Enable Application Insights
az monitor app-insights component create \
  --app $APP_NAME-insights \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web

# Link App Insights to Web App
APPINSIGHTS_KEY=$(az monitor app-insights component show \
  --app $APP_NAME-insights \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey \
  --output tsv)

az webapp config appsettings set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$APPINSIGHTS_KEY"
```

## Troubleshooting

### Authentication Issues

1. Verify you're logged in: `az account show`
2. Check role assignments: `az role assignment list --assignee $USER_OBJECT_ID`
3. Ensure endpoint is correct: `echo $VISION_ENDPOINT`

### Deployment Issues

1. Check app logs: `az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP`
2. Verify app settings: `az webapp config appsettings list --name $APP_NAME --resource-group $RESOURCE_GROUP`
3. Restart app: `az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP`

## Cost Estimation

- **Computer Vision S1**: ~$1.00 per 1,000 transactions
- **App Service B1**: ~$13/month
- **Container Registry Basic**: ~$5/month

Total estimated cost: ~$20-50/month depending on usage
