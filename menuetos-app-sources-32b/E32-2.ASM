;
;   EXAMPLE APPLICATION
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
    jmp  still

  button:                       ; button
    mov  eax,17                 ; get id
    int  0x40

    shr  eax , 8

    cmp  eax , 1                  ; Close application button
    jne  noclose
    mov  eax , -1
    int  0x40
  noclose:

    cmp  eax , 0x106              ; Menu close application
    jne  noc
    mov  eax , -1
    int  0x40
  noc:

    cmp  eax , 1000              ; Scroll bar
    jb   noscroll
    cmp  eax , 1000+200
    ja   noscroll
    mov  [scroll_value],eax
    call draw_scroll
    jmp  still
  noscroll:

    cmp  eax , 2000              ; Scroll bar
    jb   noscroll2
    cmp  eax , 2000+200
    ja   noscroll2
    mov  [scroll_value2],eax
    call draw_scroll2
    jmp  still
  noscroll2:

    cmp  eax , 10
    jne  no_clickme_button
    mov  eax , 67
    mov  ebx , [windowx]
    add  ebx , 32
    and  ebx , 63
    mov  [windowx],ebx
    add  ebx ,100
    mov  ecx , -1
    mov  edx , -1
    mov  esi , -1
    int  0x40
    jmp  still
  no_clickme_button:

    jmp  still

windowx: dd 0x0

;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,1                     ; 1, start of draw
    int  0x40

                                   ; DRAW WINDOW ( Type 4 )
    mov  eax,0                     ; function 0 : define and draw window
    mov  ebx,100*65536+300         ; [x start] *65536 + [x size]
    mov  ecx,100*65536+260         ; [y start] *65536 + [y size]
    mov  edx,0x04ffffff            ; color of work area RRGGBB,8->color gl
    mov  esi,window_label          ; pointer to window label (asciiz) or zero
    mov  edi,menu_struct           ; pointer to menu struct or zero
    int  0x40

    mov  eax , 8
    mov  ebx ,  50 * 65536 + 70
    mov  ecx ,  80 * 65536 + 18
    mov  edx , 10
    mov  esi , 0x10000000
    mov  edi , button_label
    int  0x40

    call draw_scroll

    call draw_scroll2

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    int  0x40

    ret


draw_scroll:

    mov   eax , 113
    mov   ebx , 001 shl 16 + 260
    mov   ecx , 060 shl 16 + 160
    mov   edx , 1000
    mov   esi , 200
    mov   edi , [scroll_value]
    int   0x40

    ret


draw_scroll2:

    mov   eax , 113
    mov   ebx , 002 shl 16 + 220
    mov   ecx , 030 shl 16 + 210
    mov   edx , 2000
    mov   esi , 200
    mov   edi , [scroll_value2]
    int   0x40

    ret



; DATA AREA


text:

    db   'THIS IS AN EXAMPLE PROGRAM YOU COULD    '
    db   'USE, A:\EXAMPLE.ASM  CODE IS COMMENTED  '
    db   'AND CLEAR. SYSTEM FUNCTIONS ARE IN FILE '
    db   'SYSFUNCS.TXT                            '

    db   'x <- END MARKER, DONT DELETE            '

scroll_value:

    dd   1000+100

scroll_value2:

    dd   2000+100

button_label:

    db   'CLICK ME',0

window_label:

    db   'EXAMPLE APPLICATION',0

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




