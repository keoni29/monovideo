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

xdef charSet