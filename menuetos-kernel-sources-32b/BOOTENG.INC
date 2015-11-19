;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   Bootdata.inc (c) Ville Turjanmaa
;;   License: GPL. See file copying for details.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
macro line_full_top {

    db    201
    times 78 db 205
    db    187

}

macro line_full_bottom {

    db    200
    times 78 db 205
    db    188

}

macro line_half {

    db    186,' '
    times 76 db 0xc4
    db    ' ',186

}

macro line_space {

    db    186
    times 78 db 32
    db    186

}

d80x25:

    line_full_top
    line_space
    line_space
    line_half
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    line_space
    db    186,' MenuetOS comes with ABSOLUTELY NO WARR'
    db    'ANTY; See file COPYING for details     ',186
    line_full_bottom
   
novesa:

    db    "Display: EGA/CGA",13,10,0

vervesa:

    db    "Display bios: Vesa x.x ",13,10,0

video_md:
gr_mode:

    db    186," Vesa 2.0+ 16 M LFB:  [1] 640x480, [2] 800x600, "
    db    "[3] 1024x768, [4] 1280x1024",13,10
    db    186," Vesa 1.2  16 M Bnk:  [5] 640x480, [6] 800x600, "
    db    "[7] 1024x768, [8] 1280x1024",13,10
    db    186," EGA/CGA   256 Cols:  [9] 320x200, "
    db    "VGA 16 Cols: [0]  640x480",13,10
    db    186," Select mode ? ",0

bt24:

    db    " BPP:24",13,10,0

bt32:

    db    " BPP:32",13,10,0

mouse_md:
askmouse:

    db    13,10,186," Mouse at:"
    db    " [1] PS/2 (USB), [2] Com1, [3] Com2."
    db    " Select port [1-3] ? ",0

accel_md:
gr_acc:

    db    13,10,186," Vesa 2.0+ : MTRR graphics acceleration "
    db    "[1-yes/2-no] ? ",0

gr_direct:

    db    186," Direct LFB write, paging disabled "
    db    "[1-yes/2-no] ? ",0

ram_szcd:
mem_model:

    db    13,10,186," RAM in MB's [1-32 / "
    db    "2-64 / 3-128 / 4-256 /"
    db    " 5-512 / 6-1024 / 7-2048] ? ",0

bootlog:

    db    13,10,186," After bootlog display [1-continue/2-pause] ? ",0

boot_md:
bdev:

    db    13,10,186
    db    " Load disk image from [1-floppy (default) / "
    db    "2-hd/msetup.exe (hdboot.txt)] ? ",0
    db    13,10,186,"                    "
    db    "3-use preloaded ram-image from kernel restart] ? ",0

probe_md:
probetext:

    db    13,10,13,10,186," Use preset graphics mode [1-yes, "
    db    "2-probe bios (Vesa 3.0)] ? ",0

prid:

    db    " pr:",0

prnotfnd:

    db    " pr. - not found.",0

modena:

    db    "Fatal - VBE 0x112+ required.",0

not386:

    db    "Fatal - CPU 386+ required.",0

btns:

    db    13,10,186," Fatal - 24 or 32 bpp.",0

memmovefailed:

    db    "Fatal - Int 0x15 move failed.",0

fatalsel:

    db    13,10,"Fatal - Graphics mode not supported by hardware.",0

badsect:

    db    13,10,186," Fatal - Bad sector. Replace floppy. ",0

badcalc:

    db    "Fatal - Sector calculation. Format floppy. ",0

linef2:

    db    13,10

linef:

    db    13,10,0

okt:

    db    " ... OK",0

keyin:

    db    "x",0

keyinbs:

    db    "x",8,0

diskload:

    db    13,10,"º Updating floppy cache: 00 %",8,8,8,8,0

backspace:

    db    8,0

pros:

    db    "00",8,8,0

leftpr:

    db    186," ",0

boot_dev:

    db    0  ; 0=floppy, 1=hd
   

