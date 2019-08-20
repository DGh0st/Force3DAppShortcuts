include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Force3DAppShortcuts
Force3DAppShortcuts_FILES = FASRootListController.m
Force3DAppShortcuts_INSTALL_PATH = /Library/PreferenceBundles
Force3DAppShortcuts_FRAMEWORKS = UIKit MessageUI
Force3DAppShortcuts_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Force3DAppShortcuts.plist$(ECHO_END)
