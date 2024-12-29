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
// Module:  regfile
// File:    regfile.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: 通用寄存器，共32个
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module regfile(

	input	wire	clk,
	input wire		rst,
	
	//写端口
	input wire		we,
	input wire[`RegAddrBus]	waddr,
	input wire[`RegBus]			wdata,
	
	//读端口1
	input wire					re1,
	input wire[`RegAddrBus]		 raddr1,
	output reg[`RegBus]           rdata1,
	
	//读端口2
	input wire		re2,
	input wire[`RegAddrBus]		 raddr2,
	output reg[`RegBus]           rdata2,
	output wire[223:0]  reg_data
);

	reg[`RegBus]  regs[0:`RegNum-1];
	integer i;
	
	initial begin
		for(i = 0; i < 32; i = i + 1)
			regs[i] = i;
	end
	 assign reg_data = {regs[7],regs[6],regs[5],regs[4], regs[3], regs[2], regs[1]};
	 
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin//写使能且不为0号寄存器
				regs[waddr] <= wdata;
			end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata1 <= `ZeroWord;
	  end else if(raddr1 == `RegNumLog2'h0) begin//读0寄存器直接返回0
	  		rdata1 <= `ZeroWord;
	  end else if((raddr1 == waddr) && (we == `WriteEnable) 
	  	            && (re1 == `ReadEnable)) begin//数据前推中译码与回写阶段
	  	  rdata1 <= wdata;
	  end else if(re1 == `ReadEnable) begin//读使能
	      rdata1 <= regs[raddr1];
	  end else begin
	      rdata1 <= `ZeroWord;
	  end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata2 <= `ZeroWord;
	  end else if(raddr2 == `RegNumLog2'h0) begin
	  		rdata2 <= `ZeroWord;
	  end else if((raddr2 == waddr) && (we == `WriteEnable) 
	  	            && (re2 == `ReadEnable)) begin
	  	  rdata2 <= wdata;
	  end else if(re2 == `ReadEnable) begin
	      rdata2 <= regs[raddr2];
	  end else begin
	      rdata2 <= `ZeroWord;
	  end
	end

endmodule