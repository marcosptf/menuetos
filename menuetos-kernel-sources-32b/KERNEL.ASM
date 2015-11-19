;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   MenuetOS Copyright 2000-2015 Ville Turjanmaa
;;
;;   See file COPYING for details with these additional details:
;;     - All code written in 32 bit x86 assembly language
;;     - No external code (eg. bios) at process execution time
;;
;;     Ville Turjanmaa, vmt@menuetos.net
;;      - main os coding/design
;;     Jan-Michael Brummer, BUZZ2@gmx.de
;;      - bugfixes in mouse & display drivers
;;      - code for cd-player
;;     Felix Kaiser, info@felix-kaiser.de
;;      - AMD K6-II compatible IRQ's
;;      - APM management
;;     Paolo Minazzi, paolo.minazzi@inwind.it
;;      - Sound Blaster
;;      - Fat32 write
;;     quickcode@mail.ru
;;      - 320x200 palette & convert
;;      - Vesa 1.2 bankswitch for S3 cards
;;     Alexey, kgaz@crosswinds.net
;;      - Voodoo compatible graphics
;;     Juan M. Caravaca, bitrider@wanadoo.es
;;      - Graphics optimizations
;;     kristol@nic.fi
;;      - Bootfix for some Pentium models
;;     Mike Hibbett, mikeh@oceanfree.net
;;      - SLIP driver and TCPIP stack (skeleton)
;;     Lasse Kuusijarvi, kuusijar@lut.fi
;;      - jumptable and modifications for syscalls
;;     Jarek Pelczar, jarekp3@wp.pl
;;      - AMD compatible MTRR's
;;
;;   Compile with FASM 1.50+
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

max_processes      equ   255

window_data        equ   0x0000
tss_data           equ   0x9A0000
tss_step           equ   (128+8192) ; tss & i/o - 65536 ports, * 256=2129920
draw_data          equ   0xC00000
sysint_stack_data  equ   0xC03000

twdw               equ   (0x3000-window_data)

fat_base           equ   0x100000       ; ramdisk base
fat_table          equ   0x280000       ; 0xD80000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   Included files:
;;
;;   Kernel16.inc
;;    - Booteng.inc   English text for bootup
;;    - Bootcode.inc  Hardware setup
;;    - Pci16.inc     PCI functions
;;
;;   Kernel32.inc
;;    - Sys32.inc     Process management
;;    - Shutdown.inc  Shutdown and restart
;;    - Fat32.inc     Read / write hd
;;    - Vesa12.inc    Vesa 1.2 driver
;;    - Vesa20.inc    Vesa 2.0 driver
;;    - Vga.inc       VGA driver
;;    - Stack.inc     Network interface
;;    - Mouse.inc     Mouse pointer
;;    - Scincode.inc  Window skinning
;;    - Pci32.inc     PCI functions
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;                  16 BIT ENTRY FROM BOOTSECTOR                        ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use16

                  org   0x0 ; For 16 bit code

kernel_start:

                  jmp   start_of_code

version           db    'Menuet32 v0.86                   ',13,10,13,10,0
                  dd    endofcode-0x10000

                  db   'Boot02'

display_modechg   db    0  ; display mode change for text, yes/no (0 or 2)
                           ;
                           ; Important!!
                           ; Must be set to 2, to avoid two screenmode
                           ; changes within a very short period of time.

display_atboot    db    0  ; display text, yes/no (0 or 2)
preboot_graph     db    0  ; graphics mode
preboot_mouse     db    0  ; mouse port
preboot_mtrr      db    0  ; mtrr graphics acceleration
preboot_lfb       db    0  ; linear frame buffer
preboot_blogesc   db    0  ; start immediately after bootlog
preboot_device    db    0  ; load ramdisk from floppy/hd/kernelrestart
preboot_memory    db    0  ; amount of memory
preboot_gprobe    db    0  ; probe with vesa 2.0+



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;                      16 BIT INCLUDED FILES                           ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include "KERNEL16.INC"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;                  SWITCH TO 32 BIT PROTECTED MODE                     ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

os_data        equ  os_data_l-gdts    ; GDTs
os_code        equ  os_code_l-gdts
int_code       equ  int_code_l-gdts
int_data       equ  int_data_l-gdts
tss0sys        equ  tss0sys_l-gdts
graph_data     equ  3+graph_data_l-gdts
tss0           equ  tss0_l-gdts
tss0i          equ  tss0i_l-gdts
tss0t          equ  tss0t_l-gdts
app_code       equ  3+app_code_l-gdts
app_data       equ  3+app_data_l-gdts
ring3_data     equ  3+ring3_data_l-gdts
ring3_code     equ  3+ring3_code_l-gdts
ring2_data     equ  2+ring2_data_l-gdts
ring2_code     equ  2+ring2_code_l-gdts
ring1_data     equ  1+ring1_data_l-gdts
ring1_code     equ  1+ring1_code_l-gdts


; CR0 Flags - Protected mode and Paging

        push    word 0
	pop	es
	mov	ecx,0x00000001
	mov	bx,[es:9008]		; get video mode (bootcode.inc)
	and	ebx,0xffff
	cmp	ebx,0100000000000000b	; lfb -> paging
	jb	no_paging
	mov	al,[es:0x901E]
	cmp	al,1
	je	no_paging
	or	ecx,0x80000000
       no_paging:

; Enabling 32 bit protected mode

        cli                             ; disable all irqs
        cld
        mov     al,255                  ; mask all irqs
        out     0xa1,al
        out     0x21,al
   l.5: in      al, 0x64                ; Enable A20
        test    al, 2
        jnz     l.5
        mov     al, 0xD1
        out     0x64, al
   l.6: in      al, 0x64
        test    al, 2
        jnz     l.6
        mov     al, 0xDF
        out     0x60, al
        lgdt    [cs:gdts-0x10000]       ; Load GDT
        mov     eax, cr0                ; Turn on paging // protected mode
        or      eax, ecx
        and     eax, 10011111b *65536*256 + 0xffffff ; caching enabled
        mov     cr0, eax
        jmp     shortjmp
      shortjmp:
        mov     ax,os_data              ; Selector for os
        mov     ds,ax
        mov     es,ax
        mov     fs,ax
        mov     gs,ax
        mov     ss,ax
        mov     esp,0x2FFF0             ; Set stack
        jmp     pword os_code:B32       ; jmp to enable 32 bit mode

use32

kernel_32bit:

org ( 0x10000 + ( kernel_32bit - kernel_start ) ) 

macro align value { rb (value-1) - ($ + value-1) mod value }

boot_fonts        db   'Fonts loaded',0
boot_tss          db   'Setting TSSs',0
boot_cpuid        db   'Reading CPUIDs',0
boot_devices      db   'Detecting devices',0
boot_timer        db   'Setting timer',0
boot_irqs         db   'Reprogramming IRQs',0
boot_setmouse     db   'Setting mouse',0
boot_windefs      db   'Setting window defaults',0
boot_bgr          db   'Calculating background',0
boot_resirqports  db   'Reserving IRQs & ports',0
boot_setrports    db   'Setting addresses for IRQs',0
boot_setostask    db   'Setting OS task',0
boot_allirqs      db   'Unmasking all IRQs',0
boot_tsc          db   'Reading TSC',0
boot_pal_ega      db   'Setting EGA/CGA 320x200 palette',0
boot_pal_vga      db   'Setting VGA 640x480 palette',0
boot_mtrr         db   'Setting MTRR',0
boot_tasking      db   'All set - press ESC to start',0

boot_y dd 10

boot_log:

         ret

         pusha

         mov   edx,esi
.bll3:   inc   edx
         cmp   [edx],byte 0
         jne   .bll3
         sub   edx,esi
         mov   eax,10*65536
         mov   ax,word [boot_y]
         add   [boot_y],dword 10
         mov   ebx,0xffffff
         mov   ecx,esi
         mov   edi,1
         call  dtext

         mov   [novesachecksum],1000
         call  checkEgaCga

         cmp   [preboot_blogesc],byte 1
         je    .bll2

         cmp   esi,boot_tasking
         jne   .bll2

.bll1:   in    al,0x64
         in    al,0x60
         cmp   al,129
         jne   .bll1

.bll2:   popa

         ret

cpuid_0    dd  0,0,0,0
cpuid_1    dd  0,0,0,0
cpuid_2    dd  0,0,0,0
cpuid_3    dd  0,0,0,0

firstapp   db  'L','A','U','N','C','H','E','R',' ',' ',' '
char       db  'C','H','A','R',' ',' ',' ',' ','M','T',' '
char2      db  'C','H','A','R','2',' ',' ',' ','M','T',' '
hdsysimage db  'M','S','E','T','U','P',' ',' ','E','X','E'
bootpath   db  0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;                          32 BIT ENTRY                                ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 4

B32:

; CLEAR 0x280000-0xF00000

        xor   eax,eax
        mov   edi,0x280000
        mov   ecx,(0x100000*0xF-0x280000) / 4
        cld
        rep   stosd

; SAVE & CLEAR 0-0xffff

        mov   esi,0x0000
        mov   edi,0x2F0000
        mov   ecx,0x10000 / 4
        cld
        rep   movsd
        xor   eax,eax
        mov   edi,0
        mov   ecx,0x10000 / 4
        cld
        rep   stosd

; SAVE REAL MODE VARIABLES

        movzx eax,byte [0x2f0000+0x9010]  ; mouse port
        mov   [0xF604],al
        mov   al,[0x2f0000+0x9000]        ; bpp
        mov   [0xFBF1],al
        movzx eax,word [0x2f0000+0x900A]  ; X max
        sub   eax,1
        mov   [0xfe00],eax
        movzx eax,word [0x2f0000+0x900C]  ; Y max
        sub   eax,1
        mov   [0xfe04],eax
        movzx eax,word [0x2f0000+0x9008]  ; screen mode
        mov   [0xFE0C],eax
        mov   eax,[0x2f0000+0x9014]       ; Vesa 1.2 bnk sw add
        mov   [0xE030],eax
        mov   [0xfe08],word 640*4         ; Bytes PerScanLine
        cmp   [0xFE0C],word 0x13          ; 320x200
        je    srmvl1
        cmp   [0xFE0C],word 0x12          ; VGA 640x480
        je    srmvl1
        mov   ax,[0x2f0000+0x9001]        ; for other modes
        mov   [0xfe08],ax
      srmvl1:

; GRAPHICS ADDRESSES

        mov     eax,0x100000*8                    ; LFB address
        cmp     [0xfe0c],word 0x13
        je      no_d_lfb
        cmp     [0xfe0c],word 0x12
        je      no_d_lfb
        cmp     [0x2f0000+0x901e],byte 1
        jne     no_d_lfb
        mov     eax,[0x2f0000+0x9018]
      no_d_lfb:
        mov     [0xfe80],eax

        cmp     [0xfe0c],word 0100000000000000b
        jge     setvesa20
        cmp     [0xfe0c],word 0x13
        je      v20ga32
        mov     [0xe020],dword Vesa12_putpixel24  ; Vesa 1.2
        mov     [0xe024],dword Vesa12_getpixel24
        cmp     [0xfbf1],byte 24
        jz      ga24
        mov     [0xe020],dword Vesa12_putpixel32
        mov     [0xe024],dword Vesa12_getpixel32
      ga24:
        jmp     v20ga24
      setvesa20:
        mov     [0xe020],dword Vesa20_putpixel24  ; Vesa 2.0
        mov     [0xe024],dword Vesa20_getpixel24
        cmp     [0xfbf1],byte 24
        jz      v20ga24
      v20ga32:
        mov     [0xe020],dword Vesa20_putpixel32
        mov     [0xe024],dword Vesa20_getpixel32
      v20ga24:
        cmp     [0xfe0c],word 0x12                ; 16 C VGA 640x480
        jne     no_mode_0x12
        mov     [0xe020],dword VGA_putpixel
        mov     [0xe024],dword Vesa20_getpixel32
      no_mode_0x12:

        mov     eax,[0xfe80]                      ; set for gs
        mov     [graph_data_l+2],ax
        shr     eax,16
        mov     [graph_data_l+4],al
        mov     [graph_data_l+7],ah

; MEMORY MODEL

        mov     [0xfe84],dword 0x100000*18      ; apps mem base address
        movzx   ecx,byte [0x2f0000+0x9030]
        dec     ecx
        mov     eax,32*0x100000
        shl     eax,cl
        mov     [0xfe8c],eax      ; memory for use
        cmp     eax,16*0x100000
        jne     no16mb
        mov     [0xfe84],dword 0x100000*10
      no16mb:

; READ RAMDISK IMAGE FROM HD

        cmp   [boot_dev],byte 1
        jne   no_sys_on_hd

        mov   [fat32part],1       ; Partition
        mov   [hdbase],0x1f0      ; Controller base
        mov   [hdpos],1           ;
        mov   [hdid],0x0          ;
        mov   [0xfe10],dword 0    ; entries in hd cache
        call  set_FAT32_variables

        mov   esi,40
        mov   ecx,fat_base ; 0x100000
      hdbootl1:
        mov   eax,hdsysimage
        mov   edi,12
        mov   ebx,18*2*5
        mov   edx,bootpath

        pusha
        call  file_read
        cmp   eax,0               ; image not found
        jne   $
        popa

        add   ecx,512*18*2*5
        add   esi,18*2*5
        cmp   esi,1474560/512+41-1
        jb    hdbootl1
      no_sys_on_hd:


; CALCULATE FAT CHAIN FOR RAMDISK

        call  calculatefatchain

; LOAD FONTS I and II

        mov   [0x3000],dword 1
        mov   [0x3004],dword 1
        mov   [0x3010],dword 0x3020

        mov   eax,char
        mov   esi,12
        mov   ebx,0
        mov   ecx,26000
        mov   edx,0x37000
        call  fileread

        mov   eax,char2
        mov   esi,12
        mov   ebx,0
        mov   ecx,26000
        mov   edx,0x30000
        call  fileread

        mov   esi,boot_fonts
        call  boot_log

; REDIRECT ALL IRQ'S TO INT'S 0x20-0x2f

        mov   esi,boot_irqs
        call  boot_log
        call  rerouteirqs

        mov    esi,boot_tss
        call   boot_log

; BUILD SCHEDULER

        call   build_scheduler ; sys32.inc

; LOAD IDT

         lidt  [cs:idts]

; READ CPUID RESULT

        mov     esi,boot_cpuid
        call    boot_log
        pushfd                  ; get current flags
        pop     eax
        mov     ecx,eax
        xor     eax,0x00200000  ; attempt to toggle ID bit
        push    eax
        popfd
        pushfd                  ; get new EFLAGS
        pop     eax
        push    ecx             ; restore original flags
        popfd
        and     eax,0x00200000  ; if we couldn't toggle ID,
        and     ecx,0x00200000  ; then this is i486
        cmp     eax,ecx
        jz      nopentium
        ; It's Pentium or later. Use CPUID
        mov     edi,cpuid_0
        mov     esi,0
      cpuid_new_read:
        mov     eax,esi
        cpuid
        call    cpuid_save
        add     edi,4*4
        cmp     esi,3
        jge     cpuid_done
        cmp     esi,[cpuid_0]
        jge     cpuid_done
        inc     esi
        jmp     cpuid_new_read
      cpuid_save:
        mov     [edi+00],eax
        mov     [edi+04],ebx
        mov     [edi+8],ecx
        mov     [edi+12],edx
        ret
      cpuid_done:
      nopentium:

; CR4 flags - enable fxsave / fxrstore
;
;        finit
;        mov     eax,1
;        cpuid
;        test    edx,1000000h
;        jz      fail_fpu
;        mov     eax,cr4
;        or      eax,200h        ; Enable fxsave/fxstor
;        mov     cr4,eax
;     fail_fpu:

; DETECT DEVICES

        mov    esi,boot_devices
        call   boot_log
        call   detect_devices

 ; TIMER SET TO 1/100 S

        mov   esi,boot_timer
        call  boot_log
        mov   al,0x34              ; set to 100Hz
        out   0x43,al
        mov   al,0x9b              ; lsb    1193180 / 1193
        out   0x40,al
        mov   al,0x2e              ; msb
        out   0x40,al

; SET MOUSE

        mov   esi,boot_setmouse
        call  boot_log

        call  setmouse

; SET PRELIMINARY WINDOW STACK AND POSITIONS

        mov   esi,boot_windefs
        call  boot_log
        call  setwindowdefaults

; SET BACKGROUND DEFAULTS

        mov   esi,boot_bgr
        call  boot_log
        call  calculatebackground

; RESERVE SYSTEM IRQ'S JA PORT'S

        mov   esi,boot_resirqports
        call  boot_log
        call  reserve_irqs_ports

; SET PORTS FOR IRQ HANDLERS

        mov  esi,boot_setrports
        call boot_log
        call setirqreadports

; SET UP OS TASK

        mov  esi,boot_setostask
        call boot_log
        ; name for OS/IDLE process
        mov  [0x80000+256+0],dword 'OS/I'
        mov  [0x80000+256+4],dword 'DLE '
        ; task list
        mov  [0x3004],dword 2         ; number of processes
        mov  [0x3000],dword 0         ; process count - start with os task
        mov  [0x3020+0xE],byte  1     ; on screen number
        mov  [0x3020+0x4],dword 1     ; process id number

        ; set default flags & stacks
        mov  [l.eflags],dword 0x11202 ; sti and resume
        mov  [l.ss0], os_data
        mov  [l.ss1], ring1_data
        mov  [l.ss2], ring2_data
        mov  [l.esp0], 0x52000
        mov  [l.esp1], 0x53000
        mov  [l.esp2], 0x54000
        ; osloop - TSS
        mov  eax,cr3
        mov  [l.cr3],eax
        mov  [l.eip],osloop
        mov  [l.esp],0x2fff0
        mov  [l.cs],os_code
        mov  [l.ss],os_data
        mov  [l.ds],os_data
        mov  [l.es],os_data
        mov  [l.fs],os_data
        mov  [l.gs],os_data
        ; move tss to tss_data+tss_step
        mov  esi,tss_sceleton
        mov  edi,tss_data+tss_step
        mov  ecx,120/4
        cld
        rep  movsd

        mov  ax,tss0
        ltr  ax

; READ TSC / SECOND

        mov   esi,boot_tsc
        call  boot_log
        call  _rdtsc
        mov   ecx,eax
        mov   esi,250               ; wait 1/4 a second
        call  delay_ms
        call  _rdtsc
        sub   eax,ecx
        shl   eax,2
        mov   [0xf600],eax          ; save tsc / sec

; SET VARIABLES

        call  set_variables

; STACK AND FDC

        call  stack_init
        call  fdc_init

; PALETTE FOR 320x200 and 640x480 16 col

        cmp   [0xfe0c],word 0x12
        jne   no_pal_vga
        mov   esi,boot_pal_vga
        call  boot_log
        call  paletteVGA
      no_pal_vga:

        cmp   [0xfe0c],word 0x13
        jne   no_pal_ega
        mov   esi,boot_pal_ega
        call  boot_log
        call  palette320x200
      no_pal_ega:

; LOAD DEFAULT SKIN

        call  load_default_skin

; MTRR'S

        call  enable_mtrr


; LOAD FIRST APPLICATION

        mov   [0x3000],dword 1
        mov   [0x3004],dword 1

        mov   [boot_application_load],byte 1
        mov   eax,firstapp
        call  start_application_fl
        mov   [boot_application_load],byte 0

        cmp   eax,2                  ; if no first app found - halt
        je    first_app_found

        cli
        jmp   $

      boot_application_load: dd 0x0

      first_app_found:

        mov   [0x3004],dword 2
        mov   [0x3000],dword 0


; START MULTITASKING

        mov   esi,boot_tasking
        call  boot_log

        mov   [0xe000],byte 1        ; multitasking enabled


; UNMASK ALL IRQ'S

        mov   esi,boot_allirqs
        call  boot_log

        mov   al,0                   ; unmask all irq's
        out   0xA1,al
        out   0x21,al

        mov   ecx,32

     ready_for_irqs:

        mov   al,0x20                ; ready for irqs
        out   0x20,al
        out   0xa0,al

        loop  ready_for_irqs         ; flush the queue

        sti
        jmp   $                      ; wait here for timer to take control

        ; Fly :)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                    ;
;                         MAIN OS LOOP                               ;
;                                                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

osloop:

        call   check_mouse_data
        call   draw_pointer

        call   check_menus
        call   check_scrolls
        call   checkbuttons
        call   checkwindows
        call   check_window_move_request

        call   checkmisc
        call   checkEgaCga

        call   stack_handler

        call   checkidle

        jmp    osloop



osloop_without_gui_response:

        call   check_mouse_data
        call   draw_pointer

        call   checkmisc
        call   checkEgaCga

        call   stack_handler

        call   checkidle

        ret


checkidle:

        pusha

        cmp  [check_idle_semaphore],0
        jne  no_idle_state

        call change_task
        mov  eax,[idlemem]
        mov  ebx,[0xfdf0]
        cmp  eax,ebx
        jnz  idle_exit
        call _rdtsc
        mov  ecx,eax
      idle_loop:
        hlt
        cmp  [check_idle_semaphore],0
        jne  idle_loop_exit
        mov  eax,[0xfdf0]
        cmp  ebx,eax
        jz   idle_loop
      idle_loop_exit:
        mov  [idlemem],eax
        call _rdtsc
        sub  eax,ecx
        mov  ebx,[idleuse]
        add  ebx,eax
        mov  [idleuse],ebx

        popa
        ret

      idle_exit:

        mov  ebx,[0xfdf0]
        mov  [idlemem],ebx
        call change_task

        popa
        ret

      no_idle_state:

        dec  [check_idle_semaphore]

        mov  ebx,[0xfdf0]
        mov  [idlemem],ebx
        call change_task

        popa
        ret

idlemem               dd   0x0
idleuse               dd   0x0
idleusesec            dd   0x0
check_idle_semaphore  dd   0x0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                      ;
;                   INCLUDED SYSTEM FILES                              ;
;                                                                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


include "KERNEL32.INC"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                      ;
;                       KERNEL FUNCTIONS                               ;
;                                                                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_mtrr:

        pusha

        cmp    [0x2f0000+0x901c],byte 2
        je     no_mtrr
        mov    eax,[0xFE0C]                ; if no LFB then no MTRR
        test   eax,0100000000000000b
        jz     no_mtrr
        mov    edx,[cpuid_1+3*4]           ; edx - MTRR's supported ?
        test   edx,1000000000000b
        jz     no_mtrr
        call   find_empty_mtrr
        cmp    ecx,0
        jz     no_mtrr
        mov    esi,boot_mtrr               ; 'setting mtrr'
        call   boot_log
        mov    edx,0x0                     ; LFB , +8 M , write combine
        mov    eax,[0x2f9018]
        or     eax,1
        wrmsr
        inc    ecx
        mov    edx,0xf
        mov    eax,0xff800800
        wrmsr
        mov    ecx,0x2ff                   ; enable mtrr's
        rdmsr
        or     eax,100000000000b           ; set
        wrmsr
     no_mtrr:

        popa
        ret

setwindowdefaults:

        pusha

        xor   eax,eax
        mov   ecx,0xc000
       swdl:
        inc   eax
        add   ecx,2
        mov   [ecx+0x000],ax          ; process no
        mov   [ecx+0x400],ax          ; positions in stack
        cmp   ecx,0xc400-2            ; the more high, the more surface
        jnz   swdl

        popa
        ret

find_empty_mtrr:  ; 8 pairs checked

        mov    ecx,0x201-2
      mtrr_find:
        add    ecx,2
        cmp    ecx,0x200+8*2
        jge    no_free_mtrr
        rdmsr
        test   eax,0x0800
        jnz    mtrr_find
        dec    ecx
        ret
      no_free_mtrr:
        mov    ecx,0
        ret

reserve_irqs_ports:

        pusha

        mov  [irq_owner+4*0],byte 1    ; timer
        mov  [irq_owner+4*1],byte 1    ; keyboard
        mov  [irq_owner+4*5],byte 1    ; sound blaster
        mov  [irq_owner+4*6],byte 1    ; floppy diskette
        mov  [irq_owner+4*13],byte 1   ; math co-pros
        mov  [irq_owner+4*14],byte 1   ; ide I
        mov  [irq_owner+4*15],byte 1   ; ide II
        movzx eax,byte [0xf604]        ; mouse irq
        dec   eax
        add   eax,mouseirqtable
        movzx eax,byte [eax]
        shl   eax,2
        mov   [irq_owner+eax],byte 1


                                       ; RESERVE PORTS
        mov   edi,1                    ; 0x00-0xff
        mov   [0x2d0000],edi
        shl   edi,4
        mov   [0x2d0000+edi+0],dword 1
        mov   [0x2d0000+edi+4],dword 0x0
        mov   [0x2d0000+edi+8],dword 0xff
        cmp   [0xf604],byte 2          ; com1 mouse -> 0x3f0-0x3ff
        jne   ripl1
        inc   dword [0x2d0000]
        mov   edi,[0x2d0000]
        shl   edi,4
        mov   [0x2d0000+edi+0],dword 1
        mov   [0x2d0000+edi+4],dword 0x3f0
        mov   [0x2d0000+edi+8],dword 0x3ff
      ripl1:
        cmp   [0xf604],byte 3          ; com2 mouse -> 0x2f0-0x2ff
        jne   ripl2
        inc   dword [0x2d0000]
        mov   edi,[0x2d0000]
        shl   edi,4
        mov   [0x2d0000+edi+0],dword 1
        mov   [0x2d0000+edi+4],dword 0x2f0
        mov   [0x2d0000+edi+8],dword 0x2ff
      ripl2:

        popa
        ret

mouseirqtable   db  12    ; ps2
                db  4     ; com1
                db  3     ; com2

setirqreadports:

        mov   [irq12read+0],dword 0x60 + 0x01000000  ; read port 0x60 , byte
        mov   [irq12read+4],dword 0                  ; end of port list
        mov   [irq04read+0],dword 0x3f8 + 0x01000000 ; read port 0x3f8 , byte
        mov   [irq04read+4],dword 0                  ; end of port list
        mov   [irq03read+0],dword 0x2f8 + 0x01000000 ; read port 0x2f8 , byte
        mov   [irq03read+4],dword 0                  ; end of port list

        ret

process_number dd 0x1
novesachecksum dd 0x0


set_variables:

        mov   ecx,0x100                       ; flush port 0x60
.fl60:  in    al,0x60
        loop  .fl60
        mov   [0xfcff],byte 0                 ; mouse buffer
        mov   [0xf400],byte 0                 ; keyboard buffer
        mov   [0xf500],byte 0                 ; button buffer
        mov   [0xfb0a],dword 100*65536+100    ; mouse x/y
        mov   byte [SB16_Status],0            ; Minazzi Paolo
        mov   [0x400000-12],dword 1           ; tiled background
        mov   [0xfe88],dword 0x2C0000         ; address of button list

        ret

align 4


sys_outport:

    mov   edi,ebx          ; separate flag for read / write
    and   ebx,65535

    mov   ecx,[0x2d0000]
    test  ecx,ecx
    jne   sopl8
    mov   [esp+36],dword 1
    ret

  sopl8:
    mov   edx,[0x3010]
    mov   edx,[edx+0x4]
    and   ebx,65535
    cld
  sopl1:

    mov   esi,ecx
    shl   esi,4
    add   esi,0x2d0000
    cmp   edx,[esi+0]
    jne   sopl2
    cmp   ebx,[esi+4]
    jb    sopl2
    cmp   ebx,[esi+8]
    jg    sopl2
    jmp   sopl3

  sopl2:

    dec   ecx
    jnz   sopl1
    mov   [esp+36],dword 1
    ret

  sopl3:

    test  edi,0x80000000 ; read ?
    jnz   sopl4

    mov   dx,bx          ; write
    out   dx,al
    mov   [esp+36],dword 0
    ret

  sopl4:

    mov   dx,bx          ; read
    in    al,dx
    and   eax,0xff
    mov   [esp+36],dword 0
    mov   [esp+24],eax
    ret



checkscreenpixel:

    mov   esi,[0x3004]
    inc   esi

  sciloop:

    cmp   esi,2
    jbe   scic3

    dec   esi

    movzx edi,word [esi*2+0xc400]
    shl   edi,5
    add   edi,window_data

    cmp   [edi+4],ebx ; y start
    jbe   sci2
    jmp   sciloop
  sci2:

    cmp   [edi+0],eax ; x start
    jbe   sci1
    jmp   sciloop
  sci1:
    mov   ecx,[edi+0]
    mov   edx,[edi+4]
    add   ecx,[edi+8]
    add   edx,[edi+12]
    cmp   eax,ecx
    jbe   sci3
    jmp   sciloop
  sci3:
    cmp   ebx,edx
    jbe   sci4
    jmp   sciloop
  sci4:

    movzx ecx,word [esi*2+0xc400]       ; process of pixel

    ; check that the process has a rectangle window

    mov   edx,ecx
    shl   edx,8
    add   edx,0x80000+0x80
    cmp   [edx],dword 0
    je    rect_shaped

  rand_shaped:

    pusha

    sub   eax,[edi+0]
    sub   ebx,[edi+4]
    push  ecx
    mov   ecx,[edx+4]
    shr   eax,cl
    shr   ebx,cl
    mov   esi,[edi+8]
    add   esi,1
    shr   esi,cl
    imul  ebx,esi
    add   eax,ebx
    add   eax,[edx]
    pop   ecx
    mov   edx,ecx
    shl   edx,5
    add   eax,[edx+0x3000+0x10]
    cmp   [eax],byte 1
    je    rand_window_pixel

    popa
    jmp   sciloop

  rand_window_pixel:

    popa

  rect_shaped:

    shl   ecx,5
    add   ecx,0x3000
    movzx ecx,byte [ecx+0xe]   ; screen id of process

    ret

  scic3:

    mov   ecx,1          ; os pixel
    ret




calculatescreen:

;  eax  x start
;  ebx  y start
;  ecx  x end
;  edx  y end

     pusha
     push eax

   csp1:

     push ecx
     push edx
     push eax
     push ebx

     call checkscreenpixel

     mov  eax,[0xfe00]
     inc  eax
     imul eax,dword [esp+0]
     add  eax,[esp+4]
     mov  [eax+0x400000],cl

     pop  ebx
     pop  eax
     pop  edx
     pop  ecx

     inc  eax
     cmp  eax,ecx
     jbe  csp1
     mov  eax,[esp]
     inc  ebx
     cmp  ebx,edx
     jbe  csp1

     pop  eax
     popa
     ret


setscreen:

;  eax  x start
;  ebx  y start
;  ecx  x end
;  edx  y end

     pusha

     push esi
     push eax

   csp11:

     push eax
     push ebx
     push ecx
     push edx

     mov  esi,eax
     mov  eax,[0xfe00]
     inc  eax
     mul  ebx
     add  eax,esi
     add  eax,0x400000

     mov  cl,[esp+20]
     mov  [eax],cl

     pop  edx
     pop  ecx
     pop  ebx
     pop  eax
     inc  eax
     cmp  eax,ecx
     jbe  csp11
     mov  eax,[esp]
     inc  ebx
     cmp  ebx,edx
     jbe  csp11
     add  esp,8

     popa
     ret


align 4

sys_sb16:

     cmp  word [sb16],word 0
     jnz  sb16l1
     mov  [esp+36],dword 1
     ret
   sb16l1:
     mov  [esp+36],dword 0
     cmp  eax,1    ; set volume - main
     jnz  sb16l2
     mov  dx,word [sb16]
     add  dx,4
     mov  al,0x22
     out  dx,al
     mov  esi,1
     call delay_ms
     mov  eax,ebx
     inc  edx
     out  dx,al
     ret
   sb16l2:

     cmp  eax,2    ; set volume - cd
     jnz  sb16l3
     mov  dx,word [sb16]
     add  dx,4
     mov  al,0x28
     out  dx,al
     mov  esi,1
     call delay_ms
     mov  eax,ebx
     add  edx,1
     out  dx,al
     ret
   sb16l3:
      mov  [esp+36],dword 2
      ret


align 4

sys_sb16II:

     cmp  word [sb16],word 0
     jnz  IIsb16l1
     mov  [esp+36],dword 1
     ret
   IIsb16l1:

     cmp  eax,1    ; set volume - main
     jnz  IIsb16l2
     ; L
     mov  dx,word [sb16]
     add  dx,4
     mov  al,0x30
     out  dx,al
     mov  eax,ebx
     inc  edx
     out  dx,al
     ; R
     mov  dx,word [sb16]
     add  dx,4
     mov  al,0x31
     out  dx,al
     mov  eax,ebx
     inc  edx
     out  dx,al
     mov  [esp+36],dword 0
     ret
   IIsb16l2:

     cmp  eax,2    ; set volume - cd
     jnz  IIsb16l3
     ; L
     mov  dx,word [sb16]
     add  dx,4
     mov  al,0x36
     out  dx,al
     mov  eax,ebx
     inc  edx
     out  dx,al
     ; R
     mov  dx,word [sb16]
     add  dx,4
     mov  al,0x37
     out  dx,al
     mov  eax,ebx
     inc  edx
     out  dx,al
     mov  [esp+36],dword 0
     ret
   IIsb16l3:

     mov  [esp+36],dword 2
     ret


align 4

sys_wss:

     cmp  word [wss],word 0
     jnz  wssl1
     mov  [esp+36],dword 1
     ret
   wssl1:

     cmp  eax,1    ; set volume - main
     jnz  wssl2
     mov  [esp+36],dword 0
     ret
   wssl2:

     cmp  eax,2    ; set volume - cd
     jnz  wssl3
     ; L
     mov  dx,word [wss]
     add  dx,4
     mov  al,0x2
     out  dx,al
     mov  esi,1
     call delay_ms
     mov  eax,ebx
     inc  edx
     out  dx,al
     ; R
     mov  dx,word [wss]
     add  dx,4
     mov  al,0x3
     out  dx,al
     mov  esi,1
     call delay_ms
     mov  eax,ebx
     inc  edx
     out  dx,al
     mov  [esp+36],dword 0
     ret
   wssl3:
     mov   [esp+36],dword 2
     ret

display_number:

; eax = print type, al=0 -> ebx is number
;                   al=1 -> ebx is pointer
;                   ah=0 -> display decimal
;                   ah=1 -> display hexadecimal
;                   ah=2 -> display binary
;                   eax bits 16-21 = number of digits to display (0-32)
;                   eax bits 22-31 = reserved
;
; ebx = number or pointer
; ecx = x shl 16 + y
; edx = color

     cmp   eax,0xffff            ; length > 0 ?
     jge   cont_displ
     ret
   cont_displ:

     cmp   eax,60*0x10000        ; length <= 60 ?
     jbe   cont_displ2
     ret
   cont_displ2:

     pusha

     cmp   al,1                  ; ecx is a pointer ?
     jne   displnl1
     mov   edi,[0x3010]
     mov   edi,[edi+0x10]
     mov   ebx,[edi+ebx]
   displnl1:
     sub   esp,64

     cmp   ah,0                  ; DESIMAL
     jne   no_display_desnum
     shr   eax,16
     and   eax,0x2f
     push  eax
     ;mov   edi,[0x3010]
     ;mov   edi,[edi+0x10]
     mov   edi,esp
     add   edi,4+64
     mov   ecx,eax
     mov   eax,ebx
     mov   ebx,10
   d_desnum:
     xor   edx,edx
     div   ebx
     add   dl,48
     mov   [edi],dl
     dec   edi
     loop  d_desnum
     pop   eax
     call  draw_num_text
     add   esp,64
     popa
     ret
   no_display_desnum:

     cmp   ah,0x01               ; HEXADECIMAL
     jne   no_display_hexnum
     shr   eax,16
     and   eax,0x2f
     push  eax
     ;mov   edi,[0x3010]
     ;mov   edi,[edi+0x10]
     mov   edi,esp
     add   edi,4+64
     mov   ecx,eax
     mov   eax,ebx
     mov   ebx,16
   d_hexnum:
     xor   edx,edx
     div   ebx
     add   edx,hexletters
     mov   dl,[edx]
     mov   [edi],dl
     dec   edi
     loop  d_hexnum
     pop   eax
     call  draw_num_text
     add   esp,64
     popa
     ret
   no_display_hexnum:

     cmp   ah,0x02               ; BINARY
     jne   no_display_binnum
     shr   eax,16
     and   eax,0x2f
     push  eax
     ;mov   edi,[0x3010]
     ;mov   edi,[edi+0x10]
     mov   edi,esp
     add   edi,4+64
     mov   ecx,eax
     mov   eax,ebx
     mov   ebx,2
   d_binnum:
     xor   edx,edx
     div   ebx
     add   dl,48
     mov   [edi],dl
     dec   edi
     loop  d_binnum
     pop   eax
     call  draw_num_text
     add   esp,64
     popa
     ret
   no_display_binnum:

     add   esp,64
     popa
     ret


draw_num_text:

     ; dtext
     ;
     ; eax x & y
     ; ebx color
     ; ecx start of text
     ; edx length
     ; edi 1 force

     mov   edx,eax
     mov   ecx,65
     sub   ecx,eax
     add   ecx,esp
     add   ecx,4
     mov   eax,[esp+64+32-8+4]
     mov   ebx,[esp+64+32-12+4]
     push  edx                       ; add window start x & y
     push  ebx
     mov   edx,[0x3010]
     mov   ebx,[edx-twdw]
     shl   ebx,16
     add   ebx,[edx-twdw+4]
     add   eax,ebx
     pop   ebx
     pop   edx
     mov   edi,0
     call  dtext

     ret

display_settings:

;    eax = 0         ; DISPLAY redraw
;          ebx = 0   ; all
;
;    eax = 1         ; BUTTON type
;          ebx = 0   ; flat
;          ebx = 1   ; 3D
;    eax = 2         ; set WINDOW colours
;          ebx = pointer to table
;          ecx = number of bytes define
;    eax = 3         ; get WINDOW colours
;          ebx = pointer to table
;          ecx = number of bytes wanted
;    eax = 4         ; get skin height
;          input  : nothing
;          output : eax = skin height in pixel


     pusha

     cmp  eax,0       ; redraw display
     jne  dspl0
     cmp  ebx,0
     jne  dspl0
     cmp  [windowtypechanged],dword 1
     jne  dspl00
     mov  [windowtypechanged],dword 0
     mov  [dlx],dword 0
     mov  [dly],dword 0
     mov  eax,[0xfe00]
     mov  [dlxe],eax
     mov  eax,[0xfe04]
     mov  [dlye],eax
     mov  eax,window_data
     call redrawscreen
   dspl00:
     popa
     ret
   dspl0:

     cmp  eax,1       ; button type
     jne  dspl1
     and  ebx,1
     cmp  ebx,[buttontype]
     je   dspl9
     mov  [buttontype],ebx
     mov  [windowtypechanged],dword 1
    dspl9:
     popa
     ret
   dspl1:

     cmp  eax,2       ; set common window colours
     jne  no_com_colours
     mov  [windowtypechanged],dword 1
     mov  esi,[0x3010]
     add  esi,0x10
     add  ebx,[esi]
     mov  esi,ebx
     mov  edi,common_colours
     and  ecx,127
     cld
     rep  movsb
     popa
     ret
   no_com_colours:

     cmp  eax,3       ; get common window colours
     jne  no_get_com
     mov  esi,[0x3010]
     add  esi,0x10
     add  ebx,[esi]
     mov  edi,ebx
     mov  esi,common_colours
     and  ecx,127
     cld
     rep  movsb
     popa
     ret
   no_get_com:

     cmp  eax,4       ; get skin height
     jne  no_skin_height
     popa
     mov  eax,[_skinh]
     mov  [esp+36],eax
     ret
   no_skin_height:

     popa
     ret


common_colours:

     times 128 db 0x0


read_string:

    ; eax  read_area
    ; ebx  color of letter
    ; ecx  color of background
    ; edx  number of letters to read
    ; esi  [x start]*65536 + [y_start]

    ret


align 4

sys_setup:

; 1=roland mpu midi base , base io address
; 2=keyboard   1, base kaybap 2, shift keymap, 9 country 1eng 2fi 3ger 4rus
; 3=cd base    1, pri.master 2, pri slave 3 sec master, 4 sec slave
; 4=sb16 base , base io address
; 5=system language, 1eng 2fi 3ger 4rus
; 6=wss base , base io address
; 7=hd base    1, pri.master 2, pri slave 3 sec master, 4 sec slave
; 8=fat32 partition in hd
; 9
; 10 = sound dma channel
; 11 = enable lba read
; 12 = enable pci access


     mov  [esp+36],dword 0
     cmp  eax,1                      ; MIDI
     jnz  nsyse1
     cmp  ebx,0x100
     jb   nsyse1
     mov  edx,65535
     cmp  edx,ebx
     jb   nsyse1
     mov  word [mididp],bx
     inc  bx
     mov  word [midisp],bx
     ret
   nsyse1:

     cmp  eax,2                      ; KEYBOARD
     jnz  nsyse2
     cmp  ebx,1
     jnz  kbnobase
     mov  edi,[0x3010]
     add  ecx,[edi+0x10]
     mov  eax,ecx
     mov  ebx,keymap
     mov  ecx,128
     call memmove
     ret
   kbnobase:
     cmp  ebx,2
     jnz  kbnoshift
     mov  edi,[0x3010]
     add  ecx,[edi+0x10]
     mov  eax,ecx
     mov  ebx,keymap_shift
     mov  ecx,128
     call memmove
     ret
   kbnoshift:
     cmp  ebx,3
     jne  kbnoalt
     mov  edi,[0x3010]
     add  ecx,[edi+0x10]
     mov  eax,ecx
     mov  ebx,keymap_alt
     mov  ecx,128
     call memmove
     ret
   kbnoalt:
     cmp  ebx,9
     jnz  kbnocountry
     mov  word [keyboard],cx
     ret
   kbnocountry:
     mov  [esp+36],dword 1
     ret
   nsyse2:

     cmp  eax,3                      ; CD
     jnz  nsyse3
     cmp  ebx,1
     jnz  noprma
     mov  [cdbase],0x1f0
     mov  [cdid],0xa0
   noprma:
     cmp  ebx,2
     jnz  noprsl
     mov  [cdbase],0x1f0
     mov  [cdid],0xb0
   noprsl:
     cmp  ebx,3
     jnz  nosema
     mov  [cdbase],0x170
     mov  [cdid],0xa0
   nosema:
     cmp  ebx,4
     jnz  nosesl
     mov  [cdbase],0x170
     mov  [cdid],0xb0
   nosesl:
     ret
   nsyse3:

     cmp  eax,4                      ; SB
     jnz  nsyse4
     cmp  ebx,0x100
     jb   nsyse4
     mov  edx,65535
     cmp  edx,ebx
     jb   nsyse4
     mov  word [sb16],bx
     ret
   nsyse4:

     cmp  eax,5                      ; SYSTEM LANGUAGE
     jnz  nsyse5
     mov  [syslang],ebx
     ret
   nsyse5:

     cmp  eax,6                      ; WSS
     jnz  nsyse6
     cmp  ebx,0x100
     jb   nsyse6
     mov  [wss],ebx
     ret
   nsyse6:

     cmp  eax,7                      ; HD BASE
     jne  nsyse7
     cmp  ebx,1
     jnz  noprmahd
     mov  [hdbase],0x1f0
     mov  [hdid],0x0
     mov  [hdpos],1
     call set_FAT32_variables
   noprmahd:
     cmp  ebx,2
     jnz  noprslhd
     mov  [hdbase],0x1f0
     mov  [hdid],0x10
     mov  [hdpos],2
     call set_FAT32_variables
   noprslhd:
     cmp  ebx,3
     jnz  nosemahd
     mov  [hdbase],0x170
     mov  [hdid],0x0
     mov  [hdpos],3
     call set_FAT32_variables
   nosemahd:
     cmp  ebx,4
     jnz  noseslhd
     mov  [hdbase],0x170
     mov  [hdid],0x10
     mov  [hdpos],4
     call set_FAT32_variables
   noseslhd:
     ret
   nsyse7:

     cmp  eax,8                      ; HD PARTITION
     jne  nsyse8
     mov  [fat32part],ebx
     call set_FAT32_variables
     ret
   nsyse8:

     cmp  eax,10                     ; SOUND DMA CHANNEL
     jne  no_set_sound_dma
     mov  [sound_dma],ebx
     ret
   no_set_sound_dma:

     cmp  eax,11                     ; ENABLE LBA READ
     jne  no_set_lba_read
     and  ebx,1
     mov  [lba_read_enabled],ebx
     ret
   no_set_lba_read:

     cmp  eax,12                     ; ENABLE PCI ACCESS
     jne  no_set_pci_access
     and  ebx,1
     mov  [pci_access_enabled],ebx
     ret
   no_set_pci_access:

     mov  [esp+36],dword -1
     ret


align 4

sys_getsetup:

; 1=roland mpu midi base , base io address
; 2=keyboard   1, base kaybap 2, shift keymap, 9 country 1eng 2fi 3ger 4rus
; 3=cd base    1, pri.master 2, pri slave 3 sec master, 4 sec slave
; 4=sb16 base , base io address
; 5=system language, 1eng 2fi 3ger 4rus
; 6=wss base
; 7=hd base    1, pri.master 2, pri slave 3 sec master, 4 sec slave
; 8=fat32 partition in hd
; 9=get hs timer tic

     cmp  eax,1
     jne  ngsyse1
     mov  [esp+36],dword 0
     ret
   ngsyse1:

     cmp  eax,2
     jne  ngsyse2
     cmp  ebx,1
     jnz  kbnobaseret
     mov  edi,[0x3010]
     add  ecx,[edi+0x10]
     mov  ebx,ecx
     mov  eax,keymap
     mov  ecx,128
     call memmove
     ret
   kbnobaseret:
     cmp  ebx,2
     jnz  kbnoshiftret
     mov  edi,[0x3010]
     add  ecx,[edi+0x10]
     mov  ebx,ecx
     mov  eax,keymap_shift
     mov  ecx,128
     call memmove
     ret
   kbnoshiftret:
     cmp  ebx,3
     jne  kbnoaltret
     mov  edi,[0x3010]
     add  ecx,[edi+0x10]
     mov  ebx,ecx
     mov  eax,keymap_alt
     mov  ecx,128
     call memmove
     ret
   kbnoaltret:
     cmp  ebx,9
     jnz  ngsyse2
     movzx eax,word [keyboard]
     mov  [esp+36],eax
     ret
   ngsyse2:

     cmp  eax,3
     jnz  ngsyse3
     mov  [esp+36],dword 0
     ret
   ngsyse3:

     cmp  eax,4
     jne  ngsyse4
     mov  [esp+36],dword 0
     ret
   ngsyse4:

     cmp  eax,5
     jnz  ngsyse5
     mov  eax,[syslang]
     mov  [esp+36],eax
     ret
   ngsyse5:

     cmp  eax,9
     jne  ngsyse9
     mov  eax,[0xfdf0]
     mov  edi,[0x3000]
     imul edi,256
     add  edi,0x80000
     cmp  [edi],dword 0x4B415551
     je   ftl1
     cmp  [edi+3],dword 0x4B415551
     je   ftl1
     jmp  ftl2
   ftl1:
     imul eax , 2
   ftl2:
     mov  [esp+36],eax
     ret
   ngsyse9:

     mov  [esp+36],dword 1
     ret

scroll_step  equ 32
scroll_base  equ 0xDA0000
scroll_max   equ 2000

scroll_top:  dd  0x0

scrolling: dd 0x0

align 4

check_scrolls:

    mov   [scrolling],byte 0

  chcsl9:

    cmp   [0xfb40],byte 0
    je    chcsl1

    mov   esi , [0x3004]
    shl   esi , 1
    add   esi , 0xc400
    movzx esi , word [esi]

    mov   ebp , 0
    mov   edi , scroll_base

    mov   [esisave],esi

  check_scroll_list:

    ; Process slot

    mov   esi , [esisave]

    mov   [edisave],edi

    cmp   [edi+20],esi
    jne   new_scroll_check ; chcsl1

    shl   esi , 5
    add   esi , window_data

    ; 0xfb40 - buttons
    ; 0xfb0a - word x
    ; 0xfb0c - word y

    ; X

 ;   mov   eax , [edi+0]
 ;   and   eax , 0xffff
 ;   add   eax , [esi+0]

    mov   eax , [esi+0]
    cmp   [edi+2],byte 2
    jne   chscrl12
    mov   eax , [esi+4]
  chscrl12:
    add   eax , [edi+0]
    and   eax , 0xffff
    mov   ebx , eax
    add   ebx , 13
    movzx ecx , word [0xfb0a]
    cmp   [edi+2],byte 2
    jne   chscrl1
    movzx ecx , word [0xfb0c]
  chscrl1:
    cmp   [scrolling],byte 1
    je    chcsl95
    cmp   ecx , eax
    jb    new_scroll_check ; chcsl1
    cmp   ecx , ebx
    ja    new_scroll_check ; chcsl1
  chcsl95:

    ; Y

 ;   mov   eax , [edi+4+2]
 ;   and   eax , 0xffff
 ;   add   eax , [esi+4]

    mov   eax , [esi+4]
    cmp   [edi+2],byte 2
    jne   chscrl14
    mov   eax , [esi+0]
  chscrl14:
    add   eax , [edi+4+2]
    and   eax , 0xffff

    mov   ebx , [edi+4]
    and   ebx , 0xffff
    add   ebx , eax
    movzx ecx , word [0xfb0c]
    cmp   [edi+2],byte 2
    jne   chscrl2
    movzx ecx , word [0xfb0a]
  chscrl2:
    cmp   [scrolling],byte 1
    je    chcsl96
    cmp   ecx , eax
    jb    new_scroll_check ; chcsl1
    cmp   ecx , ebx
    ja    new_scroll_check ; chcsl1
  chcsl96:

    jmp   scrfoundl1

    esisave: dd 0x0
    edisave: dd 0x0

  new_scroll_check:

    add   edi , scroll_step

    inc   ebp
    cmp   ebp , [scroll_top]
    jbe   check_scroll_list

    jmp   chcsl1 ; no scrolls found

  scrfoundl1:

  more_scroll:

    mov   edi , [edisave]

    mov   esi , [esisave]
    shl   esi , 5
    add   esi , window_data

;    mov   eax , [edi+4+2]
;    and   eax , 0xffff
;    add   eax , [esi+4]
;    mov   ebx , [edi+4]
;    and   ebx , 0xffff
;    add   ebx , eax

    mov   eax , [esi+4]
    cmp   [edi+2],byte 2
    jne   chscrl142
    mov   eax , [esi+0]
  chscrl142:
    add   eax , [edi+4+2]
    and   eax , 0xffff

    mov   ebx , [edi+4]
    and   ebx , 0xffff
    add   ebx , eax

    movzx ecx , word [0xfb0c]
    cmp   [edi+2],byte 2
    jne   chscrl22
    movzx ecx , word [0xfb0a]
  chscrl22:

    mov   esi , [esisave]

    mov   ebp , edi

    ;;;;;

    add   eax , 15
    sub   ebx , 15

    cmp   [scrolling],byte 1
    je    chcsl97

    ; Top button

    cmp   ecx , eax
    ja    chcsl32
    mov   eax , [ebp+16]
    dec   eax
    jmp   chcsl3
  chcsl32:

    ; Low button

    cmp   ecx , ebx
    jb    chcsl33
    mov   eax , [ebp+16]
    inc   eax
    jmp   chcsl3
  chcsl33:

  chcsl97:

    ; Read glider 

    movzx ecx , word [0xfb0c]
    cmp   [edi+2],byte 2
    jne   chscrl3
    movzx ecx , word [0xfb0a]
  chscrl3:

    cmp   ecx , eax     ; Below lowest point
    jae   scroll_fine_1
    mov   eax , ecx
    jmp   scrolljmp
  scroll_fine_1:
    push  eax
    mov   eax , [edi+24]
    shr   eax , 1
    sub   ecx , eax  ; glider size / 2
    pop   eax
  scrolljmp:

    cmp   ecx , eax     ; Below lowest point
    jae   scroll_fine_11
    mov   eax , ecx
  scroll_fine_11:

    sub   ecx , eax
    mov   eax , ecx

    mov   edi , [ebp+4]
    and   edi , 0xffff
    sub   edi , 15+15                 ; Heads
    sub   edi , [ebp+24]              ; Glider size
                                      ; edi = Glide area from:to

    imul  eax , [ebp+12]
    xor   edx , edx
    cmp   edi , 0
    jne   noediz
    mov   edi , 1
  noediz:
    div   edi
    add   eax , [ebp+8]

    push  ebx  ; Above highest point
    mov   ebx , [ebp+8]
    add   ebx , [ebp+12]
    dec   ebx
    cmp   eax , ebx
    jbe   scroll_fine_2
    mov   eax , ebx
  scroll_fine_2:
    pop   ebx

    cmp   eax , [ebp+16]
    je    chcsl4
    mov   [0xf500],byte 1
    mov   [0xf501],eax
  chcsl4:

    mov   eax , 1
    call  delay_hs
    call  osloop_without_gui_response

    mov   [scrolling],byte 1

    cmp   [0xfb40],byte 0
    jne   more_scroll ; chcsl9

    mov   [scrolling],byte 0

    jmp   chcsl1

  chcsl3:

    mov   [0xf500],byte 1
    mov   [0xf501],eax

  chcsl2:
    mov   eax , 1
    call  delay_hs
    call  osloop_without_gui_response
    cmp   [0xfb40],byte 0
    jne   chcsl2

  chcsl1:

    ret

remove_scrolls:

; In : edx = Process slot

    pusha

    mov   edi , scroll_base
    mov   ebp , scroll_max
  remscrl1:
    cmp  [edi+20],edx
    jne   remscrl2
    mov  [edi+20],dword 0
  remscrl2:

    add   edi , scroll_step
    dec   ebp
    jnz   remscrl1

    popa

    ret


check_scroll_table:

; Out : free address or current address

    push  ecx ebp

    mov   edi , scroll_base
    mov   ecx , [0x3000]
    mov   ebp , [scroll_top]
    cmp   ebp , 0
    je    cstl21
  cstl1:
    cmp  [edi+0],eax
    jne  cstl2
    cmp  [edi+4],ebx
    jne  cstl2
    cmp  [edi+20],ecx
    jne  cstl2

    ; Scroll position found

    pop  ebp ecx
    ret
  cstl2:
    add   edi , scroll_step
    dec   ebp
    jnz   cstl1

  cstl21:

    ; Not found or list empty

    ; Find empty slot

    mov   edi , scroll_base
    mov   ecx , [0x3000]
    mov   ebp , 0
  cstl51:
    cmp  [edi+20],dword 0
    jne  cstl52

    ; Empty slot found - check scroll_top

    inc   ebp
    cmp   ebp , [scroll_top]
    jbe   cstl53
    mov   [scroll_top], ebp
  cstl53:

    pop   ebp ecx
    ret
  cstl52:
    add   edi , scroll_step
    inc   ebp
    cmp   ebp , scroll_max
    jb    cstl51

    pop  ebp ecx

    ; No empty slots

    sub   edi , scroll_step

    ret


align 4

sys_scroll:

;        mov   eax , 113
;  eax   mov   ebx , 001 shl 16 + 260
;  ebx   mov   ecx , 060 shl 16 + 180
;  ecx   mov   edx , 1000
;  edx   mov   esi , 200
;  esi   mov   edi , [scroll_value]

    call check_scroll_table ; edi = free address or current address

    cmp  edx , 1
    jge  noscrollsizesml
    mov  edx , 1
  noscrollsizesml:

    ; Value within limits

    cmp  esi , ecx
    jae  scrl1
    mov  esi , ecx
  scrl1:
    push ecx
    add  ecx , edx
    dec  ecx
    cmp  esi , ecx
    jbe  scrl2
    mov  esi , ecx
  scrl2:
    pop  ecx

    ; Save values

    mov  [edi+0],eax
    mov  [edi+4],ebx
    mov  [edi+8],ecx
    mov  [edi+12],edx
    mov  [edi+16],esi
    push  eax
    mov   eax , [0x3000]
    mov  [edi+20],eax      ; Process slot - If Zero = slot no used
    pop   eax
          
    pusha
    and   ebx , 0xffff
    sub   ebx , 15+15
    mov   eax , ebx
    mov   ebx , edx
    xor   edx , edx
    div   ebx
    cmp   eax , 23
    jge   scsizefine
    mov   eax , 23
  scsizefine:
    mov  [edi+24],eax ; Scroll size
    popa

    mov   ebp , eax
    shr   ebp , 16  ; save for vertical / horizontal draw

    ; Transparent head 1

    pusha
    push  ebp
    mov   esi , scroll_grey_table
    mov   ebp , 15
    pop   edi
    call  scroll_transparent
    popa

    ; Transparent head 2

    pusha
    push  ebp
    mov   ecx , ebx
    shl   ecx , 16
    add   ebx , ecx
    mov   ecx , 15 shl 16
    sub   ebx , ecx
    mov   esi , scroll_grey_table
    mov   ebp , 15
    pop   edi
    call  scroll_transparent
    popa

    ; Draw glider

    mov   ebp , ebx ; Save for background

    add   ebx , 15 * 65536

    ;  ecx   mov   edx , 1000
    ;  edx   mov   esi , 200
    ;  esi   mov   edi , [scroll_value]

    push  eax ecx edx edi

    mov   eax , edi
    mov   edi , ebx
    and   edi , 0xffff
    sub   edi , 15+15                 ; Heads
    sub   edi , [eax+24]              ; Glider size
                                      ; edi = Glide area from:to
    sub   esi , ecx
    imul  esi , edi
    mov   eax , esi
    mov   ecx , edx
    cmp   ecx , 1
    je    nodece
    dec   ecx
  nodece:
    mov   edx , 0
    div   ecx

    shl   eax , 16
    add   ebx , eax

    pop   edi edx ecx eax

    ; Gray scroll area 1

    pusha
    push  eax
    mov   ecx , ebx
    mov   ebx , ebp
    shr   ecx , 16
    mov   bx  , cx
;    sub   bx  , 2
    mov   edi , [0x3010]
    mov   ecx , [edi-twdw]
    cmp   [esp+2],byte 2
    jne   nosxys23
    mov   ecx , [edi-twdw+4]
  nosxys23:
    add   ax  , cx
    mov   dx  , ax
    shl   eax , 16
    mov   ax  , dx
;    mov   ecx , ebx
;    shr   ecx , 16
;    add   bx  , cx
;    dec   bx
    add   ebx , 15*65536
;    sub   bx  , 15
    mov   ecx , [edi-twdw+4]
    cmp   [esp+2],byte 2
    jne   nosxys24
    mov   ecx , [edi-twdw+0]
  nosxys24:
    mov   dx  , cx
    shl   ecx , 16
    mov   cx  , dx
    add   ebx , ecx
    mov   edi , 0
    mov   ecx , 0xc0c0c0
    mov   ebp , 13
  sysscrl1:
    pusha
    cmp   [esp+32+2],byte 2
    jne   nosxys2
    xchg  eax , ebx
  nosxys2:
    call  draw_line
    popa
    add   ecx , 0x030303
    add   eax , 0x00010001
    dec   ebp
    jnz   sysscrl1
    pop   eax
    popa


    ; Gray scroll area 2

    pusha
    push  eax
    shr   ebx , 16
    add   ebx , [edi+24]
    shl   ebx , 16
    mov   ecx , [edi+4+2]
    mov   bx  , cx
    mov   ecx , [edi+4]
    add   bx  , cx
    sub   bx  , 15
    sub   ebx , 0x00010001

;    mov   ecx , ebx
;    mov   ebx , ebp
;    shr   ecx , 16
;    mov   bx  , cx

    mov   edi , [0x3010]
    mov   ecx , [edi-twdw]
    cmp   [esp+2],byte 2
    jne   nosxys25
    mov   ecx , [edi-twdw+4]
  nosxys25:
    add   ax  , cx
    mov   dx  , ax
    shl   eax , 16
    mov   ax  , dx
;    mov   ecx , ebx
;    shr   ecx , 16
;    add   bx  , cx
;    dec   bx
;;    add   ebx , 15*65536
;    sub   bx  , 15
    mov   ecx , [edi-twdw+4]
    cmp   [esp+2],byte 2
    jne   nosxys26
    mov   ecx , [edi-twdw+0]
  nosxys26:
    mov   dx  , cx
    shl   ecx , 16
    mov   cx  , dx
    add   ebx , ecx
    mov   edi , 0
    mov   ecx , 0xc0c0c0
    mov   ebp , 13
  sysscrl21:
    pusha
    cmp   [esp+32+2],byte 2
    jne   nosxys3
    xchg  eax , ebx
  nosxys3:
    call  draw_line
    popa
    add   ecx , 0x030303
    add   eax , 0x00010001
    dec   ebp
    jnz   sysscrl21
    pop   eax
    popa



    ; Gray 1

    pusha
    push  eax
    mov   esi , scroll_grey_table
    mov   ebp , 3
    pop   edi
    shr   edi , 16
    call  scroll_transparent
    popa
    add   ebx , 3 * 65536

    ; Blue middle

    pusha
    push  eax
    mov   esi , scroll_color_table
    mov   ebp , [edi+24]
    sub   ebp , 6
    pop   edi
    shr   edi , 16
    call  scroll_transparent
    popa

    push  eax
    mov   eax , [edi+24]
    sub   eax , 6
    shl   eax , 16
    add   ebx , eax
    pop   eax

    ; Gray 2

    pusha
    push  eax
    mov   esi , scroll_grey_table
    mov   ebp , 3
    pop   edi
    shr   edi , 16
    call  scroll_transparent
    popa

    ret


scroll_transparent:

; In : ebp = size - esi = pointer to colour table - edi = vertic/horizont

    pusha
    push  edi

    mov   edi , [0x3010]
    mov   ecx , [edi-twdw]
    cmp   [esp],byte 2
    jne   noscxysw3
    mov   ecx , [edi-twdw+4]
  noscxysw3:
    add   ax  , cx
    mov   dx  , ax
    shl   eax , 16
    mov   ax  , dx

    mov   ecx , ebx
    shr   ecx , 16
    add   ecx , ebp
    dec   ecx
    mov   bx  , cx
    mov   ecx , [edi-twdw+4]
    cmp   [esp],byte 2
    jne   noscxysw2
    mov   ecx , [edi-twdw+0]
  noscxysw2:
    mov   dx  , cx
    shl   ecx , 16
    mov   cx  , dx
    add   ebx , ecx
    mov   ebp , 13
  sysscrl2:
    mov   ecx , [esi]
    and   ecx , 0xffffff
    pusha
    cmp   [esp+32],byte 2
    jne   noscxysw
    xchg  eax,ebx
  noscxysw:
    call  draw_line
    popa
    add   esi , 3
    add   eax , 0x00010001
    dec   ebp
    jnz   sysscrl2

    pop   edi
    popa

    ret


scroll_color_table:

    db   0xA6 ,0xA6 ,0xA6 ,0xB0 ,0x9B ,0x7F ,0xAE ,0x98
    db   0x7D ,0xAB ,0x97 ,0x7B ,0xA6 ,0x94 ,0x78 ,0xA3
    db   0x90 ,0x76 ,0xA0 ,0x8D ,0x73 ,0x9C ,0x8B ,0x71
    db   0x9A ,0x87 ,0x70 ,0x97 ,0x85 ,0x6D ,0x94 ,0x84
    db   0x6B ,0x8F ,0x80 ,0x68 ,0x4F ,0x4F ,0x4F


scroll_grey_table:

    db   0xA1 ,0xA1 ,0xA1 ,0xF1 ,0xF1 ,0xF1 ,0xE6 ,0xE6 
    db   0xE6 ,0xDE ,0xDE ,0xDE ,0xDD ,0xDD ,0xDD ,0xDC 
    db   0xDC ,0xDC ,0xCB ,0xCB ,0xCB ,0xD6 ,0xD6 ,0xD6 
    db   0xDB ,0xDB ,0xDB ,0xE4 ,0xE4 ,0xE4 ,0xEC ,0xEC 
    db   0xEC ,0xE9 ,0xE9 ,0xE9 ,0x9E ,0x9E ,0x9E


;scroll_color_table:
;    db    149  ,087  ,33
;    db    229  ,210  ,156
;    db    218  ,191  ,142
;    db    210  ,176  ,124
;    db    209  ,168  ,111
;    db    208  ,170  ,100
;    db    191  ,120  ,29
;    db    202  ,148  ,36
;    db    207  ,161  ,56
;    db    216  ,173  ,68
;    db    224  ,190  ,83
;    db    221  ,189  ,80
;    db    146  ,085  ,33
;scroll_grey_table:
;    db    159,159,159
;    db    239,239,239
;    db    228,228,228
;    db    220,220,220
;    db    219,219,219
;    db    218,218,218
;    db    201,201,201
;    db    212,212,212
;    db    217,217,217
;    db    226,226,226
;    db    234,234,234
;    db    231,231,231
;    db    156,156,156




align 4

readmousepos:

; eax=0 screen relative
; eax=1 window relative
; eax=2 buttons pressed

    test eax,eax
    jnz  nosr
    mov  eax,[0xfb0a]
    shl  eax,16
    mov  ax,[0xfb0c]
    mov  [esp+36],eax
    ret
  nosr:

    cmp  eax,1
    jnz  nowr
    mov  eax,[0xfb0a]
    shl  eax,16
    mov  ax,[0xfb0c]
    mov  esi,[0x3010]
    sub  esi,twdw
    mov  bx,[esi]
    shl  ebx,16
    mov  bx,[esi+4]
    sub  eax,ebx
    mov  [esp+36],eax
    ret
  nowr:

    cmp   eax,2
    jnz   nomb
    movzx eax,byte [0xfb40]
  nomb:
    mov   [esp+36],eax

    ret


detect_devices:

    ret


sys_end:

     mov   eax,[0x3010]
     add   eax,0xa
     mov   [eax],byte 3  ; terminate this program
    waitterm:            ; wait here for termination
     mov   eax,5
     call  delay_hs
     jmp   waitterm



sys_system:

     cmp  eax,1                              ; BOOT
     jnz  nosystemboot
     mov  eax,[0x3004]
     add  eax,2
     mov  [shutdown_processes],eax
     mov  [0xFF00],al
     mov  eax,0
     ret
   shutdown_processes: dd 0x0
   nosystemboot:

     cmp  eax,2                              ; TERMINATE
     jnz  noprocessterminate
     cmp  ebx,2
     jb   noprocessterminate
     mov  edx,[0x3004]
     cmp  ebx,edx
     jg   noprocessterminate
     mov  eax,[0x3004]
     shl  ebx,5
     mov  edx,[ebx+0x3000+4]
     add  ebx,0x3000+0xa
     mov  [ebx],byte 3       ; clear possible i40's

     cmp  edx,[application_table_status]    ; clear app table stat
     jne  noatsc
     mov  [application_table_status],0
   noatsc:

     ret
   noprocessterminate:

     cmp  eax,3                              ; ACTIVATE WINDOW
     jnz  nowindowactivate
     cmp  ebx,2
     jb   nowindowactivate
     cmp  ebx,[0x3004]
     jg   nowindowactivate
     ; edi = position at window_data+
     mov  edi,ebx
     shl  ebx,1
     add  ebx,0xc000
     mov  esi,[ebx]
     and  esi,0xffff
     movzx edx,word [0x3004]
     cmp  esi,edx
     jz   nowindowactivate
     mov  [0xff01],edi
     mov  eax,0
     ret
   nowindowactivate:

     cmp  eax,4                              ; GET IDLETIME
     jnz  nogetidletime
     mov  eax,[idleusesec]
     ret
   nogetidletime:

     cmp  eax,5                              ; GET TSC/SEC
     jnz  nogettscsec
     mov  eax,[0xf600]
     ret
   nogettscsec:

     ret

sys_cd_audio:

     cmp  word [cdbase],word 0
     jnz  cdcon
     mov  eax,1
     ret
   cdcon:

     ; eax=1 cdplay at ebx 0x00FFSSMM
     ; eax=2 get tracklist size of ecx to [ebx]
     ; eax=3 stop/pause playing

     cmp  eax,1
     jnz  nocdp
     call sys_cdplay
     ret
   nocdp:

     cmp eax,2
     jnz nocdtl
     mov edi,[0x3010]
     add edi,0x10
     add ebx,[edi]
     call sys_cdtracklist
     ret
   nocdtl:

     cmp eax,3
     jnz nocdpause
     call sys_cdpause
     ret
   nocdpause:

     mov eax,0xffffff01
     ret



sys_cd_atapi_command:

     pusha

     mov  dx,word [cdbase]
     add  dx,6
     mov  ax,word [cdid]
     out  dx,al
     mov  esi,10
     call delay_ms
     mov  dx,word [cdbase]
     add  dx,7
     in   al,dx
     and  al,0x80
     cmp  al,0
     jnz  res
     jmp  cdl6
   res:
     mov dx,word [cdbase]
     add dx,7
     mov al,0x8
     out dx,al
     mov dx,word [cdbase]
     add dx,0x206
     mov al,0xe
     out dx,al
     mov  esi,1
     call delay_ms
     mov dx,word [cdbase]
     add dx,0x206
     mov al,0x8
     out dx,al
     mov  esi,30
     call delay_ms
     xor  cx,cx
   cdl5:
     inc  cx
     cmp  cx,10
     jz   cdl6
     mov  dx,word [cdbase]
     add  dx,7
     in   al,dx
     and  al,0x88
     cmp  al,0x00
     jz   cdl5
     mov  esi,100
     call delay_ms
     jmp  cdl5
   cdl6:
     mov dx,word [cdbase]
     add dx,4
     mov al,0
     out dx,al
     mov dx,word [cdbase]
     add dx,5
     mov al,0
     out dx,al
     mov dx,word [cdbase]
     add dx,7
     mov al,0xec
     out dx,al
     mov  esi,5
     call delay_ms
     mov dx,word [cdbase]
     add dx,1
     mov al,0
     out dx,al
     add dx,1
     mov al,0
     out dx,al
     add dx,1
     mov al,0
     out dx,al
     add dx,1
     mov al,0
     out dx,al
     add dx,1
     mov al,128
     out dx,al
     add dx,2
     mov al,0xa0
     out dx,al
     xor  cx,cx
     mov  dx,word [cdbase]
     add  dx,7
   cdl1:
     inc  cx
     cmp  cx,100
     jz   cdl2
     in   al,dx
     and  ax,0x88
     cmp  al,0x8
     jz   cdl2
     mov  esi,2
     call delay_ms
     jmp  cdl1
   cdl2:

     popa
     ret


sys_cdplay:

     mov  ax,5
     push ax
     push ebx
   cdplay:
     call sys_cd_atapi_command
     cli
     mov  dx,word [cdbase]
     mov  ax,0x0047
     out  dx,ax
     mov  al,1
     mov  ah,[esp+0] ; min xx
     out  dx,ax
     mov  ax,[esp+1] ; fr sec
     out  dx,ax
     mov  ax,256+99
     out  dx,ax
     mov  ax,0x0001
     out  dx,ax
     mov  ax,0x0000
     out  dx,ax
     mov  esi,10
     call delay_ms
     sti
     add  dx,7
     in   al,dx
     test al,1
     jz   cdplayok
     mov  ax,[esp+4]
     dec  ax
     mov  [esp+4],ax
     cmp  ax,0
     jz   cdplayfail
     jmp  cdplay
   cdplayfail:
   cdplayok:
     pop  ebx
     pop  ax
     mov  eax,0
     ret


sys_cdtracklist:

     push ebx
   tcdplay:
     call sys_cd_atapi_command
     mov  dx,word [cdbase]
     mov  ax,0x43+2*256
     out  dx,ax
     mov  ax,0x0
     out  dx,ax
     mov  ax,0x0
     out  dx,ax
     mov  ax,0x0
     out  dx,ax
     mov  ax,200
     out  dx,ax
     mov  ax,0x0
     out  dx,ax
     in   al,dx
     mov  cx,1000
     mov  dx,word [cdbase]
     add  dx,7
     cld
   cdtrnwewait:
     mov  esi,10
     call delay_ms
     in   al,dx
     and  al,128
     cmp  al,0
     jz   cdtrl1
     loop cdtrnwewait
   cdtrl1:
     ; read the result
     mov  ecx,[esp+0]
     mov  dx,word [cdbase]
   cdtrread:
     add  dx,7
     in   al,dx
     and  al,8
     cmp  al,8
     jnz  cdtrdone
     sub  dx,7
     in   ax,dx
     mov  [ecx],ax
     add  ecx,2
     jmp  cdtrread
   cdtrdone:
     pop  ecx
     mov  eax,0
     ret


sys_cdpause:

     call sys_cd_atapi_command

     mov  dx,word [cdbase]
     mov  ax,0x004B
     out  dx,ax
     mov  ax,0
     out  dx,ax
     mov  ax,0
     out  dx,ax
     mov  ax,0
     out  dx,ax
     mov  ax,0
     out  dx,ax
     mov  ax,0
     out  dx,ax

     mov  esi,10
     call delay_ms
     add  dx,7
     in   al,dx

     mov  eax,0
     ret


sys_cachetodiskette:
    pusha
    cmp  eax,1
    jne  no_write_all_of_ramdisk
    call fdc_writeramdisk
    popa
    ret
  no_write_all_of_ramdisk:
    cmp eax,2
    jne no_write_part_of_ramdisk
    call fdc_commitflush
    popa
    ret
  no_write_part_of_ramdisk:
    cmp  eax,3
    jne  no_set_fdc
    call fdc_set
    popa
    ret
  no_set_fdc:
    cmp  eax,4
    jne  no_get_fdc
    popa
    call fdc_get
    mov    [esp+36],ecx
    ret
   no_get_fdc:
                                popa
    ret


bgrchanged  dd  0x0

sys_background:

    cmp   eax,1                            ; BACKGROUND SIZE
    jnz   nosb1
    cmp   ebx,0
    je    sbgrr
    cmp   ecx,0
    je    sbgrr
    mov   [0x400000-8],ebx
    mov   [0x400000-4],ecx
    mov   [bgrchanged],1
  sbgrr:
    ret
  nosb1:

    cmp   eax,2                            ; SET PIXEL
    jnz   nosb2
    mov   edx,0x100000-16
    cmp   edx,ebx
    jbe   nosb2
    mov   edx,[ebx]
    and   edx,255*256*256*256
    and   ecx,255*256*256+255*256+255
    add   edx,ecx
    mov   [ebx+0x300000],edx
    mov   [bgrchanged],1
    ret
  nosb2:

    cmp   eax,3                            ; DRAW BACKGROUND
    jnz   nosb3
    cmp   [bgrchanged],0
    je    nosb31
    mov   [bgrchanged],0
    mov   [0xfff0],byte 1
   nosb31:
    ret
  nosb3:

    cmp   eax,4                            ; TILED / STRETCHED
    jnz   nosb4
    cmp   ebx,[0x400000-12]
    je    nosb41
    mov   [0x400000-12],ebx
    mov   [bgrchanged],1
   nosb41:
    ret
  nosb4:

    cmp   eax,5                            ; BLOCK MOVE TO BGR
    jnz   nosb5
    mov   edi,[0x3010]
    add   ebx,[edi+0x10]
    mov   esi,ebx
    mov   edi,ecx
    add   ecx,edx
    cmp   ecx,0x100000-16
    jbe   nsb52
    ret
   nsb52:
    add   edi,0x300000
    mov   ecx,edx
    cmp   ecx,0x100000-16
    jbe   nsb51
    ret
   nsb51:
    mov   [bgrchanged],1
    cld
    rep   movsb
    ret
  nosb5:

    ret


align 4

sys_getbackground:

    cmp   eax,1                                  ; SIZE
    jnz   nogb1
    mov   eax,[0x400000-8]
    shl   eax,16
    mov   ax,[0x400000-4]
    mov   [esp+36],eax
    ret
  nogb1:

    cmp   eax,2                                  ; PIXEL
    jnz   nogb2
    mov   edx,0x100000-16
    cmp   edx,ebx
    jbe   nogb2
    mov   eax,[ebx+0x300000]
    and   eax,255*256*256+255*256+255
    mov   [esp+36],eax
    ret
  nogb2:

    cmp   eax,4                                  ; TILED / STRETCHED
    jnz   nogb4
    mov   eax,[0x400000-12]
  nogb4:
    mov   [esp+36],eax
    ret


align 4

sys_getkey:

    movzx ebx,word [0x3000]                      ; TOP OF WINDOW STACK
    shl   ebx,1
    mov   [esp+36],dword 1
    add   ebx,0xc000
    movzx ecx,word [ebx]
    mov   edx,[0x3004]
    cmp   ecx,edx
    je    sysgkl1
    ret
  sysgkl1:
    cmp   [0xf400],byte 0
    jne   gkc1
    ret
  gkc1:
    movzx eax,byte [0xf401]
    shl   eax,8
    dec   byte [0xf400]
    and   byte [0xf400],127
    movzx ecx,byte [0xf400]
    add   ecx,2
    mov   esi,0xf402
    mov   edi,0xf401
    cld
    rep   movsb

    mov   [esp+36],eax
    ret


align 4

sys_getbutton:

    movzx ebx,word [0x3000]                      ; TOP OF WINDOW STACK
    mov   [esp+36],dword 1
    shl   ebx,1
    add   ebx,0xc000
    movzx ecx,word[ebx]
    movzx edx,word[0x3004]
    cmp   ecx,edx
    je    gbot
    ret
  gbot:
    movzx eax,byte [0xf500]
    test  eax,eax
    jnz   gbc1
    ret
  gbc1:
    mov   eax,[0xf501]
    shl   eax,8
    mov   [0xf500],byte 0
    mov   [esp+36],eax
    ret


align 4

sys_cpuusage:

;  RETURN:
;
;  +00 dword     process cpu usage
;  +04  word     position in windowing stack
;  +06  word     windowing stack value at current position (cpu nro)
;  +10 12 bytes  name
;  +22 dword     start in mem
;  +26 dword     used mem
;  +30 dword     PID , process idenfification number
;

    mov  edi,[0x3010]   ; eax = return area
    add  edi,0x10
    add  eax,[edi]

    cmp  ebx,-1         ; who am I ?
    jne  no_who_am_i
    mov  ebx,[0x3000]
  no_who_am_i:

    push eax            ; return area
    push ebx            ; process number

    push ebx
    push ebx
    push eax

    ; return memory usage

    xor  edx,edx
    mov  eax,0x20
    mul  ebx
    add  eax,0x3000+0x1c
    mov  ebx,eax
    pop  eax
    mov  ecx,[ebx]
    mov  [eax],ecx
    mov  ebx,[esp]
    shl  ebx,1
    add  ebx,0xc000
    mov  cx,[ebx]
    mov  [eax+4],cx
    mov  ebx,[esp]
    shl  ebx,1
    add  ebx,0xc400
    mov  cx,[ebx]
    mov  [eax+6],cx
    pop  ebx
    push eax
    mov  eax,ebx
    shl  eax,8
    add  eax,0x80000
    pop  ebx
    add  ebx,10
    mov  ecx,11
    call memmove

    ; memory usage

    xor    eax,eax
    mov    edx,0x100000*16-4096
    pop    ecx                                   ; get gdt of tss
    cmp    ecx,1
    je     os_mem
    ;shl    ecx,8
    ;add    ecx,0x80000+0x88
    ;mov    ecx,[ecx]
    shl    ecx,3
    ; eax run base -> edx used memory
    mov    al,[ecx+gdts+ app_code-3 +4]            ;  base  23:16
    mov    ah,[ecx+gdts+ app_code-3 +7]            ;  base  31:24
    shl    eax,16
    mov    ax,[ecx+gdts+ app_code-3 +2]            ;  base  0:15
    movzx  edx,word [ecx+gdts+ app_code-3 +0]
    shl    edx,12
  os_mem:
    add    edx,4096 - 1 ; include 4 kb selector page size
    mov    [ebx+12],eax
    mov    [ebx+16],edx

    ; PID (+30)

    mov    eax,[esp]
    shl    eax,5
    add    eax,0x3000+0x4
    mov    eax,[eax]
    mov    [ebx+20],eax

    ; window position and size

    mov    esi,[esp]
    shl    esi,5
    add    esi,window_data
    mov    edi,[esp+4]
    add    edi,34
    mov    ecx,4*4
    cld
    rep    movsb

    ; Process state (+50)

    mov    eax,[esp]
    shl    eax,5
    add    eax,0x3000+0xa
    mov    eax,[eax]
    mov    [ebx+40],ax


    pop    ebx
    pop    eax

    ; return number of processes

    mov    eax,[0x3004]
    mov    [esp+36],eax
    ret

checkimage:

        push  eax
        push  ebx
        push  ecx
        push  edx
        xor   edx,edx
        xor   ecx,ecx
        mov   cx,[0x3000]
        shl   ecx,1
        add   ecx,0xc000
        mov   dx,[ecx]
        mov   ax,[0x3004]
        cmp   dx,ax
        jz    imok
        jmp   imcheckinside
      imok:                  ; first in stack
        pop   edx
        pop   ecx
        pop   ebx
        pop   eax

        mov   ecx,0
        ret

      imcheckinside:

        mov   esi,edx        ; window of image -position in windowing stack
        pop   edx
        pop   ecx
        pop   ebx
        pop   eax
        call  cilimit
        ret

cilimit:

        push eax
        push ebx
        xor  eax,eax
        xor  ebx,ebx
        mov  al,[0xe000]
        cmp  eax,1
        jz   cilc
        pop  ebx
        pop  eax
        mov  ecx,0
        ret
      cilc:
        push  ecx
        push  edx
        mov   edi,[0x3010]
        mov   ecx,draw_data-0x3000
        add   edi,ecx
        mov   eax,[esp+12]
        mov   ebx,[esp+8]
        mov   ecx,[esp+04]
        mov   edx,[esp+00]
        mov   ecx,[edi+12]
        cmp   edx,ecx
        jbe   cici1
        jmp   cicino
      cici1:
        mov   ecx,[edi+4]
        cmp   ecx,ebx
        jbe   cici2
        jmp   cicino
      cici2:
        mov   eax,[esp+12]
        mov   ebx,[esp+8]
        mov   ecx,[esp+04]
        mov   edx,[esp+00]
        mov   edx,[edi+8]
        cmp   ecx,edx
        jbe   cici3
        jmp   cicino
      cici3:
        mov   edx,[edi+0]
        cmp   edx,eax
        jbe   cici4
        jmp   cicino
      cici4:
        pop   edx
        pop   ecx
        pop   ebx
        pop   eax
        mov   ecx,0     ;inside of draw limits
        ret
      cicino:
        pop   edx
        pop   ecx
        pop   ebx
        pop   eax
        mov   ecx,1     ;outside of draw limits
        ret


dececx:

    push eax
    push edx
    push ecx

    mov  edx,1

  dececl:

    movzx eax,byte [esp+edx]
    cmp   eax,0x20
    jge   deccl1
    mov   [esp+edx],byte 0x20
   deccl1:
    sub   [esp+edx],byte 0x20

    add  edx,1
    cmp  edx,4
    jbe  dececl

    pop  ecx
    pop  edx
    pop  eax
    ret

drawbuttonframes2:

        push  esi
        push  edi
        push  eax
        push  ebx
        push  ecx
        push  edx

        shr   eax,16
        shr   ebx,16
        mov   edx,[0x3010]

        add   eax,[edx-twdw]
        add   ebx,[edx-twdw+4]
        mov   cx,ax
        mov   dx,bx
        shl   eax,16
        shl   ebx,16
        mov   ax,cx
        mov   bx,dx
        add   ax,word [esp+12]
        mov   esi,ebx
        mov   edi,0
        mov   ecx,[esp+0]
        add   ecx,0x202020 + 0x080808
        call  draw_line

        movzx edx,word [esp+8]
        add   ebx,edx
        shl   edx,16
        add   ebx,edx
        mov   ecx,[esp+0]
;        call  dececx
        sub   ecx,0x202020 + 0x080808
        call  draw_line

        mov   ebx,esi
        push  edx
        mov   edx,eax
        shr   edx,16
        mov   ax,dx
        mov   edx,ebx
        shr   edx,16
        mov   bx,dx
        mov   dx,[esp+8+4]
        add   bx,dx
        pop   edx
        mov   edi,0
        mov   ecx,[esp+0]
        add   ecx,0x202020 + 0x080808
        call  draw_line

        mov   esi,edx
        mov   dx,[esp+12]
        add   ax,dx
        shl   edx,16
        add   eax,edx
        add   ebx,1*65536
        mov   edx,esi
        mov   ecx,[esp+0]
        sub   ecx,0x202020 + 0x080808

;        call  dececx
        call  draw_line

        pop   edx
        pop   ecx
        pop   ebx
        pop   eax
        pop   edi
        pop   esi

        ret


drawbuttonframes:

        push  esi
        push  edi
        push  eax
        push  ebx
        push  ecx
        push  edx

        shr   eax,16
        shr   ebx,16
        mov   edx,[0x3010]

        add   eax,[edx-twdw]
        add   ebx,[edx-twdw+4]
        mov   cx,ax
        mov   dx,bx
        shl   eax,16
        shl   ebx,16
        mov   ax,cx
        mov   bx,dx
        add   ax,word [esp+12]
        mov   esi,ebx
        mov   edi,0
        mov   ecx,[esp+0]
        add   ecx,0x202020
        call  draw_line

        movzx edx,word [esp+8]
        add   ebx,edx
        shl   edx,16
        add   ebx,edx
        mov   ecx,[esp+0]
        call  dececx
        call  draw_line

        mov   ebx,esi
        push  edx
        mov   edx,eax
        shr   edx,16
        mov   ax,dx
        mov   edx,ebx
        shr   edx,16
        mov   bx,dx
        mov   dx,[esp+8+4]
        add   bx,dx
        pop   edx
        mov   edi,0
        mov   ecx,[esp+0]
        add   ecx,0x202020
        call  draw_line

        mov   esi,edx
        mov   dx,[esp+12]
        add   ax,dx
        shl   edx,16
        add   eax,edx
        add   ebx,1*65536
        mov   edx,esi
        mov   ecx,[esp+0]
        call  dececx
        call  draw_line

        pop   edx
        pop   ecx
        pop   ebx
        pop   eax
        pop   edi
        pop   esi

        ret

button_dececx:

        cmp   [buttontype],dword 1
        je    bdece
        ret
      bdece:
        push  eax
        mov   eax,0x01
        cmp   edi,20
        jg    bdl9
        mov   eax,0x02
      bdl9:
        test  ecx,0xff
        jz    bdl1
        sub   ecx,eax
      bdl1:
        shl   eax,8
        test  ecx,0xff00
        jz    bdl2
        sub   ecx,eax
      bdl2:
        shl   eax,8
        test  ecx,0xff0000
        jz    bdl3
        sub   ecx,eax
      bdl3:
        pop    eax
        ret


sys_button:

        push  ebx        ; No buttons to grab bar, if window type 2,3,..
        mov   edi,[0x3000]
        shl   edi,5
        add   edi,window_data
        mov   edi , [edi+16+3]
        and   edi , 15
        cmp   edi , 0
        je    sysbl123
        cmp   edi , 1
        je    sysbl123
        cmp   ax , 20
        ja    sysbl123
        cmp   bx , 20
        ja    sysbl123
        shr   ebx , 16   
        cmp   ebx , 10
        ja    sysbl123
        pop   ebx
        ret
      sysbl123:
        pop   ebx

        test  ecx,0x80000000
        jnz   remove_button

        ; 0 -> def color 0
        ; 1 -> def color 1
        ; 2 -> use own from application

        mov   ebp , edx
        and   ebp , 0xf0000000
        cmp   ebp , 0x00000000
        jne   no_def_but_1
        and   edx , 0xff000000
        add   edx , [defbuttoncolor]   
      no_def_but_1:
        cmp   ebp , 0x10000000
        jne   no_def_but_2
        and   edx , 0xff000000
        add   edx , [defbuttoncolor2]  
      no_def_but_2:

        push  ebp

        push  esi
        push  edi
        push  eax
        push  ebx
        push  ecx
        push  edx

        test  ecx,0x40000000
        jnz   button_no_draw

        pusha                       ; button body
        push  ebx
        shr   eax,16
        shr   ebx,16
        mov   edx,[0x3010]
        mov   esi,[edx-twdw]
        mov   edi,[edx-twdw+4]
        add   eax,esi
        add   ebx,edi
        mov   cx,ax
        mov   dx,bx
        shl   eax,16
        shl   ebx,16
        mov   ax,cx
        mov   bx,dx
        movzx ecx,word [4+32+esp+12]
        add   eax,ecx
        mov   ecx,[4+32+esp+0]
        cmp   [buttontype],dword 0
        je    bdecel1
        add   ecx,0x141414
       bdecel1:
        movzx edi,word [esp]
       bnewline:
        call  button_dececx
        push  edi
        mov   edi,0
        call  draw_line
        pop   edi
        add   ebx,1*65536+1
        dec   word [esp]
        mov   dx,[esp]
        cmp   dx,0
        jnz   bnewline
        pop   ebx
        popa

        call  drawbuttonframes2

      button_no_draw:

        and   ecx,0xffff

        mov   edi,[0x3010]
        sub   edi,twdw

        mov   edi,[0xfe88]
        movzx eax,word [edi]
        cmp   eax,1000
        jge   noaddbutt
        inc   eax
        mov   [edi],ax

        shl   eax,4
        add   eax,edi

        mov   bx,[0x3000]
        mov   [eax],bx

        add   eax,2         ; save button id number
        mov   ebx,[esp+4]
        mov   [eax],bx      ; bits 0-15
        shr   ebx,16
        mov   [eax-2+0xc],bx; bits 16-31
        add   eax,2         ; x start
        mov   bx,[esp+12+2]
        mov   [eax],bx
        add   eax,2         ; x size
        mov   bx,[esp+12+0]
        mov   [eax],bx
        add   eax,2         ; y start
        mov   bx,[esp+8+2]
        mov   [eax],bx
        add   eax,2         ; y size
        mov   bx,[esp+8+0]
        mov   [eax],bx

     noaddbutt:

        pop   edx
        pop   ecx
        pop   ebx
        pop   eax
        pop   edi
        pop   esi

        ; Draw button text

        pop   ebp
        cmp   ebp , 0x10000000
        jne   no_def_but_21

        cmp   esi , 0
        je    no_def_but_21

        mov   ecx,eax
        and   ecx,0xffff
        shr   ecx,1
        shr   eax,16
        add   eax,ecx
        add   eax,2
        mov   ecx,ebx
        and   ecx,0xffff
        shr   ecx,1
        shr   ebx,16
        add   ebx,ecx
        sub   ebx,3
        mov   edx,[0x3010]
        add   eax,[edx-twdw]
        add   ebx,[edx-twdw+4]
        shl   eax,16
        mov   ax,bx

        ; eax x & y
        ; ebx font ( 0xX0000000 ) & color ( 0x00RRGGBB )
        ; ecx start of text
        ; edx length
        ; edi 1 force

        mov   ebx , 0x00000000
        mov   ecx , esi
        mov   edi , [0x3010]
        add   ecx , [edi+0x10]
        call  return_string_length
        mov   edi , edx
        imul  edi , 3
        shl   edi , 16
        sub   eax , edi
        mov   edi , 0
        call  dtext

      no_def_but_21:

        ret


remove_button:

    and  ecx,0x7fffffff

  rnewba2:

    mov   edi,[0xfe88]
    mov   eax,edi
    movzx ebx,word [edi]
    inc   bx

  rnewba:

    dec   bx
    jz    rnmba

    add   eax,0x10

    mov   dx,[0x3000]
    cmp   dx,[eax]
    jnz   rnewba

    cmp   cx,[eax+2]
    jnz   rnewba

    pusha
    mov   ecx,ebx
    inc   ecx
    shl   ecx,4
    mov   ebx,eax
    add   eax,0x10
    call  memmove
    dec   dword [edi]
    popa

    jmp   rnewba2

  rnmba:

    ret


align 4

sys_clock:

        cli
        xor   al,al           ; seconds
        out   0x70,al
        in    al,0x71
        movzx ecx,al
        mov   al,02           ; minutes
        shl   ecx,16
        out   0x70,al
        in    al,0x71
        movzx edx,al
        mov   al,04           ; hours
        shl   edx,8
        out   0x70,al
        in    al,0x71
        add   ecx,edx
        movzx edx,al
        add   ecx,edx
        sti
        mov   [esp+36],ecx
        ret


align 4

sys_date:

        cli
        mov     al,6            ; day of week
        out     0x70,al
        in      al,0x71
        mov     ch,al
        mov     al,7            ; date
        out     0x70,al
        in      al,0x71
        mov     cl,al
        mov     al,8            ; month
        shl     ecx,16
        out     0x70,al
        in      al,0x71
        mov     ch,al
        mov     al,9            ; year
        out     0x70,al
        in      al,0x71
        mov     cl,al
        sti
        mov     [esp+36],ecx
        ret


; redraw status

sys_redrawstat:

    cmp  eax,1
    jne  no_widgets_away

    ; buttons away

    mov   ecx,[0x3000]

  sys_newba2:

    mov   edi,[0xfe88]
    cmp   [edi],dword 0  ; empty button list ?
    je    end_of_buttons_away

    movzx ebx,word [edi]
    inc   ebx

    mov   eax,edi

  sys_newba:

    dec   ebx
    jz    end_of_buttons_away

    add   eax,0x10
    cmp   cx,[eax]
    jnz   sys_newba

    pusha
    mov   ecx,ebx
    inc   ecx
    shl   ecx,4
    mov   ebx,eax
    add   eax,0x10
    call  memmove
    dec   dword [edi]
    popa

    jmp   sys_newba2

  end_of_buttons_away:

    ret

  no_widgets_away:

    cmp   eax,2
    jnz   srl1

    mov   edx,[0x3010]      ; return whole screen draw area for this app
    add   edx,draw_data-0x3000
    mov   [edx+0],dword 0
    mov   [edx+4],dword 0
    mov   eax,[0xfe00]
    mov   [edx+8],eax
    mov   eax,[0xfe04]
    mov   [edx+12],eax

    mov   edi,[0x3010]
    sub   edi,twdw
    mov   [edi+30],byte 1   ; no new position & buttons from app

    call  sys_window_mouse

    ret

  srl1:

    ret


sys_drawwindow:

    mov   edi,ecx
    shr   edi,16+8
    and   edi,15

    cmp   edi,0   ; type I    - original style
    jne   nosyswI
    call  sys_set_window
    call  drawwindow_I
    ret
  nosyswI:

    cmp   edi,1   ; type II   - only reserve area, no draw
    jne   nosyswII
    call  sys_set_window
    call  sys_window_mouse
    ret
  nosyswII:

    cmp   edi,2   ; type III  - new style
    jne   nosyswIII
    push  ebx
    mov   ebx,[0x3000]
    imul  ebx,256
    add   ebx,0x80000
    cmp   [ebx],dword 'FASM'
    jne   nocbgr
    mov   ebx , ecx
    and   ebx , 0xffffff
    cmp   ebx , 0x2030a0
    jne   nocbgr
    mov   cl , 0x80
  nocbgr:
    pop   ebx
    call  sys_set_window
    call  drawwindow_IV
    ; call  drawwindow_III
    ret
  nosyswIII:

    cmp   edi,3   ; type IV - skinned window
    jne   nosyswIV
    cmp   bx , 520
    jne   no520y
    mov   bx , 506
  no520y:
    call  sys_set_window
    call  drawwindow_IV
    ret
  nosyswIV:

    cmp   edi,4   ; type V - skinned, menu window
    jne   nosyswV
    cmp   esi , 0 ; No menu
    je    no_menu_defined
    pusha
    call  sys_set_window
    call  drawwindow_V
    popa
    call  drawwindow_menu
    ret
  nosyswV:

    ret

no_menu_defined:

    pusha
    call  sys_set_window
    call  drawwindow_IV
    popa

    cmp   edx , 0
    je    no_window_label_draw_2
    pusha
    mov   edi , [0x3010]
    mov   ecx , edx
    add   ecx , [edi+0x10]
    call  return_string_length
    mov   ebx , edx
    imul  ebx , 8 / 2
    mov   eax , [edi-twdw+8]
    shr   eax , 1
    sub   eax , ebx
    and   eax , 0xffff
    add   eax , [edi-twdw]
    shl   eax , 16
    add   eax , [edi-twdw+4]
    add   eax , 8
    mov   ebx , 0x10ffffff
    mov   edi , 0
    call  dtext
    popa
  no_window_label_draw_2:

    ret


drawwindow_menu:

    ; Draw Window Label

    cmp   edx , 0
    je    no_window_label_draw
    pusha
    mov   edi , [0x3010]
    mov   ecx , edx
    add   ecx , [edi+0x10]
    call  return_string_length
    mov   ebx , edx
    imul  ebx , 8 / 2
    mov   eax , [edi-twdw+8]
    shr   eax , 1
    sub   eax , ebx
    and   eax , 0xffff
    add   eax , [edi-twdw]
    shl   eax , 16
    add   eax , [edi-twdw+4]
    add   eax , 8
    mov   ebx , 0x10ffffff
    mov   edi , 0
    call  dtext
    popa
  no_window_label_draw:

    ; Draw Menu

    cmp   esi , 0
    je    no_window_menu_draw

    mov   edi,[0x3010]

    mov   eax,[edi-twdw]
    add   eax,10
    shl   eax,16
    add   eax,[edi-twdw+4]
    add   eax,27 -1

    ; eax x & y
    ; ebx font ( 0xX0000000 ) & color ( 0x00RRGGBB )
    ; ecx start of text
    ; edx length
    ; edi 1 force

    mov   ebx , 0x00000000
    mov   ecx , esi
    add   ecx , [edi+0x10]
    add   ecx , 8*2

    mov   ebp , 0 ; If window on top, menu Xpos counter.

    cmp   [ecx],byte 0
    jne   dwml1

  dwml2:

    inc   ecx

    call  return_string_length

    ;
          
    push  eax ecx edx ebp
    mov   edi , 0
    call  dtext
    pop   ebp edx ecx eax

    add   ecx , edx
    imul  edx , 6
    add   edx , 15
    shl   edx , 16
    add   eax , edx

  dwml3:

    inc   ecx
    cmp   [ecx],word 0+255*256
    je    dwml1
    cmp   [ecx],word 0+0*256
    jne   dwml3
    inc   ecx
    jmp   dwml2

  no_window_menu_draw:

  dwml1:

    ret

return_string_length: ; asciiz

; In : ecx = first letter : Out : edx = length

    push  ecx
    mov   edx , 0
  rsll1:
    inc   edx
    inc   ecx
    cmp   [ecx-1], byte 0
    jne   rsll1
    dec   edx
    pop   ecx

    ret


get_menu_coordinates:

; In : [menu_slot]

    pusha

    mov   [menu_id],dword 0

    ; Clear coordinates

    mov   edi , menu_positions
    mov   ecx , 60
    mov   eax , 0xffffff
    cld
    rep   stosd

    ; Get menu abs address

    mov   edi , [menu_slot]
    shl   edi , 5
    mov   ecx , [edi+window_data+0x18]   ; Menu address
    add   ecx , [edi+0x3000+0x10]        ; App address
    add   ecx , 8*2

    mov   edi , [menu_slot]
    shl   edi , 5
    add   edi , window_data
    mov   eax , [edi]
    add   eax , 10  ; start X

    mov   ebp , 0   ; X-pos counter.

    cmp   [ecx],byte 0
    jne   gdwml1

  gdwml2:

    inc   ecx

    inc   dword [menu_id]

    call  return_string_length

    ; Save menu positions

    mov   [menu_positions+ebp*4],eax
    push  ecx edi
    mov   edi , [menu_slot]
    shl   edi , 5
    sub   ecx , [edi+0x3000+0x10]        
    add   ecx , edx
    inc   ecx
    mov   [menu_positions_text+ebp*4],ecx
    pop   edi ecx
    push  ecx
    mov   ecx , [menu_id]
    mov   [menu_positions_id+ebp*4],ecx
    pop   ecx
    inc   dword [menu_id]

    add   ebp , 1
    and   ebp , 0x1f

    add   ecx , edx
    imul  edx , 6
    add   edx , 15
    add   eax , edx

  gdwml3:

    inc   ecx

    cmp   [ecx],word 0+1*256
    jne   gdwml11
    inc   dword [menu_id]
  gdwml11:
    cmp   [ecx],word 0+255*256
    je    gdwml1
    cmp   [ecx],word 0+0*256
    jne   gdwml3

    inc   ecx

    jmp   gdwml2

  gdwml1:

    popa

    ret

menu_id: dd 0x0

menu_open: dd 0x0

check_menus_again:

    call  draw_menu_background

    call  check_no_selections

    jmp   chmel00


check_menus:

    mov   [menu_open],byte 0

    ; 0xfb40 - buttons

    cmp   [0xfb40],byte 0
    je    chmel1

  chmel00:

    mov   edi , [0x3004] ; Get topmost window
    shl   edi , 1
    add   edi , 0xc400 ; 0xc000
    movzx edi , word [edi]

    mov   [menu_slot], edi

    shl   edi , 5
    add   edi , window_data

    mov   eax , [edi+0x10] ; Type 4 ?
    and   eax , 0x0f000000
    cmp   eax , 0x04000000
    jne   chmel1

  ;   mov   eax , 100
  ;   call  delay_hs

    mov   eax , [edi+0x18] ; Menu defined ?
    cmp   eax , 0x0
    je    chmel1

    ; 0xfb40 - buttons
    ; 0xfb0a - word x
    ; 0xfb0c - word y

    movzx ecx , word [0xfb0a]
    movzx edx , word [0xfb0c]

    mov   eax , [edi+0x0]
    mov   ebx , [edi+0x4]
    add   eax , 5
    add   ebx , 20

    mov   [menu_start_y],ebx
    add   dword [menu_start_y],18

    cmp   ecx , eax
    jb    chmel1
    cmp   edx , ebx
    jb    chmel1

    add   eax , [edi+0x8]
    cmp   ecx , eax
    jg    chmel1

    add   ebx , 18
    cmp   edx , ebx
    jg    chmel1

 ;   mov   eax , 100
 ;   call  delay_hs

    ; Get menu X coordinates

    call  get_menu_coordinates

    ; Which menu ?

    mov   esi , menu_positions-4
    mov   ebx , ecx
    add   ebx , 6
    mov   ebp , 0

  chmel2:

    add   esi , 4
    inc   ebp

    cmp   esi , menu_positions+60*4
    ja    chmel1
    cmp   [esi], dword 0xffff
    ja    chmel1

    cmp   ebx , [esi+0]
    ja    chmel6
    jmp   chmel2
  chmel6:
    cmp   ebx , [esi+4]
    jb    chmel61
    jmp   chmel2
  chmel61:
    mov   eax , [esi+0]
    add   eax , 14 * 6
    cmp   ebx , eax
    jb    chmel62
    jmp   chmel2
  chmel62:

    mov   [selected_1_menu],ebp

    push  ebp
    dec   ebp
    mov   eax , [menu_positions_id+ebp*4]
    mov   [selected_menu],eax
    pop   ebp

    mov   eax , [esi+0]
    sub   eax , 3
    mov   [menu_start_x],eax

    ; Get image & Draw menu
    ; Get image - D20000  -> DF0000   Menu under image ( 3 * 200 * 200 )

    mov   [menu_open],byte 1

    mov   ecx , [menu_slot]
    shl   ecx , 5
    mov   ecx , [ecx+0x3000+0x10]        ; App address
    mov   ebp , [selected_1_menu]
    dec   ebp
    add   ecx , [menu_positions_text+ebp*4]
    mov   [display_sub_menu],ecx

    ;

    mov   ebx , [menu_start_y]

  chmel70:

    mov   [menu_lines],dword 14

    ; Last menu ?

    push  ecx edx
    mov   [lastmenu],byte 0
    mov   ecx , [display_sub_menu]
    inc   ecx
    call  return_string_length ; [ecx] -> edx
    add   ecx , edx
    add   ecx , 1
    cmp   [ecx], byte 1
    je    chmel72
    mov   [lastmenu],byte 1
    mov   [menu_lines],dword 18
  chmel72:
    pop   edx ecx

    ;

    mov   eax , [menu_start_x]
    mov   edi , 1

    ;  Set window ID's for menu ( 0 ? )
    ;  eax  x start
    ;  ebx  y start
    ;  ecx  x end
    ;  edx  y end
    ;  esi

    pusha
    mov   ecx , eax
    mov   edx , ebx
    add   ecx , 139
    add   edx , [menu_lines]
    dec   edx
    mov   esi , 0
    call  setscreen
    call  disable_mouse
    popa

  chmel7:

    push  eax ebx ecx edi
    ; in:
    ; eax = x coordinate
    ; ebx = y coordinate
    ; ret:
    ; ecx = 00 RR GG BB
    call  getpixel
    mov   eax , [esp+12]
    mov   ebx , [esp+8]
    sub   eax , [menu_start_y]
    sub   ebx , [menu_start_y]
    imul  ebx , 140
    add   eax , ebx
    imul  eax , 3
    add   eax , 0xD20000
    mov   [eax],ecx
    pop   edi ecx ebx eax

    push  eax ebx ecx edi
    ; eax = x coordinate
    ; ebx = y coordinate
    ; ecx = ?? RR GG BB    ; 0x01000000 negation
    ; edi = 0x00000001 force
    mov   ecx , 0xffffff
    cmp   [lastmenu],dword 1
    jne   nomenuedge3
    cmp   [menu_lines], dword 1
    jne   nomenuedge3
    mov   ecx , 0x000000
  nomenuedge3:
    cmp   eax , [menu_start_x]
    jne   nomenuedge
    mov   ecx , 0x000000
  nomenuedge:
    mov   edx , [menu_start_x]
    add   edx , 139
    cmp   eax , edx
    jne   nomenuedge2
    mov   ecx , 0x000000
  nomenuedge2:
    call  putpixel
    pop   edi ecx ebx eax

    inc   eax
    mov   edx , [menu_start_x]
    add   edx , 140
    cmp   eax , edx
    jb    chmel7
    mov   eax , [menu_start_x]

    inc   ebx

    dec   dword [menu_lines]
    jnz   chmel7

    ; Draw text

    ; dtext
    ;
    ; eax x & y
    ; ebx color
    ; ecx start of text
    ; edx length
    ; edi 1 force

    mov   [menu_reatched_y],ebx

    push  ebx
    mov   eax , [menu_start_x]
    add   eax , 10
    shl   eax , 16
    add   eax , ebx
    sub   eax , 10
    cmp   [lastmenu],byte 1
    jne   nolm
    sub   eax , 4
  nolm:
    mov   ebx , 0x000000
    mov   edi , 1
    mov   ecx , [display_sub_menu]
    inc   ecx
    call  return_string_length ; [ecx] -> edx
    cmp   [ecx],byte '-'
    jne   dtextmenu
    ; draw a line
    ; eax = x1 x2
    ; ebx = y1 y2
    ; ecx = color
    ; edi = force ?
    ; Draw line
    push  eax ebx ecx edi
    add   eax , 4
    mov   ebx , eax
    shl   ebx , 16
    mov   bx , ax
    mov   ecx , eax
    shr   ecx , 16
    add   ecx , 116
    mov   ax , cx
    mov   ecx , 0x000000
    mov   edi , 1
    call  draw_line
    pop   edi ecx ebx eax
    jmp   nodtextmenu
  dtextmenu:
    call  dtext
  nodtextmenu:
    pop   ebx

    add   ecx , edx
    add   ecx , 1
    mov   [display_sub_menu],ecx

    cmp   [ecx], byte 1
    je    chmel70
                  
    ; Get entry & check events ( networking, .. )

       ; 0xfb40 - buttons
       ; 0xfb0a - word x
       ; 0xfb0c - word y

    ; Wait for mouse up

  chmel91:
    call  osloop_without_gui_response
    mov   eax , 1
    call  delay_hs
    cmp   [0xfb40],byte 0
    jne   chmel91

    ; Wait for mouse down

  chmel92:
    call  osloop_without_gui_response
    mov   eax , 1
    call  delay_hs
    cmp   [0xfb40],byte 0
    je    chmel92

    ; Inside drop menu ?

  ;  mov   eax , 100
  ;  call  delay_hs

    movzx eax , word [0xfb0a]
    cmp   eax , [menu_start_x]
    jb    check_menus_again
    mov   ebx , [menu_start_x]
    add   ebx , 140
    cmp   eax , ebx
    ja    check_menus_again
    movzx ebx , word [0xfb0c]
    cmp   ebx , [menu_start_y]
    jb    check_menus_again
    cmp   ebx , [menu_reatched_y]
    ja    check_menus_again

    ;

    movzx eax , word [0xfb0c]
    sub   eax , [menu_start_y]
    mov   ebx , 14
    xor   edx , edx
    div   ebx
    inc   eax
    add   [selected_menu],eax

    ; Wait for mouse up

  chmel93:
    call  osloop_without_gui_response
    mov   eax , 1
    call  delay_hs
    cmp   [0xfb40],byte 0
    jne   chmel93

    ; Draw menu background

    call  draw_menu_background

    ; Set button

    mov   edi , [menu_slot]
    shl   edi , 5
    add   edi , window_data
    mov   eax , [edi+0x18] ; Menu address
    mov   edi , [menu_slot]
    shl   edi , 5
    add   edi , 0x3000
    add   eax , [edi+0x10] ; App address
    mov   ebx , [eax+8]
    mov   [0xf500], byte 1 ; F500 byte - number of button presses in buffer
    add   ebx , [selected_menu]
    mov   [0xf501], ebx

    mov   [menu_open],byte 0

    ret

  chmel1:

    call  check_no_selections

    mov   [menu_open],byte 0

    ret


check_no_selections:

    cmp   [menu_open],byte 1
    jne   no_menu_closed

    ; User made no selections

    mov   edi , [menu_slot]
    shl   edi , 5
    add   edi , window_data
    mov   eax , [edi+0x18] ; Menu address
    mov   edi , [menu_slot]
    shl   edi , 5
    add   edi , 0x3000
    add   eax , [edi+0x10] ; App address
    mov   ebx , [eax+8]
    mov   [0xf500], byte 1
    mov   [0xf501], ebx

  no_menu_closed:

    ret


draw_menu_background:

    ; Draw background image

    call  disable_mouse

    mov   eax , [menu_start_x]
    mov   ebx , [menu_start_y]
    mov   ecx , 0xff0000
    mov   edi , 1

  chmel75:

    push  eax ebx
    sub   eax , [menu_start_y]
    sub   ebx , [menu_start_y]
    imul  ebx , 140*3
    imul  eax , 3
    add   eax , ebx
    add   eax , 0xD20000
    mov   ecx , [eax]
    and   ecx , 0xffffff
    pop   ebx eax

    ; Draw pixel

    push  eax ebx ecx edi
    ; eax = x coordinate
    ; ebx = y coordinate
    ; ecx = ?? RR GG BB    ; 0x01000000 negation
    ; edi = 0x00000001 force
    call  putpixel
    pop   edi ecx ebx eax

    inc   eax
    mov   edx , [menu_start_x]
    add   edx , 140
    cmp   eax , edx
    jb    chmel75
    mov   eax , [menu_start_x]

    inc   ebx
    cmp   ebx , [menu_reatched_y]
    jb    chmel75
                  
    ; Calculate window ID's

    ;  eax  x start
    ;  ebx  y start
    ;  ecx  x end
    ;  edx  y end

    mov   eax , [menu_start_x]
    mov   ebx , [menu_start_y]
    mov   ecx , eax
    add   ecx , 140
    mov   edx , [menu_reatched_y]
    inc   edx
    call  calculatescreen

    ret


menu_slot:           dd  0x0
menu_add:            dd  0x0
menu_positions:      times 64 dd 0x0
menu_positions_text: times 64 dd 0x0
menu_positions_id:   times 64 dd 0x0

menu_start_x:        dd  0x0
menu_start_y:        dd  0x0

menu_lines:          dd  0x0

menuselection:       db  'Menu 1         '

menu_reatched_y:     dd  0x0

selected_1_menu:     dd  0x0

display_sub_menu:    dd  0x0

lastmenu:            dd  0x0

selected_menu:       dd  0x0

sys_set_window:

    mov   edi,[0x3000]
    shl   edi,5
    add   edi,window_data

    mov   [edi+16],ecx
    mov   [edi+20],edx
    mov   [edi+24],esi

    cmp   [edi+30],byte 1
    jz    newd

    push  eax
    mov   eax,[0xfdf0]
    add   eax,100
    mov   [new_window_starting],eax
    pop   eax

    mov   [edi+8],ax
    mov   [edi+12],bx
    shr   eax,16
    shr   ebx,16
    mov   [edi+00],ax
    mov   [edi+04],bx
    
    call  check_window_position

    pusha                   ; save for window fullscreen/resize
    mov   esi,edi
    sub   edi,window_data
    shr   edi,5
    shl   edi,8
    add   edi,0x80000+0x90
    mov   ecx,4
    cld
    rep   movsd
    popa

    pusha

    mov   eax,1
    call  delay_hs
    movzx eax,word [edi+00]
    movzx ebx,word [edi+04]
    movzx ecx,word [edi+8]
    movzx edx,word [edi+12]
    add   cx,ax
    add   dx,bx

    call  calculatescreen

    mov   [0xf400],byte 0           ; empty keyboard buffer
    mov   [0xf500],byte 0           ; empty button buffer

    popa

  newd:
    mov   [edi+31],byte 0   ; no redraw
    mov   edx,edi

    ret


sys_window_move:

        cmp  [window_move_pr],0
        je   mwrl1
                
        mov  [esp+36],dword 1         ; return queue error

        ret

     mwrl1:

        mov   edi,[0x3000]            ; requestor process base
        mov   [window_move_pr],edi

        mov   [window_move_eax],eax
        mov   [window_move_ebx],ebx
        mov   [window_move_ecx],ecx
        mov   [window_move_edx],edx

        mov   [esp+36],dword 0        ; return success

        ret



window_move_pr   dd  0x0
window_move_eax  dd  0x0
window_move_ebx  dd  0x0
window_move_ecx  dd  0x0
window_move_edx  dd  0x0


check_window_move_request:

        pusha

        mov   edi,[window_move_pr]    ; requestor process base

        cmp   edi,0
        je    window_move_return

        shl   edi,5
        add   edi,window_data

        push  dword [edi+0]           ; save old coordinates
        push  dword [edi+4]
        push  dword [edi+8]
        push  dword [edi+12]

        mov   eax,[window_move_eax]
        mov   ebx,[window_move_ebx]
        mov   ecx,[window_move_ecx]
        mov   edx,[window_move_edx]

        cmp   eax,-1                  ; set new position and size
        je    no_x_reposition
        mov   [edi+0],eax
      no_x_reposition:
        cmp   ebx,-1
        je    no_y_reposition
        mov   [edi+4],ebx
      no_y_reposition:
        cmp   ecx,-1
        je    no_x_resizing
        mov   [edi+8],ecx
      no_x_resizing:
        cmp   edx,-1
        je    no_y_resizing
        mov   [edi+12],edx
      no_y_resizing:

        call  check_window_position

        pusha                       ; save for window fullscreen/resize
        mov   esi,edi
        sub   edi,window_data
        shr   edi,5
        shl   edi,8
        add   edi,0x80000+0x90
        mov   ecx,4
        cld
        rep   movsd
        popa

        pusha                       ; calculcate screen at new position
        mov   eax,[edi+00]
        mov   ebx,[edi+04]
        mov   ecx,[edi+8]
        mov   edx,[edi+12]
        add   ecx,eax
        add   edx,ebx
        call  calculatescreen
        popa

        pop   edx                   ; calculcate screen at old position
        pop   ecx
        pop   ebx
        pop   eax
        add   ecx,eax
        add   edx,ebx
        mov   [dlx],eax             ; save for drawlimits
        mov   [dly],ebx
        mov   [dlxe],ecx
        mov   [dlye],edx
        call  calculatescreen

        mov   [edi+31],byte 1       ; flag the process as redraw

        mov   eax,edi               ; redraw screen at old position
        call  redrawscreen

        mov   [0xfff5],byte 0 ; mouse pointer
        mov   [0xfff4],byte 0 ; no mouse under
        mov   [0xfb44],byte 0 ; react to mouse up/down

        mov   ecx,10          ; wait 1/10 second
      wmrl3:
        call  check_mouse_data
        call  draw_pointer
        mov   eax,1
        call  delay_hs
        loop  wmrl3

        mov   [window_move_pr],0

      window_move_return:

        popa

        ret



check_window_position:

    pusha                           ; window inside screen ?

    movzx eax,word [edi+0]
    movzx ebx,word [edi+4]
    movzx ecx,word [edi+8]
    movzx edx,word [edi+12]

    mov   esi,ecx             ; check x pos
    add   esi,eax
    cmp   esi,[0xfe00]
    jbe   x_pos_ok
    mov   [edi+0],dword 0
    mov   eax,0
  x_pos_ok:

    mov   esi,edx             ; check y pos
    add   esi,ebx
    cmp   esi,[0xfe04]
    jbe   y_pos_ok
    mov   [edi+4],dword 0
    mov   ebx,0
  y_pos_ok:

    mov   esi,ecx             ; check x size
    add   esi,eax
    cmp   esi,[0xfe00]
    jbe   x_size_ok
    mov   ecx,[0xfe00]
    mov   [edi+8],ecx
  x_size_ok:

    mov   esi,edx             ; check y size
    add   esi,ebx
    cmp   esi,[0xfe04]
    jbe   y_size_ok
    mov   edx,[0xfe04]
    mov   [edi+12],edx
  y_size_ok:

    popa

    ret


new_window_starting dd 0

sys_window_mouse:

    push  eax

    mov   eax,[0xfdf0]
    cmp   [new_window_starting],eax
    jb    swml1

    mov   [0xfff4],byte 0  ; no mouse background
    mov   [0xfff5],byte 0  ; draw mouse

    mov   [new_window_starting],eax

  swml1:

    pop   eax

    ret

drawwindow_I:

        pusha

        mov   esi,[edx+24]   ; rectangle
        mov   eax,[edx+0]
        shl   eax,16
        add   eax,[edx+0]
        add   eax,[edx+8]
        mov   ebx,[edx+04]
        shl   ebx,16
        add   ebx,[edx+4]
        add   ebx,[edx+12]
        call  draw_rectangle

        mov   ecx,[edx+20]   ; grab bar
        push  ecx
        mov   esi,edx
        mov   edx,[esi+04]
        add   edx,1
        mov   ebx,[esi+04]
        add   ebx,25
        mov   eax,[esi+04]
        add   eax,[esi+12]
        cmp   ebx,eax
        jb    wdsizeok
        mov   ebx,eax
      wdsizeok:
        push  ebx
      drwi:
        mov   ebx,edx
        shl   ebx,16
        add   ebx,edx
        mov   eax,[esi+00]
        inc   eax
        shl   eax,16
        add   eax,[esi+00]
        add   eax,[esi+8]
        sub   eax,1
        push  edx
        mov   edx,0x80000000
        mov   ecx,[esi+20]
        and   ecx,edx
        cmp   ecx,edx
        jnz   nofa
        mov   ecx,[esi+20]
        sub   ecx,0x00040404
        mov   [esi+20],ecx
        and   ecx,0x00ffffff
        jmp   faj
      nofa:
        mov   ecx,[esi+20]
        and   ecx,0x00ffffff
      faj:
        pop   edx
        mov   edi,0
        call  draw_line
        inc   edx
        cmp   edx,[esp]
        jb    drwi
        add   esp,4
        pop   ecx
        mov   [esi+20],ecx

        mov   edx,[esi+04]      ; inside work area
        add   edx,21+5
        mov   ebx,[esi+04]
        add   ebx,[esi+12]
        cmp   edx,ebx
        jg    noinside
        mov   eax,1
        mov   ebx,21
        mov   ecx,[esi+8]
        mov   edx,[esi+12]
        mov   edi,[esi+16]
        call  drawbar
      noinside:

        popa

        ret


draw_rectangle:

r_eax equ [esp+28]   ; x start
r_ax  equ [esp+30]   ; x end
r_ebx equ [esp+16]   ; y start
r_bx  equ [esp+18]   ; y end
;esi                 ; color

        pusha

        mov   ecx,esi          ; yb,xb -> yb,xe
        mov   eax,r_eax
        shl   eax,16
        mov   ax,r_ax
        mov   ebx,r_ebx
        shl   ebx,16
        mov   bx,r_ebx
        mov   edi,0
        call  draw_line

        mov   ebx,r_bx         ; ye,xb -> ye,xe
        shl   ebx,16
        mov   bx,r_bx
        call  draw_line

        mov   ecx,esi          ; ya,xa -> ye,xa
        mov   eax,r_eax
        shl   eax,16
        mov   ax,r_eax
        mov   ebx,r_ebx
        shl   ebx,16
        mov   bx,r_bx
        mov   edi,0
        call  draw_line

        mov   eax,r_ax       ; ya,xe -> ye,xe
        shl   eax,16
        mov   ax,r_ax
        call  draw_line

        popa
        ret


drawwindow_III:

        pusha

        mov   edi,edx                              ; RECTANGLE
        mov   eax,[edi+0]
        shl   eax,16
        mov   ax,[edi+0]
        add   ax,[edi+8]
        mov   ebx,[edi+4]
        shl   ebx,16
        mov   bx,[edi+4]
        add   bx,[edi+12]
        mov   esi,[edi+24]
        shr   esi,1
        and   esi,0x007f7f7f
        push  esi
        call  draw_rectangle
        mov   ecx,3
      dw3l:
        add   eax,1*65536-1
        add   ebx,1*65536-1
        mov   esi,[edi+24]
        call  draw_rectangle
        dec   ecx
        jnz   dw3l
        pop   esi
        add   eax,1*65536-1
        add   ebx,1*65536-1
        call  draw_rectangle

        mov   ecx,[edx+20]                       ; GRAB BAR
        push  ecx
        mov   esi,edx
        mov   edx,[esi+04]
        add   edx,4
        mov   ebx,[esi+04]
        add   ebx,20
        mov   eax,[esi+04]
        add   eax,[esi+12]
        cmp   ebx,eax
        jb    wdsizeok2
        mov   ebx,eax
      wdsizeok2:
        push  ebx
      drwi2:
        mov   ebx,edx
        shl   ebx,16
        add   ebx,edx
        mov   eax,[esi+00]
        shl   eax,16
        add   eax,[esi+00]
        add   eax,[esi+8]
        add   eax,4*65536-4
        mov   ecx,[esi+20]
        test  ecx,0x40000000
        jz    nofa3
        add   ecx,0x040404
      nofa3:
        test  ecx,0x80000000
        jz    nofa2
        sub   ecx,0x040404
      nofa2:
        mov   [esi+20],ecx
        and   ecx,0xffffff
        mov   edi,0
        call  draw_line
        inc   edx
        cmp   edx,[esp]
        jb    drwi2
        add   esp,4
        pop   ecx
        mov   [esi+20],ecx

        mov   edx,[esi+04]                       ; WORK AREA
        add   edx,21+5
        mov   ebx,[esi+04]
        add   ebx,[esi+12]
        cmp   edx,ebx
        jg    noinside2
        mov   eax,5
        mov   ebx,20
        mov   ecx,[esi+8]
        mov   edx,[esi+12]
        sub   ecx,4
        sub   edx,4
        mov   edi,[esi+16]
        call  drawbar
      noinside2:

        popa

        ret


sys_getevent:

     call   get_event_for_app
     mov    [esp+36],eax
     ret


align 4

sys_wait_event_timeout:

     mov   ebx,[0xfdf0]
     add   ebx,eax
     cmp   ebx,[0xfdf0]
     jna   .swfet2
   .swfet1:
     call  get_event_for_app
     test  eax,eax
     jne   .eventoccur_time
     call  change_task
     cmp   ebx,[0xfdf0]
     jg    .swfet1
   .swfet2:
     xor   eax,eax
   .eventoccur_time:
     mov   [esp+36],eax
     ret


align 4

sys_waitforevent:

     call  get_event_for_app
     test  eax,eax
     jne   eventoccur
   newwait:

     call  change_task
     call  get_event_for_app
     test  eax,eax
     je    newwait

   eventoccur:
     mov   [esp+36],eax
     ret


get_event_for_app:

     pusha

     mov   edi,[0x3010]              ; WINDOW REDRAW
     test  [edi],dword 1
     jz    no_eventoccur1
     mov   edi,[0x3010]
     cmp   [edi-twdw+31],byte 0
     je    no_eventoccur1
     popa
     mov   eax,1
     ret
   no_eventoccur1:

     mov   edi,[0x3010]              ; KEY IN BUFFER
     test  [edi],dword 2
     jz    no_eventoccur2
     movzx ecx,word [0x3000]
     shl   ecx,1
     add   ecx,0xc000
     movzx edx,word [ecx]
     movzx eax,word [0x3004]
     cmp   eax,edx
     jne   no_eventoccur2
     cmp   [0xf400],byte 0
     je    no_eventoccur2
     popa
     mov   eax,2
     ret
   no_eventoccur2:

     mov   edi,[0x3010]              ; BUTTON IN BUFFER
     test  [edi],dword 4
     jz    no_eventoccur3
     movzx ecx,word [0x3000]
     shl   ecx,1
     add   ecx,0xc000
     movzx edx,word [ecx]
     movzx eax,word [0x3004]
     cmp   eax,edx
     jnz   no_eventoccur3
     cmp   [0xf500],byte 0
     je    no_eventoccur3
     popa
     mov   eax,3
     ret
   no_eventoccur3:

     mov   edi,[0x3010]              ; DESKTOP BACKGROUND REDRAW
     test  [edi],dword 16
     jz    no_eventoccur5
     cmp   [0xfff0],byte 2
     jnz   no_eventoccur5
     popa
     mov   eax,5
     ret
   no_eventoccur5:

     mov   edi,[0x3010]              ; mouse event
     test  [edi],dword 00100000b
     jz    no_mouse_event
     mov   edi,[0x3000]
     shl   edi,8
     test  [edi+0x80000+0xA8],dword 00100000b
     jz    no_mouse_event
     and   [edi+0x80000+0xA8],dword 0xffffffff-00100000b
     popa
     mov   eax,6
     ret
   no_mouse_event:

     mov   edi,[0x3010]              ; IPC
     test  [edi],dword 01000000b
     jz    no_ipc
     mov   edi,[0x3000]
     shl   edi,8
     test  [edi+0x80000+0xA8],dword 01000000b
     jz    no_ipc
     and   [edi+0x80000+0xA8],dword 0xffffffff-01000000b
     popa
     mov   eax,7
     ret
   no_ipc:


     mov   edi,[0x3010]              ; STACK
     test  [edi],dword 10000000b
     jz    no_stack_event
     mov   edi,[0x3000]
     shl   edi,8
     test  [edi+0x80000+0xA8],dword 10000000b
     jz    no_stack_event
     and   [edi+0x80000+0xA8],dword 0xffffffff-10000000b
     popa
     mov   eax,7
     ret
   no_stack_event:


     mov   esi,0x2e0000              ; IRQ'S AND DATA
     mov   ebx,0x00010000
     mov   ecx,0
   irq_event_test:
     mov   edi,[0x3010]
     test  [edi],ebx
     jz    no_irq_event
     mov   edi,ecx
     shl   edi,2
     add   edi,irq_owner
     mov   edx,[edi]
     mov   eax,[0x3010]
     mov   eax,[eax+0x4]
     cmp   edx,eax
     jne   no_irq_event
     cmp   [esi],dword 0
     jz    no_irq_event
     mov   eax,ecx
     add   eax,16
     mov   [esp+28],eax
     popa
     ret
    no_irq_event:
     add   esi,0x1000
     shl   ebx,1
     inc   ecx
     cmp   ecx,16
     jb    irq_event_test

     popa
     mov   eax,0
     ret


dtext:

        ; eax x & y
        ; ebx font ( 0xX0000000 ) & color ( 0x00RRGGBB )
        ; ecx start of text
        ; edx length
        ; edi 1 force

        test   ebx,0x10000000
        jnz    dtext2

        pusha

        mov    esi,edx
        and    esi,0xff
        cmp    esi,0    ; zero length ?
        jnz    dsok

        popa
        ret

      dsok:

      letnew:

        push   eax
        push   ecx
        push   edx
        movzx  ebx,ax
        shr    eax,16
        movzx  edx,byte [ecx]
        mov    ecx,[esp+3*4+32-16]
        call   drawletter
        pop    edx
        pop    ecx
        pop    eax

        add    eax,6*65536

        add    ecx,1
        dec    dx
        jnz    letnew

        popa
        ret


drawletter:

; eax  x
; ebx  y
; ecx  color
; edx  letter
; esi  shl size
; edi  force

        pusha

        mov   eax,0
        mov   ebx,0  ; 0x37000+eax+ebx*8
        inc   esi

      chc:

        push  eax
        push  ebx

        mov   edx,ebx
        shl   edx,3
        add   edx,eax
        add   edx,0x37000+8
        mov   ecx,[esp+32-12+8]
        imul  ecx,8*10
        add   edx,ecx
        cmp   [edx],byte 'o'
        jnz   nopix
        mov   eax,[esp+4]
        mov   ebx,[esp+0]
        add   eax,[esp+32+2*4-4]
        add   ebx,[esp+32+2*4-16]
        mov   ecx,[esp+32+2*4-8]
        call  disable_mouse
        call  putpixel
      nopix:
        pop   ebx
        pop   eax

        add   eax,1
        cmp   eax,5 ; ebp
        jnz   chc

        mov   eax,0

        add   ebx,1
        cmp   ebx,9 ; ebp
        jnz   chc

        popa
        ret


dtext2:

        ; eax x & y
        ; ebx color
        ; ecx start of text
        ; edx length
        ; edi 1 force

        pusha

        mov    esi,edx
        and    esi,0xff
        cmp    esi,0    ; zero length ?
        jnz    dsok2

        popa
        ret

      dsok2:
      letnew2:

        push   eax
        push   ecx
        push   edx
        movzx  ebx,ax
        shr    eax,16
        movzx  edx,byte [ecx]
        mov    ecx,[esp+3*4+32-16]
        call   drawletter2
        pop    edx
        pop    ecx
        pop    eax

        push   edx
        movzx  edx,byte [ecx]
        imul   edx,10*10
        add    edx,0x30000
        cmp    [edx+6],byte ' '
        jne    nocharadd8
        add    eax,8*65536
        jmp    charaddok
      nocharadd8:
        movzx  edx,byte [edx+6]
        sub    edx,47
        shl    edx,16
        add    eax,edx
      charaddok:
        pop    edx

        add    ecx,1
        dec    dx
        jnz    letnew2

        popa
        ret


drawletter2:

; eax  x
; ebx  y
; ecx  color
; edx  letter
; esi  shl size
; edi  force

        pusha

        mov   eax,0
        mov   ebx,0  ; +eax+ebx*8
        inc   esi

      chc2:

        push  eax
        push  ebx

;        cmp   esi,1
;        je    noldiv
;        xor   edx,edx
;        div   esi
;        push  eax
;        xor   edx,edx
;        mov   eax,ebx
;        div   esi
;        mov   ebx,eax
;        pop   eax
;      noldiv:

        mov   edx,ebx
        ;shl   edx,3
        imul  edx,10
        add   edx,eax
        add   edx,0x30000+8+2
        mov   ecx,[esp+32-12+8]
        ;shl   ecx,6
        imul  ecx,10*10
        add   edx,ecx
        cmp   [edx],byte 'o'
        jnz   nopix2
        mov   eax,[esp+4]
        mov   ebx,[esp+0]
        add   eax,[esp+32+2*4-4]
        add   ebx,[esp+32+2*4-16]
        mov   ecx,[esp+32+2*4-8]
        call  disable_mouse
        call  putpixel
      nopix2:
        pop   ebx
        pop   eax

        ;mov   ebp,7
        ;imul  ebp,esi

        add   eax,1
        cmp   eax,7 ;ebp
        jnz   chc2

        mov   eax,0

        ;mov   ebp,9
        ;imul  ebp,esi

        add   ebx,1
        cmp   ebx,9 ; ebp
        jnz   chc2

        popa
        ret




; check pixel limits

cplimit:
        push    edi

        cmp     byte [0xe000], 1
        jnz     .ret0
        mov     edi,[0x3010]
        add     edi, draw_data-0x3000
        mov     ecx, 1
        cmp     [edi+0], eax  ; xs
        ja      .ret1
        cmp     [edi+4], ebx  ; ys
        ja      .ret1
        cmp     eax, [edi+8]   ; xe
        ja      .ret1
        cmp     ebx, [edi+12] ; ye
        ja      .ret1

.ret0:
        xor     ecx, ecx
.ret1:
        pop     edi
        ret


; check if pixel is allowed to be drawn

checkpixel:

        push eax
        push ebx
        push edx

        mov   ecx,[0x3000]
        shl   ecx, 6
        add   ecx,0xc000
        mov   dx,word [ecx]

        cmp   dx, word [0x3004]
        jz    .ret0

        call  cplimit
        or    ecx, ecx    ; if (ecx == 0)
        jnz   .ret1

        mov  edx,[0xfe00]     ; screen x size
        inc  edx
        imul  edx, ebx
        lea  eax, [eax+edx+0x400000]
        mov  dl,[eax]

        mov  eax,[0x3000]
        shl  eax,5
        add  eax,0x3000+0xe

        mov  ecx, 1
        cmp  byte [eax], dl
        jnz  .ret1

.ret0:
        xor  ecx, ecx
.ret1:
        pop  edx
        pop  ebx
        pop  eax
        ret


; activate window

windowactivate:

        ; esi = abs mem position in stack 0xC400+

        pusha

        push  esi
        xor   eax,eax
        mov   ax,[esi] ; ax <- process no
        shl   eax,1
        mov   ebx,eax
        add   ebx,0xc000
        xor   eax,eax
        mov   ax,[ebx] ; ax <- position in window stack

        mov   esi,0                 ; drop others
      waloop:
        cmp   esi,dword[0x3004]
        jb    waok
        jmp   wacont
      waok:

        inc   esi
        mov   edi,esi
        shl   edi,1
        add   edi,0xc000

        mov   bx,[edi]
        cmp   bx,ax
        jbe   wanoc
        dec   bx
        mov   [edi],bx

      wanoc:

        jmp   waloop

      wacont:
                            ; set to no 1
        pop   esi

        xor   eax,eax
        mov   ax,[esi]
        shl   eax,1
        add   eax,0xc000
        mov   bx,[0x3004]
        mov   [eax],bx

        ; update on screen -window stack

        mov   esi,0

      waloop2:

        mov   edi,[0x3004]
        cmp   esi,edi
        jb    waok2
        jmp   wacont2

      waok2:

        inc   esi

        mov   edi,esi
        shl   edi,1
        add   edi,0xc000
        movzx ebx,word [edi]
        shl   ebx,1
        add   ebx,0xc400
        mov   ecx,esi
        mov   [ebx],cx
        jmp   waloop2

      wacont2:

        mov   [0xf400],byte 0           ; empty keyboard buffer
        mov   [0xf500],byte 0           ; empty button buffer

        popa
        ret


mouse_active  db  0


; check misc

checkmisc:

    cmp   [ctrl_alt_del],1
    jne   nocpustart
    ;
  newcount:
    mov   ecx,0
    mov   eax,[application_table_status]
  newcadc:
    cmp   [application_table_status],dword 0
    je    contcad
    cmp   eax,[application_table_status]
    jne   newcount
    push  eax ebx ecx
    mov   eax , 1
    call  delay_hs
    pop   ecx ebx eax
    add   ecx , 1
    cmp   ecx , 200
    jb    newcadc
  contcad:
    mov   [application_table_status],dword 0
    ;
    mov   eax,cpustring
    call  start_application_fl
    mov   [ctrl_alt_del],0
    jmp   nocpustart
  cpustring db 'CPU        '
  nocpustart:

    cmp   [mouse_active],1
    jne   mouse_not_active
    mov   [mouse_active],0
    mov   edi,0
    mov   ecx,[0x3004]
   set_mouse_event:
    add   edi,256
    or    [edi+0x80000+0xA8],dword 00100000b
    loop  set_mouse_event
  mouse_not_active:


    cmp   [0xfff0],byte 0               ; background update ?
    jz    nobackgr
    mov   [0xfff0],byte 2
    call  change_task
    mov   [0xfff0],byte 0
    mov   [draw_data+32+0],dword 0
    mov   [draw_data+32+4],dword 0
    mov   eax,[0xfe00]
    mov   ebx,[0xfe04]
    mov   [draw_data+32+8],eax
    mov   [draw_data+32+12],ebx
    call  drawbackground
    mov   [0xfff4],byte 0
  nobackgr:


    ; system shutdown request

    cmp  [0xFF00],byte 0
    je   noshutdown

    mov  edx,[shutdown_processes]
    sub  dl,2

    cmp  [0xff00],dl
    jne  no_mark_system_shutdown

    mov   edx,0x3040
    movzx ecx,byte [0xff00]
    add   ecx,5
  markz:
    mov   [edx+0xa],byte 3
    add   edx,0x20
    loop  markz

  no_mark_system_shutdown:

    call disable_mouse

    dec  byte [0xff00]

    cmp  [0xff00],byte 0
    jne  noshutdown  ;;  system_shutdown

    jmp  system_shutdown ; shutdown.inc

    mov  eax , 200
    call delay_hs

    ; Boot

    cli

    mov   edx , 0x64 ; Boot with keyboard controller
    mov   eax , 0xfe
    out   dx,al

    cli
    jmp   $ ;  not propably needed
    

  noshutdown:


    mov   eax,[0x3004]                  ; termination
    mov   ebx,0x3020+0xa
    mov   esi,1

  newct:
    mov   cl,[ebx]
    cmp   cl,byte 3
    jz    terminate
    cmp   cl,byte 4
    jz    terminate

    add   ebx,0x20
    inc   esi
    dec   eax
    jnz   newct

    ret


find_pressed_button_frames:

        pusha

        movzx ebx,word [eax+0]
        shl   ebx,5
        add   ebx,window_data
        movzx ecx,word [ebx+0]     ; window x start
        movzx edx,word [eax+4]     ; button x start
        add   ecx,edx
        push  ecx

        mov   dx,[eax+6]     ; button x size
        add   cx,dx
        mov   esi,ecx
        add   esi,1
        mov   cx,[ebx+4]     ; window y start
        mov   dx,[eax+8]     ; button y start
        add   ecx,edx
        mov   ebx,ecx
        mov   dx,[eax+10]    ; button y size
        add   dx,cx
        add   dx,1

        pop   eax

        ; eax x beginning
        ; ebx y beginning
        ; esi x end
        ; edx y end
        ; ecx color

        mov   [pressed_button_eax],eax
        mov   [pressed_button_ebx],ebx
        mov   [pressed_button_ecx],ecx
        mov   [pressed_button_edx],edx
        mov   [pressed_button_esi],esi

        popa
        ret

pressed_button_eax  dd  0
pressed_button_ebx  dd  0
pressed_button_ecx  dd  0
pressed_button_edx  dd  0
pressed_button_esi  dd  0

; negative button image

negativebutton:
        ; If requested, do not display button 
        ; boarder on press.
        test  ebx,0x20000000
        jz    draw_negative_button
        ret
      draw_negative_button:


        pusha

        mov   eax,[pressed_button_eax]
        mov   ebx,[pressed_button_ebx]
        mov   ecx,[pressed_button_ecx]
        mov   edx,[pressed_button_edx]
        mov   esi,[pressed_button_esi]
        mov   ecx,0x01000000

        sub   edx,1
        push  edx
        add   edx,1
        sub   esi,1
        push  esi
        add   esi,1

        push  eax
        push  ebx
        push  ecx
        push  edx
        push  edi

      bdbnewline:
        mov   edi,1    ; force
        cmp   eax,[esp+16]
        jz    bneg
        cmp   eax,[esp+20]
        jz    bneg
        cmp   ebx,[esp+12]
        jz    bneg
        cmp   ebx,[esp+24]
        jz    bneg
        jmp   nbneg

      bneg:

        call  disable_mouse
        call  putpixel

      nbneg:

        add   eax,1
        cmp   eax,esi
        jnz   bdbnewline
        mov   eax,[esp+16]
        add   ebx,1
        cmp   ebx,edx
        jnz   bdbnewline

        add   esp,28

        popa

        ret

; check buttons


; 0000 word process number
; 0002 word button id number : bits 0-15
; 0004 word x start
; 0006 word x size
; 0008 word y start
; 000A word y size
; 000C word button id number : bits 16-31
;
; button table in 0x10 increments
;
; first at 0x10


checkbuttons:

    cmp   [0xfb40],byte 0    ; mouse buttons pressed
    jnz   check_buttons_continue
    ret

  check_buttons_continue:

    pusha

    mov    esi,0
    mov    edi,[0xfe88]
    movzx  edx,word [edi]
    cmp    edx,0
    jne    yesbuttoncheck
    popa
    ret

  yesbuttoncheck:

    push  esi
    inc   edx
    push  edx

  buttonnewcheck:

    pop   edx
    pop   esi
    inc   esi
    cmp   edx,esi
    jge   bch

    popa                 ; no button pressed
    ret

  bch:

    push  esi
    push  edx
    mov   eax,esi
    shl   eax,4
    add   eax,edi

    ; check that button is at top of windowing stack

    movzx ebx,word [eax]
    shl   ebx,1
    add   ebx,0xc000
    movzx ecx,word [ebx]
    cmp   ecx,[0x3004]
    jne   buttonnewcheck

    ; check that button start is inside window x/y end

    movzx ebx,word [eax+0]
    shl   ebx,5
    add   ebx,window_data
    mov   ecx,[ebx+8]          ; window end X
    movzx edx,word [eax+4]     ; button start X
    cmp   edx,ecx
    jge   buttonnewcheck

    mov   ecx,[ebx+12]         ; window end Y
    movzx edx,word [eax+8]     ; button start Y
    cmp   edx,ecx
    jge   buttonnewcheck

    ; check coordinates
                               ; mouse x >= button x ?
    movzx ebx,word [eax+0]
    shl   ebx,5
    add   ebx,window_data
    movzx ecx,word [ebx+0]     ; window x start
    movzx edx,word [eax+4]     ; button x start
    add   edx,ecx
    mov   cx,[0xfb0a]
    cmp   edx,ecx
    jg    buttonnewcheck

    movzx ebx,word [eax+6]     ; button x size
    add   edx,ebx
    cmp   ecx,edx
    jg    buttonnewcheck

                               ; mouse y >= button y ?
    movzx ebx,word [eax+0]
    shl   ebx,5
    add   ebx,window_data
    movzx ecx,word [ebx+4]     ; window y start
    movzx edx,word [eax+8]     ; button y start
    add   edx,ecx
    mov   cx,[0xfb0c]
    cmp   edx,ecx
    jg    buttonnewcheck

    movzx ebx,word [eax+10]    ; button y size
    add   edx,ebx
    cmp   ecx,edx
    jg    buttonnewcheck

    ; mouse on button

    pop   edx
    pop   esi

    mov   bx,[eax+0xc]     ; button id : bits 16-31
    shl   ebx,16
    mov   bx,[eax+2]       ; button id : bits 00-16
    push  ebx

    mov   [0xfb44],byte 1  ; no mouse down checks
    call find_pressed_button_frames
    call negativebutton
    pusha

  cbwaitmouseup:

    call  checkidle

    call  check_mouse_data
    call  draw_pointer

    pusha
    call   stack_handler
    popa

    cmp   [0xfb40],byte 0  ; mouse buttons pressed ?
    jnz   cbwaitmouseup
    popa
    call  negativebutton
    mov   [0xfff4],byte 0  ; no mouse background
    mov   [0xfff5],byte 0  ; draw mouse
    mov   [0xf500],byte 1
    pop   ebx
    mov   [0xf501],ebx
    mov   [0xfb44],byte 0  ; mouse down checks
    popa
    ret

; check if window is necessary to draw

checkwindowdraw:

        ; edi = position in window_data+

        mov   esi,edi
        sub   esi,window_data
        shr   esi,5

        ; esi = process nro

        mov   edx,esi
        shl   edx,1
        add   edx,0xc000

        xor   ecx,ecx
        mov   cx,[edx]
        shl   ecx,1
        add   ecx,0xc400 ; position in windowing stack, checks from here ->

        mov   esi,ecx

 ;       pusha
 ;       xor   eax,eax
 ;       mov   ax,[esi]
 ;       shl   eax,5
 ;       add   eax,window_data
 ;       mov   esi,eax
 ;       popa

        push  esi

      wdn0:

        pop   esi
        add   esi,2
        push  esi

        mov   eax,[0x3004]
        shl   eax,1
        add   eax,0xc400

        cmp   esi,eax
        jbe   wdn1

        pop   esi

        mov   ecx,0       ; passed all windows to top
        ret

      wdn1:

        xor   eax,eax
        mov   ax,[esi]
        shl   eax,5
        add   eax,window_data
        mov   esi,eax

        mov   eax,[edi+0]
        mov   ebx,[edi+4]
        mov   ecx,[edi+8]
        mov   edx,[edi+12]
        add   ecx,eax
        add   edx,ebx

    ;    dec   eax ; 0.80
    ;    dec   ebx
    ;    inc   ecx ; 0.80
    ;    inc   edx

        mov   ecx,[esi+4]    ; y check
        cmp   ecx,edx
        jb    wici1
        jmp   wdn0
      wici1:
        mov   eax,[esi+12]
        add   ecx,eax
        cmp   ebx,ecx
        jbe   wici2
        jmp   wdn0
      wici2:

        mov   eax,[edi+0]
        mov   ebx,[edi+4]
        mov   ecx,[edi+8]
        mov   edx,[edi+12]
        add   ecx,eax
        add   edx,ebx

        sub   ecx , 2

    ;    dec   eax ; 0.80
    ;    dec   ebx
    ;    inc   ecx ; 0.80
    ;    inc   edx

        mov   edx,[esi+0]    ; x check
        cmp   edx,ecx
        jb    wici3
        jmp   wdn0
      wici3:
        mov   ecx,[esi+8]
        add   edx,ecx
        cmp   eax,edx
        jbe   wici4
        jmp   wdn0
      wici4:

        pop   esi
        mov   ecx,1   ; overlap some window
        ret


waredraw:     ; if redraw necessary at activate

        pusha

        call  checkwindowdraw      ; draw window on activation ?

        cmp   ecx,0
        jnz   wand2                ; yes
        jmp   wand                 ; no

      wand2:

        popa
        mov   [0xfb44],byte 1
        call  windowactivate

        ; update screen info

        pusha
        mov   edi,[0x3004]
        shl   edi,1
        add   edi,0xc400
        mov   esi,[edi]
        and   esi,65535
        shl   esi,5
        add   esi,window_data

        mov   eax,[esi+00]
        mov   ebx,[esi+04]
        mov   ecx,[esi+8]
        mov   edx,[esi+12]

        add   ecx,eax
        add   edx,ebx

        mov   edi,[0x3004]
        shl   edi,1
        add   edi,0xc400
        mov   esi,[edi]
        and   esi,255
        shl   esi,5
        add   esi,0x3000+0xe
        movzx esi,byte[esi]
        call  calculatescreen ; setscreen

        popa

        cmp   [0xff01],dword 1
        jbe   wand5

        mov   eax,10            ; wait for putimages to finish
        call  delay_hs

        mov   [edi+31],byte 1  ; redraw flag for app
        mov   [0xfb44],byte 0  ; mouse down checks

        ret

      wand5:

        mov   eax,5            ; wait for putimages to finish
        call  delay_hs

        mov   [edi+31],byte 1  ; redraw flag for app
        mov   ecx,100

       cwwaitflagdown:

        dec   ecx
        jz    cwnowait

        mov   eax,2
        call  delay_hs
        cmp   [edi+31],byte 0  ; wait flag to drop
        jnz   cwwaitflagdown

      cwnowait:

        mov   ecx,10
      cwwait:
        mov   eax,1           ; wait for draw to finish
        call  delay_hs
        loop  cwwait

        mov   [0xfb44],byte 0

        ret

      wand:

        popa

        call  windowactivate
        mov   [0xfb44],byte 0  ; mouse down checks
        mov   [0xfff4],byte 0  ; no mouse background
        mov   [0xfff5],byte 0  ; draw mouse
        ret


window_moving   db 'Kernel : Window - move/resize',13,10,0
window_moved    db 'Kernel : Window - done',13,10,0

; check window touch

checkwindows:


        pusha

        cmp  [0xff01],dword 1  ; activate request from app ?
        jbe  cwl1
        mov  edi,[0xff01]
        shl  edi,5
        add  edi,window_data
        mov  ebx,[0xff01]
        shl  ebx,1
        add  ebx,0xc000
        mov  esi,[ebx]
        and  esi,65535
        shl  esi,1
        add  esi,0xc400
        call waredraw
        mov  [0xff01],dword 0

        popa
        ret

      cwl1:

        cmp   [0xfb40],byte 0    ; mouse buttons pressed ?
        jne   cwm
        popa
        ret

      cwm:

        mov   esi,[0x3004]
        inc   esi

      cwloop:

        cmp   esi,2
        jge   cwok
        popa
        ret

      cwok:
        dec   esi
        mov   eax,esi
        shl   eax,1
        add   eax,0xc400
        xor   ebx,ebx
        mov   bx,[eax]
        shl   ebx,5
        add   ebx,window_data
        mov   edi,ebx
        mov   ax,[0xfb0a]
        mov   bx,[0xfb0c]
        mov   cx,[edi+0]
        mov   dx,[edi+4]
        cmp   cx,ax
        jb    cw1
        jmp   cwloop
      cw1:
        cmp   dx,bx
        jb    cw2
        jmp   cwloop
      cw2:
        add   cx,[edi+8]
        add   dx,[edi+12]
        cmp   ax,cx
        jb    cw3
        jmp   cwloop
      cw3:
        cmp   bx,dx
        jb    cw4
        jmp   cwloop
      cw4:

        pusha
        mov   eax,esi
        mov   bx,[0x3004]
        cmp   ax,bx
        jnz   nomovwin
        jmp   movwin
       nomovwin:
        ; eax = position in windowing stack
        ; redraw must ?
        shl   esi,1
        add   esi,0xc400
        call  waredraw
        add   esp,32

        popa
        ret

      movwin:    ; MOVE OR RESIZE WINDOW

        popa
        ; Check for user enabled fixed window
        mov   edx,[edi+0x14]
        and   edx,0x0f000000
        cmp   edx,0x01000000
        jne   window_move_enabled_for_user
        popa
        ret
      window_move_enabled_for_user:


        mov   [do_resize_from_corner],byte 0   ; resize for skinned window
        mov   edx,[edi+0x10]
        and   edx,0x0f000000
        cmp   edx,0x02000000
        jb    no_resize_2
        mov   dx,[edi+4]
        add   dx,[edi+12]
        sub   dx,6
        cmp   bx,dx
        jb    no_resize_2
        mov   [do_resize_from_corner],byte 1
        jmp   cw5
      no_resize_2:

        mov   dx,[edi+4] ; check if touch on bar
        add   dx,21
        cmp   bx,dx
        jb    cw5
        popa
        ret

      cw5:

        push   esi
        mov    esi,window_moving
        call   sys_msg_board_str
        pop    esi

        mov   ecx,[0xfdf0]    ; double-click ?
        mov   edx,ecx
        sub   edx,[latest_window_touch]
        mov   [latest_window_touch],ecx
        mov   [latest_window_touch_delta],edx

        mov   cl,[0xfb40]     ; save for shade check
        mov   [do_resize],cl

        movzx ecx,word [edi+0]
        movzx edx,word [edi+4]

        pusha
        mov   [dlx],ecx      ; save for drawlimits
        mov   [dly],edx
        mov   eax,[edi+8]
        add   ecx,eax
        mov   eax,[edi+12]
        add   edx,eax
        mov   [dlxe],ecx
        mov   [dlye],edx
        popa

        sub   ax,cx
        sub   bx,dx

        mov   esi,[0xfb0a]
        mov   [0xf300],esi

        pusha           ; wait for putimages to finish
        mov   eax,5
        call  delay_hs
        mov   eax,[edi+0]
        mov   [npx],eax
        mov   eax,[edi+4]
        mov   [npy],eax
        popa

        pusha                  ; save old coordinates
        mov   ax,[edi+00]
        mov   word [oldc+00],ax
        mov   ax,[edi+04]
        mov   word [oldc+04],ax
        mov   ax,[edi+8]
        mov   word [oldc+8],ax
        mov   word [npxe],ax
        mov   ax,[edi+12]
        mov   word [oldc+12],ax
        mov   word [npye],ax
        popa

        call  drawwindowframes

        mov   [reposition],0
        mov   [0xfb44],byte 1   ; no reaction to mouse up/down

        ; move window

      newchm:

        mov   [0xfff5],byte 1

        call  checkidle

        call  checkEgaCga

        mov   [0xfff4],byte 0

        call  check_mouse_data
        call  draw_pointer

        pusha
        call   stack_handler
        popa

        mov   esi,[0xf300]
        cmp   esi,[0xfb0a]
        je    cwb

        mov   cx,[0xfb0a]
        mov   dx,[0xfb0c]
        sub   cx,ax
        sub   dx,bx
        push  ax
        push  bx

        call  drawwindowframes

        mov   ax,[0xfe00]
        mov   bx,[0xfe04]

        cmp   [do_resize_from_corner],1
        je    no_new_position

        mov   word [npx],word 0     ; x repos ?
        cmp   ax,cx
        jb    noreposx
        mov   [reposition],1
        sub   ax,word [npxe]
        mov   word [npx],ax
        cmp   ax,cx
        jb    noreposx
        mov   word [npx],cx
      noreposx:

        mov   word [npy],word 0     ; y repos ?
        cmp   bx,dx
        jb    noreposy
        mov   [reposition],1
        sub   bx,word [npye]
        mov   word [npy],bx
        cmp   bx,dx
        jb    noreposy
        mov   word [npy],dx
      noreposy:

      no_new_position:

        cmp   [do_resize_from_corner],0    ; resize from right corner
        je    norepos_size
        pusha

        mov   edx,edi
        sub   edx,window_data
        shr   edx,5
        shl   edx,8
        add   edx,0x80000                 ; process base at 0x80000+

        movzx eax,word [0xfb0a]
        cmp   eax,[edi+0]
        jb    nnepx
        sub   eax,[edi+0]
        cmp   eax,[edx+0x90+8]
        jge   nnepx2
        mov   eax,[edx+0x90+8]
      nnepx2:
        mov   [npxe],eax
      nnepx:

        movzx eax,word [0xfb0c]
        cmp   eax,[edi+4]
        jb    nnepy
        sub   eax,[edi+4]
        cmp   eax,23 ; [edx+0x90+12]
        jge   nnepy2
        mov   eax,23 ; [edx+0x90+12]
      nnepy2:
        mov   [npye],eax
      nnepy:

        mov   [reposition],1

        popa
      norepos_size:

        pop   bx
        pop   ax
        call  drawwindowframes

        mov   esi,[0xfb0a]
        mov   [0xf300],esi

      cwb:

        cmp   [0xfb40],byte 0
        jne   newchm
                                     ; new position done
        call  drawwindowframes
        mov   [0xfff5],byte 1

        mov   eax,[npx]
        mov   [edi+0],eax
        mov   eax,[npy]
        mov   [edi+4],eax
        mov   eax,[npxe]
        mov   [edi+8],eax
        mov   eax,[npye]
        mov   [edi+12],eax

        cmp   [reposition],1         ; save new X and Y start
        jne   no_xy_save
        pusha
        mov   esi,edi
        sub   edi,window_data
        shr   edi,5
        shl   edi,8
        add   edi,0x80000+0x90
        mov   ecx,2
        cld
        rep   movsd
        popa
      no_xy_save:

        pusha                             ; WINDOW SHADE/FULLSCREEN

        cmp   [reposition],1
        je    no_window_sizing

        mov   edx,edi
        sub   edx,window_data
        shr   edx,5
        shl   edx,8
        add   edx,0x80000                 ; process base at 0x80000+

        cmp   [do_resize],2               ; window shade ?
        jb    no_window_shade
        mov   [reposition],1
        cmp   [edi+12],dword 23
        je    window_shade_up
        mov   [edi+12],dword 23           ; on
        jmp   no_window_shade
      window_shade_up:
        mov   eax,[edi+0]
        add   eax,[edi+4]
        cmp   eax,0
        je    shade_full
        mov   eax,[edx+0x9C]              ; off
        mov   [edi+12],eax
        jmp   no_window_shade
      shade_full:
        mov   eax,[0xfe04]
        mov   [edi+12],eax
      no_window_shade:

        cmp   [do_resize],1               ; fullscreen/restore ?
        jne   no_fullscreen_restore
        cmp   [latest_window_touch_delta],dword 50
        jg    no_fullscreen_restore
        mov   [reposition],1
        mov   eax,[edi+12]
        cmp   eax,[0xfe04]
        je    restore_from_fullscreen
        mov   [edi+0],dword 0             ; set fullscreen
        mov   [edi+4],dword 0
        mov   eax,[0xfe00]
        mov   [edi+8],eax
        mov   eax,[0xfe04]
        mov   [edi+12],eax
        jmp   no_fullscreen_restore
      restore_from_fullscreen:
        push  edi                         ; restore
        mov   esi,edx
        add   esi,0x90
        mov   ecx,4
        cld
        rep   movsd
        pop   edi
      no_fullscreen_restore:

        mov   eax,[edi+4]                 ; check Y inside screen
        add   eax,[edi+12]
        cmp   eax,[0xfe04]
        jbe   no_window_sizing
        mov   eax,[0xfe04]
        sub   eax,[edi+12]
        mov   [edi+4],eax
      no_window_sizing:

        popa

        cmp   [reposition],0
        je    retwm

        pusha
        mov   eax,[edi+00]
        mov   ebx,[edi+04]
        mov   ecx,[edi+8]
        mov   edx,[edi+12]
        add   ecx,eax
        add   edx,ebx
        mov   edi,[0x3004]
        shl   edi,1
        add   edi,0xc400
        movzx esi,byte [edi]
        shl   esi,5
        add   esi,0x3000+0xe
        movzx esi,byte [esi]

        sub   edi,draw_data
        shr   edi,5
        shl   edi,8
        add   edi,0x80000+0x80
        cmp   [edi],dword 0
        jne   no_rect_shaped_move
        call  setscreen
        jmp   move_calculated
      no_rect_shaped_move:
        call  calculatescreen
      move_calculated:

        popa

        mov   [edi+31],byte 1 ; mark first as redraw
        mov   [0xfff5],byte 1 ; no mouse

        pusha
        mov   eax,[oldc+00]
        mov   ebx,[oldc+04]
        mov   ecx,[oldc+8]
        mov   edx,[oldc+12]
        add   ecx,eax
        add   edx,ebx
        call  calculatescreen
        popa

        mov   eax,edi
        call  redrawscreen

        mov   ecx,100         ; wait to avoid mouse residuals
      waitre2:
        call  check_mouse_data
        mov   [0xfff5],byte 1
        call  checkidle
        cmp   [edi+31],byte 0
        jz    retwm
        loop  waitre2

      retwm:

        mov   [0xfff5],byte 0 ; mouse pointer
        mov   [0xfff4],byte 0 ; no mouse under
        mov   [0xfb44],byte 0 ; react to mouse up/down

        mov    esi,window_moved
        call   sys_msg_board_str

        popa
        ret

do_resize_from_corner      db  0x0
reposition                 db  0x0
latest_window_touch        dd  0x0
latest_window_touch_delta  dd  0x0

do_resize db 0x0

oldc    dd 0x0,0x0,0x0,0x0

dlx     dd 0x0
dly     dd 0x0
dlxe    dd 0x0
dlye    dd 0x0

npx     dd 0x0
npy     dd 0x0
npxe    dd 0x0
npye    dd 0x0

mpx     dd 0x0
mpy     dd 0x0


; draw negative window frames

drawwindowframes:

        pusha

        mov   eax,[npx]
        shl   eax,16
        add   eax,[npx]
        add   eax,[npxe]
        add   eax,65536*1-1
        mov   ebx,[npy]
        shl   ebx,16
        add   ebx,[npy]
        mov   ecx,0x01000000
        push  edi
        mov   edi,1
        call  draw_line
        pop   edi

        mov   eax,[npx]
        shl   eax,16
        add   eax,[npx]
        add   eax,[npxe]
        add   eax,65536*1-1
        mov   ebx,[npy]
        add   ebx,[npye]
        shl   ebx,16
        add   ebx,[npy]
        add   ebx,[npye]
        mov   ecx,0x01000000
        push  edi
        mov   edi,1
        call  draw_line
        pop   edi

        mov   eax,[npx]
        shl   eax,16
        add   eax,[npx]
        mov   ebx,[npy]
        shl   ebx,16
        add   ebx,[npy]
        add   ebx,[npye]
        mov   ecx,0x01000000
        push  edi
        mov   edi,1
        call  draw_line
        pop   edi

        mov   eax,[npx]
        add   eax,[npxe]
        shl   eax,16
        add   eax,[npx]
        add   eax,[npxe]
        mov   ebx,[npy]
        shl   ebx,16
        add   ebx,[npy]
        add   ebx,[npye]
        mov   ecx,0x01000000
        push  edi
        mov   edi,1
        call  draw_line
        pop   edi

        popa

        ret


; redraw screen

redrawscreen:

; eax , if process window_data base is eax, do not set flag/limits

         pusha
         push  eax

         mov   eax,2
         call  delay_hs

         mov   ecx,0               ; redraw flags for apps

       newdw2:

         inc   ecx
         push  ecx

         mov   eax,ecx
         shl   eax,5
         add   eax,window_data

         cmp   eax,[esp+4]
         je    not_this_task
                                   ; check if window in redraw area
         mov   edi,eax

         cmp   ecx,1               ; limit for background
         jz    bgli

         mov   eax,[edi+0]
         mov   ebx,[edi+4]
         mov   ecx,[edi+8]
         mov   edx,[edi+12]
         add   ecx,eax
         add   edx,ebx

         mov   ecx,[dlye]   ; ecx = area y end     ebx = window y start
         cmp   ecx,ebx
         jb    ricino

         mov   ecx,[dlxe]   ; ecx = area x end     eax = window x start
         cmp   ecx,eax
         jb    ricino

         mov   eax,[edi+0]
         mov   ebx,[edi+4]
         mov   ecx,[edi+8]
         mov   edx,[edi+12]
         add   ecx,eax
         add   edx,ebx

         mov   eax,[dly]    ; eax = area y start     edx = window y end
         cmp   edx,eax
         jb    ricino

         mov   eax,[dlx]    ; eax = area x start     ecx = window x end
         cmp   ecx,eax
         jb    ricino

        bgli:

         cmp   edi,esi
         jz    ricino

         mov   eax,edi
         add   eax,draw_data-window_data

         mov   ebx,[dlx]          ; set limits
         mov   [eax+0],ebx
         mov   ebx,[dly]
         mov   [eax+4],ebx
         mov   ebx,[dlxe]
         mov   [eax+8],ebx
         mov   ebx,[dlye]
         mov   [eax+12],ebx

         sub   eax,draw_data-window_data

         cmp   ecx,1
         jne   nobgrd
         cmp   esi,1
         je    newdw8
         call  drawbackground
       newdw8:
       nobgrd:

         mov   [eax+31],byte 1    ; mark as redraw

       ricino:

       not_this_task:

         pop   ecx

         cmp   ecx,[0x3004]
         jg    newdw3
         jmp   newdw2

       newdw3:

         pop  eax
         popa

         ret

;   check mouse
;
;
;   FB00  ->   FB0F   mouse memory 00 chunk count - FB0A-B x - FB0C-D y
;   FB10  ->   FB17   mouse color mem
;   FB21              x move
;   FB22              y move
;   FB30              color temp
;   FB28              high bits temp
;   FB4A  ->   FB4D   FB4A-B x-under - FB4C-D y-under
;   FC00  ->   FCFE   com1/ps2 buffer
;   FCFF              com1/ps2 buffer count starting from FC00

mousecount  dd  0x0
mousedata   dd  0x0


check_mouse_data:

        pusha

        mov    [mousecount],dword 0x2e0000+12*4096
        mov    [mousedata],dword 0x2e0000+12*4096+0x10
        cmp    [0xF604],byte 2
        jne    nocom1mouse
        mov    [mousecount],dword 0x2e0000+4*4096
        mov    [mousedata],dword 0x2e0000+4*4096+0x10
      nocom1mouse:
        cmp    [0xF604],byte 3
        jne    nocom2mouse
        mov    [mousecount],dword 0x2e0000+3*4096
        mov    [mousedata],dword 0x2e0000+3*4096+0x10
      nocom2mouse:

      uusicheckmouse:

        mov    ebx,[mousecount]       ; anything at buffer for mouse
        cmp    [ebx],byte 0
        jnz    c_byte

        jmp    checkmouseret

      c_byte:

        ; first byte of comX or ps2 ?

        cmp    [0xF604],byte 2
        jge    com1mousefirst
        jmp    ps2mousefirst

        ; ******************************************
        ; *********** COMX mouse driver ************
        ; ******************************************

       com1mousefirst:

        mov    edi,[mousedata]
        mov    dl,byte [edi] ; first com1 ?
        and    dl,64
        cmp    dl,64
        jnz    cm2
        mov    [0xfb00],byte 0  ; zero mouse block count
       cm2:
        xor    ebx,ebx

        mov    bl,[0xfb00]
        add    bl,1
        mov    [0xfb00],bl
        mov    eax,0xfb00
        add    eax,ebx
        mov    edi,[mousedata]
        mov    dl,byte [edi]
        mov    [eax],byte dl
        cmp    bl,3             ; three ?
        jz     com1mouse

        jmp    decm

      com1mouse:

        ; buttons

        movzx  eax,byte [0xfb01]
        shr    eax,4
        and    eax,3
        mov    [0xfb40],al


        ; com1 mouse
        ; x

        mov    dl,[0xfb01]        ; x high bits
        movzx  eax,dl
        and    al,3
        shl    al,6
        mov    dl,byte[0xfb02]    ; x low bits
        add    al,dl
        mov    [0xfb21],byte al
        movzx  ebx,word[0xfb0a]

        mov    al,byte [0xfb01]   ; + or - ?
        and    al,2
        cmp    al,2
        jnz    x_add

       x_sub:
        movzx  ebx,word[0xfb0a]   ; x-
        movzx  eax,byte [0xfb21]
        sub    bx,255
        add    bx,ax
        push   ebx
        mov    [0xfb00],byte 0
        jmp    my_event
       x_add:
        movzx  ebx,word[0xfb0a]   ; x+
        movzx  eax,byte [0xfb21]
        add    bx,ax
        push   ebx
        mov    [0xfb00],byte 0


        ; y


      my_event:

        mov    dl,[0xfb01]       ; y high bits
        movzx  eax,dl
        and    al,12
        shl    al,4
        mov    dl,byte[0xfb03]   ; y low bits
        add    al,dl
        mov    [0xfb22],byte al
        movzx  ebx,word[0xfb0c]

        mov    al,byte [0xfb01]  ; + or - ?
        and    al,8
        cmp    al,8
        jnz    y_add

      y_sub:
        movzx  ebx,word[0xfb0c]  ; y-
        movzx  eax,byte [0xfb22]
        sub    bx,255
        add    bx,ax
        push   ebx
        mov    [0xfb00],byte 0
        jmp    mdraw
      y_add:
        movzx  ebx,word[0xfb0c]  ; y+
        movzx  eax,byte [0xfb22]
        add    bx,ax
        push   ebx
        mov    [0xfb00],byte 0
        jmp    mdraw

        ; end of com1 mouse



        ; ******************************************
        ; ********  PS2 MOUSE DRIVER  **************
        ; ******************************************

      ps2mousefirst:

        movzx  edx,byte [0x2E0000+4096*12+0x10]   ; first ps2 ?
        cmp    edx,40
        jne    cm3
        mov    [0xfb00],byte 0  ; zero mouse block count
      cm3:

        movzx  ebx,byte [0xfb00]
        add    ebx,1
        mov    [0xfb00],bl
        mov    eax,0xfb00
        add    eax,ebx
        mov    dl,byte [0x2E0000+4096*12+0x10]
        mov    [eax],byte dl

        cmp    bl,3             ; full packet of three bytes ?
        jz     ps2mouse
        jmp    decm


      ps2mouse:

        mov    [0xfb00],byte 0  ; zero mouse block count

        ; buttons

        movzx  eax,byte [0xfb01]
        and    eax,3
        mov    [0xfb40],al

        ; x

        movzx  eax,word [0xfb0a]
        movzx  edx,byte [0xfb02]
        cmp    edx,128
        jb     ps2xp
        shl    edx,1
        add    eax,edx
        cmp    eax,512
        jge    ps2xsok
        mov    eax,0
        jmp    ps2xready
       ps2xsok:
        sub    eax,512
        jmp    ps2xready
       ps2xp:
        shl    edx,1
        add    eax,edx
        jmp    ps2xready
       ps2xready:
        push   eax

        ; y

        movzx  eax,word [0xfb0c]
        movzx  edx,byte [0xfb03]
        cmp    edx,128
        jb     ps2yp
        add    eax,512
        shl    edx,1
        sub    eax,edx
        jmp    ps2yready
       ps2yp:
        shl    edx,1
        cmp    edx,eax
        jb     ps201
        mov    edx,eax
       ps201:
        sub    eax,edx
        jmp    ps2yready
       ps2yready:
        push   eax

        jmp    mdraw

        ; end of ps2 mouse


        ; ****************************
        ; ***** CHECK FOR LIMITS *****
        ; ****************************

      mdraw:

        cmp    [0xfb44],byte 0
        jne    mousedraw4
        cmp    [0xfb40],byte 0
        je     mousedraw4
        mov    [0xfff5],byte 1

      mousedraw4:

        pop    ebx
        pop    eax

        mov    [mouse_active],1

        mov    dx,0                   ; smaller than zero
        cmp    bx,dx
        jge    mnb11
        mov    bx,0
      mnb11:
        mov    [0xfb0c],word bx

        mov    dx,0
        cmp    ax,dx
        jge    mnb22
        mov    ax,0
      mnb22:
        mov    [0xfb0a],word ax

        mov    edx,[0xfe04]           ; bigger than maximum
        cmp    ebx,edx
        jb     mnb1
        mov    bx,[0xfe04]
      mnb1:
        mov    [0xfb0c],word bx

        mov    edx,[0xfe00]
        cmp    eax,edx
        jb     mnb2
        mov    ax,[0xfe00]
      mnb2:
        mov    [0xfb0a],word ax


        ; ****   NEXT DATA BYTE FROM MOUSE BUFFER   ****

      decm:

        mov    edi,[mousecount]         ; decrease counter
        dec    dword [edi]

        mov    esi,[mousedata]
        mov    edi,esi
        add    esi,1
        mov    ecx,250
        cld
        rep    movsb

        jmp    uusicheckmouse

      checkmouseret:

        cmp    [0xfb44],byte 0
        jne    cmret
        cmp    [0xfb40],byte 0
        je     cmret
        mov    [0xfff4],byte 0
        mov    [0xfff5],byte 0
      cmret:

        popa

        ret


draw_mouse_under:

        ; return old picture

        pusha

        xor    ecx,ecx
        xor    edx,edx

      mres:

        movzx  eax,word [0xfb4a]
        movzx  ebx,word [0xfb4c]

        add    eax,ecx
        add    ebx,edx

        push   ecx
        push   edx
        push   eax
        push   ebx

        mov    eax,edx
        shl    eax,6
        shl    ecx,2
        add    eax,ecx
        add    eax,mouseunder
        mov    ecx,[eax]

        pop    ebx
        pop    eax

        push   edi
        mov    edi,1 ;force
        call   putpixel
        pop    edi

        pop    edx
        pop    ecx

        add    ecx,1
        cmp    ecx,16
        jnz    mres
        xor    ecx,ecx
        add    edx,1
        cmp    edx,24
        jnz    mres

        popa
        ret


save_draw_mouse:

        ; save & draw

        mov    [0xfb4a],ax
        mov    [0xfb4c],bx
        push   eax
        push   ebx
        mov    ecx,0
        mov    edx,0

      drm:

        push   eax
        push   ebx
        push   ecx
        push   edx

        pusha
        add    eax,ecx  ; save picture under mouse
        add    ebx,edx
        push   ecx
        call   getpixel
        mov    [0xfb30],ecx
        pop    ecx
        mov    eax,edx
        shl    eax,6
        shl    ecx,2
        add    eax,ecx
        add    eax,mouseunder
        mov    ebx,[0xfb30]
        mov    [eax],ebx
        popa

        mov    edi,edx           ; y cycle
        shl    edi,4             ; *16 bytes per row
        add    edi,ecx           ; x cycle
        mov    esi, edi
        add    edi, esi
        add    edi, esi          ; *3
        add    edi,[0xf200]      ; we have our str address
        mov    esi, edi
        add    esi, 16*24*3
        push   ecx
        mov    ecx, [0xfb30]
        call   combine_colors
        mov    [0xfb10], ecx
        pop    ecx


        pop    edx
        pop    ecx
        pop    ebx
        pop    eax

        add    eax,ecx       ; we have x coord+cycle
        add    ebx,edx       ; and y coord+cycle

        pusha
        mov    ecx, [0xfb10]
        mov    edi,1
        call   putpixel
        popa

      mnext:

        mov    ebx,[esp+0]      ; pure y coord again
        mov    eax,[esp+4]      ; and x

        add    ecx,1        ; +1 cycle
        cmp    ecx,16       ; if more than 16
        jnz    drm
        mov    ecx,0
        add    edx,1
        cmp    edx,24
        jnz    drm

        pop    ebx
        pop    eax

        ret


disable_mouse:

      pusha

      cmp  [0x3000],dword 1
      je   disable_m

      mov  edx,[0x3000]
      shl  edx,5
      add  edx,window_data

      movzx  eax, word [0xfb0a]
      movzx  ebx, word [0xfb0c]

      mov  ecx,[0xfe00]
      inc  ecx
      imul  ecx,ebx
      add  ecx,eax
      add  ecx,0x400000

      movzx eax, byte [edx+twdw+0xe]

      movzx ebx, byte [ecx]
      cmp   eax,ebx
      je    yes_mouse_disable
      movzx ebx, byte [ecx+16]
      cmp   eax,ebx
      je    yes_mouse_disable

      mov   ebx,[0xfe00]
      inc   ebx
      imul  ebx,10
      add   ecx,ebx

      movzx ebx, byte [ecx]
      cmp   eax,ebx
      je    yes_mouse_disable

      mov   ebx,[0xfe00]
      inc   ebx
      imul  ebx,10
      add   ecx,ebx

      movzx ebx, byte [ecx]
      cmp   eax,ebx
      je    yes_mouse_disable
      movzx ebx, byte [ecx+16]
      cmp   eax,ebx
      je    yes_mouse_disable

      jmp   no_mouse_disable

    yes_mouse_disable:

      mov  edx,[0x3000]
      shl  edx,5
      add  edx,window_data

      movzx  eax, word [0xfb0a]
      movzx  ebx, word [0xfb0c]

      mov  ecx,[edx+0]   ; mouse inside the area ?
      add  eax,14
      cmp  eax,ecx
      jb   no_mouse_disable
      sub  eax,14

      add  ecx,[edx+8]
      cmp  eax,ecx
      jg   no_mouse_disable

      mov  ecx,[edx+4]
      add  ebx,20
      cmp  ebx,ecx
      jb   no_mouse_disable
      sub  ebx,20

      add  ecx,[edx+12]
      cmp  ebx,ecx
      jg   no_mouse_disable

    disable_m:

      cmp  dword [0xf204],dword 0
      jne  nodmu
      call draw_mouse_under
    nodmu:

      mov  [0xf204],dword 1

    no_mouse_disable:

      popa

      ret



draw_pointer:

        pusha

        cmp    dword [0xf204],dword 0  ; mouse visible ?
        je     chms00

        dec    dword [0xf204]

        cmp    [0xf204],dword 0
        jne    nodmu2

        movzx  ebx,word [0xfb0c]
        movzx  eax,word [0xfb0a]
        call   save_draw_mouse

        popa
        ret

      nodmu2:

        popa
        ret

      chms00:

        popa

        pusha

        cmp   [0xf204],dword 0
        jne   nodmp

        movzx  ecx,word [0xfb4a]
        movzx  edx,word [0xfb4c]

        movzx  ebx,word [0xfb0c]
        movzx  eax,word [0xfb0a]

        cmp    eax,ecx
        jne    redrawmouse

        cmp    ebx,edx
        jne    redrawmouse

        jmp    nodmp

      redrawmouse:

        call   draw_mouse_under

        call   save_draw_mouse

     nodmp:

        popa

        ret



calculatebackground:   ; background


        ; all black

        mov   [0x400000-8],dword 4      ; size x
        mov   [0x400000-4],dword 2      ; size y

        mov   edi,0x300000              ; set background to black
        mov   eax,0
        mov   ecx,0x0fff00 / 4
        cld
        rep   stosd

        mov   edi,0x400000              ; set os to use all pixels
        mov   eax,0x01010101
        mov   ecx,0x1fff00 / 4
        cld
        rep   stosd

        ret

imax    dd 0x0



delay_ms:     ; delay in 1/1000 sec


        push  eax
        push  ecx

        mov   ecx,esi

        imul  ecx, 33941
        shr   ecx, 9

        in    al,0x61
        and   al,0x10
        mov   ah,al
        cld

 cnt1:  in    al,0x61
        and   al,0x10
        cmp   al,ah
        jz    cnt1

        mov   ah,al
        loop  cnt1

        pop   ecx
        pop   eax

        ret


set_app_param:

        pusha

        mov  edi,[0x3010]
        mov  [edi],eax

        popa
        ret



delay_hs:     ; delay in 1/100 secs

        push  eax
        push  ecx
        push  edx

        mov   edx,[0xfdf0]
        add   edx,eax

      newtic:
        mov   ecx,[0xfdf0]
        cmp   edx,ecx
        jbe   zerodelay

        call  change_task

        jmp   newtic

      zerodelay:
        pop   edx
        pop   ecx
        pop   eax

        ret


memmove:       ; memory move in bytes

; eax = from
; ebx = to
; ecx = no of bytes

    pusha

    cld

    ; ecx no to move

    mov  esi,eax
    mov  edi,ebx
    rep  movsb

    popa
    ret



random_shaped_window:

;
;  eax = 0    giving address of data area
;      ebx    address
;  ebx = 1    shape area scale
;      ebx    2^ebx scale

     cmp  eax,0
     jne  rsw_no_address
     mov  eax,[0x3000]
     shl  eax,8

     mov  [eax+0x80000+0x80],ebx
   rsw_no_address:

     cmp  eax,1
     jne  rsw_no_scale
     mov  eax,[0x3000]
     shl  eax,8
     mov  [eax+0x80000+0x84],bl
   rsw_no_scale:

     ret


; calculate fat chain

calculatefatchain:

   pusha

   mov  esi,fat_base+512
   mov  edi,fat_table ;0x280000

  fcnew:
   xor  eax,eax
   xor  ebx,ebx
   xor  ecx,ecx
   xor  edx,edx
   mov  al,[esi+0]  ; 1
   mov  bl,[esi+1]
   and  ebx,15
   shl  ebx,8
   add  eax,ebx
   mov  [edi],ax
   add  edi,2

   xor  eax,eax
   xor  ebx,ebx
   xor  ecx,ecx
   xor  edx,edx
   mov  bl,[esi+1]  ; 2
   mov  cl,[esi+2]
   shr  ebx,4
   shl  ecx,4
   add  ecx,ebx
   mov  [edi],cx
   add  edi,2

   add  esi,3

   cmp  edi,fat_table+4100*4 ;0x280000+4100*4
   jnz  fcnew

   popa
   ret


restorefatchain:   ; restore fat chain

   pusha

   mov  esi,fat_table ;0x280000
   mov  edi,fat_base+512

  fcnew2:
   cld
   xor  eax,eax
   xor  ebx,ebx
   xor  ecx,ecx                    ;   esi  XXXXxxxxxxxx  yyyyyyyyYYYY
   xor  edx,edx
   mov  ax,[esi]                   ;   edi  xxxxxxxx YYYYXXXX yyyyyyyy
   mov  bx,ax
   shr  bx,8
   and  ebx,15
   mov  [edi+0],al  ; 1 -> 1 & 2
   mov  [edi+1],bl
   add  esi,2

   xor  eax,eax
   xor  ebx,ebx
   xor  ecx,ecx
   xor  edx,edx
   mov  bx,[esi]
   mov  cx,bx
   shr  ecx,4
   mov  [edi+2],cl
   and  ebx,15
   shl  ebx,4
   mov  edx,[edi+1]
   add  edx,ebx
   mov  [edi+1],dl  ; 2 -> 2 & 3
   add  esi,2

   add  edi,3

   cmp  edi,fat_base+512+0x1200
   jb   fcnew2

   mov  esi,fat_base+512           ; duplicate fat chain
   mov  edi,fat_base+512+0x1200
   mov  ecx,0x1200/4
   cld
   rep  movsd

   popa
   ret


align 4

read_floppy_file:

; as input
;
; eax pointer to file
; ebx file lenght
; ecx start 512 byte block number
; edx number of blocks to read
; esi pointer to return/work area (atleast 20 000 bytes)
;
;
; on return
;
; eax = 0 command succesful
;       1 no fd base and/or partition defined
;       2 yet unsupported FS
;       3 unknown FS
;       4 partition not defined at hd
;       5 file not found
; ebx = size of file

     mov   edi,[0x3010]
     add   edi,0x10
     add   esi,[edi]
     add   eax,[edi]
     pusha

     mov  edi,esi
     add  edi,1024
     mov  esi,fat_base+19*512
     sub  ecx,1
     shl  ecx,9
     add  esi,ecx
     shl  edx,9
     mov  ecx,edx
     cld
     rep  movsb

     popa
     mov   [esp+36],eax
     mov   [esp+24],ebx
     ret




align 4

sys_programirq:

    mov   edi,[0x3010]
    add   edi,0x10
    add   eax,[edi]

    mov   edx,ebx
    shl   edx,2
    add   edx,irq_owner
    mov   edx,[edx]
    mov   edi,[0x3010]
    mov   edi,[edi+0x4]
    cmp   edx,edi
    je    spril1
    mov   [esp+36],dword 1
    ret
  spril1:

    mov   esi,eax
    shl   ebx,6
    add   ebx,irq00read
    mov   edi,ebx
    mov   ecx,16
    cld
    rep   movsd
    mov   [esp+36],dword 0
    ret


align 4

get_irq_data:

     mov   edx,eax           ; check for correct owner
     shl   edx,2
     add   edx,irq_owner
     mov   edx,[edx]
     mov   edi,[0x3010]
     mov   edi,[edi+0x4]
     cmp   edx,edi
     je    gidril1
     mov   [esp+36],eax
     mov   [esp+32],dword 2
     mov   [esp+24],ebx
     ret

  gidril1:

     mov   ebx,eax
     shl   ebx,12
     add   ebx,0x2e0000
     mov   eax,[ebx]
     mov   ecx,1
     test  eax,eax
     jz    gid1

     dec   eax
     mov   esi,ebx
     mov   [ebx],eax
     movzx ebx,byte [ebx+0x10]
     add   esi,0x10
     mov   edi,esi
     inc   esi
     mov   ecx,4000 / 4
     cld
     rep   movsd
     xor   ecx,ecx
   gid1:
     mov   [esp+36],eax
     mov   [esp+32],ecx
     mov   [esp+24],ebx
     ret


set_io_access_rights:

     pusha

     mov   edi,[0x3000]
     imul  edi,tss_step
     add   edi,tss_data
     add   edi,128

     mov   ecx,eax
     and   ecx,7

     shr   eax,3
     add   edi,eax

     mov   ebx,1

     shl   ebx,cl

     cmp   ebp,0                ; enable access - ebp = 0
     jne   siar1

     not   ebx
     and   [edi],byte bl

     popa

     ret

   siar1:

     or    [edi],byte bl        ; disable access - ebp = 1

     popa

     ret





r_f_port_area:

     cmp   eax,0
     je    r_port_area
     jmp   free_port_area

   r_port_area:

     pusha

     cmp   ebx,ecx            ; beginning > end ?
     jg    rpal1
     mov   esi,[0x2d0000]
     cmp   esi,0              ; no reserved areas ?
     je    rpal2
     cmp   esi,255            ; max reserved
     jge   rpal1
   rpal3:
     mov   edi,esi
     shl   edi,4
     add   edi,0x2d0000
     cmp   ebx,[edi+8]
     jg    rpal4
     cmp   ecx,[edi+4]
     jb    rpal4
     jmp   rpal1
   rpal4:

     dec   esi
     jnz   rpal3
     jmp   rpal2
   rpal1:
     popa
     mov   eax,1
     ret

   rpal2:
     popa


     ; enable port access at port IO map

     pusha                        ; start enable io map

     cmp   ecx,65536
     jge   no_unmask_io

     mov   eax,ebx

   new_port_access:

     pusha

     mov   ebp,0                  ; enable - eax = port
     call  set_io_access_rights

     popa

     inc   eax
     cmp   eax,ecx
     jbe   new_port_access

   no_unmask_io:

     popa                         ; end enable io map

     mov   edi,[0x2d0000]
     add   edi,1
     mov   [0x2d0000],edi
     shl   edi,4
     add   edi,0x2d0000
     mov   esi,[0x3010]
     mov   esi,[esi+0x4]
     mov   [edi],esi
     mov   [edi+4],ebx
     mov   [edi+8],ecx

     mov   eax,0
     ret




free_port_area:

     pusha

     mov   esi,[0x2d0000]     ; no reserved areas ?
     cmp   esi,0
     je    frpal2
     mov   edx,[0x3010]
     mov   edx,[edx+4]
   frpal3:
     mov   edi,esi
     shl   edi,4
     add   edi,0x2d0000
     cmp   edx,[edi]
     jne   frpal4
     cmp   ebx,[edi+4]
     jne   frpal4
     cmp   ecx,[edi+8]
     jne   frpal4
     jmp   frpal1
   frpal4:
     dec   esi
     jnz   frpal3
   frpal2:
     popa
     mov   eax,1
     ret
   frpal1:
     mov   ecx,256
     sub   ecx,esi
     shl   ecx,4
     mov   esi,edi
     add   esi,16
     cld
     rep   movsb

     dec   dword [0x2d0000]

     popa


     ; disable port access at port IO map

     pusha                        ; start disable io map

     cmp   ecx,65536
     jge   no_mask_io

     mov   eax,ebx

   new_port_access_disable:

     pusha

     mov   ebp,1                  ; disable - eax = port
     call  set_io_access_rights

     popa

     inc   eax
     cmp   eax,ecx
     jbe   new_port_access_disable

   no_mask_io:

     popa                         ; end disable io map

     mov   eax,0
     ret


reserve_free_irq:

     cmp   eax,0
     jz    reserve_irq

     mov   edi,ebx
     shl   edi,2
     add   edi,irq_owner
     mov   edx,[edi]
     mov   eax,[0x3010]
     mov   eax,[eax+0x4]
     mov   ecx,1
     cmp   edx,eax
     jne   fril1
     mov   [edi],dword 0
     mov   ecx,0
   fril1:
     mov   [esp+36],ecx ; return in eax
     ret

  reserve_irq:

     mov   edi,ebx
     shl   edi,2
     add   edi,irq_owner
     mov   edx,[edi]
     mov   ecx,1
     cmp   edx,0
     jne   ril1

     mov   edx,[0x3010]
     mov   edx,[edx+0x4]
     mov   [edi],edx
     mov   ecx,0

   ril1:

     mov   [esp+36],ecx ; return in eax

     ret



drawbackground:

       cmp   [0xfe0c],word 0x12
       jne   dbrv12
       cmp   [0x400000-12],dword 1
       jne   bgrstr12
       call  vga_drawbackground_tiled
       ret
     bgrstr12:
       call  vga_drawbackground_stretch
       ret
     dbrv12:

       cmp  [0xfe0c],word 0100000000000000b
       jge  dbrv20
       cmp  [0xfe0c],word 0x13
       je   dbrv20
       call  vesa12_drawbackground
       ret
     dbrv20:
       cmp   [0x400000-12],dword 1
       jne   bgrstr
       call  vesa20_drawbackground_tiled
       ret
     bgrstr:
       call  vesa20_drawbackground_stretch
       ret


sys_putimage:

     cmp   [0xfe0c],word 0x12
     jne   spiv20
     call  vga_putimage
     ret
   spiv20:

     cmp   [0xfe0c],word 0100000000000000b
     jge   piv20
     cmp   [0xfe0c],word 0x13
     je    piv20
     call  vesa12_putimage
     ret
   piv20:
     call  vesa20_putimage
     ret



; eax x beginning
; ebx y beginning
; ecx x end
; edx y end
; edi color

drawbar:

     cmp   [0xfe0c],word 0x12
     jne   sdbv20
     call  vga_drawbar
     ret
   sdbv20:

    cmp  [0xfe0c],word 0100000000000000b
    jge  dbv20
    cmp  [0xfe0c],word 0x13
    je   dbv20
    call vesa12_drawbar
    ret

  dbv20:

    call vesa20_drawbar
    ret



smm:  ; system manegement mode

     cli
     mov   ax,0x0003
     int   0x10
     jmp $


_rdtsc:

     mov   edx,[cpuid_1+3*4]
     test  edx,00010000b
     jz    ret_rdtsc
     rdtsc
     ret
   ret_rdtsc:
     mov   edx,0xffffffff
     mov   eax,0xffffffff
     ret



rerouteirqs:

        cli

        mov     al,0x11         ;  icw4, edge triggered
        out     0x20,al
        call    pic_delay
        out     0xA0,al
        call    pic_delay

        mov     al,0x20         ;  generate 0x20 +
        out     0x21,al
        call    pic_delay
        mov     al,0x28         ;  generate 0x28 +
        out     0xA1,al
        call    pic_delay

        mov     al,0x04         ;  slave at irq2
        out     0x21,al
        call    pic_delay
        mov     al,0x02         ;  at irq9
        out     0xA1,al
        call    pic_delay

        mov     al,0x01         ;  8086 mode
        out     0x21,al
        call    pic_delay
        out     0xA1,al
        call    pic_delay

        mov     al,255          ; mask all irq's
        out     0xA1,al
        call    pic_delay
        out     0x21,al
        call    pic_delay

        mov     ecx,0x1000
        cld
picl1:  call    pic_delay
        loop    picl1

        mov     al,255          ; mask all irq's
        out     0xA1,al
        call    pic_delay
        out     0x21,al
        call    pic_delay

        cli

        ret


pic_delay:

        jmp     pdl1
pdl1:   ret


sys_msg_board_str:

     pusha
   sysmsgb2:
     cmp    [esi],byte 0
     je     sysmsgb1
     mov    eax,1
     movzx  ebx,byte [esi]
     call   sys_msg_board
     inc    esi
     jmp    sysmsgb2
   sysmsgb1:
     popa
     ret

msg_board_data: times 512 db 0
msg_board_count dd 0x0

sys_msg_board:

; eax=1 : write :  bl byte to write
; ebx=2 :  read :  ebx=0 -> no data, ebx=1 -> data in al

     mov  ecx,[msg_board_count]
     cmp  eax, 1
     jne  smbl1
     mov  [msg_board_data+ecx],bl
     inc  ecx
     and  ecx, 511
     mov  [msg_board_count], ecx
     mov  [check_idle_semaphore], 5
     ret
   smbl1:

     cmp   eax, 2
     jne   smbl2
     test  ecx, ecx
     jz    smbl21
     mov   edi, msg_board_data
     mov   esi, msg_board_data+1
     movzx eax, byte [edi]
     push  ecx
     shr   ecx, 2
     cld
     rep   movsd
     pop   ecx
     and   ecx, 3
     rep   movsb
     dec   [msg_board_count]
     mov   [esp+36], eax
     mov   [esp+24], dword 1
     ret
   smbl21:
     mov   [esp+36], ecx
     mov   [esp+24], ecx
   smbl2:
     ret





sys_trace:

     cmp  eax,0                     ; get event data
     jne  no_get_sys_events

     mov  esi,save_syscall_data     ; data
     mov  edi,[0x3010]
     mov  edi,[edi+0x10]
     add  edi,ebx
     cld
     rep  movsb

     mov  [esp+24],dword 0
     mov  eax,[save_syscall_count]  ; count
     mov  [esp+36],eax
     ret

   no_get_sys_events:

     ret


sys_process_def:

     cmp   eax,1                   ; set keyboard mode
     jne   no_set_keyboard_setup

     mov   edi,[0x3000]
     imul  edi,256
     add   edi,0x80000+0xB4
     mov   [edi],bl

     ret

   no_set_keyboard_setup:

     cmp   eax,2                   ; get keyboard mode
     jne   no_get_keyboard_setup

     mov   edi,[0x3000]
     imul  edi,256
     add   edi,0x80000+0xB4
     mov   eax,[edi]
     and   eax,0xff

     mov   [esp+36],eax

     ret

   no_get_keyboard_setup:

     cmp   eax,3                   ; get keyboard ctrl, alt, shift
     jne   no_get_keyboard_cas

     xor   eax,eax
     movzx eax,byte [shift]
     movzx ebx,byte [ctrl]
     shl   ebx,2
     add   eax,ebx
     movzx ebx,byte [alt]
     shl   ebx,3
     add   eax,ebx

     mov   [esp+36],eax

     ret

   no_get_keyboard_cas:



     ret


sys_ipc:

     cmp  eax,1                      ; DEFINE IPC MEMORY
     jne  no_ipc_def
     mov  edi,[0x3000]
     shl  edi,8
     add  edi,0x80000
     mov  [edi+0xA0],ebx
     mov  [edi+0xA4],ecx
     mov  [esp+36],dword 0
     ret
   no_ipc_def:

     cmp  eax,2                      ; SEND IPC MESSAGE
     jne  no_ipc_send
     mov  esi,1
     mov  edi,0x3020
    ipcs1:
     cmp  [edi+4],ebx
     je   ipcs2
     add  edi,0x20
     inc  esi
     cmp  esi,[0x3004]
     jbe  ipcs1
     mov  [esp+36],dword 4
     ret
    ipcs2:

     cli

     push esi
     mov  eax,esi
     shl  eax,8
     mov  ebx,[eax+0x80000+0xa0]
     cmp  ebx,0                    ; ipc area not defined ?
     je   ipc_err1

     add  ebx,[eax+0x80000+0xa4]
     mov  eax,esi
     shl  eax,5
     add  ebx,[eax+0x3000+0x10]    ; ebx <- max data position

     mov  eax,esi                  ; to
     shl  esi,8
     add  esi,0x80000
     mov  edi,[esi+0xa0]
     shl  eax,5
     add  eax,0x3000
     add  edi,[eax+0x10]

     cmp  [edi],byte 0             ; overrun ?
     jne  ipc_err2

     mov  ebp,edi
     add  edi,[edi+4]
     add  edi,8

     mov  esi,ecx                  ; from
     mov  eax,[0x3010]
     mov  eax,[eax+0x10]
     add  esi,eax

     mov  ecx,edx                  ; size

     mov  eax,edi
     add  eax,ecx
     cmp  eax,ebx
     jge  ipc_err3                 ; not enough room ?

     push ecx

     mov  eax,[0x3010]
     mov  eax,[eax+4]
     mov  [edi-8],eax
     mov  [edi-4],ecx
     cld
     rep  movsb

     pop  ecx
     add  ecx,8

     mov  edi,ebp                  ; increase memory position
     add  dword [edi+4],ecx

     mov  edi,[esp]
     shl  edi,8
     or   dword [edi+0x80000+0xA8],dword 01000000b ; ipc message

     cmp  [check_idle_semaphore],dword 20
     jge  ipc_no_cis
     mov  [check_idle_semaphore],5
   ipc_no_cis:

     mov  eax,0

    ipc_err:
     add  esp,4
     mov  [esp+36],eax
     sti
     ret

    ipc_err1:
     add  esp,4
     mov  [esp+36],dword 1
     sti
     ret
    ipc_err2:
     add  esp,4
     mov  [esp+36],dword 2
     sti
     ret
    ipc_err3:
     add  esp,4
     mov  [esp+36],dword 3
     sti
     ret

   no_ipc_send:

     mov  [esp+36],dword -1
     ret


align 4

sys_gs:                         ; direct screen access

     cmp  eax,1                 ; resolution
     jne  no_gs1
     mov  eax,[0xfe00]
     shl  eax,16
     mov  ax,[0xfe04]
     add  eax,0x00010001
     mov  [esp+36],eax
     ret
   no_gs1:

     cmp   eax,2                ; bits per pixel
     jne   no_gs2
     movzx eax,byte [0xfbf1]
     mov   [esp+36],eax
     ret
   no_gs2:

     cmp   eax,3                ; bytes per scanline
     jne   no_gs3
     mov   eax,[0xfe08]
     mov   [esp+36],eax
     ret
   no_gs3:

     mov  [esp+36],dword -1
     ret


align 4 ; PCI functions

sys_pci:

     call  pci_api
     mov   [esp+36],eax
     ret


align 4  ;  system functions

syscall_setpixel:                       ; SetPixel


     mov   edx,[0x3010]
     add   eax,[edx-twdw]
     add   ebx,[edx-twdw+4]
     xor   edi,edi ; no force
     call  disable_mouse
     jmp   putpixel

align 4

syscall_writetext:                      ; WriteText

     push  ebx
     cmp   eax , 30*65536
     ja    nolabelcorrection
     cmp   ax , 19
     ja    nolabelcorrection
     and   eax , 0xffff
     add   eax , 20 * 65536
     cmp   edx , -1
     je    nolabelcorrection
     push  edx
     push  edi
     and   ebx,0xff000000
     cmp   ebx,0x01000000
     je    mul4
     imul  edx,3
     jmp   mul3
   mul4:
     imul  edx,4 
   mul3:
     mov   edi,[0x3010]
     mov   ebx,[edi-twdw+8]
     shr   ebx,1
     sub   ebx,edx
     and   ebx,0xffff
     imul  ebx,65536
     and   eax,0xffff
     add   eax,ebx
     pop   edi
     pop   edx
     or    dword [esp],0xffffff ; color to white   
   nolabelcorrection:
     pop   ebx

     mov   edi,[0x3010]
     mov   ebp,[edi-twdw]
     shl   ebp,16
     add   ebp,[edi-twdw+4]
     add   edi,0x10
     add   ecx,[edi]
     cmp   edx,-1
     jne   nozeroterm
     call  return_string_length
   nozeroterm:
     add   eax,ebp
     xor   edi,edi
     jmp   dtext

align 4

syscall_openramdiskfile:                ; OpenRamdiskFile


     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     add   edx,[edi]
     mov   esi,12
     call  fileread
     mov   [esp+36],ebx
     ret

align 4

syscall_putimage:                       ; PutImage

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     mov   edx,ecx
     mov   ecx,ebx
     mov   ebx,eax
     call  sys_putimage
     mov   [esp+36],eax
     ret

align 4

syscall_drawrect:                       ; DrawRect

     push  ebx
     mov   ebx,[0x3000]
     imul  ebx,256
     add   ebx,0x80000
     cmp   [ebx],dword 'FASM'
     jne   nocbgr2
     mov   ebx , ecx
     and   ebx , 0xffffff
     cmp   ebx , 0x2030a0
     jne   nocbgr2
     mov   cl , 0x80
   nocbgr2:
     pop   ebx

     mov   edi,ecx
     test  ax,ax
     je    drectr
     test  bx,bx
     je    drectr
     movzx ecx,ax
     shr   eax,16
     movzx edx,bx
     shr   ebx,16
     add   ecx,eax
     add   edx,ebx
     jmp   drawbar
    drectr:
     ret

align 4

syscall_getscreensize:                  ; GetScreenSize

     movzx eax,word[0xfe00]
     shl   eax,16
     mov   ax,[0xfe04]
     mov   [esp+36],eax
     ret

align 4

syscall_system:                         ; System

     call  sys_system
     mov   [esp+36],eax
     ret

align 4

syscall_startapp:                       ; StartApp

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     test  ebx,ebx
     jz    noapppar
     add   ebx,[edi]
   noapppar:
     call  start_application_fl
     mov   [esp+36],eax
     ret

align 4

syscall_cdaudio:                        ; CD

     call  sys_cd_audio
     mov   [esp+36],eax
     ret

align 4

syscall_readhd:                         ; ReadHd

     mov   edi,[0x3010]
     add   edi,0x10
     add   esi,[edi]
     add   eax,[edi]
     call  read_hd_file
     mov   [esp+36],eax
     mov   [esp+24],ebx
     ret

align 4

syscall_starthdapp:                     ; StartHdApp

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     add   ecx,[edi]
     mov   ebp,0
     call  start_application_hd
     mov   [esp+36],eax
     ret

align 4

syscall_delramdiskfile:                 ; DelRamdiskFile

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     call  filedelete
     mov   [esp+36],eax
     ret

align 4

syscall_writeramdiskfile:               ; WriteRamdiskFile

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     add   ebx,[edi]
     call  filesave
     mov   [esp+36],eax
     ret

align 4

syscall_getpixel:                       ; GetPixel

     mov   ecx,[0xfe00]
     inc   ecx
     xor   edx,edx
     div   ecx
     mov   ebx,edx
     xchg  eax,ebx
     call  dword [0xe024]
     mov   [esp+36],ecx
     ret

align 4

syscall_readstring:                     ; ReadString

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     call  read_string
     mov   [esp+36],eax
     ret

align 4

syscall_drawline:                       ; DrawLine

     mov   edi,[0x3010]
     movzx edx,word[edi-twdw]
     mov   ebp,edx
     shl   edx,16
     add   ebp,edx
     movzx edx,word[edi-twdw+4]
     add   eax,ebp
     mov   ebp,edx
     shl   edx,16
     xor   edi,edi
     add   edx,ebp
     add   ebx,edx
     jmp   draw_line

align 4

syscall_getirqowner:                    ; GetIrqOwner

     shl   eax,2
     add   eax,irq_owner
     mov   eax,[eax]
     mov   [esp+36],eax
     ret

align 4

syscall_reserveportarea:                ; ReservePortArea and FreePortArea

     call  r_f_port_area
     mov   [esp+36],eax
     ret

align 4

syscall_appints:                        ; AppInts

     test  eax,eax
     jnz   unknown_app_int_fn
     mov   edi,[0x3010]
     mov   [edi+draw_data-0x3000+0x1c],ebx
     ret
   unknown_app_int_fn:
     mov   [esp+36],dword -1
     ret

align 4

syscall_threads:                        ; CreateThreads

     call  sys_threads
     mov   [esp+36],eax
     ret

align 4

stack_driver_stat:

     call  app_stack_handler            ; Stack status

;     mov   [check_idle_semaphore],5    ; enable these for zero delay
;     call  change_task                 ; between sent packet

     mov   [esp+36],eax
     ret

align 4

socket:                                 ; Socket interface
     call  app_socket_handler

;     mov   [check_idle_semaphore],5    ; enable these for zero delay
;     call  change_task                 ; between sent packet

     mov   [esp+36],eax
     mov   [esp+24],ebx
     ret

align 4

user_events:                            ; User event times

     mov   eax,0x12345678
     mov   [esp+36],eax

     ret

align 4

read_from_hd:                           ; Read from hd - fn not in use

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     add   ecx,[edi]
     add   edx,[edi]
     call  file_read

     mov   [esp+36],eax
     mov   [esp+24],ebx

     ret


align 4

write_to_hd:                            ; Write a file to hd

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     add   ecx,[edi]
     add   edx,[edi]
     call  file_write
     ret

align 4

delete_from_hd:                         ; Delete a file from hd

     mov   edi,[0x3010]
     add   edi,0x10
     add   eax,[edi]
     add   ecx,[edi]
     call  file_delete
     ret


align 4

undefined_syscall:                      ; Undefined system call

     mov   [esp+36],dword -1
     ret


clear_busy_flag_at_caller:

      push  edi

      mov   edi,[0x3000]    ; restore processes tss pointer in gdt, busyfl?
      imul  edi,8
      mov   [edi+gdts+ tss0 +5], word 01010000b *256 +11101001b

      pop   edi

      ret




keymap:

     db   '6',27
     db   '1234567890-=',8,9
     db   'qwertyuiop[]',13
     db   '~asdfghjkl;',39,96,0,'\zxcvbnm,./',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


keymap_shift:

     db   '6',27
     db   '!@#$%^&*()_+',8,9
     db   'QWERTYUIOP{}',13
     db   '~ASDFGHJKL:"~',0,'|ZXCVBNM<>?',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


keymap_alt:

     db   ' ',27
     db   ' @ $  {[]}\ ',8,9
     db   '            ',13
     db   '             ',0,'           ',0,'4',0,' '
     db   '             ',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'ABCD',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


; device irq owners

irq_owner:       ; process id

     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0
     dd   0x0


; on irq read ports

irq00read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq01read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq02read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq03read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq04read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq05read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq06read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq07read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq08read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq09read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq10read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq11read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq12read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq13read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq14read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
irq15read  dd  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


; status

hd1_status                  dd 0x0  ; 0 - free : other - pid
application_table_status    dd 0x0  ; 0 - free : other - pid

; device addresses

mididp     dd 0x0
midisp     dd 0x0

cdbase     dd 0x0
cdid       dd 0x0

hdbase              dd   0x0  ; for boot 0x1f0
hdid                dd   0x0
hdpos               dd   0x0  ; for boot 0x1
fat32part           dd   0x0  ; for boot 0x1
lba_read_enabled    dd   0x0  ; 0 = disabled , 1 = enabled
pci_access_enabled  dd   0x0  ; 0 = disabled , 1 = enabled

keyboard   dd 0x1

sb16       dd 0x0
wss        dd 0x0
sound_dma  dd 0x1

syslang    dd 0x1

buttontype         dd 0x0
windowtypechanged  dd 0x0

endofcode:  ; -VT






