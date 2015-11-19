; GetMainArgs v1.01
; Copyright © 2003 Theodor-Iulian Ciobanu

; uses heap instead of local

  GetMainArgs:
        pusha
        invoke  GetCommandLine  ;_argc - number of args, _argv - ptr to arg table
        mov     [_argc],0
        xor     ebx,ebx
        cmp     byte [eax],22h  ;quotation mark
        jz      .startquote
        mov     [_argc],1
        push    eax

    .count:
        cmp     byte [eax],0
        jz      .endcount
        cmp     byte [eax],22h  ;quotation mark
        jz      .solvequote
        cmp     ebx,1           ;is in quote
        jz      .isinquote
        cmp     byte [eax],20h  ;space
        jz      .pusharg
        cmp     byte [eax],09h  ;tab
        jz      .pusharg
      .isinquote:
        inc     eax
        jmp     .count

    .pusharg:
        mov     byte [eax],0
        inc     eax
      .remspaces:
        cmp     byte [eax],0
        jz      .endcount
        cmp     byte [eax],22h  ;quotation mark
        jz      .startquote
        cmp     byte [eax],20h  ;space
        jz      .isspace
        cmp     byte [eax],09h  ;tab
        jnz     .endremspaces
      .isspace:
        inc     eax
        jmp     .remspaces
      .endremspaces:
        inc     [_argc]
        push    eax
        jmp     .count

    .solvequote:
        cmp     ebx,1
        jz      .endquote
      .startquote:
        mov     ebx,1
        inc     eax
        jmp     .endremspaces
      .endquote:
        mov     ebx,0
        jmp     .pusharg

    .endcount:
        mov     eax,[_argc]
        mov     ecx,4
        mul     ecx
        push    eax
        invoke  HeapAlloc,[_hheap],HEAP_ZERO_MEMORY,eax
        mov     [_argv],eax
        pop     eax
        sub     eax,4
        mov     esi,[_argv]
        add     esi,eax

    .saveargs:
        cmp     esi,[_argv]
        jb      .endsaveargs
        pop     eax
        mov     [esi],eax
        sub     esi,4
        jmp     .saveargs

    .endsaveargs:
        popa
        ret

_argc    dd ?
_argv    dd ?
