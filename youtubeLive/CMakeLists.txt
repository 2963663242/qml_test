cmake_minimum_required(VERSION 3.14)

project(youtubeLive VERSION 0.1 LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick Widgets REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Quick Widgets REQUIRED)

file(GLOB SOURCE_FILES "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/*.h")

set(PROJECT_SOURCES
        main.cpp
        qml.qrc
       ${SOURCE_FILES}
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(youtubeLive
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
    )
# Define target properties for Android with Qt 6 as:
#    set_property(TARGET youtubeLive APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
#                 ${CMAKE_CURRENT_SOURCE_DIR}/android)
# For more information, see https://doc.qt.io/qt-6/qt-add-executable.html#target-creation
else()
    if(ANDROID)
        add_library(youtubeLive SHARED
            ${PROJECT_SOURCES}
        )
# Define properties for Android with Qt 5 after find_package() calls as:
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    else()
        add_executable(youtubeLive
          ${PROJECT_SOURCES}
        )
    endif()
endif()

# 添加包含目录
target_include_directories(youtubeLive PUBLIC
                           "${CMAKE_CURRENT_SOURCE_DIR}/sdk/include"
)
# 添加库目录
target_link_directories(youtubeLive PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/sdk/win/lib)

target_compile_definitions(youtubeLive
  PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG> QT_QML_DEBUG)
target_link_libraries(youtubeLive
  PRIVATE Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick Qt${QT_VERSION_MAJOR}::Widgets LibVideoDownload.lib)

set_target_properties(youtubeLive PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

if(QT_VERSION_MAJOR EQUAL 6)
    qt_import_qml_plugins(youtubeLive)
    qt_finalize_executable(youtubeLive)
endif()

set(MY_EXECUTABLE_OUTPUT_PATH "${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}")
message(STATUS "MY_EXECUTABLE_OUTPUT_PATH=${MY_EXECUTABLE_OUTPUT_PATH}")
#添加生成后事件
add_custom_command(
TARGET youtubeLive POST_BUILD
COMMAND xcopy "\"${CMAKE_CURRENT_SOURCE_DIR}\\sdk\\win\\bin\\*\"" "\"${MY_EXECUTABLE_OUTPUT_PATH}\"" /E /S /Y
COMMAND cmd /C "\"${QT_DIR}/../../../bin/windeployqt.exe\"" "--qmldir" "${CMAKE_SOURCE_DIR}" "${MY_EXECUTABLE_OUTPUT_PATH}/${CMAKE_PROJECT_NAME}.exe"
)

# # 打印所有变量 
# function(print_directory_variables dir)
#     # Dump variables:
#     get_property(_variableNames DIRECTORY ${dir} PROPERTY VARIABLES)
#     list (SORT _variableNames)
#     foreach (_variableName ${_variableNames})
#         get_directory_property(_variableValue DIRECTORY ${dir} DEFINITION ${_variableName})
#         message(STATUS "DIR ${dir}: ${_variableName}=${_variableValue}")
#     endforeach()
# endfunction(print_directory_variables)

# # for example
# print_directory_variables(.)

