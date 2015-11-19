;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   Bootcode.inc (c) Ville Turjanmaa
;;   License: GPL. See file copying for details.
;;
;;   Configuration file, Config.dat by wrn, wrn71@yahoo.com
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    16 bit functions
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Enable read for /fd/1/config.dat

boot_media  equ  0  ;; 0=fd,1=hd

; DS:SI points to ASCIIZ string to display
; String must be in (DS set to) beginning of kernel
print:

    push  si
    mov   si,leftpr	; print border character
    call  printplain
    pop   si		; falls through to "printplain"

PDATA:	 
printplain:

    pusha
    cmp   byte [display_atboot],2
    je	  printplain_exit
    cld
  prpl1:
    lodsb			; first time -- test for null string
    cmp   al,0			; end of ASCIIZ string
    je	  printplain_exit
    mov   ah,0xe		; use BIOS TTY function
    xor   bh,bh
    int   0x10
    jmp prpl1			; get next character
  printplain_exit:
    popa

    ret
   
setbase1000:			; set DS and ES to kernel load segment

    push  eax
    mov   ax,0x1000
    mov   es,ax
    mov   ds,ax
    pop   eax

    ret


; Returns representation of a single input character in AL
; On entry BH = max and BL = min values
getkey:

    push  ebx
    push  ecx
    push  edx
    push  esi

    add   bx,0x0101
    xor   eax,eax

  gk1:

    push  ebx ecx edx esi edi ebp
    mov   ax , 0x0000 ; read key, with wait
    int   0x16
    shr   ax , 8      ; scancode
    pop   ebp edi esi edx ecx ebx
    mov   cl,al
   
    add   al,47 		; scan code 1 to 0xa = number '2' to '9'
    mov   [keyinbs],al		; place in a temporary string with backspace
    mov   si,keyinbs		; overwrite previous value
    call  printplain

    mov   al,cl
   
    cmp   al,bl 		; below minimum - try again
    jb	  gk1
    cmp   al,bh 		; above maximum - try again
    ja	  gk1

    test  ebx,0x010000
    jnz   gk3
    mov   cx,0x1000
    mov   dx,cx
    add   ax,47
    mov   cx,ax
    cmp   cx,58 		; 58 -> scan code 0xb -> key '0'
    jb	  gk_nozero
    sub   cx,10 		; output '0' to '9'
  gk_nozero:
    mov   [keyin],cl		; place in temporary string (no backspace)
    mov   si,keyin
    call  printplain
  gk3:
    sub   ax,48 		; AX = 1 to 10
    pop   esi
    pop   edx
    pop   ecx
    pop   ebx

    ret


OUTCHAR:                ; al = character to display
    push ax
    push bx
    push dx		; some BIOS modify unusual registers (DX & BP)
    push bp
    mov  ah,0x0e 	; use BIOS TTY function
    mov  bx,0007 	; page 0 (really old BIOS, foreground = white)
    int  0x10
    pop  bp
    pop  dx
    pop  bx
    pop  ax
    ret

SPACE2:
    call SPACE
SPACE:
    push ax
    mov  al,' '
    call OUTCHAR
    pop  ax
    ret

OUT4H:			; 4 hex digits representing ax
    xchg al,ah
    call OUT2H		; do top 2 (AH)
    xchg al,ah		; restore bottom and do (AL) 2 more hex digits
OUT2H:
    push ax
    shR  al,4		; do high nibble
    call OUT1H
    pop  ax		; get low nibble and print it
OUT1H:			; output a digit
    push ax		; works with number bases 2-16
    and  al,0x0F 	; remove/modify '&' for bases up to 36
    cmp  al,9
    jle  digit1
    add  al,'A'-'9'-1
  digit1:
    add  al,'0'
    call OUTCHAR
    pop  ax
    ret

; On entry DX:AX = number to display in decimal (1 - 10 digits)
; Similar function to Forth 'DU.'
DU_DOT:
    push ax 		; save registers for diagnostic print
    push bx
    push cx
    push dx
    push di
    xor  cx,cx		; count = 0
    mov  bx,10		; base = decimal (0 will crash routine)
    mov  di,dx		; DI = mid word
  udot_dgt:
    xor  dx,dx		; DX = hi  word, word order dx:di:ax
    xchg ax,di
    div  bx		; high order quotient = hi:mid / base
    xchg ax,di
    div  bx		; low order quotient = hi remainder:low / base
    push dx 		; digit to stack = low remainder
    inc  cx		; digit counted
    mov  dx,di		; anything left? (always at least 1 digit = 0)
    or   dx,ax		;   no if both quotients are 0
    jne  udot_dgt
  udot_lp:
    pop  ax		; get top digit
    call OUT1H		; display it (0-9 works same, hex or decimal)
    loop udot_lp	; do all digits (1 to 5 / 9)
  du_xit:
    pop  di		; restore registers
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; On entry AX = number to display in decimal (1 - 5 digits)
; Similar function to Forth 'U.'
U_DOT:
    push dx
    xor  dx,dx
    call DU_DOT
    pop  dx
    ret


; --------------------------------------------------------------------------
; --------------------------------------------------------------------------


reset_floppy:		; use BIOS function, ignore any errors
    push ax
    push dx
    xor ax,ax		; function 0
    xor dx,dx		; drive 0 (a:), only
    int 0x13
    pop dx
    pop ax
    ret

; cl high (7-6) + ch (7-0) = cylinder, cl low (5-0) = start sector
; al = number of sectors,  dh = side/head, es:bx = buffer location
; programmer must watch BIOS limits, some cannot cross track (or side) boundary
rd_sectors:
    push ax
    push dx
    push di
    mov di,10		; maximum number of retries
  rd_retry:
    mov ah,0x02 	; function 2 -- read multiple sectors
    mov dl,0		; use 1st floppy (a:), only
    int 0x13
    jnc rd_end
    dec di
    jnz rd_retry
    stc
  rd_end:		; return CY clr/set = good/bad read
    pop di
    pop dx
    pop ax
    ret

; --------------------------------------------------------------------------
; Floppy parameters -- variables match size and order of those found on 
; floppy MBR.  Values will be changed from default ones
; --------------------------------------------------------------------------
bytespersector: 	dw	512	; bytes / sector - offset 11
sectorspercluster:	db	1	; sectors / cluster - 13
ressectors:		dw	1	; boot (reserved) sectors - 14
n_fatcopies:		db	2	; bit map copies - 16
maxrootentries: 	dw	224	; directory entries - 17
; --------------------------------------------------------------------------
sectorsperfat:		dw	14	; sectors / map - 22
sectorspertrack:	dw	18	; sectors / track - 24
n_heads:		dw	2	; number of heads (sides) - 26
hiddensectors:		dd	0	; hidden sectors (dd) - 28
totalsectors:		dd	2880	; sectors / disk - 32
; --------------------------------------------------------------------------
; Calculated values based on above.  Default bytes per directory entry.
; --------------------------------------------------------------------------
root_sectors:	dw	14	; number root directory sectors
start_fat:	dd	1	; beginning of root directory
start_root:	dd	19	; beginning of root directory
start_user:	dd	33	; first sector to contain file info.
maxcylinders:	dw	80	; number of cylinders
bytesperentry:	dw	32	; original PCDOS directory format

; get the floppy disk parameters from MBR (logical sector 0)
; uses the root directory buffer (0:2800) to contain the sector while copying informaion
get_floppy_params:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    push es
    push word 0 		; load to bottom of memory
    pop es
    mov bx,0x02800		; load address (0:2800)
    xor dx,dx			; drive 0, logical sector 0 = physical 0/0/1
    mov cx,0001
    mov al,1			; one sector
    call rd_sectors
    jnc move_params
    mov si,badsect
    call print
    jmp $			; Fatal - floppy disk read error
  move_params:
    pop es
    push ds
    push word 0 		; from bottom (0:) to kernel (0x1000:)
    pop ds
    mov si,bx
    add si,11			; skip over jump & oem
    mov di,bytespersector
    mov cx,4			; 4 words = 8 bytes
    cld
    rep movsw
    lodsw			; AX = small count
    inc si			; skip media descriptor
    mov cx,7
    cld
    rep movsw
    pop ds
    mov dx,[totalsectors]	; ensure large/total contains number of sectors
    or	dx,[totalsectors+2]
    jnz resume_params1
    cmp ax,0
    jg	set_total
    mov ax,2880
  set_total:
    mov [totalsectors],ax

  resume_params1:
    mov ax,[maxrootentries]	; calculate number of root directory sectors
    mov cx,[bytesperentry]
    mul cx
    mov cx,[bytespersector]	; PCDOS requires an exact fit (no rounding)
    cmp cx,0
    jg	resume_params2
    mov cx,512
    mov [bytespersector],cx
  resume_params2:
    div cx
    mov [root_sectors],ax

    xor dx,dx			; calculate number of cylinders
    mov ax,[totalsectors]
    mov cx,[sectorspertrack]
    cmp cx,0
    jg	resume_params3
    mov cx,18
    mov [sectorspertrack],cx
  resume_params3:
    div cx
    xor dx,dx
    mov cx,[n_heads]
    cmp cx,0
    jg	resume_params4
    mov cx,2
    mov [n_heads],cx
  resume_params4:
    div cx
    mov [maxcylinders],ax

    mov ax,[ressectors] 	; calculate start of 1st FAT
    add ax,[hiddensectors]
    mov [start_fat],ax
    mov ax,[sectorsperfat]	; start of root directory
    xor cx,cx
    mov cl,[n_fatcopies]
    mul cx
    add ax,[start_fat]
    mov [start_root],ax
    add ax,[root_sectors]	; start of user area
    mov [start_user],ax

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; calculate the physical cylinder/head/sector from a logical sector number
; on entry DX:AX = logical sector (DS set to beginning of kernel)
; returns cylinder/head/sector in BIOS format, changes AX, DL
; uses parameters from floppy logical sector 0
; sector numbers will be < 4080 (12 bits - reserved)
calc_phys_sector:
    push bx
    cmp dx,0			; above maximum?
    ja calc_err
    cmp ax,[totalsectors]
    jb calc_cont
  calc_err:
    mov si,badcalc		; do not need to clear stack
    call print
    jmp $			; Fatal calculation error
  calc_cont:	
    push ax
    push dx
    mov ax,[n_heads]		; heads = tracks/cylinder
    mul word [sectorspertrack]	; BX = sectors/cyl = tracks/cylinder * sectors/track 
    mov bx,ax
    pop dx
    pop ax
    cmp bx,0
    je calc_err
    div bx			; ax = track, dx = sector within cyl
    xchg al,ah			; mov bits 0-7 to ah, 8 & 9 to high part of al (0-5 zeroed)
    shl al,6
    mov cx,ax			; track (cylinder number), BIOS format
    mov ax,dx
    xor dx,dx
    mov bx,[sectorspertrack]
    cmp bx,0
    je calc_err
    div bx			; ax = head, dx = sector in track
    inc dl			; one based sector (normal format)
    or cl,dl			; add to track
    mov dh,al			; head number (side)
  calc_xit:
    pop bx
    ret

; get the first floppy fat into boot area (0:0600)
; uses parameters from previous floppy read and decode
; cluster numbers will be < 38000
load_fat:
    pusha
    push es

    push word 0
    pop es
    mov bx,0x0600		; load FAT at bottom of memory
    mov ax,[start_fat]
    mov dx,[start_fat+2]
    call calc_phys_sector
    mov al,[sectorsperfat]	; read one entire FAT (4.5k reserved)
    call rd_sectors
    jnc fat_rd_end
    mov si,badsect
    call print
    jmp $			; Fatal - floppy disk read error

  fat_rd_end:
    pop es
    popa
    ret

; get the root directory into boot area (0:2800). Overwrites the MBR
; uses parameters from floppy logical sector 0
load_root:
    pusha
    push es

    push word 0
    pop es
    mov bx,0x02800		; overwrite the parameter sector
    mov ax,[start_root]
    mov dx,[start_root+2]
    call calc_phys_sector
    mov al,[root_sectors]
    call rd_sectors
    jnc root_rd_end
    mov si,badsect
    call print
    jmp $			; Fatal - floppy disk read error

  root_rd_end:
    pop es
    popa
    ret

; Read a standard FAT-12 format file into RAM
; On entry - CX = first cluster, ES:BX = file buffer, DX:AX = file size,
; DS -> beginning of kernel segment
; Returns CY clr/set for good/bad read
; Depends on floppy parameters and FAT table being previously read and set
read_file:
    pusha
    push es
    mov si,cx			; protect the first cluster number

    mov cx,[bytespersector]	; ensure NOT 0 in table (above)
    jcxz rd_rtn_error
    dec cx			; round up
    add ax,cx			; sectors = (total bytes + bytes/sector - 1) / bytes/sector
    adc dx,0
    inc cx
    div cx			; AX = whole sectors
    cmp ax,0			; any?
    jne file_cont1
  rd_rtn_error:
    stc
    jmp rd_return
  file_cont1:
    mov cx,ax			; sectors (< 65000)
    mov ax,[totalsectors]	; max. avail. sectors => total - system reserved
    mov dx,[totalsectors+2]	; this header version always stores in large count
    sub ax,[start_user]
    sbb dx,[start_user+2]	; available = user to end of partition
    cmp cx,ax			; file size <= available
    ja	rd_rtn_error

    mov ax,cx			; convert number sectors to clusters for loop count
    xor dx,dx
    xor cx,cx
    mov cl,[sectorspercluster]
    jcxz rd_rtn_error
    dec cx
    add ax,cx
    inc cx
    div cx			; AX = whole clusters
    mov cx,ax			; cluster loop counter

    mov ax,[bytespersector]	; should be multiple of paragraph size
    xor dx,dx
    mov dl,[sectorspercluster]
    mov di,dx
    mul di
    mov di,16		; bytes/paragraph
    div di
    mov di,ax		; save paragraphs per cluster in DI for segment increment
    mov ax,si		; first cluster in AX

  cluster_lp:
    push ax		; AX = current cluster
    push cx		; CX = clusters left to load

    dec ax		; cluster number to logical sector
    dec ax		; logical sector = (cluster - 2) * sectors/cluster + user_start
    xor cx,cx
    mov cl,[sectorspercluster]
    mul cx
    add ax,[start_user] 	; AX should be < 2880
    adc dx,[start_user+2]	; DX should be 0
    call calc_phys_sector	; can abort boot, but shouldn't

    mov al,[sectorspercluster]	; load entire cluster
    call rd_sectors
    jnc good_cluster
    pop cx
    pop ax
    stc
    jmp short rd_return
  good_cluster:
    mov ax,es			; update the segment to load to for next cluster
    add ax,di
    mov es,ax
    pop cx			; loop counter
    pop ax			; current cluster
    dec cx
    jz good_rd_return		; all clusters loaded?

    mov si,ax			; save a copy of current cluster
    shl ax,1			; pointer to FAT = 3/2 * old cluster + base
    add ax,si
    shr ax,1
    add ax,0x0600		; see load FAT
    xchg ax,si
    push ds
    push word 0
    pop ds
    mov dx,[si] 		; get next cluster (odd or even dependent)
    pop ds
    test al,1			; old was even?
    jz cluster0
    shr dx,4
  cluster0:
    and dx,0xFFF		; 12-bits
    mov ax,dx
    cmp ax,0xFF0		; reserved, bad or end of file
    jb	cluster_lp
    stc
    jmp short rd_return
  good_rd_return:
    clc
  rd_return:
    pop es
    popa
    ret

; Routines to parse the configuration file
; --------------------------------------------------------------------------

xchg_pntrs:
    push ds			; exchange pointers
    push es
    pop  ds
    pop  es
    xchg di,si
    ret

elim_white:			; DS:SI -> current point in file buffer, CX = characters left
    push ax
    cld
  elim_lp1:
    lodsb
    dec  cx
    jcxz elim_end
    cmp  al,' ' 		; space
    je	 elim_lp1
    cmp  al,13			; <cr>
    je	 elim_lp1
    cmp  al,10			; <lf>
    je	 elim_lp1
    cmp  al,9			; <tab>
    je	 elim_lp1
  elim_end:			; previous character is not 'white'
    inc  cx			; returns at least 1 character left (even if white space)
    dec  si
    pop  ax
    ret



; if no or corrupt configuration file, load reasonable default (AL on entry)
; if no or bad value in file, return 'ask' [AL = 0]
; returns value 0, min-max in AL
; also on entry DS:SI -> counted configuration string to find,
; BH/BL = max/min values for the configuration variable (hex 0 - ff)

if boot_media=0

get_config:
    push cx
    push dx
    push si
    push di
    push ds
    push es
    cld
    mov  cx,[file_block+0x1C]	; file size (bytes), should be < 5,000
    cmp  cx,-1
    je	 config_exit		; return default given in AX -- no file or bad read

    xor  ax,ax			; DX = count, ES:DI points to string
    lodsb
    mov  dx,ax			; save zero-extended string count
    mov  di,si			; save string start address
    mov  si,0x4400		; DS:SI -> file buffer (in low memory)
    push word 0
    pop  ds
  config_lp1:
    lodsb			; get next character from file
    dec cx
    jle  config_bad		; read to/past end of file?
    cmp  al,'#' 		; start comment?
    jne  config_srch1
  config_lp2:
    call xchg_pntrs
    mov  al,10			; ignore to end of line <lf> = 10 (also preceding <cr> = 13)
    repne scasb
    jne  config_bad		; ran out of file before found <lf>
    call xchg_pntrs
    cmp  cx,0
    jle  config_bad		; read to/past end of file?
    jmp  config_lp1		; try next line

  config_srch1:
    cmp  al,'[' 		; only significant characters are '#' and '[' at this point
    jne  config_lp1		; try next character
    call elim_white
    cmp  dx,cx			; enough bytes left to match string?
    jae  config_bad		; no, would require reading past eof
    mov  ax,dx			; AX = DX = string count
    xchg ax,cx			; CX = string count, AX = bytes left in file
    push di			; save start for next check
    repe cmpsb
    pop  di
    je	 config_val_strt	; found entry (all bytes compared are equal)?
    push ax
    mov  ax,dx			; calculate bytes left in file
    sub  ax,cx
    pop  cx
    sub  cx,ax
    jmp  config_lp2		; ignore the rest of the line

  config_bad:
    xor  eax,eax		; return 'ask'
  config_exit:
    pop  es
    pop  ds
    pop  di
    pop  si
    pop  dx
    pop  cx
    ret

  config_check:
    cmp  di,0			; any characters in value?
    je	 config_bad
  config_limits:
    cmp  dl,bh
    ja	 config_bad
    cmp  dl,bl
    jb	 config_bad
    mov  ax,dx
    jmp  short config_exit
  config_val_strt:
    xor  di,di			; character counter for value
    mov  cx,ax			; reduce file count by string size
    sub  cx,dx
    xor  dx,dx			; beginning value
    call xchg_pntrs
    mov  al,']' 		; value comes after ']'
    cld
    rep  scasb
    cmp  cx,0
    jle  config_check		; read to end of file
    call xchg_pntrs
    call elim_white		; value also after any white space
  config_lp10:
    lodsb
    dec  cx
    cmp  al,'0'
    jb	 config_check
    cmp  al,'9'
    jbe  config_deci
    and  al,0xdf		; convert to upper (clear bit 5)
    cmp  al,'A'
    jb	 config_check
    cmp  al,'F'
    ja	 config_check
    sub  al,'A'-'9'-1
  config_deci:
    inc  di
    cmp  di,2
    ja	 config_bad		; more than 2 hex digits?
    sub  al,'0' 		; AL = 0 - 9, 0a - 0f (10 - 15)
    xchg dl,dh			; DL = 0, DH = previous byte (if any)
    mov  dl,al
    cmp  cx,0			; remaining count must be positive (reached end of file)
    jle  config_limits		; eof -> leave with the current accumulated value
    jmp  short config_lp10

end if ;; boot_media=0


if boot_media=1

get_config:

   xor  eax , eax
   ret

end if ;; boot_media=1


; -------------------------------------------------------------------------------------------

video_entry:	db 5,'VIDEO'		; counted upper case string to match
probe_entry:	db 5,'PROBE'
accel_entry:	db 6,'VACCEL'
mouse_entry:	db 5,'MOUSE'
ram_entry:	db 3,'RAM'
rdrive_entry:	db 7,'RSOURCE'

config_file:	db 'CONFIG  DAT',0	; configuration file name, 8.3 format
file_block:	times 32 db 0		; directory block for file, when found


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   16 bit code entry, from kernel.asm
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
start_of_code:

; Set 16-bit selectors (segment registers) and stack
; Have NOT verified processor's generatiion, yet
; -------------------------------------------------

    cli 			; disable interrupts while manipulating stack
    mov  ax,0x2000
    mov  ss,ax
    mov  sp,0xfffc		; quad align at top of segment
    sti

    call setbase1000		; set DS & ES to beginning of kernel

    cld 			; usual direction is 'up' (increment address)


; Draw welcome screen -- 16-bit code only
; -------------------------------------------------

    ;cmp  byte [display_modechg],2
    ;je   no_mode_atboot
    ;mov  ax,0x0003              ; mode change?
    ;mov  bx,0x0000              ; yes, set 3 (80 X 25, 16-color text)
    ;mov  dx,0x0000
    ;int  0x10
    ;no_mode_atboot:

    mov  ax,0x0200              ; Set cursor position (0,0)
    mov  bx,0x0000              ; To avoid two consecutive vga mode changes
    mov  dx,0x0000
    int  0x10

    push es
    mov  ax,0xb800		; mode 0-6; et al
    mov  es,ax
    mov  di,0
    mov  si,d80x25		; macro definition of start background
    mov  cx,80*25		; entire screen page (code assumes 80 X 25)
    mov  ah,1*16+15		; text attribute = white on blue
    cld

  dfl1:
    lodsb
    stosw
    loop dfl1

    pop es

   
; Display Menuet version
; -------------------------------------------------
   
    mov   si,linef		; place on second line
    call  printplain
    mov   si,linef		; place on second line
    call  printplain
    mov   si,version		; no extra lines -> definition can be used other places
    call  print 		; string in kernel.asm


; 386+ ?
; -------------------------------------------------
   
    pushf
    pop   ax
    mov   dx,ax
    xor   ax,0x4000
    push  ax
    popf
    pushf
    pop   ax
    and   ax,0x4000
    and   dx,0x4000
    cmp   ax,dx
    jnz   cpufine
    mov   si,not386
    call  print
    jmp   $			; fatal cpu error, loop here
  cpufine:


; 32-bit processor confirmed --
; now can set 32 bit stack pointer and other registers
; ----------------------------------------------------

    cli
    mov   ax,0x2000		; stack segment (same as above)
    mov   ss,ax
    mov   esp,0xfffc		; ensure same as 16-bit value
    sti

    xor   eax,eax		; clear registers for clean start
    xor   ebx,ebx
    xor   ecx,ecx
    xor   edx,edx
    xor   esi,esi
    xor   edi,edi
    xor   ebp,ebp


; Flush keyboard controller
; -------------------------------------------------

    mov   dx,100
  fl1:
    mov   cx,10000	; read 10,000 times, then test value
  fl2:
    in	  al,0x64	; test for input available
    loop  fl2
    test  al,1		; anything in controller?
    jz	  fl3
    in	  al,0x60	; get this input, look for more
    dec   dx
    jnz   fl1
  fl3:


; Display Vesa version
; -------------------------------------------------

    push  es
    push  word 0
    pop   es
    mov   ax,0x4f00		; VESA BIOS function (get BIOS info, if function available)
    mov   di,0xa000
    int   0x10
    cmp   ax,0x004f
    je	  vesaok2
    mov   si,novesa		; print with left border
    call  print
    mov   ax,16
    jmp   novesafound
  vesaok2:
    mov   ax,[es:di+4]		; AH = major, AL = minor version
    mov   dx,ax
    add   ax,48*256+48		; convert to ASCII
    mov   [vervesa+19],ah	; replace x.x in string with numbers
    mov   [vervesa+21],al	; update offsets if string is modified
    mov   si,vervesa
    call  print
  novesafound:
    pop es


; DS = ES should = beginning of kernel segment
; get the configuration file, if it exists
; -------------------------------------------------

if boot_media=0

    call reset_floppy
    call get_floppy_params	; reads sector 0 and puts constants into kernel space
    call load_fat		; reads 1st FAT into low RAM for subsequent read
    call load_root		; reads root directory into low RAM for search

; file_search:
    mov cx,[maxrootentries]	; entry counter
    mov si,0x02800		; address of first root entry (see load root)
    push word 0 		; DS:SI points to root directory
    pop ds
  file_lp:
    push cx			; save counter
    mov dx,si			; save start pointer
    mov cx,11			; DOS (8.3) name
    mov di,config_file
    repe cmpsb
    pop cx			; restore root entry counter
    mov si,dx			; restore directory pointer, beginning of this entry
    je file_found
  file_cont:
    add si,[es:bytesperentry]	; goto next entry (PCDOS format)
    loop file_lp
    push es			; restore DS after searching all root entries
    pop  ds
  not_found:
    mov ax,-1			; mark file as empty ("not found" or bad read)
    mov [file_block+0x1C],ax
    mov [file_block+0x1E],ax
    jmp short search_end
		
  file_found:			; SI points to beginning of directory entry
    mov di,file_block		; move 32-byte directory block into kernel space
    mov cx,[es:bytesperentry]
    cld
    rep movsb
    push es			; restore DS after copying directory info
    pop  ds
    mov ax,[file_block+0x1C]	; low byte count
    mov dx,[file_block+0x1E]	; high
    mov cx,[file_block+0x1A]	; CX = first file cluster
    push word 0 		; load configuration file into bottom of memory
    pop es
    mov bx,0x4400		; Put configuration file into a temporary buffer
    call read_file
    push ds			; restore ES after file read
    pop  es
    jc not_found		; bad read -- same as not found
  search_end:

end if ;; boot_media=0

    call setbase1000 ; code sections must be independent

; DS = ES should = beginning of kernel segment
; Default, config file or user selects graphics mode
; -------------------------------------------------

    mov  eax,0			; value to use if no configuration found
    mov  ebx,0x0a01		; configuration limits
    mov  si,video_entry 	; configuration string
    call get_config		; AL = value, AH clear for indexing
    cmp  al,0			; AL = 0 -> ask user
    jne  pre_graph1
    mov  si,gr_mode		; list values for user
    call printplain
  gml0:
    mov   ebx,0x0A01
    call  getkey
    jmp short pre_graph2
  pre_graph1:
    push eax
    mov  si,video_md		; display default or configuration file value
    call printplain
    call U_DOT			; print value (1 - 255)
    pop  eax
  pre_graph2:
    cmp   al,1			; < 1 only if programmer error
    jl	  gml0
    cmp   al,8			; VGA modes?
    jg	  sgml1
    mov   si,ax
    dec   si
    shl   si,4
    add   si,gr_table
    mov   bx,[si+0]
    mov   cx,[si+4]
    mov   dx,[si+8]
    jmp   gml10			; goto mode select end
  sgml1:
    cmp   al,9			; input {9} = VGA mode 0x13
    jnz   gml00
    mov   bx,0x13
    mov   cx,640
    mov   dx,480
    push es
    push  word 0
    pop   es
    mov   [es:0x9000],byte 32	; 32 bits per pixel
    pop   es
    jmp   gml10			; goto mode select end
  gml00:
    cmp   al,0xa		; input 10 ([0] or {A}) = VGA mode 0x12
    jnz   gml02
    mov   bx,0x12
    mov   cx,640
    mov   dx,480
    push es
    push  word 0
    pop   es
    mov   [es:0x9000],byte 32	; 32 bits per pixel
    pop   es
    jmp   gml10			; goto mode select end
  gml02:
    jmp   gml0			; problem - try manual input (again)
  gr_table:
    dd	  0x112+0100000000000000b ,  640 ,  480 , 0
    dd	  0x115+0100000000000000b ,  800 ,  600 , 0
    dd	  0x118+0100000000000000b , 1024 ,  768 , 0
    dd	  0x11B+0100000000000000b , 1280 , 1024 , 0
    dd	  0x112 ,  640 , 480 , 0
    dd	  0x115 ,  800 , 600 , 0
    dd	  0x118 , 1024 , 768 , 0
    dd	  0x11B , 1280 ,1024 , 0
  gml10:
    push es			; put values into shared storage
    push  word 0
    pop   es
    mov   [es:0x9008],bx
    mov   [es:0x900A],cx
    mov   [es:0x900C],dx
    pop   es
    mov   ax,32			; 32 bits per pixel for non-Vesa modes
    cmp   bx,0x13		; mode 12 && 13 are non-Vesa, do NOT probe
    je	  nov
    cmp   bx,0x12
    je	  nov

; Clear temporary buffer in low memory used for Vesa read/write

    push cx
    push es
    push word 0
    pop  es
    mov  cx,128			; 256 bytes
    xor  ax,ax
    mov  di,0xa000
    cld
    rep  stosw
    pop  es
    pop  cx

; Default graphics or probe ? (probe VESA 2+ only)

    ; bx - mode|probe : cx - x size : dx - y size

    test bx,0100000000000000b	; test bit 14 (from table), 0 => do NOT probe
    jz	 noprobe
    push ebx
    mov  eax,0                  ; value to use if no configuration found
    mov  ebx,0x0201
    mov  si,probe_entry 	; configuration string
    call get_config
    pop  ebx
    cmp  al,0
    je	 askprobe

    push eax
    mov si,probe_md
    call printplain
    call OUT1H
    pop eax
    cmp  al,1
    je	 noprobe
    jmp short start_probe

  askprobe:
    mov   si,probetext
    call  printplain
    push  bx
    mov   ebx,0x0201
    call  getkey
    pop   bx
    cmp   al,1
    je	  noprobe

  start_probe:
    push es
    push cx
    push word 0			; Shared data segment
    pop  es

    mov  bx,0x101-1		; inc first (bit 8 => Vesa)

  newprobe:

    inc   bx
    cmp   bx,0x17f		; check 0x101 through 0x17e
    jl    probemore

    mov   si,prnotfnd		; ran through all modes
    call  printplain

    jmp   $			; Fatal - probe allowed, requested and failed

  probemore:

    mov   ax,0x4f01		; VESA BIOS (get mode info)
    mov   cx,bx
    and   cx,0x1ff		; NO modifier bits (15 - 8)
    mov   di,0xa000		; 256-byte buffer to write into
    int   0x10
    test ah,0xff		; 'set' call failed?
    jnz  newprobe

    mov   eax,[es:di]		; Lfb ?
    test  eax,10000000b		; test bit 7
    jz	  newprobe		; no, try next mode

    mov   eax,[es:di+0x12]	; X size ?
    cmp   ax,word [esp]		; CX = number of X pixels
    jne   newprobe

    mov   eax,[es:di+0x14]	; Y size ?
    cmp   ax,dx
    jne   newprobe

    movzx eax,byte [es:di+0x19]
    cmp   al,24
    jb	  newprobe

    add   bx,0100000000000000b	; bit 14 => probe (Vesa bit 14 => use linear buffer)
    mov   [es:0x9008],bx

    mov   si,prid
    call  printplain
    mov  ax,bx
    call OUT4H

    pop  cx
    pop  es


; Find Vesa 2.0 Lfb and Bpp

  noprobe:
   
    test bx,0x100		; VESA mode?
    jz   nov
    mov   ax,0x4f01		; VESA BIOS (get mode info)
    mov   cx,bx
    and  cx,0x1ff		; Bit 8 => Vesa mode, bits 9 & 10 are reserved
    push es
    push  word 0		; 256-byte buffer to write data into
    pop   es
    mov   di,0xa000
    int   0x10
    test ah,0xff		; 'set' call failed?
    jnz  nov2

    mov   ecx,[es:di+0x28]	; v2.0 linear buffer (LFB)
    mov   [es:0x9018],ecx
    movzx ax,byte [es:di+0x19]	; v1.2 bits per pixel (BPP)
    mov   [es:0x9000],ax

    push  ax
    mov   ax, [es:di+0x10]	; Bytes Per Scan Line (all supported versions)
    mov   [es:0x9001],ax
    pop   ax

  nov2:
    pop  es

  nov:				; test bits per pixel value
				; DS = ES = beginning of kernel
    cmp   ax,24
    jnz   nbpp24
    mov   si,bt24
    jmp   bppl
  nbpp24:
    cmp   ax,32
    jnz   nbpp32
    mov   si,bt32
    jmp   bppl
  nbpp32:
    mov   si,btns
    call  printplain
    jmp   $			; fatal error, must be 24 or 32, loop here
  bppl:
    call  printplain

; Find Vesa 1.2 bank switch address

    push  es      
    push  word 0
    pop   es
    mov   bx,[es:0x9008]
    pop   es
    test  bx,0100000000000000b  ; Not for LFB
    jnz   nov12
    cmp   bx,0x13               ; Not for VGA mode 0x13
    je    nov12
    cmp   bx,0x12               ; Not for VGA mode 0x12
    je    nov12

    push es
    mov   ax,0x4f0A		; VESA BIOS (modifies ES and DI)
    mov   bx,0x0		; get protected mode interface table
    int   0x10
    test ah,0xff
    jnz  vbe_error
    cmp  cx,0			; table length - any info?
    jne  vesa12_cont
  vbe_error:
    mov  si,fatalsel
    call print
    jmp  $			; Fatal error - mode NOT supported

  vesa12_cont:
    xor   eax,eax
    xor   ebx,ebx
    mov   ax,es			; eax = address = 16 * segment + offset
    shl   eax,4
    mov   bx,di
    add   eax,ebx
    xor   ebx,ebx
    mov   bx,[es:di]		; offset for 'function 5'
    add   eax,ebx
    push  word 0
    pop   es
    mov   [es:0x9014],eax
    pop  es			; restore ES

  nov12:

; MTRR graphics acceleration

    mov  eax,0			; value to use if no configuration found
    mov  ebx,0x0201
    mov  si,accel_entry 	; configuration string
    call get_config
    cmp  al,0
    jne  pre_mtrr1
    mov   si,gr_acc
    call  printplain
    mov   ebx,0x0201
    call  getkey
    jmp short pre_mtrr2
  pre_mtrr1:
    push eax
    mov  si,accel_md
    call printplain
    call OUT1H
    pop  eax
  pre_mtrr2:
    push es
    push  word 0
    pop   es
    mov   [es:0x901C],al
    pop  es
    mov   si,linef
    call  printplain

; Get mouse port

    mov  eax,0			; value to use if no configuration found
    mov  ebx,0x0301
    mov  si,mouse_entry 	; configuration string
    call get_config
    cmp  al,0
    jne  pre_mouse1
    mov   si,askmouse
    call  print
    mov   ebx,0x0301
    call  getkey
    jmp short pre_mouse2
  pre_mouse1:
    push eax
    mov  si,mouse_md
    call printplain
    call OUT1H
    pop  eax
  pre_mouse2:
    push es
    push  word 0
    pop   es
    mov   [es:0x9010],al
    pop  es
    mov   si,linef
    call  printplain

; Memory size
   
    mov  eax,0			; value to use if no configuration found
    mov  ebx,0x0701
    mov  si,ram_entry		; configuration string
    call get_config
    cmp  al,0
    jne  pre_mem1
    mov   si,mem_model
    call  printplain
    mov   ebx,0x0701
    call  getkey
    jmp short pre_mem2
  pre_mem1:
    push eax
    mov  si,ram_szcd
    call print
    call OUT1H
    pop  eax
  pre_mem2:
    push es
    push  word 0
    pop   es
    mov   [es:0x9030],al
    pop  es
    mov   si,linef
    call  printplain

; Direct write to LFB, paging disabled
   
    movzx eax,byte [es:preboot_lfb] 
    mov   eax,1			; Force paging disabled
    cmp   eax,0
    jne   pre_lfb
    mov   si,gr_direct
    call  printplain
    mov   ebx,0x0201
    call  getkey
  pre_lfb:
    push es
    push  word 0
    pop   es
    mov   [es:0x901E],al
    pop  es

; Boot device
   
    mov  eax,0			; value to use if no configuration found
    mov  ebx,0x0301
    mov  si,rdrive_entry	; configuration string
    call get_config
    cmp  al,0
    jne  pre_device1
    mov   si,bdev
    call  printplain
    mov   ebx,0x0301
    call  getkey
    jmp short pre_device2
  pre_device1:
    push eax
    mov  si,boot_md
    call printplain
    call OUT1H
    pop  eax
  pre_device2:
    dec   al			; floppy = 0, HDD = 1, Prior RAM image = 2
    mov   [boot_dev],al
    mov   si,linef
    call  printplain

; Read entire diskette into memory
;------------------------
   
    cmp   [boot_dev],byte 0
    jne   no_sys_on_floppy
    mov   si,diskload
    call  print

    call  reset_floppy
    call  get_floppy_params     ; correct disk parameters in memory

    xor  ax,ax			; starting cylinder = 0
    mov  cx,[maxcylinders]	; outer (cylinder) loop counter

  cylinder_lp:
    push cx
    xor  dx,dx			; current head = 0
    mov  cx,[n_heads]		; inner (head) loop counter
  head_lp:
    push ax
    push cx
    push dx
    mov  ch,al			; set cylinder (< 255)
    mov  cl,1			; start with physical sector 1, each track
    mov  al,[sectorspertrack]	; Read a track at a time
    push word 0
    pop  es
    mov  bx,0xa000		; es:bx -> data area (reused each time)
    call rd_sectors
    jnc  movehigh
    mov  si,badsect		; Fatal - floppy disk read error
    call print
    jmp  stopread

  movehigh:
    ; move -> 1mb               ; see memmap.inc
    mov  si,movedesc		; descriptor table (ES:SI)
    call setbase1000
    mov  ax,[bytespersector]	; words per sector (power of 2)
    shr  ax,1
    mul  word [sectorspertrack]	; CX = words per track (count for move)
    mov  cx,ax
    mov   ah,0x87		; move track to high memory
    int   0x15
    cmp   ah,0			; Was the move successfull ?
    jne   badmove

    xor  eax,eax
    mov  ax,[bytespersector]
    mul  word [sectorspertrack]	; bytes per track
    add  [movedesc+0x18+2],eax	; udate destination

    pop  dx
    pop  cx
    pop  ax
    inc  dh
    loop head_lp		; next head (or cylinder)

    inc  ax
    push ax			; ax = number of cylinders read (next to read)
    mov  bx,100
    mul  bx			; scale to 100%
    mov  bx,[maxcylinders]
    cmp  bx,0
    jg	 good_total
    mov  bx,80
    mov  [maxcylinders],bx
  good_total:
    div  bx			; whole % done
    xor  dx,dx
    add  ax,2			; round to nearest 5%
    mov  bx,5
    div  bx
    mul  bx
    cmp  ax,95
    jle  set_percent		; >= 98% -> show 99 (not more than 2 digits)
    mov  ax,99
  set_percent:
    xor  dx,dx
    mov  bx,10
    div  bx			; split digits
    add  al,'0'
    add  dl,'0'
    mov   [pros+1],dl
    mov   [pros],al
    mov   si,pros
    call  printplain

    pop  ax
    pop  cx
    dec  cx
    jcxz readdone		; Entire disk is in high memory
    jmp  cylinder_lp		; loop to next cylinder

  badmove:
    mov   si,memmovefailed	; Fatal - trouble creating disk image
    call  print
  stopread:
    mov   dx,0x3f2		; Floppy motor off
    mov   al,0
    out   dx,al
    jmp   $			; stop here

  movedesc:
    db	  0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db	  0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db	  0xff,0xff,0x0,0xa0,0x00,0x93,0x0,0x0
    db	  0xff,0xff,0x0,0x00,0x10,0x93,0x0,0x0
    db	  0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db	  0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db	  0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0
    db	  0x00,0x00,0x0,0x00,0x00,0x00,0x0,0x0

  readdone:
    mov  al,8			; backspace
    call OUTCHAR
    call OUTCHAR
    pop   ax
    mov   si,okt		; so quick, not seen
    call  printplain

  no_sys_on_floppy:
    mov   dx,0x3f2	      ; Floppy motor off (don't depend on BIOS timer)
    mov   al,0
    out   dx,al

; Paging table

    push  word 0
    pop   es
    mov   ecx,[es:0x9018]	; LFB address
    push  ecx

    map_mem equ 63		; Amount of memory to map

    mov   bx,0x6000
    mov   es,bx 		; [es:di] = 6000:0
    xor   edi,edi
    mov   ecx,256*map_mem	; Map (mapmem) M
    mov   eax,7
    cld
  pt2:
    cmp   ecx,256*(map_mem-8)	  ; 8 M map to LFB
    jne   pt3
    pop   eax
    add   eax,7
  pt3:
    cmp   ecx,256*(map_mem-12)	  ; 12 M back to linear = physical
    jne   pt4
    mov   eax,12*0x100000 + 7
  pt4:
    stosd
    add   eax,4096
    loop  pt2

; 4 kb paging

    mov   bx , 0x7000
    mov   es , bx		  ; [es:di] = 7000:0
    xor   edi, edi
    mov   ecx, 64 / 4
    mov   eax, 0x60007		  ; For 0 M
    cld
  pd4k:
    stosd
    add   eax, 0x01000
    loop  pd4k
    mov   eax, 0x70000 +8+16	; Page directory and enable caches
    mov   cr3, eax
   
; Set standard graphics (mode 0x12 or 13)

    push  es
    push  word 0
    pop   es
    mov   bx,[es:0x9008]	; video mode
    mov   ax,bx 		; Vga & 320x200
    cmp   ax,0x13
    je	  setgr
    cmp   ax,0x12
    je	  setgr
    mov   ax,0x4f02		; Vesa BIOS (set mode)
  setgr:
    int   0x10
    cmp   ah,0
    jz	  gmok
    mov   si,fatalsel
    call  print
    jmp   $			; Fatal error - mode NOT supported
  gmok:
    pop   es
   
; Set mode 0x12 graphics registers
   
    cmp   bx,0x12
    jne   gmok2
   
    mov   al,0x05
    mov   dx,0x03ce
    out   dx,al      ; Select GDC mode register
    mov   al,0x02
    mov   dx,0x03cf
    out   dx,al      ; Set write mode 2
   
    mov   al,0x02
    mov   dx,0x03c4
    out   dx,al      ; Select VGA sequencer map mask register
    mov   al,0x0f
    mov   dx,0x03c5
    out   dx,al      ; Set mask for all planes 0-3
   
    mov   al,0x08
    mov   dx,0x03ce
    out   dx,al      ; Select GDC bit mask register
		     ; For writes to 0x03cf
  gmok2:
    push ds
    pop  es


; Eof - Return to kernel16.inc
