.286
.model tiny
locals ??
.code
org 100h

Start: jmp Init
;------------------------------------------------
; Resident body
;------------------------------------------------
New09	proc
	push ax bx es ds

	mov bx, 0B800h			; start of video memory segment
	mov es, bx			; es = VideoSeg

	cmp al, 2d			; al == <1>
	jne Exit_Key
	
	mov ax, cs
	mov ds, ax

	mov di, offset msg
	mov ah, 5Fh
	mov dh, 1d
	mov dl, 1d
	call Printf
	
	jmp Not_hot_key	

Exit_Key:
	cmp al, 3d			; al == <2>
	jne Not_hot_key

	mov ax, cs
	mov ds, ax
	mov di, offset empty_msg
	mov ah, 00h
	mov dh, 1d
	mov dl, 1d
	call Printf

Not_hot_key:	
	in al, 61h
	or al, 80h
	out 61h, al
	and al, not 80h
	out 61h, al
	mov al, 20h
	out 20h, al

	pop ds es bx ax

	db 		0EAh
	Old09Ofs	dw 0
	Old09Seg	dw 0

	endp

msg		db "Message!!!", "$"
empty_msg	db 10 dup (" "), "$"

include clrs.asm
include funcs.asm
include strfuncs.asm
;------------------------------------------------
; Resident initialization
;------------------------------------------------
Init:
	pushf				; save flags (IF)
	cli				; IF = 0 <-- disables interrupts
	xor bx, bx			; bx = 0
	mov es, bx			; es = 0000 <-- beggining segment of data
	mov bx, 4d * 9d			; bx = 0024h <-- address of 09h int in InterruptTable
	mov ax, es:[bx]			; ax = 0000:[0024] <-- near address os int 09h
	mov Old09Ofs, ax		; Old09Ofs = ax <-- saving old address of int 09h
	mov es:[bx], offset New09	; es:[bx] = &New09
	mov ax, es:[bx+2]		; ax = 0000:[0026] <-- segment of int 09h
	mov Old09Seg, ax		; Old09Seg = ax <-- saving old segment of int 09h
	mov ax, cs			; ax = cs
	mov es:[bx+2], cs		; ex:[bx+2] = segment of New09 address
					; IntTable[09] = cx:[&New09]
	sti				; IF = 1 <-- enables interrupts
	popf				; restore flags (IF)

;Next:
;	in al, 60h			; read data from 60h port (keybord) to AL
;	cmp al, 1			; al == <Esc>
;	jne Next

	mov ax, 3100h			; 31h function of int 21h 
	mov dx, offset EOP		; address of the end of the residental programm (have to be in paragraphs)
	shr dx, 4			; dx *= 16
	inc dx				; dx++
	int 21h				; DOS interruption <-- ending programm and leaving it in memory
;------------------------------------------------
EOP:					; end of programm (it's size)

end Start