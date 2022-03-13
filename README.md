# Verilog formatOf-ConvertFromInt(int)

## Description

Convert 32-bit signed integer to IEEE 754 binary32 format.

Because the significand of binary32 values has fewer significant digits
than the integer being converted rounding is required.

If needed, it is easy to modify this code support converting unsigned
integers to float. Also, it is trivial to modify this code to convert
* 16-bit integers to binary16;
* 32-bit integers to binary16; and
* 64-bit integers to binary16, binary32, and binary64.

In practice, because this code is most likely to be used to implement a
RISC processor, and RISC processors use a load/store architecture, once
8-bit and 16-bit values are read from memory into a register and the
register is likely to be a 32- or 64-bit register, the need for
instructions to convert 8- and 16-bit integers into float would be very
limited.

This code, as is, supports all of the rounding modes required by the
IEEE 754 standard for the binary floating point types. These are
roundTiesToEven, roundTowardZero, roundTowardPositive, and roundTowardNegative.

In general, because the floating point value won't be exactly equal to the original
integer value, the module returns the `inexact' flag to advise the user
when there has been a loss of precision. Also the module has an `overflow'
flag. While it's not needed for converting 32-bit integers to binary32 values
there are some combinations of converting integers to floating values (such
as converting 32-bit integers into binary16 values) for which it will be needed.

## Manifest

|   Filename   |                        Description                        |
|--------------|-----------------------------------------------------------|
| README.md | This file. |
| cvtsw.sv | Code to implement MIPS cvt.s.w instruction. |
| cvtsw_tb.v | Test code for cvt.s.w. |
| ieee-754-flags.v | Include file which defines the position of each of the individual IEEE type flags within the bit vector. Also defines symbolic names for quantities defined by IEEE 754. The definitions calculate these values from NEXP and NSIG. It's because these values are calculated from NEXP and NSIG dynamically that this module is able to support all of the IEEE 754 binary types instead having a different module for each type. |
| padder24.v | Prefix adder used by the round module below. |
| round.v | Code to round 32 normalized significand to 23 bits. |

## Copyright

:copyright: Chris Larsen, 2019-2022
