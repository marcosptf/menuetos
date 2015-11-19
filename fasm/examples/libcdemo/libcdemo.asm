
; fasm example of using the C library in Unix systems

; compile the source with commands like:
;   fasm libcdemo.asm libcdemo.o
;   gcc libcdemo.o -o libcdemo
;   strip libcdemo

format ELF

include 'ccall.inc'

section '.text' executable

 public main
 extrn printf
 extrn getpid

 main:
	call	getpid
	ccall	printf, msg,eax
	ret

section '.data' writeable

 msg db "Current process ID is %d.",0xA,0
