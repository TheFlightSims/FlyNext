
SET PATH=%PATH%;%ProgramFiles%\CMake\bin;C:\sentry

SET CMAKE_TOOLCHAIN="Visual Studio 15 2017 Win64"
SET CMAKE_TOOLCHAIN_X86="Visual Studio 15 2017"


SET ROOT_DIR=%CD%
SET SOURCE=C:\FGFS\sentry-native

SET THIRDPARTY_DIR=C:\FGFS\windows-3rd-party\msvc140

rd /S /Q install_64\sentry
rd /S /Q install_32\sentry

cd build-sentry
cmake %SOURCE% -G %CMAKE_TOOLCHAIN% ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%\install_64\sentry 

cmake --build . --config RelWithDebInfo --target INSTALL

cd ..\build-sentry-32
cmake %SOURCE% -G %CMAKE_TOOLCHAIN_X86% ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%\install_32\sentry 

cmake --build . --config RelWithDebInfo --target INSTALL

cd %ROOT_DIR%

xcopy /S /Y %ROOT_DIR%\install_64\sentry\* %THIRDPARTY_DIR%\3rdParty.x64\
xcopy /S /Y %ROOT_DIR%\install_32\sentry\* %THIRDPARTY_DIR%\3rdParty\

SET SENTRY_ORG=flightgear
SET SENTRY_PROJECT=flightgear
REM SET SENTRY_AUTH_TOKEN=

sentry-cli upload-dif %ROOT_DIR%\install_64\sentry\bin\sentry.pdb
sentry-cli upload-dif %ROOT_DIR%\install_32\sentry\bin\sentry.pdb
