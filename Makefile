#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

export TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

NAME 		:= itemKiller
ABOUT 		:= $(NAME)

ifeq ($(strip $(PLGNAME)),)
PLGNAME		:=	$(NAME)
endif

TARGET		:= 	$(notdir $(CURDIR))

MAX			:=	5
JOBS		:=	$(shell nproc)
JOBS		:=	$(if $(shell [ $(JOBS) -gt $(MAX) ] && echo 1),$(MAX),$(JOBS))

CTRPFLIB	:=	$(DEVKITPRO)/libctrpf
PLGINFO 	:= 	ctrpf.plgInfo

BUILD		:= 	build
DEBUG		:=	debug

INCLUDES	:= 	include \
				vendor/glaze/include \
				vendor/magic_enum/include \
				vendor/mk7-memory/include \
				vendor/mk7-memory/vendor/lms/Include \
				vendor/mk7-memory/vendor/nnheaders/include \
				vendor/mk7-memory/vendor/nw4c/include \
				vendor/mk7-memory/vendor/sead/include

SOURCES 	:= 	src \
				src/base \
				src/base/hook_types \
				src/base/features \
				src/base/hooks \
				src/base/entries \
				src/base/memory \
				src/base/sead \
				src/base/sead/StringUtil \
				vendor/mk7-memory/vendor/sead/modules/src/container \
				vendor/mk7-memory/vendor/sead/modules/src/gfx \
				vendor/mk7-memory/vendor/sead/modules/src/math \
				vendor/mk7-memory/vendor/sead/modules/src/prim \
				vendor/mk7-memory/vendor/sead/modules/src/random
				
FILTERS 	:=	seadBitFlag.cpp \
				seadBoundBox.cpp \
				seadBitCamera.cpp \
				seadDrawLockContext.cpp \
				seadEndian.cpp \
				seadEnum.cpp \
				seadFrameBuffer.cpp \
				seadListImpl.cpp \
				seadMatrix.cpp \
				seadMemUtil.cpp \
				seadPrimitiveRenderer.cpp \
				seadPrimitiveRendererUtil.cpp \
				seadProjection.cpp \
				seadQuat.cpp \
				seadStringBuilder.cpp \
				seadStringUtil.cpp \
				seadTreeNode.cpp \
				seadSafeString.cpp

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
DEFINES 	:=	-D__3DS__ -DNNSDK -DMAGIC_ENUM_RANGE_MIN=0 -DMAGIC_ENUM_RANGE_MAX=255 \
				-DNAME="\"$(NAME)\"" -DABOUT="\"$(ABOUT)\""

ARCH		:=	-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft

CFLAGS		:=	$(ARCH) -Os -mword-relocations -fomit-frame-pointer -ffunction-sections -fno-strict-aliasing -Wno-invalid-offsetof -Wno-deprecated-declarations

CFLAGS		+=	$(INCLUDE) $(DEFINES)

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -Wno-psabi -std=gnu++23 -fshort-wchar

ASFLAGS		:=	$(ARCH)
LDFLAGS		:= -T $(TOPDIR)/3gx.ld $(ARCH) -Os -fno-lto -Wl,--gc-sections,--strip-discarded,--strip-debug,--no-wchar-size-warning

LIBS		:=	-lctrpf -lctru
LIBDIRS		:= 	$(CTRPFLIB) $(CTRULIB) $(PORTLIBS)

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(PLGNAME)
export TOPDIR	:=	$(CURDIR)
export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
					$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES		:=	$(filter-out $(FILTERS), $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp))))
SFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

export LD 		:= 	$(CXX)
export OFILES	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir) ) \
					$(foreach dir,$(LIBDIRS),-I $(dir)/include) \
					-I $(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L $(dir)/lib)

.PHONY: $(BUILD) clean all

#---------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD): create_headers
	@rm -fr $(DEBUG) *.3gx
	@mkdir -p $(DEBUG)
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --jobs=$(JOBS) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

create_headers: fetch_updates
	@$(MAKE) --jobs=$(JOBS) --no-print-directory -C $(CURDIR)/vendor/mk7-memory -s

fetch_updates:
	@git submodule foreach 'git pull && git submodule update --init --recursive'

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(DEBUG) *.3gx

re: clean all

#---------------------------------------------------------------------------------

else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
$(OUTPUT).3gx : $(OUTPUT).elf
$(OUTPUT).elf : $(OFILES)

#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
%.bin.o	:	%.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
%.3gx: %.elf
#---------------------------------------------------------------------------------
	@echo creating $(notdir $@)
	@3gxtool -d -s $(word 1, $^) $(TOPDIR)/$(PLGINFO) $@
	@-mv $(TOPDIR)/$(BUILD)/*.lst $(TOPDIR)/$(DEBUG)/
	@-mv $(TOPDIR)/*.elf $(TOPDIR)/$(DEBUG)/
	@echo $(PLGNAME).3gx successfully created!

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------