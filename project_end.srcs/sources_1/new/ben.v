`timescale 1ns / 1ps

module ban(
    input wire clk,
    input wire rst,         // 全局复位信号

    input wire[2:0] SW,          // 拨码开关信号
    input wire[223:0] rf_data,   // 寄存器文件数据

    output [7:0] seg_o,   // 七段数码管显示
    output [7:0] seg1_o,  // 第二块七段数码管显示
    output [7:0] an_o     // 数码管位选信号
);
    reg[7:0] seg = 0;
    reg[7:0] seg1 = 0;
    reg[7:0] an = 8'b00000001;

    assign seg_o = seg;
    assign seg1_o = seg1;
    assign an_o = an;

    reg [18:0] divclk_cnt = 0;
    reg div_clk = 0;
    parameter maxcnt = 50000;

    reg[31:0] dsp;

    // 分频器
    always @(posedge clk)
    begin
        if (divclk_cnt >= maxcnt)
        begin
            div_clk <= ~div_clk;
            divclk_cnt <= 0;
        end
        else
        begin
            divclk_cnt <= divclk_cnt + 1'b1;
        end
    end 

    // 根据拨码开关（SW）的状态选择显示的寄存器
    always @(*) begin
        case(SW)         
            3'b000: dsp = rf_data[31:0]; //1号寄存器
            3'b001: dsp = rf_data[63:32]; //2号寄存器
            3'b010: dsp = rf_data[95:64]; //3号寄存器
            3'b011: dsp = rf_data[127:96]; //4号寄存器
            3'b100: dsp = rf_data[158:128]; //5号寄存器
            3'b101: dsp = rf_data[191:159]; //6号寄存器
            3'b110: dsp = rf_data[207:192]; //7号寄存器
            3'b111: dsp = 16'hffff; // 默认值或未定义寄存器
            default: dsp = 16'hffff; // 防止综合问题
        endcase
    end  
    
    reg[2:0] disp_bit = 0; // 当前位数
    reg[3:0] disp_dat = 0; // 当前位的数据
     
    // 数码管动态显示位选逻辑
    always @(posedge div_clk) begin
        if (disp_bit >= 7)
            disp_bit <= 0;
        else
            disp_bit <= disp_bit + 1'b1;

        case (disp_bit)
            3'b000 :
            begin
                disp_dat <= dsp[3:0];
                an <= 8'b00000001; // 激活第一位
            end
            3'b001 :
            begin
                disp_dat <= dsp[7:4];
                an <= 8'b00000010; // 激活第二位
            end
            3'b010 :
            begin
                disp_dat <= dsp[11:8];
                an <= 8'b00000100; // 激活第三位
            end
            3'b011 :
            begin
                disp_dat <= dsp[15:12];
                an <= 8'b00001000; // 激活第四位
            end
            3'b100 :
            begin
                disp_dat <= dsp[19:16];
                an <= 8'b00010000; // 激活第五位
            end
            3'b101 :
            begin
                disp_dat <= dsp[23:20];
                an <= 8'b00100000; // 激活第六位
            end
            3'b110 :
            begin
                disp_dat <= dsp[27:24];
                an <= 8'b01000000; // 激活第七位
            end
            3'b111 :
            begin
                disp_dat <= dsp[31:28];
                an <= 8'b10000000; // 激活第八位
            end
            default:
            begin
                disp_dat <= 0;
                an <= 8'b00000000;
            end
        endcase
    end
    
    // 七段数码管显示逻辑
    always @(disp_dat) begin
        case (disp_dat)
            // 显示 0-F 的数据
            4'h0 : seg = 8'hfc;
            4'h1 : seg = 8'h60;
            4'h2 : seg = 8'hda;
            4'h3 : seg = 8'hf2;
            4'h4 : seg = 8'h66;
            4'h5 : seg = 8'hb6;
            4'h6 : seg = 8'hbe;
            4'h7 : seg = 8'he0;
            4'h8 : seg = 8'hfe;
            4'h9 : seg = 8'hf6;
            4'ha : seg = 8'hee;
            4'hb : seg = 8'h3e;
            4'hc : seg = 8'h9c;
            4'hd : seg = 8'h7a;
            4'he : seg = 8'h9e;
            4'hf : seg = 8'h8e;
        endcase
        // 同样为第二块数码管赋值
        case (disp_dat)
            4'h0 : seg1 = 8'hfc;
            4'h1 : seg1 = 8'h60;
            4'h2 : seg1 = 8'hda;
            4'h3 : seg1 = 8'hf2;
            4'h4 : seg1 = 8'h66;
            4'h5 : seg1 = 8'hb6;
            4'h6 : seg1 = 8'hbe;
            4'h7 : seg1 = 8'he0;
            4'h8 : seg1 = 8'hfe;
            4'h9 : seg1 = 8'hf6;
            4'ha : seg1 = 8'hee;
            4'hb : seg1 = 8'h3e;
            4'hc : seg1 = 8'h9c;
            4'hd : seg1 = 8'h7a;
            4'he : seg1 = 8'h9e;
            4'hf : seg1 = 8'h8e;
        endcase
    end
endmodule
