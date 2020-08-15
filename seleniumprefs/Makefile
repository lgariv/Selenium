include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SeleniumPrefs

SeleniumPrefs_FILES = SLNMPRootListController.m
SeleniumPrefs_FRAMEWORKS = UIKit
SeleniumPrefs_PRIVATE_FRAMEWORKS = Preferences
SeleniumPrefs_EXTRA_FRAMEWORKS += Cephei CepheiPrefs
SeleniumPrefs_INSTALL_PATH = /Library/PreferenceBundles
SeleniumPrefs_CFLAGS = -fobjc-arc
ADDITIONAL_OBJCFLAGS = -fobjc-arc -Wno-unguarded-availability-new -w -fdiagnostics-absolute-paths

include $(THEOS_MAKE_PATH)/bundle.mk
