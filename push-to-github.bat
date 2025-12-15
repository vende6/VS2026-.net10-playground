@echo off
REM ========================================
REM Git Commit and Push Automation Script
REM 
REM Author: Damir
REM Repository: https://github.com/vende6/VS2026-.net10-playground
REM License: MIT
REM Version: 1.0.0
REM Date: 2025-01-15
REM 
REM Description:
REM   Batch script to automatically stage, commit, and push all changes to GitHub.
REM   Checks for Git availability, displays changes, and pushes to remote repository.
REM ========================================

REM Batch script to commit and push all changes to GitHub
REM Run this script from the NewRepo directory

echo ========================================
echo Pushing Object Detection Solution to GitHub
echo ========================================
echo.

REM Check if git is available
where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git is not found in PATH
    echo.
    echo Please install Git from: https://git-scm.com/download/win
    echo Or add Git to your PATH if already installed
    echo.
    pause
    exit /b 1
)

echo Git found!
echo.

REM Display current status
echo Current Git Status:
git status
echo.

REM Add all files
echo Adding all files...
git add .
echo.

REM Display what will be committed
echo Files to be committed:
git status --short
echo.

REM Commit changes
set /p COMMIT_MSG="Enter commit message (or press Enter for default): "
if "%COMMIT_MSG%"=="" set COMMIT_MSG=Add Blazor and MAUI apps with Azure Computer Vision object detection

echo.
echo Committing changes...
git commit -m "%COMMIT_MSG%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Commit failed or nothing to commit
    echo.
    pause
    exit /b 1
)

REM Display remote info
echo.
echo Remote repository:
git remote -v
echo.

REM Ask for confirmation before pushing
set /p CONFIRM="Ready to push to GitHub? (y/n): "
if /i "%CONFIRM%" NEQ "y" (
    echo.
    echo Push cancelled
    echo.
    pause
    exit /b 0
)

echo.
echo Pushing to GitHub...
git push origin master

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Successfully pushed to GitHub!
    echo ========================================
    echo.
    echo Repository: https://github.com/vende6/VS2026-.net10-playground
    echo.
) else (
    echo.
    echo Push failed!
    echo You may need to pull changes first or resolve conflicts
    echo.
    echo Try running:
    echo   git pull origin master --rebase
    echo   git push origin master
    echo.
)

pause
