include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Mirror

$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit CoreGraphics
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = PhotoShop
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-deprecated-declarations

# 部署目标 iOS 10
export THEOS_CURRENT_ARCH = arm64
ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
