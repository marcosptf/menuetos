;
;    CPU SPEED INDICATIOR
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
   
    mov  eax,18
    mov  ebx,5
    int  0x40
   
    xor  edx,edx
    mov  ebx,1000000
    div  ebx
    mov  ebx,10
    mov  edi,text+19
    mov  ecx,5
  newnum:
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  dl,48
    mov  [edi],dl
    sub  edi,1
    loop newnum
   
    call draw_window            ; at first, draw the window
   
still:
   
    mov  eax,10                 ; wait here for event
    int  0x40
   
    cmp  eax,1                  ; redraw request ?
    jz   red
    cmp  eax,2                  ; key in buffer ?
    jz   key
    cmp  eax,3                  ; button in buffer ?
    jz   button
   
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
    jnz  noclose
    mov  eax,0xffffffff         ; close this program
    int  0x40
  noclose:
   
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
    mov  ebx,100*65536+200         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+65          ; [y start] *65536 + [y size]
    mov  edx,0x001111aa            ; color of work area RRGGBB,8->color glide
    mov  esi,0x805577cc            ; color of grab bar  RRGGBB,8->color
    mov  edi,0x00ffffff            ; color of frames    RRGGBB
    int  0x40
   
                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x00ffffff            ; color of text RRGGBB
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40
                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,(200-19)*65536+12     ; [x start] *65536 + [x size]
    mov  ecx,5*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,0x3355aa              ; button color RRGGBB
    int  0x40
   
    mov  ebx,25*65536+35           ; draw info text with function 4
    mov  ecx,0xffffff
    mov  edx,text
    mov  esi,40
  newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,40
    cmp  [edx],byte 'x'
    jnz  newline
   
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40
   
    ret
   
   
; DATA AREA
   
   
text:
    db 'CPU RUNNING AT       MHZ                '
    db 'x <- END MARKER, DONT DELETE            '
   
labelt:
    db   'CPU SPEED'
labellen:
   
I_END:
   
   
   
   