echo off
rem Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.

call set_env.bat || exit /b 1

set OUT_DIR=%JCEF_ROOT_DIR%\jcef_build\native\Release

if "%~1" == "clean" (
    echo *** delete "%OUT_DIR%"...
    rmdir /s /q "%OUT_DIR%"
    exit /b 0
)
md "%OUT_DIR%"

if "%~2" == "arm64" (
    set "TARGET_ARCH=arm64"
)
if "%~2" == "x86_64" (
    set "TARGET_ARCH=x86_64"
)
echo TARGET_ARCH=%TARGET_ARCH%

cd "%JCEF_ROOT_DIR%\jcef_build" || goto:__exit


echo *** set VS16 env...

if "%env.VS160COMNTOOLS%" neq "" (
    set "VS160COMNTOOLS=%env.VS160COMNTOOLS%"
)
if "%VS160COMNTOOLS%" == "" (
    echo error: VS160COMNTOOLS is not set
    goto:__exit
)
echo VS160COMNTOOLS="%VS160COMNTOOLS%"
if "%TARGET_ARCH%" == "arm64" (
    call "%VS160COMNTOOLS%\..\..\VC\Auxiliary\Build\vcvarsamd64_arm64.bat" || goto:__exit
) else (
    call "%VS160COMNTOOLS%\..\..\VC\Auxiliary\Build\vcvarsall.bat" amd64 || goto:__exit
)

echo *** run cmake...
if "%env.JCEF_CMAKE%" neq "" (
    set "JCEF_CMAKE=%env.JCEF_CMAKE%"
)
if "%JCEF_CMAKE%" == "" (
    echo error: JCEF_CMAKE is not set
    goto:__exit
)
echo JCEF_CMAKE=%JCEF_CMAKE%

if "%env.JCEF_PYTHON%" neq "" (
    set "JCEF_PYTHON=%env.JCEF_PYTHON%"
)
if "%JCEF_PYTHON%" == "" (
    echo error: JCEF_PYTHON is not set
    goto:__exit
)
echo JCEF_PYTHON=%JCEF_PYTHON%
set "PATH=%JCEF_CMAKE%\bin;%JCEF_PYTHON%;%PATH%"
set RC=

rem Workaround for https://gitlab.kitware.com/cmake/cmake/-/issues/19193
setlocal
set "PATH=%JDK_11%\bin;%PATH%"

if "%TARGET_ARCH%" == "arm64" (
    cmake -G "Visual Studio 16 2019" -A ARM64 -D "JAVA_HOME=%JDK_11:\=/%" .. || goto:__exit
) else (
    cmake -G "Visual Studio 16 2019" -A x64   -D "JAVA_HOME=%JDK_11:\=/%" .. || goto:__exit
)

endlocal

echo *** run cmake build...
cmake --build . --config Release -- /t:Rebuild || goto:__exit

cd "%JB_TOOLS_OS_DIR%" && exit /b 0

:__exit
cd "%JB_TOOLS_OS_DIR%" && exit /b 1