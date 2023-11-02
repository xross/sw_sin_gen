cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_sin_gen)

set(APP_HW_TARGET XCORE-AI-MCAUDIO-600.xn )
set(APP_DEPENDENT_MODULES lib_spdif lib_adat lib_xassert)
set(APP_COMPILER_FLAGS -fcomment-asm -Wall -O3 -report -g -fxscope -DADAT_TX_USE_SHARED_BUFF=1)

set(XMOS_DEPS_ROOT_DIR ${CMAKE_SOURCE_DIR}/../../)

XMOS_REGISTER_APP()
