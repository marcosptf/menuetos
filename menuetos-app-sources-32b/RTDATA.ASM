;
;   COMMUNICATING WITH MODEM: PORTS & IRQ
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


    mov  eax,45                 ; reserve irq 4
    mov  ebx,0
    mov  ecx,4
    int  0x40

    mov  eax,46                 ; reserve ports 0x3f8-0x3ff
    mov  ebx,0
    mov  ecx,0x3f8
    mov  edx,0x3ff
    int  0x40

    mov  eax,44                 ; read these ports at interrupt/irq 4
    mov  ebx,irqtable
    mov  ecx,4
    int  0x40

    mov  eax,40                 ; enable event for interrupt/irq 4
    mov  ebx,10000b shl 16 + 111b
    int  0x40

    call program_com1

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
    cmp  eax,16+4               ; data read by interrupt ?
    je   irq4

    jmp  still

  red:                          ; redraw
    call draw_window
    jmp  still

  key:                          ; key
    mov  eax,2                  ; just read it and ignore
    int  0x40

    mov  al,ah
    mov  dx,0x3f8
    out  dx,al

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

  irq4:

    mov  eax,42
    mov  ebx,4
    int  0x40

    ; eax = number of bytes left
    ; ecx = 0 success, =1 fail
    ; bl  = byte

    inc   [pos]
    and   [pos],31
    mov   eax,[pos]

    mov   [text+3*50+eax],bl
    call  draw_window

    jmp  still


baudrate_9600   equ 12
baudrate_57600  equ  2

program_com1:

    mov  dx,0x3f8+3
    mov  al,0x80
    out  dx,al

    mov  dx,0x3f8+1
    mov  al,0x00
    out  dx,al

    mov  dx,0x3f8+0
    mov  al,baudrate_9600
    out  dx,al

    mov  dx,0x3f8+3
    mov  al,0x3
    out  dx,al

    mov  dx,0x3f8+4
    mov  al,0xb
    out  dx,al

    mov  dx,0x3f8+1
    mov  al,0x1
    out  dx,al

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
    mov  ebx,100*65536+300         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+120         ; [y start] *65536 + [y size]
    mov  edx,0x04ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,window_label          ; color of grab bar  RRGGBB,8->color gl
    mov  edi,0                     ; color of frames    RRGGBB
    int  0x40

                                   ; CLOSE BUTTON
    mov  eax,8                     ; function 8 : define and draw button
    mov  ebx,(300-19)*65536+12     ; [x start] *65536 + [x size]
    mov  ecx,5*65536+12            ; [y start] *65536 + [y size]
    mov  edx,1                     ; button id
    mov  esi,0x6688dd              ; button color RRGGBB
    int  0x40

    mov  ebx,20*65536+35           ; draw info text with function 4
    mov  ecx,0x000000
    mov  edx,text
    mov  esi,50
  newline:
    mov  eax,4
    int  0x40
    add  ebx,10
    add  edx,50
    cmp  [edx],byte 'x'
    jne  newline

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


; DATA AREA


text:

    db 'TYPED CHARACTERS ARE SENT TO MODEM IN COM1.       '
    db 'DATA FROM MODEM IS READ BY IRQ4                   '
    db 'INTERRUPT AND DISPLAYED BELOW.                    '
    db '                                                  ' 

    db 'x <- END MARKER, DONT DELETE                      '

pos  dd  0x0


window_label:

     db   'RTDATA.ASM',0

irqtable:
       ; port    ; 1=byte, 2=word
  dd   0x3f8 +0x01000000   ; read byte from port 0x3f8 at interrupt/irq 4
  dd   0x0                 ; no more ports ( max 15 ) to read


I_END:




