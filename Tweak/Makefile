include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e 
TWEAK_NAME = Axon
$(TWEAK_NAME)_FILES = Tweak.xm $(wildcard AXN*.m)
$(TWEAK_NAME)_FRAMEWORKS += QuartzCore WebKit MediaPlayer UIKit
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = ControlCenterUIKit PersistentConnection
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/var/mobile/Library/Snoozer$(ECHO_END)
	$(ECHO_NOTHING) if [ -f $(THEOS_STAGING_DIR)/var/mobile/Library/Snoozer/config.plist ] ; then cp config.plist $(THEOS_STAGING_DIR)/var/mobile/Library/Snoozer/config.plist ; fi $(ECHO_END)