; original version; uses buttons.
; suffers from needing a long keypress before submenu opens when menu is overlapped
; Also, should close other submenus (children!) when opening a new menu


;
;   MENU APPLICATION
;
;   Compile with FASM for Menuet
;


; Constants


OPTIONSFILE         equ I_END + 256 ; Place for Menu Options File (8KB)
MENUTABLE           equ OPTIONSFILE + 8192 ; Place for Menu Table, 8KB
OSWORKAREA          equ MENUTABLE + 8192   ; Place for OS work area, 16KB

BPP                 equ 3           ; Number of bytes per pixel
BMPHEADER           equ 18*3        ; Header part of bmp file

MENU_MAX_DEPTH      equ 1024        ; Maximum depth of menu image
MENU_WIDTH          equ 120         ; Maximum width of Panel image

; This is also a temporary work area for building the free-form
; window data
MENU_AREA           equ OSWORKAREA + 0x4000 

; memory location of 'constructed' image prior to display
MENU_IMAGE          equ MENU_AREA + ( MENU_MAX_DEPTH * MENU_WIDTH )

; memory location of main bmp image read in from ram disk
BMP_MT              equ MENU_IMAGE + ( BPP * MENU_MAX_DEPTH * MENU_WIDTH )
BMP_MT_WIDTH        equ MENU_WIDTH  ; The width of the original image
BMP_MT_DEPTH        equ 20          ; The height of the bitmap image
BMP_MTF_DEPTH       equ 5           ; The heigth of the submenu top image

BMP_MC              equ 1024 + BMP_MT + BMPHEADER + (BPP * BMP_MT_DEPTH \
                                                       * (BMP_MT_WIDTH+3))
BMP_MC_WIDTH        equ MENU_WIDTH ; The width of the original image
BMP_MC_DEPTH        equ 34         ; The height of the bitmap image

BMP_MB              equ 1024 + BMP_MC + BMPHEADER + (BPP * BMP_MC_DEPTH \
                                                        * (BMP_MC_WIDTH+3))
BMP_MB_WIDTH        equ MENU_WIDTH ; The width of the original image
BMP_MB_DEPTH        equ 54         ; The height of the bitmap image

ICON_FILE           equ 1024 + BMP_MB + BMPHEADER + (BPP * BMP_MB_DEPTH \
                                                        * (BMP_MB_WIDTH+3))


use32

               org    0x0

               db     'MENUET01'        ; 8 byte id
               dd     0x01              ; header version
               dd     START             ; start of code
               dd     I_END             ; size of image ; could be much less
               dd     0x100000          ; memory for app
               dd     0x7fff0           ; esp
               dd     I_Param , 0x0         ; I_Param , I_Icon




;***************************************************************************
;   Function
;      START
;
;   Description
;       Entry point of the menu application
;
;***************************************************************************
START:   
    ; Look at the input params - Menuname and position
    call    parseParams
    
    ; Read Menu options from file
    call    readMenuOptions
    
    ; Read the bitmaps
    call    readBitmaps
    
    ; Copy bitmaps into menu image
    call    buildMenuImage
        
    ; Create the free-form window definition, and apply it    
    call    setWindowForm
    
    call    renderIcons    
    
    call    draw_window

    mov     eax,60                 ; IPC
    mov     ebx,1                  ; define receive area
    mov     ecx,received_messages  ; pointer to start
    mov     edx,1000               ; size of area
    int     0x40


    mov     eax,40                 ; WANTED EVENTS
    mov     ebx,01000111b          ; IPC 7 + defaults
    int     0x40
    mov  [received_messages+8],dword 0*256+0
    mov  [received_messages+12],dword 0


still:

    mov     eax, 23                  ; wait here for event
    mov     ebx, 200
    int     0x40

    cmp     eax,1                   ; redraw request ?
    je      red
    cmp     eax,2                   ; key in buffer ?
    je      key
    cmp     eax,3                   ; button in buffer ?
    je      button
    cmp     eax, 7
    je      IPC
    
    ; Close app after 5 seconds of no activity - disabled
;;    mov     eax, -1
;;    int     0x40
    jmp     still

IPC:
    ; Tell any child menus to close, then close myself
    cmp     [childPID], dword 0
    je      noSub
    
    mov     ecx, [childPID]
    mov     eax,9
    mov     ebx,OSWORKAREA
    int     0x40
    mov     ecx, dword [OSWORKAREA + 30]

    mov     eax,60                 ; IPC
    mov     ebx,2                  ; send message
    mov     edx,received_messages  ; Send any data
    mov     esi, 4
    int     0x40
      
noSub:


    mov     eax, -1
    int     0x40
    jmp     still    


red:                                ; redraw 
    ; get mouse x/y
    mov     eax, 37
    mov     ebx, 1
    int     0x40
    
    mov     ebx, eax
    shr     ebx, 16             ; ebx = x
    
    ; Is the mouse in the window?
    cmp     ebx, MENU_WIDTH
    jae     nomenu
    
    ; Yes, so convert the y position to an index
    ; into the menu
    mov     ecx, eax
    and     ecx, 0xFFFF         ; ecx = y
    
    mov     eax, ecx
    
    ; The 'buttons' start part way down the menu
    ; so add the appropriate offset
    mov     ecx, BMP_MT_DEPTH
    cmp     [menuType], byte 'M'
    je     @f
    mov     ecx, BMP_MTF_DEPTH
@@:
    
    cmp     eax, ecx
    jb      nomenu
    sub     eax, ecx
    
    xor     edx, edx
    mov     ecx, 34
    div     ecx
    
    ; Make sure we do not go 'below' the last button
    cmp     eax, [numOptions]
    jae     nomenu  
    
    cmp     eax, [lastButton]
    je      nomenu
    mov     [lastButton], eax    
    
    ; Mouse button pressed?
    mov     eax, 37
    mov     ebx, 2
    int     0x40
    
    cmp     eax, 0
    je      nomenu
    mov     eax, [lastButton]    
             
    jmp     dored 
 
nomenu: 
    mov     eax, -1

dored:
    push    eax
    call    draw_window
    pop     eax
    
    cmp     eax, -1
    je      still
    
    shl     eax, 4                  ; Get button id

    jmp     dobutton

key:                                ; key
    mov     eax,2                   ; just read it and ignore
    int     0x40
    jmp     still

button:                             ; button
    mov     eax,17                  ; get id
    int     0x40

    shr     eax,8                   ; Get button id

dobutton:
    ; Application or Menu?
    mov     ebx, [MENUTABLE + eax + 4]
    cmp     [ebx], byte 'A'
    je      launchApp
    
    call    runMenu
    jmp     still

launchApp:
    call    runApp
    
    ; Give a small delay - simultaneous app open / close is a problem
    ; in the kernel
    mov     eax, 5
    mov     ebx, 50
    int     0x40

;;    call    closeMenus      
;;    ; Close me!
;;    mov     eax, -1
;;    int     0x40
    jmp     still



;***************************************************************************
;   Function
;      closeMenus
;
;   Description
;       searches the process table for MMENU apps, and closes them
;
;***************************************************************************
closeMenus:

    ; Who am i :o)
    mov     eax, 9
    mov     ebx, OSWORKAREA             ; Temporary work area
    mov     ecx, -1
    int     0x40
    
    mov     ebx, [OSWORKAREA + 30]      ; Get my PID
    mov     edi, appname
    mov     esi, OSWORKAREA + 10        ; Get app name, save
    mov     ecx, 12
    cld
    rep     movsb
    mov     ecx, eax                    ; Get number of apps
    
    
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
    mov     ebx, 2
    mov     eax, 18
    int     0x40
    
cm002:
    loop    cm001
       
    ret


runApp:
    ; Copy the filename across
    mov     esi, [MENUTABLE + eax + 12] 
    mov     edi, tmpfn
    mov     ecx, 256
    cld
    rep     movsb

    mov     eax, 16    
    mov     [tmpf], eax
    xor     eax, eax
    mov     [tmpf+4], eax
    mov     [tmpf+12], eax
    mov     eax, params
    mov     [tmpf+8], eax
    
    mov     [params], byte 0
    
    
    ; run the app
    mov     eax, 58
    mov     ebx, tmpf
    int     0x40    

    ret
    
    
    
runMenu:
    ; If we are already running a menu, tell it to close
    cmp     [childPID], dword 0
    je      rm00b
    
    push    eax

    mov     ecx, [childPID]
    mov     eax,9
    mov     ebx,OSWORKAREA
    int     0x40
    mov     ecx, dword [OSWORKAREA + 30]

    mov     eax,60                 ; IPC
    mov     ebx,2                  ; send message
    mov     edx,received_messages  ; Send any data
    mov     esi, 4
    int     0x40

    pop     eax
    
rm00b:
    ; Write in newX/Y the starting postion for the new menu
    ; open menu nearby the button we pressed
    push    eax         ; Our button number
    shr     eax, 4          
    imul    eax, 34
    add     eax, [startY]
    add     eax, 28
    cmp     [startX],dword MENU_WIDTH-10
    jbe     noyup
    sub     eax , 12
  noyup:
    mov     [newY], eax
    
    mov     eax, [startX]
    add     eax, MENU_WIDTH - 3
    mov     [newX], eax
    pop     eax
    mov     esi, [MENUTABLE + eax + 12] 
    mov     edi, params
    mov     ecx, 256
    cld
    rep     movsb
    
    ; Now write across the startx and starty positions
    mov     edi, params             ; Find the end of the first param
rm00a:
    inc     edi
    cmp     [edi], byte 0
    jne     rm00a
    
    mov     [edi], byte ' '
    mov     ecx, 4
    add     edi, ecx
    mov     eax, [newX]
    mov     ebx, 10
rm000:
    xor     edx, edx
    div     ebx
    add     dl, '0'
    mov     [edi], dl
    dec     edi
    loop    rm000
    
    add     edi, 5
        
    mov     [edi], byte ' '
    mov     ecx, 4
    add     edi, ecx
    mov     eax, [newY]
    mov     ebx, 10
rm001:
    xor     edx, edx
    div     ebx
    add     dl, '0'
    mov     [edi], dl
    dec     edi
    loop    rm001
    
    mov     [edi+5], byte 0
    
    mov     eax,58
    mov     ebx,startfile
    int     0x40
    
    mov     [childPID], eax
    
    ret



;***************************************************************************
;   Function
;      parseParams
;
;   Description
;       Looks at the input parameters; Are we the main menu, and where are 
;       we drawn?
;
;***************************************************************************
parseParams:
    mov     edi, I_Param
  
    ; set up Menu type variable
    mov      al, [edi]                   ; MAINMENU or SUBMENUxxx
    mov      [menuType], al    
    
pp001:
    inc     edi
    cmp     [edi], byte ' '
    jne     pp001
pp002:
    inc     edi
    cmp     [edi], byte ' '
    je      pp001
    
pp003:    
    mov     eax, [startX]
    imul    eax, 10
    movzx   ebx, byte [edi]
    sub     bl, byte '0'
    add     eax, ebx
    mov     [startX], eax
    inc     edi
    cmp     [edi], byte '0'
    jae     pp003

    inc     edi
    
pp004:    
    mov     eax, [startY]
    imul    eax, 10
    movzx   ebx, byte [edi]
    sub     bl, byte '0'
    add     eax, ebx
    mov     [startY], eax
    inc     edi
    cmp     [edi], byte '0'
    jae     pp004    
    
    ret



;***************************************************************************
;   Function
;      buildMenuImage
;
;   Description
;       Constructs the menu picture by copying in small bits of the image
;       from pre-loaded bmp files
;
;***************************************************************************
buildMenuImage:
    ; Note, we do funny maths here because the bmp image
    ; is stored with a multiple of 4 pixels per row

    xor     eax, eax
    mov     [menuDepth], eax
    
    mov     ecx, BMP_MT_DEPTH
    cmp     [menuType], byte 'M'
    je     @f
    mov     ecx, BMP_MTF_DEPTH
  @@:
    
    add     [menuDepth], ecx
    mov     esi, BMP_MT + BMPHEADER
    mov     edi, MENU_IMAGE
    cld     
fill1:
    push    ecx
    push    esi
    mov     ecx, BMP_MT_WIDTH * BPP
    rep     movsb
    pop     esi
    add     esi, ((BMP_MT_WIDTH * BPP) + 3) and 0xFFFC
    pop     ecx
    loop    fill1
    
      
    ; Add 1 centre bar for each option to be displayed
    mov     ecx, [numOptions]
    dec     ecx
fill2_1:    
    push    ecx  

    mov     ecx, BMP_MC_DEPTH
    add     [menuDepth], ecx
    mov     esi, BMP_MC + BMPHEADER
       
fill2:
    push    ecx
    push    esi
    mov     ecx, BMP_MC_WIDTH * BPP
    rep     movsb
    pop     esi
    add     esi, ((BMP_MC_WIDTH * BPP) + 3) and 0xFFFC
    pop     ecx
    loop    fill2
    pop     ecx
    loop    fill2_1

    mov     ecx, BMP_MB_DEPTH
    add     [menuDepth], ecx
    mov     esi, BMP_MB + BMPHEADER
       
fill3:
    push    ecx
    push    esi
    mov     ecx, BMP_MB_WIDTH * BPP
    rep     movsb
    pop     esi
    add     esi, ((BMP_MB_WIDTH * BPP) + 3) and 0xFFFC
    pop     ecx
    loop    fill3
    
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
    
    mov     edx, [menuDepth]
    imul    edx, MENU_WIDTH
    
newpix:
    mov     eax,[ MENU_IMAGE + esi*BPP]
    mov     bl,0
    and     eax,0xffffff
    cmp     eax,0x000000
    je      cred
    mov     bl,1

cred:
    mov     [esi+ MENU_AREA ],bl
    inc     esi
    cmp     esi,edx
    jbe     newpix

    ; set the free-form window in the OS
    mov  eax,50
    mov  ebx,0
    mov  ecx,MENU_AREA
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
    mov     ebx, mt
    cmp     [menuType], byte 'M'
    je     @f
    mov     ebx, mtf
  @@:
    int     0x40
    mov     eax, 58
    mov     ebx, mc
    int     0x40
    mov     eax, 58
    mov     ebx, mb
    int     0x40    
    ret



;***************************************************************************
;   Function
;      readMenuOptions
;
;   Description
;       using the application input parameter I-Param ( which specifies
;       the name of the menu ), builds the list of menu options.
;       This list is used to determine the size of the menu and the
;       icons, text that appear on the menu.
;       This updates numOptions and optionsList
;       I hate reading text files :o)
;
;***************************************************************************
readMenuOptions:
    xor     eax, eax
    mov     [numOptions], eax           ; Start with a empty list

    mov     eax, 58
    mov     ebx, optionsf
    int     0x40    

    cld
    mov     esi, OPTIONSFILE
    
    ; Skip through the file to our menu list, as defined by I_Params
    
rmo000a:    
    mov     edi, I_Param    
    
rmo000:
    inc     esi
    cmp     [esi-1], byte '['
    je      rmo001
    jmp     rmo000
    
rmo001:    
    cmpsb   
    je      rmo001
    ; If the last character was ], we have a match
    cmp     [esi-1],byte ']'            
    jne     rmo000a                     ; No? Then look for next
    
    ; Build menu table list
    mov     edi, MENUTABLE
rmoLoop:    
    ; Found correct submenu. 
    ; Skip any whitespace or comments, to get to first character of option
    call    skipWhite
    call    nextLine
    call    findParam
    cmp     [esi], byte '['             ; Have we come to the end of the list?
    je      rmoExit                     ; Yes, so we have finished
    
    ; Add menu item into the list
    inc     dword [numOptions]
    
    ; MENUTABLE is an array of menu options
    ; the format is
    ; dd pointer to menu text, asciiz
    ; dd pointer to option type string, asciiz 
    ; dd pointer to menu icon string, ascii z
    ; dd pointer to appname or submenu name, asciiz
    
    virtual at edi
      mtext  dd ?
      mopt   dd ?
      micon  dd ?
      mname  dd ?
    end virtual
    
    mov     [mtext], esi                ; Mark start of text string
    
rmo002:
    inc     esi
    cmp     [esi-1], byte ','
    jne     rmo002
    
    mov     [esi-1], byte 0             ; zero terminate ascii string
    call    skipWhite
    mov     [mopt], esi                ; Mark start of text string
    
rmo003:
    inc     esi
    cmp     [esi-1], byte ','
    jne     rmo003

    mov     [esi-1], byte 0             ; zero terminate ascii string
    call    skipWhite
    mov     [micon], esi                ; Mark start of text string
    
rmo004:
    inc     esi
    cmp     [esi-1], byte ','
    jne     rmo004

    mov     [esi-1], byte 0             ; zero terminate ascii string
    call    skipWhite
    mov     [mname], esi                ; Mark start of text string

    ; Finially, find the end of the line, and zero terminate it
rmo005:
    inc     esi
    cmp     [esi], byte 0x0a
    je      rmo006
    cmp     [esi], byte 0x0d
    je      rmo006
    cmp     [esi], byte 0x09
    je      rmo006
    cmp     [esi], byte ' '
    je      rmo006
    jmp     rmo005

rmo006:
    mov     [esi], byte 0             ; zero terminate ascii string

    add     edi, 16
    jmp     rmoLoop
    
rmoExit:
    ret
        


;***************************************************************************
;   Function
;       skipWhite
;
;   Description
;       skips any tabs or spaces
;
;***************************************************************************
skipWhite:
    mov     al, [esi]
    cmp     al, ' '
    je      sw002                   ; skip space char
    cmp     al, 0x09        
    je      sw002                   ; skip tab char
    ret

sw002:
    inc     esi
    jmp     skipWhite



;***************************************************************************
;   Function
;       nextLine
;
;   Description
;       skips to the beginning of the next line
;
;***************************************************************************
nextLine:
    mov     al, [esi]
    cmp     al, 0x0a
    je      nl002           ; We have reached the end
    cmp     al, 0x0d
    je      nl002
    inc     esi
    jmp     nextLine
    
nl002:                      ; Now skip the CR/LF bits
    inc     esi
    mov     al, [esi]
    cmp     al, 0x0a
    je      nl003                  
    cmp     al, 0x0d
    je      nl003
    ret                     ; Now at start of new line
        
nl003:
    inc     esi      
    ret                     ; Now at start of new line    
    
    

;***************************************************************************
;   Function
;       findParam
;
;   Description
;       skips comments and blank lines until the next parameter if found
;       source is in esi; dont touch edi
;
;***************************************************************************
findParam:
    mov     al, [esi]               ; get file character
    
    ; is it a comment line?
    cmp     al, '#'
    jne     fp002
    
    call    nextLine                ; Move to next line
    jmp     findParam
    
fp002:
    call    skipWhite               ; Move past any spaces
    
    ; Was it an empty line?
    mov     al, [esi]
    cmp     al, 0x0a
    je      fp003                   
    cmp     al, 0x0d
    je      fp003
    ret                             ; We have the parameter!

fp003:
    ; It was an empty line; Read past the end of line marker
    ; and return to findParam for next line
    inc     esi
    mov     al, [esi]
    cmp     al, 0x0a
    je      fp004                  
    cmp     al, 0x0d
    je      fp004
    jmp     findParam

fp004:
    inc     esi
    jmp     findParam




;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************


draw_window:
    mov     eax,12                     ; function 12:tell os about windowdraw
    mov     ebx,1                      ; 1, start of draw
    int     0x40

                                    ; DRAW WINDOW
    mov     eax,0                      ; function 0 : define and draw window
    mov     ebx, [startX] ;0 + MENU_WIDTH
    shl     ebx, 16
    add     ebx, MENU_WIDTH - 1
;    dec     ebx
    mov     ecx, [startY] ; 28 * 65536
    shl     ecx, 16
    add     ecx, [menuDepth]
    mov     edx,0x01000000 ; 0x02ffffff  ; col of work area RRGGBB,8->color gl
    mov     esi,0x815080d0             ; color of grab bar  RRGGBB,8->color gl
    mov     edi,0x005080d0             ; color of frames    RRGGBB
    int     0x40

    
    mov     ecx, [numOptions]
    mov     eax, 8                       ; function 8 : define and draw button
    mov     ebx, 0*65536+MENU_WIDTH      ; [x start] *65536 + [x size]
    mov     edx, 0x60000000             ; button id - 6 at front means no rect
    mov     esi, 0x6688dd                ; button color RRGGBB
    mov     edi, BMP_MT_DEPTH*65536 + 34 ; [y start] *65536 + [y size]
    cmp     [menuType], byte 'M'
    je     @f
    mov     edi, BMP_MTF_DEPTH*65536 + 34 ; [y start] *65536 + [y size]
@@:

dw001:
    pusha
    mov     ecx, edi
    int     0x40
    popa
    add     edi, 34 * 65536
    add     edx, 16                     ; Make button id offset into MENUTABLE
    loop    dw001
    
    ; Place the image on the screen
    mov     eax,7
    mov     ebx,MENU_IMAGE    
    mov     ecx, MENU_WIDTH * 65536
    add     ecx, [menuDepth]
    mov     edx,0
    int     0x40
    

    ; add the text labels to the menu
    mov     ecx, [numOptions]
    mov     edi, MENUTABLE
    mov     eax, 4                  ; Write text
    mov     ebx, 46 * 65536 + 32
    cmp     [menuType], byte 'M'
    je     @f
    mov     ebx, 46 * 65536 + 20
@@:

dwText:    
    pusha
    mov     edx, [edi]
    call    strLen                  
    xor     ecx, ecx                ; Black text
    int     0x40
    popa
    add     ebx, 34
    add     edi, 16
    loop    dwText
    
    mov     eax,12                    ; function 12:tell os about windowdraw
    mov     ebx,2                     ; 2, end of draw
    int     0x40

    ret


;***************************************************************************
;   Function
;      strLen
;
;   Description
;       Optimised to work with drawText: Returns length of string
;       string pointed to by edx
;       result in esi
;       ecx used as temp variable
;
;***************************************************************************
strLen:
    
    mov     esi, edx
    dec     esi
sl000:
    inc     esi
    cmp     [esi], byte 0
    jne     sl000
    sub     esi, edx
    
    ret


;***************************************************************************
;   Function
;      drawIcon
;
;   Description
;       Loads an icon file ( fname ) and renders it into the menu image
;       at the current position.
;       The icon must be 32x32, 24 bit colour. If it is a .ico file, It must
;       have an alpha channel, although it isn't used.
;
;       This is mike.dld's code, ripped from icon.asm
;
;       icon file name pointed to by esi
;       top left position to display icon in edi
;
;***************************************************************************
drawIcon:
    push    edi
    
    ; Copy the filename across
    mov     edi, tmpfn
    mov     ecx, 256
    cld
    rep     movsb
    
    xor     eax, eax
    mov     [tmpf], eax
    mov     [tmpf+4], eax
    dec     eax
    mov     [tmpf+8], eax
    mov     eax, ICON_FILE    
    mov     [tmpf+12], eax
    
    
    ; Read the .ico or .bmp file
    mov     eax, 58
    mov     ebx, tmpf
    int     0x40    


    ; What type of image file is it?
    mov     [itype],0
    cmp     word[ICON_FILE],'BM'
    je      @f
    inc     [itype]
  @@:
    
    pop     esi
    mov     ecx, esi

    ; esi points to menu image top left position
    ; We point to the end since the icon image is 'upside down'
    add     esi, (MENU_WIDTH * 31 * BPP)
    
    ; edi scans through icon image
    mov     edi,ICON_FILE+62 ; 6 - header, 16 - iconinfo, 40 - bitmapinfo
    cmp     [itype],0
    jne     @f
    mov     edi,ICON_FILE+54
  @@:
    xor     ebp,ebp

l00:
    push    ecx
    
    virtual at edi
      r  db ?
      g  db ?
      b  db ?
      a  db ?
    end virtual
    
    virtual at esi+ebp
      ar db ?
      ag db ?
      ab db ?
    end virtual

    movzx   cx,[a]
    
    cmp     [itype],0
    jne     @f
    mov     eax,[edi]
    and     eax,0x00ffffff
    test    eax,eax
    jnz     @f
    mov     al,[ar]
    mov     [esi+ebp+0],al
    mov     al,[ag]
    mov     [esi+ebp+1],al
    mov     al,[ab]
    mov     [esi+ebp+2],al
    jmp     no_transp
  @@:

    xor     eax,eax
    mov     al,[r]
    cmp     [itype],0
    je      @f
    movzx   bx,[ar]
    sub     ax,bx
    mov     bx,cx
    imul    bx
    xor     edx,edx
    mov     bx,255
    div     bx
    movzx   ebx,[ar]
    add     eax,ebx
  @@:
    mov     [esi+ebp+0],al

    xor     eax,eax
    mov     al,[g]
    cmp     [itype],0
    je      @f
    movzx   bx,[ag]
    sub     ax,bx
    mov     bx,cx
    imul    bx
    xor     edx,edx
    mov     bx,255
    div     bx
    movzx   bx,[ag]
    add     eax,ebx
  @@:
    mov     [esi+ebp+1],al

    xor     eax,eax
    mov     al,[b]
    cmp     [itype],0
    je      @f
    movzx   bx,[ab]
    sub     ax,bx
    mov     bx,cx
    imul    bx
    xor     edx,edx
    mov     bx,255
    div     bx
    movzx   bx,[ab]
    add     eax,ebx
  @@:
    mov     [esi+ebp+2],al

no_transp:
    pop     ecx
    add     edi,3
    add     edi,[itype]

    add     ebp,3
    cmp     ebp,32*3
    jl      l00
    
    xor     ebp,ebp

    sub     esi,MENU_WIDTH * BPP
    cmp     esi, ecx
    jge     l00

    ret



;***************************************************************************
;   Function
;      renderIcons
;
;   Description
;       Reads the icon images and renders them into the menu bitmap
;
;***************************************************************************
renderIcons:
    mov     ecx, [numOptions]
    mov     esi, MENUTABLE + 8 ; Offset to menu icon filename
    mov     edi, MENU_IMAGE + (6 + (BMP_MT_DEPTH * MENU_WIDTH)) * BPP
    cmp     [menuType], byte 'M'
    je     @f
    mov     edi, MENU_IMAGE + (6 + (BMP_MTF_DEPTH * MENU_WIDTH)) * BPP
@@:

ri001:
    pusha
    mov     esi, [esi]
    call    drawIcon
    popa
    add     esi, 16
    add     edi, 34 * MENU_WIDTH * BPP
    loop    ri001
        
    ret




    
    

; Data area

childPID    dd  0

received_messages:

      db  0      ; lock byte
      db  0,0,0  ; reserved
      dd  8      ; pointer to free msg position from received_messages
      times 16 db 0  

lastButton  dd -1
startX:     dd  0                   ; Place to draw menu
startY:     dd  0
newX:       dd  0
newY:       dd  0

menuType:   db  0                   ; 0 == main, 1 == sub
menuDepth:  dd  0                   ; Real depth of menu
numOptions: dd  5                   ; Number of menu options ( 5 is test )

itype	    dd  0
appname     db  '            '

mtf:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_MT                      ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/mtf.bmp',0

mt:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_MT                      ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/mt.bmp',0

mc:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_MC                      ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/mc.bmp',0

mb:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  BMP_MB                      ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/mb.bmp',0

optionsf:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  OPTIONSFILE                 ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
    db  '/rd/1/mpanel.dat',0


tmpf:
    dd  0
    dd  0
    dd  -1                          ; Amount to load - all of it
    dd  ICON_FILE                   ; Place to store file data
    dd  OSWORKAREA                  ; os work area - 16KB
tmpfn:
    times 256 db 0                  ; space for the filename


startfile:
    dd  16                          ; Start file option
    dd  0                           ; Reserved, 0
    dd  params                      ; Parameters 
    dd  0                           ; Reserved, 0
    dd  OSWORKAREA                  ; OS work area - 16KB
    db  '/rd/1/mmenu',0
    
params:     ; Shared with I_Params
I_Param:    ; 256 bytes    

I_END:




