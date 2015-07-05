; Calculate timing parameters
		leftChars	equ	2
		rightChars	equ 1
		hCharsTotal equ	hChars + leftChars + rightChars
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
			vLines		equ		288
		elseif rFreq = 60
			hTime		equ		63
			hSyncTime	equ		4
			bPorchTime	equ		4
			fPorchTime	equ		2
			vSyncHLines	equ		6
			vSyncPad	equ		240
			vLines		equ		
		else
			error	"Unknown frequency"
		endif

		t0Interval		var		hTime * sysFreq / (hCharsTotal * 1000_000)
		t1hSync			equ		hSyncTime * sysFreq / 1000_000
		t1BroadSync		equ		(t0Interval * (hCharsTotal / 2)) - t1hSync

		;if t0Interval < (cWidth + 1) * spiPre * 2
		if hCharsTotal > (hTime * 25) / ((cWidth + 1) * spiPre * 2)
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
		lineBuff	equ		10h					; Line buffer
		userVars	equ		lineBuff + hChars	; Start of user variables
		
		
		screenBuff	equ		200h