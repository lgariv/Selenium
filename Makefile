INSTALL_TARGET_PROCESSES = SpringBoard
export GO_EASY_ON_ME = 1

export ARCHS = arm64 arm64e
export TARGET = iphone:clang:13.5:11.0

export PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk
SUBPROJECTS += Tweak #Prefs
SUBPROJECTS += seleniumprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
