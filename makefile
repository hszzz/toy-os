.PHONY : all clean

IMAGE := toy-os
IMAGE_PATH := /mnt/hgfs

AS := nasm
CC := gcc
LD := ld

MKDIR := mkdir
CP    := cp
RM    := rm -rf

CFLAGS := -m32 -O0 -Wall -Werror -nostdinc -fno-builtin -fno-stack-protector \
	-funsigned-char -finline-functions -finline-small-functions \
	-findirect-inlining -finline-functions-called-once \
	-ggdb -gstabs+ -fdump-rtl-expand

LD_SCRIPT  := scripts/link.lds

BOOT_SRC   := bl/boot.asm
LOADER_SRC := bl/loader.asm
BLFUNC_SRC := bl/blfunc.asm
COMMON_SRC := bl/common.asm

BUILD_DIR  := build

BOOT_OUT   := $(BUILD_DIR)/boot
LOADER_OUT := $(BUILD_DIR)/loader
KERNEL_OUT := $(BUILD_DIR)/kernel

all : $(BUILD_DIR) $(IMAGE)

$(BOOT_OUT) : $(BOOT_SRC) $(BLFUNC_SRC)
	@echo "build boot ..."
	$(AS) -I ./bl/ -f bin $< -o $@ 

$(LOADER_OUT) : $(LOADER_SRC) $(BLFUNC_SRC) $(COMMON_SRC)
	@echo "build loader ..."
	$(AS) -I ./bl/ -f bin $< -o $@

$(IMAGE) : $(BOOT_OUT) $(LOADER_OUT)
	@echo "create os image ..."
	bximage $@ -q -fd -size=1.44
	@echo "create MBR ..."
	dd if=$(BOOT_OUT) of=$@ bs=512 count=1 conv=notrunc
	sudo mount -o loop $(IMAGE) $(IMAGE_PATH)
	@echo "copy loader to image"
	sudo cp $(LOADER_OUT) $(IMAGE_PATH)/$(LOADER_OUT)
	sudo umount $(IMAGE_PATH)

$(BUILD_DIR) : 
	@$(MKDIR) $@

clean :
	@$(RM) $(BUILD_DIR)

