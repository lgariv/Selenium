include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Selenium
$(TWEAK_NAME)_FILES = Tweak.xm $(wildcard AXN*.m)
$(TWEAK_NAME)_FRAMEWORKS += QuartzCore WebKit MediaPlayer UIKit CoreLocation MapKit Contacts
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = ControlCenterUIKit PersistentConnection BulletinBoard #WorkflowUI
ADDITIONAL_OBJCFLAGS += -fobjc-arc -Wno-unguarded-availability-new -w -fdiagnostics-absolute-paths

include $(THEOS_MAKE_PATH)/tweak.mk
