REM Setup OptiScaler for your game
@echo off
cls
echo  ::::::::  :::::::::  ::::::::::: :::::::::::  ::::::::   ::::::::      :::     :::        :::::::::: :::::::::  
echo :+:    :+: :+:    :+:     :+:         :+:     :+:    :+: :+:    :+:   :+: :+:   :+:        :+:        :+:    :+: 
echo +:+    +:+ +:+    +:+     +:+         +:+     +:+        +:+         +:+   +:+  +:+        +:+        +:+    +:+ 
echo +#+    +:+ +#++:++#+      +#+         +#+     +#++:++#++ +#+        +#++:++#++: +#+        +#++:++#   +#++:++#:  
echo +#+    +#+ +#+            +#+         +#+            +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ 
echo #+#    #+# #+#            #+#         #+#     #+#    #+# #+#    #+# #+#     #+# #+#        #+#        #+#    #+# 
echo  ########  ###            ###     ###########  ########   ########  ###     ### ########## ########## ###    ### 
echo.
echo Coping is strong with this one...
echo v2.8 - now with OptiPatcher support
echo.

del "!! README_EXTRACT ALL FILES TO GAME FOLDER !!.txt" 2>nul

setlocal enabledelayedexpansion

if exist OptiScaler.sln (
    echo Detected OptiScaler.sln or .git files^^!
    echo.
    echo If .sln or .git files are in the folder, congratz, you have the source code.
	echo Now please try properly downloading OptiScaler.
	echo.
    echo Hint - use the Releases page on GitHub, or RTFM :^)
	echo.
    echo.
	echo P.S. If you somehow have both the OptiScaler.dll and .sln file, then be nice, just delete the .sln file, re-run the BAT setup and hope for the best.
	echo.
    goto end
)

if not exist OptiScaler.dll (
    echo OptiScaler "OptiScaler.dll" file is not found^^!
    echo Detected a folder permissions issue most likely. Might have more luck running the BAT as admin.
    echo.
	echo OR
	echo.
    echo If "OptiScaler.dll" exists, please manually rename to a supported filename ^(e.g. dxgi/winmm.dll^) and you are done^^!
	echo No need to run the setup BAT again after renaming.
	echo.
    echo.
    goto end
)

REM Check if old pre-0.9 additional files exist, along with an existing Opti installation
set "OLD_FILES_FOUND=0"
set "OPTI_DLL_LIST="
if exist nvapi64.dll set "OLD_FILES_FOUND=1"
if exist nvngx.dll set "OLD_FILES_FOUND=1"
if exist OptiScaler.asi set "OLD_FILES_FOUND=1"
if exist "Remove OptiScaler.bat" set "OLD_FILES_FOUND=1"
if exist "Remove_OptiScaler.bat" set "OLD_FILES_FOUND=1"

for %%F in (dxgi.dll winmm.dll d3d12.dll dbghelp.dll version.dll wininet.dll winhttp.dll) do (
    if exist "%%F" (
        set "origname="
        for /f "tokens=*" %%P in ('powershell -NoProfile -Command "(Get-Item '%%F').VersionInfo.OriginalFilename"') do (
            set "origname=%%P"
        )
        if /i "!origname!"=="OptiScaler.dll" (
            set "OLD_FILES_FOUND=1"
            set "OPTI_DLL_LIST=!OPTI_DLL_LIST! %%F"
        )
    )
)

if "!OLD_FILES_FOUND!"=="1" (
    echo WARNING: Possible old OptiScaler file^(s^) detected^^!
    if exist nvapi64.dll echo   - nvapi64.dll
    if exist nvngx.dll echo   - nvngx.dll
    if exist OptiScaler.asi echo   - OptiScaler.asi
	if exist "Remove OptiScaler.bat" echo   - Remove OptiScaler.bat
    if exist "Remove_OptiScaler.bat" echo   - Remove_OptiScaler.bat
    for %%F in (!OPTI_DLL_LIST!) do echo   - %%F ^(original filename: OptiScaler.dll^)
    echo.
    echo These files may conflict with the current version of OptiScaler.
    echo It is recommended to delete them.
    echo.
    echo Do you want to delete these files?
    echo.
	echo [1] Yes
    echo [2] No
    echo.
	set /p "USER_CHOICE=Waiting - "
	echo.
    if /i "!USER_CHOICE!"=="1" (
        if exist nvapi64.dll (
            del nvapi64.dll
            echo Deleted nvapi64.dll
        )
        if exist nvngx.dll (
            del nvngx.dll
            echo Deleted nvngx.dll
        )
        if exist OptiScaler.asi (
            del OptiScaler.asi
            echo Deleted OptiScaler.asi
        )
		if exist "Remove OptiScaler.bat" (
            del "Remove OptiScaler.bat"
            echo Deleted Remove OptiScaler.bat
        )
        if exist "Remove_OptiScaler.bat" (
            del "Remove_OptiScaler.bat"
            echo Deleted Remove_OptiScaler.bat
        )
        for %%F in (!OPTI_DLL_LIST!) do (
            del "%%F"
            echo Deleted %%F
        )
        echo Done^^!
    ) else (
        echo Skipping deletion. Note that these files may cause issues.
    )
    echo.
)

REM Set paths based on current directory

set "optiScalerFile=.\OptiScaler.dll"
set setupSuccess=false

REM Check if the Engine folder exists
if exist ".\Engine" (
    echo Found Engine folder. If this is an Unreal Engine game, then please extract Optiscaler to #CODENAME#\Binaries\Win64
	echo Do not extract to the Engine folder^^!
	echo.
	echo Example - \Jedi Survivor\SwGame\Binaries\Win64, \Witchfire\Witchfire\Binaries\Win64
    echo.
    echo Continue installation to current folder?
	echo. 
    echo [1] Yes
    echo [2] No
    echo.
	set /p continueChoice="Waiting - "
    set continueChoice=!continueChoice: =!

    if "!continueChoice!"=="1" (
        goto selectFilename
    )

    goto end
)

REM Prompt user to select a filename for OptiScaler
:selectFilename
echo.
echo Choose a filename for OptiScaler (default is dxgi.dll, most compatible):
echo (For Vulkan, use winmm.dll. For XGP/MS Store, winmm/version.dll may be better)
echo.
echo  [1] dxgi.dll
echo  [2] winmm.dll
echo  [3] version.dll
echo  [4] dbghelp.dll
echo  [5] d3d12.dll
echo  [6] wininet.dll
echo  [7] winhttp.dll
echo  [8] OptiScaler.asi
echo.
set /p filenameChoice="Enter 1-8 (or press Enter for default): "

if "%filenameChoice%"=="" (
    set selectedFilename="dxgi.dll"
) else if "%filenameChoice%"=="1" (
    set selectedFilename="dxgi.dll"
) else if "%filenameChoice%"=="2" (
    set selectedFilename="winmm.dll"
) else if "%filenameChoice%"=="3" (
    set selectedFilename="version.dll"
) else if "%filenameChoice%"=="4" (
    set selectedFilename="dbghelp.dll"
) else if "%filenameChoice%"=="5" (
    set selectedFilename="d3d12.dll"
) else if "%filenameChoice%"=="6" (
    set selectedFilename="wininet.dll"
) else if "%filenameChoice%"=="7" (
    set selectedFilename="winhttp.dll"
) else if "%filenameChoice%"=="8" (
    set selectedFilename="OptiScaler.asi"
) else (
    echo Invalid choice. Please select a valid option.
    echo.
    goto selectFilename
)

if exist %selectedFilename% (
    echo.
    echo WARNING: %selectedFilename% already exists in the current folder.
    echo.
	echo Do you want to overwrite %selectedFilename%?
	echo.
    echo [1] Yes
    echo [2] No
    echo.
	set /p overwriteChoice="Waiting - "
    set overwriteChoice=!overwriteChoice: =!
    
    echo.
    if "!overwriteChoice!"=="1" (
        goto checkWine
    )

    goto selectFilename
)

REM Wine doesn't support powershell
:checkWine
reg query HKEY_CURRENT_USER\Software\Wine\DllOverrides >nul 2>&1
if %errorlevel%==0 (
    echo.
    echo Using wine, skipping over spoofing checks.
    echo If you need, you can disable spoofing by setting Dxgi=false in the config
    echo.
    pause
    goto completeSetup
) 

if exist %windir%\system32\nvapi64.dll (
    echo.
    echo Nvidia driver files detected.
    set isNvidia=true
) else (
    set isNvidia=false
)

REM Query user for GPU type
echo.
echo Are you using an Nvidia GPU or AMD/Intel GPU?
echo.
echo [1] AMD/Intel
echo [2] Nvidia
echo.

:gpuPrompt
if "%isNvidia%"=="true" (
    set /p gpuChoice="Enter 1 or 2 (Detected Nvidia): "
) else (
    set /p gpuChoice="Enter 1 or 2 (Detected AMD/Intel): "
)

if "%gpuChoice%"=="1" goto gpuValid
if "%gpuChoice%"=="2" goto gpuValid
echo Invalid input. Please enter 1 or 2.
echo.
goto gpuPrompt

:gpuValid

REM Skip spoofing if Nvidia
if "%gpuChoice%"=="2" (
    goto completeSetup
)

REM Query user for DLSS
echo.
echo Will you try to use DLSS inputs to replace with FSR/XeSS? (enables Nvidia spoofing, required for DLSS-FG, Reflex-^>AL2)
echo If you want to change the setting later, edit OptiScaler.ini and set Dxgi=false to disable spoofing and reverse.
echo.
echo [1] Yes
echo [2] No
echo.
set /p enablingSpoofing="Enter 1 or 2 (or press Enter for Yes): "

set configFile=OptiScaler.ini
if "%enablingSpoofing%"=="2" (
    if not exist "%configFile%" (
        echo Config file not found: %configFile%
        pause
    )

    powershell -Command "(Get-Content '%configFile%') -replace 'Dxgi=auto', 'Dxgi=false' | Set-Content '%configFile%'"
)

REM OptiPatcher auto-download removed in this fork (security hardening):
REM the upstream script downloaded OptiPatcher.asi from a mutable "rolling" release
REM without any checksum or signature check and then enabled ASI (code) loading.
echo.
echo NOTE: Automatic OptiPatcher download is disabled in this fork for security reasons.
echo It is optional and not needed for FSR on AMD GPUs. If you really need it, download
echo it manually from the official OptiPatcher GitHub releases, put it into the plugins
echo folder and set LoadAsiPlugins=true in OptiScaler.ini yourself.
echo.

goto completeSetup

:completeSetup
REM Rename OptiScaler file
echo.
if "!overwriteChoice!"=="1" (
    echo Removing previous %selectedFilename%...
    del /F %selectedFilename% 
)

echo Renaming OptiScaler file to %selectedFilename%...
rename "%optiScalerFile%" %selectedFilename%
if errorlevel 1 (
    echo.
    echo ERROR: Failed to rename OptiScaler file to %selectedFilename%. Most likely due to folder permissions issues.
    echo Please rename OptiScaler.dll manually to %selectedFilename%^^! No need to run setup BAT again after that.
    echo.
    goto end
)

goto create_uninstaller

:create_uninstaller_return

cls
echo  OptiScaler setup completed successfully...
echo.
echo   ___                 
echo  (_         '        
echo  /__  /)   /  () (/  
echo          _/      /    
echo.

set setupSuccess=true

:end
pause

if "%setupSuccess%"=="true" (
    del "setup_linux.sh"
    del "%~nx0"
)

exit /b

:create_uninstaller
setlocal DisableDelayedExpansion

(
echo @echo off
echo setlocal EnableDelayedExpansion
echo cls
echo echo  ::::::::  :::::::::  ::::::::::: :::::::::::  ::::::::   ::::::::      :::     :::        :::::::::: :::::::::  
echo echo :+:    :+: :+:    :+:     :+:         :+:     :+:    :+: :+:    :+:   :+: :+:   :+:        :+:        :+:    :+: 
echo echo +:+    +:+ +:+    +:+     +:+         +:+     +:+        +:+         +:+   +:+  +:+        +:+        +:+    +:+ 
echo echo +#+    +:+ +#++:++#+      +#+         +#+     +#++:++#++ +#+        +#++:++#++: +#+        +#++:++#   +#++:++#:  
echo echo +#+    +#+ +#+            +#+         +#+            +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ 
echo echo #+#    #+# #+#            #+#         #+#     #+#    #+# #+#    #+# #+#     #+# #+#        #+#        #+#    #+# 
echo echo  ########  ###            ###     ###########  ########   ########  ###     ### ########## ########## ###    ### 
echo echo.
echo echo Coping is strong with this one...
echo echo v2.8 - now with OptiPatcher support
echo echo.
echo REM Check if OptiScaler installation exists
echo set "OLD_FILES_FOUND=0"
echo set "OPTI_DLL_LIST="
echo if exist OptiScaler.asi set "OLD_FILES_FOUND=1"

echo for %%%%F in ^(dxgi.dll winmm.dll d3d12.dll dbghelp.dll version.dll wininet.dll winhttp.dll^) do ^(
echo     if exist "%%%%F" ^(
echo         set "origname="
echo         for /f "tokens=*" %%%%P in ^('powershell -NoProfile -Command "(Get-Item '%%%%F').VersionInfo.OriginalFilename"'^) do ^(
echo             set "origname=%%%%P"
echo         ^)
echo         if /i "!origname!"=="OptiScaler.dll" ^(
echo             set "OLD_FILES_FOUND=1"
echo             set "OPTI_DLL_LIST=!OPTI_DLL_LIST! %%%%F"
echo         ^)
echo     ^)
echo ^)

echo if "!OLD_FILES_FOUND!"=="1" ^(
echo     echo Existing OptiScaler installation detected^^^^!
echo     if exist OptiScaler.asi echo   - OptiScaler.asi
echo     for %%%%F in ^(!OPTI_DLL_LIST!^) do echo   - %%%%F - original filename: OptiScaler.dll
echo     echo.
echo ^)

echo echo Do you want to remove OptiScaler?
echo echo.
echo echo [1] Yes
echo echo [2] No
echo echo.
echo set /p removeChoice="Waiting - "
echo echo.

echo if "%%removeChoice%%"=="1" ^(
echo     del OptiScaler.log
echo     del OptiScaler.ini
echo     del OptiScaler.asi
echo     del fakenvapi.dll
echo     del fakenvapi.ini
echo     del fakenvapi.log
echo     del dlssg_to_fsr3_amd_is_better.dll
echo     del dlssg_to_fsr3.log
echo     del /Q D3D12_Optiscaler\*
echo     rd D3D12_Optiscaler
echo     del /Q DlssOverrides\*
echo     rd DlssOverrides
echo     del /Q Licenses\*
echo     rd Licenses
echo     for %%%%F in ^(!OPTI_DLL_LIST!^) do ^(del "%%%%F"^)
echo     echo.
echo     echo Deleting OptiPatcher if present
echo     del plugins\OptiPatcher.asi
echo     rd plugins
echo     echo.
echo     echo OptiScaler removed^^^^! Ignore the warnings about missing files.
echo     echo.
echo ^) else ^(
echo     echo.
echo     echo Operation cancelled.
echo     echo.
echo ^)

echo.
echo pause
echo if "%%removeChoice%%"=="1" ^(
echo     del "%%~nx0"
echo ^)
) > "Remove_OptiScaler.bat"

endlocal
echo.
echo Uninstaller created.
echo.

goto create_uninstaller_return
