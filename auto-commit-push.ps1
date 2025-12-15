<#
.SYNOPSIS
    Automatic Git commit and push script for Object Detection Solution

.DESCRIPTION
    PowerShell script to automatically find Git, stage all changes, commit with
    a comprehensive message, and push to GitHub. Includes error handling and
    detailed status messages.

.PARAMETER RepoPath
    Path to the repository (defaults to script directory)

.AUTHOR
    vende6

.VERSION
    1.0.0

.DATE
    2025-01-15

.REPOSITORY
    https://github.com/vende6/VS2026-.net10-playground

.LICENSE
    MIT License

.EXAMPLE
    .\auto-commit-push.ps1
    Runs the script from the current directory

.EXAMPLE
    .\auto-commit-push.ps1 -RepoPath "C:\path\to\repo"
    Runs the script with a specific repository path
#>

# Auto-commit and push script
param(
    [string]$RepoPath = $PSScriptRoot
)

Set-Location $RepoPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto-Committing and Pushing to GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Try to find git executable
$gitLocations = @(
    "git",
    "C:\Program Files\Git\bin\git.exe",
    "C:\Program Files (x86)\Git\bin\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\git.exe",
    "$env:ProgramFiles\Git\bin\git.exe",
    "$env:ProgramFiles(x86)\Git\bin\git.exe"
)

$gitExe = $null
foreach ($location in $gitLocations) {
    try {
        $result = & $location --version 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -match "git version") {
            $gitExe = $location
            Write-Host "Found Git at: $gitExe" -ForegroundColor Green
            break
        }
    } catch {
        continue
    }
}

if (-not $gitExe) {
    Write-Host "ERROR: Git executable not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please use Visual Studio's Git UI:" -ForegroundColor Yellow
    Write-Host "1. Press Ctrl+0, G to open Git Changes" -ForegroundColor Gray
    Write-Host "2. Review changes and commit" -ForegroundColor Gray
    Write-Host "3. Click Push button" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Repository: $RepoPath" -ForegroundColor Cyan
Write-Host ""

# Check git status
Write-Host "Checking status..." -ForegroundColor Yellow
& $gitExe status --short

# Add all files
Write-Host ""
Write-Host "Staging all files..." -ForegroundColor Yellow
& $gitExe add -A

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to stage files" -ForegroundColor Red
    exit 1
}

# Commit
$commitMessage = "Add Blazor and MAUI apps with Azure Computer Vision object detection

- Created Blazor Web App with image upload and object detection
- Created .NET MAUI cross-platform app with camera and gallery integration
- Integrated Azure Computer Vision API with Managed Identity authentication
- Added comprehensive documentation and deployment guides
- Configured secure authentication using DefaultAzureCredential
- Includes bounding boxes, confidence scores, tags, and captions"

Write-Host ""
Write-Host "Committing changes..." -ForegroundColor Yellow
& $gitExe commit -m $commitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit failed (might be nothing to commit)" -ForegroundColor Yellow
    & $gitExe status
} else {
    Write-Host ""
    Write-Host "Commit successful!" -ForegroundColor Green
}

# Push to origin
Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
& $gitExe push origin master

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "? Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository: https://github.com/vende6/VS2026-.net10-playground" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Push failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "- Need to authenticate with GitHub" -ForegroundColor Gray
    Write-Host "- Remote has changes - need to pull first" -ForegroundColor Gray
    Write-Host "- No network connection" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Try:" -ForegroundColor Yellow
    Write-Host "  git pull origin master --rebase" -ForegroundColor Gray
    Write-Host "  git push origin master" -ForegroundColor Gray
    Write-Host ""
}
