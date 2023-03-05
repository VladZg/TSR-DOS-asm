;------------------------------------------------
;Counts string length before stopping symbol
;------------------------------------------------
;Entry:		AH = stop-symbol of the string
;		SI = address of the string
;Exit:		CX = length (without ENDL_SYMBOL)
;		BX = address of the symbol after the stop-symbol
;Expects:	string contains stop-symbol
;Destroys:	AL BX CX
;------------------------------------------------
StrLenS	proc
	mov bp, sp
	push bp

	push si
	xor cx, cx			; cx = 0
	
??Next_Symbol:
	lodsb				; al = [si++]
	cmp al, ah			; al == ah
	je ??Exit_Function
	inc cx				; cx++
	jmp ??Next_Symbol		

??Exit_Function:
	mov bx, si
	pop si
	
	pop bp
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Counts string length (C strlen analog)
;------------------------------------------------
;Entry:		SI = address of the string
;Exit:		CX = length (without ENDL_SYMBOL)
;		BX = address of the symbol after the ENDL_SYMBOL
;Expects:	string ends with ENDL_SYMBOL ($)
;Destroys:	AX BX CX
;------------------------------------------------
StrLen	proc
	push si
	mov cx, si

??Next_Symbol:
	lodsb			; al = [si++]
	cmp al, ENDL_SYMBOL	; al == ENDL_SYMBOL
	jne ??Next_Symbol	

??Exit_Function:
	sub si, cx
	dec si		; si -= cx + 1d <-- length of str without ENDL_STR
	mov cx, si
	pop si
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Searches first entrance of the cymbol in string (C memchr analog)
;------------------------------------------------
;Entry:		SI = address of the string
;		AH = searching symbol
;		CX = length of the part the string for search
;Exit:		DI = address of the first entry of the symbol (0 if there is no)
;Expects:	string ends with ENDL_SYMBOL ($)
;Destroys:	AX BX CX DI
;------------------------------------------------
MemChr	proc
	mov bp, sp
	push bp

	push si

??Next_Symbol:
	lodsb			; al = [si++]
	cmp al, ah		; al == ah
	je ??Symbol_Founded
	cmp al, ENDL_SYMBOL	; al == ENDL_SYMBOL
	je ??Symbol_Not_Founded	
	loop ??Next_Symbol

??Symbol_Not_Founded:
	xor di, di		; di = 0
	jmp ??Exit_Function

??Symbol_Founded:
	mov di, si		; di = si
	dec di			; di-- <-- address of founded symbol

??Exit_Function:
	pop si

	pop bp
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Searches first entrance of the cymbol in string (C strchr analog)
;------------------------------------------------
;Entry:		SI = address of the string
;		AH = searching symbol
;Exit:		DI = address of the first entry of the symbol (0 if there is no)
;Expects:	string ends with ENDL_SYMBOL ($)
;Destroys:	AX BX DI
;------------------------------------------------
StrChr	proc
	mov bp, sp
	push bp

	push si

??Next_Symbol:
	lodsb			; al = [si++]
	cmp al, ah		; al == ah
	je ??Symbol_Founded
	cmp al, ENDL_SYMBOL	; al == ENDL_SYMBOL
	je ??Symbol_Not_Founded	
	jmp ??Next_Symbol

??Symbol_Not_Founded:
	xor di, di		; di = 0
	jmp ??Exit_Function

??Symbol_Founded:
	mov di, si		; di = si
	dec di			; di-- <-- address of founded symbol

??Exit_Function:
	pop si

	pop bp
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Fills an array with symbols (C memset analog)
;------------------------------------------------
;Entry:		SI = address of the array
;		AL = filling symbol
;		CX = length of the array for filling
;Exit:		None
;Expects:	string ends with ENDL_SYMBOL ($)
;		address of te string given in ES segment
;Destroys:	CX DI
;------------------------------------------------
MemSet	proc
	mov di, si	; di = si

	cld		; DF = 0 <-- setting di-increasing mode in stosb
	rep stosb	; while (cx-- != 0) {es:[di++] = al}

	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Copies n symbols from source to destination array (C MemCpy analog)
;------------------------------------------------
;Entry:		AX:SI = address of the source array
;		BX:DI = address of the destination array
;		CX = length of the copying part
;Exit:		DI = address of the destination array
;Expects:	address of the destination array given in ES segment
;		address of the source array given in DS segment
;Destroys:	CX
;------------------------------------------------
MemCpy	proc
	push es ds si di

	mov ds, ax
	mov es, bx
	cld		; DF = 0 <-- setting increasing mode
	rep movsb 	; while (cx--) {es:[di++] = ds:[si++]}

	pop di si ds es
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Copies src str to dst str (C StrCpy analog)
;------------------------------------------------
;Entry:		SI = address of the source str
;		DI = address of the destination str
;Exit:		DI = address of the destination array
;Expects:	address of the destination array given in ES segment
;		address of the source array given in DS segment
;Destroys:	AL
;------------------------------------------------
StrCpy	proc
	push si
	push di

	cld			; DF = 0 <-- setting increasing mode

??Next_Symbol:			; while (al != "$")
	lodsb			; al = ds:[si++]
	stosb			; es:[di++] = al
	cmp al, ENDL_SYMBOL	; al != "$"
	jne ??Next_Symbol

	pop di
	pop si
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Compares n symbols of buf1 and buf2 str and set flags as cmp (C MemCmp analog)
;------------------------------------------------
;Entry:		SI = address of the source array
;		DI = address of the destination array
;		CX = length of the copying part
;Exit:		flags of cmp
;Expects:	address of the destination array given in ES segment
;		address of the source array given in DS segment
;Destroys:	AL CX
;------------------------------------------------
MemCmp	proc
	push si
	push di

	cld			; DF = 0 <-- setting increasing mode
	repe cmpsb		; while (cx-- && es:[di++] == ds:[si++]) {es:[di++] == ds:[si++]x}

??Exit_Function:
	pop di
	pop si
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Compares buf1 and buf2 str (C StrCmp analog)
;------------------------------------------------
;Entry:		SI = address of the source str
;		DI = address of the destination str
;Exit:		flags of cmp
;Expects:	address of the destination array given in ES segment
;		address of the source array given in DS segment
;Destroys:	AL
;------------------------------------------------
StrCmp	proc
	push si
	push di

	cld			; DF = 0 <-- setting increasing mode

??Next_Symbol:			; while (al != ENDL_SYMBOL && es:[di++] == ds:[si++])
	lodsb			; al = ds:[si++]
	scasb			; es:[di++] == al
	jne ??Exit_Function
	cmp al, ENDL_SYMBOL	; al == ENDL_SYMBOL
	jne ??Next_Symbol

??Exit_Function:
	pop di
	pop si
	ret
	endp
;------------------------------------------------

;------------------------------------------------
;Counts a number of given symbols in given str
;------------------------------------------------
;Entry:		AH = code of the symbol we search
;		DI = address of the string
;Exit:		CX = number of repeats
;Expects:	string ends with ENDL_SYMBOL
;Destroys:	AL CX
;------------------------------------------------
CntStrSymb	proc
	mov bp, sp
	push bp

	push si
	xor cx, cx
	mov si, di

??Next_Symbol:
	lodsb				; al = [si++]
	cmp al, ENDL_SYMBOL		; al == ENDL_SYMBOL
	je ??Exit_Function
	cmp al, ah			; al != ah
	jne ??Next_Symbol
	inc cx				; cx++
	jmp ??Next_Symbol	

??Exit_Function:
	pop si
	
	pop bp
	ret
	endp
;------------------------------------------------

;---------------------------------------------------
;Counts a length of the longest line from the text
;---------------------------------------------------
;Entry:		DI = address of the text
;Exit:		CL = length of the longest line
;Expects:	lines are splitted by STRSPLIT_SYMBOL, text end with ENDL_SYMBOL
;Destroys:	AL CX
;------------------------------------------------
CntStrMaxLen	proc
	mov bp, sp
	push bp

	push si
	xor cx, cx
	mov si, di

??Next_Symbol:
	lodsb				; al = [si++]
	cmp al, ENDL_SYMBOL		; al == ENDL_SYMBOL
	je ??Prepare_Out
	cmp al, SEP_SYMBOL		; al == SEP_SYMBOL
	je ??Skip_ClrChng_Symbols
	inc cl				; cl++
	cmp al, STRSPLIT_SYMBOL			; al != STRSPLIT_SYMBOL
	jne ??Next_Symbol
	dec cl				; cl--
	cmp cl, ch			; cl > ch
	ja ??Set_New_Max
	xor cl, cl			; cl = 0
	jmp ??Next_Symbol

??Skip_ClrChng_Symbols:
	add si, 2d			; si += 3
	jmp ??Next_Symbol	

??Set_New_Max:
	mov ch, cl			; ch = cl
	xor cl, cl
	jmp ??Next_Symbol	

??Prepare_Out:
	cmp cl, ch			; cl > ch
	jae ??Exit_Function
	mov cl, ch

??Exit_Function:
	pop si

	pop bp
	ret
	endp
;------------------------------------------------