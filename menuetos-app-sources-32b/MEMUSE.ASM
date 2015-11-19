;
;    MEMORY USAGE
;
;    Compile with FASM for Menuet
;

use32

                org     0x0
                db      'MENUET00'              ; 8 byte id
                dd      38                      ; required os
                dd      START                   ; program start
                dd      I_END                   ; program image size
                dd      0x100000                ; required amount of memory
                                                ; esp = 0x7FFF0
                dd      0x00000000              ; reserved=no extended header



START:                          ; start of execution

    call draw_window            ; at first, draw the window

still:

    call draw_window
    call draw_usage

    mov  eax,23                 ; wait here for event
    mov  ebx,200
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   red
    cmp  eax,2                  ; key in buffer ?
    je   key
    cmp  eax,3                  ; button in buffer ?
    je   button

    jmp  still

  red:                          ; redraw
    call draw_window
    jmp  still

  key:                          ; key
    mov  eax,2                  ; just read it and ignore
    int  0x40
    jmp  still

  button:                       ; button
    mov  eax,17                 ; get id
    int  0x40

    cmp  ah,1                   ; button id=1 ?
    jne  noclose
    mov  eax,-1                 ; close this program
    int  0x40
  noclose:

    jmp  still


draw_usage:

    pusha

    mov  edi,1

    mov  ecx,1
    mov  ebx,I_END
  drl1:
    mov  eax,9
    int  0x40

    cmp  ecx,eax
    jg   drl11

    cmp  ecx,84
    jge  drl3

    pusha                    ; blue
    mov  ebx,5*65536+390
    shl  ecx,16+1
    add  ecx,65536*30
    mov  cx,2
    mov  edx,0x1111cc
    mov  eax,13
    int  0x40
    popa

    pusha                    ; white
    mov  ebx,[I_END+22]
    shr  ebx,17
    shl  ebx,16
    mov  eax,[I_END+26]
    shr  eax,17
    mov  bx,ax
    add  ebx,10*65536+1
    shl  ecx,16+1
    add  ecx,65536*30
    mov  cx,1
    mov  edx,0xffffff
    mov  eax,13
    int  0x40
    popa

   drl3:

    mov  esi,[I_END+22]
    add  esi,[I_END+26]
    cmp  esi,edi
    jbe  drl6
    mov  edi,esi
  drl6:

    inc  ecx

    jmp  drl1

  drl11:

    mov  eax,9
    mov  ebx,I_END
    mov  ecx,1
    int  0x40

    mov  ecx,eax
    mov  eax,47
    mov  ebx,4*65536
    mov  edx,10*65536+235
    mov  esi,0xffffff
    int  0x40

    mov  ecx,edi
    mov  eax,47
    mov  ebx,1*256+12*65536
    mov  edx,50*65536+235
    mov  esi,0xffffff
    int  0x40

    shr  ecx,17
    add  ecx,10
    mov  ebx,ecx
    shl  ebx,16
    mov  bx,cx
    mov  ecx,34*65536+200
    mov  edx,0xff0000
    mov  eax,38
    int  0x40

    popa
    ret



;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,10*65536+530          ; [x start] *65536 + [x size]
    mov  ecx,10*65536+250          ; [y start] *65536 + [y size]
    mov  edx,0x031111cc            ; color of work area RRGGBB,8->color glide
    mov  esi,0x8099bbff            ; color of grab bar  RRGGBB,8->color glide
    mov  edi,0x00ffffff            ; color of frames    RRGGBB
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x00ffffff            ; color of text RRGGBB
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

    mov  ebx,10
    mov  edi,64
    mov  ecx,25
    mov  edx,0xffffff
  newpix:
    mov  eax,1
    int  0x40
    add  ebx,8
    dec  edi
    jne  newpix

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA

labelt:
     db   'MEMORY USAGE'
labellen:

I_END:




