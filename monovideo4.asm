; Filename: monovideo4.asm
; Author: Koen van Vliet <8by8mail@gmail.com>
; Description: Test with monochrome video using timers and SPI for shifting out pixels data
include "ez8.inc"

; Setup video generator
		sysFreq		equ		20_000_000
		rFreq		equ		50

		hChars		equ		21			; Character columns
		vChars		equ		26			; Character rows
		hBorderL	equ		2			; Left horizontal border width
		hBorderR	equ		2			; Right horizontal border width
		cWidth		equ		8			; Width of a character
		cHeight		equ		8			; Height of a character

		spiPre		equ	3

; Calculate timing parameters
		hCharsTotal equ	hChars + 1;3 ;+ hBorderL + hBorderR
		if (hCharsTotal / 2) * 2 < hCharsTotal
			error "Horizontal characters must be an even number."
		endif
		
		if rFreq = 50
			hTime		equ		64
			hSyncTime	equ		4
			bPorchTime	equ		4
			fPorchTime	equ		2
			vSyncHLines	equ		5
			vSyncPad	equ		1
		elseif rFreq = 60
			hTime		equ		63
			hSyncTime	equ		4
			bPorchTime	equ		4
			fPorchTime	equ		2
			vSyncHLines	equ		6
			vSyncPad	equ	0
		else
			error	"Unknown frequency"
		endif

		t0Interval		var		hTime * sysFreq / (hCharsTotal * 1000_000)
		t1hSync			equ		hSyncTime * sysFreq / 1000_000
		t1BroadSync		equ		(t0Interval * (hCharsTotal / 2)) - t1hSync

		if t0Interval < (cWidth + 1) * spiPre * 2
			error "Horizontal character count to high. Timing requirements not met!"
		endif
		
;Register labels (R4-R8 are free to use)
		DDR			equ		1
		AF			equ		2

		vBuff		equ		RR10
		vBuffH		equ		R10
		vBuffL		equ		R11
		isrVect		equ		RR14
		isrVectH	equ		R14
		isrVectL	equ		R15
		hCharCnt	equ		R12
		vLineCnt	equ		R13
		state		equ		R9
		
		screenBuff	equ		200h

vector	RESET = init
vector timer0 = isrT0
org 0200h
init		di									; Disable interrupts
			srp		#00h						; Setup working registers
			ldx		SPH,#00h					; Set stack pointer base address
			ldx		SPL,#FFh
			ld		R6,#2
			call	clrBuff						; Clear display buffer
			
initSpi		ldx		PCADDR,#DDR					; MOSI pin is output
			ldx		PCCTL,#~(1<<4)
			ldx		PCADDR,#AF					; Set alternate SPI functions
			ldx		PCCTL,#(1<<4)				; MOSI alternate function
			ldx		SPICTL,#(1<<1)|(1<<0)		; SPI Master enabled
			ldx		SPIMODE,#((cWidth & 7) << 2); Set amt. of bits per char
			ldx		SPIBRH,#HIGH(spiPre)		; Setup dot clock
			ldx		SPIBRL,#LOW(spiPre)

			ldx		T0CTL1,#0					; Clear the register
			ldx		T0CTL0,#0					; No cascading
			ldx		T0RH,#HIGH(t0Interval)		; Set T0 reload value
			ldx		T0RL,#LOW(t0Interval)		;
			ldx		T0CTL1,#(1<<0)				; Continuous mode, pre=f/1
			ldx		IRQ0ENH,#(1<<5)				; T0 interrupt high priority
			ldx		IRQ0ENL,#(1<<5)
			
			ldx		T1CTL1,#0					; Clear the register
			ldx		T1CTL0,#0					; No cascading
			ldx		T1RH,#HIGH(t1hSync)			; Set T1 interval for short sync pulse
			ldx		T1RL,#LOW(t1hSync)
			ldx		T1CTL1,#(1<<6)				; One-shot mode. Sync is inactive (HIGH)

initGPIO	ldx		PCADDR,#AF					; T1OUT alternate function enable
			orx		PCCTL,#(1<<1)			
			
startVideo	ld		R4,#F0h
			ld		R5,#5
			ld		state,#LOW(preEq)			; Set state to preEq
			ld		hCharCnt,#hCharsTotal/2
			ld		vLineCnt,#vSyncHLines + vSyncPad
			ld		isrVectH,#HIGH(sync)
			ld		isrVectL,#LOW(sync)
			orx		T0CTL1,#(1<<7)				; T0 enabled	
			ei									; Enable interrupts
			
$$			; Do stuff
			jr		$B

clrBuff		ld		R0,#HIGH(screenBuff)
			ld		R1,#LOW(screenBuff)
			ld		R2,R6						; Fill the display buffer with this value
$$			ldx		@RR0,R2
			incw	RR0
			cp		R1,#LOW(screenBuff+hChars*vChars)
			cpc		R0,#HIGH(screenBuff+hChars*vChars)
			jr		ne,$B
			ret

isrT0		jp		@isrVect

align 256
sync		andx	T1CTL1,#~(1<<6)				; Sync active (LOW)
			orx		T1CTL1,#(1<<7)				; Start sync pulse timer
			orx		T1CTL1,#(1<<6)
			ld		isrVectL,state
			ld		vBuffL,#FFh					; Load black pixels in video buffer
			iret
; Pre-equalizing pulses
preEq		djnz	hCharCnt,preEqEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(vertPad)			; Set state to vertical padding
			ld		vLineCnt,R5
			ld		hCharCnt,#hCharsTotal
			ld		isrVectL,#LOW(sync)
			iret
$$			ld		hCharCnt,#hCharsTotal/2
			ld		isrVectL,#LOW(sync)
preEqEnd	iret

; Vertical padding
vertPad		djnz	hCharCnt,vertPadEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(fetch)			; Set state to visible display
			ld		vLineCnt,R4
			ld		hCharCnt,#hCharsTotal
			ld		isrVectL,#LOW(sync)
			ld		R2,#HIGH(screenBuff)		; Return to first character
			ld		R3,#LOW(screenBuff)
			iret
$$			ld		hCharCnt,#hCharsTotal/2
			ld		isrVectL,#LOW(sync)
vertPadEnd	iret

; Visible display
fetch		ldx		SPIDATA,vBuffL
			djnz	hCharCnt,fetchTile			; End of line?
			sub		R3,#hChars					; Yes: Jump back to start of line
			sbc		R2,#0
			djnz	vLineCnt,$F					; 
			ld		state,#LOW(postEq)			; Set state to postEq
			ld		vLineCnt,#vSyncHLines
			ld		hCharCnt,#hCharsTotal/2
			ld		isrVectL,#LOW(sync)
			iret
$$			ld		R0,vLineCnt
			and		R0,#07h
			jr		ne,$F						; 8 lines done?
			add		R3,#hChars					; Yes: Jump to start of next line
			adc		R2,#0
$$			ld		hCharCnt,#hChars
			ld		isrVectL,#LOW(sync)
fetchTile	ld		R0,vLineCnt
			and		R0,#07h						; Select row of pixels in character
			or		R0,#HIGH(charSet)			; 
			ldx		R1,@RR2						; Get character from display buffer
			incw	RR2							; Advance to next character
			ldc		vBuffL,@RR0					; Load pixels in video buffer
			;ld		vBuffL,vLineCnt
			iret
; Post-equalizing pulses
postEq		djnz	hCharCnt,postEqEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(vSync)			; Set state to visible display
			ld		vLineCnt,#vSyncHLines
			ldx		T1RH,#HIGH(t1BroadSync)		; Set T1 interval for broad sync pulse
			ldx		T1RL,#LOW(t1BroadSync)
$$			ld		hCharCnt,#hCharsTotal/2
			ld		isrVectL,#LOW(sync)
postEqEnd	iret
; Broad sync pulses
vSync		djnz	hCharCnt,vSyncEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(preEq)			; Set state to preEq
			ld		vLineCnt,#vSyncHLines + vSyncPad
			ldx		T1RH,#HIGH(t1hSync)			; Set T1 interval for short sync pulse
			ldx		T1RL,#LOW(t1hSync)
$$			ld		hCharCnt,#hCharsTotal/2
			ld		isrVectL,#LOW(sync)
vSyncEnd	iret


org 1000h										; Only change high byte high nibble
charSet											; of charset origin!
			byte	FFh,FFh,FFh,FFh,FFh,00h		; [space] @ A B C [cursor]
org 1100h	
			byte	FFh,87h,99h,83h,C3h,00h
org 1200h	
			byte	FFh,7Bh,99h,99h,99h,00h
org	1300h	
			byte	FFh,6Bh,81h,99h,9Fh,00h
org 1400h	
			byte	FFh,0Bh,99h,83h,9Fh,00h
org 1500h	
			byte	FFh,FBh,99h,99h,9Fh,00h
org 1600h	
			byte	FFh,FBh,C3h,99h,99h,00h
org 1700h		
			byte	FFh,07h,E7h,83h,C3h,00h

if vSync - sync > 200
	warning "vSync label almost out of reach!"	; Only the isr vector's lower byte is updated
endif											; Therefore Vsync - sync <= 255
			
