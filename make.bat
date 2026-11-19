@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not "%~2"=="" goto badArgs
if "%~1"=="" goto menu
if /i "%~1"=="x64" goto x64
if /i "%~1"=="x86" goto x86
if /i "%~1"=="ansi" goto ansi
if "%~1"=="/?" goto help
:badArgs
call :help
exit /b 2

:menu
echo 1. Unicode 32-bit
echo 2. Unicode 64-bit
echo 3. ANSI 32-bit
choice /c 123C /n /m "Select 1, 2, 3, or C to cancel: "
if errorlevel 4 exit /b 0
if errorlevel 3 goto ansi
if errorlevel 2 goto x64
if errorlevel 1 goto x86
exit /b 0

:x64
set "base=Unicode 64-bit.bin"
goto build
:x86
set "base=Unicode 32-bit.bin"
goto build
:ansi
set "base=ANSI 32-bit.bin"

:build
if not defined AHK_DIR call :registry HKCU 64
if not defined AHK_DIR call :registry HKCU 32
if not defined AHK_DIR call :registry HKLM 64
if not defined AHK_DIR call :registry HKLM 32
if not defined AHK_DIR if exist "%ProgramFiles%\AutoHotkey\Compiler\Ahk2Exe.exe" set "AHK_DIR=%ProgramFiles%\AutoHotkey"
if not defined AHK_DIR if exist "%ProgramFiles(x86)%\AutoHotkey\Compiler\Ahk2Exe.exe" set "AHK_DIR=%ProgramFiles(x86)%\AutoHotkey"
if not defined AHK_DIR goto missingCompiler
set "compiler=%AHK_DIR%\Compiler\Ahk2Exe.exe"
set "runtime=%AHK_DIR%\Compiler\%base%"
if not exist "%compiler%" goto missingCompiler
if not exist "%runtime%" goto missingCompiler

rem Compile beside the destination so a failed build leaves the previous executable usable.
set "stage=%~dp0.steamrelief-build-%RANDOM%-%RANDOM%"
mkdir "%stage%" || exit /b 1
"%compiler%" /in "%~dp0SteamRelief.ahk" /out "%stage%\SteamRelief.exe" /icon "%~dp0icon.ico" /base "%runtime%" /silent verbose
set "status=%errorlevel%"
if not "%status%"=="0" goto cleanup
move /y "%stage%\SteamRelief.exe" "%~dp0SteamRelief.exe" >nul
set "status=%errorlevel%"
if "%status%"=="0" echo Built "%~dp0SteamRelief.exe" using %base%.

:cleanup
if exist "%stage%\SteamRelief.exe" del /q "%stage%\SteamRelief.exe"
rmdir "%stage%"
exit /b %status%

:registry
for /f "tokens=2,*" %%A in ('reg query "%~1\SOFTWARE\AutoHotkey" /v InstallDir /reg:%~2 2^>nul') do if exist "%%B\Compiler\Ahk2Exe.exe" if exist "%%B\Compiler\%base%" set "AHK_DIR=%%B"
exit /b 0

:missingCompiler
echo AutoHotkey v1 compiler or "%base%" missing. Set AHK_DIR to the v1 installation or extracted ZIP directory. 1>&2
exit /b 1

:help
echo Usage: make.bat [x64^|x86^|ansi]
echo With no argument, choose the architecture from the menu.
echo For a portable AutoHotkey v1 toolchain, set AHK_DIR to its root folder.
echo The output is SteamRelief.exe next to make.bat.
exit /b 0
