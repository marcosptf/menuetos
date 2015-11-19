
include 'elf.inc'

macro interpreter [library]
{
 segment interpreter readable
 db library,0
}

macro needed [library]
{
 local str
 match needed,needed@dynamic \{ define needed@dynamic needed,str:library \}
 match ,needed@dynamic \{ define needed@dynamic str:library \}
}
define needed@dynamic

macro import [name]
{
 common
  local strtab,strsz,symtab,rel,relsz,hash
  segment dynamic readable
  match needed,needed@dynamic
  \{ irp item,needed \\{ match str:library,item \\\{ dq DT_NEEDED,str-strtab \\\} \\} \}
  dq DT_STRTAB,strtab
  dq DT_STRSZ,strsz
  dq DT_SYMTAB,symtab
  dq DT_SYMENT,sizeof.Elf64_Sym
  dq DT_RELA,rela
  dq DT_RELASZ,relasz
  dq DT_RELAENT,sizeof.Elf64_Rela
  dq DT_HASH,hash
  dq DT_NULL,0
  segment readable writeable
  symtab: Elf64_Sym
 forward
  local fstr
  Elf64_Sym fstr-strtab,0,0,STB_GLOBAL,STT_FUNC,0,0
 common
  rela:
  local counter
  counter = 1
 forward
   Elf64_Rela name,counter,R_X86_64_64
   counter = counter+1
 common
  relasz = $-rela
  hash:
  dd 1,counter
  dd 0
  repeat counter
   if %=counter
    dd 0
   else
    dd %
   end if
  end repeat
  strtab db 0
 forward
  fstr db `name,0
 common
  match needed,needed@dynamic
  \{ irp item,needed \\{ match str:library,item \\\{ str db library,0 \\\} \\} \}
  strsz = $-strtab
 forward
  name dq 0
}
