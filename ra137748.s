.org 0x0
.section .iv,"a"

_start:		

interrupt_vector:
	b	RESET_HANDLER
.org 0x8
	b	IRQ_HANDLER
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

.set ENTRADA_CODIGO_USUARIO,	0x77802000

@ stacks de cada modo
.set SVC_STACK, 0x77701000
.set UND_STACK, 0x77702000
.set ABT_STACK, 0x77703000
.set IRQ_STACK, 0x77704000
.set FIQ_STACK, 0x77705000
.set USR_STACK, 0x77706000

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

	@Configure stacks for all modes
	ldr		sp, =SVC_STACK
	msr		CPSR_c, #0xDF  @ Enter system mode, FIQ/IRQ disabled
	ldr		sp, =USR_STACK
	msr		CPSR_c, #0xD1  @ Enter FIQ mode, FIQ/IRQ disabled
	ldr		sp, =FIQ_STACK
	msr		CPSR_c, #0xD2  @ Enter IRQ mode, FIQ/IRQ disabled
	ldr		sp, =IRQ_STACK
	msr		CPSR_c, #0xD7  @ Enter abort mode, FIQ/IRQ disabled
	ldr		sp, =ABT_STACK
	msr		CPSR_c, #0xDB  @ Enter undefined mode, FIQ/IRQ disabled
	ldr		sp, =UND_STACK

											@instrucao msr - habilita interrupcoes
	msr		CPSR_c, #0x10					@ USER mode, IRQ/FIQ disabled

	ldr		r0, =ENTRADA_CODIGO_USUARIO
	movs	pc, r0

IRQ_HANDLER:
	ldr		r0, =GPT_BASE					@ zera flag, para nao tratar esta interrupcao novamente
	mov		r1, #1
	str		r1, [r0, #GPT_SR]

	sub		lr, lr, #4						@ retorna
	movs	pc, lr

SVC_HANDLER:
	msr		CPSR_c, #0x1F
	sub		lr, lr, #4						@ retorna
	movs	pc, lr

