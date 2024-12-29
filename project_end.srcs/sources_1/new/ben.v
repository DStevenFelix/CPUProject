`timescale 1ns / 1ps

module ban(
    input wire clk,
    input wire rst,         // ȫ�ָ�λ�ź�

    input wire[2:0] SW,          // ���뿪���ź�
    input wire[223:0] rf_data,   // �Ĵ����ļ�����

    output [7:0] seg_o,   // �߶��������ʾ
    output [7:0] seg1_o,  // �ڶ����߶��������ʾ
    output [7:0] an_o     // �����λѡ�ź�
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

    // ��Ƶ��
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

    // ���ݲ��뿪�أ�SW����״̬ѡ����ʾ�ļĴ���
    always @(*) begin
        case(SW)         
            3'b000: dsp = rf_data[31:0]; //1�żĴ���
            3'b001: dsp = rf_data[63:32]; //2�żĴ���
            3'b010: dsp = rf_data[95:64]; //3�żĴ���
            3'b011: dsp = rf_data[127:96]; //4�żĴ���
            3'b100: dsp = rf_data[158:128]; //5�żĴ���
            3'b101: dsp = rf_data[191:159]; //6�żĴ���
            3'b110: dsp = rf_data[207:192]; //7�żĴ���
            3'b111: dsp = 16'hffff; // Ĭ��ֵ��δ����Ĵ���
            default: dsp = 16'hffff; // ��ֹ�ۺ�����
        endcase
    end  
    
    reg[2:0] disp_bit = 0; // ��ǰλ��
    reg[3:0] disp_dat = 0; // ��ǰλ������
     
    // ����ܶ�̬��ʾλѡ�߼�
    always @(posedge div_clk) begin
        if (disp_bit >= 7)
            disp_bit <= 0;
        else
            disp_bit <= disp_bit + 1'b1;

        case (disp_bit)
            3'b000 :
            begin
                disp_dat <= dsp[3:0];
                an <= 8'b00000001; // �����һλ
            end
            3'b001 :
            begin
                disp_dat <= dsp[7:4];
                an <= 8'b00000010; // ����ڶ�λ
            end
            3'b010 :
            begin
                disp_dat <= dsp[11:8];
                an <= 8'b00000100; // �������λ
            end
            3'b011 :
            begin
                disp_dat <= dsp[15:12];
                an <= 8'b00001000; // �������λ
            end
            3'b100 :
            begin
                disp_dat <= dsp[19:16];
                an <= 8'b00010000; // �������λ
            end
            3'b101 :
            begin
                disp_dat <= dsp[23:20];
                an <= 8'b00100000; // �������λ
            end
            3'b110 :
            begin
                disp_dat <= dsp[27:24];
                an <= 8'b01000000; // �������λ
            end
            3'b111 :
            begin
                disp_dat <= dsp[31:28];
                an <= 8'b10000000; // ����ڰ�λ
            end
            default:
            begin
                disp_dat <= 0;
                an <= 8'b00000000;
            end
        endcase
    end
    
    // �߶��������ʾ�߼�
    always @(disp_dat) begin
        case (disp_dat)
            // ��ʾ 0-F ������
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
        // ͬ��Ϊ�ڶ�������ܸ�ֵ
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
