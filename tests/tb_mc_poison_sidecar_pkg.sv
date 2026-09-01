`timescale 1ns/1ps

module tb_mc_poison_sidecar_pkg;
  import mc_poison_sidecar_pkg::*;

  int checks;

  task automatic check(input logic condition, input string description);
    if (!condition)
      $fatal(1, "POISON_SIDECAR_PKG: FAIL: %s", description);
    checks++;
  endtask

  initial begin
    check(PHYS_LINE_COUNT_PER_CHANNEL == 28'h800_0000,
          "physical line count");
    check(DATA_LINE_COUNT_PER_CHANNEL == 28'h7e0_0000,
          "data line count");
    check(POISON_META_LINE_COUNT == 28'h003_f000,
          "bitmap line count");
    check(poison_meta_line(27'h0) == 27'h7e0_0000,
          "first metadata line");
    check(poison_bit_select(27'h0) == 9'h000, "first bit");
    check(poison_meta_line(27'h1ff) == 27'h7e0_0000,
          "last bit same line");
    check(poison_bit_select(27'h1ff) == 9'h1ff,
          "last bit select");
    check(poison_meta_line(27'h200) == 27'h7e0_0001,
          "next metadata line");
    check({1'b0, poison_meta_line(DATA_LINE_COUNT_PER_CHANNEL[26:0] - 1)} <
          PHYS_LINE_COUNT_PER_CHANNEL,
          "last metadata address is physical");
    check(!is_host_data_line(POISON_META_BASE_LINE[26:0]),
          "metadata is hidden");
    check(VISIBLE_BYTES_PER_CHANNEL == 64'h0000_0001_f800_0000,
          "7.875 GiB per channel");
    check(VISIBLE_BYTES_TOTAL == 64'h0000_0003_f000_0000,
          "15.75 GiB total");
    check(HDM_SIZE_256MB == 36'h03f,
          "63 256-MiB HDM units");

    $display("POISON_SIDECAR_PKG: PASS (%0d checks)", checks);
    $finish;
  end
endmodule
