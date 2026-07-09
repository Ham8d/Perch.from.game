TARGET := iphone:clang:latest:14.0
ARCHS  := arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FreeIAP
FreeIAP_FILES = Tweak.xm
FreeIAP_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
FreeIAP_FRAMEWORKS = StoreKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
