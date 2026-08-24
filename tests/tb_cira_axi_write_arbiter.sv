`timescale 1ns / 1ps

module tb_cira_axi_write_arbiter;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic [11:0] legacy_awid, cira_awid, phy_awid;
    logic [63:0] legacy_awaddr, cira_awaddr, phy_awaddr;
    logic [9:0] legacy_awlen, cira_awlen, phy_awlen;
    logic [2:0] legacy_awsize, cira_awsize, phy_awsize;
    logic [1:0] legacy_awburst, cira_awburst, phy_awburst;
    logic [2:0] legacy_awprot, cira_awprot, phy_awprot;
    logic [3:0] legacy_awqos, cira_awqos, phy_awqos;
    logic [6:0] legacy_awuser, cira_awuser, phy_awuser;
    logic [3:0] legacy_awcache, cira_awcache, phy_awcache;
    logic [1:0] legacy_awlock, cira_awlock, phy_awlock;
    logic [3:0] legacy_awregion, cira_awregion, phy_awregion;
    logic [5:0] legacy_awatop, cira_awatop, phy_awatop;
    logic legacy_awvalid, legacy_awready, cira_awvalid, cira_awready;
    logic phy_awvalid, phy_awready;

    logic [511:0] legacy_wdata, cira_wdata, phy_wdata;
    logic [63:0] legacy_wstrb, cira_wstrb, phy_wstrb;
    logic legacy_wlast, legacy_wuser, legacy_wvalid, legacy_wready;
    logic cira_wlast, cira_wuser, cira_wvalid, cira_wready;
    logic phy_wlast, phy_wuser, phy_wvalid, phy_wready;

    logic [11:0] phy_bid;
    logic [1:0] phy_bresp;
    logic [3:0] phy_buser;
    logic phy_bvalid, phy_bready;
    logic [11:0] legacy_bid, cira_bid;
    logic [1:0] legacy_bresp, cira_bresp;
    logic [3:0] legacy_buser, cira_buser;
    logic legacy_bvalid, legacy_bready, cira_bvalid, cira_bready;

    int errors = 0;
    int checks = 0;
    int aw_count = 0;
    int w_count = 0;
    int cira_b_count = 0;
    int legacy_b_count = 0;
    logic [63:0] awaddr_log [0:3];
    logic [11:0] awid_log [0:3];
    logic [511:0] wdata_log [0:3];

    cira_axi_write_arbiter dut (
        .clk(clk), .rst_n(rst_n),
        .legacy_awid(legacy_awid), .legacy_awaddr(legacy_awaddr),
        .legacy_awlen(legacy_awlen), .legacy_awsize(legacy_awsize),
        .legacy_awburst(legacy_awburst), .legacy_awprot(legacy_awprot),
        .legacy_awqos(legacy_awqos), .legacy_awuser(legacy_awuser),
        .legacy_awvalid(legacy_awvalid), .legacy_awcache(legacy_awcache),
        .legacy_awlock(legacy_awlock), .legacy_awregion(legacy_awregion),
        .legacy_awatop(legacy_awatop), .legacy_awready(legacy_awready),
        .legacy_wdata(legacy_wdata), .legacy_wstrb(legacy_wstrb),
        .legacy_wlast(legacy_wlast), .legacy_wuser(legacy_wuser),
        .legacy_wvalid(legacy_wvalid), .legacy_wready(legacy_wready),
        .legacy_bid(legacy_bid), .legacy_bresp(legacy_bresp),
        .legacy_buser(legacy_buser), .legacy_bvalid(legacy_bvalid),
        .legacy_bready(legacy_bready),
        .cira_awid(cira_awid), .cira_awaddr(cira_awaddr),
        .cira_awlen(cira_awlen), .cira_awsize(cira_awsize),
        .cira_awburst(cira_awburst), .cira_awprot(cira_awprot),
        .cira_awqos(cira_awqos), .cira_awuser(cira_awuser),
        .cira_awvalid(cira_awvalid), .cira_awcache(cira_awcache),
        .cira_awlock(cira_awlock), .cira_awregion(cira_awregion),
        .cira_awatop(cira_awatop), .cira_awready(cira_awready),
        .cira_wdata(cira_wdata), .cira_wstrb(cira_wstrb),
        .cira_wlast(cira_wlast), .cira_wuser(cira_wuser),
        .cira_wvalid(cira_wvalid), .cira_wready(cira_wready),
        .cira_bid(cira_bid), .cira_bresp(cira_bresp), .cira_buser(cira_buser),
        .cira_bvalid(cira_bvalid), .cira_bready(cira_bready),
        .phy_awid(phy_awid), .phy_awaddr(phy_awaddr), .phy_awlen(phy_awlen),
        .phy_awsize(phy_awsize), .phy_awburst(phy_awburst), .phy_awprot(phy_awprot),
        .phy_awqos(phy_awqos), .phy_awuser(phy_awuser), .phy_awvalid(phy_awvalid),
        .phy_awcache(phy_awcache), .phy_awlock(phy_awlock), .phy_awregion(phy_awregion),
        .phy_awatop(phy_awatop), .phy_awready(phy_awready),
        .phy_wdata(phy_wdata), .phy_wstrb(phy_wstrb), .phy_wlast(phy_wlast),
        .phy_wuser(phy_wuser), .phy_wvalid(phy_wvalid), .phy_wready(phy_wready),
        .phy_bid(phy_bid), .phy_bresp(phy_bresp), .phy_buser(phy_buser),
        .phy_bvalid(phy_bvalid), .phy_bready(phy_bready)
    );

    task automatic check(input logic cond, input string msg);
        checks++;
        if (cond) $display("  [ ok ] %s", msg);
        else begin
            $display("  [FAIL] %s", msg);
            errors++;
        end
    endtask

    task automatic wait_aw;
        int timeout;
        int start_count;
        begin
            start_count = aw_count;
            for (timeout = 0; timeout < 20; timeout++) begin
                @(posedge clk);
                #1;
                if (aw_count != start_count)
                    return;
            end
            check(1'b0, "physical AW handshake timed out");
        end
    endtask

    task automatic wait_w;
        int timeout;
        int start_count;
        begin
            start_count = w_count;
            for (timeout = 0; timeout < 20; timeout++) begin
                @(posedge clk);
                #1;
                if (w_count != start_count)
                    return;
            end
            check(1'b0, "physical W handshake timed out");
        end
    endtask

    task automatic send_b(input logic [1:0] resp);
        begin
            @(negedge clk);
            phy_bresp = resp;
            phy_bvalid = 1'b1;
            @(negedge clk);
            phy_bvalid = 1'b0;
        end
    endtask

    always @(posedge clk) begin
        if (phy_awvalid && phy_awready) begin
            awaddr_log[aw_count] <= phy_awaddr;
            awid_log[aw_count] <= phy_awid;
            aw_count <= aw_count + 1;
        end
        if (phy_wvalid && phy_wready) begin
            wdata_log[w_count] <= phy_wdata;
            w_count <= w_count + 1;
        end
        if (phy_bvalid && phy_bready) begin
            if (cira_bvalid)
                cira_b_count <= cira_b_count + 1;
            if (legacy_bvalid)
                legacy_b_count <= legacy_b_count + 1;
        end
    end

    initial begin
        legacy_awid = 12'h111;
        legacy_awaddr = 64'h0000_0000_0000_1000;
        legacy_awlen = 0; legacy_awsize = 3'd6; legacy_awburst = 2'b00;
        legacy_awprot = 0; legacy_awqos = 0; legacy_awuser = 0; legacy_awcache = 4'h1;
        legacy_awlock = 0; legacy_awregion = 0; legacy_awatop = 0;
        legacy_wdata = 512'h1111; legacy_wstrb = '1; legacy_wlast = 1; legacy_wuser = 0;
        legacy_awvalid = 0; legacy_wvalid = 0; legacy_bready = 1;

        cira_awid = 12'hc1a;
        cira_awaddr = 64'h0000_0004_0000_0040;
        cira_awlen = 0; cira_awsize = 3'd6; cira_awburst = 2'b00;
        cira_awprot = 0; cira_awqos = 0; cira_awuser = 7'b0000010; cira_awcache = 4'h1;
        cira_awlock = 0; cira_awregion = 0; cira_awatop = 0;
        cira_wdata = 512'hc1c1; cira_wstrb = '1; cira_wlast = 1; cira_wuser = 0;
        cira_awvalid = 0; cira_wvalid = 0; cira_bready = 1;

        phy_awready = 1; phy_wready = 0;
        phy_bid = 12'hc1a; phy_bresp = 0; phy_buser = 0; phy_bvalid = 0;

        repeat (3) @(posedge clk);
        rst_n = 1;

        $display("=== CIRA AXI1 write arbiter tests ===");
        @(negedge clk);
        legacy_awvalid = 1;
        cira_awvalid = 1;
        wait_aw();
        check(awaddr_log[0] == cira_awaddr && awid_log[0] == cira_awid,
              "CIRA completion has priority when both masters request AW");
        @(negedge clk);
        cira_awvalid = 0;
        cira_wvalid = 1;
        repeat (2) @(posedge clk);
        check(!legacy_awready && !legacy_wready && cira_wvalid,
              "legacy master is blocked until CIRA's B response");
        phy_wready = 1;
        wait_w();
        check(wdata_log[0] == cira_wdata, "CIRA W follows its own AW without interleaving");
        send_b(2'b00);
        #1;
        check(cira_b_count == 1 && legacy_b_count == 0, "CIRA alone receives its B response");
        cira_wvalid = 0;

        // CIRA is now idle; the queued legacy transaction may proceed.
        wait_aw();
        check(aw_count == 2, "legacy AW is accepted after CIRA B handshake");
        check(awaddr_log[1] == legacy_awaddr && awid_log[1] == legacy_awid,
              "legacy AW is released after CIRA B handshake");
        legacy_awvalid = 0;
        legacy_wvalid = 1;
        wait_w();
        check(wdata_log[1] == legacy_wdata, "legacy W follows its own AW without interleaving");
        phy_bid = legacy_awid;
        send_b(2'b10);
        #1;
        check(legacy_b_count == 1 && cira_b_count == 1, "legacy alone receives its B response");
        @(negedge clk);
        legacy_wvalid = 0;

        check(aw_count == 2 && w_count == 2, "arbiter issued exactly one serialized write per master");
        check(awaddr_log[0] == cira_awaddr && awaddr_log[1] == legacy_awaddr,
              "physical AW order matches selected transaction ownership");
        check(wdata_log[0] == cira_wdata && wdata_log[1] == legacy_wdata,
              "physical W order cannot cross transaction ownership");

        if (errors != 0) begin
            $display("%0d/%0d checks failed", errors, checks);
            $fatal(1);
        end
        $display("All %0d checks passed", checks);
        $finish;
    end
endmodule
