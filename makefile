.PHONY : all clean rebuild

IMAGE := toy-os
IMAGE_PATH := /mnt/hgfs

AS := nasm
CC := gcc
LD := ld

MKDIR := mkdir
CP    := cp
RM    := rm -rf

BOCHS    := bochs
BOCHSRC  := .bochsrc
BOCHSLOG := bochs.log

CFLAGS := -m32 -O0 -Wall -Werror -nostdinc -fno-builtin -fno-stack-protector \
		-funsigned-char -finline-functions -finline-small-functions \
		-findirect-inlining -finline-functions-called-once \
		-ggdb -gstabs+ -fdump-rtl-expand -I./kernel -I./include -I./usr

LD_SCRIPT_KERNEL := -T./scripts/kernel.lds
LD_SCRIPT_APP    := -T./scripts/app.lds

BOOT_SRC   := bl/boot.asm
LOADER_SRC := bl/loader.asm
BLFUNC_SRC := bl/blfunc.asm
COMMON_SRC := bl/common.asm
KENTRY_SRC := kernel/kentry.asm

BUILD_DIR  := build

KERNEL_ELF := $(BUILD_DIR)/kernel.out
BOOT_OUT   := $(BUILD_DIR)/boot
LOADER_OUT := $(BUILD_DIR)/loader
KERNEL_OUT := $(BUILD_DIR)/kernel
KENTRY_OUT := $(BUILD_DIR)/kentry.o

KERNEL_OBJS := $(BUILD_DIR)/kmain.o \
	$(BUILD_DIR)/kprint.o \
	$(BUILD_DIR)/kernel.o \
	$(BUILD_DIR)/interrupt.o \
	$(BUILD_DIR)/task.o \
	$(BUILD_DIR)/utility.o \
	$(BUILD_DIR)/ihandler.o \
	$(BUILD_DIR)/list.o \
	$(BUILD_DIR)/queue.o \
	$(BUILD_DIR)/syscall.o \
	$(BUILD_DIR)/app.o

APP_ENTRY_SRC := kernel/aentry.asm
APP_ENTRY_OUT := $(BUILD_DIR)/aentry.o

APP_ELF  := $(BUILD_DIR)/app.out
APP_OUT  := $(BUILD_DIR)/app
APP_OBJS := $(BUILD_DIR)/kprint.o  \
			$(BUILD_DIR)/utility.o \
			$(BUILD_DIR)/app.o

all : $(BUILD_DIR) $(IMAGE) $(BOOT_OUT) $(LOADER_OUT) $(KERNEL_OUT) $(APP_OUT)
	
$(IMAGE) :
	bximage $@ -q -fd -size=1.44

$(BOOT_OUT) : $(BOOT_SRC) $(BLFUNC_SRC)
	$(AS) -I./bl/ -f bin $< -o $@
	dd if=$@ of=$(IMAGE) bs=512 count=1 conv=notrunc

$(LOADER_OUT) : $(LOADER_SRC) $(COMMON_SRC) $(BLFUNC_SRC)
	$(AS) -I./bl/ -f bin $< -o $@
	sudo mount -o loop $(IMAGE) $(IMAGE_PATH)
	sudo cp $@ $(IMAGE_PATH)/loader
	sudo umount $(IMAGE_PATH)
	
$(KENTRY_OUT) : $(KENTRY_SRC) $(COMMON_SRC)
	$(AS) -I./bl/ -f elf32 $< -o $@

$(BUILD_DIR) : 
	@$(MKDIR) $@

$(KERNEL_OUT) : $(KERNEL_ELF)
	objcopy -O binary $< $@
	sudo mount -o loop $(IMAGE) $(IMAGE_PATH)
	sudo cp $@ $(IMAGE_PATH)/kernel
	sudo umount $(IMAGE_PATH)
	
$(BUILD_DIR)/%.o : */%.c
	$(CC) $(CFLAGS) -o $@ -c $(filter %.c, $^)

$(KERNEL_ELF) : $(KENTRY_OUT) $(KERNEL_OBJS)
	$(LD) $(LD_SCRIPT_KERNEL) -m elf_i386 -s $^ -o $@

$(APP_ENTRY_OUT) : $(APP_ENTRY_SRC) $(COMMON_SRC)
	$(AS) -I./bl/ -f elf32 $< -o $@

$(APP_ELF) : $(APP_ENTRY_OUT) $(APP_OBJS)
	$(LD) $(LD_SCRIPT_APP) -m elf_i386 -s $^ -o $@

$(APP_OUT) : $(APP_ELF)
	objcopy -O binary $< $@
	sudo mount -o loop $(IMAGE) $(IMAGE_PATH)
	sudo cp $@ $(IMAGE_PATH)/app
	sudo umount $(IMAGE_PATH)

rebuild :
	$(MAKE) clean
	$(MAKE) all

clean :
	$(RM) $(BUILD_DIR) $(IMAGE) $(BOCHSLOG)

bochs : all
	$(BOCHS) -q -f $(BOCHSRC) -log $(BOCHSLOG)
