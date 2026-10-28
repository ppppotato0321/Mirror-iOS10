include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Mirror

$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit CoreGraphics
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-deprecated-declarations

ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
