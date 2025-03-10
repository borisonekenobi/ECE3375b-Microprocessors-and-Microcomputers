.global _start

ADC_BASE:	.word	0xFF204000	@ address of A/D Converter
GPIO_BASE:	.word	0xFF200060	@ address for GPIO
SW_BASE:	.word	0xFF200040	@ address for slider switches

TWELVE:		.word	0x00000FFF	@ twelve bits on (0000 1111 1111 1111)
LED_VALUE:	.word	0x00000199	@ ⌊(2¹² - 1) / 10⌋ = 409 = 0x199

_start:
	ldr r0, =0					@ clear register 0
	ldr r1, =0					@ clear register 1
	ldr r2, =0					@ clear register 2
	ldr r3, =0					@ clear register 3
	
	ldr r4, ADC_BASE			@ A/D Converter
	ldr r5, GPIO_BASE			@ GPIO
	ldr r6, SW_BASE				@ slider switches
	ldr r7, TWELVE				@ twelve bit mask (0000 1111 1111 1111)
	ldr r8, LED_VALUE			@ 409 in hex = 0x199
	ldr r9, [r6]				@ slider switches value
	ldr r10, [r4]				@ ADC value
	ldr r11, =0					@ GPIO output
	ldr r12, =0					@ unassigned
	
	ldr r0, =0x3ff				@ ten bit mask (0000 0011 1111 1111)
	str r0, [r5, #4]			@ write to directional control register

_main_loop:
	ldr r9, [r6]				@ load value of slider switches
	and r9, #1					@ only keep bit 0
	cmp r9, #0					@ if r9 = 0:
	ldreq r10, [r4, #0x00]		@	load value of A/D
	ldrne r10, [r4, #0x04]		@ else: load value of (A/D + 4)
	
	tst r10, #(1 << 15)			@ if bit 15 of r10 ≠ 1:
	@beq _main_loop				@ 	goto _main_loop
	
	and r10, r7					@ only keep bits 0-11
	ldr r11, =0					@ reset value of r11

_sub_loop:
	subs r10, r8				@ r10 - 0x199 and if r10 > 0:
	lslgt r11, #1				@ 	left shift r11 by 1 bit
	addgt r11, #1				@ 	r11 + 1
	bgt _sub_loop				@	goto _sub_loop
	
	str r11, [r5]				@ store r11 in GPIO
	b _main_loop				@ goto _main_loop
