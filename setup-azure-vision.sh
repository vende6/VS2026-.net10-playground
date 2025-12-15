#!/bin/bash
# ========================================
# Azure Computer Vision Setup Script
# 
# Author: Damir
# Repository: https://github.com/vende6/VS2026-.net10-playground
# License: MIT
# Version: 1.0.0
# Date: 2025-01-15
# 
# Description:
#   Automated Azure CLI script to create Computer Vision resource
#   and configure authentication for object detection apps.
# ========================================

echo "=========================================="
echo "Azure Computer Vision Setup"
echo "=========================================="
echo ""

# Configuration Variables
RESOURCE_GROUP="ObjectDetectionRG"
LOCATION="eastus"
VISION_RESOURCE_NAME="objectdetection-vision-$(date +%s)"
SUBSCRIPTION_ID=""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}? $1${NC}"
}

print_info() {
    echo -e "${YELLOW}? $1${NC}"
}

print_error() {
    echo -e "${RED}? $1${NC}"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

print_success "Azure CLI found"

# Login to Azure
print_info "Logging in to Azure..."
az login

if [ $? -ne 0 ]; then
    print_error "Azure login failed"
    exit 1
fi

print_success "Successfully logged in to Azure"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
print_info "Using subscription: $SUBSCRIPTION_ID"

# Create Resource Group
print_info "Creating resource group: $RESOURCE_GROUP in $LOCATION..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

if [ $? -eq 0 ]; then
    print_success "Resource group created: $RESOURCE_GROUP"
else
    print_error "Failed to create resource group"
    exit 1
fi

# Create Computer Vision Resource
print_info "Creating Computer Vision resource: $VISION_RESOURCE_NAME..."
az cognitiveservices account create \
    --name $VISION_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --kind ComputerVision \
    --sku S1 \
    --location $LOCATION \
    --yes

if [ $? -eq 0 ]; then
    print_success "Computer Vision resource created: $VISION_RESOURCE_NAME"
else
    print_error "Failed to create Computer Vision resource"
    exit 1
fi

# Get the endpoint
VISION_ENDPOINT=$(az cognitiveservices account show \
    --name $VISION_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --query properties.endpoint \
    --output tsv)

print_success "Computer Vision endpoint: $VISION_ENDPOINT"

# Get the key (for reference, though we use Managed Identity)
VISION_KEY=$(az cognitiveservices account keys list \
    --name $VISION_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --query key1 \
    --output tsv)

# Get your user object ID for role assignment
USER_OBJECT_ID=$(az ad signed-in-user show --query id --output tsv)

# Get the resource ID
VISION_RESOURCE_ID=$(az cognitiveservices account show \
    --name $VISION_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --query id \
    --output tsv)

# Assign Cognitive Services User role to your user
print_info "Assigning Cognitive Services User role to your account..."
az role assignment create \
    --role "Cognitive Services User" \
    --assignee $USER_OBJECT_ID \
    --scope $VISION_RESOURCE_ID

if [ $? -eq 0 ]; then
    print_success "Role assigned successfully"
else
    print_error "Failed to assign role (you may already have it)"
fi

# Output summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Computer Vision Resource: $VISION_RESOURCE_NAME"
echo "Endpoint: $VISION_ENDPOINT"
echo ""
echo "Configuration for appsettings.json:"
echo "--------------------"
echo "\"AzureComputerVision\": {"
echo "  \"Endpoint\": \"$VISION_ENDPOINT\""
echo "}"
echo "--------------------"
echo ""
echo "Environment Variable (for MAUI):"
echo "--------------------"
echo "export AZURE_COMPUTER_VISION_ENDPOINT=\"$VISION_ENDPOINT\""
echo "--------------------"
echo ""
echo "For reference (use Managed Identity instead):"
echo "Key: $VISION_KEY"
echo ""

# Save configuration to file
CONFIG_FILE="azure-config.txt"
cat > $CONFIG_FILE << EOF
Azure Computer Vision Configuration
====================================
Created: $(date)
Author: Damir

Resource Group: $RESOURCE_GROUP
Location: $LOCATION
Subscription ID: $SUBSCRIPTION_ID
Computer Vision Resource: $VISION_RESOURCE_NAME
Endpoint: $VISION_ENDPOINT
Resource ID: $VISION_RESOURCE_ID

Blazor App Configuration (appsettings.json):
{
  "AzureComputerVision": {
    "Endpoint": "$VISION_ENDPOINT"
  }
}

MAUI App Environment Variable:
export AZURE_COMPUTER_VISION_ENDPOINT="$VISION_ENDPOINT"

Windows PowerShell:
\$env:AZURE_COMPUTER_VISION_ENDPOINT="$VISION_ENDPOINT"

Key (for reference - use Managed Identity):
$VISION_KEY
EOF

print_success "Configuration saved to: $CONFIG_FILE"
echo ""
print_info "Next steps:"
echo "1. Update ObjectDetectionBlazor/appsettings.json with the endpoint"
echo "2. Set environment variable for MAUI app"
echo "3. Run 'az login' on your development machine"
echo "4. Test the applications!"
echo ""
