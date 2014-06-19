		.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
	b	RESET_HANDLER
.org 0x8
	b	SVC_HANDLER
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

SET_UART:
	.set UART_BASE,			0x53FBC000
	.set UART_UTXD,			0x0040						@ 0x53FBC040
	.set UART_UCR1,			0x0080						@ 0x53FBC080
	.set UART_UCR2,			0x0084						@ 0x53FBC084
	.set UART_UCR3,			0x0088						@ 0x53FBC088
	.set UART_UCR4,			0x008C						@ 0x53FBC08C
	.set UART_UFCR,			0x0090						@ 0x53FBC090
	.set UART_USR1,			0x0094						@ 0x53FBC094					
	.set UART_UBIR,			0x00A4						@ 0x53FBC0A4
	.set UART_UBMR,			0x00A8						@ 0x53FBC0A8

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

	ldr             r0, =UART_BASE

        mov             r1, #0x1
        str             r1, [r0, #UART_UCR1]

        mov             r1, #0x21
	mov		r1, r1, lsl #8
	add		r1, r1, #0x27
        str             r1, [r0, #UART_UCR2]

        mov             r1, #0x7
	mov		r1, r1, lsl #8
	add		r1, r1, #0x04
        str             r1, [r0, #UART_UCR3]

        mov             r1, #0x7C
	mov		r1, r1, lsl #8
        str             r1, [r0, #UART_UCR4]

	mov		r1, #0x8
	mov		r1, r1, lsl #8
	add		r1, r1, #0x9E
	str		r1, [r0, #UART_UFCR]

	mov		r1, #0x8
	mov		r1, r1, lsl #8
	add		r1, r1, #0xFF
	str		r1, [r0, #UART_UBIR]

	mov		r1, #0xC
	mov		r1, r1, lsl #8
	add		r1, r1, #0x34
	str		r1, [r0, #UART_UBMR]

											@ Carrega endereço do início do programa de usuário
	ldr		r0, =USER_TEXT
	ldr		r0, [r0]
											@ Entra em modo de usuário com interrupções habilitadas
	msr		CPSR_c, #0x10

	mov		PC, r0

SVC_HANDLER:
	cmp		r7, #1
	beq		SYSCALL_EXIT

	cmp		r7, #2
	beq		SYSCALL_FORK

	cmp		r7, #4
	beq		SYSCALL_WRITE

	cmp		r7, #20
	beq		SYSCALL_GETPID

SVC_END:
	msr		CPSR_c, #0x10						@ retorna ao modo de usuario, e retorna
@	sub		lr, lr, #4
	mov		pc, lr

IRQ_HANDLER:
	ldr		r0, =GPT_BASE					@ zera flag, para nao tratar esta interrupcao novamente
	mov		r1, #1
	str		r1, [r0, #GPT_SR]

	sub		lr, lr, #4						@ retorna
	movs		pc, lr

SYSCALL_EXIT:
	b		SVC_END

SYSCALL_FORK:
	b		SVC_END

SYSCALL_WRITE:
	msr		CPSR_c, #0xD3						@ modo supervisor, com IRQ e FIQ desabilitadas
	ldr		r0, =UART_BASE
	push		{r4}
	WRITE:
		WAIT_TO_WRITE:
			ldr		r3, [r0, #UART_USR1]			@ se o 13o bit de USR1 for 0
			mov		r4, #(1 << 13)				@ temos de esperar para escrever	
			and		r4, r4, r3
			cmp		r4, #0
			beq		WAIT_TO_WRITE
		sub		r2, r2, #1					@ podemos escrever, r2 tem quantos caracteres ainda restam a ser escrito
		ldr		r4, [r1], #1					@ r4 = r1[i++]
		str		r4, [r0, #UART_UTXD]				@ escrevemos na fila a ser transmitida
		cmp		r2, #0						@ se ainda tem caracteres a serem escritos
		bne		WRITE						@ continuamos o loop
	pop		{r4}
	b		SVC_END

SYSCALL_GETPID:
	ldr	r0, =RUNNING_PID
	ldr	r0, [r0]

	b	SVC_END

.data
USER_TEXT:		.word	0x77802000
RUNNING_PID:	.word	0
