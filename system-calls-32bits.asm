System calls - M32
   
eax      = function number
int 0x40 = execute system call

00 - Define and draw window
01 - Putpixel
02 - Get key
03 - Get system time
04 - Display text
05 - Delay
07 - Putimage
08 - Define button
09 - Process info
10 - Wait for event
11 - Check for event
12 - Window redraw status
13 - Draw filled rectangle
14 - Get screen size
15 - Background
16 - Save ramdisk to floppy
17 - Get button ID
18 - System
20 - Midi interface, MPU401
21 - Device setup
23 - Wait for event with timeout
24 - CD audio
25 - SB16 I
26 - Get setup for devices
27 - WSS
28 - SB16 II
29 - Get date
35 - Read screen pixel
37 - Read mouse data
38 - Display line
39 - Get background data
40 - Set bitfield for wanted events
41 - Get IRQ owner
42 - Get data read by IRQ
44 - Program IRQ
45 - Reserve/free IRQ
46 - Reserve/free port area
47 - Display number to window
48 - Define general window properties
50 - Free form window shape and scale
51 - Create thread
52 - Stack driver status
53 - Socket interface
55 - Sound interface
58 - File system
59 - Trace system calls
60 - Inter process communication
61 - Direct graphics access
62 - PCI access
63 - Debug board
64 - Application memory resize
65 - UTF
66 - Keyboard data mode
67 - Application window move / resize
113- Vertical/Horizontal Scroll
-1 - End application

--
   
00 - Define and draw window
   
        In : ebx - [x start] shl 16 + [x size]
             ecx - [y start] shl 16 + [y size]
             edx - Body color 0xXYRRGGBB

                 X=8 - Color glide
                 Y=0 - Window type I
                 Y=1 - Reserve area, no draw
                 Y=2 - Window type II
                 Y=3 - Skinned window
                       Closebutton id=1 added
                 Y=4 - Skinned window with menu
                       Closebutton id=1 added
                       esi=zero or pointer to window label (asciiz)
                       edi=zero or pointer to menu struct

             esi - Grab bar color 0xXYRRGGBB X=8-Color glide-
                                             X=4-Color glide+
                                             Y=1-No window move
             edi - Frame color 0xRRGGBB

        Out: -

01 - Putpixel
   
        In : ebx - X
             ecx - Y
             edx - Pixel color 0x0XRRGGBB 
                   X = 0 normal, 1 negative
                               
        Out: -

02 - Get key
   
        Out: al = 0 - Successful - ah = key
             al = 1 - No key in buffer

        See function 66

03 - Get system time
   
        Out: eax - 0x00SSMMHH seconds,minutes,hours
   
04 - Display text
   
        In : ebx - [x start]*65536 + [y start]
             ecx - Color - 0xF0RRGGBB - F=font(0/1) 
             edx - Pointer to text beginning
             esi - Text length or -1 for asciiz string

        Out: -   

05 - Delay
   
        In : ebx - Delay in 1/100 secs

        Out: -   

07 - Putimage
   
        In : ebx - Pointer to image in memory - RRGGBBRRGGBB..
             ecx - Image size [x]*65536+[y]
             edx - Image position in window [x]*65536+[y]

        Out: -   

08 - Define button
   
        In : ebx - [x start]*65536 + [x size]
             ecx - [y start]*65536 + [y size]
             edx - Button ID number (24 bits)

              bit 31 - removes a button matching the id
                       function doesn't remove the button image 
                       to avoid unnecessary flickering
              bit 30 - button image is not drawn
              bit 29 - rectangle is not drawn when pressed

             esi - Button color 0xX0RRGGBB

              X = 0 - use system color 1
              X = 1 - use system color 2
                      edi = zero or pointer to button label (asciiz)
              X = 2 - user defined color RRGGBB

        Out: -
 

09 - Process info
   
        In : ebx - Pointer to 1024 bytes table
             ecx - Process number (-1 = whoami)

        Out: eax - Number of processes

              Table:  +00 dword cpu usage
                      +04  word Processes position in window stack
                      +06  word Window stack value at ecx
                      +10 11 db Name of the process
                      +22 dword Start of processes memory
                      +26 dword Memory used by process
                      +30 dword PID of the process
                      +34 dword Window x start
                      +38 dword Window y start
                      +42 dword Window x size
                      +46 dword Window y size
                      +50  word Process slot state

10 - Wait for event
   
        Out: eax - Event type

                 - 1 window redraw
                 - 2 key in buffer
                 - 3 button pressed   

11 - Check for event
   
        Out: eax - Event type

                 - 0 no event
                 - 1 window redraw
                 - 2 key in buffer
                 - 3 button pressed

12 - Window redraw status
   
        In : ebx - 1 Start of redraw
                 - 2 End of redraw

        Out: -

13 - Draw filled rectangle
   
        In : ebx - [x start] shl 16 + [x size]
             ecx - [y start] shl 16 + [y size]
             edx - color 0xRRGGBB

        Out: -

14 - Get screen size
   
        Out: eax - [screen x max] shl 16 + [screen y max]
   
15 - Background
   
        In : ebx 1 - Set background size

                 ecx - X size
                 edx - Y size

             ebx 2 - Write to background memory - max (0x100000-16)

                 ecx - Position in memory in bytes
                 edx - Color 0xRRGGBB

             ebx 3 - Draw background

             ebx 4 - type of background draw

                 ecx 1 - Tiled
                 ecx 2 - Stretched

             ebx 5 - Blockmove image to os bgr memory

                 ecx - Source
                 edx - Position in os background
                 esi - Count of bytes to move
    
16 - Save ramdisk to floppy

        In : ebx 1 - Save all
  
17 - Get button ID
   
        Out: al 0 - Successful and ah has ID
                    (shr eax,8 - eax=24 bit ID)
             al 1 - No key in buffer   

18 - System
   
        In : ebx 1 - Boot
             ebx 2 - Force terminate, ecx - Process slot
             ebx 3 - Activate window, ecx - Process slot
             ebx 4 - Idle cycles / second
             ebx 5 - Time stamp / second

        Out: rax

20 - Midi interface, MPU401
   
        In : ebx  1 - reset device
             ebx  2 - midi output, cl data      

21 - Device setup
   
        In : ebx 1 - Roland mpu midi base , base io address
             ebx 2 - Keyboard 1 base keymap, 2 shift keymap (ecx pointer to keymap)
                              9 country 1eng 2fi 3ger 4rus
             ebx 3 - Cd base 1 pri.master, 2 pri slave,
                             3 sec master, 4 sec slave
             ebx 4 - Sb16 base, base io address
             ebx 5 - System language, 1eng, 2fi, 3ger, 4rus
             ebx 6 - Wss base, base io address
             ebx 7 - Hd base, 1 pri.master, 2 pri slave
                              3 sec master, 4 sec slave
             ebx 8 - Fat32 partition in hd
             ebx 10- Sound dma channel in ecx      

23 - Wait for event with timeout
   
        In : ebx - Time to delay in HS

        Out: eax - Event type

                 - 0 No event
                 - 1 Window redraw
                 - 2 Key in buffer
                 - 3 Button   
   
24 - CD audio

        In : ebx 1 - Play (ecx=00FRSSMM)
             ebx 2 - Get playlist (size of ecx to [edx])
             ebx 3 - Stop/pause play

        Out: -
   
25 - SB16 I
   
        In : ebx 1 - Set main volume cl [L]*16+[R]
             ebx 2 - Set CD volume cl [L]*16+[R]

        Out: -  
   
26 - Get setup for devices
   
        In : ebx 1 - Roland mpu midi base , base io address
             ebx 2 - Keyboard 1 base keymap ,2 shift keymap
                              9 country 1eng, 2fi, 3ger, 4rus
             ebx 3 - Cd base  1 pri.master, 2 pri slave,
                              3 sec master, 4 sec slave
             ebx 4 - Sb16 base, base io address
             ebx 5 - System language, 1eng, 2fi, 3ger, 4rus
             ebx 6 - Wss base, base io address
             ebx 7 - Hd base, 1 pri.master, 2 pri slave
                              3 sec master, 4 sec slave
             ebx 8 - Fat32 partition in hd
             ebx 9 - Uptime in 1/100 sec -> eax

        Out: eax - Return value
   
27 - WSS
   
        In : ebx 1 - Set main volume to cl 0-255
             ebx 2 - Set cd volume to cl 0-255

        Out: -

28 - SB16 II
   
        In : ebx 1 - Set main volume to cl 0-255
             ebx 2 - Set cd volume to cl 0-255

        Out: -  

29 - Get date
   
        Out: eax - 0xYYDDMM year,date,month   

35 - Read screen pixel
   
        In : ebx - Pixel count from top left of the screen
   
        Out: eax - 0x00RRGGBB Color   

37 - Read mouse data
   
        In : ebx - 0 Screen relative
             ebx - 1 Window relative
             ebx - 2 Buttons pressed

        Out: eax - data      

38 - Display line
   
        In : ebx - [x start] shl 16 + [x end]
             ecx - [y start] shl 16 + [y end]
             edx - 0x00RRGGBB Color
   
        Out: -   
   
39 - Get background data
   
        In : ebx 1 - Get background size 
                     Out: eax=[x size] shl 16 + [y size]
             ebx 2 - Get background pixel
              ecx  - Position at background memory map 
                     Out: eax = value
             ebx 4 - Get background type 
                     Out: eax=1 tiled, eax=2 stretched
   
40 - Set bitfield for wanted events

        In : ebx - bitfield of wanted events

             default:

             ebx = 00000000 00000000 00000000 00000111b  Events:
                                                     I   Window draw
                                                    I    Key in buffer
                                                   I     Button in buffer
                                                  I      
                                                 I       Desktop background draw
                                                I        Mouse
                                               I         IPC
                   I---------------I                     Get irqs data

        Out: -

41 - Get IRQ owner
   
        In : ebx - IRQ

        Out: eax - PID of process
   
42 - Get data read by IRQ
   
        In : ebx - IRQ number

        Out: eax - Number of bytes in buffer
              bl - Data
             ecx - 0 - Successful data read
                   1 - No data in buffer
                   2 - Incorrect IRQ owner   

44 - Program IRQ
   
        In : ebx - Pointer to table

        Out: ecx - IRQ number   

45 - Reserve/free IRQ
   
        In : ebx - 0 Reserve, 1 Free
             ecx - IRQ number

        Out: eax - 0 Successful, 1 Error   

46 - Reserve/free port area

        Direct IO access with IN and OUT commands
     
        In : ebx - 0 Reserve, 1 Free
             ecx - Port area start (min 256)
             edx - Port area end (max 16383)

        Out: eax - 0 Successful, 1 Error

47 - Display number
   
        In : ebx - Print type, bl=0 - ecx=value
                               bl=1 - ecx=pointer
                               bh=0 - display decimal
                               bh=1 - display hexadecimal
                               bh=2 - display binary
                   bits 16-21 = number of digits to display (0-32)
                   bits 22-31 = reserved
             ecx - Value or pointer
             edx - x shl 16 + y
             esi - Color

        Out: -
   
48 - Define general window properties
   
        In: ebx - 0  Apply/redraw
             ecx - 0  Apply/redraw desktop
            ebx - 1  Define button style
             ecx - 0  Set flat buttons
             ecx - 1  Set 3d buttons
            ebx - 2  Define window colors
             ecx      Pointer to table
             edx      Number of bytes defined
            ebx - 3  Get define window colors
             ecx      Pointer to table
             edx      Number of bytes to get
            ebx - 4  Get window skin height

        Out: -

50 - Free form window shape and scale
   
        In : ebx - 0 Shape reference area
               ecx - Pointer to reference area   
                     byte per pixel (0=not used, 1=used, other=reserved)
             ebx - 1 Scale of reference area (default 1:1)
               ecx - Scale is set to 2^ecx
   
        Out: -   

51 - Create thread
   
        In : ebx = 1  Create
             ecx      Thread entry point
             edx      Thread stack position
   
        Out: eax = PID or 0xfffffff0+ for error  

52 - Stack driver status
   
        - See stack.txt

53 - Socket interface
   
        - See stack.txt   

55 - Sound interface
   
        In : ebx - 0   Load sound block
               ecx     Pointer to (default size 65536 byte) soundblock
             ebx - 1   Play (default 44 khz 8 bit mono) sound block
             ebx - 2   Set format
               ecx - 1 Set play block length
                 edx   Block length

        Out: -
   
58 - File system
   
        In : ebx - Pointer to fileinfo block
   
             Path examples:
      
             '/RD/1/KERNEL.ASM',0
             '/HD/1/KERNEL.ASM',0
   
             Fileinfo:
   
             dd   0       Read
             dd   0x0     512 block to read 0+
             dd   0x1     Blocks to read (/bytes to write/append)
             dd   0x20000 Return data pointer
             dd   0x10000 Work area for os - 16384 bytes
             db   PATH    asciiz dir & filename

        Out: eax - 0 Success or error code
             ebx - Size of file
   
        or
   
             Fileinfo:
   
             dd   1        Write
             dd   0x0      Ignored
             dd   10000    Bytes to write
             dd   0x20000  Source data pointer
             dd   0x10000  Work area for os - 16384 bytes
             db   PATH     ASCIIZ dir & filename

        Out: eax = 0 Success or error code

        or
   
             LBA
   
             Fileinfo:
               
             dd   0x8      LBA read
             dd   0x0      512 block to read (write)
             dd   0x1      Set to 1
             dd   0x20000  Return data pointer
             dd   0x10000  Work area for os (16384 bytes)
             dd   PATH     Physical device ; asciiz

             ( or /rd/1/ )

             LBA read must be enabled with setup

             The asciiz in this context refers to the physical device and
             not to logical one.
             For hd: first=pri.master, second=pri.slave
             third=sec.master, fourth=sec.slave
   
        or
   
             Fileinfo:
   
             dd   16       Start application
             dd   0x0      Ignored
             dd   param    0 or parameter area (asciiz)
                           Receiving application must
                           reserve a 256 byte area
             dd   0x0      Ignored
             dd   0x10000  Work area for os - 16384 bytes
             db   PATH     asciiz dir & filename
   
        Out: eax = pid or 0xfffffff0+ for error
   
59 - Trace system calls
   
        In : ebx - 0 Get system events
              ecx    Pointer to table - 64 bytes/system call descriptor

                     +00 PID +32 EDI +36 ESI +40 EBP +44 ESP
                     +48 EBX +52 EDX +56 ECX +60 EAX
   
             edx     Number of bytes to return (max 1024)
   
        Out: eax - Number of system calls from start
                   Latest call is saved to (eax mod 16)*64 in table
             ebx - 0 Above format   

60 - Inter process communication
   
        In : ebx - 1 Define IPC memory
             ebx - 2 Send message

        Out: -

61 - Direct graphics access
   
        In : ebx - 1 Get resolution -> eax [x] shl 16 + [y]
             ebx - 2 Get bits per pixel -> eax
             ebx - 3 Get bytes per scanline -> eax
   
        Direct access with gs selector: mov [gs:0],dword 0xffffff

        Out: eax - See above

62 - PCI access
   
        - See pci.txt

63 - Debug board
   
        In : ebx - 1 Write byte (cl=byte)
             ebx - 2 Read byte 
                     Out: ebx=1-byte in al 
                          ebx=0-no data

        Out: -

64 - Application memory resize

        In : ebx - 1 Set amount of memory
               ecx   New amount of memory

        Out: eax - 0 Successfull
             eax - 1 Out of memory

65 - UTF

66 - Keyboard data mode

        In : ebx - 1 Set mode
               ecx - 0 Keymap
               ecx - 1 Scancodes
             ebx - 2 Get mode - return in eax
             ebx - 3 Get ctrl alt shift state - return in eax

67 - Application window move / resize

        In : ebx - New x start
             ecx - New y start
             edx - New x size
             esi - New y size

        Out: -
     
        Specifying any parameter as -1 will leave the parameter unchanged.

113- Vertical/Horizontal Scroll

        Vertical scroll

        In : ebx - 1 shl 16 + X start
             ecx - Y start shl 16+ Y size
             edx - Scroll value start
             esi - Scroll value size
             edi - Current scroll value

        Out: -

        Horizontal scroll

        In : ebx - 2 shl 16 + Y start
             ecx - X start shl 16+ X size
             edx - Scroll value start
             esi - Scroll value size
             edi - Current scroll value

        Out: -

-1 - End application

        In : -

        Out: -
   


