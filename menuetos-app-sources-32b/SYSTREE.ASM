;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   SYSTREE BROWSER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use32

    org    0x0
    db     'MENUET01'              ; 8 byte id
    dd     0x01                    ; header version
    dd     START                   ; program start
    dd     I_END                   ; program image size
    dd     0x100000                ; required amount of memory
    dd     0x7f000                 ; stack
    dd     0x0,0x0                 ; param,icon

; 0x80000  pre-read area
; 0x20000  return area
; 0x10000  work area


diry  equ 66
dirys equ 202
locy  equ 47

START:                          ; start of execution

    call pre_read_directory
    call read_directory

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

    mov  eax,17
    int  0x40

    shr  eax , 8

    ; Menu quit

    cmp  eax , 504
    jne  no_menu_quit
    mov  eax , -1
    int  0x40
  no_menu_quit:

    ; Other menu selections

    cmp  eax , 500
    jb   no_menu
    cmp  eax , 520
    ja   no_menu
    jmp  still
  no_menu:

    ; Scroll

    cmp  eax , 1000
    jb   noscroll
    cmp  eax , 9999
    ja   noscroll
    mov  [scrollv],eax
    call draw_scroll
    mov  eax,[scrollv]
    sub  eax , 1000-1
    mov  [readblock],eax
    call read_directory
    call drawbuttons
    jmp  still
  noscroll:

    cmp  eax,1                   ; button id=1 ?
    jnz  noclose
    mov  eax,0xffffffff         ; close this program
    int  0x40
  noclose:

    shl  eax , 8

    cmp  ah,21
    jge  yesnewdir
    jmp  nonewdir
  yesnewdir:

    pusha
    mov  al,ah
    and  eax,255
    sub  eax,21
    xor  edx,edx
    mov  ebx,62
    mul  ebx
    mov  esi,eax
    add  esi,fileinfo+7

    cmp  [esi],word 'OL'
    jz   folok

    cmp  [esi+14],word 'XT'          ; show txt and asm files
    je   yeseditor
    cmp  [esi+14],word 'SM'
    je   yeseditor
    jmp  noeditor
  yeseditor:

    popa
    shr  eax,8
    sub  eax,21
    imul eax,32
    add  eax,data_area+1024
    mov  esi,eax
    mov  edi,param
    mov  ecx,11
    cld
    rep  movsb

    mov  eax,19
    mov  ebx,editor
    mov  ecx,param
    int  0x40

    jmp  still

  noeditor:
                               ; start application
    popa
    pusha

    mov  al,ah
    and  eax,255
    sub  eax,21
    xor  edx,edx
    mov  ebx,32
    mul  ebx
    mov  ebx,eax
    add  ebx,data_area+1024

    cmp  [location+1], word 'FD'
    jne  no_ramdisk_start
    mov  eax,19
    mov  ecx,0
    int  0x40
  no_ramdisk_start:

    cmp  [location+1], word 'HD'
    jne  no_harddisk_start

    mov  esi,ebx
    mov  edi,location+1
    add  edi,[loclen]
    mov  ecx,11
    cld
    rep  movsb

    mov  eax,31
    mov  ebx,location+24
    mov  ecx,[loclen]
    sub  ecx,12
    mov  edx,0x10000
    int  0x40

  no_harddisk_start:

    popa
    jmp  still


  folok:

    popa

    mov  al,ah
    and  eax,255
    sub  eax,21
    xor  edx,edx
    mov  ebx,32
    mul  ebx
    mov  esi,eax
    mov  edi,[loclen]
    add  edi,1
    add  esi,data_area+1024
    cmp  [esi],word '..'     ; if '..'
    jnz  chdir1
    mov  eax,[loclen]
    sub  eax,12
    mov  [loclen],eax
    mov  [readblock],dword 1
    jmp  readhd
  chdir1:
    cmp  [esi],byte '.'     ; if '.'
    jnz  chdir2
    jmp  still
  chdir2:

    add  edi,location
    mov  ecx,11
    cld
    rep  movsb

    mov  eax,[loclen]
    add  eax,12
    mov  [loclen],eax
    mov  [readblock],dword 1

  readhd:

    call pre_read_directory
    call read_directory
    call drawbuttons

    jmp  still

  nonewdir:

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
    mov  ebx,100*65536+407         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+306-223+dirys   ; [y start] *65536 + [y size]
    mov  edx,0x04ffffff            ; color of work area RRGGBB
    mov  esi,window_label          ; color of grab bar  RRGGBB,8->co
    mov  edi,menu_struct           ; color of frames    RRGGBB
    int  0x40

    ; Frames for files

    mov   eax , 38
    mov   ebx , 19 * 65536 + 387
    mov   ecx , (diry-1) * 65536 + (diry-1)
    mov   edx , 0x000000
    int   0x40
    mov   ecx , (diry+dirys) * 65536 + (diry+dirys)
    int   0x40
    mov   ebx , 19 * 65536 + 19
    mov   ecx , (diry-1) * 65536 + (diry+dirys)
    int   0x40

    call draw_scroll

    call drawbuttons

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret

draw_scroll:

    mov  eax , 113
    mov  ebx , 1 shl 16 + 375
    mov  ecx , diry shl 16 + dirys
    mov  edx , 1000
    mov  esi , [scrollsize]
    mov  edi , [scrollv]
    int  0x40

    ret

scrollsize: dd 100

scrollv: dd 1000

zeroentry: db 0

drawbuttons:

    ; Draw directory

    pusha
    mov  eax , 13
    mov  ebx , 19 * 65536 + 369
    mov  ecx , locy * 65536 + 11
    mov  edx , 0xe0e0e0
    int  0x40
    popa

    pusha
    mov  eax , 4
    mov  ebx , 21 * 65536 + (locy+2)
    mov  ecx , 0x000000
    mov  edx , root+12
    mov  edi , [loclen]
    inc  edi
  newdirchar:
    cmp  [edx],byte ' '
    jbe  skipchar
    mov  esi , 1
    int  0x40
    add  ebx , 6*65536
  skipchar:
    inc  edx
    dec  edi
    jnz  newdirchar
    popa

    ; Draw files

    pusha

    mov  ebx,20*65536+354
    mov  ecx,diry*65536+12
    mov  edx,21
    mov  esi,0x003344aa;0x6677cc

 newb:

    push edx
    mov  eax,8
    add  edx,0x80000000
    mov  edi,0
    int  0x40
    pop  edx
    push edx
    add  edx,0x40000000
    int  0x40
    pop  edx

    pusha
    sub  edx,21
    mov  esi,edx
    imul edx,12
    cmp  edx,[loclen]
    jg   no_dir_text
    mov  eax,4
    sub  ebx,125*65536
    shr  ecx,16
    mov  bx,cx
    add  bx,3
    shl  esi,2+16
    add  ebx,esi
    mov  ecx,0xffffff
    add  edx,root
    cmp  edx,root
    jne  no_yellow
    mov  ecx,0xffff00
  no_yellow:
    mov  esi,11
    mov  ecx,0x000000
;    int  0x40
  no_dir_text:
    popa

    pusha
    sub  edx,21
    mov  eax,edx
    xor  edx,edx
    mov  ebx,62
    mul  ebx
    add  eax,fileinfo
    mov  ebx,25*65536
    shr  ecx,16
    mov  bx,cx
    add  ebx,5*65536+3
    mov  ecx,0xffffff
    cmp  [eax+21],word 'SM'
    jnz  noasm
    mov  ecx,0x88ffff
  noasm:
    cmp  [eax+7],word 'OL'
    jnz  nofolt
    mov  ecx,0xffff00
  nofolt:
    cmp  [eax+7],word 'EL'
    jnz  nodelt
    mov  ecx,0x99aaee
  nodelt:
    mov  edx,eax
    mov  esi,49
    mov  eax,4
    mov  ecx,0x000000
    pusha
    mov  eax , 13
    mov  ecx , ebx
    shl  ecx , 16
    mov  bx  , 346
    sub  ebx , 6*65536
    mov  cx ,  8
    mov  edx , 0xffffff
    int  0x40
    popa
    sub  ebx , 3 * 65536
    add  esi , 5+3
    int  0x40
    popa

    add  ecx,(11*65536)
    inc  edx
    cmp  edx,37+4-2
    jnz  newb

    popa

    ret



fileinfoblock:

   dd 0x0       ; read
   dd 0x0       ; first block
   dd 0x1       ; number of blocks to read
   dd 0x20000   ; ret
   dd 0x10000   ; work
filedir:
   times 12*10 db 32



pre_read_directory:

    mov  edi , 0x80000
    mov  ecx , 0x70000
    mov  eax , 0
    cld
    rep  stosb

    mov  esi,location
    mov  edi,filedir
    mov  ecx,12*8
    cld
    rep  movsb

    mov  eax,[loclen]
    mov  [filedir+eax],byte 0

    mov  ecx , 0
  prdl1:
    mov  [fileinfoblock+4],ecx
    push ecx
    imul ecx , 512
    add  ecx , 0x80000
    mov  [fileinfoblock+12],ecx ; dword 0x80000
    pop  ecx
    mov  eax,58
    mov  ebx,fileinfoblock
    int  0x40

    cmp  [loclen],dword 20
    jb   read_error

    cmp  eax,0
    jne  read_error

    inc  ecx

    cmp  ecx , 100
    ja   read_error

    jmp  prdl1

  read_error:

    inc  ecx

    imul ecx , 16

    add  ecx , 32

    mov  [scrollsize],ecx

    cmp  [loclen],dword 5
    jb   nodotadd
    cmp  [0x80000],dword '..  '
    je   nodotadd
    cmp  [0x80000+32],dword '..  '
    je   nodotadd
    mov  esi , 0x80000    + 0x70000
    mov  edi , 0x80000+32 + 0x70000
    mov  ecx , 0x70000+32
    std
    rep  movsb

    mov  [0x80000],dword '..  '
    mov  [0x80000+11],byte 0x10

  nodotadd:

    and  [scrollsize],dword 0xfff

    mov   esi , 0x80000
    mov   ebp , 0
  newtest:
    cmp  [esi],byte 0
    je   remove_entry
    mov  al , [esi+11]
    and  al , 0xf
    cmp  al , 0xf
    je   remove_entry
    jmp  entry_fine
  remove_entry:
    push esi
    mov  edi , esi
    add  esi , 32
    mov  ecx , [scrollsize]
    add  ecx , 16
    sub  ecx , ebp
    imul ecx , 32
    cld
    rep  movsb
    pop  esi
    dec  dword [scrollsize]
    sub  esi , 32
  entry_fine:
    add  esi , 32
    inc  ebp
    mov  ecx , [scrollsize]
    cmp  ebp , ecx
    jbe  newtest

    ; Search first DEL

    mov   esi , 0x80000
    mov   ebp , 0
  newtest2:
    cmp  [esi],byte 0
    je   found_del
    add  esi , 32
    inc  ebp
    mov  ecx , [scrollsize]
    cmp  ebp , ecx
    jbe  newtest2
  found_del:

    mov  [scrollsize],ebp

    ; Alphabetical order

    mov  ebp , 0

  alpl3:

    mov  esi , [scrollsize]
    dec  esi
    imul esi , 32
    add  esi , 0x80000
    mov  edi , alphatemp
    mov  ecx , 32
    cld
    rep  movsb

    mov  ecx , 0

  alpl2:

    cmp  ecx , ebp
    jae  alpl1

    mov  esi , ecx
    shl  esi , 5

    mov  edi , 0

  asdfa:

    mov  al , [alphatemp + edi]
    cmp  al , [0x80000 + esi + edi]
    jb   alpl1
   ; cmp  al , [0x80000 + esi + edi]
    jne  asdf

    inc  edi
    cmp  edi , 11
    jb   asdfa

  asdf:

    inc  ecx
    jmp  alpl2

  alpl1:

    mov  esi , ecx
    shl  esi , 5
    add  esi , 0x80000
    push esi
    mov  edi , esi
    add  edi , 32
    mov  eax , [scrollsize]
    dec  eax
    shl  eax , 5
    add  eax , 0x80000
    sub  eax , esi
    add  esi , eax
    add  edi , eax
    mov  ecx , eax
    add  ecx , 32
    std
    rep  movsb
    mov  esi , alphatemp
    pop  edi
    mov  ecx , 32
    cld
    rep  movsb

    inc  ebp

    cmp  ebp , [scrollsize]
    jbe  alpl3

    mov  edi , [scrollsize]
    imul edi , 32
    add  edi , 0x80000
    mov  eax , 0
    mov  ecx , 32
    cld
    rep  stosb

    mov  [scrollv],dword 1000
    call draw_scroll

    ret


alphatemp: times 32 db 0


getblock:

    pusha

    mov  esi , eax
    dec  esi
    imul esi , 32
    add  esi , 0x80000
    mov  edi , 0x20000
    mov  ecx , 32*22
    cld
    rep  movsb

    popa

    ret


read_directory:

    mov  eax,[readblock]
    call getblock

    mov  [dirlen],ebx

    mov  esi,0x20000
    mov  edi,data_area+1024
    mov  ecx,512+300
    cld
    rep  movsb

    mov  ebx,1024

    ; command succesful

    mov  esi,data_area+1024
    mov  edi,fileinfo+11
    mov  edx,16+5

  newlineb:

    pusha               ; clear
    mov  al,32
    mov  ecx,58
    sub  edi,11
    cld
    rep  stosb
    popa

    mov  cl,[esi]       ; end of entries ?
    cmp  cl,6
    jnz  noib0
    mov  [edi-5],dword 'EOE '
    add  esi,32
    add  edi,62
    jmp  inf
  noib0:

    mov  cl,[esi+0]
    cmp  cl,0xe5
    je   yesdelfil

    mov  cl,[esi+11]    ; long fat32 name ?
    cmp  cl,0xf
    jnz  noib1

    mov  [edi-5],dword 'F32 '
    add  esi,32
    add  edi,62
    jmp  inf

  noib1:

    mov  eax,'DAT '     ; data or .. ?

    mov  cl,[esi+0]     ; deleted file
    cmp  cl,0xe5
    je   yesdelfil
    cmp  cl,0x0
    je   yesdelfil
    jmp  nodelfil
   yesdelfil:
    mov  eax,'DEL '
    add  esi , 32
    add  edi , 62
    jmp  inf
    jmp  ffile
  nodelfil:

    mov  cl,[esi+11]    ; folder
    and  cl,0x10
    jz   ffile
    mov  eax,'FOL '
    mov  [edi-5],eax
;    mov  [edi+45],byte '-'
;    jmp  nosize

  ffile:

    mov  [edi-5],eax

    pusha               ; size
    mov  eax,[esi+28]
    mov  esi,edi
    add  esi,37+2   - 12 + 6
    mov  ebx,10
    mov  ecx,12
  newnum:
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [esi],dl
    cmp  eax,0
    jz   zernum
    sub  esi,1
    loop newnum
  zernum:
    popa
  nosize:

    pusha               ; attributes
    mov  eax,[esi+11]
    mov  esi,edi
    add  esi,37+2   - 18
    mov  ebx,2
    mov  ecx,8
  newnum2:
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [esi],dl
    sub  esi,1
    loop newnum2
    popa


    pusha                    ; date
    add  edi , 15+ 6
    mov  [edi+17],dword '.  .'
    mov  [edi+21],dword '2002'

    mov  eax,[esi+24]
    and  eax,1111111000000000b
    shr  eax,9
    add  eax,1980
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  dl,48
    mov  [edi+24],dl
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [edi+23],dl
    xor  edx,edx
    div  ebx
    add  al , 48
    add  dl , 48
    mov  [edi+22],dl
    mov  [edi+21],al

    mov  eax,[esi+24]
    and  eax,11111b
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  al,48
    add  dl,48
    mov  [edi+15],al
    mov  [edi+16],dl

    mov  eax , [esi+24]
    and  eax , 0000000111100000b
    shr  eax , 5
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  al,48
    add  dl,48
    mov  [edi+18],al         ; month
    mov  [edi+19],dl
    popa


    pusha                    ; number
    mov  ecx,17+5
    sub  ecx,edx
    mov  eax,[readblock]
    sub  eax,1
    add  eax,ecx
    xor  edx,edx
    mov  ebx,10
    div  ebx
    add  dl,48
    mov  [edi-8],dl          ;0001
    xor  edx,edx
    div  ebx
    add  dl,48
    mov  [edi-9],dl          ;0010
    xor  edx,edx
    div  ebx
    add  al,48
    add  dl,48
    mov  [edi-10],dl         ;0100
    mov  [edi-11],al         ;1000
    popa

    mov  ecx,8          ; first 8
    cld
    rep  movsb
    mov  [edi],byte '.'
    add  edi,1
    mov  ecx,3          ; last 3
    cld
    rep  movsb

    add  esi,(32-11)
    add  edi,(60-12+2)

  inf:

    sub  edx,1
    cmp  edx,0
    jnz  newlineb

    ret


hd_read_error:

    cmp  eax,1
    jnz  la1
    mov  edx,nodef
    mov  esi,50
  la1:
    cmp  eax,2
    jnz  la2
    mov  esi,nosup
    mov  edi,data_area+8
    mov  ecx,50
    cld
    rep  movsb
    mov  edx,data_area
    mov  esi,8+50
  la2:
    cmp  eax,3
    jnz  la3
    mov  esi,unknw
    mov  edi,data_area+8
    mov  ecx,50
    cld
    rep  movsb
    mov  edx,data_area
    mov  esi,8+50
  la3:
    cmp  eax,4
    jnz  la4
    mov  edx,xpart
    mov  esi,50
  la4:
    cmp  eax,5
    jnz  la5
    mov  edx,eof
    mov  esi,50
    dec  dword [readblock]
    add  [loclen],dword 12

  la5:
    cmp  eax,6
    jnz  la6
    mov  edx,fnf
    mov  esi,50
  la6:

    mov  eax,4
    mov  ebx,70*65536+(diry+dirys+5)
    mov  ecx,0x00000000
    int  0x40

    sub  [loclen],dword 12
    jmp  read_directory



; DATA AREA


dirlen    dd   0x1
b_color   dd   0x6677cc
editor    db   'TINYPAD    '
param     db   '           ',0
text      db   '/                       '
up        db   0x18
down      db   0x19
xx        db   'x'
loclen    dd  0
readblock dd  1

window_label:

     db   'FILE BROWSER',0

root      db   'ROOTDIR     '


location:

          db    '/           /           /           /           '
          db    '/           /           /           /           '
          db    '/           /           /           /           '
          db    '/           /           /           /           '
          db    '/           /           /           /           '
          db    '/           /           /           /           '
          db    '/           /           /           /           '
          db    '/           /           /           /           '

fileinfo:

    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '
    db   '  00               .     10.20  01.01.00                      '


nodef   db   'NO HD BASE AND/OR FAT32 PARTITION DEFINED.         '
xpart   db   'INVALID PARTITION AND/OR HD BASE                   '
nosup   db   '<- FS, NO SUPPORT YET                              '
unknw   db   '<- UNKNOWN FS                                      '
eof     db   'END OF FILE                                        '
fnf     db   'FILE NOT FOUND                                     '

menu_struct:

    dq   0
    dq   500

    db   0,'FILE',0
    db   1,'Open ..',0
    db   1,'-',0
    db   1,'Quit',0

    db   255

data_area:

I_END:




