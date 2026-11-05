@echo off
rem Installs or updates the Stjartgruppen addon for WoW: Forever.
rem It runs install.ps1 (next to this file), which only copies the addon into your game folder.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
