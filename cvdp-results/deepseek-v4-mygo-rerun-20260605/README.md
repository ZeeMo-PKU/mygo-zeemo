# CVDP DeepSeek v4 MyGo Rerun Results

This directory records the final CVDP cid003 result after rerunning the
previous `MODEL_OR_MYGO_ERROR` tasks for the LLM-Go/MyGo route.

## Summary

- Direct Verilog baseline: 37/78 PASS
- Original MyGo route before reruns: 37/78 PASS
- MyGo route after rerunning prior route failures: 45/78 PASS

## Rerun Scope

- Rerun input: the 20 tasks that were `MODEL_OR_MYGO_ERROR` in the first MyGo run.
- Rerun result: 8 PASS, 3 FAIL, 9 MODEL_OR_MYGO_ERROR.
- Final merged 78-task result: 45 PASS, 24 FAIL, 9 MODEL_OR_MYGO_ERROR.

## Direct-vs-MyGo Cross Result

- Both pass: 21
- MyGo improved direct-Verilog failures to PASS: 24
- MyGo regressed direct-Verilog PASS cases: 16
- Both fail: 17
- Union if selecting any CVDP PASS from direct or MyGo: 61/78

## Files

- `rerun_final_report.md`: final human-readable report.
- `rerun_summary.json`: result of the 20 rerun tasks.
- `merged_after_rerun_summary.json`: merged 78-task MyGo result after applying reruns.
- `rerun_summary.txt`: rerun status counts.
- `rerun_done.json`: rerun completion metadata.

