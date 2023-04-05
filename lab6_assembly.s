	.data

	.global prompt
	.global uart_interrupt_init
	.global gpio_interrupt_init
	.global UART0_Handler
	.global Switch_Handler
	.global Timer_Handler		; This is needed for Lab #6
	.global simple_read_character
	.global output_character	; This is from your Lab #6 Library
	.global read_string		; This is from your Lab #6 Library
	.global output_string		; This is from your Lab #6 Library
	.global uart_init		; This is from your Lab #6 Library
	.global lab6
prompt:	.string "Press SW1 or a key (q to quit)", 0
data_block: .word 0
spacesMoved_block: .word 0

output: .string "Total Moves Made: ", 0 
top_bottom_borders: .string "--------------------", 0
side_borders: .string "|                    |", 0 ;The board is 20 characters by 20 characters in size (actual size inside the walls).
cursor_position: .string 27, "[10;10H" ;set up a cursor position variable that will be 10 - 10
clear_screen: .string 27, "[2J" ; clear screen cursor position moved to home row 0, line 0 

	.text



ptr_to_prompt:				.word prompt
prt_to_dataBlock: 			.word data_block
prt_to_spacesMoved_block:	.word spacesMoved_block

ptr_to_top_bottom_borders:		.word top_bottom_borders
ptr_to_side_borders:		.word side_borders
ptr_to_cursor_position: 	.word cursor_position
ptr_to_clear_screen: 		.word clear_screen
ptr_to_output:				.word output

;***************Data packet orginization*******************************
;	|LocationX	|LocationY	|SW1Presses	|Direction| EndBit|
;	0		    8		    16		    24-25	  31
;**********************************************************************
lab6:	; This is your main routine which is called from your C wrapper
	PUSH {lr}   		; Store lr to stack
	BL uart_init
	BL uart_interrupt_init
	BL gpio_interrupt_init

<<<<<<< HEAD
	LDR r4, ptr_to_top_bottom_borders ; load border string into registers
	LDR r5, ptr_to_side_borders ;load string into register
   	LDR r6, ptr_to_middle_row
=======
	;Updata locationX and locationY to be at center
	LDR r0, prt_to_dataBlock ;load the datablock into r0

	MOV r1, #10 ;move 10 into r1 as intial location will be 10,10 as that is the middle of a 20x20 board
	;LocationX
	LDRB r1, [r0,#0]

	;LocationY
	LDRB r1, [r0,#1]

	;Start game
	BL Timer_init
	
	LDR r5, ptr_to_cursor_position
>>>>>>> origin/saahil_branch

	;Updata locationX and locationY to be at center
	;Start game
	BL Timer_init
loop:
	MOV r0,r0
	MOV r0,r0
	MOV r0,r0
	b loop

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
	
	;print_location
	;Load locationX and locationY
	ldr r0, prt_to_dataBlock

	;LocationX
	LDRB r1, [r0,#0]

	;LocationY
	LDRB r2, [r0,#1]

	;Check if were at a border
;	CMP r1, #0 ;border should be at 0 and 21 for the sides and top and bottom 
;	BLE y_check ;if x <= 0 check the y value (as with increasing speeds we could've hopped out of bounds with one move)

;	CMP r1, #21  ;
;	BGE y_check ;if x >= 21 exit as 0 should be a border as with increasing speeds we could've hopped out of bounds with one move

;y_check:
;	CMP r2, #0 
;	BLE exit ;if y also <= 0 then exit as we are at a border if not keep going
;	CMP r2, #21 ;check if r2 is greater than or equal to 21
;	BGE exit ;subroutine is at the bottom of the code right before ".end"
	
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

	;Change cursor location string to equal the new position of x and y 

	;branch to end of if
	b end_timer_handler

not_zero:
	cmp r3, #1
	bne not_one
	;update locationX & Y
	sub r1, r1,r4

	;Store location
	STRB r1, [r0,#0]

	;branch to end of if
	b end_timer_handler

not_one:
	cmp r3, #2
	bne not_two
	;update locationX & Y
	add r2, r2,r4

	;Store location
	STRB r1, [r2,#1]

	;branch to end of if
	b end_timer_handler

not_two:
	cmp r3, #3
	bne end_timer_handler
	;update locationX & Y
	SUB r2, r2,r4

	;Store location
	STRB r1, [r2,#1]

	;branch to end of if
	b end_timer_handler


	;Change cursor back to end of string
	;Pop registers
end_timer_handler:
	POP {r4-r11}
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
	;MOV r1, #0x2400
	;MOVT r1, #0x00F4
	MOV r1,#2000
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
	BX lr       	; Return

UART0_Handler:
	BX lr

exit: 
	MOV r0, r9;output prompt "Total Moves Made: "
	BL output_string
	;move the counter for # of moves into the register that int2string uses as an argument
	;int2string on that register


	.end
