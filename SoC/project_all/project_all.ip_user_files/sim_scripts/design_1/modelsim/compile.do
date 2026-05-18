vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/lib_cdc_v1_0_3
vlib modelsim_lib/msim/proc_sys_reset_v5_0_16
vlib modelsim_lib/msim/microblaze_v11_0_14
vlib modelsim_lib/msim/microblaze_riscv_v1_0_3
vlib modelsim_lib/msim/lmb_v10_v3_0_14
vlib modelsim_lib/msim/lmb_bram_if_cntlr_v4_0_25
vlib modelsim_lib/msim/blk_mem_gen_v8_4_9
vlib modelsim_lib/msim/generic_baseblocks_v2_1_2
vlib modelsim_lib/msim/axi_infrastructure_v1_1_0
vlib modelsim_lib/msim/axi_register_slice_v2_1_33
vlib modelsim_lib/msim/fifo_generator_v13_2_11
vlib modelsim_lib/msim/axi_data_fifo_v2_1_32
vlib modelsim_lib/msim/axi_crossbar_v2_1_34
vlib modelsim_lib/msim/axi_lite_ipif_v3_0_4
vlib modelsim_lib/msim/axi_intc_v4_1_20
vlib modelsim_lib/msim/xlconcat_v2_1_6
vlib modelsim_lib/msim/mdm_riscv_v1_0_3
vlib modelsim_lib/msim/lib_pkg_v1_0_4
vlib modelsim_lib/msim/lib_srl_fifo_v1_0_4
vlib modelsim_lib/msim/axi_uartlite_v2_0_37

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap lib_cdc_v1_0_3 modelsim_lib/msim/lib_cdc_v1_0_3
vmap proc_sys_reset_v5_0_16 modelsim_lib/msim/proc_sys_reset_v5_0_16
vmap microblaze_v11_0_14 modelsim_lib/msim/microblaze_v11_0_14
vmap microblaze_riscv_v1_0_3 modelsim_lib/msim/microblaze_riscv_v1_0_3
vmap lmb_v10_v3_0_14 modelsim_lib/msim/lmb_v10_v3_0_14
vmap lmb_bram_if_cntlr_v4_0_25 modelsim_lib/msim/lmb_bram_if_cntlr_v4_0_25
vmap blk_mem_gen_v8_4_9 modelsim_lib/msim/blk_mem_gen_v8_4_9
vmap generic_baseblocks_v2_1_2 modelsim_lib/msim/generic_baseblocks_v2_1_2
vmap axi_infrastructure_v1_1_0 modelsim_lib/msim/axi_infrastructure_v1_1_0
vmap axi_register_slice_v2_1_33 modelsim_lib/msim/axi_register_slice_v2_1_33
vmap fifo_generator_v13_2_11 modelsim_lib/msim/fifo_generator_v13_2_11
vmap axi_data_fifo_v2_1_32 modelsim_lib/msim/axi_data_fifo_v2_1_32
vmap axi_crossbar_v2_1_34 modelsim_lib/msim/axi_crossbar_v2_1_34
vmap axi_lite_ipif_v3_0_4 modelsim_lib/msim/axi_lite_ipif_v3_0_4
vmap axi_intc_v4_1_20 modelsim_lib/msim/axi_intc_v4_1_20
vmap xlconcat_v2_1_6 modelsim_lib/msim/xlconcat_v2_1_6
vmap mdm_riscv_v1_0_3 modelsim_lib/msim/mdm_riscv_v1_0_3
vmap lib_pkg_v1_0_4 modelsim_lib/msim/lib_pkg_v1_0_4
vmap lib_srl_fifo_v1_0_4 modelsim_lib/msim/lib_srl_fifo_v1_0_4
vmap axi_uartlite_v2_0_37 modelsim_lib/msim/axi_uartlite_v2_0_37

vlog -work xpm -64 -incr -mfcu  -sv "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"/opt/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/opt/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93  \
"/opt/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../bd/design_1/ipshared/e11c/hdl/myip_rxtx_slave_lite_v1_0_S00_AXI.v" \
"../../../bd/design_1/ipshared/e11c/hdl/myip_rxtx.v" \
"../../../bd/design_1/ipshared/e11c/rx.v" \
"../../../bd/design_1/ipshared/e11c/tx.v" \
"../../../bd/design_1/ip/design_1_myip_rxtx_0_0/sim/design_1_myip_rxtx_0_0.v" \

vcom -work lib_cdc_v1_0_3 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/2a4f/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_16 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/0831/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/design_1/ip/design_1_proc_sys_reset_0_0/sim/design_1_proc_sys_reset_0_0.vhd" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../bd/design_1/ip/design_1_clk_wiz_0/design_1_clk_wiz_0_clk_wiz.v" \
"../../../bd/design_1/ip/design_1_clk_wiz_0/design_1_clk_wiz_0.v" \

vcom -work microblaze_v11_0_14 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/a243/hdl/microblaze_v11_0_vh_rfs.vhd" \

vcom -work microblaze_riscv_v1_0_3 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/f9dd/hdl/microblaze_riscv_v1_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/design_1/ip/design_1_microblaze_riscv_0_0/sim/design_1_microblaze_riscv_0_0.vhd" \

vcom -work lmb_v10_v3_0_14 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/7495/hdl/lmb_v10_v3_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/design_1/ip/design_1_dlmb_v10_0/sim/design_1_dlmb_v10_0.vhd" \
"../../../bd/design_1/ip/design_1_ilmb_v10_0/sim/design_1_ilmb_v10_0.vhd" \

vcom -work lmb_bram_if_cntlr_v4_0_25 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/73e9/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/design_1/ip/design_1_dlmb_bram_if_cntlr_0/sim/design_1_dlmb_bram_if_cntlr_0.vhd" \
"../../../bd/design_1/ip/design_1_ilmb_bram_if_cntlr_0/sim/design_1_ilmb_bram_if_cntlr_0.vhd" \

vlog -work blk_mem_gen_v8_4_9 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/5ec1/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../bd/design_1/ip/design_1_lmb_bram_0/sim/design_1_lmb_bram_0.v" \

vlog -work generic_baseblocks_v2_1_2 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/0c28/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_infrastructure_v1_1_0 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_33 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/3ee4/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_11 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/6080/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_11 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/6080/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_11 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/6080/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_32 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/65ce/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_crossbar_v2_1_34 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/a7e3/hdl/axi_crossbar_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../bd/design_1/ip/design_1_microblaze_riscv_0_axi_periph_imp_xbar_0/sim/design_1_microblaze_riscv_0_axi_periph_imp_xbar_0.v" \

vcom -work axi_lite_ipif_v3_0_4 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/66ea/hdl/axi_lite_ipif_v3_0_vh_rfs.vhd" \

vcom -work axi_intc_v4_1_20 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/99b7/hdl/axi_intc_v4_1_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/design_1/ip/design_1_microblaze_riscv_0_axi_intc_0/sim/design_1_microblaze_riscv_0_axi_intc_0.vhd" \

vlog -work xlconcat_v2_1_6 -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/6120/hdl/xlconcat_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../bd/design_1/ip/design_1_microblaze_riscv_0_xlconcat_0/sim/design_1_microblaze_riscv_0_xlconcat_0.v" \

vcom -work mdm_riscv_v1_0_3 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/d547/hdl/mdm_riscv_v1_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/design_1/ip/design_1_mdm_1_0/sim/design_1_mdm_1_0.vhd" \

vcom -work lib_pkg_v1_0_4 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/8c68/hdl/lib_pkg_v1_0_rfs.vhd" \

vcom -work lib_srl_fifo_v1_0_4 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/1e5a/hdl/lib_srl_fifo_v1_0_rfs.vhd" \

vcom -work axi_uartlite_v2_0_37 -64 -93  \
"../../../../project_all.gen/sources_1/bd/design_1/ipshared/9a87/hdl/axi_uartlite_v2_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/design_1/ip/design_1_axi_uartlite_0_0/sim/design_1_axi_uartlite_0_0.vhd" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/3cbc" "+incdir+../../../../project_all.gen/sources_1/bd/design_1/ipshared/ec67/hdl" \
"../../../bd/design_1/ipshared/0cff/hdl/dotmatrix_ip_slave_lite_v1_0_S00_AXI.v" \
"../../../bd/design_1/ipshared/0cff/src/exam02_sequential_logic.v" \
"../../../bd/design_1/ipshared/0cff/src/max7219_8x32_cntr.v" \
"../../../bd/design_1/ipshared/0cff/hdl/dotmatrix_ip.v" \
"../../../bd/design_1/ip/design_1_dotmatrix_ip_0_0/sim/design_1_dotmatrix_ip_0_0.v" \
"../../../bd/design_1/ipshared/76fc/hdl/i2c_mpu_ip_slave_lite_v1_0_S00_AXI.v" \
"../../../bd/design_1/ipshared/76fc/dsdfg.v" \
"../../../bd/design_1/ipshared/76fc/src/mpu_cntr.v" \
"../../../bd/design_1/ip/design_1_i2c_mpu_ip_0_0/sim/design_1_i2c_mpu_ip_0_0.v" \
"../../../bd/design_1/ipshared/45e9/hdl/step_counter_ip_slave_lite_v1_0_S00_AXI.v" \
"../../../bd/design_1/ipshared/45e9/src/step_counter_cntr.v" \
"../../../bd/design_1/ipshared/45e9/hdl/step_counter_ip.v" \
"../../../bd/design_1/ip/design_1_step_counter_ip_0_0/sim/design_1_step_counter_ip_0_0.v" \
"../../../bd/design_1/sim/design_1.v" \

vlog -work xil_defaultlib \
"glbl.v"

