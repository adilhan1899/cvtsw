`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2021
// Engineer: Chris Larsen
// 
// Create Date: 04/09/2021 07:54:21 AM
// Design Name: 
// Module Name: round
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Utility routine for cvt.s.w instruction.
//
//              This instruction name is specific to MIPS but it's assumed that
//              other architectures have similar instructions with different names
//              which convert a signed 32-bit integer into a IEEE 754 binary32
//              value.
//
//              The integer stored in `sigIn' has already been shifted left so its
//              most significant bit set is to 1 (one) is in bit sigIn[INTn-1] and
//              the value of `expIn' has been adjusted accordingly.
//
//              The module is parameterized so it can be re-used as the basis of the
//              cvt.d.l instruction; the `padder24' module would have to be
//              replaced with a module to round a 53-bit significand. Again, this
//              instruction is specific to the MIPS architecture. It would also be
//              useful for converting/rounding any integer quantity into an IEEE
//              floating point format where the number of bits in the significand
//              of the result is fewer than the number of bits in the original
//              integer. [Note: This even applies if the original integer was
//              unsigned. The module presumes that the absolute value of the input
//              integer is the value stored in `sigIn'.] For example, suppose MIPS
//              had an instruction to convert a 16-bit unsigned integer into an
//              IEEE 754 binary16 value this module (with the appropriate input
//              parameters and by replacing the addition module) could be used to
//              perform the necessary rounding.
//////////////////////////////////////////////////////////////////////////////////
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module round(negIn, expIn, sigIn, ra, expOut, sigOut);
  parameter INTn = 32;
  parameter NEXP =  8;
  parameter NSIG = 23;
  `include "ieee-754-flags.v"
  input negIn;
  input [NEXP-1:0] expIn;
  input [INTn-1:0] sigIn;
  input [LAST_RA:0] ra;
  output [NEXP-1:0] expOut;
  output [NSIG:0] sigOut;
  
  wire Cout;
  wire [NSIG:0] aSig, rSig, tSig;
  wire [NEXP-1:0] rExp;
  
  // Flags used in determination of whether we should be rounding:
  wire lastKeptBitIsOdd, decidingBitIsOne, remainingBitsAreNonzero;
  
  // Is the last bit to be saved a `1', that is, is it odd?
  assign lastKeptBitIsOdd        =  sigIn[INTn-NSIG-1];
  
  // Is the first bit to be truncated a `1'?
  // Then we use the last bit being kept to break the tie
  // in choosing to round, or use the rest of the truncated
  // bits.
  assign decidingBitIsOne        =  sigIn[INTn-NSIG-2];
  
  // Are the bits beyond the first bit to be truncated all zero?
  // If not, we don't have a tie situation.
  assign remainingBitsAreNonzero = |sigIn[INTn-NSIG-3:0];
                
  // This flag holds the boolean value of whether or not we need to round this
  // significand. It's used as the carry-in bit for the instantiation of
  // padder24() below.
  wire roundBit;
  
  // Determine whether or not we round this significand.
  assign roundBit = (ra[roundTiesToEven] & // First rounding case
                     decidingBitIsOne & (lastKeptBitIsOdd | remainingBitsAreNonzero)) |
                    (ra[roundTowardPositive] & // Second rounding case
                     ~negIn & (decidingBitIsOne | remainingBitsAreNonzero)) |
                    (ra[roundTowardNegative] & // Third rounding case
                     negIn & (decidingBitIsOne | remainingBitsAreNonzero));
                    // When ra[roundTowardZero] is true we don't round, we
                    // truncate.

  // Round NSIG+1 most significant bits of the significand.
  assign tSig = sigIn[INTn-1:INTn-NSIG-1];
  
  // Compute the rounded significand.
  padder24 U0(tSig, {NSIG+1{1'b0}}, roundBit, aSig, Cout);
  // If there was a carry-out then the carry-out is the new most significant
  // bit set to 1 (one).
  assign rSig = Cout ? {Cout, aSig[NSIG:1]} : aSig;
  
  // If when we rounded sigIn there was a carry-out we need to adjust the exponent
  // to re-normalize the result.
  assign rExp = expIn + Cout; // We're adding either 1 or 0 to expIn.
  
  // Return final exponent and significand values.
  assign {expOut, sigOut} = {rExp, rSig};

  endmodule
