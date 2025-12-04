; Example program demonstrating .org, .fill, and instructions

.ORG 0
NOP             ; first instruction is NOP
INC r1          ; increment r1
ADD r1,r2       ; add r1 and r2

.ORG 100        ; jump to address 100 (decimal value)
.FILL 5 INC r1  ; fill 5 memory words with "INC r1"

.ORG 0x200      ; jump to address 0x200 (hex value)
ADD r3,52       ; add immediate 52 to r3
PD2 r5          ; some instruction
PD2 0xFF        ; same instruction with immediate but in hex!

.ORG 300
NOP             ; another NOP
EN1             ; some instruction
