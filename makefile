.PONY : all clean rebuild

BOOT_SRC := boot.asm
BOOT_OUT := boot

LOADER_SRC := loader.asm
LOADER_OUT := loader

IMG := data.img
IMG_PATH := /mnt/

RM := rm -rf

all : $(IMG) $(BOOT_OUT) $(LOADER_OUT)
	@echo "success"

$(IMG) :
	bximage $@ -q -fd -size=1.44

$(BOOT_OUT) : $(BOOT_SRC)
	nasm $^ -o $@
	dd if=$@ of=$(IMG) bs=512 count=1 conv=notrunc

$(LOADER_OUT) : $(LOADER_SRC)
	nasm $^ -o $@
	sudo mount -o loop $(IMG) $(IMG_PATH)
	sudo cp $@ $(IMG_PATH)/$@
	sudo umount $(IMG_PATH)

clean:
	$(RM) $(IMG) $(BOOT_OUT) $(LOADER_OUT)

rebuild:
	@$(MAKE) clean
	@$(MAKE) all

