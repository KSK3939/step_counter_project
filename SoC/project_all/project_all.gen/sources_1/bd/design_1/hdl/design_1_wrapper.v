//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Mon May 18 16:07:28 2026
//Host        : user18-H410M-HD3P running 64-bit Ubuntu 24.04.4 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (max_cs_0,
    max_csk_0,
    max_din_0,
    reset,
    scl_0,
    sda_0,
    sys_clock,
    uart_rx_0,
    uart_tx_0,
    usb_uart_rxd,
    usb_uart_txd);
  output max_cs_0;
  output max_csk_0;
  output max_din_0;
  input reset;
  output scl_0;
  inout sda_0;
  input sys_clock;
  input uart_rx_0;
  output uart_tx_0;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire max_cs_0;
  wire max_csk_0;
  wire max_din_0;
  wire reset;
  wire scl_0;
  wire sda_0;
  wire sys_clock;
  wire uart_rx_0;
  wire uart_tx_0;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  design_1 design_1_i
       (.max_cs_0(max_cs_0),
        .max_csk_0(max_csk_0),
        .max_din_0(max_din_0),
        .reset(reset),
        .scl_0(scl_0),
        .sda_0(sda_0),
        .sys_clock(sys_clock),
        .uart_rx_0(uart_rx_0),
        .uart_tx_0(uart_tx_0),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
