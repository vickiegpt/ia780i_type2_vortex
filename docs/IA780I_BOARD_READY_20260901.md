# IA-780I board-ready Quartus result (2026-09-01)

This manifest records the fresh Quartus 25.1 build produced from source commit
`64a3ba6` on branch `codex/ia780i-x64-noecc`.

## Board contract

- Device: `AGIB023R18A1E1V`
- Fitter seed: `2`
- DDR4: two channels, 64 DQ bits per channel, no external ECC DQ
- EMIF application interface: 512 bits per channel
- Host-visible HDM capacity: 15.75 GiB total
- Private capacity: 128 MiB per channel, including the inline poison sidecar

## Signoff timing

The standalone Timing Analyzer loaded the fresh `final` snapshot and reported
`Timing requirements were met`.

| Check | Worst slack | TNS / failing endpoints |
|---|---:|---:|
| Setup | +0.038 ns | 0.000 ns / 0 |
| Hold | +0.000 ns | 0.000 ns / 0 |
| Recovery | +0.665 ns | 0.000 ns / 0 |
| Removal | +0.148 ns | 0.000 ns / 0 |

All unconstrained-path counters are zero. Signoff Design Assistant reports zero
High-severity violations. The two Medium-severity rule classes are generated-IP
SDC diagnostics: overridden broad max/min-delay exceptions (`TMC-20025`) and six
empty generated-IP collections (`TMC-20026`).

## Programming artifact

- SOF: `hardware_test_design/output_files/cxltyp2_ed.sof`
- Size: 18,144,246 bytes
- SHA-256: `2a8a650c57be7b4861090e1cdcc9687b4b33837d1869d5e0dce493c35b9054e0`
- Generated: `2026-09-01 14:05:21 UTC`

The assembler loaded the same fresh `final` snapshot and completed with zero
errors and zero warnings.

## Evidence

- Synthesis: `hardware_test_design/logs/quartus_syn_vortex_tag_mlab_seed2_ia780i_x64_20260901.log`
- Fitter: `hardware_test_design/logs/quartus_fit_tag_mlab_seed2_ia780i_x64_20260901.log`
- Timing Analyzer: `hardware_test_design/logs/quartus_sta_tag_mlab_seed2_ia780i_x64_20260901.log`
- Assembler: `hardware_test_design/logs/quartus_asm_timing_closed_seed2_ia780i_x64_20260901.log`
- Reports: `hardware_test_design/output_files/cxltyp2_ed.{syn,fit,sta}.rpt`

The fail-closed checker command was:

```sh
cd hardware_test_design
python3 ../scripts/check_quartus_ia780i_result.py --project-dir .
```

It reported `IA780I_QUARTUS_RESULT=PASS` with the device, DQ width, AVMM width,
four timing slacks, unconstrained-path count, and SOF hash shown above.

The tracked `cxltyp2_ed_ioaux_right_param_table.hex` is a Quartus-regenerated
IOAUX cache. It was intentionally left as an uncommitted generated-worktree
change and is not part of this source/evidence commit.
