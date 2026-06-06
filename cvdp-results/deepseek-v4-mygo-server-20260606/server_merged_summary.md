# MyGo CVDP Server Run Report

- Run: `deepseek-v4-mygo-server-20260606`
- Generated at: `2026-06-06T11:13:59`
- Server: `Trifoliate (/home/rongxv)`
- Model: `deepseek/deepseek-v4-pro`
- Flow: DeepSeek -> MyGo -> CIRCT -> Icarus/CVDP cocotb
- MyGo commit: `125084e`
- Parallelism: 4 shards, skip-existing enabled, go-attempts=3, retries=2

## Summary

- Total: 78
- PASS: 56
- FAIL: 14
- MODEL_OR_MYGO_ERROR: 8
- Pass rate: 71.79%

## Interpretation

本轮 78 道题全部在服务器完成。`PASS` 表示 MyGo 生成的 HDL 通过 CVDP cocotb 判题；`FAIL` 表示已经进入 CVDP 功能判题但行为不符合测试；`MODEL_OR_MYGO_ERROR` 表示模型/MyGo 工具链未产出可用于功能判题的 HDL。

## Failed Or Error Tasks

| # | Task | Status | Category | Failure reason |
|---:|---|---|---|---|
| 3 | `cvdp_copilot_64b66b_encoder_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 7 | `cvdp_copilot_apb_dsp_unit_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 8 | `cvdp_copilot_apb_gpio_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | MyGo compile failed after DeepSeek revision attempts: MyGo verilog FAIL. /home/rongxv/work/mygo_cvdp_work/08_cvdp_copilot_apb_gpio_0001_1780710090540_1866677/.mygo-tmp/.mygo-circt-1057250930/design.mlir:141:37: error:... |
| 9 | `cvdp_copilot_apb_history_shift_register_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 24 | `cvdp_copilot_concatenate_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 25 | `cvdp_copilot_configurable_digital_low_pass_filter_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | MyGo compile failed after DeepSeek revision attempts: MyGo ir FAIL. error: /home/rongxv/work/mygo_cvdp_work/25_cvdp_copilot_configurable_digital_low_pass_filter_0001_1780709806034_1866668/main.go:5:107: Port redeclare... |
| 28 | `cvdp_copilot_convolutional_encoder_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 30 | `cvdp_copilot_data_width_converter_0003` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 33 | `cvdp_copilot_digital_dice_roller_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 35 | `cvdp_copilot_edge_detector_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 36 | `cvdp_copilot_ethernet_packet_parser_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | MyGo compile failed after DeepSeek revision attempts: MyGo verilog FAIL. /home/rongxv/work/mygo_cvdp_work/36_cvdp_copilot_ethernet_packet_parser_0001_1780712037989_1866677/.mygo-tmp/.mygo-circt-2924727010/design.mlir:... |
| 39 | `cvdp_copilot_fibonacci_series_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 40 | `cvdp_copilot_fifo_async_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 43 | `cvdp_copilot_gcd_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | MyGo compile failed after DeepSeek revision attempts: MyGo compile failed |
| 60 | `cvdp_copilot_piso_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 62 | `cvdp_copilot_restoring_division_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | MyGo compile failed after DeepSeek revision attempts: MyGo ir FAIL. error: /home/rongxv/work/mygo_cvdp_work/62_cvdp_copilot_restoring_division_0001_1780712342790_1866671/main.go:64:1: missing return package loading fa... |
| 64 | `cvdp_copilot_secure_read_write_bus_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 65 | `cvdp_copilot_secure_read_write_register_bank_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | MyGo compile failed after DeepSeek revision attempts: MyGo compile failed |
| 68 | `cvdp_copilot_set_bit_calculator_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 70 | `cvdp_copilot_static_branch_predict_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb reported failing tests despite zero process return code. |
| 75 | `cvdp_copilot_unpacker_one_hot_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | MyGo compile failed after DeepSeek revision attempts: MyGo compile failed |
| 77 | `cvdp_copilot_vga_controller_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | MyGo compile failed after DeepSeek revision attempts: MyGo ir FAIL. error: /home/rongxv/work/mygo_cvdp_work/77_cvdp_copilot_vga_controller_0001_1780714849469_1866668/main.go:95:1: missing return package loading failed |

## Full Task Table

| # | Task | Status | Category | 中文说明 |
|---:|---|---|---|---|
| 1 | `cvdp_copilot_16qam_mapper_0001` | PASS | PASS | CVDP 判题通过。 |
| 2 | `cvdp_copilot_16qam_mapper_0006` | PASS | PASS | CVDP 判题通过。 |
| 3 | `cvdp_copilot_64b66b_encoder_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 4 | `cvdp_copilot_8x3_priority_encoder_0001` | PASS | PASS | CVDP 判题通过。 |
| 5 | `cvdp_copilot_Carry_Lookahead_Adder_0001` | PASS | PASS | CVDP 判题通过。 |
| 6 | `cvdp_copilot_GFCM_0001` | PASS | PASS | CVDP 判题通过。 |
| 7 | `cvdp_copilot_apb_dsp_unit_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 8 | `cvdp_copilot_apb_gpio_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | DeepSeek 修正后仍未通过 MyGo 编译/IR/Verilog 生成链路。 |
| 9 | `cvdp_copilot_apb_history_shift_register_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 10 | `cvdp_copilot_axi_register_0001` | PASS | PASS | CVDP 判题通过。 |
| 11 | `cvdp_copilot_axi_stream_upscale_0001` | PASS | PASS | CVDP 判题通过。 |
| 12 | `cvdp_copilot_axil_precision_counter_0001` | PASS | PASS | CVDP 判题通过。 |
| 13 | `cvdp_copilot_axis_joiner_0001` | PASS | PASS | CVDP 判题通过。 |
| 14 | `cvdp_copilot_barrel_shifter_0001` | PASS | PASS | CVDP 判题通过。 |
| 15 | `cvdp_copilot_bcd_counter_0001` | PASS | PASS | CVDP 判题通过。 |
| 16 | `cvdp_copilot_bcd_to_excess_3_0001` | PASS | PASS | CVDP 判题通过。 |
| 17 | `cvdp_copilot_binary_to_one_hot_decoder_0001` | PASS | PASS | CVDP 判题通过。 |
| 18 | `cvdp_copilot_caesar_cipher_0001` | PASS | PASS | CVDP 判题通过。 |
| 19 | `cvdp_copilot_car_parking_management_0001` | PASS | PASS | CVDP 判题通过。 |
| 20 | `cvdp_copilot_cascaded_adder_0001` | PASS | PASS | CVDP 判题通过。 |
| 21 | `cvdp_copilot_clock_divider_0003` | PASS | PASS | CVDP 判题通过。 |
| 22 | `cvdp_copilot_comparator_0001` | PASS | PASS | CVDP 判题通过。 |
| 23 | `cvdp_copilot_complex_multiplier_0001` | PASS | PASS | CVDP 判题通过。 |
| 24 | `cvdp_copilot_concatenate_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 25 | `cvdp_copilot_configurable_digital_low_pass_filter_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | DeepSeek 修正后仍未通过 MyGo 编译/IR/Verilog 生成链路。 |
| 26 | `cvdp_copilot_configurable_digital_low_pass_filter_0004` | PASS | PASS | CVDP 判题通过。 |
| 27 | `cvdp_copilot_configurable_digital_low_pass_filter_0014` | PASS | PASS | CVDP 判题通过。 |
| 28 | `cvdp_copilot_convolutional_encoder_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 29 | `cvdp_copilot_data_bus_controller_0001` | PASS | PASS | CVDP 判题通过。 |
| 30 | `cvdp_copilot_data_width_converter_0003` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 31 | `cvdp_copilot_dbi_0001` | PASS | PASS | CVDP 判题通过。 |
| 32 | `cvdp_copilot_decode_firstbit_0001` | PASS | PASS | CVDP 判题通过。 |
| 33 | `cvdp_copilot_digital_dice_roller_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 34 | `cvdp_copilot_digital_stopwatch_0001` | PASS | PASS | CVDP 判题通过。 |
| 35 | `cvdp_copilot_edge_detector_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 36 | `cvdp_copilot_ethernet_packet_parser_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | DeepSeek 修正后仍未通过 MyGo 编译/IR/Verilog 生成链路。 |
| 37 | `cvdp_copilot_events_to_apb_0001` | PASS | PASS | CVDP 判题通过。 |
| 38 | `cvdp_copilot_factorial_0001` | PASS | PASS | CVDP 判题通过。 |
| 39 | `cvdp_copilot_fibonacci_series_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 40 | `cvdp_copilot_fifo_async_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 41 | `cvdp_copilot_filo_0005` | PASS | PASS | CVDP 判题通过。 |
| 42 | `cvdp_copilot_fsm_seq_detector_0001` | PASS | PASS | CVDP 判题通过。 |
| 43 | `cvdp_copilot_gcd_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | DeepSeek 修正后仍未通过 MyGo 编译/IR/Verilog 生成链路。 |
| 44 | `cvdp_copilot_gf_multiplier_0001` | PASS | PASS | CVDP 判题通过。 |
| 45 | `cvdp_copilot_hamming_code_tx_and_rx_0001` | PASS | PASS | CVDP 判题通过。 |
| 46 | `cvdp_copilot_hamming_code_tx_and_rx_0003` | PASS | PASS | CVDP 判题通过。 |
| 47 | `cvdp_copilot_hebbian_rule_0017` | PASS | PASS | CVDP 判题通过。 |
| 48 | `cvdp_copilot_hill_cipher_0001` | PASS | PASS | CVDP 判题通过。 |
| 49 | `cvdp_copilot_load_store_unit_0001` | PASS | PASS | CVDP 判题通过。 |
| 50 | `cvdp_copilot_matrix_multiplier_0001` | PASS | PASS | CVDP 判题通过。 |
| 51 | `cvdp_copilot_microcode_sequencer_0001` | PASS | PASS | CVDP 判题通过。 |
| 52 | `cvdp_copilot_morse_code_0001` | PASS | PASS | CVDP 判题通过。 |
| 53 | `cvdp_copilot_moving_average_0001` | PASS | PASS | CVDP 判题通过。 |
| 54 | `cvdp_copilot_nbit_swizzling_0001` | PASS | PASS | CVDP 判题通过。 |
| 55 | `cvdp_copilot_packet_controller_0001` | PASS | PASS | CVDP 判题通过。 |
| 56 | `cvdp_copilot_palindrome_3b_0002` | PASS | PASS | CVDP 判题通过。 |
| 57 | `cvdp_copilot_perceptron_0001` | PASS | PASS | CVDP 判题通过。 |
| 58 | `cvdp_copilot_perf_counters_0001` | PASS | PASS | CVDP 判题通过。 |
| 59 | `cvdp_copilot_perfect_squares_0001` | PASS | PASS | CVDP 判题通过。 |
| 60 | `cvdp_copilot_piso_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 61 | `cvdp_copilot_prbs_gen_0003` | PASS | PASS | CVDP 判题通过。 |
| 62 | `cvdp_copilot_restoring_division_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | DeepSeek 修正后仍未通过 MyGo 编译/IR/Verilog 生成链路。 |
| 63 | `cvdp_copilot_reverse_bits_0001` | PASS | PASS | CVDP 判题通过。 |
| 64 | `cvdp_copilot_secure_read_write_bus_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 65 | `cvdp_copilot_secure_read_write_register_bank_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | DeepSeek 修正后仍未通过 MyGo 编译/IR/Verilog 生成链路。 |
| 66 | `cvdp_copilot_sequencial_binary_to_one_hot_decoder_0001` | PASS | PASS | CVDP 判题通过。 |
| 67 | `cvdp_copilot_serial_in_parallel_out_0004` | PASS | PASS | CVDP 判题通过。 |
| 68 | `cvdp_copilot_set_bit_calculator_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 69 | `cvdp_copilot_sorter_0001` | PASS | PASS | CVDP 判题通过。 |
| 70 | `cvdp_copilot_static_branch_predict_0001` | FAIL | CVDP_FUNCTION_FAIL | CVDP cocotb 功能测试失败，说明生成 HDL 已进入判题但行为不符合参考测试。 |
| 71 | `cvdp_copilot_sync_lifo_0001` | PASS | PASS | CVDP 判题通过。 |
| 72 | `cvdp_copilot_sync_serial_communication_0001` | PASS | PASS | CVDP 判题通过。 |
| 73 | `cvdp_copilot_thermostat_0001` | PASS | PASS | CVDP 判题通过。 |
| 74 | `cvdp_copilot_ttc_lite_0001` | PASS | PASS | CVDP 判题通过。 |
| 75 | `cvdp_copilot_unpacker_one_hot_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | DeepSeek 修正后仍未通过 MyGo 编译/IR/Verilog 生成链路。 |
| 76 | `cvdp_copilot_vending_machine_0001` | PASS | PASS | CVDP 判题通过。 |
| 77 | `cvdp_copilot_vga_controller_0001` | MODEL_OR_MYGO_ERROR | MODEL_OR_MYGO_ERROR | DeepSeek 修正后仍未通过 MyGo 编译/IR/Verilog 生成链路。 |
| 78 | `cvdp_copilot_wb2ahb_0001` | PASS | PASS | CVDP 判题通过。 |
