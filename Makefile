FW_DEVICE_IP=192.168.1.106

include theos/makefiles/common.mk

TWEAK_NAME = GameSolver
GameSolver_FILES = ActivatorListener.mm CaptureMyScreen.m BoardSolver.m FakeTouch.mm
GameSolver_FRAMEWORKS = QuartzCore UIKit CoreGraphics
GameSolver_PRIVATE_FRAMEWORKS = IOSurface IOMobileFramebuffer IOKit
GameSolver_LDFLAGS = -lactivator -lrocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk

# after-install::
# 	install.exec "killall -9 SpringBoard"
