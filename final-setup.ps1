<#
.SYNOPSIS
    Final Setup Script - Run this after Azure CLI installation completes

.DESCRIPTION
    This script completes the Azure Computer Vision setup after Azure CLI is installed.
    It will create all necessary Azure resources and update your application configurations.

.AUTHOR
    Damir

.DATE
    2025-01-15
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Final Azure Setup for Object Detection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Wait for Azure CLI installation to complete
Write-Host "Waiting for Azure CLI installation to complete..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes. Please wait..." -ForegroundColor Gray
Write-Host ""

Start-Sleep -Seconds 60

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Test Azure CLI
Write-Host "Testing Azure CLI installation..." -ForegroundColor Yellow
try {
    $azVersion = az --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "? Azure CLI installed successfully!" -ForegroundColor Green
    } else {
        throw "Azure CLI not ready"
    }
} catch {
    Write-Host "? Azure CLI installation is still in progress or failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Wait for the installation to complete" -ForegroundColor White
    Write-Host "2. Close and reopen PowerShell/Terminal" -ForegroundColor White
    Write-Host "3. Run this script again: .\final-setup.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Or manually run: .\setup-azure-vision.ps1" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Proceeding with Azure setup..." -ForegroundColor Green
Write-Host ""

# Run the main setup script
& "$PSScriptRoot\setup-azure-vision.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Check azure-config.txt for your endpoint" -ForegroundColor White
Write-Host "2. Test Blazor app: cd ObjectDetectionBlazor; dotnet run" -ForegroundColor White
Write-Host "3. Test MAUI app: cd ObjectDetectionMaui; dotnet build" -ForegroundColor White
Write-Host ""
