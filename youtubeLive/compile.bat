set WORKSPACE=%~dp0
set BUILD_DIR=%WORKSPACE%\build
set CMAKE_PREFIX_PATH="D:\app\qt\5.15.1\msvc2019_64"

rd "%BUILD_DIR%" /S /Q
cmake -S . -B "%BUILD_DIR%" -DCMAKE_PREFIX_PATH=%CMAKE_PREFIX_PATH% "-DCMAKE_BUILD_TYPE:STRING=Release"
cmake --build "%BUILD_DIR%" --config Release
