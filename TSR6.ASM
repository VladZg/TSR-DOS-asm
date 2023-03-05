;------------------------------------------------
; Printing all regs values every 55ms before timer inc
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
	push ax bx cx dx si di es ds	; saving registers

	mov ax, cs
	mov ds, ax

	in al, 60h			

	cmp al, 2Ah			; hot key "ON" -- <Shift(L)>
	je ??Set_On

	cmp al, 36h			; hot key "OFF" -- <Shift(R)>
	jne ??Exit_Intrpt

	mov ax, cs			; segment of src copying
	mov si, offset SaveBuf		; address of src copying
	mov bx, 0B800h			; segment of dst copying
	mov di, 0d			; address of dst copying
	mov cx, 4000d			; number of copying buf
	call MemCpy			; copy from SaveBuf to DrawBuf
	mov bx, offset Show_Regs_Mode	
	mov byte ptr [bx], 00h		; set "off" mode
	jmp ??Exit_Intrpt

??Set_On:
	mov ax, 0B800h			; segment of src copying
	mov si, 0h			; address of src copying
	mov bx, cs			; segment of dst copying
	mov di, offset SaveBuf		; address of dst copying
	mov cx, 4000d			; number of copying buf
	call MemCpy			; copy from VideoMem to SaveBuf
	mov bx, offset Show_Regs_Mode
	mov byte ptr [bx], 0FFh		; set "on" mode

??Exit_Intrpt:
	in al, 61h			; input from 61h port to al
	or al, 80h			; al || 10000000 (7th bit of al -> 1)
	out 61h, al			; output al to 61h port
	and al, not 80h			; al && ~(10000000) (7th bit of al --> 0)
	out 61h, al			; output al to 61h port
	mov al, 20h			; al = 20h
	out 20h, al			; output al to 20h port

	pop ds es di si dx cx bx ax 	; restore registers

	db 		0EAh		; jmp Old09Seg:Old09Ofs
	Old09Ofs	dw 0		; offset of old 09h interruption
	Old09Seg	dw 0		; segment of old 09h inrerruption

	endp

New08	proc
	push ax bx cx dx si di bp sp es ds	; saving registers
	push ds es sp bp di si dx cx bx ax	; saving registers values
	
	mov bx, 0B800h		; 
	mov es, bx			; es = DrawBuf
	mov ax, cs
	mov ds, ax

	mov si, offset ChangeBuf
	mov di, 0d
	mov bx, offset SaveBuf
	mov cx, 4000d			; cx = 4000
??Next_Symbol:
	cld				; DF = 0 <-- setting increasing mode
	cmpsb 				; ds:[si++] == es:[di++]
	je ??Continue_Cmp
	dec di
	mov ax, es:[di]
	mov ds:[bx], ax
	inc di
??Continue_Cmp:
	inc bx
	loop ??Next_Symbol

	mov bx, offset Show_Regs_Mode
	mov byte ptr al, [bx]

	cmp al, 00h
	je ??Turned_Off
	cmp al, 0FFh
	je ??Turned_On
	rep pop di di di di di di di di di di
	jmp ??Exit_Intrpt	

??Turned_On:
;	mov ah, 5Fh
;	mov al, 00h
;	mov bh, 12d
;	mov bl, 12d
;	mov dh, 49d
;	mov dl, 2d
;	mov si, offset Frame_Attr
;	call DrwFrm

	mov si, offset Regs		; di = Regs
	mov dh, 36d			; x coord
	mov dl, 3d			; y coord
	mov ah,	00101010b		; light green on dark green
	mov cx, 10d			; num of regs
??Next_Reg:
	call Print			; prints reg name
	mov di, si
	add di, 5d
	pop ax
	call NToHex			; di = Hex(ax)
	mov si, di
	add dh, 5d
	mov ah, 00101010b		
	call Print			; prints reg value
	add si, 5d
	inc dl
	sub dh, 5d
	loop ??Next_Reg

	mov si, offset Turned_On_Msg
	mov ah, GREEN_ON_BLACK
	jmp ??Exit_Intrpt

??Turned_Off:
	pop di di di di di di di di di di
	mov si, offset Turned_Off_Msg
	mov ah, RED_ON_BLACK

??Exit_Intrpt:
	mov dh, 1d			; x coord
	mov dl, 1d			; y coord
	call Print

	mov ax, 0B800h			; segment of src copying
	mov si, 0d			; address of src copying
	mov bx, cs			; segment of dst copying
	mov di, offset ChangeBuf	; address of dst copying
	mov cx, 4000d			; number of copying buf
	call MemCpy			; copy from SaveBuf to DrawBuf

	pop ds es sp bp di si dx cx bx ax

	db 		0EAh		; jmp Old09Seg:Old09Ofs
	Old08Ofs	dw 0		; offset of old 08h interruption
	Old08Seg	dw 0		; segment of old 08h inrerruption
	
	endp

Show_Regs_Mode	db	00h
Turned_On_Msg	db	"ON!$"
Turned_Off_Msg	db	"OFF$"

Frame_Attr	db	LEFT_UP_BRACKET, 	UP_BRACKET,	 RIGHT_UP_BRACKET
		db	LEFT_BRACKET,		BOX_PATTERN,	 RIGHT_BRACKET
		db	LEFT_BOTTOM_BRACKET, 	BOTTOM_BRACKET,	 RIGHT_BOTTOM_BRACKET

Regs		db	"AX =     ", "$"
		db	"BX =     ", "$"
		db	"CX =     ", "$"
		db	"DX =     ", "$"
		db	"SI =     ", "$"
		db	"DI =     ", "$"
		db	"BP =     ", "$"
		db	"SP =     ", "$"
		db	"ES =     ", "$"
		db	"DS =     ", "$"	

SaveBuf		db	4000 dup (?)
ChangeBuf	db	4000 dup (?)
DrawBuf		db	4000 dup (?)

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
;	cmp al, 1Ch			; al == <Enter>
;	jne Next

	pushf				; save flags (IF)
	cli				; IF = 0 <-- disables interrupts
	xor bx, bx			; bx = 0
	mov es, bx			; es = 0000 <-- beggining segment of data
	mov bx, 4d * 8d			; bx = 0024h <-- address of 08h int in InterruptTable
	mov ax, es:[bx]			; ax = 0000:[0024] <-- near address os int 08h
	mov Old08Ofs, ax		; Old08Ofs = ax <-- saving old address of int 08h
	mov es:[bx], offset New08	; es:[bx] = &New08
	mov ax, es:[bx+2]		; ax = 0000:[0026] <-- segment of int 09h
	mov Old08Seg, ax		; Old08Seg = ax <-- saving old segment of int 08h
	mov ax, cs			; ax = cs
	mov es:[bx+2], cs		; ex:[bx+2] = segment of New09 address
					; IntTable[08] = cx:[&New08]
	sti				; IF = 1 <-- enables interrupts
	popf				; restore flags (IF)

	mov ax, 3100h			; 31h function of int 21h 
	mov dx, offset EOP		; address of the end of the residental programm (have to be in paragraphs)
	shr dx, 4			; dx *= 16
	inc dx				; dx++
	int 21h				; DOS interruption <-- ending programm and leaving it in memory
;------------------------------------------------

EOP:					; end of programm (it's size)

end Start