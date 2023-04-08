	.data

	.global prompt
	.global uart_interrupt_init
	.global gpio_interrupt_init
	.global UART0_Handler
	.global Switch_Handler
	.global Timer_Handler		; This is needed for Lab #6
	.global output_character	; This is from your Lab #6 Library
	.global read_string		; This is from your Lab #6 Library
	.global output_string		; This is from your Lab #6 Library
	.global uart_init		; This is from your Lab #6 Library
	.global simple_read_character
	.global lab6
	.global output_string_nw
	.global parse_string
	.global int2string_nn
	.global output_string_withlen_nw
	.global tiva_pushbtn_init
	.global int2string

prompt:	.string "Press SW1 or a key (q to quit)", 0
data_block: .word 0
spacesMoved_block: .word 0

output: .string "Total Moves Made: ", 0 
top_bottom_borders: .string " --------------------", 0
side_borders: .string "|                    |", 0 ;The board is 20 characters by 20 characters in size (actual size inside the walls).
cursor_position: .string 27, "[" ;set up a cursor position variable that will be 10 - 10
home: .string 27, "[1;1H",0
clear_screen: .string 27, "[2J",0 ; clear screen cursor position moved to home row 0, line 0zzz
backspace:	.string 27, "[08", 0
asterisk:	.string 27, "*", 0
num_1_string: .string 27, "   "
num_2_string: .string 27, "   "
saveCuror:	  .string 27, "[s",0
restoreCuror: .string 27, "[u",0
center: 	  .string 27, "[10;10H", 0

	.text



ptr_to_prompt:				.word prompt
prt_to_dataBlock: 			.word data_block
prt_to_spacesMoved_block:	.word spacesMoved_block

ptr_to_top_bottom_borders:		.word top_bottom_borders
ptr_to_side_borders:		.word side_borders
ptr_to_cursor_position: 	.word cursor_position
ptr_to_clear_screen: 		.word clear_screen
ptr_to_output:				.word output
ptr_to_backspace:				.word backspace
ptr_to_asterisk:				.word asterisk
ptr_to_home: 					.word home
ptr_num_1_string: 				.word num_1_string
ptr_num_2_string: 				.word num_2_string
ptr_saveCuror:					.word saveCuror
ptr_restoreCuror:				.word restoreCuror
ptr_center:						.word center

;***************Data packet orginization*******************************
;	|LocationX	|LocationY	|SW1Presses	|Direction| EndBit|
;	0		    8		    16		    24-25	  31
;**********************************************************************
lab6:	; This is your main routine which is called from your C wrapper
	PUSH {lr}   		; Store lr to stack
	
s	LDR r4, ptr_to_top_bottom_borders ; load border string into registers
	LDR r5, ptr_to_side_borders ;load string into register
	BL uart_init
	bl tiva_pushbtn_init
	BL uart_interrupt_init
	BL gpio_interrupt_init
	
	;Clear screen
	LDR r0, ptr_to_clear_screen ;clear the screen and moves cursor to 0,0
	BL output_string_nw

	;Updata locationX and locationY to be at center
	LDR r0, ptr_center ;load the datablock into r0
	bl output_string_nw
	MOV r1, #10 ;move 10 into r1 as intial location will be 10,10 as that is the middle of a 20x20 board
	ldr r0,prt_to_dataBlock
	;LocationX
	STRB r1, [r0,#0]
	;LocationY
	STRB r1, [r0,#1]


	;Init speed
	MOV r2, #1
	STRB r2, [r0,#2]
	;Start game
	BL Timer_init

inf_loop:
	LDR r0, prt_to_dataBlock
	LDRB r1, [r0, #3]
	LSR r1, #7
	CMP r1, #1
	BNE inf_loop


	;Disable timer
	;disable GPTMCTL TAEN (1)->1st bit of:  0x4003000C
	MOV r0, #0x000C
	MOVT r0, #0x4003
	ldr r1, [r0]
	mvn r2, #1
	and r1,r1,r2
	str r1, [r0]

;PRINT ENDING PROMPT HERE
a	ldr r0, ptr_to_clear_screen
	bl output_string
	ldr r0, ptr_to_home
	bl output_string

	LDR r0, ptr_to_output
	BL output_string_nw
	LDR r0, prt_to_spacesMoved_block
	LDR r0, [r0]
	LDR r1, ptr_num_1_string
	BL int2string ;outputs string into r1
	ldr r0, ptr_num_1_string
	;MOV r0, r1 ;set up r0 as the argument for output string by moving the string with the number of moves into r0
	BL output_string



	;poll until endbit is 1
	POP {lr}
	MOV pc, lr

;Timer_handler(print_screen) handler subroutine
;Desction
;	Refreshes the player location and borders upon a timer interrupts
Timer_Handler:

	; Your code for your Timer handler goes here.  It is not needed
	; for Lab #5, but will be used in Lab #6.  It is referenced here
	; because the interrupt enabled startup code has declared Timer_Handler.
	; This will allow you to not have to redownload startup code for
	; Lab #6.  Instead, you can use the same startup code as for Lab #5.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler.

	;Preserve registers
	PUSH {lr}
	PUSH {r4-r11}

	;Clear timer interrupt (1)->0th bit of 0x40030024
	MOV r0 ,#0x0024
	MOVT r0, #0x4003
	LDR r1, [r0]
	ORR r1, #1
	str r1,[r0]

	mov r5, #1

	;Save cursor position
	ldr r0,ptr_saveCuror
	bl output_string_nw


	;Clear screen
	LDR r0, ptr_to_clear_screen ;clear the screen and moves cursor to 0,0
	BL output_string_nw
	LDR r0, ptr_to_home
	BL output_string_nw

;Print_borders
print_borders:
    LDR r0, ptr_to_top_bottom_borders ;move top and bottom border to the register used as an argument in output_string
    BL output_string ; branch to output_string

    MOV r1, #0 ;move 0 into r1 (or any free register) to use as a counter

    LDR r0, ptr_to_side_borders ; move side borders to the register used as an argument in output_string (could do it in the loop but this is a bit faster i think)
    BL side_loop ; branch to loop that will print out the sides of the board

side_loop:
    CMP r1, #20  ;(or #21?) compare to see if we have entered the loop 20 times (if we have printed all the side borders)
    BEQ bottom ;if all the sides are done we just have to print the bottom border

	push {r0-r4}
	LDR r0, ptr_to_side_borders
    BL output_string ;r0 should already hold the side borders
	pop {r0-r4}
    ADD r1, r1, #1 ;increment counter
    B side_loop ;Branch back to the loop to print the next line or

bottom:
    LDR r0, ptr_to_top_bottom_borders ;move top and bottom border to the register used as an argument in output_string
    BL output_string ; branch to output_string


;Restore cursor
	ldr r0,ptr_restoreCuror
	bl output_string_nw

;update_location
	;Load locationX and locationY
	ldr r0, prt_to_dataBlock

	;LocationX
	LDRB r1, [r0,#0]

	;LocationYs
	LDRB r2, [r0,#1]
	
	;Load direction
	LDRB r3, [r0,#3]

	;Load speed
	LDRB r4, [r0,#2]

	;Parse direction
	cmp r3, #0
	bne not_zero
	;update locationX & Y
	add r1, r1,r4

	;Store location
	STRB r1, [r0,#0]
	mov r0, r4
	bl movCursor_right
	;branch to end of if
	b end_timer_handler

	;r5 will store pointer to string
	;r6 will store index to replace
not_zero:
	cmp r3, #1
	bne not_one
	;update locationX & Y
	sub r1, r1,r4
	;Store location
	STRB r1, [r0,#0]
	mov r0,r4
	bl movCursor_left
	b end_timer_handler

not_one:
	cmp r3, #2
	bne not_two
	;update locationX & Y
	add r2, r2,r4
	;Store location
	STRB r2, [r0,#1]
	mov r0, r4
	bl movCursor_up

	b end_timer_handler

not_two:
	cmp r3, #3
	bne end_timer_handler
	;update locationX & Y
	SUB r2, r2,r4
	;Store location
	STRB r2, [r0,#1]
	;Change cursor back to end of string
	;Pop registers
	mov r0, r4
	bl movCursor_down

end_timer_handler:

insert_asterisk:
	MOV r0, #42
	bl output_character
	;Move back
	mov r0, #8
	bl output_character


	;Incrament spaces
	ldr r0, prt_to_dataBlock
	ldrb r2, [r0,#2]
	ldr r1, prt_to_spacesMoved_block
	ldr r0,[r1]
	add r0,r0, r2
	str r0,[r1]

	;Check borders
	bl border_check
	POP {r4-r11}
	POP {lr}
	BX LR


	
Timer_init:
	PUSH {lr}
	;Enable clock (1)->0th bit of: 0x400FE604
	MOV r0, #0xE604
	MOVT r0, #0x400F
	ldr r1, [r0]
	ORR r1, r1, #1
	str r1, [r0]

	;disable GPTMCTL TAEN (1)->1st bit of:  0x4003000C
	MOV r0, #0x000C
	MOVT r0, #0x4003
	ldr r1, [r0]
	mvn r2, #1
	and r1,r1,r2
	str r1, [r0]

	;enable 32 mbit mode (1)->1st bit of:  0x40030000
	MOV r0, #0x0000
	MOVT r0, #0x4003
	ldr r1, [r0]
	mvn r2,  #1
	and r1, r2,r1
	str r1, [r0]

	;Put timer into Periodic mode GPTMTAMR (1)->2nd bit 0x40030004
	MOV r0, #0x0004
	MOVT r0, #0x4003
	ldr r1, [r0]
	orr r1, r1, #2
	MVN r2, #1
	AND r1,r1,r2
	str r1, [r0]


	;Setup Interrupt interval period (GPTMTAILR) register0x40030028
	;set to 16M -> 16,000,000-> 0xF42400 ticks per cycle
	MOV r0, #0x0028
	MOVT r0, #0x4003
	ldr r1, [r0]
	MOV r1, #0x2400
	MOVT r1, #0x00F4
	str r1, [r0]

	;Setup interrup intervbal to interrupt the processor 1->0th bit of 0x40030018
	MOV r0, #0x0018
	MOVT r0, #0x4003
	ldr r1,[r0]
	orr r1,#1
	str r1,[r0]

	;Configure timer to interrupt processor (1)->19th bit of 0xE000E100
	MOV r0, #0xE100
	MOVT r0, #0xE000
	ldr r1, [r0]
	MOV r2,#1
	lsl r2,r2,#19
	orr r1, r1, r2
	str r1, [r0]

	;Enable timer 1->1st bit of 0x4003000C
	MOV r0, #0x000C
	MOVT r0, #0x4003
	ldr r1, [r0]
	orr r1, r1, #1
	str r1, [r0]

	POP {lr}
	MOV pc,lr

Switch_Handler:

	; Your code for your UART handler goes here.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler
	PUSH {lr}
	PUSH {r4-r11}


	;clear interrupt register GPIOICR
	MOV r0, #0x541C
	MOVT r0, #0x4002
	LDR r1,[r0]
	ORR r1, r1,#16
	STR r1, [r0]

	;Incrament switch presses (Speed)
	ldr r0,prt_to_dataBlock
	LDRB r1,[r0, #2]		;Modify third byte
	ADD r1, r1,#1
	STRB r1,[r0, #2]

	POP {r4-r11}
	POP {lr}
	BX lr       	; Return

UART0_Handler:

	PUSH {lr}
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler
	PUSH {r4-r11}

	;Clear Interrupt: Set the bit 4 (RXIC) in the UART Interrupt Clear Register (UARTICR)
	;UART0 Base Address: 0x4000C000
	;UARTICR Offset: 0x044
	;UART0 Bit Position: Bit 4

	MOV r0, #0xC000
	MOVT r0, #0x4000


	LDR r2, [r0, #0x44]

	ORR r2, r2, #16		;bit 4 has 1

	STR r2, [r0, #0x44]	;clearing interrupt bit


	MOV r4, #0
	MOV r5, #1		;setting registers ot the values of directions
	MOV r6, #2
	MOV r7, #3


	BL simple_read_character		;retrieving the character pressed
	ldr r1, prt_to_dataBlock		;base address of the data Block

	;a ascii: #97
	;d ascii: #100
	;s ascii: #115
	;w ascii: #119

	CMP r0, #100		;if char== 'd'
	BNE check_a_char
	STRB r4, [r1, #3]	;storing 00 in dataBlock[3]
	B direction_end
check_a_char:
	CMP r0, #97		;if char== 'a'
	BNE check_w_char
	STRB r5, [r1, #3]	;storing 01 in dataBlock[3]
	B direction_end
check_w_char:
	CMP r0, #119		;if char== 'w'
	BNE check_s_char
	STRB r6, [r1, #3]	;storing 10 in dataBlock[3]
	B direction_end
check_s_char:
	CMP r0, #115		;if char== 's'
	BNE direction_end
	STRB r7, [r1, #3]	;storing 11 in dataBlock[3]

direction_end:			;note: if the char is NONE of the above, the direction remains the same
	POP{r4-r11}
	POP {lr}
	BX lr

exit: 
	MOV r0, r9;output prompt "Total Moves Made: "
	BL output_string
	;move the counter for # of moves into the register that int2string uses as an argument
	;int2string on that register

***************************HELER SUBROUTINES ****************************************
;r0-locationX(int), r1-locationY(int)
;change_cursor(r0,r1)
print_cursor_location:
	PUSH {lr}
	PUSH {r4-r5}
	;locationX
	mov r4, r0
	;locationY
	mov r5, r1
	;print cursor_postion_string
	mov r0,#27
	;output_string_nw
	bl output_character
	mov r0, #91
	bl output_character
	;load locationX
	mov r0,r4
	ldr r1, ptr_num_1_string
	;int2string (into num1_string)
	bl int2string_nn

	;if num1 >= 10 branch
	mov r0,r4
	cmp r0, #10
	BGE num1_greater
	;else num1 less
	mov r0, #48
	bl output_character
	mov r1, #1
	ldr r0, ptr_num_1_string
	bl output_string_withlen_nw
	b locationYout

num1_greater:
	ldr r0,ptr_num_1_string
	mov r1, #2
	;output_string_nw
	bl output_string_withlen_nw

locationYout:
	;load Decimal(";")
	mov r0, #59
	;output_character
	bl output_character


	;load locationY
	mov r0,r5
	ldr r1, ptr_num_2_string
	;int2string (into num1_string)
	bl int2string_nn

	;if num2 >= 10 branch
	mov r0,r5
	cmp r0, #10
	BGE num2_greater
	;else num1 less
	mov r0, #48
	bl output_character
	mov r1, #1
	ldr r0, ptr_num_2_string
	bl output_string_withlen_nw
	b end_print_cursor

num2_greater:
	ldr r0,ptr_num_1_string
	mov r1, #2
	;output_string_nw
	bl output_string_withlen_nw



end_print_cursor:
	;output H
	mov r0, #72
	bl output_character
	;load Decimal("/0")
	mov r0, #0
	;output_character
	bl output_character
	POP {r4-r5}
	POP {lr}
	mov pc,lr


border_check:
	push {lr}

	ldr r0, prt_to_dataBlock
	;checkX
	ldrb r1, [r0,#0]
	cmp r1, #22
	bge set_endbit
	cmp r1, #0
	blt set_endbit

	;checkY
	ldrb r1, [r0,#1]
	cmp r1, #20
	bge set_endbit
	cmp r1, #0
	blt set_endbit

	;Else
	b end_border_check

set_endbit
	ldrb r1, [r0,#3]
	mov r2, #1
	lsl r2,r2,#7
	orr r1,r2,r2
	strb r1, [r0,#3]

end_border_check:

	pop {lr}
	mov pc,lr

;Moves cursor by a r0 amount of places
movCursor_right:
	PUSH {lr}
	;Save spaces to move by
	mov r5,r0

loop_right:
	sub r5,r5,#1
	;output escape sequence
	mov r0,#27
	bl output_character

	;output '['
	mov r0, #91
	bl output_character
	;output value to move by
	mov r0,r5
	bl output_character
	;output ending character
	mov r0,#67
	bl output_character
	;ouptut Null byte
	mov r0,#0
	bl output_character

	cmp r5,#0
	bne loop_right

	POP {lr}
	mov pc,lr

movCursor_left:
	PUSH {lr}
	;Save spaces to move by
	mov r5,r0
loop_left:
	sub r5,r5,#1
	;output escape sequence
	mov r0,#27
	bl output_character

	;output '['
	mov r0, #91
	bl output_character
	;output value to move by
	mov r0,r5
	bl output_character
	;output ending character
	mov r0,#68
	bl output_character
	;ouptut Null byte
	mov r0,#0
	bl output_character
	cmp r5,#0
	bne loop_left

	POP {lr}
	mov pc,lr

movCursor_up:
	PUSH {lr}

	;Save spaces to move by
	mov r5,r0
loop_up:
	sub r5, r5,#1
	;output escape sequence
	mov r0,#27
	bl output_character

	;output '['
	mov r0, #91
	bl output_character
	;output value to move by
	mov r0,r5
	bl output_character
	;output ending characterB
	mov r0,#65
	bl output_character
	;ouptut Null byte
	mov r0,#0
	bl output_character
	cmp r5,#0
	bne loop_up
	POP {lr}
	mov pc,lr

movCursor_down:
	PUSH {lr}

	;Save spaces to move by
	mov r5,r0
loop_down:
	sub r5,r5,#1
	;output escape sequence
	mov r0,#27
	bl output_character

	;output '['
	mov r0, #91
	bl output_character
	;output value to move by
	mov r0,r5
	bl output_character
	;output ending character
	mov r0,#66
	bl output_character
	;ouptut Null byte
	mov r0,#0
	bl output_character
	cmp r5,#0
	bne loop_down

	POP {lr}
	mov pc,lr
	.end
