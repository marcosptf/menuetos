
format ELF executable 3
entry start

include 'import32.inc'
include 'proc32.inc'

interpreter '/lib/ld-linux.so.2'
needed 'libc.so.6'
import printf,exit

segment readable executable

start:
	cinvoke printf,msg
	cinvoke exit

segment readable writeable

msg db 'Hello world!',0xA,0
