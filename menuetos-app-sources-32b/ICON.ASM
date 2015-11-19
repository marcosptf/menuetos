;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    Icon application
;    Compile with FASM for Menuet
;    (c) V.Turjanmaa
;    August 12, 2004 - 32-bit ICO format support (mike.dld)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use32

  org     0x0

  db      'MENUET01'     ; 8 byte id
  dd      0x01           ; required os
  dd      START          ; program start
  dd      I_END          ; program image size
  dd      I_END+65536    ; required amount of memory
  dd      stackposition
  dd      I_PARAM
  dd      0x0

flipdelay equ 4

START:           ; start of execution

    cmp  [I_PARAM],byte 0
    jne  nohalt
    or  eax,-1
    int  0x40
  nohalt:

    mov  eax,[I_PARAM+0]
    sub  eax,0x01010101
    mov  [xpos],eax
    mov  eax,[I_PARAM+4]
    sub  eax,0x01010101
    mov  [ypos],eax

    mov  esi,I_PARAM+8
    mov  edi,fname
    mov  ecx,11
    cld
    rep  movsb

    mov  esi,I_PARAM+8+11
    mov  edi,start_file
    mov  ecx,11+25
    cld
    rep  movsb

    mov  esi,I_PARAM+8+11+11+25
    mov  edi,labelt
    mov  ecx,11
    cld
    rep  movsb

    mov  eax,40          ; get also event background change
    mov  ebx,1+2+4+16
    int  0x40

    call get_bg
    call draw_window

    mov  eax , 5
    mov  ebx , 100
    call draw_window

still:

    mov  eax,23          ; wait here for event
    mov  ebx,flipdelay
    int  0x40

    cmp  eax,1          ; redraw request ?
    jz  red
    cmp  eax,2          ; key in buffer ?
    jz  key
    cmp  eax,3          ; button in buffer ?
    jz  button
    cmp  eax,5          ; background redraw ?
    jz  check

    call check_mouse
    jmp  still

  check:
    pusha
    call get_bg
    call draw_icon
    popa
    jmp  still

  red:           ; redraw
    call draw_window
    jmp  still

  key:           ; key
    mov  eax,2          ; just read it and ignore
    int  0x40
    jmp  still

  button:          ; button
    mov  eax,17    ; get id
    int  0x40

 ;   mov  eax,23    ; delay
 ;   mov  ebx,50
 ;   int  0x40
 ;   cmp  eax,3
 ;   jne  noid1

 ;   mov  eax,17    ; get id
 ;   int  0x40
    cmp  ah,1      ; button id=1 ?
    jnz  noid1

    mov  eax,58
    mov  ebx,start_file_info
    int  0x40

    call flip_icon

  noid1:

    jmp  still

check_mouse:
     ret
     pusha
     mov  eax,37
     mov  ebx,2
     int  0x40
     cmp  eax,0
     je   no_mouse_over
     mov  eax,37
     mov  ebx,1
     int  0x40
     mov  ebx,eax
     shr  ebx,16
     and  eax,65535
     cmp  eax,50
     jge  no_mouse_over
     cmp  ebx,50
     jge  no_mouse_over
     call flip_icon
     mov  eax,19
     mov  ebx,start_file
     int  0x40
   no_mouse_up:
     mov  eax,5
     mov  ebx,10
     int  0x40
     mov  eax,37
     mov  ebx,2
     int  0x40
   no_mouse_over:
     popa
     ret

flip_icon:
     ret
     pusha
     mov  [bgrload],byte 1
     mov  eax,1
     call flip
     mov  eax,2
     call flip
     mov  eax,3
     call flip
     mov  eax,4
     call flip
     mov  eax,5
     call flip
     mov  eax,4
     call flip
     mov  eax,3
     call flip
     mov  eax,2
     call flip
     mov  eax,1
     call flip
     mov  eax,0
     call flip
     mov  [bgrload],byte 0
     popa
     ret
flip:
     mov  [iconstate],eax
     call get_bg
     call draw_icon
     mov  eax,5
     mov  ebx,flipdelay
     int  0x40
     ret

draw_window:

    mov  eax,12      ; function 12:tell os about windowdraw
    mov  ebx,1      ; 1, start of draw
    int  0x40

    mov  eax,14
    int  0x40

    sub  eax,60*65536
    mov  ebx,eax
    mov  bx,40
       ; DRAW WINDOW
    mov  eax,0      ; function 0 : define and draw window
    mov  ebx,[xpos-2]
    mov  ecx,[ypos-2]
    add  ebx,[yw]        ; [x start] *65536 + [x size]
    mov  cx,51      ; [y start] *65536 + [y size]
    mov  edx,0x00000000     ; color of work area RRGGBB,8->color gl
    mov  esi,0x00000000     ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0x00000000     ; color of frames    RRGGBB
    int  0x40

    mov  eax,8   ; button
    mov  ebx,50
    mov  ecx,50
    mov  edx,1 ; + 1 shl 29
    mov  esi,0
    int  0x40

    call draw_icon

    mov  eax,12
    mov  ebx,2
    int  0x40

    ret

get_bg:

    pusha

    mov  eax,14
    int  0x40
    add  eax,0x00010001
    mov  [scrxy],eax

    mov  eax,39
    mov  ebx,4
    int  0x40
    mov  [bgrdrawtype],eax

    mov  eax,39        ; get background size
    mov  ebx,1
    int  0x40
    mov  [bgrxy],eax

    mov  eax,6
    mov  ebx,fname
    mov  ecx,0
    mov  edx,0xffffffff
    mov  esi,I_END+256  ; size = 4268 bytes
    int  0x40

    mov  [itype],0
    cmp  word[I_END+256],'BM'
    je  @f
    inc  [itype]
  @@:

    mov  ebx,[yw]             ; 4286 - icon file image
    mov  ecx,0                ; 8112 - 52*52*3 - bg image
    mov  esi,I_END+256+4286   ;! 54+32*3*33-3
    mov  edi,51*3

    mov  ebp , 0

  newb:

    push ebx ecx

    cmp  [bgrload],byte 1
    jne  nogeteax

    mov  eax , [bgrsave+ebp]
    add  ebp , 3
    and  eax , 0xffffff
    jmp  nobpix

  nogeteax:

  yesbpix:

    cmp   [bgrdrawtype],dword 2
    jne   nostretch

    mov   eax,[ypos]
    add   eax,ecx
    xor   edx,edx
    movzx ebx,word [bgrxy]
    mul   ebx
    xor   edx,edx
    movzx ebx,word [scrxy]
    div   ebx
    xor   edx,edx
    movzx ebx,word [bgrxy+2]
    mul   ebx
    push  eax

    mov   eax,[xpos]
    add   eax,[esp+8]
    xor   edx,edx
    movzx ebx,word [bgrxy+2]
    mul   ebx
    xor   edx,edx
    movzx ebx,word [scrxy+2]
    div   ebx
    add   eax,[esp]
    add   esp,4

  nostretch:

    cmp   [bgrdrawtype],dword 1
    jne   notiled

    mov  eax,[ypos]
    add  eax,ecx
    xor  edx,edx
    movzx ebx,word [bgrxy]
    div  ebx
    mov  eax,edx
    movzx  ebx,word [bgrxy+2]
    xor  edx,edx
    mul  ebx
    push eax

    mov  eax,[xpos]
    add  eax,[esp+8]
    movzx ebx,word [bgrxy+2]
    xor  edx,edx
    div  ebx
    mov  eax,edx
    add  eax,[esp]
    add  esp,4

  notiled:

    lea  ecx,[eax+eax*2]

    mov  eax,39
    mov  ebx,2

    int  0x40

    mov  [bgrsave+ebp],eax
    add  ebp , 3

  nobpix:

    pop  ecx ebx

    mov  [esi+edi+0],al
    mov  [esi+edi+1],ah
    shr  eax,16
    mov  [esi+edi+2],al
    sub  edi,3

    dec  ebx
    jge  newb
    mov  ebx,[yw]

    add  esi,52*3
    mov  edi,51*3
    inc  ecx
    cmp  ecx,52
    jne  newb

;*****************************************************************************

    mov  esi,I_END+256+4286+8112-17*52*3+10*3 ;! 54+32*3*33-3
    mov  eax,[iconstate]
    mov  eax,[add_table0+eax*4]
    add  esi,eax
    mov  edi,I_END+256+62
    cmp  [itype],0
    jne  @f
    mov  edi,I_END+256+54
  @@:
    xor  ebp,ebp
    mov  [pixl],0
  newp:

    virtual at edi
      r db ?
      g db ?
      b db ?
      a db ?
    end virtual
    virtual at esi+ebp
      ar db ?
      ag db ?
      ab db ?
    end virtual

    movzx ecx,[a]

    push  ebp
    cmp   [iconstate],3
    jb   @f
    neg   ebp
  @@:

    cmp  [itype],0
    jne  @f
    mov  eax,[edi]
    and  eax,$00FFFFFF
    jnz  @f
    jmp  no_transp
  @@:

    movzx eax,[r]
    cmp   [itype],0
    je   @f
    movzx ebx,byte[ar]
    sub   eax,ebx
    imul  eax,ecx
    xor   edx,edx
    or   ebx,$0FF
    div   ebx
    movzx ebx,[ar]
    add   eax,ebx
  @@:
    mov  [esi+ebp+0],al

    movzx eax,[g]
    cmp   [itype],0
    je   @f
    movzx ebx,[ag]
    sub   eax,ebx
    imul  eax,ecx
    xor   edx,edx
    or   ebx,$0FF
    div   ebx
    movzx ebx,[ag]
    add   eax,ebx
  @@:
    mov  [esi+ebp+1],al

    movzx eax,[b]
    cmp   [itype],0
    je   @f
    movzx ebx,[ab]
    sub   eax,ebx
    imul  eax,ecx
    xor   edx,edx
    or   ebx,$0FF
    div   ebx
    movzx ebx,[ab]
    add   eax,ebx
  @@:
    mov  [esi+ebp+2],al

  no_transp:

    pop   ebp

    movzx eax,[itype]
    imul  eax,6
    add   eax,[iconstate]
    push  eax
    mov   eax,[add_table1+eax*4]
    add   edi,eax

    add  ebp,3
    pop  eax
    mov  eax,[add_table2+eax*4]
    add  [pixl],eax
    cmp  [pixl],32
    jl  newp
    xor  ebp,ebp
    mov  [pixl],0

    sub  esi,52*3
    cmp  esi,I_END+256+4286+52*4*3
    jge  newp

;*****************************************************************************

    popa
    ret

draw_picture:
    mov  eax,7
    mov  ebx,I_END+256+4286
    mov  ecx,52 shl 16 + 52
    xor  edx,edx
    int  0x40
    ret

draw_icon:
    call draw_picture
    call text_length
    call draw_text
    ret

text_length:
    pusha
    mov   eax,labelt
  news:
    cmp   [eax],byte 40
    jb   founde
    inc   eax
    cmp   eax,labelt+11
    jb   news
   founde:
    sub   eax,labelt
    mov   [tl],eax
    popa
    ret

draw_text:
    pusha
    mov   eax,[tl]
    imul  eax,3
    shl   eax,16
    mov   ebx,28*65536+42
    sub   ebx,eax

;    movzx ecx,byte [I_PARAM+8+11+11+7+25]
;    shl   ecx,16
;    add   ebx,ecx

    jmp   shade

; replaced - delete commented lines below if you like that style
    mov   eax,4
    sub   ebx,1*65536+1
    xor   ecx,ecx
    mov   edx,labelt
    mov   esi,labellen-labelt
    int   0x40
    add   ebx,1*65536+0
    int   0x40
    add   ebx,1*65536+0
    int   0x40
    add   ebx,0*65536+1
    int   0x40
    sub   ebx,2*65536+0
    int   0x40
    add   ebx,0*65536+1
    int   0x40
    add   ebx,1*65536+0
    int   0x40
    add   ebx,1*65536+0
    int   0x40
    sub   ebx,1*65536+1
    mov   ecx,0xFFFFFF
    int   0x40

  shade:

    mov   eax,4
    mov   ecx,0x000000        ; black shade of text
    mov   edx,labelt
    mov   esi,labellen-labelt
    add   ebx,1*65536+1
    int   0x40
    mov   eax,4         ; white text
    sub   ebx,1*65536+1
    mov   ecx,0xeeeeee
    int   0x40
    popa
    ret


; DATA AREA

itype  db 0

start_file_info:

             dd  16
             dd  0x0
             dd  0x0 ; param
             dd  0x0
             dd  workarea
start_file:  db  '/FD/1/SETUP'
             times 50 db 0

fname       db  'HD      BMP'
labelt:     db  'SETUP      '
labellen:

align 4

tl  dd  2
yw  dd  51

xpos  dd  15
ypos  dd  185

bgrxy   dd  0x0
scrxy   dd  0x0
bgrdrawtype dd  0x0

iconstate   dd 0
pixl dd ?
add_table0  dd (16-4*4)*3,(16-4*2)*3,(16-4*1)*3,\
               (16+4*1)*3,(16+4*2)*3,(16+4*4)*3
add_table1  dd 3,6,12,12,6,3
            dd 4,8,16,16,8,4
add_table2  dd 1,2,4,4,2,1
            dd 1,2,4,4,2,1

bgrload: dd 0x0

bgrsave: times (32*32*4+0x100) db ?

               times 0x1000 db ?
stackposition: times 0x100 db ?

workarea: times 16384 db ?

I_PARAM:  times 100 db ?

; params: 4 xpos 4 ypos 11 iconfile 11 startfile 7 label
;           +0     +4      +8          +19         +55

I_END:

