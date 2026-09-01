`timescale 1ns/1ps

module mc_poison_sidecar
  import mc_poison_sidecar_pkg::*;
(
  input  logic         clk,
  input  logic         reset_n,

  input  logic [26:0]  up_address,
  input  logic [511:0] up_writedata,
  input  logic [63:0]  up_byteenable,
  input  logic         up_read,
  input  logic         up_write,
  input  logic         up_write_poison,
  output logic [511:0] up_readdata,
  output logic         up_readdatavalid,
  output logic         up_read_poison,
  output logic         up_ready,

  output logic [26:0]  phy_address,
  output logic [511:0] phy_writedata,
  output logic [63:0]  phy_byteenable,
  output logic         phy_read,
  output logic         phy_write,
  input  logic [511:0] phy_readdata,
  input  logic         phy_readdatavalid,
  input  logic         phy_ready
);

  localparam int unsigned SUMMARY_ENTRIES = int'(POISON_META_LINE_COUNT);
  localparam logic [17:0] SUMMARY_LAST_INDEX =
    POISON_META_LINE_COUNT[17:0] - 18'd1;

  typedef enum logic [3:0] {
    ST_INIT,
    ST_IDLE,
    ST_DATA_REQ,
    ST_DATA_WAIT,
    ST_SUMMARY_LOOKUP,
    ST_SUMMARY_RESOLVE,
    ST_META_READ_REQ,
    ST_META_READ_WAIT,
    ST_META_WRITE_REQ,
    ST_RESPONSE
  } state_t;

  typedef struct packed {
    logic         valid;
    logic [15:0]  tag;
    logic [511:0] bits;
  } meta_cache_entry_t;

  (* ramstyle = "M20K" *) logic summary_ram [0:SUMMARY_ENTRIES-1];
  meta_cache_entry_t meta_cache [0:3];

  state_t state;
  logic [17:0] init_index;
  logic [17:0] meta_index;
  logic [1:0]  cache_index;
  logic [15:0] cache_tag;

  logic [26:0]  latched_address;
  logic [511:0] latched_writedata;
  logic [63:0]  latched_byteenable;
  logic         latched_read;
  logic         latched_write;
  logic         latched_write_poison;

  logic [511:0] latched_readdata;
  logic         resolved_read_poison;
  logic [511:0] pending_meta_bits;
  logic         summary_write_enable;
  logic [17:0]  summary_write_address;
  logic         summary_write_data;
  logic         summary_read_data;

  always_comb begin
    meta_index = latched_address[26:9];
    cache_index = meta_index[1:0];
    cache_tag = meta_index[17:2];

    up_ready = (state == ST_IDLE) && is_host_data_line(up_address);
    up_readdata = latched_readdata;
    up_readdatavalid = (state == ST_RESPONSE) && latched_read;
    up_read_poison = resolved_read_poison;

    phy_address = '0;
    phy_writedata = '0;
    phy_byteenable = '0;
    phy_read = 1'b0;
    phy_write = 1'b0;

    summary_write_enable = 1'b0;
    summary_write_address = meta_index;
    summary_write_data = |pending_meta_bits;

    if (reset_n && state == ST_INIT) begin
      summary_write_enable = 1'b1;
      summary_write_address = init_index;
      summary_write_data = 1'b0;
    end
    else if (reset_n && state == ST_META_WRITE_REQ && phy_ready) begin
      summary_write_enable = 1'b1;
    end

    case (state)
      ST_DATA_REQ: begin
        phy_address = latched_address;
        phy_writedata = latched_writedata;
        phy_byteenable = latched_byteenable;
        phy_read = latched_read;
        phy_write = latched_write;
      end

      ST_META_READ_REQ: begin
        phy_address = poison_meta_line(latched_address);
        phy_byteenable = '1;
        phy_read = 1'b1;
      end

      ST_META_WRITE_REQ: begin
        phy_address = poison_meta_line(latched_address);
        phy_writedata = pending_meta_bits;
        phy_byteenable = '1;
        phy_write = 1'b1;
      end

      default: begin
      end
    endcase
  end

  // Keep the large poison-summary array on one explicit synchronous RAM port.
  // Multiple procedural write sites make Quartus implement the 2^18 entries as
  // decoder logic instead of M20Ks, which is not a viable fit/timing structure.
  always_ff @(posedge clk) begin
    if (summary_write_enable)
      summary_ram[summary_write_address] <= summary_write_data;
    summary_read_data <= summary_ram[meta_index];
  end

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      state <= ST_INIT;
      init_index <= '0;
      latched_address <= '0;
      latched_writedata <= '0;
      latched_byteenable <= '0;
      latched_read <= 1'b0;
      latched_write <= 1'b0;
      latched_write_poison <= 1'b0;
      latched_readdata <= '0;
      resolved_read_poison <= 1'b0;
      pending_meta_bits <= '0;
      for (int cache_entry = 0; cache_entry < 4; cache_entry++)
        meta_cache[cache_entry] <= '0;
    end
    else begin
      case (state)
        ST_INIT: begin
          if (init_index == SUMMARY_LAST_INDEX) begin
            init_index <= '0;
            state <= ST_IDLE;
          end
          else begin
            init_index <= init_index + 1'b1;
          end
        end

        ST_IDLE: begin
          if ((up_read || up_write) && is_host_data_line(up_address)) begin
            latched_address <= up_address;
            latched_writedata <= up_writedata;
            latched_byteenable <= up_byteenable;
            latched_write <= up_write;
            latched_read <= up_read && !up_write;
            latched_write_poison <= up_write_poison;
            resolved_read_poison <= 1'b0;
            state <= ST_DATA_REQ;
          end
        end

        ST_DATA_REQ: begin
          if (phy_ready) begin
            if (latched_read)
              state <= ST_DATA_WAIT;
            else
              state <= ST_SUMMARY_LOOKUP;
          end
        end

        ST_DATA_WAIT: begin
          if (phy_readdatavalid) begin
            latched_readdata <= phy_readdata;
            state <= ST_SUMMARY_LOOKUP;
          end
        end

        ST_SUMMARY_LOOKUP: begin
          state <= ST_SUMMARY_RESOLVE;
        end

        ST_SUMMARY_RESOLVE: begin
          if (!summary_read_data) begin
            if (latched_read) begin
              resolved_read_poison <= 1'b0;
              state <= ST_RESPONSE;
            end
            else if (!latched_write_poison) begin
              state <= ST_RESPONSE;
            end
            else begin
              pending_meta_bits <= '0;
              pending_meta_bits[poison_bit_select(latched_address)] <= 1'b1;
              state <= ST_META_WRITE_REQ;
            end
          end
          else if (meta_cache[cache_index].valid &&
                   meta_cache[cache_index].tag == cache_tag) begin
            if (latched_read) begin
              resolved_read_poison <=
                meta_cache[cache_index].bits[poison_bit_select(latched_address)];
              state <= ST_RESPONSE;
            end
            else begin
              pending_meta_bits <= meta_cache[cache_index].bits;
              pending_meta_bits[poison_bit_select(latched_address)] <=
                latched_write_poison;
              state <= ST_META_WRITE_REQ;
            end
          end
          else begin
            state <= ST_META_READ_REQ;
          end
        end

        ST_META_READ_REQ: begin
          if (phy_ready)
            state <= ST_META_READ_WAIT;
        end

        ST_META_READ_WAIT: begin
          if (phy_readdatavalid) begin
            meta_cache[cache_index].valid <= 1'b1;
            meta_cache[cache_index].tag <= cache_tag;
            meta_cache[cache_index].bits <= phy_readdata;
            if (latched_read) begin
              resolved_read_poison <=
                phy_readdata[poison_bit_select(latched_address)];
              state <= ST_RESPONSE;
            end
            else begin
              pending_meta_bits <= phy_readdata;
              pending_meta_bits[poison_bit_select(latched_address)] <=
                latched_write_poison;
              state <= ST_META_WRITE_REQ;
            end
          end
        end

        ST_META_WRITE_REQ: begin
          if (phy_ready) begin
            meta_cache[cache_index].valid <= 1'b1;
            meta_cache[cache_index].tag <= cache_tag;
            meta_cache[cache_index].bits <= pending_meta_bits;
            state <= ST_RESPONSE;
          end
        end

        ST_RESPONSE: begin
          state <= ST_IDLE;
        end

        default: begin
          state <= ST_INIT;
          init_index <= '0;
        end
      endcase
    end
  end

endmodule
