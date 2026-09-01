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
// This define configures the design for the design validation environment of a single bbs slice.
// This mode is not intended for customer use and may result in unexpected behaviour if set.
`ifndef INTEL_ONLY_CXLIPDEV
   `include "cxl_ed_defines.svh.iv"
`endif

module mc_emif_avmm
  import ddr_mc_top_common_pkg::*;
(
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] mem_refclk,

  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] pll_locked,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] local_reset_done,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] local_cal_success,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] local_cal_fail,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_usr_reset_n,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_usr_clk,

  /* DDR4 signals
  */
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_CK_WIDTH-1:0]   mem_ck,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_CK_WIDTH-1:0]   mem_ck_n,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_ADDR_WIDTH-1:0] mem_a,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                         mem_act_n,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_BA_WIDTH-1:0]   mem_ba,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_BG_WIDTH-1:0]   mem_bg,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_CKE_WIDTH-1:0]  mem_cke,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_CS_WIDTH-1:0]   mem_cs_n,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_ODT_WIDTH-1:0]  mem_odt,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                         mem_reset_n,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                         mem_par,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                         mem_alert_n,
   input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                         mem_oct_rzqin, 
 
  inout wire [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_DQS_WIDTH-1:0]  mem_dqs,
  inout wire [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_DQS_WIDTH-1:0]  mem_dqs_n,
  inout wire [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_DQ_WIDTH-1:0]   mem_dq,
  inout wire [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_HA_DDR4_DBI_WIDTH-1:0]  mem_dbi_n,
  
  /* AVMM signals
  */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_BURST_WIDTH-1:0] emif_amm_burstcount,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0]  emif_amm_address,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0]  emif_amm_writedata,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_BE_WIDTH-1:0]    emif_amm_byteenable,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        emif_amm_write,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        emif_amm_read,  
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        emif_amm_write_poison,
  
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] emif_amm_readdata,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                       emif_amm_readdatavalid,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                       emif_amm_read_poison,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                       emif_amm_ready
);

// ================================================================================================
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] pll_ref_clk_out;

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][4095:0] calbus_seq_param_tbl; // emif_fm_0:calbus_seq_param_tbl -> emif_cal_0:calbus_seq_param_tbl_0
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][31:0]   calbus_rdata;         // emif_fm_0:calbus_rdata -> emif_cal_0:calbus_rdata_0
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][31:0]   calbus_wdata;         // emif_cal_0:calbus_wdata_0 -> emif_fm_0:calbus_wdata
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][19:0]   calbus_address;       // emif_cal_0:calbus_address_0 -> emif_fm_0:calbus_address
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]         calbus_read;          // emif_cal_0:calbus_read_0 -> emif_fm_0:calbus_read
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]         calbus_write;         // emif_cal_0:calbus_write_0 -> emif_fm_0:calbus_write

logic calbus_clk;   // emif_cal_0:calbus_clk -> [emif_fm_0:calbus_clk, emif_fm_1:calbus_clk]

logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0]  phy_amm_address;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0]  phy_amm_writedata;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_BE_WIDTH-1:0]    phy_amm_byteenable;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        phy_amm_write;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        phy_amm_read;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0]  phy_amm_readdata;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        phy_amm_readdatavalid;
logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        phy_amm_ready;

// ================================================================================================
`ifdef IA780I

        emif emif_inst_0
        (
           .oct_rzqin            (mem_oct_rzqin          [0] ), //   input,     width = 1,                oct.oct_rzqin
           .mem_ck               (mem_ck                 [0] ), //  output,     width = 1,                mem.mem_ck
           .mem_ck_n             (mem_ck_n               [0] ), //  output,     width = 1,                   .mem_ck_n
           .mem_a                (mem_a                  [0] ), //  output,    width = 17,                   .mem_a
           .mem_act_n            (mem_act_n              [0] ), //  output,     width = 1,                   .mem_act_n
           .mem_ba               (mem_ba                 [0] ), //  output,     width = 2,                   .mem_ba
           .mem_bg               (mem_bg                 [0] ), //  output,     width = 2,                   .mem_bg
           .mem_cke              (mem_cke                [0] ), //  output,     width = 2,                   .mem_cke
           .mem_cs_n             (mem_cs_n               [0] ), //  output,     width = 2,                   .mem_cs_n
           .mem_odt              (mem_odt                [0] ), //  output,     width = 2,                   .mem_odt
           .mem_reset_n          (mem_reset_n            [0] ), //  output,     width = 1,                   .mem_reset_n
           .mem_par              (mem_par                [0] ), //  output,     width = 1,                   .mem_par
           .mem_alert_n          (mem_alert_n            [0] ), //   input,     width = 1,                   .mem_alert_n
           .mem_dqs              (mem_dqs                [0][7:0] ), //   inout,     width = 8,                   .mem_dqs
           .mem_dqs_n            (mem_dqs_n              [0][7:0] ), //   inout,     width = 8,                   .mem_dqs_n
           .mem_dq               (mem_dq                 [0][63:0]), //   inout,    width = 64,                   .mem_dq
           .mem_dbi_n            (mem_dbi_n              [0][7:0] ), //   inout,     width = 8,                   .mem_dbi_n
           .pll_ref_clk          (mem_refclk             [0] ), //   input,     width = 1,        pll_ref_clk.clk
           //.pll_ref_clk_out      (pll_ref_clk_out        [0] ), //  output,     width = 1,    pll_ref_clk_out.clk
           .pll_locked           (pll_locked             [0] ), //  output,     width = 1,         pll_locked.pll_locked
           .local_reset_done     (local_reset_done       [0] ), //  output,     width = 1, local_reset_status.local_reset_done
           .local_cal_success    (local_cal_success      [0] ), //  output,     width = 1,             status.local_cal_success
           .local_cal_fail       (local_cal_fail         [0] ), //  output,     width = 1,                   .local_cal_fail
           .emif_usr_reset_n     (emif_usr_reset_n       [0] ), //  output,     width = 1,   emif_usr_reset_n.reset_n
           .emif_usr_clk         (emif_usr_clk           [0] ), //  output,     width = 1,       emif_usr_clk.clk
           .amm_address_0        (phy_amm_address        [0] ),
           .amm_read_0           (phy_amm_read           [0] ), //   input,     width = 1,                   .read
           .amm_write_0          (phy_amm_write          [0] ), //   input,     width = 1,                   .write
           .amm_writedata_0      (phy_amm_writedata      [0] ), //   input,   width = 512,                   .writedata
           .amm_burstcount_0     (emif_amm_burstcount    [0] ), //   input,     width = 7,                   .burstcount
           .amm_byteenable_0     (phy_amm_byteenable     [0] ), //   input,    width = 64,                   .byteenable
           .amm_ready_0          (phy_amm_ready          [0] ), //  output,     width = 1,         ctrl_amm_0.waitrequest_n
           .amm_readdata_0       (phy_amm_readdata       [0] ), //  output,   width = 512,                   .readdata
           .amm_readdatavalid_0  (phy_amm_readdatavalid  [0] ), //  output,     width = 1,                   .readdatavalid
           .calbus_read          (calbus_read            [0] ), //   input,     width = 1,        emif_calbus.calbus_read
           .calbus_write         (calbus_write           [0] ), //   input,     width = 1,                   .calbus_write
           .calbus_address       (calbus_address         [0] ), //   input,    width = 20,                   .calbus_address
           .calbus_wdata         (calbus_wdata           [0] ), //   input,    width = 32,                   .calbus_wdata
           .calbus_rdata         (calbus_rdata           [0] ), //  output,    width = 32,                   .calbus_rdata
           .calbus_seq_param_tbl (calbus_seq_param_tbl   [0] ), //  output,  width = 4096,                   .calbus_seq_param_tbl
           .local_reset_req      (1'b0                       ), //   input,     width = 1,    local_reset_req.local_reset_req
           .calbus_clk           (calbus_clk                 )  //   input,     width = 1,    emif_calbus_clk.clk
        );
        emif emif_inst_1
        (
           .oct_rzqin            (mem_oct_rzqin          [1] ), //   input,     width = 1,                oct.oct_rzqin
           .mem_ck               (mem_ck                 [1] ), //  output,     width = 1,                mem.mem_ck
           .mem_ck_n             (mem_ck_n               [1] ), //  output,     width = 1,                   .mem_ck_n
           .mem_a                (mem_a                  [1] ), //  output,    width = 17,                   .mem_a
           .mem_act_n            (mem_act_n              [1] ), //  output,     width = 1,                   .mem_act_n
           .mem_ba               (mem_ba                 [1] ), //  output,     width = 2,                   .mem_ba
           .mem_bg               (mem_bg                 [1] ), //  output,     width = 2,                   .mem_bg
           .mem_cke              (mem_cke                [1] ), //  output,     width = 2,                   .mem_cke
           .mem_cs_n             (mem_cs_n               [1] ), //  output,     width = 2,                   .mem_cs_n
           .mem_odt              (mem_odt                [1] ), //  output,     width = 2,                   .mem_odt
           .mem_reset_n          (mem_reset_n            [1] ), //  output,     width = 1,                   .mem_reset_n
           .mem_par              (mem_par                [1] ), //  output,     width = 1,                   .mem_par
           .mem_alert_n          (mem_alert_n            [1] ), //   input,     width = 1,                   .mem_alert_n
           .mem_dqs              (mem_dqs                [1][7:0] ), //   inout,     width = 8,                   .mem_dqs
           .mem_dqs_n            (mem_dqs_n              [1][7:0] ), //   inout,     width = 8,                   .mem_dqs_n
           .mem_dq               (mem_dq                 [1][63:0]), //   inout,    width = 64,                   .mem_dq
           .mem_dbi_n            (mem_dbi_n              [1][7:0] ), //   inout,     width = 8,                   .mem_dbi_n
           .pll_ref_clk          (mem_refclk             [1] ), //   input,     width = 1,        pll_ref_clk.clk
           //.pll_ref_clk_out      (pll_ref_clk_out        [1] ), //  output,     width = 1,    pll_ref_clk_out.clk
           .pll_locked           (pll_locked             [1] ), //  output,     width = 1,         pll_locked.pll_locked
           .local_reset_done     (local_reset_done       [1] ), //  output,     width = 1, local_reset_status.local_reset_done
           .local_cal_success    (local_cal_success      [1] ), //  output,     width = 1,             status.local_cal_success
           .local_cal_fail       (local_cal_fail         [1] ), //  output,     width = 1,                   .local_cal_fail
           .emif_usr_reset_n     (emif_usr_reset_n       [1] ), //  output,     width = 1,   emif_usr_reset_n.reset_n
           .emif_usr_clk         (emif_usr_clk           [1] ), //  output,     width = 1,       emif_usr_clk.clk
           .amm_address_0        (phy_amm_address        [1] ),
           .amm_read_0           (phy_amm_read           [1] ), //   input,     width = 1,                   .read
           .amm_write_0          (phy_amm_write          [1] ), //   input,     width = 1,                   .write
           .amm_writedata_0      (phy_amm_writedata      [1] ), //   input,   width = 512,                   .writedata
           .amm_burstcount_0     (emif_amm_burstcount    [1] ), //   input,     width = 7,                   .burstcount
           .amm_byteenable_0     (phy_amm_byteenable     [1] ), //   input,    width = 64,                   .byteenable
           .amm_ready_0          (phy_amm_ready          [1] ), //  output,     width = 1,         ctrl_amm_0.waitrequest_n
           .amm_readdata_0       (phy_amm_readdata       [1] ), //  output,   width = 512,                   .readdata
           .amm_readdatavalid_0  (phy_amm_readdatavalid  [1] ), //  output,     width = 1,                   .readdatavalid
           .calbus_read          (calbus_read            [1] ), //   input,     width = 1,        emif_calbus.calbus_read
           .calbus_write         (calbus_write           [1] ), //   input,     width = 1,                   .calbus_write
           .calbus_address       (calbus_address         [1] ), //   input,    width = 20,                   .calbus_address
           .calbus_wdata         (calbus_wdata           [1] ), //   input,    width = 32,                   .calbus_wdata
           .calbus_rdata         (calbus_rdata           [1] ), //  output,    width = 32,                   .calbus_rdata
           .calbus_seq_param_tbl (calbus_seq_param_tbl   [1] ), //  output,  width = 4096,                   .calbus_seq_param_tbl
           .local_reset_req      (1'b0                       ), //   input,     width = 1,    local_reset_req.local_reset_req
           .calbus_clk           (calbus_clk                 )  //   input,     width = 1,    emif_calbus_clk.clk
        );

  generate for (genvar chanCount = 0;
                chanCount < ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL;
                chanCount++) begin : GEN_POISON_SIDECAR
    mc_poison_sidecar sidecar
    (
      .clk                 (emif_usr_clk[chanCount]),
      .reset_n             (emif_usr_reset_n[chanCount]),
      .up_address          (emif_amm_address[chanCount]),
      .up_writedata        (emif_amm_writedata[chanCount]),
      .up_byteenable       (emif_amm_byteenable[chanCount]),
      .up_read             (emif_amm_read[chanCount]),
      .up_write            (emif_amm_write[chanCount]),
      .up_write_poison     (emif_amm_write_poison[chanCount]),
      .up_readdata         (emif_amm_readdata[chanCount]),
      .up_readdatavalid    (emif_amm_readdatavalid[chanCount]),
      .up_read_poison      (emif_amm_read_poison[chanCount]),
      .up_ready            (emif_amm_ready[chanCount]),
      .phy_address         (phy_amm_address[chanCount]),
      .phy_writedata       (phy_amm_writedata[chanCount]),
      .phy_byteenable      (phy_amm_byteenable[chanCount]),
      .phy_read            (phy_amm_read[chanCount]),
      .phy_write           (phy_amm_write[chanCount]),
      .phy_readdata        (phy_amm_readdata[chanCount]),
      .phy_readdatavalid   (phy_amm_readdatavalid[chanCount]),
      .phy_ready           (phy_amm_ready[chanCount])
    );

`ifndef SYNTHESIS
    always_ff @(posedge emif_usr_clk[chanCount]) begin
      if (emif_usr_reset_n[chanCount]) begin
        if (phy_amm_write[chanCount])
          assert ({1'b0, phy_amm_address[chanCount]} <
                  mc_poison_sidecar_pkg::PHYS_LINE_COUNT_PER_CHANNEL);
        if (emif_amm_ready[chanCount] && emif_amm_write[chanCount])
          assert ({1'b0, emif_amm_address[chanCount]} <
                  mc_poison_sidecar_pkg::DATA_LINE_COUNT_PER_CHANNEL);
        if (emif_amm_readdatavalid[chanCount])
          assert (!$isunknown(emif_amm_read_poison[chanCount]));
      end
    end
`endif
  end
  endgenerate

`else 
`ifndef REVB_DEVKIT
  
  generate for( genvar chanCount = 0; chanCount < ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL; chanCount=chanCount+1 )
  begin : GEN_CHAN_COUNT_EMIF_NOT_REVB

        emif   emif_inst 
        (
           .oct_rzqin            (mem_oct_rzqin[chanCount] ),        //   input,     width = 1,                oct.oct_rzqin
           .mem_ck               (mem_ck[chanCount]        ),        //  output,     width = 1,                mem.mem_ck
           .mem_ck_n             (mem_ck_n[chanCount]      ),        //  output,     width = 1,                   .mem_ck_n
           .mem_a                (mem_a[chanCount]         ),        //  output,    width = 17,                   .mem_a
           .mem_act_n            (mem_act_n[chanCount]     ),        //  output,     width = 1,                   .mem_act_n
           .mem_ba               (mem_ba[chanCount]        ),        //  output,     width = 2,                   .mem_ba
           .mem_bg               (mem_bg[chanCount]        ),        //  output,     width = 2,                   .mem_bg
           .mem_cke              (mem_cke[chanCount]       ),        //  output,     width = 2,                   .mem_cke
           .mem_cs_n             (mem_cs_n[chanCount]      ),        //  output,     width = 2,                   .mem_cs_n
           .mem_odt              (mem_odt[chanCount]       ),        //  output,     width = 2,                   .mem_odt
           .mem_reset_n          (mem_reset_n[chanCount]   ),        //  output,     width = 1,                   .mem_reset_n
           .mem_par              (mem_par[chanCount]       ),        //  output,     width = 1,                   .mem_par
           .mem_alert_n          (mem_alert_n[chanCount]   ),        //   input,     width = 1,                   .mem_alert_n
           .mem_dqs              (mem_dqs[chanCount]       ),        //   inout,     width = 9,                   .mem_dqs
           .mem_dqs_n            (mem_dqs_n[chanCount]     ),        //   inout,     width = 9,                   .mem_dqs_n
           .mem_dq               (mem_dq[chanCount]        ),        //   inout,    width = 72,                   .mem_dq
           .mem_dbi_n            (mem_dbi_n[chanCount]     ),        //   inout,     width = 9,                   .mem_dbi_n

           .pll_ref_clk          (mem_refclk[chanCount]      ),      //   input,     width = 1,        pll_ref_clk.clk
           .pll_ref_clk_out      (pll_ref_clk_out[chanCount] ),      //  output,     width = 1,    pll_ref_clk_out.clk
           .pll_locked           (pll_locked[chanCount]      ),      //  output,     width = 1,         pll_locked.pll_locked

           .local_reset_req      (1'b0),                             //   input,     width = 1,    local_reset_req.local_reset_req
           .local_reset_done     (local_reset_done[chanCount]  ),    //  output,     width = 1, local_reset_status.local_reset_done
           .local_cal_success    (local_cal_success[chanCount] ),    //  output,     width = 1,             status.local_cal_success
           .local_cal_fail       (local_cal_fail[chanCount]    ),    //  output,     width = 1,                   .local_cal_fail

           .emif_usr_reset_n     (emif_usr_reset_n[chanCount]  ),    //  output,     width = 1,   emif_usr_reset_n.reset_n
           .emif_usr_clk         (emif_usr_clk[chanCount]      ),    //  output,     width = 1,       emif_usr_clk.clk

           .amm_address_0        (emif_amm_address[chanCount] ),
           .amm_read_0           (emif_amm_read[chanCount]          ),    //   input,     width = 1,                   .read
           .amm_write_0          (emif_amm_write[chanCount]         ),    //   input,     width = 1,                   .write
           .amm_writedata_0      (emif_amm_writedata[chanCount]     ),    //   input,   width = 576,                   .writedata
           .amm_burstcount_0     (emif_amm_burstcount[chanCount]    ),    //   input,     width = 7,                   .burstcount
           .amm_byteenable_0     (emif_amm_byteenable[chanCount]    ),    //   input,    width = 72,                   .byteenable
           .amm_ready_0          (emif_amm_ready[chanCount]         ),    //  output,     width = 1,         ctrl_amm_0.waitrequest_n
           .amm_readdata_0       (emif_amm_readdata[chanCount]      ),    //  output,   width = 576,                   .readdata
           .amm_readdatavalid_0  (emif_amm_readdatavalid[chanCount] ),    //  output,     width = 1,                   .readdatavalid

           .calbus_read          (calbus_read[chanCount]          ),  //   input,     width = 1,        emif_calbus.calbus_read
           .calbus_write         (calbus_write[chanCount]         ),  //   input,     width = 1,                   .calbus_write
           .calbus_address       (calbus_address[chanCount]       ),  //   input,    width = 20,                   .calbus_address
           .calbus_wdata         (calbus_wdata[chanCount]         ),  //   input,    width = 32,                   .calbus_wdata
           .calbus_clk           (calbus_clk                      ),  //   input,     width = 1,    emif_calbus_clk.clk
           .calbus_rdata         (calbus_rdata[chanCount]         ),  //  output,    width = 32,                   .calbus_rdata
           .calbus_seq_param_tbl (calbus_seq_param_tbl[chanCount] )   //  output,  width = 4096,                   .calbus_seq_param_tbl
        );
  end
  endgenerate

`else  // ifndef REVB_DEVKIT

  generate for( genvar chanCount = 0; chanCount < ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL; chanCount=chanCount+1 )
  begin : GEN_CHAN_COUNT_EMIF_REVB

    if (chanCount == 0)
    begin: NON_HPS_MEM

        emif   emif_inst 
        (
           .oct_rzqin            (mem_oct_rzqin[chanCount] ),        //   input,     width = 1,                oct.oct_rzqin
           .mem_ck               (mem_ck[chanCount]        ),        //  output,     width = 1,                mem.mem_ck
           .mem_ck_n             (mem_ck_n[chanCount]      ),        //  output,     width = 1,                   .mem_ck_n
           .mem_a                (mem_a[chanCount]         ),        //  output,    width = 17,                   .mem_a
           .mem_act_n            (mem_act_n[chanCount]     ),        //  output,     width = 1,                   .mem_act_n
           .mem_ba               (mem_ba[chanCount]        ),        //  output,     width = 2,                   .mem_ba
           .mem_bg               (mem_bg[chanCount]        ),        //  output,     width = 2,                   .mem_bg
           .mem_cke              (mem_cke[chanCount]       ),        //  output,     width = 2,                   .mem_cke
           .mem_cs_n             (mem_cs_n[chanCount]      ),        //  output,     width = 2,                   .mem_cs_n
           .mem_odt              (mem_odt[chanCount]       ),        //  output,     width = 2,                   .mem_odt
           .mem_reset_n          (mem_reset_n[chanCount]   ),        //  output,     width = 1,                   .mem_reset_n
           .mem_par              (mem_par[chanCount]       ),        //  output,     width = 1,                   .mem_par
           .mem_alert_n          (mem_alert_n[chanCount]   ),        //   input,     width = 1,                   .mem_alert_n
           .mem_dqs              (mem_dqs[chanCount]       ),        //   inout,     width = 9,                   .mem_dqs
           .mem_dqs_n            (mem_dqs_n[chanCount]     ),        //   inout,     width = 9,                   .mem_dqs_n
           .mem_dq               (mem_dq[chanCount]        ),        //   inout,    width = 72,                   .mem_dq
         `ifdef ENABLE_DDR_DBI_PINS
           .mem_dbi_n            (mem_dbi_n[chanCount]),                                    //   inout,     width = 9,                   .mem_dbi_n
         `endif
           .pll_ref_clk          (mem_refclk[chanCount]      ),      //   input,     width = 1,        pll_ref_clk.clk
           .pll_ref_clk_out      (pll_ref_clk_out[chanCount] ),      //  output,     width = 1,    pll_ref_clk_out.clk
           .pll_locked           (pll_locked[chanCount]      ),      //  output,     width = 1,         pll_locked.pll_locked

           .local_reset_req      (1'b0),                             //   input,     width = 1,    local_reset_req.local_reset_req
           .local_reset_done     (local_reset_done[chanCount]  ),    //  output,     width = 1, local_reset_status.local_reset_done
           .local_cal_success    (local_cal_success[chanCount] ),    //  output,     width = 1,             status.local_cal_success
           .local_cal_fail       (local_cal_fail[chanCount]    ),    //  output,     width = 1,                   .local_cal_fail

           .emif_usr_reset_n     (emif_usr_reset_n[chanCount]  ),    //  output,     width = 1,   emif_usr_reset_n.reset_n
           .emif_usr_clk         (emif_usr_clk[chanCount]      ),    //  output,     width = 1,       emif_usr_clk.clk
		 
           .amm_address_0        (emif_amm_address[chanCount] ),
           .amm_read_0           (emif_amm_read[chanCount]          ),    //   input,     width = 1,                   .read
           .amm_write_0          (emif_amm_write[chanCount]         ),    //   input,     width = 1,                   .write
           .amm_writedata_0      (emif_amm_writedata[chanCount]     ),    //   input,   width = 576,                   .writedata
           .amm_burstcount_0     (emif_amm_burstcount[chanCount]    ),    //   input,     width = 7, 
         `ifdef ENABLE_DDR_DBI_PINS
           .amm_byteenable_0     (emif_amm_byteenable[chanCount]),          //   input,    width = 72,                   .byteenable
         `endif          
           .amm_ready_0          (emif_amm_ready[chanCount]         ),    //  output,     width = 1,         ctrl_amm_0.waitrequest_n
           .amm_readdata_0       (emif_amm_readdata[chanCount]      ),    //  output,   width = 576,                   .readdata
           .amm_readdatavalid_0  (emif_amm_readdatavalid[chanCount] ),    //  output,     width = 1,                   .readdatavalid

           .calbus_read          (calbus_read[chanCount]          ),  //   input,     width = 1,        emif_calbus.calbus_read
           .calbus_write         (calbus_write[chanCount]         ),  //   input,     width = 1,                   .calbus_write
           .calbus_address       (calbus_address[chanCount]       ),  //   input,    width = 20,                   .calbus_address
           .calbus_wdata         (calbus_wdata[chanCount]         ),  //   input,    width = 32,                   .calbus_wdata
           .calbus_clk           (calbus_clk                      ),  //   input,     width = 1,    emif_calbus_clk.clk
           .calbus_rdata         (calbus_rdata[chanCount]         ),  //  output,    width = 32,                   .calbus_rdata
           .calbus_seq_param_tbl (calbus_seq_param_tbl[chanCount] )   //  output,  width = 4096,                   .calbus_seq_param_tbl
        );

    end
    if (chanCount == 1)
    begin : HPS_MEM

		emif2   emif_inst_2 
        (
           .oct_rzqin            (mem_oct_rzqin[chanCount] ),        //   input,     width = 1,                oct.oct_rzqin
           .mem_ck               (mem_ck[chanCount]        ),        //  output,     width = 1,                mem.mem_ck
           .mem_ck_n             (mem_ck_n[chanCount]      ),        //  output,     width = 1,                   .mem_ck_n
           .mem_a                (mem_a[chanCount]         ),        //  output,    width = 17,                   .mem_a
           .mem_act_n            (mem_act_n[chanCount]     ),        //  output,     width = 1,                   .mem_act_n
           .mem_ba               (mem_ba[chanCount]        ),        //  output,     width = 2,                   .mem_ba
           .mem_bg               (mem_bg[chanCount]        ),        //  output,     width = 2,                   .mem_bg
           .mem_cke              (mem_cke[chanCount]       ),        //  output,     width = 2,                   .mem_cke
           .mem_cs_n             (mem_cs_n[chanCount]      ),        //  output,     width = 2,                   .mem_cs_n
           .mem_odt              (mem_odt[chanCount]       ),        //  output,     width = 2,                   .mem_odt
           .mem_reset_n          (mem_reset_n[chanCount]   ),        //  output,     width = 1,                   .mem_reset_n
           .mem_par              (mem_par[chanCount]       ),        //  output,     width = 1,                   .mem_par
           .mem_alert_n          (mem_alert_n[chanCount]   ),        //   input,     width = 1,                   .mem_alert_n
           .mem_dqs              (mem_dqs[chanCount]       ),        //   inout,     width = 9,                   .mem_dqs
           .mem_dqs_n            (mem_dqs_n[chanCount]     ),        //   inout,     width = 9,                   .mem_dqs_n
           .mem_dq               (mem_dq[chanCount]        ),        //   inout,    width = 72,                   .mem_dq
         `ifdef ENABLE_DDR_DBI_PINS
           .mem_dbi_n            (mem_dbi_n[chanCount]),                                    //   inout,     width = 9,                   .mem_dbi_n
         `endif
           .pll_ref_clk          (mem_refclk[chanCount]      ),      //   input,     width = 1,        pll_ref_clk.clk
           //.pll_ref_clk_out      (pll_ref_clk_out[chanCount] ),      //  output,     width = 1,    pll_ref_clk_out.clk
           .pll_locked           (pll_locked[chanCount]      ),      //  output,     width = 1,         pll_locked.pll_locked

           .local_reset_req      (1'b0),                             //   input,     width = 1,    local_reset_req.local_reset_req
           .local_reset_done     (local_reset_done[chanCount]  ),    //  output,     width = 1, local_reset_status.local_reset_done
           .local_cal_success    (local_cal_success[chanCount] ),    //  output,     width = 1,             status.local_cal_success
           .local_cal_fail       (local_cal_fail[chanCount]    ),    //  output,     width = 1,                   .local_cal_fail

           .emif_usr_reset_n     (emif_usr_reset_n[chanCount]  ),    //  output,     width = 1,   emif_usr_reset_n.reset_n
           .emif_usr_clk         (emif_usr_clk[chanCount]      ),    //  output,     width = 1,       emif_usr_clk.clk
		 
           .amm_address_0        (emif_amm_address[chanCount] ),
           .amm_read_0           (emif_amm_read[chanCount]          ),    //   input,     width = 1,                   .read
           .amm_write_0          (emif_amm_write[chanCount]         ),    //   input,     width = 1,                   .write
           .amm_writedata_0      (emif_amm_writedata[chanCount]     ),    //   input,   width = 576,                   .writedata
           .amm_burstcount_0     (emif_amm_burstcount[chanCount]    ),    //   input,     width = 7, 
         `ifdef ENABLE_DDR_DBI_PINS
           .amm_byteenable_0     (emif_amm_byteenable[chanCount]),          //   input,    width = 72,                   .byteenable
         `endif          
           .amm_ready_0          (emif_amm_ready[chanCount]         ),    //  output,     width = 1,         ctrl_amm_0.waitrequest_n
           .amm_readdata_0       (emif_amm_readdata[chanCount]      ),    //  output,   width = 576,                   .readdata
           .amm_readdatavalid_0  (emif_amm_readdatavalid[chanCount] ),    //  output,     width = 1,                   .readdatavalid

           .calbus_read          (calbus_read[chanCount]          ),  //   input,     width = 1,        emif_calbus.calbus_read
           .calbus_write         (calbus_write[chanCount]         ),  //   input,     width = 1,                   .calbus_write
           .calbus_address       (calbus_address[chanCount]       ),  //   input,    width = 20,                   .calbus_address
           .calbus_wdata         (calbus_wdata[chanCount]         ),  //   input,    width = 32,                   .calbus_wdata
           .calbus_clk           (calbus_clk                      ),  //   input,     width = 1,    emif_calbus_clk.clk
           .calbus_rdata         (calbus_rdata[chanCount]         ),  //  output,    width = 32,                   .calbus_rdata
           .calbus_seq_param_tbl (calbus_seq_param_tbl[chanCount] )   //  output,  width = 4096,                   .calbus_seq_param_tbl
        );
    end
  end
  endgenerate

`endif  // ifndef REVB_DEVKIT
`endif  // ifdef  IA780I

`ifndef IA780I
  assign emif_amm_read_poison = '0;
`endif

// ================================================================================================
/* EMIF AVMM Calibration blocks
*/
generate if( ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL == 1 )
begin : GEN_CAL_ONE_MEM_CHANNEL
        emif_cal_one_ch  emif_cal_one_ch_inst 
        (
            .calbus_clk             (calbus_clk              ),  //  output,     width = 1, emif_calbus_clk.clk
            .calbus_read_0          (calbus_read[0]          ),  //  output,     width = 1,   emif_calbus_0.calbus_read
            .calbus_write_0         (calbus_write[0]         ),  //  output,     width = 1,                .calbus_write
            .calbus_address_0       (calbus_address[0]       ),  //  output,    width = 20,                .calbus_address
            .calbus_wdata_0         (calbus_wdata[0]         ),  //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_0         (calbus_rdata[0]         ),  //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_0 (calbus_seq_param_tbl[0] )   //   input,  width = 4096,                .calbus_seq_param_tbl
        );
end
else begin : GEN_CAL_TWO_MEM_CHANNELS
        emif_cal_two_ch  emif_cal_two_ch_inst 
        (
            .calbus_clk             (calbus_clk              ),  //  output,     width = 1, emif_calbus_clk.clk

            .calbus_read_0          (calbus_read[0]          ),  //  output,     width = 1,   emif_calbus_0.calbus_read
            .calbus_write_0         (calbus_write[0]         ),  //  output,     width = 1,                .calbus_write
            .calbus_address_0       (calbus_address[0]       ),  //  output,    width = 20,                .calbus_address
            .calbus_wdata_0         (calbus_wdata[0]         ),  //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_0         (calbus_rdata[0]         ),  //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_0 (calbus_seq_param_tbl[0] ),  //   input,  width = 4096,                .calbus_seq_param_tbl

            .calbus_read_1          (calbus_read[1]          ),  //  output,     width = 1,   emif_calbus_1.calbus_read
            .calbus_write_1         (calbus_write[1]         ),  //  output,     width = 1,                .calbus_write
            .calbus_address_1       (calbus_address[1]       ),  //  output,    width = 20,                .calbus_address
            .calbus_wdata_1         (calbus_wdata[1]         ),  //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_1         (calbus_rdata[1]         ),  //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_1 (calbus_seq_param_tbl[1] )   //   input,  width = 4096,                .calbus_seq_param_tbl
        );
end
endgenerate

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL4nnGYJsqTc8TI08yjuiq4a53857dEJ6iMPFjoTXR0id5VMmMVKTHMo03DzRLlOFVK9pQktOF5G5Zyqu8Gc0kEuVkIfZOPdKErqbRMXrVzOg3sdb1M2hn9DXak/ZNqXT+KvsYoCpnIQqaZfoQZVxQmMZUuTWv0t7wEKjL589Dei+ue4dYZ+1XAe5Q/EDakeSYAcSzXZvA9kv5Fi0kPqqe72EONlPV6LVpGHjCTFjvAOcTDazXw3l8wayFiMhRylsdUatIuainXstKSfoR4KQTA/z3Z0/CUqWwJqoqPpTeakElxTbv5hdAjtzjPJwErSIUE8hpF37W8P+s8sIllErw1FLYnzuS7u+zFJnQH11X58nhw+n1QUDzXXHifVHPJs1RtHlCW1b0ff5qntBuXWJX5i5VJ1ldNK0LRcsv3S28W7jYJzu8TUyE1Nm8kCWqpQp1FYwEvXsU7yvT5pMxzQEHo7aSyE8gGE+PnAItHPywMQm3U1haucbi8Gt/00O7w/1CSTR7pslQMMWBZX11+3aFElxBs2Uc12To/HOr0xs/PKcCVxTfQPZtgl53G7KxJtPjAYhfY2abnR5K+zzy+IHcoaKRJkO/wgvWeyhMLciiDYsnrN2ynKy7W1AQ7xVgv5MVpfha31xk96b5PNIlzzSYIMDEGrTpwuRPfbvEkQlX5MD3ofSU8Ni5L8l7oHUIkJY6LrWfxcyq35Ks7idxrgGcoIcAO3rpQUa/5NIwhqfcSWXHa94pwyjtFoQsBymvCQRidBbkVokTf8eUVoOzZIZE+b"
`endif
