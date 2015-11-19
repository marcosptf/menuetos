;
;    END
;
;    Ok, this is the sceleton that MENUET 0.38 understands.
;    Do not change the header bits for now. Compile with fasm.
;

use32

              org     0x0
              db      'MENUET00'              ; 8 byte id
              dd      38                      ; required os
              dd      START                   ; program start
              dd      I_END                   ; program image end
              dd      0x100000                ; reguired amount of memory
              dd      0x00000000              ; reserved=no extended header


START:

    call  draw_window

still:

    mov  eax,10                 ; wait here for event
    int  0x40

    cmp  eax,1
    jz   red
    cmp  eax,2
    jz   key
    cmp  eax,3
    jz   button

    jmp  still

  red:
    call draw_window
    jmp  still

  key:
    mov  eax,2
    int  0x40

    jmp  still

  button:

    mov  eax,17
    int  0x40

    cmp  ah,3
    jz   boot

    mov  eax,0xffffffff ; close this program
    int  0x40

    ; end of program

  boot:

    mov  eax,18    ; system boot
    mov  ebx,1
    int  0x40

    mov  eax,0xffffffff ; close this program
    int  0x40


draw_window:

    pusha

    mov  eax,48
    mov  ebx,3
    mov  ecx,I_END
    mov  edx,40
    int  0x40

    mov  eax,12                    ; tell os about redraw start
    mov  ebx,1
    int  0x40

    mov  eax,14                    ; get screen max x & max y
    int  0x40

    shr  eax,17
    sub  eax,93
    shl  eax,16
    mov  ebx,eax
    add  ebx,186

    mov  eax,0                     ; define and draw window
    mov  ecx,190*65536+85
    mov  edx,0x04ffffff
    mov  esi,window_label ; [I_END+24]
    mov  edi,0
    int  0x40

    mov  eax,8
    mov  ebx,26*65536+60           ; button start x & size
    mov  ecx,47*65536+15           ; button start y & size
    mov  edx,3                     ; button number
    mov  esi,0x10000000
    mov  edi,button_label_1
    int  0x40

    mov  eax,8
    mov  ebx,98*65536+60           ; button start x & size
    mov  ecx,47*65536+15           ; button start y & size
    mov  edx,2                     ; button number
    mov  esi,0x10000000
    mov  edi,button_label_2
    int  0x40

    mov  eax,12                    ; tell os about redraw end
    mov  ebx,2
    int  0x40

    popa

    ret

window_label:

     db   'EXIT MENUET',0

button_label_1:

    db   'YES',0

button_label_2:

    db   'NO',0

I_END:





