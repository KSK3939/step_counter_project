`timescale 1ns / 1ps

module step_counter_cntr(
    input clk, reset_p,
    input signed [15:0] az,
    input data_valid,
    input [31:0] high_th,
    input [31:0] low_th,
    input [31:0] min_step_samples,
    input [4:0] base_shift,
    input [31:0] calib_samples,
    
    
    output reg [31:0] step_count,
    output reg [31:0] distance,
    output reg step_pulse
    );
    
//    parameter HIGH_TH = 350; // maxium change
//    parameter LOW_TH = 120;  // minimum change
//    parameter MIN_STEP_SAMPLES = 40; // 100Hz -> 0.3s
    parameter STRIDE_CM = 70; // average distance per step = 70cm
//    parameter BASE_SHIFT = 5; // average speed
//    parameter CALIB_SAMPLES = 100; // 
    
    reg signed [31:0] z_base;
    wire signed [31:0] az_ext;
    wire signed [31:0] z_diff;
    wire [31:0] abs_diff;
    
    reg [31:0] cooldown_cnt;
    reg armed;
    
    reg initialized;
    reg [31:0] calib_cnt;
    
    assign az_ext = {{16{az[15]}}, az};
    assign z_diff = az_ext - z_base;
    assign abs_diff = z_diff[31] ? (~z_diff + 1'b1) : z_diff;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            z_base <= 32'sd0;
            
            step_count <= 32'd0;
            distance <= 32'd0;
            step_pulse <= 1'b0;
            
            cooldown_cnt <= 32'd0;
            armed <= 1'b1;
            
            initialized <= 1'b0;
            calib_cnt <= 16'd0;
        end
        else begin
            step_pulse <= 1'b0;
            
            if(data_valid) begin
                if(!initialized) begin
                    z_base <= az_ext;
                    initialized <= 1'b1;
                    calib_cnt <= 16'd0;
                    armed <= 1'b1;
                end
                else if(calib_cnt < calib_samples) begin
                    z_base <= z_base + (z_diff >>> base_shift);
                    calib_cnt <= calib_cnt + 1'b1;
                end
                else begin
                    z_base <= z_base + (z_diff >>> base_shift);
                    
                    if(cooldown_cnt > 0) begin
                        cooldown_cnt <= cooldown_cnt - 1'b1;
                    end
                    
                    if(!armed) begin
                        if(abs_diff < low_th) begin
                            armed <= 1'b1;
                        end
                    end
                    
                    else begin
                        if((abs_diff > high_th) && (cooldown_cnt == 0)) begin
                            step_count <= step_count + 1'b1;
                            distance <= distance + STRIDE_CM;
                            step_pulse <= 1'b1;
                            
                            armed <= 1'b0;
                            cooldown_cnt <= min_step_samples;
                        end
                    end
                end
            end
        end
    end
    
endmodule
