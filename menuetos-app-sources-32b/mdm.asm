;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   M32 opened menu
;
;   Copyright 2015 Ville Turjanmaa
;
;   Compile with FASM for Menuet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use32

    org  0x0

    db	 'MENUET01'		; Header id
    dd	 0x01			; Version
    dd	 START			; Start of code
    dd	 I_END			; Size of image
    dd	 0x100000		; Memory for app
    dd	 0x7fff0		; Esp
    dd	 param,0x0		; I_Param,I_Icon

row equ 34

; 0x10000 work area
; 0x20000 mpanel.dat
; 0x30000 image

START:				; Start of execution

    mov  eax , 58
    mov  ebx , loadlist
    int  0x40

    mov  esi , 0x20000
    mov  edi , param+12
  newp:
    mov  al  , [esi]
    cmp  al  , '#'
    jne  norem
  newrem:
    add  esi , 1
    cmp  [esi],byte 13
    jne  newrem
  norem:
    mov  bl  , [edi]
    cmp  al  , bl
    jne  nothispos
    add  edi , 1
    cmp  [esi+1],byte ']'
    jne  noposfound
    cmp  [edi],byte '.'
    je	 posfound
  noposfound:
    add  esi , 1
    jmp  newp
  nothispos:
    mov  edi , param+12
    add  esi , 1
    cmp  esi , 0x20000+16000
    jb	 newp
    ; not found
    mov  eax , -1
    int  0x40
  posfound:
    add  esi , 1
    cmp  [esi-1],byte 10
    jne  posfound
    mov  [beginning],esi

    mov  eax , 0
    mov  edi , pointers
  newcount:
    cmp  [esi],byte ','
    jne  nocomma
    mov  [esi],byte 0
  nocomma:
    cmp  [esi], byte 10
    jne  nocount
    cmp  [esi+1],byte '#'
    je	 nocount
    cmp  [esi+1],byte ' '
    jb	 countfound
    add  esi , 1
    mov  [edi],esi
    add  edi , 4
    add  eax , 1
  nocount:
    add  esi , 1
    jmp  newcount
  countfound:
    mov  [paramcount],eax
    mov  [edi],dword 0

    mov  eax , 14
    int  0x40
    mov  [screeny],ax
    shr  eax , 16
    mov  [screenx],ax

    movzx eax , byte [param]
    sub   eax , 'A'
    imul  eax , 131
    add   eax , 1
    mov   [startx],eax

    movzx eax , byte [param+1]
    sub   eax , 'A'
    imul  eax , row
    mov   ebx , [screeny]
    sub   ebx , 30 ; downward menu y size
    sub   ebx , eax
    mov   ecx , [paramcount]
    imul  ecx , row
    add   ecx , 4
    sub   ebx , ecx ; window height
    mov   [starty],ebx
    mov   [sizey],ecx

    call  draw_window

    mov   eax , 60
    mov   ebx , 1
    mov   ecx , ipcarea
    mov   edx , 20
    int   0x40

    mov   eax , 9
    mov   ebx , process_info
    mov   ecx , -1
    int   0x40

    mov   eax , [process_info+30]
    mov   edi , menuparam+10
  newpid:
    xor   edx , edx
    mov   ebx , 10
    div   ebx
    add   dl  , 48
    mov   [edi], dl
    sub   edi , 1
    cmp   edi , menuparam+3
    ja	  newpid

still:

    mov  eax,23 		; Wait here for event
    mov  ebx,5
    int  0x40

    cmp  eax,1			; Redraw request
    je	 red
    cmp  eax,2			; Key in buffer
    je	 key
    cmp  eax,3			; Button in buffer
    je	 button

    cmp  [ipcarea+8],byte 0
    je	 still

    jmp  terminate


red:				; Redraw
    call draw_window
    jmp  still

key:				; Key
    mov  eax,2			; Just read it and ignore
    int  0x40

    jmp  terminate


button: 			; Button
    mov  eax,17 		; Get id
    int  0x40

    shr  eax , 8

    cmp  eax , 100
    jb	 nostart
    cmp  eax , 150
    ja	 nostart
    sub  eax , 100
    mov  ebp , eax
    mov  esi , [pointers+ebp*4]
  nofirstz:
    add  esi , 1
    cmp  [esi],byte 0
    jne  nofirstz
  nosecondz:
    add  esi , 1
    cmp  [esi],dword 'MENU'
    je	 startnewmenu
    cmp  [esi],byte 0
    jne  nosecondz
  nothirdz:
    add  esi , 1
    cmp  [esi],byte 0
    jne  nothirdz
  nostartp:
    add  esi , 1
    cmp  [esi],byte ' '
    jbe  nostartp
    mov  edi , filestart+4*5
  newtextc:
    mov  al  , [esi]
    cmp  al  , ' '
    jbe  textcdone
    mov  [edi],al
    add  edi , 1
    add  esi , 1
    jmp  newtextc
  textcdone:
    mov  [edi],byte 0
    mov  eax , 58
    mov  ebx , filestart
    int  0x40
;    jmp  still
    jmp  terminate
  nostart:

    jmp  still


terminate:

    call send_term_to_parent
    call send_term_to_child

    mov  eax , -1
    int  0x40


startnewmenu:

    call  send_term_to_child

    mov   eax , ebp
    mov   bl  , [paramcount]
    sub   bl  , al
    add   bl  , 'A'-1
    mov   al  , [param+1]
    sub   al  , 'A'
    add   bl  , al
    mov   [menuparam+1],bl

    mov   al , [param]
    add   al , 1
    mov   [menuparam],al

  nosecondz2:
    add  esi , 1
    cmp  [esi],byte 0
    jne  nosecondz2
  nothirdz2:
    add  esi , 1
    cmp  [esi],byte 0
    jne  nothirdz2
  nostartp2:
    add  esi , 1
    cmp  [esi],byte ' '
    jbe  nostartp2
    mov  edi , menuparam+12
  newtextc2:
    mov  al  , [esi]
    cmp  al  , ' '
    jbe  textcdone2
    mov  [edi],al
    add  edi , 1
    add  esi , 1
    jmp  newtextc2
  textcdone2:
    mov   [edi],byte '.'
    mov   [edi+1],byte 0

    mov   eax , 58
    mov   ebx , newmenu
    int   0x40

    mov   ecx , eax
    mov   eax , 9
    mov   ebx , process_info
    int   0x40
    mov   eax , [process_info+30]
    mov   [childpid],eax

    jmp   still


send_term_to_parent:

    cmp   [ipcarea+8],byte 't'
    je	  noparent

    mov   esi , param+3
    mov   ebx , 0
  newterm:
    xor   eax , eax
    mov   al  , [esi]
    cmp   al  , '.'
    je	  term1
    sub   al  , '0'
    imul  ebx , 10
    add   ebx , eax
    add   esi , 1
    jmp   newterm
  term1:

    cmp   ebx , 0
    je	  noparent

    mov   ecx , ebx
    mov   eax , 60
    mov   ebx , 2
    mov   edx , ipcterm
    mov   esi , 1
    mov   edi , 1
    int   0x40

  noparent:

    ret


send_term_to_child:

    pusha

    cmp   [childpid],dword 0
    je	  nosendch

    mov   eax , 60
    mov   ebx , 2
    mov   ecx , [childpid]
    mov   edx , ipcterm2
    mov   esi , 1
    mov   edi , 1
    int   0x40

    mov   [childpid],dword 0

  nosendch:

    popa
    ret


draw_window:

    mov  eax,12 		; Function 12: window draw
    mov  ebx,1			; Start of draw
    int  0x40

				; DRAW WINDOW ( Type 4 )
    mov  eax , 0		; Function 0 : define and draw window
    mov  ebx , [startx]
    shl  ebx , 16
    add  ebx , 130
    mov  ecx , [starty]
    shl  ecx , 16
    add  ecx , [sizey]
    mov  edx , 0x01ffffff	; Color of work area RRGGBB,8->color gl
    mov  esi , 0x01000000	; Pointer to window label (asciiz) or z
    mov  edi , 0		; Pointer to menu struct or zero
    int  0x40

    mov  eax , 8
    mov  ebx , 0 shl 16 + 130
    mov  ecx , 3 shl 16 + row-3
    mov  edx , 0
    mov  esi , 0xd0d0d0
  newbutton:
    add  edx , 100 + 1 shl 29
    int  0x40
    sub  edx , 100 + 1 shl 29
    add  edx , 1
    add  ecx , row shl 16
    cmp  edx , [paramcount]
    jb	 newbutton

    mov  eax , 38
    mov  ebx , 0 shl 16 + 130
    mov  ecx , 0 shl 16 + 0
  newline:
    mov  edx , 0xd0d0d0
    int  0x40
    add  ecx , 1 shl 16 + 1
    cmp  cx  , [sizey]
    jbe  newline

    mov  eax , 38
    mov  ebx , 0 shl 16 + 130
    mov  ecx , 0 shl 16 + 0
    mov  edx , 0xffffff
    int  0x40
    mov  eax , 38
    mov  ebx , 0 shl 16 + 0
    mov  ecx , [sizey]
    mov  edx , 0xffffff
    int  0x40
    mov  eax , 38
    mov  ebx , 130 shl 16 + 130
    mov  ecx , [sizey]
    mov  edx , 0xb0b0b0
    int  0x40
    mov  eax , 38
    mov  ebx , 0 shl 16 + 130
    mov  ecx , [sizey]
    sub  ecx , 1
    shl  ecx , 16
    add  ecx , [sizey]
    sub  ecx , 1
    mov  edx , 0xb0b0b0
    int  0x40

    mov  edi,pointers
    mov  eax,4			; Draw info text
    mov  ebx,50*65536+12+4
    mov  ecx,0x000000
    mov  esi,-1
  newtext:
    mov  edx,[edi]
    int  0x40
    add  ebx , row
    add  edi , 4
    cmp  [edi],dword 0
    jne  newtext

    mov  edx,pointers
    mov  ebp,0
  newimage:
    mov  esi,[edx]
  sc1:
    add  esi , 1
    cmp  [esi],byte 0
    jne  sc1
  sc2:
    add  esi , 1
    cmp  [esi],byte 0
    jne  sc2
  sc3:
    add  esi , 1
    cmp  [esi],byte ' '
    jbe  sc3
    mov  edi , loadicon+4*5
  sc5:
    mov  al  , [esi]
    cmp  al  , 32
    jbe  sc4
    mov  [edi],al
    add  edi , 1
    add  esi , 1
    jmp  sc5
  sc4:
    mov  [edi],byte 0
    mov  eax , 58
    mov  ebx , loadicon
    int  0x40
    push edx
    mov  eax , 0
    mov  ebx , 0
  sc10:
    mov  ecx , 32
    sub  ecx , ebx
    imul ecx , 32
    add  ecx , eax
    imul ecx , 3
    add  ecx , 0x30000+150-3*32*2
    mov  edx , [ecx]
    and  edx , 0xffffff
    cmp  edx , 0
    jne  sc11
    mov  edx , 0xd0d0d0
  sc11:
    mov  ecx , ebx
    imul ecx , 32
    add  ecx , eax
    imul ecx , 3
    add  ecx , 0x40000
    mov  [ecx],edx
    add  eax , 1
    cmp  eax , 32
    jb	 sc10
    mov  eax , 0
    add  ebx , 1
    cmp  ebx , 32
    jb	 sc10
    pop  edx
    push edx
    mov  eax , 7
    mov  ebx , 0x40000
    mov  ecx , 32 shl 16 + 32
    mov  edx , ebp
    imul edx , row
    add  edx , 7 shl 16 + 3
    int  0x40
    pop  edx
    add  edx , 4
    add  ebp , 1
    cmp  ebp , [paramcount]
    jb	 newimage

  nopic:

    mov  eax,12 		; Function 12: window draw
    mov  ebx,2			; End of draw
    int  0x40

    ret


; DATA AREA

loadlist:

    dd	 0
    dd	 0
    dd	 -1
    dd	 0x20000
    dd	 0x10000
    db	 '/rd/1/mpanel.dat',0

loadicon:

    dd	 0
    dd	 0
    dd	 -1
    dd	 0x30000
    dd	 0x10000
    times 256 db 0

childpid: dq 0x0

ipcterm:
	  db 'T',0
ipcterm2:
	  db 't',0

newmenu:

    dd	  16
    dd	  0
    dd	  menuparam
    dd	  0
    dd	  0x10000
    db	  '/rd/1/mdm',0

menuparam: db 'BC.00000000.SUBMENU0.',0

filestart:

    dd	  16
    dd	  0
    dd	  0
    dd	  0
    dd	  0x10000
    db	  '/rd/1/setup',0
    times 256 db ?

startx: dq 1
starty: dq 300
sizey:	dq 268

screenx: dq 0
screeny: dq 0

beginning: dq 0x0
paramcount: dq 0x0

ipcarea: db 0,0,0,0
	 dd 0
	 times 64 db 0

process_info: times 2000 db ?

pointers: times 4*100 db ?

param: times 1024 db ?

I_END:




