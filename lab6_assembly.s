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

prompt:	.string "Press SW1 or a key (q to quit)", 0


	.text



ptr_to_prompt:		.word prompt


;***************Data packet orginization*******************************
;	|SwitchPresses	|KeyPresses	|End Flag	|Nothing|
;	0		8		16		24	32
;**********************************************************************
lab6:	; This is your main routine which is called from your C wrapper
	PUSH {lr}   		; Store lr to stack

	BL uart_interrupt_init
	BL gpio_interrupt_init

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

	;Clear timer interrupt (1)->0th bit of 0x40030024
	MOV r0 ,#0x0024
	MOVT r0, #0x4003


	;Print_borders

	;print_location
	;update_location
	;Change cursor back to end of string
	;Pop registers
	BX LR

Timer_init:
	PUSH {lr}
	;Enable clock (1)->0th bit of: 0x400FE604
	;enable (1)->1st bit of:  0x40030000
	;Put timer into Periodic mode GPTMTAMR (1)->2nd bit 0x40030004
	;Setup Interrupt interval period (GPTMTAILR) register0x40030028
	;set to 16M -> 16,000,000-> 0xF42400 ticks per cycle
	;Configure timer to interrupt processor (1)->19th bit of 0xE000E100
	;Enable timer 1->1st bit of 0x4003000C
	POP {lr}
	MOV pc,lr

Switch_Handler:
	BX lr       	; Return

UART0_Handler:
	BX lr


	.end
