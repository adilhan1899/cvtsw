`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2021 12:50:00 PM
// Design Name: 
// Module Name: cvtsw
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Convert 32-bit signed integer into 32-bit floating point number.
//              Implement MIPS cvt.s.w instruction.
//
//              The module also needs to be able to compute its outputs
//              based on the rounding mode configured by the user. We need
//              to support:
//              o roundTiesToEven,
//              o roundTowardZero,
//              o roundTowardPositive, and
//              o roundTowardNegative.
//
//              Per section 4.3.3: "The roundTiesToEven rounding-direction
//              attribute shall be the default rounding-direction attribute
//              for results in binary formats."
//
//              The rounding mode `roundTiesToAway' is only required for
//              base 10 floating point numbers. That is, it's optional for
//              base 2 floating point numbers, so I'm omitting this feature.
//              See Section 4.3.3.
//
//              No 32-bit signed integer is so large that it can't be
//              represented as a binary32/binary64/binary128 number.
//              Consequently we will never have an overflow exception.
//              We can have overflow exceptions when converting 32-bit
//              signed integers to binary16.
//
//              Because we're converting integers to floating point numbers
//              we will never have a number with only (any) fractional part
//              so testing for underflow exception has no meaning in this
//              case.
//
//              Implement `roundTowardZero' and signal `inexact' exception.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cvtsw(w, s, ra, inexact, overflow);
  parameter INTn = 32;
  parameter NEXP =  8;
  parameter NSIG = 23;
  `include "ieee-754-flags.v"
  localparam CLOG2_INTn = $clog2(INTn);
  input signed [INTn-1:0] w;
  output [NEXP+NSIG:0] s;
  reg [NEXP+NSIG:0] s;
  input [LAST_RA:0] ra;     // Rounding Attribute
  output inexact, overflow; // Signal exception conditions.
  reg overflow;
  
  reg [INTn-1:0] sigIn;
  wire [INTn-1:0] mask;
  
  assign mask = {NEXP+NSIG+1{1'b1}};

  integer i;
  reg [NEXP-1:0] expIn;
  
  reg [NEXP-1:0] expOut;
  reg [NSIG:0] sigOut;
          
  always @(*)
    begin
      // Signed integers are stored in 2's complement form; floating
      // point numbers are stored in sign/magnitude form. If the
      // input value is negative compute its absolute value. We get
      // the correct result even though 2 ** (INTn-1) can't be
      // represented as a signed integer. Effectively, after we've
      // computed the absolute value we treat the INTn-bit result as
      // an unsigned number and this works.
      sigIn = w[INTn-1] ? (~w + 1) : w;
      
      if (sigIn == 0)
        begin
          s = {NEXP+NSIG+1{1'b0}};
        end
      else
        begin
          // Left shift the significand to get the most significant
          // 1 bit into bit position NSIG. Keep track of how many places
          // We needed to shift the significand value; we'll need this
          // information for calculating the final exponent value.
          expIn = 0;
          for (i = (1 << (CLOG2_INTn - 1)); i > 0; i = i >> 1)
            begin
              if ((sigIn & (mask << (INTn - i))) == 0)
                begin
                  sigIn = sigIn << i;
                  expIn = expIn | i;
                end
            end

          // The largest possible signed INTn-bit signed integer magnitude
          // is 2 ** (INTn-1) so we start with (INTn-1) as our largest
          // possible exponent. Each bit position we had to shift in order
          // to get the most significant one bit into position NSIG reduces
          // the exponent value. Don't forget we need to add the BIAS value
          // to get our final exponent value.
          expIn = (INTn-1) + BIAS - expIn; // Exponent w/bias.
          
          // See below for the instantiation of the round module which
          // does the actual rounding. The instantiation is placed at
          // the bottom because it can't be instantiated inside of an
          // `always' block.  The lines above us create its input. The
          // lines below use its output.
          
          // Did we round to +/- infinity?
          // This test isn't needed for this case. But it will be needed
          // for other integer to float conversions so we leave it here as
          // a reminder for when it is needed.
          overflow = &expOut;
          s[NEXP+NSIG:NSIG] = {w[INTn-1], expOut};
          s[NSIG-1:0] = overflow ? {NSIG{1'b0}} : sigOut;
        end
    end

    // If any of the bits removed by truncation are 1 then we produced
    // an inexact result.
    assign inexact = |sigIn[INTn-2-NSIG:0];
    
    // Round the significand.
    round U0(w[INTn-1], expIn, sigIn, ra, expOut, sigOut);
endmodule
