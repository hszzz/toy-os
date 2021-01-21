org 0x7c00

start:				;initialize register value
	mov ax, cs
	mov ss, ax
	mov ds, ax
	mov es, ax

	mov si, msg

print:				;print character in msg one by one
	mov al, [si]	;fetch the address of the register si, which is the first byte of msg
	add si, 1
	cmp al, 0x00
	je last
	mov ah, 0x0e
	mov bx, 0x0f
	int 0x10
	jmp print

last:				;CPU stop
	hlt
	jmp last

msg:
	db 0x0a, 0x0a	;0x0a = '\n'
	db "hello toy-os"
	db 0x0a, 0x0a
	times 510-($-$$) db 0x00
	db 0x55, 0xaa

