# IA-780I x64 No-ECC, Poison Sidecar, CXL.cache, and Timing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a timing-clean `AGIB023R18A1E1V` bitstream from latest main with two x64 no-ECC DDR4 channels, full-range persistent poison sidecar semantics, and the reviewed CIRA CXL.cache host-LLC completion writer.

**Architecture:** Start from the isolated `origin/main@6f64289` worktree and first port the already-reviewed `606178f` CXL.cache patch without VR2 or Qwen/Concordia changes. Retarget the active board and generated EMIF to 512-bit Avalon-MM data, place one poison bit per 64-byte line in a reserved per-channel DDR bitmap with an on-chip summary/cache, then integrate the sidecar at the per-channel EMIF boundary. Finish with exact-device Quartus compilation, structural CDC/setup repair, full TimeQuest closure, and evidence capture.

**Tech Stack:** SystemVerilog, Verilator, Python 3, Quartus Prime Pro 25.1, Platform Designer/Qsys EMIF generation, TimeQuest, Git worktrees

---

## File structure and responsibility map

**Create:**

- `tests/check_ia780i_x64_contract.py` — fail-closed static board, width, IP, capacity, and source-binding checker.
- `hardware_test_design/common/mc_top/mc_poison_sidecar_pkg.sv` — single authority for visible-capacity and bitmap address constants/functions.
- `hardware_test_design/common/mc_top/mc_poison_sidecar.sv` — one-channel data/metadata Avalon-MM sequencer, summary RAM, and four-line metadata cache.
- `tests/tb_mc_poison_sidecar_pkg.sv` — constant and address-mapping proof.
- `tests/tb_mc_poison_sidecar.sv` — behavioral poison, ordering, cache, and backpressure proof.
- `tests/Makefile.mc_poison_sidecar_pkg` — Verilator mapping-test target.
- `tests/Makefile.mc_poison_sidecar` — Verilator sidecar-test target.
- `hardware_test_design/constraints/ia780i_reset_sync.sdc` — endpoint-specific reset synchronizer constraints only if the implemented reset topology needs them.
- `scripts/check_quartus_ia780i_result.py` — fail-closed parser for exact device, fresh SOF, and all four slack classes.

**Modify:**

- `hardware_test_design/cxltyp2_ed.qsf` — activate IA780I, include CIRA/sidecar sources, remove active ALTECC bindings, retain exact board source, and bind regenerated EMIF once.
- `hardware_test_design/constraints/ia780i_pinout.tcl` — retain exact E1V device and x64 pin assignments; only comments/assertions may change unless a schematic-backed correction is found.
- `hardware_test_design/common/cxl_ed_defines.svh.iv` — x64 top-level DQ/DQS definitions under `IA780I`.
- `hardware_test_design/common/ed_cxlip_top_pkg.sv` — IA780I DDR/EMIF width and no-ECC constants.
- `hardware_test_design/common/mc_top/ddr_mc_top_common_pkg.sv` — 512/64 interface widths, no-ECC setting, and sidecar types/constants import.
- `hardware_test_design/common/mc_top/emif_ip/emif.ip` — x64 DDR4 source parameter with EMIF ECC disabled.
- `hardware_test_design/common/mc_top/emif_ip/emif_cal_two_ch.ip` — regenerated calibration metadata for the two exact-device EMIF instances if Qsys changes it.
- `hardware_test_design/common/mc_top/mc_emif_avmm.sv` — instantiate the repository `emif` module twice and place sidecar controllers between MC and physical EMIF.
- `hardware_test_design/common/mc_top/mc_single_chan_ecc_req.sv` — remove active IA780I ALTECC generation, pass 512-bit data, and export merged write poison.
- `hardware_test_design/common/mc_top/mc_single_chan_ecc_rsp.sv` — accept sidecar read poison and remove active IA780I syndrome dependency.
- `hardware_test_design/common/mc_top/mc_top.sv` — connect per-channel poison sidebands to request/response blocks.
- `hardware_test_design/ed_top_wrapper_typ2.sv` — advertise 15.75 GiB, pass poison sidebands, and preserve the ported CXL.cache channel-1 integration.
- `hardware_test_design/common/rv64/vortex/cache/VX_cache_repl.sv` and/or the exact TimeQuest endpoints discovered later — add only the pipeline stage required by the measured setup path.
- destination-domain reset wrappers identified by TimeQuest — implement asynchronous assertion and synchronous deassertion at each destination.

**Port unchanged from reviewed commit `606178f`:**

- `hardware_test_design/common/afu/afu_top.sv`
- `hardware_test_design/common/rv64/cira_axi_write_arbiter.sv`
- `hardware_test_design/common/rv64/cira_cxl_cache_completion_writer.sv`
- `hardware_test_design/common/rv64/cira_job_dispatch.sv`
- CIRA portions of `hardware_test_design/ed_top_wrapper_typ2.sv` and `hardware_test_design/cxltyp2_ed.qsf`
- `tests/Makefile.cira_axi_write_arbiter`
- `tests/Makefile.cira_cache_writer`
- `tests/Makefile.cira_dispatch`
- `tests/check_cira_cxl_cache_integration.sh`
- `tests/tb_cira_axi_write_arbiter.sv`
- `tests/tb_cira_cxl_cache_completion_writer.sv`
- `tests/tb_cira_job_dispatch.sv`

## Fixed numeric contract

Use these values everywhere through package constants, never duplicated literals:

```systemverilog
localparam int unsigned POISON_LINE_BYTES = 64;
localparam int unsigned POISON_BITS_PER_META_LINE = 512;
localparam int unsigned EMIF_LINE_ADDR_WIDTH = 27;
localparam logic [27:0] PHYS_LINE_COUNT_PER_CHANNEL = 28'h800_0000;
localparam logic [27:0] PRIVATE_LINE_COUNT_PER_CHANNEL = 28'h020_0000;
localparam logic [27:0] DATA_LINE_COUNT_PER_CHANNEL = 28'h7e0_0000;
localparam logic [26:0] POISON_META_BASE_LINE = 27'h7e0_0000;
localparam logic [17:0] POISON_META_LINE_COUNT = 18'h3f000;
localparam logic [63:0] VISIBLE_BYTES_PER_CHANNEL = 64'h0000_0001_f800_0000;
localparam logic [63:0] VISIBLE_BYTES_TOTAL = 64'h0000_0003_f000_0000;
localparam logic [35:0] HDM_SIZE_256MB = 36'h03f;
```

`VISIBLE_BYTES_PER_CHANNEL` is 7.875 GiB; `VISIBLE_BYTES_TOTAL` is 15.75 GiB; `HDM_SIZE_256MB=63` advertises 63 units of 256 MiB.

### Task 1: Establish clean baseline and import reviewed CIRA tests

**Files:**

- Create from `606178f`: `tests/Makefile.cira_axi_write_arbiter`
- Create from `606178f`: `tests/Makefile.cira_cache_writer`
- Create from `606178f`: `tests/Makefile.cira_dispatch`
- Create from `606178f`: `tests/check_cira_cxl_cache_integration.sh`
- Create from `606178f`: `tests/tb_cira_axi_write_arbiter.sv`
- Create from `606178f`: `tests/tb_cira_cxl_cache_completion_writer.sv`
- Create from `606178f`: `tests/tb_cira_job_dispatch.sv`

- [ ] **Step 1: Verify the isolated baseline and toolchain**

Run:

```bash
git status --short
git rev-parse --short HEAD
verilator --version
quartus_sh --version
```

Expected: clean status, HEAD descends from `6f64289`, Verilator is present, and Quartus reports 25.1 Pro Edition.

- [ ] **Step 2: Restore only the reviewed tests**

Run:

```bash
git restore --source=606178f -- \
  tests/Makefile.cira_axi_write_arbiter \
  tests/Makefile.cira_cache_writer \
  tests/Makefile.cira_dispatch \
  tests/check_cira_cxl_cache_integration.sh \
  tests/tb_cira_axi_write_arbiter.sv \
  tests/tb_cira_cxl_cache_completion_writer.sv \
  tests/tb_cira_job_dispatch.sv
```

Expected: exactly seven untracked test files appear; no RTL or QSF changes.

- [ ] **Step 3: Run tests to prove the implementation is absent**

Run:

```bash
make -C tests -f Makefile.cira_cache_writer clean all run
make -C tests -f Makefile.cira_axi_write_arbiter clean all run
make -C tests -f Makefile.cira_dispatch clean all run
```

Expected: each target fails because its reviewed RTL module is not present on main.  A pre-existing PASS is a scope error and must be investigated before continuing.

- [ ] **Step 4: Commit the red tests**

```bash
git add tests/Makefile.cira_axi_write_arbiter tests/Makefile.cira_cache_writer \
  tests/Makefile.cira_dispatch tests/check_cira_cxl_cache_integration.sh \
  tests/tb_cira_axi_write_arbiter.sv tests/tb_cira_cxl_cache_completion_writer.sv \
  tests/tb_cira_job_dispatch.sv
git commit -m "test(cxl): import reviewed CIRA cache writeback regressions"
```

### Task 2: Port only the reviewed CXL.cache implementation

**Files:**

- Modify/Create: the six hardware files listed under “Port unchanged from reviewed commit `606178f`”
- Test: the seven Task 1 files

- [ ] **Step 1: Apply only the hardware portion of `606178f`**

Run:

```bash
git show --format= 606178f -- hardware_test_design | git apply --index --3way
git diff --cached --check
```

Expected: patch applies without reject files.  Staged changes are limited to `afu_top.sv`, the three CIRA RTL files, `ed_top_wrapper_typ2.sv`, and `cxltyp2_ed.qsf`.

- [ ] **Step 2: Prove forbidden paths were not imported**

Run:

```bash
git diff --cached --name-only
git diff --cached | rg 'target_hdm|CIRA_AWUSER_I_SO|concordia|qwen|vortex_dcoh_writeback'
```

Expected: `target_hdm=0`/`CIRA_AWUSER_I_SO` is present; no Qwen, Concordia, VR2, or `vortex_dcoh_writeback` source is introduced.

- [ ] **Step 3: Run the focused CIRA tests**

Run:

```bash
make -C tests -f Makefile.cira_cache_writer clean all run
make -C tests -f Makefile.cira_axi_write_arbiter clean all run
make -C tests -f Makefile.cira_dispatch clean all run
bash tests/check_cira_cxl_cache_integration.sh
```

Expected: all writer, arbiter, dispatcher, and integration checks PASS, including magic-last, error response, and `target_hdm=0` assertions.

- [ ] **Step 4: Commit the reviewed port**

```bash
git commit -m "feat(cxl): port reviewed CIRA cache completion writer"
```

- [ ] **Step 5: Verify the matching trusted-HPA runtime contract without editing its dirty tree**

Run the two existing runtime gates in `/home/victoryang00/CXLMemUring`:

```bash
ctest --test-dir /home/victoryang00/CXLMemUring/build \
  -R 'test_cira_(offload_path|cache_completion_path)' --output-on-failure
```

Expected: both tests PASS, including rejection of zero/misaligned completion
HPAs and preservation of the translated HPA in the submitted descriptor.  Do
not stage, clean, reset, or otherwise modify that runtime worktree; its
pre-existing benchmark/profile changes are outside this branch.

### Task 3: Add the fail-closed IA-780I x64 static contract

**Files:**

- Create: `tests/check_ia780i_x64_contract.py`
- Modify: `hardware_test_design/cxltyp2_ed.qsf`
- Test: `tests/check_ia780i_x64_contract.py`

- [ ] **Step 1: Write the checker with exact assertions**

Create a Python script whose core checks are:

```python
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
QSF = ROOT / "hardware_test_design/cxltyp2_ed.qsf"
PINOUT = ROOT / "hardware_test_design/constraints/ia780i_pinout.tcl"
DEFINES = ROOT / "hardware_test_design/common/cxl_ed_defines.svh.iv"
PKG = ROOT / "hardware_test_design/common/mc_top/ddr_mc_top_common_pkg.sv"
EMIF = ROOT / "hardware_test_design/common/mc_top/emif_ip/emif.ip"

def active_lines(path: Path):
    return [line.strip() for line in path.read_text().splitlines()
            if line.strip() and not line.lstrip().startswith("#")]

errors = []
qsf = active_lines(QSF)
pinout = active_lines(PINOUT)
if qsf.count("source ./constraints/ia780i_pinout.tcl") != 1:
    errors.append("IA780I pinout must be sourced exactly once")
if 'set_global_assignment -name VERILOG_MACRO IA780I' not in qsf:
    errors.append("IA780I macro is not active")
device_lines = [line for line in qsf + pinout if re.search(r"-name DEVICE ", line)]
if device_lines != ["set_global_assignment -name DEVICE AGIB023R18A1E1V"]:
    errors.append(f"unexpected active DEVICE assignments: {device_lines}")
for forbidden in ("qsf_device_pinout.tcl", "AGIB027R29A1E2VR2", "concordia_qwen"):
    if any(forbidden in line for line in qsf):
        errors.append(f"forbidden active IA780I binding: {forbidden}")

def count_pin(prefix: str) -> int:
    return sum(re.search(rf"-to {re.escape(prefix)}\[[01]\]\[\d+\]$", line) is not None
               for line in pinout)

expected = {"mem_dq": 128, "mem_dqs": 16, "mem_dqs_n": 16, "mem_dbi_n": 16}
for signal, count in expected.items():
    if count_pin(signal) != count:
        errors.append(f"{signal}: expected {count}, got {count_pin(signal)}")
if any(re.search(r"-to mem_dq\[[01]\]\[(6[4-9]|7[01])\]$", line) for line in pinout):
    errors.append("ECC DQ[71:64] must not be active")

text = DEFINES.read_text() + PKG.read_text() + EMIF.read_text()
for required in ("DDR_MEM_DQ_W  64", "DDR_MEM_DQS_W 8",
                 "MCTOP_EMIF_AMM_DATA_WIDTH      = 512",
                 "MCTOP_EMIF_AMM_BE_WIDTH        = 64",
                 "<ipxact:value>64</ipxact:value>",
                 "CTRL_DDR4_ECC_EN"):
    if required not in text:
        errors.append(f"missing x64 contract token: {required}")
if errors:
    print("IA780I_X64_CONTRACT: FAIL")
    print("\n".join(f"- {error}" for error in errors))
    sys.exit(1)
print("IA780I_X64_CONTRACT: PASS")
```

Also parse the `CTRL_DDR4_ECC_EN` parameter block and require its value to be `false`; do not accept the parameter name alone.

- [ ] **Step 2: Run the checker to verify the baseline fails**

Run:

```bash
python3 tests/check_ia780i_x64_contract.py
```

Expected: FAIL for inactive `IA780I`, 576-bit MC width, and 72-bit EMIF DQ.

- [ ] **Step 3: Activate only the board-level IA780I selection**

Change the QSF IA-780I block to exactly:

```tcl
# IA-780I bbrev1 board authority
source ./constraints/ia780i_pinout.tcl
set_global_assignment -name VERILOG_MACRO IA780I
set_global_assignment -name VERILOG_MACRO "SYNTHESIS"
set_global_assignment -name VERILOG_MACRO "QUARTUS"
```

Do not add a second `DEVICE` assignment.  Keep the device authority in `ia780i_pinout.tcl`.

- [ ] **Step 4: Re-run and capture the narrower expected failure**

Run:

```bash
python3 tests/check_ia780i_x64_contract.py
```

Expected: pinout and board-selection checks pass; width/IP checks still fail.

- [ ] **Step 5: Commit the checker and board selection**

```bash
git add tests/check_ia780i_x64_contract.py hardware_test_design/cxltyp2_ed.qsf
git commit -m "test(ia780i): enforce exact board and x64 contract"
```

### Task 4: Convert the active MC datapath from 72/576 ECC to 64/512 no-ECC

**Files:**

- Modify: `hardware_test_design/common/ed_cxlip_top_pkg.sv`
- Modify: `hardware_test_design/common/mc_top/ddr_mc_top_common_pkg.sv`
- Modify: `hardware_test_design/common/mc_top/mc_single_chan_ecc_req.sv`
- Modify: `hardware_test_design/common/mc_top/mc_single_chan_ecc_rsp.sv`
- Modify: `hardware_test_design/common/mc_top/mc_top.sv`
- Modify: `hardware_test_design/cxltyp2_ed.qsf`
- Test: `tests/check_ia780i_x64_contract.py`

- [ ] **Step 1: Make package widths conditional and authoritative**

Use the IA780I branch in both packages:

```systemverilog
`ifdef IA780I
localparam MC_HA_DDR4_DQ_WIDTH   = 64;
localparam MC_HA_DDR4_DQS_WIDTH  = 8;
localparam MC_HA_DDR4_DBI_WIDTH  = 8;
localparam EMIF_AMM_DATA_WIDTH   = 512;
localparam EMIF_AMM_BE_WIDTH     = 64;
localparam MC_ECC_EN             = 0;
`else
localparam MC_HA_DDR4_DQ_WIDTH   = 72;
localparam MC_HA_DDR4_DQS_WIDTH  = 9;
localparam MC_HA_DDR4_DBI_WIDTH  = 9;
localparam EMIF_AMM_DATA_WIDTH   = 576;
localparam EMIF_AMM_BE_WIDTH     = 72;
localparam MC_ECC_EN             = 1;
`endif
```

Apply the same values to the `MCTOP_` names in `ddr_mc_top_common_pkg.sv`.  Keep `MC_HA_DP_DATA_WIDTH` and `MCTOP_MC_HA_DP_DATA_WIDTH` at 512.

- [ ] **Step 2: Bypass ALTECC structurally under IA780I**

In `mc_single_chan_ecc_req.sv`, guard every ALTECC encoder instance and every 72-bit swivel with `ifndef IA780I`.  The IA780I branch must drive:

```systemverilog
assign ia780i_writedata = from_mcrmw_new_req_emifclk.writedata;
assign ia780i_write_poison = from_mcrmw_new_req_emifclk.write_poison;
```

and use `ia780i_writedata` for the 512-bit AVMM request.  Add an output `to_sidecar_write_poison_emifclk` that is registered with the same latency and valid qualification as the write request.

In `mc_single_chan_ecc_rsp.sv`, add:

```systemverilog
input logic sidecar_read_poison_emifclk;
```

and use the existing response pipeline latency to assign:

```systemverilog
altecc_dec_q <= muxed_read_data[511:0];
altecc_dec_err_corrected <= '0;
altecc_dec_err_detected  <= '0;
altecc_dec_err_fatal     <= '0;
altecc_dec_syn_e         <= '0;
eccrsp2rmw_rd_resp_emifclk.read_poison <= sidecar_read_poison_emifclk;
```

Do not instantiate `altecc_enc_latency0`, `altecc_dec_latency1`, or `altecc_dec_latency2` in the active IA780I generate branch.

- [ ] **Step 3: Carry poison sidebands through `mc_top.sv`**

Add per-channel ports:

```systemverilog
output logic [MCTOP_MC_CHANNEL-1:0] hdm2emif_write_poison_emifclk,
input  logic [MCTOP_MC_CHANNEL-1:0] emif2hdm_read_poison_emifclk,
```

Connect each request encoder's merged poison to the output and each response decoder's sidecar poison input.  Poison must be associated with the same channel and request as its data.

- [ ] **Step 4: Remove active ALTECC QSF bindings for IA780I**

Delete the three active `IP_FILE` assignments for `altecc_enc_latency0.ip`, `altecc_dec_latency1.ip`, and `altecc_dec_latency2.ip`.  The source directories may remain for non-IA780I history, but the exact IA780I project must not elaborate them.

- [ ] **Step 5: Run static and focused lint checks**

Run:

```bash
python3 tests/check_ia780i_x64_contract.py
verilator --lint-only -Wall -Wno-fatal -DIA780I \
  hardware_test_design/common/mc_top/ddr_mc_top_common_pkg.sv \
  hardware_test_design/common/mc_top/hdm_axi_if_pkg.sv \
  hardware_test_design/common/mc_top/mc_single_chan_ecc_req.sv \
  hardware_test_design/common/mc_top/mc_single_chan_ecc_rsp.sv
```

Expected: contract still fails only on unregenerated EMIF metadata; lint has no width truncation or unresolved ALTECC module in the IA780I branch.

- [ ] **Step 6: Commit the no-ECC datapath**

```bash
git add hardware_test_design/common/ed_cxlip_top_pkg.sv \
  hardware_test_design/common/mc_top/ddr_mc_top_common_pkg.sv \
  hardware_test_design/common/mc_top/mc_single_chan_ecc_req.sv \
  hardware_test_design/common/mc_top/mc_single_chan_ecc_rsp.sv \
  hardware_test_design/common/mc_top/mc_top.sv hardware_test_design/cxltyp2_ed.qsf
git commit -m "feat(emif): use 512-bit no-ECC IA780I datapath"
```

### Task 5: Regenerate exact-device x64 EMIF and two-channel calibration IP

**Files:**

- Modify: `hardware_test_design/common/mc_top/emif_ip/emif.ip`
- Modify generated files under: `hardware_test_design/common/mc_top/emif_ip/emif/`
- Modify if generated: `hardware_test_design/common/mc_top/emif_ip/emif_cal_two_ch.ip`
- Modify: `hardware_test_design/common/mc_top/mc_emif_avmm.sv`
- Modify: `hardware_test_design/cxltyp2_ed.qsf`
- Test: `tests/check_ia780i_x64_contract.py`

- [ ] **Step 1: Change only the EMIF source parameters**

Set the `MEM_DDR4_DQ_WIDTH` value to 64 and keep all controller ECC values false:

```xml
<ipxact:parameter parameterId="MEM_DDR4_DQ_WIDTH" type="int">
  <ipxact:name>MEM_DDR4_DQ_WIDTH</ipxact:name>
  <ipxact:displayName>DQ width</ipxact:displayName>
  <ipxact:value>64</ipxact:value>
</ipxact:parameter>
```

Require `CTRL_DDR4_ECC_EN`, `CTRL_DDR4_ECC_AUTO_CORRECTION_EN`, `CTRL_DDR4_ECC_READDATAERROR_EN`, and `CTRL_DDR4_ECC_STATUS_EN` to remain `false`.

- [ ] **Step 2: Regenerate synthesis output for the exact part**

Run from `hardware_test_design/common/mc_top/emif_ip`:

```bash
export LM_LICENSE_FILE=/opt/altera_pro/25.1/lic_qsim_24_any.dat
qsys-generate emif.ip --synthesis=VERILOG --family="Agilex 7" \
  --part=AGIB023R18A1E1V
qsys-generate emif_cal_two_ch.ip --synthesis=VERILOG --family="Agilex 7" \
  --part=AGIB023R18A1E1V
```

Expected: both commands exit 0; generation reports name `emif`, exact part `AGIB023R18A1E1V`, DQ width 64, AVMM data width 512, and no ECC controller ports.

- [ ] **Step 3: Replace missing IA780I instance names with the generated module**

In `mc_emif_avmm.sv`, remove the IA780I references to absent modules `dram0_ddr2666_32gb` and `dram1_ddr2666_32gb`.  Instantiate the generated module in the existing channel loop:

```systemverilog
for (genvar chanCount = 0; chanCount < MCTOP_MC_CHANNEL; chanCount++) begin : GEN_EMIF
  emif emif_inst (
    .mem_dq             (mem_dq[chanCount]),
    .mem_dqs            (mem_dqs[chanCount]),
    .mem_dqs_n          (mem_dqs_n[chanCount]),
    .mem_dbi_n          (mem_dbi_n[chanCount]),
    .amm_address_0      (phy_amm_address[chanCount]),
    .amm_read_0         (phy_amm_read[chanCount]),
    .amm_write_0        (phy_amm_write[chanCount]),
    .amm_writedata_0    (phy_amm_writedata[chanCount]),
    .amm_byteenable_0   (phy_amm_byteenable[chanCount]),
    .amm_readdata_0     (phy_amm_readdata[chanCount]),
    .amm_readdatavalid_0(phy_amm_readdatavalid[chanCount]),
    .amm_ready_0        (phy_amm_ready[chanCount])
  );
end
```

Retain all existing clock, reset, calibration, address/control, and memory-pin connections that are omitted from this focused excerpt.  Their signal names must match the regenerated `emif.v` port list exactly.

- [ ] **Step 4: Verify generated port widths instead of trusting generation exit status**

Run:

```bash
python3 tests/check_ia780i_x64_contract.py
rg -n 'mem_dq.*\[63:0\]|amm_writedata_0.*\[511:0\]|amm_byteenable_0.*\[63:0\]' \
  hardware_test_design/common/mc_top/emif_ip/emif/emif.v
rg -n 'mem_dq.*\[71:0\]|amm_writedata_0.*\[575:0\]' \
  hardware_test_design/common/mc_top/emif_ip/emif/emif.v
```

Expected: contract PASS for board/IP widths; the first search finds all three x64 ports and the forbidden-width search returns no matches.

- [ ] **Step 5: Commit source and reproducible generated collateral**

```bash
git add hardware_test_design/common/mc_top/emif_ip/emif.ip \
  hardware_test_design/common/mc_top/emif_ip/emif \
  hardware_test_design/common/mc_top/emif_ip/emif_cal_two_ch.ip \
  hardware_test_design/common/mc_top/mc_emif_avmm.sv \
  hardware_test_design/cxltyp2_ed.qsf
git commit -m "feat(emif): regenerate IA780I dual x64 interfaces"
```

### Task 6: Define and prove poison bitmap mapping and visible capacity

**Files:**

- Create: `hardware_test_design/common/mc_top/mc_poison_sidecar_pkg.sv`
- Create: `tests/tb_mc_poison_sidecar_pkg.sv`
- Create: `tests/Makefile.mc_poison_sidecar_pkg`
- Modify: `hardware_test_design/ed_top_wrapper_typ2.sv`
- Modify: `hardware_test_design/cxltyp2_ed.qsf`

- [ ] **Step 1: Write a failing mapping test**

The testbench imports `mc_poison_sidecar_pkg` and checks:

```systemverilog
initial begin
  check(DATA_LINE_COUNT_PER_CHANNEL == 28'h7e0_0000, "data line count");
  check(poison_meta_line(27'h0) == 27'h7e0_0000, "first metadata line");
  check(poison_bit_select(27'h0) == 9'h000, "first bit");
  check(poison_meta_line(27'h1ff) == 27'h7e0_0000, "last bit same line");
  check(poison_bit_select(27'h1ff) == 9'h1ff, "last bit select");
  check(poison_meta_line(27'h200) == 27'h7e0_0001, "next metadata line");
  check({1'b0, poison_meta_line(DATA_LINE_COUNT_PER_CHANNEL[26:0] - 1)} <
        PHYS_LINE_COUNT_PER_CHANNEL,
        "last metadata address is physical");
  check(!is_host_data_line(POISON_META_BASE_LINE), "metadata is hidden");
  check(VISIBLE_BYTES_TOTAL == 64'h0000_0003_f000_0000, "15.75 GiB total");
  $display("POISON_SIDECAR_PKG: PASS");
  $finish;
end
```

Run `make -C tests -f Makefile.mc_poison_sidecar_pkg clean all run` and expect failure because the package does not exist.

- [ ] **Step 2: Implement the package**

Create the fixed constants above and these functions:

```systemverilog
function automatic logic [26:0] poison_meta_line(input logic [26:0] data_line);
  return POISON_META_BASE_LINE + (data_line >> 9);
endfunction

function automatic logic [8:0] poison_bit_select(input logic [26:0] data_line);
  return data_line[8:0];
endfunction

function automatic logic is_host_data_line(input logic [26:0] line_addr);
  return {1'b0, line_addr} < DATA_LINE_COUNT_PER_CHANNEL;
endfunction
```

Add an elaboration assertion that
`{1'b0, POISON_META_BASE_LINE} + POISON_META_LINE_COUNT <= PHYS_LINE_COUNT_PER_CHANNEL`.

- [ ] **Step 3: Advertise the exact visible capacity**

In `ed_top_wrapper_typ2.sv`, replace the 16 GiB constants with package values:

```systemverilog
assign hdm_size_256mb = mc_poison_sidecar_pkg::HDM_SIZE_256MB;
assign mc_chan_memsize[chanCount] = mc_poison_sidecar_pkg::VISIBLE_BYTES_PER_CHANNEL;
```

Do not calculate capacity from all `2**27` physical lines, because the private range must remain unreachable by host requests.

- [ ] **Step 4: Run mapping and static tests**

Run:

```bash
make -C tests -f Makefile.mc_poison_sidecar_pkg clean all run
python3 tests/check_ia780i_x64_contract.py
```

Expected: both PASS and print the exact 15.75 GiB aggregate.

- [ ] **Step 5: Commit mapping and capacity**

```bash
git add hardware_test_design/common/mc_top/mc_poison_sidecar_pkg.sv \
  hardware_test_design/ed_top_wrapper_typ2.sv hardware_test_design/cxltyp2_ed.qsf \
  tests/tb_mc_poison_sidecar_pkg.sv tests/Makefile.mc_poison_sidecar_pkg
git commit -m "feat(cxlmem): reserve poison metadata capacity"
```

### Task 7: Implement the per-channel poison sidecar with TDD

**Files:**

- Create: `hardware_test_design/common/mc_top/mc_poison_sidecar.sv`
- Create: `tests/tb_mc_poison_sidecar.sv`
- Create: `tests/Makefile.mc_poison_sidecar`
- Modify: `hardware_test_design/cxltyp2_ed.qsf`

- [ ] **Step 1: Write a cycle-accurate fake-EMIF testbench**

Model physical data and metadata as associative arrays keyed by 27-bit line address.  Provide tasks:

```systemverilog
task automatic data_write(input logic [26:0] addr,
                          input logic [511:0] data,
                          input logic poison);
task automatic data_read(input logic [26:0] addr,
                         output logic [511:0] data,
                         output logic poison);
task automatic hold_phy_ready(input int cycles);
task automatic evict_metadata_cache;
```

Execute these ordered cases with assertions after each response:

1. clean read returns poison 0 without a physical metadata read;
2. poisoned full write stores data and sets the selected bitmap bit;
3. poisoned read returns poison 1 after data and metadata are resolved;
4. clean full write clears poison;
5. two addresses sharing one metadata line preserve independent bits;
6. accesses spanning five metadata lines force four-line-cache eviction without losing poison;
7. AW/read-ready backpressure does not advance state or duplicate requests;
8. private-range upstream request is rejected and emits no physical request;
9. reset/summary initialization gates `up_ready` until all `18'h3f000` summary entries are zeroed.

Run `make -C tests -f Makefile.mc_poison_sidecar clean all run` and expect failure because the DUT is absent.

- [ ] **Step 2: Implement the module interface**

Use one instance per EMIF channel:

```systemverilog
module mc_poison_sidecar (
  input  logic         clk,
  input  logic         reset_n,
  input  logic [26:0]  up_address,
  input  logic [511:0] up_writedata,
  input  logic [63:0]  up_byteenable,
  input  logic         up_read,
  input  logic         up_write,
  input  logic         up_write_poison,
  output logic [511:0] up_readdata,
  output logic         up_readdatavalid,
  output logic         up_read_poison,
  output logic         up_ready,
  output logic [26:0]  phy_address,
  output logic [511:0] phy_writedata,
  output logic [63:0]  phy_byteenable,
  output logic         phy_read,
  output logic         phy_write,
  input  logic [511:0] phy_readdata,
  input  logic         phy_readdatavalid,
  input  logic         phy_ready
);
```

Latch exactly one upstream operation.  Use explicit states for summary initialization, data request, data response, summary lookup, metadata read, metadata update, and upstream response.  Never infer response ownership from the current upstream inputs after accepting a request.

- [ ] **Step 3: Implement summary and cache storage**

Use a 1-bit by `18'h3f000` inferred block RAM for `summary_ram` and a boot FSM that writes zero to one entry per clock.  Gate `up_ready=0` until the final entry is cleared.

Use four write-through metadata cache entries:

```systemverilog
typedef struct packed {
  logic         valid;
  logic [15:0]  tag;
  logic [511:0] bits;
} meta_cache_entry_t;
meta_cache_entry_t meta_cache [0:3];
```

Index with `meta_line_index[1:0]` and tag with the remaining bits.  A dirty bit is unnecessary because every mutation issues a physical metadata write before upstream completion.

- [ ] **Step 4: Implement logical poison operations**

For a read:

```systemverilog
resolved_poison = summary_bit
                  ? resolved_meta_bits[poison_bit_select(latched_address)]
                  : 1'b0;
```

For a write, the input is already the RMW-merged final poison.  If summary is zero and final poison is zero, skip metadata traffic.  Otherwise update exactly one bit:

```systemverilog
next_meta_bits = resolved_meta_bits;
next_meta_bits[poison_bit_select(latched_address)] = latched_write_poison;
next_summary_bit = |next_meta_bits;
```

Issue the metadata write with all 64 byte enables asserted, wait for physical acceptance, update cache and summary, then complete upstream.  Never expose metadata readdata as payload data.

- [ ] **Step 5: Run unit tests and lint**

Run:

```bash
make -C tests -f Makefile.mc_poison_sidecar clean all run
verilator --lint-only -Wall -Wno-fatal \
  hardware_test_design/common/mc_top/mc_poison_sidecar_pkg.sv \
  hardware_test_design/common/mc_top/mc_poison_sidecar.sv
```

Expected: all nine behavioral cases PASS; no inferred latch, width, array-index, or multiple-driver warnings.

- [ ] **Step 6: Commit the sidecar unit**

```bash
git add hardware_test_design/common/mc_top/mc_poison_sidecar.sv \
  hardware_test_design/cxltyp2_ed.qsf tests/tb_mc_poison_sidecar.sv \
  tests/Makefile.mc_poison_sidecar
git commit -m "feat(cxlmem): add persistent poison sidecar"
```

### Task 8: Integrate sidecar controllers with both EMIF channels

**Files:**

- Modify: `hardware_test_design/common/mc_top/mc_emif_avmm.sv`
- Modify: `hardware_test_design/common/mc_top/mc_top.sv`
- Modify: `hardware_test_design/ed_top_wrapper_typ2.sv`
- Modify: `tests/tb_mc_poison_sidecar.sv`
- Test: all MC and CIRA focused tests

- [ ] **Step 1: Extend the test to prove two-channel independence**

Instantiate two sidecars against two fake EMIF models.  Write the same local line address clean on channel 0 and poisoned on channel 1, then read both.  Require channel 0 poison 0 and channel 1 poison 1, with no cross-channel physical metadata access.

Run the test and expect failure until the two-channel wrapper connections exist.

- [ ] **Step 2: Insert sidecars at the physical EMIF boundary**

Rename the current generated-EMIF signals inside `mc_emif_avmm.sv` to `phy_amm_*`.  For each channel instantiate:

```systemverilog
mc_poison_sidecar sidecar (
  .clk                (emif_usr_clk[chanCount]),
  .reset_n            (emif_usr_reset_n[chanCount]),
  .up_address         (emif_amm_address[chanCount]),
  .up_writedata       (emif_amm_writedata[chanCount]),
  .up_byteenable      (emif_amm_byteenable[chanCount]),
  .up_read            (emif_amm_read[chanCount]),
  .up_write           (emif_amm_write[chanCount]),
  .up_write_poison    (emif_amm_write_poison[chanCount]),
  .up_readdata        (emif_amm_readdata[chanCount]),
  .up_readdatavalid   (emif_amm_readdatavalid[chanCount]),
  .up_read_poison     (emif_amm_read_poison[chanCount]),
  .up_ready           (emif_amm_ready[chanCount]),
  .phy_address        (phy_amm_address[chanCount]),
  .phy_writedata      (phy_amm_writedata[chanCount]),
  .phy_byteenable     (phy_amm_byteenable[chanCount]),
  .phy_read           (phy_amm_read[chanCount]),
  .phy_write          (phy_amm_write[chanCount]),
  .phy_readdata       (phy_amm_readdata[chanCount]),
  .phy_readdatavalid  (phy_amm_readdatavalid[chanCount]),
  .phy_ready          (phy_amm_ready[chanCount])
);
```

Add `emif_amm_write_poison` input and `emif_amm_read_poison` output arrays to `mc_emif_avmm.sv`, and connect them through `ed_top_wrapper_typ2.sv` to the Task 4 `mc_top` ports.

- [ ] **Step 3: Add integration assertions**

Bind assertions in simulation that require:

```systemverilog
assert property (@(posedge emif_usr_clk[ch])
  phy_amm_write[ch] |-> {1'b0, phy_amm_address[ch]} < PHYS_LINE_COUNT_PER_CHANNEL);
assert property (@(posedge emif_usr_clk[ch])
  emif_amm_ready[ch] && emif_amm_write[ch] |->
  {1'b0, emif_amm_address[ch]} < DATA_LINE_COUNT_PER_CHANNEL);
assert property (@(posedge emif_usr_clk[ch])
  emif_amm_readdatavalid[ch] |-> !$isunknown(emif_amm_read_poison[ch]));
```

- [ ] **Step 4: Run the full focused regression**

Run:

```bash
make -C tests -f Makefile.mc_poison_sidecar_pkg clean all run
make -C tests -f Makefile.mc_poison_sidecar clean all run
make -C tests -f Makefile.cira_cache_writer clean all run
make -C tests -f Makefile.cira_axi_write_arbiter clean all run
make -C tests -f Makefile.cira_dispatch clean all run
bash tests/check_cira_cxl_cache_integration.sh
python3 tests/check_ia780i_x64_contract.py
```

Expected: every command PASS; the two-channel test observes independent poison state.

- [ ] **Step 5: Commit integrated no-ECC poison behavior**

```bash
git add hardware_test_design/common/mc_top/mc_emif_avmm.sv \
  hardware_test_design/common/mc_top/mc_top.sv \
  hardware_test_design/ed_top_wrapper_typ2.sv tests/tb_mc_poison_sidecar.sv
git commit -m "feat(cxlmem): integrate poison sidecars with dual EMIF"
```

### Task 9: Add fail-closed Quartus result validation

**Files:**

- Create: `scripts/check_quartus_ia780i_result.py`
- Test: parser fixtures made from temporary copied report snippets

- [ ] **Step 1: Write parser self-tests first**

The script accepts `--project-dir` and `--max-sof-age-seconds`.  Its `--self-test` mode creates in-memory good and bad report snippets and verifies rejection of:

- wrong device;
- 72-bit DQ or 576-bit AVMM;
- missing SOF;
- stale SOF;
- negative setup, hold, recovery, or removal slack;
- absent slack class;
- unconstrained paths greater than zero.

Run `python3 scripts/check_quartus_ia780i_result.py --self-test` and expect failure before implementation.

- [ ] **Step 2: Implement strict parsing**

Use `pathlib`, `re`, and `hashlib`.  Require exact device text `AGIB023R18A1E1V`, locate `output_files/cxltyp2_ed.sof`, and parse the minimum slack for each class from TimeQuest reports.  The final output format is:

```text
DEVICE=AGIB023R18A1E1V
EMIF_DQ_PER_CHANNEL=64
EMIF_AVMM_WIDTH=512
SETUP_WNS=<value>
HOLD_WNS=<value>
RECOVERY_WNS=<value>
REMOVAL_WNS=<value>
UNCONSTRAINED_PATHS=0
SOF_SHA256=<64 hex chars>
IA780I_QUARTUS_RESULT=PASS
```

Exit nonzero before printing PASS if any requirement is absent or negative.

- [ ] **Step 3: Run self-tests and commit**

```bash
python3 scripts/check_quartus_ia780i_result.py --self-test
git add scripts/check_quartus_ia780i_result.py
git commit -m "test(quartus): validate exact IA780I timing result"
```

Expected: self-test PASS and no external report files are modified.

### Task 10: Run the first exact-device full compile and classify failures

**Files:**

- Modify only files implicated by compiler/elaborator evidence
- Preserve log: `hardware_test_design/logs/quartus_compile_ia780i_x64_<timestamp>.log`

- [ ] **Step 1: Run preflight checks**

```bash
git status --short
python3 tests/check_ia780i_x64_contract.py
bash tests/check_cira_cxl_cache_integration.sh
export LM_LICENSE_FILE=/opt/altera_pro/25.1/lic_qsim_24_any.dat
quartus_sh --version
```

Expected: clean tracked status, all static/focused checks PASS, Quartus 25.1.

- [ ] **Step 2: Compile without hiding the exit code**

From `hardware_test_design`, run:

```bash
mkdir -p logs
quartus_sh --flow compile cxltyp2_ed 2>&1 | tee \
  logs/quartus_compile_ia780i_x64_$(date -u +%Y%m%d_%H%M%S).log
```

Capture the pipeline exit status and require Quartus exit 0.  Do not treat a generated SOF as success when Quartus reports an error.

- [ ] **Step 3: Classify every failure before editing**

Record exact error IDs and group them into:

1. source/elaboration width or missing-module errors;
2. EMIF/IP generation legality errors;
3. pin/device/fitter errors;
4. setup/hold paths;
5. recovery/removal/reset paths;
6. unconstrained or ignored-constraint warnings.

For each source/IP/fitter error, make the smallest correction, re-run its focused checker, and commit with `fix(<area>): <exact cause>`.  Do not begin SDC timing exceptions while source or fitter legality errors remain.

- [ ] **Step 4: Run the strict result checker**

```bash
python3 ../scripts/check_quartus_ia780i_result.py \
  --project-dir . --max-sof-age-seconds 86400
```

Expected at this stage: either PASS, or a fail-closed report naming only concrete timing/unconstrained categories.  Wrong device or wrong width stops the plan and returns to Tasks 3–5.

### Task 11: Close setup timing from measured paths

**Files:**

- Modify only the exact RTL endpoints shown by the new E1V TimeQuest report
- Likely modify: `hardware_test_design/common/rv64/vortex/cache/VX_cache_repl.sv`
- Likely modify the associated cache pipeline/control file named by the report

- [ ] **Step 1: Extract the worst 20 setup paths**

Use TimeQuest Tcl or the generated report to record startpoint, endpoint, clock, logic depth, RAM blocks, and slack for each path.  Confirm whether the earlier replacement-state-to-cache-data RAM path remains the E1V worst path; do not assume the old E2V endpoint still applies.

- [ ] **Step 2: Add a focused cache pipeline regression before RTL change**

Extend the existing Vortex cache test or create `tests/tb_vortex_cache_repl_pipeline.sv` to issue replacement selections under stalls and verify that victim way, address, dirty state, and writeback data remain aligned after one added register stage.  Run it and require failure against the unpipelined latency expectation.

- [ ] **Step 3: Pipeline the measured combinational boundary**

Register the replacement decision and every associated sideband together:

```systemverilog
always_ff @(posedge clk) begin
  if (reset) begin
    repl_valid_q <= 1'b0;
  end else if (repl_ready) begin
    repl_valid_q <= repl_valid;
    repl_way_q   <= repl_way;
    repl_addr_q  <= repl_addr;
    repl_dirty_q <= repl_dirty;
  end
end
```

Update downstream ready/valid logic so stalls hold all fields.  Do not register only the way index while leaving dirty/address/data combinational.

- [ ] **Step 4: Run focused tests, recompile, and compare paths**

Run the cache regression, all CIRA/sidecar tests, then a full compile.  Require the old path to disappear or become nonnegative without creating a protocol test failure.  Commit the structural change and record before/after WNS in the commit body.

- [ ] **Step 5: Repeat only for remaining real synchronous setup paths**

For each negative path, add a reproducing latency/alignment test, implement one registered boundary, rerun tests, and compile.  Stop when setup and hold are nonnegative.  Frequency reduction is outside this plan without new user approval.

### Task 12: Close recovery/removal with destination-domain reset synchronization

**Files:**

- Modify the reset source/destination files named by TimeQuest
- Create if required: `hardware_test_design/constraints/ia780i_reset_sync.sdc`
- Modify: `hardware_test_design/cxltyp2_ed.qsf` to include the SDC once

- [ ] **Step 1: Extract every negative recovery/removal endpoint**

For each endpoint, record reset source, destination clock, whether assertion is asynchronous, synchronizer depth, and existing SDC coverage.  Distinguish an actual unsynchronized reset deassertion from a correctly synchronized chain whose first stage alone needs an asynchronous exception.

- [ ] **Step 2: Add reset synchronizer tests**

Create or extend a reset testbench that asserts reset asynchronously, deasserts it near a destination clock edge, and requires downstream reset to remain asserted until two clean destination-clock edges have elapsed.

- [ ] **Step 3: Implement asynchronous-assert/synchronous-deassert reset per domain**

Use a dedicated synchronizer for each destination clock:

```systemverilog
(* ASYNC_REG = "TRUE" *) logic [1:0] rst_sync_n;
always_ff @(posedge dst_clk or negedge async_reset_n) begin
  if (!async_reset_n)
    rst_sync_n <= 2'b00;
  else
    rst_sync_n <= {rst_sync_n[0], 1'b1};
end
assign dst_reset_n = rst_sync_n[1];
```

Do not fan out a synchronizer output from one clock domain into another unrelated domain.

- [ ] **Step 4: Constrain only implemented synchronizer endpoints**

If TimeQuest still analyzes asynchronous assertion into the first stage, constrain only the resolved first-stage reset pins.  Preserve recovery/removal analysis from the final synchronizer stage to downstream logic.  Validate every collection with `get_registers` and fail if it is empty.

- [ ] **Step 5: Recompile and require all reset slack nonnegative**

Run the reset test, focused regressions, full compile, and strict result checker.  Commit RTL and SDC together with the exact before/after recovery/removal WNS.

### Task 13: Final regression, artifact manifest, and branch verification

**Files:**

- Create: `hardware_test_design/output_files/ia780i_x64_build_manifest.txt`
- Preserve latest full compile log under: `hardware_test_design/logs/`
- Do not commit transient `db/`, `incremental_db/`, or simulator `obj_dir/` outputs

- [ ] **Step 1: Run all focused regressions from clean sources**

```bash
make -C tests -f Makefile.mc_poison_sidecar_pkg clean all run
make -C tests -f Makefile.mc_poison_sidecar clean all run
make -C tests -f Makefile.cira_cache_writer clean all run
make -C tests -f Makefile.cira_axi_write_arbiter clean all run
make -C tests -f Makefile.cira_dispatch clean all run
bash tests/check_cira_cxl_cache_integration.sh
python3 tests/check_ia780i_x64_contract.py
python3 scripts/check_quartus_ia780i_result.py --self-test
ctest --test-dir /home/victoryang00/CXLMemUring/build \
  -R 'test_cira_(offload_path|cache_completion_path)' --output-on-failure
```

Expected: every command PASS.

- [ ] **Step 2: Run the final full Quartus compile**

```bash
export LM_LICENSE_FILE=/opt/altera_pro/25.1/lic_qsim_24_any.dat
cd hardware_test_design
quartus_sh --flow compile cxltyp2_ed 2>&1 | tee \
  logs/quartus_compile_ia780i_x64_final_$(date -u +%Y%m%d_%H%M%S).log
python3 ../scripts/check_quartus_ia780i_result.py \
  --project-dir . --max-sof-age-seconds 86400
```

Expected: Quartus exit 0 and `IA780I_QUARTUS_RESULT=PASS` with nonnegative setup, hold, recovery, and removal.

- [ ] **Step 3: Write the reproducible build manifest**

Populate the manifest with exact values emitted by the checker:

```text
GIT_COMMIT=<40-hex commit>
QUARTUS_VERSION=25.1.0 Build 129 SP0.36 Pro Edition
DEVICE=AGIB023R18A1E1V
DDR_CHANNELS=2
DQ_PER_CHANNEL=64
ECC=disabled
VISIBLE_HDM_BYTES=0x3f0000000
POISON_META_BYTES_PER_CHANNEL=0x00fc0000
SETUP_WNS=<nonnegative>
HOLD_WNS=<nonnegative>
RECOVERY_WNS=<nonnegative>
REMOVAL_WNS=<nonnegative>
SOF=<absolute path>
SOF_SHA256=<64-hex digest>
COMPILE_LOG=<absolute path>
```

- [ ] **Step 4: Confirm scope and clean branch state**

Run:

```bash
git diff origin/main...HEAD --name-only
git grep -n -E 'AGIB027R29A1E2VR2|concordia_qwen|vortex_dcoh_writeback' -- \
  hardware_test_design ':!hardware_test_design/logs/*'
git status --short
```

Expected: only approved board/EMIF/poison/CIRA/timing/test/docs files differ; forbidden active sources are absent; generated transient directories are ignored or untracked and not staged.

- [ ] **Step 5: Commit the manifest and final evidence pointers**

```bash
git add hardware_test_design/output_files/ia780i_x64_build_manifest.txt \
  hardware_test_design/logs/quartus_compile_ia780i_x64_final_*.log
git commit -m "build(ia780i): record timing-clean x64 bitstream"
```

- [ ] **Step 6: Run final verification on committed HEAD**

Re-run the static checker, focused tests, strict Quartus-result checker, `git status --short`, and `sha256sum` on the SOF.  Report compile/timing claims only from this final committed HEAD and its matching manifest.

## Self-review results

- Spec coverage: exact E1V device, dual x64 no-ECC EMIF, 15.75 GiB capacity, persistent poison sidecar, reviewed-only CXL.cache completion port, full tests, fresh SOF, and all four slack classes each have explicit tasks.
- Scope isolation: VR2, Qwen/Concordia, CXL-HDM completion fallback, raw virtual-address completion, and unreviewed DCOH smoke RTL are explicitly excluded and checked.
- Type consistency: line addresses are 27 bits, cache lines and metadata lines are 512 bits, byte enables are 64 bits, poison is one bit per logical request, and all mapping constants are sourced from `mc_poison_sidecar_pkg`.
- Placeholder scan: the plan contains no deferred implementation markers.  Timing endpoint filenames beyond the known Vortex cache candidate are intentionally selected from the new exact-device TimeQuest evidence before editing, as required by the diagnostic workflow.
