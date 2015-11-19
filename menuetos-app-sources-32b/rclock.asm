;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   M32 Clock
;
;   Copyright Ville Turjanmaa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use32

    org  0x0

    db   'MENUET01'             ; Header id
    dd   0x01                   ; Version
    dd   START                  ; Start of code
    dd   I_END                  ; Size of image
    dd   0x100000               ; Memory for app
    dd   0x7fff0                ; Esp
    dd   0x0,0x0                ; I_Param,I_Icon

START:                          ; Start of execution

    mov  eax , 14
    int  0x40
    mov  [screensize],eax

    call shape_window

    call calculate_coordinates

    call draw_window

still:

    mov  eax,23                 ; Wait here for event
    mov  ebx,100
    int  0x40

    cmp  eax,1                  ; Redraw request
    je   red
    cmp  eax,2                  ; Key in buffer
    je   key
    cmp  eax,3                  ; Button in buffer
    je   button

    call draw_screen

    jmp  still

red:                            ; Redraw
    call draw_window
    jmp  still

key:                            ; Key
    mov  eax,2                  ; Just read it and ignore
    int  0x40

    mov  eax , -1
    int  0x40

    jmp  still

button:                         ; Button
    mov  eax,17                 ; Get id
    int  0x40

    shr  eax , 8

    cmp  eax , 1                ; Button close
    jne  noclose
    mov  eax , -1
    int  0x40
  noclose:

    cmp  eax , 0x106            ; Menu close
    jne  noc
    mov  eax , -1
    int  0x40
  noc:

    jmp  still


shape_window:

    mov  eax , 58
    mov  ebx , loadshape
    int  0x40

    mov  esi , 0x20000+18*3
    mov  edi , 0x80000+64*129*3
    mov  eax , 0
  newline:
    push esi edi
    mov  ecx , 64*3
    cld
    rep  movsb
    pop  edi esi
    add  esi , 64*3
    add  edi , 128*3
    add  eax , 1
    cmp  eax , 64
    jb   newline

    mov  esi , 0x20000+18*3
    mov  edi , 0x80000+64*127*3
    mov  eax , 0
  newline2:
    push esi edi
    mov  ecx , 64*3
    cld
    rep  movsb
    pop  edi esi
    add  esi , 64*3
    sub  edi , 128*3
    add  eax , 1
    cmp  eax , 64
    jb   newline2

    mov  esi , 0x80000+64*3
    mov  edi , 0x80000+64*3-1
    mov  eax , 0
  newline3:
    mov  ecx , 0
    push esi edi
  newline4:
    mov  bl , [esi]
    mov  [edi],bl
    add  esi , 1
    sub  edi , 1
    add  ecx , 1
    cmp  ecx , 64*3
    jb   newline4
    pop  edi esi
    add  esi , 128*3
    add  edi , 128*3
    add  eax , 1
    cmp  eax , 128
    jb   newline3

    mov  esi , 0x80000
    mov  edi , 0x40000
  shp1:
    mov  al  , 1
    cmp  [esi],word 0xffff
    jne  notrp
    cmp  [esi+2],byte 0xff
    jne  notrp

    mov  al , 0
  notrp:
    mov  [edi],al
    add  edi , 1
    add  esi , 3
    cmp  edi , 0x40000+128*128
    jbe  shp1

    mov  eax , 50
    mov  ebx , 0
    mov  ecx , 0x40000
    int  0x40

    ret


draw_window:

    mov  eax,12                 ; Function 12: window draw
    mov  ebx,1                  ; Start of draw
    int  0x40

                                ; DRAW WINDOW ( Type 4 )
    mov  eax,0                  ; Function 0 : define and draw window
    mov  ebx , [screensize]
    sub  ebx , 270 shl 16
    mov  bx  , 127
    mov  ecx,100*65536+127      ; [y start] *65536 + [y size]
    mov  edx,0x01ffffff         ; Color of work area RRGGBB,8->color gl
    mov  esi,0                  ; Pointer to window label (asciiz) or z
    mov  edi,0                  ; Pointer to menu struct or zero
    int  0x40

    call draw_screen

    mov  eax,12                 ; Function 12: window draw
    mov  ebx,2                  ; End of draw
    int  0x40

    ret


getbcd:

    push eax ebx ecx
    mov  eax , edx
    shr  edx , 4
    and  edx , 0xf
    imul edx , 10
    mov  ecx , eax
    and  ecx , 0xf
    add  edx , ecx
    pop  ecx ebx eax

    ret


draw_screen:

    ; Image

    mov  eax , 7
    mov  ebx , 0x80000
    mov  ecx , 128 shl 16 + 128
    mov  edx , 0
    int  0x40

    ; Date

    mov  eax , 29
    int  0x40

    mov  edx , eax
    shr  edx , 8
    call getbcd
    mov  edx , [months+edx*4-4]
    mov  [text+0],edx

    mov  edx , eax
    shr  edx , 16
    and  edx , 0xf
    add  edx , 48
    mov  [text+4],dl
    mov  edx , eax
    shr  edx , 16+4
    and  edx , 0xf
    add  edx , 48
    mov  [text+3],dl

    mov  [text+5],byte 0

    ; Time

    mov  eax , 3
    int  0x40

    mov  edx , eax
    call getbcd
    push edx
    mov  edx , eax
    shr  edx , 8
    call getbcd
    push edx
    mov  edx , eax
    shr  edx , 16
    call getbcd
    push edx

    ; Text

    mov  eax,4                  ; Draw info text
    mov  ebx,49*65536+93
    ;cmp  [esp+4],dword 25
    ;jb   nopos1
    ;cmp  [esp+4],dword 35
    ;ja   nopos1
    ;mov  ebx,49*65536+30
    ;nopos1:
    pusha
    mov  eax , 13
    mov  ecx , ebx
    sub  ecx , 2
    shl  ecx , 16
    add  ecx , 12
    mov  ebx , 47 shl 16 + 33
    mov  edx , 0xf4f4f4
    int  0x40
    popa
    mov  ecx,0xa8a8a8
    mov  edx,text
    mov  esi,-1
    int  0x40

    ; Pointers

    mov   ebp , [esp+8]
    cmp   ebp , 12
    jb    ebpfine
    sub   ebp , 12
  ebpfine:
    imul  ebp , 5
    mov   eax , 38
    movzx ebx , byte [posx+ebp]
    movzx ecx , byte [posy+ebp]
    imul  ebx , 128+64
    imul  ecx , 128+64
    shr   ebx , 8
    shr   ecx , 8
    add   ebx , 16
    add   ecx , 16
    shl   ebx , 16
    shl   ecx , 16
    add   ebx , 64
    add   ecx , 64
    mov   edx , 0x000000
    mov   eax , 38
    int   0x40

    mov   ebp , [esp+4]
    mov   eax , 38
    movzx ebx , byte [posx+ebp]
    movzx ecx , byte [posy+ebp]
    shl   ebx , 16
    shl   ecx , 16
    add   ebx , 64
    add   ecx , 64
    mov   edx , 0x000000
    mov   eax , 38
    int   0x40

    mov   ebp , [esp+0]
    mov   eax , 38
    movzx ebx , byte [posx+ebp]
    movzx ecx , byte [posy+ebp]
    shl   ebx , 16
    shl   ecx , 16
    add   ebx , 64
    add   ecx , 64
    mov   edx , 0xff0000
    mov   eax , 38
    int   0x40

    add   esp , 12

    ret


calculate_coordinates:

    mov    esi , posx
    call   ccl0
    mov    esi , posy
    call   ccl0

    ret

  ccl0:
    mov    edi , esi
    add    edi , 59
  ccl1:
    movzx  eax , byte [esi+0]
    movzx  ebx , byte [esi+5]
    mov    ecx , 1
  ccl2:
    push   eax ebx
    mov    edx , 5
    sub    edx , ecx
    imul   eax , edx
    imul   ebx , ecx
    add    eax , ebx
    xor    edx , edx
    mov    ebx , 5
    div    ebx
    mov    [esi+ecx],al
    pop    ebx eax
    add    ecx , 1
    cmp    ecx , 4
    jbe    ccl2
    add    esi , 5
    cmp    esi , edi
    jb     ccl1

    ret

; DATA AREA

screensize: dq 0x0

months: db 'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec '

posx: db  64,0,0,0,0
      db  85,0,0,0,0
      db 100,0,0,0,0
      db 105,0,0,0,0
      db 100,0,0,0,0
      db  85,0,0,0,0
      db  64,0,0,0,0
      db  42,0,0,0,0
      db  27,0,0,0,0
      db  22,0,0,0,0
      db  27,0,0,0,0
      db  42,0,0,0,0
      db  64,0,0,0,0

posy:
      db  20,0,0,0,0
      db  27,0,0,0,0
      db  42,0,0,0,0
      db  64,0,0,0,0
      db  84,0,0,0,0
      db 100,0,0,0,0
      db 107,0,0,0,0
      db 100,0,0,0,0
      db  84,0,0,0,0
      db  64,0,0,0,0
      db  42,0,0,0,0
      db  27,0,0,0,0
      db  20,0,0,0,0


text:

    db   '            ',0

loadshape:

    dd   0
    dd   0
    dd   -1
    dd   0x20000
    dd   0x10000
    db   '/rd/1/rclock.bmp',0


I_END:




