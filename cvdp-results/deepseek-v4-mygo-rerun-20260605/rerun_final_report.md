# MyGo error-rerun final report

- Rerun completed: 20/20 previous MODEL_OR_MYGO_ERROR tasks
- Rerun results: PASS 8, FAIL 3, MODEL_OR_MYGO_ERROR 9
- Full MyGo route after applying reruns: PASS 45/78, FAIL 24, MODEL_OR_MYGO_ERROR 9
- Original MyGo route before reruns: PASS 37/78
- Direct Verilog baseline: PASS 37/78

## Interpretation
After rerunning the previous route failures, MyGo route improves from 37/78 to 45/78, which is +8 over direct Verilog baseline and +8 over the first MyGo run.

## Remaining route failures after rerun
- idx 10: cvdp_copilot_axi_register_0001 - MyGo compile failed after DeepSeek revision attempts: MyGo ir TIMEOUT after 301.0s
- idx 19: cvdp_copilot_car_parking_management_0001 - MyGo compile failed after DeepSeek revision attempts: MyGo mlir TIMEOUT after 300.9s
- idx 43: cvdp_copilot_gcd_0001 - MyGo compile failed after DeepSeek revision attempts: MyGo compile failed
- idx 58: cvdp_copilot_perf_counters_0001 - MyGo compile failed after DeepSeek revision attempts: MyGo verilog FAIL. C:\temp\mygo_cvdp_work\58_cvdp_copilot_perf_counters_0001_1780649007522_30864\.mygo-tmp\.mygo-circt-1046997175\design.mlir:6:25: error: use of undeclared SSA value nam...
- idx 62: cvdp_copilot_restoring_division_0001 - MyGo compile failed after DeepSeek revision attempts: MyGo ir FAIL. error: C:\temp\mygo_cvdp_work\62_cvdp_copilot_restoring_division_0001_1780651137487_30864\main.go:86:1: missing return | package loading failed
- idx 64: cvdp_copilot_secure_read_write_bus_0001 - MyGo compile failed after DeepSeek revision attempts: MyGo ir TIMEOUT after 715.8s
- idx 65: cvdp_copilot_secure_read_write_register_bank_0001 - MyGo compile failed after DeepSeek revision attempts: MyGo verilog FAIL. C:\temp\mygo_cvdp_work\65_cvdp_copilot_secure_read_write_register_bank_0001_1780665576886_10152\.mygo-tmp\.mygo-circt-3448873388\design.mlir:213:26: error: use of unde...
- idx 74: cvdp_copilot_ttc_lite_0001 - MyGo compile failed after DeepSeek revision attempts: MyGo ir TIMEOUT after 1814.2s
- idx 75: cvdp_copilot_unpacker_one_hot_0001 - JSONDecodeError: Expecting value: line 495 column 1 (char 2717)

## Baseline transition after rerun
- both_pass: 21
- improved_fail_to_pass: 24
- regressed_pass_to_fail: 16
- both_fail: 17
- union pass if selecting any CVDP PASS from direct or MyGo: 61/78
