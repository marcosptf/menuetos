;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   Ega.inc
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


checkEgaCga:

        cmp    [0xfe0c],dword 0x13
        je     cnvl
        ret
      cnvl:

        pusha
        mov    ecx,[0xfb0a]
        cmp    ecx,[novesachecksum]
        jne    novesal
        popa
        ret

      novesal:
        mov    [novesachecksum],ecx
        mov    ecx,0
        movzx  eax,word [0xfb0c]
        cmp    eax,100
        jge    m13l3
        mov    eax,100
      m13l3:
        cmp    eax,480-100
        jbe    m13l4
        mov    eax,480-100
      m13l4:
        sub    eax,100
        imul   eax,640*4
        add    ecx,eax
        movzx  eax,word [0xfb0a]
        cmp    eax,160
        jge    m13l1
        mov    eax,160
      m13l1:
        cmp    eax,640-160
        jbe    m13l2
        mov    eax,640-160
      m13l2:
        sub    eax,160
        shl    eax,2
        add    ecx,eax
        mov    esi,[0xfe80]
        add    esi,ecx
        mov    edi,0xa0000
        mov    edx,200
        mov    ecx,320
        cld
     m13pix:
        lodsd
        push   eax
        mov    ebx,eax
        and    eax,(128+64+32)      ; blue
        shr    eax,5
        and    ebx,(128+64+32)*256  ; green
        shr    ebx,8+2
        add    eax,ebx
        pop    ebx
        and    ebx,(128+64)*256*256 ; red
        shr    ebx,8+8
        add    eax,ebx
        stosb
        loop   m13pix
        mov    ecx,320
        add    esi,4*(640-320)
        dec    edx
        jnz    m13pix

        popa
        ret


palette320x200:

       mov   edx,0x3c8
       mov   eax,0
       out   dx,al
       mov   ecx,256
       mov   edx,0x3c9
       xor   eax,eax

     palnew:
       mov   al,0
       test  ah,64
       jz    pallbl1
       add   al,21
     pallbl1:
       test  ah,128
       jz    pallbl2
       add   al,42
     pallbl2:
       out   dx,al
       mov   al,0
       test  ah,8
       jz    pallbl3
       add   al,8
     pallbl3:
       test  ah,16
       jz    pallbl4
       add   al,15
     pallbl4:
       test  ah,32
       jz    pallbl5
       add   al,40
     pallbl5:
       out   dx,al
       mov   al,0
       test  ah,1
       jz    pallbl6
       add   al,8
     pallbl6:
       test  ah,2
       jz    pallbl7
       add   al,15
     pallbl7:
       test  ah,4
       jz    pallbl8
       add   al,40
     pallbl8:
       out   dx,al
       add   ah,1
       loop  palnew

       ret
