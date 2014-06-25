.align 4
.text
_start:
	b		main
	mov		r0, #0
	ldr		r1, =bla
	mov		r2, #7
	mov		r3, #48
	bl		fork
	bl		fork
while:
	mov		r0, #0
	ldr		r1, =bla
	strb	r3, [r1]
	mov		r2, #7
	push	{r3}
@	bl		write
	pop		{r3}
	add		r3, r3, #1
	mov		r2, r3
	add		r2, r2, #1
	while_2:
		cmp		r2, r3
		beq		while_2
	cmp		r3, #58
	bne		while

	bl		exit

.data
bla:	.asciz "alows\n\0"
