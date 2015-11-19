;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   Kernel32.inc (c) Ville Turjanmaa
;;   License: GPL. See file copying for details.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
;% +include
   
; processes

include "SYS32.INC"    ; process scheduling

; shutdown

include "SHUTDOWN.INC" ; shutdown or restart

; file system

include "FS.INC"       ; syscall
include "FAT32.INC"    ; read / write
include "RD.INC"       ; ramdisk read / write

; sound
   
include "SB16.INC"     ; playback for Sound Blaster 16
   
; display
   
include "VESA12.INC"   ; Vesa 1.2 functions
include "VESA20.INC"   ; Vesa 2.0 functions
include "VGA.INC"      ; VGA 16 color functions
   
; Network Interface & TCPIP Stack
   
include "STACK.INC"
   
; Mouse pointer
   
include "MOUSE.INC"
   
; Window skinning
   
include "SKINCODE.INC"
   
; Pci functions

include "PCI32.INC"

; Floppy drive controller

include "FDC.INC"

; EGA

include "EGA.INC"

; MIDI

include "MIDI.INC"

;% -include
   
   
   
   
   
   
