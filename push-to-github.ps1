<#
.SYNOPSIS
    Git commit and push automation script for Object Detection Solution

.DESCRIPTION
    PowerShell script to automatically stage, commit, and push all changes to GitHub.
    Checks for Git availability, displays changes, prompts for commit message,
    and pushes to the remote repository.

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
    .\push-to-github.ps1
    Runs the script from the current directory
#>

# PowerShell script to commit and push all changes to GitHub
# Run this script from the NewRepo directory

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pushing Object Detection Solution to GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to the repository directory
Set-Location $PSScriptRoot

# Check if git is available
$gitPath = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $gitPath) {
    Write-Host "ERROR: Git is not found in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "Or add Git to your PATH if already installed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common Git installation paths:" -ForegroundColor Yellow
    Write-Host "  - C:\Program Files\Git\bin\git.exe" -ForegroundColor Gray
    Write-Host "  - C:\Program Files (x86)\Git\bin\git.exe" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "Git found at: $gitPath" -ForegroundColor Green
Write-Host ""

# Display current status
Write-Host "Current Git Status:" -ForegroundColor Yellow
git status
Write-Host ""

# Add all files
Write-Host "Adding all files..." -ForegroundColor Yellow
git add .
Write-Host ""

# Display what will be committed
Write-Host "Files to be committed:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Prompt for commit message
Write-Host "Enter commit message (or press Enter for default):" -ForegroundColor Cyan
$commitMessage = Read-Host
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Add Blazor and MAUI apps with Azure Computer Vision object detection"
}

# Commit changes
Write-Host ""
Write-Host "Committing changes..." -ForegroundColor Yellow
git commit -m $commitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Commit failed or nothing to commit" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Display remote info
Write-Host ""
Write-Host "Remote repository:" -ForegroundColor Yellow
git remote -v
Write-Host ""

# Ask for confirmation before pushing
Write-Host "Ready to push to GitHub?" -ForegroundColor Cyan
Write-Host "Press 'y' to continue, any other key to cancel" -ForegroundColor Gray
$confirmation = Read-Host

if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    Write-Host ""
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    git push origin master
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Successfully pushed to GitHub!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Repository: https://github.com/vende6/VS2026-.net10-playground" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "Push failed!" -ForegroundColor Red
        Write-Host "You may need to pull changes first or resolve conflicts" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Try running:" -ForegroundColor Yellow
        Write-Host "  git pull origin master --rebase" -ForegroundColor Gray
        Write-Host "  git push origin master" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "Push cancelled" -ForegroundColor Yellow
    Write-Host ""
}
