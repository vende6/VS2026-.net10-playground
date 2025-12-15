@echo off
echo ========================================
echo  Azure Deployment - dotnet publish
echo ========================================
echo.
echo Deploying your Blazor app to Azure...
echo.

cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\deploy-with-dotnet.ps1"

pause
