`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2021 01:10:08 PM
// Design Name: 
// Module Name: cvtsw_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cvtsw_tb();
  parameter INTn = 32;
  parameter NEXP = 8;
  parameter NSIG = 23;
  localparam decidingBit = INTn - NSIG - 3;
  `include "../../sources_1/new/ieee-754-flags.v"
  reg signed [INTn-1:0] w;
  reg [LAST_RA:0] ra  = 1 << roundTiesToEven;
  reg [LAST_RA:0] raz = 1 << roundTowardZero;
  reg [LAST_RA:0] rap = 1 << roundTowardPositive;
  reg [LAST_RA:0] ran = 1 << roundTowardNegative;
  wire [NEXP+NSIG:0] s, sz, sp, sn;
  wire[3:0] inexact;
  
  integer i;
  
  initial
    begin
      w = 0;
      $monitor("w = %d (0x%x), s = %x, sz = %x, sp = %x, sn = %x, inexact = %s",
               w, w,
               s, sz, sp, sn, (&inexact ? "True" : (~|inexact ? "False" : "Error")));
    end
  
  initial
    begin
      // Test 2 ** i. All values should be exact.
      for (i = 0; i < (INTn-1); i = i + 1)
        begin
          #10 w = 1 << i;
          #10 w = (~w) + 1;                   // Test negative value
        end
        
      // Test most negative value.
      #10 w = 1 << (INTn - 1);
        
      // Test (2 ** i) - 1. Some of the values should be inexact.
      for (i = 2; i < INTn; i = i + 1)
        begin
          #10 w = (1 << i) - 1;
          #10 w = (~w) + 1;                   // Test negative value
        end
        
      for (i = 0; i < INTn-NSIG-2; i = i + 1)
        begin
          #10 w = ((1 << (NSIG+1)) | 1) << i; // Even
          #10 w = (~w) + 1;                   // Test negative value
          #10 w = ((1 << (NSIG+1)) | 2) << i; // Odd but don't round
          #10 w = (~w) + 1;                   // Test negative value
          #10 w = ((1 << (NSIG+1)) | 3) << i; // Odd
          #10 w = (~w) + 1;                   // Test negative value
        end
        
      // When the decidingBit is 1 & the last bit being kept is zero
      // verify that when any of the other discarded bits is 1 that we
      // round up in the roundTiesToEven case.
      for (i = 0; i < decidingBit; i = i + 1)
        begin
          #10 w = (1 << (INTn - 2)) | (1 << decidingBit) | (1 << i);
          #10 w = (~w) + 1;                   // Test negative value
        end
        
      #10 $display("Test ended");
      $stop;
    end
  
  cvtsw inst1(w, s,  ra,  inexact[0]);
  cvtsw inst2(w, sz, raz, inexact[1]);
  cvtsw inst3(w, sp, rap, inexact[2]);
  cvtsw inst4(w, sn, ran, inexact[3]);
  
endmodule
