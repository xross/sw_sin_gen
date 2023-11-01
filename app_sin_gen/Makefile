# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.
TARGET = XCORE-AI-MCAUDIO-600.xn
APP_NAME =

# The flags passed to xcc when building the application
XCC_FLAGS    = -fcomment-asm -Wall -O3 -report -g -fxscope -DADAT_TX_USE_SHARED_BUFF=1



# The USED_MODULES variable lists other module used by the application. These
# modules will extend the SOURCE_DIRS, INCLUDE_DIRS and LIB_DIRS variables.
# Modules are expected to be in the directory above the BASE_DIR directory.
USED_MODULES = lib_spdif lib_adat lib_xassert

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
