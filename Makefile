ARCHS=armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = TimeCode
TimeCode_FILES = Tweak.xm
TimeCode_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += timecode
include $(THEOS_MAKE_PATH)/aggregate.mk
