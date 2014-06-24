.align 4
.text
_start:
	mov		r0, #0
	ldr		r1, =bla
	mov		r2, #7
	#bl		exit
	bl		fork
	bl		write
	bl		fork
	bl		write
while:
	add		r0, r0, #1
	b		while

.data
bla:	.asciz "alows\n\0"
