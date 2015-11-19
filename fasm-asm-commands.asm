
assembly commands for nasm and fasm

\H{insAAA} \i\c{AAA}, \i\c{AAS}, \i\c{AAM}, \i\c{AAD}: ASCII
Adjustments

\c AAA                           ; 37                   [8086]

\c AAS                           ; 3F                   [8086]

\c AAD                           ; D5 0A                [8086]
\c AAD imm                       ; D5 ib                [8086]

\c AAM                           ; D4 0A                [8086]
\c AAM imm                       ; D4 ib                [8086]

These instructions are used in conjunction with the add, subtract,
multiply and divide instructions to perform binary-coded decimal
arithmetic in \e{unpacked} (one BCD digit per byte - easy to
translate to and from ASCII, hence the instruction names) form.
There are also packed BCD instructions \c{DAA} and \c{DAS}: see
\k{insDAA}.

\c{AAA} should be used after a one-byte \c{ADD} instruction whose
destination was the \c{AL} register: by means of examining the value
in the low nibble of \c{AL} and also the auxiliary carry flag
\c{AF}, it determines whether the addition has overflowed, and
adjusts it (and sets the carry flag) if so. You can add long BCD
strings together by doing \c{ADD}/\c{AAA} on the low digits, then
doing \c{ADC}/\c{AAA} on each subsequent digit.

\c{AAS} works similarly to \c{AAA}, but is for use after \c{SUB}
instructions rather than \c{ADD}.

\c{AAM} is for use after you have multiplied two decimal digits
together and left the result in \c{AL}: it divides \c{AL} by ten and
stores the quotient in \c{AH}, leaving the remainder in \c{AL}. The
divisor 10 can be changed by specifying an operand to the
instruction: a particularly handy use of this is \c{AAM 16}, causing
the two nibbles in \c{AL} to be separated into \c{AH} and \c{AL}.

\c{AAD} performs the inverse operation to \c{AAM}: it multiplies
\c{AH} by ten, adds it to \c{AL}, and sets \c{AH} to zero. Again,
the multiplier 10 can be changed.

\H{insADC} \i\c{ADC}: Add with Carry

\c ADC r/m8,reg8                 ; 10 /r                [8086]
\c ADC r/m16,reg16               ; o16 11 /r            [8086]
\c ADC r/m32,reg32               ; o32 11 /r            [386]

\c ADC reg8,r/m8                 ; 12 /r                [8086]
\c ADC reg16,r/m16               ; o16 13 /r            [8086]
\c ADC reg32,r/m32               ; o32 13 /r            [386]

\c ADC r/m8,imm8                 ; 80 /2 ib             [8086]
\c ADC r/m16,imm16               ; o16 81 /2 iw         [8086]
\c ADC r/m32,imm32               ; o32 81 /2 id         [386]

\c ADC r/m16,imm8                ; o16 83 /2 ib         [8086]
\c ADC r/m32,imm8                ; o32 83 /2 ib         [386]

\c ADC AL,imm8                   ; 14 ib                [8086]
\c ADC AX,imm16                  ; o16 15 iw            [8086]
\c ADC EAX,imm32                 ; o32 15 id            [386]

\c{ADC} performs integer addition: it adds its two operands
together, plus the value of the carry flag, and leaves the result in
its destination (first) operand. The flags are set according to the
result of the operation: in particular, the carry flag is affected
and can be used by a subsequent \c{ADC} instruction.

In the forms with an 8-bit immediate second operand and a longer
first operand, the second operand is considered to be signed, and is
sign-extended to the length of the first operand. In these cases,
the \c{BYTE} qualifier is necessary to force NASM to generate this
form of the instruction.

To add two numbers without also adding the contents of the carry
flag, use \c{ADD} (\k{insADD}).

\H{insADD} \i\c{ADD}: Add Integers

\c ADD r/m8,reg8                 ; 00 /r                [8086]
\c ADD r/m16,reg16               ; o16 01 /r            [8086]
\c ADD r/m32,reg32               ; o32 01 /r            [386]

\c ADD reg8,r/m8                 ; 02 /r                [8086]
\c ADD reg16,r/m16               ; o16 03 /r            [8086]
\c ADD reg32,r/m32               ; o32 03 /r            [386]

\c ADD r/m8,imm8                 ; 80 /0 ib             [8086]
\c ADD r/m16,imm16               ; o16 81 /0 iw         [8086]
\c ADD r/m32,imm32               ; o32 81 /0 id         [386]

\c ADD r/m16,imm8                ; o16 83 /0 ib         [8086]
\c ADD r/m32,imm8                ; o32 83 /0 ib         [386]

\c ADD AL,imm8                   ; 04 ib                [8086]
\c ADD AX,imm16                  ; o16 05 iw            [8086]
\c ADD EAX,imm32                 ; o32 05 id            [386]

\c{ADD} performs integer addition: it adds its two operands
together, and leaves the result in its destination (first) operand.
The flags are set according to the result of the operation: in
particular, the carry flag is affected and can be used by a
subsequent \c{ADC} instruction (\k{insADC}).

In the forms with an 8-bit immediate second operand and a longer
first operand, the second operand is considered to be signed, and is
sign-extended to the length of the first operand. In these cases,
the \c{BYTE} qualifier is necessary to force NASM to generate this
form of the instruction.

\H{insAND} \i\c{AND}: Bitwise AND

\c AND r/m8,reg8                 ; 20 /r                [8086]
\c AND r/m16,reg16               ; o16 21 /r            [8086]
\c AND r/m32,reg32               ; o32 21 /r            [386]

\c AND reg8,r/m8                 ; 22 /r                [8086]
\c AND reg16,r/m16               ; o16 23 /r            [8086]
\c AND reg32,r/m32               ; o32 23 /r            [386]

\c AND r/m8,imm8                 ; 80 /4 ib             [8086]
\c AND r/m16,imm16               ; o16 81 /4 iw         [8086]
\c AND r/m32,imm32               ; o32 81 /4 id         [386]

\c AND r/m16,imm8                ; o16 83 /4 ib         [8086]
\c AND r/m32,imm8                ; o32 83 /4 ib         [386]

\c AND AL,imm8                   ; 24 ib                [8086]
\c AND AX,imm16                  ; o16 25 iw            [8086]
\c AND EAX,imm32                 ; o32 25 id            [386]

\c{AND} performs a bitwise AND operation between its two operands
(i.e. each bit of the result is 1 if and only if the corresponding
bits of the two inputs were both 1), and stores the result in the
destination (first) operand.

In the forms with an 8-bit immediate second operand and a longer
first operand, the second operand is considered to be signed, and is
sign-extended to the length of the first operand. In these cases,
the \c{BYTE} qualifier is necessary to force NASM to generate this
form of the instruction.

The MMX instruction \c{PAND} (see \k{insPAND}) performs the same
operation on the 64-bit MMX registers.

\H{insARPL} \i\c{ARPL}: Adjust RPL Field of Selector

\c ARPL r/m16,reg16              ; 63 /r                [286,PRIV]

\c{ARPL} expects its two word operands to be segment selectors. It
adjusts the RPL (requested privilege level - stored in the bottom
two bits of the selector) field of the destination (first) operand
to ensure that it is no less (i.e. no more privileged than) the RPL
field of the source operand. The zero flag is set if and only if a
change had to be made.

\H{insBOUND} \i\c{BOUND}: Check Array Index against Bounds

\c BOUND reg16,mem               ; o16 62 /r            [186]
\c BOUND reg32,mem               ; o32 62 /r            [386]

\c{BOUND} expects its second operand to point to an area of memory
containing two signed values of the same size as its first operand
(i.e. two words for the 16-bit form; two doublewords for the 32-bit
form). It performs two signed comparisons: if the value in the
register passed as its first operand is less than the first of the
in-memory values, or is greater than or equal to the second, it
throws a BR exception. Otherwise, it does nothing.

\H{insBSF} \i\c{BSF}, \i\c{BSR}: Bit Scan

\c BSF reg16,r/m16               ; o16 0F BC /r         [386]
\c BSF reg32,r/m32               ; o32 0F BC /r         [386]

\c BSR reg16,r/m16               ; o16 0F BD /r         [386]
\c BSR reg32,r/m32               ; o32 0F BD /r         [386]

\c{BSF} searches for a set bit in its source (second) operand,
starting from the bottom, and if it finds one, stores the index in
its destination (first) operand. If no set bit is found, the
contents of the destination operand are undefined.

\c{BSR} performs the same function, but searches from the top
instead, so it finds the most significant set bit.

Bit indices are from 0 (least significant) to 15 or 31 (most
significant).

\H{insBSWAP} \i\c{BSWAP}: Byte Swap

\c BSWAP reg32                   ; o32 0F C8+r          [486]

\c{BSWAP} swaps the order of the four bytes of a 32-bit register:
bits 0-7 exchange places with bits 24-31, and bits 8-15 swap with
bits 16-23. There is no explicit 16-bit equivalent: to byte-swap
\c{AX}, \c{BX}, \c{CX} or \c{DX}, \c{XCHG} can be used.

\H{insBT} \i\c{BT}, \i\c{BTC}, \i\c{BTR}, \i\c{BTS}: Bit Test

\c BT r/m16,reg16                ; o16 0F A3 /r         [386]
\c BT r/m32,reg32                ; o32 0F A3 /r         [386]
\c BT r/m16,imm8                 ; o16 0F BA /4 ib      [386]
\c BT r/m32,imm8                 ; o32 0F BA /4 ib      [386]

\c BTC r/m16,reg16               ; o16 0F BB /r         [386]
\c BTC r/m32,reg32               ; o32 0F BB /r         [386]
\c BTC r/m16,imm8                ; o16 0F BA /7 ib      [386]
\c BTC r/m32,imm8                ; o32 0F BA /7 ib      [386]

\c BTR r/m16,reg16               ; o16 0F B3 /r         [386]
\c BTR r/m32,reg32               ; o32 0F B3 /r         [386]
\c BTR r/m16,imm8                ; o16 0F BA /6 ib      [386]
\c BTR r/m32,imm8                ; o32 0F BA /6 ib      [386]

\c BTS r/m16,reg16               ; o16 0F AB /r         [386]
\c BTS r/m32,reg32               ; o32 0F AB /r         [386]
\c BTS r/m16,imm                 ; o16 0F BA /5 ib      [386]
\c BTS r/m32,imm                 ; o32 0F BA /5 ib      [386]

These instructions all test one bit of their first operand, whose
index is given by the second operand, and store the value of that
bit into the carry flag. Bit indices are from 0 (least significant)
to 15 or 31 (most significant).

In addition to storing the original value of the bit into the carry
flag, \c{BTR} also resets (clears) the bit in the operand itself.
\c{BTS} sets the bit, and \c{BTC} complements the bit. \c{BT} does
not modify its operands.

The bit offset should be no greater than the size of the operand.

\H{insCALL} \i\c{CALL}: Call Subroutine

\c CALL imm                      ; E8 rw/rd             [8086]
\c CALL imm:imm16                ; o16 9A iw iw         [8086]
\c CALL imm:imm32                ; o32 9A id iw         [386]
\c CALL FAR mem16                ; o16 FF /3            [8086]
\c CALL FAR mem32                ; o32 FF /3            [386]
\c CALL r/m16                    ; o16 FF /2            [8086]
\c CALL r/m32                    ; o32 FF /2            [386]

\c{CALL} calls a subroutine, by means of pushing the current
instruction pointer (\c{IP}) and optionally \c{CS} as well on the
stack, and then jumping to a given address.

\c{CS} is pushed as well as \c{IP} if and only if the call is a far
call, i.e. a destination segment address is specified in the
instruction. The forms involving two colon-separated arguments are
far calls; so are the \c{CALL FAR mem} forms.

You can choose between the two immediate \i{far call} forms (\c{CALL
imm:imm}) by the use of the \c{WORD} and \c{DWORD} keywords: \c{CALL
WORD 0x1234:0x5678}) or \c{CALL DWORD 0x1234:0x56789abc}.

The \c{CALL FAR mem} forms execute a far call by loading the
destination address out of memory. The address loaded consists of 16
or 32 bits of offset (depending on the operand size), and 16 bits of
segment. The operand size may be overridden using \c{CALL WORD FAR
mem} or \c{CALL DWORD FAR mem}.

The \c{CALL r/m} forms execute a \i{near call} (within the same
segment), loading the destination address out of memory or out of a
register. The keyword \c{NEAR} may be specified, for clarity, in
these forms, but is not necessary. Again, operand size can be
overridden using \c{CALL WORD mem} or \c{CALL DWORD mem}.

As a convenience, NASM does not require you to call a far procedure
symbol by coding the cumbersome \c{CALL SEG routine:routine}, but
instead allows the easier synonym \c{CALL FAR routine}.

The \c{CALL r/m} forms given above are near calls; NASM will accept
the \c{NEAR} keyword (e.g. \c{CALL NEAR [address]}), even though it
is not strictly necessary.

\H{insCBW} \i\c{CBW}, \i\c{CWD}, \i\c{CDQ}, \i\c{CWDE}: Sign Extensions

\c CBW                           ; o16 98               [8086]
\c CWD                           ; o16 99               [8086]
\c CDQ                           ; o32 99               [386]
\c CWDE                          ; o32 98               [386]

All these instructions sign-extend a short value into a longer one,
by replicating the top bit of the original value to fill the
extended one.

\c{CBW} extends \c{AL} into \c{AX} by repeating the top bit of
\c{AL} in every bit of \c{AH}. \c{CWD} extends \c{AX} into \c{DX:AX}
by repeating the top bit of \c{AX} throughout \c{DX}. \c{CWDE}
extends \c{AX} into \c{EAX}, and \c{CDQ} extends \c{EAX} into
\c{EDX:EAX}.

\H{insCLC} \i\c{CLC}, \i\c{CLD}, \i\c{CLI}, \i\c{CLTS}: Clear Flags

\c CLC                           ; F8                   [8086]
\c CLD                           ; FC                   [8086]
\c CLI                           ; FA                   [8086]
\c CLTS                          ; 0F 06                [286,PRIV]

These instructions clear various flags. \c{CLC} clears the carry
flag; \c{CLD} clears the direction flag; \c{CLI} clears the
interrupt flag (thus disabling interrupts); and \c{CLTS} clears the
task-switched (\c{TS}) flag in \c{CR0}.

To set the carry, direction, or interrupt flags, use the \c{STC},
\c{STD} and \c{STI} instructions (\k{insSTC}). To invert the carry
flag, use \c{CMC} (\k{insCMC}).

\H{insCMC} \i\c{CMC}: Complement Carry Flag

\c CMC                           ; F5                   [8086]

\c{CMC} changes the value of the carry flag: if it was 0, it sets it
to 1, and vice versa.

\H{insCMOVcc} \i\c{CMOVcc}: Conditional Move

\c CMOVcc reg16,r/m16            ; o16 0F 40+cc /r      [P6]
\c CMOVcc reg32,r/m32            ; o32 0F 40+cc /r      [P6]

\c{CMOV} moves its source (second) operand into its destination
(first) operand if the given condition code is satisfied; otherwise
it does nothing.

For a list of condition codes, see \k{iref-cc}.

Although the \c{CMOV} instructions are flagged \c{P6} above, they
may not be supported by all Pentium Pro processors; the \c{CPUID}
instruction (\k{insCPUID}) will return a bit which indicates whether
conditional moves are supported.

\H{insCMP} \i\c{CMP}: Compare Integers

\c CMP r/m8,reg8                 ; 38 /r                [8086]
\c CMP r/m16,reg16               ; o16 39 /r            [8086]
\c CMP r/m32,reg32               ; o32 39 /r            [386]

\c CMP reg8,r/m8                 ; 3A /r                [8086]
\c CMP reg16,r/m16               ; o16 3B /r            [8086]
\c CMP reg32,r/m32               ; o32 3B /r            [386]

\c CMP r/m8,imm8                 ; 80 /0 ib             [8086]
\c CMP r/m16,imm16               ; o16 81 /0 iw         [8086]
\c CMP r/m32,imm32               ; o32 81 /0 id         [386]

\c CMP r/m16,imm8                ; o16 83 /0 ib         [8086]
\c CMP r/m32,imm8                ; o32 83 /0 ib         [386]

\c CMP AL,imm8                   ; 3C ib                [8086]
\c CMP AX,imm16                  ; o16 3D iw            [8086]
\c CMP EAX,imm32                 ; o32 3D id            [386]

\c{CMP} performs a `mental' subtraction of its second operand from
its first operand, and affects the flags as if the subtraction had
taken place, but does not store the result of the subtraction
anywhere.

In the forms with an 8-bit immediate second operand and a longer
first operand, the second operand is considered to be signed, and is
sign-extended to the length of the first operand. In these cases,
the \c{BYTE} qualifier is necessary to force NASM to generate this
form of the instruction.

\H{insCMPSB} \i\c{CMPSB}, \i\c{CMPSW}, \i\c{CMPSD}: Compare Strings

\c CMPSB                         ; A6                   [8086]
\c CMPSW                         ; o16 A7               [8086]
\c CMPSD                         ; o32 A7               [386]

\c{CMPSB} compares the byte at \c{[DS:SI]} or \c{[DS:ESI]} with the
byte at \c{[ES:DI]} or \c{[ES:EDI]}, and sets the flags accordingly.
It then increments or decrements (depending on the direction flag:
increments if the flag is clear, decrements if it is set) \c{SI} and
\c{DI} (or \c{ESI} and \c{EDI}).

The registers used are \c{SI} and \c{DI} if the address size is 16
bits, and \c{ESI} and \c{EDI} if it is 32 bits. If you need to use
an address size not equal to the current \c{BITS} setting, you can
use an explicit \i\c{a16} or \i\c{a32} prefix.

The segment register used to load from \c{[SI]} or \c{[ESI]} can be
overridden by using a segment register name as a prefix (for
example, \c{es cmpsb}). The use of \c{ES} for the load from \c{[DI]}
or \c{[EDI]} cannot be overridden.

\c{CMPSW} and \c{CMPSD} work in the same way, but they compare a
word or a doubleword instead of a byte, and increment or decrement
the addressing registers by 2 or 4 instead of 1.

The \c{REPE} and \c{REPNE} prefixes (equivalently, \c{REPZ} and
\c{REPNZ}) may be used to repeat the instruction up to \c{CX} (or
\c{ECX} - again, the address size chooses which) times until the
first unequal or equal byte is found.

\H{insCMPXCHG} \i\c{CMPXCHG}, \i\c{CMPXCHG486}: Compare and Exchange

\c CMPXCHG r/m8,reg8             ; 0F B0 /r             [PENT]
\c CMPXCHG r/m16,reg16           ; o16 0F B1 /r         [PENT]
\c CMPXCHG r/m32,reg32           ; o32 0F B1 /r         [PENT]

\c CMPXCHG486 r/m8,reg8          ; 0F A6 /r             [486,UNDOC]
\c CMPXCHG486 r/m16,reg16        ; o16 0F A7 /r         [486,UNDOC]
\c CMPXCHG486 r/m32,reg32        ; o32 0F A7 /r         [486,UNDOC]

These two instructions perform exactly the same operation; however,
apparently some (not all) 486 processors support it under a
non-standard opcode, so NASM provides the undocumented
\c{CMPXCHG486} form to generate the non-standard opcode.

\c{CMPXCHG} compares its destination (first) operand to the value in
\c{AL}, \c{AX} or \c{EAX} (depending on the size of the
instruction). If they are equal, it copies its source (second)
operand into the destination and sets the zero flag. Otherwise, it
clears the zero flag and leaves the destination alone.

\c{CMPXCHG} is intended to be used for atomic operations in
multitasking or multiprocessor environments. To safely update a
value in shared memory, for example, you might load the value into
\c{EAX}, load the updated value into \c{EBX}, and then execute the
instruction \c{lock cmpxchg [value],ebx}. If \c{value} has not
changed since being loaded, it is updated with your desired new
value, and the zero flag is set to let you know it has worked. (The
\c{LOCK} prefix prevents another processor doing anything in the
middle of this operation: it guarantees atomicity.) However, if
another processor has modified the value in between your load and
your attempted store, the store does not happen, and you are
notified of the failure by a cleared zero flag, so you can go round
and try again.

\H{insCMPXCHG8B} \i\c{CMPXCHG8B}: Compare and Exchange Eight Bytes

\c CMPXCHG8B mem                 ; 0F C7 /1             [PENT]

This is a larger and more unwieldy version of \c{CMPXCHG}: it
compares the 64-bit (eight-byte) value stored at \c{[mem]} with the
value in \c{EDX:EAX}. If they are equal, it sets the zero flag and
stores \c{ECX:EBX} into the memory area. If they are unequal, it
clears the zero flag and leaves the memory area untouched.

\H{insCPUID} \i\c{CPUID}: Get CPU Identification Code

\c CPUID                         ; 0F A2                [PENT]

\c{CPUID} returns various information about the processor it is
being executed on. It fills the four registers \c{EAX}, \c{EBX},
\c{ECX} and \c{EDX} with information, which varies depending on the
input contents of \c{EAX}.

\c{CPUID} also acts as a barrier to serialise instruction execution:
executing the \c{CPUID} instruction guarantees that all the effects
(memory modification, flag modification, register modification) of
previous instructions have been completed before the next
instruction gets fetched.

The information returned is as follows:

\b If \c{EAX} is zero on input, \c{EAX} on output holds the maximum
acceptable input value of \c{EAX}, and \c{EBX:EDX:ECX} contain the
string \c{"GenuineIntel"} (or not, if you have a clone processor).
That is to say, \c{EBX} contains \c{"Genu"} (in NASM's own sense of
character constants, described in \k{chrconst}), \c{EDX} contains
\c{"ineI"} and \c{ECX} contains \c{"ntel"}.

\b If \c{EAX} is one on input, \c{EAX} on output contains version
information about the processor, and \c{EDX} contains a set of
feature flags, showing the presence and absence of various features.
For example, bit 8 is set if the \c{CMPXCHG8B} instruction
(\k{insCMPXCHG8B}) is supported, bit 15 is set if the conditional
move instructions (\k{insCMOVcc} and \k{insFCMOVB}) are supported,
and bit 23 is set if MMX instructions are supported.

\b If \c{EAX} is two on input, \c{EAX}, \c{EBX}, \c{ECX} and \c{EDX}
all contain information about caches and TLBs (Translation Lookahead
Buffers).

For more information on the data returned from \c{CPUID}, see the
documentation on Intel's web site.

\H{insDAA} \i\c{DAA}, \i\c{DAS}: Decimal Adjustments

\c DAA                           ; 27                   [8086]
\c DAS                           ; 2F                   [8086]

These instructions are used in conjunction with the add and subtract
instructions to perform binary-coded decimal arithmetic in
\e{packed} (one BCD digit per nibble) form. For the unpacked
equivalents, see \k{insAAA}.

\c{DAA} should be used after a one-byte \c{ADD} instruction whose
destination was the \c{AL} register: by means of examining the value
in the \c{AL} and also the auxiliary carry flag \c{AF}, it
determines whether either digit of the addition has overflowed, and
adjusts it (and sets the carry and auxiliary-carry flags) if so. You
can add long BCD strings together by doing \c{ADD}/\c{DAA} on the
low two digits, then doing \c{ADC}/\c{DAA} on each subsequent pair
of digits.

\c{DAS} works similarly to \c{DAA}, but is for use after \c{SUB}
instructions rather than \c{ADD}.

\H{insDEC} \i\c{DEC}: Decrement Integer

\c DEC reg16                     ; o16 48+r             [8086]
\c DEC reg32                     ; o32 48+r             [386]
\c DEC r/m8                      ; FE /1                [8086]
\c DEC r/m16                     ; o16 FF /1            [8086]
\c DEC r/m32                     ; o32 FF /1            [386]

\c{DEC} subtracts 1 from its operand. It does \e{not} affect the
carry flag: to affect the carry flag, use \c{SUB something,1} (see
\k{insSUB}). See also \c{INC} (\k{insINC}).

\H{insDIV} \i\c{DIV}: Unsigned Integer Divide

\c DIV r/m8                      ; F6 /6                [8086]
\c DIV r/m16                     ; o16 F7 /6            [8086]
\c DIV r/m32                     ; o32 F7 /6            [386]

\c{DIV} performs unsigned integer division. The explicit operand
provided is the divisor; the dividend and destination operands are
implicit, in the following way:

\b For \c{DIV r/m8}, \c{AX} is divided by the given operand; the
quotient is stored in \c{AL} and the remainder in \c{AH}.

\b For \c{DIV r/m16}, \c{DX:AX} is divided by the given operand; the
quotient is stored in \c{AX} and the remainder in \c{DX}.

\b For \c{DIV r/m32}, \c{EDX:EAX} is divided by the given operand;
the quotient is stored in \c{EAX} and the remainder in \c{EDX}.

Signed integer division is performed by the \c{IDIV} instruction:
see \k{insIDIV}.

\H{insEMMS} \i\c{EMMS}: Empty MMX State

\c EMMS                          ; 0F 77                [PENT,MMX]

\c{EMMS} sets the FPU tag word (marking which floating-point
registers are available) to all ones, meaning all registers are
available for the FPU to use. It should be used after executing MMX
instructions and before executing any subsequent floating-point
operations.

\H{insENTER} \i\c{ENTER}: Create Stack Frame

\c ENTER imm,imm                 ; C8 iw ib             [186]

\c{ENTER} constructs a stack frame for a high-level language
procedure call. The first operand (the \c{iw} in the opcode
definition above refers to the first operand) gives the amount of
stack space to allocate for local variables; the second (the \c{ib}
above) gives the nesting level of the procedure (for languages like
Pascal, with nested procedures).

The function of \c{ENTER}, with a nesting level of zero, is
equivalent to

\c           PUSH EBP            ; or PUSH BP         in 16 bits
\c           MOV EBP,ESP         ; or MOV BP,SP       in 16 bits
\c           SUB ESP,operand1    ; or SUB SP,operand1 in 16 bits

This creates a stack frame with the procedure parameters accessible
upwards from \c{EBP}, and local variables accessible downwards from
\c{EBP}.

With a nesting level of one, the stack frame created is 4 (or 2)
bytes bigger, and the value of the final frame pointer \c{EBP} is
accessible in memory at \c{[EBP-4]}.

This allows \c{ENTER}, when called with a nesting level of two, to
look at the stack frame described by the \e{previous} value of
\c{EBP}, find the frame pointer at offset -4 from that, and push it
along with its new frame pointer, so that when a level-two procedure
is called from within a level-one procedure, \c{[EBP-4]} holds the
frame pointer of the most recent level-one procedure call and
\c{[EBP-8]} holds that of the most recent level-two call. And so on,
for nesting levels up to 31.

Stack frames created by \c{ENTER} can be destroyed by the \c{LEAVE}
instruction: see \k{insLEAVE}.

\H{insF2XM1} \i\c{F2XM1}: Calculate 2**X-1

\c F2XM1                         ; D9 F0                [8086,FPU]

\c{F2XM1} raises 2 to the power of \c{ST0}, subtracts one, and
stores the result back into \c{ST0}. The initial contents of \c{ST0}
must be a number in the range -1 to +1.

\H{insFABS} \i\c{FABS}: Floating-Point Absolute Value

\c FABS                          ; D9 E1                [8086,FPU]

\c{FABS} computes the absolute value of \c{ST0}, storing the result
back in \c{ST0}.

\H{insFADD} \i\c{FADD}, \i\c{FADDP}: Floating-Point Addition

\c FADD mem32                    ; D8 /0                [8086,FPU]
\c FADD mem64                    ; DC /0                [8086,FPU]

\c FADD fpureg                   ; D8 C0+r              [8086,FPU]
\c FADD ST0,fpureg               ; D8 C0+r              [8086,FPU]

\c FADD TO fpureg                ; DC C0+r              [8086,FPU]
\c FADD fpureg,ST0               ; DC C0+r              [8086,FPU]

\c FADDP fpureg                  ; DE C0+r              [8086,FPU]
\c FADDP fpureg,ST0              ; DE C0+r              [8086,FPU]

\c{FADD}, given one operand, adds the operand to \c{ST0} and stores
the result back in \c{ST0}. If the operand has the \c{TO} modifier,
the result is stored in the register given rather than in \c{ST0}.

\c{FADDP} performs the same function as \c{FADD TO}, but pops the
register stack after storing the result.

The given two-operand forms are synonyms for the one-operand forms.

\H{insFBLD} \i\c{FBLD}, \i\c{FBSTP}: BCD Floating-Point Load and Store

\c FBLD mem80                    ; DF /4                [8086,FPU]
\c FBSTP mem80                   ; DF /6                [8086,FPU]

\c{FBLD} loads an 80-bit (ten-byte) packed binary-coded decimal
number from the given memory address, converts it to a real, and
pushes it on the register stack. \c{FBSTP} stores the value of
\c{ST0}, in packed BCD, at the given address and then pops the
register stack.

\H{insFCHS} \i\c{FCHS}: Floating-Point Change Sign

\c FCHS                          ; D9 E0                [8086,FPU]

\c{FCHS} negates the number in \c{ST0}: negative numbers become
positive, and vice versa.

\H{insFCLEX} \i\c{FCLEX}, \{FNCLEX}: Clear Floating-Point Exceptions

\c FCLEX                         ; 9B DB E2             [8086,FPU]
\c FNCLEX                        ; DB E2                [8086,FPU]

\c{FCLEX} clears any floating-point exceptions which may be pending.
\c{FNCLEX} does the same thing but doesn't wait for previous
floating-point operations (including the \e{handling} of pending
exceptions) to finish first.

\H{insFCMOVB} \i\c{FCMOVcc}: Floating-Point Conditional Move

\c FCMOVB fpureg                 ; DA C0+r              [P6,FPU]
\c FCMOVB ST0,fpureg             ; DA C0+r              [P6,FPU]

\c FCMOVBE fpureg                ; DA D0+r              [P6,FPU]
\c FCMOVBE ST0,fpureg            ; DA D0+r              [P6,FPU]

\c FCMOVE fpureg                 ; DA C8+r              [P6,FPU]
\c FCMOVE ST0,fpureg             ; DA C8+r              [P6,FPU]

\c FCMOVNB fpureg                ; DB C0+r              [P6,FPU]
\c FCMOVNB ST0,fpureg            ; DB C0+r              [P6,FPU]

\c FCMOVNBE fpureg               ; DB D0+r              [P6,FPU]
\c FCMOVNBE ST0,fpureg           ; DB D0+r              [P6,FPU]

\c FCMOVNE fpureg                ; DB C8+r              [P6,FPU]
\c FCMOVNE ST0,fpureg            ; DB C8+r              [P6,FPU]

\c FCMOVNU fpureg                ; DB D8+r              [P6,FPU]
\c FCMOVNU ST0,fpureg            ; DB D8+r              [P6,FPU]

\c FCMOVU fpureg                 ; DA D8+r              [P6,FPU]
\c FCMOVU ST0,fpureg             ; DA D8+r              [P6,FPU]

The \c{FCMOV} instructions perform conditional move operations: each
of them moves the contents of the given register into \c{ST0} if its
condition is satisfied, and does nothing if not.

The conditions are not the same as the standard condition codes used
with conditional jump instructions. The conditions \c{B}, \c{BE},
\c{NB}, \c{NBE}, \c{E} and \c{NE} are exactly as normal, but none of
the other standard ones are supported. Instead, the condition \c{U}
and its counterpart \c{NU} are provided; the \c{U} condition is
satisfied if the last two floating-point numbers compared were
\e{unordered}, i.e. they were not equal but neither one could be
said to be greater than the other, for example if they were NaNs.
(The flag state which signals this is the setting of the parity
flag: so the \c{U} condition is notionally equivalent to \c{PE}, and
\c{NU} is equivalent to \c{PO}.)

The \c{FCMOV} conditions test the main processor's status flags, not
the FPU status flags, so using \c{FCMOV} directly after \c{FCOM}
will not work. Instead, you should either use \c{FCOMI} which writes
directly to the main CPU flags word, or use \c{FSTSW} to extract the
FPU flags.

Although the \c{FCMOV} instructions are flagged \c{P6} above, they
may not be supported by all Pentium Pro processors; the \c{CPUID}
instruction (\k{insCPUID}) will return a bit which indicates whether
conditional moves are supported.

\H{insFCOM} \i\c{FCOM}, \i\c{FCOMP}, \i\c{FCOMPP}, \i\c{FCOMI}, \i\c{FCOMIP}: Floating-Point Compare

\c FCOM mem32                    ; D8 /2                [8086,FPU]
\c FCOM mem64                    ; DC /2                [8086,FPU]
\c FCOM fpureg                   ; D8 D0+r              [8086,FPU]
\c FCOM ST0,fpureg               ; D8 D0+r              [8086,FPU]

\c FCOMP mem32                   ; D8 /3                [8086,FPU]
\c FCOMP mem64                   ; DC /3                [8086,FPU]
\c FCOMP fpureg                  ; D8 D8+r              [8086,FPU]
\c FCOMP ST0,fpureg              ; D8 D8+r              [8086,FPU]

\c FCOMPP                        ; DE D9                [8086,FPU]

\c FCOMI fpureg                  ; DB F0+r              [P6,FPU]
\c FCOMI ST0,fpureg              ; DB F0+r              [P6,FPU]

\c FCOMIP fpureg                 ; DF F0+r              [P6,FPU]
\c FCOMIP ST0,fpureg             ; DF F0+r              [P6,FPU]

\c{FCOM} compares \c{ST0} with the given operand, and sets the FPU
flags accordingly. \c{ST0} is treated as the left-hand side of the
comparison, so that the carry flag is set (for a `less-than' result)
if \c{ST0} is less than the given operand.

\c{FCOMP} does the same as \c{FCOM}, but pops the register stack
afterwards. \c{FCOMPP} compares \c{ST0} with \c{ST1} and then pops
the register stack twice.

\c{FCOMI} and \c{FCOMIP} work like the corresponding forms of
\c{FCOM} and \c{FCOMP}, but write their results directly to the CPU
flags register rather than the FPU status word, so they can be
immediately followed by conditional jump or conditional move
instructions.

The \c{FCOM} instructions differ from the \c{FUCOM} instructions
(\k{insFUCOM}) only in the way they handle quiet NaNs: \c{FUCOM}
will handle them silently and set the condition code flags to an
`unordered' result, whereas \c{FCOM} will generate an exception.

\H{insFCOS} \i\c{FCOS}: Cosine

\c FCOS                          ; D9 FF                [386,FPU]

\c{FCOS} computes the cosine of \c{ST0} (in radians), and stores the
result in \c{ST0}. See also \c{FSINCOS} (\k{insFSIN}).

\H{insFDECSTP} \i\c{FDECSTP}: Decrement Floating-Point Stack Pointer

\c FDECSTP                       ; D9 F6                [8086,FPU]

\c{FDECSTP} decrements the `top' field in the floating-point status
word. This has the effect of rotating the FPU register stack by one,
as if the contents of \c{ST7} had been pushed on the stack. See also
\c{FINCSTP} (\k{insFINCSTP}).

\H{insFDISI} \i\c{FxDISI}, \i\c{FxENI}: Disable and Enable Floating-Point Interrupts

\c FDISI                         ; 9B DB E1             [8086,FPU]
\c FNDISI                        ; DB E1                [8086,FPU]

\c FENI                          ; 9B DB E0             [8086,FPU]
\c FNENI                         ; DB E0                [8086,FPU]

\c{FDISI} and \c{FENI} disable and enable floating-point interrupts.
These instructions are only meaningful on original 8087 processors:
the 287 and above treat them as no-operation instructions.

\c{FNDISI} and \c{FNENI} do the same thing as \c{FDISI} and \c{FENI}
respectively, but without waiting for the floating-point processor
to finish what it was doing first.

\H{insFDIV} \i\c{FDIV}, \i\c{FDIVP}, \i\c{FDIVR}, \i\c{FDIVRP}: Floating-Point Division

\c FDIV mem32                    ; D8 /6                [8086,FPU]
\c FDIV mem64                    ; DC /6                [8086,FPU]

\c FDIV fpureg                   ; D8 F0+r              [8086,FPU]
\c FDIV ST0,fpureg               ; D8 F0+r              [8086,FPU]

\c FDIV TO fpureg                ; DC F8+r              [8086,FPU]
\c FDIV fpureg,ST0               ; DC F8+r              [8086,FPU]

\c FDIVR mem32                   ; D8 /0                [8086,FPU]
\c FDIVR mem64                   ; DC /0                [8086,FPU]

\c FDIVR fpureg                  ; D8 F8+r              [8086,FPU]
\c FDIVR ST0,fpureg              ; D8 F8+r              [8086,FPU]

\c FDIVR TO fpureg               ; DC F0+r              [8086,FPU]
\c FDIVR fpureg,ST0              ; DC F0+r              [8086,FPU]

\c FDIVP fpureg                  ; DE F8+r              [8086,FPU]
\c FDIVP fpureg,ST0              ; DE F8+r              [8086,FPU]

\c FDIVRP fpureg                 ; DE F0+r              [8086,FPU]
\c FDIVRP fpureg,ST0             ; DE F0+r              [8086,FPU]

\c{FDIV} divides \c{ST0} by the given operand and stores the result
back in \c{ST0}, unless the \c{TO} qualifier is given, in which case
it divides the given operand by \c{ST0} and stores the result in the
operand.

\c{FDIVR} does the same thing, but does the division the other way
up: so if \c{TO} is not given, it divides the given operand by
\c{ST0} and stores the result in \c{ST0}, whereas if \c{TO} is given
it divides \c{ST0} by its operand and stores the result in the
operand.

\c{FDIVP} operates like \c{FDIV TO}, but pops the register stack
once it has finished. \c{FDIVRP} operates like \c{FDIVR TO}, but
pops the register stack once it has finished.

\H{insFFREE} \i\c{FFREE}: Flag Floating-Point Register as Unused

\c FFREE fpureg                  ; DD C0+r              [8086,FPU]

\c{FFREE} marks the given register as being empty.

\H{insFIADD} \i\c{FIADD}: Floating-Point/Integer Addition

\c FIADD mem16                   ; DE /0                [8086,FPU]
\c FIADD mem32                   ; DA /0                [8086,FPU]

\c{FIADD} adds the 16-bit or 32-bit integer stored in the given
memory location to \c{ST0}, storing the result in \c{ST0}.

\H{insFICOM} \i\c{FICOM}, \i\c{FICOMP}: Floating-Point/Integer Compare

\c FICOM mem16                   ; DE /2                [8086,FPU]
\c FICOM mem32                   ; DA /2                [8086,FPU]

\c FICOMP mem16                  ; DE /3                [8086,FPU]
\c FICOMP mem32                  ; DA /3                [8086,FPU]

\c{FICOM} compares \c{ST0} with the 16-bit or 32-bit integer stored
in the given memory location, and sets the FPU flags accordingly.
\c{FICOMP} does the same, but pops the register stack afterwards.

\H{insFIDIV} \i\c{FIDIV}, \i\c{FIDIVR}: Floating-Point/Integer Division

\c FIDIV mem16                   ; DE /6                [8086,FPU]
\c FIDIV mem32                   ; DA /6                [8086,FPU]

\c FIDIVR mem16                  ; DE /0                [8086,FPU]
\c FIDIVR mem32                  ; DA /0                [8086,FPU]

\c{FIDIV} divides \c{ST0} by the 16-bit or 32-bit integer stored in
the given memory location, and stores the result in \c{ST0}.
\c{FIDIVR} does the division the other way up: it divides the
integer by \c{ST0}, but still stores the result in \c{ST0}.

\H{insFILD} \i\c{FILD}, \i\c{FIST}, \i\c{FISTP}: Floating-Point/Integer Conversion

\c FILD mem16                    ; DF /0                [8086,FPU]
\c FILD mem32                    ; DB /0                [8086,FPU]
\c FILD mem64                    ; DF /5                [8086,FPU]

\c FIST mem16                    ; DF /2                [8086,FPU]
\c FIST mem32                    ; DB /2                [8086,FPU]

\c FISTP mem16                   ; DF /3                [8086,FPU]
\c FISTP mem32                   ; DB /3                [8086,FPU]
\c FISTP mem64                   ; DF /0                [8086,FPU]

\c{FILD} loads an integer out of a memory location, converts it to a
real, and pushes it on the FPU register stack. \c{FIST} converts
\c{ST0} to an integer and stores that in memory; \c{FISTP} does the
same as \c{FIST}, but pops the register stack afterwards.

\H{insFIMUL} \i\c{FIMUL}: Floating-Point/Integer Multiplication

\c FIMUL mem16                   ; DE /1                [8086,FPU]
\c FIMUL mem32                   ; DA /1                [8086,FPU]

\c{FIMUL} multiplies \c{ST0} by the 16-bit or 32-bit integer stored
in the given memory location, and stores the result in \c{ST0}.

\H{insFINCSTP} \i\c{FINCSTP}: Increment Floating-Point Stack Pointer

\c FINCSTP                       ; D9 F7                [8086,FPU]

\c{FINCSTP} increments the `top' field in the floating-point status
word. This has the effect of rotating the FPU register stack by one,
as if the register stack had been popped; however, unlike the
popping of the stack performed by many FPU instructions, it does not
flag the new \c{ST7} (previously \c{ST0}) as empty. See also
\c{FDECSTP} (\k{insFDECSTP}).

\H{insFINIT} \i\c{FINIT}, \i\c{FNINIT}: Initialise Floating-Point Unit

\c FINIT                         ; 9B DB E3             [8086,FPU]
\c FNINIT                        ; DB E3                [8086,FPU]

\c{FINIT} initialises the FPU to its default state. It flags all
registers as empty, though it does not actually change their values.
\c{FNINIT} does the same, without first waiting for pending
exceptions to clear.

\H{insFISUB} \i\c{FISUB}: Floating-Point/Integer Subtraction

\c FISUB mem16                   ; DE /4                [8086,FPU]
\c FISUB mem32                   ; DA /4                [8086,FPU]

\c FISUBR mem16                  ; DE /5                [8086,FPU]
\c FISUBR mem32                  ; DA /5                [8086,FPU]

\c{FISUB} subtracts the 16-bit or 32-bit integer stored in the given
memory location from \c{ST0}, and stores the result in \c{ST0}.
\c{FISUBR} does the subtraction the other way round, i.e. it
subtracts \c{ST0} from the given integer, but still stores the
result in \c{ST0}.

\H{insFLD} \i\c{FLD}: Floating-Point Load

\c FLD mem32                     ; D9 /0                [8086,FPU]
\c FLD mem64                     ; DD /0                [8086,FPU]
\c FLD mem80                     ; DB /5                [8086,FPU]
\c FLD fpureg                    ; D9 C0+r              [8086,FPU]

\c{FLD} loads a floating-point value out of the given register or
memory location, and pushes it on the FPU register stack.

\H{insFLD1} \i\c{FLDxx}: Floating-Point Load Constants

\c FLD1                          ; D9 E8                [8086,FPU]
\c FLDL2E                        ; D9 EA                [8086,FPU]
\c FLDL2T                        ; D9 E9                [8086,FPU]
\c FLDLG2                        ; D9 EC                [8086,FPU]
\c FLDLN2                        ; D9 ED                [8086,FPU]
\c FLDPI                         ; D9 EB                [8086,FPU]
\c FLDZ                          ; D9 EE                [8086,FPU]

These instructions push specific standard constants on the FPU
register stack. \c{FLD1} pushes the value 1; \c{FLDL2E} pushes the
base-2 logarithm of e; \c{FLDL2T} pushes the base-2 log of 10;
\c{FLDLG2} pushes the base-10 log of 2; \c{FLDLN2} pushes the base-e
log of 2; \c{FLDPI} pushes pi; and \c{FLDZ} pushes zero.

\H{insFLDCW} \i\c{FLDCW}: Load Floating-Point Control Word

\c FLDCW mem16                   ; D9 /5                [8086,FPU]

\c{FLDCW} loads a 16-bit value out of memory and stores it into the
FPU control word (governing things like the rounding mode, the
precision, and the exception masks). See also \c{FSTCW}
(\k{insFSTCW}).

\H{insFLDENV} \i\c{FLDENV}: Load Floating-Point Environment

\c FLDENV mem                    ; D9 /4                [8086,FPU]

\c{FLDENV} loads the FPU operating environment (control word, status
word, tag word, instruction pointer, data pointer and last opcode)
from memory. The memory area is 14 or 28 bytes long, depending on
the CPU mode at the time. See also \c{FSTENV} (\k{insFSTENV}).

\H{insFMUL} \i\c{FMUL}, \i\c{FMULP}: Floating-Point Multiply

\c FMUL mem32                    ; D8 /1                [8086,FPU]
\c FMUL mem64                    ; DC /1                [8086,FPU]

\c FMUL fpureg                   ; D8 C8+r              [8086,FPU]
\c FMUL ST0,fpureg               ; D8 C8+r              [8086,FPU]

\c FMUL TO fpureg                ; DC C8+r              [8086,FPU]
\c FMUL fpureg,ST0               ; DC C8+r              [8086,FPU]

\c FMULP fpureg                  ; DE C8+r              [8086,FPU]
\c FMULP fpureg,ST0              ; DE C8+r              [8086,FPU]

\c{FMUL} multiplies \c{ST0} by the given operand, and stores the
result in \c{ST0}, unless the \c{TO} qualifier is used in which case
it stores the result in the operand. \c{FMULP} performs the same
operation as \c{FMUL TO}, and then pops the register stack.

\H{insFNOP} \i\c{FNOP}: Floating-Point No Operation

\c FNOP                          ; D9 D0                [8086,FPU]

\c{FNOP} does nothing.

\H{insFPATAN} \i\c{FPATAN}, \i\c{FPTAN}: Arctangent and Tangent

\c FPATAN                        ; D9 F3                [8086,FPU]
\c FPTAN                         ; D9 F2                [8086,FPU]

\c{FPATAN} computes the arctangent, in radians, of the result of
dividing \c{ST1} by \c{ST0}, stores the result in \c{ST1}, and pops
the register stack. It works like the C \c{atan2} function, in that
changing the sign of both \c{ST0} and \c{ST1} changes the output
value by pi (so it performs true rectangular-to-polar coordinate
conversion, with \c{ST1} being the Y coordinate and \c{ST0} being
the X coordinate, not merely an arctangent).

\c{FPTAN} computes the tangent of the value in \c{ST0} (in radians),
and stores the result back into \c{ST0}.

\H{insFPREM} \i\c{FPREM}, \i\c{FPREM1}: Floating-Point Partial Remainder

\c FPREM                         ; D9 F8                [8086,FPU]
\c FPREM1                        ; D9 F5                [386,FPU]

These instructions both produce the remainder obtained by dividing
\c{ST0} by \c{ST1}. This is calculated, notionally, by dividing
\c{ST0} by \c{ST1}, rounding the result to an integer, multiplying
by \c{ST1} again, and computing the value which would need to be
added back on to the result to get back to the original value in
\c{ST0}.

The two instructions differ in the way the notional round-to-integer
operation is performed. \c{FPREM} does it by rounding towards zero,
so that the remainder it returns always has the same sign as the
original value in \c{ST0}; \c{FPREM1} does it by rounding to the
nearest integer, so that the remainder always has at most half the
magnitude of \c{ST1}.

Both instructions calculate \e{partial} remainders, meaning that
they may not manage to provide the final result, but might leave
intermediate results in \c{ST0} instead. If this happens, they will
set the C2 flag in the FPU status word; therefore, to calculate a
remainder, you should repeatedly execute \c{FPREM} or \c{FPREM1}
until C2 becomes clear.

\H{insFRNDINT} \i\c{FRNDINT}: Floating-Point Round to Integer

\c FRNDINT                       ; D9 FC                [8086,FPU]

\c{FRNDINT} rounds the contents of \c{ST0} to an integer, according
to the current rounding mode set in the FPU control word, and stores
the result back in \c{ST0}.

\H{insFRSTOR} \i\c{FSAVE}, \i\c{FRSTOR}: Save/Restore Floating-Point State

\c FSAVE mem                     ; 9B DD /6             [8086,FPU]
\c FNSAVE mem                    ; DD /6                [8086,FPU]

\c FRSTOR mem                    ; DD /4                [8086,FPU]

\c{FSAVE} saves the entire floating-point unit state, including all
the information saved by \c{FSTENV} (\k{insFSTENV}) plus the
contents of all the registers, to a 94 or 108 byte area of memory
(depending on the CPU mode). \c{FRSTOR} restores the floating-point
state from the same area of memory.

\c{FNSAVE} does the same as \c{FSAVE}, without first waiting for
pending floating-point exceptions to clear.

\H{insFSCALE} \i\c{FSCALE}: Scale Floating-Point Value by Power of Two

\c FSCALE                        ; D9 FD                [8086,FPU]

\c{FSCALE} scales a number by a power of two: it rounds \c{ST1}
towards zero to obtain an integer, then multiplies \c{ST0} by two to
the power of that integer, and stores the result in \c{ST0}.

\H{insFSETPM} \i\c{FSETPM}: Set Protected Mode

\c FSETPM                        ; DB E4                [286,FPU]

This instruction initalises protected mode on the 287 floating-point
coprocessor. It is only meaningful on that processor: the 387 and
above treat the instruction as a no-operation.

\H{insFSIN} \i\c{FSIN}, \i\c{FSINCOS}: Sine and Cosine

\c FSIN                          ; D9 FE                [386,FPU]
\c FSINCOS                       ; D9 FB                [386,FPU]

\c{FSIN} calculates the sine of \c{ST0} (in radians) and stores the
result in \c{ST0}. \c{FSINCOS} does the same, but then pushes the
cosine of the same value on the register stack, so that the sine
ends up in \c{ST1} and the cosine in \c{ST0}. \c{FSINCOS} is faster
than executing \c{FSIN} and \c{FCOS} (see \k{insFCOS}) in
succession.

\H{insFSQRT} \i\c{FSQRT}: Floating-Point Square Root

\c FSQRT                         ; D9 FA                [8086,FPU]

\c{FSQRT} calculates the square root of \c{ST0} and stores the
result in \c{ST0}.

\H{insFST} \i\c{FST}, \i\c{FSTP}: Floating-Point Store

\c FST mem32                     ; D9 /2                [8086,FPU]
\c FST mem64                     ; DD /2                [8086,FPU]
\c FST fpureg                    ; DD D0+r              [8086,FPU]

\c FSTP mem32                    ; D9 /3                [8086,FPU]
\c FSTP mem64                    ; DD /3                [8086,FPU]
\c FSTP mem80                    ; DB /0                [8086,FPU]
\c FSTP fpureg                   ; DD D8+r              [8086,FPU]

\c{FST} stores the value in \c{ST0} into the given memory location
or other FPU register. \c{FSTP} does the same, but then pops the
register stack.

\H{insFSTCW} \i\c{FSTCW}: Store Floating-Point Control Word

\c FSTCW mem16                   ; 9B D9 /0             [8086,FPU]
\c FNSTCW mem16                  ; D9 /0                [8086,FPU]

\c{FSTCW} stores the FPU control word (governing things like the
rounding mode, the precision, and the exception masks) into a 2-byte
memory area. See also \c{FLDCW} (\k{insFLDCW}).

\c{FNSTCW} does the same thing as \c{FSTCW}, without first waiting
for pending floating-point exceptions to clear.

\H{insFSTENV} \i\c{FSTENV}: Store Floating-Point Environment

\c FSTENV mem                    ; 9B D9 /6             [8086,FPU]
\c FNSTENV mem                   ; D9 /6                [8086,FPU]

\c{FSTENV} stores the FPU operating environment (control word,
status word, tag word, instruction pointer, data pointer and last
opcode) into memory. The memory area is 14 or 28 bytes long,
depending on the CPU mode at the time. See also \c{FLDENV}
(\k{insFLDENV}).

\c{FNSTENV} does the same thing as \c{FSTENV}, without first waiting
for pending floating-point exceptions to clear.

\H{insFSTSW} \i\c{FSTSW}: Store Floating-Point Status Word

\c FSTSW mem16                   ; 9B DD /0             [8086,FPU]
\c FSTSW AX                      ; 9B DF E0             [286,FPU]

\c FNSTSW mem16                  ; DD /0                [8086,FPU]
\c FNSTSW AX                     ; DF E0                [286,FPU]

\c{FSTSW} stores the FPU status word into \c{AX} or into a 2-byte
memory area.

\c{FNSTSW} does the same thing as \c{FSTSW}, without first waiting
for pending floating-point exceptions to clear.

\H{insFSUB} \i\c{FSUB}, \i\c{FSUBP}, \i\c{FSUBR}, \i\c{FSUBRP}: Floating-Point Subtract

\c FSUB mem32                    ; D8 /4                [8086,FPU]
\c FSUB mem64                    ; DC /4                [8086,FPU]

\c FSUB fpureg                   ; D8 E0+r              [8086,FPU]
\c FSUB ST0,fpureg               ; D8 E0+r              [8086,FPU]

\c FSUB TO fpureg                ; DC E8+r              [8086,FPU]
\c FSUB fpureg,ST0               ; DC E8+r              [8086,FPU]

\c FSUBR mem32                   ; D8 /5                [8086,FPU]
\c FSUBR mem64                   ; DC /5                [8086,FPU]

\c FSUBR fpureg                  ; D8 E8+r              [8086,FPU]
\c FSUBR ST0,fpureg              ; D8 E8+r              [8086,FPU]

\c FSUBR TO fpureg               ; DC E0+r              [8086,FPU]
\c FSUBR fpureg,ST0              ; DC E0+r              [8086,FPU]

\c FSUBP fpureg                  ; DE E8+r              [8086,FPU]
\c FSUBP fpureg,ST0              ; DE E8+r              [8086,FPU]

\c FSUBRP fpureg                 ; DE E0+r              [8086,FPU]
\c FSUBRP fpureg,ST0             ; DE E0+r              [8086,FPU]

\c{FSUB} subtracts the given operand from \c{ST0} and stores the
result back in \c{ST0}, unless the \c{TO} qualifier is given, in
which case it subtracts \c{ST0} from the given operand and stores
the result in the operand.

\c{FSUBR} does the same thing, but does the subtraction the other way
up: so if \c{TO} is not given, it subtracts \c{ST0} from the given
operand and stores the result in \c{ST0}, whereas if \c{TO} is given
it subtracts its operand from \c{ST0} and stores the result in the
operand.

\c{FSUBP} operates like \c{FSUB TO}, but pops the register stack
once it has finished. \c{FSUBRP} operates like \c{FSUBR TO}, but
pops the register stack once it has finished.

\H{insFTST} \i\c{FTST}: Test \c{ST0} Against Zero

\c FTST                          ; D9 E4                [8086,FPU]

\c{FTST} compares \c{ST0} with zero and sets the FPU flags
accordingly. \c{ST0} is treated as the left-hand side of the
comparison, so that a `less-than' result is generated if \c{ST0} is
negative.

\H{insFUCOM} \i\c{FUCOMxx}: Floating-Point Unordered Compare

\c FUCOM fpureg                  ; DD E0+r              [386,FPU]
\c FUCOM ST0,fpureg              ; DD E0+r              [386,FPU]

\c FUCOMP fpureg                 ; DD E8+r              [386,FPU]
\c FUCOMP ST0,fpureg             ; DD E8+r              [386,FPU]

\c FUCOMPP                       ; DA E9                [386,FPU]

\c FUCOMI fpureg                 ; DB E8+r              [P6,FPU]
\c FUCOMI ST0,fpureg             ; DB E8+r              [P6,FPU]

\c FUCOMIP fpureg                ; DF E8+r              [P6,FPU]
\c FUCOMIP ST0,fpureg            ; DF E8+r              [P6,FPU]

\c{FUCOM} compares \c{ST0} with the given operand, and sets the FPU
flags accordingly. \c{ST0} is treated as the left-hand side of the
comparison, so that the carry flag is set (for a `less-than' result)
if \c{ST0} is less than the given operand.

\c{FUCOMP} does the same as \c{FUCOM}, but pops the register stack
afterwards. \c{FUCOMPP} compares \c{ST0} with \c{ST1} and then pops
the register stack twice.

\c{FUCOMI} and \c{FUCOMIP} work like the corresponding forms of
\c{FUCOM} and \c{FUCOMP}, but write their results directly to the CPU
flags register rather than the FPU status word, so they can be
immediately followed by conditional jump or conditional move
instructions.

The \c{FUCOM} instructions differ from the \c{FCOM} instructions
(\k{insFCOM}) only in the way they handle quiet NaNs: \c{FUCOM} will
handle them silently and set the condition code flags to an
`unordered' result, whereas \c{FCOM} will generate an exception.

\H{insFXAM} \i\c{FXAM}: Examine Class of Value in \c{ST0}

\c FXAM                          ; D9 E5                [8086,FPU]

\c{FXAM} sets the FPU flags C3, C2 and C0 depending on the type of
value stored in \c{ST0}: 000 (respectively) for an unsupported
format, 001 for a NaN, 010 for a normal finite number, 011 for an
infinity, 100 for a zero, 101 for an empty register, and 110 for a
denormal. It also sets the C1 flag to the sign of the number.

\H{insFXCH} \i\c{FXCH}: Floating-Point Exchange

\c FXCH                          ; D9 C9                [8086,FPU]
\c FXCH fpureg                   ; D9 C8+r              [8086,FPU]
\c FXCH fpureg,ST0               ; D9 C8+r              [8086,FPU]
\c FXCH ST0,fpureg               ; D9 C8+r              [8086,FPU]

\c{FXCH} exchanges \c{ST0} with a given FPU register. The no-operand
form exchanges \c{ST0} with \c{ST1}.

\H{insFXTRACT} \i\c{FXTRACT}: Extract Exponent and Significand

\c FXTRACT                       ; D9 F4                [8086,FPU]

\c{FXTRACT} separates the number in \c{ST0} into its exponent and
significand (mantissa), stores the exponent back into \c{ST0}, and
then pushes the significand on the register stack (so that the
significand ends up in \c{ST0}, and the exponent in \c{ST1}).

\H{insFYL2X} \i\c{FYL2X}, \i\c{FYL2XP1}: Compute Y times Log2(X) or Log2(X+1)

\c FYL2X                         ; D9 F1                [8086,FPU]
\c FYL2XP1                       ; D9 F9                [8086,FPU]

\c{FYL2X} multiplies \c{ST1} by the base-2 logarithm of \c{ST0},
stores the result in \c{ST1}, and pops the register stack (so that
the result ends up in \c{ST0}). \c{ST0} must be non-zero and
positive.

\c{FYL2XP1} works the same way, but replacing the base-2 log of
\c{ST0} with that of \c{ST0} plus one. This time, \c{ST0} must have
magnitude no greater than 1 minus half the square root of two.

\H{insHLT} \i\c{HLT}: Halt Processor

\c HLT                           ; F4                   [8086]

\c{HLT} puts the processor into a halted state, where it will
perform no more operations until restarted by an interrupt or a
reset.

\H{insIBTS} \i\c{IBTS}: Insert Bit String

\c IBTS r/m16,reg16              ; o16 0F A7 /r         [386,UNDOC]
\c IBTS r/m32,reg32              ; o32 0F A7 /r         [386,UNDOC]

No clear documentation seems to be available for this instruction:
the best I've been able to find reads `Takes a string of bits from
the second operand and puts them in the first operand'. It is
present only in early 386 processors, and conflicts with the opcodes
for \c{CMPXCHG486}. NASM supports it only for completeness. Its
counterpart is \c{XBTS} (see \k{insXBTS}).

\H{insIDIV} \i\c{IDIV}: Signed Integer Divide

\c IDIV r/m8                     ; F6 /7                [8086]
\c IDIV r/m16                    ; o16 F7 /7            [8086]
\c IDIV r/m32                    ; o32 F7 /7            [386]

\c{IDIV} performs signed integer division. The explicit operand
provided is the divisor; the dividend and destination operands are
implicit, in the following way:

\b For \c{IDIV r/m8}, \c{AX} is divided by the given operand; the
quotient is stored in \c{AL} and the remainder in \c{AH}.

\b For \c{IDIV r/m16}, \c{DX:AX} is divided by the given operand; the
quotient is stored in \c{AX} and the remainder in \c{DX}.

\b For \c{IDIV r/m32}, \c{EDX:EAX} is divided by the given operand;
the quotient is stored in \c{EAX} and the remainder in \c{EDX}.

Unsigned integer division is performed by the \c{DIV} instruction:
see \k{insDIV}.

\H{insIMUL} \i\c{IMUL}: Signed Integer Multiply

\c IMUL r/m8                     ; F6 /5                [8086]
\c IMUL r/m16                    ; o16 F7 /5            [8086]
\c IMUL r/m32                    ; o32 F7 /5            [386]

\c IMUL reg16,r/m16              ; o16 0F AF /r         [386]
\c IMUL reg32,r/m32              ; o32 0F AF /r         [386]

\c IMUL reg16,imm8               ; o16 6B /r ib         [286]
\c IMUL reg16,imm16              ; o16 69 /r iw         [286]
\c IMUL reg32,imm8               ; o32 6B /r ib         [386]
\c IMUL reg32,imm32              ; o32 69 /r id         [386]

\c IMUL reg16,r/m16,imm8         ; o16 6B /r ib         [286]
\c IMUL reg16,r/m16,imm16        ; o16 69 /r iw         [286]
\c IMUL reg32,r/m32,imm8         ; o32 6B /r ib         [386]
\c IMUL reg32,r/m32,imm32        ; o32 69 /r id         [386]

\c{IMUL} performs signed integer multiplication. For the
single-operand form, the other operand and destination are implicit,
in the following way:

\b For \c{IMUL r/m8}, \c{AL} is multiplied by the given operand; the
product is stored in \c{AX}.

\b For \c{IMUL r/m16}, \c{AX} is multiplied by the given operand;
the product is stored in \c{DX:AX}.

\b For \c{IMUL r/m32}, \c{EAX} is multiplied by the given operand;
the product is stored in \c{EDX:EAX}.

The two-operand form multiplies its two operands and stores the
result in the destination (first) operand. The three-operand form
multiplies its last two operands and stores the result in the first
operand.

The two-operand form is in fact a shorthand for the three-operand
form, as can be seen by examining the opcode descriptions: in the
two-operand form, the code \c{/r} takes both its register and
\c{r/m} parts from the same operand (the first one).

In the forms with an 8-bit immediate operand and another longer
source operand, the immediate operand is considered to be signed,
and is sign-extended to the length of the other source operand. In
these cases, the \c{BYTE} qualifier is necessary to force NASM to
generate this form of the instruction.

Unsigned integer multiplication is performed by the \c{MUL}
instruction: see \k{insMUL}.

\H{insIN} \i\c{IN}: Input from I/O Port

\c IN AL,imm8                    ; E4 ib                [8086]
\c IN AX,imm8                    ; o16 E5 ib            [8086]
\c IN EAX,imm8                   ; o32 E5 ib            [386]
\c IN AL,DX                      ; EC                   [8086]
\c IN AX,DX                      ; o16 ED               [8086]
\c IN EAX,DX                     ; o32 ED               [386]

\c{IN} reads a byte, word or doubleword from the specified I/O port,
and stores it in the given destination register. The port number may
be specified as an immediate value if it is between 0 and 255, and
otherwise must be stored in \c{DX}. See also \c{OUT} (\k{insOUT}).

\H{insINC} \i\c{INC}: Increment Integer

\c INC reg16                     ; o16 40+r             [8086]
\c INC reg32                     ; o32 40+r             [386]
\c INC r/m8                      ; FE /0                [8086]
\c INC r/m16                     ; o16 FF /0            [8086]
\c INC r/m32                     ; o32 FF /0            [386]

\c{INC} adds 1 to its operand. It does \e{not} affect the carry
flag: to affect the carry flag, use \c{ADD something,1} (see
\k{insADD}). See also \c{DEC} (\k{insDEC}).

\H{insINSB} \i\c{INSB}, \i\c{INSW}, \i\c{INSD}: Input String from I/O Port

\c INSB                          ; 6C                   [186]
\c INSW                          ; o16 6D               [186]
\c INSD                          ; o32 6D               [386]

\c{INSB} inputs a byte from the I/O port specified in \c{DX} and
stores it at \c{[ES:DI]} or \c{[ES:EDI]}. It then increments or
decrements (depending on the direction flag: increments if the flag
is clear, decrements if it is set) \c{DI} or \c{EDI}.

The register used is \c{DI} if the address size is 16 bits, and
\c{EDI} if it is 32 bits. If you need to use an address size not
equal to the current \c{BITS} setting, you can use an explicit
\i\c{a16} or \i\c{a32} prefix.

Segment override prefixes have no effect for this instruction: the
use of \c{ES} for the load from \c{[DI]} or \c{[EDI]} cannot be
overridden.

\c{INSW} and \c{INSD} work in the same way, but they input a word or
a doubleword instead of a byte, and increment or decrement the
addressing register by 2 or 4 instead of 1.

The \c{REP} prefix may be used to repeat the instruction \c{CX} (or
\c{ECX} - again, the address size chooses which) times.

See also \c{OUTSB}, \c{OUTSW} and \c{OUTSD} (\k{insOUTSB}).

\H{insINT} \i\c{INT}: Software Interrupt

\c INT imm8                      ; CD ib                [8086]

\c{INT} causes a software interrupt through a specified vector
number from 0 to 255.

The code generated by the \c{INT} instruction is always two bytes
long: although there are short forms for some \c{INT} instructions,
NASM does not generate them when it sees the \c{INT} mnemonic. In
order to generate single-byte breakpoint instructions, use the
\c{INT3} or \c{INT1} instructions (see \k{insINT1}) instead.

\H{insINT1} \i\c{INT3}, \i\c{INT1}, \i\c{ICEBP}, \i\c{INT01}: Breakpoints

\c INT1                          ; F1                   [P6]
\c ICEBP                         ; F1                   [P6]
\c INT01                         ; F1                   [P6]

\c INT3                          ; CC                   [8086]

\c{INT1} and \c{INT3} are short one-byte forms of the instructions
\c{INT 1} and \c{INT 3} (see \k{insINT}). They perform a similar
function to their longer counterparts, but take up less code space.
They are used as breakpoints by debuggers.

\c{INT1}, and its alternative synonyms \c{INT01} and \c{ICEBP}, is
an instruction used by in-circuit emulators (ICEs). It is present,
though not documented, on some processors down to the 286, but is
only documented for the Pentium Pro. \c{INT3} is the instruction
normally used as a breakpoint by debuggers.

\c{INT3} is not precisely equivalent to \c{INT 3}: the short form,
since it is designed to be used as a breakpoint, bypasses the normal
IOPL checks in virtual-8086 mode, and also does not go through
interrupt redirection.

\H{insINTO} \i\c{INTO}: Interrupt if Overflow

\c INTO                          ; CE                   [8086]

\c{INTO} performs an \c{INT 4} software interrupt (see \k{insINT})
if and only if the overflow flag is set.

\H{insINVD} \i\c{INVD}: Invalidate Internal Caches

\c INVD                          ; 0F 08                [486]

\c{INVD} invalidates and empties the processor's internal caches,
and causes the processor to instruct external caches to do the same.
It does not write the contents of the caches back to memory first:
any modified data held in the caches will be lost. To write the data
back first, use \c{WBINVD} (\k{insWBINVD}).

\H{insINVLPG} \i\c{INVLPG}: Invalidate TLB Entry

\c INVLPG mem                    ; 0F 01 /0             [486]

\c{INVLPG} invalidates the translation lookahead buffer (TLB) entry
associated with the supplied memory address.

\H{insIRET} \i\c{IRET}, \i\c{IRETW}, \i\c{IRETD}: Return from Interrupt

\c IRET                          ; CF                   [8086]
\c IRETW                         ; o16 CF               [8086]
\c IRETD                         ; o32 CF               [386]

\c{IRET} returns from an interrupt (hardware or software) by means
of popping \c{IP} (or \c{EIP}), \c{CS} and the flags off the stack
and then continuing execution from the new \c{CS:IP}.

\c{IRETW} pops \c{IP}, \c{CS} and the flags as 2 bytes each, taking
6 bytes off the stack in total. \c{IRETD} pops \c{EIP} as 4 bytes,
pops a further 4 bytes of which the top two are discarded and the
bottom two go into \c{CS}, and pops the flags as 4 bytes as well,
taking 12 bytes off the stack.

\c{IRET} is a shorthand for either \c{IRETW} or \c{IRETD}, depending
on the default \c{BITS} setting at the time.

\H{insJCXZ} \i\c{JCXZ}, \i\c{JECXZ}: Jump if CX/ECX Zero

\c JCXZ imm                      ; o16 E3 rb            [8086]
\c JECXZ imm                     ; o32 E3 rb            [386]

\c{JCXZ} performs a short jump (with maximum range 128 bytes) if and
only if the contents of the \c{CX} register is 0. \c{JECXZ} does the
same thing, but with \c{ECX}.

\H{insJMP} \i\c{JMP}: Jump

\c JMP imm                       ; E9 rw/rd             [8086]
\c JMP SHORT imm                 ; EB rb                [8086]
\c JMP imm:imm16                 ; o16 EA iw iw         [8086]
\c JMP imm:imm32                 ; o32 EA id iw         [386]
\c JMP FAR mem                   ; o16 FF /5            [8086]
\c JMP FAR mem                   ; o32 FF /5            [386]
\c JMP r/m16                     ; o16 FF /4            [8086]
\c JMP r/m32                     ; o32 FF /4            [386]

\c{JMP} jumps to a given address. The address may be specified as an
absolute segment and offset, or as a relative jump within the
current segment.

\c{JMP SHORT imm} has a maximum range of 128 bytes, since the
displacement is specified as only 8 bits, but takes up less code
space. NASM does not choose when to generate \c{JMP SHORT} for you:
you must explicitly code \c{SHORT} every time you want a short jump.

You can choose between the two immediate \i{far jump} forms (\c{JMP
imm:imm}) by the use of the \c{WORD} and \c{DWORD} keywords: \c{JMP
WORD 0x1234:0x5678}) or \c{JMP DWORD 0x1234:0x56789abc}.

The \c{JMP FAR mem} forms execute a far jump by loading the
destination address out of memory. The address loaded consists of 16
or 32 bits of offset (depending on the operand size), and 16 bits of
segment. The operand size may be overridden using \c{JMP WORD FAR
mem} or \c{JMP DWORD FAR mem}.

The \c{JMP r/m} forms execute a \i{near jump} (within the same
segment), loading the destination address out of memory or out of a
register. The keyword \c{NEAR} may be specified, for clarity, in
these forms, but is not necessary. Again, operand size can be
overridden using \c{JMP WORD mem} or \c{JMP DWORD mem}.

As a convenience, NASM does not require you to jump to a far symbol
by coding the cumbersome \c{JMP SEG routine:routine}, but instead
allows the easier synonym \c{JMP FAR routine}.

The \c{CALL r/m} forms given above are near calls; NASM will accept
the \c{NEAR} keyword (e.g. \c{CALL NEAR [address]}), even though it
is not strictly necessary.

\H{insJcc} \i\c{Jcc}: Conditional Branch

\c Jcc imm                       ; 70+cc rb             [8086]
\c Jcc NEAR imm                  ; 0F 80+cc rw/rd       [386]

The \i{conditional jump} instructions execute a near (same segment)
jump if and only if their conditions are satisfied. For example,
\c{JNZ} jumps only if the zero flag is not set.

The ordinary form of the instructions has only a 128-byte range; the
\c{NEAR} form is a 386 extension to the instruction set, and can
span the full size of a segment. NASM will not override your choice
of jump instruction: if you want \c{Jcc NEAR}, you have to use the
\c{NEAR} keyword.

The \c{SHORT} keyword is allowed on the first form of the
instruction, for clarity, but is not necessary.

\H{insLAHF} \i\c{LAHF}: Load AH from Flags

\c LAHF                          ; 9F                   [8086]

\c{LAHF} sets the \c{AH} register according to the contents of the
low byte of the flags word. See also \c{SAHF} (\k{insSAHF}).

\H{insLAR} \i\c{LAR}: Load Access Rights

\c LAR reg16,r/m16               ; o16 0F 02 /r         [286,PRIV]
\c LAR reg32,r/m32               ; o32 0F 02 /r         [286,PRIV]

\c{LAR} takes the segment selector specified by its source (second)
operand, finds the corresponding segment descriptor in the GDT or
LDT, and loads the access-rights byte of the descriptor into its
destination (first) operand.

\H{insLDS} \i\c{LDS}, \i\c{LES}, \i\c{LFS}, \i\c{LGS}, \i\c{LSS}: Load Far Pointer

\c LDS reg16,mem                 ; o16 C5 /r            [8086]
\c LDS reg32,mem                 ; o32 C5 /r            [8086]

\c LES reg16,mem                 ; o16 C4 /r            [8086]
\c LES reg32,mem                 ; o32 C4 /r            [8086]

\c LFS reg16,mem                 ; o16 0F B4 /r         [386]
\c LFS reg32,mem                 ; o32 0F B4 /r         [386]

\c LGS reg16,mem                 ; o16 0F B5 /r         [386]
\c LGS reg32,mem                 ; o32 0F B5 /r         [386]

\c LSS reg16,mem                 ; o16 0F B2 /r         [386]
\c LSS reg32,mem                 ; o32 0F B2 /r         [386]

These instructions load an entire far pointer (16 or 32 bits of
offset, plus 16 bits of segment) out of memory in one go. \c{LDS},
for example, loads 16 or 32 bits from the given memory address into
the given register (depending on the size of the register), then
loads the \e{next} 16 bits from memory into \c{DS}. \c{LES},
\c{LFS}, \c{LGS} and \c{LSS} work in the same way but use the other
segment registers.

\H{insLEA} \i\c{LEA}: Load Effective Address

\c LEA reg16,mem                 ; o16 8D /r            [8086]
\c LEA reg32,mem                 ; o32 8D /r            [8086]

\c{LEA}, despite its syntax, does not access memory. It calculates
the effective address specified by its second operand as if it were
going to load or store data from it, but instead it stores the
calculated address into the register specified by its first operand.
This can be used to perform quite complex calculations (e.g. \c{LEA
EAX,[EBX+ECX*4+100]}) in one instruction.

\c{LEA}, despite being a purely arithmetic instruction which
accesses no memory, still requires square brackets around its second
operand, as if it were a memory reference.

\H{insLEAVE} \i\c{LEAVE}: Destroy Stack Frame

\c LEAVE                         ; C9                   [186]

\c{LEAVE} destroys a stack frame of the form created by the
\c{ENTER} instruction (see \k{insENTER}). It is functionally
equivalent to \c{MOV ESP,EBP} followed by \c{POP EBP} (or \c{MOV
SP,BP} followed by \c{POP BP} in 16-bit mode).

\H{insLGDT} \i\c{LGDT}, \i\c{LIDT}, \i\c{LLDT}: Load Descriptor Tables

\c LGDT mem                      ; 0F 01 /2             [286,PRIV]
\c LIDT mem                      ; 0F 01 /3             [286,PRIV]
\c LLDT r/m16                    ; 0F 00 /2             [286,PRIV]

\c{LGDT} and \c{LIDT} both take a 6-byte memory area as an operand:
they load a 32-bit linear address and a 16-bit size limit from that
area (in the opposite order) into the GDTR (global descriptor table
register) or IDTR (interrupt descriptor table register). These are
the only instructions which directly use \e{linear} addresses,
rather than segment/offset pairs.

\c{LLDT} takes a segment selector as an operand. The processor looks
up that selector in the GDT and stores the limit and base address
given there into the LDTR (local descriptor table register).

See also \c{SGDT}, \c{SIDT} and \c{SLDT} (\k{insSGDT}).

\H{insLMSW} \i\c{LMSW}: Load/Store Machine Status Word

\c LMSW r/m16                    ; 0F 01 /6             [286,PRIV]

\c{LMSW} loads the bottom four bits of the source operand into the
bottom four bits of the \c{CR0} control register (or the Machine
Status Word, on 286 processors). See also \c{SMSW} (\k{insSMSW}).

\H{insLOADALL} \i\c{LOADALL}, \i\c{LOADALL286}: Load Processor State

\c LOADALL                       ; 0F 07                [386,UNDOC]
\c LOADALL286                    ; 0F 05                [286,UNDOC]

This instruction, in its two different-opcode forms, is apparently
supported on most 286 processors, some 386 and possibly some 486.
The opcode differs between the 286 and the 386.

The function of the instruction is to load all information relating
to the state of the processor out of a block of memory: on the 286,
this block is located implicitly at absolute address \c{0x800}, and
on the 386 and 486 it is at \c{[ES:EDI]}.

\H{insLODSB} \i\c{LODSB}, \i\c{LODSW}, \i\c{LODSD}: Load from String

\c LODSB                         ; AC                   [8086]
\c LODSW                         ; o16 AD               [8086]
\c LODSD                         ; o32 AD               [386]

\c{LODSB} loads a byte from \c{[DS:SI]} or \c{[DS:ESI]} into \c{AL}.
It then increments or decrements (depending on the direction flag:
increments if the flag is clear, decrements if it is set) \c{SI} or
\c{ESI}.

The register used is \c{SI} if the address size is 16 bits, and
\c{ESI} if it is 32 bits. If you need to use an address size not
equal to the current \c{BITS} setting, you can use an explicit
\i\c{a16} or \i\c{a32} prefix.

The segment register used to load from \c{[SI]} or \c{[ESI]} can be
overridden by using a segment register name as a prefix (for
example, \c{es lodsb}).

\c{LODSW} and \c{LODSD} work in the same way, but they load a
word or a doubleword instead of a byte, and increment or decrement
the addressing registers by 2 or 4 instead of 1.

\H{insLOOP} \i\c{LOOP}, \i\c{LOOPE}, \i\c{LOOPZ}, \i\c{LOOPNE}, \i\c{LOOPNZ}: Loop with Counter

\c LOOP imm                      ; E2 rb                [8086]
\c LOOP imm,CX                   ; a16 E2 rb            [8086]
\c LOOP imm,ECX                  ; a32 E2 rb            [386]

\c LOOPE imm                     ; E1 rb                [8086]
\c LOOPE imm,CX                  ; a16 E1 rb            [8086]
\c LOOPE imm,ECX                 ; a32 E1 rb            [386]
\c LOOPZ imm                     ; E1 rb                [8086]
\c LOOPZ imm,CX                  ; a16 E1 rb            [8086]
\c LOOPZ imm,ECX                 ; a32 E1 rb            [386]

\c LOOPNE imm                    ; E0 rb                [8086]
\c LOOPNE imm,CX                 ; a16 E0 rb            [8086]
\c LOOPNE imm,ECX                ; a32 E0 rb            [386]
\c LOOPNZ imm                    ; E0 rb                [8086]
\c LOOPNZ imm,CX                 ; a16 E0 rb            [8086]
\c LOOPNZ imm,ECX                ; a32 E0 rb            [386]

\c{LOOP} decrements its counter register (either \c{CX} or \c{ECX} -
if one is not specified explicitly, the \c{BITS} setting dictates
which is used) by one, and if the counter does not become zero as a
result of this operation, it jumps to the given label. The jump has
a range of 128 bytes.

\c{LOOPE} (or its synonym \c{LOOPZ}) adds the additional condition
that it only jumps if the counter is nonzero \e{and} the zero flag
is set. Similarly, \c{LOOPNE} (and \c{LOOPNZ}) jumps only if the
counter is nonzero and the zero flag is clear.

\H{insLSL} \i\c{LSL}: Load Segment Limit

\c LSL reg16,r/m16               ; o16 0F 03 /r         [286,PRIV]
\c LSL reg32,r/m32               ; o32 0F 03 /r         [286,PRIV]

\c{LSL} is given a segment selector in its source (second) operand;
it computes the segment limit value by loading the segment limit
field from the associated segment descriptor in the GDT or LDT.
(This involves shifting left by 12 bits if the segment limit is
page-granular, and not if it is byte-granular; so you end up with a
byte limit in either case.) The segment limit obtained is then
loaded into the destination (first) operand.

\H{insLTR} \i\c{LTR}: Load Task Register

\c LTR r/m16                     ; 0F 00 /3             [286,PRIV]

\c{LTR} looks up the segment base and limit in the GDT or LDT
descriptor specified by the segment selector given as its operand,
and loads them into the Task Register.

\H{insMOV} \i\c{MOV}: Move Data

\c MOV r/m8,reg8                 ; 88 /r                [8086]
\c MOV r/m16,reg16               ; o16 89 /r            [8086]
\c MOV r/m32,reg32               ; o32 89 /r            [386]
\c MOV reg8,r/m8                 ; 8A /r                [8086]
\c MOV reg16,r/m16               ; o16 8B /r            [8086]
\c MOV reg32,r/m32               ; o32 8B /r            [386]

\c MOV reg8,imm8                 ; B0+r ib              [8086]
\c MOV reg16,imm16               ; o16 B8+r iw          [8086]
\c MOV reg32,imm32               ; o32 B8+r id          [386]
\c MOV r/m8,imm8                 ; C6 /0 ib             [8086]
\c MOV r/m16,imm16               ; o16 C7 /0 iw         [8086]
\c MOV r/m32,imm32               ; o32 C7 /0 id         [386]

\c MOV AL,memoffs8               ; A0 ow/od             [8086]
\c MOV AX,memoffs16              ; o16 A1 ow/od         [8086]
\c MOV EAX,memoffs32             ; o32 A1 ow/od         [386]
\c MOV memoffs8,AL               ; A2 ow/od             [8086]
\c MOV memoffs16,AX              ; o16 A3 ow/od         [8086]
\c MOV memoffs32,EAX             ; o32 A3 ow/od         [386]

\c MOV r/m16,segreg              ; o16 8C /r            [8086]
\c MOV r/m32,segreg              ; o32 8C /r            [386]
\c MOV segreg,r/m16              ; o16 8E /r            [8086]
\c MOV segreg,r/m32              ; o32 8E /r            [386]

\c MOV reg32,CR0/2/3/4           ; 0F 20 /r             [386]
\c MOV reg32,DR0/1/2/3/6/7       ; 0F 21 /r             [386]
\c MOV reg32,TR3/4/5/6/7         ; 0F 24 /r             [386]
\c MOV CR0/2/3/4,reg32           ; 0F 22 /r             [386]
\c MOV DR0/1/2/3/6/7,reg32       ; 0F 23 /r             [386]
\c MOV TR3/4/5/6/7,reg32         ; 0F 26 /r             [386]

\c{MOV} copies the contents of its source (second) operand into its
destination (first) operand.

In all forms of the \c{MOV} instruction, the two operands are the
same size, except for moving between a segment register and an
\c{r/m32} operand. These instructions are treated exactly like the
corresponding 16-bit equivalent (so that, for example, \c{MOV
DS,EAX} functions identically to \c{MOV DS,AX} but saves a prefix
when in 32-bit mode), except that when a segment register is moved
into a 32-bit destination, the top two bytes of the result are
undefined.

\c{MOV} may not use \c{CS} as a destination.

\c{CR4} is only a supported register on the Pentium and above.

\H{insMOVD} \i\c{MOVD}: Move Doubleword to/from MMX Register

\c MOVD mmxreg,r/m32             ; 0F 6E /r             [PENT,MMX]
\c MOVD r/m32,mmxreg             ; 0F 7E /r             [PENT,MMX]

\c{MOVD} copies 32 bits from its source (second) operand into its
destination (first) operand. When the destination is a 64-bit MMX
register, the top 32 bits are set to zero.

\H{insMOVQ} \i\c{MOVQ}: Move Quadword to/from MMX Register

\c MOVQ mmxreg,r/m64             ; 0F 6F /r             [PENT,MMX]
\c MOVQ r/m64,mmxreg             ; 0F 7F /r             [PENT,MMX]

\c{MOVQ} copies 64 bits from its source (second) operand into its
destination (first) operand.

\H{insMOVSB} \i\c{MOVSB}, \i\c{MOVSW}, \i\c{MOVSD}: Move String

\c MOVSB                         ; A4                   [8086]
\c MOVSW                         ; o16 A5               [8086]
\c MOVSD                         ; o32 A5               [386]

\c{MOVSB} copies the byte at \c{[ES:SI]} or \c{[ES:ESI]} to
\c{[DS:DI]} or \c{[DS:EDI]}. It then increments or decrements
(depending on the direction flag: increments if the flag is clear,
decrements if it is set) \c{SI} and \c{DI} (or \c{ESI} and \c{EDI}).

The registers used are \c{SI} and \c{DI} if the address size is 16
bits, and \c{ESI} and \c{EDI} if it is 32 bits. If you need to use
an address size not equal to the current \c{BITS} setting, you can
use an explicit \i\c{a16} or \i\c{a32} prefix.

The segment register used to load from \c{[SI]} or \c{[ESI]} can be
overridden by using a segment register name as a prefix (for
example, \c{es movsb}). The use of \c{ES} for the store to \c{[DI]}
or \c{[EDI]} cannot be overridden.

\c{MOVSW} and \c{MOVSD} work in the same way, but they copy a word
or a doubleword instead of a byte, and increment or decrement the
addressing registers by 2 or 4 instead of 1.

The \c{REP} prefix may be used to repeat the instruction \c{CX} (or
\c{ECX} - again, the address size chooses which) times.

\H{insMOVSX} \i\c{MOVSX}, \i\c{MOVZX}: Move Data with Sign or Zero Extend

\c MOVSX reg16,r/m8              ; o16 0F BE /r         [386]
\c MOVSX reg32,r/m8              ; o32 0F BE /r         [386]
\c MOVSX reg32,r/m16             ; o32 0F BF /r         [386]

\c MOVZX reg16,r/m8              ; o16 0F B6 /r         [386]
\c MOVZX reg32,r/m8              ; o32 0F B6 /r         [386]
\c MOVZX reg32,r/m16             ; o32 0F B7 /r         [386]

\c{MOVSX} sign-extends its source (second) operand to the length of
its destination (first) operand, and copies the result into the
destination operand. \c{MOVZX} does the same, but zero-extends
rather than sign-extending.

\H{insMUL} \i\c{MUL}: Unsigned Integer Multiply

\c MUL r/m8                      ; F6 /4                [8086]
\c MUL r/m16                     ; o16 F7 /4            [8086]
\c MUL r/m32                     ; o32 F7 /4            [386]

\c{MUL} performs unsigned integer multiplication. The other operand
to the multiplication, and the destination operand, are implicit, in
the following way:

\b For \c{MUL r/m8}, \c{AL} is multiplied by the given operand; the
product is stored in \c{AX}.

\b For \c{MUL r/m16}, \c{AX} is multiplied by the given operand;
the product is stored in \c{DX:AX}.

\b For \c{MUL r/m32}, \c{EAX} is multiplied by the given operand;
the product is stored in \c{EDX:EAX}.

Signed integer multiplication is performed by the \c{IMUL}
instruction: see \k{insIMUL}.

\H{insNEG} \i\c{NEG}, \i\c{NOT}: Two's and One's Complement

\c NEG r/m8                      ; F6 /3                [8086]
\c NEG r/m16                     ; o16 F7 /3            [8086]
\c NEG r/m32                     ; o32 F7 /3            [386]

\c NOT r/m8                      ; F6 /2                [8086]
\c NOT r/m16                     ; o16 F7 /2            [8086]
\c NOT r/m32                     ; o32 F7 /2            [386]

\c{NEG} replaces the contents of its operand by the two's complement
negation (invert all the bits and then add one) of the original
value. \c{NOT}, similarly, performs one's complement (inverts all
the bits).

\H{insNOP} \i\c{NOP}: No Operation

\c NOP                           ; 90                   [8086]

\c{NOP} performs no operation. Its opcode is the same as that
generated by \c{XCHG AX,AX} or \c{XCHG EAX,EAX} (depending on the
processor mode; see \k{insXCHG}).

\H{insOR} \i\c{OR}: Bitwise OR

\c OR r/m8,reg8                  ; 08 /r                [8086]
\c OR r/m16,reg16                ; o16 09 /r            [8086]
\c OR r/m32,reg32                ; o32 09 /r            [386]

\c OR reg8,r/m8                  ; 0A /r                [8086]
\c OR reg16,r/m16                ; o16 0B /r            [8086]
\c OR reg32,r/m32                ; o32 0B /r            [386]

\c OR r/m8,imm8                  ; 80 /1 ib             [8086]
\c OR r/m16,imm16                ; o16 81 /1 iw         [8086]
\c OR r/m32,imm32                ; o32 81 /1 id         [386]

\c OR r/m16,imm8                 ; o16 83 /1 ib         [8086]
\c OR r/m32,imm8                 ; o32 83 /1 ib         [386]

\c OR AL,imm8                    ; 0C ib                [8086]
\c OR AX,imm16                   ; o16 0D iw            [8086]
\c OR EAX,imm32                  ; o32 0D id            [386]

\c{OR} performs a bitwise OR operation between its two operands
(i.e. each bit of the result is 1 if and only if at least one of the
corresponding bits of the two inputs was 1), and stores the result
in the destination (first) operand.

In the forms with an 8-bit immediate second operand and a longer
first operand, the second operand is considered to be signed, and is
sign-extended to the length of the first operand. In these cases,
the \c{BYTE} qualifier is necessary to force NASM to generate this
form of the instruction.

The MMX instruction \c{POR} (see \k{insPOR}) performs the same
operation on the 64-bit MMX registers.

\H{insOUT} \i\c{OUT}: Output Data to I/O Port

\c OUT imm8,AL                   ; E6 ib                [8086]
\c OUT imm8,AX                   ; o16 E7 ib            [8086]
\c OUT imm8,EAX                  ; o32 E7 ib            [386]
\c OUT DX,AL                     ; EE                   [8086]
\c OUT DX,AX                     ; o16 EF               [8086]
\c OUT DX,EAX                    ; o32 EF               [386]

\c{IN} writes the contents of the given source register to the
specified I/O port. The port number may be specified as an immediate
value if it is between 0 and 255, and otherwise must be stored in
\c{DX}. See also \c{IN} (\k{insIN}).

\H{insOUTSB} \i\c{OUTSB}, \i\c{OUTSW}, \i\c{OUTSD}: Output String to I/O Port

\c OUTSB                         ; 6E                   [186]

\c OUTSW                         ; o16 6F               [186]

\c OUTSD                         ; o32 6F               [386]

\c{OUTSB} loads a byte from \c{[DS:SI]} or \c{[DS:ESI]} and writes
it to the I/O port specified in \c{DX}. It then increments or
decrements (depending on the direction flag: increments if the flag
is clear, decrements if it is set) \c{SI} or \c{ESI}.

The register used is \c{SI} if the address size is 16 bits, and
\c{ESI} if it is 32 bits. If you need to use an address size not
equal to the current \c{BITS} setting, you can use an explicit
\i\c{a16} or \i\c{a32} prefix.

The segment register used to load from \c{[SI]} or \c{[ESI]} can be
overridden by using a segment register name as a prefix (for
example, \c{es outsb}).

\c{OUTSW} and \c{OUTSD} work in the same way, but they output a
word or a doubleword instead of a byte, and increment or decrement
the addressing registers by 2 or 4 instead of 1.

The \c{REP} prefix may be used to repeat the instruction \c{CX} (or
\c{ECX} - again, the address size chooses which) times.

\H{insPACKSSDW} \i\c{PACKSSDW}, \i\c{PACKSSWB}, \i\c{PACKUSWB}: Pack Data

\c PACKSSDW mmxreg,r/m64         ; 0F 6B /r             [PENT,MMX]
\c PACKSSWB mmxreg,r/m64         ; 0F 63 /r             [PENT,MMX]
\c PACKUSWB mmxreg,r/m64         ; 0F 67 /r             [PENT,MMX]

All these instructions start by forming a notional 128-bit word by
placing the source (second) operand on the left of the destination
(first) operand. \c{PACKSSDW} then splits this 128-bit word into
four doublewords, converts each to a word, and loads them side by
side into the destination register; \c{PACKSSWB} and \c{PACKUSWB}
both split the 128-bit word into eight words, converts each to a
byte, and loads \e{those} side by side into the destination
register.

\c{PACKSSDW} and \c{PACKSSWB} perform signed saturation when
reducing the length of numbers: if the number is too large to fit
into the reduced space, they replace it by the largest signed number
(\c{7FFFh} or \c{7Fh}) that \e{will} fit, and if it is too small
then they replace it by the smallest signed number (\c{8000h} or
\c{80h}) that will fit. \c{PACKUSWB} performs unsigned saturation:
it treats its input as unsigned, and replaces it by the largest
unsigned number that will fit.

\H{insPADDB} \i\c{PADDxx}: MMX Packed Addition

\c PADDB mmxreg,r/m64            ; 0F FC /r             [PENT,MMX]
\c PADDW mmxreg,r/m64            ; 0F FD /r             [PENT,MMX]
\c PADDD mmxreg,r/m64            ; 0F FE /r             [PENT,MMX]

\c PADDSB mmxreg,r/m64           ; 0F EC /r             [PENT,MMX]
\c PADDSW mmxreg,r/m64           ; 0F ED /r             [PENT,MMX]

\c PADDUSB mmxreg,r/m64          ; 0F DC /r             [PENT,MMX]
\c PADDUSW mmxreg,r/m64          ; 0F DD /r             [PENT,MMX]

\c{PADDxx} all perform packed addition between their two 64-bit
operands, storing the result in the destination (first) operand. The
\c{PADDxB} forms treat the 64-bit operands as vectors of eight
bytes, and add each byte individually; \c{PADDxW} treat the operands
as vectors of four words; and \c{PADDD} treats its operands as
vectors of two doublewords.

\c{PADDSB} and \c{PADDSW} perform signed saturation on the sum of
each pair of bytes or words: if the result of an addition is too
large or too small to fit into a signed byte or word result, it is
clipped (saturated) to the largest or smallest value which \e{will}
fit. \c{PADDUSB} and \c{PADDUSW} similarly perform unsigned
saturation, clipping to \c{0FFh} or \c{0FFFFh} if the result is
larger than that.

\H{insPADDSIW} \i\c{PADDSIW}: MMX Packed Addition to Implicit
Destination

\c PADDSIW mmxreg,r/m64          ; 0F 51 /r             [CYRIX,MMX]

\c{PADDSIW}, specific to the Cyrix extensions to the MMX instruction
set, performs the same function as \c{PADDSW}, except that the
result is not placed in the register specified by the first operand,
but instead in the register whose number differs from the first
operand only in the last bit. So \c{PADDSIW MM0,MM2} would put the
result in \c{MM1}, but \c{PADDSIW MM1,MM2} would put the result in
\c{MM0}.

\H{insPAND} \i\c{PAND}, \i\c{PANDN}: MMX Bitwise AND and AND-NOT

\c PAND mmxreg,r/m64             ; 0F DB /r             [PENT,MMX]
\c PANDN mmxreg,r/m64            ; 0F DF /r             [PENT,MMX]

\c{PAND} performs a bitwise AND operation between its two operands
(i.e. each bit of the result is 1 if and only if the corresponding
bits of the two inputs were both 1), and stores the result in the
destination (first) operand.

\c{PANDN} performs the same operation, but performs a one's
complement operation on the destination (first) operand first.

\H{insPAVEB} \i\c{PAVEB}: MMX Packed Average

\c PAVEB mmxreg,r/m64            ; 0F 50 /r             [CYRIX,MMX]

\c{PAVEB}, specific to the Cyrix MMX extensions, treats its two
operands as vectors of eight unsigned bytes, and calculates the
average of the corresponding bytes in the operands. The resulting
vector of eight averages is stored in the first operand.

\H{insPCMPEQB} \i\c{PCMPxx}: MMX Packed Comparison

\c PCMPEQB mmxreg,r/m64          ; 0F 74 /r             [PENT,MMX]
\c PCMPEQW mmxreg,r/m64          ; 0F 75 /r             [PENT,MMX]
\c PCMPEQD mmxreg,r/m64          ; 0F 76 /r             [PENT,MMX]

\c PCMPGTB mmxreg,r/m64          ; 0F 64 /r             [PENT,MMX]
\c PCMPGTW mmxreg,r/m64          ; 0F 65 /r             [PENT,MMX]
\c PCMPGTD mmxreg,r/m64          ; 0F 66 /r             [PENT,MMX]

The \c{PCMPxx} instructions all treat their operands as vectors of
bytes, words, or doublewords; corresponding elements of the source
and destination are compared, and the corresponding element of the
destination (first) operand is set to all zeros or all ones
depending on the result of the comparison.

\c{PCMPxxB} treats the operands as vectors of eight bytes,
\c{PCMPxxW} treats them as vectors of four words, and \c{PCMPxxD} as
two doublewords.

\c{PCMPEQx} sets the corresponding element of the destination
operand to all ones if the two elements compared are equal;
\c{PCMPGTx} sets the destination element to all ones if the element
of the first (destination) operand is greater (treated as a signed
integer) than that of the second (source) operand.

\H{insPDISTIB} \i\c{PDISTIB}: MMX Packed Distance and Accumulate
with Implied Register

\c PDISTIB mmxreg,mem64          ; 0F 54 /r             [CYRIX,MMX]

\c{PDISTIB}, specific to the Cyrix MMX extensions, treats its two
input operands as vectors of eight unsigned bytes. For each byte
position, it finds the absolute difference between the bytes in that
position in the two input operands, and adds that value to the byte
in the same position in the implied output register. The addition is
saturated to an unsigned byte in the same way as \c{PADDUSB}.

The implied output register is found in the same way as \c{PADDSIW}
(\k{insPADDSIW}).

Note that \c{PDISTIB} cannot take a register as its second source
operand.

\H{insPMACHRIW} \i\c{PMACHRIW}: MMX Packed Multiply and Accumulate
with Rounding

\c PMACHRIW mmxreg,mem64         ; 0F 5E /r             [CYRIX,MMX]

\c{PMACHRIW} acts almost identically to \c{PMULHRIW}
(\k{insPMULHRW}), but instead of \e{storing} its result in the
implied destination register, it \e{adds} its result, as four packed
words, to the implied destination register. No saturation is done:
the addition can wrap around.

Note that \c{PMACHRIW} cannot take a register as its second source
operand.

\H{insPMADDWD} \i\c{PMADDWD}: MMX Packed Multiply and Add

\c PMADDWD mmxreg,r/m64          ; 0F F5 /r             [PENT,MMX]

\c{PMADDWD} treats its two inputs as vectors of four signed words.
It multiplies corresponding elements of the two operands, giving
four signed doubleword results. The top two of these are added and
placed in the top 32 bits of the destination (first) operand; the
bottom two are added and placed in the bottom 32 bits.

\H{insPMAGW} \i\c{PMAGW}: MMX Packed Magnitude

\c PMAGW mmxreg,r/m64            ; 0F 52 /r             [CYRIX,MMX]

\c{PMAGW}, specific to the Cyrix MMX extensions, treats both its
operands as vectors of four signed words. It compares the absolute
values of the words in corresponding positions, and sets each word
of the destination (first) operand to whichever of the two words in
that position had the larger absolute value.

\H{insPMULHRW} \i\c{PMULHRW}, \i\c{PMULHRIW}: MMX Packed Multiply
High with Rounding

\c PMULHRW mmxreg,r/m64          ; 0F 59 /r             [CYRIX,MMX]
\c PMULHRIW mmxreg,r/m64         ; 0F 5D /r             [CYRIX,MMX]

These instructions, specific to the Cyrix MMX extensions, treat
their operands as vectors of four signed words. Words in
corresponding positions are multiplied, to give a 32-bit value in
which bits 30 and 31 are guaranteed equal. Bits 30 to 15 of this
value (bit mask \c{0x7FFF8000}) are taken and stored in the
corresponding position of the destination operand, after first
rounding the low bit (equivalent to adding \c{0x4000} before
extracting bits 30 to 15).

For \c{PMULHRW}, the destination operand is the first operand; for
\c{PMULHRIW} the destination operand is implied by the first operand
in the manner of \c{PADDSIW} (\k{insPADDSIW}).

\H{insPMULHW} \i\c{PMULHW}, \i\c{PMULLW}: MMX Packed Multiply

\c PMULHW mmxreg,r/m64           ; 0F E5 /r             [PENT,MMX]
\c PMULLW mmxreg,r/m64           ; 0F D5 /r             [PENT,MMX]

\c{PMULxW} treats its two inputs as vectors of four signed words. It
multiplies corresponding elements of the two operands, giving four
signed doubleword results.

\c{PMULHW} then stores the top 16 bits of each doubleword in the
destination (first) operand; \c{PMULLW} stores the bottom 16 bits of
each doubleword in the destination operand.

\H{insPMVccZB} \i\c{PMVccZB}: MMX Packed Conditional Move

\c PMVZB mmxreg,mem64            ; 0F 58 /r             [CYRIX,MMX]
\c PMVNZB mmxreg,mem64           ; 0F 5A /r             [CYRIX,MMX]
\c PMVLZB mmxreg,mem64           ; 0F 5B /r             [CYRIX,MMX]
\c PMVGEZB mmxreg,mem64          ; 0F 5C /r             [CYRIX,MMX]

These instructions, specific to the Cyrix MMX extensions, perform
parallel conditional moves. The two input operands are treated as
vectors of eight bytes. Each byte of the destination (first) operand
is either written from the corresponding byte of the source (second)
operand, or left alone, depending on the value of the byte in the
\e{implied} operand (specified in the same way as \c{PADDSIW}, in
\k{insPADDSIW}).

\c{PMVZB} performs each move if the corresponding byte in the
implied operand is zero. \c{PMVNZB} moves if the byte is non-zero.
\c{PMVLZB} moves if the byte is less than zero, and \c{PMVGEZB}
moves if the byte is greater than or equal to zero.

Note that these instructions cannot take a register as their second
source operand.

\H{insPOP} \i\c{POP}: Pop Data from Stack

\c POP reg16                     ; o16 58+r             [8086]
\c POP reg32                     ; o32 58+r             [386]

\c POP r/m16                     ; o16 8F /0            [8086]
\c POP r/m32                     ; o32 8F /0            [386]

\c POP CS                        ; 0F                   [8086,UNDOC]
\c POP DS                        ; 1F                   [8086]
\c POP ES                        ; 07                   [8086]
\c POP SS                        ; 17                   [8086]
\c POP FS                        ; 0F A1                [386]
\c POP GS                        ; 0F A9                [386]

\c{POP} loads a value from the stack (from \c{[SS:SP]} or
\c{[SS:ESP]}) and then increments the stack pointer.

The address-size attribute of the instruction determines whether
\c{SP} or \c{ESP} is used as the stack pointer: to deliberately
override the default given by the \c{BITS} setting, you can use an
\i\c{a16} or \i\c{a32} prefix.

The operand-size attribute of the instruction determines whether the
stack pointer is incremented by 2 or 4: this means that segment
register pops in \c{BITS 32} mode will pop 4 bytes off the stack and
discard the upper two of them. If you need to override that, you can
use an \i\c{o16} or \i\c{o32} prefix.

The above opcode listings give two forms for general-purpose
register pop instructions: for example, \c{POP BX} has the two forms
\c{5B} and \c{8F C3}. NASM will always generate the shorter form
when given \c{POP BX}. NDISASM will disassemble both.

\c{POP CS} is not a documented instruction, and is not supported on
any processor above the 8086 (since they use \c{0Fh} as an opcode
prefix for instruction set extensions). However, at least some 8086
processors do support it, and so NASM generates it for completeness.

\H{insPOPA} \i\c{POPAx}: Pop All General-Purpose Registers

\c POPA                          ; 61                   [186]
\c POPAW                         ; o16 61               [186]
\c POPAD                         ; o32 61               [386]

\c{POPAW} pops a word from the stack into each of, successively,
\c{DI}, \c{SI}, \c{BP}, nothing (it discards a word from the stack
which was a placeholder for \c{SP}), \c{BX}, \c{DX}, \c{CX} and
\c{AX}. It is intended to reverse the operation of \c{PUSHAW} (see
\k{insPUSHA}), but it ignores the value for \c{SP} that was pushed
on the stack by \c{PUSHAW}.

\c{POPAD} pops twice as much data, and places the results in
\c{EDI}, \c{ESI}, \c{EBP}, nothing (placeholder for \c{ESP}),
\c{EBX}, \c{EDX}, \c{ECX} and \c{EAX}. It reverses the operation of
\c{PUSHAD}.

\c{POPA} is an alias mnemonic for either \c{POPAW} or \c{POPAD},
depending on the current \c{BITS} setting.

Note that the registers are popped in reverse order of their numeric
values in opcodes (see \k{iref-rv}).

\H{insPOPF} \i\c{POPFx}: Pop Flags Register

\c POPF                          ; 9D                   [186]
\c POPFW                         ; o16 9D               [186]
\c POPFD                         ; o32 9D               [386]

\c{POPFW} pops a word from the stack and stores it in the bottom 16
bits of the flags register (or the whole flags register, on
processors below a 386). \c{POPFD} pops a doubleword and stores it
in the entire flags register.

\c{POPF} is an alias mnemonic for either \c{POPFW} or \c{POPFD},
depending on the current \c{BITS} setting.

See also \c{PUSHF} (\k{insPUSHF}).

\H{insPOR} \i\c{POR}: MMX Bitwise OR

\c POR mmxreg,r/m64              ; 0F EB /r             [PENT,MMX]

\c{POR} performs a bitwise OR operation between its two operands
(i.e. each bit of the result is 1 if and only if at least one of the
corresponding bits of the two inputs was 1), and stores the result
in the destination (first) operand.

\H{insPSLLD} \i\c{PSLLx}, \i\c{PSRLx}, \i\c{PSRAx}: MMX Bit Shifts

\c PSLLW mmxreg,r/m64            ; 0F F1 /r             [PENT,MMX]
\c PSLLW mmxreg,imm8             ; 0F 71 /6 ib          [PENT,MMX]

\c PSLLD mmxreg,r/m64            ; 0F F2 /r             [PENT,MMX]
\c PSLLD mmxreg,imm8             ; 0F 72 /6 ib          [PENT,MMX]

\c PSLLQ mmxreg,r/m64            ; 0F F3 /r             [PENT,MMX]
\c PSLLQ mmxreg,imm8             ; 0F 73 /6 ib          [PENT,MMX]

\c PSRAW mmxreg,r/m64            ; 0F E1 /r             [PENT,MMX]
\c PSRAW mmxreg,imm8             ; 0F 71 /4 ib          [PENT,MMX]

\c PSRAD mmxreg,r/m64            ; 0F E2 /r             [PENT,MMX]
\c PSRAD mmxreg,imm8             ; 0F 72 /4 ib          [PENT,MMX]

\c PSRLW mmxreg,r/m64            ; 0F D1 /r             [PENT,MMX]
\c PSRLW mmxreg,imm8             ; 0F 71 /2 ib          [PENT,MMX]

\c PSRLD mmxreg,r/m64            ; 0F D2 /r             [PENT,MMX]
\c PSRLD mmxreg,imm8             ; 0F 72 /2 ib          [PENT,MMX]

\c PSRLQ mmxreg,r/m64            ; 0F D3 /r             [PENT,MMX]
\c PSRLQ mmxreg,imm8             ; 0F 73 /2 ib          [PENT,MMX]

\c{PSxxQ} perform simple bit shifts on the 64-bit MMX registers: the
destination (first) operand is shifted left or right by the number of
bits given in the source (second) operand, and the vacated bits are
filled in with zeros (for a logical shift) or copies of the original
sign bit (for an arithmetic right shift).

\c{PSxxW} and \c{PSxxD} perform packed bit shifts: the destination
operand is treated as a vector of four words or two doublewords, and
each element is shifted individually, so bits shifted out of one
element do not interfere with empty bits coming into the next.

\c{PSLLx} and \c{PSRLx} perform logical shifts: the vacated bits at
one end of the shifted number are filled with zeros. \c{PSRAx}
performs an arithmetic right shift: the vacated bits at the top of
the shifted number are filled with copies of the original top (sign)
bit.

\H{insPSUBB} \i\c{PSUBxx}: MMX Packed Subtraction

\c PSUBB mmxreg,r/m64            ; 0F F8 /r             [PENT,MMX]
\c PSUBW mmxreg,r/m64            ; 0F F9 /r             [PENT,MMX]
\c PSUBD mmxreg,r/m64            ; 0F FA /r             [PENT,MMX]

\c PSUBSB mmxreg,r/m64           ; 0F E8 /r             [PENT,MMX]
\c PSUBSW mmxreg,r/m64           ; 0F E9 /r             [PENT,MMX]

\c PSUBUSB mmxreg,r/m64          ; 0F D8 /r             [PENT,MMX]
\c PSUBUSW mmxreg,r/m64          ; 0F D9 /r             [PENT,MMX]

\c{PSUBxx} all perform packed subtraction between their two 64-bit
operands, storing the result in the destination (first) operand. The
\c{PSUBxB} forms treat the 64-bit operands as vectors of eight
bytes, and subtract each byte individually; \c{PSUBxW} treat the operands
as vectors of four words; and \c{PSUBD} treats its operands as
vectors of two doublewords.

In all cases, the elements of the operand on the right are
subtracted from the corresponding elements of the operand on the
left, not the other way round.

\c{PSUBSB} and \c{PSUBSW} perform signed saturation on the sum of
each pair of bytes or words: if the result of a subtraction is too
large or too small to fit into a signed byte or word result, it is
clipped (saturated) to the largest or smallest value which \e{will}
fit. \c{PSUBUSB} and \c{PSUBUSW} similarly perform unsigned
saturation, clipping to \c{0FFh} or \c{0FFFFh} if the result is
larger than that.

\H{insPSUBSIW} \i\c{PSUBSIW}: MMX Packed Subtract with Saturation to
Implied Destination

\c PSUBSIW mmxreg,r/m64          ; 0F 55 /r             [CYRIX,MMX]

\c{PSUBSIW}, specific to the Cyrix extensions to the MMX instruction
set, performs the same function as \c{PSUBSW}, except that the
result is not placed in the register specified by the first operand,
but instead in the implied destination register, specified as for
\c{PADDSIW} (\k{insPADDSIW}).

\H{insPUNPCKHBW} \i\c{PUNPCKxxx}: Unpack Data

\c PUNPCKHBW mmxreg,r/m64        ; 0F 68 /r             [PENT,MMX]
\c PUNPCKHWD mmxreg,r/m64        ; 0F 69 /r             [PENT,MMX]
\c PUNPCKHDQ mmxreg,r/m64        ; 0F 6A /r             [PENT,MMX]

\c PUNPCKLBW mmxreg,r/m64        ; 0F 60 /r             [PENT,MMX]
\c PUNPCKLWD mmxreg,r/m64        ; 0F 61 /r             [PENT,MMX]
\c PUNPCKLDQ mmxreg,r/m64        ; 0F 62 /r             [PENT,MMX]

\c{PUNPCKxx} all treat their operands as vectors, and produce a new
vector generated by interleaving elements from the two inputs. The
\c{PUNPCKHxx} instructions start by throwing away the bottom half of
each input operand, and the \c{PUNPCKLxx} instructions throw away
the top half.

The remaining elements, totalling 64 bits, are then interleaved into
the destination, alternating elements from the second (source)
operand and the first (destination) operand: so the leftmost element
in the result always comes from the second operand, and the
rightmost from the destination.

\c{PUNPCKxBW} works a byte at a time, \c{PUNPCKxWD} a word at a
time, and \c{PUNPCKxDQ} a doubleword at a time.

So, for example, if the first operand held \c{0x7A6A5A4A3A2A1A0A}
and the second held \c{0x7B6B5B4B3B2B1B0B}, then:

\b \c{PUNPCKHBW} would return \c{0x7B7A6B6A5B5A4B4A}.

\b \c{PUNPCKHWD} would return \c{0x7B6B7A6A5B4B5A4A}.

\b \c{PUNPCKHDQ} would return \c{0x7B6B5B4B7A6A5A4A}.

\b \c{PUNPCKLBW} would return \c{0x3B3A2B2A1B1A0B0A}.

\b \c{PUNPCKLWD} would return \c{0x3B2B3A2A1B0B1A0A}.

\b \c{PUNPCKLDQ} would return \c{0x3B2B1B0B3A2A1A0A}.

\H{insPUSH} \i\c{PUSH}: Push Data on Stack

\c PUSH reg16                    ; o16 50+r             [8086]
\c PUSH reg32                    ; o32 50+r             [386]

\c PUSH r/m16                    ; o16 FF /6            [8086]
\c PUSH r/m32                    ; o32 FF /6            [386]

\c PUSH CS                       ; 0E                   [8086]
\c PUSH DS                       ; 1E                   [8086]
\c PUSH ES                       ; 06                   [8086]
\c PUSH SS                       ; 16                   [8086]
\c PUSH FS                       ; 0F A0                [386]
\c PUSH GS                       ; 0F A8                [386]

\c PUSH imm8                     ; 6A ib                [286]
\c PUSH imm16                    ; o16 68 iw            [286]
\c PUSH imm32                    ; o32    id            [386]

\c{PUSH} decrements the stack pointer (\c{SP} or \c{ESP}) by 2 or 4,
and then stores the given value at \c{[SS:SP]} or \c{[SS:ESP]}.

The address-size attribute of the instruction determines whether
\c{SP} or \c{ESP} is used as the stack pointer: to deliberately
override the default given by the \c{BITS} setting, you can use an
\i\c{a16} or \i\c{a32} prefix.

The operand-size attribute of the instruction determines whether the
stack pointer is decremented by 2 or 4: this means that segment
register pushes in \c{BITS 32} mode will push 4 bytes on the stack,
of which the upper two are undefined. If you need to override that,
you can use an \i\c{o16} or \i\c{o32} prefix.

The above opcode listings give two forms for general-purpose
\i{register push} instructions: for example, \c{PUSH BX} has the two
forms \c{53} and \c{FF F3}. NASM will always generate the shorter
form when given \c{PUSH BX}. NDISASM will disassemble both.

Unlike the undocumented and barely supported \c{POP CS}, \c{PUSH CS}
is a perfectly valid and sensible instruction, supported on all
processors.

The instruction \c{PUSH SP} may be used to distinguish an 8086 from
later processors: on an 8086, the value of \c{SP} stored is the
value it has \e{after} the push instruction, whereas on later
processors it is the value \e{before} the push instruction.

\H{insPUSHA} \i\c{PUSHAx}: Push All General-Purpose Registers

\c PUSHA                         ; 60                   [186]
\c PUSHAD                        ; o32 60               [386]
\c PUSHAW                        ; o16 60               [186]

\c{PUSHAW} pushes, in succession, \c{AX}, \c{CX}, \c{DX}, \c{BX},
\c{SP}, \c{BP}, \c{SI} and \c{DI} on the stack, decrementing the
stack pointer by a total of 16.

\c{PUSHAD} pushes, in succession, \c{EAX}, \c{ECX}, \c{EDX},
\c{EBX}, \c{ESP}, \c{EBP}, \c{ESI} and \c{EDI} on the stack,
decrementing the stack pointer by a total of 32.

In both cases, the value of \c{SP} or \c{ESP} pushed is its
\e{original} value, as it had before the instruction was executed.

\c{PUSHA} is an alias mnemonic for either \c{PUSHAW} or \c{PUSHAD},
depending on the current \c{BITS} setting.

Note that the registers are pushed in order of their numeric values
in opcodes (see \k{iref-rv}).

See also \c{POPA} (\k{insPOPA}).

\H{insPUSHF} \i\c{PUSHFx}: Push Flags Register

\c PUSHF                         ; 9C                   [186]
\c PUSHFD                        ; o32 9C               [386]
\c PUSHFW                        ; o16 9C               [186]

\c{PUSHFW} pops a word from the stack and stores it in the bottom 16
bits of the flags register (or the whole flags register, on
processors below a 386). \c{PUSHFD} pops a doubleword and stores it
in the entire flags register.

\c{PUSHF} is an alias mnemonic for either \c{PUSHFW} or \c{PUSHFD},
depending on the current \c{BITS} setting.

See also \c{POPF} (\k{insPOPF}).

\H{insPXOR} \i\c{PXOR}: MMX Bitwise XOR

\c PXOR mmxreg,r/m64             ; 0F EF /r             [PENT,MMX]

\c{PXOR} performs a bitwise XOR operation between its two operands
(i.e. each bit of the result is 1 if and only if exactly one of the
corresponding bits of the two inputs was 1), and stores the result
in the destination (first) operand.

\H{insRCL} \i\c{RCL}, \i\c{RCR}: Bitwise Rotate through Carry Bit

\c RCL r/m8,1                    ; D0 /2                [8086]
\c RCL r/m8,CL                   ; D2 /2                [8086]
\c RCL r/m8,imm8                 ; C0 /2 ib             [286]
\c RCL r/m16,1                   ; o16 D1 /2            [8086]
\c RCL r/m16,CL                  ; o16 D3 /2            [8086]
\c RCL r/m16,imm8                ; o16 C1 /2 ib         [286]
\c RCL r/m32,1                   ; o32 D1 /2            [386]
\c RCL r/m32,CL                  ; o32 D3 /2            [386]
\c RCL r/m32,imm8                ; o32 C1 /2 ib         [386]

\c RCR r/m8,1                    ; D0 /3                [8086]
\c RCR r/m8,CL                   ; D2 /3                [8086]
\c RCR r/m8,imm8                 ; C0 /3 ib             [286]
\c RCR r/m16,1                   ; o16 D1 /3            [8086]
\c RCR r/m16,CL                  ; o16 D3 /3            [8086]
\c RCR r/m16,imm8                ; o16 C1 /3 ib         [286]
\c RCR r/m32,1                   ; o32 D1 /3            [386]
\c RCR r/m32,CL                  ; o32 D3 /3            [386]
\c RCR r/m32,imm8                ; o32 C1 /3 ib         [386]

\c{RCL} and \c{RCR} perform a 9-bit, 17-bit or 33-bit bitwise
rotation operation, involving the given source/destination (first)
operand and the carry bit. Thus, for example, in the operation
\c{RCR AL,1}, a 9-bit rotation is performed in which \c{AL} is
shifted left by 1, the top bit of \c{AL} moves into the carry flag,
and the original value of the carry flag is placed in the low bit of
\c{AL}.

The number of bits to rotate by is given by the second operand. Only
the bottom five bits of the rotation count are considered by
processors above the 8086.

You can force the longer (286 and upwards, beginning with a \c{C1}
byte) form of \c{RCL foo,1} by using a \c{BYTE} prefix: \c{RCL
foo,BYTE 1}. Similarly with \c{RCR}.

\H{insRDMSR} \i\c{RDMSR}: Read Model-Specific Registers

\c RDMSR                         ; 0F 32                [PENT]

\c{RDMSR} reads the processor Model-Specific Register (MSR) whose
index is stored in \c{ECX}, and stores the result in \c{EDX:EAX}.
See also \c{WRMSR} (\k{insWRMSR}).

\H{insRDPMC} \i\c{RDPMC}: Read Performance-Monitoring Counters

\c RDPMC                         ; 0F 33                [P6]

\c{RDPMC} reads the processor performance-monitoring counter whose
index is stored in \c{ECX}, and stores the result in \c{EDX:EAX}.

\H{insRDTSC} \i\c{RDTSC}: Read Time-Stamp Counter

\c RDTSC                         ; 0F 31                [PENT]

\c{RDTSC} reads the processor's time-stamp counter into \c{EDX:EAX}.

\H{insRET} \i\c{RET}, \i\c{RETF}, \i\c{RETN}: Return from Procedure Call

\c RET                           ; C3                   [8086]
\c RET imm16                     ; C2 iw                [8086]

\c RETF                          ; CB                   [8086]
\c RETF imm16                    ; CA iw                [8086]

\c RETN                          ; C3                   [8086]
\c RETN imm16                    ; C2 iw                [8086]

\c{RET}, and its exact synonym \c{RETN}, pop \c{IP} or \c{EIP} from
the stack and transfer control to the new address. Optionally, if a
numeric second operand is provided, they increment the stack pointer
by a further \c{imm16} bytes after popping the return address.

\c{RETF} executes a far return: after popping \c{IP}/\c{EIP}, it
then pops \c{CS}, and \e{then} increments the stack pointer by the
optional argument if present.

\H{insROL} \i\c{ROL}, \i\c{ROR}: Bitwise Rotate

\c ROL r/m8,1                    ; D0 /0                [8086]
\c ROL r/m8,CL                   ; D2 /0                [8086]
\c ROL r/m8,imm8                 ; C0 /0 ib             [286]
\c ROL r/m16,1                   ; o16 D1 /0            [8086]
\c ROL r/m16,CL                  ; o16 D3 /0            [8086]
\c ROL r/m16,imm8                ; o16 C1 /0 ib         [286]
\c ROL r/m32,1                   ; o32 D1 /0            [386]
\c ROL r/m32,CL                  ; o32 D3 /0            [386]
\c ROL r/m32,imm8                ; o32 C1 /0 ib         [386]

\c ROR r/m8,1                    ; D0 /1                [8086]
\c ROR r/m8,CL                   ; D2 /1                [8086]
\c ROR r/m8,imm8                 ; C0 /1 ib             [286]
\c ROR r/m16,1                   ; o16 D1 /1            [8086]
\c ROR r/m16,CL                  ; o16 D3 /1            [8086]
\c ROR r/m16,imm8                ; o16 C1 /1 ib         [286]
\c ROR r/m32,1                   ; o32 D1 /1            [386]
\c ROR r/m32,CL                  ; o32 D3 /1            [386]
\c ROR r/m32,imm8                ; o32 C1 /1 ib         [386]

\c{ROL} and \c{ROR} perform a bitwise rotation operation on the given
source/destination (first) operand. Thus, for example, in the
operation \c{ROR AL,1}, an 8-bit rotation is performed in which
\c{AL} is shifted left by 1 and the original top bit of \c{AL} moves
round into the low bit.

The number of bits to rotate by is given by the second operand. Only
the bottom 3, 4 or 5 bits (depending on the source operand size) of
the rotation count are considered by processors above the 8086.

You can force the longer (286 and upwards, beginning with a \c{C1}
byte) form of \c{ROL foo,1} by using a \c{BYTE} prefix: \c{ROL
foo,BYTE 1}. Similarly with \c{ROR}.

\H{insRSM} \i\c{RSM}: Resume from System-Management Mode

\c RSM                           ; 0F AA                [PENT]

\c{RSM} returns the processor to its normal operating mode when it
was in System-Management Mode.

\H{insSAHF} \i\c{SAHF}: Store AH to Flags

\c SAHF                          ; 9E                   [8086]

\c{SAHF} sets the low byte of the flags word according to the
contents of the \c{AH} register. See also \c{LAHF} (\k{insLAHF}).

\H{insSAL} \i\c{SAL}, \i\c{SAR}: Bitwise Arithmetic Shifts

\c SAL r/m8,1                    ; D0 /4                [8086]
\c SAL r/m8,CL                   ; D2 /4                [8086]
\c SAL r/m8,imm8                 ; C0 /4 ib             [286]
\c SAL r/m16,1                   ; o16 D1 /4            [8086]
\c SAL r/m16,CL                  ; o16 D3 /4            [8086]
\c SAL r/m16,imm8                ; o16 C1 /4 ib         [286]
\c SAL r/m32,1                   ; o32 D1 /4            [386]
\c SAL r/m32,CL                  ; o32 D3 /4            [386]
\c SAL r/m32,imm8                ; o32 C1 /4 ib         [386]

\c SAR r/m8,1                    ; D0 /0                [8086]
\c SAR r/m8,CL                   ; D2 /0                [8086]
\c SAR r/m8,imm8                 ; C0 /0 ib             [286]
\c SAR r/m16,1                   ; o16 D1 /0            [8086]
\c SAR r/m16,CL                  ; o16 D3 /0            [8086]
\c SAR r/m16,imm8                ; o16 C1 /0 ib         [286]
\c SAR r/m32,1                   ; o32 D1 /0            [386]
\c SAR r/m32,CL                  ; o32 D3 /0            [386]
\c SAR r/m32,imm8                ; o32 C1 /0 ib         [386]

\c{SAL} and \c{SAR} perform an arithmetic shift operation on the given
source/destination (first) operand. The vacated bits are filled with
zero for \c{SAL}, and with copies of the original high bit of the
source operand for \c{SAR}.

\c{SAL} is a synonym for \c{SHL} (see \k{insSHL}). NASM will
assemble either one to the same code, but NDISASM will always
disassemble that code as \c{SHL}.

The number of bits to shift by is given by the second operand. Only
the bottom 3, 4 or 5 bits (depending on the source operand size) of
the shift count are considered by processors above the 8086.

You can force the longer (286 and upwards, beginning with a \c{C1}
byte) form of \c{SAL foo,1} by using a \c{BYTE} prefix: \c{SAL
foo,BYTE 1}. Similarly with \c{SAR}.

\H{insSALC} \i\c{SALC}: Set AL from Carry Flag

\c SALC                          ; D6                   [8086,UNDOC]

\c{SALC} is an early undocumented instruction similar in concept to
\c{SETcc} (\k{insSETcc}). Its function is to set \c{AL} to zero if
the carry flag is clear, or to \c{0xFF} if it is set.

\H{insSBB} \i\c{SBB}: Subtract with Borrow

\c SBB r/m8,reg8                 ; 18 /r                [8086]
\c SBB r/m16,reg16               ; o16 19 /r            [8086]
\c SBB r/m32,reg32               ; o32 19 /r            [386]

\c SBB reg8,r/m8                 ; 1A /r                [8086]
\c SBB reg16,r/m16               ; o16 1B /r            [8086]
\c SBB reg32,r/m32               ; o32 1B /r            [386]

\c SBB r/m8,imm8                 ; 80 /3 ib             [8086]
\c SBB r/m16,imm16               ; o16 81 /3 iw         [8086]
\c SBB r/m32,imm32               ; o32 81 /3 id         [386]

\c SBB r/m16,imm8                ; o16 83 /3 ib         [8086]
\c SBB r/m32,imm8                ; o32 83 /3 ib         [8086]

\c SBB AL,imm8                   ; 1C ib                [8086]
\c SBB AX,imm16                  ; o16 1D iw            [8086]
\c SBB EAX,imm32                 ; o32 1D id            [386]

\c{SBB} performs integer subtraction: it subtracts its second
operand, plus the value of the carry flag, from its first, and
leaves the result in its destination (first) operand. The flags are
set according to the result of the operation: in particular, the
carry flag is affected and can be used by a subsequent \c{SBB}
instruction.

In the forms with an 8-bit immediate second operand and a longer
first operand, the second operand is considered to be signed, and is
sign-extended to the length of the first operand. In these cases,
the \c{BYTE} qualifier is necessary to force NASM to generate this
form of the instruction.

To subtract one number from another without also subtracting the
contents of the carry flag, use \c{SUB} (\k{insSUB}).

\H{insSCASB} \i\c{SCASB}, \i\c{SCASW}, \i\c{SCASD}: Scan String

\c SCASB                         ; AE                   [8086]
\c SCASW                         ; o16 AF               [8086]
\c SCASD                         ; o32 AF               [386]

\c{SCASB} compares the byte in \c{AL} with the byte at \c{[ES:DI]}
or \c{[ES:EDI]}, and sets the flags accordingly. It then increments
or decrements (depending on the direction flag: increments if the
flag is clear, decrements if it is set) \c{DI} (or \c{EDI}).

The register used is \c{DI} if the address size is 16 bits, and
\c{EDI} if it is 32 bits. If you need to use an address size not
equal to the current \c{BITS} setting, you can use an explicit
\i\c{a16} or \i\c{a32} prefix.

Segment override prefixes have no effect for this instruction: the
use of \c{ES} for the load from \c{[DI]} or \c{[EDI]} cannot be
overridden.

\c{SCASW} and \c{SCASD} work in the same way, but they compare a
word to \c{AX} or a doubleword to \c{EAX} instead of a byte to
\c{AL}, and increment or decrement the addressing registers by 2 or
4 instead of 1.

The \c{REPE} and \c{REPNE} prefixes (equivalently, \c{REPZ} and
\c{REPNZ}) may be used to repeat the instruction up to \c{CX} (or
\c{ECX} - again, the address size chooses which) times until the
first unequal or equal byte is found.

\H{insSETcc} \i\c{SETcc}: Set Register from Condition

\c SETcc r/m8                    ; 0F 90+cc /2          [386]

\c{SETcc} sets the given 8-bit operand to zero if its condition is
not satisfied, and to 1 if it is.

\H{insSGDT} \i\c{SGDT}, \i\c{SIDT}, \i\c{SLDT}: Store Descriptor Table Pointers

\c SGDT mem                      ; 0F 01 /0             [286,PRIV]
\c SIDT mem                      ; 0F 01 /1             [286,PRIV]
\c SLDT r/m16                    ; 0F 00 /0             [286,PRIV]

\c{SGDT} and \c{SIDT} both take a 6-byte memory area as an operand:
they store the contents of the GDTR (global descriptor table
register) or IDTR (interrupt descriptor table register) into that
area as a 32-bit linear address and a 16-bit size limit from that
area (in that order). These are the only instructions which directly
use \e{linear} addresses, rather than segment/offset pairs.

\c{SLDT} stores the segment selector corresponding to the LDT (local
descriptor table) into the given operand.

See also \c{LGDT}, \c{LIDT} and \c{LLDT} (\k{insLGDT}).

\H{insSHL} \i\c{SHL}, \i\c{SHR}: Bitwise Logical Shifts

\c SHL r/m8,1                    ; D0 /4                [8086]
\c SHL r/m8,CL                   ; D2 /4                [8086]
\c SHL r/m8,imm8                 ; C0 /4 ib             [286]
\c SHL r/m16,1                   ; o16 D1 /4            [8086]
\c SHL r/m16,CL                  ; o16 D3 /4            [8086]
\c SHL r/m16,imm8                ; o16 C1 /4 ib         [286]
\c SHL r/m32,1                   ; o32 D1 /4            [386]
\c SHL r/m32,CL                  ; o32 D3 /4            [386]
\c SHL r/m32,imm8                ; o32 C1 /4 ib         [386]

\c SHR r/m8,1                    ; D0 /5                [8086]
\c SHR r/m8,CL                   ; D2 /5                [8086]
\c SHR r/m8,imm8                 ; C0 /5 ib             [286]
\c SHR r/m16,1                   ; o16 D1 /5            [8086]
\c SHR r/m16,CL                  ; o16 D3 /5            [8086]
\c SHR r/m16,imm8                ; o16 C1 /5 ib         [286]
\c SHR r/m32,1                   ; o32 D1 /5            [386]
\c SHR r/m32,CL                  ; o32 D3 /5            [386]
\c SHR r/m32,imm8                ; o32 C1 /5 ib         [386]

\c{SHL} and \c{SHR} perform a logical shift operation on the given
source/destination (first) operand. The vacated bits are filled with
zero.

A synonym for \c{SHL} is \c{SAL} (see \k{insSAL}). NASM will
assemble either one to the same code, but NDISASM will always
disassemble that code as \c{SHL}.

The number of bits to shift by is given by the second operand. Only
the bottom 3, 4 or 5 bits (depending on the source operand size) of
the shift count are considered by processors above the 8086.

You can force the longer (286 and upwards, beginning with a \c{C1}
byte) form of \c{SHL foo,1} by using a \c{BYTE} prefix: \c{SHL
foo,BYTE 1}. Similarly with \c{SHR}.

\H{insSHLD} \i\c{SHLD}, \i\c{SHRD}: Bitwise Double-Precision Shifts

\c SHLD r/m16,reg16,imm8         ; o16 0F A4 /r ib      [386]
\c SHLD r/m16,reg32,imm8         ; o32 0F A4 /r ib      [386]
\c SHLD r/m16,reg16,CL           ; o16 0F A5 /r         [386]
\c SHLD r/m16,reg32,CL           ; o32 0F A5 /r         [386]

\c SHRD r/m16,reg16,imm8         ; o16 0F AC /r ib      [386]
\c SHRD r/m32,reg32,imm8         ; o32 0F AC /r ib      [386]
\c SHRD r/m16,reg16,CL           ; o16 0F AD /r         [386]
\c SHRD r/m32,reg32,CL           ; o32 0F AD /r         [386]

\c{SHLD} performs a double-precision left shift. It notionally places
its second operand to the right of its first, then shifts the entire
bit string thus generated to the left by a number of bits specified
in the third operand. It then updates only the \e{first} operand
according to the result of this. The second operand is not modified.

\c{SHRD} performs the corresponding right shift: it notionally
places the second operand to the \e{left} of the first, shifts the
whole bit string right, and updates only the first operand.

For example, if \c{EAX} holds \c{0x01234567} and \c{EBX} holds
\c{0x89ABCDEF}, then the instruction \c{SHLD EAX,EBX,4} would update
\c{EAX} to hold \c{0x12345678}. Under the same conditions, \c{SHRD
EAX,EBX,4} would update \c{EAX} to hold \c{0xF0123456}.

The number of bits to shift by is given by the third operand. Only
the bottom 5 bits of the shift count are considered.

\H{insSMI} \i\c{SMI}: System Management Interrupt

\c SMI                           ; F1                   [386,UNDOC]

This is an opcode apparently supported by some AMD processors (which
is why it can generate the same opcode as \c{INT1}), and places the
machine into system-management mode, a special debugging mode.

\H{insSMSW} \i\c{SMSW}: Store Machine Status Word

\c SMSW r/m16                    ; 0F 01 /4             [286,PRIV]

\c{SMSW} stores the bottom half of the \c{CR0} control register (or
the Machine Status Word, on 286 processors) into the destination
operand. See also \c{LMSW} (\k{insLMSW}).

\H{insSTC} \i\c{STC}, \i\c{STD}, \i\c{STI}: Set Flags

\c STC                           ; F9                   [8086]
\c STD                           ; FD                   [8086]
\c STI                           ; FB                   [8086]

These instructions set various flags. \c{STC} sets the carry flag;
\c{STD} sets the direction flag; and \c{STI} sets the interrupt flag
(thus enabling interrupts).

To clear the carry, direction, or interrupt flags, use the \c{CLC},
\c{CLD} and \c{CLI} instructions (\k{insCLC}). To invert the carry
flag, use \c{CMC} (\k{insCMC}).

\H{insSTOSB} \i\c{STOSB}, \i\c{STOSW}, \i\c{STOSD}: Store Byte to String

\c STOSB                         ; AA                   [8086]
\c STOSW                         ; o16 AB               [8086]
\c STOSD                         ; o32 AB               [386]

\c{STOSB} stores the byte in \c{AL} at \c{[ES:DI]} or \c{[ES:EDI]},
and sets the flags accordingly. It then increments or decrements
(depending on the direction flag: increments if the flag is clear,
decrements if it is set) \c{DI} (or \c{EDI}).

The register used is \c{DI} if the address size is 16 bits, and
\c{EDI} if it is 32 bits. If you need to use an address size not
equal to the current \c{BITS} setting, you can use an explicit
\i\c{a16} or \i\c{a32} prefix.

Segment override prefixes have no effect for this instruction: the
use of \c{ES} for the store to \c{[DI]} or \c{[EDI]} cannot be
overridden.

\c{STOSW} and \c{STOSD} work in the same way, but they store the
word in \c{AX} or the doubleword in \c{EAX} instead of the byte in
\c{AL}, and increment or decrement the addressing registers by 2 or
4 instead of 1.

The \c{REP} prefix may be used to repeat the instruction \c{CX} (or
\c{ECX} - again, the address size chooses which) times.

\H{insSTR} \i\c{STR}: Store Task Register

\c STR r/m16                     ; 0F 00 /1             [286,PRIV]

\c{STR} stores the segment selector corresponding to the contents of
the Task Register into its operand.

\H{insSUB} \i\c{SUB}: Subtract Integers

\c SUB r/m8,reg8                 ; 28 /r                [8086]
\c SUB r/m16,reg16               ; o16 29 /r            [8086]
\c SUB r/m32,reg32               ; o32 29 /r            [386]

\c SUB reg8,r/m8                 ; 2A /r                [8086]
\c SUB reg16,r/m16               ; o16 2B /r            [8086]
\c SUB reg32,r/m32               ; o32 2B /r            [386]

\c SUB r/m8,imm8                 ; 80 /5 ib             [8086]
\c SUB r/m16,imm16               ; o16 81 /5 iw         [8086]
\c SUB r/m32,imm32               ; o32 81 /5 id         [386]

\c SUB r/m16,imm8                ; o16 83 /5 ib         [8086]
\c SUB r/m32,imm8                ; o32 83 /5 ib         [386]

\c SUB AL,imm8                   ; 2C ib                [8086]
\c SUB AX,imm16                  ; o16 2D iw            [8086]
\c SUB EAX,imm32                 ; o32 2D id            [386]

\c{SUB} performs integer subtraction: it subtracts its second
operand from its first, and leaves the result in its destination
(first) operand. The flags are set according to the result of the
operation: in particular, the carry flag is affected and can be used
by a subsequent \c{SBB} instruction (\k{insSBB}).

In the forms with an 8-bit immediate second operand and a longer
first operand, the second operand is considered to be signed, and is
sign-extended to the length of the first operand. In these cases,
the \c{BYTE} qualifier is necessary to force NASM to generate this
form of the instruction.

\H{insTEST} \i\c{TEST}: Test Bits (notional bitwise AND)

\c TEST r/m8,reg8                ; 84 /r                [8086]
\c TEST r/m16,reg16              ; o16 85 /r            [8086]
\c TEST r/m32,reg32              ; o32 85 /r            [386]

\c TEST r/m8,imm8                ; F6 /7 ib             [8086]
\c TEST r/m16,imm16              ; o16 F7 /7 iw         [8086]
\c TEST r/m32,imm32              ; o32 F7 /7 id         [386]

\c TEST AL,imm8                  ; A8 ib                [8086]
\c TEST AX,imm16                 ; o16 A9 iw            [8086]
\c TEST EAX,imm32                ; o32 A9 id            [386]

\c{TEST} performs a `mental' bitwise AND of its two operands, and
affects the flags as if the operation had taken place, but does not
store the result of the operation anywhere.

\H{insUMOV} \i\c{UMOV}: User Move Data

\c UMOV r/m8,reg8                ; 0F 10 /r             [386,UNDOC]
\c UMOV r/m16,reg16              ; o16 0F 11 /r         [386,UNDOC]
\c UMOV r/m32,reg32              ; o32 0F 11 /r         [386,UNDOC]

\c UMOV reg8,r/m8                ; 0F 12 /r             [386,UNDOC]
\c UMOV reg16,r/m16              ; o16 0F 13 /r         [386,UNDOC]
\c UMOV reg32,r/m32              ; o32 0F 13 /r         [386,UNDOC]

This undocumented instruction is used by in-circuit emulators to
access user memory (as opposed to host memory). It is used just like
an ordinary memory/register or register/register \c{MOV}
instruction, but accesses user space.

\H{insVERR} \i\c{VERR}, \i\c{VERW}: Verify Segment Readability/Writability

\c VERR r/m16                    ; 0F 00 /4             [286,PRIV]

\c VERW r/m16                    ; 0F 00 /5             [286,PRIV]

\c{VERR} sets the zero flag if the segment specified by the selector
in its operand can be read from at the current privilege level.
\c{VERW} sets the zero flag if the segment can be written.

\H{insWAIT} \i\c{WAIT}: Wait for Floating-Point Processor

\c WAIT                          ; 9B                   [8086]

\c{WAIT}, on 8086 systems with a separate 8087 FPU, waits for the
FPU to have finished any operation it is engaged in before
continuing main processor operations, so that (for example) an FPU
store to main memory can be guaranteed to have completed before the
CPU tries to read the result back out.

On higher processors, \c{WAIT} is unnecessary for this purpose, and
it has the alternative purpose of ensuring that any pending unmasked
FPU exceptions have happened before execution continues.

\H{insWBINVD} \i\c{WBINVD}: Write Back and Invalidate Cache

\c WBINVD                        ; 0F 09                [486]

\c{WBINVD} invalidates and empties the processor's internal caches,
and causes the processor to instruct external caches to do the same.
It writes the contents of the caches back to memory first, so no
data is lost. To flush the caches quickly without bothering to write
the data back first, use \c{INVD} (\k{insINVD}).

\H{insWRMSR} \i\c{WRMSR}: Write Model-Specific Registers

\c WRMSR                         ; 0F 30                [PENT]

\c{WRMSR} writes the value in \c{EDX:EAX} to the processor
Model-Specific Register (MSR) whose index is stored in \c{ECX}. See
also \c{RDMSR} (\k{insRDMSR}).

\H{insXADD} \i\c{XADD}: Exchange and Add

\c XADD r/m8,reg8                ; 0F C0 /r             [486]
\c XADD r/m16,reg16              ; o16 0F C1 /r         [486]
\c XADD r/m32,reg32              ; o32 0F C1 /r         [486]

\c{XADD} exchanges the values in its two operands, and then adds
them together and writes the result into the destination (first)
operand. This instruction can be used with a \c{LOCK} prefix for
multi-processor synchronisation purposes.

\H{insXBTS} \i\c{XBTS}: Extract Bit String

\c XBTS reg16,r/m16              ; o16 0F A6 /r         [386,UNDOC]
\c XBTS reg32,r/m32              ; o32 0F A6 /r         [386,UNDOC]

No clear documentation seems to be available for this instruction:
the best I've been able to find reads `Takes a string of bits from
the first operand and puts them in the second operand'. It is
present only in early 386 processors, and conflicts with the opcodes
for \c{CMPXCHG486}. NASM supports it only for completeness. Its
counterpart is \c{IBTS} (see \k{insIBTS}).

\H{insXCHG} \i\c{XCHG}: Exchange

\c XCHG reg8,r/m8                ; 86 /r                [8086]
\c XCHG reg16,r/m8               ; o16 87 /r            [8086]
\c XCHG reg32,r/m32              ; o32 87 /r            [386]

\c XCHG r/m8,reg8                ; 86 /r                [8086]
\c XCHG r/m16,reg16              ; o16 87 /r            [8086]
\c XCHG r/m32,reg32              ; o32 87 /r            [386]

\c XCHG AX,reg16                 ; o16 90+r             [8086]
\c XCHG EAX,reg32                ; o32 90+r             [386]
\c XCHG reg16,AX                 ; o16 90+r             [8086]
\c XCHG reg32,EAX                ; o32 90+r             [386]

\c{XCHG} exchanges the values in its two operands. It can be used
with a \c{LOCK} prefix for purposes of multi-processor
synchronisation.

\c{XCHG AX,AX} or \c{XCHG EAX,EAX} (depending on the \c{BITS}
setting) generates the opcode \c{90h}, and so is a synonym for
\c{NOP} (\k{insNOP}).

\H{insXLATB} \i\c{XLATB}: Translate Byte in Lookup Table

\c XLATB                         ; D7                   [8086]

\c{XLATB} adds the value in \c{AL}, treated as an unsigned byte, to
\c{BX} or \c{EBX}, and loads the byte from the resulting address (in
the segment specified by \c{DS}) back into \c{AL}.

The base register used is \c{BX} if the address size is 16 bits, and
\c{EBX} if it is 32 bits. If you need to use an address size not
equal to the current \c{BITS} setting, you can use an explicit
\i\c{a16} or \i\c{a32} prefix.

The segment register used to load from \c{[BX+AL]} or \c{[EBX+AL]}
can be overridden by using a segment register name as a prefix (for
example, \c{es xlatb}).

\H{insXOR} \i\c{XOR}: Bitwise Exclusive OR

\c XOR r/m8,reg8                 ; 30 /r                [8086]
\c XOR r/m16,reg16               ; o16 31 /r            [8086]
\c XOR r/m32,reg32               ; o32 31 /r            [386]

\c XOR reg8,r/m8                 ; 32 /r                [8086]
\c XOR reg16,r/m16               ; o16 33 /r            [8086]
\c XOR reg32,r/m32               ; o32 33 /r            [386]

\c XOR r/m8,imm8                 ; 80 /6 ib             [8086]
\c XOR r/m16,imm16               ; o16 81 /6 iw         [8086]
\c XOR r/m32,imm32               ; o32 81 /6 id         [386]

\c XOR r/m16,imm8                ; o16 83 /6 ib         [8086]
\c XOR r/m32,imm8                ; o32 83 /6 ib         [386]

\c XOR AL,imm8                   ; 34 ib                [8086]
\c XOR AX,imm16                  ; o16 35 iw            [8086]
\c XOR EAX,imm32                 ; o32 35 id            [386]

\c{XOR} performs a bitwise XOR operation between its two operands
(i.e. each bit of the result is 1 if and only if exactly one of the
corresponding bits of the two inputs was 1), and stores the result
in the destination (first) operand.

In the forms with an 8-bit immediate second operand and a longer
first operand, the second operand is considered to be signed, and is
sign-extended to the length of the first operand. In these cases,
the \c{BYTE} qualifier is necessary to force NASM to generate this
form of the instruction.

The MMX instruction \c{PXOR} (see \k{insPXOR}) performs the same
operation on the 64-bit MMX registers.

