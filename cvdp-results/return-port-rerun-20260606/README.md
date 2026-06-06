# CVDP return-port rerun results

This directory records the rerun after updating MyGo to expose top-level named Go return values as Verilog output ports.

## Scope

- Rerun set: 33 tasks that were not PASS in the previous MyGo final table.
- Model output: reused existing DeepSeek-generated Go; no new LLM generation was performed for this rerun.
- Compiler: patched MyGo with named-return output-port support.
- Harness: CVDP cocotb/Icarus flow.

## Result

- PASS: 12
- MODEL_OR_MYGO_ERROR: 21
- FAIL: 0

The single earlier comparator FAIL was caused by the local CVDP wrapper adapter incorrectly turning 1-bit ports into same-name parameters. After fixing the adapter and rerunning only that task, `cvdp_copilot_comparator_0001` passed CVDP.

## Files

- `summary_33tasks.md`: human-readable detailed table.
- `summary_33tasks.csv`: spreadsheet-friendly detailed table.
- `summary_33tasks.json`: structured detailed table.
- `summary_33tasks.txt`: status counts.
