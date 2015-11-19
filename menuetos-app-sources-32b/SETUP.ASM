;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               ;;
;;     DEVICE SETUP              ;;
;;                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
   
use32
   
   
    org     0x0
    db      'MENUET01'             ; 8 byte id
    dd      0x01                   ;
    dd      START                  ; program start
    dd      I_END                  ; program image end
    dd      0x80000                ; reguired amount of memory
    dd      0x7ff00                ; stack
    dd      0,0                    ; reserved
   
   
START:
   
    call  draw_window
   
still:
   
    mov  eax,10                 ; wait here for event
    int  0x40
   
    cmp  eax,1
    jz   red
    cmp  eax,2
    jz   key
    cmp  eax,3
    jz   button
   
    jmp  still
   
red:

    jmp  START
   
key:

    mov  eax,2
    int  0x40

    jmp  still
   
button:
   
    mov  eax,17
    int  0x40
   
    cmp  ah,1                ; CLOSE APPLICATION
    jne  no_close
    mov  eax,-1
    int  0x40
  no_close:
   
    cmp  ah,11               ; SET MIDI BASE
    jnz  nosetbase1
    mov  eax,21
    mov  ebx,1
    mov  ecx,[midibase]
    int  0x40
   nosetbase1:
    cmp  ah,12
    jnz  nomm
    mov  eax,[midibase]
    sub  eax,2
    mov  [midibase],eax
    call draw_infotext
  nomm:
    cmp  ah,13
    jnz  nomp
    mov  eax,[midibase]
    add  eax,2
    mov  [midibase],eax
    call draw_infotext
  nomp:
   
   
    cmp  ah,4                ; SET KEYBOARD
    jnz  nokm
    mov  eax,[keyboard]
    cmp  eax,0
    je   downuplbl
    dec  eax
    jmp  nodownup
   downuplbl:
    mov  eax,5
   nodownup:
    mov  [keyboard],eax
    call draw_infotext
  nokm:
    cmp  ah,5
    jnz  nokp
    mov  eax,[keyboard]
    cmp  eax,5
    je   updownlbl
    inc  eax
    jmp  noupdown
   updownlbl:
    mov  eax,0
   noupdown:
    mov  [keyboard],eax
    call draw_infotext
  nokp:
   
   
    cmp  ah,22                ; SET CD BASE
    jnz  nocm
    mov  eax,[cdbase]
    sub  eax,1
    dec  eax
    and  eax,3
    inc  eax
    mov  [cdbase],eax
    call draw_infotext
  nocm:
    cmp  ah,23
    jnz  nocp
    mov  eax,[cdbase]
    add  eax,1
    dec  eax
    and  eax,3
    inc  eax
    mov  [cdbase],eax
    call draw_infotext
  nocp:
    cmp  ah,21
    jnz  nocs
    mov  eax,21
    mov  ebx,3
    mov  ecx,[cdbase]
    int  0x40
  nocs:
   
    cmp  ah,62              ; SET HD BASE
    jnz  hnocm
    mov  eax,[hdbase]
    sub  eax,1
    dec  eax
    and  eax,3
    inc  eax
    mov  [hdbase],eax
    call draw_infotext
  hnocm:
    cmp  ah,63
    jnz  hnocp
    mov  eax,[hdbase]
    add  eax,1
    dec  eax
    and  eax,3
    inc  eax
    mov  [hdbase],eax
    call draw_infotext
  hnocp:
    cmp  ah,61
    jnz  hnocs
    mov  eax,21
    mov  ebx,7
    mov  ecx,[hdbase]
    int  0x40
  hnocs:
   
    cmp  ah,82              ; SET SOUND DMA
    jne  no_sdma_d
    mov  eax,[sound_dma]
    dec  eax
   sdmal:
    and  eax,3
    mov  [sound_dma],eax
    call draw_infotext
    jmp  still
  no_sdma_d:
    cmp  ah,83
    jne  no_sdma_i
    mov  eax,[sound_dma]
    inc  eax
    jmp  sdmal
  no_sdma_i:
    cmp  ah,81
    jne  no_set_sound_dma
    mov  eax,21
    mov  ebx,10
    mov  ecx,[sound_dma]
    int  0x40
    jmp  still
  no_set_sound_dma:
   
    cmp  ah,92                   ; SET LBA READ
    jne  no_lba_d
    mov  eax,[lba_read]
    dec  eax
  slbal:
    and  eax,1
    mov  [lba_read],eax
    call draw_infotext
    jmp  still
   no_lba_d:
    cmp  ah,93
    jne  no_lba_i
    mov  eax,[lba_read]
    inc  eax
    jmp  slbal
  no_lba_i:
    cmp  ah,91
    jne  no_set_lba_read
    mov  eax,21
    mov  ebx,11
    mov  ecx,[lba_read]
    int  0x40
    jmp  still
   no_set_lba_read:
   
   
    cmp  ah,102                   ; SET PCI ACCESS
     jne  no_pci_d
     mov  eax,[pci_acc]
    dec  eax
  pcip:
    and  eax,1
     mov  [pci_acc],eax
     call draw_infotext
    jmp  still
  no_pci_d:
    cmp  ah,103
    jne  no_pci_i
     mov  eax,[pci_acc]
     inc  eax
     jmp  pcip
   no_pci_i:
    cmp  ah,101
     jne  no_set_pci_acc
     mov  eax,21
    mov  ebx,12
    mov  ecx,[pci_acc]
    int  0x40
    jmp  still
  no_set_pci_acc:
   
    cmp  ah,72                  ; SET FAT32 PARTITION
    jnz  fhnocm
    mov  eax,[f32p]
    sub  eax,1
    dec  eax
    and  eax,3
    inc  eax
    mov  [f32p],eax
    call draw_infotext
  fhnocm:
    cmp  ah,73
    jnz  fhnocp
    mov  eax,[f32p]
    add  eax,1
    dec  eax
    and  eax,3
    inc  eax
    mov  [f32p],eax
    call draw_infotext
  fhnocp:
    cmp  ah,71
    jnz  fhnocs
    mov  eax,21
    mov  ebx,8
    mov  ecx,[f32p]
    int  0x40
  fhnocs:
   
    cmp  ah,32                  ; SET SOUND BLASTER 16 BASE
    jnz  nosbm
    mov  eax,[sb16]
    sub  eax,2
    mov  [sb16],eax
    call draw_infotext
  nosbm:
    cmp  ah,33
    jnz  nosbp
    mov  eax,[sb16]
    add  eax,2
    mov  [sb16],eax
    call draw_infotext
  nosbp:
    cmp  ah,31
    jnz  nosbs
    mov  eax,21
    mov  ebx,4
    mov  ecx,[sb16]
    int  0x40
  nosbs:
   
    cmp  ah,52                  ; SET WINDOWS SOUND SYSTEM BASE
    jnz  nowssm
    mov  eax,[wss]
    sub  eax,1
    dec  eax
    and  eax,3
    inc  eax
    mov  [wss],eax
    call draw_infotext
  nowssm:
    cmp  ah,53
    jnz  nowssp
    mov  eax,[wss]
    add  eax,1
    dec  eax
    and  eax,3
    inc  eax
    mov  [wss],eax
    call draw_infotext
  nowssp:
    cmp  ah,51
    jnz  nowsss
    mov  eax,21
    mov  ebx,6
    mov  ecx,[wssp]
    int  0x40
  nowsss:
   
    cmp  ah,42                ; SET SYSTEM LANGUAGE BASE
    jnz  nosysm
    mov  eax,[syslang]
    cmp  eax,1
    je   nosysm
    dec  eax
    mov  [syslang],eax
    call draw_infotext
  nosysm:
    cmp  ah,43
    jnz  nosysp
    mov  eax,[syslang]
    cmp  eax,4
    je   nosysp
    inc  eax
    mov  [syslang],eax
    call draw_infotext
  nosysp:
    cmp  ah,41
    jnz  nosyss
    mov  eax,21
    mov  ebx,5
    mov  ecx,[syslang]
    int  0x40
  nosyss:
   
    cmp  ah,3                  ; SET KEYMAP
    jne  nosetkeyl
    mov  eax,[keyboard]
    cmp  eax,0
    jnz  nosetkeyle
    mov  eax,21       ; english
    mov  ebx,2
    mov  ecx,1
    mov  edx,en_keymap
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,2
    mov  edx,en_keymap_shift
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,9
    mov  edx,1
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,3
    mov  edx,alt_general
    int  0x40
  nosetkeyle:
    mov  eax,[keyboard]
    cmp  eax,1
    jnz  nosetkeylfi
    mov  eax,21       ; finnish
    mov  ebx,2
    mov  ecx,1
    mov  edx,fi_keymap
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,2
    mov  edx,fi_keymap_shift
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,9
    mov  edx,2
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,3
    mov  edx,alt_general
    int  0x40
  nosetkeylfi:
    mov  eax,[keyboard]
    cmp  eax,2
    jnz  nosetkeylge
    mov  eax,21       ; german
    mov  ebx,2
    mov  ecx,1
    mov  edx,ge_keymap
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,2
    mov  edx,ge_keymap_shift
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,9
    mov  edx,3
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,3
    mov  edx,alt_general
    int  0x40
  nosetkeylge:
    mov  eax,[keyboard]
    cmp  eax,3
    jnz  nosetkeylru
    mov  eax,21       ; russian
    mov  ebx,2
    mov  ecx,1
    mov  edx,ru_keymap
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,2
    mov  edx,ru_keymap_shift
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,3
    mov  edx,alt_general
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,9
    mov  edx,4
    int  0x40
  nosetkeylru:
    mov  eax,[keyboard]   ; french 
    cmp  eax,4
    jnz  nosetkeylfr
    mov  eax,21
    mov  ebx,2
    mov  ecx,1
    mov  edx,fr_keymap
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,2
    mov  edx,fr_keymap_shift
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,3
    mov  edx,fr_keymap_alt_gr
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,9
    mov  edx,5
    int  0x40
  nosetkeylfr:
    mov  eax,[keyboard]   ; ptbr (brazilian portuguese)
    cmp  eax,5
    jnz  nosetkeylptbr
    mov  eax,21
    mov  ebx,2
    mov  ecx,1
    mov  edx,ptbr_keymap
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,2
    mov  edx,ptbr_keymap_shift
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,3
    mov  edx,alt_general
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,9
    mov  edx,5
    int  0x40
  nosetkeylptbr:

   
  nosetkeyl:
   
    jmp  still
   
button_label: db 0   
   
draw_buttons:
   
    pusha
   
    shl  ecx,16
    add  ecx,12
    mov  ebx,(350-50)*65536+46

 ;   mov  esi , 0x10000000
 ;   mov  edi , button_label
   
    mov  eax,8
    mov  edi,0
    int  0x40
   
    mov  eax,8
    mov  ebx,(350-79)*65536+9
    inc  edx
    mov  edi,0
    int  0x40
   
    mov  eax,8
    mov  ebx,(350-67)*65536+9
    inc  edx
    mov  edi,0
    int  0x40
   
    popa
    ret
   
   
   
; ********************************************
; ******* WINDOW DEFINITIONS AND DRAW  *******
; ********************************************
   
   
draw_window:
   
    pusha
   
    mov  eax,12
    mov  ebx,1
    int  0x40
   
    mov  eax,0
    mov  ebx,110*65536+355
    mov  ecx,110*65536+256
    mov  edx,0x84111199
    mov  esi,window_label
    mov  edi,0
    int  0x40
   
    mov  eax,8                     ; CLOSE BUTTON
    mov  ebx,(355-19)*65536+12
    mov  ecx,5  *65536+12
    mov  edx,1
    mov  esi,0x005588dd
    mov  edi,0
    int  0x40
   
    mov  esi,0x105580c0
    mov  edx,11
    mov  ecx,43
    call draw_buttons
   
    mov  edx,41
    mov  ecx,43+8*8
    call draw_buttons
   
    mov  edx,21
    mov  ecx,43+4*8
    call draw_buttons
   
    mov  edx,31
    mov  ecx,43+2*8
    call draw_buttons
   
    mov  edx,3
    mov  ecx,43+10*8
    call draw_buttons
   
    mov  edx,51
    mov  ecx,43+12*8
    call draw_buttons
   
    mov  edx,61
    mov  ecx,43+6*8
    call draw_buttons
   
    mov  edx,91
    mov  ecx,43+18*8
    call draw_buttons
   
    mov  edx,71
    mov  ecx,43+14*8
    call draw_buttons
   
    mov  edx,81
    mov  ecx,43+16*8
    call draw_buttons
   
    mov  edx,101
    mov  ecx,43+20*8
    call draw_buttons
   
    call draw_infotext
   
    mov  eax,12
    mov  ebx,2
    int  0x40
   
    popa
    ret
   
   
   
draw_infotext:
   
    pusha
   
    mov  eax,[keyboard]                       ; KEYBOARD
    cmp  eax,0
    jnz  noen
    mov  [text00+56*10+28],dword 'ENGL'
    mov  [text00+56*10+32],dword 'ISH '
  noen:
    cmp  eax,1
    jnz  nofi
    mov  [text00+56*10+28],dword 'FINN'
    mov  [text00+56*10+32],dword 'ISH '
  nofi:
    cmp  eax,2
    jnz  noge
    mov  [text00+56*10+28],dword 'GERM'
    mov  [text00+56*10+32],dword 'AN  '
  noge:
    cmp  eax,3
    jnz  nogr
    mov  [text00+56*10+28],dword 'RUSS'
    mov  [text00+56*10+32],dword 'IAN '
  nogr:
    cmp  eax,4
    jnz  nofr
    mov  [text00+56*10+28],dword 'FREN'
    mov  [text00+56*10+32],dword 'CH  '
  nofr:
    cmp  eax,5
    jnz  noptbr
    mov  [text00+56*10+28],dword 'PT-B'
    mov  [text00+56*10+32],dword 'R   '
  noptbr:
   
   
    mov  eax,[syslang]                          ; SYSTEM LANGUAGE
    sub  eax,1
    cmp  eax,0
    jnz  noen5
    mov  [text00+56*8+28],dword 'ENGL'
    mov  [text00+56*8+32],dword 'ISH '
  noen5:
    cmp  eax,1
    jnz  nofi5
    mov  [text00+56*8+28],dword 'FINN'
    mov  [text00+56*8+32],dword 'ISH '
  nofi5:
    cmp  eax,2
    jnz  noge5
    mov  [text00+56*8+28],dword 'GERM'
    mov  [text00+56*8+32],dword 'AN  '
  noge5:
    cmp  eax,3
    jnz  nogr5
    mov  [text00+56*8+28],dword 'RUSS'
    mov  [text00+56*8+32],dword 'IAN '
  nogr5:
    cmp  eax,4
    jne  nofr5
    mov  [text00+56*8+28],dword 'FREN'
    mov  [text00+56*8+32],dword 'CH  '
  nofr5:
   
   
    mov  eax,[midibase]                          ; MIDI BASE
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*0+32],cl
    shr  eax,4
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*0+31],cl
    shr  eax,4
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*0+30],cl
   
   
    mov  eax,[sb16]                            ; SB16 BASE
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*2+32],cl
    shr  eax,4
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*2+31],cl
    shr  eax,4
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*2+30],cl
   
   
    mov  eax,[wss]                           ; WSS BASE
    cmp  eax,1
    jnz  nowss1
    mov  [wssp],dword 0x530
  nowss1:
    cmp  eax,2
    jnz  nowss2
    mov  [wssp],dword 0x608
  nowss2:
    cmp  eax,3
    jnz  nowss3
    mov  [wssp],dword 0xe80
  nowss3:
    cmp  eax,4
    jnz  nowss4
    mov  [wssp],dword 0xf40
  nowss4:
   
    mov  eax,[wssp]
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*12+32],cl
    shr  eax,4
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*12+31],cl
    shr  eax,4
    xor  ebx,ebx
    mov  bl,al
    and  bl,15
    add  ebx,hex
    mov  cl,[ebx]
    mov  [text00+56*12+30],cl
   
   
    mov  eax,[cdbase]                           ; CD BASE
    cmp  eax,1
    jnz  noe1
    mov  [text00+56*4+28],dword 'PRI.'
    mov  [text00+56*4+32],dword 'MAST'
    mov  [text00+56*4+36],dword 'ER  '
  noe1:
    cmp  eax,2
    jnz  nof1
    mov  [text00+56*4+28],dword 'PRI.'
    mov  [text00+56*4+32],dword 'SLAV'
    mov  [text00+56*4+36],dword 'E   '
  nof1:
    cmp  eax,3
    jnz  nog1
    mov  [text00+56*4+28],dword 'SEC.'
    mov  [text00+56*4+32],dword 'MAST'
    mov  [text00+56*4+36],dword 'ER  '
  nog1:
    cmp  eax,4
    jnz  nog2
    mov  [text00+56*4+28],dword 'SEC.'
    mov  [text00+56*4+32],dword 'SLAV'
    mov  [text00+56*4+36],dword 'E   '
  nog2:
   
   
    mov  eax,[hdbase]                         ; HD BASE
    cmp  eax,1
    jnz  hnoe1
    mov  [text00+56*6+28],dword 'PRI.'
    mov  [text00+56*6+32],dword 'MAST'
    mov  [text00+56*6+36],dword 'ER  '
  hnoe1:
    cmp  eax,2
    jnz  hnof1
    mov  [text00+56*6+28],dword 'PRI.'
    mov  [text00+56*6+32],dword 'SLAV'
    mov  [text00+56*6+36],dword 'E   '
  hnof1:
    cmp  eax,3
    jnz  hnog1
    mov  [text00+56*6+28],dword 'SEC.'
    mov  [text00+56*6+32],dword 'MAST'
    mov  [text00+56*6+36],dword 'ER  '
  hnog1:
    cmp  eax,4
    jnz  hnog2
    mov  [text00+56*6+28],dword 'SEC.'
    mov  [text00+56*6+32],dword 'SLAV'
    mov  [text00+56*6+36],dword 'E   '
  hnog2:
   
   
    mov  eax,[f32p]                       ; FAT32 PARTITION
    add  al,48
    mov  [text00+56*14+28],al
   
    mov  eax,[sound_dma]                  ; SOUND DMA
    add  eax,48
    mov  [text00+56*16+28],al
   
    mov  eax,[lba_read]                   ; LBA READ
    mov  ebx,'ON  '
    cmp  eax,1
    je   lbar
    mov  ebx,'OFF '
  lbar:
    mov  [text00+56*18+28],ebx
   
    mov  eax,[pci_acc]                   ; PCI ACCESS
    mov  ebx,'ON  '
    cmp  eax,1
    je   lbar2
    mov  ebx,'OFF '
  lbar2:
    mov  [text00+56*20+28],ebx
   
    mov  eax,13
    mov  ebx,175*65536+85
    mov  ecx,40*65536+182
    mov  edx,0x80111199-19
    int  0x40

    ; White part
   
    mov  edx,text00
    xor  edi,edi
    mov  ebx,10*65536+45
  newline:
    mov  eax,4
    mov  ecx,0xffffff
    mov  esi,44 ; 56
    int  0x40
    add  ebx,8
    add  edx,56
    inc  edi
    cmp  [edx],byte 'x'
    jnz  newline

    ; Black part
   
    mov  edx,text00
    xor  edi,edi
    mov  ebx,(10+44*6)*65536+45
  newline2:
    mov  eax,4
    mov  ecx,0x000000
    mov  esi,12
    add  edx , 44
    int  0x40
    sub  edx , 44
    add  ebx,8
    add  edx,56
    inc  edi
    cmp  [edx],byte 'x'
    jnz  newline2

    popa
    ret
   
   
   
; DATA AREA
   
   
text00:
   
    db 'MIDI: ROLAND MPU-401 BASE : 0x320           - +   APPLY '
    db '                                                        '
    db 'SOUND: SB16 BASE          : 0x240           - +   APPLY '
    db '                                                        '
    db 'CD-ROM BASE               : PRI.SLAVE       - +   APPLY '
    db '                                                        '
    db 'HARDDISK-1 BASE           : PRI.MASTER      - +   APPLY '
    db '                                                        '
    db 'SYSTEM LANGUAGE           : ENGLISH         - +   APPLY '
    db '                                                        '
    db 'KEYBOARD LAYOUT           : ENGLISH         - +   APPLY '
    db '                                                        '
    db 'WINDOWS SOUND SYSTEM BASE : 0x200           - +   APPLY '
    db '                                                        '
    db 'FAT32-1 PARTITION IN HD-1 : 1               - +   APPLY '
    db '                                                        '
    db 'SOUND DMA CHANNEL         : 1               - +   APPLY '
    db '                                                        '
    db 'LBA READ ENABLED          : OFF             - +   APPLY '
    db '                                                        '
    db 'PCI ACCESS FOR APPL.      : OFF             - +   APPLY '
    db '                                                        '
    db '                                                        '
    db 'NOTE: TEST FAT32 FUNCTIONS WITH EXTREME CARE            '
    db '                                                        '
    db 'x                                                       '
   
   
keyboard  dd 0x0
midibase  dd 0x320
cdbase    dd 0x2
sb16      dd 0x220
syslang   dd 0x1
wss       dd 0x1
wssp      dd 0x0
hdbase    dd 0x1
f32p      dd 0x1
sound_dma dd 0x1
lba_read  dd 0x0
pci_acc   dd 0x0
   
   

window_label:

    db   'SETUP',0
  
   
hex db   '0123456789ABCDEF'
   
alt_general:
   
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
                                                     

en_keymap:
   
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
   
   
en_keymap_shift:
   
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
   
   
fr_keymap:
   
     db   '6',27
     db   '&Œ"',39,'(-Õ_”–)=',8,9
     db   'azertyuiop^$',13
     db   '~qsdfghjklm“',0,0,'*wxcvbn,;:!',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   
   
   
fr_keymap_shift:
   
   
     db   '6',27
     db   '1234567890+',8,9
     db   'AZERTYUIOP’‘',13
     db   '~QSDFGHJKLM%',0,'÷WXCVBN?./',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   

fr_keymap_alt_gr:
   
   
     db   '6',27
     db   28,'~#{[|ÿ\^@]}',8,9
     db   'azertyuiop^$',13
     db   '~qsdfghjklm“',0,0,'*wxcvbn,;:!',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   

   
   
fi_keymap:
   
     db   '6',27
     db   '1234567890+[',8,9
     db   'qwertyuiop',192,'~',13
     db   '~asdfghjkl',194,193,'1',0,39,'zxcvbnm,.-',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   
   
fi_keymap_shift:
   
     db   '6',27
     db   '!"#œ%&/()=?]',8,9
     db   'QWERTYUIOP',200,'~',13
     db   '~ASDFGHJKL',202,201,'1',0,'*ZXCVBNM;:_',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   
   
   
ge_keymap:
   
     db   '6',27
     db   '1234567890?[',8,9
     db   'qwertzuiop',203,'~',13
     db   '~asdfghjkl',194,193,'1',0,39,'yxcvbnm,.-',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   
   
ge_keymap_shift:
   
     db   '6',27
     db   '!"#$%&/()=',197,']',8,9
     db   'QWERTZUIOP',195,'~',13
     db   '~ASDFGHJKL',202,201,'1',0,'*YXCVBNM;:_',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   
ru_keymap:
   
     db   '6',27
     db   '1234567890-[',8,9
     db   169,230,227,170,165,173,163,232,233,167,229,234,13
     db   0,0xe4,235,162,160,175,224,174,171,164,166,237
     db   '--/'
     db   239,231,225,172,168,226,236,161,238,'.-','45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   
   
ru_keymap_shift:
   
     db   '6',27
     db   '!"N;:?*()_+]',8,0
     db   137,150,147,138,0x85,141,131,152,153,135,0x95,154,13
     db   0,0x94,155,130,128,143,144,142,139,132,134,157
     db   '--\'
     db   159,151,145,140,136,146,156,129,158,',-','45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

ptbr_keymap:

     db   '6',27
     db   '1234567890-=',8,9
     db   'qwertyuiop',39,'[',13
     db   '~asdfghjklc','~',44,0,']','zxcvbnm,.;',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB\D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDE/GHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


ptbr_keymap_shift:

     db   '6',27
     db   '!@#$%"&*()_+',8,9
     db   'QWERTYUIOP',96,'{',13
     db   '~ASDFGHJKLC','^','"',0,'}','ZXCVBNM<>:',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB|D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDE?GHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

   
   
I_END:
   
   
   
   
   
   
   

