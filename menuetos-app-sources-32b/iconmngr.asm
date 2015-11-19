;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Icon manager
;
;   Compile with FASM for Menuet
;
;   (c) V.Turjanmaa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use32

    org    0x0

    db     'MENUET01'              ; 8 byte id
    dd     0x01                    ; header version
    dd     START                   ; start of code
    dd     I_END                   ; size of image
    dd     0x100000                ; memory for app
    dd     0x7fff0                 ; esp
    dd     I_Param , 0x0           ; I_Param , I_Icon

START:                          ; start of execution

    call load_icon_list

    call check_parameters

    call draw_window            ; at first, draw the window

still:

    mov  eax,10                 ; wait here for event
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

    shr  eax,8

    cmp  eax,1                  ; button id=1 ?
    jne  noclose
    mov  eax,-1                 ; close this program
    int  0x40
  noclose:

    cmp  eax,11
    jb   no_str
    cmp  eax,13
    jg   no_str
    call read_string
    jmp  still
  no_str:


    cmp  eax,21                 ; apply changes
    jne  no_apply

    ; (1) save list

    mov  eax,33
    mov  ebx,icon_lst
    mov  ecx,icon_data
    mov  edx,52+25
    imul edx,dword [icons]
    mov  esi,0
    int  0x40


    ; (2) terminate all icons

    mov  esi,1
   newread:
    inc  esi
    mov  eax,9
    mov  ebx,I_END
    mov  ecx,esi
    int  0x40
    cmp  esi,eax
    jg   all_terminated

    cmp  [I_END+10],dword 'ICON'
    jne  newread
    cmp  [I_END+14],dword '    '
    jne  newread

    mov  eax,18
    mov  ebx,2
    mov  ecx,esi
    int  0x40

    mov  eax,5
    mov  ebx,5
    int  0x40

    mov  esi,1

    jmp  newread

   all_terminated:

   apply_changes:

    ; (3)  start icons from icon_data

    mov  edi,[icons]
    mov  esi,icon_data

    cmp  edi , 0
    je   icons_done

  start_new:

    push edi
    push esi

    movzx eax,byte [esi]    ; x position
    cmp  eax,'E'
    jg   no_left
    sub  eax,65
    imul eax,64
    add  eax,15
    jmp  x_done
  no_left:
    sub  eax,65
    mov  ebx,9
    sub  ebx,eax
    imul ebx,64
    push ebx
    mov  eax,14
    int  0x40
    pop  ebx
    shr  eax,16
    sub  eax,51+15
    sub  eax,ebx
  x_done:
    add  eax,0x01010101
    mov  [icon_start_parameters],eax

    movzx eax,byte [esi+1]  ; y position
    cmp  eax,'E'
    jg   no_up
    sub  eax,65
    imul eax,80
    add  eax,34 + 9 ; Leave space for Panel
    sub  eax,23 ; down
    jmp  y_done
  no_up:
    sub  eax,65
    mov  ebx,9
    sub  ebx,eax
    imul ebx,80
    push ebx
    mov  eax,14
    int  0x40
    pop  ebx
    and  eax,0xffff
    sub  eax,-1+80
    sub  eax,16 ; down
    sub  eax,ebx
  y_done:
    add  eax,0x01010101
    mov  [icon_start_parameters+4],eax

    mov  esi,[esp]          ; icon picture
    add  esi,5
    mov  edi,icon_start_parameters+8
    mov  ecx,11
    cld
    rep  movsb

    mov  esi,[esp]          ; icon application
    add  esi,19
    mov  edi,icon_start_parameters+8+11
    mov  ecx,11+25
    cld
    rep  movsb

    mov  esi,[esp]
    add  esi,33+25
    mov  edi,icon_start_parameters+8+11+11+25
    mov  ecx,7
    cld
    rep  movsb

    mov  eax,19
    mov  ebx,icon_name
    mov  ecx,icon_start_parameters
    int  0x40

    mov  eax,5
    mov  ebx,3
    int  0x40

    pop  esi
    pop  edi

    add  esi,50+25+2

    dec  edi
    jnz  start_new

  icons_done:

    cmp  [I_Param],byte 0
    je   still

    mov  eax,-1
    int  0x40

  no_apply:


    cmp  eax,22                 ; user pressed the 'add icon' button
    jne  no_add_icon

    mov  eax,13
    mov  ebx,24*65536+260
    mov  ecx,250*65536+10
    mov  edx,0xffffff
    int  0x40
    mov  eax,4
    mov  ebx,24*65536+250
    mov  ecx,0xff0000
    mov  edx,add_text
    mov  esi,add_text_len-add_text
    int  0x40

    mov  eax,10
    int  0x40
    cmp  eax,3
    jne  still
    mov  eax,17
    int  0x40
    shr  eax,8
    cmp  eax,40
    jb   no_f
    sub  eax,40

    xor  edx,edx  ; bcd -> 10
    mov  ebx,16
    div  ebx
    imul eax,10
    add  eax,edx

    mov  ebx,eax
    add  ebx,icons_reserved
    cmp  [ebx],byte 'x'
    je   no_f
    mov  [ebx],byte 'x'

    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  eax,65
    add  edx,65
    mov  [icon_default+0],dl
    mov  [icon_default+1],al

    inc  dword [icons]
    mov  edi,[icons]
    dec  edi
    imul edi,52+25
    add  edi,icon_data

    mov  [current_icon],edi

    mov  esi,icon_default
    mov  ecx,52+25
    cld
    rep  movsb

  no_f:

    call draw_window

    jmp  still

  no_add_icon:

    cmp  eax,23                     ; user pressed the remove icon button
    jne  no_remove_icon

    mov  eax,13
    mov  ebx,24*65536+260
    mov  ecx,250*65536+10
    mov  edx,0xffffff
    int  0x40
    mov  eax,4
    mov  ebx,24*65536+250
    mov  ecx,0xff0000
    mov  edx,rem_text
    mov  esi,rem_text_len-rem_text
    int  0x40

    mov  eax,10
    int  0x40
    cmp  eax,3
    jne  no_found
    mov  eax,17
    int  0x40
    shr  eax,8
    cmp  eax,40
    jb   no_found
    sub  eax,40

    xor  edx,edx
    mov  ebx,16
    div  ebx
    imul eax,10
    add  eax,edx

    mov  ebx,eax
    add  ebx,icons_reserved
    cmp  [ebx],byte 'x'
    jne  no_found
    mov  [ebx],byte ' '

    xor  edx,edx
    mov  ebx,10
    div  ebx
    shl  eax,8
    mov  al,dl

    add  eax,65*256+65

    mov  esi,icon_data
    mov  edi,52+25
    imul edi,[icons]
    add  edi,icon_data
  news:
    cmp  word [esi],ax
    je   foundi
    add  esi,52+25
    cmp  esi,edi
    jb   news
    jmp  no_found

  foundi:

    mov  ecx,edi
    sub  ecx,esi

    mov  edi,esi
    add  esi,52+25

    cld
    rep  movsb

    dec  [icons]

    mov  eax,icon_data
    mov  [current_icon],eax

  no_found:

    call draw_window

    jmp  still



  no_remove_icon:


    cmp  eax,40                 ; user pressed button for icon position
    jb   no_on_screen_button

    sub  eax,40
    mov  edx,eax
    shl  eax,4
    and  edx,0xf
    mov  dh,ah
    add  edx,65*256+65

    mov  esi,icon_data
    mov  ecx,[icons]
    cmp  ecx , 0
    je   still   ; No icons
    cld
   findl1:
    cmp  dx,[esi]
    je   foundl1
    add  esi,50+25+2
    loop findl1
    jmp  still

   foundl1:

    mov  [current_icon],esi

    call print_strings

    jmp  still

  no_on_screen_button:


    jmp  still


current_icon dd icon_data


print_strings:

    pusha

    mov  eax,13              ; clear text area
    mov  ebx,100*65536+190
    mov  ecx,278*65536+40
    mov  edx,0xffffff
    int  0x40

    mov  eax,4               ; icon text
    mov  ebx,100*65536+278
    mov  ecx,0x000000
    mov  edx,[current_icon]
    add  edx,33+25
    mov  esi,12
    int  0x40

    mov  eax,4               ; icon application
    add  ebx,14
    mov  edx,[current_icon]
    add  edx,19
    mov  esi,12+25
    int  0x40

    mov  eax,4               ; icon bmp
    add  ebx,14
    mov  edx,[current_icon]
    add  edx,5
    mov  esi,12
    int  0x40

    popa

    ret


icon_lst db 'ICON    LST'

load_icon_list:

    pusha

    mov   eax,6
    mov   ebx,icon_lst
    mov   ecx,0
    mov   edx,-1
    mov   esi,icon_data
    int   0x40

    add   eax,10
    xor   edx,edx
    mov   ebx,52+25
    div   ebx
    mov   [icons],eax

    mov   edi,icons_reserved   ; clear reserved area
    mov   eax,32
    mov   ecx,10*10
    cld
    rep   stosb

    mov   ecx,[icons]          ; set used icons to reserved area
    cmp   ecx , 0
    je    icon_list_empty
    mov   esi,icon_data
    cld
  ldl1:
    movzx ebx,byte [esi+1]
    sub   ebx,65
    imul  ebx,10
    movzx eax,byte [esi]
    add   ebx,eax
    sub   ebx,65
    add   ebx,icons_reserved
    mov   [ebx],byte 'x'
    add   esi,50+25+2
    loop  ldl1
  icon_list_empty:

    popa

    ret


check_parameters:

    cmp   [I_Param],dword 'BOOT'
    je    chpl1
    ret
   chpl1:

    mov   eax,21
    jmp   apply_changes


positions dd 33+25,19,5


read_string:

    pusha

    sub  eax,11

    mov  ebp,12
    cmp  eax,1
    jne  nolen2
    mov  ebp,12+19
  nolen2:

    shl  eax,2
    add  eax,positions
    mov  eax,[eax]

    mov  esi,[current_icon]
    add  esi,eax
    mov  [addr],esi

    mov  edi,[addr]
    mov  eax,'_'
    mov  ecx,ebp
    cld
    rep  stosb

    call print_strings

    mov  edi,[addr]
  f11:
    mov  eax,10
    int  0x40
    cmp  eax,2
    jz   fbu
    jmp  rs_done
  fbu:
    mov  eax,2
    int  0x40
    shr  eax,8
    cmp  eax,13
    je   rs_done
    cmp  eax,8
    jnz  nobsl
    cmp  edi,[addr]
    jz   f11
    dec  edi
    mov  [edi],byte '_'
    call print_strings
    jmp  f11
  nobsl:
    cmp  eax,31
    jbe  f11
    cmp  eax,97
    jb   keyok
    sub  eax,32
  keyok:
    mov  [edi],al
    call print_strings

    add  edi,1
    mov  esi,[addr]
    add  esi,ebp
    cmp  esi,edi
    jnz  f11

   rs_done:

    mov  ecx,[addr]
    add  ecx,ebp
    sub  ecx,edi
    mov  eax,32
    cld
    rep  stosb

    call print_strings

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
    mov  eax,0
    mov  ebx,210*65536+300
    mov  ecx,40*65536+390
    mov  edx,0x04ffffff
    mov  esi,window_label
    mov  edi,0
    int  0x40

    mov  eax,13                    ; WINDOW AREA
    mov  ebx,20*65536+260
    mov  ecx,35*65536+200
    mov  edx,0x204070
    int  0x40

    mov  eax,38                    ; VERTICAL LINE ON WINDOW AREA
    mov  ebx,150*65536+150
    mov  ecx,35*65536+235
    mov  edx,0xffffff
    int  0x40

    mov  eax,38                    ; HOROZONTAL LINE ON WINDOW AREA
    mov  ebx,20*65536+280
    mov  ecx,135*65536+135
    mov  edx,0xffffff
    int  0x40

    mov  eax,8                     ; TEXT ENTER BUTTONS
    mov  ebx,20*65536+72
    mov  ecx,275*65536+13
    mov  edx,11
    mov  esi,[bcolor]
    add  esi , 0x10000000
    mov  edi , 0
    int  0x40
    inc  edx
    add  ecx,14*65536
    mov  eax,8
    int  0x40
    inc  edx
    add  ecx,14*65536
    mov  eax,8
    int  0x40

    mov  eax,8                     ; APPLY AND SAVE CHANGES BUTTON
    mov  ebx,20*65536+259
    mov  ecx,(329+14*2)*65536+15
    mov  edx,21
    mov  esi,[bcolor]
    add  esi , 0x10000000
    mov  edi , 0
    int  0x40

    mov  eax,8                     ; ADD ICON BUTTON
    mov  ebx,20*65536+129
    sub  ecx,14*2*65536
    inc  edx
    int  0x40

    mov  eax,8                     ; REMOVE ICON BUTTON
    add  ebx,130*65536
    inc  edx
    int  0x40

    mov  eax,0                     ; DRAW BUTTONS ON WINDOW AREA
    mov  ebx,20*65536+25
    mov  ecx,35*65536+19
    mov  edi,icon_table
    mov  edx,40
   newbline:

    cmp  [edi],byte 'x'
    jne  no_button

    mov  esi,0;0x5577cc
    cmp  [edi+100],byte 'x'
    jne  nores
    mov  esi,1;0xcc5555
  nores:

    push eax
    mov  eax,8
    push esi edi
    mov  esi , 0x10000000
    mov  edi , 0
    int  0x40
    pop  edi esi
    cmp  esi , 1
    jne  noresb
    push eax ebx ecx edx
    mov  eax , 13
    add  ebx , 1 * 65536 -1
    add  ecx , 1 * 65536 -1
    mov  edx , 0x808080
    int  0x40
    pop  edx ecx ebx eax
  noresb:
    pop  eax

  no_button:

    add  ebx,26*65536

    inc  edi
    inc  edx

    inc  al
    cmp  al,9
    jbe  newbline
    mov  al,0

    add  edx,6

    ror  ebx,16
    mov  bx,20
    ror  ebx,16
    add  ecx,20*65536

    inc  ah
    cmp  ah,9
    jbe  newbline

    mov  ebx,24*65536+250
    mov  ecx,0x000000
    mov  edx,text
    mov  esi,40
  newline:
    mov  ecx,[edx]
    add  edx,4
    mov  eax,4
    int  0x40
    add  ebx,14
    add  edx,40
    cmp  [edx],byte 'x'
    jne  newline

    call print_strings

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA


str1   db   '                   '
str2   db   '                   '

bcolor dd 0x335599

icon_table:

    times 4  db  'xxxx  xxxx'
    times 2  db  '          '
    times 1  db  '          '
    times 3  db  'xxxx  xxxx'


icons_reserved:

    times 10 db  '          '


text:
    db 0,0,0,0,        'CLICK ON ICON POSITION TO EDIT          '
    db 0,0,0,0,         '                                        '
    db 0  ,0  ,0  ,0  , ' ICON TEXT                              '
    db 0  ,0  ,0  ,0  , ' ICON APP                               '
    db 0  ,0  ,0  ,0  , ' ICON BMP                               '
    db 0,0,0,0,         '                                        '
    db 0  ,0  ,0  ,0,   '      ADD ICON            REMOVE ICON   '
    db 0,0,0,0,         '                                        '
    db 0  ,0  ,0  ,0,   '        SAVE AND APPLY ALL CHANGES      '

    db                  'x <- END MARKER, DONT DELETE            '



window_label:

    db 'ICON MANAGER',0

icons dd 0

addr  dd 0
ya    dd 0

add_text db 'PRESS BUTTON OF UNUSED ICON POSITION'
add_text_len:

rem_text db 'PRESS BUTTON OF USED ICON'
rem_text_len:

icon_name:

      db 'ICON       '

icon_start_parameters:

      db   25,1,1,1
      db   35,1,1,1
      db   'WRITE   BMP'
      db   'EDITOR                              '
      db   'EDITOR ',0,0

icon_default:

      db   'AA - HD.BMP      - /FD/1/SETUP                          '
      db   '- SETUP           *',13,10

icon_data:   ; data length 50+25+2

    times (52+25)*40 db 0

    nop

I_Param:

    times 256 db 0

    nop

I_END:














