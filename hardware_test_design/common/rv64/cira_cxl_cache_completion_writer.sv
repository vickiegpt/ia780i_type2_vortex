`timescale 1ns / 1ps

// CXL.cache completion writer for CIRA jobs.
//
// A completion is published as two ordered coherent stores to one cache line:
//   1. 64-byte payload with magic == 0, followed by B OKAY.
//   2. a four-byte DEAD_BEEF magic store, followed by B OKAY.
// The host is therefore never allowed to observe a success magic before the
// payload's CXL.cache transaction has completed successfully.
module cira_cxl_cache_completion_writer (
    input  logic         clk,
    input  logic         rst_n,

    input  logic         req_valid,
    input  logic [31:0]  req_status,
    input  logic [63:0]  req_result,
    input  logic [63:0]  req_completion_hpa,
    output logic         req_busy,
    output logic         req_done,
    output logic         req_error,

    output logic [11:0]  awid,
    output logic [63:0]  awaddr,
    output logic [9:0]   awlen,
    output logic [2:0]   awsize,
    output logic [1:0]   awburst,
    output logic [2:0]   awprot,
    output logic [3:0]   awqos,
    output logic [6:0]   awuser,
    output logic         awvalid,
    output logic [3:0]   awcache,
    output logic [1:0]   awlock,
    output logic [3:0]   awregion,
    output logic [5:0]   awatop,
    input  logic         awready,

    output logic [511:0] wdata,
    output logic [63:0]  wstrb,
    output logic         wlast,
    output logic         wuser,
    output logic         wvalid,
    input  logic         wready,

    input  logic [11:0]  bid,
    input  logic [1:0]   bresp,
    input  logic [3:0]   buser,
    input  logic         bvalid,
    output logic         bready
);

    localparam logic [31:0] CIRA_CXL_COMPLETION_MAGIC = 32'hDEAD_BEEF;
    localparam logic [11:0] CIRA_AXI_ID = 12'hC1A;

    // CAFU t_cafu_axi4_awuser: {AtomicSwapIfEM, target_hdm,
    // do_not_send_d2hreq, opcode}.  eWR_CAFU_I_SO is opcode 2 and keeps the
    // operation on the CXL.cache path rather than the CXL.mem HDM path.
    localparam logic [6:0] CIRA_AWUSER_I_SO = 7'b0000010;
    localparam logic [3:0] CIRA_AWCACHE_DEVICE_BUFFERABLE = 4'b0001;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_PAYLOAD_AW,
        ST_PAYLOAD_W,
        ST_PAYLOAD_B,
        ST_COMMIT_AW,
        ST_COMMIT_W,
        ST_COMMIT_B
    } state_t;

    state_t state;
    logic [63:0] latched_hpa;
    logic [31:0] latched_status;
    logic [63:0] latched_result;
    logic [63:0] latched_cycles;
    logic [63:0] latched_timestamp;
    logic [63:0] cycle_counter;

    assign req_busy = (state != ST_IDLE);

    always_comb begin
        awid     = CIRA_AXI_ID;
        awaddr   = latched_hpa;
        awlen    = 10'd0;
        awsize   = 3'd6; // 64-byte cache line
        awburst  = 2'b00; // FIXED: one coherent cache-line write
        awprot   = 3'b000;
        awqos    = 4'b0000;
        awuser   = CIRA_AWUSER_I_SO;
        awvalid  = (state == ST_PAYLOAD_AW) || (state == ST_COMMIT_AW);
        awcache  = CIRA_AWCACHE_DEVICE_BUFFERABLE;
        awlock   = 2'b00;
        awregion = 4'b0000;
        awatop   = 6'b000000;

        wdata = '0;
        wstrb = 64'hffff_ffff_ffff_ffff;
        if (state == ST_COMMIT_W) begin
            wdata[31:0] = CIRA_CXL_COMPLETION_MAGIC;
            wstrb = 64'h0000_0000_0000_000f;
        end else begin
            wdata[31:0]    = 32'h0000_0000;
            wdata[63:32]   = latched_status;
            wdata[127:64]  = latched_result;
            wdata[191:128] = latched_cycles;
            wdata[255:192] = latched_timestamp;
        end
        wlast  = 1'b1;
        wuser  = 1'b0;
        wvalid = (state == ST_PAYLOAD_W) || (state == ST_COMMIT_W);

        bready = (state == ST_PAYLOAD_B) || (state == ST_COMMIT_B);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state             <= ST_IDLE;
            latched_hpa       <= '0;
            latched_status    <= '0;
            latched_result    <= '0;
            latched_cycles    <= '0;
            latched_timestamp <= '0;
            cycle_counter     <= '0;
            req_done          <= 1'b0;
            req_error         <= 1'b0;
        end else begin
            cycle_counter <= cycle_counter + 64'd1;
            req_done      <= 1'b0;
            req_error     <= 1'b0;

            unique case (state)
                ST_IDLE: begin
                    if (req_valid) begin
                        if (req_completion_hpa == 64'd0 || req_completion_hpa[5:0] != 6'd0) begin
                            req_error <= 1'b1;
                        end else begin
                            latched_hpa       <= req_completion_hpa;
                            latched_status    <= req_status;
                            latched_result    <= req_result;
                            latched_cycles    <= cycle_counter;
                            latched_timestamp <= cycle_counter;
                            state             <= ST_PAYLOAD_AW;
                        end
                    end
                end

                ST_PAYLOAD_AW: begin
                    if (awready)
                        state <= ST_PAYLOAD_W;
                end

                ST_PAYLOAD_W: begin
                    if (wready)
                        state <= ST_PAYLOAD_B;
                end

                ST_PAYLOAD_B: begin
                    if (bvalid) begin
                        if (bresp == 2'b00 && bid == CIRA_AXI_ID)
                            state <= ST_COMMIT_AW;
                        else begin
                            req_error <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end
                end

                ST_COMMIT_AW: begin
                    if (awready)
                        state <= ST_COMMIT_W;
                end

                ST_COMMIT_W: begin
                    if (wready)
                        state <= ST_COMMIT_B;
                end

                ST_COMMIT_B: begin
                    if (bvalid) begin
                        if (bresp == 2'b00 && bid == CIRA_AXI_ID)
                            req_done <= 1'b1;
                        else
                            req_error <= 1'b1;
                        state <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    // BUSER is intentionally ignored by this AXI4 completion protocol.
    logic unused_buser;
    assign unused_buser = ^buser;

endmodule
