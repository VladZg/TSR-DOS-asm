;------------------------------------------------
; Printing all regs values after tap on hot key <shift(R)>
;------------------------------------------------
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
	push ax bx cx dx si di es ds		; saving registers
	push ds es sp bp di si dx cx bx ax	; saving registers values

	mov bx, 0B800h			; start of video memory segment
	mov es, bx			; es = VideoSeg

	in al, 60h
	cmp al, 36h			; <shift(R)>
	jne ??Exit_Intrpt_1

Reset_Aboba	db	"ABOBA!!!$"

??Print_Regs:
	mov ax, cs
	mov ds, ax

	mov si, offset Frame_Type	; frame type
	mov bh, 10d			; length
	mov bl, 12d			; height
	mov dl, 2d			; y coord
	mov dh, 2d			; x coord
	mov ah, PINK_ON_BLACK		; colour of frame
	mov al, BLACK_ON_BLACK		; colour of center
;	call DrwFrm 			; DrawFrame() <-- draws frame

	mov di, offset AX_Name		; di = AX_Name
	mov dh, 3d			; x coord
	mov dl, 3d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax name

	pop ax				; restore ax value
	mov di, offset AX_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 3d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset BX_Name
	mov dh, 3d			; x coord
	mov dl, 4d			; y coord
	mov ah, 5Fh
	call Printf

	pop ax				; restore bx value
	mov di, offset BX_Value		; di = BX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 4d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset CX_Name
	mov dh, 3d			; x coord
	mov dl, 5d			; y coord
	mov ah, 5Fh
	call Printf

;-----------------------
jmp ??After_Exit_Intrpt_1
??Exit_Intrpt_1:
pop ax bx cx dx si di bp sp es ds
jmp ??Exit_Intrpt
??After_Exit_Intrpt_1:
;------------------------

	pop ax				; restore ax value
	mov di, offset CX_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 5d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset DX_Name
	mov dh, 3d			; x coord
	mov dl, 6d			; y coord
	mov ah, 5Fh
	call Printf
;------
	pop ax				; restore ax value
	mov di, offset DX_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 6d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset SI_Name
	mov dh, 3d			; x coord
	mov dl, 7d			; y coord
	mov ah, 5Fh
	call Printf

	pop ax				; restore ax value
	mov di, offset SI_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 7d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset DI_Name
	mov dh, 3d			; x coord
	mov dl, 8d			; y coord
	mov ah, 5Fh
	call Printf

	pop ax				; restore ax value
	mov di, offset DI_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 8d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset BP_Name
	mov dh, 3d			; x coord
	mov dl, 9d			; y coord
	mov ah, 5Fh
	call Printf

	pop ax				; restore ax value
	mov di, offset BP_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 9d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset SP_Name
	mov dh, 3d			; x coord
	mov dl, 10d			; y coord
	mov ah, 5Fh
	call Printf

	pop ax				; restore ax value
	mov di, offset SP_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 10d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset ES_Name
	mov dh, 3d			; x coord
	mov dl, 11d			; y coord
	mov ah, 5Fh
	call Printf

	pop ax				; restore ax value
	mov di, offset ES_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 11d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

	mov di, offset DS_Name
	mov dh, 3d			; x coord
	mov dl, 12d			; y coord
	mov ah, 5Fh
	call Printf
	
	pop ax				; restore ax value
	mov di, offset DS_Value		; di = AX_Value
	call NToHex			; di = Hex(ax)
	mov dh, 8d			; x coord
	mov dl, 12d			; y coord
	mov ah, 5Fh			; pink on black
	call Printf			; prints ax value

??Exit_Intrpt:
	in al, 61h			; input from 61h port to al
	or al, 80h			; al || 10000000 (7th bit of al -> 1)
	out 61h, al			; output al to 61h port
	and al, not 80h			; al && ~(10000000) (7th bit of al --> 0)
	out 61h, al			; output al to 61h port
	mov al, 20h			; al = 20h
	out 20h, al			; output al to 20h port

	pop ds es di si dx cx bx ax 	 ; restore registers

	db 		0EAh		; jmp Old09Seg:Old09Ofs
	Old09Ofs	dw 0		; offset of old 09h interruption
	Old09Seg	dw 0		; segment of old 09h inrerruption

	endp

Frame_Type	db	LEFT_UP_BRACKET, UP_BRACKET, RIGHT_UP_BRACKET, LEFT_BRACKET, BOX_PATTERN, RIGHT_BRACKET, LEFT_BOTTOM_BRACKET, BOTTOM_BRACKET, RIGHT_BOTTOM_BRACKET
AX_Name		db	"ax = ", "$"
BX_Name		db	"bx = ", "$"
CX_Name		db	"cx = ", "$"
DX_Name		db	"dx = ", "$"
SI_Name		db	"si = ", "$"
DI_Name		db	"di = ", "$"
BP_Name		db	"bp = ", "$"
SP_Name		db	"sp = ", "$"
ES_Name		db	"es = ", "$"
DS_Name		db	"ds = ", "$"
AX_Value	db	4 dup (?), "$"
BX_Value	db	4 dup (?), "$"
CX_Value	db	4 dup (?), "$"
DX_Value	db	4 dup (?), "$"
SI_Value	db	4 dup (?), "$"
DI_Value	db	4 dup (?), "$"
BP_Value	db	4 dup (?), "$"
SP_Value	db	4 dup (?), "$"
ES_Value	db	4 dup (?), "$"
DS_Value	db	4 dup (?), "$"

include clrs.asm
include funcs.asm
include strfuncs.asm
;------------------------------------------------
; Resident initialization
;------------------------------------------------
Init:
	mov ah, 10h			; ah = 10h
	int 16h				; reading one key symbol
	cmp ah, 1Ch			; <Enter>
	jne Not_Init

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

	mov ax, 3100h			; 31h function of int 21h 
	mov dx, offset EOP		; address of the end of the residental programm (have to be in paragraphs)
	shr dx, 4			; dx *= 16
	inc dx				; dx++
	int 21h				; DOS interruption <-- ending programm and leaving it in memory

Not_Init:
	EXIT
;------------------------------------------------
EOP:					; end of programm (it's size)

end Start