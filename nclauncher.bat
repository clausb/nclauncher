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

rem CONFIGURE: Set your preferred VPN host here.
set url=define-your-vpn-host-here
ping -n 1 %url% >nul
if not errorlevel 1 goto :validhost

rem Try to auto-detect the VPN host from the config file
set NCCLIENTCONFIG="%NCCLIENTDIR%\..\Common Files\config.ini"
if exist %NCCLIENTCONFIG% for /f "delims=[]" %%A in ('findstr [[a-z0-9]\. %NCCLIENTCONFIG% ^| findstr /V "Network Connect"') do set url=%%A
ping -n 1 %url% >nul
if errorlevel 1 (
  echo ERROR: Host %url% does not ping. Please check your configuration.
  goto :end
)

:validhost
call :read_no_history url %url% "VPN host"

set user=%USERNAME%
call :read_no_history user %user% "Username"

rem CONFIGURE: Set your preferred realm here. By default, the script
rem assumes two-stage authentication using a PIN and RSA SecurID.

set realm="SecurID(Network Connect)"
call :read_no_history realm %realm% "Realm"

REM TODO: Hide password input
set password=""
call :read_no_history password %password% "Enter PIN + token value for user %user%:" 
if x%password%==x (
  echo ERROR: No password specified
  goto :end
)

cls

echo Launching Juniper Network Connect client in
echo   %NCCLIENTDIR%...
"%NCCLIENTDIR%\nclauncher.exe" -url %url% -u %user% -p %password% -r %realm%
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
:end
endlocal
