/*
        Copyright © 2020 Robert A. Ford. All rights reserved.

        No further distribution is authorized without the expressed written consent of the copyright holder.

        Calling sequence:
            long borrow = sub256(...);                      "borrow" is the value of the carry bit, zero or one

        register useage:
            r0  = (byte) result[]                           result = a - b;
            r1  = (byte) a[]                                a[0] is the least significant portion; a[31] is most significant
            r2  = (byte) b[]

        scratch registers:
            x4, x5      a variable
            x6, x7      b variable
            x8, x9      result

        Numbers are assumed to be 2's complement notation. Add and subtract may produce 257 bit result.

        Modified November 2024 to use fewer instructions than the original
*/


     .global   sub256
     .p2align 4
     .type    sub256, %function

sub256:

        ldp x4, x5, [x1], #16                   // this subtracts the first 128 bits of the 256 bit inputs
        ldp x6, x7, [x2], #16
        subs x8, x4, x6
        sbcs x9, x5, x7
        stp x8, x9, [x0], #16

        ldp x4, x5, [x1], #16                   // this subtracts the first 128 bits of the 256 bit inputs
        ldp x6, x7, [x2], #16
        sbcs x8, x4, x6
        sbcs x9, x5, x7
        stp x8, x9, [x0], #16

        mov x4, xzr                             // and this takes care of the carry, aka borrow
        mov x5, xzr
        sbcs x3, x4, x5
        str x3, [x0], #8                        // if the result of the subtraction is negative, this will set a byte to one

        mov x0, x3

        ret
