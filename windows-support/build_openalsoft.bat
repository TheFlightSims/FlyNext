
SET PATH=%PATH%;%ProgramFiles%\CMake\bin;C:\sentry

SET CMAKE_TOOLCHAIN="Visual Studio 15 2017 Win64"
SET CMAKE_TOOLCHAIN_X86="Visual Studio 15 2017"


SET ROOT_DIR=%CD%
SET SOURCE=C:\FGFS\openal-soft

SET THIRDPARTY_DIR=C:\FGFS\windows-3rd-party\msvc140

rd /S /Q install_64\openal
rd /S /Q install_32\openal

md build-openal-soft
cd build-openal-soft

cmake %SOURCE% -G %CMAKE_TOOLCHAIN% ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%\install_64\openal 

cmake --build . --config RelWithDebInfo --target INSTALL

cd ..
md build-openal-soft-32
cd build-openal-soft-32

cmake %SOURCE% -G %CMAKE_TOOLCHAIN_X86% ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%\install_32\openal 

cmake --build . --config RelWithDebInfo --target INSTALL

cd %ROOT_DIR%

xcopy /S /Y %ROOT_DIR%\install_64\openal\include\* %THIRDPARTY_DIR%\3rdParty.x64\include\
xcopy /S /Y %ROOT_DIR%\install_64\openal\lib\cmake\* %THIRDPARTY_DIR%\3rdParty.x64\lib\cmake\
xcopy /S /Y %ROOT_DIR%\install_64\openal\bin\OpenAL32.dll %THIRDPARTY_DIR%\3rdParty.x64\bin\
xcopy /S /Y %ROOT_DIR%\install_64\openal\lib\OpenAL32.lib %THIRDPARTY_DIR%\3rdParty.x64\lib\

xcopy /S /Y %ROOT_DIR%\install_32\openal\include\* %THIRDPARTY_DIR%\3rdParty\include\
xcopy /S /Y %ROOT_DIR%\install_32\openal\bin\OpenAL32.dll %THIRDPARTY_DIR%\3rdParty\bin\
xcopy /S /Y %ROOT_DIR%\install_32\openal\lib\OpenAL32.lib %THIRDPARTY_DIR%\3rdParty\lib\
xcopy /S /Y %ROOT_DIR%\install_32\openal\lib\cmake\* %THIRDPARTY_DIR%\3rdParty\lib\cmake\

SET SENTRY_ORG=flightgear
SET SENTRY_PROJECT=flightgear
REM SET SENTRY_AUTH_TOKEN=

sentry-cli upload-dif %ROOT_DIR%\build-openal-soft\RelWithDebInfo\OpenAL32.pdb
sentry-cli upload-dif %ROOT_DIR%\build-openal-soft032\RelWithDebInfo\OpenAL32.pdb
