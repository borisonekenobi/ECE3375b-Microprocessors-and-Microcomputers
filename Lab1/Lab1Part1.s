.global _start

_start:

	@ initialize delay length
	ldr r3, DELAY_LENGTH
	
	@ initialize pointer for LEDs
	ldr r4, LED_BASE
	@ initialize status of LEDs
	mov r1, #1
	
	@ turn on first LED and turn off all others
	str r0, [r4]

@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ START OF MAIN PROGRAM @@	
@ endless main loop
_main_loop:
	@ toggle LEDs using exclusive or (XOR)
	@ but ARM calls it ``eor'' instead of ``xor''
	@ probably for... reasons?
	eor r1, #1
	@ write to LEDs
	str r1, [r4]
	
	@ initialize loop counter to DELAY_LENGTH
	mov r0, r3

@ do nothing for a while
_delay_loop:
	@ check if counter reached 0
	cmp r0, #0
	@ branch back to main loop if it is zero
	beq _main_loop
	@ otherwise reduce loop counter by one
	sub r0, #1
	@ cycle through delay loop again
	b _delay_loop

@@@ END OF MAIN PROGRAM @@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@	

@ labels for constants and addresses
DELAY_LENGTH:	.word	70000000
LED_BASE:		.word	0xFF200000