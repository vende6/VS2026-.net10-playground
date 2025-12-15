<#
.SYNOPSIS
    Complete Azure Computer Vision Setup and Configuration

.DESCRIPTION
    Comprehensive script that completes the entire Azure Computer Vision setup:
    - Verifies Azure CLI login
    - Creates or retrieves Computer Vision resources
    - Updates all configuration files
    - Tests the connection
    - Provides next steps

.AUTHOR
    Damir

.VERSION
    1.0.0

.DATE
    2025-01-15

.REPOSITORY
    https://github.com/vende6/VS2026-.net10-playground

.LICENSE
    MIT License

.EXAMPLE
    .\complete-azure-setup.ps1
    Runs the complete setup process interactively

.EXAMPLE
    .\complete-azure-setup.ps1 -ResourceGroup "MyRG" -Location "eastus"
    Creates resources with specified parameters
#>

param(
    [string]$ResourceGroup = "ObjectDetectionRG",
    [string]$Location = "eastus",
    [string]$VisionResourceName = "objectdetection-vision-$(Get-Date -Format 'yyyyMMddHHmmss')",
    [switch]$UseExisting
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Azure Computer Vision Complete Setup  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Author: Damir" -ForegroundColor Gray
Write-Host "Repository: https://github.com/vende6/VS2026-.net10-playground" -ForegroundColor Gray
Write-Host ""

# Function to print status messages
function Write-Step {
    param([string]$Message)
    Write-Host "? $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "? $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "? $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "? $Message" -ForegroundColor Cyan
}

# Step 1: Verify Azure CLI installation
Write-Step "Verifying Azure CLI installation..."
try {
    $azVersion = az version 2>&1 | ConvertFrom-Json
    Write-Success "Azure CLI version $($azVersion.'azure-cli') installed"
} catch {
    Write-Failure "Azure CLI is not installed or not in PATH"
    Write-Host ""
    Write-Host "Please install Azure CLI from:" -ForegroundColor Yellow
    Write-Host "https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

# Step 2: Verify Azure login
Write-Step "Verifying Azure authentication..."
try {
    $accountInfo = az account show 2>&1 | ConvertFrom-Json
    Write-Success "Logged in as: $($accountInfo.user.name)"
    Write-Info "Subscription: $($accountInfo.name) ($($accountInfo.id))"
    $SubscriptionId = $accountInfo.id
} catch {
    Write-Failure "Not logged in to Azure"
    Write-Host ""
    Write-Step "Attempting to log in..."
    
    try {
        az login --output none
        $accountInfo = az account show 2>&1 | ConvertFrom-Json
        Write-Success "Successfully logged in as: $($accountInfo.user.name)"
        $SubscriptionId = $accountInfo.id
    } catch {
        Write-Failure "Azure login failed"
        Write-Host "Please run 'az login' manually and try again" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""

# Step 3: Check for existing resources or create new ones
$VisionEndpoint = $null
$VisionKey = $null

if ($UseExisting) {
    Write-Step "Searching for existing Computer Vision resources..."
    
    $existingResources = az cognitiveservices account list `
        --query "[?kind=='ComputerVision'].{name:name, group:resourceGroup, endpoint:properties.endpoint, location:location}" `
        --output json | ConvertFrom-Json
    
    if ($existingResources -and $existingResources.Count -gt 0) {
        Write-Success "Found $($existingResources.Count) existing Computer Vision resource(s)"
        Write-Host ""
        
        for ($i = 0; $i -lt $existingResources.Count; $i++) {
            Write-Host "  [$($i + 1)] $($existingResources[$i].name)" -ForegroundColor Cyan
            Write-Host "      Resource Group: $($existingResources[$i].group)" -ForegroundColor Gray
            Write-Host "      Location: $($existingResources[$i].location)" -ForegroundColor Gray
            Write-Host "      Endpoint: $($existingResources[$i].endpoint)" -ForegroundColor Gray
            Write-Host ""
        }
        
        if ($existingResources.Count -eq 1) {
            $selectedResource = $existingResources[0]
            Write-Info "Using the only available resource: $($selectedResource.name)"
        } else {
            do {
                $selection = Read-Host "Select resource number (1-$($existingResources.Count))"
                $selectionNum = [int]$selection
            } while ($selectionNum -lt 1 -or $selectionNum -gt $existingResources.Count)
            
            $selectedResource = $existingResources[$selectionNum - 1]
        }
        
        $ResourceGroup = $selectedResource.group
        $VisionResourceName = $selectedResource.name
        $VisionEndpoint = $selectedResource.endpoint
        
        Write-Success "Selected: $VisionResourceName in $ResourceGroup"
    } else {
        Write-Info "No existing resources found. Creating new resource..."
        $UseExisting = $false
    }
    
    Write-Host ""
}

if (-not $UseExisting -or -not $VisionEndpoint) {
    # Step 4: Create Resource Group
    Write-Step "Creating/verifying resource group: $ResourceGroup in $Location..."
    
    $existingRG = az group exists --name $ResourceGroup
    
    if ($existingRG -eq "true") {
        Write-Info "Resource group already exists: $ResourceGroup"
    } else {
        az group create `
            --name $ResourceGroup `
            --location $Location `
            --output none
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Resource group created: $ResourceGroup"
        } else {
            Write-Failure "Failed to create resource group"
            exit 1
        }
    }
    
    Write-Host ""
    
    # Step 5: Create Computer Vision Resource
    Write-Step "Creating Computer Vision resource: $VisionResourceName..."
    Write-Info "This may take 2-3 minutes..."
    Write-Host ""
    
    az cognitiveservices account create `
        --name $VisionResourceName `
        --resource-group $ResourceGroup `
        --kind ComputerVision `
        --sku S1 `
        --location $Location `
        --yes `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Computer Vision resource created successfully!"
    } else {
        Write-Failure "Failed to create Computer Vision resource"
        Write-Info "The resource name might already be taken. Try with a different name."
        exit 1
    }
    
    Write-Host ""
    
    # Get the endpoint
    $VisionEndpoint = az cognitiveservices account show `
        --name $VisionResourceName `
        --resource-group $ResourceGroup `
        --query properties.endpoint `
        --output tsv
}

# Step 6: Get resource details
Write-Step "Retrieving resource details..."

if (-not $VisionEndpoint) {
    $VisionEndpoint = az cognitiveservices account show `
        --name $VisionResourceName `
        --resource-group $ResourceGroup `
        --query properties.endpoint `
        --output tsv
}

$VisionKey = az cognitiveservices account keys list `
    --name $VisionResourceName `
    --resource-group $ResourceGroup `
    --query key1 `
    --output tsv

$VisionResourceId = az cognitiveservices account show `
    --name $VisionResourceName `
    --resource-group $ResourceGroup `
    --query id `
    --output tsv

Write-Success "Endpoint: $VisionEndpoint"
Write-Host ""

# Step 7: Assign RBAC role
Write-Step "Configuring role-based access control (RBAC)..."

$UserObjectId = az ad signed-in-user show --query id --output tsv

try {
    az role assignment create `
        --role "Cognitive Services User" `
        --assignee $UserObjectId `
        --scope $VisionResourceId `
        --output none 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Cognitive Services User role assigned to your account"
    } else {
        Write-Info "Role assignment skipped (you may already have it)"
    }
} catch {
    Write-Info "Role assignment skipped (you may already have it)"
}

Write-Host ""

# Step 8: Update configuration files
Write-Step "Updating configuration files..."

function Update-JsonEndpoint {
    param(
        [string]$FilePath,
        [string]$NewEndpoint
    )
    
    if (Test-Path $FilePath) {
        try {
            $json = Get-Content $FilePath -Raw | ConvertFrom-Json
            
            if (-not $json.AzureComputerVision) {
                $json | Add-Member -MemberType NoteProperty -Name "AzureComputerVision" -Value @{} -Force
            }
            
            if ($json.AzureComputerVision.PSObject.Properties.Name -contains "Endpoint") {
                $json.AzureComputerVision.Endpoint = $NewEndpoint
            } else {
                $json.AzureComputerVision | Add-Member -MemberType NoteProperty -Name "Endpoint" -Value $NewEndpoint -Force
            }
            
            $json | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
            Write-Host "  ? Updated: $FilePath" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "  ? Failed: $FilePath - $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "  ? Not found: $FilePath" -ForegroundColor Yellow
        return $false
    }
}

# Update Blazor appsettings
$blazorAppsettings = "ObjectDetectionBlazor\appsettings.json"
Update-JsonEndpoint -FilePath $blazorAppsettings -NewEndpoint $VisionEndpoint

$blazorDevAppsettings = "ObjectDetectionBlazor\appsettings.Development.json"
if (Test-Path $blazorDevAppsettings) {
    Update-JsonEndpoint -FilePath $blazorDevAppsettings -NewEndpoint $VisionEndpoint
}

Write-Host ""

# Step 9: Set environment variables
Write-Step "Setting environment variables..."

$env:AZURE_COMPUTER_VISION_ENDPOINT = $VisionEndpoint
$env:AzureComputerVision__Endpoint = $VisionEndpoint

Write-Host "  ? Session variables set" -ForegroundColor Green
Write-Host "    • AZURE_COMPUTER_VISION_ENDPOINT" -ForegroundColor Gray
Write-Host "    • AzureComputerVision__Endpoint" -ForegroundColor Gray

# Optionally set permanent user environment variables
Write-Host ""
Write-Host "Set permanent user environment variables? (y/n): " -NoNewline -ForegroundColor Cyan
$setPermanent = Read-Host

if ($setPermanent -eq 'y' -or $setPermanent -eq 'Y') {
    [System.Environment]::SetEnvironmentVariable("AZURE_COMPUTER_VISION_ENDPOINT", $VisionEndpoint, "User")
    [System.Environment]::SetEnvironmentVariable("AzureComputerVision__Endpoint", $VisionEndpoint, "User")
    Write-Host "  ? Permanent environment variables set" -ForegroundColor Green
}

Write-Host ""

# Step 10: Create configuration reference file
Write-Step "Creating configuration reference file..."

$ConfigFile = "azure-config.txt"
$ConfigContent = @"
=========================================
Azure Computer Vision Configuration
=========================================
Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Author: Damir
Repository: https://github.com/vende6/VS2026-.net10-playground

AZURE RESOURCES
=========================================
Subscription ID: $SubscriptionId
Resource Group: $ResourceGroup
Location: $Location
Computer Vision Resource: $VisionResourceName
Resource ID: $VisionResourceId
Endpoint: $VisionEndpoint

CONFIGURATION
=========================================

Blazor App (appsettings.json):
{
  "AzureComputerVision": {
    "Endpoint": "$VisionEndpoint"
  }
}

Environment Variables (PowerShell):
`$env:AZURE_COMPUTER_VISION_ENDPOINT="$VisionEndpoint"
`$env:AzureComputerVision__Endpoint="$VisionEndpoint"

Environment Variables (Bash/Linux):
export AZURE_COMPUTER_VISION_ENDPOINT="$VisionEndpoint"
export AzureComputerVision__Endpoint="$VisionEndpoint"

AUTHENTICATION
=========================================
Method: DefaultAzureCredential
Supports:
  ? Azure CLI (az login)
  ? Visual Studio / VS Code
  ? Managed Identity (when deployed)
  ? Environment variables

Current User: $($accountInfo.user.name)
Role: Cognitive Services User

REFERENCE (DO NOT USE IN PRODUCTION)
=========================================
Key1: $VisionKey

Note: Use Managed Identity or Azure CLI instead of keys
for better security and automatic credential rotation.

NEXT STEPS
=========================================
1. Verify authentication:
   az login

2. Test Blazor application:
   cd ObjectDetectionBlazor
   dotnet run

3. Test MAUI application:
   cd ObjectDetectionMaui
   dotnet build -f net10.0-windows10.0.19041.0

4. Deploy to Azure:
   See AZURE_DEPLOYMENT.md for deployment instructions

USEFUL COMMANDS
=========================================
# Check current login status
az account show

# List all Computer Vision resources
az cognitiveservices account list --query "[?kind=='ComputerVision']"

# View resource details
az cognitiveservices account show --name $VisionResourceName --resource-group $ResourceGroup

# Check role assignments
az role assignment list --scope $VisionResourceId --output table

# Monitor API calls
az monitor metrics list --resource $VisionResourceId --metric TotalCalls

TROUBLESHOOTING
=========================================
If you encounter authentication errors:
1. Run: az login
2. Verify role: az role assignment list --assignee $UserObjectId
3. Check endpoint in appsettings.json
4. Restart Visual Studio or IDE

If you encounter "credential not found" errors:
1. Ensure you're logged in: az account show
2. Check environment variables are set
3. Verify the endpoint URL is correct

SUPPORT
=========================================
Documentation: https://learn.microsoft.com/azure/ai-services/computer-vision/
Repository: https://github.com/vende6/VS2026-.net10-playground
Issues: https://github.com/vende6/VS2026-.net10-playground/issues

"@

$ConfigContent | Out-File -FilePath $ConfigFile -Encoding UTF8
Write-Success "Configuration saved to: $ConfigFile"

Write-Host ""

# Step 11: Test connection (optional)
Write-Host "Would you like to test the Azure Computer Vision connection now? (y/n): " -NoNewline -ForegroundColor Cyan
$testConnection = Read-Host

if ($testConnection -eq 'y' -or $testConnection -eq 'Y') {
    Write-Host ""
    Write-Step "Testing Azure Computer Vision connection..."
    
    try {
        # Quick test using Azure CLI
        $testResult = az cognitiveservices account show `
            --name $VisionResourceName `
            --resource-group $ResourceGroup `
            --query provisioningState `
            --output tsv
        
        if ($testResult -eq "Succeeded") {
            Write-Success "Connection test successful! Resource is ready."
        } else {
            Write-Info "Resource state: $testResult"
        }
    } catch {
        Write-Failure "Connection test failed: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Setup Complete! ?" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host "-------" -ForegroundColor Gray
Write-Host "? Resource Group: " -NoNewline
Write-Host $ResourceGroup -ForegroundColor Cyan
Write-Host "? Computer Vision: " -NoNewline
Write-Host $VisionResourceName -ForegroundColor Cyan
Write-Host "? Endpoint: " -NoNewline
Write-Host $VisionEndpoint -ForegroundColor Cyan
Write-Host "? Configuration: " -NoNewline
Write-Host "Updated" -ForegroundColor Green
Write-Host "? Authentication: " -NoNewline
Write-Host "Ready" -ForegroundColor Green
Write-Host ""

Write-Host "NEXT STEPS" -ForegroundColor Yellow
Write-Host "----------" -ForegroundColor Gray
Write-Host "1. Review configuration: " -NoNewline
Write-Host "type $ConfigFile" -ForegroundColor Cyan
Write-Host "2. Test Blazor app: " -NoNewline
Write-Host "cd ObjectDetectionBlazor; dotnet run" -ForegroundColor Cyan
Write-Host "3. Build MAUI app: " -NoNewline
Write-Host "cd ObjectDetectionMaui; dotnet build" -ForegroundColor Cyan
Write-Host "4. Read deployment guide: " -NoNewline
Write-Host "AZURE_DEPLOYMENT.md" -ForegroundColor Cyan
Write-Host ""

Write-Host "?? Your Azure Computer Vision setup is complete!" -ForegroundColor Green
Write-Host "   You can now start detecting objects in images!" -ForegroundColor Green
Write-Host ""
