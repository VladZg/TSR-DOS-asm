.286
.model tiny
locals ??
.code
org 100h

Start:  jmp Beginning
include clrs.asm
include funcs.asm
include strfuncs.asm

Beginning:
	mov ax, 0B800h
	mov es, ax

	mov si, offset Frame_Type	; frame type
	mov bh, 10d			; length
	mov bl, 12d			; height
	mov dl, 10d			; y coord
	mov dh, 25d			; x coord
	mov ah, PINK_ON_BLACK		; colour of frame
	mov al, BLACK_ON_BLACK		; colour of center
	call DrwFrm 			; DrawFrame() <-- draws frame

	mov ax, 0B800h
	mov si, 0h
	mov bx, cs
	mov di, offset buf1
	mov cx, 4000d
	call MemCpy

	call ClrScr
	
	mov ax, cs
	mov si, offset buf1
	mov bx, 0B800h
	mov di, 0h
	mov cx, 4000d
	call MemCpy

	EXIT

text		db "TEST TEXT... Aboba!?"
AX_Value:	db 4 dup (?), "$"
Frame_Type	db	LEFT_UP_BRACKET, UP_BRACKET, RIGHT_UP_BRACKET, LEFT_BRACKET, BOX_PATTERN, RIGHT_BRACKET, LEFT_BOTTOM_BRACKET, BOTTOM_BRACKET, RIGHT_BOTTOM_BRACKET

buf1		db	4000 dup (?)
buf2		db	4000 dup (?)
end Start