# Makefile initially writen for Little-Wire by Omer Kilic <omerkilic@gmail.com>
# Later on modified by ihsan Kehribar <ihsan@kehribar.me> for Micronucleus bootloader application.

#CC=gcc

ifndef TARGET_OS
ifeq ($(shell uname), Linux)
	UNAME_M := $(shell uname -m)
	ifeq ($(UNAME_M),x86_64)
		TARGET_OS := linux64
	endif
	ifeq ($(UNAME_M),i686)
		TARGET_OS := linux32
	endif
	ifeq ($(UNAME_M), $(filter $(UNAME_M),armv6l armv7l))
		TARGET_OS := linux-armhf
	endif
else ifeq ($(shell uname), Darwin)
	TARGET_OS := osx
else ifeq ($(shell uname), OpenBSD)
	TARGET_OS := openbsd
else ifeq ($(shell uname), FreeBSD)
	TARGET_OS := freebsd
else
        TARGET_OS := win32
endif
endif # TARGET_OS

ifeq ($(shell uname), Linux)
	USBFLAGS=$(shell libusb-config --cflags)
	USBLIBS=$(shell libusb-config --libs)
	EXE_SUFFIX =
	OSFLAG = -D LINUX
else ifeq ($(shell uname), Darwin)
	USBFLAGS=$(shell libusb-config --cflags || libusb-legacy-config --cflags)
	USBLIBS=$(shell libusb-config --libs || libusb-legacy-config --libs)
	EXE_SUFFIX =
	OSFLAG = -D MAC_OS
	# Uncomment these to create a static binary:
	# USBLIBS = /opt/local/lib/libusb-legacy/libusb-legacy.a
	USBLIBS += -mmacosx-version-min=10.5
	# USBLIBS += -framework CoreFoundation
	# USBLIBS += -framework IOKit
	# Uncomment these to create a dual architecture binary:
	OSFLAG += -arch x86_64 -arch i386
else ifeq ($(shell uname), OpenBSD)
	USBFLAGS=$(shell libusb-config --cflags || libusb-legacy-config --cflags)
	USBLIBS=$(shell libusb-config --libs || libusb-legacy-config --libs)
	EXE_SUFFIX =
	OSFLAG = -D OPENBSD
else ifeq ($(shell uname), FreeBSD)
	USBFLAGS=
	USBLIBS= -lusb
	EXE_SUFFIX =
	OSFLAG = -D OPENBSD
else
	USBFLAGS =
	USBLIBS = -lusb
	EXE_SUFFIX = .exe
	OSFLAG = -D WIN
endif

TARGET := micronucleus$(EXE_SUFFIX)

# OS-specific settings and build flags
ifeq ($(TARGET_OS),win32)
	ARCHIVE ?= zip
else
	ARCHIVE ?= tar
endif

# Packaging into archive (for 'dist' target)
ifeq ($(ARCHIVE), zip)
	ARCHIVE_CMD := zip -r
	ARCHIVE_EXTENSION := zip
endif
ifeq ($(ARCHIVE), tar)
	ARCHIVE_CMD := tar czf
	ARCHIVE_EXTENSION := tar.gz
endif

VERSION ?= $(shell git describe --always)

LIBS    = $(USBLIBS)
INCLUDE = library
CFLAGS  = $(USBFLAGS) -I$(INCLUDE) -O -g $(OSFLAG)

LWLIBS = micronucleus_lib littleWire_util
EXAMPLES = micronucleus

DIST_NAME := $(TARGET)-$(VERSION)-$(TARGET_OS)
DIST_DIR := $(DIST_NAME)
DIST_ARCHIVE := $(DIST_NAME).$(ARCHIVE_EXTENSION)

all: library $(TARGET)

dist: $(DIST_ARCHIVE)

$(DIST_ARCHIVE): $(LWLIBS) $(TARGET) $(DIST_DIR)
	cp $(EXAMPLES) $(DIST_DIR)/
	$(ARCHIVE_CMD) $(DIST_ARCHIVE) $(DIST_DIR)

library: $(LWLIBS)

$(LWLIBS):
	@echo Building library: $@...
	$(CC) $(CFLAGS) -c library/$@.c

$(TARGET): $(addsuffix .o, $(LWLIBS))
	@echo Building command line tool: $@...
	$(CC) $(CFLAGS) -o $@ $@.c $^ $(LIBS)
	strip $(TARGET) 2>/dev/null \
	|| $(CROSS_TRIPLE)-strip $(TARGET)

$(BUILD_DIR):
	@mkdir -p $@

$(DIST_DIR):
	@mkdir -p $@

clean:
	@rm -f *.o
	@rm -f $(TARGET)
	@rm -rf $(DIST_DIR)
	@rm -f $(DIST_ARCHIVE)

install: all
	cp micronucleus /usr/local/bin

.PHONY:	all clean dist
