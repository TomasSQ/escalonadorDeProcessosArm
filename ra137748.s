.org 0x0
.section .iv,"a"

_start:		

interrupt_vector:
	b	RESET_HANDLER
.org 0x18
	b	IRQ_HANDLER

SET_TZIC:
@ Constantes para os enderecos do TZIC
	.set TZIC_BASE,			0x0FFFC000
	.set TZIC_INTCTRL,		0x0
	.set TZIC_INTSEC1,		0x84 
	.set TZIC_ENSET1,		0x104
	.set TZIC_PRIOMASK,		0xC
 	.set TZIC_PRIORITY9,	0x424

SET_GPT:
@Constantes para os enderecos do GPT
	.set GPT_BASE,			0x53FA0000
	.set GPT_CR,			0x0000
	.set GPT_PR,			0x0004
	.set GPT_SR,			0x0008
	.set GPT_OCR1,			0x0010
	.set GPT_IR,			0x000C

.org 0x100
.text
RESET_HANDLER:
	ldr		r0, =interrupt_vector
	mcr		p15, 0, r0, c12, c0, 0

											@ Liga o GPT
	ldr		r0, =GPT_BASE

	mov		r1, #0x41
	str		r1, [r0, #GPT_CR]

	mov		r1, #0
	str		r1, [r0, #GPT_PR]

	mov		r1, #100
	str		r1, [r0, #GPT_OCR1]

	mov		r1, #1
	str		r1, [r0, #GPT_IR]

											@ Liga o controlador de interrupcoes
											@ R1 <= TZIC_BASE

	ldr		r1, =TZIC_BASE

											@ Configura interrupcao 39 do GPT como nao segura
	mov		r0, #(1 << 7)
	str		r0, [r1, #TZIC_INTSEC1]

											@ Habilita interrupcao 39 (GPT)
											@ reg1 bit 7 (gpt)

	mov		r0, #(1 << 7)
	str		r0, [r1, #TZIC_ENSET1]

											@ Configure interrupt39 priority as 1
											@ reg9, byte 3

	ldr		r0, [r1, #TZIC_PRIORITY9]
	bic		r0, r0, #0xFF000000
	mov		r2, #1
	orr		r0, r0, r2, lsl #24
	str		r0, [r1, #TZIC_PRIORITY9]

											@ Configure PRIOMASK as 0
	eor		r0, r0, r0
	str		r0, [r1, #TZIC_PRIOMASK]

											@ Habilita o controlador de interrupcoes
	mov		r0, #1
	str		r0, [r1, #TZIC_INTCTRL]

											@instrucao msr - habilita interrupcoes
	msr		CPSR_c, #0x13       			@ SUPERVISOR mode, IRQ/FIQ enabled

	ldr		r0, =CONTADOR
	mov		r1, #0
	str		r1, [r0]

	laco:
		b	laco

IRQ_HANDLER:
	ldr		r0, =GPT_BASE					@ zera flag, para nao tratar esta interrupcao novamente
	mov		r1, #1
	str		r1, [r0, #GPT_SR]

	ldr		r0, =CONTADOR					@ incrementa contador
	ldr		r1, [r0]
	add		r1, r1, #1
	str		r1, [r0]

	sub		lr, lr, #4						@ retorna
	movs	pc, lr

.data
CONTADOR: .word		0

