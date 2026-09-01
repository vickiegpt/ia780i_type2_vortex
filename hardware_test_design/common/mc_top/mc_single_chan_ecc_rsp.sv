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

module mc_single_chan_ecc_rsp
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
 
  /* HDM emif-axi signals in
  */
  input logic [ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] noc2hdm_aximm_rresp_emifclk,
  input logic [hdm_axi_if_pkg::HDM_AXI_RDATA_BW-1:0]                noc2hdm_aximm_rdata_emifclk,
  input logic [hdm_axi_if_pkg::HDM_AXI_RID_BW-1:0]                  noc2hdm_aximm_rid_emifclk,
  input logic                                                       noc2hdm_aximm_rlast_emifclk,  
  input logic [hdm_axi_if_pkg::HDM_AXI_RUSER_t_BW-1:0]              noc2hdm_aximm_ruser_emifclk,
  input logic                                                       noc2hdm_aximm_rvalid_emifclk,
 
  /* AVMM read response signals in
  */ 
  input logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] avmm_rd_rsp_data_emifclk,
  input logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    avmm_rd_rsp_id_emifclk,
  input logic                                                        sidecar_read_poison_emifclk,

  input logic avmm_rd_rsp_valid_emifclk,
 
  /* responses to RMW to cdc_rspfifo
  */ 
  output ddr_mc_top_common_pkg::t_rchan_rspfifo_data     eccrsp2rmw_rd_resp_emifclk,
  output ddr_mc_top_common_pkg::t_rchan_rspfifo_ecc      eccrsp2rmw_rd_ecc_emifclk
);

`ifdef IA780I
// IA-780I has no external ECC lane.  Return the native 512-bit payload and
// pipeline poison metadata beside it with the configured one-cycle response
// latency.
always_ff @(posedge emifclk)
begin
  if (!emifresetn) begin
    eccrsp2rmw_rd_resp_emifclk <= '0;
    eccrsp2rmw_rd_ecc_emifclk  <= '0;
  end
  else begin
    eccrsp2rmw_rd_resp_emifclk.read_data <= emif_avmm_1_axi_0
      ? avmm_rd_rsp_data_emifclk
      : noc2hdm_aximm_rdata_emifclk;
    eccrsp2rmw_rd_resp_emifclk.read_id <= emif_avmm_1_axi_0
      ? avmm_rd_rsp_id_emifclk
      : noc2hdm_aximm_rid_emifclk[ddr_mc_top_common_pkg::MC_LOCAL_AXI_RRC_ID_BW-1:0];
    eccrsp2rmw_rd_resp_emifclk.read_axi_resp <= emif_avmm_1_axi_0
      ? ddr_mc_top_common_pkg::eresp_MCTOP_OKAY
      : ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding'(noc2hdm_aximm_rresp_emifclk);
    eccrsp2rmw_rd_resp_emifclk.read_resp_valid <= emif_avmm_1_axi_0
      ? avmm_rd_rsp_valid_emifclk
      : noc2hdm_aximm_rvalid_emifclk;
    eccrsp2rmw_rd_resp_emifclk.read_poison <= sidecar_read_poison_emifclk;

    eccrsp2rmw_rd_ecc_emifclk.ecc_err_corrected <= '0;
    eccrsp2rmw_rd_ecc_emifclk.ecc_err_detected  <= '0;
    eccrsp2rmw_rd_ecc_emifclk.ecc_err_fatal     <= '0;
    eccrsp2rmw_rd_ecc_emifclk.ecc_err_syn_e     <= '0;
    eccrsp2rmw_rd_ecc_emifclk.ecc_err_valid <= emif_avmm_1_axi_0
      ? avmm_rd_rsp_valid_emifclk
      : noc2hdm_aximm_rvalid_emifclk;
  end
end

`else
// ================================================================================================
/* MUX between emif_avmm and emif_axi
*/
ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding    muxed_read_axi_rresp;

logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] muxed_read_data;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RRC_ID_BW-1:0]    muxed_read_id;

logic muxed_read_rsp_valid;

assign muxed_read_rsp_valid = emif_avmm_1_axi_0 ? avmm_rd_rsp_valid_emifclk : noc2hdm_aximm_rvalid_emifclk;

assign muxed_read_id = emif_avmm_1_axi_0 ? avmm_rd_rsp_id_emifclk : noc2hdm_aximm_rid_emifclk[ddr_mc_top_common_pkg::MC_LOCAL_AXI_RRC_ID_BW-1:0];

assign muxed_read_axi_rresp = emif_avmm_1_axi_0 ? ddr_mc_top_common_pkg::eresp_MCTOP_OKAY : ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding'(noc2hdm_aximm_rresp_emifclk);

assign muxed_read_data = emif_avmm_1_axi_0 ? avmm_rd_rsp_data_emifclk
                                           : {noc2hdm_aximm_ruser_emifclk[63:56], noc2hdm_aximm_rdata_emifclk[511:448],
                                              noc2hdm_aximm_ruser_emifclk[55:48], noc2hdm_aximm_rdata_emifclk[447:384],
                                              noc2hdm_aximm_ruser_emifclk[47:40], noc2hdm_aximm_rdata_emifclk[383:320],
                                              noc2hdm_aximm_ruser_emifclk[39:32], noc2hdm_aximm_rdata_emifclk[319:256],
                                              noc2hdm_aximm_ruser_emifclk[31:24], noc2hdm_aximm_rdata_emifclk[255:192],
                                              noc2hdm_aximm_ruser_emifclk[23:16], noc2hdm_aximm_rdata_emifclk[191:128],
                                              noc2hdm_aximm_ruser_emifclk[15:8],  noc2hdm_aximm_rdata_emifclk[127:64],
                                              noc2hdm_aximm_ruser_emifclk[7:0],   noc2hdm_aximm_rdata_emifclk[63:0]};

// ================================================================================================
/* detect single and double bit errors in the readdata from emif
   used to set as poison back to CXLIP
   
   Also, staging the rest of the read_rsp to align with the altecc_dec_latency1/2 module;
*/
logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] altecc_dec_q;

logic [ALTECC_INST_NUMBER-1:0] altecc_dec_err_corrected;
logic [ALTECC_INST_NUMBER-1:0] altecc_dec_err_detected;
logic [ALTECC_INST_NUMBER-1:0] altecc_dec_err_fatal;
logic [ALTECC_INST_NUMBER-1:0] altecc_dec_syn_e;

generate if( MC_ECC_DEC_LATENCY == 1 )
begin : GEN_ECC_DEC_LATENCY_1
  for( genvar alteccCount = 0; alteccCount < ALTECC_INST_NUMBER; alteccCount=alteccCount+1 )
  begin : GEN_ECC_DEC_LATENCY_1_alteccCount

`ifdef IA780I
  always_ff @(posedge emifclk)
  begin
    altecc_dec_q[alteccCount*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH] <= muxed_read_data[alteccCount*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH];
    altecc_dec_err_corrected[alteccCount] <= 'h0;
    altecc_dec_err_detected[alteccCount]  <= 'h0;
    altecc_dec_err_fatal[alteccCount]     <= 'h0;
    altecc_dec_syn_e[alteccCount]         <= 'h0;
  end
`else
      altecc_dec_latency1   altecc_dec_inst 
      (
        .clock         ( emifclk ),
      
        .data          ( muxed_read_data[alteccCount*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH] ),
        .q             (    altecc_dec_q[alteccCount*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH] ),

        .err_corrected ( altecc_dec_err_corrected[alteccCount] ),
        .err_detected  (  altecc_dec_err_detected[alteccCount] ),
        .err_fatal     (     altecc_dec_err_fatal[alteccCount] ),
        .syn_e         (         altecc_dec_syn_e[alteccCount] )
      );
`endif
  end  // GEN_ECC_DEC_LATENCY_1_alteccCount
end    // GEN_ECC_DEC_LATENCY_1
else begin : GEN_ECC_DEC_LATENCY_2
  for( genvar alteccCount = 0; alteccCount < ALTECC_INST_NUMBER; alteccCount=alteccCount+1 )
  begin : GEN_ECC_DEC_LATENCY_2_alteccCount

      altecc_dec_latency2   altecc_dec_inst 
      (
        .clock         ( emifclk ),
      
        .data          ( muxed_read_data[alteccCount*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH] ),
        .q             (    altecc_dec_q[alteccCount*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH] ),

        .err_corrected ( altecc_dec_err_corrected[alteccCount] ),
        .err_detected  (  altecc_dec_err_detected[alteccCount] ),
        .err_fatal     (     altecc_dec_err_fatal[alteccCount] ),
        .syn_e         (         altecc_dec_syn_e[alteccCount] )
      );

  end  // GEN_ECC_DEC_LATENCY_2_alteccCount
end    // GEN_ECC_DEC_LATENCY_2
endgenerate

// ================================================================================================
generate if( MC_ECC_DEC_LATENCY == 1 )
begin : GEN_ECC_DEC_LATENCY_1_SHIFT

      ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding         shift_read_axi_rresp;			
      logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RRC_ID_BW-1:0] shift_read_id;
      logic                                                     shift_read_resp_valid;
	  
      always_ff @( posedge emifclk ) shift_read_resp_valid <= ~emifresetn ? '0 : muxed_read_rsp_valid;
	  
      always_ff @( posedge emifclk ) shift_read_id <= ~emifresetn ? '0 : muxed_read_id;
	  
      always_ff @( posedge emifclk ) shift_read_axi_rresp <= ~emifresetn ? ddr_mc_top_common_pkg::eresp_MCTOP_OKAY : ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding'(muxed_read_axi_rresp);
      
      assign eccrsp2rmw_rd_resp_emifclk.read_data       = altecc_dec_q;
      assign eccrsp2rmw_rd_resp_emifclk.read_id         = shift_read_id;
      assign eccrsp2rmw_rd_resp_emifclk.read_poison     = ( altecc_dec_err_fatal != 0);
      assign eccrsp2rmw_rd_resp_emifclk.read_axi_resp   = shift_read_axi_rresp;
      assign eccrsp2rmw_rd_resp_emifclk.read_resp_valid = shift_read_resp_valid;

      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_corrected = altecc_dec_err_corrected;
      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_detected  = altecc_dec_err_detected;
      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_fatal     = altecc_dec_err_fatal;
      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_syn_e     = altecc_dec_syn_e;
      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_valid     = shift_read_resp_valid;

end    // GEN_ECC_DEC_LATENCY_1_SHIFT
else begin : GEN_ECC_DEC_LATENCY_2_SHIFT

      ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding         shift_read_axi_rresp_0;
      ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding         shift_read_axi_rresp_1;   
      logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RRC_ID_BW-1:0] shift_read_id_0;
      logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RRC_ID_BW-1:0] shift_read_id_1;
      logic                                                     shift_read_resp_valid_0;
      logic                                                     shift_read_resp_valid_1;      

      always_ff @( posedge emifclk ) shift_read_resp_valid_0 <= ~emifresetn ? '0 : muxed_read_rsp_valid;
      always_ff @( posedge emifclk ) shift_read_resp_valid_1 <= ~emifresetn ? '0 : shift_read_resp_valid_0;
      
      always_ff @( posedge emifclk ) shift_read_id_0 <= ~emifresetn ? '0 : muxed_read_id;
      always_ff @( posedge emifclk ) shift_read_id_1 <= ~emifresetn ? '0 : shift_read_id_0;
      
      always_ff @( posedge emifclk ) shift_read_axi_rresp_0 <= ~emifresetn ? ddr_mc_top_common_pkg::eresp_MCTOP_OKAY : ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding'(muxed_read_axi_rresp);
      always_ff @( posedge emifclk ) shift_read_axi_rresp_1 <= ~emifresetn ? ddr_mc_top_common_pkg::eresp_MCTOP_OKAY : ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding'(shift_read_axi_rresp_0);

      assign eccrsp2rmw_rd_resp_emifclk.read_data       = altecc_dec_q;
      assign eccrsp2rmw_rd_resp_emifclk.read_id         = shift_read_id_1;
      assign eccrsp2rmw_rd_resp_emifclk.read_poison     = ( altecc_dec_err_fatal != 0);
      assign eccrsp2rmw_rd_resp_emifclk.read_axi_resp   = shift_read_axi_rresp_1;
      assign eccrsp2rmw_rd_resp_emifclk.read_resp_valid = shift_read_resp_valid_1;

      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_corrected = altecc_dec_err_corrected;
      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_detected  = altecc_dec_err_detected;
      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_fatal     = altecc_dec_err_fatal;
      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_syn_e     = altecc_dec_syn_e;
      assign eccrsp2rmw_rd_ecc_emifclk.ecc_err_valid     = shift_read_resp_valid_1;

end    // GEN_ECC_DEC_LATENCY_2_SHIFT
endgenerate
`endif

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3TW0bPCixBuFWfiJ343rPhYgMPwbC//9YnVYZkAvlLR7D/WaEKBPkhYOdC7IYEbIjSTs84djraAYCgz6nFUqqO0VpFUO5W6k1e82OqxEWaS2DQOQpSKGLtdrHvRH7v4XOw8iR+45n+/padxz8rVMVQlBMgwAFyWRZiw0dEGoHb6vB4GDcc4Yra8GjQ3ujvatlxRJepzyqlIHDzSjuPRqOK8eOJ/2V4s+A64WcKO9HOoqwACAj50LSgwP2lJ9A7oNCO4QbZBgoITMJzkCAqSgnuQoRifOhDjhVRAU6Sr7jmdu39XgFNcY3UmvbZBQhkmoJiR14jragstxgRadoO38vwzDRwemXXHePnfSzzKw6YzogMJJCXm5vHcTumvtR8XIkgd7hbQJ/aFsVHEIi+pw8SCc0BNm9YFcWo/HNrXUXT4lrvqt+uzMplXbE80zClTfkbDXh4x1PmDHDQ0pjYGGakvEYZP4v8Eie3O074Og2MiNlgvdKllf/H+h0eFyQM7mVbUG7KcaQH1vcojIhwjogd8r02B3AIY1UYKl2yOxf7XsMDuG1f9HcBRvMO0W2MWqDEne3raDG9TA1I6rHBTLi1XQx8t1g0kgnILXmcVFEHB/JyJsYy8l2xOV2JhCFngnF9Cm6PGdfYfQBSvCIkRsgptVLL3UvSSdL6xFcG1CwBAGILXCeWlfZ4VN6y74iFwcbblBVspohhU2q+L7WRoFFST27uEcYQh+E1RiNn+4bquuFQ90bArpYEfmm8c0AgKxEgZSP05NCaS6ohCQzwD2baG"
`endif
