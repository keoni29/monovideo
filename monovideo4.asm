; Filename: monovideo4.asm
; Author: Koen van Vliet <8by8mail@gmail.com>
; Description: Test with monochrome video using timers and SPI for shifting out pixels data
include "ez8.inc"

; Setup video generator
		sysFreq		equ		20_000_000 
		rFreq		equ		50

		hChars		equ		21			; Character columns
		vChars		equ		30			; Character rows
		hBorderL	equ		2			; Left horizontal border width
		hBorderR	equ		2			; Right horizontal border width
		cWidth		equ		7			; Width of a character
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
			vSyncPad	equ		1;1
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
			
startVideo	ld		R4,#C0h
			ld		R5,#0Dh
			ld		state,#LOW(preEq)			; Set state to preEq
			ld		hCharCnt,#hChars/2
			ld		vLineCnt,#vSyncHLines + vSyncPad
			ld		isrVectH,#HIGH(sync)
			ld		isrVectL,#LOW(sync)
			orx		T0CTL1,#(1<<7)				; T0 enabled	
			ei									; Enable interrupts
			
$$			; Do stuff
			jr		$B

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
			ld		hCharCnt,#hChars
			ld		isrVectL,#LOW(sync)
			iret
$$			ld		hCharCnt,#hChars/2
			ld		isrVectL,#LOW(sync)
preEqEnd	iret

; Vertical padding
vertPad		djnz	hCharCnt,vertPadEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(fetch)			; Set state to visible display
			ld		vLineCnt,R4
			ld		hCharCnt,#hChars
			ld		isrVectL,#LOW(sync)
			ld		R2,#HIGH(screenBuff)		; Return to first character
			ld		R3,#LOW(screenBuff)
			iret
$$			ld		hCharCnt,#hChars/2
			ld		isrVectL,#LOW(sync)
vertPadEnd	iret

; Visible display
fetch		ldx		SPIDATA,vBuffL
			djnz	hCharCnt,fetchTile			; End of line?
			sub		R3,#hChars					; Yes: Jump back to start of line
			sbc		R2,#0
			djnz	vLineCnt,$F					; 
			ld		state,#LOW(vertPad2)		; Set state to vertical padding
			ld		vLineCnt,R5
			ld		hCharCnt,#hChars
			ld		isrVectL,#LOW(sync)
			iret
$$			ld		R0,vLineCnt
			rr		R0
			and		R0,#07h
			jr		ne,$F						; 16 lines done?
			add		R3,#hChars					; Yes: Jump to start of next line
			adc		R2,#0
$$			ld		hCharCnt,#hChars
			ld		isrVectL,#LOW(sync)
fetchTile	ld		R0,vLineCnt
			rr		R0
			and		R0,#07h						; Select row of pixels in character
			or		R0,#HIGH(charSet)			; 
			ldx		R1,@RR2						; Get character from display buffer
			incw	RR2							; Advance to next character
			ldc		vBuffL,@RR0					; Load pixels in video buffer
			;ld		vBuffL,vLineCnt
			iret
			
; Vertical padding bottom
vertPad2	djnz	hCharCnt,vertPad2End
			djnz	vLineCnt,$F
			ld		state,#LOW(postEq)			; Set state to postEq
			ld		vLineCnt,#vSyncHLines
			ld		hCharCnt,#hChars/2
			ld		isrVectL,#LOW(sync)
			iret
$$			ld		hCharCnt,#hChars/2
			ld		isrVectL,#LOW(sync)
vertPad2End	iret

; Post-equalizing pulses
postEq		djnz	hCharCnt,postEqEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(vSync)			; Set state to visible display
			ld		vLineCnt,#vSyncHLines
			ldx		T1RH,#HIGH(t1BroadSync)		; Set T1 interval for broad sync pulse
			ldx		T1RL,#LOW(t1BroadSync)
$$			ld		hCharCnt,#hChars/2
			ld		isrVectL,#LOW(sync)
postEqEnd	iret
; Broad sync pulses
vSync		djnz	hCharCnt,vSyncEnd
			djnz	vLineCnt,$F
			ld		state,#LOW(preEq)			; Set state to preEq
			ld		vLineCnt,#vSyncHLines + vSyncPad
			ldx		T1RH,#HIGH(t1hSync)			; Set T1 interval for short sync pulse
			ldx		T1RL,#LOW(t1hSync)
$$			ld		hCharCnt,#hChars/2
			ld		isrVectL,#LOW(sync)
vSyncEnd	iret


org 1000h										; Only change high byte high nibble
charSet											; of charset origin!
		byte FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,9Fh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh,FFh
org 1100h
		byte FFh,E7h,FFh,93h,CFh,73h,81h,FFh,E7h,E7h,FFh,FFh,CFh,FFh,CFh,3Fh,87h,03h,03h,87h,F3h,87h,87h,CFh,83h,83h,FFh,CFh,E3h,FFh,C7h,CFh,87h,33h,07h,87h,0Fh,03h,3Fh,87h,33h,87h,8Fh,33h,03h,39h,33h,87h,3Fh,E3h,33h,87h,CFh,87h,CFh,39h,33h,CFh,03h,87h,F9h,E1h,FFh,03h
org 1200h
		byte FFh,FFh,FFh,93h,07h,33h,33h,FFh,CFh,F3h,99h,E7h,CFh,FFh,CFh,9Fh,33h,CFh,9Fh,33h,F3h,33h,33h,CFh,39h,39h,FFh,E7h,CFh,FFh,F3h,FFh,3Bh,33h,33h,33h,27h,3Fh,3Fh,33h,33h,CFh,27h,27h,3Fh,39h,33h,33h,3Fh,87h,27h,33h,CFh,33h,87h,11h,33h,CFh,3Fh,9Fh,F3h,F9h,FFh,FFh
org 1300h
		byte FFh,FFh,FFh,01h,F3h,9Fh,31h,FFh,9Fh,F9h,C3h,E7h,FFh,FFh,FFh,CFh,33h,CFh,CFh,F3h,01h,F3h,33h,CFh,39h,F9h,E7h,E7h,9Fh,83h,F9h,CFh,3Fh,33h,33h,3Fh,33h,3Fh,3Fh,33h,33h,CFh,E7h,0Fh,3Fh,39h,23h,33h,3Fh,33h,0Fh,F3h,CFh,33h,33h,01h,87h,CFh,9Fh,9Fh,E7h,F9h,FFh,FFh
org 1400h
		byte FFh,E7h,FFh,93h,87h,CFh,8Fh,FFh,9Fh,F9h,00h,81h,FFh,83h,FFh,E7h,13h,CFh,E7h,C7h,33h,F3h,07h,CFh,83h,81h,FFh,FFh,3Fh,FFh,FCh,E7h,23h,03h,07h,3Fh,33h,0Fh,0Fh,23h,03h,CFh,E7h,1Fh,3Fh,29h,03h,33h,07h,33h,07h,87h,CFh,33h,33h,29h,CFh,87h,CFh,9Fh,CFh,F9h,BBh,FFh
org 1500h
		byte FFh,E7h,99h,01h,3Fh,E7h,87h,CFh,9Fh,F9h,C3h,E7h,FFh,FFh,FFh,F3h,23h,8Fh,F3h,F3h,C3h,07h,3Fh,E7h,39h,39h,FFh,FFh,9Fh,83h,F9h,F3h,23h,33h,33h,3Fh,33h,3Fh,3Fh,3Fh,33h,CFh,E7h,0Fh,3Fh,01h,03h,33h,33h,33h,33h,3Fh,CFh,33h,33h,39h,87h,33h,E7h,9Fh,9Fh,F9h,93h,FFh
org 1600h
		byte FFh,E7h,99h,93h,83h,33h,33h,E7h,CFh,F3h,99h,E7h,FFh,FFh,FFh,F9h,33h,CFh,33h,33h,E3h,3Fh,33h,33h,39h,39h,E7h,E7h,CFh,FFh,F3h,33h,33h,87h,33h,33h,27h,3Fh,3Fh,33h,33h,CFh,E7h,27h,3Fh,11h,13h,33h,33h,33h,33h,33h,CFh,33h,33h,39h,33h,33h,F3h,9Fh,3Fh,F9h,C7h,FFh
org 1700h
		byte FFh,E7h,99h,93h,CFh,3Bh,87h,F3h,E7h,E7h,FFh,FFh,FFh,FFh,FFh,FFh,87h,CFh,87h,87h,F3h,03h,87h,03h,83h,83h,FFh,FFh,E3h,FFh,C7h,87h,87h,CFh,07h,87h,0Fh,03h,03h,87h,33h,87h,C3h,33h,3Fh,39h,33h,87h,07h,87h,07h,87h,03h,33h,33h,39h,33h,33h,03h,87h,FFh,E1h,EFh,FFh

if vSync - sync > 200
	warning "vSync label almost out of reach!"	; Only the isr vector's lower byte is updated
endif											; Therefore Vsync - sync <= 255
			
