cmake_minimum_required(VERSION 3.10)
project(wxapp_android)

set(CMAKE_CXX_STANDARD 17)

# =====================================================
# Caminhos para wxWidgets Android (WX_ANDROID_ROOT e ANDROID_ABI vêm do
# Makefile)
# =====================================================
set(WX_SYSROOT "${WX_ANDROID_ROOT}/${ANDROID_ABI}/usr")
set(WX_CONFIG "${WX_SYSROOT}/bin/wx-config")
set(WX_LIB_DIR "${WX_SYSROOT}/lib")

if(NOT EXISTS "${WX_CONFIG}")
  message(FATAL_ERROR "wx-config não encontrado em ${WX_CONFIG}")
endif()

message(STATUS "WX_CONFIG  = ${WX_CONFIG}")
message(STATUS "WX_SYSROOT = ${WX_SYSROOT}")
message(STATUS "WX_LIB_DIR = ${WX_LIB_DIR}")

# =====================================================
# 1) Pega CXXFLAGS do wx-config (includes + defines)
# =====================================================
execute_process(
  COMMAND ${WX_CONFIG} --cxxflags
  OUTPUT_VARIABLE WX_CXXFLAGS_RAW
  OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "WX_CXXFLAGS_RAW = ${WX_CXXFLAGS_RAW}")

separate_arguments(WX_CXXFLAGS_RAW)

set(WX_INCLUDES "")
set(WX_DEFINES "")
set(WX_OTHER_CFLAGS "")

foreach(flag ${WX_CXXFLAGS_RAW})
  if(flag MATCHES "^-I")
    string(SUBSTRING ${flag} 2 -1 INC)
    list(APPEND WX_INCLUDES "${INC}")
  elseif(flag MATCHES "^-D")
    string(SUBSTRING ${flag} 2 -1 DEF)
    list(APPEND WX_DEFINES "${DEF}")
  else()
    list(APPEND WX_OTHER_CFLAGS "${flag}")
  endif()
endforeach()

message(STATUS "WX_INCLUDES      = ${WX_INCLUDES}")
message(STATUS "WX_DEFINES       = ${WX_DEFINES}")
message(STATUS "WX_OTHER_CFLAGS  = ${WX_OTHER_CFLAGS}")

# =====================================================
# 2) Descobre TODAS as libs wxWidgets disponíveis e linka todas. Assim não falta
# nada (assert, etc).
# =====================================================
file(GLOB WX_LIBS_FULL "${WX_LIB_DIR}/libwx_*.so")

if(NOT WX_LIBS_FULL)
  message(FATAL_ERROR "Nenhuma libwx_*.so encontrada em ${WX_LIB_DIR}")
endif()

message(STATUS "WX_LIBS_FULL = ${WX_LIBS_FULL}")

# =====================================================
# 3) Biblioteca nativa que o Android vai carregar
# =====================================================
add_library(wxapp SHARED wx_app.cpp wx_jni.cpp)

# Includes / defines / flags do wx
target_include_directories(wxapp PRIVATE ${WX_INCLUDES})

# Aqui desliga as asserts do wx para evitar referências a wxTrap/wxOnAssert/etc
target_compile_definitions(wxapp PRIVATE ${WX_DEFINES} wxDEBUG_LEVEL=0 NDEBUG)

target_compile_options(wxapp PRIVATE ${WX_OTHER_CFLAGS})

target_link_libraries(wxapp PRIVATE ${WX_LIBS_FULL} log)
