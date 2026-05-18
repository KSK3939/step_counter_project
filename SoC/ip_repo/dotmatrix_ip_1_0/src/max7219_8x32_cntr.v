`timescale 1ns / 1ps

module max7219_8x32_cntr(
    input clk, reset_p,
    input init,
    input update,
    input clear,
    
    input [15:0] num,
    
    output reg max_din,
    output reg max_cs,
    output reg max_csk,
    
    output reg busy,
    output reg done,
    output reg init_done
    );
    parameter CLK_DIV = 50;
    // state
    localparam OP_NONE = 2'd0; // nothing
    localparam OP_INIT = 2'd1; // initialize
    localparam OP_UPDATE = 2'd2; // update
    localparam OP_CLEAR = 2'd3; // clear
    
    reg [1:0] op;
    
    // dataflow
    localparam S_IDLE = 3'd0; // idle
    localparam S_LOAD = 3'd1; // ready
    localparam S_LOW = 3'd2; // low, din ready
    localparam S_HIGH = 3'd3; // high, din done
    localparam S_LATCH = 3'd4; // latch, cs high
    localparam S_NEXT = 3'd5; // next row
    localparam S_DONE = 3'd6; // done
    
    reg [2:0] state;
    
    reg [63:0] tx_shift; // shift register
    wire [63:0] tx_packet; // whole data
    reg [5:0] cnt; // counter
    reg [15:0] div_cnt; // div counter
        
    reg [3:0] cmd_idx; // present row
    reg last_cmd; // is it last? flag
    
    reg [7:0] addr; // address
    reg [7:0] data0; // data 0
    reg [7:0] data1; // data 1
    reg [7:0] data2; // data 2
    reg [7:0] data3; // data 3
    
    reg [7:0] init_data; // data for initialize
    
    wire init_nedge;
    wire update_nedge;
    wire clear_nedge;
    
    wire init_pedge;
    wire update_pedge;
    wire clear_pedge;
   
    wire [3:0] digit3;
    wire [3:0] digit2;
    wire [3:0] digit1;
    wire [3:0] digit0;
    
    wire [15:0] bcd_num;
    
    assign bcd_num = (num / 1000 << 12) | (num % 1000 / 100 << 8) | (num % 100 / 10 << 4) | (num % 10); 
    
//    bin_to_dec btd(
//    .bin(num),
//    .bcd(bcd_num));
    
    assign digit3 = bcd_num[15:12];
    assign digit2 = bcd_num[11:8];
    assign digit1 = bcd_num[7:4];
    assign digit0 = bcd_num[3:0];
    
    reg [7:0] number [0:9][0:7];
    
    initial begin
        number[0][0] = 8'h3C; number[0][1] = 8'h7E; number[0][2] = 8'h66; number[0][3] = 8'h66;
        number[0][4] = 8'h66; number[0][5] = 8'h66; number[0][6] = 8'h7E; number[0][7] = 8'h3C;
        
        number[1][0] = 8'h18; number[1][1] = 8'h18; number[1][2] = 8'h18; number[1][3] = 8'h18;
        number[1][4] = 8'h18; number[1][5] = 8'h18; number[1][6] = 8'h18; number[1][7] = 8'h18;
        
        number[2][0] = 8'h3C; number[2][1] = 8'h7E; number[2][2] = 8'h66; number[2][3] = 8'h66;
        number[2][4] = 8'h0C; number[2][5] = 8'h18; number[2][6] = 8'h3E; number[2][7] = 8'h7E;
        
        number[3][0] = 8'h3c; number[3][1] = 8'h3e; number[3][2] = 8'h06; number[3][3] = 8'h1c;
        number[3][4] = 8'h1c; number[3][5] = 8'h06; number[3][6] = 8'h3e; number[3][7] = 8'h3c;
    
        number[4][0] = 8'h06; number[4][1] = 8'h0e; number[4][2] = 8'h1e; number[4][3] = 8'h36;
        number[4][4] = 8'h66; number[4][5] = 8'h7f; number[4][6] = 8'h7f; number[4][7] = 8'h06;
    
        number[5][0] = 8'h7e; number[5][1] = 8'h7e; number[5][2] = 8'h60; number[5][3] = 8'h7c;
        number[5][4] = 8'h7e; number[5][5] = 8'h06; number[5][6] = 8'h7e; number[5][7] = 8'h7c;
    
        number[6][0] = 8'h3c; number[6][1] = 8'h7e; number[6][2] = 8'h66; number[6][3] = 8'h60;
        number[6][4] = 8'h7c; number[6][5] = 8'h66; number[6][6] = 8'h7e; number[6][7] = 8'h3c;
    
        number[7][0] = 8'h7e; number[7][1] = 8'h7e; number[7][2] = 8'h06; number[7][3] = 8'h0c;
        number[7][4] = 8'h18; number[7][5] = 8'h18; number[7][6] = 8'h18; number[7][7] = 8'h18;
    
        number[8][0] = 8'h3c; number[8][1] = 8'h7e; number[8][2] = 8'h66; number[8][3] = 8'h3c;
        number[8][4] = 8'h3c; number[8][5] = 8'h66; number[8][6] = 8'h7e; number[8][7] = 8'h3c;
    
        number[9][0] = 8'h3c; number[9][1] = 8'h7e; number[9][2] = 8'h66; number[9][3] = 8'h7e;
        number[9][4] = 8'h3e; number[9][5] = 8'h06; number[9][6] = 8'h3e; number[9][7] = 8'h3c;
    end

    edge_detector_p init_edge (
        .clk(clk), .reset_p(reset_p),
        .cp(init),
        .p_edge(init_pedge), .n_edge(init_nedge));
    
    edge_detector_p update_edge (
        .clk(clk), .reset_p(reset_p),
        .cp(update),
        .p_edge(update_pedge), .n_edge(update_nedge));
        
    edge_detector_p clear_edge (
        .clk(clk), .reset_p(reset_p),
        .cp(clear),
        .p_edge(clear_pedge), .n_edge(clear_nedge));
        
    always @(*) begin
        addr = 8'h00;
        init_data = 8'h00;
        data0 = 8'h00;
        data1 = 8'h00;
        data2 = 8'h00;
        data3 = 8'h00;
        
        
        last_cmd = 1'b1;
        
        case(op)
            OP_INIT : begin
                last_cmd = (cmd_idx == 4'd4);
                case(cmd_idx)
                    4'd0 : begin
                        addr = 8'h0F;
                        init_data = 8'h00;
                    end
                    4'd1 : begin
                        addr = 8'h09;
                        init_data = 8'h00;
                    end
                    4'd2 : begin
                        addr = 8'h0B;
                        init_data = 8'h07;
                    end
                    4'd3 : begin
                        addr = 8'h0A;
                        init_data = 8'h01;
                    end
                    4'd4 : begin
                        addr = 8'h0C;
                        init_data = 8'h01;
                    end
                endcase
                
                data3 = init_data;
                data2 = init_data;
                data1 = init_data;
                data0 = init_data;
            end
            
            OP_UPDATE : begin
                addr = {5'b00000, cmd_idx[2:0]} + 8'h01;
                last_cmd = (cmd_idx == 4'd7);
                
                data3 = (digit3 <= 4'd9) ? number[digit3][cmd_idx[2:0]] : 8'h00;
                data2 = (digit2 <= 4'd9) ? number[digit2][cmd_idx[2:0]] : 8'h00;
                data1 = (digit1 <= 4'd9) ? number[digit1][cmd_idx[2:0]] : 8'h00;
                data0 = (digit0 <= 4'd9) ? number[digit0][cmd_idx[2:0]] : 8'h00;
            end
            
            OP_CLEAR : begin
                addr = {5'b00000, cmd_idx[2:0]} + 8'h01;
                last_cmd = (cmd_idx == 4'd7);
                
                data3 = 8'h00;
                data2 = 8'h00;
                data1 = 8'h00;
                data0 = 8'h00;
            end
        endcase
    end
    
    assign tx_packet = {
        addr, data3,
        addr, data2,
        addr, data1,
        addr, data0
    };
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            op <= OP_NONE;
            state <= S_IDLE;
            tx_shift <= 64'd0;
            cnt <= 6'd0;
            div_cnt <= 16'd0;
            
            max_din <= 1'b0;
            max_cs <= 1'b1;
            max_csk <= 1'b0;
            
            busy <= 1'b0;
            done <= 1'b0;
            init_done <= 1'b0;
        end
        else begin
            done <= 1'b0;
            
            case(state)
                S_IDLE : begin
                    max_csk <= 1'b0;
                    max_cs <= 1'b1;
                    busy <= 1'b0;
                    div_cnt <= 16'd0;
                    
                    if(init_pedge) begin
                        op <= OP_INIT;
                        cmd_idx <= 4'd0;
                        busy <= 1'b1;
                        state <= S_LOAD;
                    end
                        
                    else if(clear_pedge) begin
                         op <= OP_CLEAR;
                         cmd_idx <= 4'd0;
                         busy <= 1'b1;
                         state <= S_LOAD;
                    end
                    else if(update_pedge) begin
                        op <= OP_UPDATE;
                        cmd_idx <= 4'd0;
                        busy <= 1'b1;
                        state <= S_LOAD;
                    end
                end
                
                S_LOAD : begin
                    tx_shift <= tx_packet;
                    cnt <= 6'd63;
                    div_cnt <= 16'd0;
                    
                    max_cs <= 1'b0;
                    max_csk <= 1'b0;
                    max_din <= tx_packet[63];
                    
                    busy <= 1'b1;
                    state <= S_LOW;
                end
                
                S_LOW : begin
                    if(div_cnt >= CLK_DIV - 1) begin
                        div_cnt <= 16'd0;
                        max_csk <= 1'b1;
                        state <= S_HIGH;
                    end
                 
                    else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end
                
                S_HIGH : begin
                    if(div_cnt >= CLK_DIV - 1) begin
                        div_cnt <= 16'd0;
                        max_csk <= 0;

                        
                        if(cnt == 6'd0) begin
                            state <= S_LATCH;
                        end
                        else begin
                            max_din <= tx_shift[62];
                            tx_shift <= {tx_shift[62:0] , 1'b0};
                            cnt <= cnt - 1'b1;
                            state <= S_LOW;
                        end
                    end
                    else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end
                
                S_LATCH : begin
                    max_cs = 1'b1;
                    max_csk = 1'b0;
                    div_cnt = 16'd0;
                    state = S_NEXT;
                end
                
                S_NEXT : begin
                    max_cs = 1'b1;
                    max_csk = 1'b0;
                    if(div_cnt >= CLK_DIV - 1) begin
                        if(last_cmd) begin
                            state <= S_DONE;
                        end
                        else begin
                            cmd_idx <= cmd_idx + 1;
                            state <= S_LOAD;
                        end
                    end
                    else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end
                
                S_DONE : begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    max_cs <= 1'b1;
                    max_csk <= 1'b0;
                    
                    if(op == OP_INIT) begin
                        init_done <= 1'b1;
                    end
                    
                    op <= OP_NONE;
                    state <= S_IDLE;
                end 
            endcase
        end
    end

endmodule
