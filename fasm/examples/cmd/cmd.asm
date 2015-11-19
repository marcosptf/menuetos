; GetMainArgs v1.01
; Copyright © 2003 Theodor-Iulian Ciobanu

format PE GUI 4.0
entry start

include 'win32a.inc'
include 'cmd.inc'

  start:
        invoke  GetProcessHeap
        mov     [_hheap],eax
        invoke  HeapAlloc,[_hheap],HEAP_ZERO_MEMORY,1000h
        mov     [_strbuf],eax

        call    GetMainArgs
        mov     esi,[_argv]
        cinvoke wsprintf,[_strbuf],_fmt1,[_argc]
        mov     ebx,[_argc]
    @@:
        cinvoke wsprintf,[_strbuf],_fmt2,[_strbuf],[esi]
        add     esi,4
        dec     ebx
        cmp     ebx,0
        jnz     @b
        invoke  MessageBox,0,[_strbuf],_msgcap,MB_ICONINFORMATION+MB_OK

        invoke  HeapFree,[_hheap],0,[_argv]
        invoke  HeapFree,[_hheap],0,[_strbuf]
        invoke  ExitProcess,0

_strbuf  dd ?
_fmt1    db '%u',0
_fmt2    db '%s, "%s"',0
_msgcap  db 'Command line parameters',0
_hheap   dd ?

data import
 library kernel,'KERNEL32.DLL',\
         user,'USER32.DLL'

 import kernel,\
         GetCommandLine,'GetCommandLineA',\
         GetProcessHeap,'GetProcessHeap',\
         HeapAlloc,'HeapAlloc',\
         HeapFree,'HeapFree',\
         ExitProcess,'ExitProcess'

 import user,\
        MessageBox,'MessageBoxA',\
        wsprintf,'wsprintfA'
end data
