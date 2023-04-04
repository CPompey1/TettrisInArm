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


	MOV pc, lr

Timer_Handler:

	; Your code for your Timer handler goes here.  It is not needed
	; for Lab #5, but will be used in Lab #6.  It is referenced here
	; because the interrupt enabled startup code has declared Timer_Handler.
	; This will allow you to not have to redownload startup code for
	; Lab #6.  Instead, you can use the same startup code as for Lab #5.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler.

	;Preserve registers
	;Clear timer interrupt
	;Print_borders
	;print_location
	;update_location
	;Change cursor back to end of string
	;Pop registers

	BX lr       	; Return

	.end
