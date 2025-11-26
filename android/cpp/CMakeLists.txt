cmake_minimum_required(VERSION 3.10)
project(wxapp LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_library(LOG_LIB log)

# Caminho para seu prefixo wxWidgets Android
set(WX_ROOT "$ENV{HOME}/wx/android-wx-3.2.4/arm64-v8a/usr")

include_directories(${WX_ROOT}/include)

link_directories(${WX_ROOT}/lib)

add_library(wxapp SHARED wx_jni.cpp wx_app.cpp)

target_link_libraries(wxapp ${LOG_LIB} wx_baseu-3.2 wx_qtu_core-3.2 c++_shared)
