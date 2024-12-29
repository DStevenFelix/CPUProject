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
// Module:  ex
// File:    ex.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: 执行阶段
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module ex( 

	input wire rst,
	
	//送到执行阶段的信息
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,

	//HI、LO寄存器的值
	input wire[`RegBus]           hi_i,
	input wire[`RegBus]           lo_i,

	//回写阶段的指令是否要写HI、LO，用于检测HI、LO的数据相关
	input wire[`RegBus]           wb_hi_i,
	input wire[`RegBus]           wb_lo_i,
	input wire                    wb_whilo_i,
	
	//访存阶段的指令是否要写HI、LO，用于检测HI、LO的数据相关
	input wire[`RegBus]           mem_hi_i,
	input wire[`RegBus]           mem_lo_i,
	input wire                    mem_whilo_i,

	input wire[`DoubleRegBus]     hilo_temp_i,
	input wire[1:0]               cnt_i,

	//与除法模块相连
	input wire[`DoubleRegBus]     div_result_i,
	input wire                    div_ready_i,
	
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]			wdata_o,

	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o,
	output reg                    whilo_o,
	
	output reg[`DoubleRegBus]     hilo_temp_o,
	output reg[1:0]               cnt_o,

	output reg[`RegBus]           div_opdata1_o,
	output reg[`RegBus]           div_opdata2_o,
	output reg                    div_start_o,
	output reg                    signed_div_o,

	output reg		stallreq       			
	
);

	reg[`RegBus] logicout;//存储逻辑运算结果
	reg[`RegBus] shiftres;//移位
	reg[`RegBus] moveres;//移动
	reg[`RegBus] arithmeticres;//简单算数（32）
	reg[`DoubleRegBus] mulres;	//乘法结果（64）
	reg[`RegBus] HI;//HI寄存器的最新内容
	reg[`RegBus] LO;//HI寄存器的最新内容
	
	wire[`RegBus] reg2_i_mux;//保存第二个操作数reg2_i的补码
	wire[`RegBus] reg1_i_not;	//保存第一个操作数reg1_i的反码
	wire[`RegBus] result_sum;//保存加法结果（减法）
	wire ov_sum;//溢出
	wire reg1_eq_reg2;//第一个操作数是否等于第二个操作数
	wire reg1_lt_reg2;//第一个操作数是否小于第二个操作数
	wire[`RegBus] opdata1_mult;//乘法操作的被乘数
	wire[`RegBus] opdata2_mult;//乘法操作的乘数
	wire[`DoubleRegBus] hilo_temp;//临时保存的乘法结果
	reg[`DoubleRegBus] hilo_temp1;		//乘法结果
	reg stallreq_for_div;
			
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP:			begin
					logicout <= reg1_i | reg2_i;
				end
				`EXE_AND_OP:		begin
					logicout <= reg1_i & reg2_i;
				end
				`EXE_NOR_OP:		begin
					logicout <= ~(reg1_i |reg2_i);
				end
				`EXE_XOR_OP:		begin
					logicout <= reg1_i ^ reg2_i;
				end
				default:				begin
					logicout <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_SLL_OP:			begin
					shiftres <= reg2_i << reg1_i[4:0] ;
				end
				`EXE_SRL_OP:		begin
					shiftres <= reg2_i >> reg1_i[4:0];
				end
				`EXE_SRA_OP:		begin
					shiftres <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) 
												| reg2_i >> reg1_i[4:0];//比特位填充
				end
				default:				begin
					shiftres <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
											 (aluop_i == `EXE_SLT_OP) ) 
											 ? (~reg2_i)+1 : reg2_i;//如果是减法则保存第二位的补码，否则不变

	assign result_sum = reg1_i + reg2_i_mux;										 

	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  //计算是否溢出，正正和为负，负负和为正
									
	assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?
												 ((reg1_i[31] && !reg2_i[31]) || 
												 (!reg1_i[31] && !reg2_i[31] && result_sum[31])||//都为正数且相减为负数
			                   (reg1_i[31] && reg2_i[31] && result_sum[31]))//都为负数且相减为负数
			                   :	(reg1_i < reg2_i);//比较reg1与reg2的大小，无符号直接算术符比较
  
  assign reg1_i_not = ~reg1_i;//取反为clo服务
							
	always @ (*) begin
		if(rst == `RstEnable) begin
			arithmeticres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP:		begin
					arithmeticres <= result_sum; 
				end
				`EXE_SUB_OP, `EXE_SUBU_OP:		begin
					arithmeticres <= result_sum; 
				end		

				default:				begin
					arithmeticres <= `ZeroWord;
				end
			endcase
		end
	end
	
	
	
	
	
	
	
	
	//
	//
	//
	//乘法

  //取得乘法操作的操作数，如果是有符号乘法且操作数是负数，那么取反加一
  //乘数
	assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) )
													&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
//被乘数
  assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
													&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;	

  assign hilo_temp = opdata1_mult * opdata2_mult;																				

	always @ (*) begin
		if(rst == `RstEnable) begin
			mulres <= {`ZeroWord,`ZeroWord};
		end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP))begin//有符号乘法
			if(reg1_i[31] ^ reg2_i[31] == 1'b1) begin//异号
				mulres <= ~hilo_temp + 1;//取补码
			end else begin
			  mulres <= hilo_temp;
			end
		end else begin
				mulres <= hilo_temp;
		end
	end














  //得到最新的HI、LO寄存器的值，此处要解决指令数据相关问题
	always @ (*) begin
		if(rst == `RstEnable) begin
			{HI,LO} <= {`ZeroWord,`ZeroWord};
		end else if(mem_whilo_i == `WriteEnable) begin
			{HI,LO} <= {mem_hi_i,mem_lo_i};
		end else if(wb_whilo_i == `WriteEnable) begin
			{HI,LO} <= {wb_hi_i,wb_lo_i};
		end else begin
			{HI,LO} <= {hi_i,lo_i};			
		end
	end	

  always @ (*) begin
    stallreq =   stallreq_for_div;
  end












//
//
//
//除法

  //DIV、DIVU指令	
	always @ (*) begin
		if(rst == `RstEnable) begin
			stallreq_for_div <= `NoStop;
	    div_opdata1_o <= `ZeroWord;
			div_opdata2_o <= `ZeroWord;
			div_start_o <= `DivStop;
			signed_div_o <= 1'b0;
		end else begin
			stallreq_for_div <= `NoStop;
	    div_opdata1_o <= `ZeroWord;
			div_opdata2_o <= `ZeroWord;
			div_start_o <= `DivStop;
			signed_div_o <= 1'b0;	
			case (aluop_i) 
				`EXE_DIV_OP:		begin
					if(div_ready_i == `DivResultNotReady) begin
	    			    div_opdata1_o <= reg1_i;//被除数
						div_opdata2_o <= reg2_i;//除数
						div_start_o <= `DivStart;
						signed_div_o <= 1'b1;//继续除
						stallreq_for_div <= `Stop;//没结束继续停止if id ex阶段 001111
					end else if(div_ready_i == `DivResultReady) begin
	    			div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b1;
						stallreq_for_div <= `NoStop;
					end else begin						
	    			div_opdata1_o <= `ZeroWord;
						div_opdata2_o <= `ZeroWord;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end					
				end
				`EXE_DIVU_OP:		begin
					if(div_ready_i == `DivResultNotReady) begin
	    			div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStart;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `Stop;
					end else if(div_ready_i == `DivResultReady) begin
	    			div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end else begin						
	    			div_opdata1_o <= `ZeroWord;
						div_opdata2_o <= `ZeroWord;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end					
				end
				default: begin
				end
			endcase
		end
	end	





	//MFHI、MFLO、MOVN、MOVZ指令
	always @ (*) begin
		if(rst == `RstEnable) begin
	  	moveres <= `ZeroWord;
	  end else begin
	   moveres <= `ZeroWord;
	   case (aluop_i)
	   	`EXE_MFHI_OP:		begin
	   		moveres <= HI;
	   	end
	   	`EXE_MFLO_OP:		begin
	   		moveres <= LO;
	   	end
	   	`EXE_MOVZ_OP:		begin
	   		moveres <= reg1_i;
	   	end
	   	`EXE_MOVN_OP:		begin
	   		moveres <= reg1_i;
	   	end
	   	default : begin
	   	end
	   endcase
	  end
	end	 

 always @ (*) begin
	 wd_o <= wd_i;
	 	 	 	
	 if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || 
	      (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin//溢出使能为0
	 	wreg_o <= `WriteDisable;
	 end else begin
	  wreg_o <= wreg_i;
	 end
	 
	 case ( alusel_i ) 
	 	`EXE_RES_LOGIC:		begin
	 		wdata_o <= logicout;
	 	end
	 	`EXE_RES_SHIFT:		begin
	 		wdata_o <= shiftres;
	 	end	 	
	 	`EXE_RES_MOVE:		begin
	 		wdata_o <= moveres;
	 	end	 	
	 	`EXE_RES_ARITHMETIC:	begin
	 		wdata_o <= arithmeticres;
	 	end
	 	`EXE_RES_MUL:		begin
	 		wdata_o <= mulres[31:0];//后32位存入rd
	 	end	 	
	 	default:					begin
	 		wdata_o <= `ZeroWord;
	 	end
	 endcase
 end	

//hi lo存取
	always @ (*) begin
		if(rst == `RstEnable) begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;		
		end else if((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= mulres[63:32];//高位存入hi
			lo_o <= mulres[31:0];//低位存入lo	
		end else if((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= div_result_i[63:32];//余数送高位
			lo_o <= div_result_i[31:0];		//商送低位					
		end else if(aluop_i == `EXE_MTHI_OP) begin
			whilo_o <= `WriteEnable;
			hi_o <= reg1_i;
			lo_o <= LO;
		end else if(aluop_i == `EXE_MTLO_OP) begin
			whilo_o <= `WriteEnable;
			hi_o <= HI;
			lo_o <= reg1_i;
		end else begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end				
	end			

endmodule