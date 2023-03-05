;------------------------------------------------
; Test example from class
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
	push ax bx es ds		; save registers

	mov bx, 0B800h			; start of video memory segment
	mov es, bx			; es = VideoSeg

	mov ah, 5Fh			; pink on black
	mov bx, 160d * 5d + 80d		; shift in videomemory
	in al, 60h			; input from 60h port to al
	mov es:[bx], ax			; draws symbol from al

	in al, 61h			; input from 61h port to al
	or al, 80h			; al || 10000000 (7th bit of al -> 1)
	out 61h, al			; output al to 61h port
	and al, not 80h			; al && ~(10000000) (7th bit of al --> 0)
	out 61h, al			; output al to 61h port
	mov al, 20h			; al = 20h
	out 20h, al			; output al to 20h port

	pop ds es bx ax			; restore registers

	db 		0EAh		; jmp Old09Seg:Old09Ofs
	Old09Ofs	dw 0		; offset of old 09h interruption
	Old09Seg	dw 0		; segment of old 09h inrerruption

	endp
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