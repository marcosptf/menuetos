is_input:

   push edx
   mov  dx,word [midisp]
   in   al,dx
   and  al,0x80
   pop  edx
   ret


is_output:

   push edx
   mov  dx,word [midisp]
   in   al,dx
   and  al,0x40
   pop  edx
   ret


get_mpu_in:

   push edx
   mov  dx,word [mididp]
   in   al,dx
   pop  edx
   ret


put_mpu_out:

   push edx
   mov  dx,word [mididp]
   out  dx,al
   pop  edx
   ret


setuart:

 su1:
   call is_output
   cmp  al,0
   jnz  su1
   mov  dx,word [midisp]
   mov  al,0xff
   out  dx,al
 su2:
   mov  dx,word [midisp]
   mov  al,0xff
   out  dx,al
   call is_input
   cmp  al,0
   jnz  su2
   call get_mpu_in
   cmp  al,0xfe
   jnz  su2
 su3:
   call is_output
   cmp  al,0
   jnz  su3
   mov  dx,word [midisp]
   mov  al,0x3f
   out  dx,al

   ret


align 4

sys_midi:

     cmp  [mididp],0
     jnz  sm0
     mov  [esp+36],dword 1
     ret
   sm0:

     cmp  eax,1
     mov  [esp+36],dword 0
     jnz  smn1
     call setuart
     ret
   smn1:

     cmp  eax,2
     jnz  smn2
   sm10:
     call get_mpu_in
     call is_output
     test al,al
     jnz  sm10
     mov  al,bl
     call put_mpu_out
     ret
   smn2:

     ret

