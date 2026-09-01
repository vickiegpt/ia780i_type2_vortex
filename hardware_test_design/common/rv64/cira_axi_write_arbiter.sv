`timescale 1ns / 1ps

// Serialize the legacy AFU write master and the CIRA CXL.cache completion
// writer onto the generated AXI1/CAFU port.  Ownership begins when AW is
// accepted and is retained through W and B, so channel fragments from the two
// masters cannot be combined into one AXI transaction.
module cira_axi_write_arbiter (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [11:0]  legacy_awid,
    input  logic [63:0]  legacy_awaddr,
    input  logic [9:0]   legacy_awlen,
    input  logic [2:0]   legacy_awsize,
    input  logic [1:0]   legacy_awburst,
    input  logic [2:0]   legacy_awprot,
    input  logic [3:0]   legacy_awqos,
    input  logic [6:0]   legacy_awuser,
    input  logic         legacy_awvalid,
    input  logic [3:0]   legacy_awcache,
    input  logic [1:0]   legacy_awlock,
    input  logic [3:0]   legacy_awregion,
    input  logic [5:0]   legacy_awatop,
    output logic         legacy_awready,
    input  logic [511:0] legacy_wdata,
    input  logic [63:0]  legacy_wstrb,
    input  logic         legacy_wlast,
    input  logic         legacy_wuser,
    input  logic         legacy_wvalid,
    output logic         legacy_wready,
    output logic [11:0]  legacy_bid,
    output logic [1:0]   legacy_bresp,
    output logic [3:0]   legacy_buser,
    output logic         legacy_bvalid,
    input  logic         legacy_bready,

    input  logic [11:0]  cira_awid,
    input  logic [63:0]  cira_awaddr,
    input  logic [9:0]   cira_awlen,
    input  logic [2:0]   cira_awsize,
    input  logic [1:0]   cira_awburst,
    input  logic [2:0]   cira_awprot,
    input  logic [3:0]   cira_awqos,
    input  logic [6:0]   cira_awuser,
    input  logic         cira_awvalid,
    input  logic [3:0]   cira_awcache,
    input  logic [1:0]   cira_awlock,
    input  logic [3:0]   cira_awregion,
    input  logic [5:0]   cira_awatop,
    output logic         cira_awready,
    input  logic [511:0] cira_wdata,
    input  logic [63:0]  cira_wstrb,
    input  logic         cira_wlast,
    input  logic         cira_wuser,
    input  logic         cira_wvalid,
    output logic         cira_wready,
    output logic [11:0]  cira_bid,
    output logic [1:0]   cira_bresp,
    output logic [3:0]   cira_buser,
    output logic         cira_bvalid,
    input  logic         cira_bready,

    output logic [11:0]  phy_awid,
    output logic [63:0]  phy_awaddr,
    output logic [9:0]   phy_awlen,
    output logic [2:0]   phy_awsize,
    output logic [1:0]   phy_awburst,
    output logic [2:0]   phy_awprot,
    output logic [3:0]   phy_awqos,
    output logic [6:0]   phy_awuser,
    output logic         phy_awvalid,
    output logic [3:0]   phy_awcache,
    output logic [1:0]   phy_awlock,
    output logic [3:0]   phy_awregion,
    output logic [5:0]   phy_awatop,
    input  logic         phy_awready,
    output logic [511:0] phy_wdata,
    output logic [63:0]  phy_wstrb,
    output logic         phy_wlast,
    output logic         phy_wuser,
    output logic         phy_wvalid,
    input  logic         phy_wready,
    input  logic [11:0]  phy_bid,
    input  logic [1:0]   phy_bresp,
    input  logic [3:0]   phy_buser,
    input  logic         phy_bvalid,
    output logic         phy_bready
);

    typedef enum logic [1:0] { ST_IDLE, ST_W, ST_B } state_t;
    state_t state;
    logic owner_cira;

    always_comb begin
        legacy_awready = 1'b0;
        legacy_wready  = 1'b0;
        legacy_bid     = '0;
        legacy_bresp   = '0;
        legacy_buser   = '0;
        legacy_bvalid  = 1'b0;
        cira_awready   = 1'b0;
        cira_wready    = 1'b0;
        cira_bid       = '0;
        cira_bresp     = '0;
        cira_buser     = '0;
        cira_bvalid    = 1'b0;

        phy_awid       = '0;
        phy_awaddr     = '0;
        phy_awlen      = '0;
        phy_awsize     = '0;
        phy_awburst    = '0;
        phy_awprot     = '0;
        phy_awqos      = '0;
        phy_awuser     = '0;
        phy_awvalid    = 1'b0;
        phy_awcache    = '0;
        phy_awlock     = '0;
        phy_awregion   = '0;
        phy_awatop     = '0;
        phy_wdata      = '0;
        phy_wstrb      = '0;
        phy_wlast      = 1'b0;
        phy_wuser      = 1'b0;
        phy_wvalid     = 1'b0;
        phy_bready     = 1'b0;

        if (state == ST_IDLE) begin
            // A newly generated completion has priority so its payload and
            // magic commit make forward progress even while ATE is active.
            if (cira_awvalid) begin
                phy_awid     = cira_awid;
                phy_awaddr   = cira_awaddr;
                phy_awlen    = cira_awlen;
                phy_awsize   = cira_awsize;
                phy_awburst  = cira_awburst;
                phy_awprot   = cira_awprot;
                phy_awqos    = cira_awqos;
                phy_awuser   = cira_awuser;
                phy_awvalid  = cira_awvalid;
                phy_awcache  = cira_awcache;
                phy_awlock   = cira_awlock;
                phy_awregion = cira_awregion;
                phy_awatop   = cira_awatop;
                cira_awready = phy_awready;
            end else if (legacy_awvalid) begin
                phy_awid       = legacy_awid;
                phy_awaddr     = legacy_awaddr;
                phy_awlen      = legacy_awlen;
                phy_awsize     = legacy_awsize;
                phy_awburst    = legacy_awburst;
                phy_awprot     = legacy_awprot;
                phy_awqos      = legacy_awqos;
                phy_awuser     = legacy_awuser;
                phy_awvalid    = legacy_awvalid;
                phy_awcache    = legacy_awcache;
                phy_awlock     = legacy_awlock;
                phy_awregion   = legacy_awregion;
                phy_awatop     = legacy_awatop;
                legacy_awready = phy_awready;
            end
        end else if (state == ST_W) begin
            if (owner_cira) begin
                phy_wdata    = cira_wdata;
                phy_wstrb    = cira_wstrb;
                phy_wlast    = cira_wlast;
                phy_wuser    = cira_wuser;
                phy_wvalid   = cira_wvalid;
                cira_wready  = phy_wready;
            end else begin
                phy_wdata      = legacy_wdata;
                phy_wstrb      = legacy_wstrb;
                phy_wlast      = legacy_wlast;
                phy_wuser      = legacy_wuser;
                phy_wvalid     = legacy_wvalid;
                legacy_wready  = phy_wready;
            end
        end else begin
            if (owner_cira) begin
                cira_bid     = phy_bid;
                cira_bresp   = phy_bresp;
                cira_buser   = phy_buser;
                cira_bvalid  = phy_bvalid;
                phy_bready   = cira_bready;
            end else begin
                legacy_bid    = phy_bid;
                legacy_bresp  = phy_bresp;
                legacy_buser  = phy_buser;
                legacy_bvalid = phy_bvalid;
                phy_bready    = legacy_bready;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= ST_IDLE;
            owner_cira <= 1'b0;
        end else begin
            unique case (state)
                ST_IDLE: begin
                    if (cira_awvalid && phy_awready) begin
                        owner_cira <= 1'b1;
                        state <= ST_W;
                    end else if (legacy_awvalid && !cira_awvalid && phy_awready) begin
                        owner_cira <= 1'b0;
                        state <= ST_W;
                    end
                end
                ST_W: begin
                    if (phy_wvalid && phy_wready)
                        state <= ST_B;
                end
                ST_B: begin
                    if (phy_bvalid && phy_bready)
                        state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
