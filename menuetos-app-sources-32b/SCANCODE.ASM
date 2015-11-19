;
;   KEYBOARD SCANCODE EXAMPLE
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

    mov  eax,66    ; keyboard mode definitions
    mov  ebx,1     ; set
    mov  ecx,1     ; return scancodes
    int  0x40

    mov  eax,26    ; get setup for keyboard
    mov  ebx,2
    mov  ecx,1     ; base keymap
    mov  edx,keymap
    int  0x40

    call draw_window

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

    mov  esi,scan_codes+1
    mov  edi,scan_codes+0
    mov  ecx,15
    cld
    rep  movsb

    mov  esi,key_codes+12
    mov  edi,key_codes+0
    mov  ecx,15*12
    cld
    rep  movsb

    shr  eax,8                   ; scancode
    and  eax,0xff
    mov  [scan_codes+15],al

    mov  [key_codes+15*12+8],dword 'Down'
    cmp  eax,128
    jb   no_up
    mov  [key_codes+15*12+8],dword 'Up  '
  no_up:

    mov    ebx,eax
    and    ebx,0x7f

    movzx  edx,byte [keymap+ebx]  ; key from keymap
    mov    [key_codes+15*12+0],edx
    mov    [key_codes+15*12+4],dword '    '

    movzx  edx,byte [ext]
    shl    edx,8
    add    ebx,edx

    mov    esi,ext0-10
  new_ext0:
    add    esi,10
    cmp    esi,ext0end
    jg     exit_ext0
    movzx  edx,word [esi]
    cmp    edx,ebx
    jne    new_ext0
    mov    edx,[esi+2]
    mov    [key_codes+15*12+0],edx
    mov    edx,[esi+6]
    mov    [key_codes+15*12+4],edx
  exit_ext0:
  no_ext_off:

    cmp  [ext2],0
    je   noext2dec
    dec  [ext2]
    cmp  [ext2],0
    jne  noext2dec
    mov    [key_codes+15*12+0],dword '----'
    mov    [key_codes+15*12+4],dword '----'
  noext2dec:

    mov  [ext],0

    cmp  eax,224
    jne  no_ext
    mov  [key_codes+15*12+0],dword '    '
    mov  [key_codes+15*12+4],dword '    '
    mov  [key_codes+15*12+8],dword 'Ext '
    mov  [ext],1
  no_ext:

    cmp  eax,225
    jne  no_ext2
    mov  [key_codes+15*12+0],dword '    '
    mov  [key_codes+15*12+4],dword '    '
    mov  [key_codes+15*12+8],dword 'Ext2'
    mov  [ext],2
    mov  [ext2],2
  no_ext2:


    call draw_codes

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
    mov  ebx,100*65536+200         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+275         ; [y start] *65536 + [y size]
    mov  edx,0x04ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,window_label          ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0                     ; color of frames    RRGGBB
    int  0x40

                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,(200-19)*65536+12     ; [x start] *65536 + [x size]
    mov  ecx,5*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,0x6688dd              ; button color RRGGBB
    int  0x40

    mov  ebx,20*65536+35           ; draw info text with function 4
    mov  ecx,0x000000
    mov  edx,text
    mov  esi,40
    mov  eax,4
    int  0x40

    call draw_codes

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


draw_codes:

    mov  eax,47
    mov  ebx,6*65536
    mov  edx,20*65536+60
    mov  edi,0
    mov  esi,0x000000
  newscan:
    pusha
    mov  cx,dx
    shl  ecx,16
    add  ecx,10
    mov  eax,13
    mov  ebx,20*65536+160
    mov  edx,0xffffff
    int  0x40
    popa
    pusha
    mov  ebx,edx
    add  ebx,70*65536
    mov  eax,4
    mov  ecx,0x000000
    mov  edx,key_codes
    imul edi,12
    add  edx,edi
    mov  esi,12
    int  0x40
    popa
    movzx  ecx,byte [scan_codes+edi]
    int  0x40
    add  ecx,1
    add  edx,12
    inc  edi
    cmp  edi,16
    jne  newscan

    ret


; DATA AREA

ext0:

    db    1,0,'Esc     '
    db   28,0,'Enter   '
    db   29,0,'L-Ctrl  '
    db   41,0,'1/2     '
    db   42,0,'L-Shift '
    db   54,0,'R-Shift '
    db   55,0,'Num *   '
    db   56,0,'Alt     '
    db   58,0,'CapsLck '
    db   59,0,'F1      '
    db   60,0,'F2      '
    db   61,0,'F3      '
    db   62,0,'F4      '
    db   63,0,'F5      '
    db   64,0,'F6      '
    db   65,0,'F7      '
    db   66,0,'F8      '
    db   67,0,'F9      '
    db   68,0,'F10     '
    db   69,0,'NumLock '
    db   70,0,'SclLock '
    db   71,0,'Num 7   '
    db   72,0,'Num 8   '
    db   73,0,'Num 9   '
    db   74,0,'Num -   '
    db   75,0,'Num 4   '
    db   76,0,'Num 5   '
    db   77,0,'Num 6   '
    db   78,0,'Num +   '
    db   79,0,'Num 1   '
    db   80,0,'Num 2   '
    db   81,0,'Num 3   '
    db   82,0,'Num 0   '
    db   83,0,'Num ,   '
    db   87,0,'F11     '
    db   88,0,'F12     '

    db   28,1,'Num Ent '
    db   29,1,'R-Ctrl  '
    db   53,1,'Num /   '
    db   55,1,'PrScr   '
    db   56,1,'Alt Gr  '
    db   71,1,'Home    '
    db   72,1,'Up-A    '
    db   73,1,'PgUp    '
    db   75,1,'Left-A  '
    db   77,1,'Right-A '
    db   79,1,'End     '
    db   80,1,'Down-A  '
    db   81,1,'PgDown  '
    db   82,1,'Insert  '
    db   83,1,'Delete  '
    db   91,1,'Menu-1  '
    db   92,1,'Menu-2  '
    db   93,1,'Menu-3  '

    db   29,2,'Break   '

ext0end:


text:
    db 'DIRECT KEYBOARD DATA                    '


window_label:

    db   'SCANCODES',0


ext  db 0x0
ext2 db 0x0

pos dd 0x0

scan_codes: times 16 db 0

key_codes:  times 16 dd 0,0,0

keymap:

I_END:




