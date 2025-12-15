# Azure Computer Vision Object Detection - Complete Setup Guide

**Author:** Damir  
**Repository:** https://github.com/vende6/VS2026-.net10-playground  
**License:** MIT  
**Created:** 2025-01-15  

---

## ?? Quick Start

You are logged in with `az login` and want to complete your Azure Computer Vision object detection setup. Here's what to do:

### Option 1: Complete Automated Setup (Recommended)

Run the complete setup script that creates everything:

```powershell
# Windows PowerShell
.\complete-azure-setup.ps1
```

```bash
# Linux/macOS
chmod +x complete-azure-setup.sh
./complete-azure-setup.sh
```

This script will:
- ? Verify your Azure CLI login
- ? Create or use existing Computer Vision resources
- ? Configure RBAC permissions
- ? Update all configuration files
- ? Set environment variables
- ? Test the connection

### Option 2: Update Existing Endpoints

If you already have Azure resources and just need to update endpoints:

```powershell
# Windows PowerShell
.\update-azure-endpoints.ps1
```

This script will:
- Find your existing Computer Vision resources
- Update `appsettings.json` files
- Set environment variables

### Option 3: Manual Setup

Follow the step-by-step commands in `AZURE_DEPLOYMENT.md`

---

## ?? Available Scripts

### 1. `complete-azure-setup.ps1` / `complete-azure-setup.sh`
**Full automated setup - Run this first!**

Creates all Azure resources, configures authentication, and updates your project.

```powershell
# Use default settings
.\complete-azure-setup.ps1

# Custom resource group and location
.\complete-azure-setup.ps1 -ResourceGroup "MyRG" -Location "westus"

# Use existing resources instead of creating new ones
.\complete-azure-setup.ps1 -UseExisting
```

**What it does:**
1. Verifies Azure CLI and login status
2. Creates Resource Group (if needed)
3. Creates Computer Vision resource (S1 SKU)
4. Assigns "Cognitive Services User" role
5. Updates `ObjectDetectionBlazor/appsettings.json`
6. Sets environment variables
7. Creates `azure-config.txt` reference file
8. Tests the connection

### 2. `update-azure-endpoints.ps1`
**Update configuration files with new endpoints**

Use this when you need to change endpoints or update configuration.

```powershell
# Interactive mode - select from existing resources
.\update-azure-endpoints.ps1

# Specify resource directly
.\update-azure-endpoints.ps1 -ResourceGroup "MyRG" -VisionResourceName "my-vision"

# Manually provide endpoint
.\update-azure-endpoints.ps1 -Endpoint "https://my-vision.cognitiveservices.azure.com/"
```

**What it does:**
1. Lists your Computer Vision resources
2. Updates `appsettings.json` files
3. Sets session environment variables
4. Optionally sets permanent user environment variables
5. Creates configuration reference file

### 3. `test-object-detection.ps1`
**Test your Azure Computer Vision setup**

Verifies everything is working correctly.

```powershell
# Test with default sample image
.\test-object-detection.ps1

# Test with your own image URL
.\test-object-detection.ps1 -ImageUrl "https://example.com/photo.jpg"
```

**What it does:**
1. Checks Azure authentication
2. Finds Computer Vision resources
3. Makes a real API call to detect objects
4. Displays detected objects, tags, and description
5. Verifies the service is working

### 4. `setup-azure-vision.ps1` / `setup-azure-vision.sh`
**Original setup scripts**

These are the original scripts. Use `complete-azure-setup.ps1` instead for a better experience.

---

## ?? Configuration Files

After running the setup, these files will be updated:

### `ObjectDetectionBlazor/appsettings.json`
```json
{
  "AzureComputerVision": {
    "Endpoint": "https://your-resource.cognitiveservices.azure.com/"
  }
}
```

### `azure-config.txt`
Complete reference of your Azure configuration, including:
- Resource details
- Endpoint URL
- Environment variable commands
- Authentication info
- Troubleshooting tips

---

## ?? Testing Your Setup

### 1. Test with the Test Script
```powershell
.\test-object-detection.ps1
```

### 2. Run the Blazor Application
```powershell
cd ObjectDetectionBlazor
dotnet run
```

Then open: `https://localhost:5001`

### 3. Build the MAUI Application
```powershell
cd ObjectDetectionMaui
dotnet build -f net10.0-windows10.0.19041.0
```

---

## ?? Authentication

The applications use **DefaultAzureCredential** which supports:

? **Azure CLI** (for local development)
```bash
az login
```

? **Visual Studio / VS Code** (automatic)

? **Managed Identity** (when deployed to Azure)

? **Environment Variables** (fallback)

### Verify Authentication
```bash
# Check your current login
az account show

# Check role assignments
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)
```

---

## ?? Environment Variables

The scripts set these environment variables:

### For MAUI App:
```powershell
# PowerShell
$env:AZURE_COMPUTER_VISION_ENDPOINT="https://your-resource.cognitiveservices.azure.com/"

# Bash
export AZURE_COMPUTER_VISION_ENDPOINT="https://your-resource.cognitiveservices.azure.com/"
```

### For .NET Configuration:
```powershell
# PowerShell
$env:AzureComputerVision__Endpoint="https://your-resource.cognitiveservices.azure.com/"

# Bash
export AzureComputerVision__Endpoint="https://your-resource.cognitiveservices.azure.com/"
```

---

## ??? Troubleshooting

### Problem: "Not logged in to Azure"
**Solution:**
```bash
az login
```

### Problem: "Endpoint not configured"
**Solution:**
```powershell
# Update endpoints
.\update-azure-endpoints.ps1

# Or set environment variable
$env:AzureComputerVision__Endpoint="https://your-resource.cognitiveservices.azure.com/"
```

### Problem: "Authentication failed"
**Solution:**
```bash
# Re-login to Azure
az login

# Verify you have the correct role
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)
```

### Problem: "Resource not found"
**Solution:**
```bash
# List your Computer Vision resources
az cognitiveservices account list --query "[?kind=='ComputerVision']"

# Recreate if needed
.\complete-azure-setup.ps1
```

### Problem: Test script fails
**Solution:**
1. Check `azure-config.txt` for correct endpoint
2. Verify login: `az account show`
3. Check resource exists: `az cognitiveservices account show --name <name> --resource-group <rg>`
4. Review logs in the test output

---

## ?? Additional Resources

### Documentation Files
- `AZURE_DEPLOYMENT.md` - Detailed Azure CLI commands and deployment guide
- `AZURE_SETUP_GUIDE.md` - Step-by-step setup instructions
- `azure-config.txt` - Your specific configuration (created by scripts)

### Azure Resources
- [Computer Vision Documentation](https://learn.microsoft.com/azure/ai-services/computer-vision/)
- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)
- [DefaultAzureCredential](https://learn.microsoft.com/dotnet/api/azure.identity.defaultazurecredential)

### Project Structure
```
NewRepo/
??? ObjectDetectionBlazor/          # Blazor web application
?   ??? Services/
?   ?   ??? AzureObjectDetectionService.cs
?   ??? appsettings.json           # ? Updated by scripts
??? ObjectDetectionMaui/           # MAUI mobile/desktop app
?   ??? Services/
?       ??? AzureObjectDetectionService.cs
??? complete-azure-setup.ps1       # ? Run this first!
??? complete-azure-setup.sh        # Linux/macOS version
??? update-azure-endpoints.ps1     # Update endpoints
??? test-object-detection.ps1      # Test your setup
??? azure-config.txt              # Your configuration reference
```

---

## ?? Cost Estimation

**Computer Vision S1 SKU:**
- ~$1.00 per 1,000 transactions
- First 5,000 transactions free per month

**Typical usage:**
- Development/Testing: < $5/month
- Small production: $10-50/month
- Enterprise: Scales with usage

**To monitor costs:**
```bash
az cognitiveservices account show --name <name> --resource-group <rg> --query properties.metrics
```

---

## ?? Success Checklist

After running the setup, verify:

- [ ] `az account show` returns your account info
- [ ] `azure-config.txt` exists with your endpoint
- [ ] `ObjectDetectionBlazor/appsettings.json` has the correct endpoint
- [ ] Environment variables are set
- [ ] `.\test-object-detection.ps1` completes successfully
- [ ] Blazor app runs with `dotnet run`
- [ ] MAUI app builds successfully

---

## ?? Getting Help

If you encounter issues:

1. **Check the troubleshooting section above**
2. **Review `azure-config.txt`** for your configuration
3. **Run the test script:** `.\test-object-detection.ps1`
4. **Check Azure Portal** to verify resources exist
5. **Open an issue:** https://github.com/vende6/VS2026-.net10-playground/issues

---

## ?? Next Steps

1. ? Complete the setup (if not done): `.\complete-azure-setup.ps1`
2. ? Test the connection: `.\test-object-detection.ps1`
3. ? Run the Blazor app: `cd ObjectDetectionBlazor; dotnet run`
4. ? Explore the code and customize for your needs
5. ? Deploy to Azure: See `AZURE_DEPLOYMENT.md`

---

**Happy Object Detecting! ??**

Made with ?? by Damir
