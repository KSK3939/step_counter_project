# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "")
  file(REMOVE_RECURSE
  "/home/ming/workspace_ondevice_2/vitis_20206_2/platform_Project_MPU_Counter/microblaze_riscv_0/standalone_microblaze_riscv_0/bsp/include/sleep.h"
  "/home/ming/workspace_ondevice_2/vitis_20206_2/platform_Project_MPU_Counter/microblaze_riscv_0/standalone_microblaze_riscv_0/bsp/include/xiltimer.h"
  "/home/ming/workspace_ondevice_2/vitis_20206_2/platform_Project_MPU_Counter/microblaze_riscv_0/standalone_microblaze_riscv_0/bsp/include/xtimer_config.h"
  "/home/ming/workspace_ondevice_2/vitis_20206_2/platform_Project_MPU_Counter/microblaze_riscv_0/standalone_microblaze_riscv_0/bsp/lib/libxiltimer.a"
  )
endif()
