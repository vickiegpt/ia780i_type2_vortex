`timescale 1ns / 1ps

module tb_cxl_bundled_toggle_cdc;

    localparam int WIDTH = 136;

    logic src_clk = 1'b0;
    logic dst_clk = 1'b0;
    logic src_rst_n = 1'b0;
    logic dst_rst_n = 1'b0;
    logic src_send = 1'b0;
    logic [WIDTH-1:0] src_data = '0;
    logic dst_valid;
    logic [WIDTH-1:0] dst_data;

    int checks = 0;
    int errors = 0;
    int valid_count = 0;

    // Deliberately unrelated clocks exercise both source/destination orderings.
    always #4 src_clk = ~src_clk;
    always #6.5 dst_clk = ~dst_clk;

    cxl_bundled_toggle_cdc #(.WIDTH(WIDTH)) dut (
        .src_clk(src_clk),
        .src_rst_n(src_rst_n),
        .src_send(src_send),
        .src_data(src_data),
        .dst_clk(dst_clk),
        .dst_rst_n(dst_rst_n),
        .dst_valid(dst_valid),
        .dst_data(dst_data)
    );

    always_ff @(posedge dst_clk) begin
        if (dst_valid)
            valid_count <= valid_count + 1;
    end

    task automatic check(input logic cond, input string msg);
        checks++;
        if (cond) $display("  [ ok ] %s", msg);
        else begin
            $display("  [FAIL] %s", msg);
            errors++;
        end
    endtask

    task automatic send_bundle(input logic [WIDTH-1:0] payload);
        @(negedge src_clk);
        src_data = payload;
        src_send = 1'b1;
        @(negedge src_clk);
        src_send = 1'b0;
        // Deliberately corrupt the live input.  The destination must receive
        // the source-domain snapshot, never this later value.
        src_data = ~payload;
    endtask

    task automatic expect_bundle(input logic [WIDTH-1:0] payload,
                                 input int expected_count);
        int timeout;
        logic seen;
        begin
            seen = 1'b0;
            for (timeout = 0; timeout < 16; timeout++) begin
                @(posedge dst_clk);
                #1;
                if (dst_valid) begin
                    seen = 1'b1;
                    check(dst_data == payload, "destination receives one coherent source snapshot");
                    break;
                end
            end
            check(seen, "toggle transfer reaches destination");
            @(posedge dst_clk);
            #1;
            check(!dst_valid, "destination valid is a single-cycle pulse");
            check(valid_count == expected_count,
                  "exactly one destination event is emitted per source send");
        end
    endtask

    initial begin
        logic [WIDTH-1:0] first_payload;
        logic [WIDTH-1:0] second_payload;

        first_payload  = 136'h5a_0123_4567_89ab_cdef_fedc_ba98_7654_3210;
        second_payload = 136'ha5_dead_beef_cafe_f00d_1020_3040_5060_7080;

        repeat (3) @(posedge src_clk);
        src_rst_n = 1'b1;
        repeat (2) @(posedge dst_clk);
        dst_rst_n = 1'b1;

        $display("=== Bundled toggle CDC tests ===");
        send_bundle(first_payload);
        expect_bundle(first_payload, 1);

        repeat (3) @(posedge src_clk);
        send_bundle(second_payload);
        expect_bundle(second_payload, 2);

        check(dst_data == second_payload,
              "destination snapshot remains stable between transfer events");

        $display("Checks: %0d, errors: %0d", checks, errors);
        if (errors != 0)
            $fatal(1, "bundled toggle CDC regression failed");
        $finish;
    end

endmodule
