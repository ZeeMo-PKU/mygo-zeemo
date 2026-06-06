# MyGo CVDP Final Detailed Results

- Final MyGo route: PASS 45/78, FAIL 24, MODEL_OR_MYGO_ERROR 9
- Direct Verilog baseline: PASS 37/78
- Transition: both_pass 21, improved_fail_to_pass 24, regressed_pass_to_fail 16, both_fail 17
- Rule: final status comes from merged rerun result; FAIL reason is extracted from CVDP harness logs when available; MODEL_OR_MYGO_ERROR reason comes from MyGo/LLM route logs.

| # | Task | Direct | MyGo | 对照 | 失败原因/说明 |
|---:|---|---|---|---|---|
| 1 | cvdp_copilot_16qam_mapper_0001 | FAIL (仿真错误/测试失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 2 | cvdp_copilot_16qam_mapper_0006 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 3 | cvdp_copilot_64b66b_encoder_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（encoder_data_out_high, encoder_data_out_low） |
| 4 | cvdp_copilot_8x3_priority_encoder_0001 | PASS | PASS | 两边都通过 | 通过 |
| 5 | cvdp_copilot_Carry_Lookahead_Adder_0001 | PASS | PASS | 两边都通过 | 通过 |
| 6 | cvdp_copilot_GFCM_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 7 | cvdp_copilot_apb_dsp_unit_0001 | FAIL (超时) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（pready, prdata, pslverr, sram_valid） |
| 8 | cvdp_copilot_apb_gpio_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 9 | cvdp_copilot_apb_history_shift_register_0001 | FAIL (功能断言失败) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（pready, prdata, pslverr, history_full） |
| 10 | cvdp_copilot_axi_register_0001 | FAIL (超时) | MODEL_OR_MYGO_ERROR | 两边都失败 | MyGo ir 阶段超时（301.0s） |
| 11 | cvdp_copilot_axi_stream_upscale_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 12 | cvdp_copilot_axil_precision_counter_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 13 | cvdp_copilot_axis_joiner_0001 | PASS | PASS | 两边都通过 | 通过 |
| 14 | cvdp_copilot_barrel_shifter_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（data_out） |
| 15 | cvdp_copilot_bcd_counter_0001 | PASS | PASS | 两边都通过 | 通过 |
| 16 | cvdp_copilot_bcd_to_excess_3_0001 | PASS | PASS | 两边都通过 | 通过 |
| 17 | cvdp_copilot_binary_to_one_hot_decoder_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（one_hot_out） |
| 18 | cvdp_copilot_caesar_cipher_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（output_char） |
| 19 | cvdp_copilot_car_parking_management_0001 | PASS | MODEL_OR_MYGO_ERROR | MyGo 回退：Direct 通过→MyGo 失败 | MyGo mlir 阶段超时（300.9s） |
| 20 | cvdp_copilot_cascaded_adder_0001 | PASS | PASS | 两边都通过 | 通过 |
| 21 | cvdp_copilot_clock_divider_0003 | PASS | PASS | 两边都通过 | 通过 |
| 22 | cvdp_copilot_comparator_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP harness 执行失败：Icarus/cocotb 子命令返回非零状态 5，详细编译/断言日志不完整 |
| 23 | cvdp_copilot_complex_multiplier_0001 | PASS | PASS | 两边都通过 | 通过 |
| 24 | cvdp_copilot_concatenate_0001 | FAIL (功能断言失败) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（o_ready, o_error, o_fsm_status, o_vector_1） |
| 25 | cvdp_copilot_configurable_digital_low_pass_filter_0001 | PASS | PASS | 两边都通过 | 通过 |
| 26 | cvdp_copilot_configurable_digital_low_pass_filter_0004 | PASS | PASS | 两边都通过 | 通过 |
| 27 | cvdp_copilot_configurable_digital_low_pass_filter_0014 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 28 | cvdp_copilot_convolutional_encoder_0001 | FAIL (功能断言失败) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（encoded_bit1, encoded_bit2） |
| 29 | cvdp_copilot_data_bus_controller_0001 | FAIL (仿真错误/测试失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 30 | cvdp_copilot_data_width_converter_0003 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（o_data_out_hi, o_data_out_lo, o_data_out_valid, next_counter） |
| 31 | cvdp_copilot_dbi_0001 | PASS | PASS | 两边都通过 | 通过 |
| 32 | cvdp_copilot_decode_firstbit_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 33 | cvdp_copilot_digital_dice_roller_0001 | FAIL (仿真错误/测试失败) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（dice_value） |
| 34 | cvdp_copilot_digital_stopwatch_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 35 | cvdp_copilot_edge_detector_0001 | FAIL (功能断言失败) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（o_positive_edge_detected, o_negative_edge_detected） |
| 36 | cvdp_copilot_ethernet_packet_parser_0001 | FAIL (超时) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（ack, field, field_vld） |
| 37 | cvdp_copilot_events_to_apb_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 38 | cvdp_copilot_factorial_0001 | PASS | PASS | 两边都通过 | 通过 |
| 39 | cvdp_copilot_fibonacci_series_0001 | FAIL (仿真错误/测试失败) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（fib_out, overflow_flag） |
| 40 | cvdp_copilot_fifo_async_0001 | FAIL (功能断言失败) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（w_full, r_empty, r_data） |
| 41 | cvdp_copilot_filo_0005 | PASS | PASS | 两边都通过 | 通过 |
| 42 | cvdp_copilot_fsm_seq_detector_0001 | PASS | PASS | 两边都通过 | 通过 |
| 43 | cvdp_copilot_gcd_0001 | FAIL (超时) | MODEL_OR_MYGO_ERROR | 两边都失败 | MyGo 编译失败（日志未给出更细错误） |
| 44 | cvdp_copilot_gf_multiplier_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（result） |
| 45 | cvdp_copilot_hamming_code_tx_and_rx_0001 | PASS | PASS | 两边都通过 | 通过 |
| 46 | cvdp_copilot_hamming_code_tx_and_rx_0003 | PASS | PASS | 两边都通过 | 通过 |
| 47 | cvdp_copilot_hebbian_rule_0017 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 48 | cvdp_copilot_hill_cipher_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 49 | cvdp_copilot_load_store_unit_0001 | PASS | PASS | 两边都通过 | 通过 |
| 50 | cvdp_copilot_matrix_multiplier_0001 | PASS | PASS | 两边都通过 | 通过 |
| 51 | cvdp_copilot_microcode_sequencer_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 52 | cvdp_copilot_morse_code_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（morse_out, morse_length） |
| 53 | cvdp_copilot_moving_average_0001 | PASS | PASS | 两边都通过 | 通过 |
| 54 | cvdp_copilot_nbit_swizzling_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 55 | cvdp_copilot_packet_controller_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 56 | cvdp_copilot_palindrome_3b_0002 | PASS | PASS | 两边都通过 | 通过 |
| 57 | cvdp_copilot_perceptron_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 58 | cvdp_copilot_perf_counters_0001 | FAIL (Harness执行失败/超时) | MODEL_OR_MYGO_ERROR | 两边都失败 | MyGo/CIRCT 后端失败：MLIR 中出现 undeclared SSA value |
| 59 | cvdp_copilot_perfect_squares_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 60 | cvdp_copilot_piso_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（serial_out） |
| 61 | cvdp_copilot_prbs_gen_0003 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 62 | cvdp_copilot_restoring_division_0001 | FAIL (超时) | MODEL_OR_MYGO_ERROR | 两边都失败 | LLM 生成的 Go 不合法：缺少 return，MyGo IR/package loading 失败 |
| 63 | cvdp_copilot_reverse_bits_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（num_out） |
| 64 | cvdp_copilot_secure_read_write_bus_0001 | PASS | MODEL_OR_MYGO_ERROR | MyGo 回退：Direct 通过→MyGo 失败 | MyGo ir 阶段超时（715.8s） |
| 65 | cvdp_copilot_secure_read_write_register_bank_0001 | FAIL (功能断言失败) | MODEL_OR_MYGO_ERROR | 两边都失败 | MyGo/CIRCT 后端失败：MLIR 中出现 undeclared SSA value |
| 66 | cvdp_copilot_sequencial_binary_to_one_hot_decoder_0001 | FAIL (超时) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（o_one_hot_out） |
| 67 | cvdp_copilot_serial_in_parallel_out_0004 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（parallel_out） |
| 68 | cvdp_copilot_set_bit_calculator_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（o_set_bit_count） |
| 69 | cvdp_copilot_sorter_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 70 | cvdp_copilot_static_branch_predict_0001 | FAIL (仿真错误/测试失败) | FAIL | 两边都失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（predict_branch_taken_o, predict_branch_pc_o） |
| 71 | cvdp_copilot_sync_lifo_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 72 | cvdp_copilot_sync_serial_communication_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 73 | cvdp_copilot_thermostat_0001 | PASS | FAIL | MyGo 回退：Direct 通过→MyGo 失败 | CVDP/Icarus elaboration 失败：MyGo 输出模块端口不匹配（o_heater_full, o_heater_medium, o_heater_low, o_aircon_full） |
| 74 | cvdp_copilot_ttc_lite_0001 | FAIL (仿真错误/测试失败) | MODEL_OR_MYGO_ERROR | 两边都失败 | MyGo ir 阶段超时（1814.2s） |
| 75 | cvdp_copilot_unpacker_one_hot_0001 | PASS | MODEL_OR_MYGO_ERROR | MyGo 回退：Direct 通过→MyGo 失败 | LLM/API 返回解析失败：JSONDecodeError |
| 76 | cvdp_copilot_vending_machine_0001 | FAIL (超时) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
| 77 | cvdp_copilot_vga_controller_0001 | PASS | PASS | 两边都通过 | 通过 |
| 78 | cvdp_copilot_wb2ahb_0001 | FAIL (功能断言失败) | PASS | MyGo 改善：Direct 失败→MyGo 通过 | 通过 |
