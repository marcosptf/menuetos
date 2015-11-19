;
;   RD2HD
;
;   Compile with FASM for Menuet
;

use32

               org    0x0

               db     'MENUET01'              ; 8 byte id
               dd     0x01                    ; header version
               dd     START                   ; start of code
               dd     I_END                   ; size of image
               dd     0x300000                ; memory for app
               dd     0xfff0                  ; esp
               dd     0x0 , 0x0               ; I_Param , I_Icon

; 0x0fff0 - STACK
; 0x20000 - 1.4 Mb IMAGE

START:                          ; start of execution

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

    cmp  ah,'s'
    jne  still

    mov  esi,reading
    call print_text

    mov  ecx,0

  newread:

    mov  [fileinfo+4],ecx
    mov  eax,ecx
    imul eax,512
    add  eax,0x20000
    mov  [fileinfo+12],eax

    mov  eax,58
    mov  ebx,fileinfo
    int  0x40

    cmp  eax,0
    je   success_read

    mov  esi,read_failed
    call print_text

    jmp  success

  success_read:


    inc  ecx
    cmp  ecx,80*18*2
    jb   newread

    mov  esi,saving
    call print_text

    mov  eax,58
    mov  ebx,filesave
    int  0x40

    mov  esi,writefine
    call print_text

    cmp  eax,0
    je   success

    mov  esi,failed
    call print_text

  success:

    mov  eax,5
    mov  ebx,300
    int  0x40

    mov  esi,waiting
    call print_text

    jmp  still

  fileinfo:

    dd   8,0,1,0x20000,0x10000
    db   '/RD/1/',0

  filesave:

    dd  1,0,1474560,0x20000,0x10000
    db  '/HD/1/MENUET.IMG',0

  button:                       ; button
    mov  eax,17                 ; get id
    int  0x40

    cmp  ah,1                   ; button id=1 ?
    jne  noclose

    mov  eax,-1                 ; close this program
    int  0x40
  noclose:

    jmp  still

reading:     db 'Reading                      '
saving:      db 'Saving                       '
waiting:     db 'Waiting for command          '
failed:      db 'Write failed!                '
writefine:   db 'Write success!               '
read_failed: db 'Read failed!                 '


print_text:

    pusha

    mov  edi,text+40*4+6
    mov  ecx,19
    cld
    rep  movsb

    call draw_window

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
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,100*65536+270         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+140         ; [y start] *65536 + [y size]
    mov  edx,0x03ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,0x805080d0            ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0x005080d0            ; color of frames    RRGGBB
    int  0x40

                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x10ddeeff            ; font 1 & color ( 0xF0RRGGBB )
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40

                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,(300-19)*65536+12     ; [x start] *65536 + [x size]
    mov  ecx,5*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,0x6688dd              ; button color RRGGBB
;    int  0x40

    mov  ebx,20*65536+45           ; draw info text with function 4
    mov  ecx,0x224466
    mov  edx,text
    mov  esi,40
  newline:
    mov  eax,4
    int  0x40
    add  ebx,15
    add  edx,40
    cmp  [edx],byte 'x'
    jne  newline

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA


text:
    db ' 1) ENABLE LBA READ AND HD WITH SETUP   '
    db ' 2) PRESS <S> TO COPY RAMDISK AS:       '
    db '    /HD/1/MENUET.IMG                    '
    db '                                        '
    db '    ( WAITING FOR COMMAND )             '

    db 'x <- END MARKER, DONT DELETE            '


labelt:
    db   'RD2HD'
labellen:

I_END:



