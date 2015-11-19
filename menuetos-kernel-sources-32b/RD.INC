;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   Rd.inc (c) Ville Turjanmaa
;;   License: GPL. See file copying for details.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ramdisk_free_space:    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   returns free space in edi
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        push   eax ebx ecx

        mov    eax,fat_table
        xor    edi,edi
        mov    ecx,1448000/512
      rdfs1:
        mov    ebx,[eax]
        and    ebx,4095
        cmp    ebx,0
        jne    rdfs2
        add    edi,512
      rdfs2:
        add    eax,2
        loop   rdfs1

        pop    ecx ebx eax
        ret
   

expand_filename:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; exapand filename with '.' to 11 character
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        push esi edi ebx

        mov  esi,eax

        mov  edi,esp                  ; check for '.' in the name
        add  edi,12+8
        mov  eax,edi

        mov  [eax+0],dword '    '
        mov  [eax+4],dword '    '
        mov  [eax+8],dword '    '
   
      flr1:
   
        cmp  [esi],byte '.'
        jne  flr2
        mov  edi,eax
        add  edi,7
        jmp  flr3
   
      flr2:
   
        mov  bl,[esi]
        mov  [edi],bl
   
      flr3:
   
        inc  esi
        inc  edi
   
        mov  ebx,eax
        add  ebx,11
   
        cmp  edi,ebx
        jbe  flr1
   
        pop  ebx edi esi
        ret
   
   
fileread:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  fileread - sys floppy
;
;  eax  points to filename 11 chars
;  ebx  first wanted block       ; 1+ ; if 0 then set to 1
;  ecx  number of blocks to read ; 1+ ; if 0 then set to 1
;  edx  mem location to return data
;  esi  length of filename 12*X
;
;  ret ebx = size or 0xffffffff file not found
;      eax = 0 ok read or other = errormsg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;     push   esi
   ;     mov    esi,eax
   ;     push   dword [esi+11]
   ;     mov    [esi+11],byte 13
   ;     mov    [esi+12],byte 10
   ;     mov    [esi+13],byte 10
   ;     push   esi
   ;     call   sys_msg_board_str
   ;     pop    esi
   ;     pop    dword [esi+11]
   ;     pop    esi

        cmp    esi,0               ; return ramdisk root
        jne    fr_noroot
        cmp    ebx,224/16
        jbe    fr_do
        mov    eax,5
        mov    ebx,0
        ret
      fr_do:
        mov    edi,edx
        dec    ebx
        shl    ebx,9
        mov    esi,fat_base+512*19
        add    esi,ebx
        shl    ecx,9
        cld
        rep    movsb
        mov    eax,0 ; ok read
        mov    ebx,0
        ret
     fr_noroot:
   
        sub    esp,32
        push   eax ecx edi
        mov    edi , esp
        add    edi , 3*4
        mov    ecx , 32
        mov    eax , 0
        cld
        rep    stosb
        pop    edi ecx eax
        call   expand_filename
   
      frfloppy:

        ; Read starts at block no1
   
        cmp    ebx,0
        jne    frfl5
        mov    ebx,1
      frfl5:

        ; Return 1+ blocks

        cmp    ecx,0
        jne    frfl6
        mov    ecx,1
      frfl6:
   
        dec    ebx
   
        push   eax ; 24 file size
        push   eax ; 20 file size
        push   ebx ; 16 first wanted block
        push   ecx ; 12 amount of 512 blocks to read
        push   edx ; 08 return data to
        push   esi
        push   edi

        mov    edi,fat_base+512*18+512  ;Point at directory
        mov    edx,224 +1
   
l.20:   dec    edx
        jnz    l.21
        mov    eax,5                    ; file not found
        mov    ebx,-1

        add    esp,32+28
        ret

      fd_file_not_found: db 'File not found',13,10,0
      fd_file_found: db 'File found',13,10,0

      l.21:

  ;      mov    esi,eax                  ;Name of file we want
  ;      mov    ecx,11
  ;      cld
  ;      rep    cmpsb                    ;Found the file?
  ;      je     fifound                  ;Yes
  ;      add    cl, 21                   ;Offset to next directory entry
  ;      add    edi, ecx                 ;Advance to next entry

        mov    ecx , [eax]
        cmp    ecx , [edi]
        jne    noflf
        mov    ecx , [eax+4]
        cmp    ecx , [edi+4]
        jne    noflf
        mov    ecx , [eax+7]
        cmp    ecx , [edi+7]
        jne    noflf
        add    edi , 11
        jmp    fifound
      noflf:

        add    edi , 32

        jmp    l.20
   
     fifound:
   
        mov    ebx,[edi-11+28]          ;file size
        and    ebx,0x1fffff 
        mov    [esp+20],ebx
        mov    [esp+24],ebx
        mov    eax,[edi-11+26]
        and    eax,65535
        mov    edi,eax                  ;edi=cluster
   
      frnew:
   
        add    eax,31                   ;bootsector+2*fat+filenames
        shl    eax,9                    ;*512
        add    eax,fat_base             ;image base
        mov    ebx,[esp+8]
        mov    ecx,512                  ;[esp+4]
   
        cmp    [esp+16],dword 0         ;Wanted 512 byte block ?
        jne    frfl7

        push   ecx esi edi
        mov    esi , eax
        mov    edi , ebx
        mov    ecx , 512
        cld
        rep    movsb
        pop    edi esi ecx
        ; call memmove

        add    [esp+8],dword 512
        dec    dword [esp+12]           ;last wanted cluster ?
        cmp    [esp+12],dword 0 ; 0.80
        je     frnoread
        jmp    frfl8
      frfl7:
        dec    dword [esp+16]
      frfl8:
        shl    edi,1                    ;find next cluster from FAT
        add    edi,fat_table  ; 0xD80000 ;  0x280000
        mov    eax,[edi]
        and    eax,4095
        mov    edi,eax
        cmp    edi,4095                 ;eof  - cluster
        jz     frnoread2
   
        cmp    [esp+24],dword 512       ;eof  - size
        jb     frnoread
        sub    [esp+24],dword 512
   
        jmp    frnew

      frnoread2:

        cmp    [esp+16],dword 0         ; eof without read ?
        je     frnoread

        pop    edi
        pop    esi
        pop    edx
        pop    ecx
        pop    ebx
        pop    ebx     ; ebx <- eax : size of file

        add    esp,32+4

        mov    eax,6   ; end of file
        ret

      frnoread:
   
        pop    edi esi edx ecx
        add    esp,4
        pop    ebx     ; ebx <- eax : size of file
        add    esp,36
        mov    eax,0
        ret
   
filedelete:   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; filedelete - sys floppy
;
; in:
; eax - filename 11 chars
;
; out:
; eax - 0 = successful, 1 = file not found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        mov    ebp,1  ; file not found as default

      filedelete_newtry:

        sub    esp,32
        call   expand_filename
   
        push   eax ebx ecx edx esi edi

        mov    edi,fat_base+512*18+512  ;Point at directory
        mov    edx,224 +1
   
     l20d:
        sub    edx,1
        cmp    edx,0
        jnz    l21d
        jmp    frnoreadd
     l21d:
        mov    esi,eax                  ;Name of file we want
        mov    ecx, 11
        cld
        rep    cmpsb                    ;Found the file?
        je     fifoundd                 ;Yes
        add    cl, 21                   ;Offset to next directory entry
        add    edi, ecx                 ;Advance to next entry
        jmp    l20d
     fifoundd:
   
        mov    [edi-11],byte 0xE5       ;mark filename deleted
        add    edi,0xf
        mov    eax,[edi]
        and    eax,65535
        mov    edi,eax                  ;edi = cluster
   
      frnewd:
   
        shl    edi,1                    ;find next cluster from FAT
        add    edi,fat_table ; 0x280000
        mov    eax,[edi]
        mov    [edi],word 0x0           ;clear fat chain cluster
        and    eax,4095
        mov    edi,eax
        cmp    edi,dword 4095           ;last cluster ?
        jz     frnoreadd2
   
        jmp    frnewd
   
      frnoreadd2:
   
        pop    edi esi edx ecx ebx eax
        add    esp,32
        mov    ebp,0       ; file found
        jmp    filedelete_newtry
   
      frnoreadd:
   
        pop    edi esi edx ecx ebx eax
        add    esp,32
        mov    eax,ebp
        ret
   
filesave:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
; filesave - sys floppy
;
; eax points to filename 11 chars
;
;        eax      ; pointer to file name
;        ebx      ; buffer
;        ecx      ; count to write in bytes
;        edx      ; 0 create new , 1 append
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
        sub  esp,32
        call expand_filename
        cmp  edx,0
        jnz  fsdel
        pusha
        call filedelete
        popa
   
      fsdel:
   
        call   ramdisk_free_space
        cmp    ecx,edi
        jb     rd_do_save
        add    esp,32
        mov    eax,1    ; not enough free space
        ret
   
      rd_do_save:
   
        push   eax ebx ecx edx esi edi

        mov    edi,fat_base+512*18+512  ;Point at directory
        mov    edx,224 +1
        ; find an empty spot for filename in the root dir
     l20ds:
        sub    edx,1
        cmp    edx,0
        jnz    l21ds
        jmp    frnoreadds
     l21ds:
        cmp    [edi],byte 0xE5
        jz     fifoundds
        cmp    [edi],byte 0x0
        jz     fifoundds
        add    edi,32                   ; Advance to next entry
        jmp    l20ds
     fifoundds:
   
        push   edi                      ; move the filename to root dir
        mov    esi,[esp+4+20]
        mov    ecx,11
        cld
        rep    movsb
        pop    edi
        mov    edx,edi
        add    edx,11+0xf               ; edx <- cluster save position
        mov    ebx,[esp+12]             ; save file size
        mov    [edi+28],ebx
        mov    [edi+11],byte 0x20       ; attribute
        mov    ebx,1                    ; first cluster
   
      frnewds:
   
        add    ebx,1
        mov    edi,ebx                  ; find free cluster in FAT
        shl    edi,1
        add    edi,fat_table ;0x280000
        mov    eax,[edi]
        and    eax,4095
        cmp    eax,0x0
        jnz    frnewds
        mov    [edx],bx                 ; save next cluster pos. to prev cl.
        mov    edx,edi                  ; next save pos abs mem add
        call   fdc_filesave
        pusha                           ; move save to floppy cluster
        add    ebx,31
        shl    ebx,9
        add    ebx,fat_base
        mov    eax,[esp+32+16]
        mov    ecx,512
        call   memmove
        popa
   
        mov    eax,[esp+12]
        cmp    eax,512
        jb     flnsa
        sub    eax,512
        mov    [esp+12],eax
        mov    eax,[esp+16]
        add    eax,512
        mov    [esp+16],eax
        jmp    frnewds
   
     flnsa:
        mov    [edi],word 4095          ; mark end of file - last cluster
   
      frnoreadds:
   
        pop    edi esi edx ecx ebx eax
        add    esp,32

        pusha
        cli
        call   fdc_commitfile
        sti
        popa

        mov    eax,0
        ret



