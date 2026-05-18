`timescale 1ns / 1ps

// I2C Master V2 (변경 없음)
module i2c_master_v2(
    input clk, reset_p,
    input [6:0] addr,
    input [7:0] tx_data,
    input rd_wr, 
    input start,
    output reg busy, done,
    output reg [7:0] rx_data,
    output scl,
    inout sda
);
    parameter CLK_FREQ = 100_000_000;
    parameter I2C_FREQ = 100_000;
    localparam QUARTER = CLK_FREQ / (I2C_FREQ * 4);

    reg [15:0] clk_cnt;
    reg [3:0] bit_cnt;
    reg [3:0] state;
    reg [7:0] addr_sh, data_sh;
    reg sda_out, sda_en, scl_reg;

    assign sda = sda_en ? sda_out : 1'bz;
    assign scl = scl_reg;

    localparam IDLE=0, START=1, ADDR_RW=2, ACK1=3, DATA=4, ACK2=5, STOP=6;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            state <= IDLE; busy <= 0; done <= 0;
            scl_reg <= 1; sda_en <= 1; sda_out <= 1;
            clk_cnt <= 0; 
        end else begin
            case(state)
                IDLE: begin
                    done <= 0;
                    if(start) begin
                        busy <= 1;
                        addr_sh <= {addr, rd_wr};
                        data_sh <= tx_data;
                        state <= START;
                        clk_cnt <= 0;
                    end else busy <= 0;
                end
                START: begin
                    if(clk_cnt == QUARTER)   begin sda_out <= 0; end
                    if(clk_cnt == QUARTER*2) begin scl_reg <= 0; state <= ADDR_RW; clk_cnt <= 0; bit_cnt <= 7; end
                    else clk_cnt <= clk_cnt + 1;
                end
                ADDR_RW: begin
                    if(clk_cnt == 0) begin sda_en <= 1; sda_out <= addr_sh[bit_cnt]; end
                    if(clk_cnt == QUARTER)   scl_reg <= 1;
                    if(clk_cnt == QUARTER*3) scl_reg <= 0;
                    if(clk_cnt == QUARTER*4) begin
                        clk_cnt <= 0;
                        if(bit_cnt == 0) state <= ACK1;
                        else bit_cnt <= bit_cnt - 1;
                    end else clk_cnt <= clk_cnt + 1;
                end
                ACK1: begin
                    if(clk_cnt == 0)         sda_en <= 0;
                    if(clk_cnt == QUARTER)   scl_reg <= 1;
                    if(clk_cnt == QUARTER*3) scl_reg <= 0;
                    if(clk_cnt == QUARTER*4) begin
                        clk_cnt <= 0; bit_cnt <= 7; state <= DATA;
                    end else clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    if(rd_wr) begin
                        if(clk_cnt == 0) sda_en <= 0;
                        if(clk_cnt == QUARTER*2) rx_data[bit_cnt] <= sda;
                    end else begin
                        if(clk_cnt == 0) begin sda_en <= 1; sda_out <= data_sh[bit_cnt]; end
                    end
                    if(clk_cnt == QUARTER)   scl_reg <= 1;
                    if(clk_cnt == QUARTER*3) scl_reg <= 0;
                    if(clk_cnt == QUARTER*4) begin
                        clk_cnt <= 0;
                        if(bit_cnt == 0) state <= ACK2;
                        else bit_cnt <= bit_cnt - 1;
                    end else clk_cnt <= clk_cnt + 1;
                end
                ACK2: begin
                    if(clk_cnt == 0) begin
                        if(rd_wr) begin sda_en <= 1; sda_out <= 1; end
                        else sda_en <= 0;
                    end
                    if(clk_cnt == QUARTER)   scl_reg <= 1;
                    if(clk_cnt == QUARTER*3) scl_reg <= 0;
                    if(clk_cnt == QUARTER*4) begin
                        clk_cnt <= 0; state <= STOP;
                    end else clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    if(clk_cnt == 0)         begin sda_en <= 1; sda_out <= 0; end
                    if(clk_cnt == QUARTER)   scl_reg <= 1;
                    if(clk_cnt == QUARTER*2) begin sda_out <= 1; end
                    if(clk_cnt == QUARTER*4) begin done <= 1; state <= IDLE; end
                    else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule



module i2c_mpu9250(
    input clk, reset_p,
    output scl,
    inout sda,
    output reg signed [15:0] ax, ay, az,
    output reg data_valid
);
    reg [6:0] mpu_addr = 7'h68;
    reg [7:0] tx_data_reg;
    reg [6:0] i2c_addr_reg;
    reg rd_wr_reg, start_reg;
    wire busy, done;
    wire [7:0] rx_data;

    i2c_master_v2 U_master(
        .clk(clk), .reset_p(reset_p),
        .addr(i2c_addr_reg), .tx_data(tx_data_reg),
        .rd_wr(rd_wr_reg), .start(start_reg),
        .busy(busy), .done(done), .rx_data(rx_data),
        .scl(scl), .sda(sda)
    );

    reg [3:0] state;
    reg [7:0] xh, xl, yh, yl, zh;
    reg [19:0] wait_cnt;

    localparam IDLE=0, WAKEUP_REG=1, WAKEUP_VAL=2, SET_ADDR=3,
               READ_XH=4, READ_XL=5, READ_YH=6, READ_YL=7,
               READ_ZH=8, READ_ZL=9, PARSE=10, WAIT=11;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            state <= IDLE; start_reg <= 0; data_valid <= 0; wait_cnt <= 0;
            ax <= 0; ay <= 0; az <= 0;
            xh <= 0; xl <= 0; yh <= 0; yl <= 0; zh <= 0;
        end else begin
            start_reg  <= 0;
            data_valid <= 0;

            case(state)
                IDLE: state <= WAKEUP_REG;

                // [1] PWR_MGMT_1 레지스터 주소 전송
                WAKEUP_REG: if(!busy) begin
                    i2c_addr_reg <= mpu_addr;
                    tx_data_reg  <= 8'h6B;
                    rd_wr_reg    <= 0;
                    start_reg    <= 1;
                    state        <= WAKEUP_VAL;
                end

                // [2] 0x00 전송 → 슬립 해제
                WAKEUP_VAL: if(done) begin
                    i2c_addr_reg <= mpu_addr;
                    tx_data_reg  <= 8'h00;
                    rd_wr_reg    <= 0;
                    start_reg    <= 1;
                    state        <= SET_ADDR;
                end

                // [3] 가속도 시작 레지스터 0x3B 지정
                SET_ADDR: if(done) begin
                    i2c_addr_reg <= mpu_addr;
                    tx_data_reg  <= 8'h3B;
                    rd_wr_reg    <= 0;
                    start_reg    <= 1;
                    state        <= READ_XH;
                end

                // [4] 읽기 시퀀스 - done 시점에 해당 바이트 저장 후 다음 읽기 시작
                READ_XH: if(done) begin
                    xh           <= rx_data;
                    i2c_addr_reg <= mpu_addr;
                    rd_wr_reg    <= 1;
                    start_reg    <= 1;
                    state        <= READ_XL;
                end

                READ_XL: if(done) begin
                    xl           <= rx_data;
                    i2c_addr_reg <= mpu_addr;
                    rd_wr_reg    <= 1;
                    start_reg    <= 1;
                    state        <= READ_YH;
                end

                READ_YH: if(done) begin
                    yh           <= rx_data;
                    i2c_addr_reg <= mpu_addr;
                    rd_wr_reg    <= 1;
                    start_reg    <= 1;
                    state        <= READ_YL;
                end

                READ_YL: if(done) begin
                    yl           <= rx_data;
                    i2c_addr_reg <= mpu_addr;
                    rd_wr_reg    <= 1;
                    start_reg    <= 1;
                    state        <= READ_ZH;
                end

                READ_ZH: if(done) begin
                    zh           <= rx_data;
                    i2c_addr_reg <= mpu_addr;
                    rd_wr_reg    <= 1;
                    start_reg    <= 1;
                    state        <= READ_ZL;
                end

                READ_ZL: if(done) begin
                    state <= PARSE;
                end

                // [5] 조합 - rx_data는 READ_ZL done 직후라 zl값 유효
                PARSE: begin
                    ax         <= {xh, xl};
                    ay         <= {yh, yl};
                    az         <= {zh, rx_data};
                    data_valid <= 1;
                    wait_cnt   <= 0;
                    state      <= WAIT;
                end

                // [6] 대기 후 SET_ADDR부터 재측정 (WAKEUP은 한 번만)
                WAIT: begin
                    if(wait_cnt >= 200000) begin
                        wait_cnt <= 0;
                        if(!busy) begin
                            i2c_addr_reg <= mpu_addr;
                            tx_data_reg  <= 8'h3B;
                            rd_wr_reg    <= 0;
                            start_reg    <= 1;
                            state        <= READ_XH;
                        end
                    end else wait_cnt <= wait_cnt + 1;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule