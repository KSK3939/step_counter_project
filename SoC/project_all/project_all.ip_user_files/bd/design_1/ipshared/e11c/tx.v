`timescale 1ns / 1ps


module uart_tx_core(
    input wire clk,
    input wire rst,
    input wire [7:0] tx_data,
    input wire tx_start,
    input wire [31:0] baud_div,
    output reg tx,
    output reg tx_busy,
    output reg tx_done
    );
    
    localparam IDLE = 2'd0;
    localparam START = 2'd1;
    localparam DATA = 2'd2;
    localparam STOP = 2'd3;
    
    reg [1:0] state;
    reg [31:0] baud_cnt;
    reg [2:0] bit_idx;
    reg [7:0] data_buf;
    
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            state <= IDLE;
            baud_cnt <= 32'd0;
            bit_idx <= 3'd0;
            data_buf <= 8'd0;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            tx_done <= 1'b0;
            
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    baud_cnt <= 32'd0;
                    bit_idx <= 3'd0;
                
                
                if(tx_start) begin
                    state <= START;
                    tx_busy <= 1'b1;
                    data_buf <= tx_data;
                end
            end
            
                START: begin
                    tx <= 1'b0;
                    if(baud_cnt >= baud_div) begin
                        baud_cnt <= 32'd0;
                        state <= DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                DATA: begin
                    tx <= data_buf[bit_idx];
                    if(baud_cnt >= baud_div) begin
                        baud_cnt <= 32'd0;
                        if(bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                STOP: begin
                    tx <= 1'b1;
                    if(baud_cnt >= baud_div) begin
                        baud_cnt <= 32'b0;
                        state <= IDLE;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
