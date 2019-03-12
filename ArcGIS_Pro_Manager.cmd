:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Author:		David Geeraerts
:: Location:	Olympia, Washington USA
:: E-Mail:		geeraerd@evergreen.edu
::
::
:: Copyleft License(s)
:: GNU GPL (General Public License)
:: https://www.gnu.org/licenses/gpl-3.0.en.html
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::#############################################################################
::							#DESCRIPTION#
::	SCRIPT STYLE: Intelligent Wrapper
::	The purpose of this script/commandlet is to intelligently manage
::		ESRI ArcGIS Pro. Will always UPGRADE an existing version and
::		apply any update packages.
::	Minimally developed for console output. Primarily developed for log output.
::
:: VERSIONING INFORMATION
::  Semantic Versioning used
::   http://semver.org/
::	Major.Minor.Revision
::	Added BUILD number which is used during development and testing.
::#############################################################################

:::::::::::::::::::::::::::
@Echo Off
setlocal enableextensions
:::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET SCRIPT_NAME=ArcGIS_Pro_Manager
SET SCRIPT_VERSION=1.2.0
SET SCRIPT_BUILD=0013
Title %SCRIPT_NAME% Version: %SCRIPT_VERSION%
Prompt AGM$G
color 0B
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Declare Global variables
::	All User variables are set within here.
::		(configure variables)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::	PACKAGE_SOURCE is where the unpacked folder for ArcGIS is located
::	consider this the repository location, where the staging folder is located.
::	Inside the folder should contain the ArcGISPro.msi
SET "PACKAGE_SOURCE=\\Orca\research\Software\ESRI\ArcGIS_Pro"
SET "PACKAGE_DESTINATION=%PUBLIC%\Downloads"

:: Log settings
::	Advise local storage for logging.
SET LOG_LOCATION=%PUBLIC%\Logs
::	Advise the default log file name.
SET LOG_FILE=%COMPUTERNAME%_ArcGIS_Pro_Manager.log
:: Log Shipping
::	Advise network file share location
SET "LOG_SHIPPING_LOCATION=\\SC-Vanadium\Logs\ArcGISPro"

:: Cleanup staging and var 
::	OFF 0
::	ON 1
SET CLEANUP=1


::###########################################################################::
::		*******************
::		Advanced Settings 
::		*******************
::###########################################################################::

:: ArcGIS Silent Install Parameters
::	{DEFAULT: %System Drive%\Program Files\ArcGIS\Pro for a per-machine installation}
::	{DEFAULT: %System Drive%\%USERPROFILE%\AppData\Local\Programs\ArcGIS\Pro for a current user instance}
SET "$INSTALLDIR=%SystemDrive%\Program Files\ArcGIS\Pro"

::	PER MACHINE 1
::	PER USER 2
::	{0,1}
SET $ALLUSERS=1

::	ESRI User Experience improvement program
::	{0,1}
SET $ENABLEEUEI=0

::	If specified, the BlockAddins registry value allows system administrators
::	to configure the types of add-ins that ArcGIS Pro will load. It is created
::	under HKEY_LOCAL_MACHINE\SOFTWARE\Esri\ArcGISPro\Settings.
::	This property is only read during a per-machine installation; it is ignored
::	if specified for a per-user setup.
::	Setting BLOCKADDINS=0 will load all add-ins, regardless of whether they
::	have digital signatures; 1 will only load add-ins that are digitally
::	assigned by a trusted certificate authority; 2 will only load add-ins that
::	have been published by Esri; 3 will only load add-ins from the
::	administrator folders and those published by Esri; 4 will not load or
::	execute add-ins; and 5 will only load add-ins from the administrator
::	folders. Level 0 is the default.
::	{0,1,2,3,4,5}
SET $BLOCKADDINS=0

::	DEFAULT 1
::	{0,1}
SET $CHECKFORUPDATESATSTARTUP=0

::	Specifies the host name of the license manager. Multiple license servers
::	can be defined by separating the host names with a semicolon; for example,
::	ESRI_LICENSE_HOST=@primaryLM;@backupLM2;@backupLM3
SET $ESRI_LICENSE_HOST=

::	Can be Viewer, Editor, or Professional.
SET $SOFTWARE_CLASS=Professional

::	Use SINGLE_USE to install ArcGIS Pro as a Single Use seat;
::	CONCURRENT_USE to install as a Concurrent Use seat;
::	and NAMED_USER for a Named User license.
::	{SINGLE_USE, Concurrent_USE, NAMED_USER}
SET $AUTHORIZATION_TYPE=NAMED_USER

::	During a silent, per-machine installation of ArcGIS Pro, if the
::	authorization type is defined, this is set to True under
::	HKEY_LOCAL_MACHINE\SOFTWARE\Esri\ArcGISPro\Licensing.
::	When LOCK_AUTH_SETTINGS is True, the licensing settings in the registry
::	apply to all ArcGIS Pro users on that machine; an individual user cannot
::	make changes. To allow ArcGIS Pro users on the machine to define their own
::	authorization settings through the ArcGIS Pro application,
::	set LOCK_AUTH_SETTINGS to False.
::	This property does not apply to a per-user installation.
::	{True, False}
SET $LOCK_AUTH_SETTINGS=False

::	Specifies whether a connection to www.arcgis.com should be available from
::	the Portals page. To include the connection, set this property to TRUE.
::	If set to FALSE, the connection will not appear on the Portals page.
::	{True, False}
SET $ArcGIS_Connection=True

::	 To add one or more portal connections to the Portals page,
::	set Portal_List = <portalURL1>; <portalURL2>.
::	Use semicolons to separate portal URLs.
::	If ArcGIS_Connection is set to False, this property cannot contain arcgis.com.
::	If your portal supports HTTPS, it is strongly recommended that the
::	Portal_List URLs use HTTPS.
SET "$Portal_List=https://geoduck.maps.arcgis.com"

::	License_URL
::	To specify the URL of the Named User licensing portal,
::	set License_URL = <portalURL>.
::	If ArcGIS_Connection is set to False, License_URL cannot contain arcgis.com.
::	To use this property, AUTHORIZATION_TYPE must be set to NAMED_USER.
SET "$License_URL=https://geoduck.maps.arcgis.com"

::###########################################################################::


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::##### Everything below here is 'hard-coded' [DO NOT MODIFY] #####
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:SLT
::	Start Lapse Time
:: Calculate lapse time by capturing start time
::	Parsing %TIME% variable to get an interger number
FOR /F "tokens=1 delims=:." %%h IN ("%TIME%") DO SET S_hh=%%h
FOR /F "tokens=2 delims=:." %%h IN ("%TIME%") DO SET S_mm=%%h
FOR /F "tokens=3 delims=:." %%h IN ("%TIME%") DO SET S_ss=%%h
FOR /F "tokens=4 delims=:." %%h IN ("%TIME%") DO SET S_ms=%%h
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: CONSOLE OUTPUT WHEN RUNNING Manually
ECHO ********************************************
ECHO. 
ECHO %SCRIPT_NAME% %SCRIPT_VERSION% %SCRIPT_BUILD%
ECHO.
ECHO ********************************************
ECHO.
ECHO.
ECHO Processing...
ECHO.
ECHO.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: Check Log access
IF NOT EXIST %LOG_LOCATION% MD %LOG_LOCATION% || SET LOG_LOCATION=%TEMP%\Logs
ECHO TEST %DATE% %TIME% > %LOG_LOCATION%\test_%LOG_FILE% || SET LOG_LOCATION=%TEMP%\Logs
IF EXIST %LOG_LOCATION%\test_%LOG_FILE% DEL /Q %LOG_LOCATION%\test_%LOG_FILE%
IF NOT EXIST "%LOG_LOCATION%\var" MD "%LOG_LOCATION%\var" || IF NOT EXIST "%TEMP%\Logs" MD "%TEMP%\Logs\var"


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:fISO8601
:: Function to ensure ISO 8601 Date format yyyy-mmm-dd
ECHO Checking on Powershell...
IF DEFINED PSModulePath @powershell $PSVersionTable.PSVersion || GoTo skipPS
IF DEFINED PSModulePath @powershell $PSVersionTable.PSVersion > %LOG_LOCATION%\var\var_PS_Version.txt
FOR /F "usebackq skip=3 tokens=1 delims= " %%P IN ("%LOG_LOCATION%\var\var_PS_Version.txt") DO SET "PS_MAJOR_VERSION=%%P"
FOR /F "usebackq skip=3 tokens=2 delims= " %%P IN ("%LOG_LOCATION%\var\var_PS_Version.txt") DO SET "PS_MINOR_VERSION=%%P"
FOR /F "usebackq skip=3 tokens=3 delims= " %%P IN ("%LOG_LOCATION%\var\var_PS_Version.txt") DO SET "PS_BUILD_VERSION=%%P"
FOR /F "usebackq skip=3 tokens=4 delims= " %%P IN ("%LOG_LOCATION%\var\var_PS_Version.txt") DO SET "PS_REVISION_VERSION=%%P"
:: Easiest way to get ISO date
@powershell Get-Date -format "yyyy-MM-dd" > %LOG_LOCATION%\var\var_ISO8601_Date.txt
SET /P ISO_DATE= < %LOG_LOCATION%\var\var_ISO8601_Date.txt

:skipPS

:fmanualISO
:: Manually create the ISO 8601 date format
IF DEFINED ISO_DATE GoTo skipfmiso
FOR /F "tokens=2 delims=/ " %%T IN ("%DATE%") DO SET ISO_MONTH=%%T
FOR /F "tokens=3 delims=/ " %%T IN ("%DATE%") DO SET ISO_DAY=%%T
FOR /F "tokens=4 delims=/ " %%T IN ("%DATE%") DO SET ISO_YEAR=%%T
SET ISO_DATE=%ISO_YEAR%-%ISO_MONTH%-%ISO_DAY%

:skipfmiso
::*****************************************************************************



:start
IF EXIST "%LOG_LOCATION%\%LOG_FILE%" ECHO. >> %LOG_LOCATION%\%LOG_FILE%
ECHO %ISO_DATE% %TIME% [INFO]	START... >> %LOG_LOCATION%\%LOG_FILE%
IF NOT EXIST %LOG_LOCATION%\var\var_systeminfo_TimeZone.txt (
	FOR /F "tokens=2-3 delims=(" %%S IN ('systeminfo ^| FIND /I "Time Zone"') Do ECHO Time Zone: ^(%%S^(%%T > %LOG_LOCATION%\var\var_systeminfo_TimeZone.txt
	) && IF EXIST "%LOG_LOCATION%\var\var_systeminfo_TimeZone.txt" ECHO %ISO_DATE% %TIME% [DEBUG]	File [var_systeminfo_TimeZone.txt] created! >> %LOG_LOCATION%\%LOG_FILE%
SET /P var_TimeZone= < %LOG_LOCATION%\var\var_systeminfo_TimeZone.txt
ECHO %ISO_DATE% %TIME% [INFO]	"%var_TimeZone%" >> %LOG_LOCATION%\%LOG_FILE%
ECHO %ISO_DATE% %TIME% [INFO]	SCRIPT: %SCRIPT_NAME% %SCRIPT_VERSION% >> %LOG_LOCATION%\%LOG_FILE%
ECHO %ISO_DATE% %TIME% [INFO]	SCRIPT BUILD: %SCRIPT_BUILD% >> %LOG_LOCATION%\%LOG_FILE%
ECHO %ISO_DATE% %TIME% [INFO]	Computer: %COMPUTERNAME% >> %LOG_LOCATION%\%LOG_FILE%
ECHO %ISO_DATE% %TIME% [INFO]	User: %USERNAME% >> %LOG_LOCATION%\%LOG_FILE%


:: Check if running with Administrative Privilege
openfiles.exe > %LOG_LOCATION%\var\var_openfiles.txt 2>nul
SET ADMIN_STATUS=%ERRORLEVEL%
ECHO %ISO_DATE% %TIME% [DEBUG]	VARIABLE: ADMIN_STATUS: {%ADMIN_STATUS%} >> %LOG_LOCATION%\%LOG_FILE%
IF %ADMIN_STATUS% EQU 0 ECHO %ISO_DATE% %TIME% [DEBUG]	Running with administrative privilege. >> %LOG_LOCATION%\%LOG_FILE%
IF %ADMIN_STATUS% EQU 1 ECHO %ISO_DATE% %TIME% [FATAL]	Not running with administrative privilege! >> %LOG_LOCATION%\%LOG_FILE%

:: Get the currently installed version of ArcGIS Pro
(FOR /F "tokens=3 delims= " %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro /V REALVERSION') DO ECHO %%P > %LOG_LOCATION%\var\var_ArcGISPro_version.txt) 2> nul
IF EXIST "%LOG_LOCATION%\var\var_ArcGISPro_Version.txt" SET /P ARCGISPRO_VERSION= < "%LOG_LOCATION%\var\var_ArcGISPro_Version.txt"
IF DEFINED ARCGISPRO_VERSION ECHO %ISO_DATE% %TIME% [INFO]	Currently installed ARCGISPRO Version: %ARCGISPRO_VERSION% >> %LOG_LOCATION%\%LOG_FILE%
IF NOT DEFINED ARCGISPRO_VERSION ECHO %ISO_DATE% %TIME% [INFO]	ArcGIS Pro not installed! First time installation! >> %LOG_LOCATION%\%LOG_FILE%
IF NOT DEFINED ARCGISPRO_VERSION SET ARCGISPRO_VERSION=0

:: Get the currently installed updates of ArcGIS Pro
(FOR /F "tokens=6 delims=\" %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Updates') DO ECHO %%P > %LOG_LOCATION%\var\var_ArcGISPro_Update.txt) 2> nul
IF EXIST "%LOG_LOCATION%\var\var_ArcGISPro_Update.txt" SET /P ARCGISPRO_UPDATE= < "%LOG_LOCATION%\var\var_ArcGISPro_Update.txt"
IF DEFINED ARCGISPRO_UPDATE ECHO %ISO_DATE% %TIME% [INFO]	Currently installed ARCGISPRO Patch: %ARCGISPRO_UPDATE% >> %LOG_LOCATION%\%LOG_FILE%
IF NOT DEFINED ARCGISPRO_UPDATE ECHO %ISO_DATE% %TIME% [INFO]	ArcGIS Pro patches not installed! >> %LOG_LOCATION%\%LOG_FILE%
IF NOT DEFINED ARCGISPRO_UPDATE SET ARCGISPRO_UPDATE=0


:: GET the latest ArcGIS installation package
dir /B /A:D /O:-N "%PACKAGE_SOURCE%" > %LOG_LOCATION%\var\var_ArcGISPro_FOLDER.txt
SET /P ARCGISPRO_FOLDER= < %LOG_LOCATION%\var\var_ArcGISPro_FOLDER.txt
ECHO %ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_FOLDER: %ARCGISPRO_FOLDER% >> %LOG_LOCATION%\%LOG_FILE%

:: Check if installer should run
ECHO %ISO_DATE% %TIME% [INFO]	Checking if the ArcGIS Pro installer should run... >> %LOG_LOCATION%\%LOG_FILE%
IF ARCGISPRO_VERSION EQU 0 GoTo skipAPcheck
FOR /F "tokens=2 delims=_" %%P IN ("%ARCGISPRO_FOLDER%") DO SET ARCGISPRO_FOLDER_NUMBER=%%P
ECHO %ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_FOLDER_NUMBER: %ARCGISPRO_FOLDER_NUMBER% >> %LOG_LOCATION%\%LOG_FILE%
IF %ARCGISPRO_FOLDER_NUMBER% EQU %ARCGISPRO_VERSION% ECHO %ISO_DATE% %TIME% [INFO]	ArcGIS Pro already installed to version %ARCGISPRO_FOLDER_NUMBER% >> %LOG_LOCATION%\%LOG_FILE%
IF %ARCGISPRO_FOLDER_NUMBER% EQU %ARCGISPRO_VERSION% GoTo skipAP
:skipAPcheck


:: Copy the installers locally
ROBOCOPY "%PACKAGE_SOURCE%\%ARCGISPRO_FOLDER%" "%PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%" /S /E /NP /R:2 /W:5 /LOG+:"%LOG_LOCATION%\%LOG_FILE%"

:: Execute the installer
ECHO %ISO_DATE% %TIME% [INFO]	Installing ArcGIS Pro latest version... >> %LOG_LOCATION%\%LOG_FILE%
IF DEFINED ARCGISPRO_FOLDER msiexec /i "%PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%\ArcGISPro.msi" INSTALLDIR="%$INSTALLDIR%" ALLUSERS=%$ALLUSERS% ENABLEEUEI=%$ENABLEEUEI% BLOCKADDINS=%$BLOCKADDINS% CHECKFORUPDATESATSTARTUP=%$CHECKFORUPDATESATSTARTUP% ESRI_LICENSE_HOST=%$ESRI_LICENSE_HOST% SOFTWARE_CLASS=%$SOFTWARE_CLASS% AUTHORIZATION_TYPE=%$AUTHORIZATION_TYPE% LOCK_AUTH_SETTINGS=%$LOCK_AUTH_SETTINGS% ArcGIS_Connection=%$ArcGIS_Connection% Portal_List="%$Portal_List%" License_URL="%$License_URL%" /qb
SET ARCGIS_INSTALL_ERROR=%ERRORLEVEL%
ECHO %ISO_DATE% %TIME% [DEBUG]	ARCGIS_INSTALL_ERROR: %ARCGIS_INSTALL_ERROR% >> %LOG_LOCATION%\%LOG_FILE%
:skipAP

:: Execute the update package
ECHO %ISO_DATE% %TIME% [INFO]	Checking if patch installer should run... >> %LOG_LOCATION%\%LOG_FILE%
:: Find and define the update package
dir /B /A:-D "%PACKAGE_SOURCE%" | FIND /I "msp" > %LOG_LOCATION%\var\var_ArcGISPro_updatePackage.txt
SET /P ARCGISPRO_UPDATE_PACKAGE= < %LOG_LOCATION%\var\var_ArcGISPro_updatePackage.txt
IF DEFINED ARCGISPRO_UPDATE_PACKAGE ECHO %ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_UPDATE_PACKAGE: %ARCGISPRO_UPDATE_PACKAGE% >> %LOG_LOCATION%\%LOG_FILE%
REM See if the MSI log file already exists, and if it does change it to UTF-8 encoding so FINDSTR can work.
IF EXIST "%LOG_LOCATION%\%ARCGISPRO_UPDATE_PACKAGE%.log" (@powershell Get-Content -Path "%LOG_LOCATION%\%ARCGISPRO_UPDATE_PACKAGE%.log" | @powershell Set-Content -Path "%LOG_LOCATION%\%ARCGISPRO_UPDATE_PACKAGE%.log" -Encoding UTF8)
IF EXIST "%LOG_LOCATION%\%ARCGISPRO_UPDATE_PACKAGE%.log" FINDSTR /I /C:"Configuration completed successfully." "%LOG_LOCATION%\%ARCGISPRO_UPDATE_PACKAGE%.log" && GoTo skipAPP
:: Check registry on updates and compare to package update.
(FOR /F "tokens=3-5 delims=()." %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Updates /S /v "NAME"') DO ECHO %%P%%Q%%R >> %LOG_LOCATION%\var\VAR_ArcGISPro_Updated_REGKEY_Result.txt) 2> nul
IF EXIST "%LOG_LOCATION%\var\var_ArcGISPro_Updated_REGKEY_Result.txt" SET /P $STRING= < %LOG_LOCATION%\var\var_ArcGISPro_Updated_REGKEY_Result.txt
ECHO %ISO_DATE% %TIME% [DEBUG]	VARIABLE: VAR_ARCGISPRO_UPDATED_REGKEY_RESULT: %$STRING% >> %LOG_LOCATION%\%LOG_FILE%
:: This line is not working. Something is up with the 2nd pipe with FIND
(DIR /B /A:-D "%PACKAGE_SOURCE%" | FIND /I "msp" | FIND /I "%$STRING%") && GoTo skipAPP

ECHO %ISO_DATE% %TIME% [INFO]	Installing ArcGIS Pro [%ARCGISPRO_UPDATE_PACKAGE%] patches... >> %LOG_LOCATION%\%LOG_FILE%
IF DEFINED ARCGISPRO_UPDATE_PACKAGE msiexec /L "%LOG_LOCATION%\%ARCGISPRO_UPDATE_PACKAGE%.log" /P "%PACKAGE_SOURCE%\%ARCGISPRO_UPDATE_PACKAGE%" /qb
SET ARCGIS_UPDATE_ERROR=%ERRORLEVEL%
ECHO %ISO_DATE% %TIME% [DEBUG]	ARCGIS_UPDATE_ERROR: %ARCGIS_UPDATE_ERROR% >> %LOG_LOCATION%\%LOG_FILE%
:skipAPP

:: Get the currently installed version of ArcGIS Pro
FOR /F "tokens=3 delims= " %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro /V REALVERSION') DO ECHO %%P > %LOG_LOCATION%\var\var_ArcGISPro_version.txt
SET /P ARCGISPRO_VERSION= < "%LOG_LOCATION%\var\var_ArcGISPro_Version.txt"
ECHO %ISO_DATE% %TIME% [INFO]	Installed ARCGISPRO Version: %ARCGISPRO_VERSION% >> %LOG_LOCATION%\%LOG_FILE%


:: Get the updated version of ArcGIS Pro
FOR /F "tokens=6 delims=\" %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Updates') DO ECHO %%P > %LOG_LOCATION%\var\var_ArcGISPro_Patch.txt
SET /P ARCGISPRO_PATCH= < "%LOG_LOCATION%\var\var_ArcGISPro_Patch.txt"
ECHO %ISO_DATE% %TIME% [INFO]	ARCGISPRO Patch: %ARCGISPRO_PATCH% >> %LOG_LOCATION%\%LOG_FILE%


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Clean
IF %CLEANUP% EQU 0 GoTo skipClean
IF EXIST "%LOG_LOCATION%\var" RD /S /Q "%LOG_LOCATION%\var"
IF NOT EXIST "%LOG_LOCATION%\var" ECHO %ISO_DATE% %TIME% [DEBUG]	var folder deleted! >> %LOG_LOCATION%\%LOG_FILE%
IF EXIST "%PACKAGE_DESTINATION%" RD /S /Q "%PACKAGE_DESTINATION%"
IF NOT EXIST "%PACKAGE_DESTINATION%"  ECHO %ISO_DATE% %TIME% [DEBUG]	ArcGIS Pro staging area deleted! >> %LOG_LOCATION%\%LOG_FILE%
:skipClean
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ELT
::	End Lapse Time
::	Calculate lapse time by capturing end time
::	Parsing %TIME% variable to get an interger number
FOR /F "tokens=1 delims=:." %%h IN ("%TIME%") DO SET E_hh=%%h
FOR /F "tokens=2 delims=:." %%h IN ("%TIME%") DO SET E_mm=%%h
FOR /F "tokens=3 delims=:." %%h IN ("%TIME%") DO SET E_ss=%%h
FOR /F "tokens=4 delims=:." %%h IN ("%TIME%") DO SET E_ms=%%h
:: DEBUG (FUTURE)
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	E_hh: %E_hh% >> %LOG_LOCATION%\%LOG_FILE%
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	E_mm: %E_mm% >> %LOG_LOCATION%\%LOG_FILE%
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	E_ss: %E_ss% >> %LOG_LOCATION%\%LOG_FILE%
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	E_ms: %E_ms% >> %LOG_LOCATION%\%LOG_FILE%

:: Calculate the actual lapse time
IF %E_hh% GEQ %S_hh% (SET /A "L_hh=%E_hh%-%S_hh%") ELSE (SET /A "L_hh=%S_hh%-%E_hh%")
IF %E_mm% GEQ %S_mm% (SET /A "L_mm=%E_mm%-%S_mm%") ELSE (SET /A "L_mm=%S_mm%-%E_mm%")
IF %E_ss% GEQ %S_ss% (SET /A "L_ss=%E_ss%-%S_ss%") ELSE (SET /A "L_ss=%S_ss%-%E_ss%")
IF %E_ms% GEQ %S_ms% (SET /A "L_ms=%E_ms%-%S_ms%") ELSE (SET /A "L_ms=%S_ms%-%E_ms%")
:: DEBUG (FUTURE)
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	L_hh: %L_hh% >> %LOG_LOCATION%\%LOG_FILE%
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	L_mm: %L_mm% >> %LOG_LOCATION%\%LOG_FILE%
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	L_ss: %L_ss% >> %LOG_LOCATION%\%LOG_FILE%
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	L_ms: %L_ms% >> %LOG_LOCATION%\%LOG_FILE%

:: turn hours into minutes and add to total minutes
IF %L_hh% GTR 0 SET /A "L_hhh=%L_hh%*60"
IF %L_hh% EQU 0 SET L_hhh=0
IF %L_hhh% GTR 0 SET /A "L_tm=%L_hhh%+%L_mm%"
IF %L_hhh% EQU 0 SET L_tm=%L_mm%
:: DEBUG (FUTURE)
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	L_hhh: %L_hhh%
:: IF %LOG_LEVEL_DEBUG% EQU 1 ECHO %ISO_DATE% %TIME% [DEBUG]	L_tm: %L_tm%

ECHO %ISO_DATE% %TIME% [INFO]	Time Lapsed (mm:ss.ms): %L_tm%:%L_ss%.%L_ms% >> %LOG_LOCATION%\%LOG_FILE%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:EOF
ECHO %ISO_DATE% %TIME% [INFO]	END! >> %LOG_LOCATION%\%LOG_FILE%
ECHO. >> %LOG_LOCATION%\%LOG_FILE%
:: Ship the log file
IF NOT EXIST "%LOG_SHIPPING_LOCATION%" MD "%LOG_SHIPPING_LOCATION%"
IF EXIST %LOG_LOCATION%\%LOG_FILE% ROBOCOPY "%LOG_LOCATION%" "%LOG_SHIPPING_LOCATION%" %LOG_FILE% /R:5 /W:30
ENDLOCAL
EXIT /B