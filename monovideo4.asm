; Filename: monovideo4.asm
; Author: Koen van Vliet <8by8mail@gmail.com>
; Description: Test with monochrome video using timers and SPI for shifting out pixels data
include "ez8.inc"
; Setup video generator
		sysFreq		equ		25_000_000;20_000_000 
		rFreq		equ		50

		hChars		equ		28	;28 stable		; Character columns
		vChars		equ		30			; Character rows
		hBorderL	equ		2			; Left horizontal border width
		hBorderR	equ		2			; Right horizontal border width
		cWidth		equ		8			; Width of a character
		cHeight		equ		8			; Height of a character

		spiPre		equ	2

include "monovideo4.inc"

vector	RESET = init
vector timer0 = isrT0
org 0200h
init		di									; Disable interrupts
			srp		#00h						; Setup working registers
			ldx		SPH,#00h					; Set stack pointer base address
			ldx		SPL,#FFh
			ld		R6,#2
			call	clrBuff						; Clear display buffer
			
			ld		R2,#HIGH(testScreen)
			ld		R3,#LOW(testScreen)
			call	puts
			
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
			ldx		T1CTL1,#(1<<6) | (1 << 4)	; One-shot mode. Sync is inactive (HIGH)
												; pre=f/4

initGPIO	ldx		PCADDR,#AF					; T1OUT alternate function enable
			orx		PCCTL,#(1<<1)			
			
startVideo	ld		R4,#EFh
			ld		R5,#23h
			ld		R6,#19h
			ld		state,#LOW(preEq)			; Set state to preEq
			ld		hCharCnt,#hCharsTotal/2 - leftChars - rightChars
			ld		vLineCnt,#vSyncHLines + vSyncPad
			ld		isrVectH,#HIGH(sync)
			ld		isrVectL,#LOW(sync)
			orx		T0CTL1,#(1<<7)				; T0 enabled	
			ei									; Enable interrupts
			
$$			; Do stuff
			jr		$B

puts		ld		R0,#HIGH(screenBuff)
			ld		R1,#LOW(screenBuff)
$$			ldc		R4,@RR2
			cp		R4,#0
			jr		z,putsEnd
			sub		R4,#32						; Subtract ascii offset
			ldx		@RR0,R4
			incw	RR0
			incw	RR2
			jr		$B
putsEnd		ret

clrBuff		ld		R0,#HIGH(screenBuff)
			ld		R1,#LOW(screenBuff)
$$			ld		R2,R1
			and		R2,#63
			ldx		@RR0,R2
			incw	RR0
			cp		R1,#LOW(screenBuff+hChars*vChars)
			cpc		R0,#HIGH(screenBuff+hChars*vChars)
			jr		ne,$B
			ret

isrT0		jp		@isrVect

align 256
sync
backPorch	ld		isrVectL,#LOW(backBor1)
			sub		R3,#hChars					; Yes: Jump back to start of line
			sbc		R2,#0
			ld		R0,vLineCnt
			and		R0,#07h
			jr		ne,$F						; 8 lines done?
			add		R3,#hChars - 1					; Yes: Jump to start of next line
			adc		R2,#0
$$			iret

backBor1	ld		isrVectL,#LOW(hSync)
			incw	RR2							; Advance to next character
			ld		R0,vLineCnt
			and		R0,#07h						; Select row of pixels in character
			or		R0,#HIGH(charSet)			; 
			iret
			
hSync		andx	T1CTL1,#~(1<<6)				; Sync active (LOW)
			orx		T1CTL1,#(1<<7)				; Start sync pulse timer
			orx		T1CTL1,#(1<<6)
			ld		isrVectL,#LOW(frontPorch)
			iret
doVSync		andx	T1CTL1,#~(1<<6)				; Sync active (LOW)
			orx		T1CTL1,#(1<<7)				; Start sync pulse timer
			orx		T1CTL1,#(1<<6)
			ld		isrVectL,state
			ld		hCharCnt,#hCharsTotal/2 - 1
			iret

frontPorch	ld		isrVectL,#LOW(frontBor1)
			ld		vBuffL,#FFh					; Load black pixels in video buffer
			iret
frontBor1	ld		isrVectL,#LOW(frontBor2)
			ld		vBuffL,#FFh
			iret
frontBor2	ld		isrVectL,#LOW(frontBor3)
			ld		vBuffL,#FFh
			iret
frontBor3	ld		isrVectL,#LOW(frontBor4)
			ld		vBuffL,#FFh
			iret
frontBor4	ld		isrVectL,state
			ld		vBuffL,#FFh
			ld		hCharCnt,#hChars
			iret
			
; Pre-equalizing pulses
preEq		djnz	hCharCnt,preEqEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(vertPad)			; Set state to vertical padding
			ld		vLineCnt,R5
			;ld		hCharCnt,#hChars
			ld		isrVectL,#LOW(sync)
			iret
$$			;ld		hCharCnt,#hCharsTotal/2 - 1
			ld		isrVectL,#LOW(doVSync)
preEqEnd	iret

; Vertical padding
vertPad		djnz	hCharCnt,vertPadEnd
			;ld		hCharCnt,#hChars
			ld		isrVectL,#LOW(sync)
			djnz	vLineCnt,$F
			ld		state,#LOW(fetch)			; Set state to visible display
			ld		vLineCnt,R4
			iret
$$			ld		R2,#HIGH(screenBuff + hChars + hChars - 2); Return to first character
			ld		R3,#LOW(screenBuff + hChars + hChars - 2)
vertPadEnd	iret



; Visible display
fetch		ldx		SPIDATA,vBuffL
			djnz	hCharCnt,fetchTile			; End of line?
			ld		isrVectL,#LOW(sync)
			djnz	vLineCnt,$F					; 
			ld		state,#LOW(vertPad2)		; Set state to vertical padding
			ld		vLineCnt,R6
$$			iret
fetchTile	ldx		R1,@RR2						; Get character from display buffer
			incw	RR2							; Advance to next character
			ldc		vBuffL,@RR0					; Load pixels in video buffer
			;ld		vBuffL,vLineCnt
			;ld		vBuffL,#00h					; Load white pixels
			iret


			
			
; Vertical padding bottom
vertPad2	djnz	hCharCnt,vertPad2End
			ld		isrVectL,#LOW(sync)
			djnz	vLineCnt,$F
			ld		state,#LOW(postEq)			; Set state to postEq
			ld		vLineCnt,#vSyncHLines
			;ld		hCharCnt,#hCharsTotal/2 - 1
			iret
$$			;ld		hCharCnt,#hChars
vertPad2End	iret

; Post-equalizing pulses
postEq		djnz	hCharCnt,postEqEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(vSync)			; Set state to visible display
			ld		vLineCnt,#vSyncHLines
			ldx		T1RH,#HIGH(t1BroadSync)		; Set T1 interval for broad sync pulse
			ldx		T1RL,#LOW(t1BroadSync)
$$			;ld		hCharCnt,#hCharsTotal/2 - 1
			ld		isrVectL,#LOW(doVSync)
postEqEnd	iret
; Broad sync pulses
vSync		djnz	hCharCnt,vSyncEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(preEq)			; Set state to preEq
			ld		vLineCnt,#vSyncHLines + vSyncPad
			ldx		T1RL,#LOW(t1hSync)			; Set T1 interval for short sync pulse
$$			;ld		hCharCnt,#hCharsTotal/2 - 1
			ld		isrVectL,#LOW(doVSync)
vSyncEnd	iret


if vSync - sync > 200
	warning "vSync label almost out of reach!"	; Only the isr vector's lower byte is updated
endif											; Therefore Vsync - sync <= 255
			
xref charSet

testScreen
	asciz	"0000:00 01 02 03 04 05 06 07"