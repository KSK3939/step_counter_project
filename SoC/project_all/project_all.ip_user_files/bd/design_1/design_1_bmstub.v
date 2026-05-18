// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------

`timescale 1 ps / 1 ps

(* BLOCK_STUB = "true" *)
module design_1 (
  reset,
  sys_clock,
  usb_uart_rxd,
  usb_uart_txd,
  max_cs_0,
  max_csk_0,
  max_din_0,
  scl_0,
  sda_0,
  uart_rx_0,
  uart_tx_0
);

  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RESET RST" *)
  (* X_INTERFACE_MODE = "slave RST.RESET" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RESET, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
  input reset;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.SYS_CLOCK CLK" *)
  (* X_INTERFACE_MODE = "slave CLK.SYS_CLOCK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.SYS_CLOCK, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN design_1_sys_clock, INSERT_VIP 0" *)
  input sys_clock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:uart:1.0 usb_uart RxD" *)
  (* X_INTERFACE_MODE = "master usb_uart" *)
  input usb_uart_rxd;
  (* X_INTERFACE_INFO = "xilinx.com:interface:uart:1.0 usb_uart TxD" *)
  output usb_uart_txd;
  (* X_INTERFACE_IGNORE = "true" *)
  output max_cs_0;
  (* X_INTERFACE_IGNORE = "true" *)
  output max_csk_0;
  (* X_INTERFACE_IGNORE = "true" *)
  output max_din_0;
  (* X_INTERFACE_IGNORE = "true" *)
  output scl_0;
  (* X_INTERFACE_IGNORE = "true" *)
  inout sda_0;
  (* X_INTERFACE_IGNORE = "true" *)
  input uart_rx_0;
  (* X_INTERFACE_IGNORE = "true" *)
  output uart_tx_0;

  // stub module has no contents

endmodule
