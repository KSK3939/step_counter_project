`timescale 1ns / 1ps

module rx_tb;
    reg clk;
    reg rst;
    reg rx;
    reg [31:0] baud_div;
    wire [7:0] rx_data;
    wire rx_busy;
    wire rx_done;
    wire rx_error;
    
    uart_rx_core dut(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .baud_div(baud_div),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done(rx_done),
        .rx_error(rx_error)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    integer BIT_CLKS;
    
    task send_bit;
        input bit_val;
        integer i;
        begin
            @(negedge clk);
            rx = bit_val;
            for(i = 0; i < BIT_CLKS; i = i + 1)
                @(negedge clk);
        end
    endtask
    
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            send_bit(1'b1);
            send_bit(1'b0);
            for(i = 0; i < 8; i = i + 1)
                send_bit(data[i]);
            
            send_bit(1'b1);
        end
    endtask
    
    task send_byte_with_bad_stop;
        input [7:0] data;
        integer i;
        begin
            send_bit(1'b1);
            send_bit(1'b0);
            for(i = 0; i < 8; i = i + 1)
                send_bit(data[i]);
            send_bit(1'b0);
        end
    endtask
    
    task false_start_pulse;
        integer i;
        begin
            @(negedge clk);
            rx = 1'b0;
            for(i = 0; i < 3; i = i +1)
                @(negedge clk);
            rx = 1'b1;
            for(i = 0; i < BIT_CLKS; i = i + 1)
                @(negedge clk);
        end
    endtask
    
    task check_done_pulse_one_cycle;
        begin
            @(posedge clk);
            #1;
            if(rx_done !== 1'b0)
                $display("[%0t] ERROR: rx_done is not 1-cycle pulse", $time);
            else
                $display("[%0t] OK: rx_done is 1-cycle pulse", $time);
        end
    endtask
    
    task line_idle;
        integer i;
        begin
            @(negedge clk);
            rx = 1'b1;
            for(i = 0; i < BIT_CLKS; i = i + 1)
                @(negedge clk);
        end
    endtask
    
    initial begin
        rx = 1'b1;
        rst = 1'b0;
        baud_div = 16;
        BIT_CLKS = baud_div + 1;
        
        repeat(5) @(negedge clk);
        rst = 1'b1;
        repeat(5) @(negedge clk);
        
        $display("\n[TEST 1] Normal receive 0xA5");
        fork
            send_byte(8'hA5);
            begin
                @(posedge rx_done);
                if(rx_data !== 8'hA5)
                    $display("[%0t] ERROR: rx_data = %h, expected = A5", $time, rx_data);
                else
                    $display("[%0t] OK: rx_data = %h", $time, rx_data);
                    
                if(rx_error !== 1'b0)
                    $display("[%0t] ERROR: rx_error asserted unexpectly", $time);
                else
                    $display("[%0t] OK: rx_error = 0", $time);
                
                check_done_pulse_one_cycle();
            end
        join
        
        repeat(10) @(negedge clk);
        
        $display("\n[TEST 2] Frame error (bad stop bit)");
        fork
            send_byte_with_bad_stop(8'h3C);
            begin
                @(posedge rx_error);
                $display("[%0t] OK: rx_error asserted", $time);
                
                if(rx_done !== 1'b0)
                    $display("[%0t] ERROR: rx_done should not assert on", $time);
            end
        join
        
        repeat(10) @(negedge clk);
        
        line_idle();
        $display("\n[TEST 3] False start noise");
        false_start_pulse();
        
        if(rx_done !== 1'b0 && rx_error !== 1'b0)
            $display("[%0t] ERROR: false start created unexpected event", $time);
        else
            $display("[%0t] OK: false start ignored", $time);
        
        repeat(10) @(negedge clk);
        
        line_idle();
        $display("\n[TEST 4] Back-to-back receive");
        fork
            send_byte(8'h55);
            begin
                @(posedge rx_done);
                if(rx_data !== 8'h55)
                    $display("[%0t] ERROR: first byte mismatch", $time);
                else
                    $display("[%0t] OK: first byte = %h", $time, rx_data);
           end
        join
        
        repeat(5) @(negedge clk);
        
        fork        
            send_byte(8'hC3);
            begin
                @(posedge rx_done);
                #1;
                if(rx_data !== 8'hC3)
                    $display("[%0t] ERROR: second byte mismatch", $time);
                else
                    $display("[%0t] OK: second byte = %h", $time, rx_data);
            end
        join
            repeat(5) @(negedge clk);
        $display("\nSimulation finished");
        $finish;
    end                
endmodule