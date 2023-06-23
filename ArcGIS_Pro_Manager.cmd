:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Author:		David Geeraerts
:: Location:	Olympia, Washington USA
:: E-Mail:		geeraerd@evergreen.edu
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Copyleft License(s)
:: GNU GPL (General Public License)
:: https://www.gnu.org/licenses/gpl-3.0.en.html
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::
@Echo Off
setlocal enableextensions
:::::::::::::::::::::::::::

::#############################################################################
::							#DESCRIPTION#
::	SCRIPT STYLE: Intelligent Wrapper
::	The purpose of this script/commandlet is to intelligently manage
::		ESRI ArcGIS Pro. Will always UPGRADE an existing version and
::		apply any update packages, based on a network file share repository.
::
::	Minimally developed for console output. Primarily developed for log output.
::#############################################################################

::::::::::::::::::::::::::::::::::
:: VERSIONING INFORMATION		::
::  Semantic Versioning used	::
::   http://semver.org/			::
::::::::::::::::::::::::::::::::::
::	Major.Minor.Revision
::	Added BUILD number which is used during development and testing.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SET $SCRIPT_NAME=ArcGIS_Pro_Manager
SET $SCRIPT_VERSION=1.8.4
SET $SCRIPT_BUILD=20230623 0830
Title %$SCRIPT_NAME% %$SCRIPT_VERSION%
Prompt AGPM$G
color 0B
mode con:cols=80
mode con:lines=45
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Declare Global variables
::	All User variables are set within here.
::		(configure variables)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::	PACKAGE_SOURCE is where the unpacked folder for ArcGIS is located
::	consider this the repository location, where the staging folder is located.
::	Inside the folder should contain the ArcGISPro.msi
::	NETWORK REPOSITORY
SET "$PACKAGE_SOURCE=\\Orca\research\Software\ESRI\ArcGIS_Pro"
SET "$PACKAGE_DESTINATION=%PUBLIC%\Downloads"

::	Microsoft .net sdk dependency package repository
SET "$NET_SDK_PACKAGE=\\Orca\research\Software\Microsoft\NET


:: Log settings
::	Advise local storage for logging.
SET "$LOG_LOCATION=%PUBLIC%\Logs"
::	Advise the default log file name.
SET $LLOG_FILE=ArcGIS_Pro_Manager_%COMPUTERNAME%.log
:: Log Shipping
::	Advise network file share location
::	if no log server, leave blank
SET "$LOG_SHIPPING_LOCATION=\\SC-Vanadium\Logs\ArcGISPro"

:: CLEANUP staging and var 
::	OFF 0
::	ON 1
SET $CLEANUP=1

:: LOGGING LEVEL CONTROL
::  by default, ALL=0 & TRACE=0
SET $LOG_LEVEL_ALL=0
SET $LOG_LEVEL_INFO=1
SET $LOG_LEVEL_WARN=1
SET $LOG_LEVEL_ERROR=1
SET $LOG_LEVEL_FATAL=1
SET $LOG_LEVEL_DEBUG=0
SET $LOG_LEVEL_TRACE=0

:: DEBUG Mode
:: Turn on debugging regardless of host
:: 0 = OFF (NO)
:: 1 = ON (YES)
SET $DEBUG_MODE=0

:: Configure a Debugger to auto set all logging
SET $DEBUGGER_PC=SC-Cavia


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

::	ACCEPTEULA
::	This property is required to accept the End User License Agreement during a silent installation.
SET $ACCEPTEULA=yes

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
SET $ESRI_LICENSE_HOST=@sc-tellus.evergreen.edu;@ac-arc10-lic.evergreen.edu

::	Can be Viewer, Editor, or Professional.
SET $SOFTWARE_CLASS=Professional

::	Use SINGLE_USE to install ArcGIS Pro as a Single Use seat;
::	CONCURRENT_USE to install as a Concurrent Use seat;
::	and NAMED_USER for a Named User license.
::	{SINGLE_USE, Concurrent_USE, NAMED_USER}
SET $AUTHORIZATION_TYPE=CONCURRENT_USE

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
::	SET "$License_URL=https://geoduck.maps.arcgis.com"

::###########################################################################::


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::##### Everything below here is 'hard-coded' [DO NOT MODIFY] #####
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:SLT
::	Start Lapse Time
::	will be used to calculate how long the script runs for
SET $START_TIME=%Time%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: CONSOLE OUTPUT WHEN RUNNING Manually
ECHO ****************************************************************
ECHO. 
ECHO      %$SCRIPT_NAME% %$SCRIPT_VERSION%
ECHO.
ECHO ****************************************************************
ECHO.
ECHO.
ECHO Processing...
ECHO.
ECHO.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: Check Log access
IF NOT EXIST %$LOG_LOCATION% MD %$LOG_LOCATION% || SET $LOG_LOCATION=%PUBLIC%\Logs
:: What if log location gets set to Public
IF NOT EXIST %$LOG_LOCATION% MD %$LOG_LOCATION%
ECHO TEST %DATE% %TIME% > %$LOG_LOCATION%\test_%$LLOG_FILE% || SET $LOG_LOCATION=%TEMP%\Logs
:: What if log location gets set to temp
IF NOT EXIST %$LOG_LOCATION% MD %$LOG_LOCATION%
IF EXIST %$LOG_LOCATION%\test_%$LLOG_FILE% DEL /Q %$LOG_LOCATION%\test_%$LLOG_FILE%
IF NOT EXIST "%$LOG_LOCATION%\var" MD "%$LOG_LOCATION%\var" || IF NOT EXIST "%TEMP%\Logs" MD "%TEMP%\Logs\var"
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Certain test computers should always have ALL logging turned on
HOSTNAME | (FIND /I "%$DEBUGGER_PC%" 2> nul) && (SET $DEBUG_MODE=1) && (SET $CLEANUP=0)


:flogl
:: FUNCTION: Check and configure for ALL LOG LEVEL
IF %$DEBUG_MODE% EQU 1 SET $LOG_LEVEL_ALL=1
IF %$LOG_LEVEL_ALL% EQU 1 SET $LOG_LEVEL_INFO=1
IF %$LOG_LEVEL_ALL% EQU 1 SET $LOG_LEVEL_WARN=1
IF %$LOG_LEVEL_ALL% EQU 1 SET $LOG_LEVEL_ERROR=1
IF %$LOG_LEVEL_ALL% EQU 1 SET $LOG_LEVEL_FATAL=1
IF %$LOG_LEVEL_ALL% EQU 1 SET $LOG_LEVEL_DEBUG=1
IF %$LOG_LEVEL_ALL% EQU 1 SET $LOG_LEVEL_TRACE=1
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: Powershell Check
ECHO Checking on Powershell...
echo.
IF DEFINED PSModulePath (SET PS_STATUS=1) ELSE (SET PS_STATUS=0)
IF NOT EXIST "%$LOG_LOCATION%" SET "$LOG_LOCATION=%TEMP%"
IF NOT EXIST "%$LOG_LOCATION%\var" MD "%$LOG_LOCATION%\var" 
IF EXIST "%$LOG_LOCATION%\var\var_PS_Version.txt" GoTo checkPS
IF NOT DEFINED PSModulePath GoTo skipChkPS
IF DEFINED PSModulePath (@powershell $PSVersionTable.PSVersion > %$LOG_LOCATION%\var\var_PS_Version.txt) && (SET PS_STATUS=1)

:checkPS
FOR /F "usebackq skip=3 tokens=1 delims= " %%P IN ("%$LOG_LOCATION%\var\var_PS_Version.txt") DO SET "PS_MAJOR_VERSION=%%P"
FOR /F "usebackq skip=3 tokens=2 delims= " %%P IN ("%$LOG_LOCATION%\var\var_PS_Version.txt") DO SET "PS_MINOR_VERSION=%%P"
FOR /F "usebackq skip=3 tokens=3 delims= " %%P IN ("%$LOG_LOCATION%\var\var_PS_Version.txt") DO SET "PS_BUILD_VERSION=%%P"
FOR /F "usebackq skip=3 tokens=4 delims= " %%P IN ("%$LOG_LOCATION%\var\var_PS_Version.txt") DO SET "PS_REVISION_VERSION=%%P"
:skipChkPS

:fISO8601
:: Function to ensure ISO 8601 Date format yyyy-mmm-dd
:: Easiest way to get ISO date
@powershell Get-Date -format "yyyy-MM-dd" > "%$LOG_LOCATION%\var\var_ISO8601_Date.txt"
SET /P $ISO_DATE= < "%$LOG_LOCATION%\var\var_ISO8601_Date.txt"
:skipPS

:: Fallback if PowerShell not available
:fmanualISO
:: Manually create the ISO 8601 date format
IF DEFINED $ISO_DATE GoTo skipfmiso
FOR /F "tokens=2 delims=/ " %%T IN ("%DATE%") DO SET ISO_MONTH=%%T
FOR /F "tokens=3 delims=/ " %%T IN ("%DATE%") DO SET ISO_DAY=%%T
FOR /F "tokens=4 delims=/ " %%T IN ("%DATE%") DO SET ISO_YEAR=%%T
SET $ISO_DATE=%ISO_YEAR%-%ISO_MONTH%-%ISO_DAY%

:skipfmiso
::*****************************************************************************


:start
IF EXIST "%$LOG_LOCATION%\%$LLOG_FILE%" ECHO. >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	START... >> %$LOG_LOCATION%\%$LLOG_FILE%
IF NOT EXIST %$LOG_LOCATION%\var\var_TimeZone.txt (
	FOR /F "tokens=2-3 delims=()&" %%S IN ('wmic TIMEZONE GET Caption /VALUE') Do ECHO %%S%%T > %$LOG_LOCATION%\var\var_TimeZone.txt
	) && IF EXIST "%$LOG_LOCATION%\var\var_TimeZone.txt" IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	File [var_TimeZone.txt] created! >> %$LOG_LOCATION%\%$LLOG_FILE% 
SET /P var_TimeZone= < %$LOG_LOCATION%\var\var_TimeZone.txt
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	%var_TimeZone% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	SCRIPT: %$SCRIPT_NAME% %$SCRIPT_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	SCRIPT BUILD: %$SCRIPT_BUILD% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Computer: %COMPUTERNAME% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	User: %USERNAME% >> %$LOG_LOCATION%\%$LLOG_FILE%


:: Check if running with Administrative Privilege
openfiles.exe > %$LOG_LOCATION%\var\var_openfiles.txt 2>nul
SET $ADMIN_STATUS=%ERRORLEVEL%
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ADMIN_STATUS: {%$ADMIN_STATUS%} >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_DEBUG% EQU 1 IF %$ADMIN_STATUS% EQU 0 ECHO %$ISO_DATE% %TIME% [DEBUG]	Running with administrative privilege. >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$ADMIN_STATUS% EQU 1 IF %$LOG_LEVEL_FATAL% EQU 1 ECHO %$ISO_DATE% %TIME% [FATAL]	Not running with administrative privilege! >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$ADMIN_STATUS% NEQ 0 GoTo ELT
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Update License Server via Registry Key
IF %$LOG_LEVEL_TRACE% EQU 1 ECHO %$ISO_DATE% %TIME% [TRACE]	ENTER: License Server update... >> %$LOG_LOCATION%\%$LLOG_FILE%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro /V REALVERSION 2> nul
SET $LSU_ERROR=%ERRORLEVEL%
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $LSU_ERROR: %$LSU_ERROR% >> %$LOG_LOCATION%\%$LLOG_FILE%
::	skip if not installed
IF %$LSU_ERROR% NEQ 0 GoTo skipLSU
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro | FIND "Licensing"> %$LOG_LOCATION%\var\var_ArcGIS_License_HKEY.txt
SET /P $ARCGIS_LICENSE_HKEY= < "%$LOG_LOCATION%\var\var_ArcGIS_License_HKEY.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ARCGIS_LICENSE_HKEY: %$ARCGIS_LICENSE_HKEY% >> %$LOG_LOCATION%\%$LLOG_FILE%
REG ADD "%$ARCGIS_LICENSE_HKEY%" /V LICENSE_SERVER /f /d %$ESRI_LICENSE_HOST%
REG QUERY "%$ARCGIS_LICENSE_HKEY%" /V LICENSE_SERVER 2> nul > %$LOG_LOCATION%\var\var_ArcGIS_License_HKEY_Value.txt
SET /P $ARCGIS_LICENSE_HKEY_VALUE= < "%$LOG_LOCATION%\var\var_ArcGIS_License_HKEY_Value.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ARCGIS_LICENSE_HKEY_VALUE: %$ARCGIS_LICENSE_HKEY_VALUE% >> %$LOG_LOCATION%\%$LLOG_FILE%
:: update Authorization Type
REG ADD "%$ARCGIS_LICENSE_HKEY%" /V AUTHORIZATION_TYPE /f /d %$AUTHORIZATION_TYPE%
REG QUERY "%$ARCGIS_LICENSE_HKEY%" /V AUTHORIZATION_TYPE  2> nul > "%$LOG_LOCATION%\var\var_ArcGIS_AUTHORIZATION_TYPE_HKEY_Value.txt"
SET /P $ARCGIS_AUTHORIZATION_TYPE_HKEY_VALUE= < "%$LOG_LOCATION%\var\var_ArcGIS_AUTHORIZATION_TYPE_HKEY_Value.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ARCGIS_AUTHORIZATION_TYPE_HKEY_VALUE: %$ARCGIS_AUTHORIZATION_TYPE_HKEY_VALUE% >> %$LOG_LOCATION%\%$LLOG_FILE%
:skipLSU
IF %$LOG_LEVEL_TRACE% EQU 1 ECHO %$ISO_DATE% %TIME% [TRACE]	EXIT: License Server update. >> %$LOG_LOCATION%\%$LLOG_FILE%


:: If network Repo, check user is domain user
IF %$LOG_LEVEL_TRACE% EQU 1 ECHO %$ISO_DATE% %TIME% [TRACE]	ENTER: User status checking... >> %$LOG_LOCATION%\%$LLOG_FILE%
IF DEFINED $PACKAGE_SOURCE (echo %$PACKAGE_SOURCE% | FIND "\\") 
IF %ERRORLEVEL% EQU 0 (SET DOMAIN_USER_REQ=1) ELSE (SET DOMAIN_USER_REQ=0)
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: DOMAIN_USER_REQ: %DOMAIN_USER_REQ% >> %$LOG_LOCATION%\%$LLOG_FILE%
:: Should be a domain user if PACAKGE_SOURCE configured as SMB
SET LOCAL_USER=0
IF %DOMAIN_USER_REQ% EQU 1 IF "%USERDOMAIN%"=="%COMPUTERNAME%" SET LOCAL_USER=1
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: LOCAL_USER: %LOCAL_USER% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %LOCAL_USER% EQU 1 IF %$LOG_LEVEL_ERROR% EQU 1 ECHO %$ISO_DATE% %TIME% [ERROR]	User is not a domain user, but Remote Repo configured! >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %LOCAL_USER% EQU 1 GoTo postCheck
IF %$LOG_LEVEL_TRACE% EQU 1 ECHO %$ISO_DATE% %TIME% [TRACE]	EXIT: User status checking. >> %$LOG_LOCATION%\%$LLOG_FILE%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Get the currently installed version of ArcGIS Pro
(FOR /F "tokens=3 delims= " %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro /V REALVERSION') DO ECHO %%P> %$LOG_LOCATION%\var\var_ArcGISPro_version.txt) 2> nul
IF EXIST "%$LOG_LOCATION%\var\var_ArcGISPro_Version.txt" SET /P ARCGISPRO_VERSION= < "%$LOG_LOCATION%\var\var_ArcGISPro_Version.txt"
REM Will return Major and Minor, but not revision. Append 0 as revision
SET ARCGISPRO_VERSION=%ARCGISPRO_VERSION%.0
IF DEFINED ARCGISPRO_VERSION IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Found ARCGISPRO Version: %ARCGISPRO_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF NOT DEFINED ARCGISPRO_VERSION IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	ArcGIS Pro not installed! First time installation! >> %$LOG_LOCATION%\%$LLOG_FILE%
IF NOT DEFINED ARCGISPRO_VERSION SET ARCGISPRO_VERSION=0
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Get the currently installed updates of ArcGIS Pro
(FOR /F "tokens=6 delims=\" %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Updates') DO ECHO %%P > %$LOG_LOCATION%\var\var_ArcGISPro_Update.txt) 2> nul
IF EXIST "%$LOG_LOCATION%\var\var_ArcGISPro_Update.txt" SET /P ARCGISPRO_UPDATE= < "%$LOG_LOCATION%\var\var_ArcGISPro_Update.txt"
IF DEFINED ARCGISPRO_UPDATE IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Found ARCGISPRO Patch: %ARCGISPRO_UPDATE% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF NOT DEFINED ARCGISPRO_UPDATE IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	ArcGIS Pro patches not installed! >> %$LOG_LOCATION%\%$LLOG_FILE%
IF NOT DEFINED ARCGISPRO_UPDATE SET ARCGISPRO_UPDATE=0
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: GET the latest ArcGIS installation package
dir /B /A:D /O:-N "%$PACKAGE_SOURCE%"> %$LOG_LOCATION%\var\var_ArcGISPro_Folder.txt
SET /P ARCGISPRO_FOLDER= < "%$LOG_LOCATION%\var\var_ArcGISPro_Folder.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_FOLDER: %ARCGISPRO_FOLDER% >> %$LOG_LOCATION%\%$LLOG_FILE%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Check if installer should run
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Checking if the ArcGIS Pro installer should run... >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %ARCGISPRO_VERSION% EQU 0 GoTo skipAPcheck
FOR /F "tokens=2 delims=_" %%P IN ("%ARCGISPRO_FOLDER%") DO SET ARCGISPRO_FOLDER_NUMBER=%%P
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_FOLDER_NUMBER: %ARCGISPRO_FOLDER_NUMBER% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %ARCGISPRO_FOLDER_NUMBER% EQU %ARCGISPRO_VERSION% IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	ArcGIS Pro already installed to version %ARCGISPRO_FOLDER_NUMBER% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %ARCGISPRO_FOLDER_NUMBER% EQU %ARCGISPRO_VERSION% GoTo skipAP
:skipAPcheck
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Microsoft dot NET SDK Dependency
IF %$LOG_LEVEL_TRACE% EQU 1 ECHO %$ISO_DATE% %TIME% [TRACE]	ENTER: Microsoft .NET SDK... >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO Working on Microsoft dot NET SDK Dependency...
SET $INSTALL_DOTNET=0
where dotnet 2>nul || SET $INSTALL_DOTNET=1
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $INSTALL_DOTNET: %$INSTALL_DOTNET% >> %$LOG_LOCATION%\%$LLOG_FILE%
if %$INSTALL_DOTNET% EQU 1 GoTo skipNETV
dotnet --version> %$LOG_LOCATION%\var\dotnet-version.txt
SET /P $DOTNET_VERSION= < %$LOG_LOCATION%\var\dotnet-version.txt
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $DOTNET_VERSION: %$DOTNET_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
dir /B /A:-D /O:-D "%$NET_SDK_PACKAGE%"> "%$LOG_LOCATION%\var\NET-SDK_Package.txt"
for /f "tokens=3 delims=-" %%P IN (%$LOG_LOCATION%\var\NET-SDK_Package.txt) Do echo %%P> "%$LOG_LOCATION%\var\NET-SDK_Package_Version.txt"
SET /P $NET_SDK_PACKAGE_VERSION= < "%$LOG_LOCATION%\var\NET-SDK_Package_Version.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $NET_SDK_PACKAGE_VERSION: %$NET_SDK_PACKAGE_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
if %$NET_SDK_PACKAGE_VERSION% GTR %$DOTNET_VERSION% SET $INSTALL_DOTNET=1
if %$INSTALL_DOTNET% EQU 0 GoTo skipNET
:skipNETV

IF %$LOG_LEVEL_TRACE% EQU 1 ECHO %$ISO_DATE% %TIME% [TRACE]	ENTER: Microsoft .NET SDK download... >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	installing Microsoft .NET SDK >> %$LOG_LOCATION%\%$LLOG_FILE%
ROBOCOPY "%$NET_SDK_PACKAGE%" "%PUBLIC%\Downloads\NET-SDK" *.exe /NP /R:2 /W:5
CD "%PUBLIC%\Downloads\NET-SDK"
dir /B /A:-D /O:-D> "%$LOG_LOCATION%\var\NET-SDK.txt"
SET /P $NET_SDK= < "%$LOG_LOCATION%\var\NET-SDK.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $NET_SDK: %$NET_SDK% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_TRACE% EQU 1 ECHO %$ISO_DATE% %TIME% [TRACE]	EXIT: Microsoft .NET SDK download. >> %$LOG_LOCATION%\%$LLOG_FILE%
%$NET_SDK% /install /quiet /log "%$LOG_LOCATION%\MS_NET_SDK.txt"
SET $NET_SDK_ERROR=%ERRORLEVEL%
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $NET_SDK_ERROR: %$NET_SDK_ERROR% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$NET_SDK_ERROR% EQU 0 IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	dotNET-SDK {%$NET_SDK%} installed. >> %$LOG_LOCATION%\%$LLOG_FILE%
echo dotNET-SDK {%$NET_SDK%} installed.
:skipNET
IF %$LOG_LEVEL_TRACE% EQU 1 ECHO %$ISO_DATE% %TIME% [TRACE]	EXIT: Microsoft .NET SDK. >> %$LOG_LOCATION%\%$LLOG_FILE%

:: Copy the installers locally
ECHO Downloading ArcGIS Pro packages (be patient)...
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Installing ArcGIS Pro latest version... >> %$LOG_LOCATION%\%$LLOG_FILE%
ROBOCOPY "%$PACKAGE_SOURCE%\%ARCGISPRO_FOLDER%" "%$PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%" /S /E /NP /NDL /NFL /R:2 /W:5 /LOG+:"%$LOG_LOCATION%\%$LLOG_FILE%"
:: Installation Prep
::	Fix orphaned ArcGIS file in Start Menu
::	Only needed when the main installer leaves bad links.
::	IF EXIST "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\ArcGIS\ArcGIS Pro" del /S /Q /F "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\ArcGIS\ArcGIS Pro"
:: Check License_URL & Authorization_Type
IF DEFINED $License_URL IF /I "%$AUTHORIZATION_TYPE%"=="NAMED_USER" GoTo skipC1
:: not named_user, can't be defined
:: $CLEANUP reg key before installer
REM If License_URL is defined from previous install, installation will fail if AUTHORIZATION_TYPE=Concurrent
REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Settings /V License_URL /f /d ""
SET $License_URL=
:skipC1

:: Execute the installer
IF NOT DEFINED ARCGISPRO_FOLDER GoTo skipAGSPI
ECHO Installing ArcGIS Pro latest version...
msiexec /i "%$PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%\ArcGISPro.msi" INSTALLDIR="%$INSTALLDIR%" ALLUSERS=%$ALLUSERS% ENABLEEUEI=%$ENABLEEUEI% ACCEPTEULA=%$ACCEPTEULA% BLOCKADDINS=%$BLOCKADDINS% CHECKFORUPDATESATSTARTUP=%$CHECKFORUPDATESATSTARTUP% ESRI_LICENSE_HOST=^%$ESRI_LICENSE_HOST% SOFTWARE_CLASS=%$SOFTWARE_CLASS% AUTHORIZATION_TYPE=%$AUTHORIZATION_TYPE% LOCK_AUTH_SETTINGS=%$LOCK_AUTH_SETTINGS% ArcGIS_Connection=%$ArcGIS_Connection% Portal_List="%$Portal_List%" License_URL="%$License_URL%" /qb

:skipAGSPI

SET ARCGISPRO_INSTALL_ERROR=%ERRORLEVEL%
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	ARCGISPRO_INSTALL_ERROR: %ARCGISPRO_INSTALL_ERROR% >> %$LOG_LOCATION%\%$LLOG_FILE%
:skipAP
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: ArcGIS Pro Updates
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Checking if patch installer should run... >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO Checking on update packages...
:trapAPP
SET PACKAGE_ALREADY_INSTALLED=0
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Updates /S /v "NAME" 2> nul || SET PACKAGE_ALREADY_INSTALLED=0
dir /B /A:-D "%$PACKAGE_SOURCE%\%ARCGISPRO_FOLDER%" | FIND /I ".msp"> %$LOG_LOCATION%\var\var_ArcGISPro_updatePackage.txt
SET /P ARCGISPRO_UPDATE_PACKAGE= < "%$LOG_LOCATION%\var\var_ArcGISPro_updatePackage.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_UPDATE_PACKAGE: %ARCGISPRO_UPDATE_PACKAGE% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF NOT DEFINED ARCGISPRO_UPDATE_PACKAGE GoTo skipAPP
REM MSP Package should follow the format of ArcGIS_Pro_<UpdateVersion>_<build>.msp
REM Just want the Update version seperated by "_"
FOR /F "tokens=3 delims=_" %%P IN (%$LOG_LOCATION%\var\var_ArcGISPro_updatePackage.txt) DO echo %%P> %$LOG_LOCATION%\var\var_ArcGISPro_updatePackage_Version.txt
SET /P ARCGISPRO_UPDATE_PACKAGE_VERSION= < "%$LOG_LOCATION%\var\var_ArcGISPro_updatePackage_Version.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_UPDATE_PACKAGE_VERSION: %ARCGISPRO_UPDATE_PACKAGE_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%

IF EXIST "%$LOG_LOCATION%\var\var_ArcGISPro_updatePackage_system.txt" DEL /Q /F "%$LOG_LOCATION%\var\var_ArcGISPro_updatePackage_system.txt"
FOR /F "tokens=3-5 delims=^(^)." %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Updates /S /v "NAME"') DO echo %%P%%Q%%R>> "%$LOG_LOCATION%\var\var_ArcGISPro_updatePackage_system.txt"
SET /P ARCGIS_UPDATE_VERSION_SYSTEM= < "%$LOG_LOCATION%\var\var_ArcGISPro_updatePackage_system.txt"
IF %ARCGIS_UPDATE_VERSION_SYSTEM% GEQ %ARCGISPRO_UPDATE_PACKAGE_VERSION% SET PACKAGE_ALREADY_INSTALLED=1
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: PACKAGE_ALREADY_INSTALLED: %PACKAGE_ALREADY_INSTALLED% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %PACKAGE_ALREADY_INSTALLED% EQU 1 IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	ArcGIS Pro update package {%ARCGISPRO_UPDATE_PACKAGE%} already installed! >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %PACKAGE_ALREADY_INSTALLED% EQU 1 GoTo skipAPP

:: This is needed in case main ArcGIS Pro doesn't run, to retrieve msp packages
IF NOT EXIST "%$PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%\%ARCGISPRO_UPDATE_PACKAGE%" ROBOCOPY "%PACKAGE_SOURCE%\%ARCGISPRO_FOLDER%" "%$PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%" /NP /NDL /NFL /R:2 /W:5 *.msp /LOG+:"%$LOG_LOCATION%\%$LLOG_FILE%"

:runAPP
:: Execute the update package
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Installing ArcGIS Pro [%ARCGISPRO_UPDATE_PACKAGE%] patch... >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO Installing ArcGIS Pro patch [%ARCGISPRO_UPDATE_PACKAGE%]...
IF %PS_STATUS% EQU 1 @powershell Unblock-File -path "%$PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%\%ARCGISPRO_UPDATE_PACKAGE%"
"%$PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%\%ARCGISPRO_UPDATE_PACKAGE%" /passive /l "%$LOG_LOCATION%\%COMPUTERNAME%_%ARCGISPRO_UPDATE_PACKAGE%.log"
SET ARCGIS_UPDATE_ERROR=%ERRORLEVEL%
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	ARCGIS_UPDATE_ERROR: %ARCGIS_UPDATE_ERROR% >> %$LOG_LOCATION%\%$LLOG_FILE%

REM See if the MSI log file already exists, and if it does change it to UTF-8 encoding so FINDSTR can work.
::	Just using error code for now.
::IF EXIST "%$LOG_LOCATION%\%COMPUTERNAME%_%ARCGISPRO_UPDATE_PACKAGE%.log" (@powershell Get-Content -Path "%$LOG_LOCATION%\%COMPUTERNAME%_%ARCGISPRO_UPDATE_PACKAGE%.log" | @powershell Set-Content -Path "%$LOG_LOCATION%\%COMPUTERNAME%_%ARCGISPRO_UPDATE_PACKAGE%.log" -Encoding UTF8)

:skipAPP
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:postCheck
:: Get the currently installed version of ArcGIS Pro
FOR /F "tokens=3 delims= " %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro /V REALVERSION') DO ECHO %%P > %$LOG_LOCATION%\var\var_ArcGISPro_version.txt
SET /P ARCGISPRO_VERSION= < "%$LOG_LOCATION%\var\var_ArcGISPro_Version.txt"
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Current ARCGISPRO Version: %ARCGISPRO_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Get the updated version of ArcGIS Pro
FOR /F "tokens=6 delims=\" %%P IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Updates') DO ECHO %%P > %$LOG_LOCATION%\var\var_ArcGISPro_Patch.txt
SET /P ARCGISPRO_PATCH= < "%$LOG_LOCATION%\var\var_ArcGISPro_Patch.txt"
IF DEFINED ARCGISPRO_PATCH IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Current ARCGISPRO Patch: %ARCGISPRO_PATCH% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF NOT DEFINED ARCGISPRO_PATCH IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Current ARCGISPRO Patch: NA >> %$LOG_LOCATION%\%$LLOG_FILE%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Check Registry Values for ArcGIS Pro
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Licensing /v AUTHORIZATION_TYPE | FIND "%$AUTHORIZATION_TYPE%"
IF %ERRORLEVEL% EQU 1 REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Licensing /v AUTHORIZATION_TYPE /t REG_SZ /d %$AUTHORIZATION_TYPE% /f
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Licensing /v LICENSE_SERVER | FIND "%$ESRI_LICENSE_HOST%"
IF %ERRORLEVEL% EQU 1 REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\ESRI\ArcGISPro\Licensing /v LICENSE_SERVER /t REG_SZ /d %$ESRI_LICENSE_HOST% /f

:: Section for variables to be set/reset so that DEBUG is correct
IF %$DEBUG_MODE% EQU 1 SET $CLEANUP=0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Start of variable debug
IF %$LOG_LEVEL_TRACE% EQU 1 (ECHO %$ISO_DATE% %TIME% [TRACE]	ENTER: Variable debug!) >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_DEBUG% EQU 0 GoTo varE
ECHO %$ISO_DATE% %TIME% [DEBUG]	------------------------------------------------------------------- >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ADMIN_STATUS: %$ADMIN_STATUS% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ISO_MONTH: %ISO_MONTH% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ISO_DAY: %ISO_DAY% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ISO_YEAR: %ISO_YEAR% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ISO_DATE: %$ISO_DATE% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: PS_STATUS: %PS_STATUS% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: PS_MAJOR_VERSION: %PS_MAJOR_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: PS_MINOR_VERSION: %PS_MINOR_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: PS_BUILD_VERSION: %PS_BUILD_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: PS_REVISION_VERSION: %PS_REVISION_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $INSTALL_DOTNET: %$INSTALL_DOTNET% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $DOTNET_VERSION: %$DOTNET_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $NET_SDK_PACKAGE_VERSION: %$NET_SDK_PACKAGE_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $NET_SDK: %$NET_SDK% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $NET_SDK_ERROR: %$NET_SDK_ERROR% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $INSTALLDIR: %$INSTALLDIR% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ALLUSERS: %$ALLUSERS% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ENABLEEUEI: %$ENABLEEUEI% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ACCEPTEULA=%$ACCEPTEULA% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $BLOCKADDINS: %$BLOCKADDINS% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $CHECKFORUPDATESATSTARTUP: %$CHECKFORUPDATESATSTARTUP% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ESRI_LICENSE_HOST: %$ESRI_LICENSE_HOST% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $SOFTWARE_CLASS: %$SOFTWARE_CLASS% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $AUTHORIZATION_TYPE: %$AUTHORIZATION_TYPE% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $LOCK_AUTH_SETTINGS: %$LOCK_AUTH_SETTINGS% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $ArcGIS_Connection: %$ArcGIS_Connection% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $Portal_List: %$Portal_List% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $License_URL: %$License_URL% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: PACKAGE_SOURCE: %PACKAGE_SOURCE% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $PACKAGE_DESTINATION: %$PACKAGE_DESTINATION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_FOLDER: %ARCGISPRO_FOLDER% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_INSTALL_ERROR: %ARCGISPRO_INSTALL_ERROR% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGIS_UPDATE_ERROR: %ARCGIS_UPDATE_ERROR% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_VERSION: %ARCGISPRO_VERSION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: ARCGISPRO_PATCH: %ARCGISPRO_PATCH% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $LOG_LOCATION: %$LOG_LOCATION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $LLOG_FILE: %$LLOG_FILE% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $LOG_SHIPPING_LOCATION: %$LOG_SHIPPING_LOCATION% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $CLEANUP: %$CLEANUP% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $DEBUG_MODE: %$DEBUG_MODE% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: $DEBUGGER_PC:	%$DEBUGGER_PC% >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO %$ISO_DATE% %TIME% [DEBUG]	------------------------------------------------------------------- >> %$LOG_LOCATION%\%$LLOG_FILE%
:varE
IF %$LOG_LEVEL_TRACE% EQU 1 (ECHO %$ISO_DATE% %TIME% [TRACE]	EXIT: Variable debug!) >> %$LOG_LOCATION%\%$LLOG_FILE%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:ELT
:: Calculate the actual lapse time
IF %PS_STATUS% NEQ 1 GoTo skipELT
@PowerShell.exe -c "$span=([datetime]'%Time%' - [datetime]'%$START_TIME%'); '{0:00}:{1:00}:{2:00}' -f $span.Hours, $span.Minutes, $span.Seconds" > "%$LOG_LOCATION%\var\Total_Lapsed_Time.txt"
SET /P TOTAL_TIME= < "%$LOG_LOCATION%\var\Total_Lapsed_Time.txt"
IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	VARIABLE: TOTAL_TIME: %TOTAL_TIME% >> %$LOG_LOCATION%\%$LLOG_FILE%
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	Time Lapsed (hh:mm:ss): %TOTAL_TIME% >> %$LOG_LOCATION%\%$LLOG_FILE%
:skipELT
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:Clean
IF %$CLEANUP% EQU 0 GoTo skipClean
IF EXIST "%$LOG_LOCATION%\var" RD /S /Q "%$LOG_LOCATION%\var"
IF NOT EXIST "%$LOG_LOCATION%\var" IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	var folder deleted! >> %$LOG_LOCATION%\%$LLOG_FILE%
IF EXIST "%$PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%" RD /S /Q "%$PACKAGE_DESTINATION%\%ARCGISPRO_FOLDER%"
IF NOT EXIST "%$PACKAGE_DESTINATION%"  IF %$LOG_LEVEL_DEBUG% EQU 1 ECHO %$ISO_DATE% %TIME% [DEBUG]	ArcGIS Pro staging area deleted! >> %$LOG_LOCATION%\%$LLOG_FILE%
:skipClean
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:End
IF %$LOG_LEVEL_INFO% EQU 1 ECHO %$ISO_DATE% %TIME% [INFO]	END! >> %$LOG_LOCATION%\%$LLOG_FILE%
ECHO. >> %$LOG_LOCATION%\%$LLOG_FILE%
:: Domain User required
IF %LOCAL_USER% EQU 1 GoTo skipLS
:: Ship the log file
IF DEFINED $LOG_SHIPPING_LOCATION ECHO Shipping log file ...
echo.
IF NOT EXIST "%$LOG_SHIPPING_LOCATION%" MD "%$LOG_SHIPPING_LOCATION%"
IF EXIST %$LOG_LOCATION%\%$LLOG_FILE% ROBOCOPY "%$LOG_LOCATION%" "%$LOG_SHIPPING_LOCATION%" %$LLOG_FILE% /R:5 /W:30 /NDL /NFL /NP
:skipLS
ENDLOCAL
EXIT /B