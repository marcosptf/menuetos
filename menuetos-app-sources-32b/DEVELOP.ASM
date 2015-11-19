;
;    DEVELOPER INFO - Compile with fasm
;
   
use32
   
                  org    0x0
                  db     'MENUET00'              ; 8 byte id
                  dd     38                      ; required os
                  dd     START                   ; program start
                  dd     I_END                   ; program image size
                  dd     0x100000                ; required amount of memory
                                                 ; esp = 0x7fff0
                  dd     0x00000000              ; reserved=no extended header
   
START:                          ; start of execution
   
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
   
    cmp  ah,1                   ; button id=1 ?
    jnz  noclose
    mov  eax,0xffffffff         ; close this program
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
    mov  ebx, 50*65536+365         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+260         ; [y start] *65536 + [y size]
    mov  edx,0x03ffffff            ; color of work area RRGGBB
    mov  esi,0x8099bbff            ; color of grab bar  RRGGBB,8->color glide
    mov  edi,0x0099bbee            ; color of frames    RRGGBB
    int  0x40
   
                                   ; WINDOW LABEL
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,8*65536+8             ; [x start] *65536 + [y start]
    mov  ecx,0x00ffffff            ; color of text RRGGBB
    mov  edx,labelt                ; pointer to text beginning
    mov  esi,labellen-labelt       ; text length
    int  0x40
   
    mov  ebx,20*65536+35           ; draw info text with function 4
    mov  ecx,0x000000
    mov  edx,text
    mov  esi,60
  newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,60
    cmp  [edx],byte 'x'
    jnz  newline
   
    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40
   
    ret
   
   
; DATA AREA
   
text:
    db ' HOW TO MODIFY & RUN EXAMPLE.ASM UNDER MENUET               '
    db '                                                            '
    db ' 1) EDIT FILE WITH TEXT EDITOR & SAVE->RAMDISK              '
    db ' 2) COMPILE & RUN WITH FASM FOR MENUET                      '
    db ' 3) SAVE RAMDISK TO FLOPPY AT MENUET EXIT                   '
    db '    OR SAVE RESULT TO A FAT32 PARTITION                     '
    db '                                                            '
    db ' SYSFUNCS.TXT - SYSTEM FUNCTIONS FOR APPLICATIONS           '
    db ' ASM     .TXT - SHORT INTRO TO ASSEMBLY PROGRAMMING         '
    db '                                                            '
    db '                                                            '
    db ' HOW TO MODIFY AND COMPILE KERNEL                           '
    db '                                                            '
    db ' 1) EDIT KERNEL.ASM WITH TEXT EDITOR AND SAVE               '
    db ' 2) COMPILE KERNEL.ASM TO KERNEL.MNT                        '
    db ' 3) SAVE RAMDISK TO FLOPPY AT MENUET EXIT                   '
    db ' 4) BOOT, AND YOU WILL HAVE A NEW KERNEL RUNNING            '
    db '                                                            '
    db ' YOU CAN ALSO EDIT AND COMPILE THE KERNEL UNDER DOS         '
    db ' OR COMPATIBLE SYSTEM. USE FASM 1.30                        '
    db 'x                                                           '
   
labelt:
    db   'DEVELOPER INFO'
labellen:
   
I_END:
   
   
   
   