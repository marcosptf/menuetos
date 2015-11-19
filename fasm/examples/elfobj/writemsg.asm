
format ELF

section '.text' executable

 public writemsg

 writemsg:
	mov	ecx,esi
    find_end:
	lodsb
	or	al,al
	jnz	find_end
	mov	edx,esi
	sub	edx,ecx
	mov	eax,4
	mov	ebx,1
	int	0x80
	ret
