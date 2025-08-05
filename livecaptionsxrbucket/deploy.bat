@echo off
echo 🚀 LiveCaptionsXR Model Distribution - Cloudflare Deployment
echo ================================================================

REM Check if PowerShell is available
powershell -Command "& {.\scripts\deploy-to-cloudflare.ps1 -DeployMethod pages}"

pause 