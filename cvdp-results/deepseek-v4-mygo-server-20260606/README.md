# DeepSeek V4 + MyGo CVDP server run, 2026-06-06

This directory records the full 78-task CVDP `cid003` run executed on the
`Trifoliate` server.

## Setup

- Model: `deepseek/deepseek-v4-pro`
- Flow: DeepSeek -> Go/MyGo -> MyGo -> CIRCT -> Icarus/CVDP cocotb
- MyGo commit: `125084e`
- Server: `Trifoliate`, `/home/rongxv`
- Parallelism: 4 shards, `--skip-existing`, `--go-attempts 3`, `--retries 2`
- Dataset: CVDP v1.1.0 non-agentic code generation, public no-commercial subset

## Result

- Total: 78
- PASS: 56
- FAIL: 14
- MODEL_OR_MYGO_ERROR: 8
- Pass rate: 71.79%

`FAIL` means the generated HDL reached CVDP cocotb functional judging and did
not pass. `MODEL_OR_MYGO_ERROR` means the model/MyGo/CIRCT chain did not produce
valid HDL for functional judging.

Compared with the archived direct Verilog baseline
`tests/verilog-eval/historical/runs/cvdp_cid003_deepseek_v4_direct_20260602/`,
which passed 37/78 tasks, this server MyGo run passed 56/78 tasks.

## Files

- `mygo_cvdp_server_run_report.pdf`: rendered report for sharing.
- `server_merged_summary.md`: human-readable run summary and task table.
- `server_merged_summary.csv`: spreadsheet-friendly MyGo result table.
- `server_merged_summary.json`: structured MyGo result table.
- `server_vs_direct_detailed.csv`: per-task direct baseline vs MyGo comparison.
- `server_merged_summary.txt`: compact status counts.

The API key and temporary compilation work directories are intentionally not
included.
