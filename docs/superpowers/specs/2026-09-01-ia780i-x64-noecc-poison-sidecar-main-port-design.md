# IA-780I x64 No-ECC EMIF, Poison Sidecar, and CXL.cache Main-Port Design

**Status:** approved for specification; pending implementation-plan review

## Goal

Retarget the latest `origin/main` design to the IA-780I device
`AGIB023R18A1E1V`, use both external DDR4 channels as 64-bit data interfaces
without ECC DQ pins, preserve CXL poison semantics in a separate sidecar, and
port only the reviewed CIRA CXL.cache completion writeback from commit
`606178f`.

The final Quartus build must use the exact IA-780I device, generate a fresh
SOF, and have nonnegative setup, hold, recovery, and removal slack.  A
successful assembler run alone is not timing-closure evidence.

## Source and integration boundary

Implementation starts from the latest reviewed remote main baseline:

- repository: `/root/ia780i_type2_delay_buffer_new`;
- isolated implementation worktree:
  `/root/ia780i_type2_main_x64_noecc`;
- baseline: `origin/main` at `6f64289`;
- implementation branch: `codex/ia780i-x64-noecc`.

The existing `vr2` worktree is not an implementation source.  Its board
retarget, PMBus changes, Qwen/Concordia additions, generated files, and
uncommitted `vortex_dcoh_writeback` smoke test remain out of scope.

The only functional completion-writeback port is commit `606178f`, including
its focused RTL tests and integration checker.  The earlier CXL-HDM completion
arena proposal remains superseded: CIRA completions target host memory through
CXL.cache, not device HDM.

## Board and device contract

`hardware_test_design/constraints/ia780i_pinout.tcl` is the board pin
authority.  The active Quartus project must:

- set `DEVICE` to `AGIB023R18A1E1V`;
- source `ia780i_pinout.tcl` exactly once;
- enable the `IA780I` Verilog macro;
- not source the VR2 development-kit pinout;
- not override the IA-780I device later in the QSF;
- retain the IA-780I PMBus-slave settings from the board pinout;
- expose 16 CXL transmit and 16 CXL receive lanes as assigned by the pinout.

The installed Quartus Pro 25.1 device database recognizes the part as Agilex
7 device `AGIB023R18A`, FBGA package, speed grade 1.

## External DDR4 contract

There are two independent DDR4 channels.  Each channel has:

- 64 data pins (`mem_dq[63:0]`);
- 8 DQS/DQS_n pairs;
- 8 DBI/DM pins;
- no DQ[71:64], ninth DQS pair, or ninth DBI pin.

The memory interface IP and all wrappers must agree with this physical
contract.  For the IA-780I configuration:

- external DQ width is 64 per channel;
- external DQS and DBI width is 8 per channel;
- Avalon-MM data width is 512 bits;
- Avalon-MM byte-enable width is 64 bits;
- the CXL/HDM cache-line payload remains 512 bits;
- EMIF controller ECC is disabled;
- ALTECC 64-to-72 encoding and 72-to-64 decoding are not on the active data
  path;
- generated EMIF RTL must not expose 72-bit DQ or 576-bit Avalon-MM ports.

The two x64 EMIF instances and the shared two-channel calibration IP must be
regenerated for `AGIB023R18A1E1V` with Quartus Pro 25.1.  Checked-in IP
metadata, generated synthesis products, QSF IP bindings, and wrapper widths
must be mutually consistent.  Hand-truncating a generated 72-bit interface to
64 pins is not acceptable.

## Host-visible capacity and private metadata region

The current controller maps 8 GiB per channel, 16 GiB total.  Each channel
reserves its top 128 MiB for device-private metadata:

- host-visible data per channel: 7.875 GiB;
- host-visible aggregate HDM: 15.75 GiB;
- private metadata aggregate: 256 MiB.

The CXL device capacity advertisement, channel bounds checks, address mapping,
RAM initialization range, and runtime-visible HDM limits must all stop at the
15.75 GiB data boundary.  Host or Vortex data traffic must never reach the
private metadata range.

Only 16 MiB of each channel's private region is required for the initial
poison bitmap.  The remaining private space is reserved for alignment,
metadata growth, and implementation guard space; it must not be advertised as
ordinary HDM.

## Poison sidecar format

Poison is tracked at the existing CXL memory-controller granularity: one bit
per 64-byte data cache line.

For each channel:

- local data-line index is derived after the existing channel-interleave
  selection;
- one 512-bit metadata line contains poison bits for 512 consecutive data
  lines;
- metadata-line index is `data_line_index >> 9`;
- poison-bit select is `data_line_index[8:0]`;
- metadata addresses are based in the channel's private region and cannot
  alias data addresses.

The mapping is deterministic and shared by reads, full writes, partial-write
RMW, initialization, and verification logic.  Constants describing the data
limit, metadata base, bitmap size, and granularity live in one package rather
than being repeated as numeric literals.

## Poison sidecar microarchitecture

Each memory channel receives an independent sidecar controller in the EMIF
clock domain.  It contains:

1. a banked on-chip summary with one bit per bitmap metadata line;
2. a small tagged metadata-line cache;
3. an update/read sequencer that shares the channel's Avalon-MM interface
   without violating data-request ownership;
4. explicit completion signals to the existing RMW/read-response path.

The summary is reset to zero.  If a summary bit is zero, the corresponding
bitmap line is logically all zero and need not be read from DDR.  The first
poison insertion into such a line starts from a synthesized all-zero metadata
line, avoiding a boot-time 32 MiB scrub.  A summary bit is set only after the
updated metadata line has been accepted by EMIF.  Clearing the final poison
bit clears the corresponding summary bit.

The sidecar cache is write-through.  It accelerates repeated poison accesses
but is not the source of persistence.  Eviction cannot lose an update.
Poison is preserved across ordinary data writes and reads during the active
device session; persistence across device reset or power loss is not claimed.

## Read and write semantics

### Full-line write

- a write with `write_poison=1` stores the data line and sets its sidecar bit;
- a clean full-line overwrite stores the data line and clears its sidecar bit;
- the upstream write is complete only after both required data and sidecar
  operations are accepted;
- a sidecar operation cannot be reported as successful before the matching
  data operation.

### Partial write

The existing read-modify-write poison rule is retained.  The resulting poison
is the incoming write poison OR the previously stored line poison.  The
merged data and merged poison bit are committed as one logical operation.

### Read

- a zero summary bit produces `read_poison=0` without a bitmap DDR read;
- a set summary bit resolves the bitmap line and selected poison bit before
  the CXL read response is released;
- returned payload data is always the 512-bit x64-EMIF data line;
- `read_poison` is sourced from the sidecar, never from absent ECC parity
  bits or ALTECC syndrome outputs.

The existing CXL poison counters and response wiring remain active, but their
source changes from ECC decoder fatal status to sidecar state.

## Arbitration and forward progress

Sidecar metadata traffic is internal to each channel and has lower priority
than a data operation already in progress.  Once a logical operation starts,
data, metadata, and response ownership remain associated until completion.
Metadata traffic must not steal or misroute an Avalon-MM read response.

The controller permits bounded backpressure and must not deadlock when a
partial write needs both a data read and a bitmap update.  Assertions cover:

- data/metadata address non-aliasing;
- one owner per Avalon-MM response;
- no upstream completion before required metadata completion;
- no stale poison return after a clean full-line overwrite;
- no lost poison after metadata-cache eviction.

## CIRA CXL.cache completion writeback

Port the reviewed behavior from `606178f` without changing its protocol
contract:

- a completed CIRA job writes one 64-byte completion record to a trusted,
  aligned host HPA through AXI2CCIP channel 1;
- `target_hdm=0` and D2H coherency remain mandatory;
- payload bytes are written first as a complete coherent cache-line write;
- the writer waits for an OKAY B response before issuing the partial commit;
- completion magic `0xDEADBEEF` is published last using the supported partial
  `WrInv` form;
- zero or misaligned HPAs emit no AXI request and terminate with completion-I/O
  error;
- a payload or commit response error cannot produce a successful future;
- the atomic-test engine remains connected through the reviewed write
  arbiter;
- Vortex device-memory traffic remains on its existing HDM path.

The host runtime contract remains the approved trusted-HPA contract.  Raw heap
virtual addresses, pagemap fallbacks, CXL.io writes, raw TLP bypasses, and HDM
completion fallbacks are not valid substitutes for CXL.cache proof.

## Timing-closure strategy

Initial implementation retains the intended clocks.  Frequency reduction is
not the first-line closure mechanism and requires separate user approval.

Timing work proceeds by path class:

1. fix functional elaboration and exact-device/EMIF legality;
2. pipeline the Vortex D-cache replacement-to-data-RAM path if it remains the
   worst setup path;
3. synchronize reset deassertion independently in every destination clock
   domain and constrain asynchronous assertion/synchronous deassertion
   correctly;
4. isolate poison summary/cache lookup from long combinational address and
   response paths with registered request/response boundaries;
5. apply only endpoint-specific CDC or false-path constraints backed by the
   implemented synchronizer topology;
6. iterate placement, physical synthesis, and seed only after structural path
   causes are addressed.

No broad false path may hide a real synchronous data, response, recovery, or
removal violation.

## Verification

### Static contract checks

Automated checks fail closed unless all of the following agree:

- exact device `AGIB023R18A1E1V`;
- IA-780I pinout is active and no later device override exists;
- `IA780I` macro is active;
- 64 DQ and 8 DQS/DBI per channel;
- 512-bit EMIF Avalon-MM data and 64-bit byte enable;
- EMIF ECC disabled and active ALTECC encode/decode absent;
- host-visible capacity 15.75 GiB;
- metadata ranges are outside host-visible data ranges;
- required CIRA CXL.cache sources and generated IP bindings are present once.

### Focused RTL tests

Tests cover:

- sidecar address mapping and channel independence;
- clean read fast path;
- poisoned full write and poisoned readback;
- clean full-line poison clearing;
- partial-write poison merge;
- metadata cache hit, miss, eviction, and write-through ordering;
- summary first-set and last-clear behavior;
- data/metadata contention and backpressure;
- reset behavior;
- reviewed CIRA completion writer, write arbiter, and dispatcher regressions.

### Build and timing gates

Run focused Verilator tests, lint/elaboration, IP generation checks, and a full
Quartus compile using:

```sh
export LM_LICENSE_FILE=/opt/altera_pro/25.1/lic_qsim_24_any.dat
quartus_sh --flow compile cxltyp2_ed
```

Final build evidence includes the complete compile log, exact-device report,
EMIF interface report, resource report, final TimeQuest summary, fresh SOF
timestamp, and SOF SHA-256.

Timing closure requires all reported setup, hold, recovery, and removal slack
to be nonnegative.  Unconstrained-path and ignored-constraint reports must be
reviewed; zero failing paths obtained by excluding endpoints is not accepted.

### Hardware proof boundary

Quartus completion proves buildability, not CXL.cache behavior.  Hardware
acceptance additionally requires:

- both x64 DDR channels calibrate on IA-780I;
- normal and poisoned CXL.mem write/read tests demonstrate sidecar behavior;
- captured AXI2CCIP/CXL.cache request and response activity demonstrates the
  completion used `target_hdm=0`;
- the host CPU observes the exact completion payload and magic-last ordering.

Claims stop at the strongest captured evidence.  No fixed physical LLC-way
residency is claimed because CXL.cache guarantees coherent visibility rather
than permanent placement in a particular LLC way.

## Acceptance criteria

- The build targets exactly `AGIB023R18A1E1V` and uses the IA-780I pinout.
- Each DDR channel is physically and logically x64 with no external ECC DQ.
- No active 576-bit or 72-bit ECC data path remains in the IA-780I EMIF path.
- Host-visible HDM is 15.75 GiB and cannot address the private metadata area.
- Poison survives data write/read and metadata-cache eviction, and is cleared
  by a clean full-line overwrite.
- The reviewed CIRA completion reaches host memory only through CXL.cache.
- Qwen/Concordia, VR2 board changes, and unreviewed smoke-test RTL are absent.
- Focused regressions pass.
- Full Quartus compile produces a fresh SOF.
- Setup, hold, recovery, and removal slack are all nonnegative.
