export ARCHS = armv7 arm64
export TARGET = iphone:clang:8.1:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Force3DAppShortcuts
Force3DAppShortcuts_FILES = Tweak.xm
Force3DAppShortcuts_FRAMEWORKS = UIKit AudioToolbox CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += force3dappshortcuts
include $(THEOS_MAKE_PATH)/aggregate.mk
