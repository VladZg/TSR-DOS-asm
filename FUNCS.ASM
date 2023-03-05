;------------------------------------------------
VIDEOMEM_SEG		equ	0B800h
;------------------------------------------------

;------------------------------------------------
;Exits DOS
;------------------------------------------------
;Entry:		None
;Exit:		Not defined
;Expects:	None
;Destroys:	None
;------------------------------------------------
EXIT	macro
	mov ax, 4c00h
	int 21h
	endm
;------------------------------------------------

;------------------------------------------------
;Draws 1 cell
;------------------------------------------------
;Entry:		AH = color attribute
;		AL = filling symbol
;		BX = address in videosegment
;Exit:		None
;Expects:	ES = 0B800h
;Destroys:	None
;------------------------------------------------
DrwCll	proc
	mov es:[bx], ax
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Counts the effective address of the cell
;------------------------------------------------
;Entry:		DH = x coordinate (0 - 80) of start
;		DL = y coordinate (0 - 25) of start
;Exit:		BX = address of the cell in videosegment
;Expects:	None
;Destroys:	AX BX DX
;------------------------------------------------
CntAddr proc
	xor bx, bx		; bx = 0
	mov al, 80d		; al = 80
	dec dl			; dl--
	mul dl			; ax = al * dl		
	mov dl, dh		; dl = dh
	xor dh, dh		; dh = 0
	dec dl			; dl--
	add ax, dx		; ax += dx
	shl ax, 1		; ax *= 2
	mov bx, ax		; bx = ax
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Clears the rectangle with symbols
;------------------------------------------------
;Entry:		AH = color attribute
;		AL = filling symbol
;		BH = length
;		BL = width
;		DH = x coordinate (0 - 80)
;		DL = y coordinate (0 - 25)
;Exit:		None
;Expects:	ES = 0B800h
;Destroys:	BX CX
;------------------------------------------------
DrwRect	proc
	push ax
	push bx

	mov al, bh		
	mul bl			; ax = al * bl
	mov cx, ax		; cx = ax - area

	call CntAddr		; CountAddress() <-- bx = address of the first cell
	
	pop dx			; dh = length, dl = width
	pop ax			; ax = symbol + colour attribute

	mov dh, dl		; dh = dl
	xor dl, dl		; dl = 0	

??Horizontal_Next:
	call DrwCll		; DrawCell()
	add bx, 2		; bx += 2
	inc dl			; dl++
	cmp dl, dh		; dl == dh
	je ??Vertical_Next
	loop ??Horizontal_Next

??Vertical_Next:
	dec cx			; cx--
	add bx, 80d * 2d	; 
	shl dl, 1		; 
	push dx			;
	xor dh, dh		; dh = 0
	sub bx, dx		; bx += 80*2 - width*2 <-- shift to the next string
	pop dx			;
	xor dl, dl		; dl = 0
	cmp cx, 0		; cx == 0
	ja ??Horizontal_Next 

	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Clears the full screen with black
;------------------------------------------------
;Entry:		None
;Exit:		None
;Expects:	ES = 0B800h
;Destroys:	AX BX CX DX
;------------------------------------------------
ClrScr	proc
	mov ah,	BLACK_ON_BLACK  ; black colour set
	mov al, BOX_PATTERN	; box pattern set
	mov dh, 1d		; x coord of up left point
	mov dl, 1d		; y coord of up left point
	mov bh, 25d		; full screen length
	mov bl, 80d		; full screen width
	call DrwRect		; DrawRectangle()
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Draws the advanced horizontal line |L|M|M|M|M|R|
;------------------------------------------------
;Entry:		AH = bracket color attribute
;		AL = filling color attribute
;		BH = length
;		DH = x coordinate (0 - 80)
;		DL = y coordinate (0 - 25)
;		SI = address of the array with 3 symbols (L, M, R)
;Exit:		None
;Expects:	ES = 0B800h
;Destroys:	DI
;------------------------------------------------
DrwAdvLine	proc
	push dx cx bx ax
	cmp bh, 3d		; bh < 3
	jb ??Exit_Function

	call CntAddr		; bx = offset of the first cell
	mov di, bx	
	mov bx, sp		; bx = sp

	cld			; DF = 1 <-- di - increasing flag in stosw

	mov ah, [bx+1]		; ah = bracket colour
	mov al, [si]		; al = L
	stosw			; es:[di++] = ax

	xor cx, cx		; cx = 0
	mov cl, [bx+3]		; cx = length
	mov al, [si+1]		; al = M
	mov ah, [bx]		; ah = filling colour 
	rep stosw		; while (cx--) {es:[di++] = ax}

	mov ah, [bx+1]		; ah = bracket colour
	mov al, [si+2]		; al = R
	stosw			; es:[di++] = ax

??Exit_Function:
	pop ax bx cx dx
	ret
	endp	
;------------------------------------------------

;------------------------------------------------
;Draws the frame
;------------------------------------------------
;Entry:		AH = brackets color attribute
;		AL = filling color attribute
;		BH = length
;		BL = height
;		DH = x coordinate (0 - 80)
;		DL = y coordinate (0 - 25)
;		SI = address of the array with 9 symbols of frame
;Exit:		BX = address of the cell next to the last cell of the line
;Expects:	ES = 0B800h
;Destroys:	AX BX CX DX DI
;------------------------------------------------
DrwFrm	proc
	push bx ax
	cmp bh, 3d		; bh < 3
	jb ??Exit_Function
	cmp bl, 3d		; bl < 3
	jb ??Exit_Function

	mov al, ah
??Drw_First_String:
	call DrwAdvLine		; DrawAdvancedLine() <-- draws the first string
	
	add si, 3		; si += 3
	xor cx, cx		; cx = 0
	mov cl, bl		; cl = bl (height)
	sub cl, 2d		; cl -= 2
	mov bx, sp
	mov al, [bx]
	mov word ptr bx, [bx+2] ; restore bx
??Drw_Middle_Strings:
	inc dl				; dl++
	call DrwAdvLine			; DrawAdvancedLine() <-- draws the middle string
	loop ??Drw_Middle_Strings	

	add si, 3d		; di += 3
	mov bx, sp
	mov al, [bx+1]
	mov word ptr bx, [bx+2] ; restore bx
??Drw_Last_String:
	call DrwAdvLine		; DrawAdvancedLine() <-- draws the last string

??Exit_Function:
	pop ax bx
	ret
	endp	
;------------------------------------------------

;------------------------------------------------
;Translates hex num into number
;------------------------------------------------
;Entry:		DI = beginning adress of hex num
;Exit:		AX = translated number
;Expects:	None
;Destroys:	AX
;------------------------------------------------
Hton	proc
	push di
	push cx
	push bx
	mov cx, 4d		; cx = 4

??Next_Symbol:
	mov bx, bx		; bx = 0
	mov bl, [di]		; bl = [di]

??Check_For_Hex_Num:
	cmp bl, "0"		
	jb ??Check_For_Hex_Symb ; bl < "0"
	cmp bl, "9"		
	ja ??Check_For_Hex_Symb ; bl > "9"
	jmp ??Translate_Num

??Check_For_Hex_Symb:
	cmp bl, "A"		
	jb ??Exit_Function	; bl < "A"
	cmp bl, "F"
	ja ??Exit_Function	; bl > "F"
	jmp ??Translate_Ltr

??Translate_Num:
	sub bl, 48d		; num symb --> num
	jmp ??Process_Num

??Translate_Ltr:
	sub bl, 55d		; ltr symb -> num

??Process_Num:
	shl ax, 4		; ax *= 16
	add ax, bx		; ax += bx
	inc di			; di++
	loop ??Next_Symbol

??Exit_Function:	
	pop bx
	pop cx
	pop di
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Translates number into hex
;------------------------------------------------
;Entry:		AX = number
;		DI = adress of beginning str for hex num
;Exit:		DI = adress of str with hex num
;Expects:	None
;Destroys:	AX BX CX DX
;------------------------------------------------
NtoHex	proc
	push ax bx cx dx
	mov cx, 4d		; cx = 4
	mov bx, di		; bx = di
	add bx, cx		;
	mov byte ptr [bx], "$"	; end of hex str
	dec bx			; bx += 4 - 1

??Hex_Diving:
	mov dx, ax		; dx = ax
	shr ax, 4		; ax = ax // 16
	push ax
	shl ax, 4		; ax *= 16
	sub dx, ax		; dx = ax - ax // 16 = ax % 16
	pop ax
	cmp dx, 10d		; dx == 10
	jae ??Hex_Ltr_Conv

??Hex_Num_Conv:
	add dl, 48d		; ah += 48 (number -> ASCII)
	jmp ??Pushing_Hex_Symb	
??Hex_Ltr_Conv:
	add dl, 55d		; ah += 55 (hex letter number -> ASCII)	
	
??Pushing_Hex_Symb:
	mov [bx], dl		; [bx] = dl
	dec bx			; bx--
	xor dx, dx		; dx = 0	
	loop ??Hex_Diving

	pop dx cx bx ax
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Printf without args
;------------------------------------------------
;Entry:		AH = colour attribute
;		DH = x coordinate (0 - 80) of start
;		DL = y coordinate (0 - 25) of start
;		SI = address of fmt string in DS ends with '$'
;Exit:		
;Expects:	ES = 0B800h
;Destroys:	BX
;------------------------------------------------
Print	proc
	push ax cx dx si ax
	call CntAddr	; bx = shift
	mov di, bx	; di = bx
	pop ax

	cld
??Next_Symbol:
	cmp byte ptr ds:[si], ENDL_SYMBOL	; ds:[si] == "$"
	je ??Exit_Function
	movsb					; es:[di++] = ds:[si++]
	mov al, ah				; al = ah
	stosb					; es:[di++] = al
	jmp ??Next_Symbol
	
??Exit_Function:
	pop si dx cx ax
	ret
	endp
;------------------------------------------------
;Printf without args
;------------------------------------------------
;Entry:		AH = colour attribute
;		DH = x coordinate (0 - 80) of start
;		DL = y coordinate (0 - 25) of start
;		DI = address of fmt string ends with '$'
;Exit:		DI = length of out string
;Expects:	ES = 0B800h
;Destroys:	BX
;------------------------------------------------
Printf	proc
	push si
	push dx
	push ax
	push dx
	call CntAddr	; CountAddress()
	pop dx
	mov si, di	; si = di
	xor di, di	; di = 0		
	pop ax

??Text_Printf:		
	lodsb					; al = [si++]
	cmp al, ENDL_SYMBOL			; al == "$" symbol of the end 
	je ??Exit_Printf
	cmp al, SEP_SYMBOL			; al == "&" symbol of chng colour attr
	je ??Change_Clr
	cmp al, STRSPLIT_SYMBOL 		; al == "\" symbol of the split str
	jne ??Printf_Ltr

??Split_Str:
	push ax
	inc dl			; dl++
	push dx 
	call CntAddr		; CountAddress() <-- adress of the first symbol of the next str
	pop dx
	pop ax
	jmp ??Text_Printf

??Change_Clr:
	push ax
	push di
	mov di, si				; di = si
	call Hton				; HexToNumber()
	pop di
	mov cx, ax				; cx = ax
	pop ax
	mov ah, cl				; ah = cl <-- changing colour attribute
	add si, 2d				; si += 2
	jmp ??Text_Printf			; write next symbol of fmt string
		
??Printf_Ltr:
	inc di					; di++
	call DrwCll				; DrawCell()
	
	add bx, 2				; bx += 2
	jmp ??Text_Printf			; write next symbol of fmt string

??Exit_Printf:
	mov cx, dx	; cx = dx
	pop dx
	sub cx, dx	; cx -= dx
	pop si

	ret
	endp
;------------------------------------------------