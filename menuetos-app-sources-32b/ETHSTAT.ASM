;
;    Stack Status Monitor
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
                dd      0x00000000              ; reserved=no extended header


START:                          ; start of execution

    call read_status
    call draw_window            ; at first, draw the window

still:

    mov  eax,23                 ; wait here for event
    mov  ebx,200    ; Time out after 2s
    int  0x40

    cmp  eax,1                  ; redraw request ?
    jz   red
    cmp  eax,2                  ; key in buffer ?
    jz   key
    cmp  eax,3                  ; button in buffer ?
    jz   button

    call read_status
    call draw_window

    jmp  still

read_status:

 ; read the stack status data, and write it to the screen buffer

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 6
 int  0x40

 mov  ebx, text + 24
 call printhex

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 2
 int  0x40

 mov  ebx, text + 107
 call printhex

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 5
 int  0x40

 mov  ebx, text + 107 + 40
 call printhex

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 4
 int  0x40

 mov  ebx, text + 107 + 80
 call printhex

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 3
 int  0x40

 mov  ebx, text + 107 + 120
 call printhex

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 100
 int  0x40

 mov  ebx, text + 258 + 40
 call printhex

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 101
 int  0x40

 mov  ebx, text + 258 + 80
 call printhex

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 102
 int  0x40

 mov  ebx, text + 258 + 120
 call printhex

 mov  eax, 53
 mov  ebx, 255
 mov  ecx, 103
 int  0x40

 mov  ebx, text + 258 + 160
 call printhex

 ret


red:                           ; redraw
    call draw_window
    jmp  still

key:                           ; Keys are not valid at this part of the
    mov  eax,2                  ; loop. Just read it and ignore
    int  0x40
    jmp  still

button:                        ; button
    mov  eax,17                 ; get id
    int  0x40

    cmp  ah,1                   ; button id=1 ?
    jnz  still

    mov  eax,0xffffffff         ; close this program
    int  0x40

    jmp  still




;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,100*65536+260         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+210         ; [y start] *65536 + [y size]
    mov  edx,0x04ffffff            ; color of work area RRGGBB
    mov  esi,window_label          ; color of grab bar  RRGGBB,8->co
    mov  edi,0                     ; color of frames    RRGGBB
    int  0x40

    ; Screen text

    mov  ebx,25*65536+40           ; draw info text with function 4
    mov  ecx,0x000000
    mov  edx,text
    mov  esi,40
  newline:
    mov  eax,4
    int  0x40
    add  ebx,14
    add  edx,40
    cmp  [edx],byte 'x'
    jnz  newline


    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret

; Taken from PS.ASM
printhex:
; number in eax
; print to ebx
; xlat from hextable
 pusha
 mov esi, ebx
 add esi, 8
 mov ebx, hextable
 mov ecx, 8
phex_loop:
 mov edx, eax
 and eax, 15
 xlatb
 mov [esi], al
 mov eax, edx
 shr eax, 4
 dec esi
 loop phex_loop
 popa
 ret


; DATA AREA

text:

    db ' Ethernet card status : xxxxxxxx        '
    db '                                        '
    db ' IP packets received     : xxxxxxxx     '
    db ' ARP packets received    : xxxxxxxx     '
    db ' Dumped received packets : xxxxxxxx     '
    db ' IP packets sent         : xxxxxxxx     '
    db '                                        '
    db ' Empty queue    : xxxxxxxx              '
    db ' IPout queue    : xxxxxxxx              '
    db ' IPin  queue    : xxxxxxxx              '
    db ' NET1out queue  : xxxxxxxx              '
    db 'x <- END MARKER, DONT DELETE            '


window_label:

    db   'STACK STATUS',0

hextable db '0123456789ABCDEF'


I_END:







