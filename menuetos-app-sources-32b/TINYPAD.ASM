;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   TINYPAD
;;

use32

   org 0x0

   db  'MENUET01'  ; identifier
   dd  0x01        ; version
   dd  START       ; pointer to start
   dd  IMAGE_END   ; size of file
   dd  0x300000    ; size of memory
   dd  0xfff0      ; esp
   dd  I_PARAM     ; parameters
   dd  0           ; reserved

;  Memory 0x300000
;
;  stack            0x00fff0 +
;  load position    0x010000 +
;  screen comp      0x078000 +
;  edit area        0x080000 +
;  copy/paste area  0x2f0000 +

;  HOTKEYS CTRL+
;
;  F1   help screen
;  F2   load file
;  F3   search next
;  F4   save file
;  F5   enter filename
;  F6   enter search string
;  F7   ?
;  F8   change keyboard layout
;  F9   ?
;  F10  close window
;
; Ctrl + [ go to beginning
; Ctrl + ] go to the end

macro align value { rb (value-1)-($+value-1) mod value }

START:
    cmp    [I_PARAM],byte 0
    jz     noparams

    mov    esi,I_PARAM
    mov    edi,filename
    mov    ecx,50
    cld
    rep    movsb

    mov    edi,filename
    mov    ecx,50
    mov    eax,0
    repne  scasb
    sub    edi,filename
    dec    edi
    mov    [filename_len],edi
  noparams:

    jmp    do_load_file
;   call   drawwindow

; ****** WAIT LOOP ******

still:

    call writepos

still2:

    mov  eax,10   ; wait here until event
    int  0x40

    dec  eax      ; redraw ?
    jz   red
    dec  eax      ; key ?
    jz   key
    dec  eax      ; button ?
    jz   button

    jmp  still


  button:

    mov  eax,17
    int  0x40

    shr  eax , 8

    ; Scroll

    cmp  eax , 10000
    jb   noscroll
    cmp  eax , 10000 + 19999
    ja   noscroll
    mov  [scrollv],eax
    call draw_scroll
    sub  eax , 10000
    imul eax , 80
    mov  [post],eax
    call drawfile
    jmp  still
  noscroll:

    ; Menu

    cmp  eax , 0x2002
    je   yessave
    cmp  eax , 0x2004
    jne  noquit
    mov  eax , -1
    int  0x40
  noquit:
    cmp  eax , 0x2006
    je   show_help_text
    cmp  eax , 0x2000
    jne  noshowfile
    mov  edi , 0x78000
    mov  ecx , 0x07000
    mov  eax , 30
    cld
    rep  stosb
    call drawfile
  noshowfile:

    cmp  eax , 0x2007
    jne  noreadst
    mov  ah,51
    call read_string
    mov  eax , 13
    mov  ebx , 6*65536+6*80
    mov  ecx , 40*65536+20
    mov  edx , 0xffffff
    int  0x40
    mov  edi,0x78000
    mov  ecx,80*80
    mov  eax,0
    cld
    rep  stosb
    call drawfile
    jmp  still
  noreadst:

    cmp  eax , 0x2008
    jne  nosearch
    jmp  search
  nosearch:

    cmp  eax , 0x2000
    jae  still

    shl  eax , 8

    cmp  ah,50    ; search
    jne  no_search
  search:
    xor  esi,esi
    mov  edi,[post]
    add  edi,80
    imul ecx,[lines],80
    sub  ecx,edi
  news:
    push edi
  news2:
    mov  al,[esi+search_string]
    mov  bl,[edi+0x80000]
    cmp  al,bl
    je   yes_char
    cmp  al,'A'
    jb   nof
    cmp  al,'z'
    ja   nof   ; add russian !

    cmp  al,'a'
    jb   @f
    add  al,-32
    jmp  gogogo
  @@:
    cmp  al,'Z'
    ja   nof
    add  al,32
  gogogo:
    cmp  al,bl
    jne  nof
  yes_char:
    inc  edi
    inc  esi
    cmp  esi,[search_len]
    jge  sfound
    jmp  news2
  nof:
    pop  edi
    xor  esi,esi
    inc  edi
    loop news
    jmp  still
  sfound:
    xor  edx,edx
    mov  eax,edi
    mov  ebx,80
    div  ebx
    imul eax,80

    mov  [post],eax
    mov  [posy],0
    call clear_screen
    call drawfile
    jmp  still
  no_search:

    cmp  ah,4
    jne  noid4

  do_load_file:

    call empty_work_space

    cmp  [filename],'/'
    jne  @f

    call loadhdfile
    jmp  restorecursor
  @@:
    call loadfile

  restorecursor:
    mov  edi,0x78000
    mov  ecx,80*80
    mov  al,1
    cld
    rep  stosb
    xor  eax,eax
    mov  [post],eax
    mov  [posx],eax
    mov  [posy],eax

; enable color syntax for ASM and INC files:
    mov [colors],0

    jmp nocol

    mov eax, [filename_len]
    add eax, filename
    cmp word [eax-3],'AS'
    jne  @f
    cmp byte [eax-1],'M'
    jne  @f
    mov [colors],1
    jmp nocol
  @@:
    cmp word [eax-3],'IN'
    jne @f
    cmp byte [eax-1],'C'
    jne @f
    mov [colors],1
  @@:
  nocol:

    mov  ecx,[filename_len]
    add  ecx,10
    cmp  ecx,[headlen]
    jne  @f
    add  ecx,-10
    mov  esi,filename
    mov  edi,I_END
    rep  cmpsb
    jne  @f
    call drawfile
    jmp  still
  @@:
; set window title:
    mov  esi,filename
    mov  edi,I_END
    mov  ecx,[filename_len]
    mov  eax,ecx
    add  eax,10
    mov  [headlen],eax
    cld
    rep  movsb

    mov  [edi],dword ' -  '
    add  edi,3
    mov  esi,htext
    mov  ecx,htextlen-htext
    rep  movsb

    call drawwindow ;drawfile
    jmp  still
  noid4:



    mov  [savetohd],dword 0

    cmp  ah,2
    jz   yessave

    dec  ah
    jnz  nosave
    or   eax,-1
    int  0x40

  yessave:

    cmp  byte [filename],'/'
    jne  @f
    mov  [savetohd],1
@@:
    mov  [filelen],dword 0x0
    mov  [fileslines],dword 0x0

    mov  ebx,0x80000+80
    xor  edx,edx
    mov  ecx,0x10000

  sdonewline:

    mov  esi,ebx

  sdoline:

    dec  esi
    cmp  [esi],byte ' '
    jnz  slinefound

    mov  eax,ebx
    add  eax,-80
    cmp  eax,esi
    jnz  sdoline

    dec  esi   ; (!!!) add  esi,2

  slinefound:

    mov  edi,ecx ; edi = write position

    push ecx

    mov  ecx,esi ; ecx =  string length + 1
    add  ecx,80
    sub  ecx,ebx
    inc  ecx

    push ecx

    mov  esi,ebx ; beginning of next line
    add  esi,-80 ; - 80 =    of this line

    cld
    rep  movsb

    mov  [edi],byte 13
    inc  edi
    mov  [edi],byte 10
    inc  edi

    pop  eax
    pop  ecx
    add  ecx,eax
    add  ecx,2

    mov  [filelen],ecx

    mov  eax,[fileslines]
    inc  eax
    mov  [fileslines],eax

    cmp  eax,[lines]
    jg   dosave

    add  ebx,80

    jmp  sdonewline

  dosave:

    cmp  [savetohd],1
    jz   nofloppysave

    mov  eax,33
    mov  ebx,filename    ; pointer to file name
    mov  ecx,0x10000     ; buffer
    mov  edx,[filelen]   ; count to write in bytes
    sub  edx,0x10000+2
    xor  esi,esi         ; 0 create new , 1 append
    int  0x40

    test eax,eax
    je   still

    call file_not_found

  nofloppysave:

    cmp  [savetohd],0
    jz   still

    mov  ecx,[filelen]
    sub  ecx,0x10000+2
    mov  [fileinfo_write+8],ecx

    mov  esi,filename
    mov  edi,pathfile_write
    mov  ecx,50
    cld
    rep  movsb

    mov  eax,58
    mov  ebx,fileinfo_write
    int  0x40

    jmp  still

   fileinfo_write:
    dd 1
    dd 0
    dd 0
    dd 0x10000
    dd 0x70000
   pathfile_write:
    times 51 db 0

  nosave:

    inc  ah
    call read_string

    jmp  still

filelen     dd 0x0
fileslines  dd 0x0

empty_work_space:
; очистить все
  mov  eax,32
  mov  edi,0x80000
  mov  ecx,0x300000-0x90000
  cld
  rep  stosb
  mov  edi,0x10000
  mov  ecx,0x60000
  cld
  rep  stosb
  ret


red:
; перерисовка окна
   call   clear_screen
   call   drawwindow
   jmp    still

clear_screen:
; очистить экран
   mov    ecx,80*40
   mov    edi,0x78000
   xor    eax,eax
 @@:
   mov    [edi],eax
   add    edi,4
   dec    ecx
   jnz    @b
   ret

invalidate_string:
   imul   eax,[posy],80
   add    eax,0x78000
   mov    edi,eax
   mov    al,1
   mov    ecx,80
   rep    stosb
   ret

layout:
; сменить раскладку клавиатуры
 mov eax,19
 mov ebx,setup
 mov ecx,param_setup
 int 0x40
 ret

setup db 'SETUP      '
param_setup db 'LANG',0

  key:

    mov  eax,2   ; GET KEY
    int  0x40

    shr eax,8

; HELP_TEXT {
    cmp  al,9    ; Tab || Ctrl + I
    je   @f
    cmp  al,210  ; Ctrl + F1
    jne  no_help_text
  @@:
  show_help_text:
    mov  eax,13
    mov  ebx,78*65536+6*57
    mov  ecx,70*65536+172  ;112
    mov  edx,0xffffff
    int  0x40
    mov  eax,4
    mov  ebx,100*65536+80
    xor  ecx,ecx
    mov  esi,51
    mov  edx,help_text
  new_help_line:
    int  0x40
    add  ebx,10
    add  edx,esi
    cmp  [edx],byte 'x'
    jne  new_help_line
    mov  eax,10
    int  0x40
    call clear_screen
    call drawfile
    jmp  still
; HELP_TEXT }

  no_help_text:
; LOAD_FILE {
    cmp  al,211       ; Ctrl + F2
    je   do_load_file
; LOAD_FILE }

; SEARCH {
    cmp  al,212       ; Ctrl + F3
    je   search
; SEARCH }

; SAVE_FILE {
    cmp  al,213       ; Ctrl + F4
    je   yessave
; SAVE_FILE }

; ENTER_FILENAME {
    cmp  al,214       ; Ctrl + F5
    jne  @f
    mov  ah,5
    call read_string
    jmp  still
  @@:
; ENTER_FILENAME }

; ENTER_SEARCH {
    cmp  al,215       ; Ctrl + F6
    jne  @f
    mov  ah,51
    call read_string
    mov  eax , 13
    mov  ebx , 6*65536+6*80
    mov  ecx , 40*65536+20
    mov  edx , 0xffffff
    int  0x40
    mov  edi,0x78000
    mov  ecx,80*80
    mov  eax,0
    cld
    rep  stosb
    call drawfile
    jmp  still
  @@:
; ENTER_SEARCH }

; CHANGE_LAYOUT {
    cmp  al,217       ; Ctrl + F8
    jne  @f
    call layout
    jmp  still
  @@:
; CHANGE_LAYOUT }

; 3 times english -> rus
; 2 times russian -> eng

; COPY START {
    cmp  al,19
    jne  no_copy_start
    mov  eax,[post]
    imul ebx,[posy],80
    add  eax,ebx
    mov  [copy_start],eax
    jmp  still
; COPY START }

  no_copy_start:
; COPY END {
    cmp  al,5
    jne  no_copy_end
    cmp  [copy_start],0
    je   still
    mov  ecx,[post]
    imul ebx,[posy],80
    add  ecx,ebx
    add  ecx,80
    cmp  ecx,[copy_count]
    jb   still
    sub  ecx,[copy_start]
    mov  [copy_count],ecx
    mov  esi,[copy_start]
    add  esi,0x80000
    mov  edi,0x2f0000
    cld
    rep  movsb
    jmp  still
; COPY END }

  no_copy_end:
; PASTE {
    cmp  al,16
    jne  no_copy_paste
    cmp  [copy_count],0
    je   still
    mov  eax,[copy_count]
    xor  edx,edx
    mov  ebx,80
    div  ebx
    add  [lines],eax
    mov  ecx,0x2e0000
    mov  eax,[post]
    imul ebx,[posy],80
    add  eax,ebx
    add  eax,0x80000
    sub  ecx,eax
    mov  esi,0x2e0000
    sub  esi,[copy_count]
    mov  edi,0x2e0000
    std
    rep  movsb
    mov  esi,0x2f0000
    mov  edi,[post]
    imul eax,[posy],80
    add  edi,eax
    add  edi,0x80000
    mov  ecx,[copy_count]
    cld
    rep  movsb
    call clear_screen
    call drawfile
    jmp  still
; PASTE }

  no_copy_paste:
; DEL_LINE {
    cmp  al,4
    jne  no_delete_line
    mov  eax,[post]
    xor  edx,edx
    mov  ebx,80
    div  ebx
    add  eax,[posy]
    inc  eax
    cmp  eax,[lines]
    jge  still
    dec  dword [lines]
    imul edi,[posy],80
    add  edi,[post]
    add  edi,0x80000
    mov  esi,edi
    add  esi,80
    mov  ecx,0x2e0000
    sub  ecx,esi
    cld
    rep  movsb
    call clear_screen
    call drawfile
    jmp  still
; DEL_LINE }

  no_delete_line:

; ENTER {

    cmp  al,13
    jz   enter1
    jmp  noenter

   enter1:

    ; lines down

    xor  edx,edx
    mov  eax,[posy]
    inc  eax
    imul eax,80
    add  eax,0x80000-1
    add  eax,[post]
    mov  ebx,eax

    ; ebx = ([posy]+1)*80 + 0x80000 + [post] - 1
    ; debug: ebx = 79 + 0x80000

    xor  edx,edx
    imul eax,[lines],80
    add  eax,0x80000-1
    add  eax,[post]
    mov  ecx,eax

    ; ecx = [lines]*80 + 0x80000 + [post] - 1
    ; debug: ecx = 79 + 0x80000

    cmp  ebx,ecx
    jz   bug_fixed

   mnl:

    mov  dl,[ecx]
    mov  [ecx+80],dl
    dec  ecx

    cmp  ecx,ebx
    jnz  mnl

  bug_fixed:

    ; save for later

    xor  edx,edx
    imul eax,[posy],80
    add  eax,0x80000-1
    add  eax,[post]
    add  eax,[posx]
    mov  ebx,eax

    push ebx

    ; empty line

    mov  [posx],dword 0
    inc  [posy]

    ;

    xor  edx,edx
    imul eax,[posy],80
    add  eax,0x80000-1
    add  eax,[post]
    add  eax,[posx]
    mov  ebx,eax

    mov  ecx,eax
    add  ecx,80

   enz:
    mov  [ebx],byte 32
    inc  ebx
    cmp  ecx,ebx
    jnz  enz

    ; end of line to next line beginning

    xor  edx,edx
    imul eax,[posy],80
    add  eax,0x80000-1
    add  eax,[post]
    add  eax,[posx]
    mov  ebx,eax

    pop  esi
    mov  edi,ebx

    inc  esi
    inc  ebx

   enz2:
    mov  dl,[esi]
    mov  [ebx],dl
    mov  [esi],byte 32

    inc  esi
    inc  ebx

    cmp  esi,edi
    jb   enz2

    inc  [lines]

    ; Advance X position to character at previous line

    imul eax,[posy],80
    add  eax,0x80000
    add  eax,[post]
    add  eax,[posx]
    ; Current line empty ?
    mov  ecx,79
  newxc:
    cmp  [eax+ecx],byte 32
    ja   noxc
    loop newxc
    ; Previous line empty ?
    mov  ecx,79
  newxc2:
    cmp  [eax+ecx-80],byte 32
    ja   noxc2
    loop newxc2
    jmp  noxc
  noxc2:
    ; To first letter of previous line
    mov  ecx,0
  newxc3:
    cmp  [eax+ecx-80],byte 32
    ja   noxc3
    inc  ecx
    cmp  ecx , 70
    jb   newxc3
    jmp  noxc
  noxc3:
    add  [posx],ecx
  noxc:
    ;

    mov  ecx,[posy]
    cmp  ecx,[slines]
    jz   osc
    call clear_screen
    call drawfile
    jmp  still
  osc:
    dec  ecx
    mov  [posy],ecx
    add  [post],80
    call clear_screen
    call drawfile
    jmp  still

; ENTER }

  noenter:

; UP {
    cmp  al,130+48
    jnz  noup
    mov  ecx,[posy]
    test ecx,ecx
    jnz  up1
    mov  ecx,[post]
    test ecx,ecx
    jnz  up2
    jmp  still
  up2:
    add  ecx,-80
    mov  [post],ecx
    call clear_screen
    call drawfile
    jmp  still
  up1:
    dec  ecx
    mov  [posy],ecx
    call drawfile
    jmp  still
; UP }

  noup:

; DOWN {
    cmp  al,129+48
    jnz  nodown
    mov  ecx,[posy]
    mov  eax,[slines]
    dec  eax
    cmp  ecx,eax
    jb   do1
    mov  ecx,[post]
    mov  eax,[lines]
    sub  eax,[slines]
    dec  eax
    imul eax,80
    cmp  ecx,eax
    jbe  do2
    jmp  still
  do2:
    add  ecx,80
    mov  [post],ecx
    call clear_screen
    call drawfile
    jmp  still
  do1:
    pusha
    mov  eax,[post]
    xor  edx,edx
    mov  ebx,80
    div  ebx
    add  eax,[posy]
    inc  eax
    cmp  eax,[lines]
    jb   do10
    popa
    jmp  still
  do10:
    popa
    cld
    inc  ecx
    mov  [posy],ecx
    call drawfile
    jmp  still
; DOWN }

  nodown:

; LEFT {
    cmp  al,128+48
    jnz  noleft
    mov  ecx,[posx]
    xor  edx,edx
    cmp  ecx,edx
    jnz  le1
    jmp  still
  le1:
    dec  ecx
    mov  [posx],ecx
    call drawfile
    jmp  still
; LEFT }

  noleft:

; RIGHT {
    cmp  al,131+48
    jnz  noright
    mov  ecx,[posx]
    mov  edx,79
    cmp  ecx,edx
    jnz  ri1
    jmp  still
  ri1:
    inc  ecx
    mov  [posx],ecx
    call drawfile
    jmp  still
; RIGHT }

  noright:

; PAGE_UP {
    cmp  al,136+48
    jnz  nopu
    mov  eax,[slines]
    dec  eax
    imul eax,80
    mov  ecx,[post]
    cmp  eax,ecx
    jbe  pu1
    mov  ecx,eax
   pu1:
    sub  ecx,eax
    mov  [post],ecx
    call clear_screen
    call drawfile
    jmp  still
; PAGE_UP }

  nopu:

; PAGE_DOWN {
    cmp  al,135+48
    jnz  nopd
    mov  eax,[post]   ; eax = offset
    xor  edx,edx
    mov  ebx,80
    div  ebx          ; eax /= 80
    mov  ecx,[lines]  ; ecx = lines in the file
    cmp  eax,ecx      ; if eax < ecx goto pfok
    jb   pdok
    jmp  still
  pdok:
    mov  eax,[slines] ; eax = lines on the screen
    dec  eax          ; eax--
    imul eax,80       ; eax *= 80
    add  [post],eax   ; offset += eax

    mov  eax,[lines]  ; eax =  lines in the file
    sub  eax,[slines] ; eax -= lines on the screen
    xor  edx,edx
    imul eax,80       ; eax *= 80
    cmp  [post],eax
    jb   pdok2
    mov  [post],eax
  pdok2:
    call clear_screen
    call drawfile
    jmp  still
; PAGE_DOWN }

  nopd:

; HOME {
    cmp  al,132+48
    jnz  nohome
    xor  eax,eax
    mov  [posx],eax
    call drawfile
    jmp  still
; HOME }

  nohome:

; END {
    cmp  al,133+48
    jnz  noend
    mov  ecx,80
    xor  edx,edx
   ke1:
    dec  ecx
    mov  [posx],ecx
    test ecx,ecx
    jz   ke2

    xor  edx,edx
    imul eax,[posy],80
    add  eax,0x80000-1
    add  eax,[post]
    add  eax,[posx]
    mov  ebx,eax

    mov  dl,[ebx]
    mov  eax,33
    cmp  edx,eax
    jb   ke1

   ke2:
    call drawfile
    jmp  still
; END }

  noend:

    cmp  al,251         ; Ctrl + [
    jnz  no_go_to_start
    mov  [post],0       ; offset = 0
    call clear_screen   ; clear screen
    call drawfile       ; draw file
    jmp  still          ; go to still

  no_go_to_start:

    cmp  al,253         ; Ctrl + ]
    jnz  no_go_to_end
    mov  eax,[lines]    ; eax = lines in the file
    sub  eax,[slines]   ; eax -= lines on the screen
    imul eax,80         ; eax *= 80 (length of line)
    mov  [post],eax     ; offset in the file
    call clear_screen   ; clear screen
    call drawfile       ; draw file
    jmp  still          ; go to still
  no_go_to_end:

; DELETE {
    cmp  al,134+48
    jz   yesdel
    jmp  nodel

  yesdel:

    imul eax,[posy],80
    add  eax,0x80000
    add  eax,[post]
    add  eax,[posx]
    mov  ecx,eax

    imul eax,[posy],80
    add  eax,0x80000+79
    add  eax,[post]
    mov  ebx,eax

    push ebx

    dec  ecx
    dec  ebx


    push ecx ebx

    push ebx

    imul eax,[posy],80
    add  eax,0x80000
    add  eax,[post]
    mov  ecx,eax

    xor  edx,edx
    xor  eax,eax

    pop  ebx

    dec  ecx

   key12:
    inc  ecx
    mov  dh,[ecx]
    cmp  dh,33
    jb   nok
    xor  eax,eax
    inc  eax
   nok:
    cmp  ecx,ebx
    jb   key12

    pop  ebx ecx

   key123:
    inc  ecx
    mov  dl,[ecx+1]
    mov  [ecx],dl
    cmp  ecx,ebx
    jb   key123


    pop  ebx
    mov  [ebx],byte 32

    test eax,eax
    jz   dellinesup

    call clear_screen
    call drawfile
    jmp  still

  dellinesup:

    ; lines -1

    pusha

    mov  eax,[post]
    xor  edx,edx
    mov  ebx,80
    div  ebx
    add  eax,[posy]
    inc  eax

    cmp  eax,[lines]
    jb   dli1

    popa

    jmp  still

  dli1:

    popa

    dec  [lines]

    ; lines up

    mov  [posx],dword 0

    imul eax,[posy],80
    add  eax,0x80000-1
    add  eax,[post]
    mov  ebx,eax

    push ebx

    imul eax,[lines],80
    add  eax,0x80000-1
    add  eax,[post]
    mov  ecx,eax

    pop  ebx

   mnlu:

    mov  dl,[ebx+80]
    mov  [ebx],dl
    inc  ebx

    cmp  ecx,ebx
    jnz  mnlu

    call clear_screen
    call drawfile
    jmp  still
; DELETE }

  nodel:


    cmp  al,137+48   ; Insert
    jnz  noins

    imul eax,[posy],80
    add  eax,0x80000
    add  eax,[post]
    add  eax,[posx]
    mov  ecx,eax
    ; ecx = [posy]*80+0x80000+[post]+[posx]

    imul eax,[posy],80
    add  eax,0x80000+79
    add  eax,[post]
    mov  ebx,eax
    ; ebx = [posy]*80+0x80000+79+[post]

   key1234:
    dec  ebx
    mov  dl,[ebx]
    mov  [ebx+1],dl
    cmp  ecx,ebx
    jb   key1234

    mov  [ecx],byte 32

    call invalidate_string
    call drawfile
    jmp  still

  noins:


    cmp  al,8   ; Backspace
    jz   conbs2
    jmp  nobs
  conbs2:
    mov  ecx,[posx]
    test ecx,ecx
    jnz  conbs
    jmp  still
  conbs:
    dec  ecx
    mov  [posx],ecx

    imul eax,[posy],80
    add  eax,0x80000
    add  eax,[post]
    add  eax,[posx]
    mov  ebx,eax

    push ebx

    imul eax,[posy],80
    add  eax,0x80000+79
    add  eax,[post]
    mov  ebx,eax

    pop  ecx

    push ebx

    dec  ecx
   key124:
    inc  ecx
    mov  dl,[ecx+1]
    mov  [ecx],dl
    cmp  ecx,ebx
    jb   key124

    pop  ebx
    mov  [ebx],byte ' ' ; (!!!) 0

    call invalidate_string
    call drawfile
    jmp  still

  nobs:

    push eax  ; add key

    imul eax,[posy],80
    add  eax,0x80000
    add  eax,[post]
    add  eax,[posx]
    mov  ecx,eax

    push ecx

    imul eax,[posy],80
    add  eax,0x80000+79
    add  eax,[post]
    mov  ebx,eax

   key1:
    dec  ebx
    mov  dl,[ebx]
    mov  [ebx+1],dl
    cmp  ecx,ebx
    jbe  key1

    pop  ebx

    pop  eax

    mov  [ebx],al
    mov  edx,78
    mov  ecx,[posx]
    cmp  edx,ecx
    jb   noxp
    inc  ecx
    mov  [posx],ecx
  noxp:

    call invalidate_string
    call drawfile
    jmp  still




; **********************************
; **********  DRAWWINDOW  **********
; **********************************

align 4

drawwindow:

    mov  eax,12                   ; WINDOW DRAW START
    mov  ebx,1
    int  0x40

    mov  eax,48
    mov  ebx,3
    mov  ecx,system_colours
    mov  edx,10*4
    int  0x40

    mov  [w_work],0xffffff ; gray background for ASMPAD
    mov  [w_work_button],0x10384868 ; dd
    mov  [w_work_graph],0xe0e0e0 ; 0x607888 ; 0xd0d0d0 ; 0x384868  ; dd
    mov  [w_work_button_text],0;xffffff
    mov  [cursor],0xdddddd ; bbbbff

    xor  eax,eax                  ; DEFINE WINDOW
    mov  ebx,100*65536+509
    mov  ecx, 80*65536+445
    mov  edx,[w_work]
    add  edx,0x04000000
  ;  mov  esi,[w_grab]
  ;  or   esi,0x80000000
  ;  mov  edi,[w_frame]
    mov  esi , window_label
    mov  edi , menu_struct
    int  0x40

; header string
    mov  eax,4
    mov  ebx,10*65536+8
    mov  ecx,[w_grab_text]
    mov  edx,I_END
    mov  esi,[headlen]
;    int  0x40

    mov  eax,9    ; get info about me
    mov  ebx,process_info
    xor  ecx,ecx
    dec  ecx
    int  0x40

    mov  eax,[process_info+46] ; y size
    add  eax , 14
    mov  [temp],eax

    cmp  eax,100
    jb   no_draw ; do not draw text & buttons if height < 100
    sub  eax,80+15
    xor  edx,edx
    mov  ebx,10
    div  ebx
    mov  [slines],eax

    cmp eax,[posy]
    jnb @f
    dec eax
    mov [posy],eax
  @@:

    mov  eax,[temp] ; calculate buttons position
    add  eax,-47
    mov  [dstart],eax

    mov  eax,13                   ; BAR STRIPE
    mov  ebx,62*65536+486-109+13+6
    mov  ecx,[dstart]
    add  ecx,29
    shl  ecx,16
    inc  ecx
    mov  edx,[w_work_graph]
;    int  0x40

    mov  eax,8                    ; STRING BUTTON
    mov  ebx,5*65536+57
    mov  ecx,[dstart]
    add  ecx,29
    shl  ecx,16
    add  ecx,13
    mov  edx,51
    mov  esi,[w_work_button]
    mov  edi,button5
;    int  0x40

                                  ; SEARCH BUTTON
    mov  ebx,(485-51+13+6)*65536+57-6
    mov  edx,50
    mov  esi,[w_work_button]
    mov  edi,button3
;    int  0x40

    mov  eax,4                    ; SEARCH TEXT
    mov  ebx,[dstart]
    add  ebx,6*65536+32
    mov  ecx,[w_work_button_text]
    mov  edx,searcht
    mov  esi,searchtl-searcht
;    int  0x40

    mov  eax,13                   ; BAR STRIPE
    mov  ebx,6*65536+486+13
    mov  ecx,[dstart]
    shl  ecx,16
    add  ecx,15
    mov  edx,[w_work_graph]
    int  0x40

    mov  eax,8                    ; SAVE BUTTON
    mov  ebx,(485-51+13+6)*65536+57-6
    mov  ecx,[dstart]
    inc  ecx
    shl  ecx,16
    add  ecx,13
    mov  edx,2
    mov  esi,[w_work_button]
    mov  edi,button1
    int  0x40

    mov  eax,4                    ; FIRST TEXT LINE (POSITION...)
    mov  ebx,12*65536
    add  ebx,[dstart]
    add  ebx,4
    mov  ecx,[w_work_button_text]
    mov  edx,htext2
    mov  esi,htextlen2-htext2
    int  0x40


    mov  eax,8                    ; FILE BUTTON
    mov  ebx,5*65536+57
    mov  ecx,[dstart]
    add  ecx,15
    shl  ecx,16
    add  ecx,13
    mov  edx,5
    mov  esi,[w_work_button]
    mov  edi,button4
    int  0x40

    mov  ebx,(485-51+13+6)*65536+57-6  ; LOAD BUTTON
    mov  ecx,[dstart]
    add  ecx,15
    shl  ecx,16
    add  ecx,13
    mov  edx,4
    mov  edi,button2
    int  0x40

    mov  eax,4                    ; SECOND TEXT LINE (FILE...)
    mov  ebx,12*65536
    add  ebx,[dstart]
    add  ebx,18
    mov  ecx,[w_work_button_text]
    mov  edx,savetext
    mov  esi,savetextlen-savetext
    int  0x40

    call draw_scroll

    mov  edi,0x78000
    mov  ecx,80*80
    mov  eax,0
    cld
    rep  stosb

    call drawfile

    mov  eax,[dstart]
    add  eax,17
    mov  [ya],eax
    mov  [addr],filename
    call print_text

    add  eax,14
    mov  [ya],eax
    mov  [addr],search_string
;    call print_text

no_draw:

    mov  eax,12                   ; WINDOW DRAW END
    mov  ebx,2
    int  0x40

    ret


draw_scroll:

    pusha
    mov  eax , 113
    mov  ebx , 01 shl 16 + 492
    mov  ecx , 38 shl 16
    add  ecx , [process_info+46]
    sub  ecx , 85-16
    mov  edx , 10000
    mov  esi , [lines]
    cmp  esi , 5
    jb   drscrl1
    sub  esi , 5
  drscrl1:
    mov  edi , [scrollv]
    int  0x40
    popa

    ret


scrollv: dd 10000


; **********************************
; ***********  DRAWFILE  ***********
; **********************************



drawfile:

    mov  [next_not_quote],1
    mov  [next_not_quote2],1

    mov  eax,[post] ; print from position

    pusha

    mov  edi,[post]
    mov  [posl],edi

    mov  ebx,8*65536+26+18    ; letters
    xor  ecx,ecx

    mov  edx,0x80000
    add  edx,eax
    mov  edi,edx

    imul esi,[slines],80
    add  edi,esi


  nd:

    pusha

    mov       edx,ebx
    mov       edi,ebx
    add       edi,(6*65536)*80

  wi1:


    ; draw ?


    pusha

    push      ecx

    imul      eax,[posx],6
    add       eax,8
    shl       eax,16
    mov       ecx,eax

;    ecx = ([posx]*6+8)<<16

    imul      eax,[posy],10
    add       eax,26+18
    add       eax,ecx

;    eax = [posy]*10+26+ecx

    pop       ecx

    cmp       edx,eax
    jnz       drwa

    mov       eax,0x7ffff
    call      check_pos
    jmp       drlet

  drwa:

    popa


    pusha

    imul      eax,[posxm],6
    add       eax,8
    shl       eax,16
    mov       ecx,eax

    imul      eax,[posym],10
    add       eax,26+18
    add       eax,ecx

    cmp       edx,eax
    jnz       drwa2

    mov       eax,0x7ffff
    call      check_pos
    jmp       drlet

  drwa2:

    popa

    pusha

    mov       eax,0x78000  ; screen
    add       eax,[posl]   ; screen+abs
    sub       eax,[post]   ; eax = screen+abs-base = y*80+x + screen

    mov       edx,0x80000 ; file
    add       edx,[posl]  ; edx = absolute
    mov       bl,[edx]    ; in the file

    call      check_pos

    mov       cl,[eax]   ; on the screen
    cmp       bl,cl
    jnz       drlet

    popa

    jmp       nodraw


    ; draw letter


  drlet:

    mov       [eax],bl ; mov byte to the screen
    mov [tmpabc],bl
    popa      ; restore regs

;!!!!!!!!!!!!

    cmp [tmpabc],' '
    je @f
    call      draw_letter
    jmp nodraw
   @@:
    call clear_char

    nodraw:

    inc       [posl]

    add       edx,6*65536
    cmp       edx,edi
    jz        wi3
    jmp       wi1

  wi3:

    popa

    add       ebx,10
    add       edx,80
    cmp       edi,edx
    jbe       nde
    jmp       nd

  nde:

    mov       eax,[posx]
    mov       ebx,[posy]

    mov       [posxm],eax
    mov       [posym],ebx

    popa

    ret

tmpabc db 0

 stText    equ 0
 stInstr   equ 1
 stReg     equ 2
 stNum     equ 3
 stQuote   equ 4
 stComment equ 5

clear_char:

    pusha
    mov       ebx,[w_work]

    push      ecx

    imul      eax,[posx],6
    add       eax,8
    shl       eax,16
    mov       ecx,eax

    imul      eax,[posy],10
    add       eax,26+18
    add       eax,ecx

    pop ecx
    cmp       edx,eax
    jnz       drw1
    mov       ebx,[cursor]   ; light blue 0x00ffff
  drw1:

                     ; draw bar
    push      ebx
    mov       eax,13
    mov       ebx,edx
    mov       bx,6
    mov       ecx,edx
    shl       ecx,16
    add       ecx,10
    pop       edx
    int       0x40
    popa
    ret

;align 4
; CHECK POSITION
check_pos:
  cmp [colors],1
  je @f
  mov [d_status],stText
  ret
 @@:
  pushad

; COMMENT TERMINATOR
  cmp  [d_status],stComment
  jnz  @f
  mov  eax,[posl]
  sub  eax,[post]
  xor  edx,edx
  mov  ebx,80
  div  ebx
  test edx,edx
  jnz  end_check_pos
  mov  [d_status],stText
 @@:

; QUOTE TERMINATOR B
  cmp [next_not_quote],1
  jne  @f
  mov [d_status],stText
 @@:

  mov eax,[posl]
  add eax,0x80000
  mov edx,eax
  mov al,[eax]

; QUOTE TERMINATOR A
  cmp [d_status],stQuote
  jnz noquote
  cmp al,[quote]
  jne end_check_pos
  mov [next_not_quote],1
  jmp end_check_pos
 noquote:
  mov [next_not_quote],0

; START QUOTE 1
  cmp al,"'"
  jne @f
  mov [d_status],stQuote
  mov [quote],al
  jmp end_check_pos
 @@:

; START QUOTE 2
  cmp al,'"'
  jne @f
  mov [d_status],stQuote
  mov [quote],al
  jmp end_check_pos
 @@:

; START COMMENT
  cmp al,';'
  jne @f
  mov [d_status],stComment
  jmp end_check_pos
 @@:

; NUMBER TERMINATOR
  cmp [d_status],stNum
  jne nonumt
  mov ecx,23
 @@:
  dec ecx
  jz  nonumt
  cmp al,[symbols+ecx]
  jne @b

 nonumt1:
  mov [d_status],stText
 nonumt:

; START NUMBER
  cmp [d_status],stNum
  je  end_check_pos
  cmp al,'0'
  jb  nonum
  cmp al,'9'
  ja  nonum
  mov bl,[edx-1]
  mov ecx,23
 @@:
  dec ecx
  jz  nonum
  cmp bl,[symbols+ecx]
  jne @b
 @@:
  mov [d_status],stNum
  jmp end_check_pos
 nonum:

 mov [d_status],stText

 end_check_pos:
  popad
  ret

symbols db '%#&*\:/<>|{}()[]=+-,. '

align 4
;;;;;;;;;;;;;;;;;
;; DRAW LETTER ;;
;;;;;;;;;;;;;;;;;
draw_letter:

    call clear_char

    pusha
;    mov       eax,4    ; text
    mov       ebx,edx  ; x & y

mov eax,[d_status]
mov ecx,[eax*4+color_tbl]
mov eax,4

con_col:
    xor       esi,esi
    inc       esi
    mov       edx,0x80000
    mov       edi,[posl]
    add       edx,edi
    int       0x40
    popa

    ret

d_status dd 0
quote    db 0

align 4

color_tbl:
dd 0x00000000 ; text
dd 0x00000000 ; instruction
dd 0x00000000 ; register
dd 0x00009000 ; number
dd 0x00a00000 ; quote
dd 0x00909090 ; comment

next_not_quote2 db 0
next_not_quote  db 0

; **********************************
; ***********  LOADFILE  ***********
; **********************************

fileinfo_read:

     dd  0
     dd  0
     dd  300000/512
     dd  0x10000
     dd  0x70000
pathfile_read:
     times 51 db 0


loadhdfile:

     mov  esi,filename
     mov  edi,pathfile_read
     mov  ecx,50
     cld
     rep  movsb

     mov  eax,58
     mov  ebx,fileinfo_read
     int  0x40

     xchg eax,ebx

     test ebx,ebx
     je   filefound
     cmp  ebx,5
     je   filefound

     call file_not_found
     ret

loadfile:

    mov  eax,6        ; 6 = open file
    mov  ebx,filename
    xor  ecx,ecx
    mov  edx,16800
    mov  esi,0x10000
    int  0x40

    inc  eax          ; eax = -1 -> file not found
    jnz  filefound

    call file_not_found
    ret

  filefound:

    dec  eax
    mov  [filesize],eax

    mov  edi,0x80000
  new32:
    mov  [edi],byte 32
    inc  edi
    mov  edx,0x2effff
    cmp  edi,edx
    jnz  new32


    mov  edi,0x10000
    mov  ebx,0x80000

newline:

    xor  ecx,ecx
    inc  ecx

  newcheck:

    inc  ecx
    inc  edi

    mov  edx,[edi]
    and  edx,255
    mov  eax,10
    cmp  edx,eax
    jz   drawline

    mov  eax,80
    cmp  ecx,eax
    jbe  newcheck

    inc  ecx
    jmp  drawline


; ecx length
; edi position
; ebx position at 0x80000


  drawline:

    pusha

    mov       esi,ecx
    and       esi,127
    dec       esi
    mov       edx,edi
    mov       eax,esi
    sub       edx,eax

    pusha
    mov       eax,ebx
    add       eax,esi
    dec       eax
    dec       eax
    jz        nl2
    inc       eax

  nl1:
    mov       cl,[edx]
    cmp       cl,byte 15
    jb        novalidchar
    mov       [ebx],cl
  novalidchar:
    inc       edx
    inc       ebx

    mov       ecx,0x10000-1
    add       ecx,[filesize]
    cmp       edx,ecx
    jbe       frok
    jmp       nl2
  frok:
    cmp       ebx,eax
    jb        nl1
  nl2:

    popa
    popa

    inc       edi
    add       ebx,80

    mov       eax,0x10000
    add       eax,[filesize]
    cmp       eax,edi
    jb        endload

    jmp       newline

  endload:

    add       ebx,-0x80000
    mov       eax,ebx
    xor       edx,edx
    mov       ebx,80
    div       ebx

    mov       [lines],eax

    ret


file_not_found:

   mov  eax,13           ; draw red square
   mov  ebx,6*65536+15
   mov  ecx,23*65536+15
   mov  edx,0xff0000
   int  0x40

   push ebx              ; wait for 1/3 sec.
   mov  eax,5
   mov  ebx,33
   int  0x40
   pop  ebx

   mov  eax,13           ; clean square
   mov  edx,[w_work]
   int  0x40

   mov  [lines],1        ; open empty document

   ret


; *****************************
; ******  WRITE POSITION ******
; *****************************


writepos:

    pusha

    mov  eax,[posx]
    inc  eax
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  al,48
    add  dl,48
    mov  [htext2+ 9],al
    mov  [htext2+10],dl

    mov  eax,[post]
    xor  edx,edx
    mov  ebx,80
    div  ebx
    add  eax,[posy]
    inc  eax
    mov  ebx,10
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [htext2+16],dl  ; 00001
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [htext2+15],dl  ; 00010
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [htext2+14],dl  ; 00100
    xor  edx,edx
    div  ebx
    add  dl,48
    add  al,48
    mov  [htext2+13],dl  ; 01000
    mov  [htext2+12],al  ; 10000


    mov  eax,[lines]     ; number of lines
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  dl,48
    mov  [htext2+31],dl  ; 0001
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [htext2+30],dl
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [htext2+29],dl  ; 0100
    xor  edx,edx
    div  ebx
    add  dl,48
    add  al,48
    mov  [htext2+28],dl
    mov  [htext2+27],al  ; 10000

    mov  eax,13      ; draw bar
    mov  ebx,5*65536+38*6
    mov  ecx,[dstart]
    shl  ecx,16
    mov  cx,15
    mov  edx,[w_work_graph]
    int  0x40

    mov  eax,dword 0x00000004    ; write position
    mov  ebx,12*65536
    mov  bx,word [dstart]
    add  bx,4
    mov  ecx,[w_work_button_text]
    mov  edx,htext2
    mov  esi,38
    int  0x40

    ; Scroll position

    mov  eax , [post]
    mov  ebx , 80
    xor  edx , edx
    div  ebx
    add  eax , 10000
    mov  [scrollv],eax
    call draw_scroll

    popa

    ret

; ****************************
; ******* READ STRING ********
; ****************************


read_string:

    cmp  ah,5
    jz   f1
    cmp  ah,51
    jz   f2
    ret

  f1:
    mov  [addr],dword filename
    mov  eax,[dstart]
    add  eax,17
    mov  [ya],eax
    mov  [case_sens],0
    jmp  rk
  f2:
    mov  [addr],dword search_string
    mov  eax,45 
    mov  [ya],eax
    mov  [case_sens],1

  rk:

    mov  edi,[addr]

    mov  eax,[addr]
    mov  eax,[eax-4]
    mov  [temp],eax

    add  edi,eax

    call print_text

  f11:
    mov  eax,10
    int  0x40
    cmp  eax,2
    jne  read_done
   ;mov  eax,2
    int  0x40
    shr  eax,8

    cmp  eax,13     ; enter
    je   read_done

    cmp  eax,192    ; Ctrl + space
    jne  noclear

    xor  eax,eax
    mov  [temp],eax
    mov  edi,[addr]
    mov  [edi-4],eax
    mov  ecx,49
    cld
    rep  stosb
    mov  edi,[addr]
    call print_text
    jmp  f11

noclear:

    cmp  eax,8      ; backspace
    jnz  nobsl
    cmp  [temp],0
    jz   f11
    dec  [temp]
    mov  edi,[addr]
    add  edi,[temp]
    mov  [edi],byte 0

    mov  eax,[addr]
    dec  dword [eax-4]

    call print_text
    jmp  f11

  nobsl:
    cmp  [temp],50
    jae  read_done

    cmp  eax,dword 31
    jbe  f11
    cmp  [case_sens],1
    je   keyok
    cmp  eax,dword 95
    jb   keyok
    add  eax,-32
   keyok:
    ;mov  [edi],al
    mov  edi,[addr]
    add  edi,[temp]
    mov  [edi],al

    inc  [temp]

    mov  eax,[addr]
    inc  dword [eax-4]
    call print_text

    cmp  [temp],50
    jbe  f11

  read_done:

;    mov ecx,[addr]
;    mov eax,[temp]
;    add eax,ecx    ; eax = [temp]+[addr]
;    add ecx,50
;    sub ecx,eax    ; ecx = [addr]+50-[temp]-[addr]
;    mov eax,0
;    inc edi
;    cld
;    rep stosb

 mov ecx,50
 sub ecx,[temp]
 mov edi,[addr]
 add edi,[temp]
 xor eax,eax
 cld
 rep stosb

    mov [temp],999

    call print_text

    ret

searchb equ 0xf0f0f0
searchx equ 118*65536

print_text:

    pusha

    mov  eax,13
    mov  ebx,64*65536+50*6+2
    cmp  [ya],dword 100
    ja   noups2
    add  ebx,searchx
  noups2:
    mov  ecx,[ya]
    shl  ecx,16
    add  ecx,12
    mov  edx,[w_work]
    cmp  [ya],dword 100
    ja   noups
    mov  edx,searchb
  noups:
    int  0x40

    mov  edx,[addr]
    mov  esi,[edx-4]
    mov  eax,4
    mov  ebx,65*65536+2
    add  ebx,[ya]
    cmp  [ya],dword 100
    ja   noups3
    add  ebx,searchx
  noups3:
    mov  ecx,[w_work_text]
    int  0x40

    cmp  [temp],50
    ja   @f

; draw cursor
; {
    mov  eax,[ya]
    mov  ebx,eax
    shl  eax,16
    add  eax,ebx
    add  eax,10
    mov  ecx,eax

    mov  eax,[temp]
    imul eax,eax,6
    add  eax,65
    cmp  [ya],dword 100
    ja   noups4
    mov  edx,searchx
    shr  edx,16
    add  eax,edx
  noups4:
    mov  ebx,eax
    shl  eax,16
    add  ebx,eax

    mov  eax,38
    mov  edx,[w_work_text]
    int  0x40
; }

@@:
    popa

    ret

  nof12:

    ret

; **********
; *  DATA  *
; **********

button1:

    db    'SAVE',0

button2:

    db    'LOAD',0

button3:

    db    'SEARCH',0

button4:

    db    'FILE >',0

button5:

    db    'STRING >',0

cursor  dd  0x3030f0

addr   dd  filename  ; address of the input string

filename_len    dd   17
filename        db   '/RD/1/EXAMPLE.ASM'
times 51-18     db   0

times 100 db 0

search_len      dd   19
search_string   db   'Enter search string'
times 51-19     db   0

case_sens    db   0

htext:
    db  ''
htextlen:

window_label:

    db  'TEXT EDITOR',0

menu_struct:               ; Menu Struct

    dq   0                 ; Version

    dq   0x2000            ; Start value of ID to return ( ID + Line )

                           ; Returned when menu closes and
                           ; user made no selections.

    db   0,'FILE',0        ; ID = 0x2000 + 1
    db   1,'Save Current',0; ID = 0x2000 + 2
    db   1,'-',0           ; ID = 0x2000 + 3
    db   1,'Quit',0        ; ID = 0x2000 + 4

    db   0,'SEARCH',0            ; ID = 0x2000 + 5
    db   1,'Commands..',0        ; ID = 0x2000 + 6
    db   1,'String (ctrl-F6)',0  ; ID = 0x2000 + 7
    db   1,'Search (ctrl-F3)',0  ; ID = 0x2000 + 8

    db   255               ; End of Menu Struct



searcht:
;<    db  ' STRING >                                '
;    db  '                                   SEARCH '
searchtl:

htext2:
    db  'Position 00:00000   Length 00000 lines  '
htextlen2:

savetext:
;    db  ' FILE  >                                '
;    db  '                                    LOAD '
savetextlen:

;htext3:
;    db   'GIVE NAME     LOAD FILE    EDIT TEXT   '
;    db   '                                       '
;htextlen3:

help_text:

    db  'COMMANDS:                                          '
    db  '                                                   '
    db  '  CTRL+I || CTRL+F1 : HELP SCREEN                  '
    db  '  CTRL+S  : SELECT FIRST STRING TO COPY            '
    db  '  CTRL+E  : SELECT LAST STRING TO COPY             '
    db  '  CTRL+P  : PASTE SELECTED TO CURRENT POSITION     '
    db  '  CTRL+D  : DELETE CURRENT LINE                    '
    db  '  CTRL+[  : GO TO THE BEGINNING OF FILE            '
    db  '  CTRL+]  : GO TO THE END OF FILE                  '
    db  '  CTRL+F2 : LOAD FILE                              '
    db  '  CTRL+F3 : SEARCH                                 '
    db  '  CTRL+F4 : SAVE FILE                              '
    db  '  CTRL+F5 : ENTER FILENAME                         '
    db  '  CTRL+F6 : ENTER SEARCH STRING                    '
    db  'x'

colors  db 0
I_PARAM db 0    ; параметры будут начинаться ЗДЕСЬ!

IMAGE_END:

align 32

posx   dd ?     ; x на экране
posy   dd ?     ; y на экране
post   dd ?     ; смещение от начала
posl   dd ?
lines  dd ?     ; количество строк в документе
posxm  dd ?
posym  dd ?

temp   dd ?     ; используется в drawwindow и read_string
dstart dd ?     ; смещение по оси y для отрисовки кнопок и др.

filesize dd ?   ; размер файла
ya       dd ?   ; для read_string
slines   dd ?   ; количество строк на экране
savetohd dd ?   ; временная переменная

copy_start dd ?
copy_count dd ?
headlen    dd ?

system_colours: ; системные цвета - 40 байтов
w_frame            dd ?
w_grab             dd ?
w_grab_button      dd ?
w_grab_button_text dd ?
w_grab_text        dd ?
w_work             dd ?
w_work_button      dd ?
w_work_button_text dd ?
w_work_text        dd ?
w_work_graph       dd ?

I_END:          ; header string - заголовок окна
rb 100
process_info:   ;<<

