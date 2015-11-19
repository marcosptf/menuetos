;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   M32 Example application
;
;   Compile with FASM for Menuet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use32

    org  0x0

    db   'MENUET01'             ; Header id
    dd   0x01                   ; Version
    dd   START                  ; Start of code
    dd   I_END                  ; Size of image
    dd   0x100000               ; Memory for app
    dd   0x7fff0                ; Esp
    dd   0x0,0x0                ; I_Param,I_Icon

START:                          ; Start of execution

    call draw_window

still:

    mov  eax,10                 ; Wait here for event
    int  0x40

    cmp  eax,1                  ; Redraw request
    je   red
    cmp  eax,2                  ; Key in buffer
    je   key
    cmp  eax,3                  ; Button in buffer
    je   button

    jmp  still

red:                            ; Redraw
    call draw_window
    jmp  still

key:                            ; Key
    mov  eax,2                  ; Just read it and ignore
    int  0x40
    jmp  still

button:                         ; Button
    mov  eax,17                 ; Get id
    int  0x40

    shr  eax , 8

    cmp  eax , 1                ; Button close
    jne  noclose
    mov  eax , -1
    int  0x40
  noclose:

    cmp  eax , 0x106            ; Menu close
    jne  noc
    mov  eax , -1
    int  0x40
  noc:

    jmp  still


draw_window:

    mov  eax,12                 ; Function 12: window draw
    mov  ebx,1                  ; Start of draw
    int  0x40

                                ; DRAW WINDOW ( Type 4 )
    mov  eax,0                  ; Function 0 : define and draw window
    mov  ebx,100*65536+300      ; [x start] *65536 + [x size]
    mov  ecx,100*65536+160      ; [y start] *65536 + [y size]
    mov  edx,0x04ffffff         ; Color of work area RRGGBB,8->color gl
    mov  esi,window_label       ; Pointer to window label (asciiz) or zero
    mov  edi,menu_struct        ; Pointer to menu struct or zero
    int  0x40

    mov  eax,4                  ; Draw info text
    mov  ebx,20*65536+70
    mov  ecx,0x000000
    mov  edx,text
    mov  esi,-1
    int  0x40

    mov  eax,12                 ; Function 12: window draw
    mov  ebx,2                  ; End of draw
    int  0x40

    ret


; DATA AREA

window_label:

    db   'EXAMPLE APPLICATION',0

text:

    db   'SYSTEM FUNCTIONS ARE IN FILE SYSFUNCS.TXT',0


menu_struct:               ; Menu Struct

    dq   0                 ; Version

    dq   0x100             ; Start value of ID to return ( ID + Line )

                           ; Returned when menu closes and
                           ; user made no selections.

    db   0,'FILE',0        ; ID = 0x100 + 1
    db   1,'New',0         ; ID = 0x100 + 2
    db   1,'Open..',0      ; ID = 0x100 + 3
    db   1,'Save..',0      ; ID = 0x100 + 4
    db   1,'-',0           ; ID = 0x100 + 5
    db   1,'Quit',0        ; ID = 0x100 + 6

    db   0,'HELP',0        ; ID = 0x100 + 7
    db   1,'Contents..',0  ; ID = 0x100 + 8
    db   1,'About..',0     ; ID = 0x100 + 9

    db   255               ; End of Menu Struct


I_END:




