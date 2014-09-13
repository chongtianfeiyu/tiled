@rem  TILED DAILY BUILD SCRIPT
@echo off

rem The following assumes US date format!

set VERSION=%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%

set TILED_SOURCE_DIR=C:\Projects\tiled
set TILED_BUILD_DIR=C:\Builds\tiled-daily-qt5
set QTDIR=C:\Qt\5.3\msvc2013_opengl
set ARCH=32
set MAKE=C:\Qt\Tools\QtCreator\bin\jom.exe
set GIT="C:\Program Files (x86)\Git\cmd\git.exe"
set SCP="C:\Program Files (x86)\Git\bin\scp.exe"
set DESTINATION=bjorn@files.mapeditor.org:public_html/files.mapeditor.org/public/daily/

echo Waiting a bit for the network to come up...
ping -n 3 127.0.0.1 > nul

pushd %TILED_SOURCE_DIR%
%GIT% fetch
%GIT% diff --quiet origin/master
if %ERRORLEVEL% == 0 (
    echo No change, nothing to do.
    popd
    goto done
) else if %ERRORLEVEL% == 1 (
   %GIT% reset --hard origin/master
)
popd

FOR /F "tokens=*" %%i in ('%GIT% describe') do SET COMMITNOW=%%i

echo Building Tiled daily %VERSION%... (from %COMMITNOW%)

call %QTDIR%\bin\qtenv2.bat
call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86

mkdir %TILED_BUILD_DIR%
pushd %TILED_BUILD_DIR%
qmake.exe -r %TILED_SOURCE_DIR%\tiled.pro "CONFIG+=release" "QMAKE_CXXFLAGS+=-DBUILD_INFO_VERSION=%COMMITNOW%"
%MAKE%
popd

echo Building Installer...
pushd %TILED_SOURCE_DIR%\dist\win
makensis.exe tiled.nsi

echo Uploading installer...
%SCP% -B tiled-%VERSION%-win32-setup.exe %DESTINATION%

popd

:done

echo Shutting down in 30 seconds...
ping -n 31 127.0.0.1 > nul
shutdown -s
