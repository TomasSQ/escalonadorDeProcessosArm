.align 4
.text
_start:
	mov		r0, #0
	ldr		r1, =bla
	mov		r2, #7
	bl		fork
	#bl		write
	b		_start

.data
bla:	.asciz "alows\n\0"