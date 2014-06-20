.align 4
.text
_start:
	mov		r0, #0
	mov		r1, =bla
	mov		r2, #7
	bl		write
	b		_start

.data
bla:	.asciz "alows\n\0
