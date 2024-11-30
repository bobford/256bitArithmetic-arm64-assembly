These routines test the operation of 256 bit add, subtract, and multiply written in assembly language
for the ArmV8.2 64 bit architecture.  The comparison is done against BigInteger.
BigInteger uses sign-magnitude. If the results of the subtraction is negative, the result of sub256
must be negated to be positive for the comparison with BigInteger to be made.

The 256 bit arithmetic is done in 2's complement

If the addition produces a carry into bit 257, then result[33] = 1
If the subtraction produces a "borrow" from bit 257, then result[33] = -1
