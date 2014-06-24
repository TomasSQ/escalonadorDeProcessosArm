.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
	b	RESET_HANDLER
.org 0x8
	b	SVC_HANDLER
.org 0x18
	b	IRQ_HANDLER

@ Stacks
	.set SVC_STACK, 0x77701000
	.set UND_STACK, 0x77702000
	.set ABT_STACK, 0x77703000
	.set IRQ_STACK, 0x77704000
	.set FIQ_STACK, 0x77705000
	.set USR_STACK, 0x77706000

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
	.set UART_UTXD,			0x0040				@ 0x53FBC040
	.set UART_UCR1,			0x0080				@ 0x53FBC080
	.set UART_UCR2,			0x0084				@ 0x53FBC084
	.set UART_UCR3,			0x0088				@ 0x53FBC088
	.set UART_UCR4,			0x008C				@ 0x53FBC08C
	.set UART_UFCR,			0x0090				@ 0x53FBC090
	.set UART_USR1,			0x0094				@ 0x53FBC094
	.set UART_UBIR,			0x00A4				@ 0x53FBC0A4
	.set UART_UBMR,			0x00A8				@ 0x53FBC0A8

.org 0x100
.text
RESET_HANDLER:
	ldr		r0, =interrupt_vector
	mcr		p15, 0, r0, c12, c0, 0

	ldr		sp, =SVC_STACK						@ Configura stack do supervisor

	msr		CPSR_c, #0xDF						@ Entra em modo system, FIQ/IRQ desabilitados
	ldr		sp, =USR_STACK

	msr		CPSR_c, #0xD1						@ Entra em modo FIQ, FIQ/IRQ desabilitados
	ldr		sp, =FIQ_STACK

	msr		CPSR_c, #0xD2						@ Entra em modo IRQ, FIQ/IRQ desabilitados
	ldr		sp, =IRQ_STACK

	msr		CPSR_c, #0xD7						@ Entra em modo abort, FIQ/IRQ desabilitados
	ldr		sp, =ABT_STACK

	msr		CPSR_c, #0xDB						@ Entra em modo undefined, FIQ/IRQ desabilitados
	ldr		sp, =UND_STACK

	msr		CPSR_c, #0xD3						@ Volta ao modo supervisor, FIQ/IRQ desabilitados

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

	ldr		r0, =UART_BASE						@ configura o UART

	mov		r1, #0x1
	str		r1, [r0, #UART_UCR1]

	mov		r1, #0x21
	mov		r1, r1, lsl #8
	add		r1, r1, #0x27
	str		r1, [r0, #UART_UCR2]

	mov		r1, #0x7
	mov		r1, r1, lsl #8
	add		r1, r1, #0x04
	str		r1, [r0, #UART_UCR3]

	mov		r1, #0x7C
	mov		r1, r1, lsl #8
	str		r1, [r0, #UART_UCR4]

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

												@ Inicia o primeiro processo de usuário
	ldr		r0, =PROCESS_1
	ldr		r1, =NEXT_PID
	ldr		r2, [r1]
	str		r2, [r0]
	add		r2, r2, #1
	str		r2, [r1]
												@ Limpamos r1 e r2 para evitar que o processo saiba qual é o próximo PID
	mov		r1, #0
	mov		r2, #0

												@ Carrega endereço do início do programa de usuário
	ldr		r0, =USER_TEXT
	ldr		r0, [r0]
	
												@ Entra em modo de usuário com interrupções habilitadas
	msr		SPSR, #0x10
	movs	pc, r0

IRQ_HANDLER:
	ldr		r0, =GPT_BASE						@ zera flag, para nao tratar esta interrupcao novamente
	mov		r1, #1
	str		r1, [r0, #GPT_SR]

	sub		lr, lr, #4							@ retorna
	movs	pc, lr

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
	movs	pc, lr								@ retorna ao modo de usuario, e retorna

@ Salva o contexto do processo que está rodando atualmente.
SAVE_CONTEXT:
	push	{r0, r1}							@ Empilha r0 e r1, pois iremos sujá-los
	ldr		r0, =RUNNING_PID					@ Carrega número do processo em execução
	ldr		r0, [r0]
	sub		r0, r0, #1
	mov		r1, #72
	mul		r1, r0, r1

	ldr		r0, =PROCESS_CONTEXTS				@ Encontra endereço do contexto do processo atual
	add		r0, r0, r1

	ldr		r1, =RUNNING_PID					@ Carrega o PID do processo atual
	ldr		r1, [r1]
	str		r1, [r0]							@ Salva PID no contexto

	mrs		r1, SPSR							@ Salva SPSR_svc como cpsr para usr
	str		r1, [r0, #4]

	ldr		r1, [sp, #8]						@ Carrega lr_svc da stack e salva como pc no contexto
	str		r1, [r0, #8]

	msr		CPSR_c, #0xDF						@ Altera para modo system
	str		lr, [r0, #12]						@ Salva lr_usr como lr no contexto

	str		sp, [r0, #16]						@ Salva sp_usr como sp no contexto

	msr		CPSR_c, #0x93						@ Volta para o modo svc

	str		r12, [r0, #20]						@ Salva r12 no contexto
	str		r11, [r0, #24]						@ Salva r11 no contexto
	str		r10, [r0, #28]						@ Salva r10 no contexto
	str		r9, [r0, #32]						@ Salva r9 no contexto
	str		r8, [r0, #36]						@ Salva r8 no contexto
	str		r7, [r0, #40]						@ Salva r7 no contexto
	str		r6, [r0, #44]						@ Salva r6 no contexto
	str		r5, [r0, #48]						@ Salva r5 no contexto
	str		r4, [r0, #52]						@ Salva r4 no contexto
	str		r3, [r0, #56]						@ Salva r3 no contexto
	str		r2, [r0, #60]						@ Salva r2 no contexto

	pop		{r2, r3}							@ Desempilha valores iniciais de r0 e r1 em r2 e r3
	push	{r2, r3}

	str		r3, [r0, #64]						@ Salva r3 como r1 no contexto
	str		r2, [r0, #68]						@ Salva r2 como r0 no contexto

	pop		{r0, r1}

	mov		pc, lr								@ Retorna

@ Carrega processo r0 para execução
LOAD_CONTEXT:
	push	{lr}								@ Empilha lr para podermos retornar

	ldr		r1, =RUNNING_PID					@ Grava número do processo como processo atual
	str		r0, [r1]
	sub		r0, r0, #1
	mov		r1, #72
	mul		r1, r0, r1

	ldr		r0, =PROCESS_CONTEXTS				@ Encontra endereço do contexto do processo
	add		r0, r0, r1

	ldr		r1, [r0, #4]						@ Carrega SPSR do contexto
	msr		SPSR, r1

	ldr		lr, [r0, #8]						@ Carrega lr_svc do contexto

	msr		CPSR_c, #0xDF						@ Altera para modo system
	ldr		lr, [r0, #12]						@ Carrega lr_usr
	ldr		sp, [r0, #16]						@ Carrega sp_usr
	msr		CPSR_c, #0x93						@ Volta para modo svc

	ldr		r12, [r0, #20]						@ Carrega r12 do contexto
	ldr		r11, [r0, #24]						@ Carrega r11 do contexto
	ldr		r10, [r0, #28]						@ Carrega r10 do contexto
	ldr		r9, [r0, #32]						@ Carrega r9 do contexto
	ldr		r8, [r0, #36]						@ Carrega r8 do contexto
	ldr		r7, [r0, #40]						@ Carrega r7 do contexto
	ldr		r6, [r0, #44]						@ Carrega r6 do contexto
	ldr		r5, [r0, #48]						@ Carrega r5 do contexto
	ldr		r4, [r0, #52]						@ Carrega r4 do contexto
	ldr		r3, [r0, #56]						@ Carrega r3 do contexto
	ldr		r2, [r0, #60]						@ Carrega r2 do contexto
	ldr		r1, [r0, #64]						@ Carrega r1 do contexto
	ldr		r0, [r0, #68]						@ Carrega r0 do contexto

	pop		{pc}								@ Retorna

SYSCALL_EXIT:
	push	{lr}								@ Guardamos lr na stack (mesmo que o usemos)
	ldr		r0, =RUNNING_PID
	ldr		r0, [r0]
	sub		r2, r0, #1
	mov		r1, #72
	mul		r1, r2, r1
	ldr		r2, =PROCESS_CONTEXTS				@ Encontra endereço do contexto do processo atual
	add		r2, r2, r1

	mov		r1, #1
	str		r1, [r2]

	bl		FIND_NEXT_READY_CONTEXT

	pop		{lr}

	cmp		r0, #0
	blne	LOAD_CONTEXT

	beq		SYSCALL_EXIT_WAIT

	b		SVC_END

SYSCALL_EXIT_WAIT:								@ todos os processos foram finalizados.
	b		SYSCALL_EXIT_WAIT

SYSCALL_FORK:
	msr		CPSR_c, #0xDF
	msr		CPSR_c, #0x93
	push	{lr}
	bl		SAVE_CONTEXT
	pop		{lr}
	mov		r0, #1
	bl		LOAD_CONTEXT
	msr		CPSR_c, #0xDF
	msr		CPSR_c, #0x93
	b		SVC_END

SYSCALL_WRITE:
	push	{r0-r4}
	ldr		r0, =UART_BASE
	WRITE:
		WAIT_TO_WRITE:
			ldr		r3, [r0, #UART_USR1]		@ se o 13o bit de USR1 for 0
			mov		r4, #(1 << 13)				@ temos de esperar para escrever
			and		r4, r4, r3
			cmp		r4, #0
			beq		WAIT_TO_WRITE
		sub		r2, r2, #1						@ podemos escrever, r2 tem quantos caracteres ainda restam a ser escrito
		ldr		r4, [r1], #1					@ r4 = r1[i++]
		str		r4, [r0, #UART_UTXD]			@ escrevemos na fila a ser transmitida
		cmp		r2, #0							@ se ainda tem caracteres a serem escritos
		bne		WRITE							@ continuamos o loop
	pop		{r0-r4}
	b		SVC_END

SYSCALL_GETPID:
	ldr		r0, =RUNNING_PID
	ldr		r0, [r0]

	b		SVC_END

FIND_EMPTY_CONTEXT:
	push	{r1, r2, r3, lr}
	ldr		r0, =PROCESS_CONTEXTS
	ldr		r2, =PROCESS_8
	mov		r3, #1
	FIND_EMPTY_CHECK_CONTEXT:
		ldr		r1, [r0]
		cmp		r1, #0
		beq		FIND_EMPTY_CONTEXT_END
		cmp		r0, r2
		moveq	r3, #0
		beq		FIND_EMPTY_CONTEXT_END
		add		r0, r0, #72
		add		r3, r3, #1
		b		FIND_EMPTY_CHECK_CONTEXT
FIND_EMPTY_CONTEXT_END:
	mov		r0, r3
	pop		{r1, r2, r3, pc}

FIND_NEXT_READY_CONTEXT:
	push	{r1, r2, r3, r4, lr}
	ldr		r0, =RUNNING_PID				@ Carrega número do processo em execução
	ldr		r3, [r0]
	sub		r0, r3, #1
	mov		r1, #72
	mul		r1, r0, r1

	ldr		r0, =PROCESS_CONTEXTS				@ Encontra endereço do contexto do processo atual
	add		r0, r0, r1
	mov		r4, r0
	add		r0, r0, #72

	ldr		r2, =PROCESS_8
	FIND_NEXT_CHECK_CONTEXT:
		ldr		r1, [r0]
		cmp		r0, r4
		moveq	r3, #0
		beq		FIND_NEXT_READY_CONTEXT_END
		cmp		r1, #0
		bne		FIND_NEXT_READY_CONTEXT_END
		cmp		r0, r2
		ldreq	r0, =PROCESS_CONTEXTS
		addne	r0, r0, #72
		moveq	r3, #1
		addne	r3, r3, #1
		b		FIND_NEXT_CHECK_CONTEXT
FIND_NEXT_READY_CONTEXT_END:
	mov		r0, r3
	pop		{r1, r2, r3, r4, pc}

.data
USER_TEXT:			.word	0x77802000			@ Início do programa de usuário
RUNNING_PID:		.word	1					@ PID do processo em execução
NEXT_PID:			.word	1					@ PID do próximo processo a ser iniciado

@ Contexts
@ Armazenamos 4 bytes para o pid, 52 bytes de r0-r12, 4 bytes do SP_usr,
@ 4 bytes do LR_usr, 4 bytes do PC 4 bytes do SPSR
@ Caso o pid esteja vazio, o processo ainda não foi iniciado ou já foi encerrado.
PROCESS_CONTEXTS:
	PROCESS_1:	.space	72
	PROCESS_2:	.space	72
	PROCESS_3:	.space	72
	PROCESS_4:	.space	72
	PROCESS_5:	.space	72
	PROCESS_6:	.space	72
	PROCESS_7:	.space	72
	PROCESS_8:	.space	72
