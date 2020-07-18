include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Selenium
$(TWEAK_NAME)_FILES = Tweak.xm cpc.m $(wildcard AXN*.m)
$(TWEAK_NAME)_FRAMEWORKS += QuartzCore WebKit MediaPlayer UIKit 
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = ControlCenterUIKit PersistentConnection
ADDITIONAL_OBJCFLAGS = -fobjc-arc -Wno-unguarded-availability-new

include $(THEOS_MAKE_PATH)/tweak.mk

#internal-stage::
#	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/Application Support/Selenium.bundle$(ECHO_END)
#	$(ECHO_NOTHING)cp -r Resources/ $(THEOS_STAGING_DIR)/Library/Application Support/Selenium.bundle/$(ECHO_END)