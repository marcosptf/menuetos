;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                        ;;
;;  VESA20.INC                                            ;;
;;                                                        ;;
;;  Vesa 2.0 functions for MenuetOS                       ;;
;;                                                        ;;
;;  Copyright 2002 Ville Turjanmaa                        ;;
;;  Alexey, kgaz@crosswindws.net                          ;;
;;  - Voodoo compatible graphics                          ;;
;;  Juan M. Caravaca                                      ;;
;;  - Graphics optimimizations eg. drawline               ;;
;;                                                        ;;
;;  See file COPYING for details                          ;;
;;                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
; If you're planning to write your own video driver I suggest
; you replace the VESA12.INC file and see those instructions.
   
ScreenWidth             equ     0xfe00
ScreenHeight            equ     0xfe04
BytesPerScanLine        equ     0xfe08
LFBAddress              equ     0xfe80
ScreenBPP               equ     0xfbf1
WinMapAddress           equ     0x400000
   
   
vesa20_read_screen_pixel:
   
     and        eax, 0x3FFFFF
     shl        eax, 2
   
     cmp        byte [ScreenBPP], 24      ; 24 or 32 bpp ?
     jz         .no24bpp
   
     shr        eax, 2
     lea        eax, [eax+eax*2]
   
.no24bpp:
   
     add        eax, [LFBAddress]
     mov        eax, [eax]
     and        eax, 0x00ffffff
     ret
   
; getpixel
;
; in:
; eax = x coordinate
; ebx = y coordinate
;
; ret:
; ecx = 00 RR GG BB
   
getpixel:
        push    eax
        push    ebx
        push    edx
        push    edi
        call    dword [0xe024]
        pop     edi
        pop     edx
        pop     ebx
        pop     eax
        ret
   
Vesa20_getpixel24:
        ; eax = x
        ; ebx = y
        imul    ebx, [BytesPerScanLine]    ; ebx = y * y multiplier
        lea     edi, [eax+eax*2] ; edi = x*3
        add     edi, ebx         ; edi = x*3+(y*y multiplier)
        add     edi, [LFBAddress]    ; ebx = where pixel is in memory
        mov     ecx, [edi]
        and     ecx, 0xffffff
        ret
   
Vesa20_getpixel32:
        imul    ebx, [BytesPerScanLine]    ; ebx = y * y multiplier
        lea     edi, [ebx+eax*4] ; edi = x*4+(y*y multiplier)
        add     edi, [LFBAddress]    ; ebx = where pixel is in memory
        mov     ecx, [edi]
        and     ecx, 0xffffff
        ret
   
   
   
vesa20_putimage:

        call    disable_mouse
   
        mov [novesachecksum],dword 0
        push ebp ;
   
        mov     esi, ebx
   
        xor     ebx, ebx
        mov     bx, dx          ; ebx := y
        shr     edx, 16         ; edx := x
   
        mov     eax, [0x3010]
        add     edx, [eax-twdw]  ; edx+=Xwin
        add     ebx, [eax-twdw+4]; ebx+=Ywin
   
        mov     edi, ebx        ; edi:=(y+Ywin)
        imul    edi, dword [BytesPerScanLine]  ; edi:=BPScanLine*(y+Ywin)
   
        mov     ebp, ebx        ; ebp:=(y+Ywin)
        imul    ebp, [ScreenWidth]
        add     ebp, ebx        ; (ScreenXSize+1)*(Y+YWin)
                                ; +(x+Xwin)+AddrBuffer
   
        lea     edi, [edi + edx*4]  ; edi += (X+XWin)*4
   
        lea     ebp, [ebp + edx + WinMapAddress] ; ebp:=(y+Ywin)*(SXSize+
                                                 ; +(x+Xwin)+AddrBuffer
        add     edi, [LFBAddress]
   
        xor     ebx, ebx        ; ebx:=H
        mov     bx, cx
        shr     ecx, 16         ; ecx = B
        mov     eax, ecx
        shl     ecx, 2          ; ecx *= 4
   
        cmp     byte [ScreenBPP], 32
        jz      .bpp32
   
        ; corrections for 24 bpp
        sub     edi, edx
        sub     ecx, eax
   
.bpp32:
   
        ; ecx:=B*PytesPerPixel
        ;mov esi,[esp+8] ; esi:=AddrImg
   
        ; check limits while draw ?
   
        push    ebx
   
        mov     edx, [0x3010]
   
        cmp     dword [edx+draw_data-0x3000+0], 0
        jnz dbcblimitlset2
   
        cmp     dword [edx+draw_data-0x3000+4], 0
        jnz dbcblimitlset2
   
        mov     ebx, [edx+draw_data-0x3000+8]
        cmp     ebx, [ScreenWidth] ; ecx <> Screen X size
        jnz dbcblimitlset2
   
        mov     ebx, [edx+draw_data-0x3000+12]
        cmp     ebx, [ScreenHeight] ; ecx <> Screen Y size
        jnz dbcblimitlset2
   
        mov     bh, 0
   
        jmp dbcblimitlno2
   
      dbcblimitlset2:
   
        mov     bh, 1
   
      dbcblimitlno2:
   
        mov     bl, [edx+0xe]
   
        cmp [ScreenBPP],byte 24 ; 24 or 32 bpp ?
        jz pi24bit
        jmp pi32bit
   
   
; eax = B
; ecx = B*PytesPerPixel
; edx = 0x3010
; esi = ptr to image data
; edi = ptr to screen where begining painting
; ds:ebp = ptr to windows map
; bh = 0 force
;      1 not force
; bl = window ID on windows map
   
pi24bit:
   
   
      .RenderBlock:
   
        push edi
        push esi
        push eax
        push ebp
   
        .RenderLine:
   
          cmp   bl,[ds:ebp]
          jnz   .imp24no
          cmp   bh, 0
          jz    .imp24yes
          call  voodoodbcplimit
          jnz   .imp24no
   
        .imp24yes:
   
          mov   edx, [esi]
          mov   [edi], dx
          shr   edx, 16
          mov   [edi+2], dl
   
        .imp24no:
   
          add   esi, 3 ; esi+=3 ptrImage+=3
          add   edi, 3 ; edi+=3 ptrScreen+=3
          inc   ebp
   
          dec   eax ; B--
          jnz   .RenderLine
   
      pop ebp
      pop eax
      pop esi
      pop edi
   
      add       edi, [BytesPerScanLine] ; ptrScreen+=BytesPerScanLine
      add       esi, ecx
      add       ebp, [ScreenWidth]
      inc       ebp
   
      dec       dword [esp]   ; H--
      jnz       .RenderBlock
   
      pop       ebx
      pop       ebp
   
      xor       eax, eax
      ret
   
   
pi32bit:
   
        sub     ecx, eax    ; ecx = B*4 - B = B*3
   
      .RenderBlock:
   
        push edi
        push esi
        push eax
        push ebp
   
        .RenderLine:
   
          cmp   bl,[ds:ebp]
          jnz   .imp32no
          cmp   bh,0
          jz    .imp32yes
          call  voodoodbcplimit
          jnz   .imp32no
   
        .imp32yes:
   
          mov   edx, [esi]
          mov   [edi], edx
   
        .imp32no:
   
          add   esi, 3 ; esi+=3 ptrImage+=3
          add   edi, 4 ; edi+=4 ptrScreen+=4
          inc   ebp
   
          dec   eax ; B--
          jnz   .RenderLine
   
      pop ebp
      pop eax
      pop esi
      pop edi
   
      add       edi, [BytesPerScanLine] ; ptrScreen+=BytesPerScanLine
      add       esi, ecx
      add       ebp, [ScreenWidth]
      inc       ebp
   
      dec       dword [esp]   ; H--
      jnz       .RenderBlock
   
      pop       ebx
      pop       ebp
   
      xor       eax, eax
      ret
   
   
putpixel:
   
; eax = x coordinate
; ebx = y coordinate
; ecx = ?? RR GG BB    ; 0x01000000 negation
; edi = 0x00000001 force

        mov  [novesachecksum], dword 0
   
        pusha
        test edi,1                 ; force ?
        jnz   drawok2
      noforce:
        call checkpixel
        cmp  ecx, 0
        jnz  ppr
      drawok2:
        cmp [ScreenWidth], eax
        jb  ppr
        cmp [ScreenHeight], ebx
        jb  ppr
      ppok:
        ; check if negation
        test ecx,0x01000000
        jz   noneg
        call getpixel
        not  ecx
        mov  [esp+32-8],ecx
      noneg:
        ; OK to set pixel
        call dword [0xe020]
      ppr:
        popa
        ret
   
   
Vesa20_putpixel24:
   
        ; eax = x
        ; ebx = y
   
        imul    ebx, [BytesPerScanLine]     ; ebx = y * y multiplier
        lea     edi, [eax+eax*2]  ; edi = x*3
        mov     eax, [esp+32-8+4]
        add     edi, [LFBAddress]
        add     edi, ebx          ; ebx = where to put pixel in memory
        mov     [edi], ax
        shr     eax, 16
        mov     [edi+2], al
   
        ret
   
   
   
Vesa20_putpixel32:
   
        ; eax = x
        ; ebx = y
   
        imul    ebx, [BytesPerScanLine]     ; ebx = y * y multiplier
        lea     edi, [ebx+eax*4]  ; edi = x*4+(y*y multiplier)
        mov     eax, [esp+32-8+4] ; eax = color
        add     edi, [LFBAddress]     ; ebx = where to put pixel in memory
        mov     [edi], eax
   
        ret
   
   
   
   
;-------------------------------------------------
calculate_edi:
        mov     edi, ebx
        imul    edi, [ScreenWidth]
        add     edi, ebx
        add     edi, eax
        ret
;-------------------------------------------------
; DRAWLINE
   
draw_line:

        call    disable_mouse

   
; draw a line
; eax = HIWORD = x1
;       LOWORD = x2
; ebx = HIWORD = y1
;       LOWORD = y2
; ecx = color
; edi = force ?
        pusha
   
dl_x1 equ esp+20
dl_y1 equ esp+16
dl_x2 equ esp+12
dl_y2 equ esp+8
dl_dx equ esp+4
dl_dy equ esp+0
   
        xor     edx, edx      ; clear edx
        xor     esi, esi      ; unpack arguments
        xor     ebp, ebp
        mov     si, ax        ; esi = x2
        mov     bp, bx        ; ebp = y2
        shr     eax, 16       ; eax = x1
        shr     ebx, 16       ; ebx = y1
   
        push    eax           ; save x1
        push    ebx           ; save y1
        push    esi           ; save x2
        push    ebp           ; save y2
   
        ; checking x-axis...
        sub     esi, eax      ; esi = x2-x1
        push    esi           ; save y2-y1
        jl      .x2lx1        ; is x2 less than x1 ?
        jg      .no_vline     ; x1 > x2 ?
        mov     edx, ebp      ; else (if x1=x2)
        call    vline
        push    edx    ; necessary to rightly restore stack frame at .exit
        jmp     .exit
.x2lx1:
        neg     esi            ; get esi absolute value
.no_vline:
   
        ; checking y-axis...
        sub     ebp, ebx       ; ebp = y2-y1
        push    ebp            ; save y2-y1
        jl      .y2ly1         ; is y2 less than y1 ?
        jg      .no_hline      ; y1 > y2 ?
        mov     edx, [dl_x2]   ; else (if y1=y2)
        call    hline
        jmp     .exit
.y2ly1:
        neg     ebp            ; get ebp absolute value
.no_hline:
   
   
        cmp     ebp, esi
        jle     .x_rules       ; |y2-y1| < |x2-x1|  ?
   
        cmp     [dl_y2], ebx   ; make sure y1 is at the begining
        jge     .no_reverse1
   
        neg     dword [dl_dx]
        mov     edx, [dl_x2]
        mov     [dl_x2], eax
        mov     [dl_x1], edx
        mov     edx, [dl_y2]
        mov     [dl_y2], ebx
        mov     [dl_y1], edx
   
.no_reverse1:
   
        mov     eax, [dl_dx]
        cdq                    ; extend eax sing to edx
        shl     eax, 16        ; using 16bit fix-point maths
        idiv    ebp            ; eax = ((x2-x1)*65536)/(y2-y1)
        mov     edx, ebp       ; edx = counter (number of pixels to draw)
        mov     ebp, 1 *65536  ; <<16   ; ebp = dy = 1.0
        mov     esi, eax       ; esi = dx
   
        jmp     .y_rules
.x_rules:
   
        cmp     [dl_x2], eax    ; make sure x1 is at the begining
        jge     .no_reverse2
   
        neg     dword [dl_dy]
        mov     edx, [dl_x2]
        mov     [dl_x2], eax
        mov     [dl_x1], edx
        mov     edx, [dl_y2]
        mov     [dl_y2], ebx
        mov     [dl_y1], edx
   
.no_reverse2:
   
        xor     edx, edx
        mov     eax, [dl_dy]
        cdq                    ; extend eax sing to edx
        shl     eax, 16        ; using 16bit fix-point maths
        idiv    esi            ; eax = ((y2-y1)*65536)/(x2-x1)
        mov     edx, esi       ; edx = counter (number of pixels to draw)
        mov     esi, 1 *65536  ;<< 16   ; esi = dx = 1.0
        mov     ebp, eax       ; ebp = dy
   
.y_rules:
   
        mov     eax, [dl_x1]
        mov     ebx, [dl_y1]
        shl     eax, 16
        shl     ebx, 16
   
.draw:
        push    eax
        push    ebx
   
        shr     eax, 16
        shr     ebx, 16
        call    putpixel
   
        pop     ebx
        pop     eax
   
        add     ebx, ebp        ; y = y+dy
        add     eax, esi        ; x = x+dx
   
        dec     edx
        jnz     .draw
   
        ; force last drawn pixel to be at (x2,y2)
        mov     eax, [dl_x2]
        mov     ebx, [dl_y2]
        call    putpixel
   
.exit:
        add     esp, 6*4
        popa
        ret
   
hline:
; draw an horizontal line
; eax = x1
; edx = x2
; ebx = y
; ecx = color
; edi = force ?
        push    eax
        push    edx
   
        cmp     edx, eax      ; make sure x2 is above x1
        jge     .draw_hline
   
        xchg    eax, edx
   
.draw_hline:
   
        call    putpixel
        inc     eax
   
        cmp     eax, edx
        jle     .draw_hline
   
        pop     edx
        pop     eax
        ret
   
vline:
; draw a vertical line
; eax = x
; ebx = y1
; edx = y2
; ecx = color
; edi = force ?
        push    ebx
        push    edx
   
        cmp     edx, ebx      ; make sure y2 is above y1
        jge     .draw_vline
   
        xchg    ebx, edx
   
.draw_vline:
   
        call    putpixel
        inc     ebx
   
        cmp     ebx, edx
        jle     .draw_vline
   
        pop     edx
        pop     ebx
        ret
   
   
   
   
vesa20_drawbar:

     call    disable_mouse
   
     mov [novesachecksum],dword 0
   
     sub edx,ebx ; edx:=Yend-Ystart=H
     sub ecx,eax ; ecx:=Xend-Xstat=B
   
     push ebp ; +24
     push esi ; +20
     push edi ; +16
     push eax ; +12
     push ebx ; +8
     push ecx ; +4
     push edx ; +0
   
   
     mov ecx,[0x3010]       ;
     add eax,[ecx-twdw]   ; eax:=Xwin+x
     add ebx,[ecx-twdw+4] ; ebx:=Ywin+y
   
     mov ecx, eax           ; ecx:=(x+Xwin)
     mov eax, [BytesPerScanLine]      ; BytesPerScanLine
     mul ebx                ; *(y+Ywin)
     mov edi, eax           ; edi:=BytesPerScanLine*(y+Ywin)
   
     mov eax, [ScreenWidth] ; ScreenXSize
     inc eax                ; +1
     mul ebx                ; *(y+Ywin)
     mov ebp, eax           ;
     add ebp, ecx           ; +(x+Win)
     add ebp, WinMapAddress ; ebp:=(y+Ywin)*(ScreenXSize+1)+(x+Xwin)+AdrBf
   
   
     add edi,ecx            ; +(x+Xwin)
     add edi,ecx            ; +(x+Xwin)
     add edi,ecx            ; +(x+Xwin)
   
     cmp [ScreenBPP],byte 24   ; 24 or 32 bpp ? - x start
     jz dbpi24
     add edi,ecx            ; +(x+Xwin)
   dbpi24:
     add edi,[LFBAddress]   ; +AddrLFB
   
; edi:=(y+Ywin)*Screen_Y_multiplier+X*BytesPerPixel
; ebp:=(y+Ywin)*(ScreenXSize+1)+(x+Xwin)+AddrBuffer
   
; x size
   
     mov eax,[esp+4]        ; B [esp+4]
   
     mov ecx,eax            ; B
     add ecx,eax            ; +B
     add ecx,eax            ; +B
   
     cmp [ScreenBPP],byte 24   ; 24 or 32 bpp ? - x size
     jz dbpi243
     add ecx,eax            ; +B if 32bpp
     ; ecx:=B*BytesPerPixel, eax:=B
   dbpi243:
   
     mov ebx,[esp+0]        ; H
   
     ; check limits ?
   
     push eax
     push ecx
   
     mov eax,[0x3010]
   
     mov ecx,[eax+draw_data-0x3000+0]
     cmp ecx,0
     jnz dbcblimitlset
   
     mov ecx,[eax+draw_data-0x3000+4]
     cmp ecx,0
     jnz dbcblimitlset
   
     mov ecx,[eax+draw_data-0x3000+8]
     cmp ecx,[ScreenWidth]
     jnz dbcblimitlset
   
     mov ecx,[eax+draw_data-0x3000+12]
     cmp ecx,[ScreenHeight]
     jnz dbcblimitlset
   
     pop ecx
     pop eax
   
     push dword 0
   
     jmp dbcblimitlno
   
   dbcblimitlset:
   
     pop ecx ; B*BytesPerPixel
     pop eax ; B
   
     push dword 1
   
   dbcblimitlno:
   
   
     cmp [ScreenBPP],byte 24   ; 24 or 32 bpp ?
     jz dbpi24bit
     jmp dbpi32bit
   
   
   
   
; DRAWBAR 24 BBP
   
   
dbpi24bit:
   
     mov ecx,eax ; B
     cld
   
   dbnewpi:
   
     push ebx
     push edi
     push ecx ; B
   
     mov  ebx,[0x3010]
     movzx ebx,byte[ebx+0xe]
   
     cld
   
     dbnp24:
   
         mov dl,[ds:ebp]
   
         push eax
         push ecx
   
         cmp dl,bl
         jnz dbimp24no
   
         mov eax,[esp+8+3*4+16+4]    ; NoCurrentWin|NoCurrentWin
   
         mov ecx,[esp+5*4]
         cmp ecx,0
         jz dbimp24yes
   
         call voodoodbcplimit
         jnz  dbimp24no
   
       dbimp24yes:
   
         mov  [edi],ax
         shr  eax,16
         mov  [edi+2],al
   
       dbimp24no:
   
         pop ecx
         pop eax
   
         add edi,3                   ; ptrScreen+=3
         inc ebp
   
         dec  ecx
         jnz  dbnp24                 ; while ecx > 0
   
       ;
   
       mov eax,[esp+3*4+16+4]        ; color glide
       test eax,0x80000000
       jz nodbgl24
       cmp al,0
       jz nodbgl24
       dec eax
       mov [esp+3*4+16+4],eax
   
    nodbgl24:
   
     pop ecx ; ecx:=B
     pop edi
     pop ebx
   
     add edi,[BytesPerScanLine] ; ptrScreen+=BytesPerScanLine
   
     add ebp,[ScreenWidth] ;
     sub ebp, ecx ;
     inc ebp ; ptrBuffer:=ptrBuffer-B+BytesPerPixel+1
   
     dec ebx ; H--
     jz dbnonewpi ; H <> 0
     jmp dbnewpi
   
dbnonewpi:
   
     add esp,7*4
     pop ebp
   
     ret
   
   
; DRAWBAR 32 BBP
   
   
dbpi32bit:
   
     cld
     shr ecx,2
   
   dbnewpi32:
   
     push ebx
     push edi
     push ecx
   
     mov   ebx,[0x3010]
     movzx ebx,byte[ebx+0xe]
   
     cld
   
     dbnp32:
   
       mov dl,[ds:ebp]
   
       push eax
       push ecx
   
       cmp dl,bl
       jnz dbimp32no
   
       mov eax,[esp+8+3*4+16+4]
   
       mov ecx,[esp+5*4]
       cmp ecx,0
       jz dbimp32yes
   
       call voodoodbcplimit
       jnz  dbimp32no
   
     dbimp32yes:
   
       mov  [edi],ax
       shr  eax,16
       mov  [edi+2],al
   
     dbimp32no:
   
       pop ecx
       pop eax
   
       add edi,4                ; ptrScreen+=4
       inc ebp
   
       dec ecx
       jnz dbnp32
   
   dbnp32d:
   
     mov eax,[esp+12+16+4]      ; color glide
     test eax,0x80000000
     jz nodbgl32
     cmp al,0
     jz nodbgl32
     dec eax
     mov [esp+12+16+4],eax
   nodbgl32:
   
     pop ecx
     pop edi
     pop ebx
   
     add edi,[BytesPerScanLine]  ; ptrScreen+=BytesPerScanLine
   
     add ebp,[ScreenWidth]       ;
     sub ebp, ecx                ;
     inc ebp                     ; ptrBuffer:=ptrBuffer-B+BytesPerPixel+1
   
     dec ebx                     ; H--
     jz nodbnewpi32              ; H<>0
   
     jmp dbnewpi32
   
   nodbnewpi32:
   
     add esp,7*4
     pop ebp
   
     ret
   
   
   
voodoodbcplimit:
   
; ebp:=(y+Ywin)*(ScreenXSize+1)+(x+Xwin)+AddrBuffer
   
   
     pusha
   
     xor edx,edx
     mov eax,ebp
     mov ebx,[ScreenWidth] ; Screen_X_size
     add ebx,1 ; +1
     sub eax,WinMapAddress ; -AddrBuffer
     div ebx ;
     mov ebx,eax ; ebx:=Y
     mov eax,edx ; eax:=X
     call cplimit
   
     cmp  ecx,0
     jne  dbcpl12
     popa
     clc
     ret
   dbcpl12:
     popa
     stc
     ret
   
   
   
dbcplimit:
   
        pusha
   
        xor  edx,edx
        mov  ebx,[ScreenWidth]
        add  ebx,1
        sub  eax,WinMapAddress
        div  ebx
        mov  ebx,eax
        mov  eax,edx
        call cplimit
   
        cmp  ecx,0
        jne  dbcpl1
        popa
        clc
        ret
     dbcpl1:
        popa
        stc
        ret
   
   
   
   
   
   
;--------------vbe voodoo ------------------------------------------------
vesa20_drawbackground_tiled:

     call disable_mouse
   
     push ebp
     push eax
     push ebx
     push ecx
     push edx
   
     mov edx,dword [WinMapAddress-8] ; B
     add edx,dword [WinMapAddress-8] ; +B
     add edx,dword [WinMapAddress-8] ; +B
     push edx
   
     mov ebp,[draw_data+32+0] ; x start:=(x+Xwin)
     mov ebx,[draw_data+32+4] ; y start:=(y+Ywin)
   
     mov eax,[BytesPerScanLine]
     mul ebx
     xchg ebp, eax  ; BytesPerScanLine*(Ywin+y)
     add ebp, eax   ; +X
     add ebp, eax   ; +X
     add ebp, eax   ; +X
   
     cmp [ScreenBPP],byte 24 ; 24 or 32 bpp ? - x size
     jz bgl243
     add ebp,eax ; +X
   bgl243:
     add ebp,[LFBAddress]  ; +LFB
   
     ; ebp:=Y*BytesPerScanLine+X*BytesPerPixel+AddrLFB
   
     call calculate_edi
   
   
   dp3:                             ; MAIN LOOP
   
     cmp [edi+WinMapAddress],byte 1 ; ptrBuffer^<>byte(1)
     je  ybgp
   
     jmp nbgp
   
   ybgp:
   
     push eax
     push ebx
   
     mov ecx,dword [WinMapAddress-8]    ; B
     xor edx,edx                   ; edx:=0
     div ecx                       ; Xstart/B
   
     ; eax=Int(qn) edx:=Rem
   
     lea esi,[edx+edx*2]           ; esi:=edx*3
   
     mov ecx,dword [WinMapAddress-4]    ; ecx:=H
     mov eax,[esp+0]               ; eax:=Ystart
     xor edx,edx                   ;
     div ecx                       ; Ystart/H
   
     mov eax,edx                   ; eax:=Rem
     xor edx,edx                   ;
     mov ebx,[esp+8]               ; ebx:=B*3
     mul ebx                       ;
     add esi,eax                   ;
     mov eax,[esi+0x300000]
     and eax,0xffffff
   
     xchg edi, ebp
     stosw
     shr eax,16
     stosb
     xchg ebp, edi                 ; ebp+=3
     cmp [ScreenBPP],byte 24       ; 24 or 32 bpp ? - x size
     jz bgl24312
     inc ebp ; +1
   bgl24312:
   
     pop ebx
     pop eax
   
     jmp hook1
   
   nbgp:
     add ebp,3                     ; +3
     cmp [ScreenBPP],byte 24       ; 24 or 32 bpp ? - x size
     jz bgl243121
     inc ebp ; +1
   bgl243121:
   
   hook1:
   
     inc edi                       ; ptrBuffer++
     add esi,3                     ; ptrImage+=3
     inc eax
     cmp eax,[draw_data+32+8]         ; X > xend?
     jg nodp3
     jmp dp3
   
   nodp3:
   
     mov ebp,[draw_data+32+0]
   
     inc ebx
   
     mov  eax,[BytesPerScanLine]
     mul  ebx
     xchg ebp, eax                 ; BytesPerScanLine*(Ywin+y)
     add  ebp, eax                 ; +X
     add  ebp, eax                 ; +X=X*2
     add  ebp, eax                 ; +X=X*3
     cmp  [ScreenBPP],byte 24      ; 24 or 32 bpp ? - x size
     jz   bgl2431
     add  ebp,eax                  ; +X=X*4
   bgl2431:
     add ebp,[LFBAddress]          ; +LFB
   
     ; ebp:=Y*BytesPerScanLine+X*BytesPerPixel+AddrLFB
   
     call calculate_edi
   
     cmp ebx,[draw_data+32+12]
     jg  dp4
   
     jmp dp3
   
   dp4:
   
     add esp,4
   
     pop edx
     pop ecx
     pop ebx
     pop eax
     pop ebp
   
     ret
   
; ----------
   
   
   
vesa20_drawbackground_stretch:

     call  disable_mouse
   
     push ebp
     push eax
     push ebx
     push ecx
     push edx
   
     mov edx,dword [WinMapAddress-8] ; B
     add edx,dword [WinMapAddress-8] ; +B
     add edx,dword [WinMapAddress-8] ; +B
     push edx
   
     mov ebp,[draw_data+32+0] ; x start:=(x+Xwin)
     mov ebx,[draw_data+32+4] ; y start:=(y+Ywin)
   
     mov eax,[BytesPerScanLine]
     mul ebx
     xchg ebp, eax  ; BytesPerScanLine*(Ywin+y)
     add ebp, eax   ; +X
     add ebp, eax   ; +X
     add ebp, eax   ; +X
   
     cmp [ScreenBPP],byte 24 ; 24 or 32 bpp ? - x size
     jz  sbgl243
     add ebp,eax ; +X
   sbgl243:
     add ebp,[LFBAddress] ; +LFB
   
     ; ebp:=Y*BytesPerScanLine+X*BytesPerPixel+AddrLFB
   
     call calculate_edi
   
   
   sdp3:                            ; MAIN LOOP
   
     cmp [edi+WinMapAddress],byte 1     ; ptrBuffer^<>byte(1)
     je  sybgp
   
     jmp snbgp
   
   sybgp:
   
     push eax
     push ebx
   
     mov   eax,dword [WinMapAddress-8]
     xor   edx,edx
     mov   ebx,[esp+4]
     mul   ebx
     xor   edx,edx
     mov   ebx,[ScreenWidth]
     div   ebx
     lea   esi,[eax+eax*2]
     mov   eax,dword [WinMapAddress-4]
     xor   edx,edx
     mov   ebx,[esp+0]
     mul   ebx
     xor   edx,edx
     mov   ebx,[ScreenHeight]
     div   ebx
   
     xor   edx,edx
     mov   ebx,[esp+8]
     mul   ebx
     add   esi,eax
     mov   eax,[esi+0x300000]
     and   eax,0xffffff
   
     xchg edi, ebp
     stosw
     shr eax,16
     stosb
     xchg ebp, edi                 ; ebp+=3
     cmp [ScreenBPP],byte 24       ; 24 or 32 bpp ? - x size
     jz  sbgl24312
     inc ebp ; +1
   sbgl24312:
   
     pop ebx
     pop eax
   
     jmp shook1
   
   snbgp:
     add  ebp,3                     ; +3
     cmp [ScreenBPP],byte 24        ; 24 or 32 bpp ? - x size
     jz  sbgl243121
     inc ebp ; +1
   sbgl243121:
   
   shook1:
   
     inc edi                       ; ptrBuffer++
     add esi,3                     ; ptrImage+=3
     inc eax
     cmp eax,[draw_data+32+8]         ; X > xend?
     jg  snodp3
     jmp sdp3
   
   snodp3:
   
     mov ebp,[draw_data+32+0]
   
     inc ebx
   
     mov  eax,[BytesPerScanLine]
     mul  ebx
     xchg ebp, eax                 ; BytesPerScanLine*(Ywin+y)
     add  ebp, eax                 ; +X
     add  ebp, eax                 ; +X=X*2
     add  ebp, eax                 ; +X=X*3
     cmp  [ScreenBPP],byte 24      ; 24 or 32 bpp ? - x size
     jz   sbgl2431
     add  ebp,eax                  ; +X=X*4
   sbgl2431:
     add ebp,[LFBAddress]          ; +LFB
   
     ; ebp:=Y*BytesPerScanLine+X*BytesPerPixel+AddrLFB
   
     call calculate_edi
   
     cmp ebx,[draw_data+32+12]
     jg  sdp4
   
     jmp sdp3
   
   sdp4:
   
     add esp,4
   
     pop edx
     pop ecx
     pop ebx
     pop eax
     pop ebp
   
     ret
   
   
   
   
   
