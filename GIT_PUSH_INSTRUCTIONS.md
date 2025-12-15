# Manual Git Commands to Push Changes

**Author:** Damir (vende6)  
**Repository:** https://github.com/vende6/VS2026-.net10-playground  
**License:** MIT  
**Version:** 1.0.0  
**Date:** 2025-01-15  

---

## Overview

Since Git may not be available in your current PowerShell session, here are the manual commands to run:

## Option 1: Use the Automated Scripts

We've created two scripts for you:

### PowerShell Script
```powershell
cd C:\Users\cyinide\source\repos\NewRepo
.\push-to-github.ps1
```

### Batch File (CMD)
```cmd
cd C:\Users\cyinide\source\repos\NewRepo
push-to-github.bat
```

## Option 2: Use Visual Studio's Git Integration

1. In Visual Studio, go to **View** ? **Git Changes** (or press `Ctrl+0, Ctrl+G`)
2. You'll see all the new and modified files
3. Enter a commit message: "Add Blazor and MAUI apps with Azure Computer Vision object detection"
4. Click **Commit All**
5. Click **Push** to send to GitHub

## Option 3: Use Git from Command Line

Open **Git Bash** or **Command Prompt** and run:

```bash
# Navigate to the repository
cd C:\Users\cyinide\source\repos\NewRepo

# Check current status
git status

# Add all new files
git add .

# Commit with a message
git commit -m "Add Blazor and MAUI apps with Azure Computer Vision object detection"

# Push to GitHub
git push origin master
```

## Option 4: Use GitHub Desktop

1. Open GitHub Desktop
2. Select the repository: `NewRepo`
3. Review the changes in the left panel
4. Add commit message: "Add Blazor and MAUI apps with Azure Computer Vision object detection"
5. Click **Commit to master**
6. Click **Push origin**

## Files Being Added

The following new files will be pushed:

### Solution Files
- `ObjectDetectionSolution.slnx`

### Blazor App
- `ObjectDetectionBlazor/` (entire project)
  - Models/DetectedObject.cs
  - Services/AzureObjectDetectionService.cs
  - Components/Pages/ObjectDetection.razor
  - Updated Program.cs and NavMenu.razor
  - Updated appsettings.json

### MAUI App
- `ObjectDetectionMaui/` (entire project)
  - Models/DetectedObject.cs
  - Services/AzureObjectDetectionService.cs
  - ViewModels/ObjectDetectionViewModel.cs
  - Views/ObjectDetectionPage.xaml + .cs
  - Converters/ValueConverters.cs
  - Updated MauiProgram.cs, App.xaml, AppShell.xaml

### Documentation
- `README.md`
- `AZURE_DEPLOYMENT.md`
- `push-to-github.ps1`
- `push-to-github.bat`
- `GIT_PUSH_INSTRUCTIONS.md` (this file)

## Troubleshooting

### If Git is not recognized

Install Git for Windows:
```
https://git-scm.com/download/win
```

After installation, restart your terminal/PowerShell/Visual Studio.

### If push is rejected

You may need to pull first if there are remote changes:
```bash
git pull origin master --rebase
git push origin master
```

### If you need to authenticate

GitHub may prompt for authentication. You can use:
- Personal Access Token (recommended)
- GitHub Desktop for easier authentication
- SSH keys

Generate a Personal Access Token at:
```
https://github.com/settings/tokens
```

## Your Repository

**Repository URL**: https://github.com/vende6/VS2026-.net10-playground

After pushing, you can view your changes at:
https://github.com/vende6/VS2026-.net10-playground/commits/master
