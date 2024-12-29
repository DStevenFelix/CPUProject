//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Module:  openmips_min_sopc_tb
// File:    openmips_min_sopc_tb.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: openmips_min_sopc的testbench
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"
`timescale 1ns/1ps

module openmips_min_sopc_tb();

  reg     CLOCK_50;
  reg     rst;
  reg BTN;
   wire[7:0] seg;//段选，高有效
   wire[7:0] seg1;
   wire[7:0] an;//位选，低有效
  initial begin
    CLOCK_50 = 1'b0;
    forever #1 CLOCK_50 = ~CLOCK_50;
  end
  
  initial begin
    BTN=1'b0;
   end
  initial begin
        rst= `RstDisable;
  end
       
  OURCPU OURCPU0(
		.clk(CLOCK_50),
		.rst(rst),
		.BTN(BTN),
		.seg(seg),
		.seg1(seg1),
		.an(an)
	);

endmodule