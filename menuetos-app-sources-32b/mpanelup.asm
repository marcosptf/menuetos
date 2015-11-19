;
;   PANEL APPLICATION
;
;   Compile with FASM for Menuet
;


use32

               org    0x0

               db     'MENUET01'        ; 8 byte id
               dd     0x01              ; header version
               dd     START             ; start of code
               dd     I_END             ; size of image ; could be much less
               dd     0x100000          ; memory for app
               dd     0x7fff0           ; esp
               dd     0x0 , 0x0         ; I_Param , I_Icon

; Constants


OSWORKAREA          equ I_END       ; Place for OS work area, 16KB

BPP                 equ 3           ; Number of bytes per pixel
BMPHEADER           equ 18*3        ; Header part of bmp file

PANEL_DEPTH         equ 42          ; Number of rows in panel image
PANEL_MAX_WIDTH     equ 1280        ; Maximum width of Panel image

; This is also a temporary work area for building the free-form
; window data
PANEL_AREA          equ OSWORKAREA + 0x4000 

; memory location of 'constructed' image prior to display
PANEL_IMAGE         equ PANEL_AREA + ( PANEL_DEPTH * PANEL_MAX_WIDTH )

; memory location of main bmp image read in from ram disk
BMP_1               equ PANEL_IMAGE + ( BPP * PANEL_DEPTH * PANEL_MAX_WIDTH )
BMP_1_WIDTH         equ 140         ; The width of the original image
BMP_1_DEPTH         equ PANEL_DEPTH ; The height of the panel image

BMP_SCL             equ 1024 + BMP_1 + BMPHEADER + (BPP * BMP_1_DEPTH \
                                                           * BMP_1_WIDTH)
BMP_SCL_WIDTH       equ 14         ; The width of the original image
BMP_SCL_DEPTH       equ 26         ; The height of the panel image

BMP_SCC             equ 1024 + BMP_SCL + BMPHEADER + (BPP * BMP_SCL_DEPTH \
                                                          * (BMP_SCL_WIDTH+3))
BMP_SCC_WIDTH       equ 6          ; The width of the original image
BMP_SCC_DEPTH       equ 26         ; The height of the panel image

BMP_SCR             equ 1024 + BMP_SCC + BMPHEADER + (BPP * BMP_SCC_DEPTH \
                                                          * (BMP_SCC_WIDTH+3))
BMP_SCR_WIDTH       equ 18         ; The width of the original image
BMP_SCR_DEPTH       equ 26         ; The height of the panel image

BMP_BC              equ 1024 + BMP_SCR + BMPHEADER + (BPP * BMP_SCR_DEPTH \
                                                          * (BMP_SCR_WIDTH+3))
BMP_BC_WIDTH        equ 47         ; The width of the original image
BMP_BC_DEPTH        equ 34         ; The height of the panel image


; Reserve 13 bytes for each entry - the 12 bytes of the appname plus 1 null
RUNNINGAPPS         equ 1024 + BMP_BC + BMPHEADER + (BPP * BMP_BC_DEPTH \
                                                           * (BMP_BC_WIDTH+3))

CLOCK_X             equ 155
CLOCK_Y             equ 6
CLOCK_COLOUR        equ 0x00000000

APP_X               equ 217
APP_Y               equ 6
APP_INC             equ 32
APP_COLOUR          equ 0x00808080





;***************************************************************************
;   Function
;      START
;
;   Description
;       Entry point of the application
;
;***************************************************************************
START:
    ; Get the screen resolution
    mov     eax,14
    int     0x40
    
    movzx   ebx, ax
    mov     [scrSizeY], ebx
    shr     eax, 16
    mov     [scrSizeX], eax
    
    
    ; Read the Panel bitmaps
    call    readBitmaps
    
    ; Calculate how many processes are running
    call    numRunningApps
    
    ; Read the name strings of running apps
    call    readAppNames

    ; Create the panel image
    call    buildDefaultPanel

    ; Create the free-form window definition, and apply it    
    call    setWindowForm

    call    draw_window

still:

    mov     eax, 23                  ; wait here for event
    mov     ebx, 100
    int     0x40

    cmp     eax,1                   ; redraw request ?
    je      red
    cmp     eax,2                   ; key in buffer ?
    je      key
    cmp     eax,3                   ; button in buffer ?
    je      button
    
    ; Just redraw the clock, and check for a change in running apps
    call    numRunningApps
    cmp     ebx, 0
    je      showclock
    
    ; Redraw the panel bar.
    call    readAppNames
    call    buildDefaultPanel
    call    draw_window
    call    showTime
    jmp     still
    
showclock:    
    mov     eax, 3                      ; Get time
    int     0x40
    and     eax, 0x00FF0000
    cmp     [lastsecs], eax
    je      still
    call    showTime
    jmp     still

red:        
    ; Mouse button pressed?
    mov     eax, 37
    mov     ebx, 2
    int     0x40
    cmp     eax, 0
    je      nomenu

    ; get mouse x/y
    mov     eax, 37
    mov     ebx, 1
    int     0x40
    
    mov     ebx, eax
    shr     ebx, 16             ; ebx = x
    
    ; Is the mouse in the window?
    cmp     ebx, BMP_1_WIDTH - 10
    jae     nomenu
    
    ; Yes, so convert the y position to an index
    ; into the menu
    mov     ecx, eax
    and     ecx, 0xFFFF         ; ecx = y
    cmp     ecx, BMP_1_DEPTH - 5
    jae     nomenu

    mov     eax, 0
    jmp     dored
    
nomenu:
    mov     eax, -1

dored:

    push    eax
    call    draw_window
    pop     eax

    cmp     eax, 0
    jne     nodobutton
    call    dobutton
  nodobutton:

    jmp     still

key:                                ; key
    mov     eax,2                   ; just read it and ignore
    int     0x40
    jmp     still

button:                             ; button
    mov     eax,17                  ; get id
    int     0x40
    
    cmp     ah,1                    ; button id=1 ?
    jne     still

    call    dobutton
    jmp     still


dobutton:

    ; Mouse button released?

  red001:

    mov     eax , 5
    mov     ebx , 1
    int     0x40

    mov     eax, 37
    mov     ebx, 2
    int     0x40

    cmp     eax, 0
    jne     red001

    call    closeMenus
    
    ; Did we actually close any?
    cmp     eax, 0
    jne     nostill                  ; We closed some, so dont open
    
    ; Run the menu application
    mov     eax,58
    mov     ebx,startfile
    int     0x40

  nostill:

    mov     eax,17                  ; read buttons from buffer
    int     0x40

    ret

 ;   jmp     still


;***************************************************************************
;   Function
;      numRunningApps
;
;   Description
;       Reads the number of running apps. If it is different to last time,
;       ebx == 1, else ebx == 0
;
;***************************************************************************
numRunningApps:
    mov     eax, 9
    mov     ebx, OSWORKAREA             ; Temporary work area
    mov     ecx, -1
    int     0x40
    
    
    mov     ecx, eax
    mov     eax, 0
nra000:
    push    ecx
    push    eax
    mov     ebx, OSWORKAREA
    mov     eax, 9
    int     0x40
    pop     eax
    pop     ecx
    
    mov     esi, OSWORKAREA + 10    ; App name string
    cmp     [esi], dword '    '        
    je      nra001
    
    inc     eax
    
nra001:    
    loop    nra000
    
    xor     ebx, ebx
    cmp     eax, [numApps]
    je      @f
    mov     [numApps], eax
    inc     ebx
    
@@:
    ret


;***************************************************************************
;   Function
;      readAppNames
;
;   Description
;       Reads the names of the first 20 valid applications that are running
;       These will be displayed on the Panel bar.
;       Some running apps are ignored, because they are system apps; 
;       eg mpanel, mmenu, icon
;
;***************************************************************************
readAppNames:
    mov     ebx, [numApps]
    xor     edx, edx                ; edx counts app entries
    mov     ecx, edx
    mov     edi, RUNNINGAPPS

 inc ecx
    
ran001:    
    pusha
    mov     ebx, OSWORKAREA
    mov     eax, 9
    int     0x40
    popa
        
    ; if app name is not acceptable, skip
    ; save ecx, edx, edi
    mov     esi, OSWORKAREA + 10    ; App name string
    cmp     [esi], dword 'ICON'
    je      ran002
    cmp     [esi], dword 'PANE'
    je      ran002
    cmp     [esi], dword 'MPAN'
    je      ran002
    cmp     [esi], dword 'SELE'
    je      ran002
    cmp     [esi], dword 'MENU'
    je      ran002
    cmp     [esi], dword 'MMEN'
    je      ran002
    cmp     [esi], dword 'OS/I'
    je      ran002
    cmp     [esi], dword '    '
    jne     ran003

    inc     ebx
    jmp     ran002

ran003:
    push    ecx
    mov     ecx, 12
    mov     esi, OSWORKAREA + 10    ; App name string
    cld
    rep     movsb
    mov     [edi], byte 0
    inc     edi
    pop     ecx
    
    inc     edx
    cmp     edx, 20
    je      ranexit
    
ran002:    
    inc     ecx
    cmp     ecx, ebx
;    jne     ran001
  jna     ran001   
ranexit:    
    mov     [numDisplayApps], edx
    ret
    


;***************************************************************************
;   Function
;      closeMenus
;
;   Description
;       searches the process table for MMENU apps, and closes them
;       returns eax = 1 if any closed, otehrwise eax = 0
;
;***************************************************************************
closeMenus:

    mov     eax, 9
    mov     ebx, OSWORKAREA             ; Temporary work area
    mov     ecx, -1
    int     0x40
    
    mov     ecx, eax                    ; Get number of apps    
    
    xor     eax, eax                    ; Return value; 0 = no menus closed
    
cm001:
    pusha
    mov     eax, 9
    mov     ebx, OSWORKAREA             ; Temporary work area
    int     0x40                        ; get process info
    popa
    
    ; Is this 'me'? If it is, dont kill me yet!
    cmp     [OSWORKAREA + 30], ebx
    je      cm002
    
    ; Is this a MMENU app to kill?
    push    ecx
    mov     edi, appname
    mov     esi, OSWORKAREA + 10
    mov     ecx, 12
    repe    cmpsb
    cmp     ecx, 0
    pop     ecx
    jne     cm002

    ; Close the app
    push    eax
    mov     ebx, 2
    mov     eax, 18
    int     0x40
    pop     eax
    
    mov     eax, 1                      ; Indicate that we closed a menu
    
cm002:
    loop    cm001

    ret


;***************************************************************************
;   Function
;      buildDefaultPanel
;
;   Description
;       Constructs the panel picture by copying in small bits of the image
;       from pre-loaded bmp files
;
;***************************************************************************
buildDefaultPanel:
    mov     ecx, BMP_1_DEPTH
    mov     esi, BMP_1 + BMPHEADER
    mov     edi, PANEL_IMAGE
    cld     
fill1:
    push    ecx
    ; Copy the image..
    mov     ecx, BMP_1_WIDTH * BPP
    rep     movsb
    ; Now fill to right hand side of screen
    ; This copied not just the image, but the
    ; 'shape' of the image ( the black part )
    mov     ecx, [scrSizeX]
    sub     ecx, BMP_1_WIDTH
    mov     eax, [edi-3]
fill2:
    mov     [edi], eax
    add     edi, 3
    loop    fill2      
    pop     ecx
    loop    fill1

    mov     edi, PANEL_IMAGE + (BMP_1_WIDTH * BPP)

    ; Display the slot for the time
    mov     ecx, 5
    call    drawSlot

    ; Calculate where the last slot can be displayed
    mov     ebx, [scrSizeX]     ; The length of each screen line, in bytes
    imul    ebx, BPP
    mov     edx, PANEL_IMAGE
    add     edx, ebx            ; The top righthand pos
    sub     edx, (BMP_BC_WIDTH+BMP_SCL_WIDTH+(8*BMP_SCC_WIDTH)+ \
                                                      BMP_SCR_WIDTH) * BPP
     
    mov     ecx, 0
    mov     esi, RUNNINGAPPS
bdp000:
    cmp     ecx, [numDisplayApps]
    je      bdp001              ; Displaying all apps, so finish
    push    ecx
    push    edx
    push    esi
    call    strLen     
    call    drawSlot
    pop     esi
    pop     edx
    pop     ecx
    inc     ecx
    add     esi, 13
    cmp     edi, edx     
    jbe     bdp000              ; Run out of space to display
    
bdp001:  
    mov     [displayedApps], ecx

    ; Now the closing part of the big curve
    mov     ecx, BMP_BC_DEPTH
    mov     esi, BMP_BC + BMPHEADER
       
    mov     ebx, [scrSizeX]     ; The length of each screen line, in bytes
    imul    ebx, BPP
    
    mov     edx, PANEL_IMAGE
    add     edx, ebx            ; The top righthand pos
    
fill6:
    push    ecx
    push    edi
    ; Copy the image..
    push    esi
    mov     ecx, BMP_BC_WIDTH * BPP
    rep     movsb
    
    mov     eax, [edi-3]
fill6_1:
    mov     [edi], eax
    add     edi, 3
    cmp     edi, edx
    jb      fill6_1

    
    pop     esi
    add     esi, ((BMP_BC_WIDTH * BPP) + 3) and 0xFFFC
    pop     edi
    add     edi, ebx            ; Move down one line
    add     edx, ebx
    pop     ecx
    loop    fill6

    ret



;***************************************************************************
;   Function
;      strLen
;
;   Description
;       Returns the length of string at esi in ecx
;       string is 'terminated' by null or space
;
;***************************************************************************
strLen:
    push    esi

    dec     esi
    xor     ecx, ecx
sl001:
    inc     esi
    cmp     [esi], byte '0'
    je      slexit
    cmp     [esi], byte ' '
    je      slexit
    inc     ecx
    jmp     sl001
slexit: 
    pop     esi   

    ret    



;***************************************************************************
;   Function
;      drawSlot
;
;   Description
;       Copies a time/appname slot into the panel image
;       location ( top line position ) pointed to by edi
;       width ( number of characters ) in ecx
;
;***************************************************************************
drawSlot:
    ; Add in the small curve for the clock
    ; Note, we do funny maths here because the bmp image
    ; is stored with a multiple of 4 pixels per row
    
    push    ecx                 ; save num characters
    
    mov     ecx, BMP_SCL_DEPTH
    mov     esi, BMP_SCL + BMPHEADER
    
    push    edi
       
    mov     ebx, [scrSizeX]     ; The length of each screen line, in bytes
    imul    ebx, BPP
       
fill3:
    push    ecx
    push    edi
    ; Copy the image..
    push    esi
    mov     ecx, BMP_SCL_WIDTH * BPP
    rep     movsb
    pop     esi
    add     esi, ((BMP_SCL_WIDTH * BPP) + 3) and 0xFFFC
    pop     edi
    add     edi, ebx            ; Move down one line
    pop     ecx
    loop    fill3
    
    pop     edi    
    add     edi, BMP_SCL_WIDTH * BPP


    mov     ebx, [scrSizeX]     ; The length of each screen line, in bytes
    imul    ebx, BPP
    pop     ecx
fill4_1:
    push    edi
    push    ecx
    
    mov     ecx, BMP_SCC_DEPTH
    mov     esi, BMP_SCC + BMPHEADER
       
fill4:
    push    ecx
    push    edi
    ; Copy the image..
    push    esi
    mov     ecx, BMP_SCC_WIDTH * BPP
    rep     movsb
    pop     esi
    add     esi, ((BMP_SCC_WIDTH) * BPP + 3) and 0xFFFC
    pop     edi
    add     edi, ebx            ; Move down one line
    pop     ecx
    loop    fill4

    pop     ecx
    pop     edi
    add     edi, BMP_SCC_WIDTH * BPP
    loop    fill4_1


    ; Now the closing part of the small curve
    mov     ecx, BMP_SCR_DEPTH
    mov     esi, BMP_SCR + BMPHEADER
       
    mov     ebx, [scrSizeX]     ; The length of each screen line, in bytes
    imul    ebx, BPP
 
    push    edi
          
fill5:
    push    ecx
    push    edi
    ; Copy the image..
    push    esi
    mov     ecx, BMP_SCR_WIDTH * BPP
    rep     movsb
    pop     esi
    add     esi, ((BMP_SCR_WIDTH * BPP) + 3) and 0xFFFC
    pop     edi
    add     edi, ebx            ; Move down one line
    pop     ecx
    loop    fill5

    pop     edi
    
    add     edi, BMP_SCR_WIDTH * BPP 

    ret



;***************************************************************************
;   Function
;      setWindowForm
;
;   Description
;       Scans the panel image looking for the curved outline, so it can 
;       generate a free-form outline window
;
;***************************************************************************
setWindowForm:
    ; Create the free-form pixel map;
    ; black is the 'ignore' colour
    mov     esi,0
    
    mov     edx, [scrSizeX]
    imul    edx, PANEL_DEPTH
    
newpix:
    mov     eax,[ PANEL_IMAGE + esi*BPP]
    mov     bl,0
    and     eax,0xffffff
    cmp     eax,0x000000
    je      cred
    mov     bl,1

cred:
    mov     [esi+ PANEL_AREA ],bl
    inc     esi
    cmp     esi,edx
    jbe     newpix

    ; set the free-form window in the OS
    mov  eax,50
    mov  ebx,0
    mov  ecx,PANEL_AREA
    int  0x40
    ret
    
    

;***************************************************************************
;   Function
;      readBitmaps
;
;   Description
;       Loads the picture elements used to construct the panel image
;
;***************************************************************************
readBitmaps:
    ; Main panel button, plus curves
    mov     eax, 58
    mov     ebx, pbutton
    int     0x40
    mov     eax, 58
    mov     ebx, scc
    int     0x40
    mov     eax, 58
    mov     ebx, scl
    int     0x40
    mov     eax, 58
    mov     ebx, scr
    int     0x40
    mov     eax, 58
    mov     ebx, bc
    int     0x40    
    ret
    


;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************
draw_window:
    mov     eax,12                     ; function 12:tell os about windowdraw
    mov     ebx,1                      ; 1, start of draw
    int     0x40

                                    ; DRAW WINDOW
    mov     eax,0                      ; function 0 : define and draw window
    mov     ebx, [scrSizeX]
    dec     ebx
    mov     ecx,0*65536+PANEL_DEPTH             ; [y start] *65536 + [y size]
    mov     edx,0x01000000 ; 0x02ffffff  ; col of work area RRGGBB,8->color gl
    mov     esi,0x815080d0             ; color of grab bar  RRGGBB,8->color gl
    mov     edi,0x005080d0             ; color of frames    RRGGBB
    int     0x40

                                    ; MENU BUTTON
    mov     eax,8                      ; function 8 : define and draw button
    mov     ebx,0*65536+BMP_1_WIDTH - 10    ; [x start] *65536 + [x size]
    mov     ecx,0*65536+BMP_1_DEPTH - 5    ; [y start] *65536 + [y size]
    mov     edx,0x60000001             ; button id
    mov     esi,0x6688dd               ; button color RRGGBB
    int     0x40

                                    ; Place the image on the screen
    mov     eax,7
    mov     ebx,PANEL_IMAGE    
    mov     ecx, [scrSizeX]
    shl     ecx, 16
    add     ecx, PANEL_DEPTH
    mov     edx,0
    int     0x40
    
    call    showTime                    ; display the time
    call    showApps                    ; You can guess what this does
    
    mov     eax,12                    ; function 12:tell os about windowdraw
    mov     ebx,2                     ; 2, end of draw
    int     0x40

    ret




;***************************************************************************
;   Function
;      showTime
;
;   Description
;       Updates the time on the panel
;
;***************************************************************************
showTime:
    ; blank out old time    
    mov     eax,7
    mov     ebx,PANEL_IMAGE + (CLOCK_X * BPP)    
    mov     ecx, (BMP_SCC_WIDTH * 5 * 65536) + 1
    mov     edx,CLOCK_X * 65536 + CLOCK_Y
st001:
    pusha
    int     0x40
    popa
    inc     edx
    cmp     edx, CLOCK_X * 65536 + CLOCK_Y + 8    
    jne     st001
    
    call    setTimeStr

    mov     eax, 4                     ; Write text to display
    mov     ebx, (CLOCK_X * 65536) + CLOCK_Y
    mov     ecx, CLOCK_COLOUR
    mov     edx, clockStr
    mov     esi, 5                  ; 5 digits in clock hh:mm
    int     0x40  
    ret
    


;***************************************************************************
;   Function
;      showApps
;
;   Description
;       Writes the application names to the display
;
;***************************************************************************
showApps:
    mov     esi, RUNNINGAPPS
    mov     ebx, (APP_X * 65536) + APP_Y
    
    mov     ecx, [displayedApps]
    
    cmp     ecx, 0
    jne     sa001
    ret

sa001:
    pusha
    call    strLen                      ; ecx has length of string @ esi
    mov     edx, esi
    mov     esi, ecx

    mov     eax, 4                     ; Write text to display
    mov     ecx, APP_COLOUR
    int     0x40
    popa
    push    ecx
    call    strLen                      ; ecx has length of string @ esi
    imul    ecx, 6
    add     ecx, APP_INC
    shl     ecx, 16
    add     ebx, ecx
    pop     ecx
    add     esi, 13
    loop    sa001
    ret

    

;***************************************************************************
;   Function
;      setTimeStr
;
;   Description
;       Reads the time and places it in a string.
;       The : character is alternated every second
;
;***************************************************************************
setTimeStr:
    mov     eax, 3                      ; Get time
    int     0x40
    mov     ecx, '0'
    mov     ebx, eax
    and     ebx, 0xF0
    shr     ebx, 4
    add     ebx, ecx
    mov     [clockStr], bl
    mov     ebx, eax
    and     ebx, 0x0F
    add     ebx, ecx
    mov     [clockStr+1], bl
    mov     ebx, eax
    and     ebx, 0xF000
    shr     ebx, 12
    add     ebx, ecx
    mov     [clockStr+3], bl
    mov     ebx, eax
    and     ebx, 0x0F00
    shr     ebx, 8
    add     ebx, ecx
    mov     [clockStr+4], bl

    and     eax, 0x00FF0000
    mov     [lastsecs], eax
    
    mov     bl, ':'
    and     eax, 0x00010000
    cmp     eax, 0
    je      sts001
    mov     bl, ' '
sts001:
    mov     [clockStr+2], bl

    ret



; Data area
lastsecs    dd  0
scrSizeX    dd  0                   ; Resolution of screen
scrSizeY    dd  0                   ; Resolution of screen
appname     db  'MMENU       '
numApps     dd  0                   ; Number of running applications
numDisplayApps  dd 0
displayedApps   dd  0

clockStr    db '12:34'

pbutton:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_1                       ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/mpanel.bmp',0

scl:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_SCL                     ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/scl.bmp',0

scc:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_SCC                     ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/scc.bmp',0

scr:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_SCR                     ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/scr.bmp',0
    
bc:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_BC                      ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/bc.bmp',0


startfile:
    dd  16                          ; Start file option
    dd  0                           ; Reserved, 0
    dd  params                      ; Parameters - MAINMENU
    dd  0                           ; Reserved, 0
    dd  OSWORKAREA                  ; OS work area - 16KB
    db  '/rd/1/mmenu',0
params:
    db  'MAINMENU 9 28',0

I_END:




