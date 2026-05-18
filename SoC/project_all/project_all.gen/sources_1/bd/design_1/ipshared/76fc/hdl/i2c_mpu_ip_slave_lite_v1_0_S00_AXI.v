`timescale 1 ns / 1 ps

module myip_i2c_mpu6_slave_lite_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5
)
(
    // User ports
    output wire        scl,
    inout  wire        sda,
    output wire signed [15:0] ax, ay, az,   // ✅ signed 추가
    output wire        data_valid,

    input  wire        S_AXI_ACLK,
    input  wire        S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire [2:0]  S_AXI_AWPROT,
    input  wire        S_AXI_AWVALID,
    output wire        S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire        S_AXI_WVALID,
    output wire        S_AXI_WREADY,
    output wire [1:0]  S_AXI_BRESP,
    output wire        S_AXI_BVALID,
    input  wire        S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire [2:0]  S_AXI_ARPROT,
    input  wire        S_AXI_ARVALID,
    output wire        S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]  S_AXI_RRESP,
    output wire        S_AXI_RVALID,
    input  wire        S_AXI_RREADY
);

    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg  axi_awready, axi_wready, axi_bvalid;
    reg [1:0] axi_bresp;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg  axi_arready, axi_rvalid;
    reg [1:0] axi_rresp;

    localparam integer ADDR_LSB          = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 2;

    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4, slv_reg5, slv_reg6, slv_reg7;
    integer byte_index;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // ✅ localparam 값 중복 제거 - Write/Read 분리
    reg [1:0] state_write, state_read;
    localparam W_IDLE  = 2'b00;
    localparam W_ADDR  = 2'b01;
    localparam W_DATA  = 2'b10;
    localparam R_IDLE  = 2'b00;
    localparam R_ADDR  = 2'b01;
    localparam R_DATA  = 2'b10;

    // Write FSM
    always @(posedge S_AXI_ACLK) begin
        if(S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 0; axi_wready <= 0; axi_bvalid <= 0;
            axi_bresp   <= 0; axi_awaddr <= 0;
            state_write <= W_IDLE;
        end else begin
            case(state_write)
                W_IDLE: begin
                    axi_awready <= 1'b1;
                    axi_wready  <= 1'b1;
                    state_write <= W_ADDR;
                end
                W_ADDR: begin
                    if(S_AXI_AWVALID && S_AXI_AWREADY) begin
                        axi_awaddr <= S_AXI_AWADDR;
                        if(S_AXI_WVALID) begin
                            axi_awready <= 1'b1;
                            axi_bvalid  <= 1'b1;
                            state_write <= W_ADDR;
                        end else begin
                            axi_awready <= 1'b0;
                            state_write <= W_DATA;
                            if(S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                        end
                    end else begin
                        if(S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                    end
                end
                W_DATA: begin
                    if(S_AXI_WVALID) begin
                        state_write <= W_ADDR;
                        axi_bvalid  <= 1'b1;
                        axi_awready <= 1'b1;
                    end else begin
                        if(S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Register Write + HW 데이터 매핑
    always @(posedge S_AXI_ACLK) begin
        if(S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 0; slv_reg1 <= 0; slv_reg2 <= 0; slv_reg3 <= 0;
            slv_reg4 <= 0; slv_reg5 <= 0; slv_reg6 <= 0; slv_reg7 <= 0;
        end else begin
            // HW 데이터 실시간 반영 (reg1~4는 읽기 전용)
            slv_reg1 <= {31'b0, data_valid};
            slv_reg2 <= {{16{ax[15]}}, ax};   // Sign Extension
            slv_reg3 <= {{16{ay[15]}}, ay};
            slv_reg4 <= {{16{az[15]}}, az};

            if(S_AXI_WVALID) begin
                case((S_AXI_AWVALID) ?
                     S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] :
                     axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                    3'h0: for(byte_index=0; byte_index<=3; byte_index=byte_index+1)
                              if(S_AXI_WSTRB[byte_index])
                                  slv_reg0[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                    3'h5: for(byte_index=0; byte_index<=3; byte_index=byte_index+1)
                              if(S_AXI_WSTRB[byte_index])
                                  slv_reg5[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                    3'h6: for(byte_index=0; byte_index<=3; byte_index=byte_index+1)
                              if(S_AXI_WSTRB[byte_index])
                                  slv_reg6[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                    3'h7: for(byte_index=0; byte_index<=3; byte_index=byte_index+1)
                              if(S_AXI_WSTRB[byte_index])
                                  slv_reg7[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                    default: ;
                endcase
            end
        end
    end

    // Read FSM
    always @(posedge S_AXI_ACLK) begin
        if(S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0; axi_rvalid <= 1'b0;
            axi_rresp   <= 1'b0; state_read <= R_IDLE;
        end else begin
            case(state_read)
                R_IDLE: begin
                    state_read  <= R_ADDR;
                    axi_arready <= 1'b1;
                end
                R_ADDR: begin
                    if(S_AXI_ARVALID && S_AXI_ARREADY) begin
                        state_read  <= R_DATA;
                        axi_araddr  <= S_AXI_ARADDR;
                        axi_rvalid  <= 1'b1;
                        axi_arready <= 1'b0;
                    end
                end
                R_DATA: begin
                    if(S_AXI_RVALID && S_AXI_RREADY) begin
                        axi_rvalid  <= 1'b0;
                        axi_arready <= 1'b1;
                        state_read  <= R_ADDR;
                    end
                end
            endcase
        end
    end

    // AXI Read Data 선택
    assign S_AXI_RDATA =
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h0) ? slv_reg0 :
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h1) ? slv_reg1 :
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h2) ? slv_reg2 :
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h3) ? slv_reg3 :
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h4) ? slv_reg4 :
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h5) ? slv_reg5 :
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h6) ? slv_reg6 :
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h7) ? slv_reg7 : 32'b0;

    // User Logic
    i2c_mpu9250 u_i2c_mpu9250(
        .clk(S_AXI_ACLK),
        .reset_p(~S_AXI_ARESETN),
        .scl(scl),
        .sda(sda),
        .ax(ax),
        .ay(ay),
        .az(az),
        .data_valid(data_valid)
    );

endmodule