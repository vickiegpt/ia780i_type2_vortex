`timescale 1ns/1ps

module tb_mc_poison_sidecar;
  import mc_poison_sidecar_pkg::*;

  logic clk = 1'b0;
  logic reset_n = 1'b0;

  logic [26:0]  up_address;
  logic [511:0] up_writedata;
  logic [63:0]  up_byteenable;
  logic         up_read;
  logic         up_write;
  logic         up_write_poison;
  logic [511:0] up_readdata;
  logic         up_readdatavalid;
  logic         up_read_poison;
  logic         up_ready;

  logic [26:0]  phy_address;
  logic [511:0] phy_writedata;
  logic [63:0]  phy_byteenable;
  logic         phy_read;
  logic         phy_write;
  logic [511:0] phy_readdata;
  logic         phy_readdatavalid;
  logic         phy_ready;

  logic [26:0]  ch1_up_address;
  logic [511:0] ch1_up_writedata;
  logic [63:0]  ch1_up_byteenable;
  logic         ch1_up_read;
  logic         ch1_up_write;
  logic         ch1_up_write_poison;
  logic [511:0] ch1_up_readdata;
  logic         ch1_up_readdatavalid;
  logic         ch1_up_read_poison;
  logic         ch1_up_ready;
  logic [26:0]  ch1_phy_address;
  logic [511:0] ch1_phy_writedata;
  logic [63:0]  ch1_phy_byteenable;
  logic         ch1_phy_read;
  logic         ch1_phy_write;
  logic [511:0] ch1_phy_readdata;
  logic         ch1_phy_readdatavalid;
  logic         ch1_phy_ready;

  logic [511:0] physical_mem [logic [26:0]];
  logic [511:0] ch1_physical_mem [logic [26:0]];
  int checks;
  int phy_accept_count;
  int meta_read_count;
  int meta_write_count;

  always #1 clk = ~clk;

  mc_poison_sidecar dut (.*);
  mc_poison_sidecar dut_ch1 (
    .clk               (clk),
    .reset_n           (reset_n),
    .up_address        (ch1_up_address),
    .up_writedata      (ch1_up_writedata),
    .up_byteenable     (ch1_up_byteenable),
    .up_read           (ch1_up_read),
    .up_write          (ch1_up_write),
    .up_write_poison   (ch1_up_write_poison),
    .up_readdata       (ch1_up_readdata),
    .up_readdatavalid  (ch1_up_readdatavalid),
    .up_read_poison    (ch1_up_read_poison),
    .up_ready          (ch1_up_ready),
    .phy_address       (ch1_phy_address),
    .phy_writedata     (ch1_phy_writedata),
    .phy_byteenable    (ch1_phy_byteenable),
    .phy_read          (ch1_phy_read),
    .phy_write         (ch1_phy_write),
    .phy_readdata      (ch1_phy_readdata),
    .phy_readdatavalid (ch1_phy_readdatavalid),
    .phy_ready         (ch1_phy_ready)
  );

  task automatic check(input logic condition, input string description);
    if (!condition)
      $fatal(1, "POISON_SIDECAR: FAIL: %s", description);
    checks++;
  endtask

  function automatic logic [511:0] memory_value(input logic [26:0] address);
    if (physical_mem.exists(address))
      return physical_mem[address];
    return '0;
  endfunction

  function automatic logic [511:0] ch1_memory_value(
    input logic [26:0] address
  );
    if (ch1_physical_mem.exists(address))
      return ch1_physical_mem[address];
    return '0;
  endfunction

  always_ff @(posedge clk) begin
    phy_readdatavalid <= 1'b0;
    if (phy_read && phy_ready) begin
      phy_readdata <= memory_value(phy_address);
      phy_readdatavalid <= 1'b1;
      phy_accept_count++;
      if ({1'b0, phy_address} >= POISON_META_BASE_LINE)
        meta_read_count++;
    end
    if (phy_write && phy_ready) begin
      for (int byte_index = 0; byte_index < 64; byte_index++) begin
        if (phy_byteenable[byte_index])
          physical_mem[phy_address][byte_index*8 +: 8] <=
            phy_writedata[byte_index*8 +: 8];
      end
      phy_accept_count++;
      if ({1'b0, phy_address} >= POISON_META_BASE_LINE)
        meta_write_count++;
    end
  end


  always_ff @(posedge clk) begin
    ch1_phy_readdatavalid <= 1'b0;
    if (ch1_phy_read && ch1_phy_ready) begin
      ch1_phy_readdata <= ch1_memory_value(ch1_phy_address);
      ch1_phy_readdatavalid <= 1'b1;
    end
    if (ch1_phy_write && ch1_phy_ready) begin
      for (int byte_index = 0; byte_index < 64; byte_index++) begin
        if (ch1_phy_byteenable[byte_index])
          ch1_physical_mem[ch1_phy_address][byte_index*8 +: 8] <=
            ch1_phy_writedata[byte_index*8 +: 8];
      end
    end
  end

  task automatic wait_until_ready;
    int timeout = 0;
    while (!up_ready) begin
      @(negedge clk);
      timeout++;
      if (timeout > 300000)
        $fatal(1, "POISON_SIDECAR: timeout waiting for up_ready");
    end
  endtask

  task automatic ch1_wait_until_ready;
    int timeout = 0;
    while (!ch1_up_ready) begin
      @(negedge clk);
      timeout++;
      if (timeout > 300000)
        $fatal(1, "POISON_SIDECAR: timeout waiting for channel 1 ready");
    end
  endtask

  task automatic ch1_data_write(
    input logic [26:0] address,
    input logic [511:0] data,
    input logic poison
  );
    ch1_up_address = address;
    ch1_wait_until_ready();
    @(negedge clk);
    ch1_up_writedata    = data;
    ch1_up_byteenable   = '1;
    ch1_up_write_poison = poison;
    ch1_up_write        = 1'b1;
    @(posedge clk);
    @(negedge clk);
    ch1_up_write = 1'b0;
    ch1_wait_until_ready();
  endtask

  task automatic ch1_data_read(
    input logic [26:0] address,
    output logic [511:0] data,
    output logic poison
  );
    int timeout = 0;
    ch1_up_address = address;
    ch1_wait_until_ready();
    @(negedge clk);
    ch1_up_read = 1'b1;
    @(posedge clk);
    @(negedge clk);
    ch1_up_read = 1'b0;
    while (!ch1_up_readdatavalid) begin
      @(negedge clk);
      timeout++;
      if (timeout > 100)
        $fatal(1, "POISON_SIDECAR: timeout waiting for channel 1 read");
    end
    data = ch1_up_readdata;
    poison = ch1_up_read_poison;
    ch1_wait_until_ready();
  endtask

  task automatic data_write(
    input logic [26:0] address,
    input logic [511:0] data,
    input logic poison
  );
    up_address = address;
    wait_until_ready();
    @(negedge clk);
    up_writedata    = data;
    up_byteenable   = '1;
    up_write_poison = poison;
    up_write        = 1'b1;
    @(posedge clk);
    @(negedge clk);
    up_write = 1'b0;
    wait_until_ready();
  endtask

  task automatic data_read(
    input logic [26:0] address,
    output logic [511:0] data,
    output logic poison
  );
    int timeout = 0;
    up_address = address;
    wait_until_ready();
    @(negedge clk);
    up_read    = 1'b1;
    @(posedge clk);
    @(negedge clk);
    up_read = 1'b0;
    while (!up_readdatavalid) begin
      @(negedge clk);
      timeout++;
      if (timeout > 100)
        $fatal(1, "POISON_SIDECAR: timeout waiting for read response");
    end
    data   = up_readdata;
    poison = up_read_poison;
    wait_until_ready();
  endtask

  task automatic hold_phy_ready(input int cycles);
    phy_ready = 1'b0;
    repeat (cycles) @(posedge clk);
    phy_ready = 1'b1;
  endtask

  task automatic evict_metadata_cache;
    logic [511:0] ignored_data;
    logic ignored_poison;
    for (int line_index = 0; line_index < 5; line_index++) begin
      data_read(line_index * 27'h200, ignored_data, ignored_poison);
    end
  endtask

  initial begin
    logic [511:0] read_data;
    logic read_poison;
    logic [26:0] address_a = 27'h000_0040;
    logic [26:0] address_b = 27'h000_0041;
    logic [511:0] pattern_a = {16{32'hc1a0_0040}};
    logic [511:0] pattern_b = {16{32'h5eed_0041}};
    int before_count;
    int before_meta_reads;
    logic [26:0] stalled_address;
    logic [511:0] stalled_data;

    up_address      = '0;
    up_writedata    = '0;
    up_byteenable   = '1;
    up_read         = 1'b0;
    up_write        = 1'b0;
    up_write_poison = 1'b0;
    phy_readdata    = '0;
    phy_readdatavalid = 1'b0;
    phy_ready       = 1'b1;
    ch1_up_address      = '0;
    ch1_up_writedata    = '0;
    ch1_up_byteenable   = '1;
    ch1_up_read         = 1'b0;
    ch1_up_write        = 1'b0;
    ch1_up_write_poison = 1'b0;
    ch1_phy_readdata      = '0;
    ch1_phy_readdatavalid = 1'b0;
    ch1_phy_ready         = 1'b1;
    phy_accept_count = 0;
    meta_read_count  = 0;
    meta_write_count = 0;

    repeat (3) @(posedge clk);
    reset_n = 1'b1;
    repeat (8) begin
      @(negedge clk);
      check(!up_ready, "summary initialization gates upstream ready");
    end
    wait_until_ready();

    before_meta_reads = meta_read_count;
    data_read(27'h10, read_data, read_poison);
    check(!read_poison, "clean read returns poison zero");
    check(meta_read_count == before_meta_reads,
          "clean read skips physical metadata read");

    before_meta_reads = meta_read_count;
    before_count = meta_write_count;
    data_write(address_a, pattern_a, 1'b1);
    check(memory_value(address_a) == pattern_a,
          "poisoned write stores payload data");
    check(memory_value(poison_meta_line(address_a))[poison_bit_select(address_a)],
          "poisoned write sets bitmap bit");
    check(meta_read_count == before_meta_reads,
          "first poisoned write uses zero summary without metadata read");
    check(meta_write_count == before_count + 1,
          "first poisoned write persists exactly one metadata line");

    data_read(address_a, read_data, read_poison);
    check(read_data == pattern_a, "poisoned read returns payload data");
    check(read_poison, "poisoned read returns poison one");

    data_write(address_a, pattern_b, 1'b0);
    check(!memory_value(poison_meta_line(address_a))[poison_bit_select(address_a)],
          "clean write clears bitmap bit");
    data_read(address_a, read_data, read_poison);
    check(!read_poison, "read after clean overwrite returns poison zero");

    data_write(address_a, pattern_a, 1'b1);
    data_write(address_b, pattern_b, 1'b1);
    data_write(address_a, pattern_a, 1'b0);
    check(!memory_value(poison_meta_line(address_a))[poison_bit_select(address_a)],
          "shared metadata line preserves cleared bit");
    check(memory_value(poison_meta_line(address_b))[poison_bit_select(address_b)],
          "shared metadata line preserves neighboring poisoned bit");

    for (int line_index = 0; line_index < 5; line_index++)
      data_write(27'h1000 + line_index * 27'h200,
                 {480'b0, line_index[31:0]}, 1'b1);
    evict_metadata_cache();
    for (int line_index = 0; line_index < 5; line_index++) begin
      data_read(27'h1000 + line_index * 27'h200,
                read_data, read_poison);
      check(read_poison, "metadata cache eviction preserves poison");
    end

    wait_until_ready();
    @(negedge clk);
    up_address      = 27'h2000;
    up_writedata    = {16{32'hface_2000}};
    up_byteenable   = '1;
    up_write_poison = 1'b0;
    up_write        = 1'b1;
    @(posedge clk);
    @(negedge clk);
    up_write = 1'b0;
    phy_ready = 1'b0;
    wait (phy_write);
    stalled_address = phy_address;
    stalled_data = phy_writedata;
    before_count = phy_accept_count;
    repeat (5) begin
      @(negedge clk);
      check(phy_write && phy_address == stalled_address &&
            phy_writedata == stalled_data,
            "physical request is stable under backpressure");
    end
    phy_ready = 1'b1;
    wait_until_ready();
    check(phy_accept_count == before_count + 1,
          "backpressured clean write is accepted exactly once");

    before_count = phy_accept_count;
    @(negedge clk);
    up_address = POISON_META_BASE_LINE[26:0];
    up_read = 1'b1;
    repeat (5) begin
      @(negedge clk);
      check(!up_ready && !phy_read && !phy_write,
            "private-range request is rejected without physical traffic");
    end
    up_read = 1'b0;
    check(phy_accept_count == before_count,
          "private-range request emits no physical request");

    data_write(27'h3000, pattern_a, 1'b0);
    ch1_data_write(27'h3000, pattern_b, 1'b1);
    data_read(27'h3000, read_data, read_poison);
    check(!read_poison, "channel 0 retains clean poison state");
    ch1_data_read(27'h3000, read_data, read_poison);
    check(read_poison, "channel 1 retains independent poisoned state");
    check(!memory_value(poison_meta_line(27'h3000))
             [poison_bit_select(27'h3000)],
          "channel 0 bitmap remains clear");
    check(ch1_memory_value(poison_meta_line(27'h3000))
             [poison_bit_select(27'h3000)],
          "channel 1 bitmap is isolated from channel 0");

    $display("POISON_SIDECAR: PASS (%0d checks)", checks);
    $finish;
  end
endmodule
