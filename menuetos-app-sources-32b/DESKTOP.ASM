;
;    UNIFORM WINDOW COLOURS
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
   
    mov  eax,48                 ; get current colors
    mov  ebx,3
    mov  ecx,color_table
    mov  edx,4*10
    int  0x40
   
    call draw_window            ; at first, draw the window
   
still:
   
    mov  eax,23                 ; wait here for event
    mov  ebx,5
    int  0x40
   
    cmp  eax,1                  ; redraw request ?
    jz   red
    cmp  eax,2                  ; key in buffer ?
    jz   key
    cmp  eax,3                  ; button in buffer ?
    jz   button
   
    call draw_cursor
   
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
   
    cmp  ah,14                  ; set 3d buttons
    jne  no_3d
    mov  eax,48
    mov  ebx,1
    mov  ecx,1
    int  0x40
    mov  eax,48
    mov  ebx,0
    mov  ecx,0
    int  0x40
    jmp  still
   no_3d:
   
    cmp  ah,15                  ; set flat buttons
    jne  no_flat
    mov  eax,48
    mov  ebx,1
    mov  ecx,0
    int  0x40
    mov  eax,48
    mov  ebx,0
    mov  ecx,0
    int  0x40
    jmp  still
  no_flat:
   
    cmp  ah,51      ; apply
    jne  no_apply
    mov  eax,48
    mov  ebx,2
    mov  ecx,color_table
    mov  edx,10*4
    int  0x40
    mov  eax,48
    mov  ebx,0
    mov  ecx,0
    int  0x40
  no_apply:
   
    cmp  ah,31
    jb   no_new_colour
    cmp  ah,41
    jg   no_new_colour
    shr  eax,8
    sub  eax,31
    shl  eax,2
    add  eax,color_table
    mov  ebx,[color]
    mov  [eax],ebx
    call draw_colours
    jmp  still
  no_new_colour:
   
    cmp  ah,1                   ; terminate                                     
    jnz  noid1
    mov  eax,-1
    int  0x40
  noid1:
   
    cmp  ah,11                  ; read string
    jne  no_string
    call read_string
    jmp  still
  no_string:
   
    cmp  ah,12                  ; load file
    jne  no_load
    call load_file
    call draw_window
    jmp  still
  no_load:
   
    cmp  ah,13                  ; save file
    jne  no_save
    call save_file
    jmp  still
  no_save:
   
    jmp  still
   
   
draw_cursor:
   
    pusha
    mov  eax,37
    mov  ebx,2
    int  0x40
   
    cmp  eax,0
    jne  dc1
    popa
    ret
   
 dc1:
   
    mov  eax,37
    mov  ebx,1
    int  0x40
   
    mov  ebx,eax
    shr  ebx,16
    mov  ecx,eax
    and  ecx,0xffff
   
    cmp  ecx,32
    jbe  no_color
    cmp  ebx,32
    jbe  no_color
   
    sub  ebx,16
    sub  ecx,16
   
    cmp  ebx,262           ; CHANGE COLOR
    jb   no_color
    cmp  ebx,262+20*3
    jg   no_color
   
    cmp  ecx,14+128
    jge  no_color
    cmp  ecx,14
    jb   no_color
   
    xor  edx,edx
    sub  ebx,262
    mov  eax,ebx
    mov  ebx,20
    div  ebx
    mov  ebx,2
    sub  ebx,eax
   
    sub  ecx,14
    not  ecx
    shl  ecx,1
    sub  ecx,2
   
    mov  byte [ebx+color],cl
    call draw_color
   
    popa
    ret
   
  no_color:
   
    popa
    ret
   
   
load_file:
   
    pusha
   
    mov  eax,6
    mov  ebx,fname
    mov  ecx,0
    mov  edx,-1
    mov  esi,color_table
    int  0x40
   
    cmp  eax,-1
    jne  foundfile
;    int  0x40
  foundfile:
   
    call draw_colours
   
    popa
    ret
   
   
save_file:
   
    pusha
   
    mov  eax,33
    mov  ebx,fname
    mov  ecx,color_table
    mov  edx,10*4
    mov  esi,0
    int  0x40
   
    popa
    ret
   
   
read_string:
   
    pusha
   
    mov  edi,fname
    mov  al,'_'
    mov  ecx,20
    cld
    rep  stosb
   
    call print_text
   
    mov  edi,fname
   
  f11:
    mov  eax,10
    int  0x40
    cmp  eax,2
    jne  read_done
    mov  eax,2
    int  0x40
    shr  eax,8
    cmp  eax,13
    je   read_done
    cmp  eax,8
    jne  nobsl
    cmp  edi,fname
    je   f11
    dec  edi
    mov  [edi],byte '_'
    call print_text
    jmp  f11
   nobsl:
    cmp  eax,31
    jbe  f11
    cmp  eax,97
    jb   keyok
    sub  eax,32
   keyok:
    mov  [edi],al
   
    call print_text
   
    inc  edi
    mov  esi,fname+12
    cmp  esi,edi
    jne  f11
   
  read_done:
   
    mov  ecx,fname
    add  ecx,20
    sub  ecx,edi
    mov  eax,' '
    cld
    rep  stosb
   
    call print_text
   
    popa
   
    ret
   
   
print_text:
   
    pusha
   
    mov  eax,13
    mov  ebx,278*65536+6*12+4
    mov  ecx,234*65536+10
    mov  edx,[w_work]
    int  0x40
   
    mov  eax,4
    mov  ebx,280*65536+235
    mov  ecx,[w_work_text]
    mov  esi,12
    mov  edx,fname
    int  0x40
   
    popa
   
    ret
   
   
draw_color:
   
    pusha
   
    mov  eax,13
    mov  ebx,280*65536+60
    mov  ecx,170*65536+30
    mov  edx,[color]
    int  0x40
   
    mov  eax,13
    mov  ebx,280*65536+60
    mov  ecx,200*65536+10
    mov  edx,[w_work]
    int  0x40
   
    mov  eax,47
    mov  ebx,0+1*256+8*65536
    mov  ecx,[color]
    mov  edx,280*65536+201
    mov  esi,[w_work_text]
    int  0x40
   
    popa
   
    ret
   
   
draw_colours:
   
    pusha
   
    mov  esi,color_table
   
    mov  ebx,225*65536+32
    mov  ecx,37*65536+12
  newcol:
    mov  eax,13
    mov  edx,[esi]
    int  0x40
    add  ecx,20*65536
    add  esi,4
    cmp  esi,color_table+4*9
    jbe  newcol
   
    popa
   
    ret
   
   
   
;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************
   
   
draw_window:
   
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40
   
    mov  eax,48
    mov  ebx,3
    mov  ecx,app_colours
    mov  edx,10*4
    int  0x40
    mov  eax,14
    int  0x40
    sub  eax,60*65536
    mov  ebx,eax
    mov  bx,40
   
                                   ; DRAW WINDOW
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,110*65536+360         ; [x start] *65536 + [x size]
    mov  ecx,50*65536+300          ; [y start] *65536 + [y size]
    mov  edx,[w_work]              ; color of work area RRGGBB,8->color
    add  edx,0x02000000
    mov  esi,[w_grab]              ; color of grab bar  RRGGBB,8->color gl
    add  esi,0x80000000
    mov  edi,[w_frame]             ; color of frames    RRGGBB
    int  0x40
   
                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,[w_grab_text]         ; color of text RRGGBB
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40
                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,(360-19)*65536+12     ; [x start] *65536 + [x size]
    mov  ecx,4*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,[w_grab_button]       ; button color RRGGBB
    int  0x40
   
    mov  eax,8                     ; FILENAME BUTTON
    mov  ebx,280*65536+60
    mov  ecx,250*65536+14
    mov  edx,11
    mov  esi,[w_work_button]
    int  0x40
   
    mov  eax,8                     ; SAVE BUTTON
    mov  ebx,280*65536+29
    mov  ecx,270*65536+14
    mov  edx,12
    int  0x40
   
    mov  eax,8                     ; LOAD BUTTON
    add  ebx,30*65536
    inc  edx
    int  0x40
   
    mov  eax,8                     ; 3D
    mov  ebx,15*65536+35
    mov  ecx,275*65536+14
    inc  edx
    int  0x40
    mov  eax,8                     ; FLAT
    add  ebx,40*65536
    inc  edx
    int  0x40
   
   
    mov  eax,4
    mov  ebx,281*65536+254
    mov  ecx,[w_work_button_text]
    mov  edx,t1
    mov  esi,tl1-t1
    int  0x40
   
    mov  eax,4
    mov  ebx,277*65536+274
    mov  edx,t2
    mov  esi,tl2-t2
    int  0x40
   
    mov  eax,38                    ; R G B COLOR GLIDES
    mov  ebx,280*65536+295
    mov  ecx,30*65536+30
    mov  edx,0xff0000
  newl:
    int  0x40
    pusha
    add  ebx,20*65536+20
    shr  edx,8
    int  0x40
    add  ebx,20*65536+20
    shr  edx,8
    int  0x40
    popa
    sub  edx,0x020000
    add  ecx,0x00010001
    cmp  ecx,158*65536+158
    jnz  newl
   
    call draw_color
   
    mov  edx,31                    ; BUTTON ROW
    mov  ebx,15*65536+200
    mov  ecx,35*65536+14
    mov  esi,[w_work_button]
  newb:
    mov  eax,8
    int  0x40
    add  ecx,20*65536
    inc  edx
    cmp  edx,40
    jbe  newb
   
    mov  eax,8                     ; APPLY BUTTON
    add  ecx,20*65536
    mov  edx,51
    int  0x40
   
    mov  ebx,20*65536+39           ; ROW OF TEXTS
    mov  ecx,[w_work_button_text]
    mov  edx,text
    mov  esi,32
  newline:
    mov  eax,4
    int  0x40
    add  ebx,20
    add  edx,32
    cmp  [edx],byte 'x'
    jne  newline
   
    call draw_colours
   
    call print_text
   
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40
   
    ret
   
   
; DATA AREA
   
   
text:
       db  ' WINDOW FRAME                   '
       db  ' WINDOW GRAB BAR                '
       db  ' WINDOW GRAB BUTTON             '
       db  ' WINDOW GRAB BUTTON TEXT        '
       db  ' WINDOW GRAB TITLE              '
       db  ' WINDOW WORK AREA               '
       db  ' WINDOW WORK AREA BUTTON        '
       db  ' WINDOW WORK AREA BUTTON TEXT   '
       db  ' WINDOW WORK AREA TEXT          '
       db  ' WINDOW WORK AREA GRAPH         '
       db  '                                '
       db  '        APPLY CHANGES           '
       db  ' 3D    FLAT                     '
       db  'x                               '
   
   
bcolor:  dd 0x6688cc
   
   
fname db  'DEFAULT.DTP                                   '
   
color dd  0x8899ff
   
t1    db  ' FILENAME   '
tl1:
t2    db  ' LOAD SAVE '
tl2:
   
labelt:
    db   'DESKTOP COLOURS - DEFINE COLOR AND CLICK ON TARGET'
labellen:
   
   
app_colours:
   
w_frame              dd 0x8899ff
w_grab               dd 0x0
w_grab_button        dd 0xcccc00
w_grab_button_text   dd 0x0
w_grab_text          dd 0x0
w_work               dd 0x0
w_work_button        dd 0x0
w_work_button_text   dd 0x0
w_work_text          dd 0x0
w_work_graph         dd 0x0
   
times 16 dd 0x0
   
color_table:
  times 16 dd 0x0
   
I_END:
