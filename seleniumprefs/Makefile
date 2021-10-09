include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SeleniumPrefs

SeleniumPrefs_FILES = SLNMPRootListController.m
SeleniumPrefs_FRAMEWORKS = UIKit
SeleniumPrefs_PRIVATE_FRAMEWORKS = Preferences
SeleniumPrefs_EXTRA_FRAMEWORKS += Cephei CepheiPrefs
SeleniumPrefs_INSTALL_PATH = /Library/PreferenceBundles
SeleniumPrefs_CFLAGS = -fobjc-arc -Wno-unguarded-availability-new -w -fdiagnostics-absolute-paths

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SeleniumPrefs.plist$(ECHO_END)
