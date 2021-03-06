.SUFFIXES:

CC ?= gcc

CONFIG_MAK := Config.mak
include Config.mak
-include Config.local.mak

GCC := $(CROSS_COMPILE)$(CC)
TAR := tar

EXTRA_DEFS := -D_FILE_OFFSET_BITS=64 -DHAVE_ACCEPT4=1
CFLAGS := -g -pipe -O2 -Wall \
	-Wsign-compare -Wcast-align \
	-Waggregate-return \
	-Wstrict-prototypes \
	-Wmissing-prototypes \
	-Wmissing-declarations \
	-Wmissing-noreturn \
	-finline-functions \
	-Wmissing-format-attribute \
	-Wno-cast-align \
	-fwrapv \
	-Iinclude \
	-I/usr/include \
	$(SDL_CFLAGS) \
	$(EXTRA_DEFS)

ENGINE_OBJ := r_gl.o \
		r_light.o \
		r_shader.o \
		particles.o \
		img_png.o \
		asset.o \
		asset_render.o \
		tile.o \
		tile_render.o \
		font.o \
		map.o \
		tex.o \
		vec.o \
		game.o \
		hgang.o \
		console.o \
		cvar.o \
		cmd.o \
		blob.o

ENGINE_LIBS := $(SDL_LIBS) $(GL_LIBS) $(MATH_LIBS) $(PNG_LIBS)
ifeq ($(OS), win32)
# on windows sdl-config --cflags includes -Dmain=SDL_main
APP_LIBS := $(ENGINE_LIBS)
else
APP_LIBS := $(MATH_LIBS)
endif

DS_BIN := dessert-stroke$(SUFFIX)
DS_OBJ := dessert-stroke.o \
		world.o \
		chopper.o \
		missile.o \
		entity.o \
		lobby.o \
		$(ENGINE_OBJ)

SPANK_BIN := spankassets$(SUFFIX)
SPANK_OBJ := spankassets.o \
		hgang.o

MKTILE_BIN := mktile$(SUFFIX)
MKTILE_OBJ := mktile.o

MKMAP_BIN := mkmap$(SUFFIX)
MKMAP_OBJ := mkmap.o

DISTRIB_TAR := ds3d.tar.gz
DISTRIB_ZIP := ds3d.zip

ALL_BIN := $(DS_BIN) $(SPANK_BIN) $(MKTILE_BIN) $(MKMAP_BIN)
ALL_OBJ := $(DS_OBJ) $(SPANK_OBJ) $(MKTILE_OBJ) $(MKMAP_OBJ)
ALL_DEP := $(patsubst %.o, .%.d, $(ALL_OBJ))
ALL_TARGETS := $(ALL_BIN)

DATA_DIR := data
ART_SDK_DIR := ds3d-artsdk
WINDOWS_ART_PS1 := mkdata.ps1
ART_SDK_BIN := $(ALL_BIN) \
		$(WINDOWS_ART_PS1) \
		mkfont.py \
		obj2asset.py
ART_SDK_ASSETS := $(DATA_DIR)/splash.png \
		$(DATA_DIR)/font/carbon.png \
		assets/* \
		tiles/* \
		maps/* \
		chopper/* \
		carbon.ttf

TARGET: all

.PHONY: all clean walk tarball zip art_sdk

all: $(ALL_BIN)

ifeq ($(filter clean, $(MAKECMDGOALS)),clean)
CLEAN_DEP := clean
else
CLEAN_DEP :=
endif

%.o %.d: %.c $(CLEAN_DEP) $(CONFIG_MAK) Makefile
	@echo " [C] $<"
	@$(GCC) $(CFLAGS) -MMD -MF $(patsubst %.o, .%.d, $@) \
		-MT $(patsubst .%.d, %.o, $@) \
		-c -o $(patsubst .%.d, %.o, $@) $<

$(DS_BIN): $(DS_OBJ)
	@echo " [LINK] $@"
	@$(GCC) $(CFLAGS) -o $@ $(DS_OBJ) $(ENGINE_LIBS)

$(SPANK_BIN): $(SPANK_OBJ)
	@echo " [LINK] $@"
	@$(GCC) $(CFLAGS) -o $@ $(SPANK_OBJ) $(APP_LIBS)

$(MKTILE_BIN): $(MKTILE_OBJ)
	@echo " [LINK] $@"
	@$(GCC) $(CFLAGS) -o $@ $(MKTILE_OBJ) $(APP_LIBS)

$(MKMAP_BIN): $(MKMAP_OBJ)
	@echo " [LINK] $@"
	@$(GCC) $(CFLAGS) -o $@ $(MKMAP_OBJ) $(APP_LIBS)


tarball: $(DISTRIB_TAR)
$(DISTRIB_TAR): $(DS_BIN)
	@echo " [TARBALL] $@"
	@(cd ../; $(TAR) -czf \
		$(shell basename "${PWD}")/$(DISTRIB_TAR) \
		$(patsubst %, $(shell basename "${PWD}")/%, $(DS_BIN) data))

zip: $(DISTRIB_ZIP)
$(DISTRIB_ZIP): $(DS_BIN)
	@echo " [ZIP] $@"
	(cd ../; zip -qr $(shell basename "${PWD}")/$(DISTRIB_ZIP) \
		$(patsubst %, $(shell basename "${PWD}")/%, $(DS_BIN) data) \
		$(DISTRIB_ZIP_EXTRAS) )

art_sdk: $(ART_SDK_BIN) $(ART_SDK_ASSETS)
	@echo " [CLEAN]"
	@(rm -rf $(ART_SDK_DIR))
	@echo " [MKDIR]"
	@mkdir $(ART_SDK_DIR) $(ART_SDK_DIR)/$(DATA_DIR)
	@echo " [COPY]"
	@(cp -a $(ART_SDK_BIN) $(ART_SDK_DIR))
	-@(cp -a $(ART_SDK_EXTRAS) $(ART_SDK_DIR))
	@$(foreach asset,$(ART_SDK_ASSETS), mkdir -p $(dir $(ART_SDK_DIR)/$(asset));)
	@$(foreach asset,$(ART_SDK_ASSETS), cp -a $(asset) $(dir $(ART_SDK_DIR)/$(asset));)
	@echo " [STRIP]"
	@(strip $(patsubst %,$(ART_SDK_DIR)/%, $(ALL_BIN)))
	@echo " [ZIP]"
	@rm -f $(ART_SDK_DIR).zip
	@zip -qr $(ART_SDK_DIR).zip $(ART_SDK_DIR)
	@echo " [TARBALL]"
	@tar zcf $(ART_SDK_DIR).tar.gz $(ART_SDK_DIR)
		
clean:
	rm -f $(ALL_TARGETS) $(ALL_OBJ) $(ALL_DEP)

run: $(DS_BIN)
	$(DS_BIN)

ifneq ($(MAKECMDGOALS),clean)
-include $(ALL_DEP)
endif
