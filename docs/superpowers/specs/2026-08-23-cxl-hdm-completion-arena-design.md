# CXL-HDM Completion Arena Design

**Status:** superseded by `2026-08-23-cxl-cache-llc-completion-writeback-design.md`

## Goal

Close CIRA's hardware offload completion path on the IA-780I Type-2 design.
For a hardware-dispatched job, the Vortex-side completion writer must update a
64-byte completion record in device HDM that is mapped by the host process.
The existing `cira_future_await()` wait remains a cache-line wait on the host
virtual mapping, while the descriptor carries the device-visible HDM address.

## Scope and terminology

This design implements a **CXL-HDM completion arena**.  It does not implement
or claim a CXL.cache D2H request that directly installs a line in the host
LLC.  The CPU and device observe one CXL-HDM-backed cache line through their
respective mappings; host-side cache coherency makes the completed record
observable to `UMWAIT`/the selected wait backend.

The two repositories participating in this work are:

| Repository | Role |
| --- | --- |
| `/home/victoryang00/CXLMemUring` | CIRA compiler and host runtime |
| `/root/ia780i_type2_delay_buffer_new` | IA-780I Type-2 RTL and Quartus project |

No generated IP, pin assignment, existing legacy Vortex CSR, or unrelated
Concordia logic is in scope.

## Current evidence and gap

The CIRA host/device wire format is already defined by
`runtime/include/cira_cxl_job.h`: a job descriptor contains one
`completion_addr`, and completion magic is `0xDEADBEEF`.

`cira_job_dispatch.sv` is included in the current QSF and its standalone
Verilator protocol test passes 36 checks.  The dispatcher is also connected to
the Vortex launch path in `afu_top.sv`.  However, `afu_top.sv` sets
`CIRA_WB_ENABLE` to zero and ties the dispatcher writeback response off.  The
runtime currently creates ordinary heap-backed futures with `posix_memalign()`
and passes that virtual pointer as `completion_addr`.  Neither behavior is
valid for a real device-HDM write.

The existing `vortex_dcoh_writeback.sv` is only a 512-bit AXI writer.  It is
not a CXL.cache implementation, is not presently in the QSF, and publishes
magic in the same write as the payload.  It must be replaced or refactored as
an HDM completion writer with ordered publication.

## Contract after this change

### Completion arena

The runtime owns a process-local arena that maps a host-visible CXL-HDM
allocation.  It is configured explicitly with:

- `CIRA_CXL_COMPLETION_PATH`: the DAX/device file to map;
- `CIRA_CXL_COMPLETION_OFFSET`: mapping offset, default `0`;
- `CIRA_CXL_COMPLETION_BYTES`: arena length, a positive multiple of 64;
- `CIRA_CXL_COMPLETION_DEVICE_BASE`: device-visible address corresponding to
  the first byte of the mapping.

When all four are valid, hardware-capable future allocation returns a 64-byte
aligned entry in this mapping and records `host_va -> device_base + offset`.
The allocator must not use a heap address as a device address.  When no arena
is configured, existing emulation and host-only fallback behavior remains
available, but an attempted hardware submission with an untranslated
completion must fail closed and execute the existing software fallback rather
than ring a malformed doorbell.

The public future-pool registration API remains supported.  Registered entries
are a second valid source of the device address.  The arena is the default
source for `cira_future_alloc()` when hardware MMIO is enabled, so ordinary
compiler lowering no longer silently uses heap completions.

### Submission

The C wire layout is unchanged.  Add a device-address form of the submit
helper, while retaining the existing pointer-only helper for emulation and
source compatibility:

```c
int cira_mmio_submit_call_device(cira_mmio_window_t *window,
                                 void *func, void **operands,
                                 uint32_t num_operands,
                                 uint64_t completion_device_addr,
                                 uint64_t *out_seq);
```

`CiraRuntime.cpp` resolves the host completion pointer through the arena or a
registered region before using this helper.  The descriptor's
`cira_cxl_call_job_t.completion_addr` is therefore always a device HDM address;
the host pointer is retained only by the future/wait bookkeeping.

### RTL writeback and status ordering

Add a completion writer to the AFU clock domain.  It accepts the dispatcher
writeback request and emits two AXI writes to the same 64-byte aligned HDM
line:

1. Write `status`, `result`, `cycles`, `timestamp`, and reserved bytes with
   byte lanes 0--3 disabled.
2. Wait for a successful AXI write response, then write only bytes 0--3 with
   `CIRA_CXL_COMPLETION_MAGIC`.

The second write response completes the writer.  A non-OKAY response reports
an I/O writeback failure to the dispatcher; it must not produce a success
completion.  The dispatcher publishes its status-line sequence only after the
completion writer reports completion, preserving the existing two-channel
ordering rule.

The writer uses HDM Channel 1, the same device-memory target already shared by
host DAX traffic and Vortex Port 1.  The target remains explicitly marked as
HDM/device memory.  This is why the module will be named
`cira_hdm_completion_writeback`, rather than DCOH.

### AXI arbitration

Replace the two-master Channel-1 arbiter at this integration point with a
three-master version:

- master 0: host HDM Channel-1 traffic;
- master 1: Vortex Port-1 traffic;
- master 2: CIRA HDM completion writer.

The arbiter must preserve AXI write-address/data ownership until `WLAST`, use
non-overlapping response-ID tags for all three requesters, and route B/R
responses only to their originating master.  Read arbitration remains for
masters 0 and 1; the completion writer is write-only.  The legacy two-master
arbiter is left untouched so unrelated users retain their tested topology.

`afu_top.sv` instantiates the new arbiter, connects the completion writer to
master 2, enables dispatcher writeback, and connects its busy/done/status
signals.  The QSF includes the new writer and arbiter sources.

## Failure handling

- Unconfigured or malformed completion-arena configuration: no hardware
  descriptor is submitted; software fallback completes the future.
- Untranslated completion address in strict-MMIO mode: return a diagnostic
  submit failure instead of treating a host virtual address as HDM.
- Misaligned completion address: reject before starting AXI traffic.
- AXI `BRESP` error on either write: mark the job with a defined completion
  I/O error and publish the status line only after the error is known.
- A second job cannot reuse an arena entry until its host future is released
  or explicitly re-armed.

## Verification plan

1. Add a SystemVerilog unit test for the HDM writer.  Verify address
   alignment, first-write strobes, magic-last ordering, backpressure, and both
   AXI response-error paths.
2. Add a three-master arbiter test.  Exercise host/Vortex/completion contention
   and verify write-data lock ownership plus B/R ID routing.
3. Extend the dispatcher integration test with a modeled HDM line.  Verify
   that completion magic becomes visible before `cira_mmio_wait_completion()`
   would release and that the status sequence follows writer completion.
4. Extend the runtime offload-path test with a mapped test arena and a known
   device base.  Verify that the submitted descriptor contains the device
   address while the waiter observes the host mapping.  Add an untranslated
   future test proving hardware submission fails closed.
5. Run the runtime CTest suite and Verilator lint/regressions.  These prove
   host/runtime and RTL behavior only.
6. Run a Quartus compile.  Completion of fitter or assembler alone is not
   sufficient: retain final STA, fresh SOF, and build-report evidence.
7. On the target host, map the actual CXL-HDM arena, submit a Vortex kernel,
   and prove the returned completion record and status sequence.  This is the
   first gate that proves physical CXL-HDM visibility.

## Acceptance criteria

- A real hardware descriptor never contains a host virtual completion pointer.
- An RTL completion transaction writes one aligned 64-byte CIRA record with
  magic published only after its payload response succeeds.
- `cira_future_await()` observes a completion written through the HDM path.
- The host status sequence is not visible before completion writeback is done.
- Existing emulator, host-only fallback, legacy Vortex CSR, and host HDM
  traffic regressions remain passing.
- Hardware claims stop at verified CXL-HDM completion visibility; no result is
  labeled as direct CXL.cache LLC writeback without separate interface-level
  proof.
