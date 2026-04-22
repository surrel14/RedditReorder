TARGET := iphone:clang:latest:14.0
ARCHS = arm64

INSTALL_TARGET_PROCESSES = RedditApp

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RedditTabOrder

RedditTabOrder_FILES = Tweak.xm
RedditTabOrder_CFLAGS = -fobjc-arc
RedditTabOrder_FRAMEWORKS = UIKit Foundation WebKit

include $(THEOS_MAKE_PATH)/tweak.mk
