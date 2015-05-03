; Filename: monovideo3.asm
; Author: Koen van Vliet <8by8mail@gmail.com>
; Description: Test with monochrome video using timers and SPI for shifting out pixels data
include "ez8.inc"
sysFreq		equ		20_000_000
hTime		equ		64
hSyncTime	equ		4

vBuff		equ		RR10
vBuffH		equ		R10
vBuffL		equ		R11
isrVect		equ		RR14
isrVectH	equ		R14
isrVectL	equ		R15
hCharCnt	equ		R12
vLineCnt	equ		R13
hChars		equ		36
cWidth		equ		8

t0Interval	var		hTime * sysFreq / (hChars * 1000_000)
t1hSync		equ		hSyncTime * sysFreq / 1000_000

DDR			equ		1
AF			equ		2

spiPrescaler	equ	2

if t0Interval < (cWidth + 1) * spiPrescaler * 2
	t0Interval	var	(cWidth + 1) * spiPrescaler * 2
	warning "Timing requirements not met! Overriding horizontal character count."
endif

if	cWidth = 8
	spiLen		equ		0
else
	spiLen		equ		cWidth
endif

vector	RESET = init
vector timer0 = isrT0
org 0200h
init		di									; Disable interrupts
			srp		#00h						; Setup working registers
			ldx		SPH,#00h					; Set stack pointer base address
			ldx		SPL,#FFh

initSpi		ldx		PCADDR,#DDR					; MOSI pin is output
			ldx		PCCTL,#~(1<<4)
			ldx		PCADDR,#AF					; Set alternate SPI functions
			ldx		PCCTL,#(1<<4)				; MOSI alternate function
			ldx		SPICTL,#(1<<1)|(1<<0)		; SPI Master enabled
			ldx		SPIMODE,#(spiLen << 2)		; Set amt. of bits per char
			ldx		SPIBRH,#HIGH(spiPrescaler)	; Setup dot clock
			ldx		SPIBRL,#LOW(spiPrescaler)

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
			
startVideo	ld		isrVectH,#HIGH(sync)
			ld		isrVectL,#LOW(sync)
			orx		T0CTL1,#(1<<7)				; T0 enabled	
			ei									; Enable interrupts
$$			; Do stuff
			jr		$B

isrT0		jp		@isrVect

sync		andx	T1CTL1,#~(1<<6)				; Sync active (LOW)
			orx		T1CTL1,#(1<<7)
			orx		T1CTL1,#(1<<6)
			ld		isrVectH,#HIGH(fetch)
			ld		isrVectL,#LOW(fetch)
			ld		vBuffL,#FFh					; Load black pixels in video buffer
			iret

fetch		ldx		SPIDATA,vBuffL
			djnz	hCharCnt,$F
			ld		hCharCnt,#hChars
			ld		isrVectH,#HIGH(sync)
			ld		isrVectL,#LOW(sync)
$$			;ldc		vBuffL,
			iret
			
