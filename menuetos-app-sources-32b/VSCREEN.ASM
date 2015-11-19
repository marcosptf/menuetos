;
;    VIRTUAL SCREEN
;
;    Compile with FASM for Menuet
;
   
use32
   
                org     0x0
   
                db      'MENUET01'              ; 8 byte id
                dd      0x01                    ; required os
                dd      START                   ; program start
                dd      I_END                   ; program image size
                dd      0x600000                ; required amount of memory
                dd      0xfff0
                dd      0,0
   
scr     equ     0x20000
   
   
START:                          ; start of execution
   
    mov  esp,0xfff0
   
    mov  eax,14                 ; get screen size
    int  0x40
    push eax
    and  eax,0x0000ffff
    add  eax,1
    mov  [size_y],eax
    pop  eax
    shr  eax,16
    add  eax,1
    mov  [size_x],eax
   
    mov  eax,[size_x]
    shr  eax,2
    mov  [cmp_ecx],eax
   
    mov  eax,[size_x]
    xor  edx,edx
    mov  ebx,3
    mul  ebx
    mov  [add_esi],eax
   
    mov  eax,[size_y]
    shr  eax,2
    mov  [cmp_edx],eax
   
    mov   eax,[size_y]
    imul  eax,[size_x]
    imul  eax,3
    mov   [i_size],eax
   
;    call save_screen
   
    call draw_window            ; at first, draw the window
   
still:
   
    call draw_screen
   
    mov  eax,23                 ; wait here for event with timeout
    mov  ebx,[delay]
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
   
    cmp  ah,2
    jnz  nosave
    call save_screen
  nosave:
   
    jmp  still
   
   
   
save_screen:
   
     pusha
   
     mov  eax,5
     mov  ebx,500
;     int  0x40
   
     mov  ebx,0
     mov  edi,0x10000
     mov  esi,0x10000
     add  esi,[i_size]
   
   ss1:
   
     mov  eax,35
     int  0x40
   
     add  ebx,1
   
     mov  [edi],eax
     add  edi,3
   
     cmp  edi,esi
     jb   ss1
   
     mov  eax,56
     mov  ebx,filename
     mov  edx,0x10000
     mov  ecx,[i_size]
     mov  esi,path
     int  0x40
   
     popa
     ret
   
   
filename  db  'SCREEN  RAW'
path      db  0
   
;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************
   
   
draw_window:
   
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40
   
                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,100*65536             ; [x start] *65536 + [x size]
    mov  ecx,100*65536             ; [y start] *65536 + [y size]
    mov  bx,word [size_x]
    shr  bx,2
    add  bx,40
    mov  cx,word [size_y]
    shr  cx,2
    add  cx,75
    mov  edx,0x841111cc            ; color of work area RRGGBB
    mov  esi,window_label          ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0                     ; color of frames    RRGGBB
    int  0x40
   
                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,[size_x]
    shr  ebx,2
    add  ebx,40
    sub  ebx,19
    shl  ebx,16
    mov  bx,12                     ; [x start] *65536 + [x size]
    mov  ecx,5*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,0x22aacc              ; button color RRGGBB
    int  0x40
   
    mov  eax,8                     ; save image
    mov  ebx,20*65536
    mov  bx,word [size_x]
    shr  bx,2
    mov  cx,word [size_y]
    shr  cx,2
    add  cx,49
    shl  ecx,16
    mov  cx,12
    mov  edx,2
    mov  esi,0x8877cc
    int  0x40
   
    shr  ecx,16
    mov  ebx,25*65536
    mov  bx,cx
    add  bx,3
    mov  eax,4
    mov  ecx,0xffffff
    mov  edx,savetext
    mov  esi,22
    int  0x40
   
    call draw_screen
   
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40
   
    ret
   
   
draw_screen:
   
   
    pusha
   
    mov  edi,scr
   
    mov  ecx,0
    mov  edx,0
   
    mov  esi,0
   
  ds1:
   
    mov  eax,35
    mov  ebx,esi
    int  0x40
    stosd
    sub  edi,1
   
    add  esi,4
    add  ecx,1
    cmp  ecx,[cmp_ecx] ; 800/4
    jb   ds1
   
    add  esi,[add_esi] ; 800*3
    mov  ecx,0
    add  edx,1
    cmp  edx,[cmp_edx] ; 600/4
    jb   ds1
   
    mov  eax,7
    mov  ebx,scr
    mov  ecx,200*65536+160
    mov  ecx,[size_x]
    shr  ecx,2
    shl  ecx,16
    mov  cx,word [size_y]
    shr  cx,2
    mov  edx,20*65536+35
    int  0x40
   
    popa
   
    ret
   
   
draw_magnify:
   
    pusha
   
    mov  [m_x],dword 0x0
    mov  [m_y],dword 0x0
   
    mov  ecx,0
    mov  edx,0
   
  dm1:
   
    push edx
    mov  eax,edx
    mul  [size_x]
    pop  edx
    add  eax,ecx
   
    mov  ebx,eax
    mov  eax,35
    int  0x40
   
    pusha
    mov  ebx,ecx
    mov  ecx,edx
    shl  ebx,3
    add  ebx,20
    shl  ebx,16
    mov  bx,8
    shl  ecx,3
    add  ecx,35
    shl  ecx,16
    mov  cx,8
   
    mov  edx,eax
    mov  eax,13
    int  0x40
    popa
   
    add  ecx,1
    cmp  ecx,40
    jnz  dm1
    mov  ecx,0
    add  edx,1
    cmp  edx,32
    jnz  dm1
   
    popa
    ret
   
   
   
; DATA AREA
   
i_size   dd  0x1
   
m_x      dd  100
m_y      dd  100
   
size_x   dd  0
size_y   dd  0
   
cmp_ecx  dd  0
add_esi  dd  0
cmp_edx  dd  0
   
delay    dd  100
   
window_label:

     db   'SAVE SCREEN',0
   
savetext  db  'SAVE AS HD:SCREEN.RAW   '
   
   
I_END:
   
   
   
   
