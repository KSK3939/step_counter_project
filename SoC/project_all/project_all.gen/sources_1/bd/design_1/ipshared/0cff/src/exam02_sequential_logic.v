`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2025 02:06:39 PM
// Design Name: 
// Module Name: exam02_sequential_logic
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

module D_flip_flop_n(
    input d, 
    input clk, reset_p, en,
    output reg q);
    
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)q = 0;
        else if(en)q = d;
        
    end

endmodule

module D_flip_flop_p(
    input d, 
    input clk, reset_p, en,
    output reg q);
    
    always @(posedge clk)begin
        if(reset_p)q = 0;
        else if(en)q = d;
    end

endmodule

module T_flip_flop_n(
    input clk, reset_p,
    input en,
    input t,
    output reg q);
    
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)q = 0;
        else if(en & t) q = ~q;
    end
endmodule
module T_flip_flop_p(
    input clk, reset_p, en, t,
    output reg q, qbar);
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            q = 0;
            qbar = 1;
        end
        else if(en & t) begin
            q = ~q;
            qbar = ~q;
        end
    end
endmodule

module up_counter_asyc(
    input clk, reset_p,
    output [3:0] count);

    T_flip_flop_n cnt0(.clk(clk), .reset_p(reset_p), .en(1), .t(1), .q(count[0]));
    T_flip_flop_n cnt1(.clk(count[0]), .reset_p(reset_p), .en(1), .t(1), .q(count[1]));
    T_flip_flop_n cnt2(.clk(count[1]), .reset_p(reset_p), .en(1), .t(1), .q(count[2]));
    T_flip_flop_n cnt3(.clk(count[2]), .reset_p(reset_p), .en(1), .t(1), .q(count[3]));

endmodule

module down_counter_asyc(
    input clk, reset_p,
    output [3:0] count);

    T_flip_flop_p cnt0(.clk(clk), .reset_p(reset_p), .en(1), .t(1), .q(count[0]));
    T_flip_flop_p cnt1(.clk(count[0]), .reset_p(reset_p), .en(1), .t(1), .q(count[1]));
    T_flip_flop_p cnt2(.clk(count[1]), .reset_p(reset_p), .en(1), .t(1), .q(count[2]));
    T_flip_flop_p cnt3(.clk(count[2]), .reset_p(reset_p), .en(1), .t(1), .q(count[3]));

endmodule

module up_counter_p(
    input clk, reset_p,
    output reg [3:0] count);

    always @(posedge clk, posedge reset_p)begin
        if(reset_p)count = 0;
        else count = count + 1;
    end

endmodule

module down_counter_p(
    input clk, reset_p,
    output reg [3:0] count);
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)count = 4'b1111;
        else count = count - 1;
    end

endmodule
module down_counter_n(
    input clk, reset_p,
    output reg [3:0] count);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)count = 4'b1111;
        else count = count - 1;
    end

endmodule

module ring_counter(
    input clk, reset_p,
    output reg [3:0] q);

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)q = 4'b0001;
        else begin
//            case(q)
//                4'b0001 : q = 4'b0010;
//                4'b0010 : q = 4'b0100;
//                4'b0100 : q = 4'b1000;
//                4'b1000 : q = 4'b0001;
//                default : q = 4'b0001;
//            endcase
//            if(q != 4'b0001 && q != 4'b0010 && q != 4'b0100 && q != 4'b1000) q = 4'b0001;
//            else q = {q[2:0], q[3]};
            if(q[0] + q[1] + q[2] + q[3] != 1) q = 4'b0001;
            else q = {q[2:0], q[3]};
        end
    end

endmodule

module ring_counter_led(
    input clk, reset_p,
    output reg [15:0] led);
    
    reg [31:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
        
    wire clk_div22_ed_p;    
    edge_detector_n edn(.clk(clk), .reset_p(reset_p),
                        .cp(clk_div[22]), .p_edge(clk_div22_ed_p));
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)led = 16'b0000_0000_0000_0001;
        else if(clk_div22_ed_p)led = {led[14:0], led[15]};
    end

endmodule

module edge_detector_n(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge);

    reg ff_cur, ff_old;
    
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)begin
            ff_cur <= 0;
            ff_old <= 0;
        end
        else begin
            ff_old <= ff_cur;
            ff_cur <= cp;
        end
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;

endmodule
module edge_detector_p(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge);

    reg ff_cur, ff_old;
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            ff_cur = 0;
            ff_old = 0;
        end
        else begin
            ff_old = ff_cur;
            ff_cur = cp;
        end
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;

endmodule

module ring_counter_led_flag(
    input clk, reset_p,
    output reg [15:0] led);
    
    reg [31:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    reg flag;
       
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            led = 16'b0000_0000_0000_0001;
            flag = 0;
        end
        else begin
            if(clk_div[22] && flag == 0)begin
                led = {led[14:0], led[15]};
                flag = 1;
            end
            if(clk_div[22] == 0)flag = 0;
        end
    end

endmodule

module SISO(
    input clk, reset_p,
    input d,
    input en,
    output f);

    reg [7:0] register_siso;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)register_siso = 0;
        else if(en)begin
            register_siso = {d, register_siso[7:1]};
        end
    end
    
    assign f = register_siso[0];

endmodule

module SIPO(
    input clk, reset_p,
    input d,
    input rd_en,
    output [7:0] q
);

    reg [7:0] register_sipo;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)register_sipo = 0;
        else register_sipo = {d, register_sipo[7:1]};
    end
    
    assign q = rd_en ? register_sipo : 8'bz;
    
endmodule

module PISO(
    input clk, reset_p,
    input [7:0] d,
    input shift_load,
    output q);
    
    reg [7:0] register_piso;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)register_piso = 0;
        else begin
            if(shift_load)register_piso = {1'b0, register_piso[7:1]};
            else register_piso = d;
        end
    end
    assign q = register_piso[0];
endmodule

module memory(
    input clk, reset_p,
    input [7:0] i_data,
    input [9:0] wr_addr, rd_addr,
    output reg [7:0] o_data);

    reg [7:0] ram [0:1023];
    always @(posedge clk)begin
        ram[wr_addr] = i_data;
        o_data = ram[rd_addr];
    end

endmodule

module memory_one_addr_bus(
    input clk, reset_p,
    input [7:0] i_data,
    input wr_rd,
    input [9:0] addr,
    output reg [7:0] o_data);

    reg [7:0] ram [0:1023];
    always @(posedge clk)begin
        if(wr_rd)ram[addr] = i_data;
        else o_data = ram[addr];
    end

endmodule












