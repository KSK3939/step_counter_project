`timescale 1ns / 1ps

module step_counter_cntr(
    input clk, reset_p,
    input signed [15:0] ax,
    input signed [15:0] ay,
    input signed [15:0] az,
    input data_valid,
    input [31:0] high_th,
    input [31:0] low_th,
    input [31:0] min_step_samples,
    input [4:0] base_shift,
    input [31:0] calib_samples,
    
    output [33:0] motion,
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
    
    reg signed [31:0] x_base;
    reg signed [31:0] y_base;
    reg signed [31:0] z_base;
    
    wire signed [31:0] ax_ext;
    wire signed [31:0] ay_ext;
    wire signed [31:0] az_ext;
    
    wire signed [31:0] x_diff;
    wire signed [31:0] y_diff;
    wire signed [31:0] z_diff;
    
    wire [31:0] abs_x;
    wire [31:0] abs_y;
    wire [31:0] abs_z;
    
    reg [31:0] cooldown_cnt;
    reg armed;
    
    reg initialized;
    reg [31:0] calib_cnt;
    
    assign ax_ext = {{16{ax[15]}}, ax};
    assign ay_ext = {{16{ay[15]}}, ay};
    assign az_ext = {{16{az[15]}}, az};
    
    assign x_diff = ax_ext - x_base;
    assign y_diff = ay_ext - y_base;
    assign z_diff = az_ext - z_base;
    
    assign abs_x = x_diff[31] ? (~x_diff + 1'b1) : x_diff;
    assign abs_y = y_diff[31] ? (~y_diff + 1'b1) : y_diff;
    assign abs_z = z_diff[31] ? (~z_diff + 1'b1) : z_diff;
    
    wire [33:0] motion_level;
    
    assign motion_level = {2'b00, abs_x} + {2'b00, abs_y} + {2'b00, abs_z};
    assign motion = motion_level;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            x_base <= 32'sd0;
            y_base <= 32'sd0;
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
                    x_base <= ax_ext;
                    y_base <= ay_ext;
                    z_base <= az_ext;
                    initialized <= 1'b1;
                    calib_cnt <= 32'd0;
                    armed <= 1'b1;
                end
                else if(calib_cnt < calib_samples) begin
                    x_base <= x_base + (x_diff >>> base_shift);
                    y_base <= y_base + (y_diff >>> base_shift);
                    z_base <= z_base + (z_diff >>> base_shift);
                    calib_cnt <= calib_cnt + 1'b1;
                end
                else begin
                    x_base <= x_base + (x_diff >>> base_shift);
                    y_base <= y_base + (y_diff >>> base_shift);
                    z_base <= z_base + (z_diff >>> base_shift);
                    
                    if(cooldown_cnt > 0) begin
                        cooldown_cnt <= cooldown_cnt - 1'b1;
                    end
                    
                    if(!armed) begin
                        if(motion_level < low_th) begin
                            armed <= 1'b1;
                        end
                    end
                    
                    else begin
                        if((motion_level > high_th) && (cooldown_cnt == 0)) begin
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
