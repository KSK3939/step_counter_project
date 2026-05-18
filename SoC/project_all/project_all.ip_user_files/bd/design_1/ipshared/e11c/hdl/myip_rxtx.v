`timescale 1ns / 1ps

module myip_v1_0 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
)(
    // AXI Lite slave 포트
    input  wire        s00_axi_aclk,
    input  wire        s00_axi_aresetn,
    input  wire [3:0]  s00_axi_awaddr,
    input  wire [2:0]  s00_axi_awprot,
    input  wire        s00_axi_awvalid,
    output wire        s00_axi_awready,
    input  wire [31:0] s00_axi_wdata,
    input  wire [3:0]  s00_axi_wstrb,
    input  wire        s00_axi_wvalid,
    output wire        s00_axi_wready,
    output wire [1:0]  s00_axi_bresp,
    output wire        s00_axi_bvalid,
    input  wire        s00_axi_bready,
    input  wire [3:0]  s00_axi_araddr,
    input  wire [2:0]  s00_axi_arprot,
    input  wire        s00_axi_arvalid,
    output wire        s00_axi_arready,
    output wire [31:0] s00_axi_rdata,
    output wire [1:0]  s00_axi_rresp,
    output wire        s00_axi_rvalid,
    input  wire        s00_axi_rready,

    // UART 외부 핀
    output wire uart_tx,
    input  wire uart_rx
);

    // 내부 연결 신호
    wire [7:0]  tx_data_out;
    wire        tx_start;
    wire [31:0] baud_div;
    wire        tx_busy;
    wire        tx_done;

    wire [7:0]  rx_data;
    wire        rx_done;
    wire        rx_busy;
    wire        rx_error;
    
//    wire uart_tx_int;
//    wire uart_rx_sel;
    
//    localparam LOOPBACK_EN = 1'b0;
//    assign uart_rx_sel = (LOOPBACK_EN) ? uart_tx_int : uart_rx;
    
//    assign uart_tx = uart_tx_int;

    // AXI Slave 인스턴스
    myip_slave_lite_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) u_axi_slave (
        // User 포트
        .tx_data_out  (tx_data_out),
        .tx_start     (tx_start),
        .baud_div_out (baud_div),
        .tx_busy      (tx_busy),
        .tx_done      (tx_done),
        // RX 추가 포트 (slave 수정 후)
        .rx_data_in   (rx_data),
        .rx_done      (rx_done),
        .rx_busy      (rx_busy),
        .rx_error     (rx_error),
        // AXI 버스
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready)
    );

    // TX 코어 인스턴스
    uart_tx_core u_uart_tx (
        .clk      (s00_axi_aclk),
        .rst      (s00_axi_aresetn),   // active-low reset
        .tx_data  (tx_data_out),
        .tx_start (tx_start),
        .baud_div (baud_div),
        .tx       (uart_tx),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done)
    );

    // RX 코어 인스턴스
    uart_rx_core u_uart_rx (
        .clk      (s00_axi_aclk),
        .rst      (s00_axi_aresetn),
        .rx       (uart_rx),
        .baud_div (baud_div),
        .rx_data  (rx_data),
        .rx_busy  (rx_busy),
        .rx_done  (rx_done),
        .rx_error (rx_error)
    );

endmodule