`timescale 1ns / 1ps

// Protocol-level proof for the device-to-host CXL.cache completion writer.
// The first transaction publishes an unarmed completion line.  A successful
// second B response is required before the writer exposes DEAD_BEEF with a
// partial, magic-only store.
module tb_cira_cxl_cache_completion_writer;

    localparam logic [31:0] COMPLETION_MAGIC = 32'hDEAD_BEEF;
    localparam logic [63:0] COMPLETION_HPA   = 64'h0000_0004_0000_0040;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic        req_valid;
    logic [31:0] req_status;
    logic [63:0] req_result;
    logic [63:0] req_completion_hpa;
    logic        req_busy;
    logic        req_done;
    logic        req_error;

    logic [11:0]  awid;
    logic [63:0]  awaddr;
    logic [9:0]   awlen;
    logic [2:0]   awsize;
    logic [1:0]   awburst;
    logic [2:0]   awprot;
    logic [3:0]   awqos;
    logic [6:0]   awuser;
    logic         awvalid;
    logic [3:0]   awcache;
    logic [1:0]   awlock;
    logic [3:0]   awregion;
    logic [5:0]   awatop;
    logic         awready;

    logic [511:0] wdata;
    logic [63:0]  wstrb;
    logic         wlast;
    logic         wuser;
    logic         wvalid;
    logic         wready;

    logic [11:0] bid;
    logic [1:0]  bresp;
    logic [3:0]  buser;
    logic        bvalid;
    logic        bready;

    int errors = 0;
    int checks = 0;
    int aw_count = 0;
    int w_count = 0;
    int b_count = 0;
    logic [63:0] awaddr_log [0:7];
    logic [11:0] awid_log [0:7];
    logic [9:0]  awlen_log [0:7];
    logic [2:0]  awsize_log [0:7];
    logic [1:0]  awburst_log [0:7];
    logic [6:0]  awuser_log [0:7];
    logic [3:0]  awcache_log [0:7];
    logic [5:0]  awatop_log [0:7];
    logic [511:0] wdata_log [0:7];
    logic [63:0]  wstrb_log [0:7];
    logic [1:0] response_codes [0:7];

    cira_cxl_cache_completion_writer dut (
        .clk(clk), .rst_n(rst_n),
        .req_valid(req_valid), .req_status(req_status), .req_result(req_result),
        .req_completion_hpa(req_completion_hpa), .req_busy(req_busy),
        .req_done(req_done), .req_error(req_error),
        .awid(awid), .awaddr(awaddr), .awlen(awlen), .awsize(awsize),
        .awburst(awburst), .awprot(awprot), .awqos(awqos), .awuser(awuser),
        .awvalid(awvalid), .awcache(awcache), .awlock(awlock),
        .awregion(awregion), .awatop(awatop), .awready(awready),
        .wdata(wdata), .wstrb(wstrb), .wlast(wlast), .wuser(wuser),
        .wvalid(wvalid), .wready(wready),
        .bid(bid), .bresp(bresp), .buser(buser), .bvalid(bvalid), .bready(bready)
    );

    task automatic check(input logic cond, input string msg);
        checks++;
        if (cond) $display("  [ ok ] %s", msg);
        else begin
            $display("  [FAIL] %s", msg);
            errors++;
        end
    endtask

    task automatic send_request(input logic [63:0] hpa, input logic [31:0] status,
                                input logic [63:0] result);
        @(negedge clk);
        req_completion_hpa = hpa;
        req_status = status;
        req_result = result;
        req_valid = 1'b1;
        @(negedge clk);
        req_valid = 1'b0;
    endtask

    task automatic wait_terminal(input logic expect_error);
        int timeout;
        logic matched;
        begin
            matched = expect_error ? req_error : req_done;
            if (!matched) begin
                for (timeout = 0; timeout < 80; timeout++) begin
                    @(posedge clk);
                    #1;
                    if (expect_error ? req_error : req_done) begin
                        matched = 1'b1;
                        break;
                    end
                end
            end
            check(matched, expect_error ? "writer reports terminal error" :
                                         "writer reports terminal success");
        end
    endtask

    // A simple AXI write responder.  It only returns B after accepting W, so
    // observing req_done proves both AW/W/B phases for the committing write.
    always @(posedge clk) begin
        if (awvalid && awready) begin
            awaddr_log[aw_count] <= awaddr;
            awid_log[aw_count] <= awid;
            awlen_log[aw_count] <= awlen;
            awsize_log[aw_count] <= awsize;
            awburst_log[aw_count] <= awburst;
            awuser_log[aw_count] <= awuser;
            awcache_log[aw_count] <= awcache;
            awatop_log[aw_count] <= awatop;
            aw_count <= aw_count + 1;
        end
        if (wvalid && wready) begin
            wdata_log[w_count] <= wdata;
            wstrb_log[w_count] <= wstrb;
            w_count <= w_count + 1;
            bresp <= response_codes[w_count];
            bvalid <= 1'b1;
        end
        if (bvalid && bready) begin
            bvalid <= 1'b0;
            b_count <= b_count + 1;
        end
    end

    initial begin
        req_valid = 1'b0;
        req_status = '0;
        req_result = '0;
        req_completion_hpa = '0;
        awready = 1'b0;
        wready = 1'b0;
        bid = 12'hc1a;
        bresp = 2'b00;
        buser = '0;
        bvalid = 1'b0;
        for (int i = 0; i < 8; i++)
            response_codes[i] = 2'b00;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        $display("=== CIRA CXL.cache completion writer tests ===");
        send_request(COMPLETION_HPA, 32'h1122_3344, 64'h0123_4567_89ab_cdef);
        repeat (2) @(posedge clk);
        check(req_busy, "writer stays busy while AW is backpressured");
        check(awvalid, "writer holds payload AW valid during backpressure");
        awready = 1'b1;
        wready = 1'b1;
        wait_terminal(1'b0);
        #1;
        check(!req_busy, "writer becomes idle only after committing B response");
        check(aw_count == 2 && w_count == 2 && b_count == 2,
              "successful completion has exactly two AW/W/B transactions");
        check(awaddr_log[0] == COMPLETION_HPA && awaddr_log[1] == COMPLETION_HPA,
              "both coherent writes use the requested cache-line HPA");
        check(awid_log[0] == 12'hc1a && awid_log[1] == 12'hc1a,
              "writes use the dedicated CIRA AXI ID");
        check(awlen_log[0] == 0 && awlen_log[1] == 0 &&
              awsize_log[0] == 3'd6 && awsize_log[1] == 3'd6 &&
              awburst_log[0] == 2'b00 && awburst_log[1] == 2'b00,
              "writes are single 64-byte fixed bursts");
        check(awuser_log[0] == 7'b0000010 && awuser_log[1] == 7'b0000010 &&
              awcache_log[0] == 4'b0001 && awcache_log[1] == 4'b0001 &&
              awatop_log[0] == 0 && awatop_log[1] == 0,
              "writes request CAFU I_SO coherence without atomic side effects");
        check(wstrb_log[0] == 64'hffff_ffff_ffff_ffff && wdata_log[0][31:0] == 0 &&
              wdata_log[0][63:32] == 32'h1122_3344 &&
              wdata_log[0][127:64] == 64'h0123_4567_89ab_cdef,
              "payload write publishes status/result with magic still clear");
        check(wstrb_log[1] == 64'h0000_0000_0000_000f &&
              wdata_log[1][31:0] == COMPLETION_MAGIC && wdata_log[1][511:32] == 0,
              "commit write is a magic-only partial cache-line store");

        send_request(COMPLETION_HPA + 64'd8, 32'h55aa_55aa, '0);
        wait_terminal(1'b1);
        #1;
        check(aw_count == 2 && w_count == 2 && b_count == 2,
              "unaligned completion HPA issues no CXL.cache transaction");

        response_codes[2] = 2'b10;
        send_request(COMPLETION_HPA + 64'd64, 32'h89ab_cdef, 64'h7654_3210_fedc_ba98);
        wait_terminal(1'b1);
        #1;
        check(aw_count == 3 && w_count == 3 && b_count == 3,
              "payload B error prevents the magic commit transaction");
        check(wdata_log[2][31:0] == 0 && wstrb_log[2] == 64'hffff_ffff_ffff_ffff,
              "failed payload transaction never exposes success magic");

        // A commit DECERR is terminal even though the magic-only write was
        // presented on AXI.  req_done must never be raised until its B is OKAY.
        response_codes[4] = 2'b11;
        send_request(COMPLETION_HPA + 64'd128, 32'h0123_4567, 64'h89ab_cdef_0123_4567);
        wait_terminal(1'b1);
        #1;
        check(aw_count == 5 && w_count == 5 && b_count == 5,
              "commit B error is observed after payload and magic transactions");
        check(wstrb_log[4] == 64'h0000_0000_0000_000f && wdata_log[4][31:0] == COMPLETION_MAGIC,
              "commit B error came from the magic-only transaction");

        if (errors != 0) begin
            $display("%0d/%0d checks failed", errors, checks);
            $fatal(1);
        end
        $display("All %0d checks passed", checks);
        $finish;
    end
endmodule
