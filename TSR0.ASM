.model tiny
locals ??
.code
org 100h

start:		jmp main

new28	proc
	push ax bx es di si ds

	mov ax, 0B800h
	mov es, ax 

	mov ax, cs
	mov ds, ax

	mov di, offset msg1
	mov ah, 5Fh
	mov dh, 3d
	mov dl, 3d
	call Printf

	pop ds si di es bx ax
        db 0eah                 ; call Last ISR
OldISR  dd 0bad0badh
        endp         

msg1:			db 	"message!!!", "$"

include clrs.asm
include funcs.asm
include strfuncs.asm
;-------------------------------------------------------------------------;
main:		.386

                mov ax, 0
                mov ds, ax
                mov si, 28h*4
                mov ax, cs
                mov es, ax
                mov di, offset OldISR
                movsd

                mov ax, 0             
                mov ds, ax
                mov bx, 28h*4

                mov ax, offset new28 
                mov [bx], ax
                mov ax, es
                mov [bx+2], es

                mov dx, offset main
                shr dx, 4
                inc dx
                mov ax, 3100h
                int 21h
end start