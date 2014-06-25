@ Desenvolvido por Diego Rocha, RA 135494, Tomas Silva Queiroga, RA 137748, Unicamp, Ciencia da Computacao, CC012, em 2014
@ Formatado com \t = '    ' (um tab igual a 4 espacos)
@ Para MC404, T03, Escalonador de Tarefas Preemptivo

.org 0x0
.section .iv,"a"

_start:

interrupt_vector:								@ vetor contendo as interrupções tradas
	b	RESET_HANDLER
.org 0x8
	b	SVC_HANDLER
.org 0x18
	b	IRQ_HANDLER

SET_STACKS: 
@ Constantes para os enderecos do inicio da pilha para cada um dos modos (sys usará o mesmo de usr)
	.set SVC_STACK, 		0x77701000
	.set UND_STACK, 		0x77702000
	.set ABT_STACK, 		0x77703000
	.set IRQ_STACK, 		0x77704000
	.set FIQ_STACK, 		0x77705000
	.set USR_STACK, 		0x77706000
	.set CONTEXT_SIZE, 		72					@ tamanho do espaco destinado a guardar o contexto de cada processo

SET_TZIC:
@ Constantes para os enderecos do TZIC
	.set TZIC_BASE,			0x0FFFC000
@ offsets em relacao a base
	.set TZIC_INTCTRL,		0x0					@ 0x0FFFFC000
	.set TZIC_PRIOMASK,		0xC					@ 0x0FFFFC00C
	.set TZIC_INTSEC1,		0x84				@ 0x0FFFFC084
	.set TZIC_ENSET1,		0x104				@ 0x0FFFFC104
	.set TZIC_PRIORITY9,	0x424				@ 0x0FFFFC424

SET_GPT:
@ quantos ciclos serão executados até que se gere uma interrupção
	.set GPT_CICLES,		0x32
@ Constantes para os enderecos do GPT
	.set GPT_BASE,			0x53FA0000
@ offsets em relacao a base
	.set GPT_CR,			0x0000				@ 0x53FA0000
	.set GPT_PR,			0x0004				@ 0x53FA0004
	.set GPT_SR,			0x0008				@ 0x53FA0008
	.set GPT_IR,			0x000C				@ 0x53FA000C
	.set GPT_OCR1,			0x0010				@ 0x53FA0010

SET_UART:
@ Constantes para os enderecos do UART
	.set UART_BASE,			0x53FBC000
@ offsets em relacao a base
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
												@ Configura stacks
INIT_STACKS_POINTERS:
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

INIT_GPT:										@ Liga o GPT
	ldr		r0, =GPT_BASE

	mov		r1, #0x41
	str		r1, [r0, #GPT_CR]

	mov		r1, #0
	str		r1, [r0, #GPT_PR]

	mov		r1, #GPT_CICLES						@ configura o GPT para n ciclos
	str		r1, [r0, #GPT_OCR1]

	mov		r1, #1
	str		r1, [r0, #GPT_IR]

INIT_TZIC:										@ Liga o controlador de interrupcoes
	ldr		r1, =TZIC_BASE						@ R1 <= TZIC_BASE
												@ Configura interrupcao 39 do GPT como nao segura
	mov		r0, #(1 << 7)
	str		r0, [r1, #TZIC_INTSEC1]
												@ Habilita interrupcao 39 (GPT)
	mov		r0, #(1 << 7)						@ reg1 bit 7 (gpt)
	str		r0, [r1, #TZIC_ENSET1]
												@ Configure interrupt39 priority as 1
	ldr		r0, [r1, #TZIC_PRIORITY9]			@ reg9, byte 3
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

INIT_UART:										@ configura o UART
	ldr		r0, =UART_BASE

	mov		r1, #0x1							@ Habilita o UART
	str		r1, [r0, #UART_UCR1]

	mov		r1, #0x21							@ Define o fluxo de controle do hardware, formato dos dados e habilita transmicao e recepcao
	mov		r1, r1, lsl #8
	add		r1, r1, #0x27
	str		r1, [r0, #UART_UCR2]

	mov		r1, #0x7							@ UCR3[RXDMUXSEL] = 1
	mov		r1, r1, lsl #8
	add		r1, r1, #0x04
	str		r1, [r0, #UART_UCR3]

	mov		r1, #0x7C							@ CTS trigger level: 31 (31 = 1F, 7C = 1F << 2
	mov		r1, r1, lsl #8
	str		r1, [r0, #UART_UCR4]

	mov		r1, #0x8							@ Divide o clock de input do uart por 5. Entao o clock sera 100MHz/5 = 20MHz.  TXTL = 2 and RXTL = 30
	mov		r1, r1, lsl #8
	add		r1, r1, #0x9E
	str		r1, [r0, #UART_UFCR]

	mov		r1, #0x8							@ Taxa de transmissao = 921.6Kbps,  baseado no clock de 20MHz
	mov		r1, r1, lsl #8
	add		r1, r1, #0xFF
	str		r1, [r0, #UART_UBIR]

	mov		r1, #0xC
	mov		r1, r1, lsl #8
	add		r1, r1, #0x34
	str		r1, [r0, #UART_UBMR]

INIT_USER_PROCESS:								@ Inicia o primeiro processo de usuário
	ldr		r0, =PROCESS_1
	mov		r1, #1
	str		r1, [r0]

	ldr		r0, =USER_TEXT						@ Carrega endereço do início do programa de usuário
	ldr		r0, [r0]

	msr		SPSR, #0x10							@ Entra em modo de usuário com interrupções habilitadas e salta para o inicio do programa do usuario, quando executar o movs
	movs	pc, r0

IRQ_HANDLER:
	push	{r0-r3}								@ nao queremos sujar qualquer registrador antes de salvar o contexto

	sub		lr, lr, #4							@ no modo IRQ, o endereco de retorno eh LR - 4

	ldr		r0, =GPT_BASE						@ zera flag, para nao tratar esta interrupcao novamente
	mov		r1, #1
	str		r1, [r0, #GPT_SR]

	pop		{r0-r3}

	push	{lr}								@ SAVE_CONTEXT recebe por "parametro" o lr empilhado
	bl		SAVE_CONTEXT						@ salva context do processo atual
	pop		{lr}

	push	{lr}
	bl		FIND_NEXT_READY_CONTEXT				@ encontra proximo processo a ser executado
	pop		{lr}

	cmp		r0, #0
	blne	LOAD_CONTEXT						@ carrega contexto do novo processo

IRQ_HANDLER_END:
	movs	pc, lr								@ "retorna", pula para o pc (que esta no lr deste modo) do novo contexto 

SVC_HANDLER:
	cmp		r7, #1								@ apenas tratamos as syscalls definidas a baixo
	beq		SYSCALL_EXIT

	cmp		r7, #2
	beq		SYSCALL_FORK

	cmp		r7, #4
	beq		SYSCALL_WRITE

	cmp		r7, #20
	beq		SYSCALL_GETPID
												@ se nao for nenhuma das syscalls tradadas
SVC_END:
	movs	pc, lr								@ retorna ao modo de usuario, e retorna

@ Salva o contexto do processo que está rodando atualmente, com o lr salvo na pilha.
@ Entrada
@ r0-r12 e lr na pilha
SAVE_CONTEXT:
	push	{r0, r1}							@ Empilha r0 e r1, pois iremos sujá-los, e precisamos de seus valores originais, para salvar o contexto
	ldr		r0, =RUNNING_PID					@ Carrega número do processo em execução
	ldr		r0, [r0]
	sub		r0, r0, #1
	mov		r1, #CONTEXT_SIZE					@ cada contexto ocupa 72 bytes
	mul		r1, r0, r1							@ r1 = offset em relacao ao primeiro espaco destinado a contextos de processos

	ldr		r0, =PROCESS_CONTEXTS				@ Encontra endereço do contexto do processo atual
	add		r0, r0, r1							@ r0 = primeiro endereco do contexto onde serao salvos os registradores

	ldr		r1, =RUNNING_PID					@ Carrega o PID do processo atual
	ldr		r1, [r1]
	str		r1, [r0]							@ Salva PID do processo atual no contexto

	mrs		r1, SPSR							@ Salva SPSR_svc como cpsr para usr
	str		r1, [r0, #4]

	ldr		r1, [sp, #8]						@ Carrega lr_svc da stack e salva como pc no contexto
	str		r1, [r0, #8]

	mrs		r1, CPSR
	msr		CPSR_c, #0xDF						@ Altera para modo system, sem iterrupcoes FIQ e IRQ
	str		lr, [r0, #12]						@ Salva lr_usr como lr no contexto

	str		sp, [r0, #16]						@ Salva sp_usr como sp no contexto
	msr		CPSR_c, r1

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

	push	{r2, r3}							@ usamos r2 e r3 para ser os r0 e r1, que atualmente estao sendo usados
	ldr		r2, [sp, #8]
	ldr		r3, [sp, #12]

	str		r3, [r0, #64]						@ Salva r3 como r1 no contexto
	str		r2, [r0, #68]						@ Salva r2 como r0 no contexto

	pop		{r2, r3}
	pop		{r0, r1}

	mov		pc, lr								@ Retorna

@ Carrega processo para execução.
@ Entrada
@ r0: PID
LOAD_CONTEXT:
	push	{lr}								@ Empilha lr para podermos retornar

	ldr		r1, =RUNNING_PID					@ Grava número do processo como processo atual
	str		r0, [r1]

	sub		r0, r0, #1
	mov		r1, #CONTEXT_SIZE
	mul		r1, r0, r1							@ r1 = offset em relacao ao primeiro espaco destinado a contextos de processos

	ldr		r0, =PROCESS_CONTEXTS				@ Encontra endereço do contexto do processo
	add		r0, r0, r1							@ r0 = primeiro endereco do contexto onde serao salvos os registradores

	ldr		r1, [r0, #4]						@ Carrega SPSR do contexto
	msr		SPSR, r1

	ldr		lr, [r0, #8]						@ Carrega lr_svc do contexto

	mrs		r1, CPSR
	msr		CPSR_c, #0xDF						@ Altera para modo system
	ldr		lr, [r0, #12]						@ Carrega lr_usr
	ldr		sp, [r0, #16]						@ Carrega sp_usr
	msr		CPSR_c, r1							@ Volta para modo svc

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

@ finaliza o processo atual, e comeca a executar o proximo que esteja pronto
SYSCALL_EXIT:
	push	{lr}								@ Guardamos lr na stack (mesmo que o usemos)

	ldr		r0, =RUNNING_PID
	ldr		r0, [r0]
	sub		r2, r0, #1
	mov		r1, #CONTEXT_SIZE
	mul		r1, r2, r1							@ r1 = offset em relacao ao primeiro espaco destinado a contextos de processos
	ldr		r2, =PROCESS_CONTEXTS				@ Encontra endereço do contexto do processo atual
	add		r2, r2, r1							@ r2 = primeiro endereco do contexto onde serao salvos os registradores

	mov		r1, #0								@ zera o espaco no contexto destinado ao PID, para sabermos que eh um processo morto
	str		r1, [r2]

	bl		FIND_NEXT_READY_CONTEXT				@ buscamos o proximo PID (contexto que esta disponivel e pronto para rodar

	pop		{lr}

	cmp		r0, #0								@ r0 sera 0 se todos os 8 processos estiverem mortos
	beq		SYSCALL_EXIT_WAIT					@ se nao, entramos em loop, pois acabaram os processos, nada mais deve ser executado 
	blne	LOAD_CONTEXT						@ se temos um processo pronto, carregamos seu contexto

	b		SVC_END								@ retorna

SYSCALL_EXIT_WAIT:								@ todos os processos foram finalizados.
	b		SYSCALL_EXIT_WAIT

@ copia o contexto RUNNING_PID para o proximo espaço de contexto disponivel
@ retorna r0 = 0 no novo processo criado, identico ao processo atual
@ retorna r0 = PID_NOVO_PROCESSO
SYSCALL_FORK:
	push	{r1, r2}

	ldr		r0, =RUNNING_PID
	ldr		r0, [r0]
	push	{r0}								@ Empilha PID do processo atual

	push	{lr}
	bl		FIND_EMPTY_CONTEXT					@ encontramos o primeiro espaco livre para se colocar um contexto novo
	pop		{lr}

	cmp		r0, #0								@ Verifica se encontramos um espaço livre
	beq		SYSCALL_FORK_FAIL					@ Caso não tenhamos encontrado, exibimos um erro

	ldr		r1, =RUNNING_PID					@ Grava número do novo processo como processo atual
	str		r0, [r1]

	sub		r0, r0, #1							@ calcula enderedo de memoria inicial para pilha do processo
	mov		r1, #0x1000							@ cada pilha tem 0x1000 enderecos de memoria disponiveis 
	mul		r1, r0, r1
	ldr		r2, =USR_STACK
	add		r1, r1, r2

	mrs		r0, CPSR
	msr		CPSR_c, #0xDF						@ Altera para modo system, sem iterrupcoes FIQ e IRQ
	mov		r2, sp
	mov		sp, r1								@ salva sp do modo usuario
	msr		CPSR_c, r0
	push	{r2}

	ldr		r1, [sp, #4]						@ recuperamos valores dos registradores, para salvar no contexto
	ldr		r2, [sp, #8]
	mov		r0, #0
	push	{lr}
	bl		SAVE_CONTEXT						@ salvara contexto do processo atual no novo
	pop		{lr}

	pop		{r2}
	mrs		r0, CPSR
	msr		CPSR_c, #0xDF						@ Altera para modo system, sem iterrupcoes FIQ e IRQ
	mov		sp, r2								@ salva sp do modo usuario
	msr		CPSR_c, r0

	pop		{r0}
	ldr		r1, =RUNNING_PID					@ Retorna a "executar" o processo atual
	str		r0, [r1]

	pop		{r1, r2}
	b		SVC_END

SYSCALL_FORK_FAIL:
	mov		r0, #0								@ Exibimos uma mensagem de erro
	ldr		r1, =SYSCALL_FORK_FAIL_MSG
	mov		r2, #41
	mov		r7, #4
	svc		0
	b		SYSCALL_EXIT_WAIT					@ Saltamos para um loop infinito (FIM)

@ escreve os r2 caracteres, comecando pelo aquele que esta no endereco r1, sem alterar qualquer registrador
SYSCALL_WRITE:
	push	{r0-r4}
	ldr		r0, =UART_BASE

	WRITE:										@ enquanto ainda temos caracteres a serem escritos
		WAIT_TO_WRITE:
			ldr		r3, [r0, #UART_USR1]		@ se o 13o bit de USR1 for 0
			mov		r4, #(1 << 13)				@ temos de esperar para escrever
			and		r4, r4, r3
			cmp		r4, #0
			beq		WAIT_TO_WRITE				@ busy wating

		sub		r2, r2, #1						@ podemos escrever, r2 tem quantos caracteres ainda restam a ser escrito
		ldr		r4, [r1], #1					@ r4 = r1[i++]
		str		r4, [r0, #UART_UTXD]			@ escrevemos na fila a ser transmitida
		cmp		r2, #0							@ se ainda tem caracteres a serem escritos
		bne		WRITE							@ continuamos o loop

SYSCALL_WRITE_END:
	pop		{r0-r4}
	b		SVC_END

@ retorna r0 = PID do processo atual
SYSCALL_GETPID:
	ldr		r0, =RUNNING_PID
	ldr		r0, [r0]

SYSCALL_GETPID_END:
	b		SVC_END

@ Função auxiliar que encontra um contexto que não é utilizado por nenhum processo
FIND_EMPTY_CONTEXT:
	push	{r1-r3, lr}

	ldr		r0, =PROCESS_CONTEXTS				@ Obtém endereço dos contextos
	ldr		r2, =PROCESS_8						@ Obtém endereço do último contexto
	mov		r3, #1								@ Inicializa contador de PID
	FIND_EMPTY_CHECK_CONTEXT:
		ldr		r1, [r0]						@ Carrega PID do contexto

		cmp		r1, #0							@ Compara PID com 0
		beq		FIND_EMPTY_CONTEXT_END			@ Caso o PID seja igual a 0, 
												@ então este contexto não está sendo utilizado,
												@ então encerramos

		cmp		r0, r2							@ Compara endereço deste contexto com o último
		moveq	r3, #0							@ Caso sejam iguais, não há nenhum contexto disponível
		beq		FIND_EMPTY_CONTEXT_END			@ Então, encerramos

		add		r0, r0, #CONTEXT_SIZE			@ Passamos para o endereço do próximo contexto
		add		r3, r3, #1						@ Incrementamos o contador
		b		FIND_EMPTY_CHECK_CONTEXT		@ Realizamos o loop novamente

FIND_EMPTY_CONTEXT_END:
	mov		r0, r3								@ Passamos o PID para r0
	pop		{r1-r3, pc}							@ Retornamos

@ Função auxiliar que encontra o contexto do próximo processo READY
FIND_NEXT_READY_CONTEXT:
	push	{r1-r4, lr}

	ldr		r0, =RUNNING_PID					@ Carrega número do processo em execução
	ldr		r3, [r0]

	sub		r0, r3, #1
	mov		r1, #CONTEXT_SIZE
	mul		r1, r0, r1

	ldr		r0, =PROCESS_CONTEXTS				@ Encontra endereço do contexto do processo atual
	add		r0, r0, r1
	mov		r4, r0								@ Armazena endereço em r0, pois iremos utilizá-lo

	ldr		r2, =PROCESS_8						@ Carrega endereço do último contexto

	FIND_NEXT_CHECK_CONTEXT:
		cmp		r0, r2							@ Compara endereço do contexto atual com o último
		ldreq	r0, =PROCESS_CONTEXTS			@ Caso sejam iguais, retorna ao primeiro contexto
		moveq	r3, #1
		addne	r0, r0, #CONTEXT_SIZE			@ Caso contrário, passa para o próximo contexto
		addne	r3, r3, #1

		ldr		r1, [r0]						@ Verifica se este contexto possui PID
		cmp		r1, #0							@ Caso possua, é o contexto de um processo READY ou RUNNING
		beq		FIND_NEXT_CHECK_CONTEXT			@ Caso não possua, buscamos o próximo processo

		cmp		r0, r4							@ Verifica se este é o contexto do processo inicial (RUNNING)
		moveq	r3, #0							@ Caso seja, não encontramos nenhum contexto de processo READY

FIND_NEXT_READY_CONTEXT_END:
	mov		r0, r3								@ Passamos o PID para r0
	pop		{r1-r4, pc}							@ Retornamos

.data
USER_TEXT:			.word	0x77802000			@ Início do programa de usuário
RUNNING_PID:		.word	1					@ PID do processo em execução, o primeiro a ser executado sera o 1
SYSCALL_FORK_FAIL_MSG:	.asciz "Numero maximo de processos atingido (8)\n\0"

@ Contextos
@ Armazenamos 4 bytes para o pid, 52 bytes de r0-r12, 4 bytes do SP_usr,
@ 4 bytes do LR_usr, 4 bytes do PC 4 bytes do SPSR
@ Caso o pid esteja vazio (0), o processo ainda não foi iniciado ou já foi encerrado.
@ 4 * 5 + 52 = 72 = CONTEXT_SIZE
PROCESS_CONTEXTS:
	PROCESS_1:	.space	CONTEXT_SIZE
	PROCESS_2:	.space	CONTEXT_SIZE
	PROCESS_3:	.space	CONTEXT_SIZE
	PROCESS_4:	.space	CONTEXT_SIZE
	PROCESS_5:	.space	CONTEXT_SIZE
	PROCESS_6:	.space	CONTEXT_SIZE
	PROCESS_7:	.space	CONTEXT_SIZE
	PROCESS_8:	.space	CONTEXT_SIZE
