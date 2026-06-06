# MyGo return-port rerun, 33 non-PASS CVDP tasks

Source: reused existing DeepSeek-generated Go from the previous run; reran with patched MyGo named-return output-port support.

## Summary

- MODEL_OR_MYGO_ERROR: 21
- PASS: 12

## Detail

| # | Task | Status | Target | Failure category | Key reason |
|---:|---|---|---|---|---|
| 3 | cvdp_copilot_64b66b_encoder_0001 | PASS | encoder_64b66b | Passed CVDP |  |
| 7 | cvdp_copilot_apb_dsp_unit_0001 | MODEL_OR_MYGO_ERROR | apb_dsp_unit | MyGo/CIRCT backend SSA error | MyGo compile failed for reused model output: MyGo verilog FAIL. C:\temp\mygo_cvdp_work\07_cvdp_copilot_apb_dsp_unit_0001_1780696084327_15616\.mygo-tmp\.mygo-circt-3645026439\design... |
| 9 | cvdp_copilot_apb_history_shift_register_0001 | PASS | APBGlobalHistoryRegister | Passed CVDP |  |
| 10 | cvdp_copilot_axi_register_0001 | MODEL_OR_MYGO_ERROR | axi_register | MyGo timeout | MyGo compile failed for reused model output: MyGo ir TIMEOUT after 307.3s |
| 14 | cvdp_copilot_barrel_shifter_0001 | MODEL_OR_MYGO_ERROR | barrel_shifter_8bit | MyGo timeout | MyGo compile failed for reused model output: MyGo mlir TIMEOUT after 302.6s |
| 17 | cvdp_copilot_binary_to_one_hot_decoder_0001 | MODEL_OR_MYGO_ERROR | binary_to_one_hot_decoder | MyGo timeout | MyGo compile failed for reused model output: MyGo ir TIMEOUT after 304.0s |
| 18 | cvdp_copilot_caesar_cipher_0001 | MODEL_OR_MYGO_ERROR | caesar_cipher | MyGo timeout | MyGo compile failed for reused model output: MyGo ir TIMEOUT after 5604.2s |
| 19 | cvdp_copilot_car_parking_management_0001 | MODEL_OR_MYGO_ERROR | car_parking_system | Model output Go compile error | MyGo compile failed for reused model output: MyGo ir FAIL. error: C:\temp\mygo_cvdp_work\19_cvdp_copilot_car_parking_management_0001_1780702641414_15616\main.go:77:1: missing retur... |
| 22 | cvdp_copilot_comparator_0001 | PASS | signed_unsigned_comparator | Passed CVDP |  |
| 24 | cvdp_copilot_concatenate_0001 | MODEL_OR_MYGO_ERROR | enhanced_fsm_signal_processor | MyGo compile/backend error | MyGo compile failed for reused model output: MyGo mlir FAIL after 275.7s |
| 28 | cvdp_copilot_convolutional_encoder_0001 | MODEL_OR_MYGO_ERROR | convolutional_encoder | MyGo timeout | MyGo compile failed for reused model output: MyGo ir TIMEOUT after 302.7s |
| 30 | cvdp_copilot_data_width_converter_0003 | PASS | data_width_converter | Passed CVDP |  |
| 33 | cvdp_copilot_digital_dice_roller_0001 | PASS | digital_dice_roller | Passed CVDP |  |
| 35 | cvdp_copilot_edge_detector_0001 | MODEL_OR_MYGO_ERROR | sync_pos_neg_edge_detector | Model output Go compile error | MyGo compile failed for reused model output: MyGo ir FAIL. error: C:\temp\mygo_cvdp_work\35_cvdp_copilot_edge_detector_0001_1780703273885_15616\main.go:14:1: missing return package... |
| 36 | cvdp_copilot_ethernet_packet_parser_0001 | MODEL_OR_MYGO_ERROR | field_extract | MyGo timeout | MyGo compile failed for reused model output: MyGo ir TIMEOUT after 303.8s |
| 39 | cvdp_copilot_fibonacci_series_0001 | PASS | fibonacci_series | Passed CVDP |  |
| 40 | cvdp_copilot_fifo_async_0001 | PASS | fifo_async | Passed CVDP |  |
| 43 | cvdp_copilot_gcd_0001 | MODEL_OR_MYGO_ERROR | gcd_top | Model used unsupported Go construct | Do not use unsupported Go constructs. |
| 44 | cvdp_copilot_gf_multiplier_0001 | PASS | gf_multiplier | Passed CVDP |  |
| 52 | cvdp_copilot_morse_code_0001 | MODEL_OR_MYGO_ERROR | morse_encoder | MyGo timeout | MyGo compile failed for reused model output: MyGo mlir TIMEOUT after 305.4s |
| 58 | cvdp_copilot_perf_counters_0001 | PASS | cvdp_copilot_perf_counters | Passed CVDP |  |
| 60 | cvdp_copilot_piso_0001 | MODEL_OR_MYGO_ERROR | piso_8bit | Go toolchain access error | MyGo compile failed for reused model output: MyGo ir FAIL. err: fork/exec C:\Program Files\Go\bin\go.exe: Access is denied.: stderr: |
| 62 | cvdp_copilot_restoring_division_0001 | PASS | restoring_division | Passed CVDP |  |
| 63 | cvdp_copilot_reverse_bits_0001 | MODEL_OR_MYGO_ERROR | reverse_bits | MyGo timeout | MyGo compile failed for reused model output: MyGo ir TIMEOUT after 303.1s |
| 64 | cvdp_copilot_secure_read_write_bus_0001 | MODEL_OR_MYGO_ERROR | secure_read_write_bus_interface | Go toolchain access error | MyGo compile failed for reused model output: MyGo ir FAIL. err: fork/exec C:\Program Files\Go\bin\go.exe: Access is denied.: stderr: |
| 65 | cvdp_copilot_secure_read_write_register_bank_0001 | MODEL_OR_MYGO_ERROR | secure_read_write_register_bank | MyGo/CIRCT backend SSA error | MyGo compile failed for reused model output: MyGo verilog FAIL. C:\temp\mygo_cvdp_work\65_cvdp_copilot_secure_read_write_register_bank_0001_1780704341275_15616\.mygo-tmp\.mygo-circ... |
| 66 | cvdp_copilot_sequencial_binary_to_one_hot_decoder_0001 | MODEL_OR_MYGO_ERROR | binary_to_one_hot_decoder_sequential | MyGo timeout | MyGo compile failed for reused model output: MyGo ir TIMEOUT after 303.7s |
| 67 | cvdp_copilot_serial_in_parallel_out_0004 | PASS | serial_in_parallel_out_8bit | Passed CVDP |  |
| 68 | cvdp_copilot_set_bit_calculator_0001 | MODEL_OR_MYGO_ERROR | SetBitStreamCalculator | MyGo timeout | MyGo compile failed for reused model output: MyGo mlir TIMEOUT after 304.0s |
| 70 | cvdp_copilot_static_branch_predict_0001 | MODEL_OR_MYGO_ERROR | static_branch_predict | Go toolchain access error | MyGo compile failed for reused model output: MyGo ir FAIL. err: fork/exec C:\Program Files\Go\bin\go.exe: Access is denied.: stderr: |
| 73 | cvdp_copilot_thermostat_0001 | PASS | thermostat | Passed CVDP |  |
| 74 | cvdp_copilot_ttc_lite_0001 | MODEL_OR_MYGO_ERROR | ttc_counter_lite | Model output Go compile error | MyGo compile failed for reused model output: MyGo ir FAIL. error: C:\temp\mygo_cvdp_work\74_cvdp_copilot_ttc_lite_0001_1780704994245_15616\main.go:121:1: missing return package loa... |
| 75 | cvdp_copilot_unpacker_one_hot_0001 | MODEL_OR_MYGO_ERROR | unpack_one_hot | Model target function mismatch | Missing requested target function unpack_one_hot. |
