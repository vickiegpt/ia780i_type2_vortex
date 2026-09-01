`timescale 1ns/1ps

// Poison metadata layout for the IA-780I x64/no-ECC memory channels.
//
// Each channel has 8 GiB of physical DDR (2^27 64-byte lines).  The final
// 128 MiB is private to the FPGA.  One poison bit describes each host-visible
// line, so one 512-bit metadata line covers 512 data lines.
package mc_poison_sidecar_pkg;
  localparam logic [27:0] PHYS_LINE_COUNT_PER_CHANNEL = 28'h800_0000;
  localparam logic [27:0] PRIVATE_LINE_COUNT_PER_CHANNEL = 28'h020_0000;
  localparam logic [27:0] DATA_LINE_COUNT_PER_CHANNEL = 28'h7e0_0000;

  localparam logic [27:0] POISON_META_BASE_LINE = DATA_LINE_COUNT_PER_CHANNEL;
  localparam logic [27:0] POISON_META_LINE_COUNT =
    DATA_LINE_COUNT_PER_CHANNEL >> 9;

  localparam logic [63:0] VISIBLE_BYTES_PER_CHANNEL = 64'h0000_0001_f800_0000;
  localparam logic [63:0] VISIBLE_BYTES_TOTAL = 64'h0000_0003_f000_0000;
  localparam logic [35:0] HDM_SIZE_256MB = 36'h03f;

  localparam int unsigned POISON_LAYOUT_STATIC_ASSERT =
    1 / (((POISON_META_BASE_LINE + POISON_META_LINE_COUNT) <=
          PHYS_LINE_COUNT_PER_CHANNEL) ? 1 : 0);

  function automatic logic [26:0] poison_meta_line(
    input logic [26:0] data_line
  );
    poison_meta_line = POISON_META_BASE_LINE[26:0] + (data_line >> 9);
  endfunction

  function automatic logic [8:0] poison_bit_select(
    input logic [26:0] data_line
  );
    poison_bit_select = data_line[8:0];
  endfunction

  function automatic logic is_host_data_line(
    input logic [26:0] line_addr
  );
    is_host_data_line = {1'b0, line_addr} < DATA_LINE_COUNT_PER_CHANNEL;
  endfunction
endpackage
