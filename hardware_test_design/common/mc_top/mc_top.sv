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

module mc_top
  import ddr_mc_top_common_pkg::*;
  import hdm_axi_if_pkg::*;
#(
  // Note below FIFO plocalparams are not changing real fifo parameters.
  // To change real fifo parameters use IP Paremeter Editor
  // DATA WIDTH of REQFIFO (650) is set wider than actually needed, to avoid change of fifo IP settings
  //   for cases when DDR4 DIMM memory of other (bigger) size is used
  localparam REQFIFO_DEPTH_WIDTH         = 6,
  localparam REQFIFO_DATA_WIDTH          = 675,
  localparam RSPFIFO_DEPTH_WIDTH         = 6,
  localparam RSPFIFO_RCHAN_DATA_WIDTH    = 580,
  localparam RSPFIFO_BCHAN_DATA_WIDTH    = 16,

  // define a bits of mc_sr_status_eclk
  localparam MC_SR_STAT_WIDTH            = 5,
  localparam MC_SR_STAT_EMIF_CAL_FAIL    = 0,
  localparam MC_SR_STAT_EMIF_CAL_SUCCESS = 1,
  localparam MC_SR_STAT_EMIF_RESET_DONE  = 2,
  localparam MC_SR_STAT_EMIF_PLL_LOCKED  = 3,
  localparam MC_SR_STAT_RAM_INIT_DONE    = 4,
  localparam RST_REG_NUM                 = 2   // want to delete any usage of this eventually
 )
(
  input logic ipclk,
  input logic ipresetn,  // active low
  
  /* i/o signal that user should set for selecting between AVMM and AXI for HDM access
  */
  input logic emif_avmm_1_axi_0,
  
  /* Memory Controller Status
  */
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][MC_SR_STAT_WIDTH-1:0] mc_sr_status_ipclk,
 
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][mc_ecc_pkg::MC_ERR_CNT_WIDTH-1:0] mc_err_cnt_ipclk,
  
  /* External MC_TOP <--> BBS - write address channels
   */
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        ip2hdm_aximm_awvalid,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_ID_BW-1:0]     ip2hdm_aximm_awid,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_ADDR_BW-1:0]   ip2hdm_aximm_awaddr,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_BLEN_BW-1:0]   ip2hdm_aximm_awlen,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_REGION_BW-1:0] ip2hdm_aximm_awregion,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_USER_BW-1:0]   ip2hdm_aximm_awuser,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]   ip2hdm_aximm_awsize,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]  ip2hdm_aximm_awburst,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]   ip2hdm_aximm_awprot,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]    ip2hdm_aximm_awqos,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]  ip2hdm_aximm_awcache,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]   ip2hdm_aximm_awlock,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        hdm2ip_aximm_awready,   
  /* External MC_TOP <--> BBS - write data channel
   */
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_wvalid,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_DATA_BW-1:0] ip2hdm_aximm_wdata,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_STRB_BW-1:0] ip2hdm_aximm_wstrb,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_wlast,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_USER_BW-1:0] ip2hdm_aximm_wuser,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_wready,		  
  /* External MC_TOP <--> BBS - write response channel
   */
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_bvalid,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_ID_BW-1:0]   hdm2ip_aximm_bid,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_USER_BW-1:0] hdm2ip_aximm_buser,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_bresp,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_bready,  
  /* External MC_TOP <--> BBS - read address channel
   */
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        ip2hdm_aximm_arvalid,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_ID_BW-1:0]     ip2hdm_aximm_arid,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_ADDR_BW-1:0]   ip2hdm_aximm_araddr,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_BLEN_BW-1:0]   ip2hdm_aximm_arlen,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_REGION_BW-1:0] ip2hdm_aximm_arregion,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_USER_BW-1:0]   ip2hdm_aximm_aruser,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]   ip2hdm_aximm_arsize,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]  ip2hdm_aximm_arburst,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]   ip2hdm_aximm_arprot,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]    ip2hdm_aximm_arqos,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]  ip2hdm_aximm_arcache,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]   ip2hdm_aximm_arlock,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        hdm2ip_aximm_arready,  
  /* External MC_TOP <--> BBS - read response channel
   */
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_rvalid,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_rlast,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_ID_BW-1:0]   hdm2ip_aximm_rid,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_DATA_BW-1:0] hdm2ip_aximm_rdata,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_USER_BW-1:0] hdm2ip_aximm_ruser,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_rresp,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_rready,

  /* emif clk in, emif reset in
     emif calibration signals for going to cafu_csr0_cfg space
  */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emifclk,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emifresetn,  // active low
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_pll_locked,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_reset_done,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_cal_success,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_cal_fail,

 
  `ifdef HDM_SIM_CFG_USE_BASIC_MEM
     output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] mem_address_rmw_emifclk,
  `endif
 
  /* AVMM signals from emif
  */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif2hdm_avmm_ready_emifclk,

  /* AVMM signals to emif
  */
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] hdm2emif_avmm_writedata_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_BE_WIDTH-1:0]   hdm2emif_avmm_byteenable_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] hdm2emif_avmm_address_emifclk,

  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2emif_avmm_write_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2emif_avmm_read_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2emif_avmm_write_poison_emifclk,
 
  /* AVMM signals from emif
  */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] emif2hdm_avmm_readdata_emifclk,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif2hdm_avmm_read_poison_emifclk,
 
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif2hdm_avmm_readdatavalid_emifclk,
 
  /* Signals for M-Series: axi4 fabric connection for DDR5/HBMe2
  */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] noc2hdm_aximm_awready_emifclk,
 
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] hdm2noc_aximm_awlen_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_REGION_WIDTH-1:0]           hdm2noc_aximm_awregion_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_AWATOP_WIDTH-1:0]           hdm2noc_aximm_awtop_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]            hdm2noc_aximm_awburst_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]            hdm2noc_aximm_awcache_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]             hdm2noc_aximm_awlock_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]             hdm2noc_aximm_awprot_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]              hdm2noc_aximm_awqos_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]             hdm2noc_aximm_awsize_emifclk,
 
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_AWADDR_BW-1:0] hdm2noc_aximm_awaddr_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_AWID_BW-1:0]   hdm2noc_aximm_awid_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_AWUSER_BW-1:0] hdm2noc_aximm_awuser_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                        hdm2noc_aximm_awvalid_emifclk,

  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] noc2hdm_aximm_wready_emifclk,
 
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_WDATA_BW-1:0]   hdm2noc_aximm_wdata_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                         hdm2noc_aximm_wlast_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_WSTRB_BW-1:0]   hdm2noc_aximm_wstrb_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_WUSER_t_BW-1:0] hdm2noc_aximm_wuser_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                         hdm2noc_aximm_wvalid_emifclk,
  
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] noc2hdm_aximm_arready_emifclk,
  
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] hdm2noc_aximm_arlen_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_REGION_WIDTH-1:0]           hdm2noc_aximm_arregion_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]            hdm2noc_aximm_arburst_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]            hdm2noc_aximm_arcache_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]             hdm2noc_aximm_arlock_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]             hdm2noc_aximm_arprot_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]              hdm2noc_aximm_arqos_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]             hdm2noc_aximm_arsize_emifclk,

  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_ARADDR_BW-1:0] hdm2noc_aximm_araddr_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_ARID_BW-1:0]   hdm2noc_aximm_arid_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_ARUSER_BW-1:0] hdm2noc_aximm_aruser_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                        hdm2noc_aximm_arvalid_emifclk, 
 
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2noc_aximm_bready_emifclk,
 
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] noc2hdm_aximm_bresp_emifclk,
 
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_BID_BW-1:0]   noc2hdm_aximm_bid_emifclk,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_BUSER_BW-1:0] noc2hdm_aximm_buser_emifclk,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                       noc2hdm_aximm_bvalid_emifclk, 
 
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2noc_aximm_rready_emifclk,
 
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] noc2hdm_aximm_rresp_emifclk,
 
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_RDATA_BW-1:0]   noc2hdm_aximm_rdata_emifclk,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_RID_BW-1:0]     noc2hdm_aximm_rid_emifclk,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                         noc2hdm_aximm_rlast_emifclk,  
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_RUSER_t_BW-1:0] noc2hdm_aximm_ruser_emifclk,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                         noc2hdm_aximm_rvalid_emifclk
);

// ================================================================================================
logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_ADDR_WIDTH-1:0] mc_baseaddr_cl;

logic mc_baseaddr_cl_vld;

assign mc_baseaddr_cl     =  '0;
assign mc_baseaddr_cl_vld = 1'b1;

// ================================================================================================
ddr_mc_top_common_pkg::t_reqfifo_data [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] ip2reqfifo_new_req_ipclk;
ddr_mc_top_common_pkg::t_reqfifo_data [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] reqfifo2rmw_new_req_emifclk;

ddr_mc_top_common_pkg::t_reqfifo_data_postRMW_preECC [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rmw2eccreq_new_req_emifclk;

ddr_mc_top_common_pkg::t_reqfifo_data_post_ecc_avmm [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_mceccreq_to_fsm_avmm_new_req_emifclk;
ddr_mc_top_common_pkg::t_reqfifo_data_post_ecc_axi  [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_mceccreq_to_fsm_axi4_new_req_emifclk;

ddr_mc_top_common_pkg::t_bchan_rspfifo_data [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emifmux2rmw_bchan_rsp_struct_emifclk;
ddr_mc_top_common_pkg::t_bchan_rspfifo_data [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] bchan_rspfifo_data_in_intf_emifclk;

ddr_mc_top_common_pkg::t_rchan_rspfifo [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] eccrsp2rmw_rchan_rspfifo_resp_emifclk;
ddr_mc_top_common_pkg::t_rchan_rspfifo [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_rmw_to_rchan_rspfifo_resp_emifclk;
ddr_mc_top_common_pkg::t_rchan_rspfifo [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rchan_rspfifo_dout_resp_ipclk;

ddr_mc_top_common_pkg::t_rchan_rspfifo_data [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rchan_rspfifo_dout_data_intf_ipclk;
ddr_mc_top_common_pkg::t_rchan_rspfifo_ecc  [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rchan_rspfifo_dout_ecc_intf_ipclk;
ddr_mc_top_common_pkg::t_bchan_rspfifo_data [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] bchan_rspfifo_data_out_intf_ipclk;

ddr_mc_top_common_pkg::t_emif_fsm_cntrl_to_ecc [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_fsm_avmm_cntrl_emifclk;
ddr_mc_top_common_pkg::t_emif_fsm_cntrl_to_ecc [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_fsm_axi4_cntrl_emifclk;

hdm_axi_if_pkg::t_hdm_axi_wr_addr_chan_ready [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] to_fsm_axi_awready_emifclk;
hdm_axi_if_pkg::t_hdm_axi_wr_data_chan_ready [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] to_fsm_axi_wready_emifclk;
hdm_axi_if_pkg::t_hdm_axi_wuser              [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_fsm_axi_wuser_emifclk;
hdm_axi_if_pkg::t_hdm_axi_rd_addr_chan_ready [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] to_fsm_axi_arready_emifclk;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] ram_init_addr_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    ram_init_wr_id_emifclk;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_AWADDR_BW-1:0] from_fsm_axi_awaddr_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_AWID_BW-1:0]   from_fsm_axi_awid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_WDATA_BW-1:0]  from_fsm_axi_wdata_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_ARADDR_BW-1:0] from_fsm_axi_araddr_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_ARID_BW-1:0]   from_fsm_axi_arid_emifclk;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0] emif_axi_awburst_muxed;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][REQFIFO_DEPTH_WIDTH-1:0] cdc_reqfifo_fill_level_ipclk;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][RST_REG_NUM-1:0] emifresetn_reg;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] avmm_fsm2rsp_rd_id_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] avmm_fsm2rsp_wr_id_emifclk;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    avmm_wr_rsp_id_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] avmm_rd_rsp_data_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    avmm_rd_rsp_id_emifclk;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][RSPFIFO_RCHAN_DATA_WIDTH-1:0] rchan_rspfifo_data_in_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][RSPFIFO_RCHAN_DATA_WIDTH-1:0] rchan_rspfifo_q_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][RSPFIFO_DEPTH_WIDTH-1:0]      rchan_rspfifo_rdusedw_ipclk;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][RSPFIFO_BCHAN_DATA_WIDTH-1:0] bchan_rspfifo_data_in_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][RSPFIFO_BCHAN_DATA_WIDTH-1:0] bchan_rspfifo_data_out_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][RSPFIFO_DEPTH_WIDTH-1:0]      bchan_rspfifo_rdusedw_ipclk;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] ram_init_done_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_pll_locked_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_reset_done_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_cal_success_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_cal_fail_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] ram_init_done_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] mem_cntrl_ready_post_ram_init_ipclk;  // active high
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] cdc_reqfifo_full_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] cdc_reqfifo_empty_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] ram_init_wr_en_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_rmw_clear_reqfifo_read_valid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_rmw_clear_reqfifo_write_valid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_rmw_memory_ready_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_rmw_reqfifo_ren_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] clocked_reqfifo_rdempty_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] real_reqfifo_rdempty_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] ram_init_done_del1_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] post_mux_bchan_wr_rsp_valid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rchan_rspfifo_wrreq_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] bchan_rspfifo_wrreq_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_mcrmw_reqfifo_empty_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_mcecc_mem_ready_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] avmm_rd_rsp_id_fifo_almost_full_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_mceccreq_to_fsm_axi4_reqfifo_empty_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_fsm_axi_awvalid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_fsm_axi_wvalid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_fsm_axi_wlast_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] from_fsm_axi_arvalid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rchan_rspfifo_rdfull_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] bchan_rspfifo_rdfull_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] avmm_fsm2rsp_valid_wr_id_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] avmm_fsm2rsp_valid_rd_id_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] avmm_wr_rsp_valid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] avmm_rd_rsp_valid_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] toMC_hdm2ip_axi_rready;  // active high - IP ready for read  responses
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rchan_rspfifo_wrfull_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rchan_rspfifo_rdempty_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rchan_rspfifo_rdreq_ipclk; 
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] toMC_hdm2ip_axi_bready;  // active high - IP ready for write responses
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] bchan_rspfifo_wrfull_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] bchan_rspfifo_rdempty_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] bchan_rspfifo_rdreq_ipclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] rmw2raminit_ren_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] raminit_at_final_addr_emifclk;

// ================================================================================================
localparam RCHAN_FIFO_BW_MINUS_INTF_BW = (RSPFIFO_RCHAN_DATA_WIDTH - ddr_mc_top_common_pkg::MC_LOCAL_RHCAN_RSPFIFO_BW);

logic [RCHAN_FIFO_BW_MINUS_INTF_BW-1:0] rchan_zeros;

assign rchan_zeros = '0;

localparam BCHAN_FIFO_BW_MINUS_INTF_BW = RSPFIFO_BCHAN_DATA_WIDTH - ddr_mc_top_common_pkg::MC_LOCAL_BHCAN_RSPFIFO_DATA_BW;

logic [BCHAN_FIFO_BW_MINUS_INTF_BW-1:0] bchan_zeros;

assign bchan_zeros = '0;

// ================================================================================================
genvar genvarChanCount;
generate for( genvarChanCount = 0 ; genvarChanCount < ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL ; genvarChanCount=genvarChanCount+1 )
begin : GENFOR_CHAN_COUNT

  // ============================================================================================== delay on emif reset
  // want to delete any usage of this eventually
  if( RST_REG_NUM == 1 )
  begin : gen_emif_reset_reg_one

    always_ff @( posedge emifclk[genvarChanCount] )
    begin
      emifresetn_reg[genvarChanCount] <= emifresetn[genvarChanCount];
    end
  
  end
  else begin : gen_emif_reset_reg_more_than_one

    always_ff @( posedge emifclk[genvarChanCount] )
    begin
      emifresetn_reg[genvarChanCount] <= {emifresetn_reg[genvarChanCount][RST_REG_NUM-2:0], emifresetn[genvarChanCount]};
    end

  end

  // ================================================================================================ synchronizers
  altera_std_synchronizer_nocut
  #(
    .depth(3)
   )
  synchronizer_nocut_emif_cal_fail
  (
     .clk     ( ipclk ),
     .reset_n ( 1'b1 ),
     .din     ( emif_cal_fail[genvarChanCount] ),
     .dout    ( emif_cal_fail_ipclk[genvarChanCount] )
  );
  
  altera_std_synchronizer_nocut
  #(
    .depth(3)
   )
  synchronizer_nocut_emif_cal_success
  (
     .clk     ( ipclk ),
     .reset_n ( 1'b1 ),
     .din     ( emif_cal_success[genvarChanCount] ),
     .dout    ( emif_cal_success_ipclk[genvarChanCount] )
  );
  
  altera_std_synchronizer_nocut
  #(
    .depth(3)
   )
  synchronizer_nocut_emif_reset_done
  (
     .clk     ( ipclk ),
     .reset_n ( 1'b1 ),
     .din     ( emif_reset_done[genvarChanCount] ),
     .dout    ( emif_reset_done_ipclk[genvarChanCount] )
  );
  
  altera_std_synchronizer_nocut
  #(
    .depth(3)
   )
  synchronizer_nocut_emif_pll_locked
  (
     .clk     ( ipclk ),
     .reset_n ( 1'b1 ),
     .din     ( emif_pll_locked[genvarChanCount] ),
     .dout    ( emif_pll_locked_ipclk[genvarChanCount] )
  );

  altera_std_synchronizer_nocut
  #(
    .depth(3)
   )
  synchronizer_nocut_ram_init_ipclk
  (
     .clk     ( ipclk ),
     .reset_n ( 1'b1 ),
     .din     ( ram_init_done_emifclk[genvarChanCount] ),
     .dout    ( ram_init_done_ipclk[genvarChanCount] )
  );

  always_ff @( posedge ipclk )
  begin 
    mc_sr_status_ipclk[genvarChanCount][MC_SR_STAT_EMIF_CAL_FAIL]    <=    emif_cal_fail_ipclk[genvarChanCount];
    mc_sr_status_ipclk[genvarChanCount][MC_SR_STAT_EMIF_CAL_SUCCESS] <= emif_cal_success_ipclk[genvarChanCount];
    mc_sr_status_ipclk[genvarChanCount][MC_SR_STAT_EMIF_RESET_DONE]  <=  emif_reset_done_ipclk[genvarChanCount];
    mc_sr_status_ipclk[genvarChanCount][MC_SR_STAT_EMIF_PLL_LOCKED]  <=  emif_pll_locked_ipclk[genvarChanCount];
    mc_sr_status_ipclk[genvarChanCount][MC_SR_STAT_RAM_INIT_DONE]    <=    ram_init_done_ipclk[genvarChanCount];
  end
  
  // ================================================================================================ requests from CXLIP
  mc_single_chan_ip2hdm_axi_req_chans
  #(
    .REQFIFO_DEPTH_WIDTH ( REQFIFO_DEPTH_WIDTH )
   )
  inst_ip2hdm_axi_req_chans
  (
    .ipclk ( ipclk ),
    .ipresetn ( ipresetn ),
 
    .i_mem_cntrl_ready_post_ram_init_ipclk ( mem_cntrl_ready_post_ram_init_ipclk[genvarChanCount] ),

    .i_cdc_reqfifo_full_ipclk       (      cdc_reqfifo_full_ipclk[genvarChanCount]  ),
    .i_cdc_reqfifo_empty_ipclk      (      cdc_reqfifo_empty_ipclk[genvarChanCount] ),
    .i_cdc_reqfifo_fill_level_ipclk ( cdc_reqfifo_fill_level_ipclk[genvarChanCount] ),
 
    .o_ip2reqfifo_new_req_ipclk ( ip2reqfifo_new_req_ipclk[genvarChanCount] ),

    /* External MC_TOP <--> BBS - write address channels
     */
    .ip2hdm_aximm_awvalid  ( ip2hdm_aximm_awvalid[genvarChanCount]  ),
    .ip2hdm_aximm_awid     ( ip2hdm_aximm_awid[genvarChanCount]     ),
    .ip2hdm_aximm_awaddr   ( ip2hdm_aximm_awaddr[genvarChanCount]   ),
    .ip2hdm_aximm_awlen    ( ip2hdm_aximm_awlen[genvarChanCount]    ),
    .ip2hdm_aximm_awregion ( ip2hdm_aximm_awregion[genvarChanCount] ),
    .ip2hdm_aximm_awuser   ( ip2hdm_aximm_awuser[genvarChanCount]   ),
    .ip2hdm_aximm_awsize   ( ip2hdm_aximm_awsize[genvarChanCount]   ),
    .ip2hdm_aximm_awburst  ( ip2hdm_aximm_awburst[genvarChanCount]  ),
    .ip2hdm_aximm_awprot   ( ip2hdm_aximm_awprot[genvarChanCount]   ),
    .ip2hdm_aximm_awqos    ( ip2hdm_aximm_awqos[genvarChanCount]    ),
    .ip2hdm_aximm_awcache  ( ip2hdm_aximm_awcache[genvarChanCount]  ),
    .ip2hdm_aximm_awlock   ( ip2hdm_aximm_awlock[genvarChanCount]   ),
    .hdm2ip_aximm_awready  ( hdm2ip_aximm_awready[genvarChanCount]  ),
    /* External MC_TOP <--> BBS - write data channel
     */
    .ip2hdm_aximm_wvalid ( ip2hdm_aximm_wvalid[genvarChanCount] ),
    .ip2hdm_aximm_wdata  ( ip2hdm_aximm_wdata[genvarChanCount]  ),
    .ip2hdm_aximm_wstrb  ( ip2hdm_aximm_wstrb[genvarChanCount]  ),
    .ip2hdm_aximm_wlast  ( ip2hdm_aximm_wlast[genvarChanCount]  ),
   .ip2hdm_aximm_wuser  ( ip2hdm_aximm_wuser[genvarChanCount]  ),
    . hdm2ip_aximm_wready ( hdm2ip_aximm_wready[genvarChanCount] ),
    /* External MC_TOP <--> BBS - read address channel
     */
    .ip2hdm_aximm_arvalid  ( ip2hdm_aximm_arvalid[genvarChanCount]  ),
    .ip2hdm_aximm_arid     ( ip2hdm_aximm_arid[genvarChanCount]     ),
    .ip2hdm_aximm_araddr   ( ip2hdm_aximm_araddr[genvarChanCount]   ),
    .ip2hdm_aximm_arlen    ( ip2hdm_aximm_arlen[genvarChanCount]    ),
    .ip2hdm_aximm_arregion ( ip2hdm_aximm_arregion[genvarChanCount] ),
    .ip2hdm_aximm_aruser   ( ip2hdm_aximm_aruser[genvarChanCount]   ),
    .ip2hdm_aximm_arsize   ( ip2hdm_aximm_arsize[genvarChanCount]   ),
    .ip2hdm_aximm_arburst  ( ip2hdm_aximm_arburst[genvarChanCount]  ),
    .ip2hdm_aximm_arprot   ( ip2hdm_aximm_arprot[genvarChanCount]   ),
    .ip2hdm_aximm_arqos    ( ip2hdm_aximm_arqos[genvarChanCount]    ),
    .ip2hdm_aximm_arcache  ( ip2hdm_aximm_arcache[genvarChanCount]  ),
    .ip2hdm_aximm_arlock   ( ip2hdm_aximm_arlock[genvarChanCount]   ),
    .hdm2ip_aximm_arready  ( hdm2ip_aximm_arready[genvarChanCount]  )
  );

  // ================================================================================================ cdc reqfifo
  /* requests into and out of the cdc_reqfifo
     crossing from the ipclk domain to the emifclk domain
  */
/*
  mc_single_chan_cdc_reqfifo
  #(
    .REG_ON_REQFIFO_OUTPUT_EN ( ddr_mc_top_common_pkg::MCTOP_REG_ON_REQFIFO_OUTPUT_EN ),
    .REG_ON_REQFIFO_INPUT_EN  ( ddr_mc_top_common_pkg::MCTOP_REG_ON_REQFIFO_INPUT_EN  ),
    .MC_RAM_INIT_W_ZERO_EN    ( ddr_mc_top_common_pkg::MCTOP_MC_RAM_INIT_W_ZERO_EN    ),
    .REQFIFO_DEPTH_WIDTH      ( REQFIFO_DEPTH_WIDTH ),
    .REQFIFO_DATA_WIDTH       ( REQFIFO_DATA_WIDTH  )
   )
  inst_cdc_reqfifo
  (
    .ipclk ( ipclk ),
    .ipresetn ( ipresetn ),
 
    .i_mc_baseaddr_cl_valid ( mc_baseaddr_cl_vld ),
    .i_mc_baseaddr_cl       ( mc_baseaddr_cl     ),
 
    .i_ram_init_done_ipclk      (      ram_init_done_ipclk[genvarChanCount] ),
    .i_ip2reqfifo_new_req_ipclk ( ip2reqfifo_new_req_ipclk[genvarChanCount] ),

    .o_mem_cntrl_ready_post_ram_init_ipclk ( mem_cntrl_ready_post_ram_init_ipclk[genvarChanCount] ),
 
    .o_cdc_reqfifo_full_ipclk       (       cdc_reqfifo_full_ipclk[genvarChanCount] ),  
    .o_cdc_reqfifo_empty_ipclk      (      cdc_reqfifo_empty_ipclk[genvarChanCount] ),
    .o_cdc_reqfifo_fill_level_ipclk ( cdc_reqfifo_fill_level_ipclk[genvarChanCount] ),

    .emifclk    (    emifclk[genvarChanCount] ),
    .emifresetn ( emifresetn[genvarChanCount] ),
 
    .i_ram_init_wr_en_emifclk ( ram_init_wr_en_emifclk[genvarChanCount] ),
    .i_ram_init_wr_id_emifclk ( ram_init_wr_id_emifclk[genvarChanCount] ),
    .i_ram_init_done_emifclk  (  ram_init_done_emifclk[genvarChanCount] ),
    .i_ram_init_addr_emifclk  (  ram_init_addr_emifclk[genvarChanCount] ),
   
    .i_from_rmw_clear_reqfifo_write_valid_emifclk ( from_rmw_clear_reqfifo_write_valid_emifclk[genvarChanCount] ),
    .i_from_rmw_clear_reqfifo_read_valid_emifclk  (  from_rmw_clear_reqfifo_read_valid_emifclk[genvarChanCount] ),
 
    .i_from_rmw_memory_ready_emifclk ( from_rmw_memory_ready_emifclk[genvarChanCount] ),
   
    .i_rmw2reqfifo_ren_emifclk ( from_rmw_reqfifo_ren_emifclk[genvarChanCount] ),
   
    .o_reqfifo2rmw_new_req_emifclk     (     reqfifo2rmw_new_req_emifclk[genvarChanCount] ),
    .o_clocked_reqfifo_rdempty_emifclk ( clocked_reqfifo_rdempty_emifclk[genvarChanCount] ),
    .o_real_reqfifo_rdempty_emifclk    (    real_reqfifo_rdempty_emifclk[genvarChanCount] )
  );
*/
  mc_single_chan_cdc_reqfifo_ver2
  #(
    .REG_ON_REQFIFO_OUTPUT_EN ( ddr_mc_top_common_pkg::MCTOP_REG_ON_REQFIFO_OUTPUT_EN ),
    .REG_ON_REQFIFO_INPUT_EN  ( ddr_mc_top_common_pkg::MCTOP_REG_ON_REQFIFO_INPUT_EN  ),
    .MC_RAM_INIT_W_ZERO_EN    ( ddr_mc_top_common_pkg::MCTOP_MC_RAM_INIT_W_ZERO_EN    ),
    .REQFIFO_DEPTH_WIDTH      ( REQFIFO_DEPTH_WIDTH ),
    .REQFIFO_DATA_WIDTH       ( REQFIFO_DATA_WIDTH  )
   )
  inst_cdc_reqfifo
  (
    .ipclk ( ipclk ),
    .ipresetn ( ipresetn ),

    .i_mc_baseaddr_cl_valid ( mc_baseaddr_cl_vld ),
    .i_mc_baseaddr_cl       ( mc_baseaddr_cl     ),

    .i_ram_init_done_ipclk      (      ram_init_done_ipclk[genvarChanCount] ),
    .i_ip2reqfifo_new_req_ipclk ( ip2reqfifo_new_req_ipclk[genvarChanCount] ),

    .o_mem_cntrl_ready_post_ram_init_ipclk ( mem_cntrl_ready_post_ram_init_ipclk[genvarChanCount] ),

    .o_cdc_reqfifo_full_ipclk       (       cdc_reqfifo_full_ipclk[genvarChanCount] ),
    .o_cdc_reqfifo_empty_ipclk      (      cdc_reqfifo_empty_ipclk[genvarChanCount] ),
    .o_cdc_reqfifo_fill_level_ipclk ( cdc_reqfifo_fill_level_ipclk[genvarChanCount] ),

    .emifclk    (    emifclk[genvarChanCount] ),
    .emifresetn ( emifresetn[genvarChanCount] ),

    .i_ram_init_wr_en_emifclk  (  ram_init_wr_en_emifclk[genvarChanCount] ),
    .i_ram_init_wr_id_emifclk  (  ram_init_wr_id_emifclk[genvarChanCount] ),
    .i_ram_init_done_emifclk   (   ram_init_done_emifclk[genvarChanCount] ),
    .i_ram_init_addr_emifclk   (   ram_init_addr_emifclk[genvarChanCount] ),
    .i_rmw2raminit_ren_emifclk ( rmw2raminit_ren_emifclk[genvarChanCount] ),

    .i_from_rmw_clear_reqfifo_write_valid_emifclk ( from_rmw_clear_reqfifo_write_valid_emifclk[genvarChanCount] ),
    .i_from_rmw_clear_reqfifo_read_valid_emifclk  (  from_rmw_clear_reqfifo_read_valid_emifclk[genvarChanCount] ),

    .i_from_rmw_memory_ready_emifclk ( from_rmw_memory_ready_emifclk[genvarChanCount] ),

    .i_rmw2reqfifo_ren_emifclk ( from_rmw_reqfifo_ren_emifclk[genvarChanCount] ),

    .o_reqfifo2rmw_new_req_emifclk     (     reqfifo2rmw_new_req_emifclk[genvarChanCount] ),
    .o_clocked_reqfifo_rdempty_emifclk ( clocked_reqfifo_rdempty_emifclk[genvarChanCount] ),
    .o_real_reqfifo_rdempty_emifclk    (    real_reqfifo_rdempty_emifclk[genvarChanCount] )
  );
  

  // ================================================================================================ ram initialization block
/*
  mc_single_chan_ram_init
  #(
    .USE_ORIGINAL_RAM_INIT ( 0 ),  // 0 - OFF; 1 - ON
    .MC_RAM_INIT_W_ZERO_EN ( ddr_mc_top_common_pkg::MCTOP_MC_RAM_INIT_W_ZERO_EN ),  // 0 - OFF; 1 - ON
    .RST_REG_NUM           ( RST_REG_NUM )
   )
  inst_mc_ram_init
  (
    .emifclk        (        emifclk[genvarChanCount] ),
    .emifresetn     (     emifresetn[genvarChanCount] ),
    .emifresetn_reg ( emifresetn_reg[genvarChanCount][RST_REG_NUM-1] ),  // only send in MSB
   
    .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),

    .from_rmw_memory_ready_emifclk      (       from_rmw_memory_ready_emifclk[genvarChanCount] ),
    .from_emif_write_resp_valid_emifclk ( post_mux_bchan_wr_rsp_valid_emifclk[genvarChanCount] ),

    .ram_init_addr_emifclk      (      ram_init_addr_emifclk[genvarChanCount] ),
    .ram_init_wr_id_emifclk     (     ram_init_wr_id_emifclk[genvarChanCount] ),
    .ram_init_done_emifclk      (      ram_init_done_emifclk[genvarChanCount] ),
    .ram_init_done_del1_emifclk ( ram_init_done_del1_emifclk[genvarChanCount] ),
    .ram_init_wr_en_emifclk     (     ram_init_wr_en_emifclk[genvarChanCount] )
  );
*/
  mc_single_chan_ram_init_ver2
  #(
    .USE_ORIGINAL_RAM_INIT ( 0 ),  // 0 - OFF; 1 - ON
    .MC_RAM_INIT_W_ZERO_EN ( ddr_mc_top_common_pkg::MCTOP_MC_RAM_INIT_W_ZERO_EN ),  // 0 - OFF; 1 - ON
    .RST_REG_NUM           ( RST_REG_NUM )
   )
  inst_mc_ram_init
  (
    .emifclk        (        emifclk[genvarChanCount] ),
    .emifresetn     (     emifresetn[genvarChanCount] ),
    .emifresetn_reg ( emifresetn_reg[genvarChanCount] ),  // only send in MSB

    .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),

    .from_rmw_ren_emifclk               (             rmw2raminit_ren_emifclk[genvarChanCount] ),
    .from_rmw_memory_ready_emifclk      (       from_rmw_memory_ready_emifclk[genvarChanCount] ),
    .from_emif_write_resp_valid_emifclk ( post_mux_bchan_wr_rsp_valid_emifclk[genvarChanCount] ),

    .ram_init_addr_emifclk      (      ram_init_addr_emifclk[genvarChanCount] ),
    .ram_init_wr_id_emifclk     (     ram_init_wr_id_emifclk[genvarChanCount] ),
    .ram_init_done_emifclk      (      ram_init_done_emifclk[genvarChanCount] ),
    .ram_init_done_del1_emifclk ( ram_init_done_del1_emifclk[genvarChanCount] ),
    .ram_init_wr_en_emifclk     (     ram_init_wr_en_emifclk[genvarChanCount] ),
   
    .ram_init_addr_equals_final_addr_emifclk ( raminit_at_final_addr_emifclk[genvarChanCount] )
  );

  // ================================================================================================ rmw shim
  /* read-modified-write (rmw) block
  */
/*
   mc_single_chan_rmw_block
   #(
     .REQFIFO_DEPTH_WIDTH ( REQFIFO_DEPTH_WIDTH ),
     .REG_ON_BCHAN_WEN_TO_RSPFIFO ( 0 ),
     .REG_ON_BCHAN_STRUCT_TO_RSPFIFO ( 0 ),
     .REG_ON_RMW_RD_DATA_INPUT_EN ( 1 )
    )
   inst_rmw_block
   (
     .emifclk        (        emifclk[genvarChanCount] ),
     .emifresetn     (     emifresetn[genvarChanCount] ),
     .emifresetn_reg ( emifresetn_reg[genvarChanCount] ),

     .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),
	
	   .from_rmw_memory_ready_emifclk ( from_rmw_memory_ready_emifclk[genvarChanCount] ),
     .from_ram_init_done_del1_emifclk ( ram_init_done_del1_emifclk[genvarChanCount] ),
     .from_rmw_clear_reqfifo_read_valid_emifclk ( from_rmw_clear_reqfifo_read_valid_emifclk[genvarChanCount] ),
     .from_rmw_clear_reqfifo_write_valid_emifclk ( from_rmw_clear_reqfifo_write_valid_emifclk[genvarChanCount] ),
	   .from_axi_rd_id_fifo_almost_full ( avmm_rd_rsp_id_fifo_almost_full_emifclk[genvarChanCount] ),
     .from_rmw_rmw_pending_emifclk ( ),

     // to/from cdc_reqfifo
     .from_reqfifo_new_req_emifclk (             reqfifo2rmw_new_req_emifclk[genvarChanCount] ),
     .from_reqfifo_real_empty_emifclk (         real_reqfifo_rdempty_emifclk[genvarChanCount] ),
     .from_reqfifo_empty_emifclk (           clocked_reqfifo_rdempty_emifclk[genvarChanCount] ),
     .from_rmw_to_reqfifo_read_enable_emifclk ( from_rmw_reqfifo_ren_emifclk[genvarChanCount] ),
  
     // to/from mc_ecc (then to emif)
	   .to_mcecc_reqfifo_empty_emifclk  ( from_mcrmw_reqfifo_empty_emifclk[genvarChanCount] ),
     .to_mcecc_new_req_emifclk        (       rmw2eccreq_new_req_emifclk[genvarChanCount] ),
     .from_mcecc_memory_ready_emifclk (     from_mcecc_mem_ready_emifclk[genvarChanCount] ),
	 
	   .from_mcecc_rd_resp_emifclk ( eccrsp2rmw_rchan_rspfifo_resp_emifclk[genvarChanCount].read_rsp_intf ),
	   .from_mcecc_rd_ecc_emifclk  ( eccrsp2rmw_rchan_rspfifo_resp_emifclk[genvarChanCount].read_ecc_intf ),

     // write response structs from emif selection logic
     .from_emif_wr_resp_emifclk ( emifmux2rmw_bchan_rsp_struct_emifclk[genvarChanCount] ),

     // to clock domain crossing (cdc) response fifos
     .to_rspfifo_wr_resp_emifclk ( bchan_rspfifo_data_in_intf_emifclk[genvarChanCount] ),
	
     .to_rspfifo_rd_resp_emifclk ( from_rmw_to_rchan_rspfifo_resp_emifclk[genvarChanCount].read_rsp_intf ),
     .to_rspfifo_rd_ecc_emifclk  ( from_rmw_to_rchan_rspfifo_resp_emifclk[genvarChanCount].read_ecc_intf ),
 
     .to_rspfifo_bchan_wen_emifclk ( bchan_rspfifo_wrreq_emifclk[genvarChanCount] ),
     .to_rspfifo_rchan_wen_emifclk ( rchan_rspfifo_wrreq_emifclk[genvarChanCount] )
   );
*/
   mc_single_chan_rmw_block_ver2
   #(
     .REQFIFO_DEPTH_WIDTH ( REQFIFO_DEPTH_WIDTH ),
     .REG_ON_BCHAN_WEN_TO_RSPFIFO ( 0 ),
     .REG_ON_BCHAN_STRUCT_TO_RSPFIFO ( 0 ),
     .REG_ON_RMW_RD_DATA_INPUT_EN ( 1 )
    )
   inst_rmw_block
   (
     .emifclk        (        emifclk[genvarChanCount] ),
     .emifresetn     (     emifresetn[genvarChanCount] ),
     .emifresetn_reg ( emifresetn_reg[genvarChanCount][RST_REG_NUM-1] ),

     .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),

     .from_rmw_memory_ready_emifclk ( from_rmw_memory_ready_emifclk[genvarChanCount] ),
     .from_rmw_clear_reqfifo_read_valid_emifclk ( from_rmw_clear_reqfifo_read_valid_emifclk[genvarChanCount] ),
     .from_rmw_clear_reqfifo_write_valid_emifclk ( from_rmw_clear_reqfifo_write_valid_emifclk[genvarChanCount] ),
     .from_axi_rd_id_fifo_almost_full ( avmm_rd_rsp_id_fifo_almost_full_emifclk[genvarChanCount] ),
     .from_rmw_rmw_pending_emifclk ( ),

     /* to/from ram_init
     */
     .from_ram_init_done_emifclk        (      ram_init_done_emifclk[genvarChanCount] ),
     .from_ram_init_done_del1_emifclk   ( ram_init_done_del1_emifclk[genvarChanCount] ),
     .from_ram_init_valid_write_emifclk (     ram_init_wr_en_emifclk[genvarChanCount] ),
     .to_ram_init_read_enable_emifclk   (    rmw2raminit_ren_emifclk[genvarChanCount] ),
     .to_ram_init_set_write_low_emifclk (),

     .from_ram_init_addr_equals_final_addr_emifclk ( raminit_at_final_addr_emifclk[genvarChanCount] ),

     /* to/from cdc_reqfifo
     */
     .from_reqfifo_new_req_emifclk (             reqfifo2rmw_new_req_emifclk[genvarChanCount] ),
     .from_reqfifo_real_empty_emifclk (         real_reqfifo_rdempty_emifclk[genvarChanCount] ),
     .from_reqfifo_empty_emifclk (           clocked_reqfifo_rdempty_emifclk[genvarChanCount] ),
     .from_rmw_to_reqfifo_read_enable_emifclk ( from_rmw_reqfifo_ren_emifclk[genvarChanCount] ),

     /* to/from mc_ecc (then to emif)
     */
     .to_mcecc_reqfifo_empty_emifclk  ( from_mcrmw_reqfifo_empty_emifclk[genvarChanCount] ),
     .to_mcecc_new_req_emifclk        (       rmw2eccreq_new_req_emifclk[genvarChanCount] ),
     .from_mcecc_memory_ready_emifclk (     from_mcecc_mem_ready_emifclk[genvarChanCount] ),

     .from_mcecc_rd_resp_emifclk ( eccrsp2rmw_rchan_rspfifo_resp_emifclk[genvarChanCount].read_rsp_intf ),
     .from_mcecc_rd_ecc_emifclk  ( eccrsp2rmw_rchan_rspfifo_resp_emifclk[genvarChanCount].read_ecc_intf ),

     /* write response structs from emif selection logic
     */
     .from_emif_wr_resp_emifclk ( emifmux2rmw_bchan_rsp_struct_emifclk[genvarChanCount] ),

     /* to clock domain crossing (cdc) response fifos
     */
     .to_rspfifo_wr_resp_emifclk ( bchan_rspfifo_data_in_intf_emifclk[genvarChanCount] ),

     .to_rspfifo_rd_resp_emifclk ( from_rmw_to_rchan_rspfifo_resp_emifclk[genvarChanCount].read_rsp_intf ),
     .to_rspfifo_rd_ecc_emifclk  ( from_rmw_to_rchan_rspfifo_resp_emifclk[genvarChanCount].read_ecc_intf ),

     .to_rspfifo_bchan_wen_emifclk ( bchan_rspfifo_wrreq_emifclk[genvarChanCount] ),
     .to_rspfifo_rchan_wen_emifclk ( rchan_rspfifo_wrreq_emifclk[genvarChanCount] )
   );

  // ================================================================================================ ECC Requests
  /* detect errors in the writedata and encode for storing in emif-avmm mode
     stores to wuser for emif-axi mode
  */
  mc_single_chan_ecc_req
  #(
      .ALTECC_DATAWORD_WIDTH ( ddr_mc_top_common_pkg::MCTOP_ALTECC_DATAWORD_WIDTH ),
      .ALTECC_CODEWORD_WIDTH ( ddr_mc_top_common_pkg::MCTOP_ALTECC_WIDTH_CODEWORD ),
      .ALTECC_INST_NUMBER    ( ddr_mc_top_common_pkg::MCTOP_ALTECC_INST_NUMBER ),
      .MC_ECC_ENC_LATENCY    ( ddr_mc_top_common_pkg::MCTOP_MC_ECC_ENC_LATENCY ),
      .MC_ECC_DEC_LATENCY    ( ddr_mc_top_common_pkg::MCTOP_MC_ECC_DEC_LATENCY )
   )
  inst_mc_ecc_req_block
  (
     .emifclk           (        emifclk[genvarChanCount] ),
     .emifresetn        (     emifresetn[genvarChanCount] ),
     .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),
  
     /* signals to/from mc_rmw_block
     */
     .from_mcrmw_reqfifo_empty_emifclk ( from_mcrmw_reqfifo_empty_emifclk[genvarChanCount] ),
     .from_mcrmw_new_req_emifclk       (       rmw2eccreq_new_req_emifclk[genvarChanCount] ),
     .to_mcrmw_mem_ready_emifclk       (     from_mcecc_mem_ready_emifclk[genvarChanCount] ),

     /* signals to/from emif-avmm-FSM
     */
     .from_fsm_avmm_cntrl_emifclk (               from_fsm_avmm_cntrl_emifclk[genvarChanCount] ),
     .to_fsm_avmm_new_req_emifclk ( from_mceccreq_to_fsm_avmm_new_req_emifclk[genvarChanCount] ),
 
     /* signals to/from emif-aaxi4-FSM
     */
     .to_fsm_axi4_reqfifo_empty_emifclk ( from_mceccreq_to_fsm_axi4_reqfifo_empty_emifclk[genvarChanCount] ),
     .from_fsm_axi4_cntrl_emifclk       (                     from_fsm_axi4_cntrl_emifclk[genvarChanCount] ),
     .to_fsm_axi4_new_req_emifclk       (       from_mceccreq_to_fsm_axi4_new_req_emifclk[genvarChanCount] )
  );
  
  // ================================================================================================ emif-axi fsm
  /* Handle the signals to/from the emif-axi (HDM AXI) that go-to / come-from the NoC Initiators / 
     fabric connectors.  Control is handled through a FSM.
  */
  mc_single_chan_hdm_axi_fsm     inst_hdm_axi_fsm
  (
     .emifclk    (    emifclk[genvarChanCount] ),
     .emifresetn ( emifresetn[genvarChanCount] ),
   
     .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),
 
     /* signals to/from mc_ecc_req
     */
	 .from_mceccreq_reqfifo_empty_emifclk ( from_mceccreq_to_fsm_axi4_reqfifo_empty_emifclk[genvarChanCount] ),
	 .from_mceccreq_new_req_emifclk       (       from_mceccreq_to_fsm_axi4_new_req_emifclk[genvarChanCount] ),
	 .from_mceccreq_cntrl_emifclk         (                     from_fsm_axi4_cntrl_emifclk[genvarChanCount] ),
 
     /* signals to/from hdm-axi out to NoC initators / fabric connectors
     */
     .awaddr  (  from_fsm_axi_awaddr_emifclk[genvarChanCount] ),
     .awid    (    from_fsm_axi_awid_emifclk[genvarChanCount] ),
     .awvalid ( from_fsm_axi_awvalid_emifclk[genvarChanCount] ),
     .awready ( to_fsm_axi_awready_emifclk[genvarChanCount] ),
   
     .wdata  (  from_fsm_axi_wdata_emifclk[genvarChanCount] ),
     .wlast  (  from_fsm_axi_wlast_emifclk[genvarChanCount] ),
     .wvalid ( from_fsm_axi_wvalid_emifclk[genvarChanCount] ),
     .wuser  (  from_fsm_axi_wuser_emifclk[genvarChanCount] ),
     .wready (   to_fsm_axi_wready_emifclk[genvarChanCount] ),
   
     .araddr  (  from_fsm_axi_araddr_emifclk[genvarChanCount] ),
     .arid    (    from_fsm_axi_arid_emifclk[genvarChanCount] ),
     .arvalid ( from_fsm_axi_arvalid_emifclk[genvarChanCount] ),
     .arready (   to_fsm_axi_arready_emifclk[genvarChanCount] )
  );

  always_comb
  begin
    //        Remove static AWID check during initialization.  The UVM_ERR was: 
    //        "axi_nonallocating_random_test.m_top_uvm_env.m_axi_slu_env.env.axi_system_env.slave[11].monitor [register_fail:AMBA:AXI_ACE:no_outstanding_write_transaction_with_same_awid] .....
    //        Description: Monitor checks that master must not drive same AWID transaction when there is a write request or ongoing write outstanding transaction with ......
    //        same AWID - single write outstanding transaction with same AWID-'h0."
    emif_axi_awburst_muxed[genvarChanCount] = ram_init_done_emifclk[genvarChanCount] ? 2'b00 : 2'b01;

    to_fsm_axi_awready_emifclk[genvarChanCount] = noc2hdm_aximm_awready_emifclk[genvarChanCount];
     to_fsm_axi_wready_emifclk[genvarChanCount] =  noc2hdm_aximm_wready_emifclk[genvarChanCount];
    to_fsm_axi_arready_emifclk[genvarChanCount] = noc2hdm_aximm_arready_emifclk[genvarChanCount];  
  
       hdm2noc_aximm_awlen_emifclk[genvarChanCount] = '0;
    hdm2noc_aximm_awregion_emifclk[genvarChanCount] = '0;
       hdm2noc_aximm_awtop_emifclk[genvarChanCount] = '0;
     hdm2noc_aximm_awburst_emifclk[genvarChanCount] = emif_axi_awburst_muxed[genvarChanCount];
     hdm2noc_aximm_awcache_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::ecache_aw_MCTOP_DEVICE_NON_BUFFERABLE;
      hdm2noc_aximm_awlock_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::elock_MCTOP_NORMAL;
      hdm2noc_aximm_awprot_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::eprot_MCTOP_UNPRIV_SECURE_DATA;
       hdm2noc_aximm_awqos_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::eqos_MCTOP_BEST_EFFORT;
      hdm2noc_aximm_awsize_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::esize_MCTOP_512;
      hdm2noc_aximm_awaddr_emifclk[genvarChanCount] = from_fsm_axi_awaddr_emifclk[genvarChanCount];
        hdm2noc_aximm_awid_emifclk[genvarChanCount] = from_fsm_axi_awid_emifclk[genvarChanCount];
      hdm2noc_aximm_awuser_emifclk[genvarChanCount] = '0;
     hdm2noc_aximm_awvalid_emifclk[genvarChanCount] = from_fsm_axi_awvalid_emifclk[genvarChanCount];

     hdm2noc_aximm_wdata_emifclk[genvarChanCount] = from_fsm_axi_wdata_emifclk[genvarChanCount];
     hdm2noc_aximm_wlast_emifclk[genvarChanCount] = from_fsm_axi_wlast_emifclk[genvarChanCount];
     hdm2noc_aximm_wstrb_emifclk[genvarChanCount] = '1; //Byte enable handled in RMW block
     hdm2noc_aximm_wuser_emifclk[genvarChanCount] = from_fsm_axi_wuser_emifclk[genvarChanCount];
    hdm2noc_aximm_wvalid_emifclk[genvarChanCount] = from_fsm_axi_wvalid_emifclk[genvarChanCount];

       hdm2noc_aximm_arlen_emifclk[genvarChanCount] = '0;
    hdm2noc_aximm_arregion_emifclk[genvarChanCount] = '0;
     hdm2noc_aximm_arburst_emifclk[genvarChanCount] = emif_axi_awburst_muxed[genvarChanCount];
     hdm2noc_aximm_arcache_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::ecache_ar_MCTOP_DEVICE_NON_BUFFERABLE;
      hdm2noc_aximm_arlock_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::elock_MCTOP_NORMAL;
      hdm2noc_aximm_arprot_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::eprot_MCTOP_UNPRIV_SECURE_DATA;
       hdm2noc_aximm_arqos_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::eqos_MCTOP_BEST_EFFORT;
      hdm2noc_aximm_arsize_emifclk[genvarChanCount] = ddr_mc_top_common_pkg::esize_MCTOP_512;
      hdm2noc_aximm_araddr_emifclk[genvarChanCount] = from_fsm_axi_araddr_emifclk[genvarChanCount];
        hdm2noc_aximm_arid_emifclk[genvarChanCount] = from_fsm_axi_arid_emifclk[genvarChanCount];
      hdm2noc_aximm_aruser_emifclk[genvarChanCount] = '0;
     hdm2noc_aximm_arvalid_emifclk[genvarChanCount] = from_fsm_axi_arvalid_emifclk[genvarChanCount];
  end

  // ================================================================================================ emif-avmm fsm                
  /* Handle the signals to/from the emif-avmm. Control is handled through a FSM.
  */
  mc_single_chan_avmm_fsm    inst_avmm_fsm
  (
     .emifclk    (    emifclk[genvarChanCount] ),
     .emifresetn ( emifresetn[genvarChanCount] ),
   
     .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),

     /* signals to/from mc_ecc_req
     */
     .from_mceccreq_new_req_emifclk ( from_mceccreq_to_fsm_avmm_new_req_emifclk[genvarChanCount] ),
     .to_mceccreq_cntrl_emifclk     (               from_fsm_avmm_cntrl_emifclk[genvarChanCount] ),

     /* AVMM signals from emif
     */
	 .from_emif_avmm_mem_ready_emifclk ( emif2hdm_avmm_ready_emifclk[genvarChanCount] ),

     /* AVMM signals to emif
     */
     .to_emif_avmm_writedata_emifclk  (  hdm2emif_avmm_writedata_emifclk[genvarChanCount] ),
     .to_emif_avmm_byteenable_emifclk ( hdm2emif_avmm_byteenable_emifclk[genvarChanCount] ),
     .to_emif_avmm_address_emifclk    (    hdm2emif_avmm_address_emifclk[genvarChanCount] ),
     .to_emif_avmm_write_emifclk      (      hdm2emif_avmm_write_emifclk[genvarChanCount] ),
     .to_emif_avmm_read_emifclk       (       hdm2emif_avmm_read_emifclk[genvarChanCount] ),
     .to_emif_avmm_write_poison_emifclk ( hdm2emif_avmm_write_poison_emifclk[genvarChanCount] ),
 
     /* signals to AVMM response handler
     */
     .to_avmm_rsp_valid_wr_id_emifclk ( avmm_fsm2rsp_valid_wr_id_emifclk[genvarChanCount] ), 
     .to_avmm_rsp_wr_id_emifclk       (       avmm_fsm2rsp_wr_id_emifclk[genvarChanCount] ),	 
	 
     .to_avmm_rsp_valid_rd_id_emifclk ( avmm_fsm2rsp_valid_rd_id_emifclk[genvarChanCount] ),	 
     .to_avmm_rsp_rd_id_emifclk       (       avmm_fsm2rsp_rd_id_emifclk[genvarChanCount] )
  );

  // ================================================================================================ emif-avmm "respones"
  /* fake out read and write responses for AVMM back to MCAXI to CXLIP
  */
  mc_single_chan_avmm_rsp     inst_avmm_rsp
  (
     .emifclk    (    emifclk[genvarChanCount] ),
     .emifresetn ( emifresetn[genvarChanCount] ),
   
     .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),
   
     .ram_init_done_del1_emifclk ( ram_init_done_del1_emifclk[genvarChanCount] ),

     /* read id fifo and write id from EMIF AVMM FSM
     */
	 .from_avmm_fsm_valid_write_id_emifclk ( avmm_fsm2rsp_valid_wr_id_emifclk[genvarChanCount] ),
	 .from_avmm_fsm_write_id_emifclk       (       avmm_fsm2rsp_wr_id_emifclk[genvarChanCount] ),
	 .from_avmm_fsm_valid_read_id_emifclk  ( avmm_fsm2rsp_valid_rd_id_emifclk[genvarChanCount] ),
	 .from_avmm_fsm_read_id_emifclk        (       avmm_fsm2rsp_rd_id_emifclk[genvarChanCount] ),

     /* AVMM signals from EMIF
     */
	 .from_emif_avmm_readdata_emifclk      (      emif2hdm_avmm_readdata_emifclk[genvarChanCount] ),
	 .from_emif_avmm_readdatavalid_emifclk ( emif2hdm_avmm_readdatavalid_emifclk[genvarChanCount] ),

     /* write responses
     */
	 .avmm_wr_rsp_id_emifclk    (    avmm_wr_rsp_id_emifclk[genvarChanCount] ),
	 .avmm_wr_rsp_valid_emifclk ( avmm_wr_rsp_valid_emifclk[genvarChanCount] ),

     /* read responses
     */
	 .avmm_rd_rsp_data_emifclk  (  avmm_rd_rsp_data_emifclk[genvarChanCount] ),
	 .avmm_rd_rsp_id_emifclk    (    avmm_rd_rsp_id_emifclk[genvarChanCount] ),
	 .avmm_rd_rsp_valid_emifclk ( avmm_rd_rsp_valid_emifclk[genvarChanCount] ),
   
	 .avmm_rd_rsp_id_fifo_almost_full_emifclk ( avmm_rd_rsp_id_fifo_almost_full_emifclk[genvarChanCount] )
  );

  // ================================================================================================ emif MUX
  /* Handle the selection betwen emif_avmm and emif_axi for the read and write responses back to CXLIP
     The write response goes straight to the rmw_block
     The read response goes straight to the ecc_rsp_block
  */
  always_comb
  begin
    emifmux2rmw_bchan_rsp_struct_emifclk[genvarChanCount].write_user       = emif_avmm_1_axi_0 ? '0                                         :  noc2hdm_aximm_buser_emifclk[genvarChanCount];
    emifmux2rmw_bchan_rsp_struct_emifclk[genvarChanCount].write_id         = emif_avmm_1_axi_0 ? avmm_wr_rsp_id_emifclk[genvarChanCount]    :    noc2hdm_aximm_bid_emifclk[genvarChanCount][ddr_mc_top_common_pkg::MC_LOCAL_AXI_WRC_ID_BW-1:0];
    emifmux2rmw_bchan_rsp_struct_emifclk[genvarChanCount].write_resp_valid = emif_avmm_1_axi_0 ? avmm_wr_rsp_valid_emifclk[genvarChanCount] : noc2hdm_aximm_bvalid_emifclk[genvarChanCount];	
	
    emifmux2rmw_bchan_rsp_struct_emifclk[genvarChanCount].write_axi_resp   = emif_avmm_1_axi_0 ? ddr_mc_top_common_pkg::eresp_MCTOP_OKAY
                                                                                               : ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding'( noc2hdm_aximm_bresp_emifclk[genvarChanCount] );

    hdm2noc_aximm_bready_emifclk[genvarChanCount] = ~bchan_rspfifo_rdfull_ipclk[genvarChanCount];
  
    post_mux_bchan_wr_rsp_valid_emifclk[genvarChanCount] = emif_avmm_1_axi_0 ? avmm_wr_rsp_valid_emifclk[genvarChanCount] : noc2hdm_aximm_bvalid_emifclk[genvarChanCount];
  end

  // ================================================================================================ ECC Responses
  /* mc_ecc_response block
     detect errors in the readdata and encode as poison to CXLIP
     and error status counters for cafu_csr0_cfg (placed into struct in mc_devmem_top post-fifo)
  */
  assign hdm2noc_aximm_rready_emifclk[genvarChanCount] = ~rchan_rspfifo_rdfull_ipclk[genvarChanCount];

  mc_single_chan_ecc_rsp
  #(
      .ALTECC_DATAWORD_WIDTH ( ddr_mc_top_common_pkg::MCTOP_ALTECC_DATAWORD_WIDTH ),
      .ALTECC_CODEWORD_WIDTH ( ddr_mc_top_common_pkg::MCTOP_ALTECC_WIDTH_CODEWORD ),
      .ALTECC_INST_NUMBER    ( ddr_mc_top_common_pkg::MCTOP_ALTECC_INST_NUMBER ),
      .MC_ECC_ENC_LATENCY    ( ddr_mc_top_common_pkg::MCTOP_MC_ECC_ENC_LATENCY ),
      .MC_ECC_DEC_LATENCY    ( ddr_mc_top_common_pkg::MCTOP_MC_ECC_DEC_LATENCY )
   )
  inst_mc_ecc_rsp_block
  (
    .emifclk    (    emifclk[genvarChanCount] ),
    .emifresetn ( emifresetn[genvarChanCount] ),
   
    .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),

    /* HDM emif-axi signals in
    */
    .noc2hdm_aximm_rresp_emifclk  (  noc2hdm_aximm_rresp_emifclk[genvarChanCount] ),
    .noc2hdm_aximm_rdata_emifclk  (  noc2hdm_aximm_rdata_emifclk[genvarChanCount] ),
    .noc2hdm_aximm_rid_emifclk    (    noc2hdm_aximm_rid_emifclk[genvarChanCount] ),
    .noc2hdm_aximm_rlast_emifclk  (  noc2hdm_aximm_rlast_emifclk[genvarChanCount] ),
    .noc2hdm_aximm_ruser_emifclk  (  noc2hdm_aximm_ruser_emifclk[genvarChanCount] ),
    .noc2hdm_aximm_rvalid_emifclk ( noc2hdm_aximm_rvalid_emifclk[genvarChanCount] ),

    /* AVMM read response signals in
    */
	.avmm_rd_rsp_data_emifclk       (       avmm_rd_rsp_data_emifclk[genvarChanCount] ),
	.avmm_rd_rsp_id_emifclk         (         avmm_rd_rsp_id_emifclk[genvarChanCount] ),
	.avmm_rd_rsp_valid_emifclk      (      avmm_rd_rsp_valid_emifclk[genvarChanCount] ),
	.sidecar_read_poison_emifclk    ( emif2hdm_avmm_read_poison_emifclk[genvarChanCount] ),

    /* responses to RMW to cdc_rspfifo
    */ 
    .eccrsp2rmw_rd_resp_emifclk ( eccrsp2rmw_rchan_rspfifo_resp_emifclk[genvarChanCount].read_rsp_intf ),
    .eccrsp2rmw_rd_ecc_emifclk  ( eccrsp2rmw_rchan_rspfifo_resp_emifclk[genvarChanCount].read_ecc_intf )
  );

  // ================================================================================================ cdc_rspfifo_reads
  /* clock domain crossing (cdc) fifo for read responses to axi read response channel
  */
  //width = 580; depth=256
  rspfifo_580b_256w   inst_rspfifo_rchan
  (
     .wrclk ( emifclk[genvarChanCount] ),
     .rdclk ( ipclk ),
     .aclr  ( ~ipresetn ),

     .wrreq  (   rchan_rspfifo_wrreq_emifclk[genvarChanCount] ),
     .data   ( rchan_rspfifo_data_in_emifclk[genvarChanCount] ),
     .wrfull (  rchan_rspfifo_wrfull_emifclk[genvarChanCount] ),
   
     .rdreq   (    rchan_rspfifo_rdreq_ipclk[genvarChanCount] ),
     .q       (        rchan_rspfifo_q_ipclk[genvarChanCount] ),
     .rdusedw (  rchan_rspfifo_rdusedw_ipclk[genvarChanCount] ),
     .rdempty (  rchan_rspfifo_rdempty_ipclk[genvarChanCount] ),
     .rdfull  (   rchan_rspfifo_rdfull_ipclk[genvarChanCount] )
  );

  assign rchan_rspfifo_rdreq_ipclk[genvarChanCount] = ~rchan_rspfifo_rdempty_ipclk[genvarChanCount]
                                                         & toMC_hdm2ip_axi_rready[genvarChanCount];

  assign rchan_rspfifo_data_in_emifclk[genvarChanCount] = {rchan_zeros, from_rmw_to_rchan_rspfifo_resp_emifclk[genvarChanCount]};

  assign rchan_rspfifo_dout_resp_ipclk[genvarChanCount] = ddr_mc_top_common_pkg::t_rchan_rspfifo'( rchan_rspfifo_q_ipclk[genvarChanCount][ddr_mc_top_common_pkg::MC_LOCAL_RHCAN_RSPFIFO_BW-1:0] ); 

  assign rchan_rspfifo_dout_data_intf_ipclk[genvarChanCount] = rchan_rspfifo_dout_resp_ipclk[genvarChanCount].read_rsp_intf;

  assign rchan_rspfifo_dout_ecc_intf_ipclk[genvarChanCount] = rchan_rspfifo_dout_resp_ipclk[genvarChanCount].read_ecc_intf;

  // ================================================================================================ cdc_rspfifo_writes
  /* clock domain crossing (cdc) fifo for write responses to axi write response channel
  */
  //width = 16; depth=256
  rspfifo_16b_256w   inst_rspfifo_bchan
  (
     .wrclk ( emifclk[genvarChanCount] ),
     .rdclk ( ipclk ),
     .aclr  ( ~ipresetn ),

     .wrreq  (   bchan_rspfifo_wrreq_emifclk[genvarChanCount] ),
     .data   ( bchan_rspfifo_data_in_emifclk[genvarChanCount] ),
     .wrfull (  bchan_rspfifo_wrfull_emifclk[genvarChanCount] ),
   
     .rdreq   (    bchan_rspfifo_rdreq_ipclk[genvarChanCount] ),
     .q       ( bchan_rspfifo_data_out_ipclk[genvarChanCount] ),
     .rdusedw (  bchan_rspfifo_rdusedw_ipclk[genvarChanCount] ),
     .rdempty (  bchan_rspfifo_rdempty_ipclk[genvarChanCount] ),
     .rdfull  (   bchan_rspfifo_rdfull_ipclk[genvarChanCount] )
  );
  
  
  assign bchan_rspfifo_rdreq_ipclk[genvarChanCount] = ~bchan_rspfifo_rdempty_ipclk[genvarChanCount]
                                                     & toMC_hdm2ip_axi_bready[genvarChanCount];
     

  assign bchan_rspfifo_data_in_emifclk[genvarChanCount] = {bchan_zeros, bchan_rspfifo_data_in_intf_emifclk[genvarChanCount]};



  assign bchan_rspfifo_data_out_intf_ipclk[genvarChanCount] = ddr_mc_top_common_pkg::t_bchan_rspfifo_data'( bchan_rspfifo_data_out_ipclk[genvarChanCount][ddr_mc_top_common_pkg::MC_LOCAL_BHCAN_RSPFIFO_DATA_BW-1:0] );

  // ================================================================================================ responses to CXLIP
  mc_single_chan_hdm2ip_axi_resp_chans   inst_hdm2ip_axi_resp_chans
  (
    .ipclk    ( ipclk    ),
    .ipresetn ( ipresetn ),
   
    .i_bchan_rspfifo_rdempty_ipclk ( bchan_rspfifo_rdempty_ipclk[genvarChanCount] ),
    .i_rchan_rspfifo_rdempty_ipclk ( rchan_rspfifo_rdempty_ipclk[genvarChanCount] ),

    .i_rspfifo2ip_new_write_resp_ipclk (  bchan_rspfifo_data_out_intf_ipclk[genvarChanCount] ),
    .i_rspfifo2ip_new_read_resp_ipclk  ( rchan_rspfifo_dout_data_intf_ipclk[genvarChanCount] ),

    .o_toMC_hdm2ip_axi_bready ( toMC_hdm2ip_axi_bready[genvarChanCount] ),
    .o_toMC_hdm2ip_axi_rready ( toMC_hdm2ip_axi_rready[genvarChanCount] ),
 
    /* External MC_TOP <--> BBS - write response channel
     */
    .hdm2ip_aximm_bvalid ( hdm2ip_aximm_bvalid[genvarChanCount] ),
    .hdm2ip_aximm_bid    ( hdm2ip_aximm_bid[genvarChanCount]    ),
    .hdm2ip_aximm_buser  ( hdm2ip_aximm_buser[genvarChanCount]  ),
    .hdm2ip_aximm_bresp  ( hdm2ip_aximm_bresp[genvarChanCount]  ),
    .ip2hdm_aximm_bready ( ip2hdm_aximm_bready[genvarChanCount] ),
    /* External MC_TOP <--> BBS - read response channel
     */
    .hdm2ip_aximm_rvalid ( hdm2ip_aximm_rvalid[genvarChanCount] ),
    .hdm2ip_aximm_rlast  ( hdm2ip_aximm_rlast[genvarChanCount]  ),
    .hdm2ip_aximm_rid    ( hdm2ip_aximm_rid[genvarChanCount]    ),
    .hdm2ip_aximm_rdata  ( hdm2ip_aximm_rdata[genvarChanCount]  ),
    .hdm2ip_aximm_ruser  ( hdm2ip_aximm_ruser[genvarChanCount]  ),
    .hdm2ip_aximm_rresp  ( hdm2ip_aximm_rresp[genvarChanCount]  ),
    .ip2hdm_aximm_rready ( ip2hdm_aximm_rready[genvarChanCount] )
  );

  // ================================================================================================ error status
  /* Handle error correction status information back to cafu_csr0_cfg
  */
  mc_single_chan_devmem_errors    inst_devmem_errors
  (
    .ipclk    ( ipclk    ),
    .ipresetn ( ipresetn ),
   
    .rchan_rspfifo_rdempty_ipclk        (        rchan_rspfifo_rdempty_ipclk[genvarChanCount] ),
    .rchan_rspfifo_dout_data_intf_ipclk ( rchan_rspfifo_dout_data_intf_ipclk[genvarChanCount] ),
    .rchan_rspfifo_dout_ecc_intf_ipclk  (  rchan_rspfifo_dout_ecc_intf_ipclk[genvarChanCount] ),
 
    .mc_err_cnt_ipclk ( mc_err_cnt_ipclk[genvarChanCount] )
  );
	 
end  // GENFOR_CHAN_COUNT
endgenerate

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3QcvDYXsXGNrF0xREEXro6b6gwt0bmbh+On3276y4ZflcjfM90ZTpRLPPf7KLU9f0pwlVjpXhANlX5pkAqrgKe/07lFcMBswu5JGbwWQVx5WDkTd/zq4GMMD4w2puWrfoT3aUBKefqnc9jFgjZC2FJeC8v4yy9HOmV84qSECBeT52T56004kcBpoOT1Gok8hmmZuWiftCKdQ8ylThg+q15jA54eBXHf5S9gmxaHICmu90vZ6gvsxPcb12AQ23q7aAgFW0czzsiSvsMDQkFTFAxRa3FEvxyTQ3jd1rkfks+SQm319L8TxX55ja124gMapA1ErFCNQ/nfg0tjiyl/3OElltM1MHquLcHCI1uVEP3/PnykJ0+sVYm8cRxCAcPwllqE0/0prKSdESdCePXd0f8BnuzYrz9WeFke3E79KVxRI/qVcrQuBYa3f57czRAKEhNDmxbwOjJBYPmiTZRSWxrkob6AS7dBBC/R++8QJ9hzCnoEuohFoRFY6k6kogkuX6d41yfBFdOgd1QJa72aLPMBiwwgXw7a31wowCcn4vsBHjglK6Te4oz91Bw+aTR6jm+XS0LuYKwOy9RccpHgp/wpliHhfZRiEiDR0Fl7kjm3CZK4D/ybS7AeBJrYYHVT8s24W2B7K5kCGkwxZ3lSC1hq2Zt6aMdTqNu1bcyr+Dq/L46U5rhus1biHfvYKo7CQMUyHltYJqlesdOzwb2WOBkob6Du1BGyxoFKXCQCLNOmqs1MO6PtZDMqQOXraNM5GygpSCT8weuYqYRt/Qr3y7Ki"
`endif
