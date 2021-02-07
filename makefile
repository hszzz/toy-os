.PHONY : all clean rebuild

BOOT_SRC := boot.asm
BOOT_OUT := boot

LOADER_SRC := loader.asm
LOADER_INC := inc.asm
LOADER_OUT := loader

IMG := data.img
IMG_PATH := /mnt/hgfs

LOG_PATH := log
BOCHS := bochs
MKDIR := mkdir

REVERSE_PATH := reverse

RM := rm -fr

all : $(IMG) $(BOOT_OUT) $(LOADER_OUT)
	@echo "build success"

$(IMG) :
	bximage $@ -q -fd -size=1.44
	
$(BOOT_OUT) : $(BOOT_SRC)
	nasm $^ -o $@
	dd if=$@ of=$(IMG) bs=512 count=1 conv=notrunc
	
$(LOADER_OUT) : $(LOADER_SRC) $(LOADER_INC)
	nasm $< -o $@
	sudo mount -o loop $(IMG) $(IMG_PATH)
	sudo cp $@ $(IMG_PATH)/$@
	sudo umount $(IMG_PATH)
	
clean :
	$(RM) $(IMG) $(BOOT_OUT) $(LOADER_OUT)
	$(RM) $(LOG_PATH)
	$(RM) $(REVERSE_PATH)
	
rebuild :
	@$(MAKE) clean
	@$(MAKE) all

bochs : all
	$(MKDIR) $(LOG_PATH)
	$(BOCHS) -q -f .bochsrc -log log/bochs.log

reverse : $(LOADER_OUT)
	$(MKDIR) $(REVERSE_PATH)
	@ndisasm -o 0x9000 $< > $(REVERSE_PATH)/reverse.txt
