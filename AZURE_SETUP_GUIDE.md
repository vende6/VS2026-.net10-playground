# Azure Setup Guide for Object Detection

**Author:** Damir  
**Repository:** https://github.com/vende6/VS2026-.net10-playground  
**Date:** 2025-01-15  

---

## Prerequisites

### 1. Install Azure CLI

**Windows:**
```powershell
# Download and install Azure CLI
winget install -e --id Microsoft.AzureCLI
```

Or download from: https://aka.ms/installazurecliwindows

**After installation, restart your terminal/PowerShell**

### 2. Verify Installation

```powershell
az --version
```

---

## Automated Setup (Recommended)

Once Azure CLI is installed, run:

```powershell
cd C:\Users\cyinide\source\repos\NewRepo
.\setup-azure-vision.ps1
```

This script will:
- ? Login to Azure
- ? Create resource group
- ? Create Computer Vision resource
- ? Assign necessary roles
- ? Save configuration
- ? Optionally update appsettings.json automatically

---

## Manual Setup

If you prefer to run commands manually:

### Step 1: Login to Azure

```bash
az login
```

### Step 2: Set Variables

```bash
RESOURCE_GROUP="ObjectDetectionRG"
LOCATION="eastus"
VISION_RESOURCE_NAME="objectdetection-vision-damir"
```

### Step 3: Create Resource Group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### Step 4: Create Computer Vision Resource

```bash
az cognitiveservices account create \
  --name $VISION_RESOURCE_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind ComputerVision \
  --sku S1 \
  --location $LOCATION \
  --yes
```

### Step 5: Get the Endpoint

```bash
az cognitiveservices account show \
  --name $VISION_RESOURCE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint \
  --output tsv
```

### Step 6: Assign Role to Your User

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

---

## PowerShell Commands (Windows)

```powershell
# Step 1: Login
az login

# Step 2: Set Variables
$RESOURCE_GROUP = "ObjectDetectionRG"
$LOCATION = "eastus"
$VISION_RESOURCE_NAME = "objectdetection-vision-damir"

# Step 3: Create Resource Group
az group create `
  --name $RESOURCE_GROUP `
  --location $LOCATION

# Step 4: Create Computer Vision Resource
az cognitiveservices account create `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --kind ComputerVision `
  --sku S1 `
  --location $LOCATION `
  --yes

# Step 5: Get the Endpoint
$VISION_ENDPOINT = az cognitiveservices account show `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query properties.endpoint `
  --output tsv

Write-Host "Endpoint: $VISION_ENDPOINT"

# Step 6: Get your user object ID
$USER_OBJECT_ID = az ad signed-in-user show --query id --output tsv

# Step 7: Get the resource ID
$VISION_RESOURCE_ID = az cognitiveservices account show `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query id `
  --output tsv

# Step 8: Assign Role
az role assignment create `
  --role "Cognitive Services User" `
  --assignee $USER_OBJECT_ID `
  --scope $VISION_RESOURCE_ID

# Step 9: Update Environment Variable for MAUI
$env:AZURE_COMPUTER_VISION_ENDPOINT = $VISION_ENDPOINT
```

---

## Configuration

After creating the resources, you need to update your applications:

### Blazor App (appsettings.json)

Update `ObjectDetectionBlazor/appsettings.json`:

```json
{
  "AzureComputerVision": {
    "Endpoint": "YOUR_ENDPOINT_HERE"
  }
}
```

### MAUI App (Environment Variable)

**PowerShell:**
```powershell
$env:AZURE_COMPUTER_VISION_ENDPOINT="YOUR_ENDPOINT_HERE"
```

**Bash:**
```bash
export AZURE_COMPUTER_VISION_ENDPOINT="YOUR_ENDPOINT_HERE"
```

Or update `ObjectDetectionMaui/Services/AzureObjectDetectionService.cs` line 22:
```csharp
var endpoint = Environment.GetEnvironmentVariable("AZURE_COMPUTER_VISION_ENDPOINT")
    ?? "YOUR_ENDPOINT_HERE";
```

---

## Verify Setup

```powershell
# Check resource exists
az cognitiveservices account show `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP

# Check role assignment
az role assignment list `
  --scope $VISION_RESOURCE_ID `
  --output table

# Test authentication
az login
```

---

## Troubleshooting

### Azure CLI Not Found
- Restart your terminal after installation
- Check PATH: `$env:PATH`
- Reinstall Azure CLI

### Authentication Issues
- Run `az login` again
- Clear cache: `az account clear`
- Check subscription: `az account show`

### Permission Denied
- Ensure you have Contributor or Owner role on the subscription
- Contact your Azure administrator

---

## Cost Information

**Computer Vision S1 Tier:**
- ~$1.00 per 1,000 transactions
- First 5,000 transactions free per month
- Monthly estimate: $20-50 depending on usage

---

## Clean Up Resources (Optional)

To delete everything and stop billing:

```bash
az group delete --name ObjectDetectionRG --yes --no-wait
```

---

## Next Steps

1. ? Install Azure CLI (if not installed)
2. ? Run `.\setup-azure-vision.ps1`
3. ? Update appsettings.json with endpoint
4. ? Set environment variable for MAUI
5. ? Test the applications!

---

**Author:** Damir  
**Support:** https://github.com/vende6/VS2026-.net10-playground/issues
