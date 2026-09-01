// Testbench for cira_job_dispatch (runs under Verilator).
//
// Drives the CIRA control window exactly the way runtime/cira_mmio.cpp does --
// payload, then slot header, then doorbell with seq last -- and checks that the
// device launches the core and republishes the result. The struct offsets below
// are transcribed from runtime/include/cira_cxl_job.h; if the two ever drift,
// this testbench is what should catch it.
//
// Build and run:
//   make -f Makefile.cira_dispatch

`timescale 1ns / 1ps

module tb_cira_job_dispatch;

    localparam int ADDR_WIDTH = 13;

    localparam logic [63:0] JOB_MAGIC       = 64'h565843584c4a4f42; // "VXCXLJOB"
    localparam logic [63:0] BAD_MAGIC       = 64'h0badc0de0badc0de;
    localparam logic [31:0] JOB_VERSION     = 32'd1;

    localparam logic [31:0] JOB_NOP             = 32'd0;
    localparam logic [31:0] JOB_PREFETCH_CHAIN  = 32'd2;
    localparam logic [31:0] JOB_CALL            = 32'd4;

    localparam logic [31:0] ST_SUCCESS      = 32'h0000_0000;
    localparam logic [31:0] ST_BAD_VERSION  = 32'hffff_0001;
    localparam logic [31:0] ST_BAD_ARGS     = 32'hffff_0002;
    localparam logic [31:0] ST_COMPLETION_IO = 32'hffff_0003;
    localparam logic [31:0] ST_BAD_JOB      = 32'hffff_00ff;

    localparam logic [ADDR_WIDTH-1:0] DOORBELL_OFF = 'h0000;
    localparam logic [ADDR_WIDTH-1:0] ARG_BASE     = 'h0100;
    localparam logic [ADDR_WIDTH-1:0] KENTRY_BASE  = 'h1E00;
    localparam logic [ADDR_WIDTH-1:0] STATUS_OFF   = 'h1F20;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    // CSR bus
    logic                  csr_valid, csr_write, csr_ready;
    logic [ADDR_WIDTH-1:0] csr_addr;
    logic [63:0]           csr_wdata, csr_rdata;

    // Launch handshake
    logic        job_launch_valid, job_launch_ready;
    logic [63:0] job_kernel_addr, job_kernel_args;
    logic        job_speculative;

    // Retirement
    logic        job_done;
    logic [31:0] job_status;
    logic [63:0] job_result;

    // Writeback
    logic        wb_kernel_done, wb_enable, wb_done, wb_error, wb_busy;
    logic [31:0] wb_kernel_status;
    logic [63:0] wb_kernel_result, wb_completion_addr;

    logic [31:0] dbg_jobs_accepted, dbg_jobs_rejected;
    logic [63:0] dbg_last_seq;
    logic [3:0]  dbg_state;

    int errors = 0;
    int checks = 0;

    cira_job_dispatch #(.ADDR_WIDTH(ADDR_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .csr_valid(csr_valid), .csr_write(csr_write), .csr_addr(csr_addr),
        .csr_wdata(csr_wdata), .csr_ready(csr_ready), .csr_rdata(csr_rdata),
        .job_launch_valid(job_launch_valid), .job_launch_ready(job_launch_ready),
        .job_kernel_addr(job_kernel_addr), .job_kernel_args(job_kernel_args),
        .job_speculative(job_speculative),
        .job_done(job_done), .job_status(job_status), .job_result(job_result),
        .wb_kernel_done(wb_kernel_done), .wb_kernel_status(wb_kernel_status),
        .wb_kernel_result(wb_kernel_result), .wb_completion_addr(wb_completion_addr),
        .wb_enable(wb_enable), .wb_done(wb_done), .wb_error(wb_error), .wb_busy(wb_busy),
        .dbg_jobs_accepted(dbg_jobs_accepted), .dbg_jobs_rejected(dbg_jobs_rejected),
        .dbg_last_seq(dbg_last_seq), .dbg_state(dbg_state)
    );

    //=========================================================================
    // Checking helpers
    //=========================================================================

    task automatic check(input logic cond, input string msg);
        checks++;
        if (cond) $display("  [ ok ] %s", msg);
        else begin
            $display("  [FAIL] %s", msg);
            errors++;
        end
    endtask

    task automatic check_eq64(input logic [63:0] got, input logic [63:0] exp,
                              input string msg);
        checks++;
        if (got === exp) $display("  [ ok ] %s", msg);
        else begin
            $display("  [FAIL] %s (got 0x%016h expected 0x%016h)", msg, got, exp);
            errors++;
        end
    endtask

    //=========================================================================
    // CSR bus driver -- mirrors the level-based handshake in afu_top
    //=========================================================================

    task automatic csr_wr(input logic [ADDR_WIDTH-1:0] addr,
                          input logic [63:0] data);
        @(posedge clk);
        csr_valid = 1'b1;
        csr_write = 1'b1;
        csr_addr  = addr;
        csr_wdata = data;
        do @(posedge clk); while (!csr_ready);
        csr_valid = 1'b0;
        csr_write = 1'b0;
        do @(posedge clk); while (csr_ready);
    endtask

    task automatic csr_rd(input logic [ADDR_WIDTH-1:0] addr,
                          output logic [63:0] data);
        @(posedge clk);
        csr_valid = 1'b1;
        csr_write = 1'b0;
        csr_addr  = addr;
        do @(posedge clk); while (!csr_ready);
        data = csr_rdata;
        csr_valid = 1'b0;
        do @(posedge clk); while (csr_ready);
    endtask

    //=========================================================================
    // Host-side protocol helpers (what cira_mmio.cpp does)
    //=========================================================================

    function automatic logic [ADDR_WIDTH-1:0] slot_off(input int job_id);
        slot_off = ADDR_WIDTH'(ARG_BASE + (job_id * 'h400));
    endfunction

    // Stage the slot header. Payload words are written by the caller first,
    // exactly like cira_mmio_submit_job.
    task automatic stage_slot_header(input int job_id, input logic [63:0] seq,
                                     input logic [63:0] arg_len,
                                     input logic [63:0] magic);
        csr_wr(slot_off(job_id) + 'h00, magic);
        csr_wr(slot_off(job_id) + 'h08, {32'(job_id), JOB_VERSION});
        csr_wr(slot_off(job_id) + 'h10, seq);
        csr_wr(slot_off(job_id) + 'h18, arg_len);
    endtask

    // Ring the doorbell. seq goes last -- that is the commit point.
    task automatic ring_doorbell(input int job_id, input logic [63:0] seq,
                                 input logic [31:0] flags,
                                 input logic [63:0] magic,
                                 input logic [31:0] version);
        csr_wr(DOORBELL_OFF + 'h00, magic);
        csr_wr(DOORBELL_OFF + 'h08, {32'(job_id), version});
        csr_wr(DOORBELL_OFF + 'h10, {32'h0, flags});
        csr_wr(DOORBELL_OFF + 'h18, seq);
    endtask

    task automatic read_status(output logic [63:0] magic,
                               output logic [31:0] version,
                               output logic [31:0] job_id,
                               output logic [31:0] status,
                               output logic [63:0] seq);
        logic [63:0] w;
        csr_rd(STATUS_OFF + 'h00, w); magic = w;
        csr_rd(STATUS_OFF + 'h08, w); version = w[31:0]; job_id = w[63:32];
        csr_rd(STATUS_OFF + 'h10, w); status = w[31:0];
        csr_rd(STATUS_OFF + 'h18, w); seq = w;
    endtask

    // Wait until the device republishes `seq` -- this is cira_mmio_wait_seq.
    task automatic wait_seq(input logic [63:0] seq, output logic ok);
        int timeout;
        logic [63:0] m, s;
        logic [31:0] v, j, st;
        timeout = 0;
        ok = 1'b0;
        while (timeout < 2000) begin
            read_status(m, v, j, st, s);
            if (s >= seq) begin
                ok = 1'b1;
                return;
            end
            timeout++;
        end
    endtask

    //=========================================================================
    // Fake Vortex core: accepts a launch, runs a while, retires.
    // Clocked rather than an initial/forever block so there is no race with
    // the DUT sampling job_done.
    //=========================================================================

    logic [63:0] observed_kernel_addr;
    logic [63:0] observed_kernel_args;
    logic        observed_speculative;
    int          launch_count;
    localparam int CORE_DELAY = 20;

    typedef enum logic [1:0] { C_IDLE, C_RUN } core_state_t;
    core_state_t cstate;
    int          core_timer;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            job_launch_ready     <= 1'b1;
            job_done             <= 1'b0;
            job_status           <= ST_SUCCESS;
            job_result           <= 64'h0;
            observed_kernel_addr <= 64'h0;
            observed_kernel_args <= 64'h0;
            observed_speculative <= 1'b0;
            launch_count         <= 0;
            core_timer           <= 0;
            cstate               <= C_IDLE;
        end else begin
            job_done <= 1'b0;
            case (cstate)
                C_IDLE: begin
                    if (job_launch_valid && job_launch_ready) begin
                        observed_kernel_addr <= job_kernel_addr;
                        observed_kernel_args <= job_kernel_args;
                        observed_speculative <= job_speculative;
                        launch_count         <= launch_count + 1;
                        job_launch_ready     <= 1'b0;
                        core_timer           <= CORE_DELAY;
                        cstate               <= C_RUN;
                    end
                end
                C_RUN: begin
                    if (core_timer == 0) begin
                        job_result       <= 64'hfeed_face_0000_0000 + 64'(launch_count);
                        job_status       <= ST_SUCCESS;
                        job_done         <= 1'b1;
                        job_launch_ready <= 1'b1;
                        cstate           <= C_IDLE;
                    end else begin
                        core_timer <= core_timer - 1;
                    end
                end
                default: cstate <= C_IDLE;
            endcase
        end
    end

    //=========================================================================
    // Fake completion writeback engine
    //=========================================================================

    int          wb_count;
    logic [63:0] wb_seen_addr;
    logic [63:0] wb_seen_result;

    typedef enum logic [1:0] { W_IDLE, W_RUN } wb_state_t;
    wb_state_t wstate;
    int        wb_timer;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_done        <= 1'b0;
            wb_error       <= 1'b0;
            wb_busy        <= 1'b0;
            wb_count       <= 0;
            wb_seen_addr   <= 64'h0;
            wb_seen_result <= 64'h0;
            wb_timer       <= 0;
            wstate         <= W_IDLE;
        end else begin
            wb_done  <= 1'b0;
            wb_error <= 1'b0;
            case (wstate)
                W_IDLE: begin
                    if (wb_kernel_done) begin
                        wb_seen_addr   <= wb_completion_addr;
                        wb_seen_result <= wb_kernel_result;
                        wb_count       <= wb_count + 1;
                        wb_busy        <= 1'b1;
                        wb_timer       <= 8;
                        wstate         <= W_RUN;
                    end
                end
                W_RUN: begin
                    if (wb_timer == 0) begin
                        wb_busy <= 1'b0;
                        if (wb_seen_addr == 64'h0)
                            wb_error <= 1'b1;
                        else
                            wb_done <= 1'b1;
                        wstate  <= W_IDLE;
                    end else begin
                        wb_timer <= wb_timer - 1;
                    end
                end
                default: wstate <= W_IDLE;
            endcase
        end
    end

    //=========================================================================
    // Tests
    //=========================================================================

    logic [63:0] st_magic, st_seq, rdata;
    logic [31:0] st_version, st_job_id, st_status;
    logic        ok;

    initial begin
        csr_valid = 1'b0;
        csr_write = 1'b0;
        csr_addr  = '0;
        csr_wdata = '0;
        wb_enable = 1'b1;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        $display("=== cira_job_dispatch protocol tests ===");

        //---------------------------------------------------------------
        $display("control window is addressable");
        csr_wr(ARG_BASE + 'h20, 64'hdead_beef_cafe_f00d);
        csr_rd(ARG_BASE + 'h20, rdata);
        check_eq64(rdata, 64'hdead_beef_cafe_f00d, "arg slot payload round-trips");

        csr_wr(KENTRY_BASE + 8*2, 64'h8000_1234);
        csr_rd(KENTRY_BASE + 8*2, rdata);
        check_eq64(rdata, 64'h8000_1234, "kernel entry table round-trips");
        check(STATUS_OFF < (1 << ADDR_WIDTH),
              "status line at 0x1f20 is reachable (needs a 13-bit CSR bus)");

        //---------------------------------------------------------------
        $display("NOP job retires without touching the core");
        ring_doorbell(0, 64'd1, 32'h0, JOB_MAGIC, JOB_VERSION);
        wait_seq(64'd1, ok);
        check(ok, "device republished seq 1");
        read_status(st_magic, st_version, st_job_id, st_status, st_seq);
        check_eq64(st_magic, JOB_MAGIC, "status magic is VXCXLJOB");
        check(st_version == JOB_VERSION, "status version is 1");
        check(st_job_id == JOB_NOP, "status job_id is NOP");
        check(st_status == ST_SUCCESS, "NOP reported success");
        check(launch_count == 0, "NOP did not launch the core");

        //---------------------------------------------------------------
        $display("CALL job launches the core and reports back");
        // payload: {func_addr, operands_addr, completion_addr, num_operands}
        csr_wr(slot_off(4) + 'h20, 64'h0000_0000_8000_0100); // func_addr
        csr_wr(slot_off(4) + 'h28, 64'h0000_0001_0000_2000); // operands_addr
        csr_wr(slot_off(4) + 'h30, 64'h0000_0002_0000_3000); // completion_addr
        csr_wr(slot_off(4) + 'h38, 64'h0000_0000_0000_0002); // num_operands
        stage_slot_header(4, 64'd2, 64'd32, JOB_MAGIC);
        ring_doorbell(4, 64'd2, 32'h0, JOB_MAGIC, JOB_VERSION);

        wait_seq(64'd2, ok);
        check(ok, "device republished seq 2");
        check(launch_count == 1, "core was launched exactly once");
        check_eq64(observed_kernel_addr, 64'h0000_0000_8000_0100,
                   "kernel PC came from func_addr");
        check_eq64(observed_kernel_args, 64'h0000_0001_0000_2000,
                   "kernel args came from operands_addr");
        check(wb_count == 1, "completion writeback was triggered");
        check_eq64(wb_seen_addr, 64'h0000_0002_0000_3000,
                   "writeback targeted completion_addr");
        read_status(st_magic, st_version, st_job_id, st_status, st_seq);
        check(st_job_id == JOB_CALL, "status job_id is CALL");
        check(st_status == ST_SUCCESS, "CALL reported success");

        //---------------------------------------------------------------
        $display("status is published only after the writeback lands");
        check(dbg_jobs_accepted == 32'd2, "two jobs accepted so far");

        //---------------------------------------------------------------
        $display("prefetch job uses the loader's kernel entry table");
        csr_wr(KENTRY_BASE + 8*2, 64'h0000_0000_9000_0000);
        csr_wr(slot_off(2) + 'h20, 64'h0000_0003_0000_0000); // start_node_addr
        csr_wr(slot_off(2) + 'h28, 64'h0000_0003_0001_0000); // buf_addr
        csr_wr(slot_off(2) + 'h30, 64'h0);                   // completion_addr
        stage_slot_header(2, 64'd3, 64'd40, JOB_MAGIC);
        ring_doorbell(2, 64'd3, 32'h1 /* speculative */, JOB_MAGIC, JOB_VERSION);

        wait_seq(64'd3, ok);
        check(ok, "device republished seq 3");
        check(launch_count == 2, "prefetch job launched the core");
        check_eq64(observed_kernel_addr, 64'h0000_0000_9000_0000,
                   "kernel PC came from the entry table");
        check_eq64(observed_kernel_args, 64'h0000_0003_0000_0000,
                   "kernel arg is the job's primary address");
        check(observed_speculative, "SPECULATIVE flag reached the core");
        check(wb_count == 2, "zero completion_addr is handed to the CXL.cache writer");
        check_eq64(wb_seen_addr, 64'h0, "writer receives zero completion address for validation");
        read_status(st_magic, st_version, st_job_id, st_status, st_seq);
        check(st_status == ST_COMPLETION_IO,
              "completion writer error is published instead of false success");

        //---------------------------------------------------------------
        $display("malformed jobs are rejected, not executed");
        ring_doorbell(4, 64'd4, 32'h0, BAD_MAGIC, JOB_VERSION);
        wait_seq(64'd4, ok);
        read_status(st_magic, st_version, st_job_id, st_status, st_seq);
        check(st_status == ST_BAD_VERSION, "bad magic reports BAD_VERSION");
        check(launch_count == 2, "bad magic did not launch the core");

        ring_doorbell(4, 64'd5, 32'h0, JOB_MAGIC, 32'd99);
        wait_seq(64'd5, ok);
        read_status(st_magic, st_version, st_job_id, st_status, st_seq);
        check(st_status == ST_BAD_VERSION, "bad version reports BAD_VERSION");

        // Doorbell seq 6 but the slot still says seq 2 -- a torn update.
        ring_doorbell(4, 64'd6, 32'h0, JOB_MAGIC, JOB_VERSION);
        wait_seq(64'd6, ok);
        read_status(st_magic, st_version, st_job_id, st_status, st_seq);
        check(st_status == ST_BAD_ARGS, "stale arg slot reports BAD_ARGS");
        check(launch_count == 2, "stale arg slot did not launch the core");

        // Unknown job id.
        ring_doorbell(7, 64'd7, 32'h0, JOB_MAGIC, JOB_VERSION);
        wait_seq(64'd7, ok);
        read_status(st_magic, st_version, st_job_id, st_status, st_seq);
        check(st_status == ST_BAD_JOB, "out-of-range job id reports BAD_JOB");

        // Prefetch job whose kernel was never loaded.
        csr_wr(KENTRY_BASE + 8*3, 64'h0);
        csr_wr(slot_off(3) + 'h20, 64'h0000_0004_0000_0000);
        stage_slot_header(3, 64'd8, 64'd48, JOB_MAGIC);
        ring_doorbell(3, 64'd8, 32'h0, JOB_MAGIC, JOB_VERSION);
        wait_seq(64'd8, ok);
        read_status(st_magic, st_version, st_job_id, st_status, st_seq);
        check(st_status == ST_BAD_JOB, "unloaded prefetch kernel reports BAD_JOB");
        check(launch_count == 2, "unloaded prefetch kernel did not launch");

        //---------------------------------------------------------------
        $display("back-to-back jobs keep their sequence numbers");
        csr_wr(slot_off(4) + 'h20, 64'h0000_0000_8000_0200);
        csr_wr(slot_off(4) + 'h28, 64'h0000_0001_0000_4000);
        csr_wr(slot_off(4) + 'h30, 64'h0);
        stage_slot_header(4, 64'd9, 64'd32, JOB_MAGIC);
        ring_doorbell(4, 64'd9, 32'h0, JOB_MAGIC, JOB_VERSION);
        wait_seq(64'd9, ok);
        check(ok, "device republished seq 9");
        check(launch_count == 3, "third launch happened");
        check_eq64(dbg_last_seq, 64'd9, "device tracked the latest sequence");
        check(dbg_jobs_rejected == 32'd5, "five malformed jobs were rejected");

        //---------------------------------------------------------------
        $display("");
        if (errors == 0)
            $display("All %0d checks passed", checks);
        else
            $display("%0d of %0d checks FAILED", errors, checks);
        $finish;
    end

    // Global watchdog
    initial begin
        #2_000_000;
        $display("[FAIL] testbench timeout");
        $fatal(1, "timeout");
    end

endmodule
