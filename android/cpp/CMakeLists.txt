cmake_minimum_required(VERSION 3.18)
project(wxapp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

# Raiz wxWidgets Android arm64-v8a
set(WX_ROOT "${WX_ANDROID_ROOT}/${ANDROID_ABI}/usr")
set(WX_CONFIG "${WX_ROOT}/bin/wx-config")

# Obter flags do wxWidgets
execute_process(
    COMMAND ${WX_CONFIG} --cflags
    OUTPUT_VARIABLE WX_CFLAGS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
    COMMAND ${WX_CONFIG} --libs
    OUTPUT_VARIABLE WX_LIBS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Biblioteca compartilhada
add_library(wxapp SHARED
    wx_app.cpp
    wx_jni.cpp
)

# Definições e flags
target_compile_definitions(wxapp PRIVATE __WXQT__)
separate_arguments(WX_CFLAGS_LIST UNIX_COMMAND "${WX_CFLAGS}")
target_compile_options(wxapp PRIVATE ${WX_CFLAGS_LIST})

# Link wxWidgets e log
separate_arguments(WX_LIBS_LIST UNIX_COMMAND "${WX_LIBS}")
target_link_libraries(wxapp PRIVATE
    ${WX_LIBS_LIST}
    log
)

# # Link wxWidgets e log
# target_link_libraries(
#   wxapp PRIVATE ${WX_ROOT}/lib/libwx_qtu_core-3.2-Android_arm64-v8a.so
#                 ${WX_ROOT}/lib/libwx_baseu-3.2-Android_arm64-v8a.so log)
