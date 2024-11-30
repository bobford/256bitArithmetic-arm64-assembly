/*
        Copyright © 2020 Robert A. Ford. All rights reserved.

        No further distribution is authorized without the expressed written consent of the copyright holder.

        IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES,
        INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE COPYRIGHT HOLDER HAS BEEN ADVISED
        OF THE POSSIBILITY OF SUCH DAMAGE.
        THE COPYRIGHT HOLDER SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
        AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED "AS IS".
        THE COPYRIGHT HOLDER HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

        This routine multiplies two 256 bit words to produce a 512 bit product.

        Execution time is approximately 43, 12 or 8 nanoseconds. See below.

        Calling sequence:
            long result = mul256(...);                      result is always zero
            e.g., mul256(product, a, b);                    a, b: char[32]

            r0  = (byte) product[64]                         product = a * b
            r1  = (byte) a[32]
            r2  = (byte) b[32]

        scratch registers:
            x3 - x15

        Numbers are assumed to be 2's complement notation. Multiplication will produce 512 bit result.

        Timing ~ 43 nanoseconds                             measured on Huawei Mate 20 Pro
		         12 nanoseconds								measured on Xiaomi Redmi Note 14 Pro+
                  8 nanoseconds                             measured on Xiaomi 14 Pro

                    gettimeofday(&tv1, NULL);
                    for (int i = 0; i < 1000; i++) {
                        mul256(r, reinterpret_cast<unsigned long *>(dataA), reinterpret_cast<unsigned long *>(dataB));
                    }
                    gettimeofday(&tv2, NULL);
*/

// preserve_caller_vectors(): Push first 64-bits of registers on stack (sp)
.macro save_registers
    stp x24, x23, [sp, -0x40]!
    stp x22, x21, [sp, 0x10]
    stp x20, x19, [sp, 0x20]
    stp x29, x30, [sp, 0x30]
    add x29, sp, 0x30
.endm
// restore_caller_vectors(): Restore first 64-bits from registers from stack (sp)
.macro restore_registers
    ldp x29, x30, [sp, 0x30]
    ldp x20, x19, [sp, 0x20]
    ldp x22, x21, [sp, 0x10]
    ldp x24, x23, [sp], 0x40
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


     .global   mul256
     .p2align 4
     .type    mul256, %function

mul256:
        save_registers

        ldr x3, [x1], #8                            // a[0]

        partialProductsFirstStage

        str x6, [x0], #8                            // low 64 bits of answer


//      now repeat this for a[1]

        ldr x3, [x1], #8                            // a[1]

        partialProducts

//      and now combine this with the previous results

        adds x21, x6, x21

//      x21 can be stored as the next 64 bits of the answer

        str x21, [x0], #8                           // x21 is now scratch
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

        str x21, [x0], #8                           // x21 is now scratch
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

        str x21, [x0], #8                           // x21 is now scratch
        adcs x21, x14, x22
        adcs x22, x15, x23
        adcs x23, x19, x24
        adcs x24, x20, xzr

        stp x21, x22, [x0], #16
        stp x23, x24, [x0], #16

//      this completes

        mov x0, #0                                  // no error

        restore_registers

        ret
