/*
        Copyright © 2020 Robert A. Ford. All rights reserved.

        No further distribution is authorized without the expressed written consent of the copyright holder.

        Calling sequence:
            long overflow = dotProduct(...);                      "overflow" is the value of the excess, over 512 bits, in the dot product
            dotProduct(result, a, b, scratch, size, n);           byte[] result[72], byte[] a[32], byte[] b[32], byte[64]


            r0  = (byte) dotProduct[72]                           dot product = sum (i=0 ... n-1) (a * b)
            r1  = (byte) a[32*n]
            r2  = (byte) b[32*n]
            r3  = (byte) scratch[64]                              scratch buffer for product
            r4  = number of elements in sum

        scratch registers:
            x3 - x17
            x19 - x29
            r18 = not available for use

*/

// preserve_caller_vectors(): Push first 64-bits of registers on stack (sp)

.macro save_registers
stp x20, x19, [sp, #-0x60]!              // store at sp - 0x60, sp modified, sp = sp - 0x60
stp x22, x21, [sp, 0x10]
stp x24, x23, [sp, 0x20]
stp x26, x25, [sp, 0x30]
stp x28, x27, [sp, 0x40]
stp x30, x29, [sp, 0x50]
.endm
// restore required registers
.macro restore_registers
ldp x30, x29, [sp, 0x50]
ldp x28, x27, [sp, 0x40]
ldp x26, x25, [sp, 0x30]
ldp x24, x23, [sp, 0x20]
ldp x22, x21, [sp, 0x10]
ldp x20, x19, [sp], #0x60                // load from sp, sp modified, sp = sp + 0x60
.endm


.macro partialProducts
        ldp x4, x5, [x2, #0]                        // b[0]
        mul  x6, x3, x4                             // low product a * b[0]
        umulh x8, x3, x4                            // high

        mul   x7, x3, x5                            // low product a * b[1]
        umulh x9, x3, x5                            // high

        ldp x4, x5, [x2, #16]                       // b[2]
        mul   x10, x3, x4                           // low product a * b[2]
        umulh x12, x3, x4                           // high

        mul   x11, x3, x5                           // low product a * b[3]
        umulh x13, x3, x5                           // high

//      now combine a*b[0] high with a*b[1] low, a*b[1] high with a*b[2] low, etc; x6 has low 64 bits

        adds x14, x8, x7
        adcs x15, x9, x10
        adcs x19, x12, x11
        adcs x20, x13, xzr
.endm

.macro partialProductsFirstStage
        ldp x4, x5, [x2, #0]                        // b[0]
        mul  x6, x3, x4                             // low product a * b[0]
        umulh x8, x3, x4                            // high

        mul   x7, x3, x5                            // low product a * b[1]
        umulh x9, x3, x5                            // high

        ldp x4, x5, [x2, #16]                       // b[2]
        mul   x10, x3, x4                           // low product a * b[2]
        umulh x12, x3, x4                           // high

        mul   x11, x3, x5                           // low product a * b[3]
        umulh x13, x3, x5                           // high

//      now combine a*b[0] high with a*b[1] low, a*b[1] high with a*b[2] low, etc; x6 has low 64 bits

        adds x21, x8, x7
        adcs x22, x9, x10
        adcs x23, x12, x11
        adcs x24, x13, xzr
.endm


     .global   dotProduct
     .p2align 4
     .type    dotProduct, %function

dotProduct:
        save_registers 
        
        mov x16, x4                                 // loop count here
        mov x17, x0                                 // the dot product address
        mov x25, x3                                 // the scratch buffer address
        mov x27, x1                                 // the first input
        mov x28, x2                                 // the other input
loop:
        mov x26, x25                                // scratch buffer, working register
        mov x1, x27                                 // restore other input
        mov x2, x28

//      this starts the multiply for the dot product

        ldr x3, [x1], #8                            // a[0]

        partialProductsFirstStage
       
        str x6, [x26], #8                            // low 64 bits of answer       1st 8 bytes, 64 bits

//      now repeat this for a[1]

        ldr x3, [x1], #8                            // a[1]

        partialProducts

//      and now combine this with the previous results

        adds x21, x6, x21

//      x21 can be stored as the next 64 bits of the answer

        str x21, [x26], #8                           // x21 is now scratch          2nd 8 bytes

        adcs x21, x14, x22
        adcs x22, x15, x23
        adcs x23, x19, x24
        adcs x24, x20, xzr

//      now repeat this for a[2]

        ldr x3, [x1], #8                            // a[2]

        partialProducts

//      and now combine this with the previous results

        adds x21, x6, x21

//      x21 can be stored as the next 64 bits of the answer

        str x21, [x26], #8                           // x21 is now scratch          3rd 8 bytes
        adcs x21, x14, x22
        adcs x22, x15, x23
        adcs x23, x19, x24
        adcs x24, x20, xzr

//      now repeat this for a[3]

        ldr x3, [x1], #8                            // a[3]

        partialProducts

//      and now combine this with the previous results

        adds x21, x6, x21

//      x21 can be stored as the next 64 bits of the answer

        str x21, [x26], #8                           // x21 is now scratch          4th 8 bytes
        adcs x21, x14, x22
        adcs x22, x15, x23
        adcs x23, x19, x24
        adcs x24, x20, xzr

        stp x21, x22, [x26], #16                     //                               5th and 6th
        stp x23, x24, [x26], #16                     //                               7th and 8th

//      accumulate the product
//      set x20 to start of scratch buffer and x21 to accumulator. also x0 to sum

        mov x0, x17                             // points to the dot product
        mov x21, x17                            // accumulating in the dot product
        mov x20, x25                            // the scratch buffer

        ldp x4, x5, [x20], #16                   // this adds the first 128 bits of the 72 byte dot product
        ldp x6, x7, [x21], #16
        adds x8, x4, x6
        adcs x9, x5, x7
        stp x8, x9, [x0], #16

        ldp x4, x5, [x20], #16                   // this adds the next 128 bits of the 72 byte dot product
        ldp x6, x7, [x21], #16
        adcs x8, x4, x6
        adcs x9, x5, x7
        stp x8, x9, [x0], #16

        ldp x4, x5, [x20], #16                   // this adds bits 256-384 of the 72 byte dot product
        ldp x6, x7, [x21], #16
        adcs x8, x4, x6
        adcs x9, x5, x7
        stp x8, x9, [x0], #16

        ldp x4, x5, [x20], #16                   // this adds bits 384-512 of the 72 byte dot product
        ldp x6, x7, [x21], #16
        adcs x8, x4, x6
        adcs x9, x5, x7
        stp x8, x9, [x0], #16

        ldr x6, [x21], #16                   // this adds the last 128 bits of the 72 byte dot product
        mov x4, xzr
        adcs x3, x4, x6
        str x3, [x0], #8

//      reset registers for next elements in summation

        add x27, x27, #32                           // the first input
        add x28, x28, #32                           // the other input

        subs x16, x16, #1
        cbnz x16, loop
        
//      this completes

        mov x0, x3                                  // no error

        restore_registers

        ret
