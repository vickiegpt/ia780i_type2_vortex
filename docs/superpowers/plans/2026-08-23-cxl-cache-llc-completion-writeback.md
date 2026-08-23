# CXL.cache LLC Completion Writeback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a CIRA Vortex completion reach host DRAM through the generated AXI2CCIP CXL.cache interface, with an ordered magic-last publication and a trusted host-HPA runtime contract.

**Architecture:** The dispatcher supplies a completed job to a dedicated two-write CXL.cache completion writer.  A write-only arbiter shares AXI2CCIP channel 1 between that writer and the existing atomic-test engine; the writer publishes payload via the supported full-line coherent write and publishes magic only after its response succeeds.  The runtime replaces raw completion virtual addresses with a registered or driver-translated HPA before ringing a non-emulated hardware doorbell.

**Tech Stack:** SystemVerilog/Verilator/Quartus, existing Intel AXI2CCIP CXL IP, C++17, CMake/CTest.

---

## File structure

| File | Responsibility |
| --- | --- |
| `hardware_test_design/common/rv64/cira_cxl_cache_completion_writer.sv` | One-entry CXL.cache completion state machine; emits payload then magic commit. |
| `hardware_test_design/common/axi_to_avst/cira_axi2ccip_write_arbiter.sv` | Serializes existing ATE writes and completion-writer writes onto physical AXI2CCIP `axi1`; reads remain ATE-only. |
| `hardware_test_design/common/rv64/cira_job_dispatch.sv` | Waits for writer success/error before publishing the host status sequence. |
| `hardware_test_design/common/afu/afu_top.sv` | Exports the dispatcher completion request and consumes completion-writer response signals. |
| `hardware_test_design/ed_top_wrapper_typ2.sv` | Instantiates the writer/arbiter and connects their write side to the generated IP `axi1` port. |
| `hardware_test_design/cxltyp2_ed.qsf` | Includes the two new synthesizeable RTL sources. |
| `tests/tb_cira_cxl_cache_completion_writer.sv` | Writer handshake, CXL.cache attribute, ordering, and error regression. |
| `tests/tb_cira_axi2ccip_write_arbiter.sv` | AXI write ownership and response-routing regression. |
| `tests/tb_cira_job_dispatch.sv` | Completion success/error sequencing regression. |
| `tests/Makefile.cira_cache_writer`, `tests/Makefile.cira_axi2ccip_arbiter`, `tests/Makefile.cira_dispatch` | Focused Verilator commands. |
| `/home/victoryang00/CXLMemUring/runtime/include/cira_cxl_job.h` | Shared terminal completion-I/O status code. |
| `/home/victoryang00/CXLMemUring/runtime/include/cira_mmio.h` | Device-address submit ABI. |
| `/home/victoryang00/CXLMemUring/runtime/cira_mmio.cpp` | Descriptor construction using an explicit HPA. |
| `/home/victoryang00/CXLMemUring/runtime/src/CiraRuntime.cpp` | Fail-closed HPA resolution for real hardware submit. |
| `/home/victoryang00/CXLMemUring/runtime/test/test_cira_offload_path.cpp` | C ABI device-address descriptor tests. |
| `/home/victoryang00/CXLMemUring/runtime/test/test_cira_cache_completion_path.cpp` | Real-runtime strict translation/fallback regression. |
| `/home/victoryang00/CXLMemUring/runtime/test/CMakeLists.txt` | Registers the new runtime regression. |

### Task 1: Add the explicit completion-HPA submission ABI

**Files:**

- Modify: `/home/victoryang00/CXLMemUring/runtime/include/cira_cxl_job.h:51-57`
- Modify: `/home/victoryang00/CXLMemUring/runtime/include/cira_mmio.h:96-104`
- Modify: `/home/victoryang00/CXLMemUring/runtime/cira_mmio.cpp:374-388`
- Modify: `/home/victoryang00/CXLMemUring/runtime/test/test_cira_offload_path.cpp:120-197`

- [ ] **Step 1: Write a failing device-address descriptor test.**

  In `test_cira_offload_path.cpp`, submit a call using a fixed aligned HPA and
  copy `cira_cxl_call_job_t` out of the CALL argument slot.  Add these checks
  before the existing pointer-form test:

  ```cpp
  constexpr uint64_t kCompletionHpa = 0x0000'1234'5678'9a80ull;
  uint64_t device_seq = 0;
  int rc = cira_mmio_submit_call_device(w, (void *)&device_kernel, operands,
                                        2, kCompletionHpa, &device_seq);
  check(rc == CIRA_MMIO_OK, "device-form submit accepts aligned HPA");
  cira_cxl_call_job_t device_job = {};
  std::memcpy(&device_job,
              (const void *)(cira_mmio_base(w) + cira_cxl_arg_slot_off(CIRA_CXL_JOB_CALL) +
                             sizeof(cira_cxl_arg_slot_t)),
              sizeof(device_job));
  check(device_job.completion_addr == kCompletionHpa,
        "device-form descriptor preserves completion HPA");
  check(cira_mmio_submit_call_device(w, (void *)&device_kernel, operands, 2,
                                     kCompletionHpa + 1, nullptr) == CIRA_MMIO_EINVAL,
        "device-form submit rejects unaligned HPA");
  check(cira_mmio_submit_call_device(w, (void *)&device_kernel, operands, 2,
                                     0, nullptr) == CIRA_MMIO_EINVAL,
        "device-form submit rejects zero HPA");
  ```

- [ ] **Step 2: Build the current target and record the expected compile failure.**

  Run:

  ```bash
  cmake --build build --target test_cira_offload_path -j"$(nproc)"
  ```

  Expected: compilation fails because `cira_mmio_submit_call_device` is not
  declared.

- [ ] **Step 3: Add the shared terminal status and public ABI declaration.**

  Add the same value consumed by RTL to `cira_cxl_status_t`:

  ```c
  CIRA_CXL_STATUS_COMPLETION_IO = 0xffff0003u,
  ```

  Add the explicit API without changing the existing pointer-form API:

  ```c
  int cira_mmio_submit_call_device(cira_mmio_window_t *window, void *func,
                                   void **operands, uint32_t num_operands,
                                   uint64_t completion_hpa, uint64_t *out_seq);
  ```

- [ ] **Step 4: Implement the device form, then make the legacy helper a compatibility wrapper.**

  Implement the validation and descriptor construction in `cira_mmio.cpp`:

  ```cpp
  int cira_mmio_submit_call_device(cira_mmio_window_t *w, void *func,
                                   void **operands, uint32_t num_operands,
                                   uint64_t completion_hpa, uint64_t *out_seq) {
      if (num_operands && !operands)
          return CIRA_MMIO_EINVAL;
      if (completion_hpa == 0 || (completion_hpa & (CIRA_CXL_CACHELINE_SIZE - 1)))
          return CIRA_MMIO_EINVAL;
      void *target = func ? func : cira_mmio_device_func();
      if (!target)
          return CIRA_MMIO_ENODEV;
      cira_cxl_call_job_t job = {
          (uint64_t)(uintptr_t)target, (uint64_t)(uintptr_t)operands,
          completion_hpa, num_operands, 0,
      };
      return cira_mmio_submit_job(w, CIRA_CXL_JOB_CALL, &job, sizeof(job), 0, out_seq);
  }
  ```

  Preserve emulation/source compatibility by retaining
  `cira_mmio_submit_call()` and constructing its legacy descriptor with the
  pointer value; do not route it through the HPA-validating helper.

- [ ] **Step 5: Run the focused test.**

  Run:

  ```bash
  cmake --build build --target test_cira_offload_path -j"$(nproc)"
  ctest --test-dir build --output-on-failure -R '^test_cira_offload_path$'
  ```

  Expected: PASS, including the three new device-address checks and all legacy
  emulated-doorbell checks.

- [ ] **Step 6: Commit the ABI change.**

  ```bash
  git -C /home/victoryang00/CXLMemUring add runtime/include/cira_cxl_job.h runtime/include/cira_mmio.h runtime/cira_mmio.cpp runtime/test/test_cira_offload_path.cpp
  git -C /home/victoryang00/CXLMemUring commit -m "feat(runtime): submit CIRA completions by HPA"
  ```

### Task 2: Fail closed when a hardware completion cannot be translated

**Files:**

- Modify: `/home/victoryang00/CXLMemUring/runtime/src/CiraRuntime.cpp:104-122,1125-1149,1768-1788`
- Create: `/home/victoryang00/CXLMemUring/runtime/test/test_cira_cache_completion_path.cpp`
- Modify: `/home/victoryang00/CXLMemUring/runtime/test/CMakeLists.txt:17-20`

- [ ] **Step 1: Add a failing strict-submission regression.**

  The new test must create a non-emulated fixed-address MMIO window over an
  aligned anonymous control buffer, set it as the default, and use a 64-byte
  aligned heap completion.  It must first prove no registered translation
  leaves the doorbell sequence at zero, then register the completion range and
  prove that `completion_addr` in the staged CALL job is the registered HPA:

  ```cpp
  constexpr uint64_t kHpa = 0x0000'0004'0000'0000ull;
  alignas(64) uint8_t control[CIRA_CXL_CONTROL_BYTES] = {};
  cira_mmio_config_t cfg = {.fixed_addr = (uintptr_t)control,
                            .size = sizeof(control)};
  cira_mmio_window_t *window = nullptr;
  check(cira_mmio_open(&window, &cfg) == CIRA_MMIO_OK, "opens hardware-mode window");
  cira_mmio_set_default(window);

  alignas(64) cira_cxl_completion_t completion = {};
  cira_offload_submit((void *)&device_kernel, operands, 2, &completion);
  check(reinterpret_cast<cira_cxl_doorbell_t *>(control)->seq == 0,
        "untranslated heap completion does not ring hardware doorbell");
  check(cira_register_linear_region(&completion, sizeof(completion), kHpa, 0) == 0,
        "registers coherent completion HPA");
  cira_offload_submit((void *)&device_kernel, operands, 2, &completion);
  ```

  Copy the staged slot and check `completion_addr == kHpa`; unregister and
  clear the process-wide default at the end.

- [ ] **Step 2: Build the new test and verify it fails because strict resolution is absent.**

  Run:

  ```bash
  cmake --build build --target test_cira_cache_completion_path -j"$(nproc)"
  ctest --test-dir build --output-on-failure -R '^test_cira_cache_completion_path$'
  ```

  Expected: the first assertion fails because the current runtime puts the raw
  completion pointer into the non-emulated hardware descriptor.

- [ ] **Step 3: Implement one trusted completion-HPA resolver.**

  In the anonymous namespace of `CiraRuntime.cpp`, add a helper that is not
  shared with `translate_runtime_paddr()`:

  ```cpp
  bool translate_completion_hpa(void *completion, uintptr_t *hpa) {
      if (!completion || !hpa)
          return false;
      uintptr_t translated = 0;
      if (!translate_registered_region(completion, &translated) &&
          !kernel_cxl_translate_addr(completion, &translated))
          return false;
      if (translated == 0 || (translated & (CIRA_CXL_CACHELINE_SIZE - 1)))
          return false;
      *hpa = translated;
      return true;
  }
  ```

  Do not call `translate_runtime_paddr()`, `pagemap_physical_addr()`,
  `reverse_engineered_llc_addr()`, or the virtual-address fallback from this
  helper.

- [ ] **Step 4: Route only hardware MMIO through the device-form API.**

  Replace the submit portion of `submit_mmio_call()` with this branch:

  ```cpp
  int rc;
  if (cira_mmio_is_emulated(window)) {
      rc = cira_mmio_submit_call(window, func_ptr, operands, argc, completion_ptr, &seq);
  } else {
      uintptr_t completion_hpa = 0;
      if (!translate_completion_hpa(completion_ptr, &completion_hpa)) {
          std::cerr << "cira_offload_submit: no trusted CXL.cache completion HPA" << std::endl;
          return false;
      }
      rc = cira_mmio_submit_call_device(window, func_ptr, operands, argc,
                                        completion_hpa, &seq);
  }
  ```

  Leave the caller's existing `false` path intact so it performs the present
  software completion fallback.  Do not change the generic address-translation
  policy used for unrelated CIRA data accesses.

- [ ] **Step 5: Register and run the regression.**

  Add:

  ```cmake
  cira_add_runtime_test(test_cira_cache_completion_path test_cira_cache_completion_path.cpp)
  ```

  Run:

  ```bash
  cmake --build build --target test_cira_cache_completion_path -j"$(nproc)"
  ctest --test-dir build --output-on-failure -R '^(test_cira_offload_path|test_cira_cache_completion_path)$'
  ```

  Expected: PASS; the test proves an unregistered heap completion rings no
  real-hardware-mode doorbell and an explicitly registered completion stages
  its HPA.

- [ ] **Step 6: Commit the runtime routing change.**

  ```bash
  git -C /home/victoryang00/CXLMemUring add runtime/src/CiraRuntime.cpp runtime/test/test_cira_cache_completion_path.cpp runtime/test/CMakeLists.txt
  git -C /home/victoryang00/CXLMemUring commit -m "feat(runtime): require trusted CXL cache completion HPA"
  ```

### Task 3: Build and test the coherent magic-last writer

**Files:**

- Create: `hardware_test_design/common/rv64/cira_cxl_cache_completion_writer.sv`
- Create: `tests/tb_cira_cxl_cache_completion_writer.sv`
- Create: `tests/Makefile.cira_cache_writer`

- [ ] **Step 1: Write the failing Verilator testbench.**

  The testbench drives `req_valid`, a 64-byte-aligned HPA, and independent
  AW/W/B backpressure.  It records each accepted AW/W pair and checks:

  ```systemverilog
  check(txn_count == 2, "one payload and one commit write");
  check(aw_addr[0] == 64'h0000_1234_5678_9a80, "payload uses supplied HPA");
  check(aw_user[0] == 7'b0000010, "payload is CXL.cache ItoMWr/WrInv, not HDM");
  check(aw_cache[0] == 4'b0001, "payload uses supported CAFU cache attribute");
  check(w_strb[0] == 64'hffff_ffff_ffff_ffff, "payload writes complete line");
  check(w_data[0][31:0] == 32'h0, "payload leaves completion magic clear");
  check(w_strb[1] == 64'h0000_0000_0000_000f, "commit writes only magic bytes");
  check(w_data[1][31:0] == 32'hdead_beef, "commit publishes CIRA magic");
  check(done && !error, "OKAY commit completes writer");
  ```

  Add independent cases for an unaligned HPA, payload `SLVERR`, and commit
  `DECERR`; each must issue no success `done` pulse.

- [ ] **Step 2: Run it and verify the expected missing-module failure.**

  Run:

  ```bash
  make -C tests -f Makefile.cira_cache_writer run
  ```

  Expected: Verilator cannot find `cira_cxl_cache_completion_writer`.

- [ ] **Step 3: Implement a single-entry two-write FSM.**

  Use these public signals and local constants so the writer has no dependency
  on generated-IP implementation files:

  ```systemverilog
  localparam logic [6:0] CXL_CACHE_AWUSER = 7'b0000010;
  localparam logic [3:0] CXL_CACHE_AWCACHE = 4'b0001;
  localparam logic [31:0] CIRA_MAGIC = 32'hdead_beef;
  typedef enum logic [2:0] {IDLE, PAYLOAD_AW, PAYLOAD_W, PAYLOAD_B,
                            COMMIT_AW, COMMIT_W, COMMIT_B} state_t;
  ```

  Accept only `req_valid && !busy` in `IDLE`; reject zero or
  `(completion_hpa & 64'h3f) != 0` with a one-cycle `error` pulse.  Latch
  status/result and a free-running cycle counter.  Drive both requests with
  `AWID=12'hc1a`, `AWLEN=0`, `AWSIZE=3'd6`, `AWBURST=2'b00`,
  `AWUSER=CXL_CACHE_AWUSER`, `AWCACHE=CXL_CACHE_AWCACHE`, and no atomics.
  The payload W beat is a full line with magic zero; only after `bresp == 2'b00`
  does the FSM send a commit W beat with `WSTRB=64'hf` and magic in bits 31:0.
  `done` pulses only after an OKAY commit B handshake; either non-OKAY B
  response pulses `error` and returns to `IDLE`.

- [ ] **Step 4: Add the focused Verilator makefile.**

  Use the existing test style:

  ```make
  VERILATOR ?= verilator
  RTL_DIR := ../hardware_test_design/common/rv64
  TOP := tb_cira_cxl_cache_completion_writer
  SOURCES := $(TOP).sv $(RTL_DIR)/cira_cxl_cache_completion_writer.sv
  VFLAGS := --binary -j 0 --timing -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-INITIALDLY
  run:
	$(VERILATOR) $(VFLAGS) --top-module $(TOP) $(SOURCES) -o obj_dir/tb_cira_cache_writer
	./obj_dir/tb_cira_cache_writer
  ```

- [ ] **Step 5: Run writer test and lint.**

  Run:

  ```bash
  make -C tests -f Makefile.cira_cache_writer run
  verilator --lint-only -Wall -Wno-DECLFILENAME --top-module cira_cxl_cache_completion_writer hardware_test_design/common/rv64/cira_cxl_cache_completion_writer.sv
  ```

  Expected: all writer checks pass; lint has no writer warnings.

- [ ] **Step 6: Commit the writer and regression.**

  ```bash
  git add hardware_test_design/common/rv64/cira_cxl_cache_completion_writer.sv tests/tb_cira_cxl_cache_completion_writer.sv tests/Makefile.cira_cache_writer
  git commit -m "feat(rtl): add CXL cache completion writer"
  ```

### Task 4: Add the channel-1 write arbiter without changing coherency fields

**Files:**

- Create: `hardware_test_design/common/axi_to_avst/cira_axi2ccip_write_arbiter.sv`
- Create: `tests/tb_cira_axi2ccip_write_arbiter.sv`
- Create: `tests/Makefile.cira_axi2ccip_arbiter`

- [ ] **Step 1: Write a failing two-master AXI testbench.**

  Model an ATE write and a CIRA writer request with arbitrary distinct IDs.
  Assert both valid in the same cycle and stall AW/W/B independently.  The
  checker must prove CIRA priority when idle, selection retention through W,
  and response routing:

  ```systemverilog
  check(out_awuser == 7'b0000010 && out_awcache == 4'b0001,
        "arbiter preserves CIRA coherent attributes");
  check(out_wdata == cira_wdata && out_wstrb == 64'hf,
        "arbiter keeps selected CIRA address/data ownership");
  check(cira_bvalid && !ate_bvalid, "CIRA B response returns only to CIRA");
  check(ate_bvalid && !cira_bvalid, "ATE B response returns only to ATE");
  ```

- [ ] **Step 2: Run the test and verify the module is initially absent.**

  Run:

  ```bash
  make -C tests -f Makefile.cira_axi2ccip_arbiter run
  ```

  Expected: Verilator reports the arbiter module is missing.

- [ ] **Step 3: Implement a serial one-write-at-a-time arbiter.**

  Give the module full AW/W/B signals for `ate_*`, `cira_*`, and `out_*`;
  widths must match the physical `axi1` port: AWID/BID=12, AWUSER=7,
  AWATOP=6, data=512, strobe=64, BUSER=4.  Use an owner register and state
  machine:

  ```systemverilog
  typedef enum logic [1:0] {ARB_IDLE, ARB_W, ARB_B} arb_state_t;
  logic owner_cira;

  // In ARB_IDLE, select CIRA if cira_awvalid, otherwise ATE if ate_awvalid.
  // Latch owner only on out_awvalid && out_awready.
  // In ARB_W, expose W only from the latched owner; advance on W handshake.
  // In ARB_B, expose the CXL-IP B response only to the latched owner;
  // return to IDLE only on that owner's B handshake.
  ```

  Preserve every selected AW/W field bit-for-bit.  The serial design is
  intentional: it prevents AW/W owner mixing and the completion writer allows
  at most one outstanding write.  ATE read channels remain outside this module.

- [ ] **Step 4: Add and run the focused arbiter regression.**

  Makefile inputs are the testbench plus the new arbiter.  Run:

  ```bash
  make -C tests -f Makefile.cira_axi2ccip_arbiter run
  verilator --lint-only -Wall -Wno-DECLFILENAME --top-module cira_axi2ccip_write_arbiter hardware_test_design/common/axi_to_avst/cira_axi2ccip_write_arbiter.sv
  ```

  Expected: contention, both response paths, and unmodified CIRA attributes
  pass; lint is clean.

- [ ] **Step 5: Commit the arbiter and regression.**

  ```bash
  git add hardware_test_design/common/axi_to_avst/cira_axi2ccip_write_arbiter.sv tests/tb_cira_axi2ccip_write_arbiter.sv tests/Makefile.cira_axi2ccip_arbiter
  git commit -m "feat(rtl): arbitrate CIRA writes onto AXI2CCIP"
  ```

### Task 5: Make dispatcher retirement wait for writer success or failure

**Files:**

- Modify: `hardware_test_design/common/rv64/cira_job_dispatch.sv:71-86,107-140,300-430`
- Modify: `tests/tb_cira_job_dispatch.sv:25-78,240-360`
- Modify: `tests/Makefile.cira_dispatch`

- [ ] **Step 1: Extend the dispatcher testbench with a writer-error input.**

  Add `logic wb_error;` to the DUT connection.  Make its fake writer expose
  `wb_done` only after a configurable delay and emit `wb_error` for one test
  completion.  Add checks that status sequence remains unchanged while the
  writer is busy and that failure uses the exact shared value:

  ```systemverilog
  localparam logic [31:0] ST_COMPLETION_IO = 32'hffff_0003;
  check(status_seq < submitted_seq, "status sequence waits for CXL.cache commit");
  check(status_code == ST_COMPLETION_IO, "writer error is terminal completion I/O status");
  check(wb_count == 1 && wb_seen_addr == 64'h0000_1234_5678_9a80,
        "dispatcher forwards completion HPA to writer");
  ```

- [ ] **Step 2: Run the current dispatch test and verify it fails on the new port/checks.**

  Run:

  ```bash
  make -C tests -f Makefile.cira_dispatch run
  ```

  Expected: compile failure because `wb_error` and completion-I/O status are
  absent from the dispatcher interface.

- [ ] **Step 3: Extend the dispatcher interface and state machine.**

  Add `input logic wb_error` next to `wb_done`/`wb_busy`, and the exact local
  status constant:

  ```systemverilog
  localparam logic [31:0] STATUS_COMPLETION_IO = 32'hffff_0003;
  ```

  When writeback is enabled, retirement must assert the existing
  `wb_kernel_done` request even for a zero completion address, then wait in
  the writeback state.  On `wb_error`, latch `STATUS_COMPLETION_IO` as the
  terminal status and publish the status line/sequence; on `wb_done`, publish
  the kernel status.  Do not publish status while `wb_busy` is true or before
  either terminal response.  The non-writeback configuration retains its
  present status-only behavior for simulation/legacy use.

- [ ] **Step 4: Run dispatch regression and lint.**

  Run:

  ```bash
  make -C tests -f Makefile.cira_dispatch run
  make -C tests -f Makefile.cira_dispatch lint
  ```

  Expected: the original acceptance/rejection coverage plus delayed writer and
  writer-error checks pass; dispatcher lint is clean.

- [ ] **Step 5: Commit dispatch ordering.**

  ```bash
  git add hardware_test_design/common/rv64/cira_job_dispatch.sv tests/tb_cira_job_dispatch.sv tests/Makefile.cira_dispatch
  git commit -m "feat(rtl): retire CIRA jobs after cache completion"
  ```

### Task 6: Connect the writer to generated AXI2CCIP channel 1

**Files:**

- Modify: `hardware_test_design/common/afu/afu_top.sv:526-548,1146-1200`
- Modify: `hardware_test_design/ed_top_wrapper_typ2.sv:382-435,1867-1960,2500-2925`
- Modify: `hardware_test_design/common/cust_afu/cust_afu_wrapper.sv:55-150`
- Modify: `hardware_test_design/cxltyp2_ed.qsf:225-240,475-490`

- [ ] **Step 1: Write a structural source test before editing integration.**

  Add a shell-free Verilator lint target to `tests/Makefile.cira_cache_writer`
  that compiles the writer with a tiny wrapper exposing AXI1 widths.  Its
  assertions must use `awuser == 7'b0000010` and show no `target_hdm` bit is
  set.  This test remains independent of generated encrypted IP.

- [ ] **Step 2: Export writeback handshakes from `afu_top`.**

  Add these ports to the common tail of the `afu_top` port list, after the
  external Vortex/Concordia control ports so every slice configuration sees
  the same signals:

  ```systemverilog
  , output logic        cira_ccip_wb_valid
  , output logic [31:0] cira_ccip_wb_status
  , output logic [63:0] cira_ccip_wb_result
  , output logic [63:0] cira_ccip_wb_hpa
  , input  logic        cira_ccip_wb_busy
  , input  logic        cira_ccip_wb_done
  , input  logic        cira_ccip_wb_error
  ```

  Replace `CIRA_WB_ENABLE = 1'b0` with `1'b1`, connect dispatcher writeback
  outputs to the new `cira_ccip_wb_*` outputs, and connect its `wb_busy`,
  `wb_done`, and new `wb_error` inputs to the three response ports.  Remove
  the obsolete comments that describe HDM writer re-enablement; do not connect
  `vortex_dcoh_writeback.sv`.

- [ ] **Step 3: Add wrapper-level CIRA request/response wires and writer instance.**

  Near the existing `gpu_*_from_afu` declarations in `ed_top_wrapper_typ2.sv`,
  declare the seven `cira_ccip_wb_*` wires plus the writer's complete AXI
  write-channel signals.  Instantiate:

  ```systemverilog
  cira_cxl_cache_completion_writer cira_cache_completion_writer_inst (
      .clk(ip2hdm_clk), .rst_n(ip2hdm_reset_n),
      .req_valid(cira_ccip_wb_valid), .req_status(cira_ccip_wb_status),
      .req_result(cira_ccip_wb_result), .req_completion_hpa(cira_ccip_wb_hpa),
      .req_busy(cira_ccip_wb_busy), .req_done(cira_ccip_wb_done),
      .req_error(cira_ccip_wb_error),
      // connect cira_axi1_aw*, cira_axi1_w*, and cira_axi1_b* signals
  );
  ```

  Add the same seven named connections to `afu_top_inst`.  All signals are in
  `ip2hdm_clk`; do not insert an unnecessary CDC block.

- [ ] **Step 4: Insert the write arbiter on AXI1 while retaining ATE reads.**

  Rename only the existing ATE **write** connections at
  `afu_atomic_test_engine` to `ate_axi1_aw*`, `ate_axi1_w*`, and `ate_axi1_b*`.
  Keep its AR/R connections directly on physical `axi1_ar*`/`axi1_r*`.  Then
  instantiate `cira_axi2ccip_write_arbiter` with ATE as master 0, CIRA as
  master 1, and physical `axi1_aw*`, `axi1_w*`, `axi1_b*` as its output.

  Make the same write-net renaming in the `BYPASS_ATE` branch, where
  `cust_afu_wrapper` is master 0.  Widen that wrapper's `awuser` declaration
  from `[5:0]` to `[6:0]` and retain its all-zero assignment, so the conditional
  diagnostic build has the same physical AXI1 width as the generated IP.
  Do not alter either branch's ATE/cust read connection.

- [ ] **Step 5: Add only the new source files to the Quartus project.**

  Add adjacent to the existing CIRA dispatcher assignment:

  ```tcl
  set_global_assignment -name SYSTEMVERILOG_FILE ./common/rv64/cira_cxl_cache_completion_writer.sv
  set_global_assignment -name SYSTEMVERILOG_FILE ./common/axi_to_avst/cira_axi2ccip_write_arbiter.sv
  ```

  Do not regenerate or modify `intel_rtile_cxl_top_cxltyp2_ed.ip`, pin Tcl,
  HDM decoder settings, or the Vortex Port1/MC arbiter.

- [ ] **Step 6: Run all local RTL regressions and a Quartus map/elaboration gate.**

  Run:

  ```bash
  make -C tests -f Makefile.cira_cache_writer run
  make -C tests -f Makefile.cira_axi2ccip_arbiter run
  make -C tests -f Makefile.cira_dispatch run
  quartus_map cxltyp2_ed
  ```

  Expected: all Verilator tests pass and Quartus map completes without width,
  multiple-driver, or missing-source errors.  A map pass is an elaboration
  gate, not a hardware completion claim.

- [ ] **Step 7: Commit the top-level integration.**

  ```bash
  git add hardware_test_design/common/afu/afu_top.sv hardware_test_design/ed_top_wrapper_typ2.sv hardware_test_design/common/cust_afu/cust_afu_wrapper.sv hardware_test_design/cxltyp2_ed.qsf
  git commit -m "feat(rtl): route CIRA completion through CXL cache"
  ```

### Task 7: Run the complete evidence ladder and preserve proof artifacts

**Files:**

- Modify only if needed for reproducible commands: `tests/Makefile.cira_cache_writer`, `tests/Makefile.cira_axi2ccip_arbiter`, `tests/Makefile.cira_dispatch`
- Do not change generated IP, QSF pin assignments, or unrelated dirty files.

- [ ] **Step 1: Run both repository test suites from clean build directories.**

  Run:

  ```bash
  cmake --build /home/victoryang00/CXLMemUring/build -j"$(nproc)"
  ctest --test-dir /home/victoryang00/CXLMemUring/build --output-on-failure
  make -C /root/ia780i_type2_delay_buffer_new/tests -f Makefile.cira_cache_writer run
  make -C /root/ia780i_type2_delay_buffer_new/tests -f Makefile.cira_axi2ccip_arbiter run
  make -C /root/ia780i_type2_delay_buffer_new/tests -f Makefile.cira_dispatch run
  ```

  Expected: all runtime and focused RTL tests pass.  Report failures with the
  first failing command and log path; do not weaken the strict HPA gate.

- [ ] **Step 2: Run full synthesis and retain timing evidence.**

  Run from `hardware_test_design`:

  ```bash
  quartus_sh --flow compile cxltyp2_ed
  ```

  Record the final fit/STA/assembler result and exact report paths.  A fresh
  SOF is required before programming hardware; fitter completion alone is not
  enough.

- [ ] **Step 3: Perform target-host CXL.cache proof.**

  Before execution, verify the programmed SOF timestamp, endpoint enumeration,
  and that the CXL.cache path is active.  Register a 64-byte host completion
  page through either `cira_register_linear_region()` with the driver-provided
  HPA or `CIRA_CXL_CACHE_DEV`; submit one CIRA call; capture AXI1/CCIP monitor
  evidence showing `target_hdm=0`, full payload response before the partial
  magic request, and successful commit response.  Then show the CPU observes
  `magic=0xDEADBEEF`, fields, and a success sequence in order.

- [ ] **Step 4: Commit any reproducibility-only test harness changes.**

  ```bash
  git add tests/Makefile.cira_cache_writer tests/Makefile.cira_axi2ccip_arbiter tests/Makefile.cira_dispatch
  git diff --cached --check
  git commit -m "test: document CXL cache completion verification"
  ```

  Skip this commit when no test-harness file changed; never commit build logs,
  SOFs, generated databases, or unrelated user modifications.

## Plan self-review

- **Spec coverage:** Tasks 1-2 implement the trusted HPA descriptor contract;
  Tasks 3-4 implement and test the ordered CXL.cache writer and AXI1 sharing;
  Tasks 5-6 connect response ordering through dispatcher/top-level/QSF; Task 7
  provides runtime, RTL, Quartus, and physical CXL.cache proof gates.
- **Placeholder scan:** no TODO/TBD/"appropriate error handling" steps; each
  code change names an exact file, interface, condition, and verification
  command.
- **Type consistency:** completion HPA is `uint64_t`/`logic [63:0]`; physical
  AXI1 uses 12-bit IDs, 7-bit AWUSER, 512-bit WDATA, and 64-bit WSTRB across
  writer, arbiter, and wrapper; terminal status is `0xffff0003` in C and RTL.
