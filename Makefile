TARGET := iphone:clang:latest:13.0
ARCHS  := arm64 arm64e

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FreeIAP

FreeIAP_FILES = Tweak.m
FreeIAP_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
FreeIAP_FRAMEWORKS = StoreKit Foundation UIKit
FreeIAP_LDFLAGS = -Wl,-not_for_dyld_shared_cache

include $(THEOS_MAKE_PATH)/library.mk
