;
;   DEBUG BOARD
;
;   Compile with FASM for Menuet
;

use32

               org    0x0

               db     'MENUET01'              ; 8 byte id
               dd     0x01                    ; header version
               dd     START                   ; start of code
               dd     I_END                   ; size of image
               dd     0x100000                ; memory for app
               dd     0x7fff0                 ; esp
               dd     0x0 , 0x0               ; I_Param , I_Icon

xpos  dd 0x0
ypos  dd 11

START:                          ; start of execution

     mov  ecx,1024
    clearboard:
     mov  eax,63
     mov  ebx,2
     int  0x40
     loop clearboard

     call draw_window

still:

    mov  eax,23                 ; wait here for event
    mov  ebx,1
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   red
    cmp  eax,2                  ; key in buffer ?
    je   key
    cmp  eax,3                  ; button in buffer ?
    je   button

    mov  eax,63
    mov  ebx,2
    int  0x40

    cmp  ebx,1
    jne  still

  new_data:

    cmp  al,13
    jne  no13
    mov  [xpos],0
    jmp  new_check
   no13:
    cmp  al,10
    jne  no10
    inc  [ypos]
    cmp  [ypos],12
    jbe  noypos
    mov  [ypos],12
    mov  esi,text+80
    mov  edi,text
    mov  ecx,80*13
    cld
    rep  movsb
  noypos:
    jmp  new_check
  no10:

    mov  esi,[ypos]
    imul esi,80
    add  esi,[xpos]
    mov  [text+esi],al
    inc  [xpos]
    cmp  [xpos],80
    jb   xposok
    mov  [xpos],79
  xposok:

  new_check:

    mov  eax,63
    mov  ebx,2
    int  0x40

    cmp  ebx,1
    je   new_data

    call draw_window

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




;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40
                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,100*65536+500          ; [x start] *65536 + [x size]
    mov  ecx,250*65536+165         ; [y start] *65536 + [y size]
    mov  edx,0x04ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,window_label          ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0                     ; color of frames    RRGGBB
    int  0x40

    mov  ebx,15*65536+33           ; draw info text with function 4
    mov  ecx,0x000000
    mov  edx,text
    mov  esi,80
  newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,80
    cmp  [edx],byte 'x'
    jne  newline

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA

text:

    times 80*14 db 32
    db 'x'

window_label:

    db    'DEBUG BOARD',0

I_END:



