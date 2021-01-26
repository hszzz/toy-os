org 0x9000

begin:
	mov si, msg

print:
	mov al, [si]
	add si, 1
	cmp al, 0x00
	je end
	mov ah, 0x0e
	mov bx, 0x0f
	int 0x10
	jmp print

end:
	hlt
	jmp end

msg:
	db 0x0a, 0x0a
	db "hello os!"
	db 0x0a, 0x0a
	db 0x00

