cmake_minimum_required(VERSION 3.18)
project(wxapp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

# Raiz wxWidgets Android
set(WX_ROOT "${WX_ANDROID_ROOT}/${ANDROID_ABI}/usr")
set(WX_CONFIG "${WX_ROOT}/bin/wx-config")
set(WX_LIB_DIR "${WX_ROOT}/lib")

if(NOT EXISTS "${WX_CONFIG}")
    message(FATAL_ERROR "wx-config não encontrado em ${WX_CONFIG}")
endif()

message(STATUS "WX_CONFIG  = ${WX_CONFIG}")
message(STATUS "WX_LIB_DIR = ${WX_LIB_DIR}")

# Obter CFLAGS do wxWidgets
execute_process(
    COMMAND ${WX_CONFIG} --cflags
    OUTPUT_VARIABLE WX_CFLAGS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Obter LIBS do wxWidgets (apenas para debug/informação)
execute_process(
    COMMAND ${WX_CONFIG} --libs std,qt
    OUTPUT_VARIABLE WX_LIBS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

message(STATUS "WX_CFLAGS = ${WX_CFLAGS}")
message(STATUS "WX_LIBS (info) = ${WX_LIBS}")

# Descobrir TODAS as libs wxWidgets com o sufixo correto (_arm64-v8a)
file(GLOB WX_LIBS_FULL "${WX_LIB_DIR}/libwx_*.so")

if(NOT WX_LIBS_FULL)
    message(FATAL_ERROR "Nenhuma libwx_*.so encontrada em ${WX_LIB_DIR}")
endif()

message(STATUS "WX_LIBS_FULL = ${WX_LIBS_FULL}")

# Biblioteca compartilhada
add_library(wxapp SHARED
    wx_app.cpp
    wx_jni.cpp
)

# Definições e flags
target_compile_definitions(wxapp PRIVATE __WXQT__)
separate_arguments(WX_CFLAGS_LIST UNIX_COMMAND "${WX_CFLAGS}")
target_compile_options(wxapp PRIVATE ${WX_CFLAGS_LIST})

# Link com TODAS as libs wxWidgets encontradas (caminho completo)
target_link_libraries(wxapp PRIVATE
    ${WX_LIBS_FULL}
    log
)
