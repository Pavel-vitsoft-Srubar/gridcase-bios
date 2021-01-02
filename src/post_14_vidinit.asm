
POST14_VidInit	PROC
		; Enter via fall-through from previous POST code

; ---------------------------------------------------------------------------
; Determine initial video mode and initialize adapter
		mov	ds, [cs:kBdaSegment]
		mov	al, CHECKPOINT_VIDEO
		out	PORT_DIAGNOSTICS, al

		; Assume default mode based on interruptFlag?
		; TODO: how is this set?
		mov	[equipmentWord], 30h,DATA=BYTE	; 80x25 monochrome
		test	[interruptFlag], 40h	; ???
		jnz	.l15
		mov	[equipmentWord], 20h,DATA=BYTE	; 80x25 colour

		; Check for an option ROM present anywhere between C000:0000
		; and C8000:0000, at 2KB boundaries.  If found, then assume it
		; an EGA+ video adapter and update the default video mode.
.l15		mov	si, 0C000h
		mov	cx, 10h
.findVidRom	mov	ds, si
		add	si, 80h
		cmp	[0], 0AA55h,DATA=WORD	; check for option ROM signature
		loopne	.findVidRom
		mov	ds, [cs:kBdaSegment]
		jnz	.l16
		and	[equipmentWord], 0CFh,DATA=BYTE	; set video equipment to EGA+

.l16		mov	al, CMOS_STATUS_DIAG | NMI_DISABLE
		call	ReadCmos
		mov	bl, al,CODE=LONG
		test	al, 0C0h		; invalid config or CMOS checksum bad?
		jnz	.loc_F8664

		; Update CMOS equipment byte with video mode
		mov	al, CMOS_EQUIPMENT | NMI_DISABLE
		call	ReadCmos
		mov	bh, al,CODE=LONG
		and	al, 30h			; isolate CMOS equipment video bits
		cmp	[equipmentWord], al
		jz	.loc_F8653
		cmp	al, 10h
		jnz	.loc_F865B
		cmp	[equipmentWord], 20h,DATA=BYTE
		jnz	.loc_F865B
		and	[equipmentWord], 0CFh,DATA=BYTE
		or	[equipmentWord], al
.loc_F8653	test	bh, 1
		jnz	.loc_F8664
		jmp	.loc_F8669

		nop				; lone NOP to jump over

.loc_F865B	mov	al, bl,CODE=LONG
		or	al, 20h
		mov	ah, CMOS_STATUS_DIAG | NMI_DISABLE
		call	WriteCmos

.loc_F8664	or	[equipmentWord], 1,DATA=BYTE

.loc_F8669	sti
		test	[interruptFlag], 20h
		jnz	.loc_F8674
		jmp	.vidInitFail

		nop				; lone NOP to jumo over

		; Init the display now we know what type it is
.loc_F8674	mov	al, CHECKPOINT_VIDEO_INIT
		out	PORT_DIAGNOSTICS, al

		; TODO: why is equipmentWord modified here?
		push	[equipmentWord]		; save original equipment word
		mov	[equipmentWord], 30h,DATA=BYTE	; set just reserved bits in equipment word
		xor	ax, ax,CODE=LONG	; mode 0: 40x25 CGA text
		int	10h			; set video mode
		mov	[equipmentWord], 10h,DATA=BYTE	; set just one reserved bit in equipment word
		mov	ax, 3			; mode 3: 80x25 CGA text
		int	10h			; set video mode
		pop	ax
		mov	[equipmentWord], ax
		test	al, 30h			; check int10/00 return
		jz	.vidInitFail

		call	TestVidMem
		jnb	.vidInitDone
		mov	al, [equipmentWord]
		and	al, 10h			; reserved bit?
		add	al, 10h			; reserved bits?
		xor	[equipmentWord], al
		call	TestVidMem
		jb	.vidInitFail

		Inline	WriteString,'Display adapter failed; using alternate',0Dh,0Ah,0
		call	SetSoftResetFlag
		jmp	.vidInitDone

.vidInitFail	xor	ax, ax,CODE=LONG
		mov	ds, ax
		mov	[40h], SoftwareIret,DATA=WORD
.vidInitDone	; Exit via fall-through to next POST procedure
		ENDPROC POST14_VidInit

