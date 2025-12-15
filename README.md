# Azure Object Detection Solution

**Author:** vende6  
**Repository:** https://github.com/vende6/VS2026-.net10-playground  
**License:** MIT  
**Created:** 2025-01-15  
**Version:** 1.0.0  
**Framework:** .NET 10.0  

---

## Overview

This solution contains two applications that use Azure Computer Vision for object detection:

1. **ObjectDetectionBlazor** - A Blazor Web App
2. **ObjectDetectionMaui** - A .NET MAUI cross-platform app

## Prerequisites

- .NET 10.0 SDK
- Azure Subscription
- Azure Computer Vision resource

## Azure Setup

### 1. Create Azure Computer Vision Resource

You can create the resource using the Azure Portal or Azure CLI:

```bash
# Login to Azure
az login

# Create a resource group (if you don't have one)
az group create --name MyResourceGroup --location eastus

# Create Computer Vision resource
az cognitiveservices account create \
  --name MyComputerVisionResource \
  --resource-group MyResourceGroup \
  --kind ComputerVision \
  --sku S1 \
  --location eastus

# Get the endpoint
az cognitiveservices account show \
  --name MyComputerVisionResource \
  --resource-group MyResourceGroup \
  --query properties.endpoint
```

### 2. Configure Authentication

Both applications use **Azure.Identity.DefaultAzureCredential** for secure authentication, which supports:

- **Managed Identity** (when deployed to Azure)
- **Azure CLI** (for local development)
- **Visual Studio** (for local development)
- **Environment Variables**

#### For Local Development:

**Option 1: Azure CLI (Recommended)**
```bash
az login
```

**Option 2: Assign yourself Computer Vision User role**
```bash
# Get your user object ID
az ad signed-in-user show --query id -o tsv

# Assign Cognitive Services User role
az role assignment create \
  --role "Cognitive Services User" \
  --assignee <YOUR_USER_OBJECT_ID> \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/MyResourceGroup/providers/Microsoft.CognitiveServices/accounts/MyComputerVisionResource
```

## Blazor Web App Setup

### 1. Update Configuration

Edit `ObjectDetectionBlazor/appsettings.json`:

```json
{
  "AzureComputerVision": {
    "Endpoint": "https://YOUR_RESOURCE_NAME.cognitiveservices.azure.com/"
  }
}
```

Replace `YOUR_RESOURCE_NAME` with your actual Computer Vision resource name.

### 2. Run the Application

```bash
cd ObjectDetectionBlazor
dotnet run
```

Navigate to the "Object Detection" page to upload and analyze images.

## .NET MAUI App Setup

### 1. Set Environment Variable

**Windows (PowerShell):**
```powershell
$env:AZURE_COMPUTER_VISION_ENDPOINT="https://YOUR_RESOURCE_NAME.cognitiveservices.azure.com/"
```

**macOS/Linux:**
```bash
export AZURE_COMPUTER_VISION_ENDPOINT="https://YOUR_RESOURCE_NAME.cognitiveservices.azure.com/"
```

### 2. Update the Service (Alternative)

Or edit `ObjectDetectionMaui/Services/AzureObjectDetectionService.cs` line 22 to hardcode your endpoint:

```csharp
var endpoint = Environment.GetEnvironmentVariable("AZURE_COMPUTER_VISION_ENDPOINT")
    ?? "https://YOUR_RESOURCE_NAME.cognitiveservices.azure.com/";
```

### 3. Run the Application

```bash
cd ObjectDetectionMaui
dotnet build
```

Then run from Visual Studio or:
- **Windows**: `dotnet run -f net10.0-windows10.0.19041.0`
- **Android**: Deploy to emulator/device
- **iOS**: Deploy to simulator/device
- **macOS**: `dotnet run -f net10.0-maccatalyst`

## Features

### Blazor App
- Upload images from your computer
- Real-time object detection with bounding boxes
- Display detected objects with confidence scores
- Show image caption and tags
- Responsive UI with Bootstrap

### MAUI App
- Pick photos from gallery
- Take photos with camera
- Object detection on mobile devices
- Display detected objects with confidence scores
- Show image caption and tags
- Cross-platform support (Android, iOS, Windows, macOS)

## Security Best Practices

? **Using Managed Identity** - No credentials in code  
? **DefaultAzureCredential** - Supports multiple auth methods  
? **No hardcoded keys** - Environment-based configuration  
? **HTTPS only** - Secure connections to Azure  

## Deployment

### Deploy Blazor App to Azure App Service

```bash
# Create App Service
az webapp up \
  --name MyObjectDetectionApp \
  --resource-group MyResourceGroup \
  --runtime "DOTNETCORE:10.0"

# Enable Managed Identity
az webapp identity assign \
  --name MyObjectDetectionApp \
  --resource-group MyResourceGroup

# Assign role to Managed Identity
az role assignment create \
  --role "Cognitive Services User" \
  --assignee <MANAGED_IDENTITY_PRINCIPAL_ID> \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/MyResourceGroup/providers/Microsoft.CognitiveServices/accounts/MyComputerVisionResource

# Set app settings
az webapp config appsettings set \
  --name MyObjectDetectionApp \
  --resource-group MyResourceGroup \
  --settings AzureComputerVision__Endpoint="https://YOUR_RESOURCE_NAME.cognitiveservices.azure.com/"
```

## Troubleshooting

### Authentication Errors

1. Ensure you're logged in: `az login`
2. Verify you have the correct role assignment
3. Check your endpoint URL is correct
4. For MAUI, ensure environment variable is set

### Build Errors

1. Ensure .NET 10.0 SDK is installed
2. Restore packages: `dotnet restore`
3. Clean and rebuild: `dotnet clean && dotnet build`

## License

MIT
