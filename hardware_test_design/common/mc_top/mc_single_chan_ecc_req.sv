// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// Copyright 2024 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
///////////////////////////////////////////////////////////////////////

module mc_single_chan_ecc_req
  import ddr_mc_top_common_pkg::*;
  import hdm_axi_if_pkg::*;
#(
  parameter ALTECC_DATAWORD_WIDTH = 64,
  parameter ALTECC_CODEWORD_WIDTH = 72,
  parameter ALTECC_INST_NUMBER    = 8,
  parameter MC_ECC_ENC_LATENCY    = 0, // supported option 0 and 1; (latency in emif_usr_clk cycles)
  parameter MC_ECC_DEC_LATENCY    = 1, // supported option 1 and 2; (latency in emif_usr_clk cycles)

  localparam ECCENC_DATA_WIDTH     = ALTECC_INST_NUMBER * ALTECC_CODEWORD_WIDTH,
  localparam MEM_SYMBOL_WIDTH      = 8,
  localparam MEM_BE_WIDTH          = ECCENC_DATA_WIDTH / MEM_SYMBOL_WIDTH
 )
(
  input logic emifclk,                         // EMIF User Clock
  input logic emifresetn,                      // EMIF reset
  input logic emif_avmm_1_axi_0,
 
  /* signals to/from mc_rmw_block
  */
  input logic from_mcrmw_reqfifo_empty_emifclk,
  
  input ddr_mc_top_common_pkg::t_reqfifo_data_postRMW_preECC     from_mcrmw_new_req_emifclk,
 
  output logic to_mcrmw_mem_ready_emifclk,
 
  /* signals to/from emif-avmm-FSM
  */
  input ddr_mc_top_common_pkg::t_emif_fsm_cntrl_to_ecc      from_fsm_avmm_cntrl_emifclk,
  
  output ddr_mc_top_common_pkg::t_reqfifo_data_post_ecc_avmm     to_fsm_avmm_new_req_emifclk,
 
  /* signals to/from emif-aaxi4-FSM
  */
  input ddr_mc_top_common_pkg::t_emif_fsm_cntrl_to_ecc      from_fsm_axi4_cntrl_emifclk,
  
  output logic to_fsm_axi4_reqfifo_empty_emifclk,
  
  output ddr_mc_top_common_pkg::t_reqfifo_data_post_ecc_axi     to_fsm_axi4_new_req_emifclk
);

`ifdef IA780I
// IA-780I exposes a native 512-bit (64-byte) AVMM datapath.  Poison is
// metadata, not an ECC corruption: keep it in the request record so it stays
// aligned with the write through AVMM backpressure.
always_ff @(posedge emifclk)
begin
  if (!emifresetn)
    to_fsm_avmm_new_req_emifclk <= '0;
  else begin
    if (from_fsm_avmm_cntrl_emifclk.mem_ready) begin
      to_fsm_avmm_new_req_emifclk.wr_id        <= from_mcrmw_new_req_emifclk.wr_id;
      to_fsm_avmm_new_req_emifclk.rd_id        <= from_mcrmw_new_req_emifclk.rd_id;
      to_fsm_avmm_new_req_emifclk.address      <= from_mcrmw_new_req_emifclk.address;
      to_fsm_avmm_new_req_emifclk.writedata    <= from_mcrmw_new_req_emifclk.writedata;
      to_fsm_avmm_new_req_emifclk.write_poison <= from_mcrmw_new_req_emifclk.write_poison;
    end

    if (from_fsm_avmm_cntrl_emifclk.mem_ready && from_mcrmw_new_req_emifclk.write)
      to_fsm_avmm_new_req_emifclk.write <= 1'b1;
    else if (from_fsm_avmm_cntrl_emifclk.clear_write_valid)
      to_fsm_avmm_new_req_emifclk.write <= 1'b0;

    if (from_fsm_avmm_cntrl_emifclk.mem_ready && from_mcrmw_new_req_emifclk.read)
      to_fsm_avmm_new_req_emifclk.read <= 1'b1;
    else if (from_fsm_avmm_cntrl_emifclk.clear_read_valid)
      to_fsm_avmm_new_req_emifclk.read <= 1'b0;
  end
end

always_comb
begin
  to_fsm_axi4_reqfifo_empty_emifclk = 1'b1;
  to_fsm_axi4_new_req_emifclk       = '0;
  to_mcrmw_mem_ready_emifclk        = from_fsm_avmm_cntrl_emifclk.mem_ready;
end

`else
// ================================================================================================
/* altecc_enc_* -> encode (swivel) ecc with data
   altecc_dec_* -> unswivel ecc from data and determine any errors
*/
logic [ECCENC_DATA_WIDTH-1:0] writedata_with_ecc_encoded;

generate for( genvar alteccCount = 0 ; alteccCount < ddr_mc_top_common_pkg::MCTOP_ALTECC_INST_NUMBER ; alteccCount=alteccCount+1 )
begin : gen_ALTECC_ENC
  
  altecc_enc_latency0   altecc_enc_latency0_inst
  (
     .data ( from_mcrmw_new_req_emifclk.writedata[alteccCount*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH] ),
     .q    (           writedata_with_ecc_encoded[alteccCount*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH] )
  );
  
end
endgenerate

// ================================================================================================
// == invert/corrupt 2 ECC parity bits in case from_mcrmw_write_poison is set
// This will lead to err_fatal being set on decoder side and hence to from_mcecc_dec_memout_read_poison_mclk bit set.
// Note cuorrupting ECC parity bits instead of data bits has benefit of keeping data as is.
// Note that it is not recommended to invert/corrupt MSB ECC parity bit as it has longest logic depth
// (depends on all data bits and all other ECC parity bits) ==
logic [ECCENC_DATA_WIDTH-1:0] writedata_with_ecc_encoded_n_poison;

generate for(genvar i=0 ; i < ddr_mc_top_common_pkg::MCTOP_ALTECC_INST_NUMBER ; i=i+1) 
begin : gen_ECC_ENC_INST

  always_comb
  begin
`ifdef IA780I
    writedata_with_ecc_encoded_n_poison[i*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH] = from_mcrmw_new_req_emifclk.writedata[i*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH];
`else
    writedata_with_ecc_encoded_n_poison[i*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH]
           = writedata_with_ecc_encoded[i*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH];

    if( from_mcrmw_new_req_emifclk.write_poison )
	  begin
	    writedata_with_ecc_encoded_n_poison[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-1)] = !writedata_with_ecc_encoded[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-1)];
	    writedata_with_ecc_encoded_n_poison[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-2)] = !writedata_with_ecc_encoded[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-2)];
    end
    else if( i == 0 ) //RAS injection, single error injection so always use data group0 for simplicity (e.g. i=0)
    begin
      if( from_mcrmw_new_req_emifclk.write_ras_dbe )
	    begin
	      writedata_with_ecc_encoded_n_poison[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-1)] = !writedata_with_ecc_encoded[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-1)];
	      writedata_with_ecc_encoded_n_poison[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-2)] = !writedata_with_ecc_encoded[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-2)];
	    end
	    else if( from_mcrmw_new_req_emifclk.write_ras_sbe ) 
	    begin
	      writedata_with_ecc_encoded_n_poison[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-2)] = !writedata_with_ecc_encoded[((((i+1)*ALTECC_CODEWORD_WIDTH)-1)-2)];
	    end
	  end
`endif 
  end
end
endgenerate

// ================================================================================================
/* clock/pipeline the requests here if (MC_ECC_ENC_LATENCY == 1)
     and select between emif-avmm or emif-axi4 path for downstream FSM
*/
generate if( MC_ECC_ENC_LATENCY == 1 )
begin : gen_ECC_ENC_LATENCY_1

  logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] to_emif_avmm_writedata_comb;
  logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] to_emif_avmm_address_comb;
  logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    to_emif_avmm_wr_id_comb;
  logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    to_emif_avmm_rd_id_comb;
  logic                                                        to_emif_avmm_write_valid_comb;
  logic                                                        to_emif_avmm_read_valid_comb;
  logic                                                        to_emif_avmm_write_poison_comb;

  logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] to_emif_avmm_writedata_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] to_emif_avmm_address_emifclk;
  logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    to_emif_avmm_wr_id_emifclk;
  logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    to_emif_avmm_rd_id_emifclk;
  logic                                                        to_emif_avmm_write_valid_emifclk;
  logic                                                        to_emif_avmm_read_valid_emifclk;
  logic                                                        to_emif_avmm_write_poison_emifclk;

  logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] to_emif_axi4_writedata_comb;
  logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] to_emif_axi4_address_comb;
  logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    to_emif_axi4_wr_id_comb;
  logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    to_emif_axi4_rd_id_comb;
  logic                                                        to_emif_axi4_write_valid_comb;
  logic                                                        to_emif_axi4_read_valid_comb;
  hdm_axi_if_pkg::t_hdm_axi_wuser                              to_emif_axi4_wuser_ecc_comb;

  logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] to_emif_axi4_writedata_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] to_emif_axi4_address_emifclk;
  logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    to_emif_axi4_wr_id_emifclk;
  logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    to_emif_axi4_rd_id_emifclk;
  logic                                                        to_emif_axi4_write_valid_emifclk;
  logic                                                        to_emif_axi4_read_valid_emifclk;
  hdm_axi_if_pkg::t_hdm_axi_wuser                              to_emif_axi4_wuser_ecc_emifclk;

  logic to_fsm_axi4_reqfifo_empty_comb;

  // reqfifo empty to emif-axi-fsm, but not needed for emif-avmm-fsm
  assign to_fsm_axi4_reqfifo_empty_comb = emif_avmm_1_axi_0
                                          ? 1'b1
                                          : from_fsm_axi4_cntrl_emifclk.mem_ready
                                            ? from_mcrmw_reqfifo_empty_emifclk
                                            : to_fsm_axi4_reqfifo_empty_emifclk;
											
  assign to_emif_axi4_read_valid_comb = emif_avmm_1_axi_0
                                        ? 1'b0
                                        : (from_fsm_axi4_cntrl_emifclk.mem_ready & from_mcrmw_new_req_emifclk.read )
                                          ? 1'b1
                                          : from_fsm_axi4_cntrl_emifclk.clear_read_valid
                                            ? 1'b0
                                            : to_emif_axi4_read_valid_emifclk;
											
  assign to_emif_avmm_read_valid_comb = ~emif_avmm_1_axi_0
                                        ? 1'b0
                                        : (from_fsm_avmm_cntrl_emifclk.mem_ready & from_mcrmw_new_req_emifclk.read)
                                          ? 1'b1
                                          : from_fsm_avmm_cntrl_emifclk.clear_read_valid
                                            ? 1'b0
                                            : to_emif_avmm_read_valid_emifclk;
											
  assign to_emif_axi4_write_valid_comb = emif_avmm_1_axi_0
                                         ? 1'b0
                                         : (from_fsm_axi4_cntrl_emifclk.mem_ready & from_mcrmw_new_req_emifclk.write)
                                           ? 1'b1
                                           : from_fsm_axi4_cntrl_emifclk.clear_write_valid
                                             ? 1'b0
                                             : to_emif_axi4_write_valid_emifclk;

  assign to_emif_avmm_write_valid_comb = ~emif_avmm_1_axi_0
                                         ? 1'b0
                                         : (from_fsm_avmm_cntrl_emifclk.mem_ready & from_mcrmw_new_req_emifclk.write)
                                           ? 1'b1
                                           : from_fsm_avmm_cntrl_emifclk.clear_write_valid
                                             ? 1'b0
                                             : to_emif_avmm_write_valid_emifclk;									  

  assign to_emif_axi4_wr_id_comb = emif_avmm_1_axi_0
                                   ? '0
                                   : from_fsm_axi4_cntrl_emifclk.mem_ready
                                     ? from_mcrmw_new_req_emifclk.wr_id
                                     : to_emif_axi4_wr_id_emifclk;

  assign to_emif_avmm_wr_id_comb = ~emif_avmm_1_axi_0
                                   ? '0
                                   : from_fsm_avmm_cntrl_emifclk.mem_ready
                                     ? from_mcrmw_new_req_emifclk.wr_id
                                     : to_emif_avmm_wr_id_emifclk;
									 
  assign to_emif_axi4_rd_id_comb = emif_avmm_1_axi_0
                                   ? '0
                                   : from_fsm_axi4_cntrl_emifclk.mem_ready
                                     ? from_mcrmw_new_req_emifclk.rd_id
                                     : to_emif_axi4_rd_id_emifclk;
										  
  assign to_emif_avmm_rd_id_comb = ~emif_avmm_1_axi_0
                                   ? '0
                                   : from_fsm_avmm_cntrl_emifclk.mem_ready
                                     ? from_mcrmw_new_req_emifclk.rd_id
                                     : to_emif_avmm_rd_id_emifclk;
									 
  assign to_emif_axi4_address_comb = emif_avmm_1_axi_0
                                     ? '0
                                     : from_fsm_axi4_cntrl_emifclk.mem_ready
                                       ? from_mcrmw_new_req_emifclk.address
                                       : to_emif_axi4_address_emifclk;

  assign to_emif_avmm_address_comb = ~emif_avmm_1_axi_0
                                     ? '0
                                     : from_fsm_avmm_cntrl_emifclk.mem_ready
                                       ? from_mcrmw_new_req_emifclk.address
                                       : to_emif_avmm_address_emifclk;

  assign to_emif_avmm_write_poison_comb = ~emif_avmm_1_axi_0
                                          ? 1'b0
                                          : from_fsm_avmm_cntrl_emifclk.mem_ready
                                            ? from_mcrmw_new_req_emifclk.write_poison
                                            : to_emif_avmm_write_poison_emifclk;
									 
  // keep data and ecc encoded together for avmm
  assign to_emif_avmm_writedata_comb = ~emif_avmm_1_axi_0
                                       ? '0
									   : from_fsm_avmm_cntrl_emifclk.mem_ready
									     ? writedata_with_ecc_encoded_n_poison
									     : to_emif_avmm_writedata_emifclk;
									 
  // unswivel the ecc and data for AXI								 
  assign to_emif_axi4_writedata_comb = emif_avmm_1_axi_0
                                       ? '0
                                       : from_fsm_axi4_cntrl_emifclk.mem_ready
                                         ? {writedata_with_ecc_encoded_n_poison[567:504],
                                            writedata_with_ecc_encoded_n_poison[495:432],
                                            writedata_with_ecc_encoded_n_poison[423:360],
                                            writedata_with_ecc_encoded_n_poison[351:288],
		                                    writedata_with_ecc_encoded_n_poison[279:216],
		                                    writedata_with_ecc_encoded_n_poison[207:144],
		                                    writedata_with_ecc_encoded_n_poison[135:72],
		                                    writedata_with_ecc_encoded_n_poison[63:0]}
                                         : to_emif_axi4_writedata_emifclk;

  // unswivel the ecc and data for AXI	
  assign to_emif_axi4_wuser_ecc_comb = emif_avmm_1_axi_0
                                       ? '0
                                       : from_fsm_axi4_cntrl_emifclk.mem_ready
                                         ? {writedata_with_ecc_encoded_n_poison[575:568],
		                                    writedata_with_ecc_encoded_n_poison[503:496],
		                                    writedata_with_ecc_encoded_n_poison[431:424],
		                                    writedata_with_ecc_encoded_n_poison[359:352],
		                                    writedata_with_ecc_encoded_n_poison[287:280],
		                                    writedata_with_ecc_encoded_n_poison[215:208],
		                                    writedata_with_ecc_encoded_n_poison[143:136],
		                                    writedata_with_ecc_encoded_n_poison[71:64]}
									     : to_emif_axi4_wuser_ecc_emifclk;

  always_ff @( posedge emifclk )
  begin
    to_fsm_axi4_reqfifo_empty_emifclk <= ~emifresetn ? 1'b0 : to_fsm_axi4_reqfifo_empty_comb;  
    to_emif_axi4_read_valid_emifclk   <= ~emifresetn ? 1'b0 : to_emif_axi4_read_valid_comb;
    to_emif_axi4_write_valid_emifclk  <= ~emifresetn ? 1'b0 : to_emif_axi4_write_valid_comb;	
	
	to_emif_axi4_wr_id_emifclk     <= to_emif_axi4_wr_id_comb;
	to_emif_axi4_rd_id_emifclk     <= to_emif_axi4_rd_id_comb;									  
	to_emif_axi4_address_emifclk   <= to_emif_axi4_address_comb;	
	to_emif_axi4_writedata_emifclk <= to_emif_axi4_writedata_comb;
    to_emif_axi4_wuser_ecc_emifclk <= to_emif_axi4_wuser_ecc_comb;

    to_emif_avmm_read_valid_emifclk  <= ~emifresetn ? 1'b0 : to_emif_avmm_read_valid_comb;
    to_emif_avmm_write_valid_emifclk <= ~emifresetn ? 1'b0 : to_emif_avmm_write_valid_comb;	
	
	to_emif_avmm_wr_id_emifclk     <= to_emif_avmm_wr_id_comb;
	to_emif_avmm_rd_id_emifclk     <= to_emif_avmm_rd_id_comb;
	to_emif_avmm_address_emifclk   <= to_emif_avmm_address_comb;	
	to_emif_avmm_writedata_emifclk <= to_emif_avmm_writedata_comb;
	to_emif_avmm_write_poison_emifclk <= to_emif_avmm_write_poison_comb;
  end

  always_comb
  begin
    to_fsm_axi4_new_req_emifclk.write      = to_emif_axi4_write_valid_emifclk;
    to_fsm_axi4_new_req_emifclk.read       = to_emif_axi4_read_valid_emifclk;
    to_fsm_axi4_new_req_emifclk.wr_id      = to_emif_axi4_wr_id_emifclk;
    to_fsm_axi4_new_req_emifclk.rd_id      = to_emif_axi4_rd_id_emifclk;
    to_fsm_axi4_new_req_emifclk.address    = to_emif_axi4_address_emifclk;
    to_fsm_axi4_new_req_emifclk.writedata  = to_emif_axi4_writedata_emifclk;
    to_fsm_axi4_new_req_emifclk.wuser_ecc  = to_emif_axi4_wuser_ecc_emifclk;
    
    to_fsm_avmm_new_req_emifclk.write      = to_emif_avmm_write_valid_emifclk;
    to_fsm_avmm_new_req_emifclk.read       = to_emif_avmm_read_valid_emifclk;
    to_fsm_avmm_new_req_emifclk.wr_id      = to_emif_avmm_wr_id_emifclk;
    to_fsm_avmm_new_req_emifclk.rd_id      = to_emif_avmm_rd_id_emifclk;
    to_fsm_avmm_new_req_emifclk.address    = to_emif_avmm_address_emifclk;
    to_fsm_avmm_new_req_emifclk.writedata  = to_emif_avmm_writedata_emifclk;
    to_fsm_avmm_new_req_emifclk.write_poison = to_emif_avmm_write_poison_emifclk;
  end

end  // gen_ECC_ENC_LATENCY_1
else if( MC_ECC_ENC_LATENCY == 0 )
begin : gen_ECC_ENC_LATENCY_0

  always_comb
  begin
    to_fsm_axi4_reqfifo_empty_emifclk = emif_avmm_1_axi_0 | from_mcrmw_reqfifo_empty_emifclk;
  
    to_fsm_axi4_new_req_emifclk.read = ~emif_avmm_1_axi_0 & from_mcrmw_new_req_emifclk.read;

    to_fsm_avmm_new_req_emifclk.read = emif_avmm_1_axi_0 & from_mcrmw_new_req_emifclk.read;
	
    to_fsm_axi4_new_req_emifclk.write = ~emif_avmm_1_axi_0 & from_mcrmw_new_req_emifclk.write;

    to_fsm_avmm_new_req_emifclk.write = emif_avmm_1_axi_0 & from_mcrmw_new_req_emifclk.write;
	
    to_fsm_axi4_new_req_emifclk.wr_id = emif_avmm_1_axi_0 ? '0 : from_mcrmw_new_req_emifclk.wr_id;
  
    to_fsm_avmm_new_req_emifclk.wr_id = ~emif_avmm_1_axi_0 ? '0 : from_mcrmw_new_req_emifclk.wr_id;

    to_fsm_axi4_new_req_emifclk.rd_id = emif_avmm_1_axi_0 ? '0 : from_mcrmw_new_req_emifclk.rd_id;
  
    to_fsm_avmm_new_req_emifclk.rd_id = ~emif_avmm_1_axi_0 ? '0 : from_mcrmw_new_req_emifclk.rd_id;
										  
    to_fsm_axi4_new_req_emifclk.address = emif_avmm_1_axi_0 ? '0 : from_mcrmw_new_req_emifclk.address;

	to_fsm_avmm_new_req_emifclk.address = ~emif_avmm_1_axi_0 ? '0 : from_mcrmw_new_req_emifclk.address;

    // keep data and ecc encoded together for avmm
	to_fsm_avmm_new_req_emifclk.writedata = ~emif_avmm_1_axi_0 ? '0 : writedata_with_ecc_encoded_n_poison;
	to_fsm_avmm_new_req_emifclk.write_poison = ~emif_avmm_1_axi_0 ? 1'b0 : from_mcrmw_new_req_emifclk.write_poison;

    // unswivel the ecc and data for AXI
    to_fsm_axi4_new_req_emifclk.writedata = emif_avmm_1_axi_0
                                            ? '0
                                            : {writedata_with_ecc_encoded_n_poison[567:504],
                                               writedata_with_ecc_encoded_n_poison[495:432],
                                               writedata_with_ecc_encoded_n_poison[423:360],
                                               writedata_with_ecc_encoded_n_poison[351:288],
		                                       writedata_with_ecc_encoded_n_poison[279:216],
		                                       writedata_with_ecc_encoded_n_poison[207:144],
		                                       writedata_with_ecc_encoded_n_poison[135:72],
		                                       writedata_with_ecc_encoded_n_poison[63:0]};
											   
    // unswivel the ecc and data for AXI
    to_fsm_axi4_new_req_emifclk.wuser_ecc = emif_avmm_1_axi_0
                                            ? '0
                                            : {writedata_with_ecc_encoded_n_poison[575:568],
		                                       writedata_with_ecc_encoded_n_poison[503:496],
		                                       writedata_with_ecc_encoded_n_poison[431:424],
		                                       writedata_with_ecc_encoded_n_poison[359:352],
		                                       writedata_with_ecc_encoded_n_poison[287:280],
		                                       writedata_with_ecc_encoded_n_poison[215:208],
		                                       writedata_with_ecc_encoded_n_poison[143:136],
		                                       writedata_with_ecc_encoded_n_poison[71:64]};								 
  end

end  // gen_ECC_ENC_LATENCY_0
endgenerate

// ================================================================================================
assign to_mcrmw_mem_ready_emifclk = emif_avmm_1_axi_0
                                    ? from_fsm_avmm_cntrl_emifclk.mem_ready
                                    : from_fsm_axi4_cntrl_emifclk.mem_ready;
`endif

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3SEKB48JCvjMo5dc0reIZ4leFH3Lo21BXIsF0yU1zqR4us3Hm1VHTG9pqFepAEfTYjaeQrSIOb4bejicbSsWGRkTexVU0KEsRXCoopTp5jqAYdSBUZeeTaM+/mCkomoKUijDOQYALD8XgPLrGpxKsrv8BeGD29U0TrenA6m/+D+H9x/yM3u0BEKwtBWMzmMwtqkKN/j955ka5/0bsDfnwDHKnluHP5E7WJRlN/3QkuUgpB2sBnuWQf/+oRtzuyNbdcEJIoWV02D5E/rJo+q1eJ6lozDlFC96hvMAzbXI/ATA6kPOgAOzOJrMiYCiW2H/DjuIrQn1zSqbmW1AlpHBjC2ln1TYxPJUABXdKWC2p5MOz+/ARE1xVjdvpTEoR+p+Rozaye0dK7W+sCx2A3+isUuvwo/8BFTUmOnOg7CPHSEg+h8g8IR+XVV83M09pvULgT55sjKicCaf40f1mPEiwhSkP0F6lIEjZt3b78vxatGTyJuvZvuiBC9HVWk8fHXMuv5nk7OmdYIY+iAAS3rQKiVWDMfwYn/xaSp+4niU7t3ThgFjODCsP58Kb3vND9seoAA7LzJxV7qTfy3r2nI1h7YO507jvZD41Or1PJQM/QVyMbwCL8OToAHfFeJcW4D41SC1TChjdL0jFrExVrWexneW+oXYIj0TbgDkeVzMjAKmW0J9+T66sARJhy1NQobHmpzqoz5t8ry727hRZCBAO4OZoqIRu6qeWvOVcl0A1thiA452DP3Fnfj/Wl0XvFanAwH2M9bmRWWCRW3I3CcdXrK"
`endif
