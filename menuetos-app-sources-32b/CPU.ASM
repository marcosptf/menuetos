;
;   Process management
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

START:                          ; start of execution

     mov  [addr],dword start_application
     mov  [ya],dword 382

     call draw_window

still:

    mov  eax,23                 ; wait here for event
    mov  ebx,100
    int  0x40

    cmp  eax,1                  ; redraw request ?
    je   red
    cmp  eax,2                  ; key in buffer ?
    je   key
    cmp  eax,3                  ; button in buffer ?
    je   button

    call draw_process

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

    shr  eax,8

    cmp  eax,10
    jb   noterm
    cmp  eax,50
    jg   noterm
    sub  eax,10
    add  eax,[list_start]
    mov  ecx,eax
    mov  eax,18
    mov  ebx,2
    int  0x40
    jmp  still
  noterm:

    cmp  eax , 1000
    jb   no_scroll
    cmp  eax , 1300
    ja   no_scroll
    mov  [scrollv],eax
    call draw_scroll
    mov  eax,[scrollv]
    sub  eax,1000
    mov  [list_start],eax
    call draw_process
    jmp  still
  no_scroll:

    cmp  eax,51
    jne  noadd
    sub  [list_start],32
    and  [list_start],255
    call draw_process
    jmp  still
  noadd:

    cmp  eax,52
    jne  nosub
    add  [list_start],32
    and  [list_start],255
    call draw_process
    jmp  still
  nosub:

    cmp  eax,61
    jne  notermall
    mov  ecx,256
  newterm:
    mov  eax,18
    mov  ebx,2
    int  0x40
    loop newterm
    jmp  still
  notermall:


    cmp  eax,53
    je   read_string

    cmp  eax,54
    jne  nostart
    mov  eax,58
    mov  ebx,file_start
    int  0x40
  nostart:

    cmp  eax,1                   ; button id=1 ?
    jne  noclose
    mov  eax,-1                 ; close this program
    int  0x40
  noclose:

    jmp  still


pos  equ 8*65536+45

xm   equ 33

list_start  dd 0

print_color dd 0x0

draw_process:

    pusha

    mov  edi,1

  newprocess:

    mov  eax,13
    mov  ebx,pos
    and  ebx,0xffff0000
    add  ebx,10*65536+500
    mov  edx,pos
    and  edx,0xffff
    mov  ecx,edi
    imul ecx,10
    add  ecx,edx
    shl  ecx,16
    add  ecx,9
    mov  edx,0xf4f4f4
    int  0x40

    mov  eax,9
    mov  ebx,I_END
    mov  ecx,edi
    add  ecx,[list_start]
    int  0x40

    push eax

    mov  eax,47                ; list position
    mov  ebx,3*65536+1*256
    mov  ecx,edi
    add  ecx,[list_start]
    mov  edx,edi
    imul edx,10
    add  edx,12*65536+pos
    mov  esi,[tcolor]
    int  0x40

    pop  eax

    mov  ecx,edi
    add  ecx,[list_start]

    cmp  ecx,eax
    jg   no_process

    mov  eax,47                ; display state
    mov  ebx,1*65536+1*256
    mov  ecx,[I_END+50]
    mov  edx,edi
    imul edx,10
    add  edx,30*65536+pos
    mov  esi,[tcolor]
;    int  0x40

    cmp  [I_END+50],word 9
    je   no_process

    mov  [print_color],0x000000
    cmp  [I_END+50],word 0
    je   running
    mov  [print_color],0xff0000
  running:

    mov  eax,4                 ; name of the process
    mov  ebx,edi
    imul ebx,10
    add  ebx,42*65536+pos
    mov  ecx,[print_color]
    mov  edx,I_END+10
    mov  esi,11
    int  0x40

    mov  eax,47                ; display PID
    mov  ebx,8*65536+1*256
    mov  ecx,[I_END+30]
    mov  edx,edi
    imul edx,10
    add  edx,20*6*65536+pos
    mov  esi,[tcolor]
    int  0x40

    mov  eax,47                ; display cpu usage
    mov  ebx,8*65536+1*256
    mov  ecx,[I_END+0]
    mov  edx,edi
    imul edx,10
    add  edx,30*6*65536+pos
    mov  esi,[tcolor]
    int  0x40

    mov  eax,18
    mov  ebx,5
    int  0x40

    xor  edx,edx
    mov  ebx,100
    div  ebx

    mov  ebx,[I_END+0]

    xchg eax,ebx

    xor  edx,edx
    or   ebx,1
    div  ebx

    mov  ecx,eax

    mov  eax,47                ; display cpu usage %
    mov  ebx,3*65536+0*256
    mov  edx,edi
    imul edx,10
    add  edx,40*6*65536+pos
    mov  esi,[tcolor]
    int  0x40

    mov  eax,47                ; display memory start
    mov  ebx,8*65536+1*256
    mov  ecx,[I_END+22]
    mov  edx,edi
    imul edx,10
    add  edx,45*6*65536+pos
    mov  esi,[tcolor]
    int  0x40

    mov  eax,47                ; display memory usage
    mov  ebx,8*65536+1*256
    mov  ecx,[I_END+26]
    mov  edx,edi
    imul edx,10
    add  edx,55*6*65536+pos
    mov  esi,[tcolor]
    int  0x40

    mov  eax,47                ; display window position
    mov  ebx,8*65536+1*256
    mov  ecx,[I_END+34]
    shl  ecx,16
    add  ecx,[I_END+38]
    mov  edx,edi
    imul edx,10
    add  edx,65*6*65536+pos
    mov  esi,[tcolor]
    int  0x40

    mov  eax,47                ; display window xy size
    mov  ebx,8*65536+1*256
    mov  ecx,[I_END+42]
    shl  ecx,16
    add  ecx,[I_END+46]
    mov  edx,edi
    imul edx,10
    add  edx,75*6*65536+pos
    mov  esi,[tcolor]
    int  0x40

  no_process:

    inc  edi

    cmp  edi,32
    jbe  newprocess

    popa

    ret

file_start: dd 16
            dd 0,0,0,0x10000

start_application: db '/FD/1/LAUNCHER',0
                   times 60 db 32
addr     dd  0x0
ya       dd  0x0

read_string:

    mov  edi,[addr]
    mov  eax,0
    mov  ecx,40
    cld
    rep  stosb

    call print_text

    mov  edi,[addr]

  f11:
     mov  eax,23
     mov  ebx,100
    int  0x40
     call draw_process
     cmp  eax,0
    je   f11
    cmp  eax,2
    jne  read_done
    mov  eax,2
    int  0x40
    shr  eax,8
    cmp  eax,13
    je   read_done
    cmp  eax,8
    jnz  nobsl
    cmp  edi,[addr]
    jz   f11
    sub  edi,1
    mov  [edi],byte 32
    call print_text
    jmp  f11
  nobsl:
    cmp  al,95
    jbe  cok
    sub  al,32
  cok:
    mov  [edi],al

    call print_text

    add  edi,1
    mov  esi,[addr]
    add  esi,30
    cmp  esi,edi
    jnz  f11

  read_done:

    mov  [edi],byte 0

    call print_text

    jmp  still


print_text:

    pusha

    mov  eax,13
    mov  ebx,(264-6*xm)*65536+31*6
    mov  ecx,[ya]
    shl  ecx,16
    mov  cx,12
    sub  ecx,2*65536
    mov  edx,0xeeeeee
    int  0x40

    mov  eax,4
    mov  edx,[addr]
    mov  ebx,(265-6*xm)*65536
    add  ebx,[ya]
    mov  ecx,0x000000
    mov  esi,30
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

    mov  eax,12
    mov  ebx,1
    int  0x40

    mov  eax,14
    int  0x40

    mov  ebx,eax
    mov  ecx,eax

    shr  ebx,16
    and  ebx,0xffff
    and  ecx,0xffff

    shr  ebx,1
    shr  ecx,1

    sub  ebx,315
    sub  ecx,200

    shl  ebx,16
    shl  ecx,16
                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  bx,630                    ; [x start] *65536 + [x size]
    mov  cx,400                    ; [y start] *65536 + [y size]
    mov  edx,0x04ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,window_label          ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0                     ; color of frames    RRGGBB
    int  0x40
                 
    mov  ebx,20*65536+35           ; draw info text with function 4
    mov  ecx,0x000000
    mov  edx,text
    mov  esi,100
    mov  eax,4
    int  0x40

    mov  eax,8                      ; terminate buttons
    mov  ebx,530*65536+55
    mov  ecx,54*65536+9
    mov  edx,11
    mov  esi,0x10aabbcc
    mov  edi,0
   newb:
    int  0x40
    add  ecx,10*65536
    inc  edx
    cmp  edx,11+32
    jb   newb

    mov  eax,8                      ; terminate all
    mov  ebx,530*65536+55
    mov  ecx,380*65536+10
    mov  edx,61
    mov  esi,0x10aabbcc
    mov  edi,0
    int  0x40

    mov  eax,8                      ; previous
    mov  ebx,30*65536+96
    mov  ecx,380*65536+10
    mov  edx,51
    mov  esi,0xaabbcc
;    int  0x40

    mov  eax,8                      ; next
    mov  ebx,130*65536+96
    mov  ecx,380*65536+10
    mov  edx,52
    mov  esi,0xaabbcc
;    int  0x40

    mov  eax,8                      ; text enter
    mov  ebx,(237-6*xm)*65536+20
    mov  ecx,380*65536+10
    mov  edx,53
    mov  esi,0x10aabbcc
    mov  edi,0
    int  0x40

    mov  eax,8                      ; start application
    mov  ebx,(456-6*xm)*65536+63
    mov  ecx,380*65536+10
    mov  edx,54
    mov  esi,0x10aabbcc
    mov  edi,0
    int  0x40

    mov  eax,4
    mov  ebx,30*65536+382
    mov  ecx,0x000000
    mov  edx,tbts
    mov  esi,tbte-tbts
    int  0x40

    call draw_scroll

    call draw_process

    call print_text

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


draw_scroll:

    mov   eax , 113
    mov   ebx , 1 shl 16 + 600
    mov   ecx , 55 shl 16 + 32 * 10
    mov   edx , 1000
    mov   esi , 256-32
    mov   edi , [scrollv]
    int   0x40

    ret


; DATA AREA

scrollv:

    dd    1000

tcolor dd 0x000000

text:

  db '     NAME         PID       CPU-USAGE   %  '
  db 'MEMORY START/USAGE  W-POS     W-SIZE      TERMINATE'
  db '                            '
  db 'x <- END MARKER, DONT DELETE            '

tbts: db  '   >                                   '
      db  '   RUN                                       TERM ALL '
tbte:


window_label:

     db   'PROCESSES',0

I_END:


