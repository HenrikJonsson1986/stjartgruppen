@echo off
rem Installs or updates the Stjartgruppen addon for WoW: Forever.
rem It runs files\install.ps1, which only copies the addon into your game folder.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0files\install.ps1" %*
