
; fasm demonstration of writing 64-bit ELF executable
; (thanks to František Gábriš)

; syscall numbers: /usr/src/linux/include/asm-x86_64/unistd.h
; parameters order:
; r9    ; 6th param
; r8    ; 5th param
; r10   ; 4th param
; rdx   ; 3rd param
; rsi   ; 2nd param
; rdi   ; 1st param
; eax   ; syscall_number
; syscall

format ELF64 executable 3

segment readable executable

entry $

	mov	edx,msg_size	; CPU zero extends 32-bit operation to 64-bit
				; we can use less bytes than in case mov rdx,...
	lea	rsi,[msg]
	mov	edi,1		; STDOUT
	mov	eax,1		; sys_write
	syscall

	xor	edi,edi 	; exit code 0
	mov	eax,60		; sys_exit
	syscall

segment readable writeable

msg db 'Hello 64-bit world!',0xA
msg_size = $-msg