# CXL.cache LLC Completion Writeback Design

**Status:** approved for implementation

## Goal

Implement CIRA's paper-facing DCOH completion path as a real CXL.cache
device-to-host coherent write, rather than as an HDM or CXL.io write.  A
completed Vortex job writes its 64-byte `cira_cxl_completion_t` to a
host-DRAM cache line through the generated AXI-to-CCIP bridge.  The host then
observes the same line through `cira_future_await()`.

This design uses "LLC writeback" in the protocol-correct sense: the write is
accepted by the host CXL.cache coherence agent and is visible to the host cache
hierarchy.  CXL.cache does not expose an architectural promise that a line
occupies a particular physical LLC way at an arbitrary instant, so acceptance
will be proven by coherent request/response and CPU visibility, not by a claim
of fixed LLC residency.

## Scope and existing evidence

| Repository | Role |
| --- | --- |
| `/home/victoryang00/CXLMemUring` | CIRA compiler/runtime and C ABI |
| `/root/ia780i_type2_delay_buffer_new` | IA-780I Type-2 RTL and Quartus project |

The CIRA wire contract remains `runtime/include/cira_cxl_job.h`: a job holds a
64-bit `completion_addr`, records are 64-byte aligned, and `0xDEADBEEF` is the
completion magic published last.

The active hardware path is incomplete:

- `cira_job_dispatch.sv` is already in the QSF, launches Vortex work, and has
  writeback request outputs, but `afu_top.sv` sets `CIRA_WB_ENABLE` to zero.
- `vortex_dcoh_writeback.sv` is an unused HDM-style AXI writer.  It cannot
  establish CXL.cache semantics and currently publishes magic with payload.
- Vortex Host Port0 is tied off in both `vortex_gpu_wrapper.sv` and
  `afu_top.sv`.  Vortex Port1 reaches device HDM through `axi_mc_arbiter` and
  must not be reused for host completion writes.
- The generated IP exposes two AXI-to-CCIP channels.  `ed_top_wrapper_typ2.sv`
  sends its cache-demux output to `axi0`; `axi1` is a second `axi2ccip` channel
  currently driven by `afu_atomic_test_engine`.  It is the available coherent
  attachment point for the completion writer once arbitrated.

The pre-existing CAFU source establishes the allowed coherent attributes:
`eWR_CAFU_I_SO` maps a complete cache-line write to `ItoMWr` and a byte-strobe
partial write to `WrInv` in the enabled WSC0 configuration.  The writer will
emit the corresponding packed AXI user value
`{AtomicSwapIfEM=0, target_hdm=0, do_not_send_d2hreq=0,
opcode=eWR_CAFU_I_SO}`.  `target_hdm=0` is mandatory: HDM writes are not an
acceptable fallback.

## Architecture

### 1. CIRA coherent completion writer

Create `hardware_test_design/common/rv64/cira_cxl_cache_completion_writer.sv`.
It is a single-entry, write-only AXI master clocked by `ip2hdm_clk`, accepting
the dispatcher signals `{kernel_done, status, result, completion_hpa}` and
returning `{busy, done, error}`.  It rejects zero or non-64-byte-aligned HPAs
before emitting any AXI request.

For an accepted completion it emits exactly two single-beat, 512-bit AXI
transactions on the coherent AXI2CCIP channel:

1. **Payload:** a 64-byte line whose bytes 4--63 contain `status`, `result`,
   `cycles`, `timestamp`, and zeroed reserved bytes; bytes 0--3 carry zero.
   `AWSIZE=6`, `AWLEN=0`, `AWBURST=FIXED`,
   `WSTRB=64'hffff_ffff_ffff_ffff`, and the coherent `ItoMWr` attributes
   above are used.  The writer waits for an `OKAY` B response.
2. **Commit:** the same line address, the same coherent write attributes, and
   a 512-bit beat with only `WSTRB[3:0]=4'hf`; bytes 0--3 contain
   `CIRA_CXL_COMPLETION_MAGIC`.  Under WSC0 this is the supported partial
   `WrInv` form.  Only an `OKAY` response makes `done` true.

The commit request is never issued after an error response from the payload
request.  Backpressure on AW, W, and B is legal.  No request is interleaved
between the address and data phases of either write.  The writer does not read,
modify, or preserve the 32 reserved bytes: a CIRA future is armed to all zero
before submission and the completion record owns the complete line.

### 2. AXI2CCIP channel-1 arbitration

Create `hardware_test_design/common/axi_to_avst/cira_axi2ccip_write_arbiter.sv`.
It combines exactly two write masters into the physical `axi1` AXI2CCIP
channel:

- existing `afu_atomic_test_engine` (master 0), retained for validation;
- the CIRA completion writer (master 1).

Only write channels are arbitrated.  The atomic-test engine retains the
existing read connection directly to `axi1`; the completion writer has no read
interface.  Arbitration accepts a request only after it has selected one
master, holds selection through the matching W handshake, and routes the B
response to the selected requester.  The writer permits one outstanding
request, so B routing is unambiguous.  The arbiter must not modify AWUSER,
AWCACHE, address, data, strobe, or response values.

This is deliberately on `axi1`, not `axi0`: `axi0` is under CAFU cache/IO
selection and changing it would entangle runtime CIRA traffic with the
compliance-AFU mode machine.  `axi1` is exported by the generated IP as a
separate `axi2ccip_*_ch1` interface.  The implementation keeps the generated
IP and pin/HDM configuration unchanged.

### 3. Dispatcher-to-top integration

`afu_top.sv` exposes the dispatcher's completion request and accepts the
writer's response as dedicated ports:

```systemverilog
output logic        cira_ccip_wb_valid;
output logic [31:0] cira_ccip_wb_status;
output logic [63:0] cira_ccip_wb_result;
output logic [63:0] cira_ccip_wb_hpa;
input  logic        cira_ccip_wb_busy;
input  logic        cira_ccip_wb_done;
input  logic        cira_ccip_wb_error;
```

`ed_top_wrapper_typ2.sv` wires these ports to the writer and connects the
writer/ATE arbiter to `axi1`.  The old HDM `vortex_dcoh_writeback.sv` remains
unused and is not added to the active implementation.

`cira_job_dispatch.sv` is extended with `wb_error`.  With writeback enabled,
it sends every retired hardware job to the writer, including a malformed zero
completion address; it does not take a silent status-only success path.  It
continues to publish the status window at `0x1f20`, but only after either a
successful commit or a writer error.  A writer error publishes the new defined
terminal status `CIRA_CXL_STATUS_COMPLETION_IO = 0xffff0003` and does not
claim a successful completion.

### 4. Runtime device-address contract

An ordinary process virtual address is not a CXL.cache target address.  Add:

```c
int cira_mmio_submit_call_device(cira_mmio_window_t *window, void *func,
                                 void **operands, uint32_t num_operands,
                                 uint64_t completion_hpa,
                                 uint64_t *out_seq);
```

It differs from the legacy `cira_mmio_submit_call()` only in the value placed
in `cira_cxl_call_job_t.completion_addr`.  The existing pointer-form helper
remains for emulation and source compatibility.

Before a real MMIO hardware submit, `CiraRuntime.cpp` resolves the future
pointer with this strict order:

1. `cira_translate_registered_addr()` for a region explicitly registered by
   the application; or
2. the existing `CIRA_CXL_CACHE_DEV` translation ioctl, which owns any needed
   page pinning/IOMMU mapping and returns `device_addr` or `host_phys_addr`.

The result must be nonzero and 64-byte aligned.  The hardware path must not
use virtual addresses, `/proc/self/pagemap`, reverse-engineered LLC encodings,
or `cira_translate_paddr()` fallback modes.  If neither trusted translation
succeeds, submission fails closed before the doorbell and CIRA uses its
existing software completion fallback.  The translation's pin/mapping lifetime
must cover `cira_future_await()` and `cira_future_free()`; the driver ioctl is
the authority for its release protocol.

## Failure behavior

- zero/misaligned completion HPA: no AXI traffic; terminal completion-I/O
  error is reported through the status window;
- payload or commit `BRESP != OKAY`: no success magic is committed; terminal
  completion-I/O error follows after the response;
- untranslatable future pointer: the runtime never rings the doorbell and
  falls back to its current software completion path;
- cache-route activity is never redirected to HDM, CXL.io, or a raw TLP
  bypass.

## Verification plan

1. Add a standalone SystemVerilog testbench for the writer.  Check complete
   `ItoMWr` attributes, `target_hdm=0`, payload/commit byte lanes, magic-last,
   AW/W/B backpressure, misalignment rejection, and B-response error paths.
2. Add an arbiter testbench that creates ATE/CIRA contention, verifies
   address-data ownership, response return, and unmodified CIRA attributes.
3. Extend `tb_cira_job_dispatch.sv` with success and writer-error retirement
   cases.  Assert that status sequence publication is after writer completion
   and that writer errors are terminal failures.
4. Extend `runtime/test/test_cira_offload_path.cpp` to inspect a submitted
   device-form job descriptor, verify the HPA value is preserved, and reject a
   zero HPA.  Add a runtime test that an unregistered heap future cannot reach
   the hardware submit helper.
5. Run the focused Verilator tests, runtime tests, and a Quartus elaboration/
   compile.  Compile success is only build evidence.
6. On the target host, trace `axi1`/CCIP request and response signals (or the
   platform's equivalent CXL.cache monitor), submit an HPA-backed future, and
   show that the CPU sees magic, payload, and status sequence in order.  This
   is the hardware proof gate; it must not be replaced by an HDM/DAX test.

## Acceptance criteria

- Every hardware completion writes the host address only through AXI2CCIP
  CXL.cache with `target_hdm=0` and D2H coherence enabled.
- `CIRA_CXL_COMPLETION_MAGIC` is observable only after the payload B response
  has succeeded.
- A failed write response cannot yield a successful future or status sequence.
- The host runtime never places a raw heap VA in a real hardware descriptor.
- Existing ATE reads/writes, Vortex device-memory access, control-window
  status completion, and emulation continue to work.
- A final hardware claim is limited to captured CXL.cache traffic plus CPU
  observation of the exact completion record.
