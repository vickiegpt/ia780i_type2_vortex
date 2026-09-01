//
// cira_job_dispatch.sv
//
// Device-side implementation of the CIRA CXL Type-2 job protocol.
//
// This is the RTL counterpart of runtime/include/cira_cxl_job.h. The host
// stages a job descriptor in the control window, then commits a doorbell whose
// sequence number is written last; this module polls the doorbell, validates
// the descriptor, launches the Vortex RISC-V core, and republishes the result
// so the host can observe completion.
//
// Control window layout (byte offsets, 64-bit accesses, must match the header):
//
//   0x0000  doorbell        magic / version / job_id / flags / status / seq
//   0x0100  arg slot 0      header {magic, version, job_id, seq, arg_len}
//   0x0500  arg slot 1        followed by the job payload
//   0x0900  arg slot 2
//   0x0D00  arg slot 3
//   0x1100  arg slot 4      (CIRA_CXL_JOB_CALL)
//   0x1E00  kernel entry table  (RTL extension, see below)
//   0x1F20  host status     magic / version / job_id / status / seq
//
// Kernel entry table (0x1E00 + job_id*8) is an addition to the header's
// layout. The prefetch job ids carry no code pointer -- the host names an
// operation, not a kernel -- so the loader programs the device-resident entry
// point for each of those ids once, at init, and the doorbell then selects
// among them. Job id CALL ignores the table and uses func_addr from its
// payload. The region sits inside the reserved span between the last arg slot
// and the status line, so it costs the host contract nothing.
//
// Completion is reported on two independent channels, both of which the host
// runtime already understands:
//
//   1. the status line at 0x1F20, polled with cira_mmio_wait_seq(); and
//   2. a 64-byte completion line written through CXL.cache to the address
//      named in the job, polled with cira_mmio_wait_completion().  The address
//      is a cacheline-aligned host physical address supplied by the runtime's
//      registered-region or CXL.cache driver translation path.
//
// Channel 1 always runs. Channel 2 runs whenever wb_enable is set.  An absent
// or invalid completion address is intentionally passed to the writer so it
// returns a completion-I/O failure instead of permitting a false success.
//
module cira_job_dispatch #(
    // Byte-address width of the control window. 13 bits == 0x2000, which is
    // CIRA_CXL_CONTROL_BYTES; the status line at 0x1F20 does not fit in 12.
    parameter int ADDR_WIDTH = 13
) (
    input  logic                    clk,
    input  logic                    rst_n,

    // CSR slave: the host's view of the control window.
    input  logic                    csr_valid,
    input  logic                    csr_write,
    input  logic [ADDR_WIDTH-1:0]   csr_addr,
    input  logic [63:0]             csr_wdata,
    output logic                    csr_ready,
    output logic [63:0]             csr_rdata,

    // Launch handshake to the Vortex wrapper.
    output logic                    job_launch_valid,
    input  logic                    job_launch_ready,
    output logic [63:0]             job_kernel_addr,
    output logic [63:0]             job_kernel_args,
    output logic                    job_speculative,

    // Retirement from the Vortex wrapper.
    input  logic                    job_done,
    input  logic [31:0]             job_status,
    input  logic [63:0]             job_result,

    // Completion-line writeback through the CXL.cache AXI port.
    output logic                    wb_kernel_done,
    output logic [31:0]             wb_kernel_status,
    output logic [63:0]             wb_kernel_result,
    output logic [63:0]             wb_completion_addr,
    input  logic                    wb_enable,
    input  logic                    wb_done,
    input  logic                    wb_error,
    input  logic                    wb_busy,

    // Debug / status observability.
    output logic [31:0]             dbg_jobs_accepted,
    output logic [31:0]             dbg_jobs_rejected,
    output logic [63:0]             dbg_last_seq,
    output logic [3:0]              dbg_state
);

    //=========================================================================
    // Protocol constants -- keep in lockstep with cira_cxl_job.h
    //=========================================================================

    localparam logic [63:0] CIRA_JOB_MAGIC      = 64'h565843584c4a4f42; // "VXCXLJOB"
    localparam logic [63:0] CIRA_PACC_JOB_MAGIC = 64'h4847505550414343; // "HGPUPACC"
    localparam logic [31:0] CIRA_JOB_VERSION    = 32'd1;

    localparam logic [31:0] JOB_NOP               = 32'd0;
    localparam logic [31:0] JOB_INSTALL_CACHELINE = 32'd1;
    localparam logic [31:0] JOB_PREFETCH_CHAIN    = 32'd2;
    localparam logic [31:0] JOB_STREAM_PREFETCH   = 32'd3;
    localparam logic [31:0] JOB_CALL              = 32'd4;
    localparam int          NUM_JOB_IDS           = 5;

    localparam logic [31:0] STATUS_SUCCESS     = 32'h0000_0000;
    localparam logic [31:0] STATUS_RUNNING     = 32'h0000_0001;
    localparam logic [31:0] STATUS_BAD_VERSION = 32'hffff_0001;
    localparam logic [31:0] STATUS_BAD_ARGS    = 32'hffff_0002;
    localparam logic [31:0] STATUS_COMPLETION_IO = 32'hffff_0003;
    localparam logic [31:0] STATUS_BAD_JOB     = 32'hffff_00ff;

    localparam logic [31:0] FLAG_SPECULATIVE = 32'h0000_0001;

    // Region bounds, all byte addresses inside the control window.
    // The doorbell starts at offset 0, so only its end bound is needed.
    localparam logic [ADDR_WIDTH-1:0] DOORBELL_END  = 'h0020;
    localparam logic [ADDR_WIDTH-1:0] ARG_BASE      = 'h0100;
    localparam logic [ADDR_WIDTH-1:0] ARG_END       = 'h1500; // 0x100 + 5*0x400
    localparam logic [ADDR_WIDTH-1:0] KENTRY_BASE   = 'h1E00;
    localparam logic [ADDR_WIDTH-1:0] KENTRY_END    = 'h1E40;
    localparam logic [ADDR_WIDTH-1:0] STATUS_BASE   = 'h1F20;
    localparam logic [ADDR_WIDTH-1:0] STATUS_END    = 'h1F40;

    // Doorbell word offsets (64-bit granular).
    //   w0 = magic, w1 = {job_id, version}, w2 = {status, flags}, w3 = seq
    // The host writes ascending words, so w3 committing is the trigger.
    localparam int DB_W_MAGIC = 0;
    localparam int DB_W_IDVER = 1;
    localparam int DB_W_STFLG = 2;
    localparam int DB_W_SEQ   = 3;

    // Arg slot header words: w0 = magic, w1 = {job_id, version}, w2 = seq,
    // w3 = arg_len. Payload starts at w4 (byte offset 0x20).
    localparam int SLOT_W_MAGIC   = 0;
    localparam int SLOT_W_IDVER   = 1;
    localparam int SLOT_W_SEQ     = 2;
    localparam int SLOT_W_ARGLEN  = 3;
    localparam int SLOT_W_PAYLOAD = 4;
    // Payload words retained per slot. The widest payload is the stream
    // prefetch job at 48 bytes; 8 words (64 B) covers every job with margin.
    localparam int SLOT_PAYLOAD_WORDS = 8;
    localparam int SLOT_WORDS         = SLOT_W_PAYLOAD + SLOT_PAYLOAD_WORDS;

    //=========================================================================
    // Register file
    //=========================================================================

    logic [63:0] doorbell [4];
    logic [63:0] slot     [NUM_JOB_IDS][SLOT_WORDS];
    logic [63:0] kentry   [NUM_JOB_IDS];

    // Host status line (0x1F20). seq is published last.
    logic [63:0] st_magic;
    logic [31:0] st_version;
    logic [31:0] st_job_id;
    logic [31:0] st_status;
    logic [63:0] st_seq;

    logic [63:0] last_seq;       // last doorbell sequence consumed
    logic        doorbell_hit;   // pulse: seq word was written

    //=========================================================================
    // Address decode
    //=========================================================================

    logic sel_doorbell, sel_arg, sel_kentry, sel_status;
    logic [1:0]             db_word;
    logic [ADDR_WIDTH-1:0]  arg_off;
    logic [2:0]             arg_job;
    logic [6:0]             arg_word;
    logic                   arg_word_ok;
    logic [3:0]             arg_word_idx;
    logic [2:0]             kentry_idx;
    logic                   kentry_ok;
    logic [1:0]             status_word;

    always_comb begin
        sel_doorbell = (csr_addr < DOORBELL_END);
        sel_arg      = (csr_addr >= ARG_BASE)      && (csr_addr < ARG_END);
        sel_kentry   = (csr_addr >= KENTRY_BASE)   && (csr_addr < KENTRY_END);
        sel_status   = (csr_addr >= STATUS_BASE)   && (csr_addr < STATUS_END);

        db_word = csr_addr[4:3];

        // Slots are 0x400 apart, so within the arg region bits [12:10] pick the
        // slot and bits [9:3] the 64-bit word inside it.
        arg_off      = csr_addr - ARG_BASE;
        arg_job      = arg_off[12:10];
        arg_word     = arg_off[9:3];
        arg_word_ok  = (arg_word < 7'(SLOT_WORDS));
        arg_word_idx = arg_word[3:0];

        kentry_idx = csr_addr[5:3];
        kentry_ok  = (kentry_idx < 3'(NUM_JOB_IDS));

        status_word = csr_addr[4:3];
    end

    //=========================================================================
    // Job acceptance
    //=========================================================================

    // Everything needed to launch, sampled when the doorbell is validated.
    logic [31:0] cur_job_id;
    logic [31:0] cur_flags;
    logic [63:0] cur_seq;
    logic [63:0] cur_kernel_addr;
    logic [63:0] cur_kernel_args;
    logic [63:0] cur_completion;
    logic [31:0] cur_status;

    typedef enum logic [3:0] {
        S_IDLE,
        S_DECODE,
        S_LAUNCH,
        S_RUNNING,
        S_WRITEBACK,
        S_PUBLISH,
        S_REJECT
    } state_t;

    state_t state;

    // Combinational view of the slot addressed by the doorbell's job id.
    logic [2:0]  db_job_idx;
    logic [63:0] db_slot_magic;
    logic [31:0] db_slot_version;
    logic [31:0] db_slot_job_id;
    logic [63:0] db_slot_seq;
    logic [63:0] db_slot_arglen;
    logic        job_id_valid;
    logic        job_uses_kernel_table;
    logic        doorbell_magic_ok;
    logic        doorbell_version_ok;
    logic        slot_ok;

    always_comb begin
        job_id_valid = (doorbell[DB_W_IDVER][63:32] < NUM_JOB_IDS);
        db_job_idx   = job_id_valid ? doorbell[DB_W_IDVER][34:32] : 3'd0;

        // Everything except NOP and CALL is a memory-side operation whose
        // entry point the loader must have published in the kernel table.
        job_uses_kernel_table =
            (cur_job_id == JOB_INSTALL_CACHELINE) ||
            (cur_job_id == JOB_PREFETCH_CHAIN) ||
            (cur_job_id == JOB_STREAM_PREFETCH);

        db_slot_magic   = slot[db_job_idx][SLOT_W_MAGIC];
        db_slot_version = slot[db_job_idx][SLOT_W_IDVER][31:0];
        db_slot_job_id  = slot[db_job_idx][SLOT_W_IDVER][63:32];
        db_slot_seq     = slot[db_job_idx][SLOT_W_SEQ];
        db_slot_arglen  = slot[db_job_idx][SLOT_W_ARGLEN];

        doorbell_magic_ok = (doorbell[DB_W_MAGIC] == CIRA_JOB_MAGIC) ||
                            (doorbell[DB_W_MAGIC] == CIRA_PACC_JOB_MAGIC);
        doorbell_version_ok = (doorbell[DB_W_IDVER][31:0] == CIRA_JOB_VERSION);

        // The slot must describe the same job and the same sequence as the
        // doorbell, otherwise the host is mid-update and the payload is stale.
        slot_ok = ((db_slot_magic == CIRA_JOB_MAGIC) ||
                   (db_slot_magic == CIRA_PACC_JOB_MAGIC)) &&
                  (db_slot_version == CIRA_JOB_VERSION) &&
                  (db_slot_job_id == doorbell[DB_W_IDVER][63:32]) &&
                  (db_slot_seq == doorbell[DB_W_SEQ]) &&
                  (db_slot_arglen != 64'd0);
    end

    //=========================================================================
    // CSR access + dispatch FSM
    //=========================================================================

    integer i, j;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) doorbell[i] <= 64'h0;
            for (i = 0; i < NUM_JOB_IDS; i = i + 1) begin
                for (j = 0; j < SLOT_WORDS; j = j + 1) slot[i][j] <= 64'h0;
                kentry[i] <= 64'h0;
            end
            st_magic   <= 64'h0;
            st_version <= 32'h0;
            st_job_id  <= 32'h0;
            st_status  <= 32'h0;
            st_seq     <= 64'h0;
            last_seq   <= 64'h0;
            doorbell_hit <= 1'b0;
            csr_ready  <= 1'b0;
            csr_rdata  <= 64'h0;

            state           <= S_IDLE;
            cur_job_id      <= 32'h0;
            cur_flags       <= 32'h0;
            cur_seq         <= 64'h0;
            cur_kernel_addr <= 64'h0;
            cur_kernel_args <= 64'h0;
            cur_completion  <= 64'h0;
            cur_status      <= 32'h0;

            job_launch_valid <= 1'b0;
            wb_kernel_done   <= 1'b0;

            dbg_jobs_accepted <= 32'h0;
            dbg_jobs_rejected <= 32'h0;
        end else begin
            doorbell_hit   <= 1'b0;
            wb_kernel_done <= 1'b0;

            //-----------------------------------------------------------------
            // CSR slave: level-based ready, matching the Vortex wrapper.
            //-----------------------------------------------------------------
            if (csr_valid && !csr_ready) begin
                csr_ready <= 1'b1;

                if (csr_write) begin
                    if (sel_doorbell) begin
                        doorbell[db_word] <= csr_wdata;
                        // The host commits seq last; that write is the trigger.
                        if (db_word == 2'(DB_W_SEQ)) doorbell_hit <= 1'b1;
                    end else if (sel_arg) begin
                        if (arg_word_ok) slot[arg_job][arg_word_idx] <= csr_wdata;
                    end else if (sel_kentry) begin
                        if (kentry_ok) kentry[kentry_idx] <= csr_wdata;
                    end
                    // The status line is device-owned; host writes are ignored.
                end else begin
                    if (sel_doorbell) begin
                        csr_rdata <= doorbell[db_word];
                    end else if (sel_arg) begin
                        csr_rdata <= arg_word_ok ? slot[arg_job][arg_word_idx] : 64'h0;
                    end else if (sel_kentry) begin
                        csr_rdata <= kentry_ok ? kentry[kentry_idx] : 64'h0;
                    end else if (sel_status) begin
                        case (status_word)
                            2'd0: csr_rdata <= st_magic;
                            2'd1: csr_rdata <= {st_job_id, st_version};
                            2'd2: csr_rdata <= {32'h0, st_status};
                            default: csr_rdata <= st_seq;
                        endcase
                    end else begin
                        csr_rdata <= 64'h0;
                    end
                end
            end else if (!csr_valid && csr_ready) begin
                csr_ready <= 1'b0;
            end

            //-----------------------------------------------------------------
            // Dispatch FSM
            //-----------------------------------------------------------------
            case (state)
                S_IDLE: begin
                    if (doorbell_hit && (doorbell[DB_W_SEQ] != last_seq)) begin
                        last_seq   <= doorbell[DB_W_SEQ];
                        cur_seq    <= doorbell[DB_W_SEQ];
                        cur_job_id <= doorbell[DB_W_IDVER][63:32];
                        cur_flags  <= doorbell[DB_W_STFLG][31:0];
                        state      <= S_DECODE;
                    end
                end

                S_DECODE: begin
                    if (!doorbell_magic_ok || !doorbell_version_ok) begin
                        cur_status <= STATUS_BAD_VERSION;
                        state      <= S_REJECT;
                    end else if (!job_id_valid) begin
                        cur_status <= STATUS_BAD_JOB;
                        state      <= S_REJECT;
                    end else if (cur_job_id == JOB_NOP) begin
                        // A NOP is a protocol ping: retire it without touching
                        // the core, so the host can prove the path is alive.
                        cur_status     <= STATUS_SUCCESS;
                        cur_completion <= 64'h0;
                        state          <= S_PUBLISH;
                    end else if (!slot_ok) begin
                        cur_status <= STATUS_BAD_ARGS;
                        state      <= S_REJECT;
                    end else begin
                        // Payload word 2 is completion_addr for every job type.
                        cur_completion <= slot[db_job_idx][SLOT_W_PAYLOAD + 2];

                        if (cur_job_id == JOB_CALL) begin
                            // {func_addr, operands_addr, completion_addr, ...}
                            cur_kernel_addr <= slot[db_job_idx][SLOT_W_PAYLOAD + 0];
                            cur_kernel_args <= slot[db_job_idx][SLOT_W_PAYLOAD + 1];
                        end else begin
                            // Prefetch jobs name an operation, not a kernel, so
                            // the entry point comes from the loader's table.
                            // Their payload begins with the address the kernel
                            // works on (addr / start_node_addr / base_addr), and
                            // that is what gets handed over as the argument --
                            // the slot itself lives in registers here, not in
                            // memory the core can read. Jobs needing more than
                            // one word must use CALL with an operands pointer.
                            cur_kernel_addr <= kentry[db_job_idx];
                            cur_kernel_args <= slot[db_job_idx][SLOT_W_PAYLOAD + 0];
                        end

                        if ((cur_job_id != JOB_CALL) && (kentry[db_job_idx] == 64'h0)) begin
                            // No kernel was ever loaded for this operation.
                            cur_status <= STATUS_BAD_JOB;
                            state      <= S_REJECT;
                        end else if (job_uses_kernel_table || (cur_job_id == JOB_CALL)) begin
                            cur_status       <= STATUS_RUNNING;
                            job_launch_valid <= 1'b1;
                            state            <= S_LAUNCH;
                        end else begin
                            cur_status <= STATUS_BAD_JOB;
                            state      <= S_REJECT;
                        end
                    end
                end

                S_LAUNCH: begin
                    if (job_launch_valid && job_launch_ready) begin
                        job_launch_valid <= 1'b0;
                        state            <= S_RUNNING;
                    end
                end

                S_RUNNING: begin
                    if (job_done) begin
                        cur_status <= job_status;
                        if (wb_enable) begin
                            wb_kernel_done <= 1'b1;
                            state          <= S_WRITEBACK;
                        end else begin
                            state <= S_PUBLISH;
                        end
                    end
                end

                S_WRITEBACK: begin
                    // Publish the status line only after the completion line
                    // has landed, so a host that watches either channel cannot
                    // observe the job finishing before its result is visible.
                    if (wb_error) begin
                        cur_status <= STATUS_COMPLETION_IO;
                        state      <= S_PUBLISH;
                    end else if (wb_done) begin
                        state <= S_PUBLISH;
                    end
                end

                S_PUBLISH: begin
                    dbg_jobs_accepted <= dbg_jobs_accepted + 32'd1;
                    state <= S_IDLE;
                end

                S_REJECT: begin
                    dbg_jobs_rejected <= dbg_jobs_rejected + 32'd1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase

            //-----------------------------------------------------------------
            // Host status line. Header fields settle a cycle before seq, which
            // is what the host polls, so it never reads a torn record.
            //-----------------------------------------------------------------
            if ((state == S_PUBLISH) || (state == S_REJECT)) begin
                st_magic   <= CIRA_JOB_MAGIC;
                st_version <= CIRA_JOB_VERSION;
                st_job_id  <= cur_job_id;
                st_status  <= cur_status;
                st_seq     <= cur_seq;
            end
        end
    end

    //=========================================================================
    // Outputs
    //=========================================================================

    assign job_kernel_addr    = cur_kernel_addr;
    assign job_kernel_args    = cur_kernel_args;
    assign job_speculative    = (cur_flags & FLAG_SPECULATIVE) != 32'h0;

    assign wb_kernel_status   = cur_status;
    assign wb_kernel_result   = job_result;
    assign wb_completion_addr = cur_completion;

    assign dbg_last_seq       = last_seq;
    assign dbg_state          = state;

    // wb_busy participates in no decision today; the FSM waits on wb_done.
    logic unused;
    assign unused = ^{1'b0, wb_busy, csr_addr[2:0], arg_off[2:0], arg_word[6:4]};

endmodule
