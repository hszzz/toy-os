org 0x7c00

start:
	mov ax, cs
	mov ss, ax
	mov ds, ax
	mov es, ax

	mov si, msg

print:
	mov al, [si]
	add si, 1
	cmp al, 0x00
	je last
	mov ah, 0x0e
	mov bx, 0x0f
	int 0x10
	jmp print

last:
	hlt
	jmp last

msg:
	db 0x0a, 0x0a
	db "hello toy-os"
	db 0x0a, 0x0a
	times 510-($-$$) db 0x00
	db 0x55, 0xaa

