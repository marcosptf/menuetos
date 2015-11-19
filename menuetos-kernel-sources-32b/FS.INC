;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   Fs.inc (c) Ville Turjanmaa
;;   License: GPL. See file copying for details.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


dir0:        db  'HD         '
             db  'FD         '
             db  0
   
dir1:        db  '1          '
             db  '2          '
             db  '3          '
             db  '4          '
             db  0
   

hd_address_table:  dd  0x1f0,0x00,0x1f0,0x10
                   dd  0x170,0x00,0x170,0x10

file_system:
   
; IN:
;
; eax = 0  ; read file          /RamDisk/First  6   /HardDisk/First 30
; eax = 1  ; write file         /RamDisk/First 33   /HardDisk/First 56
; eax = 2  ; delete file        /RamDisk/First 32   /HardDisk/First 57
; eax = 3  ; append to a file   /RamDisk/First ??   /HardDisk/First ??
; eax = 8  ; lba read
;   
; OUT:
;
; eax = 0 : read ok
; eax = 1 : no fd base and/or partition defined
; eax = 2 : yet unsupported FS
; eax = 3 : unknown FS
; eax = 4 : partition not defined at hd
; eax = 5 : file not found
; eax = 6 : end of file
; eax = 7 : memory pointer not in application area
;
; ebx = size

    ; Extract parameters
   
    mov  edi,[0x3010]
    add  eax,[edi+0x10]    ;  abs start of info block
   
    cmp  [eax+0],dword 16  ; dont care about read&write blocks
    je   fs_read
   
    cmp  [0x3000],dword 1  ; no memory checks for kernel requests
    je   no_checks_for_kernel

    mov  ebx,[0x3000]      ; pointer in application memory ?
    imul ebx,256
    add  ebx,0x80000
    mov  ebx,[ebx+0x8c]

    mov  ebp,ebx           ; save for checking at stack save
    sub  ebp,[eax+12]
    shr  ebp,9

    sub  ebx,512           ; need atleast one block

    cmp  ebx,[eax+12]
    ja   area_in_app_mem
    mov  eax,7
    mov  [esp+36],dword 7
    ret
  area_in_app_mem:

  no_checks_for_kernel:


    cmp  [eax+8],dword 0   ;  read or write 0 blocks/bytes ?
    jne  fs_read
    mov  [esp+36],dword 0
    ret
  fs_read:
   
    mov  ebx,[eax+20]     ;  program wants root directory ?
    cmp  bl,0
    je   fs_getroot
    cmp  bh,0
    je   fs_getroot
    jmp  fs_noroot
  fs_getroot:
    mov  edx,[edi+0x10]
    mov  esi,dir0
    mov  edi,[eax+12]
    add  edi,edx
    mov  ecx,11
    cld
    rep  movsb
    mov  eax,0x10
    stosb
    add  edi,32-11-1
    mov  ecx,11
    cld
    rep  movsb
    stosb
    mov  [esp+36],dword 0       ; ok read
    mov  [esp+24],dword 32*2    ; size of root
    ret

  fs_noroot:
   
    mov  ebx,[eax+0]
    push ebx              ;  read/write/delete/append
    mov  ebx,[eax+4]
    push ebx              ;  512 block number to read
    mov  ebx,[eax+8]

    cmp  [eax+0],dword 0  ; if read, check that the data stays at
    jne  ret_size_fine    ; application memory
    cmp  ebx,ebp
    jbe  ret_size_fine
    mov  ebx,ebp
  ret_size_fine:         

    push ebx              ;  bytes to write/append or 512 blocks to read
    mov  ebx,[eax+12]
    add  ebx,[edi+0x10]
    push ebx              ;  abs start of return/save area

    mov  ebx,eax
    add  ebx,20           ;  abs start of dir + filename
    mov  esi,[eax+16]
    add  esi,[edi+0x10]   ;  abs start of work area
   
    ; Extract directory to work area
    ; 0-127 : directory & file : / 11 + / 11 + / 11 - zero terminated
   
    mov  edi,esi
    mov  eax,32
    mov  ecx,127
    cld
    rep  stosb
   
    mov  ecx,9
    mov  eax,0
  filesys_l6:
    mov  [esi+eax],byte '/'
    add  eax,12
    loop filesys_l6
   
    xor  eax,eax
   
    push esi
    push esi
   
  filesys_l1:
   
    inc ebx
   
    cmp [ebx],byte 0
    je  filesys_d1
   
    cmp [ebx],byte '.'
    jne filesys_l2
    mov esi,[esp]
    add esi,8
    jmp filesys_l1
  filesys_l2:
   
    cmp [ebx],byte '/'
    je  filesys_d2
   
    mov  al,[ebx]
    cmp  eax,0x60
    jb   filesys_l3
    sub  eax,0x20
  filesys_l3:
    mov  [esi+1],al
    inc  esi
   
    cmp  esi,edi
    jge  filesys_d1
   
    jmp  filesys_l1
   
  filesys_d2:
   
    add  [esp],dword 12
    mov  esi,[esp]
   
    jmp  filesys_l1
   
  filesys_d1:
   
    mov  esi,[esp]
    mov  [esi+12],byte 0
                           ; [esp+0] ; name of file start
                           ; [esp+4] ; dir start
    mov  edi,[esp+4]
   
    mov  ebx,[dir0+11]     ; /RAMDISK and FLOPPY
    mov  eax,[edi+1]

    cmp  eax,'FD  '
    je   fdtord
    cmp  eax,'fd  '
    je   fdtord
    cmp  eax,'fD  '
    je   fdtord
    cmp  eax,'Fd  '
    je   fdtord
    jmp  nofdtord
  fdtord:
    mov  eax,'RD  '
  nofdtord:

    cmp  eax,'RD  '
    je   fs_yesramdisk
    cmp  eax,ebx
    jne  fs_noramdisk
   
  fs_yesramdisk:
   
    cmp  [edi+1+11],byte 0
    je   fs_give_dir1
   
    mov  ebx,[dir1]        ; /FIRST
    mov  eax,[edi+1+12]
    cmp  eax,'1   '
    je   fs_yesramdisk_first
    cmp  eax,ebx
    jne  fs_noramdisk
   
  fs_yesramdisk_first:

    cmp  [esp+20],dword 8  ; LBA read ramdisk
    jne  fs_no_LBA_read_ramdisk

    mov  eax,[esp+16]      ; LBA block to read
    mov  ecx,[esp+8]       ; abs pointer to return area

    call LBA_read_ramdisk
    jmp  file_system_return
   
  fs_no_LBA_read_ramdisk:


    cmp  [esp+20],dword 0  ; READ
    jne  fs_noramdisk_read
   
    mov  eax,[esp+4]  ; fname
    add  eax,2*12+1
    mov  ebx,[esp+16] ; block start
    inc  ebx
    mov  ecx,[esp+12] ; block count
    mov  edx,[esp+8]  ; return
    mov  esi,[esp+0]
    sub  esi,eax
    add  esi,12+1     ; file name length
    call fileread
   
    jmp  file_system_return
   
   fs_noramdisk_read:
   
   
    cmp  [esp+20],dword 1  ; WRITE
    jne  fs_noramdisk_write
   
    mov  eax,[esp+4]  ; fname
    add  eax,2*12+1
    mov  ebx,[esp+8]  ; buffer
    mov  ecx,[esp+12] ; count to write
    mov  edx,0        ; create new
    call filesave

    ; eax=0 ok - eax=1 not enough free space
   
    jmp  file_system_return
   
  fs_noramdisk_write:
   
    cmp  [esp+20],dword 16  ; START APPLICATION
    jne  fs_noramdisk_start_application
   
    mov  eax,[esp+4]  ; fname
    add  eax,2*12+1

    mov  ebx,0        ; parameters to pass
    cmp  [esp+12],dword 0
    je   no_fl_start_param
    mov  ebx,[0x3010]
    mov  ebx,[ebx+0x10]
    add  ebx,[esp+12]
  no_fl_start_param:

    call start_application_fl
   
    jmp  file_system_return
   
  fs_noramdisk_start_application:
   
  fs_noramdisk:
   
   
    mov  ebx,[dir0]        ; /HARDDISK
    mov  eax,[edi+1]
    cmp  eax,'HD  '
    je   fs_yesharddisk
    cmp  eax,ebx
    jne  fs_noharddisk
   
  fs_yesharddisk:
   
    cmp  [esp+20],dword 8  ; LBA read
    jne  fs_no_LBA_read    ;
    mov  eax,[esp+16]      ; LBA block to read
    mov  ebx,edi           ;
    add  ebx,1+12          ; pointer to FIRST/SECOND/THIRD/FOURTH
    mov  ecx,[esp+8]       ; abs pointer to return area
    call LBA_read          ;
    jmp  file_system_return
   
  fs_no_LBA_read:
   
    cmp  [edi+1+11],byte 0 ; directory read
    je   fs_give_dir1
   
    mov  ebx,[dir1]        ; /FIRST
    mov  eax,[edi+1+12]
    cmp  eax,'1   '
    je   fs_yesharddisk_first
    cmp  eax,ebx
    jne  fs_noharddisk
   
  fs_yesharddisk_first:
   
    cmp  [esp+20],dword 0  ; READ
    jne  fs_noharddisk_read
   
    mov  edi,[esp+0]
    mov  [edi],byte 0 ; zero terminated path

    mov  eax,[esp+4]
    add  eax,12*2
    mov  edi,[esp+0]
    sub  edi,eax
    add  edi,12       ; file length

    mov  eax,[esp+0]  
    inc  eax          ; filename start

    mov  ebx,[esp+12] ; count to read
    mov  ecx,[esp+8]  ; buffer
    mov  edx,[esp+4]
    add  edx,12*2     ; dir start
    mov  esi,[esp+16] ; blocks to read
  
    call file_read

    mov  edi,[esp+0]
    mov  [edi],byte '/' ; 

    jmp  file_system_return
   
   fs_noharddisk_read:
   
   
    cmp  [esp+20],dword 1  ; WRITE
    jne  fs_noharddisk_write
   
    mov  eax,[esp+0]  ; fname
    inc  eax
   
    mov  ebx,[esp+12] ; count to write
    mov  ecx,[esp+8]  ; buffer
    mov  edi,[esp+0]
    mov  [edi],byte 0
    mov  edx,[esp+4]
    add  edx,12*2
  
    call file_write

    mov  edi,[esp+0]
    mov  [edi],byte '/' ; 

    ; eax=0 ok - eax=1 not enough free space

    jmp  file_system_return
   
   
  fs_noharddisk_write:
   
   
    cmp  [esp+20],dword 16       ; START APPLICATION
    jne  fs_noharddisk_start_application
   
    mov  eax,[esp+4]  ; fname
    add  eax,12*2
   
    mov  ebx,[esp+0]  ; length
    sub  ebx,eax
    add  ebx,12
   
    mov  ecx,[esp+4]  ; work area
    add  ecx,512

    mov  ebp,0        ; parameters to pass
    cmp  [esp+12],dword 0
    je   no_hd_start_param
    mov  ebp,[0x3010]
    mov  ebp,[ebp+0x10]
    add  ebp,[esp+12]
  no_hd_start_param:

    call start_application_hd
   
    jmp  file_system_return
   
  fs_noharddisk_start_application:
   
  fs_noharddisk:
   
  file_system_return:
   
    add  esp,24
   
    mov  [esp+36],eax
    mov  [esp+24],ebx
   
    ret
   
   
  fs_give_dir1:
   
     mov  eax,0x10
     mov  ebx,1
     mov  edi,[esp+8]
     mov  esi,dir1
   fs_d1_new:
     mov  ecx,11
     cld
     rep  movsb
     stosb
     add  edi,32-11-1
     dec  ebx
     jnz  fs_d1_new
   
     add  esp,24
   
     mov  [esp+36],dword 0      ; ok read
     mov  [esp+24],dword 32*1   ; dir/data size
     ret



LBA_read_ramdisk:

     cmp  [lba_read_enabled],1
     je   lbarrl1

     mov  ebx,0
     mov  eax,2
     ret

  lbarrl1:

     cmp  eax,18*2*80
     jb   lbarrl2
     mov  ebx,0
     mov  eax,3
     ret

  lbarrl2:

     pusha

     call   restorefatchain

     mov    edi,ecx
     mov    esi,eax

     imul   esi,512
     add    esi,0x100000
     mov    ecx,512
     cld
     rep    movsb

     popa

     mov  eax,0
     mov  ebx,0

     ret
   

LBA_read:
   
; IN:    
;
; eax = LBA block to read
; ebx = pointer to FIRST/SECOND/THIRD/FOURTH
; ecx = abs pointer to return area
   
     cmp  [lba_read_enabled],1
     je   lbarl1
     mov  eax,2
     ret
   
   lbarl1:
   
     cli
     cmp  [hd1_status],0
     je   lbarok

     sti
     call change_task
     jmp  lbarl1

   lbarok:

     call reserve_hd1
     
     sti
   
     push eax
     push ecx
   
     mov  edi,hd_address_table
     mov  esi,dir1
     mov  ecx,4
   blar0:
     mov  eax,[esi]
     cmp  [ebx],eax
     jne  blar1
     mov  eax,[edi+0]
     mov  ebx,[edi+4]
     jmp  blar2
   blar1:
     add  edi,8
     add  esi,11
     loop blar0
   
     mov  eax,1
     mov  ebx,1
     jmp  LBA_read_ret
   
   blar2:
   
     call wait_for_hd_idle

     ; eax = hd port
     ; ebx = set for primary (0x00) or slave (0x10)

     cli
   
     mov   edx,eax
     add   edx,1
     xor   eax,eax
     out   dx,al
     add   edx,1
     mov   al,1
     out   dx,al
     add   edx,1
     mov   al,[esp+4]
     out   dx,al
     add   edx,1
     mov   al,[esp+5]
     out   dx,al
     add   edx,1
     mov   al,[esp+6]
     out   dx,al
   
     add   edx,1
     mov   al,[esp+7]
     and   al,1+2+4+8
     add   al,bl
     add   al,128+64+32
     out   dx,al
   
     add   edx,1
     mov   al,20h
     out   dx,al

     sti
   
     call  wait_for_sector_buffer
   
     cli

     mov   edi,[esp+0]
     mov   ecx,256
     sub   edx,7
    LBA_hd_data:
     in    ax,dx
     stosw
     loop  LBA_hd_data
   
     sti

     xor   eax,eax
     xor   ebx,ebx
   
   LBA_read_ret:
   
     mov  [hd1_status],0
     add  esp,2*4
   
     ret
   

