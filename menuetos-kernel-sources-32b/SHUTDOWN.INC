;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   Shutdown.inc (c) Ville Turjanmaa
;;   License: GPL. See file copying for details.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


system_shutdown:          

    mov   eax,3             ; Stop playing cd
    call  sys_cd_audio

    ; Disable PS/2 mouse

    cmp   [0xF604],byte 1
    jne   nops2mousedisable
    mov   al , 0xa7
    out   0x64 , al
  nops2mousedisable:

    cli                     ; Darken screen
    mov   ecx,0x3fff00/4    
    push  ecx
    mov   esi,[0xfe80]
    cmp   esi,32*0x100000
    jbe   no_darken_screen
    mov   edi,16*0x100000
  sdnewpix:
    mov   eax,[esi]
    add   esi,4
    shr   eax,1
    and   eax,0x7f7f7f7f
    stosd
    loop  sdnewpix
    pop   ecx
    mov   esi,16*0x100000
    mov   edi,[0xfe80]
    cld
    rep   movsd
  no_darken_screen:

    ; Blue background

    mov   eax,[0xfe00]
    shr   eax,1
    sub   eax,200
   
    mov   ebx,[0xfe04]
    shr   ebx,1
    mov   [shutdownpos],ebx
    sub   ebx,120
   
    mov   edi,1
    mov   ecx,0x0000A0
   
  sdnewpix2:
   
    call  putpixel
   
    inc   eax
    mov   esi,[0xfe00]
    shr   esi,1
    add   esi,200
    cmp   eax,esi
    jnz   sdnewpix2
   
    dec   ecx
   
    mov   eax,[0xfe00]
    shr   eax,1
    sub   eax,200
   
    inc   ebx
   
    mov   edx,[shutdownpos]
    sub   edx,86
    cmp   ebx,edx
    jnz   sdnewpix2

    ; Its safe to power down computer..
   
    mov   esi,[0xfe00]    
    shr   esi,1
    sub   esi,200 ; 220
    add   esi,26 ; 20 ; 27
    shl   esi,16
    mov   eax,esi
    add   eax,[shutdownpos]
    sub   eax,88+19
    mov   esi,5
    mov   ebx,0xffffff
    mov   ecx,shutdowntext
    mov   edx,60
    mov   edi,1
  newsdt:
    call  dtext

    ; Wait for Esc key

 waitforsomekey:

    in    al,0x60
    mov   bl,al

  waitforkey:
    in    al,0x60
    cmp   al,bl
    je    waitforkey

    ; Esc down ?

    in    al,0x60
    cmp   al,1
    jne   waitforkey

    mov   bl,al
  waitforkey2:
    in    al,0x60
    cmp   al,bl
    je    waitforkey2

    ; Esc up ?

    mov   bl,0 
    in    al,0x60
    in    al,0x60
    cmp   al,127
    je    waitforsomekey

    ; Boot with keyboard controller

    mov   edx , 0x64 
    mov   eax , 0xfe
    out   dx,al

    cli
    jmp   $ ;  not propably needed

    ;
    ;  The following code is disabled due to compatibility issues
    ;

    mov   esi,[0xfe00]      ; version
    shr   esi,1
    sub   esi,200
    add   esi,20
    shl   esi,16
    mov   eax,esi
    add   eax,[shutdownpos]
    sub   eax,105
    mov   ebx,0xffffff
    mov   ecx,version+0x10000
    mov   edx,11+2
    mov   edi,1
    call  dtext
   
    mov   eax,rosef          ; load rose.txt
    mov   ebx,0
    mov   ecx,16800
    mov   edx,0x90000
    mov   esi,12
    call  fileread
   
    mov   esi,[0xfe00]       ; draw rose
    shr   esi,1
    add   esi,20
    shl   esi,16
    mov   eax,esi
    add   eax,[shutdownpos]
    sub   eax,110
   
    mov   ebx,0xff0000
    mov   ecx,0x90001
    mov   edx,27
    mov   edi,1
   
   nrl:
    call  dtext
    sub   ebx,0x050000
    add   eax,8
    add   ecx,31
    cmp   ecx,dword 0x90001+25*31
    jnz   nrl
   
    call  checkEgaCga
   
    cli

    ; Load kernel.mnt to 0x8000:0
   
    mov   eax,kernel               
    mov   esi,12
    mov   ebx,0
    mov   ecx,-1
    mov   edx,0x80000
    call  fileread

    ; Move kernel loader to 0x4000:0
   
    mov   esi,restart_kernel_4000  
    mov   edi,0x40000
    mov   ecx,1000
    cld
    rep   movsb

    ; Restore 0x0 - 0xffff
   
    mov   eax,0x2F0000    
    mov   ebx,0x0000
    mov   ecx,0xffff
    call  memmove
   
    call  restorefatchain
   
    mov   eax,pr_mode_exit
    mov   [0x467+0],ax
    mov   [0x467+2],word 0x1000
   
    mov   al,0x0F
    out   0x70,al
    mov   al,0x05
    out   0x71,al
   
    mov   al,0xFE
    out   0x64,al
    hlt
   
    ;;  use16 ; disabled 0.82
   
pr_mode_exit:
   
    mov   ax,1000
    mov   ds,ax
    mov   es,ax
    mov   fs,ax
    mov   gs,ax
    mov   ss,ax
   
    mov   al,2
    out   0x21,al
    mov   al,0
    out   0xA1,al
   
    jmp   real_mode-0x10000
   
old_ints_h:

    dw    4*0x20
    dd    0
    dw    0
   
real_mode:
   
    lidt  [cs:old_ints_h-0x10000]
    mov   sp,0xfff0
   
    sti
  nbw:
    xor   ax,ax
    in    al,0x60
    cmp   al,7
    jge   nbw
    mov   bl,al
  nbw2:
    in    al,0x60
    cmp   al,bl
    je    nbw2
    cmp   ax,240
    jne   nbw31
    mov   al,bl
    dec   al
    jmp   nbw32
  nbw31:
    add   bl,128
    cmp   al,bl
    jne   nbw
    sub   al,129
  nbw32:
    cmp   al,1              ; Write floppy
    jnz   no_floppy_write
    call  floppy_write
    jmp   nbw
  no_floppy_write:
;    cmp  al,2              ; Poweroff
;    jnz  no_apm_off
;    call APM_PowerOff
;  no_apm_off:
    cmp   al,2               ; Boot
    jnz   no_sys_boot
    jmp   0xffff:0
  no_sys_boot:
   
    cmp   al,3               ; Restart kernel
    je    restart_kernel
   
    jmp   nbw
   
kernel:

    db    'KERNEL  MNT'
   
restart_kernel:
   
    mov   ax,0x0003      ; set text mode for screen
    int   0x10
   
    jmp   0x4000:0000
   
restart_kernel_4000:
   
    mov   di,0x1000      ; Load kernel image from 0x8000:0 -> 0x1000:0
   
  new_kernel_block_move:
   
    mov   ebx,0
   
  new_kernel_byte_move:
   
    mov   ax,di
    add   ax,0x7000
    mov   es,ax
    mov   dl,[es:bx]
    mov   es,di
    mov   [es:bx],dl
  
    inc   ebx
    cmp   ebx,65536
    jbe   new_kernel_byte_move
   
    add   di,0x1000
    cmp   di,0x2000
    jbe   new_kernel_block_move
        
    wbinvd  ; Write and invalidate cache
   
    mov   ax,0x1000
    mov   es,ax
    mov   ax,0x2000
    mov   ss,ax
    mov   sp,0xff00
   
    jmp   0x1000:0000
   
APM_PowerOff: ;; not in use at the moment due to
              ;; incompatibility in some machines
   
    mov   ax,5304h
    sub   bx,bx
    int   15h
    mov   ax,5302h
    sub   bx,bx
    int   15h
    mov   ax,5308h
    mov   bx,1
    mov   cx,bx
    int   15h
    mov   ax,530Dh
    mov   bx,1
    mov   cx,bx
    int   15h
    mov   ax,530Fh
    mov   bx,1
    mov   cx,bx
    int   15h
    mov   ax,530Eh
    sub   bx,bx
    mov   cx,102h
    int   15h
    mov   ax,5307h
    mov   bx,1
    mov   cx,3
    int   15h

    ret
   
flm:

    db    0x0
   
floppy_write:   ; Write diskette image to floppy
   
    pusha
   
    mov   ax,0x1000
    mov   es,ax
    cmp   [es:flm-0x10000],byte 1
    je    fwwritedone
    mov   [es:flm-0x10000],byte 1
   
    mov   ax,0x0000               ; reset drive
    mov   dx,0x0000
    int   0x13
   
    mov   cx,0x0001               ; startcyl,startsector
    mov   dx,0x0000               ; starthead,drive
    push  word 80*2               ; read no of sect
   
  fwwrites:

    pusha
   
    ; Move 1mb+ -> 0:a000
   
    pusha
    mov   si,fwmovedesc -0x10000
    push  word 0x1000
    pop   es
    mov   cx,256*18
    mov   ah,0x87
    int   0x15
    mov   eax,[es:fwmovedesc-0x10000+0x12]
    add   eax,512*18
    mov   [es:fwmovedesc-0x10000+0x12],eax
    popa
   
    xor   si,si
  fwnewwrite:
    push  word 0x0
    pop   es
    mov   bx,0xa000               ; es:bx -> data area
    mov   ax,0x0300+18            ; read, no of sectors to read
    int   0x13
   
    cmp   ah,0
    jz    fwgoodwrite
   
    add   si,1
    cmp   si,10
    jnz   fwnewwrite
   
    add   esp,32+2
   
    popa                          ; Can not access diskette
    ret
   
  fwgoodwrite:
   
    popa
   
    inc   dh
    cmp   dh,2
    jnz   fwbb2
    mov   dh,0
    inc   ch
   
  fwbb2:
   
    cld
    pop   ax
    dec   ax
    push  ax
    cmp   ax,0
    jnz   fwrs
  
    pop   ax
   
    jmp   fwwritedone
  fwrs:
    jmp   fwwrites
   
  fwmovedesc:
   
    db    0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db    0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db    0xff,0xff,0x0,0x00,0x10,0x93,0x0,0x0
    db    0xff,0xff,0x0,0xa0,0x00,0x93,0x0,0x0
    db    0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db    0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db    0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db    0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
   
  fwwritedone:
   
    popa

    ret
   
use32
   
shutdownpos:

    dd    0x0

rosef:

    db   "ROSE    TXT"
   
shutdowntext:

    db   "It's safe to power off computer or press <Esc> to reboot.     "
   
