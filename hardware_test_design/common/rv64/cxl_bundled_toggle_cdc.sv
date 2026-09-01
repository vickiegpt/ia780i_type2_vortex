// Multi-cycle-path bundled-data clock-domain crossing.
//
// The source captures the complete payload before toggling the one-bit event.
// The payload remains stable until the next event.  Only the event bit passes
// through a metastability synchronizer; the destination captures the stable
// payload after observing the synchronized toggle.  Static timing constraints
// bound payload skew/delay relative to the destination clock.
module cxl_bundled_toggle_cdc #(
    parameter int WIDTH = 1
) (
    input  logic             src_clk,
    input  logic             src_rst_n,
    input  logic             src_send,
    input  logic [WIDTH-1:0] src_data,

    input  logic             dst_clk,
    input  logic             dst_rst_n,
    output logic             dst_valid,
    output logic [WIDTH-1:0] dst_data
);

    (* preserve *) logic [WIDTH-1:0] src_data_hold;
    (* preserve *) logic             src_toggle;

    (* altera_attribute = {"-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; "
                           "-name SYNCHRONIZER_IDENTIFICATION FORCED; "
                           "-name DONT_MERGE_REGISTER ON; "
                           "-name PRESERVE_REGISTER ON"} *)
    logic dst_toggle_meta;
    (* preserve *) logic dst_toggle_sync;
    (* preserve *) logic dst_toggle_seen;
    (* preserve *) logic [WIDTH-1:0] dst_data_hold;

    assign dst_data = dst_data_hold;

    always_ff @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_data_hold <= '0;
            src_toggle    <= 1'b0;
        end else if (src_send) begin
            src_data_hold <= src_data;
            src_toggle    <= ~src_toggle;
        end
    end

    always_ff @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_toggle_meta <= 1'b0;
            dst_toggle_sync <= 1'b0;
            dst_toggle_seen <= 1'b0;
            dst_valid       <= 1'b0;
            dst_data_hold   <= '0;
        end else begin
            dst_toggle_meta <= src_toggle;
            dst_toggle_sync <= dst_toggle_meta;
            dst_toggle_seen <= dst_toggle_sync;
            dst_valid       <= 1'b0;

            if (dst_toggle_sync != dst_toggle_seen) begin
                dst_data_hold <= src_data_hold;
                dst_valid     <= 1'b1;
            end
        end
    end

endmodule
