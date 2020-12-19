;
; YM2612.asm
;
; Created: 17.12.2020 14:51:51

.equ	varL	= 0x0060 ;
.equ	varH	= 0x022F ;                                    

.equ	mem_adc_in_L = 0x0060
.equ	mem_adc_in_H = 0x0254

.equ	mem_lcd_out_L = 0x0255
.equ	mem_lcd_out_H = 0x044d

.equ	baud	= 250000					; baudrate
.equ	bps		= (16000000/16/baud) - 1	; baud prescale   
.equ	stop_symbol = 0x15

.def	data_ = r0
.def	temp = r16
.def	temp2 = r17
.def	temp3 = r18
.def	lcd_data = r19
.def	traag1 = r20
.def	traag2 = r21       
.def	swreg = r22   

;**** Interrupt Vectors ****

.org		0
	rjmp	RESET		

.ORG		0x00B		
	rjmp	UART_RXCP

.ORG		0x00D		
	rjmp	UART_TXCP

.org		0x00E
	rjmp	ADC_read	

;**************************************************************

RESET:

	ldi		temp,	high(RAMEND);
	out		SPH,	temp
	ldi		temp,	low(RAMEND)
	out		SPL,	temp			
	ldi		XL,		LOW(mem_adc_in_L)		; initialize X pointer
	ldi		XH,		HIGH(mem_adc_in_L)		; to ADC data in.
	ldi		YL,		LOW(mem_lcd_out_L)		; initialize Y pointer
	ldi		YH,		HIGH(mem_lcd_out_L)		; to ADC data in.

	;Setting up directions on IO pins. Comments denote YM2612 pin name:
	sbi		ddrb, 0						;D6
	sbi		ddrb, 1						;D7
	cbi		ddrb, 2						;!IRQ
	sbi		ddrb, 3						;/0M
	sbi		ddrb, 4						;!CS
	sbi		ddrb, 5						;!WR

	;cbi	ddrc, 0						;
	sbi		ddrc, 1						;A0
	sbi		ddrc, 2						;A1
	;cbi	ddrc, 3						;
	sbi		ddrc, 4						;D0
	sbi		ddrc, 5						;D1

	;cbi	ddrd, 0						;RXD
	;cbi	ddrd, 1						;TXD
	cbi		ddrd, 2						;INT0
	cbi		ddrd, 3						;INT1
	sbi		ddrd, 4						;D2
	sbi		ddrd, 5						;D3
	sbi		ddrd, 6						;D4
	sbi		ddrd, 7						;D5

	sbi		ddrc, 0						;test LED
	sbi		ddrc, 3						;test LED

	;Configuring Timer2 to output a 8MHz to feed YM2612 clock in at pin 24
	ldi		temp, 0b00011001			;WGM20=0, WGM21=1, COM20=1, COM21=0, CS=MIN - for CTC, toggle output, min PreScaler for max freq: fCLK / 2
	out		TCCR2, temp
	ldi		temp, 0
	out		OCR2, temp

	;Setting up UART
	ldi		r16, bps
	ldi		r17, 0
	out		UBRRL,	r16			; load baud prescale
	out		UBRRH,	r17			; to UBRR0
	ldi		temp,	0b11011000
	out		UCSRB,	temp			; and receiver	

	;Initialising IO
	cbi		portc, 0
	cbi		portc, 3
	clr		temp
	mov		data_, temp
	rcall	data_to_pin


main:
	sei
	cbi		portc, 3
	rjmp	main




data_to_pin:
	cbi		portc, 4
	cbi		portc, 5
	cbi		portd, 4
	cbi		portd, 5
	cbi		portd, 6
	cbi		portd, 7
	cbi		portb, 0
	cbi		portb, 1
			
	mov		temp2, data_
	sbrc	temp2, 0
	sbi		portc, 4
	sbrc	temp2, 1
	sbi		portc, 5
	sbrc	temp2, 2
	sbi		portd, 4
	sbrc	temp2, 3
	sbi		portd, 5
	sbrc	temp2, 4
	sbi		portd, 6
	sbrc	temp2, 5
	sbi		portd, 7
	sbrc	temp2, 6
	sbi		portb, 0
	sbrc	temp2, 7
	sbi		portb, 1

	ret


UART_RXCP:
		push	temp
		in		temp,	UDR
		sbi		portc, 0
		sbi		portc, 3
		out		UDR,	temp
		pop		temp
		reti

UART_TXCP:
		reti

ADC_read:
		reti