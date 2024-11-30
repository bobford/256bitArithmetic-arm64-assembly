/*
        Copyright © 2020 Robert A. Ford. All rights reserved.

        No further distribution is authorized without the expressed written consent of the copyright holder.

        Calling sequence:
            long carry = add256(...);                      "carry" is the value of the carry bit, zero or one
            add256(result, a, b);                           byte[] result[33], byte[] a[32], byte[] b[32]

        register useage:
            r0  = (byte) result[]                           result = a + b;
            r1  = (byte) a[]                                a[0] is the least significant portion; a[31] is most significant
            r2  = (byte) b[]

        scratch registers:
            x4, x5      a variable
            x6, x7      b variable
            x8, x9      result

        Numbers are assumed to be 2's complement notation. Add and subtract may produce 257 bit result.

        Example of invocation from native-lib.cpp:
            auto *r = (unsigned char*)calloc(size, sizeof(unsigned char));
            carry = add256(r, reinterpret_cast<unsigned char *>(dataA), reinterpret_cast<unsigned char *>(dataB));
            __android_log_print(ANDROID_LOG_DEBUG, TAG, "carry out: %8lx ", carry);

        Modified November 2024 to use fewer instructions than the original

        The following was used to convert the resultant byte array into a hex string:

            private String getByteAsHexString(byte[] a) {
                int size = a.length;
                StringBuilder result = new StringBuilder();
                for (int i=size-1; i>=0; i--) {
                    String n = String.format("%02x", a[i]);
                    result.append(n);
                }
                return result.toString();
            }
*/


     .global   add256
     .p2align 4
     .type    add256, %function

add256:
        ldp x4, x5, [x1], #16                   // this adds the first 128 bits of the 256 bit inputs
        ldp x6, x7, [x2], #16
        adds x8, x4, x6
        adcs x9, x5, x7
        stp x8, x9, [x0], #16

        ldp x4, x5, [x1], #16                   // this adds the last 128 bits of the 256 bit inputs
        ldp x6, x7, [x2], #16
        adcs x8, x4, x6
        adcs x9, x5, x7
        stp x8, x9, [x0], #16

        mov x4, xzr                             // and this is for the carry
        mov x5, xzr
        adc x3, x4, x5
        str x3, [x0], #8

        mov x0, x3

        ret
