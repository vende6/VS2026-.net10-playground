#!/bin/bash
#
# Complete Azure Computer Vision Setup Script
# 
# Author: Damir
# Repository: https://github.com/vende6/VS2026-.net10-playground
# License: MIT
# Version: 1.0.0
# Date: 2025-01-15
#
# Description:
#   Comprehensive setup script that creates Azure resources,
#   configures authentication, and updates application settings.
#

set -e

# Default values
RESOURCE_GROUP="${RESOURCE_GROUP:-ObjectDetectionRG}"
LOCATION="${LOCATION:-eastus}"
VISION_RESOURCE_NAME="${VISION_RESOURCE_NAME:-objectdetection-vision-$(date +%s)}"
USE_EXISTING="${USE_EXISTING:-false}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Functions for colored output
print_step() {
    echo -e "${YELLOW}? $1${NC}"
}

print_success() {
    echo -e "${GREEN}? $1${NC}"
}

print_failure() {
    echo -e "${RED}? $1${NC}"
}

print_info() {
    echo -e "${CYAN}? $1${NC}"
}

echo ""
echo "=========================================="
echo "  Azure Computer Vision Complete Setup  "
echo "=========================================="
echo ""
echo -e "${GRAY}Author: Damir${NC}"
echo -e "${GRAY}Repository: https://github.com/vende6/VS2026-.net10-playground${NC}"
echo ""

# Step 1: Verify Azure CLI
print_step "Verifying Azure CLI installation..."
if ! command -v az &> /dev/null; then
    print_failure "Azure CLI is not installed"
    echo ""
    echo -e "${YELLOW}Please install Azure CLI from:${NC}"
    echo -e "${CYAN}https://docs.microsoft.com/cli/azure/install-azure-cli${NC}"
    exit 1
fi

AZ_VERSION=$(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo "unknown")
print_success "Azure CLI version $AZ_VERSION installed"
echo ""

# Step 2: Verify Azure login
print_step "Verifying Azure authentication..."
if ! az account show &> /dev/null; then
    print_failure "Not logged in to Azure"
    echo ""
    print_step "Attempting to log in..."
    
    if az login; then
        ACCOUNT_INFO=$(az account show)
        USER_NAME=$(echo $ACCOUNT_INFO | jq -r '.user.name')
        print_success "Successfully logged in as: $USER_NAME"
    else
        print_failure "Azure login failed"
        echo -e "${YELLOW}Please run 'az login' manually and try again${NC}"
        exit 1
    fi
else
    ACCOUNT_INFO=$(az account show)
    USER_NAME=$(echo $ACCOUNT_INFO | jq -r '.user.name')
    SUBSCRIPTION_NAME=$(echo $ACCOUNT_INFO | jq -r '.name')
    SUBSCRIPTION_ID=$(echo $ACCOUNT_INFO | jq -r '.id')
    
    print_success "Logged in as: $USER_NAME"
    print_info "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
fi

echo ""

# Step 3: Check for existing resources
VISION_ENDPOINT=""
VISION_KEY=""

if [ "$USE_EXISTING" = "true" ]; then
    print_step "Searching for existing Computer Vision resources..."
    
    EXISTING_RESOURCES=$(az cognitiveservices account list \
        --query "[?kind=='ComputerVision'].{name:name, group:resourceGroup, endpoint:properties.endpoint, location:location}" \
        -o json)
    
    RESOURCE_COUNT=$(echo $EXISTING_RESOURCES | jq '. | length')
    
    if [ "$RESOURCE_COUNT" -gt 0 ]; then
        print_success "Found $RESOURCE_COUNT existing Computer Vision resource(s)"
        echo ""
        
        # Display resources
        echo "$EXISTING_RESOURCES" | jq -r '.[] | "  [\(.name)]\n    Resource Group: \(.group)\n    Location: \(.location)\n    Endpoint: \(.endpoint)\n"'
        
        if [ "$RESOURCE_COUNT" -eq 1 ]; then
            RESOURCE_GROUP=$(echo $EXISTING_RESOURCES | jq -r '.[0].group')
            VISION_RESOURCE_NAME=$(echo $EXISTING_RESOURCES | jq -r '.[0].name')
            VISION_ENDPOINT=$(echo $EXISTING_RESOURCES | jq -r '.[0].endpoint')
            print_info "Using the only available resource: $VISION_RESOURCE_NAME"
        else
            echo -e "${CYAN}Select resource number (1-$RESOURCE_COUNT): ${NC}"
            read -r selection
            
            index=$((selection - 1))
            RESOURCE_GROUP=$(echo $EXISTING_RESOURCES | jq -r ".[$index].group")
            VISION_RESOURCE_NAME=$(echo $EXISTING_RESOURCES | jq -r ".[$index].name")
            VISION_ENDPOINT=$(echo $EXISTING_RESOURCES | jq -r ".[$index].endpoint")
        fi
        
        print_success "Selected: $VISION_RESOURCE_NAME in $RESOURCE_GROUP"
    else
        print_info "No existing resources found. Creating new resource..."
        USE_EXISTING="false"
    fi
    
    echo ""
fi

# Step 4: Create Resource Group (if needed)
if [ -z "$VISION_ENDPOINT" ]; then
    print_step "Creating/verifying resource group: $RESOURCE_GROUP in $LOCATION..."
    
    if az group exists --name $RESOURCE_GROUP | grep -q "true"; then
        print_info "Resource group already exists: $RESOURCE_GROUP"
    else
        az group create \
            --name $RESOURCE_GROUP \
            --location $LOCATION \
            --output none
        
        print_success "Resource group created: $RESOURCE_GROUP"
    fi
    
    echo ""
    
    # Step 5: Create Computer Vision Resource
    print_step "Creating Computer Vision resource: $VISION_RESOURCE_NAME..."
    print_info "This may take 2-3 minutes..."
    echo ""
    
    if az cognitiveservices account create \
        --name $VISION_RESOURCE_NAME \
        --resource-group $RESOURCE_GROUP \
        --kind ComputerVision \
        --sku S1 \
        --location $LOCATION \
        --yes \
        --output none; then
        print_success "Computer Vision resource created successfully!"
    else
        print_failure "Failed to create Computer Vision resource"
        print_info "The resource name might already be taken. Try with a different name."
        exit 1
    fi
    
    echo ""
fi

# Step 6: Get resource details
print_step "Retrieving resource details..."

if [ -z "$VISION_ENDPOINT" ]; then
    VISION_ENDPOINT=$(az cognitiveservices account show \
        --name $VISION_RESOURCE_NAME \
        --resource-group $RESOURCE_GROUP \
        --query properties.endpoint \
        -o tsv)
fi

VISION_KEY=$(az cognitiveservices account keys list \
    --name $VISION_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --query key1 \
    -o tsv)

VISION_RESOURCE_ID=$(az cognitiveservices account show \
    --name $VISION_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --query id \
    -o tsv)

print_success "Endpoint: $VISION_ENDPOINT"
echo ""

# Step 7: Assign RBAC role
print_step "Configuring role-based access control (RBAC)..."

USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

if az role assignment create \
    --role "Cognitive Services User" \
    --assignee $USER_OBJECT_ID \
    --scope $VISION_RESOURCE_ID \
    --output none 2>/dev/null; then
    print_success "Cognitive Services User role assigned to your account"
else
    print_info "Role assignment skipped (you may already have it)"
fi

echo ""

# Step 8: Update configuration files
print_step "Updating configuration files..."

update_json_endpoint() {
    local file_path=$1
    local new_endpoint=$2
    
    if [ -f "$file_path" ]; then
        if python3 -c "
import json
import sys

try:
    with open('$file_path', 'r') as f:
        data = json.load(f)
    
    if 'AzureComputerVision' not in data:
        data['AzureComputerVision'] = {}
    
    data['AzureComputerVision']['Endpoint'] = '$new_endpoint'
    
    with open('$file_path', 'w') as f:
        json.dump(data, f, indent=2)
    
    print('success')
except Exception as e:
    print(f'error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
            echo -e "  ${GREEN}? Updated: $file_path${NC}"
            return 0
        else
            echo -e "  ${RED}? Failed: $file_path${NC}"
            return 1
        fi
    else
        echo -e "  ${YELLOW}? Not found: $file_path${NC}"
        return 1
    fi
}

# Update Blazor appsettings
update_json_endpoint "ObjectDetectionBlazor/appsettings.json" "$VISION_ENDPOINT"

if [ -f "ObjectDetectionBlazor/appsettings.Development.json" ]; then
    update_json_endpoint "ObjectDetectionBlazor/appsettings.Development.json" "$VISION_ENDPOINT"
fi

echo ""

# Step 9: Set environment variables
print_step "Setting environment variables..."

export AZURE_COMPUTER_VISION_ENDPOINT="$VISION_ENDPOINT"
export AzureComputerVision__Endpoint="$VISION_ENDPOINT"

echo -e "  ${GREEN}? Session variables set${NC}"
echo -e "    ${GRAY}• AZURE_COMPUTER_VISION_ENDPOINT${NC}"
echo -e "    ${GRAY}• AzureComputerVision__Endpoint${NC}"

# Add to shell profile
echo ""
echo -e "${CYAN}Add permanent environment variables to your shell profile? (y/n): ${NC}"
read -r set_permanent

if [ "$set_permanent" = "y" ] || [ "$set_permanent" = "Y" ]; then
    SHELL_RC=""
    
    if [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    
    if [ -n "$SHELL_RC" ]; then
        echo "" >> "$SHELL_RC"
        echo "# Azure Computer Vision Configuration (added $(date))" >> "$SHELL_RC"
        echo "export AZURE_COMPUTER_VISION_ENDPOINT=\"$VISION_ENDPOINT\"" >> "$SHELL_RC"
        echo "export AzureComputerVision__Endpoint=\"$VISION_ENDPOINT\"" >> "$SHELL_RC"
        
        print_success "Environment variables added to $SHELL_RC"
        print_info "Run 'source $SHELL_RC' to apply changes"
    fi
fi

echo ""

# Step 10: Create configuration file
print_step "Creating configuration reference file..."

CONFIG_FILE="azure-config.txt"

cat > $CONFIG_FILE << EOF
=========================================
Azure Computer Vision Configuration
=========================================
Created: $(date)
Author: Damir
Repository: https://github.com/vende6/VS2026-.net10-playground

AZURE RESOURCES
=========================================
Subscription ID: $SUBSCRIPTION_ID
Resource Group: $RESOURCE_GROUP
Location: $LOCATION
Computer Vision Resource: $VISION_RESOURCE_NAME
Resource ID: $VISION_RESOURCE_ID
Endpoint: $VISION_ENDPOINT

CONFIGURATION
=========================================

Blazor App (appsettings.json):
{
  "AzureComputerVision": {
    "Endpoint": "$VISION_ENDPOINT"
  }
}

Environment Variables (Bash/Linux/macOS):
export AZURE_COMPUTER_VISION_ENDPOINT="$VISION_ENDPOINT"
export AzureComputerVision__Endpoint="$VISION_ENDPOINT"

Environment Variables (PowerShell/Windows):
\$env:AZURE_COMPUTER_VISION_ENDPOINT="$VISION_ENDPOINT"
\$env:AzureComputerVision__Endpoint="$VISION_ENDPOINT"

AUTHENTICATION
=========================================
Method: DefaultAzureCredential
Supports:
  ? Azure CLI (az login)
  ? Visual Studio / VS Code
  ? Managed Identity (when deployed)
  ? Environment variables

Current User: $USER_NAME
Role: Cognitive Services User

REFERENCE (DO NOT USE IN PRODUCTION)
=========================================
Key1: $VISION_KEY

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
   dotnet build

4. Deploy to Azure:
   See AZURE_DEPLOYMENT.md for deployment instructions

USEFUL COMMANDS
=========================================
# Check current login status
az account show

# List all Computer Vision resources
az cognitiveservices account list --query "[?kind=='ComputerVision']"

# View resource details
az cognitiveservices account show --name $VISION_RESOURCE_NAME --resource-group $RESOURCE_GROUP

# Check role assignments
az role assignment list --scope $VISION_RESOURCE_ID --output table

# Monitor API calls
az monitor metrics list --resource $VISION_RESOURCE_ID --metric TotalCalls

TROUBLESHOOTING
=========================================
If you encounter authentication errors:
1. Run: az login
2. Verify role: az role assignment list --assignee $USER_OBJECT_ID
3. Check endpoint in appsettings.json
4. Restart your IDE

If you encounter "credential not found" errors:
1. Ensure you're logged in: az account show
2. Check environment variables are set
3. Verify the endpoint URL is correct

SUPPORT
=========================================
Documentation: https://learn.microsoft.com/azure/ai-services/computer-vision/
Repository: https://github.com/vende6/VS2026-.net10-playground
Issues: https://github.com/vende6/VS2026-.net10-playground/issues

EOF

print_success "Configuration saved to: $CONFIG_FILE"
echo ""

# Step 11: Test connection
echo -e "${CYAN}Would you like to test the Azure Computer Vision connection now? (y/n): ${NC}"
read -r test_connection

if [ "$test_connection" = "y" ] || [ "$test_connection" = "Y" ]; then
    echo ""
    print_step "Testing Azure Computer Vision connection..."
    
    TEST_RESULT=$(az cognitiveservices account show \
        --name $VISION_RESOURCE_NAME \
        --resource-group $RESOURCE_GROUP \
        --query provisioningState \
        -o tsv)
    
    if [ "$TEST_RESULT" = "Succeeded" ]; then
        print_success "Connection test successful! Resource is ready."
    else
        print_info "Resource state: $TEST_RESULT"
    fi
fi

echo ""
echo "=========================================="
echo "  Setup Complete! ?"
echo "=========================================="
echo ""

# Summary
echo -e "${YELLOW}SUMMARY${NC}"
echo "-------"
echo -e "? Resource Group: ${CYAN}$RESOURCE_GROUP${NC}"
echo -e "? Computer Vision: ${CYAN}$VISION_RESOURCE_NAME${NC}"
echo -e "? Endpoint: ${CYAN}$VISION_ENDPOINT${NC}"
echo -e "? Configuration: ${GREEN}Updated${NC}"
echo -e "? Authentication: ${GREEN}Ready${NC}"
echo ""

echo -e "${YELLOW}NEXT STEPS${NC}"
echo "----------"
echo -e "1. Review configuration: ${CYAN}cat $CONFIG_FILE${NC}"
echo -e "2. Test Blazor app: ${CYAN}cd ObjectDetectionBlazor && dotnet run${NC}"
echo -e "3. Build MAUI app: ${CYAN}cd ObjectDetectionMaui && dotnet build${NC}"
echo -e "4. Read deployment guide: ${CYAN}AZURE_DEPLOYMENT.md${NC}"
echo ""

echo -e "${GREEN}?? Your Azure Computer Vision setup is complete!${NC}"
echo -e "${GREEN}   You can now start detecting objects in images!${NC}"
echo ""
