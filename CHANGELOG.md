# Changelog

All notable changes to the Azure Object Detection Solution will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-15

### Added - Initial Release

#### Blazor Web App
- ? Image upload functionality with file picker
- ?? Azure Computer Vision integration for object detection
- ?? Bounding box visualization with confidence scores
- ??? Tag and caption display
- ?? Responsive Bootstrap UI
- ?? Secure authentication using Azure Managed Identity
- ?? Comprehensive error handling and logging
- ? Real-time image analysis

#### .NET MAUI App
- ?? Cross-platform support for Android, iOS, Windows, and macOS
- ?? Camera integration for taking photos
- ??? Gallery integration for picking existing photos
- ?? Azure Computer Vision object detection
- ?? MVVM architecture with proper separation of concerns
- ?? Native UI with XAML
- ?? Secure authentication using Azure Managed Identity
- ?? Comprehensive error handling
- ?? Observable collections for real-time updates

#### Shared Features
- ?? DefaultAzureCredential for secure authentication
- ?? Support for both Managed Identity and local development
- ?? Clean architecture with service layer
- ?? Detailed documentation and setup guides
- ?? Azure deployment scripts and guides
- ? Complete project metadata and licensing

#### Documentation
- ?? README.md with comprehensive setup instructions
- ?? AZURE_DEPLOYMENT.md with step-by-step Azure CLI commands
- ?? GIT_PUSH_INSTRUCTIONS.md for version control
- ?? LICENSE file (MIT)
- ?? AUTHORS.md with contributor information
- ?? Full code documentation with XML comments

#### Infrastructure
- ??? PowerShell and batch scripts for Git operations
- ?? NuGet packages:
  - Azure.AI.Vision.ImageAnalysis 1.0.0
  - Azure.Identity 1.17.1
- ??? Solution file for multi-project management
- ?? Project metadata in .csproj files

### Security
- ?? No hardcoded credentials
- ?? Managed Identity support for Azure deployment
- ??? DefaultAzureCredential for local development
- ?? HTTPS-only communication with Azure services
- ?? Environment-based configuration

### Technical Details
- **Framework:** .NET 10.0
- **Language:** C# 13
- **UI Frameworks:** Blazor Server, .NET MAUI
- **Cloud Platform:** Microsoft Azure
- **AI Service:** Azure Computer Vision
- **Authentication:** Azure Identity with Managed Identity
- **Architecture:** Clean Architecture, MVVM (MAUI)

---

## Release Notes

### Version 1.0.0 Highlights

This is the initial release of the Azure Object Detection Solution, featuring:

1. **Dual Application Approach**
   - Web-based Blazor app for desktop browsers
   - Native MAUI app for mobile and desktop platforms

2. **Azure Integration**
   - Complete integration with Azure Computer Vision
   - Secure authentication using best practices
   - Support for both cloud and local development

3. **Production Ready**
   - Comprehensive error handling
   - Logging and monitoring support
   - Deployment guides for Azure App Service
   - Full documentation

4. **Developer Experience**
   - Clean, well-documented code
   - Proper metadata and licensing
   - Easy-to-follow setup guides
   - Helper scripts for common tasks

---

## Planned Features

See the [issues page](https://github.com/vende6/VS2026-.net10-playground/issues) for upcoming features and improvements.

---

**Author:** Damir (vende6)  
**Repository:** https://github.com/vende6/VS2026-.net10-playground  
**License:** MIT
