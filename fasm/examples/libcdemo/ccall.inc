
macro ccall proc,[arg]
  { common
     local size
     size = 0
     mov ebp,esp
     if ~ arg eq
    forward
     size = size + 4
    common
     sub esp,size
     end if
     and esp,-16
     if ~ arg eq
     add esp,size
    reverse
     pushd arg
    common
     end if
     call proc
     mov esp,ebp }

