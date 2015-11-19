   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                          ;;
;;   WINDOW SKIN for MenuetOS               ;;
;;                                          ;;
;;   entryway@bkg.lt                        ;;
;;                                          ;;
;;   Bugfixes & upgrades by                 ;;
;;             Samuel Rodriguez Perez       ;;
;;             Xeoda@ciberirmandade.org     ;;
;;                                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   
   
include "SKINDATA.INC"
   
load_default_skin:
   
    pusha
    cmp   [_refleft], 0
    jnz   skinok1
    mov   [_refleft], 0x778000
    mov   eax,_fileleft
    mov   ebx, 1
    mov   ecx, -1
    mov   edx,[_refleft]
    mov   esi,12
    call  fileread
skinok1:
    cmp   [_refbase], 0
    jnz   skinok2
    mov   eax,[v_skinh]
    mov   ebx,[_skinleftw]
    imul  eax,ebx
    imul  eax,3
    add   eax,[_refleft]
    mov   [_refbase],eax
    mov   eax,_filebase
    mov   ebx, 1
    mov   ecx, -1
    mov   edx,[_refbase]
    mov   esi,12
    call  fileread
skinok2:
    cmp   [_refoper], 0
    jnz   skinok3
    mov   eax,[v_skinh]
    mov   ebx,[_skinbasew]
    imul  eax,ebx
    imul  eax,3
    add   eax,[_refbase]
    mov   [_refoper],eax
    mov   eax,_fileoper
    mov   ebx, 1
    mov   ecx, -1
    mov   edx,[_refoper]
    mov   esi,12
    call  fileread
skinok3:
    popa
    ret
   
   
drawwindow_IV:
   
        pusha
   
        push  edx
   
        mov   edi,[esp]                              ; RECTANGLE
   
        mov   eax,[edi+0]
        shl   eax,16
        mov   ax,[edi+0]
        add   ax,[edi+8]
        mov   ebx,[edi+4]
        shl   ebx,16
        mov   bx,[edi+4]
        add   bx,[edi+12]
        mov   esi,[_coloroutborder]
        call  draw_rectangle
        mov   ecx,3
      _dw3l:
        add   eax,1*65536-1
        add   ebx,1*65536-1
        mov   esi,[_colorframe] ;[edi+24]
        call  draw_rectangle
        dec   ecx
        jnz   _dw3l
        mov   esi,[_colorborder]
        add   eax,1*65536-1
        add   ebx,1*65536-1
        call  draw_rectangle

        ; Middle skin

        mov   esi,[esp]
        mov   eax,[esi+8]
        mov   edx,0
        mov   ebx,[_skinbasew]
        div   ebx
        and   eax , 0xfff
        inc   eax
        mov   ebx,[_refbase]
        mov   ecx,[_skinbasew]
        shl   ecx,16
        add   ecx,[_skinh]
        mov   edx,[_skinbase]
        shl   edx,16
        mov   edx , 0 ; x,y start

      baseskinloop:

        push  eax
        push  ebx
        push  ecx
        push  edx
        call  sys_putimage
        ; mov   eax , 10
        ; call  delay_hs
        pop   edx
        pop   ecx
        pop   ebx
        pop   eax

        shr   edx,16
        add   edx,[_skinbasew]
        shl   edx,16

        dec   eax
        cmp   eax, 0
        jnz   baseskinloop

        ; Left skin
   
        mov   esi,[esp]
        mov   eax,[esi+8]    
        mov   edx,[_skinleft]
        shl   edx,16
        mov   ecx,[_skinleftw]
        shl   ecx,16
        add   ecx,[_skinh]
        mov   ebx,[_refleft]
        call  sys_putimage

        ; Right skin
   
        mov   esi,[esp]
        mov   edx,[esi+8]
        sub   edx,[_skinoperw]
        inc   edx
        shl   edx,16
        mov   ebx,[_refoper]
        mov   ecx,[_skinoperw]
        shl   ecx,16
        add   ecx,[_skinh]
        call  sys_putimage
   
        mov   esi,[esp]
   
        mov   edx,[esi+04]                       ; WORK AREA
        add   edx,21+5
        mov   ebx,[esi+04]
        add   ebx,[esi+12]
        cmp   edx,ebx
        jg    _noinside2
        mov   eax,5
        mov   ebx,[_skinh]
        mov   ecx,[esi+8]
        mov   edx,[esi+12]
        sub   ecx,4
        sub   edx,4
        mov   edi,[esi+16]
        call  drawbar
      _noinside2:
   
        mov   edi,[0xfe88]
        movzx eax,word [edi]
        cmp   eax,1000
        jge   no_skin_add_button
        inc   eax
        mov   [edi],ax
   
        shl   eax,4
        add   eax,edi
   
        mov   bx,[0x3000]
        mov   [eax],bx
   
        add   eax,2         ; save button id number
        mov   bx,1
        mov   [eax],bx
        mov   bx,0x2000     ; button id : bits 16-31 - do not draw press
      ;  mov   bx , 0x0000
        mov   [eax-2+0xc],bx

        add   eax,2         ; x start
        mov   ebx,[esp]
        mov   ebx,[ebx+8]
        cmp   [_buttonCx],0
        jg    _bCx_at_right
        mov   ebx,[_buttonCw]    ; ebx will be 0 in next instruction
      _bCx_at_right:
        sub   ebx,[_buttonCw]
        sub   ebx,[_buttonCx]
        mov   [eax],bx
        add   eax,2         ; x size
        mov   ebx,[_buttonCw]
        mov   [eax],bx
        add   eax,2         ; y start
        mov   ebx,[_buttonCy]
        mov   [eax],bx
        add   eax,2         ; y size
        mov   ebx,[_buttonCh]
        mov   [eax],bx
   
      no_skin_add_button:
   
        add   esp,4
        popa
        ret
   


   
drawwindow_V:
   
        pusha
   
        push  edx

        ; Rectangle
   
        mov   edi,[esp]                              
   
        mov   eax,[edi+0]
        shl   eax,16
        mov   ax,[edi+0]
        add   ax,[edi+8]
        mov   ebx,[edi+4]
        shl   ebx,16
        mov   bx,[edi+4]
        add   bx,[edi+12]
        mov   esi,[_coloroutborder]
        call  draw_rectangle
        mov   ecx,3
      v_dw3l:
        add   eax,1*65536-1
        add   ebx,1*65536-1
        mov   esi,[_colorframe] ;[edi+24]
        call  draw_rectangle
        dec   ecx
        jnz   v_dw3l
        mov   esi,[_colorborder]
        add   eax,1*65536-1
        add   ebx,1*65536-1
        call  draw_rectangle

        ; Middle skin

        mov   esi,[esp]
        mov   eax,[esi+8]
        mov   edx,0
        mov   ebx,[v_skinbasew]
        div   ebx
        and   eax , 0xfff
        inc   eax
        mov   ebx,[_refbase]
        mov   ecx,[v_skinbasew]
        shl   ecx,16
        add   ecx,[v_skinh]
        mov   edx,[v_skinbase]
        shl   edx,16
        mov   edx , 0 ; x,y start

      baseskinloop2:

        push  eax
        push  ebx
        push  ecx
        push  edx
        call  sys_putimage
        ; mov   eax , 10
        ; call  delay_hs
        pop   edx
        pop   ecx
        pop   ebx
        pop   eax

        shr   edx,16
        add   edx,[v_skinbasew]
        shl   edx,16

        dec   eax
        cmp   eax, 0
        jnz   baseskinloop2


        ; Left skin
   
        mov   esi,[esp]
        mov   eax,[esi+8]    ; window width
        mov   edx,[v_skinleft]
        shl   edx,16
        mov   ecx,[v_skinleftw]
        shl   ecx,16
        add   ecx,[v_skinh]
        mov   ebx,[_refleft]
        call  sys_putimage

        ; Middle skin
   
  ;      mov   esi,[esp]
  ;      mov   eax,[esi+8]
  ;      sub   eax,[v_skinleftw]
  ;      sub   eax,[v_skinoperw]
  ;      mov   edx,0
  ;      mov   ebx,[v_skinbasew]
  ;      div   ebx

  ;      and   eax , 0xfff
  ;      inc   eax
   
  ;      mov   ebx,[_refbase]
  ;      mov   ecx,[v_skinbasew]
  ;      shl   ecx,16
  ;      add   ecx,[v_skinh]
  ;      mov   edx,[v_skinbase]
  ;      sub   edx,[v_skinbasew]
  ;      shl   edx,16
  ;    vbaseskinloop:
  ;      shr   edx,16
  ;      add   edx,[v_skinbasew]
  ;      shl   edx,16
  ;      push  eax
  ;      push  ebx
  ;      push  ecx
  ;      push  edx
  ;      call  sys_putimage
   
  ;      pop   edx
  ;      pop   ecx
  ;      pop   ebx
  ;      pop   eax
  ;      dec   eax
  ;      cmp   eax, 0
  ;      jnz   vbaseskinloop
  ;    vnon_base:

        ; Skin right
   
        mov   esi,[esp]
        mov   edx,[esi+8]
        sub   edx,[v_skinoperw]
        inc   edx
        shl   edx,16
        mov   ebx,[_refoper]
        mov   ecx,[v_skinoperw]
        shl   ecx,16
        add   ecx,[v_skinh]
        call  sys_putimage

        ; Work area
   
        mov   esi,[esp]
        mov   edx,[esi+04]                  
        add   edx,[v_skinh] ;  21+5+18
        mov   ebx,[esi+04]
        add   ebx,[esi+12]
        cmp   edx,ebx
        jg    v_noinside2
        mov   eax,5
        mov   ebx,[v_skinh]
        mov   ecx,[esi+8]
        mov   edx,[esi+12]
        sub   ecx,4
        sub   edx,4
        mov   edi,[esi+16]
        call  drawbar
      v_noinside2:
   
        mov   edi,[0xfe88]
        movzx eax,word [edi]
        cmp   eax,1000
        jge   vno_skin_add_button
        inc   eax
        mov   [edi],ax
   
        shl   eax,4
        add   eax,edi
   
        mov   bx,[0x3000]
        mov   [eax],bx
   
        add   eax,2         ; save button id number
        mov   bx,1
        mov   [eax],bx
        mov   bx,0x2000     ; button id : bits 16-31 - do not draw press
      ;  mov   bx , 0x0000
        mov   [eax-2+0xc],bx

        add   eax,2         ; x start
        mov   ebx,[esp]
        mov   ebx,[ebx+8]
        cmp   [_buttonCx],0
        jg    v_bCx_at_right
        mov   ebx,[_buttonCw]    ; ebx will be 0 in next instruction
      v_bCx_at_right:
        sub   ebx,[_buttonCw]
        sub   ebx,[_buttonCx]
        mov   [eax],bx
        add   eax,2         ; x size
        mov   ebx,[_buttonCw]
        mov   [eax],bx
        add   eax,2         ; y start
        mov   ebx,[_buttonCy]
        mov   [eax],bx
        add   eax,2         ; y size
        mov   ebx,[_buttonCh]
        mov   [eax],bx
   
      vno_skin_add_button:
   
        add   esp,4
        popa
        ret
   
   
   

   
