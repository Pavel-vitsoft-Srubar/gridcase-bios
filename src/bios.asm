; ===========================================================================
; 
; GRiD 1520 BIOS
; 
; Main file; all code/data is ultimately included from here.
; 
; Comments marked with [TechRef] refer to the GRiDCase 1500 Series Hardware
; Technical Reference.
; 
; Comments marked with [Public] identify locations/APIs mentioned in publicly
; available documentation.
; 
; Comments marked with [Compat] identify places where data/code layout must
; remain fixed for compatibility with software that relies on undocumented or
; semi-documented functionality.
; 
; ===========================================================================

		include	"src/macros.inc"
		include	"src/ports.inc"
		include	"src/cmos.inc"
		include	"src/segments.inc"
		include	"src/todo.asm"

; ---------------------------------------------------------------------------
; 32K BIOS starts at F000:8000
; [TechRef] 3-1 "ROM-BIOS AND I/O REGISTERS"
; It's easier to generate a 64KB ROM with 32KB empty at the start, and then
; reduce it to 32KB later than it is to work out how an offset origin works.
; ---------------------------------------------------------------------------
$		equ	BIOS_START

		; Copyright notice at start, doubled so both the even and odd ROMs contain a complete copy
		db	'CCooppyyrriigghhtt  11998855,,11998866  PPhhooeenniixx  TTeecchhnnoollooggiieess  LLttdd..'

include		"src/reset.asm"

; ---------------------------------------------------------------------------
; System identification section at F000:DFD0
; ---------------------------------------------------------------------------
		FillRom	0DFD0h, 0FFh

		; EPROM part numbers, arranged so each split ROM has a unique number.
		; 1520 BIOS EPROM part numbers differ in the final digit.
		; Note that the arrow is offset by one byte, so even/odd ROMs have it in different columns.
		; [Public] 0FDFDh:000Ch == 2D2Dh
		; [TechRef] 3-26 "System Identification"
		db	'330000663365--0000 <<-- ppaarrtt  nnuummbbeerr'

		; [Public] 0F000h:0DFFEh == 34h
		; [TechRef] 3-26 "System Identification"
GridSysId	CompatAddress 0DFFEh
		dw	0034h

; ---------------------------------------------------------------------------
; XT compatibility section at F000:E000
; AT BIOS listing refers to this as ORGS.ASM
; ---------------------------------------------------------------------------
		FillRom	0E000h, 0FFh
		include	"src/at_compat.asm"

; ---------------------------------------------------------------------------
; Power-On Reset Vector at F000:FFF0
; ---------------------------------------------------------------------------
		FillRom	0FFF0h, 0FFh

		; [Public] CPU reset vector is top of address space minus 16 bytes
		; AT BIOS calls this P_O_R (POWER ON RESET)
Reset		CompatAddress 0FFF0h
		jmp	0F000h:Reset_Compat

		; [Public] IBM BIOS stores ROM date at F000:FFF5 (AT BIOS calls this 'RELEASE MARKER')
ReleaseMarker	CompatAddress 0FFF5h
		db	'03/11/89'

		db	0FFh		; Unused byte

		; [Public] IBM BIOS stores machine identification byte at F000:FFFE
MachineId	CompatAddress 0FFFEh
		db	0FCh		; Model FC == IBM AT (6 MHz)
		db	00		; Submodel 00 == no specific submodel

; ===========================================================================
; END OF PROGRAM
; ===========================================================================

