;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                               ;;
;;  MenuetOS process management, protected ring3                 ;;
;;                                                               ;;
;;  Distributed under GPL. See file COPYING for details.         ;;
;;  Copyright 2003 Ville Turjanmaa                               ;;
;;                                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 4

irq0:

        cmp   [error_interrupt],-1
        je    no_error_in_previous_process

        mov   edi,[error_interrupt]
        imul  edi,8
        mov   [edi+tss0i_l +5], word 01010000b *256 +11101001b

        mov   edi,[error_interrupt]
        imul  edi,128
        add   edi,0x290000
        mov   esi,[error_interrupt_entry]
        mov   [edi+l.eip-tss_sceleton],esi
        mov   [edi+l.eflags-tss_sceleton],dword 0x11002

        mov   [0xffff],byte 0

        mov   [error_interrupt],-1

     no_error_in_previous_process:

        mov    edi,[0x3000]
        imul   edi,8
        mov    [edi+gdts+ tss0 +5], word 01010000b *256 +11101001b

        inc   dword [0xfdf0]

        mov   eax,[0xfdf0]
        cmp   eax,[next_usage_update]
        jb    nocounter
        add   eax,100
        mov   [next_usage_update],eax
        call  updatecputimes
      nocounter:

        mov   edi,[0x3010]

        mov   ebx,[edi+0x18]
        call  _rdtsc
        sub   eax,ebx
        add   eax,[edi+0x14]
        mov   [edi+0x14],eax

        mov   ebx,[0x3000]

        cmp   [0xffff],byte 1
        je    do_not_change_task

      waiting_for_termination:
      waiting_for_reuse:

        add   edi,0x20
        inc   ebx

        cmp   [edi+0xa],byte 3
        je    waiting_for_termination
        cmp   [edi+0xa],byte 4
        je    waiting_for_termination
        cmp   [edi+0xa],byte 9
        je    waiting_for_reuse

        cmp   ebx,[0x3004]
        jbe   nsched0
        mov   ebx,1
        mov   edi,0x3020

      nsched0:

        mov   [0x3000],ebx
        mov   [0x3010],edi

      do_not_change_task:

        call  _rdtsc
        mov   [edi+0x18],eax

        cmp   [0xffff],byte 0
        je    nodecffff
        dec   byte [0xffff]
      nodecffff:

        shl   bx,3
        add   bx,tss0
        mov   [tss_s],bx

        mov   al,0x20
        mov   dx,0x20
        out   dx,al

        db    0xea
tss_t   dd    0
tss_s   dw    tss0t

        jmp   irq0

next_usage_update dd 100

change_task:

        mov   [0xffff],byte 2

        dec   dword [0xfdf0]

        int   0x20

        ret

align 4

; GDT TABLE

gdts:

        dw     gdte-$-1
        dd     gdts
        dw     0

os_code_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +10011010b
        db     0x00

os_data_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +10010010b
        db     0x00

graph_data_l:

        dw     0xff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +11110010b
        db     0x00


ring3_code_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +11111010b
        db     0x00

ring3_data_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +11110010b
        db     0x00



ring2_code_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +11011010b
        db     0x00

ring2_data_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +11010010b
        db     0x00



ring1_code_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +10111010b
        db     0x00

ring1_data_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +10110010b
        db     0x00



int_code_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +10011110b
        db     0x00

int_data_l:

        dw     0xffff
        dw     0x0000
        db     0x00
        dw     11011111b *256 +10010010b
        db     0x00

tss0_l:
      times (max_processes+10) dd 0,0

tss0t_l:
      times (max_processes+10) dd 0,0

tss0i_l:
      times (256+10) dd 0,0

app_code_l:
      times (max_processes+10) dd 0,0

app_data_l:
      times (max_processes+10) dd 0,0

tss0sys_l:
      times (max_processes+10) dd 0,0

gdte:


idts:
      dw  idte-$-1
      dd  idts+8
      dw  0

      times 0x62 dd 0,0

idte:

build_process_gdt_tss_pointer:

        mov    ecx,tss_data
        mov    edi,0
      setgdtl2:
        mov    [edi+gdts+ tss0 +0], word tss_step
        mov    [edi+gdts+ tss0 +2], cx
        mov    eax,ecx
        shr    eax,16
        mov    [edi+gdts+ tss0 +4], al
        mov    [edi+gdts+ tss0 +7], ah
        mov    [edi+gdts+ tss0 +5], word 01010000b *256 +11101001b
        add    ecx,tss_step
        add    edi,8
        cmp    edi,8*(max_processes+5)
        jbe    setgdtl2

        ret

build_process_gdt_gate_pointer:

        mov    edi,0
        mov    dx,tss0
      setidtl1:
        mov    ecx,[esi]
        mov    [edi+gdts+ tss0t +0], word 0
        mov    [edi+gdts+ tss0t +2], dx
        mov    [edi+gdts+ tss0t +4], word 11100101b*256
        mov    [edi+gdts+ tss0t +6], word 0
        add    dx,8
        add    edi,8
        cmp    edi,8*(max_processes+5)
        jb     setidtl1

        ret

build_interrupt_table:

        mov  [l.eflags],dword 0x11002
        mov  [l.ss0], int_data
        mov  [l.ss1], ring1_data
        mov  [l.ss2], ring2_data
        mov  [l.esp0], 0x52000
        mov  [l.esp1], 0x53000
        mov  [l.esp2], 0x54000

        mov  eax,cr3
        mov  [l.cr3],eax
        mov  [l.cs],int_code
        mov  [l.ss],int_data
        mov  [l.ds],int_data
        mov  [l.es],int_data
        mov  [l.fs],int_data
        mov  [l.gs],int_data

        mov  eax,sys_int
        mov  [l.esp],0x720000
        mov  edi,0x290000

     newint:
        push edi
        mov  ebx,[eax]
        mov  [l.eip],ebx
        mov  esi,tss_sceleton
        mov  ecx,120/4
        cld
        rep  movsd
        pop  edi

        add  edi,128
        add  [l.esp],1024
        add  eax,4

        cmp  eax,sys_int+4*0x60
        jb   newint

;;

        mov    esi,boot_sched_3_2
        call   boot_log

        mov    ecx,0x290000
        mov    edi,0
      setgdtl2i:
        mov    [edi+gdts+ tss0i +0], word 128
        mov    [edi+gdts+ tss0i +2], cx
        mov    eax,ecx
        shr    eax,16
        mov    [edi+gdts+ tss0i +4], al
        mov    [edi+gdts+ tss0i +7], ah
        mov    [edi+gdts+ tss0i +5], word 01010000b *256 +11101001b
        add    ecx,128
        add    edi,8
        cmp    edi,8*0x60
        jbe    setgdtl2i

;;

        mov    esi,boot_sched_3_3
        call   boot_log

        mov    edi,0
        mov    edx,tss0i
      setidtl2:
        mov    [edi+idts+ 8 +0], word 0
        mov    [edi+idts+ 8 +2], dx
        mov    [edi+idts+ 8 +4], word 10000101b*256
        cmp    edi,0x40*8
        jne    no_sw_int
        mov    [edi+idts+ 8 +4], word 11100101b*256
      no_sw_int:
        mov    [edi+idts+ 8 +6], word 0
        add    edx,8
        add    edi,8

        cmp    edi,8*0x60
        jb     setidtl2

        ret

build_syscall_interrupt_table:

        mov  [l.eflags],dword 0x11002
        mov  [l.ss0], int_data
        mov  [l.ss1], ring1_data
        mov  [l.ss2], ring2_data
        mov  [l.esp0], 0x52000
        mov  [l.esp1], 0x53000
        mov  [l.esp2], 0x54000

        mov  eax,cr3
        mov  [l.cr3],eax
        mov  [l.cs],int_code
        mov  [l.ss],int_data
        mov  [l.ds],int_data
        mov  [l.es],int_data
        mov  [l.fs],int_data
        mov  [l.gs],int_data

        mov  [l.esp],sysint_stack_data
        mov  edi,0x298000

     newint2:
        push edi
        mov  ebx,i40
        mov  [l.eip],ebx
        mov  esi,tss_sceleton
        mov  ecx,120/4
        cld
        rep  movsd
        pop  edi

        add  [l.esp],4096
        add  edi,128
        add  eax,4

        cmp  edi,0x298000+128*(max_processes+5)
        jb   newint2

;;

        mov    ecx,0x298000
        mov    edi,0
      setgdtl2i2:
        mov    [edi+gdts+ tss0sys +0], word 128
        mov    [edi+gdts+ tss0sys +2], cx
        mov    eax,ecx
        shr    eax,16
        mov    [edi+gdts+ tss0sys +4], al
        mov    [edi+gdts+ tss0sys +7], ah
        mov    [edi+gdts+ tss0sys +5], word 01010000b *256 +11101001b
        add    ecx,128
        add    edi,8
        cmp    edi,8*(max_processes+5)
        jbe    setgdtl2i2

;;

        mov    dx,tss0sys
        mov    edi,8*0x40

        mov    [edi+idts+ 8 +0], word 0
        mov    [edi+idts+ 8 +2], dx
        mov    [edi+idts+ 8 +4], word 11100101b*256
        mov    [edi+idts+ 8 +6], word 0

        ret


updatecputimes:

        pusha

        call _rdtsc
        mov  eax,[idleuse]
        mov  [idleusesec],eax
        mov  [idleuse],dword 0
        mov  ecx,[0x3004]
        mov  edi,0x3020
      newupdate:
        mov  ebx,[edi+0x14]
        mov  [edi+0x1c],ebx
        mov  [edi+0x14],dword 0
        add  edi,0x20
        loop newupdate

        popa
        ret


sys_int:

    dd   s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,sa,sb,sc,sd,se,sf

    dd   s10        ,s11        ,i_unknown12,i_unknown13
    dd   i_unknown14,i_unknown15,i_unknown16,i_unknown17
    dd   i_unknown18,i_unknown19,i_unknown1a,i_unknown1b
    dd   i_unknown1c,i_unknown1d,i_unknown1e,i_unknown1f

    dd   irq0  ,irq1  ,p_irq2 ,p_irq3 ,p_irq4 ,p_irq5,p_irq6 ,p_irq7
    dd   p_irq8,p_irq9,p_irq10,p_irq11,p_irq12,irqD  ,p_irq14,p_irq15

    dd   i_unknown30,i_unknown31,i_unknown32,i_unknown33
    dd   i_unknown34,i_unknown35,i_unknown36,i_unknown37
    dd   i_unknown38,i_unknown39,i_unknown3a,i_unknown3b
    dd   i_unknown3c,i_unknown3d,i_unknown3e,i_unknown3f

    dd   i40        ,i_unknown41,i_unknown42,i_unknown43
    dd   i_unknown44,i_unknown45,i_unknown46,i_unknown47
    dd   i_unknown48,i_unknown49,i_unknown4a,i_unknown4b
    dd   i_unknown4c,i_unknown4d,i_unknown4e,i_unknown4f

    dd   i_unknown50,i_unknown51,i_unknown52,i_unknown53
    dd   i_unknown54,i_unknown55,i_unknown56,i_unknown57
    dd   i_unknown58,i_unknown59,i_unknown5a,i_unknown5b
    dd   i_unknown5c,i_unknown5d,i_unknown5e,i_unknown5f

    dd   i_unknown60,i_unknown61,i_unknown62,i_unknown63
    dd   i_unknown64,i_unknown65,i_unknown66,i_unknown67
    dd   i_unknown68,i_unknown69,i_unknown6a,i_unknown6b
    dd   i_unknown6c,i_unknown6d,i_unknown6e,i_unknown6f

    dd   i_unknown70,i_unknown71,i_unknown72,i_unknown73
    dd   i_unknown74,i_unknown75,i_unknown76,i_unknown77
    dd   i_unknown78,i_unknown79,i_unknown7a,i_unknown7b
    dd   i_unknown7c,i_unknown7d,i_unknown7e,i_unknown7f

    dd   i_unknown80,i_unknown81,i_unknown82,i_unknown83
    dd   i_unknown84,i_unknown85,i_unknown86,i_unknown87
    dd   i_unknown88,i_unknown89,i_unknown8a,i_unknown8b
    dd   i_unknown8c,i_unknown8d,i_unknown8e,i_unknown8f

    dd   i_unknown90,i_unknown91,i_unknown92,i_unknown93
    dd   i_unknown94,i_unknown95,i_unknown96,i_unknown97
    dd   i_unknown98,i_unknown99,i_unknown9a,i_unknown9b
    dd   i_unknown9c,i_unknown9d,i_unknown9e,i_unknown9f

    dd   i_unknowna0,i_unknowna1,i_unknowna2,i_unknowna3
    dd   i_unknowna4,i_unknowna5,i_unknowna6,i_unknowna7
    dd   i_unknowna8,i_unknowna9,i_unknownaa,i_unknownab
    dd   i_unknownac,i_unknownad,i_unknownae,i_unknownaf

    dd   i_unknownb0,i_unknownb1,i_unknownb2,i_unknownb3
    dd   i_unknownb4,i_unknownb5,i_unknownb6,i_unknownb7
    dd   i_unknownb8,i_unknownb9,i_unknownba,i_unknownbb
    dd   i_unknownbc,i_unknownbd,i_unknownbe,i_unknownbf

    dd   i_unknownc0,i_unknownc1,i_unknownc2,i_unknownc3
    dd   i_unknownc4,i_unknownc5,i_unknownc6,i_unknownc7
    dd   i_unknownc8,i_unknownc9,i_unknownca,i_unknowncb
    dd   i_unknowncc,i_unknowncd,i_unknownce,i_unknowncf

    dd   i_unknownd0,i_unknownd1,i_unknownd2,i_unknownd3
    dd   i_unknownd4,i_unknownd5,i_unknownd6,i_unknownd7
    dd   i_unknownd8,i_unknownd9,i_unknownda,i_unknowndb
    dd   i_unknowndc,i_unknowndd,i_unknownde,i_unknowndf

    dd   i_unknowne0,i_unknowne1,i_unknowne2,i_unknowne3
    dd   i_unknowne4,i_unknowne5,i_unknowne6,i_unknowne7
    dd   i_unknowne8,i_unknowne9,i_unknownea,i_unknowneb
    dd   i_unknownec,i_unknowned,i_unknownee,i_unknownef

    dd   i_unknownf0,i_unknownf1,i_unknownf2,i_unknownf3
    dd   i_unknownf4,i_unknownf5,i_unknownf6,i_unknownf7
    dd   i_unknownf8,i_unknownf9,i_unknownfa,i_unknownfb
    dd   i_unknownfc,i_unknownfd,i_unknownfe,i_unknownff


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                            ;;
;;                   SYSTEM CALL ENTRY                        ;;
;;                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 4

i40:

      cli

      mov    edi,[0x3000]
      imul   edi,8
      mov    [edi+gdts+ tss0 +5], word 01010000b *256 +11101001b

      mov    eax,[schd]
      mov    [usedi40+eax],byte 1
      push   eax

      mov    edi,[0x3000]
      imul   edi,256
      mov    [edi+0x80000+0xB0],eax

      mov    eax,1  ; search from 1 ( 0 reserved for 'not used' in app )
    search_free_i40:
      cmp    [usedi40+eax],byte 0
      je     found_free_i40
      inc    eax
      cmp    eax,max_processes+10
      jbe    search_free_i40
      jmp    $
    found_free_i40:

      mov    [schd],eax

      mov    edx,8
      imul   edx,[schd]
      add    edx,tss0sys
      mov    edi,8*0x40

      mov    [edi+idts+ 8 +0], word 0
      mov    [edi+idts+ 8 +2], dx
      mov    [edi+idts+ 8 +4], word 11100101b*256
      mov    [edi+idts+ 8 +6], word 0

      mov   ebx,[0x3000]
      shl   ebx,3
      add   ebx,tss0_l

      mov   ecx,[0x3000]
      shl   ecx,2

      mov   eax,[0x3000]
      mov   [tasknum+ecx],eax

      mov   eax,[ebx]
      mov   [reg1+ecx],eax
      mov   eax,[ebx+4]
      mov   [reg2+ecx],eax

      mov   ecx,8
      imul  ecx,[esp]
      mov   eax,[tss0sys_l+ecx]
      mov   [ebx],eax
      mov   eax,[tss0sys_l+ecx+4]
      mov   [ebx+4],eax

      call  save_registers

      mov   esi,[0x3000]
      imul  esi,tss_step
      add   esi,tss_data

      mov   eax,[esi+l.eax-tss_sceleton]
      mov   ebx,[esi+l.ebx-tss_sceleton]
      mov   ecx,[esi+l.ecx-tss_sceleton]

      pusha

      mov   edi,[esi+l.eax-tss_sceleton]
      mov   eax,[esi+l.ebx-tss_sceleton]
      mov   ebx,[esi+l.ecx-tss_sceleton]
      mov   ecx,[esi+l.edx-tss_sceleton]
      mov   edx,[esi+l.esi-tss_sceleton]
      mov   esi,[esi+l.edi-tss_sceleton]

      sti
      push   eax
      and    edi,0xff
      call   dword [servetable+edi*4]
      pop    eax
      cli

      popa

      mov   esi,[0x3000]
      imul  esi,tss_step
      add   esi,tss_data

      mov   [esi+l.eax-tss_sceleton],eax
      mov   [esi+l.ebx-tss_sceleton],ebx
      mov   [esi+l.ecx-tss_sceleton],ecx

      mov   ebx,[0x3000]
      shl   ebx,3
      add   ebx,tss0_l

      mov   ecx,[0x3000]
      shl   ecx,2

      mov   eax,[reg1+ecx]
      mov   [ebx],eax
      mov   eax,[reg2+ecx]
      mov   [ebx+4],eax

      mov    edi,[0x3000]          ; no syscall interrupt in use anymore
      imul   edi,256
      mov    [edi+0x80000+0xB0],eax

      mov   [tasknum+ecx],dword 0

      mov    edi,8
      pop    eax        ; this handler
      mov    [usedi40+eax],byte 0
      imul   edi,eax
      mov    [edi+tss0sys_l +5], word 01010000b *256 +11101001b

      mov   ebx,[0x3000]
      shl   bx,3
      add   bx,tss0t
      mov   [tss_s3],bx

        db    0xea
tss_t3  dd    0
tss_s3  dw    tss0t

      jmp    i40

tasknum:    times (max_processes+10) dd 0,0
reg1:       times (max_processes+10) dd 0,0
reg2:       times (max_processes+10) dd 0,0
usedi40:    times (max_processes+10) db 0,0
schd                  dd 0x0

save_registers:

      mov   esi,[0x3000]
      imul  esi,tss_step
      add   esi,tss_data

      mov   eax,[esi+l.eax-tss_sceleton]
      mov   ebx,[esi+l.ebx-tss_sceleton]
      mov   ecx,[esi+l.ecx-tss_sceleton]
      mov   edx,[esi+l.edx-tss_sceleton]
      mov   edi,[esi+l.edi-tss_sceleton]
      mov   ebp,[esi+l.ebp-tss_sceleton]

      mov   esi,[esi+l.esi-tss_sceleton]

      pusha
      mov   esi,[0x3010]
      mov   eax,[esi+0x4]
      mov   esi,esp
      inc   [save_syscall_count]
      mov   edi,[save_syscall_count]
      and   edi,15
      shl   edi,6
      add   edi,save_syscall_data+32
      mov   [edi-32],eax
      mov   ecx,32 / 4
      cld
      rep   movsd
      popa
      ret

save_syscall_count                dd 0x0
save_syscall_data: times 64*16    dd 0x0

align 4

servetable:

      dd sys_drawwindow          ; 0-DrawWindow
      dd syscall_setpixel        ; 1-SetPixel
      dd sys_getkey              ; 2-GetKey
      dd sys_clock               ; 3-GetTime
      dd syscall_writetext       ; 4-WriteText
      dd delay_hs                ; 5-DelayHs
      dd syscall_openramdiskfile ; 6-OpenRamdiskFile
      dd syscall_putimage        ; 7-PutImage
      dd sys_button              ; 8-DefineButton
      dd sys_cpuusage            ; 9-GetProcessInfo
      dd sys_waitforevent        ; 10-WaitForEvent
      dd sys_getevent            ; 11-CheckForEvent
      dd sys_redrawstat          ; 12-BeginDraw and EndDraw
      dd syscall_drawrect        ; 13-DrawRect
      dd syscall_getscreensize   ; 14-GetScreenSize
      dd sys_background          ; 15-bgr
      dd sys_cachetodiskette     ; 16-FlushFloppyCache
      dd sys_getbutton           ; 17-GetButton
      dd syscall_system          ; 18-Shutdown,KillApp,WindowActivate
      dd syscall_startapp        ; 19-StartApp
      dd sys_midi                ; 20-ResetMidi and OutputMidi
      dd sys_setup               ; 21-SetMidiBase,SetKeymap,SetShiftKeymap,.
      dd undefined_syscall       ; 22-not used
      dd sys_wait_event_timeout  ; 23-TimeOutWaitForEvent
      dd syscall_cdaudio         ; 24-PlayCdTrack,StopCd and GetCdPlaylist
      dd sys_sb16                ; 25-SetSb16
      dd sys_getsetup            ; 26-GetMidiBase,GetKeymap,GetShiftKeymap,.
      dd sys_wss                 ; 27-SetWssMainVol and SetWssCdVol
      dd sys_sb16II              ; 28-SetSb16
      dd sys_date                ; 29-GetDate
      dd syscall_readhd          ; 30-ReadHd
      dd syscall_starthdapp      ; 31-StartHdApp
      dd syscall_delramdiskfile  ; 32-DelRamdiskFile
      dd syscall_writeramdiskfile; 33-WriteRamdiskFile
      dd read_floppy_file        ; 34-ReadFloppyDrive
      dd syscall_getpixel        ; 35-GetPixel
      dd syscall_readstring      ; 36-ReadString (not yet ready)
      dd readmousepos            ; 37-GetMousePosition_ScreenRelative,.
      dd syscall_drawline        ; 38-DrawLine
      dd sys_getbackground       ; 39-GetBackgroundSize,ReadBgrData,.
      dd set_app_param           ; 40-WantEvents
      dd syscall_getirqowner     ; 41-GetIrqOwner
      dd get_irq_data            ; 42-ReadIrqData
      dd sys_outport             ; 43-SendDeviceData
      dd sys_programirq          ; 44-ProgramIrqs
      dd reserve_free_irq        ; 45-ReserveIrq and FreeIrq
      dd syscall_reserveportarea ; 46-ReservePortArea and FreePortArea
      dd display_number          ; 47-WriteNum
      dd display_settings        ; 48-SetRedrawType and SetButtonType
      dd syscall_appints         ; 49-AppInts
      dd random_shaped_window    ; 50-Window shape & scale
      dd syscall_threads         ; 51-Threads
      dd stack_driver_stat       ; 52-Stack driver status
      dd socket                  ; 53-Socket interface
      dd user_events             ; 54-User events
      dd sound_interface         ; 55-Sound interface
      dd write_to_hd             ; 56-Write a file to hd
      dd delete_from_hd          ; 57-Delete a file from hd
      dd file_system             ; 58-Common file system interface
      dd sys_trace               ; 59-System call trace
      dd sys_ipc                 ; 60-Inter Process Communication
      dd sys_gs                  ; 61-Direct graphics access
      dd sys_pci                 ; 62-PCI functions
      dd sys_msg_board           ; 63-System message board
      dd sys_resize_app_memory   ; 64-Resize application memory usage
      dd undefined_syscall       ; 65-UTF
      dd sys_process_def         ; 66-Process definitions - keyboard
      dd sys_window_move         ; 67-Window move or resize

      times (113-67-1) dd undefined_syscall

      dd sys_scroll              ; 113-Srolls

      times 255 - ( ($-servetable) /4 )  dd undefined_syscall

      dd sys_end                 ; -1-end application

tss_sceleton:

l.back   dw 0,0
l.esp0   dd 0
l.ss0    dw 0,0
l.esp1   dd 0
l.ss1    dw 0,0
l.esp2   dd 0
l.ss2    dw 0,0
l.cr3    dd 0
l.eip    dd 0
l.eflags dd 0
l.eax    dd 0
l.ecx    dd 0
l.edx    dd 0
l.ebx    dd 0
l.esp    dd 0
l.ebp    dd 0
l.esi    dd 0
l.edi    dd 0
l.es     dw 0,0
l.cs     dw 0,0
l.ss     dw 0,0
l.ds     dw 0,0
l.fs     dw 0,0
l.gs     dw 0,0
l.ldt    dw 0,0
l.trap   dw 0
l.io     dw 0

s0:
        cli

        mov   [error_interrupt],0x0
        mov   [error_interrupt_entry],dword s0

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task


s1:
        cli

        mov   [error_interrupt],0x1
        mov   [error_interrupt_entry],dword s1

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

s2:
        cli

        mov   [error_interrupt],0x2
        mov   [error_interrupt_entry],dword s2

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

s3:
        cli

        mov   [error_interrupt],0x3
        mov   [error_interrupt_entry],dword s3

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

s4:
        cli

        mov   [error_interrupt],0x4
        mov   [error_interrupt_entry],dword s4

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

s5:
        cli

        mov   [error_interrupt],0x5
        mov   [error_interrupt_entry],dword s5

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

s6:
        cli

        mov   [error_interrupt],0x6
        mov   [error_interrupt_entry],dword s6

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task


prev_user_of_fpu dd 0x1 ; set to OS

s7:
        mov    edi,7
        imul   edi,8
        mov    [edi+gdts+ tss0i +5], word 01010000b *256 +11101001b

        mov    edi,[0x3000]
        imul   edi,8
        mov    [edi+gdts+ tss0 +5], word 01010000b *256 +11101001b

        mov   esi,[0x3000]
        imul  esi,tss_step
        add   esi,tss_data
        mov   edi,fpu_tss
        mov   ecx,120
        cld
        rep   movsb

        mov   esi,[0x3000]
        imul  esi,tss_step
        add   esi,tss_data

        mov   word [esi+l.cs-tss_sceleton],int_code
        mov   word [esi+l.ss-tss_sceleton],int_data
        mov   word [esi+l.ds-tss_sceleton],int_data
        mov   word [esi+l.es-tss_sceleton],int_data
        mov   word [esi+l.fs-tss_sceleton],int_data
        mov   word [esi+l.gs-tss_sceleton],int_data
        mov   dword [esi+l.esp-tss_sceleton],fpu_stack+4*8
        mov   dword [esi+l.eip-tss_sceleton],fpu_handler
        mov   dword [esi+l.eflags-tss_sceleton],0x11002

        mov     ebx,[0x3000]
        shl     bx,3
        add     bx,tss0t
        mov     [tss_s7],bx

        db    0xea
        dd    0
tss_s7  dw    tss0t

        jmp    s7

fpu_tss:  times 128 db 0

fpu_handler:

        clts

        mov    eax,[prev_user_of_fpu]
        shl    eax,8
        add    eax,0x80000+0x10
        fsave  [eax]

        mov    eax,[0x3000]
        mov    [prev_user_of_fpu],eax
        shl    eax,8
        add    eax,0x80000
        cmp    [eax+0x7f],byte 0
        je     bs7_first_fpu
        frstor [eax+0x10]
      bs7_first_fpu:
        mov    [eax+0x7f],byte 1

        movzx  eax,word [fpu_tss+l.ss-tss_sceleton]  ; push ss
        push   eax
        mov    eax,[fpu_tss+l.esp-tss_sceleton]      ; push esp
        push   eax
        mov    eax,[fpu_tss+l.eflags-tss_sceleton]   ; push eflags
        push   eax

        movzx  eax,word [fpu_tss+l.cs-tss_sceleton]  ; push cs
        push   eax
        mov    eax,[fpu_tss+l.eip-tss_sceleton]      ; push eip
        push   eax

        push   dword [fpu_tss+l.eax-tss_sceleton]

        mov    ax,[fpu_tss+l.es-tss_sceleton]
        mov    es,ax
        mov    ax,[fpu_tss+l.fs-tss_sceleton]
        mov    fs,ax
        mov    ax,[fpu_tss+l.gs-tss_sceleton]
        mov    gs,ax
        mov    ax,[fpu_tss+l.ds-tss_sceleton]
        mov    ds,ax

        pop    eax

        iret

fpu_stack: times 10*4 db 0

s8:
        cli

        mov   [error_interrupt],0x8
        mov   [error_interrupt_entry],dword s8

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

s9:
        cli

        mov   [error_interrupt],0x9
        mov   [error_interrupt_entry],dword s9

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

sa:
        cli

        mov   [error_interrupt],0xa
        mov   [error_interrupt_entry],dword sa

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

sb:
        cli

        mov   [error_interrupt],0xb
        mov   [error_interrupt_entry],dword sb

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

sc:
        cli

        mov   [error_interrupt],0xc
        mov   [error_interrupt_entry],dword sc

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

sd:
        cli

        mov   [error_interrupt],0xd
        mov   [error_interrupt_entry],dword sd

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

se:
        cli

        mov   [error_interrupt],0xe
        mov   [error_interrupt_entry],dword se

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

sf:
        cli

        mov   [error_interrupt],0xf
        mov   [error_interrupt_entry],dword sf

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

s10:
        cli

        mov   [error_interrupt],0x10
        mov   [error_interrupt_entry],dword s10

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

s11:
        cli

        mov   [error_interrupt],0x11
        mov   [error_interrupt_entry],dword s11

        call  show_error_parameters

        mov   edx,[0x3010]
        mov   [edx+0xa],byte 4

        jmp   change_task

writehex:

      pusha

      mov  ecx,eax
      mov  ax,word [printerrorat]
      shl  eax,16
      mov  ax,[esp+32+4]
      sub  ax,60
      mov  edx,1
      mov  esi,8
      mov  ebx,0xffffff
    whl1:
      push ecx
      and  ecx,0xf
      add  ecx,hexletters
      mov  edi,1

      mov  cl,[ecx]
      mov  edi,[write_error_to]
      mov  [edi],cl
      dec  [write_error_to]

      pop  ecx
      shr  ecx,4
      sub  eax,6*65536
      dec  esi
      jnz  whl1

      popa
      ret


hexletters  db '0123456789ABCDEF'

error_interrupt         dd  -1
error_interrupt_entry   dd  -1

printerrorat            dd 300

process_error  db 'Kernel : Process - Forced terminate INT: 00000000',13,10,0
process_pid    db 'Kernel : Process - Forced terminate PID: 00000000',13,10,0
process_eip    db 'Kernel : Process - Forced terminate EIP: 00000000',13,10,0

write_error_to  dd  0x0

show_error_parameters:

        mov    [write_error_to],process_pid+48
        mov    eax,[0x3000]
        imul   eax,0x20
        mov    eax,[0x3000+4+eax]
        call   writehex

        mov    [write_error_to],process_error+48
        mov    eax,[error_interrupt]
        call   writehex

        mov    eax,[0x3000]
        imul   eax,tss_step
        mov    eax,[eax+tss_data+l.eip-tss_sceleton]
        mov    [write_error_to],process_eip+48
        call   writehex

        mov    esi,process_error
        call   sys_msg_board_str

        mov    esi,process_pid
        call   sys_msg_board_str

        mov    esi,process_eip
        call   sys_msg_board_str

        ret

keyboard_mode db 0
keyboard_data db 0

irq1:

        call  restore_caller

        xor   eax,eax
        mov   dx,0x60
        in    al,dx

        mov   [keyboard_data],al

        movzx edi,word [0x3004]  ; top window process
        shl   edi,1
        add   edi,0xc400
        movzx edi,word [edi]
        imul  edi,256
        add   edi,0x800B4
        mov   edx,[edi]

        mov   [keyboard_mode],dl

        cmp   al,29             ; CTRL
        jne   noctrlon
        mov   [ctrl],byte 1
        jmp   nokey
      noctrlon:

        cmp   al,29+128
        jne   noctrloff
        mov   [ctrl],byte 0
        jmp   nokey
      noctrloff:

        cmp   al,56             ; ALT
        jnz   noalton1
        mov   [alt],byte 1
        jmp   nokey
      noalton1:

        cmp   al,184
        jnz   noaltoff1
        mov   [alt],byte 0
        jmp   nokey
      noaltoff1:

        cmp   al,42             ; SHIFT
        jnz   noshifton1
        or    byte [shift],byte 1
        jmp   nokey
      noshifton1:
        cmp   al,54
        jnz   noshifton2
        or    byte [shift],byte 2
        jmp   nokey
      noshifton2:

        cmp   al,42+128
        jnz   noshiftoff1
        and   byte [shift],byte 2
        jmp   nokey
      noshiftoff1:
        cmp   al,54+128
        jnz   noshiftoff2
        and   byte [shift],byte 1
        jmp   nokey
      noshiftoff2:

        cmp   al,byte 128
        jb    yeskey
        jmp   nokey

      yeskey:

        mov   ecx,eax              ; plain key
        add   ecx,keymap
        mov   bl,[ecx]

        cmp   [alt],1             ; ctrl alt del
        jne   noctrlaltdel
        cmp   [ctrl],1
        jne   noctrlaltdel
        cmp   bl,134+48
        jne   noctrlaltdel
        mov   [ctrl_alt_del],1
        jmp   nokey

      ctrl_alt_del db 0

      noctrlaltdel:

        cmp   [ctrl],byte 1        ; ctrl on ?
        jne   nco
        sub   bl,96
      nco:

        cmp   [shift],byte 0       ; shift on ?
        je    nso
        mov   ecx,eax
        add   ecx,keymap_shift
        mov   bl,[ecx]
      nso:

        cmp   [alt],byte 1         ; alt on ?
        jz    yao
        jmp   nao
      yao:
        mov   ecx,eax
        add   ecx,keymap_alt
        mov   bl,[ecx]

        ; alt mouse ?

        xor   edx,edx
        cmp   bl,178
        jnz   noaltup
        mov   edx,5*65536
        mov   bl,255
      noaltup:
        cmp   bl,177
        jnz   noaltdown
        mov   edx,251*65536
        mov   bl,255
      noaltdown:
        cmp   bl,176
        jnz   noaltleft
        mov   edx,251*256
        mov   bl,255
      noaltleft:
        cmp   bl,179
        jnz   noaltright
        mov   edx,5*256
        mov   bl,255
      noaltright:
        cmp   bl,' '
        jnz   noaltmbd
        mov   bl,[altmouseb]
        add   bl,1
        and   bl,1
        mov   [altmouseb],bl
        mov   bl,255
      noaltmbd:
        cmp   bl,255
        jnz   nao
        mov   [0xF604],byte 1 ; ps2 data
        mov   [0xfb00],byte 0 ; ps2 chunk count
        mov   [0x2E0000+4096*12],word 3 ; mouse data count
        movzx ebx,byte [altmouseb]
        or    edx,ebx
        mov   [0x2E0000+4096*12+0x10],edx
        mov   bl,0
      nao:

        cmp   [keyboard_mode],0  ; return from keymap
        jne   nokey

        cmp   bl,0
        jz    nokey

        movzx edx,byte [0xf400]
        cmp   edx,120
        jge   nokey
        inc   edx
        mov   [0xf400],dl
        mov   [0xf400+edx],bl

      nokey:

        cmp   [keyboard_mode],1  ; return scancode
        jne   no_scancode

        movzx edx,byte [0xf400]
        cmp   edx,120
        jge   no_scancode

        inc   edx
        mov   [0xf400],dl

        mov   al,[keyboard_data]
        mov   [0xf400+edx],al

      no_scancode:


        mov   [check_idle_semaphore],5

        mov   al,0x20                   ; ready for next irq
        mov   dx,0x20
        out   dx,al

        call  return_to_caller

        jmp   irq1


shift      db  0x0
ctrl       db  0x0
alt        db  0x0
altgr      db  0x0
altmouseb  db  0x0

irq5:

     call   restore_caller

     mov    dx,word [sb16]
     add    dx,0xe
     in     al,dx

;     mov    byte [SB16_Status],0

     mov    [check_idle_semaphore],5

     mov    al,0x20
     out    0x20,al

     call  return_to_caller

     jmp   irq5

irqD:

     call   restore_caller

     mov   dx,0xf0
     mov   al,0
     out   dx,al

     mov   dx,0xa0
     mov   al,0x20
     out   dx,al
     mov   dx,0x20
     out   dx,al

     mov   ds,cx
     mov   es,cx
     mov   fs,cx

     call  return_to_caller

     jmp   irqD

p_irq2:

     call  restore_caller

     mov   edi,2               ; 1
     call  irqhandler          ; 2/5

     call  return_to_caller

     jmp   p_irq2

p_irq3:

     call  restore_caller

     mov   edi,3
     call  irqhandler

     call  return_to_caller

     jmp   p_irq3

p_irq4:

     call  restore_caller

     mov   edi,4
     call  irqhandler

     call  return_to_caller

     jmp   p_irq4

p_irq5:

     call  restore_caller

     mov   edi,5
     call  irqhandler

     call  return_to_caller

     jmp   p_irq5

p_irq6:

     call  restore_caller

     call  fdc_irq

     mov   edi,6
     call  irqhandler

     call  return_to_caller

     jmp   p_irq6

p_irq7:

     call  restore_caller

     mov   edi,7
     call  irqhandler

     call  return_to_caller

     jmp   p_irq7

p_irq8:

     call  restore_caller

     mov   edi,8
     call  irqhandler

     call  return_to_caller

     jmp   p_irq8

p_irq9:

     call  restore_caller

     mov   edi,9
     call  irqhandler

     call  return_to_caller

     jmp   p_irq9

p_irq10:

     call  restore_caller

     mov   edi,10
     call  irqhandler

     call  return_to_caller

     jmp   p_irq10

p_irq11:

     call  restore_caller

     mov   edi,11
     call  irqhandler

     call  return_to_caller

     jmp   p_irq11

p_irq12:

      call  restore_caller

      mov   edi,12
      call  irqhandler

      call  return_to_caller

      jmp   p_irq12

p_irq13:

     call  restore_caller

     mov   edi,13
     call  irqhandler

     call  return_to_caller

     jmp   p_irq13

p_irq14:

     call  restore_caller

     mov   edi,14
     call  irqhandler

     call  return_to_caller

     jmp   p_irq14

p_irq15:

     call  restore_caller

     mov   edi,15
     call  irqhandler

     call  return_to_caller

     jmp   p_irq15


restore_caller:

      mov    edi,[0x3000]
      imul   edi,8
      mov    [edi+gdts+ tss0 +5], word 01010000b *256 +11101001b

      ret

return_to_caller:

      mov   ebx,[0x3000]
      shl   bx,3
      add   bx,tss0t
      mov   [tss_irq12],bx

           db    0xea
           dd    0
tss_irq12  dw    tss0t

           ret

irqh dd 0x0

irqhandler:

     push   edi

     mov    esi,edi          ; 1
     shl    esi,6            ; 1
     add    esi,irq00read    ; 1
     shl    edi,12           ; 1
     add    edi,0x2E0000

     mov    [check_idle_semaphore],5

   irqnewread:

     mov    dx,[esi]         ; 2+

     cmp    dx,0             ; 1
     jz     irqover
     cmp    [esi+3],byte 1   ; 2     ; byte read
     jne    noirqbyte        ; 4-11

     in     al,dx

     mov    edx,[edi]
     cmp    edx,4000
     je     irqfull
     mov    ebx,edi
     add    ebx,0x10
     add    ebx,edx
     mov    [ebx],al
     add    edx,1
     mov    [edi],edx

     add    esi,4
     jmp    irqnewread

   noirqbyte:


     cmp    [esi+3],byte 2     ; word read
     jne    noirqword

     in     ax,dx

     mov    edx,[edi]
     cmp    edx,4000
     je     irqfull
     mov    ebx,edi
     add    ebx,0x10
     add    ebx,edx
     mov    [ebx],ax
     add    edx,2
     mov    [edi],edx
     add    esi,4
     jmp    irqnewread

   noirqword:
   irqfull:
   irqover:

     mov    al,0x20            ; ready for next irq
     out    0x20,al

     pop    ebx
     cmp    ebx,7
     jbe    noa0
     out    0xa0,al
   noa0:

     ret

i_unknown10:
        push  dword $
        jmp   i_u_errorhandle
i_unknown11:
        push  dword $
        jmp   i_u_errorhandle
i_unknown12:
        push  dword $
        jmp   i_u_errorhandle
i_unknown13:
        push  dword $
        jmp   i_u_errorhandle
i_unknown14:
        push  dword $
        jmp   i_u_errorhandle
i_unknown15:
        push  dword $
        jmp   i_u_errorhandle
i_unknown16:
        push  dword $
        jmp   i_u_errorhandle
i_unknown17:
        push  dword $
        jmp   i_u_errorhandle
i_unknown18:
        push  dword $
        jmp   i_u_errorhandle
i_unknown19:
        push  dword $
        jmp   i_u_errorhandle
i_unknown1a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown1b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown1c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown1d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown1e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown1f:
        push  dword $
        jmp   i_u_errorhandle


i_unknown20:
        push  dword $
        jmp   i_u_errorhandle
i_unknown21:
        push  dword $
        jmp   i_u_errorhandle
i_unknown22:
        push  dword $
        jmp   i_u_errorhandle
i_unknown23:
        push  dword $
        jmp   i_u_errorhandle
i_unknown24:
        push  dword $
        jmp   i_u_errorhandle
i_unknown25:
        push  dword $
        jmp   i_u_errorhandle
i_unknown26:
        push  dword $
        jmp   i_u_errorhandle
i_unknown27:
        push  dword $
        jmp   i_u_errorhandle
i_unknown28:
        push  dword $
        jmp   i_u_errorhandle
i_unknown29:
        push  dword $
        jmp   i_u_errorhandle
i_unknown2a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown2b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown2c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown2d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown2e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown2f:
        push  dword $
        jmp   i_u_errorhandle


i_unknown30:
        push  dword $
        jmp   i_u_errorhandle
i_unknown31:
        push  dword $
        jmp   i_u_errorhandle
i_unknown32:
        push  dword $
        jmp   i_u_errorhandle
i_unknown33:
        push  dword $
        jmp   i_u_errorhandle
i_unknown34:
        push  dword $
        jmp   i_u_errorhandle
i_unknown35:
        push  dword $
        jmp   i_u_errorhandle
i_unknown36:
        push  dword $
        jmp   i_u_errorhandle
i_unknown37:
        push  dword $
        jmp   i_u_errorhandle
i_unknown38:
        push  dword $
        jmp   i_u_errorhandle
i_unknown39:
        push  dword $
        jmp   i_u_errorhandle
i_unknown3a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown3b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown3c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown3d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown3e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown3f:
        push  dword $
        jmp   i_u_errorhandle


i_unknown40:
        push  dword $
        jmp   i_u_errorhandle
i_unknown41:
        push  dword $
        jmp   i_u_errorhandle
i_unknown42:
        push  dword $
        jmp   i_u_errorhandle
i_unknown43:
        push  dword $
        jmp   i_u_errorhandle
i_unknown44:
        push  dword $
        jmp   i_u_errorhandle
i_unknown45:
        push  dword $
        jmp   i_u_errorhandle
i_unknown46:
        push  dword $
        jmp   i_u_errorhandle
i_unknown47:
        push  dword $
        jmp   i_u_errorhandle
i_unknown48:
        push  dword $
        jmp   i_u_errorhandle
i_unknown49:
        push  dword $
        jmp   i_u_errorhandle
i_unknown4a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown4b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown4c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown4d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown4e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown4f:
        push  dword $
        jmp   i_u_errorhandle



i_unknown50:
        push  dword $
        jmp   i_u_errorhandle
i_unknown51:
        push  dword $
        jmp   i_u_errorhandle
i_unknown52:
        push  dword $
        jmp   i_u_errorhandle
i_unknown53:
        push  dword $
        jmp   i_u_errorhandle
i_unknown54:
        push  dword $
        jmp   i_u_errorhandle
i_unknown55:
        push  dword $
        jmp   i_u_errorhandle
i_unknown56:
        push  dword $
        jmp   i_u_errorhandle
i_unknown57:
        push  dword $
        jmp   i_u_errorhandle
i_unknown58:
        push  dword $
        jmp   i_u_errorhandle
i_unknown59:
        push  dword $
        jmp   i_u_errorhandle
i_unknown5a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown5b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown5c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown5d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown5e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown5f:
        push  dword $
        jmp   i_u_errorhandle


i_unknown60:
        push  dword $
        jmp   i_u_errorhandle
i_unknown61:
        push  dword $
        jmp   i_u_errorhandle
i_unknown62:
        push  dword $
        jmp   i_u_errorhandle
i_unknown63:
        push  dword $
        jmp   i_u_errorhandle
i_unknown64:
        push  dword $
        jmp   i_u_errorhandle
i_unknown65:
        push  dword $
        jmp   i_u_errorhandle
i_unknown66:
        push  dword $
        jmp   i_u_errorhandle
i_unknown67:
        push  dword $
        jmp   i_u_errorhandle
i_unknown68:
        push  dword $
        jmp   i_u_errorhandle
i_unknown69:
        push  dword $
        jmp   i_u_errorhandle
i_unknown6a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown6b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown6c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown6d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown6e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown6f:
        push  dword $
        jmp   i_u_errorhandle


i_unknown70:
        push  dword $
        jmp   i_u_errorhandle
i_unknown71:
        push  dword $
        jmp   i_u_errorhandle
i_unknown72:
        push  dword $
        jmp   i_u_errorhandle
i_unknown73:
        push  dword $
        jmp   i_u_errorhandle
i_unknown74:
        push  dword $
        jmp   i_u_errorhandle
i_unknown75:
        push  dword $
        jmp   i_u_errorhandle
i_unknown76:
        push  dword $
        jmp   i_u_errorhandle
i_unknown77:
        push  dword $
        jmp   i_u_errorhandle
i_unknown78:
        push  dword $
        jmp   i_u_errorhandle
i_unknown79:
        push  dword $
        jmp   i_u_errorhandle
i_unknown7a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown7b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown7c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown7d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown7e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown7f:
        push  dword $
        jmp   i_u_errorhandle


i_unknown80:
        push  dword $
        jmp   i_u_errorhandle
i_unknown81:
        push  dword $
        jmp   i_u_errorhandle
i_unknown82:
        push  dword $
        jmp   i_u_errorhandle
i_unknown83:
        push  dword $
        jmp   i_u_errorhandle
i_unknown84:
        push  dword $
        jmp   i_u_errorhandle
i_unknown85:
        push  dword $
        jmp   i_u_errorhandle
i_unknown86:
        push  dword $
        jmp   i_u_errorhandle
i_unknown87:
        push  dword $
        jmp   i_u_errorhandle
i_unknown88:
        push  dword $
        jmp   i_u_errorhandle
i_unknown89:
        push  dword $
        jmp   i_u_errorhandle
i_unknown8a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown8b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown8c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown8d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown8e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown8f:
        push  dword $
        jmp   i_u_errorhandle


i_unknown90:
        push  dword $
        jmp   i_u_errorhandle
i_unknown91:
        push  dword $
        jmp   i_u_errorhandle
i_unknown92:
        push  dword $
        jmp   i_u_errorhandle
i_unknown93:
        push  dword $
        jmp   i_u_errorhandle
i_unknown94:
        push  dword $
        jmp   i_u_errorhandle
i_unknown95:
        push  dword $
        jmp   i_u_errorhandle
i_unknown96:
        push  dword $
        jmp   i_u_errorhandle
i_unknown97:
        push  dword $
        jmp   i_u_errorhandle
i_unknown98:
        push  dword $
        jmp   i_u_errorhandle
i_unknown99:
        push  dword $
        jmp   i_u_errorhandle
i_unknown9a:
        push  dword $
        jmp   i_u_errorhandle
i_unknown9b:
        push  dword $
        jmp   i_u_errorhandle
i_unknown9c:
        push  dword $
        jmp   i_u_errorhandle
i_unknown9d:
        push  dword $
        jmp   i_u_errorhandle
i_unknown9e:
        push  dword $
        jmp   i_u_errorhandle
i_unknown9f:
        push  dword $
        jmp   i_u_errorhandle


i_unknowna0:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna1:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna2:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna3:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna4:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna5:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna6:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna7:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna8:
        push  dword $
        jmp   i_u_errorhandle
i_unknowna9:
        push  dword $
        jmp   i_u_errorhandle
i_unknownaa:
        push  dword $
        jmp   i_u_errorhandle
i_unknownab:
        push  dword $
        jmp   i_u_errorhandle
i_unknownac:
        push  dword $
        jmp   i_u_errorhandle
i_unknownad:
        push  dword $
        jmp   i_u_errorhandle
i_unknownae:
        push  dword $
        jmp   i_u_errorhandle
i_unknownaf:
        push  dword $
        jmp   i_u_errorhandle


i_unknownb0:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb1:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb2:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb3:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb4:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb5:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb6:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb7:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb8:
        push  dword $
        jmp   i_u_errorhandle
i_unknownb9:
        push  dword $
        jmp   i_u_errorhandle
i_unknownba:
        push  dword $
        jmp   i_u_errorhandle
i_unknownbb:
        push  dword $
        jmp   i_u_errorhandle
i_unknownbc:
        push  dword $
        jmp   i_u_errorhandle
i_unknownbd:
        push  dword $
        jmp   i_u_errorhandle
i_unknownbe:
        push  dword $
        jmp   i_u_errorhandle
i_unknownbf:
        push  dword $
        jmp   i_u_errorhandle


i_unknownc0:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc1:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc2:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc3:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc4:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc5:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc6:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc7:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc8:
        push  dword $
        jmp   i_u_errorhandle
i_unknownc9:
        push  dword $
        jmp   i_u_errorhandle
i_unknownca:
        push  dword $
        jmp   i_u_errorhandle
i_unknowncb:
        push  dword $
        jmp   i_u_errorhandle
i_unknowncc:
        push  dword $
        jmp   i_u_errorhandle
i_unknowncd:
        push  dword $
        jmp   i_u_errorhandle
i_unknownce:
        push  dword $
        jmp   i_u_errorhandle
i_unknowncf:
        push  dword $
        jmp   i_u_errorhandle


i_unknownd0:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd1:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd2:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd3:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd4:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd5:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd6:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd7:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd8:
        push  dword $
        jmp   i_u_errorhandle
i_unknownd9:
        push  dword $
        jmp   i_u_errorhandle
i_unknownda:
        push  dword $
        jmp   i_u_errorhandle
i_unknowndb:
        push  dword $
        jmp   i_u_errorhandle
i_unknowndc:
        push  dword $
        jmp   i_u_errorhandle
i_unknowndd:
        push  dword $
        jmp   i_u_errorhandle
i_unknownde:
        push  dword $
        jmp   i_u_errorhandle
i_unknowndf:
        push  dword $
        jmp   i_u_errorhandle


i_unknowne0:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne1:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne2:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne3:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne4:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne5:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne6:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne7:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne8:
        push  dword $
        jmp   i_u_errorhandle
i_unknowne9:
        push  dword $
        jmp   i_u_errorhandle
i_unknownea:
        push  dword $
        jmp   i_u_errorhandle
i_unknowneb:
        push  dword $
        jmp   i_u_errorhandle
i_unknownec:
        push  dword $
        jmp   i_u_errorhandle
i_unknowned:
        push  dword $
        jmp   i_u_errorhandle
i_unknownee:
        push  dword $
        jmp   i_u_errorhandle
i_unknownef:
        push  dword $
        jmp   i_u_errorhandle



i_unknownf0:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf1:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf2:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf3:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf4:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf5:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf6:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf7:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf8:
        push  dword $
        jmp   i_u_errorhandle
i_unknownf9:
        push  dword $
        jmp   i_u_errorhandle
i_unknownfa:
        push  dword $
        jmp   i_u_errorhandle
i_unknownfb:
        push  dword $
        jmp   i_u_errorhandle
i_unknownfc:
        push  dword $
        jmp   i_u_errorhandle
i_unknownfd:
        push  dword $
        jmp   i_u_errorhandle
i_unknownfe:
        push  dword $
        jmp   i_u_errorhandle
i_unknownff:
        push  dword $
        jmp   i_u_errorhandle


i_u_errorhandle:

        cli

        pop   eax

        sti

        jmp   $





compare_to_thread:

         push ebx

         mov  eax,edx
         imul eax,8
         add  eax,gdts+ app_code-3
         mov  ebx,[eax]
         cmp  ebx,[old_code_0]
         jne  ctt0
         mov  ebx,[eax+4]
         cmp  ebx,[old_code_1]
         jne  ctt0

         pop  ebx
         mov  eax,1
         ret

       ctt0:

         pop  ebx
         mov  eax,0
         ret



check_for_thread_mem:

         pusha

         mov  ecx,[0x3004]
       cftm0:
         mov  eax,ecx
         imul eax,8
         add  eax,gdts+ app_code-3
         mov  ebx,[eax]
         cmp  ebx,[old_code_0]
         jne  cftm1
         mov  ebx,[eax+4]
         cmp  ebx,[old_code_1]
         jne  cftm1

         mov  eax,ecx  ; new code segments
         imul eax,8
         add  eax,gdts+ app_code-3

         mov  ebx,[new_code_0]
         mov  [eax],ebx
         mov  ebx,[new_code_1]
         mov  [eax+4],ebx

         mov  eax,ecx  ; new data segments
         imul eax,8
         add  eax,gdts+ app_data-3

         mov  ebx,[new_data_0]
         mov  [eax],ebx
         mov  ebx,[new_data_1]
         mov  [eax+4],ebx

         cmp  [new_pos],0   ; new memory position segments
         je   no_new_postition_for_thread
         mov  eax,ecx
         imul eax,32
         add  eax,0x3000
         mov  ebx,[new_pos]
         mov  [eax+0x10],ebx
       no_new_postition_for_thread:

         mov  eax,ecx       ; new amount of memory
         imul eax,256
         add  eax,0x80000
         mov  ebx,[new_amount]
         mov  [eax+0x8C],ebx

       cftm1:

         dec  ecx
         jnz  cftm0

         popa

         ret


save_for_thread_check:

        ; save for thread check

        pusha
        mov    esi,[0x3000]
        imul   esi,8
        add    esi,gdts+ app_code-3 +0
        mov    edi,old_code_0
        mov    ecx,8
        cld
        rep    movsb
        popa

        ret


save_new_position_for_threads:

        ; new code segment for thread check
        pusha
        mov    esi,[0x3000]
        imul   esi,8
        add    esi,gdts+ app_code-3 +0
        mov    edi,new_code_0
        mov    ecx,8
        cld
        rep    movsb
        popa

        ; new data segment for thread check
        pusha
        mov    esi,[0x3000]
        imul   esi,8
        add    esi,gdts+ app_data-3 +0
        mov    edi,new_data_0
        mov    ecx,8
        cld
        rep    movsb
        popa

        ret


set_application_table_status:

        push eax

        mov  eax,[0x3000]
        imul eax,32
        add  eax,0x3000+4
        mov  eax,[eax]

        mov  [application_table_status],eax

        pop  eax

        ret


clear_application_table_status:

        push eax

        mov  eax,[0x3000]
        imul eax,32
        add  eax,0x3000+4
        mov  eax,[eax]

        cmp  eax,[application_table_status]
        jne  apptsl1
        mov  [application_table_status],0
      apptsl1:

        pop  eax

        ret


old_code_0 dd 0x0
old_code_1 dd 0x0

;

new_code_0 dd 0x0
new_code_1 dd 0x0

new_data_0 dd 0x0
new_data_1 dd 0x0

new_pos    dd 0x0
new_amount dd 0x0


sys_resize_app_memory:

        ; eax = 1 - resize
        ;     ebx = new amount of memory

        cmp    eax,1
        jne    no_application_mem_resize

        add    ebx,4095
        shr    ebx,12
        shl    ebx,12
        mov    ebp,ebx

        ; wait for process table to be free

      rsm0:

        cli
        cmp   [application_table_status],0
        je    rsm1
        sti
        call  change_task
        jmp   rsm0

      rsm1:

        call  set_application_table_status
        sti

        cmp    ebx,0 ; other than zero
        je     mem_resize_unsuccess

        call   save_for_thread_check

        ; find a free place

        mov    esi,[0xfe84]  ; application memory start
        mov    edi,ebp
        add    edi,esi
        dec    edi

      rfgdt:

        mov    edx,2

      rfindgdtl1:

        call   compare_to_thread
        cmp    eax,1
        je     rfindfl3

        mov    ecx,edx
        shl    ecx,3

        ; eax run base -> ebx limit

        mov    al,[ecx+gdts+ app_code-3 +4]
        mov    ah,[ecx+gdts+ app_code-3 +7]
        shl    eax,16
        mov    ax,[ecx+gdts+ app_code-3 +2]

        movzx  ebx,word [ecx+gdts+ app_code-3 +0]
        shl    ebx,12
        add    ebx,eax

        cmp    eax,edi
        jg     rfindfl3
        cmp    ebx,esi
        jb     rfindfl3

        add    esi,4096
        add    edi,4096

        cmp    edi,[0xfe8c]        ; < c_memory
        jbe    rfgdt

        jmp    rfind_free_ret_2   ;; not enough memory

      rfindfl3:

        inc    edx
        cmp    edx,[0x3004]
        jbe    rfindgdtl1

     rfindfl1:
     rthread_c:

        mov    ecx,[0x3000]
        shl    ecx,3

        inc    edi
        sub    edi,esi
        add    edi,4095
        shr    edi,12
        dec    edi

        ; code

        mov    eax,esi
        mov    ebx,edi

        mov    [ecx+gdts+ app_code-3 +2], ax              ;  base  0:15
        shr    eax,16
        mov    [ecx+gdts+ app_code-3 +4], al              ;  base  23:16
        mov    [ecx+gdts+ app_code-3 +7], ah              ;  base  31:24
        mov    [ecx+gdts+ app_code-3 +0], bx              ;  limit

        ; data

        mov    eax,esi
        mov    [ecx+gdts+ app_data-3 +2], ax              ;  base  0:15
        shr    eax,16
        mov    [ecx+gdts+ app_data-3 +4], al              ;  base  23:16
        mov    [ecx+gdts+ app_data-3 +7], ah              ;  base  31:24

        movzx  edx,word [ecx+gdts+ app_code-3 +0]         ;  save limit

        mov    [ecx+gdts+ app_data-3 +0], bx              ;  limit

        and    ebx,0xffff

        cmp    ebx,edx  ; copy smaller from memory sizes
        jge    noedxebxxchg
        mov    edx,ebx
      noedxebxxchg:

        movzx  ecx,dx
        shl    ecx,12
        add    ecx,4096

        mov    edi,esi

        mov    eax,[0x3010]
        mov    esi,[eax+0x10]

        mov    [eax+0x10],edi  ; new memory position

        mov    eax,[0x3000]    ; new memory size
        shl    eax,8
        add    eax,0x80000
        mov    [eax+0x8c],ebp

        mov    [new_pos],edi    ; new position for threads
        mov    [new_amount],ebp ; new amount of mem for threads

        cmp    esi,edi
        je     no_app_move

        cld
        rep    movsb           ; move the app image to the new position

      no_app_move:

        call   save_new_position_for_threads
        call   check_for_thread_mem

        mov    [application_table_status],0

        mov    [esp+36],dword 0 ; eax <- 0 ; successfull

        ret

     rfind_free_ret_2:

     mem_resize_unsuccess:

        mov    [application_table_status],0

        mov    [esp+36],dword 1 ; eax <- 1 ; unsuccessfull

        ret

     no_application_mem_resize:


        ret



find_free_mem:

        push   eax
        push   ebx
        push   ecx
        push   edx
        push   edi

        call   find_free_process_slot
        mov    eax,[new_process_place]

        cmp    eax,max_processes
        jg     find_free_ret_2

        cmp    [thread_create],1
        je     thread_c

        mov    esi,[0xfe84]
        add    edi,esi
        dec    edi

        mov    eax,2
        cmp    dword [0x3004],1
        je     findf4

     fgdt:

        mov    edx,2

      findgdtl1:

        mov    ecx,edx
        shl    ecx,3

        ; eax run base -> ebx limit

        mov    al,[ecx+gdts+ app_code-3 +4]
        mov    ah,[ecx+gdts+ app_code-3 +7]
        shl    eax,16
        mov    ax,[ecx+gdts+ app_code-3 +2]

        movzx  ebx,word [ecx+gdts+ app_code-3 +0]
        shl    ebx,12
        add    ebx,eax

        cmp    eax,edi
        jg     findfl3
        cmp    ebx,esi
        jb     findfl3

        add    esi,4096
        add    edi,4096

        cmp    edi,[0xfe8c]        ; < c_memory
        jbe    fgdt

        jmp    find_free_ret_2

      findfl3:

        inc    edx
        cmp    edx,[check_processes]
        jbe    findgdtl1

     findfl1:
     thread_c:

         mov    eax,[new_process_place]

     findf4:

        mov    [first_gdt_search],eax
        mov    [gdt_place],eax

        mov    ecx,eax
        shl    ecx,3

        inc    edi
        sub    edi,esi
        add    edi,4095
        shr    edi,12
        dec    edi

        ; code

        mov    eax,esi
        mov    ebx,edi

        mov    [ecx+gdts+ app_code-3 +2], ax                   ;  base  0:15
        shr    eax,16
        mov    [ecx+gdts+ app_code-3 +4], al                   ;  base  23:16
        mov    [ecx+gdts+ app_code-3 +7], ah                   ;  base  31:24
        mov    [ecx+gdts+ app_code-3 +0], bx                   ;  limit
        mov    [ecx+gdts+ app_code-3 +5], word 11010000b *256 +11111010b

        ; data

        mov    eax,esi
        mov    [ecx+gdts+ app_data-3 +2], ax                   ;  base  0:15
        shr    eax,16
        mov    [ecx+gdts+ app_data-3 +4], al                   ;  base  23:16
        mov    [ecx+gdts+ app_data-3 +7], ah                   ;  base  31:24
        mov    [ecx+gdts+ app_data-3 +0], bx                   ;  limit
        mov    [ecx+gdts+ app_data-3 +5], word 11010000b *256 +11110010b

        push   esi
        mov    esi,process_loading
        call   sys_msg_board_str
        pop    esi

      find_free_ret:

        pop    edi
        pop    edx
        pop    ecx
        pop    ebx
        pop    eax
        ret

      find_free_ret_2:

        pop    edi
        pop    edx
        pop    ecx
        pop    ebx
        pop    eax
        mov    esi,0
        ret


get_app_params:

    push eax

    cmp  [0x90000+6],word '00'
    jne  no_00_header

    mov  eax,[0x90000+12]
    mov  [app_start],eax
    mov  eax,[0x90000+16]
    mov  [app_i_end],eax
    mov  eax,[0x90000+20]
    mov  [app_mem],eax
    shr  eax,1
    sub  eax,0x10
    mov  [app_esp],eax
    mov  eax,[0x90000+24]
    mov  [app_i_param],eax
    mov  [app_i_icon],dword 0

    pop  eax
    mov  esi,1
    ret

  no_00_header:


    cmp  [0x90000+6],word '01'
    jne  no_01_header

    mov  eax,[0x90000+12]
    mov  [app_start],eax
    mov  eax,[0x90000+16]
    mov  [app_i_end],eax
    mov  eax,[0x90000+20]
    mov  [app_mem],eax
    mov  eax,[0x90000+24]
    mov  [app_esp],eax
    mov  eax,[0x90000+28]
    mov  [app_i_param],eax
    mov  eax,[0x90000+32]
    mov  [app_i_icon],eax

    pop  eax
    mov  esi,1
    ret

   no_01_header:

    pop  eax
    mov  esi,0
    ret


start_application_fl:

    ; eax - pointer to filename
    ; ebx - parameters to pass

    cli
    cmp   [application_table_status],0
    je    stfl9
    sti
    call  change_task
    jmp   start_application_fl
  stfl9:

    call  set_application_table_status

    mov   [thread_create],0

    push  ebx
    push  eax

    mov   ebx,1
    mov   ecx,2
    mov   edx,0x90000
    mov   esi,12
    cli
    call  fileread
    cli
    cmp   eax,0
    jne   noflrun
    cmp   [0x90000+0],dword 'MENU'
    jnz   noflrun
    cmp   [0x90000+4],word  'ET'
    jnz   noflrun
    call  get_app_params
    cmp   esi,0
    je    noflrun
    mov   edi,[app_mem]
    call  find_free_mem
    cmp   esi,0
    jne   start_app_c

  noflrun:

    pop   eax
    pop   ebx
    mov   eax,-1
    mov   [application_table_status],0
    sti
    ret

  start_app_c:

    mov   [app_mem_pos],esi

    mov   edi,[app_mem_pos]      ; clear run location
    mov   ecx,[app_mem]
    mov   eax,0x0
    cld
    rep   stosb

    mov   eax,[esp+0]            ; read all of file to it's run location
    mov   ebx,0
    mov   ecx,-1
    mov   edx,[app_mem_pos]
    mov   esi,12
    cli
    call  fileread
    cli

    jmp   add_app_parameters


start_application_hd:

    ; eax - file name, abs address
    ; ebx - file length
    ; ecx - work area, abs address
    ; ebp - parameters to pass

    cli
    cmp   [application_table_status],0
    je    sthd9
    sti
    call  change_task
    jmp   start_application_hd
  sthd9:

    call  set_application_table_status

    sti

    mov   [thread_create],0

    push  ebx   ; file length
    push  eax   ; file name    - abs address
    push  ecx   ; work area    - abs address

    mov   esi,ecx

    mov   ecx,1
    mov   edx,1

    pusha
    call  read_hd_file
    cmp   eax,0
    je    rhdfl5
    popa

    add   esp,4*3
    mov   eax,-1
    mov   [application_table_status],0
    ret

  rhdfl5:
    popa

    cmp   [esi+1024+0],dword 'MENU'
    jnz   nohdrun
    cmp   [esi+1024+4],word  'ET'
    jnz   nohdrun

    add   esi,1024
    mov   edi,0x90000
    mov   ecx,512/4
    cld
    rep   movsd

    call  get_app_params
    cmp   esi,0
    je    nohdrun

    mov   edi,[app_mem]
    call  find_free_mem
    cmp   esi,0
    jne   read_file_to_place

  nohdrun:

    add   esp,4*3
    mov   eax,1
    mov   [application_table_status],0
    sti
    ret

  read_file_to_place:

    cli

    mov   [thread_create],0
    mov   [app_mem_pos],esi

    pop   esi

    mov   edi,[app_mem_pos]            ; clear run location
    mov   ecx,[app_mem]
    mov   eax,0x0
    cld
    rep   stosb

    mov   ecx,1                        ; read the file to its run-location

  hdnw:

    push  ecx
    push  esi
    mov   eax,[esp+8]
    mov   ebx,[esp+12]
    mov   edx,1
    call  read_hd_file
    pop   esi
    pop   ecx
    cmp   eax,0
    jne   stnshd

    push  ecx
    mov   eax,esi
    add   eax,1024
    mov   ebx,ecx
    sub   ebx,1
    shl   ebx,9
    add   ebx,[app_mem_pos]
    mov   ecx,512
    call  memmove
    pop   ecx

    add   ecx,1
    jmp   hdnw

  stnshd:

    cli

    pop   esi edi  ; pos - len

    add   esi , edi

    inc   edi
  newesidec:
    dec   edi
    jz    nonewesidec
    dec   esi
    cmp   [esi],byte '/'
    jne   newesidec
  nonewesidec:
    inc   esi

    push  ebp  ; dword 0
    push  esi  ; name position

    jmp   add_app_parameters


threadstring       dd  0x0
new_process_place  dd  0x0
check_processes    dd  0x0

app_start    dd  0x0
app_i_end    dd  0x0
app_mem      dd  0x0
app_esp      dd  0x0
app_i_param  dd  0x0
app_i_icon   dd  0x0
app_mem_pos  dd  0x0

process_loading  db 'Kernel : Process - loading ',13,10,0
process_running  db 'Kernel : Process - done',13,10,0
first_gdt_search dd 0x2
thread_create    dd 0x0
gdt_place        dd 0x0


sys_threads:

; eax=1 create thread
;
;   ebx=thread start
;   ecx=thread stack value
;
; on return : eax = pid

    cli
    cmp   [application_table_status],0
    je    stth9
    sti
    call  change_task
    jmp   sys_threads
  stth9:

    call  set_application_table_status

    sti

    cmp  eax,1
    jne  no_sys_thread_create
    cli

    mov  eax,[0x3010]
    mov  eax,[eax+0x10]
    mov  [app_mem_pos],eax

    mov  [app_i_param],0
    mov  [app_i_icon],0

    mov  [app_start],ebx
    mov  [app_esp],ecx

    mov  ebx,[0x3000]
    shl  ebx,8
    add  ebx,0x80000
    mov  [threadstring],ebx
    mov  ebx,[ebx+0x8c]
    mov  [app_mem],ebx

    mov  esi,[app_mem_pos]
    mov  edi,[app_mem]
    add  edi,esi
    dec  edi
    mov  [thread_create],1
    call find_free_mem
    cmp  esi,0
    jne  th_cr1
    mov  [application_table_status],0
    mov  eax,1   ; no free memory
    sti
    ret
  th_cr1:
    push dword 0
    push dword [threadstring]
    jmp  add_app_parameters
  no_sys_thread_create:

    mov  eax,-1
    mov  [application_table_status],0
    ret


find_free_process_slot:

    pusha

    mov   ebx,[0x3004]
    mov   [check_processes],ebx
    inc   ebx
    mov   [new_process_place],ebx

    mov   ebx,2

  newfps:

    mov   eax,ebx
    imul  eax,0x20
    add   eax,0x3000+0xa
    cmp   [eax],byte 9
    je    ffpl

    inc   ebx
    cmp   ebx,[0x3004]
    jbe   newfps

    cmp   dword [0x3004],dword max_processes
    jae   noaddnewp

    mov   ebx , [0x3004]
    add   ebx , 1
    imul  ebx , 0x20
    mov   [0x3000+ebx+0xa],byte 9

    add   dword [0x3004],dword 1
    mov   ebx,[0x3004]
    mov   [check_processes],ebx
    mov   [new_process_place],ebx

  noaddnewp:

    popa
    ret

  ffpl:

    mov   [new_process_place],ebx

    popa
    ret




add_app_parameters:

; returns:  eax = pid or -1 if unsuccesfull

    cmp   [app_i_param],dword 0     ; parameter
    jz    no_app_params
    mov   eax,0
    mov   edi,[app_i_param]
    add   edi,[app_mem_pos]
    mov   ecx,256/4
    cld
    rep   stosd
    mov   esi,[esp+4]
    cmp   esi,0
    jz    no_app_params
    mov   eax,[app_i_param]
    add   eax,[app_mem_pos]
    mov   edi,eax
    mov   ecx,256
    cld
  app_new_param:
    cmp   [esi],byte 0
    jz    no_app_params
    movsb
    loop  app_new_param
  no_app_params:

    mov   ebx,[new_process_place]

    mov   edi,ebx                   ; clear 0x80000 (256 bytes)
    shl   edi,8
    add   edi,0x80000
    mov   ecx,256 / 4
    mov   eax,0
    cld
    rep   stosd

    shl   ebx,5                     ; * 32 +0x3000
    add   ebx,0x3000

    mov   al,byte [new_process_place] ; screen id ?
    mov   [ebx+0xe],al

    mov   [ebx],dword 1+2+4         ; report events: windowdraw, key, button

    inc   dword [process_number]    ; process id number
    mov   eax,[process_number]
    mov   [ebx+4],eax

    mov   ecx,ebx                   ; set draw limits
    add   ecx,draw_data-0x3000
    mov   [ecx+0],dword 0
    mov   [ecx+4],dword 0
    mov   eax,[0xfe00]
    mov   [ecx+8],eax
    mov   eax,[0xfe04]
    mov   [ecx+12],eax

    mov   eax,[app_mem_pos]        ; position in memory
    mov   [ebx+0x10],eax

    ; TSS

    mov   eax,cr3
    mov   [l.cr3],eax
    mov   eax,[app_start]
    mov   [l.eip],eax
    mov   eax,[app_esp]
    mov   [l.esp],eax

    mov   ebx,[new_process_place]              ; gdt's
    shl   ebx,3

    mov   ax,app_code
    add   ax,bx
    mov   [l.cs],ax
    mov   ax,app_data
    add   ax,bx
    mov   [l.ss],ax
    mov   [l.ds],ax
    mov   [l.es],ax
    mov   [l.fs],ax
    mov   ax,graph_data
    mov   [l.gs],ax
    mov   [l.io],word 128
    mov   [l.eflags],dword 0x11202
    mov   [l.ss0], os_data
    mov   [l.ss1], ring1_data
    mov   [l.ss2], ring2_data
    mov   [l.esp0], 0x55000
    mov   [l.esp1], 0x56000
    mov   [l.esp2], 0x57000

    mov   eax,tss_sceleton          ; move tss to tss_data+
    mov   ebx,[new_process_place]
    imul  ebx,tss_step
    add   ebx,tss_data
    mov   ecx,120
    call  memmove

    ; Add IO access table

    mov  eax,0xff
    mov  edi,[new_process_place]
    imul edi,tss_step
    add  edi,tss_data
    add  edi,128
    mov  ecx,8192 ; for 8192 * 8 bits = 16384 ports
    cld
    rep  stosb

    ; make sure gdt is pointing to the process
    ; and not to i40 handler

    mov   ecx,ebx
    mov   edi,[new_process_place]
    imul  edi,8

    mov   [edi+gdts+ tss0 +0], word tss_step     ; limit 0:15
    mov   [edi+gdts+ tss0 +2], cx                ; base  0:15
    mov   eax,ecx
    shr   eax,16
    mov   [edi+gdts+ tss0 +4], al                ; base  23:16
    mov   [edi+gdts+ tss0 +7], ah                ; base  31:24
    mov   [edi+gdts+ tss0 +5], word 01010000b *256 +11101001b

    pop   eax
    pop   ebx

    mov   ebx,[new_process_place]              ; save name of the process
    shl   ebx,8
    add   ebx,0x80000
    mov   ecx,11
    call  memmove

    mov   ebx,[new_process_place]              ; save image size
    shl   ebx,8
    add   ebx,0x80000+0x8C
    mov   eax,[app_mem]
    mov   [ebx],eax

    mov   [0xf400],byte 0           ; empty keyboard buffer
    mov   [0xf500],byte 0           ; empty button buffer

    mov   [application_table_status],0
    mov   eax,[process_number]

    mov   ebx,[new_process_place]
    imul  ebx,0x20
    mov   [0x3000+ebx+0xa],byte 0

    mov   edi,[new_process_place]
    shl   edi,5
    add   edi,window_data
    mov   ebx,[new_process_place]
    shl   ebx,1
    add   ebx,0xc000
    mov   esi,[ebx]
    and   esi,65535
    shl   esi,1
    add   esi,0xc400
    movzx  eax,word [esi]
    call   windowactivate

    cmp   [boot_application_load],byte 1 ; for AMD64
    je    no_boot_enable_int
    sti
  no_boot_enable_int:

    push   esi
    mov    esi,process_running
    call   sys_msg_board_str
    pop    esi

    ret

process_terminating   db 'Kernel : Process - terminating',13,10,0
process_terminated    db 'Kernel : Process - done',13,10,0

terminate: ; terminate application

    push   esi
    mov    esi,process_terminating
    call   sys_msg_board_str
    pop    esi

    cli
    cmp   [application_table_status],0
    je    term9
    sti

    ret

  term9:

    call  set_application_table_status

    mov   [first_gdt_search],0x2   ; start gdt search from beginning

    cmp   [prev_user_of_fpu],esi   ; if user fpu last -> fpu user = 1
    jne   fpu_ok_1
    mov   [prev_user_of_fpu],1
  fpu_ok_1:

    mov   [0xf400],byte 0           ; empty keyboard buffer
    mov   [0xf500],byte 0           ; empty button buffer

    mov   ecx,esi                               ; clear memory reserv.
    shl   ecx,3
    mov   [ecx+gdts+ app_code-3 +0],dword 0
    mov   [ecx+gdts+ app_code-3 +4],dword 0
    mov   [ecx+gdts+ app_data-3 +0],dword 0
    mov   [ecx+gdts+ app_data-3 +4],dword 0

    mov   edi,esi
    imul  edi,0x20
    add   edi,0x3000
    cmp   [edi+0xa],byte 3  ; if normal terminate then clear int40 handler
    jne   nocl40

    mov   edi,esi   ; free the used interrupt 0x40 handler
    imul  edi,256
    mov   eax,[edi+0x80000+0xb0]

    cmp   eax,0     ; is application using a systemcall interrupt  ?
    je    nocl40

    mov   [usedi40+eax],byte 0

    mov   edi,8
    imul  edi,eax
    mov   [edi+tss0sys_l +5], word 01010000b *256 +11101001b

    mov   edi,128
    imul  edi,eax
    mov   [edi+0x298000+l.eip-tss_sceleton],dword i40
    mov   [edi+0x298000+l.eflags-tss_sceleton],dword 0x11002

    mov   ebx,eax
    imul  ebx,4096
    add   ebx,sysint_stack_data
    mov   [edi+0x298000+l.esp-tss_sceleton],ebx

  nocl40:

    mov   ecx,esi                 ; remove buttons
  bnewba2:
    mov   edi,[0xfe88]
    mov   eax,edi
    cld
    movzx ebx,word [edi]
    inc   bx
  bnewba:
    dec   bx
    jz    bnmba
    add   eax,0x10
    cmp   cx,[eax]
    jnz   bnewba
    pusha
    mov   ecx,ebx
    inc   ecx
    shl   ecx,4
    mov   ebx,eax
    add   eax,0x10
    call  memmove
    dec   dword [edi]
    popa
    jmp   bnewba2
  bnmba:

    pusha     ; save window coordinates for window restoring
    cld
    shl   esi,5
    add   esi,window_data
    mov   ax,[esi+0]
    mov   word [dlx],ax
    mov   bx,[esi+8]
    add   ax,bx
    mov   word [dlxe],ax
    mov   ax,[esi+4]
    mov   word [dly],ax
    mov   bx,[esi+12]
    add   ax,bx
    mov   word [dlye],ax
    mov   [esi+0],word 0
    mov   [esi+8],word 5
    mov   ax,[0xFE04]
    mov   [esi+4],ax
    mov   [esi+12],word 5
    mov   [esi+16],dword 0
    mov   [esi+20],dword 0
    mov   [esi+24],dword 0
    mov   [esi+28],dword 0
    popa

    pusha
    mov   edi,esi
    shl   edi,5
    add   edi,window_data
    mov   ecx,32
    mov   eax,0
    cld
    rep   stosb

    mov   eax,[0xFE04]      ; set window to start from maxy+1
    add   eax,2

    mov   edi,esi
    shl   edi,5
    add   edi,window_data
    mov   [edi+4],eax

    popa

    pusha
    mov   edi,esi
    shl   edi,5
    add   edi,draw_data
    mov   ecx,32
    mov   eax,0
    cld
    rep   stosb
    popa

    pusha         ; at 0x80000+
    mov   edi,esi
    shl   edi,8
    add   edi,0x80000
    mov   ecx,256
    mov   eax,0
    cld
    rep   stosb
    popa

    pusha          ; name to spaces
    mov   edi,esi
    shl   edi,8
    add   edi,0x80000
    mov   ecx,11
    mov   eax,32
    cld
    rep   stosb
    popa

    pusha                ; C000 --> C400
    mov   eax,0xc000
    mov   esi,0
  nlc40:
    add   eax,2
    inc   esi
    mov   ebx,[0x3004]
    cmp   ebx,esi
    jb    nlc41
    xor   ecx,ecx
    mov   cx,[eax]
    shl   ecx,1
    add   ecx,0xc400
    mov   edx,esi
    mov   [ecx],dx
    jmp   nlc40
  nlc41:
    popa

    pusha ; remove hd1 reservation
    mov   edx,esi
    imul  edx,0x20
    add   edx,0x3000
    mov   edx,[edx+4]
    cmp   [hd1_status],edx
    jne   no_hd1_s_remove
    mov   [hd1_status],0
  no_hd1_s_remove:
    popa


    pusha ; remove all irq reservations
    mov   edx,esi
    imul  edx,0x20
    add   edx,0x3000
    mov   edx,[edx+4]
    mov   edi,irq_owner
    mov   ecx,16
  newirqfree:
    cmp   [edi],edx
    jne   nofreeirq
    mov   [edi],dword 0
  nofreeirq:
    add    edi,4
    loop   newirqfree
    popa

    pusha                       ; remove all scrolls
    ; mov   edx,esi
    ; imul  edx,0x20
    ; add   edx,0x3000
    ; mov   edx,[edx+4]
    mov   edx , esi
    call  remove_scrolls ; in: edx = Process slot
    popa


    pusha                     ; remove all port reservations

    mov   edx,esi
    imul  edx,0x20
    add   edx,0x3000
    mov   edx,[edx+4]

  rmpr0:

    mov   esi,[0x2d0000]

    cmp   esi,0
    je    rmpr9

  rmpr3:

    mov   edi,esi
    shl   edi,4
    add   edi,0x2d0000

    cmp   edx,[edi]
    je    rmpr4

    dec   esi
    jnz   rmpr3

    jmp   rmpr9

  rmpr4:

    mov   ecx,256
    sub   ecx,esi
    shl   ecx,4

    mov   esi,edi
    add   esi,16
    cld
    rep   movsb

    dec   dword [0x2d0000]

    jmp   rmpr0

  rmpr9:

    popa



    mov  edi,esi         ; do not run this process slot
    imul edi,0x20
    add  edi,0x3000
    mov  [edi+0xa],byte 9

    sti  ; .. and life goes on

    movzx eax,word [dlx]
    movzx ebx,word [dly]
    movzx ecx,word [dlxe]
    movzx edx,word [dlye]
    call  calculatescreen

    mov   eax,0
    call  redrawscreen

    mov   [0xfff4],byte 0  ; no mouse background
    mov   [0xfff5],byte 0  ; draw mouse

    mov   [application_table_status],0

    mov   esi,process_terminated
    call  sys_msg_board_str

    ret


boot_sched_1    db   'Building gdt tss pointer',0
boot_sched_2    db   'Building gdt gate pointer',0
boot_sched_3    db   'Building interrupt table - TSS',0
boot_sched_3_2  db   'Building interrupt table - GDT',0
boot_sched_3_3  db   'Building interrupt table - IDT',0
boot_sched_4    db   'Building syscall interrupt table',0


build_scheduler:

        mov    esi,boot_sched_1
        call   boot_log
        call   build_process_gdt_tss_pointer

        mov    esi,boot_sched_2
        call   boot_log
        call   build_process_gdt_gate_pointer

        mov    esi,boot_sched_3
        call   boot_log
        call   build_interrupt_table

        mov    esi,boot_sched_4
        call   boot_log
        call   build_syscall_interrupt_table

        ret

