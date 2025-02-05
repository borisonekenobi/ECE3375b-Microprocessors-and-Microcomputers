@ Your first program
.global _start

@ you can put an array of data into memory here if you want
.data
@ as an example: the values [1,2,3,4] will be sequentially stored in memory as bytes
seg_values: .byte 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71

@ now start the code
.text
_start:
	ldr r0, SW_BASE
	ldr r2, array_adr
	ldr r4, HEX3_HEX0_BASE
	ldr r6, DELAY_LENGTH
	mov r8, #0
	@ initialize registers here as necessary
	
@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ START OF MAIN PROGRAM @@	
_main_loop:

	@ put main code here
	@ you can call a subroutine using code like this:
	@ bl <subroutine_name>
	eor r8, #0x0f
	
	bl _read_switches
	bl _display_hex
	
	mov r5, r6
	bl _delay_loop
	@ loop endlessly
	
	b _main_loop
@@@ END OF MAIN PROGRAM @@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@	


@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ START OF SUBROUTINES @@@	
@ do nothing for a while
_delay_loop:
	@ check if counter reached 0
	cmp r5, #0
	@ branch back to main loop if it is zero
	beq _main_loop
	@ otherwise reduce loop counter by one
	sub r5, #1
	@ cycle through delay loop again
	b _delay_loop

_display_off:
	mov r3, #0
	str r3, [r4]
	mov r5, r6
	bl _delay_loop

_display_hex:
	@ put code to display value on hex display here		

	cmp r8, #0
	beq _display_off
	and r1, r8

	@@@ a trick for getting the hex code for a digit:
	@@@
	@@@ you can access an element of an array using offsets
	@ ldrb r0, [r1, #5]
	@@@ if array base address is in r1, this accesses the 5th byte of the array
	@@@ note that the offset can even be a register
	ldrb r3, [r2, r1]
	@@@ this accesses the nth byte in array at r1, where n is in register r2
	@@@
	@@@ if you don't understand this trick, then there are other ways to do it
	@@@ a lot of compare statements, for example
	@ cmp r1, #0
	@ moveq r2, [code for displaying #0 on hex display]
	@@@ etc.	
	
	str r3, [r4]
	
	@ return from subroutine
	bx lr
	
_read_switches:
	@ put code to read from switches here
	ldr r1, [r0]
	@ return from subroutine
	bx lr
@@@ END OF SUBROUTINES @@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@


@ labels for constants and addresses
LED_BASE:		.word	0xFF200000
HEX3_HEX0_BASE:	.word	0xFF200020
SW_BASE:		.word	0xFF200040
@ feel free to add more if necessary
@ for example, if you put an array in the .data block above,
@ find the address of that array here
array_adr:		.word    seg_values
DELAY_LENGTH:	.word	70000000