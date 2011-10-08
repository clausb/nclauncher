@echo off
REM Launch Juniper Network Connect client from the command line
REM Written by Claus Brod in 2011, see
REM http://www.clausbrod.de/Blog/DefinePrivatePublic20110820JuniperNetworkConnect

REM --------------------------------------------------------
setlocal enableextensions

call :find_juniper_client NCCLIENTDIR
if "x%NCCLIENTDIR%"=="x" (
  echo ERROR: Cannot find Network Connect client.
  goto :end
)

rem if "x%1"=="x-stop" goto :stop_client

rem TBD: Option to delete launcher config file (to reset settings)

call :load_config
if "x%NCLAUNCHER_URL%"==x goto :autodetect
ping -n 1 %NCLAUNCHER_URL% >nul
if not errorlevel 1 goto :validhost

:autodetect
rem Try to auto-detect the VPN host from the config file
set NCCLIENTCONFIG="%NCCLIENTDIR%\..\Common Files\config.ini"
if exist %NCCLIENTCONFIG% for /f "delims=[]" %%A in ('findstr [[a-z0-9]\. %NCCLIENTCONFIG% ^| findstr /V "Network Connect"') do set NCLAUNCHER_URL=%%A
ping -n 1 %NCLAUNCHER_URL% >nul
if errorlevel 1 (
  echo ERROR: Host %NCLAUNCHER_URL% does not ping. Please check your configuration.
  goto :end
)

:validhost
call :read_no_history NCLAUNCHER_URL %NCLAUNCHER_URL% "VPN host"

if "x%NCLAUNCHER_USER%"=="x" set NCLAUNCHER_USER=%USERNAME%
call :read_no_history NCLAUNCHER_USER %NCLAUNCHER_USER% "Username"

REM CONFIGURE: Set your preferred realm here. By default, the script
REM assumes two-stage authentication using a PIN and RSA SecurID.
REM TBD: Query server for default realm   

if x%NCLAUNCHER_REALM%==x set NCLAUNCHER_REALM="SecurID(Network Connect)"

call :read_no_history NCLAUNCHER_REALM %NCLAUNCHER_REALM% "Realm"

REM TODO: Hide password input
set password=""
call :read_no_history password %password% "Enter PIN + token value for user %NCLAUNCHER_USER%:" 
if x%password%==x (
  echo ERROR: No password specified
  goto :end
)

cls

echo Launching Juniper Network Connect client in
echo   %NCCLIENTDIR%...
"%NCCLIENTDIR%\nclauncher.exe" -url %NCLAUNCHER_URL% -u %NCLAUNCHER_USER% -p %password% -r %NCLAUNCHER_REALM%
rem echo ERRORLEVEL=%ERRORLEVEL%
rem pause
if not errorlevel 0 call :save_config
goto :end

:stop_client
"%NCCLIENTDIR\nclauncher.exe" -stop
goto :end

REM --------------------------------------------------------
:find_juniper_client
setlocal
set CLIENT=

rem search registry first
for /f "tokens=1* delims=	" %%A in ('reg query "HKLM\SOFTWARE\Juniper Networks" 2^>nul') do set LATESTVERSION="%%A"
if x%LATESTVERSION%==x"" goto :eof
for /f "tokens=2* delims=	 " %%A in ('reg query %LATESTVERSION% /v InstallPath 2^>nul ^| findstr InstallPath') do set CLIENT=%%B

rem if nothing found, check filesystem
if "x%CLIENT%"=="x" for /d %%A in ("%ProgramFiles(x86)%\Juniper Networks\Network Connect*") do set CLIENT=%%A
if "x%CLIENT%"=="x" for /d %%A in ("%ProgramFiles%\Juniper Networks\Network Connect*") do set CLIENT=%%A

endlocal & set "%~1=%CLIENT%"
goto :eof


REM --------------------------------------------------------
REM read_no_history promptvar default promptmessage
:read_no_history
setlocal
set msg=%~3
if not "x%~2"=="x" (
  set msg="%~3 (default: %~2): "
)
set /P RNH_TEMP=%msg% <nul
set RNH_TEMP=

REM call external script to avoid adding to our own command history
set RNH_CMDFILE=%TEMP%\temp$$$.cmd
  (
    echo @echo off
    echo set var_=%2
    echo set /p var_=
    echo echo %%var_%%
  )> "%RNH_CMDFILE%"

for /f "delims=," %%A in ('%RNH_CMDFILE%') do set RNH_TEMP=%%A
del %RNH_CMDFILE%
endlocal & if not x%RNH_TEMP%==x set "%~1=%RNH_TEMP%"
goto :eof


REM --------------------------------------------------------
REM load_config
:load_config
set NCLAUNCHERCONFIG=%USERPROFILE%\nclauncher.cfg.bat
if exist %NCLAUNCHERCONFIG% call %NCLAUNCHERCONFIG%
goto :eof

REM --------------------------------------------------------
REM save_config
:save_config
set NCLAUNCHERCONFIG=%USERPROFILE%\nclauncher.cfg.bat
echo set NCLAUNCHER_URL=%NCLAUNCHER_URL% >%NCLAUNCHERCONFIG%
echo set NCLAUNCHER_USER=%NCLAUNCHER_USER% >>%NCLAUNCHERCONFIG%
echo set NCLAUNCHER_REALM=%NCLAUNCHER_REALM% >>%NCLAUNCHERCONFIG%
echo Configuration written to %NCLAUNCHERCONFIG.
goto :eof

REM --------------------------------------------------------
REM delete_config
:delete_config
set NCLAUNCHERCONFIG=%USERPROFILE%\nclauncher.cfg.bat
if exist %NCLAUNCHERCONFIG% del /q %NCLAUNCHERCONFIG%
goto :eof

REM --------------------------------------------------------
:end
endlocal
