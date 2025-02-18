.global _start

timeout:			.word	0x001E8480	@ 2 million

seg_values:			.byte	0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71
seg_val_adr:		.word	seg_values	@ address of above array

MPCORE_PRIV_TIMER:	.word	0xFFFEC600	@ address of A9 private timer
HEX3_HEX0_BASE:		.word	0xFF200020	@ address of displays 0 to 3
HEX5_HEX4_BASE:		.word	0xFF200030	@ address of displays 4 to 5
SW_BASE:			.word	0xFF200040	@ address of slider switches
KEY_BASE:			.word	0xFF200050	@ address of push buttons

_udiv:
	@ if r1 is 0, infinite loop
	@cmp r1, #0							@ if r1 = 0:
	@hlt 0x0							@ 	halt
	
	mov r2, #0							@ clear register 2 for division
	mov r3, #0							@ clear register 3 for modulus
_div_loop:
	cmp r0, r1							@ if r0 ≥ r1:
	subge r0, r0, r1					@ 	r0 = r0 - r1
	addge r2, r2, #1					@ 	r2 = r2 + 1
	
	bgt _div_loop						@ goto div_loop
	
	mov r3, r0							@ put remainder in r3
	bx lr								@ goto lr

_start:
	ldr r0, =0							@ clear register 0
	ldr r1, =0							@ clear register 1
	ldr r2, =0							@ clear register 2
	ldr r3, =0							@ clear register 3
	
	ldr r4, timeout						@ timeout
	ldr r5, =0							@ centisecond (10ms) counter
	ldr r6, =0							@ lap time
	ldr r7, MPCORE_PRIV_TIMER			@ MPCore private timer base address
	ldr r8, HEX3_HEX0_BASE				@ displays 0 to 3 (in r8)
	ldr r8, HEX5_HEX4_BASE				@ displays 4 to 5 (purposefully in r8)
	ldr r8, SW_BASE						@ slider switches (purposefully in r8)
	ldr r8, KEY_BASE					@ push buttons (purposefully in r8)
	ldr r9, seg_val_adr					@ address of array
	ldr r10, =0							@ counting flag
	ldr r11, =0							@ unassigned
	ldr r12, =0							@ unassigned

_start_timer:
	ldr r7, MPCORE_PRIV_TIMER			@ MPCore private timer base address
	str r4, [r7]						@ put timeout into load of timer
	mov r4, #0b0011						@ I = 0, A = 1, E = 1
	str r4, [r7, #0x08]					@ set continue and enable bits of control of timer

_timer_loop:
	ldr r4, [r7, #0x0C]					@ set r4 to status of timer
	cmp r4, #0							@ if r4 = 0:
	beq _timer_loop						@ 	goto timer_loop
	str r4, [r7, #0x0C]					@ else: reset status of timer
	
	cmp r10, #1							@ if counter flag = 1:
	addeq r5, #1						@ 	add 1 to counter
_loop:
	@cmp r5, #360000					@ if counter = 60min * 60sec * 100cs
	@beq _loop							@ 	goto loop
	
	push {lr}							@ push the value of lr to the stack
	bl _read_switches					@ goto read_switches
	pop {lr}							@ pop the top value of the stack to lr
	
	push {lr}							@ push the value of lr to the stack
	bl _show_time						@ goto show_time
	pop {lr}							@ pop the top value of the stack to lr
	
	b _timer_loop						@ goto timer_loop

_read_switches:
	ldr r8, KEY_BASE					@ save push buttons address to r8
	ldr r11, [r8]						@ read value from push buttons
	
	and r12, r11, #0b0001				@ read start bit value
	cmp r12, #0b0001					@ if start bit value = 1:
	ldreq r10, =1						@ 	counting flag = 1
	
	and r12, r11, #0b0010				@ read stop bit value
	cmp r12, #0b0010					@ if stop bit value = 1:
	ldreq r10, =0						@ 	counting flag = 0
	
	and r12, r11, #0b0100				@ read lap bit value
	cmp r12, #0b0100					@ if lap bit value = 1:
	moveq r6, r5						@ 	lap time = counter
	
	and r12, r11, #0b1000				@ read clear bit value
	cmp r12, #0b1000					@ if clear bit value = 1:
	ldreq r10, =0						@ counting flag = 0
	ldreq r5, =0						@ counter = 0
	ldreq r6, =0						@ lap time = 0
	
	bx lr								@ return

_show_time:
	ldr r8, SW_BASE						@ save slider switches address to r8
	ldr r11, [r8]						@ read value from slider switches
	and r11, #0x1						@ read display switch value
	
	mov r0, r5							@ numerator: counter
	cmp r11, #0x1						@ if display switch = 1:
	subeq r0, r6						@ subtract lap time from counter
	
	@ display minutes:
	ldr r1, =6000						@ denominator: 60sec * 100cs = 6000
	push {lr}							@ push the value of lr to the stack
	bl _udiv							@ do division
	pop {lr}							@ pop the top value of the stack to lr
	
	mov r11, r3							@ save seconds in register 11
	
	mov r0, r2							@ numerator: minutes
	ldr r1, =10							@ denominator: 10
	push {lr}							@ push the value of lr to the stack
	bl _udiv							@ do division
	pop {lr}							@ pop the top value of the stack to lr
	
	ldrb r2, [r9, r2]					@ save array value in r2
	ldrb r3, [r9, r3]					@ save array value in r3
	lsl r2, #8							@ shift r2 left by 1 byte
	add r2, r3							@ r2 = r2 + r3
	
	ldr r8, HEX5_HEX4_BASE				@ save display address to r8
	str r2, [r8]						@ save values to seg-display
	
	@ display seconds:
	mov r0, r11							@ numerator: seconds
	ldr r1, =10							@ denominator: 10
	push {lr}							@ push the value of lr to the stack
	bl _udiv							@ do division
	pop {lr}							@ pop the top value of the stack to lr
	
	ldrb r11, [r9, r3]					@ save array value in r11
	ror r11, #8							@ rotate r11 right by 1 byte
	
	mov r0, r2							@ numerator: seconds remainder
	ldr r1, =10							@ denominator: 10
	push {lr}							@ push the value of lr to the stack
	bl _udiv							@ do division
	pop {lr}							@ pop the top value of the stack to lr
	
	ldrb r12, [r9, r3]					@ save array value in r12
	add r11, r12						@ r11 = r11 + r12
	ror r11, #8							@ rotate r11 right by 1 byte
	
	mov r0, r2							@ numerator: tenth second remainder
	ldr r1, =10							@ denominator: 10
	push {lr}							@ push the value of lr to the stack
	bl _udiv							@ do division
	pop {lr}							@ pop the top value of the stack to lr
	
	ldrb r12, [r9, r3]					@ save array value in r12
	add r11, r12						@ r11 = r11 + r12
	ror r11, #8							@ rotate r11 right by 1 byte
	ldrb r12, [r9, r2]					@ save array value in r12
	add r11, r12						@ r11 = r12 + r11
	ror r11, #8							@ rotate r11 right by 1 byte
	
	ldr r8, HEX3_HEX0_BASE				@ save display address to r8
	str r11, [r8]						@ save values to seg-display
	
	bx lr								@ return
