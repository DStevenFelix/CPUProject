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
// Module:  openmips_min_sopc
// File:    openmips_min_sopc.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: ????OpenMIPS?????????????SOPC??????????????
//              wishbone???????openmips????SOPC????openmips??
//              wb_conmax??GPIO controller??flash controller??uart 
//              controller?????????????flash?????flashmem????????
//              ?洢?????????????ram?????datamem???????д洢
//              ????????????wishbone??????    
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module openmips_min_sopc(

	input	wire	clk,
	input wire	rst,
	output wire[223:0] reg_data
);

  //???????洢??
  wire[`InstAddrBus] inst_addr;
  wire[`InstBus] inst;
  wire rom_ce;
 

 openmips openmips0(
		.clk(clk),
		.rst(rst),
	
		.rom_addr_o(inst_addr),
		.rom_data_i(inst),
		.rom_ce_o(rom_ce),
		.reg_data(reg_data)
	
	);
	
	inst_rom inst_rom0(
		.ce(rom_ce),
		.addr(inst_addr),
		.inst(inst)	
	);


endmodule