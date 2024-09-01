@echo off
:: This batch file runs the PowerShell script nxr.ps1 with the provided arguments.

:: Check if an argument was provided
if "%~1"=="" (
    echo Usage: nxr.cmd "C:\path\to\file\or\directory"
    exit /b 1
)

:: Define the relative path to the PowerShell script (assuming it's in the same directory)
set PS_SCRIPT_PATH="%~dp0nxr.ps1"

:: Run the PowerShell script with the provided arguments
powershell -ExecutionPolicy Bypass -File %PS_SCRIPT_PATH% "%~1"
