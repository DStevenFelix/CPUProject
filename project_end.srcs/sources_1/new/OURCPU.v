`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/04 11:28:47
// Design Name: 
// Module Name: OURCPU
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


module OURCPU(
	input	wire clk,
	input wire	rst,
    input wire[2:0] SW,           

    output wire[7:0] seg,
    output wire[7:0] seg1,
    output wire[7:0] an 
    );
    wire[223:0] reg_data;
    reg [31:0] count = 0;
    reg div_clk = 0;

     always @(posedge clk) begin
        if(count >= 50000000) begin
            div_clk <= ~div_clk;
            count <= 0;
        end
        else begin
            count <= count + 1;
        end
    end
    
    openmips_min_sopc openmips_min_sopc0(
    .clk(div_clk),
    .rst(rst),
    .reg_data(reg_data)
    );
    
    ban ban0(
    .clk(clk),
    .rst(rst),
    .SW(SW),
    .rf_data(reg_data),
    .seg_o(seg),
    .seg1_o(seg1),
    .an_o(an)
    );
endmodule
