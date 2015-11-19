;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                 ;;
;;  FAT32.INC                                                      ;;
;;                                                                 ;;
;;  FAT32 functions for MenuetOS                                   ;;
;;                                                                 ;;
;;  Copyright 2002 Paolo Minazzi, paolo.minazzi@inwind.it          ;;
;;                                                                 ;;
;;  See file COPYING for details                                   ;;
;;                                                                 ;;
;;  10.9.2004  Fat16 file system - Mario79                         ;;
;;  06.9.2004  Fix free space by Mario79 added - MH                ;;
;;  24.5.2004  Write back buffer for File_write - VT               ;;
;;  20.5.2004  File_read function to work with syscall 58 - VT     ;;
;;  30.3.2004  Error parameters at function return - VT            ;;
;;  01.5.2002  Bugfix in device write - VT                         ;;
;;  20.5.2002  Hd status check - VT                                ;;
;;  29.6.2002  Improved fat32 verification - VT                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;       CLUSTER[0]  CLUSTER[1]  CLUSTER[2] CLUSTER[3]
;
;###    ######## -->######## -->########   ########
;#2#--> #      # |  #      # |  #      #   #      #
;###    #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #          CLUSTER
;       #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #
;       #      # |  #      # |  #      #   #      #
;       ######## |  ######## |  ########   ########
;                |           |
;                |           ------------------
;                |                            |
;                --------------------         |
;                                   |         |
;      ########    ########    ########   ########
;      # xxxx #    # xxxx #    #   3  #   #   4  #
;      ########    ########    ########   ########          FAT
;
;       FAT[0]       FAT[1]      FAT[2]    FAT[3]
;

cache_max equ 1000

RESERVED_SECTOR:     dd 0x20
PARTITION_START:     dd 0x3f
FAT32_SIZE:          dd 0x1f3a
NUMBER_OF_FATS:      dd 0x2
SECTOR_PER_CLUSTER:  dd 0x8
ROOT_CLUSTER:        dd 2
buffer:              times 64 dd 0,0
cluster:             dd 0
cluster1:            dd 0
valid_fat:           db 0
PARTITION_SIZE:      dd 0
PARTITION_END:       dd 0

hd_error             dd 0
hd_setup             dd 0

;***********************
;*         Start       *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.1      *
;***********************
FILE_SIZE:           dd 0
ADR_FSINFO:          dd 0
change_mem           db 0
old_size_file:       dd 0
;***********************
;*         End         *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.1      *
;***********************

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.1      *
;***********************
fs_type              dd 0
file_or_directory    dd 0
analyze_f16          db 0
correct_fat16        dd 0
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.1      *
;***********************

reserve_hd1:

    push  eax
    mov   eax,[0x3000]
    imul  eax,32
    add   eax,0x3000
    mov   eax,[eax+4]
    mov   [hd1_status],eax
    pop   eax

    ret

clear_hd_cache:

    pusha
    mov   edi,0x600000
    mov   ecx,65535
    mov   eax,0
    cld
    rep   stosb
    popa

    ret


set_FAT32_variables:

    cli
    cmp   [hd1_status],0
    je    set_fat32_l1

    sti
    call  change_task
    jmp   set_FAT32_variables

  set_fat32_l1:

    call  reserve_hd1

    sti

    call  clear_hd_cache

    cmp   dword [hdpos],0
    je    problem_hd_or_partition_or_fat32_ret

    push  eax
    push  ebx

    xor   eax,eax                        ; Read MBR
    mov   ebx,buffer
    call  hd_read

    cmp   dword [fat32part],0
    jnz   hd_and_partition_ok

problem_hd_or_partition_or_fat32:

    pop   ebx
    pop   eax

problem_hd_or_partition_or_fat32_ret:

    mov   [valid_fat],byte 0
    mov   [hd1_status],0 ; free

    ret

hd_and_partition_ok:

    mov   ecx,[fat32part]
    mov   eax,0
    mov   ebx,buffer+0x1be+8  -16
  hdapl1:
    add   ebx,16
    add   eax,[ebx]
    loop  hdapl1

    mov   [PARTITION_START],eax
    mov   ebx,[ebx+4]
    mov   [PARTITION_SIZE],ebx

    mov   [hd_setup],1
    mov   ebx,buffer
    call  hd_read ;_new        ; Read boot sector of partition
    mov   [hd_setup],0

    cmp   [ebx+0x53],dword 'AT32'
    ; jnz  problem_hd_or_partition_or_fat32
    jnz   problem_hd_or_partition_or_fat32_1

    mov   [valid_fat],byte 1
    movzx eax,word [ebx+0xe]
    mov   [RESERVED_SECTOR],eax
    mov   eax,[ebx+0x24]
    mov   [FAT32_SIZE],eax
    movzx eax,byte [ebx+0x10]
    mov   [NUMBER_OF_FATS],eax
    movzx eax,byte [ebx+0xd]
    mov   [SECTOR_PER_CLUSTER],eax
    mov   eax,[ebx+44]
    mov   [ROOT_CLUSTER],eax
    mov   eax,[PARTITION_START]
    add   eax,[PARTITION_SIZE]
    dec   eax
    mov   [PARTITION_END],eax
    pop   ebx
    pop   eax

;    mov [hd1_status],0   ; free
;    ret
;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.2      *
;***********************

    mov   [fs_type],1      ; 1 -Fat32
    mov   [hd1_status],0   ; free
    ret

problem_hd_or_partition_or_fat32_1:

    cmp   [ebx+55],dword 'AT16'
    je    par_fat16
    jmp   problem_hd_or_partition_or_fat32

par_fat16:

    mov   [valid_fat],byte 1
    movzx eax,word [ebx+0xe]
    mov   [RESERVED_SECTOR],eax
    movzx eax,word [ebx+0x16]
    mov   [FAT32_SIZE],eax
    movzx eax,byte [ebx+0x10]
    mov   [NUMBER_OF_FATS],eax
    movzx eax,byte [ebx+0xd]
    mov   [SECTOR_PER_CLUSTER],eax

    xor   eax,eax
    mov   [ROOT_CLUSTER],eax
    mov   eax,[PARTITION_START]
    add   eax,[PARTITION_SIZE]
    dec   eax
    mov   [PARTITION_END],eax

    mov   eax,[SECTOR_PER_CLUSTER]
    shl   eax,1
    mov   ebx,32
    sub   ebx,eax
    mov   [correct_fat16],ebx

    pop   ebx
    pop   eax

    mov   [fs_type],2      ; 2 - Fat16
    mov   [hd1_status],0   ; Free
    ret

;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.2      *
;***********************

set_FAT:
;--------------------------------
; set_FAT
;
; input :  EAX = #block
;          EDX = value to save
; output:  nothing
;--------------------------------

    push  eax  ; [esp+16]
    push  ebx  ; [esp+12]
    push  ecx  ; [esp+8]
    push  edx  ; [esp+4]
    push  esi  ; [esp]

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.3      *
;***********************

    cmp [fs_type],1
    je correct3_11
    shl eax,1
    jmp  correct3_12
correct3_11:
    shl eax,2
correct3_12:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.3      *
;***********************

    xor edx,edx
    mov ebx,512
    div ebx
    mov esi,edx

    add eax,[RESERVED_SECTOR]
    add eax,[PARTITION_START]
    mov ebx,buffer

    mov ecx,[NUMBER_OF_FATS]
    mov edx,[esp+4]

set_an_other_FAT:

    call hd_read ;_new

    cmp  [f_del],1
    je   fat_zero

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.4      *
;***********************

    cmp [fs_type],1
    je correct3_11_1
    cmp  [buffer+esi],word 0
    je   fat_zero
    jmp  correct3_12_1
correct3_11_1:
   cmp  [buffer+esi],dword 0
   je   fat_zero
correct3_12_1:
   mov  [8*0x100000],dword 0xffffff
   jmp  fat_nonzero
fat_zero:
  cmp [fs_type],1
  je correct3_13_3
   mov [buffer+esi],dx
   jmp correct3_13_4
correct3_13_3:
   mov [buffer+esi],edx
correct3_13_4:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.4      *
;***********************

   call hd_write_new

  fat_nonzero:

   add eax,[FAT32_SIZE]
   loop set_an_other_FAT

   pop esi
   pop edx
   pop ecx
   pop ebx
   pop eax
   ret


get_FAT:
;--------------------------------
; get_FAT
;
; input :  EAX = #block
; output:  EAX = #block
;--------------------------------
   push ebx
   push edx

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.5      *
;***********************
  cmp [fs_type],1
  je correct3_13_5
  shl eax,1
  jmp  correct3_14_1
correct3_13_5:
   shl eax,2
correct3_14_1:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.5      *
;***********************

   xor edx,edx
   mov ebx,512
   div ebx

   add eax,[RESERVED_SECTOR]
   add eax,[PARTITION_START]
   mov ebx,buffer

   call hd_read ;_new

   mov  eax,[buffer+edx]

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.6      *
;***********************
  cmp [fs_type],1
  je correct3_13_6
  and  eax,0xffff
correct3_13_6:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.6      *
;***********************

   pop edx
   pop ebx
   ret


get_FAT_cache:
;--------------------------------
; get_FAT_cache - used for reading only : internal cache
;
; input :  EAX = #block
; output:  EAX = #block
;--------------------------------
   push ebx
   push edx

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.7      *
;***********************
  cmp [fs_type],1
  je correct3_13
  shl eax,1
  jmp  correct3_14
correct3_13:
   shl eax,2
correct3_14:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.7      *
;***********************

   xor edx,edx
   mov ebx,512
   div ebx

   add eax,[RESERVED_SECTOR]
   add eax,[PARTITION_START]
   mov ebx,fat_cache

   cmp  eax,[fat_in_cache]
   je   fat_found_in_cache
   mov  [fat_in_cache],eax
   call hd_read
 fat_found_in_cache:

   mov  eax,[fat_cache+edx]

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.8      *
;***********************
  cmp [fs_type],1
  je correct3_13_1
  and  eax,0xffff
correct3_13_1:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.8      *
;***********************

   pop edx
   pop ebx
   ret


fat_in_cache dd -1
fat_cache: times 512 db 0



;find_pointer_in_FAT:
;--------------------------------
; For each item of FAT do
;   if (item read == EAX)
;     return #item
;     carry=0
;   else
;     carry=1;
;
; input :  EAX = #block
; output:  if CARRY=0 then EAX = #block
;          if CARRY=1 then EAX = distroyed
;--------------------------------
;  add eax,2
;  push eax
;  push ecx
;  push edx

;  mov ecx,[FAT32_SIZE]
;  shl ecx,9-2                 ; *512 for sector   /4 for dword
;  mov edx,2

;adr78:
;  mov eax,edx
;  call get_FAT
;  cmp eax,[esp+8]
;  je found_pointer
;  inc edx
;  loop adr78

;  pop edx
;  pop ecx
;  add esp,4
;  stc
;  ret

;found_pointer:
;  mov eax,edx
;  pop edx
;  pop ecx
;  add esp,4
;  clc
;  ret

analyze_directory:
;--------------------------------
; input  : EAX = first cluster of the directory
;          EBX = pointer to filename
; output : IF CARRY=0 EAX = sector where th file is found
;                     EBX = pointer in buffer
;                     [buffer .. buffer+511]
;                     ECX,EDX,EDI,EDI not changed
;          IF CARRY=1
;--------------------------------
   push ebx ;[esp+16]
   push ecx
   push edx
   push esi
   push edi


adr56:
   mov [cluster_tmp],eax

   mov ecx,[FAT32_SIZE]
   imul ecx,[NUMBER_OF_FATS]
   add ecx,[RESERVED_SECTOR]

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.9      *
;***********************
  cmp [fs_type],2
  je correct2_11
  sub  eax,2
correct2_11:
   imul eax,[SECTOR_PER_CLUSTER]
  cmp [fs_type],1
  je correct2_13
  cmp [file_or_directory],0
  je  correct2_13
  cmp [analyze_f16],0
  je  correct2_13
  add eax,[correct_fat16]
correct2_13:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.9      *
;***********************

   add eax,[PARTITION_START]
   add eax,ecx

   mov edx,[SECTOR_PER_CLUSTER]

new_sector_in_cluster:
   mov ebx,buffer
   call hd_read ;_new

   mov ecx,512/32

adr1_analyze:

   mov edi,[ebx+11]
   and edi,0xf
   cmp edi,0xf
   je  long_filename_data

   mov esi,[esp+16]
   mov edi,ebx
   cld
   push ecx
   mov ecx,11
   rep cmpsb
   pop ecx
   je found_file_analyze

 long_filename_data:

   add ebx,32
   loop adr1_analyze

   inc eax
   dec edx
   jne new_sector_in_cluster

   mov eax,[cluster_tmp]
   call get_FAT
   mov [cluster_tmp],eax

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.10     *
;***********************
  cmp [fs_type],2
  je  correct5_2
   cmp eax,0x0f000000
   jb  adr56
 correct6_2:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.10     *
;***********************

   pop edi
   pop esi
   pop edx
   pop ecx
   add esp,4
   stc        ;file not found
   ret

found_file_analyze:
   pop edi
   pop esi
   pop edx
   pop ecx
   add esp,4
   clc        ;file found
   ret

cluster_tmp: dd 0 ; common variable used by
                  ; analyze_directory and analyze_directory_to_write
cluster_tmp2: dd 0
cluster_tmp3: dd 0


analyze_directory_to_write:
;--------------------------------
; input  : EAX = first cluster of the directory
; output : IF CARRY=0 EAX = sector where the file is found
;                     EBX = pointer in buffer
;                     [buffer .. buffer+511]
;                     ECX,EDX,EDI,EDI not changed
;          IF CARRY=1
;--------------------------------

   push ecx
   push edx
   push esi
   push edi

adr561:
   mov [cluster_tmp],eax
   mov [cluster_tmp2],eax

   mov ecx,[FAT32_SIZE]
   imul ecx,[NUMBER_OF_FATS]
   add ecx,[RESERVED_SECTOR]

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.10     *
;***********************
  cmp [fs_type],2
  je correct2_14
  sub  eax,2
correct2_14:
   imul eax,[SECTOR_PER_CLUSTER]
  cmp [fs_type],1
  je  correct2_16
  cmp [file_or_directory],0
  je  correct2_16
  cmp [analyze_f16],0
  je  correct2_16
  add eax,[correct_fat16]
correct2_16:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.10     *
;***********************

   add eax,[PARTITION_START]
   add eax,ecx

   mov edx,[SECTOR_PER_CLUSTER]

new_sector_in_cluster1:
   mov ebx,buffer
   call hd_read ;_new

   mov ecx,512/32

adr1_analyze1:
   cmp byte [ebx],0x00
   je  found_file_analyze1
   cmp byte [ebx],0xe5
   je  found_file_analyze1

avanti:
   add ebx,32
   loop adr1_analyze1

   inc eax
   dec edx
   jne new_sector_in_cluster1

   mov eax,[cluster_tmp]
   mov [cluster_tmp3],eax
   call get_FAT
   mov [cluster_tmp],eax

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.11     *
;***********************
  cmp [fs_type],2
  je  correct5_1
   cmp eax,0x0f000000
   jb  adr561
 correct6_1:
  xor eax,eax
  cmp [fs_type],2
  je correct3_15_3
   mov eax,2                       ;this block of code add a new cluster
correct3_15_3:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.11     *
;***********************

   call get_free_FAT               ;for the directory because the directory
                                   ;is full

   push eax
   mov  edx,0x0fffffff    ; new end for directory
   call set_FAT
   pop  eax

   mov  edx,eax
   mov  eax,[cluster_tmp3]
   mov  [f_del],1
   call set_FAT
   mov  [f_del],0

;   mov edx,eax
;   mov eax,[cluster_tmp2]
;   call set_FAT

   mov ecx,512/4
   xor eax,eax
   mov edi,buffer
   cld
   rep stosd

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.12     *
;***********************
  cmp [fs_type],2
  je correct2_17
  sub  edx,2
correct2_17:
   mov eax,[SECTOR_PER_CLUSTER]
   imul eax,edx
  cmp [fs_type],1
  je  correct2_19
  cmp [file_or_directory],0
  je  correct2_19
  cmp [analyze_f16],0
  je  correct2_19
  add eax,[correct_fat16]
correct2_19:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.12     *
;***********************

   add eax,[PARTITION_START]
   add eax,[RESERVED_SECTOR]
   mov ecx,[FAT32_SIZE]
   imul ecx,[NUMBER_OF_FATS]
   add eax,ecx
   mov ebx,buffer
   mov ecx,[SECTOR_PER_CLUSTER]

set_empty_directory:
   call hd_write_new
   inc eax
   loop set_empty_directory

   sub eax,[SECTOR_PER_CLUSTER]

found_file_analyze1:

   pop edi
   pop esi
   pop edx
   pop ecx
   clc        ;file found
   ret

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.13     *
;***********************
correct5_1:
  cmp  eax,0xFFFF
  jb  adr561
  jmp  correct6_1

correct5_2:
  cmp  eax,0xfff8  ;0xFFFF
  jb  adr56
  jmp  correct6_2

correct5_3:
  cmp  eax,0xFFFF
  jge delete_OK
  jmp  correct6_3

correct5_4:
  cmp [file_or_directory],0
  je  file_read_eof
  cmp  eax,0xFFFF
  jge file_read_eof
  jmp  correct6_4

correct3_15_5:
check_new_1:
   cmp  word [buffer+edx],0
   jne  no_found_1
   cmp  word [buffer+edx+2],0
   jne  no_found_1
   jmp  found
  no_found_1:
   add  edx,2
   inc  ecx
   cmp  edx,512-2
   jb   check_new_1
   inc  ecx
   
   inc eax
   call hd_read ;_new
   xor edx,edx
   jmp check_new_1
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.13     *
;***********************

data_read            dd 0x0
blocks_to_read       dd 0x0
return_data_pointer  dd 0x0
file_size            dd 0x0


get_data_cluster:

;--------------------------------
; input :  EAX = # block
;          ( EBX = pointer to buffer )
;          ( ECX = # bytes to read in buffer )
; output:  nothing
;--------------------------------

ORG_EAX equ [esp+20]
ORG_EBX equ [esp+16]
ORG_ECX equ [esp+12]
ORG_EDX equ [esp+8]
ORG_ESI equ [esp+4]
ORG_EDI equ [esp]

   push  eax ; ORG_EAX
   push  ebx ; ORG_EBX
   push  ecx ; ORG_ECX
   push  edx ; ORG_EDX
   push  esi ; ORG_ESI
   push  edi ; ORG_EDI

;   mov   edi,ebx
;
;   xor   edx,edx
;   mov   eax,ecx
;   mov   ebx,512
;   div   ebx

   mov   ecx,[FAT32_SIZE]
   imul  ecx,[NUMBER_OF_FATS]
   add   ecx,[RESERVED_SECTOR]

   mov   ebx,ORG_EAX

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.14     *
;***********************
  cmp [fs_type],2
  je correct2_20
  sub  ebx,2
correct2_20:
   imul  ebx,[SECTOR_PER_CLUSTER]
  cmp [fs_type],1
  je correct2_22
  cmp [file_or_directory],0
  je  correct2_22
  add ebx,[correct_fat16]
correct2_22:
   add   ebx,[PARTITION_START]
   add   ebx,ecx
   mov ecx,[SECTOR_PER_CLUSTER]
   cmp [fs_type],1
   je  correct7_1
   cmp [file_or_directory],1
   je  correct7_1
   mov ecx,32
correct7_1:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.14     *
;***********************

   mov eax,ebx
   mov ebx,buffer

read:

   cmp  [data_read],0  ; first wanted block
   je   gdcl1
   dec  [data_read]
   jmp  gdcl2
 gdcl1:

   mov  ebx,[return_data_pointer]

   call hd_read ;_new

;   push ecx
;   mov esi,buffer
;   mov edi,[return_data_pointer]
;   mov ecx,512
;   cld
;   rep movsb
;   pop ecx

   add  [return_data_pointer],512
   dec  [blocks_to_read]

 gdcl2:

   cmp [blocks_to_read],0
   je  out_of_read

   inc eax
   loop read

out_of_read:

   pop edi
   pop esi
   pop edx
   pop ecx
   pop ebx
   pop eax
   ret

set_data_cluster:
;--------------------------------
; input :  EAX = # block
;          EBX = pointer to buffer
;          ECX = # bytes to write in buffer
; output:  nothing
;--------------------------------
   push eax ; ORG_EAX
   push ebx ; ORG_EBX
   push ecx ; ORG_ECX
   push edx ; ORG_EDX
   push esi ; ORG_ESI
   push edi ; ORG_EDI

   mov  esi,ebx

   xor  edx,edx
   mov  eax,ecx
   mov  ebx,512
   div  ebx

   mov  ecx,[FAT32_SIZE]
   imul ecx,[NUMBER_OF_FATS]
   add  ecx,[RESERVED_SECTOR]

   mov  ebx,ORG_EAX

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.15     *
;***********************
  cmp [fs_type],2
  je correct2_23
  sub  ebx,2
correct2_23:
   imul ebx,[SECTOR_PER_CLUSTER]
  cmp [fs_type],1
  je  correct2_25
  cmp [file_or_directory],0
  je  correct2_25
  add ebx,[correct_fat16]
correct2_25:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.15     *
;***********************

   add  ebx,[PARTITION_START]
   add  ebx,ecx

   mov  ecx,[SECTOR_PER_CLUSTER]    ; vt

   mov  eax,ebx
   mov  ebx,buffer

write:
   push ecx
   mov  edi,buffer
   mov  ecx,512
   cld
   rep  movsb
   call hd_write_new
   inc  eax
   pop  ecx
   loop write

   pop  edi
   pop  esi
   pop  edx
   pop  ecx
   pop  ebx
   pop  eax
   ret

get_free_FAT:
;------------------------------------------
; input  :  EAX = # cluster for start the searching
; output :  EAX = # first cluster found free
;-------------------------------------------
   push ebx
   push ecx
   push edx

   mov ecx,eax

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.16     *
;***********************
  cmp [fs_type],1
  je correct3_15
  shl eax,1
  jmp  correct3_16
correct3_15:
   shl eax,2
correct3_16:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.16     *
;***********************

   xor edx,edx
   mov ebx,512
   div ebx

   add eax,[RESERVED_SECTOR]
   add eax,[PARTITION_START]
   mov ebx,buffer
   call hd_read ;_new

check_new:

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.17     *
;***********************
  cmp [fs_type],2
  je correct3_15_5
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.17     *
;***********************

   cmp  dword [buffer+edx],0
   jne  no_found
   cmp  dword [buffer+edx+4],0
   jne  no_found
   jmp  found
  no_found:
   add  edx,4
   inc  ecx
   cmp  edx,512-4
   jb   check_new
   inc  ecx

   inc eax
   call hd_read ;_new
   xor edx,edx
   jmp check_new

found:
   mov eax,ecx
   pop edx
   pop ecx
   pop ebx
   ret

;EXPERIMENTAL !!!!!!!!!!!!!
get_cluster_of_a_path:
;---------------------------------------------------------
; input: EBX = pointer to a path string
;          (example: the path "/files/data/document" become
;                           "files......data.......document...0"
;         '.' = space char
;         '0' = char(0) (ASCII=0) !!! )
; output: if (CARRY=1) -> ERROR in the PATH
;         if (CARRY=0) -> EAX=cluster
;---------------------------------------------------------
    push ebx
    push edx

    mov eax,[ROOT_CLUSTER]
    mov edx,ebx

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.18     *
;***********************
   mov  [analyze_f16],0

search_end_of_path:
    cmp byte [edx],0
    je found_end_of_path

    inc edx ; '/'

    mov ebx,edx
    call analyze_directory

   mov  [analyze_f16],1
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.18     *
;***********************

    jc directory_not_found

    mov ax,[ebx+20]                     ;read the HIGH 16bit cluster field
    shl eax,16
    mov ax,[ebx+26]                     ;read the LOW 16bit cluster field
    add edx,11                            ;8+3 (name+extension)
    jmp search_end_of_path

found_end_of_path:
    pop edx
    pop ebx
    clc                                 ;no errors
    ret

directory_not_found:
    pop edx
    pop ebx
    stc                                 ;errors occour
    ret

bcd2bin:
;----------------------------------
; input  : AL=BCD number (eg. 0x11)
; output : AH=0
;          AL=decimal number (eg. 11)
;----------------------------------
                push cx
                mov cl,al
                shr cl,4
                mov ch,cl
                shl cl,3
                add cl,ch
                add cl,ch
                and al,0xf
                add al,cl
                mov ah,0
                pop cx
                ret

get_data_for_file:
;-----------------------------------------------------
; Get data from CMOS and pack day,month,year in AX
; DATE   bits  0..4   : day of month 0..31
;              5..8   : month of year 1..12
;              9..15  : count of years from 1980
;-----------------------------------------------------
                push dx
                xor dx,dx
                mov al,0x7   ;day
                out 0x70,al
                in al,0x71
                call bcd2bin
                or dx,ax

                mov al,0x8   ;month
                out 0x70,al
                in al,0x71
                call bcd2bin
                shl ax,5
                or dx,ax

                mov al,0x9   ;year
                out 0x70,al
                in al,0x71
                call bcd2bin
                add ax,20    ;because CMOS return only the
                ;two last digit (eg. 2000 -> 00 , 2001 -> 01) and we
                shl ax,9     ;need the difference with
                ;1980 (eg. 2001-1980)
                or dx,ax
                xchg ax,dx   ;the result must be in AX
                pop dx
                ret

;-----------------------------------------------------
; Get time from CMOS and pack hour,minute,second in AX
; TIME   bits  0..4   : second (the low bit is lost)
;              5..10  : minute 0..59
;              11..15 : hour 0..23
;-----------------------------------------------------
get_time_for_file:
                push dx
                xor dx,dx
                mov al,0x0   ;second
                out 0x70,al
                in al,0x71
                call bcd2bin
                shr ax,1
                or dx,ax

                mov al,0x2   ;minute
                out 0x70,al
                in al,0x71
                call bcd2bin
                shl ax,5
                or dx,ax

                mov al,0x4   ;hour
                out 0x70,al
                in al,0x71
                call bcd2bin
                shl ax,11
                or dx,ax
                xchg ax,dx   ;the result must be in AX
                pop dx
                ret

file_write:
;--------------------------------------------------------------------------
;   INPUT :user-reg  register-in-this  meaning      symbol-in-this-routine
;
;            EAX        EDI            system call to write    /
;            EBX        EAX   (PAR0)   pointer to file-name    PAR0
;            EDX        ECX   (PAR1)   pointer to buffer       PAR1
;            ECX        EBX   (PAR2)   file size               PAR2
;            ESI        EDX   (PAR3)   pointer to path         PAR3
;
;   OUTPUT : eax = 0 - ok
;            eax = 1 - error at write
;            eax = 2 - bad partition
;
;--------------------------------------------------------------------------

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.19     *
;***********************
  mov  [file_or_directory],1
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.19     *
;***********************

;***********************
;*         Start       *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.2      *
;***********************
    mov [FILE_SIZE],ebx
;***********************
;*         End         *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.2      *
;***********************

    cmp  [valid_fat],byte 1
    jz   fat_ok_for_writing
    mov  eax,2
    ret
fat_ok_for_writing:

   cli
   cmp  [hd1_status],0
   je   fatokl1

   sti
   call change_task
   jmp  fat_ok_for_writing

  fatokl1:

   call reserve_hd1
   sti

   sub  esp,32
   call expand_filename

   pusha
   mov ecx,edx            ;try to delete the file first
   call file_delete
   popa

   pushad

PAR0 equ [esp+28]        ;EAX
PAR1 equ [esp+24]        ;ECX
PAR2 equ [esp+16]        ;EBX
PAR3 equ [esp+20]        ;EDX


   mov ebx,PAR3
   call get_cluster_of_a_path
   jnc found_directory_for_writing

exit_writing_with_error:

   mov   edi,1            ; write all of cache to hd
   call  write_cache

   popa
   stc

   add  esp,32
   mov  [hd1_status],0
   mov  eax,1
   ret

found_directory_for_writing:
   call analyze_directory_to_write

found1:
   push eax

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.20     *
;***********************
  xor eax,eax
  cmp [fs_type],2
  je correct3_15_1
   mov eax,2
correct3_15_1:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.20     *
;***********************

   call get_free_FAT
   mov [cluster],eax
   pop eax

   push ebx
   mov ebx,buffer
   call hd_read ;_new
   pop ebx

   mov esi,PAR0             ;file name
   mov edi,ebx
   mov ecx,11
   cld
   rep movsb

   mov ecx,PAR2
   mov [ebx+28],ecx         ;file size
   mov ecx,[cluster]
   mov [ebx+26],cx          ;16 bits low  of cluster
   shr ecx,16
   mov [ebx+20],cx          ;16 bits high of cluster
   mov byte [ebx+11],0x20   ;attrib
   push eax

   call get_time_for_file
   mov [ebx+22],ax

   call get_data_for_file
   mov [ebx+24],ax

   pop eax

   mov ebx,buffer           ;save the directory name,length,cluster
   call hd_write_new

   imul esi,[SECTOR_PER_CLUSTER],512

hd_new_block_write:

   mov  eax,[cluster]      ; eax = block
   mov  ebx,PAR1           ; ebx = buffer
   call set_data_cluster

   mov  ecx,esi            ; ecx = size to write in bytes
   cmp  ecx,PAR2
   jbe  adr3
   mov  ecx,PAR2
 adr3:

   add  PAR1,ecx
   sub  PAR2,ecx            ; sub wrote bytes in stack

   cmp  PAR2,dword 0
   je   file_saved_OK

   mov  eax,[cluster]
   inc  eax
   call get_free_FAT
   mov  [cluster1],eax      ; next free in FAT

   mov  eax,[cluster]
   mov  edx,[cluster1]
   call set_FAT

   mov  eax,[cluster1]
   mov  [cluster],eax

   jmp  hd_new_block_write     ; adr2

file_saved_OK:

   mov  eax,[cluster]
   mov  edx,0x0fffffff
   call set_FAT

   mov   edi,1            ; write all of cache to hd
   call  write_cache

   popad
   clc

   add  esp,32
;   mov  [hd1_status],0   ; free device
;   mov  eax,0
;   ret
;***********************
;*         Start       *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.3      *
;***********************
   cmp [fs_type],2          ;For Fat16 the correction is not necessary!
   je correct10_11
   call write_free_mem_hd   
correct10_11:
   mov  [hd1_status],0
   xor  eax, eax
   ret

write_free_mem_hd:
   mov  eax,[PARTITION_START]
   mov  ebx,buffer
   call hd_read ;_new
   movzx  ecx,word [ebx+48]
   add  eax,ecx
   mov  [ADR_FSINFO],eax
   call hd_read ;_new
   mov  eax,[FILE_SIZE]
   call  calc_file_size_claster
   mov  [FILE_SIZE],eax
   cmp  [change_mem],1
   je change_mem_1
   cmp  [change_mem],2
   je change_mem_2
   jmp change_mem_3
change_mem_2:
   mov  eax,[old_size_file]
   call  calc_file_size_claster
   add  [buffer+488],eax
change_mem_1:
   mov  eax,[FILE_SIZE]
   sub  [buffer+488],eax
   mov  eax,[ADR_FSINFO]
   mov  ebx,buffer
   call hd_write_new_sys
   call wait_for_hd_idle
change_mem_3:
   ret
calc_file_size_claster:
   mov  ebx,[SECTOR_PER_CLUSTER]
   call correct_calc
   mov  ebx,512
   call correct_calc
   ret
correct_calc:
   xor  edx,edx
   div  ebx
   cmp edx,0
   je not_correction
   inc eax
not_correction:
   ret
;***********************
;*          End        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.3      *
;***********************

file_read:
;--------------------------------------------------------------------------
;   INPUT :  user-register register-in-this  meaning         symbol-in-this
;
;            EAX           EDI               system call to write   /
;            EBX           EAX   (PAR0)      pointer to file-name   PAR0
;            EDX           ECX   (PAR1)      pointer to buffer      PAR1
;            ECX           EBX   (PAR2)   vt file blocks to read    PAR2
;            ESI           EDX   (PAR3)      pointer to path        PAR3
;            EDI           ESI            vt first 512 block to read
;                          EDI               if 0 - read root
;
; OUT:
;
; eax = 0 command succesful
;       1 no hd base and/or partition defined
;       - 2 yet unsupported FS
;       - 3 unknown FS
;       - 4 partition not defined at hd
;       5 eof
;       6 file not found
; ebx = size of file
;--------------------------------------------------------------------------
   cmp  [valid_fat],byte 1
   jz   fat_ok_for_reading
   mov  ebx,0
   mov  eax,1 ; partition not defined
   ret

fat_ok_for_reading:

   cli
   cmp  [hd1_status],0
   je   fatokr1
   sti
   call change_task
   jmp  fat_ok_for_reading

  fatokr1:

   call reserve_hd1
   sti

   mov  [data_read],esi
   mov  [blocks_to_read],ebx
   mov  [return_data_pointer],ecx
   mov  [fat_in_cache],-1

   pushad

PAR0 equ [esp+28]        ;EAX
PAR1 equ [esp+24]        ;ECX
PAR2 equ [esp+16]        ;EBX
PAR3 equ [esp+20]        ;EDX

   mov ebx,PAR3
   call get_cluster_of_a_path
   jc file_to_read_not_found

   cmp  edi,0            ; read root
   jne  no_read_root

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.21     *
;***********************

  mov eax,[ROOT_CLUSTER]
  cmp [fs_type],2
  je read_root_f16
  jmp read_root
read_root_f16:
  mov [file_or_directory],0
  jmp read_root
no_read_root:
  mov [file_or_directory],1

;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.21     *
;***********************

   mov ebx,PAR0
   call analyze_directory
   jc file_to_read_not_found

found1r:

   mov eax,[ebx+28]  ; file size
   mov [file_size],eax

   mov ax,[ebx+20]   ; FAT entry
   shl eax,16
   mov ax,[ebx+26]

read_root:

   imul esi,[SECTOR_PER_CLUSTER],512

   call get_data_cluster

adr2r:

   cmp [blocks_to_read],0
   je  file_read_OK

   call get_FAT_cache

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.22     *
;***********************
  cmp [fs_type],2
  je  correct5_4
   cmp  eax,0x0f000000   ; end of file
   jge  file_read_eof
   cmp  eax,0x00000000   ; incorrect fat chain
   je   file_read_eof
 correct6_4:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.22     *
;***********************

   call get_data_cluster

   jmp adr2r

file_read_OK:
   popad
   mov  [hd1_status],0
   mov  ebx,[file_size]
   mov  eax,0
   ret

file_read_eof:
   popad
   mov  [hd1_status],0
   mov  ebx,[file_size]
   mov  eax,5
   ret

file_to_read_not_found:
   popad
   mov  [hd1_status],0
   mov  ebx,0
   mov  eax,6
   ret

; OUT:
;
; eax = 0 - Command succesful
;       1 - No hd base and/or partition defined
;       2 - Unsupported FS
;       3 - Unknown FS
;       4 - Partition not defined at hd
;       5 - Eof ?
;       6 - File not found ?
; ebx = size of file


f_del db 0x0

file_delete:
;--------------------------------------------------------------------------
;EXPERIMENTAL !!!!!
;      INPUT :  user-reg  register-in-this meaning           symbol-in-this
;               EAX       EDI              system call to delete   /
;               EBX       EAX     (PAR0)   pointer to file-name    PAR0
;               EDX       ECX     (PAR1)   pointer to path         PAR1
;--------------------------------------------------------------------------

    cmp  [valid_fat],byte 1
    jz   fat_ok_for_deleting
    ret
fat_ok_for_deleting:

   pushad

   mov [f_del],1           ; delete on

PAR0 equ [esp+28] ;EAX
PAR1 equ [esp+24] ;ECX

   mov ebx,PAR1
   call get_cluster_of_a_path
   jc file_to_delete_not_found

   mov ebx,PAR0
   call analyze_directory
   jc file_to_delete_not_found

found_delete:

   mov byte [ebx],0xe5

;***********************
;*        Start        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.4      *
;***********************
   mov edx,[ebx+28]
   mov [old_size_file],edx
;***********************
;*          End        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.4      *
;***********************

   mov edx,ebx
   mov ebx,buffer
   call hd_write_new

   mov ebx,edx

   mov ax,[ebx+20]
   shl eax,16
   mov ax,[ebx+26]
   xor edx,edx

clean_new_chain:
   mov ebx,eax

   call get_FAT
   mov ecx,eax

   mov eax,ebx
   call set_FAT

   mov eax,ecx

;***********************
;*         Start       *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.23     *
;***********************
  cmp [fs_type],2
  je  correct5_3
   cmp eax,0x0f000000  ; end of file
   jge delete_OK
   cmp eax,0x00000000  ; unfinished fat chain
   je  delete_OK
 correct6_3:
;***********************
;*         End         *
;* Mario79 edited code *
;*        Fat16        *
;*     change 1.23     *
;***********************

   jmp clean_new_chain

delete_OK:

   popad
   clc
   mov [f_del],0
;   ret
;
;file_to_delete_not_found:
;
;   popad
;   mov  [f_del],0
;   stc
;   ret

;***********************
;*        Start        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.5      *
;***********************
   mov [change_mem],2
   ret

file_to_delete_not_found:

   popad
   mov  [f_del],0
   stc
   mov [change_mem],1
   ret
;***********************
;*          End        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.5      *
;***********************


;**************************************************************************
;
;   0x600008  - first entry in cache list
;
;            +0   - lba cluster
;            +4   - state of cache cluster
;                   0 = empty
;                   1 = used for read  ( same as in hd )
;                   2 = used for write ( differs from hd )
;
;      +65536 - cache entries
;
;**************************************************************************

hd_read:

;  eax block to read
;  ebx destination

    pusha                 ; scan cache

    mov  ecx,cache_max    ; entries in cache
    mov  esi,0x600000+8
    mov  edi,1

  hdreadcache:

    cmp  [esi+4],dword 0  ; empty
    je   nohdcache

    cmp  [esi],eax        ; correct cluster
    jne  nohdcache

    mov  esi,edi
    shl  esi,9
    add  esi,0x600000+65536
    mov  edi,ebx
    mov  ecx,512
    cld
    rep  movsb
    popa
    ret

  nohdcache:

    add  esi,8
    add  edi,1
    loop hdreadcache

    popa

    call  wait_for_hd_idle

    push  esi edi eax ebx ecx edx

    cli

    xor   eax,eax
    mov   edx,[hdbase]
    add   edx,1
    mov   al,0
    out   dx,al
    add   edx,1
    mov   al,1
    out   dx,al
    add   edx,1
    mov   al,[esp+12]
    out   dx,al
    add   edx,1
    mov   al,[esp+13]
    out   dx,al
    add   edx,1
    mov   al,[esp+14]
    out   dx,al
    add   edx,1
    mov   al,[esp+15]
    and   al,1+2+4+8
    mov   bl,byte [hdid]
    add   al,bl
    add   al,128+64+32
    out   dx,al
    add   edx,1
    mov   al,20h
    out   dx,al

    sti

    call  wait_for_sector_buffer

    cmp   [hd_error],0
    jne   hd_read_error

    cli

    mov   edi,[esp+8]
    mov   ecx,256
    mov   edx,[hdbase]
    cld
    rep   insw

    sti

    mov   esi,[esp+8]      ; move sector to cache
    mov   ecx,512

    mov   edi,0            ; write if the cache is full
    call  write_cache

    call  find_empty_slot  ; ret in edi

    cmp   edi,-1
    jne   founds
    call  find_empty_read_slot  ; ret in edi
  founds:

    push  edi

    shl   edi,9
    add   edi,0x600000+65536
    cld
    rep   movsb            ; move data

    pop   edi

    imul  edi,8
    add   edi,0x600000
    mov   eax,[esp+12]
    mov   [edi],eax        ; cluster number

    mov   [edi+4],dword 1  ; hd read - mark as same as in hd

  not_to_cache:

    pop   edx ecx ebx eax edi esi
    ret




;****************************************************************
hd_write_new:
; eax = block
; ebx = pointer to memory

    push edi
    mov  edi,0 ; write cache if full
    call write_cache
    pop  edi

    ; check if the cache already has the cluster and overwrite it

    pusha

    mov  ecx,cache_max
    mov  esi,0x600000+8
    mov  edi,1

  hdwritecache:

    cmp  [esi+4],dword 0 ; if cache slot is empty
    je   not_in_cache_write

    cmp  [esi],eax       ; if the slot has the cluster
    jne  not_in_cache_write

    mov  [esi+4],dword 2 ; write - differs from hd

    shl  edi,9
    add  edi,0x600000+65536
    mov  esi,ebx
    mov  ecx,512
    cld
    rep  movsb

    popa
    ret

  not_in_cache_write:

    add  esi,8
    add  edi,1
    loop hdwritecache

    ; block not found in cache
    ; write the block to a new location

    call  find_empty_slot ; ret in edi

    cmp   edi,-1
    jne   foundsw
    call  find_empty_read_slot  ; ret in edi
  foundsw:

    push  edi

    imul edi,8
    add  edi,0x600000

    mov  [edi+0],eax
    mov  [edi+4],dword 2

    pop  edi

    shl  edi,9
    add  edi,0x600000+65536
    mov  esi,ebx
    mov  ecx,512
    cld
    rep  movsb
    popa
    ret


write_cache:

    ; edi = 0 - write all only if the cache is full
    ; edi = 1 - write all

    pusha

    cmp  edi,0
    jne  no_check_for_full_cache

    mov  ecx,cache_max-15
    mov  esi,0x600000+8
    mov  edi,1

  cachel1:

    cmp  [esi+4],dword 2     ; if cache slot is different from hd
    jne  cachel2

    add  esi,8
    add  edi,1
    loop cachel1

    ; no empty slots found

    jmp  flush_cache

  cachel2:

    popa
    ret

  no_check_for_full_cache:


    ; edi = 1


  flush_cache:


    ; write difference ( 2 ) from cache to hd


    mov  ecx,cache_max
    mov  esi,0x600000+8
    mov  edi,1

  write_cache_more:

    cmp  [esi+4],dword 2 ; if cache slot is not different
    jne  does_not_need_writing

    mov  [esi+4],dword 1 ; same as in hd

    ; give parameters

    pusha

    mov  eax,[esi+0]  ; eax = cluster to write

    mov  ebx,edi
    imul ebx,512
    add  ebx,0x600000+65536

                      ; ebx = from memory position

    cmp  eax,[PARTITION_START]
    jb   danger
    cmp  eax,[PARTITION_END]
    ja   danger

    call  wait_for_hd_idle

    push  esi    ; [esp+12] +13 +14 +15
    push  eax    ; [esp+8]  +9  +10 +11
    push  ecx    ; [esp+4]  +5 +6 +7
    push  edx    ; [esp]    +1 +2 +3

    cli

    xor   eax,eax
    mov   edx,[hdbase]
    inc   edx
    out   dx,al
    inc   edx
    mov   al,1
    out   dx,al
    inc   edx
    mov   al,[esp+8]
    out   dx,al
    inc   edx
    mov   al,[esp+9]
    out   dx,al
    inc   edx
    mov   al,[esp+10]
    out   dx,al
    inc   edx
    mov   al,[esp+11]
    and   al,1+2+4+8
    add   al,byte [hdid]
    add   al,128+64+32
    out   dx,al
    inc   edx
    mov   al,30h
    out   dx,al

    sti

    call  wait_for_sector_buffer

    cmp   [hd_error],0
    jne   hd_write_error

    cli

    mov   esi,ebx
    mov   ecx,256
    mov   edx,[hdbase]
    cld
    rep outsw

    sti

    pop edx
    pop ecx
    pop eax
    pop esi

  danger:

    popa

  does_not_need_writing:

    add  esi,8
    add  edi,1
    dec  ecx
    jnz  write_cache_more

    popa
    ret


find_empty_slot:

    push eax ebx ecx edx esi

    mov  ecx,cache_max
    mov  esi,0x600000+8
    mov  edi,1

  search_for_empty:

    cmp  [esi+4],dword 0 ; if cache slot is empty
    je   found_empty_slot

    add  esi,8
    add  edi,1
    loop search_for_empty

    mov  edi,-1

    ; jmp  $ ; should not happen

  found_empty_slot:

    pop  esi edx ecx ebx eax

    ret


fat_search_start dd 0x0

find_empty_read_slot:

    push eax ebx ecx edx esi

  new_read_search:

    inc  dword [fat_search_start]
    cmp  [fat_search_start],cache_max-10
    jb   sok
    mov  [fat_search_start],0
  sok:

    mov  ecx,cache_max
    mov  esi,0x600000+8
    mov  edi,1

  search_for_empty_read:

    cmp  edi,[fat_search_start]
    jb   next_cache

    cmp  [esi+4],dword 1 ; if cache slot is used for reading
    je   found_empty_read_slot

  next_cache:

    add  esi,8
    add  edi,1
    loop search_for_empty_read

    mov  edi,1
    call write_cache

    mov  [fat_search_start],dword 0

    jmp  new_read_search

  found_empty_read_slot:

    pop  esi edx ecx ebx eax

    ret


hd_wait_timeout: dd 0x0


save_hd_wait_timeout:

    push  eax

    mov   eax,[0xfdf0]      
    add   eax,300           ; 3 sec timeout
    mov   [hd_wait_timeout],eax

    pop   eax

    ret


check_hd_wait_timeout:

    push  eax

    mov   eax,[hd_wait_timeout]
    cmp   [0xfdf0],eax
    jg    hd_timeout_error

    pop   eax

    ret


hd_timeout_str   db 'K : FS - HD timeout',13,10,0
hd_read_str      db 'K : FS - HD read error',13,10,0
hd_write_str     db 'K : FS - HD write error',13,10,0


hd_timeout_error:

    call  clear_hd_cache
    call  clear_application_table_status
    mov   esi,hd_timeout_str
    call  sys_msg_board_str
    jmp   $


hd_read_error:

    call  clear_hd_cache
    call  clear_application_table_status
    mov   esi,hd_read_str
    call  sys_msg_board_str
    jmp   $

hd_write_error:

    call  clear_hd_cache
    call  clear_application_table_status
    mov   esi,hd_write_str
    call  sys_msg_board_str
    jmp   $




wait_for_hd_idle:

    push  eax
    push  edx

    call  save_hd_wait_timeout

    mov   edx,[hdbase]
    add   edx,0x7
  wfhil1:

    call  check_hd_wait_timeout

    in    al,dx
    test  al,128
    jnz   wfhil1

    pop   edx
    pop   eax
    ret


wait_for_sector_buffer:

    push  eax edx

    mov   edx,[hdbase]
    add   edx,0x7

    call  save_hd_wait_timeout

  hdwait_sbuf:              ; wait for sector buffer to be ready

    call  check_hd_wait_timeout

    in    al,dx
    test  al,8
    jz    hdwait_sbuf

    mov   [hd_error],0

    cmp   [hd_setup],1      ; do not mark error for setup request
    je    buf_wait_ok

    test  al,1              ; previous command ended up with an error
    jz    buf_wait_ok
    mov   [hd_error],1

  buf_wait_ok:

    pop   edx eax

    ret



read_hd_file:
;-----------------------------------------------------------------
;
; Converting old reading function for hd-application start.
;
; IN:
;
; eax - pointer to file (0 = read only first sector of drive: eg 'label')
; ebx - file lenght
; ecx - start 512 byte block number
; edx - number of blocks to read
; esi - pointer to return/work area (atleast 20 000 bytes)
;
; For new read function
;
; EAX   (PAR0)      pointer to file-name   PAR0
; ECX   (PAR1)      pointer to buffer      PAR1
; EBX   (PAR2)   vt file blocks to read    PAR2
; EDX   (PAR3)      pointer to path        PAR3
; ESI            vt first 512 block to read
; EDI               if 0 - return root
;--------------------------------------------------------------------------

     pusha
     mov  esi,eax
     mov  edi,startpath
     mov  ecx,250
     cld
     rep  movsb
     popa

     mov  eax,startpath
     add  eax,ebx
     sub  eax,12
     mov  [eax],byte 0
     mov  eax,startpath

     push eax ebx ecx edx esi

     pop  ecx ; pointer to buffer
     add  ecx,1024
     pop  ebx ; number of blocks to read
     pop  esi ; first block to read
     dec  esi
     pop  eax ; file length
     pop  edx ; pointer to path

     mov  edi,12

     add  eax,edx
     sub  eax,12
     inc  eax

     call file_read

     ret

startpath: times 255 db 0

;***********************
;*         Start       *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.6      *
;***********************
hd_write_new_sys:
; eax = block
; ebx = pointer to memory
   
    cmp  eax,[PARTITION_START]
    jb   danger_1
    cmp  eax,[PARTITION_END]
    ja   danger_1
   
    call  wait_for_hd_idle
   
    push  esi    ; [esp+12] +13 +14 +15
    push  eax    ; [esp+8]  +9  +10 +11
    push  ecx    ; [esp+4]  +5 +6 +7
    push  edx    ; [esp]    +1 +2 +3
   
    cli
   
    xor   eax,eax
    mov   edx,[hdbase] 
    inc   edx
    out   dx,al
    inc   edx
    mov   al,1 
    out   dx,al
    inc   edx
    mov   al,[esp+8] 
    out   dx,al
    inc   edx
    mov   al,[esp+9]
    out   dx,al
    inc   edx
    mov   al,[esp+10]
    out   dx,al
    inc   edx
    mov   al,[esp+11]
    and   al,1+2+4+8
    add   al,byte [hdid]
    add   al,128+64+32
    out   dx,al
    inc   edx
    mov   al,31h 
    out   dx,al

    sti

hdwait_write:
    in    al,dx
    and   al,128
    jnz    hdwait_write

    cli

    mov   esi,ebx
    mov   ecx,256
    mov   edx,[hdbase]

    cld
    rep outsw
   
    sti

    pop edx
    pop ecx
    pop eax
    pop esi
danger_1:
    ret   
;***********************
;*          End        *
;* Mario79 edited code *
;*  correct free mem   *
;*     change 1.6      *
;***********************
