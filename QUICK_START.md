# Quick Start - Azure Computer Vision Setup

**Author:** Damir  
**Date:** 2025-01-15  

---

## ? What's Been Done

1. ? Git author configured to "Damir"
2. ? All file headers updated with author "Damir"
3. ? All metadata and copyright information updated
4. ? Azure setup scripts created
5. ? Changes committed and pushed to GitHub

---

## ?? Next Steps - Create Azure Resources

### Option 1: Automated Setup (Recommended)

**Step 1: Install Azure CLI**
```powershell
winget install -e --id Microsoft.AzureCLI
```

**Step 2: Restart PowerShell/Terminal**

**Step 3: Run Setup Script**
```powershell
cd C:\Users\cyinide\source\repos\NewRepo
.\setup-azure-vision.ps1
```

The script will:
- Login to Azure
- Create resource group "ObjectDetectionRG"
- Create Computer Vision resource
- Assign permissions
- Save configuration
- Optionally update appsettings.json

---

### Option 2: Manual Commands

If you prefer manual control, run these commands:

```powershell
# 1. Install Azure CLI
winget install -e --id Microsoft.AzureCLI

# 2. Login to Azure
az login

# 3. Set variables
$RESOURCE_GROUP = "ObjectDetectionRG"
$LOCATION = "eastus"
$VISION_RESOURCE_NAME = "objectdetection-vision-damir"

# 4. Create Resource Group
az group create `
  --name $RESOURCE_GROUP `
  --location $LOCATION

# 5. Create Computer Vision Resource
az cognitiveservices account create `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --kind ComputerVision `
  --sku S1 `
  --location $LOCATION `
  --yes

# 6. Get the Endpoint
$VISION_ENDPOINT = az cognitiveservices account show `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query properties.endpoint `
  --output tsv

Write-Host "Your endpoint: $VISION_ENDPOINT" -ForegroundColor Green

# 7. Assign Role to Your User
$USER_OBJECT_ID = az ad signed-in-user show --query id --output tsv
$VISION_RESOURCE_ID = az cognitiveservices account show `
  --name $VISION_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query id `
  --output tsv

az role assignment create `
  --role "Cognitive Services User" `
  --assignee $USER_OBJECT_ID `
  --scope $VISION_RESOURCE_ID
```

---

## ?? Update Application Configuration

### Blazor App

Edit `ObjectDetectionBlazor/appsettings.json`:

```json
{
  "AzureComputerVision": {
    "Endpoint": "https://objectdetection-vision-damir.cognitiveservices.azure.com/"
  }
}
```

### MAUI App

Set environment variable:

```powershell
$env:AZURE_COMPUTER_VISION_ENDPOINT="https://objectdetection-vision-damir.cognitiveservices.azure.com/"
```

Or update `ObjectDetectionMaui/Services/AzureObjectDetectionService.cs` line 22.

---

## ?? Test the Applications

### Blazor App
```powershell
cd ObjectDetectionBlazor
dotnet run
```
Navigate to: http://localhost:5000/objectdetection

### MAUI App
```powershell
cd ObjectDetectionMaui
dotnet build -f net10.0-windows10.0.19041.0
```
Run from Visual Studio or deploy to device.

---

## ?? Verify Everything

```powershell
# Check Git author
git log --format="%an <%ae>" -1
# Should show: Damir <damir@example.com>

# Check Azure resources
az group list --output table
az cognitiveservices account list --resource-group ObjectDetectionRG --output table

# Check role assignments
az role assignment list --assignee $USER_OBJECT_ID --output table
```

---

## ?? Documentation Files

- `AZURE_SETUP_GUIDE.md` - Comprehensive setup guide
- `AZURE_DEPLOYMENT.md` - Deployment to Azure App Service
- `README.md` - Project overview and setup
- `setup-azure-vision.ps1` - Automated setup script
- `setup-azure-vision.sh` - Setup script for Linux/Mac

---

## ?? Cost Estimate

- **Computer Vision S1**: ~$1.00 per 1,000 transactions
- **First 5,000 transactions/month**: FREE
- **Estimated monthly cost**: $20-50 (depending on usage)

---

## ?? Troubleshooting

**Azure CLI not found:**
- Restart terminal after installation
- Check: `az --version`

**Login issues:**
- Run: `az login`
- Clear cache: `az account clear`

**Permission denied:**
- Contact Azure subscription administrator
- Verify subscription access: `az account show`

---

## ? Summary

Your repository now has:
- ? Author set to "Damir" everywhere
- ? Git commits showing "Damir" as author
- ? Automated Azure setup scripts
- ? Comprehensive documentation
- ? All changes pushed to GitHub

**Next:** Install Azure CLI and run `.\setup-azure-vision.ps1`

---

**GitHub Repository:** https://github.com/vende6/VS2026-.net10-playground  
**Latest Commit:** Update author to Damir and add Azure setup automation
