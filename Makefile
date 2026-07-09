TARGET := iphone:clang:latest:12.0
ARCHS  := arm64 arm64e

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FreeIAP

FreeIAP_FILES = Tweak.x
FreeIAP_CFLAGS = -fobjc-arc
FreeIAP_FRAMEWORKS = StoreKit Foundation UIKit
FreeIAP_LDFLAGS = -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/library.mk
