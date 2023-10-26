@echo off
cd /d "%~dp0"

SET PATH=C:\path\to\FlightGearBuild\install\bin;C:\path\to\FlightGearBuild\windows-3rd-party\msvc140\3rdParty.x64\bin;C:\Qt\5.15.0\msvc2019_64\bin;%PATH%
fgfs.exe --launcher