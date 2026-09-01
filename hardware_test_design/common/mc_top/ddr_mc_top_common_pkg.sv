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
//
// THIS IS AN AUTO-GENERATED FILE!!!!!
//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//
// CUSTOMER USE : This make structs and parameters previously hidden behind encryption
//   under the CXLIP boundary visible. Instructions and warnings on editing these structs
//   and parameters will be provided in-line where considered necessary.
//

package ddr_mc_top_common_pkg;

// This define configures the design for the design validation environment of a single bbs slice.
// This mode is not intended for customer use and may result in unexpected behaviour if set.
//`define INTEL_ONLY_CXLIPDEV  1


`ifdef INTEL_ONLY_CXLIPDEV


  // This define is used to differentiate certain logic between TYPE3 and non-TYPE3
  `define MCTOP_TYPE_2 1
  //`define MCTOP_TYPE_3 1


  // For CXLIPDEV simulation and debug only. Changes how ram_initialization works:
  //   SIM_MC_RAM_INIT_W_ZERO_SINGLE_ONLY  - sends a single write to address 0
  //   SIM_MC_RAM_INIT_W_ZERO_PARTIAL_ONLY - sets ram_init_addr to {42'{1}, 4'b0} and lets ram initializtion work as usual
  `ifdef MCTOP_TYPE_2
    `define SIM_MC_RAM_INIT_W_ZERO_PARTIAL_ONLY 1
    //`define SIM_MC_RAM_INIT_W_ZERO_SINGLE_ONLY 1
  `endif

`endif  // INTEL_ONLY_CXLIPDEV



// parameters and structs copied from CXLIP gobal defines package

// @@copy for common_mctop_pkg@@start 
  // these are for the GRAM** settings in the fifos
  localparam MCTOP_GRAM_AUTO = "no_rw_check";       // defaults to auto
  localparam MCTOP_GRAM_BLCK = "no_rw_check, M20K";
  localparam MCTOP_GRAM_DIST = "no_rw_check, MLAB";

//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//

// parameters and structs copied from the CXLIP top package

// @@copy for common_mctop_pkg@@start
// number of memory controller channels
`ifdef INTEL_ONLY_CXLIPDEV
  localparam MCTOP_MC_CHANNEL                  = 1;
`else 
  `ifdef ENABLE_1_SLICE   // 1 slice
    localparam MCTOP_MC_CHANNEL                = 1;
  `elsif ENABLE_4_SLICE   // 4 slice
    localparam MCTOP_MC_CHANNEL                = 4;
  `else                   // 2 slice  
    localparam MCTOP_MC_CHANNEL                = 2;
  `endif
`endif

// @@copy for common_mctop_pkg@@start
localparam MCTOP_MC_HA_DDR4_ADDR_WIDTH     = 17;
localparam MCTOP_MC_HA_DDR4_BA_WIDTH       = 2;
localparam MCTOP_MC_HA_DDR4_BG_WIDTH       = 2;
localparam MCTOP_MC_HA_DDR4_CK_WIDTH       = 1;
localparam MCTOP_MC_HA_DDR4_CKE_WIDTH      = 1;
localparam MCTOP_MC_HA_DDR4_CS_WIDTH       = 1;
localparam MCTOP_MC_HA_DDR4_ODT_WIDTH      = 1;
`ifdef IA780I
localparam MCTOP_MC_HA_DDR4_DQS_WIDTH      = 8;
localparam MCTOP_MC_HA_DDR4_DQ_WIDTH       = 64;
localparam MCTOP_MC_HA_DDR4_DBI_WIDTH      = 8;
`else
localparam MCTOP_MC_HA_DDR4_DQS_WIDTH      = 9;
localparam MCTOP_MC_HA_DDR4_DQ_WIDTH       = 72;
localparam MCTOP_MC_HA_DDR4_DBI_WIDTH      = 9;
`endif
localparam MCTOP_MEMCNTRL_ADDR_WIDTH = 46;

localparam MCTOP_EMIF_AMM_ADDR_WIDTH      = 27;
`ifdef IA780I
localparam MCTOP_EMIF_AMM_DATA_WIDTH      = 512;
localparam MCTOP_EMIF_AMM_BE_WIDTH        = 64;
`else
localparam MCTOP_EMIF_AMM_DATA_WIDTH      = 576;
localparam MCTOP_EMIF_AMM_BE_WIDTH        = 72;
`endif
localparam MCTOP_EMIF_AMM_BURST_WIDTH     = 7;

localparam MCTOP_EMIF_AXI_ADDR_WIDTH = 46;
localparam MCTOP_EMIF_AXI_DATA_WIDTH = 512;
localparam MCTOP_EMIF_AXI_STRB_WIDTH = 64;
localparam MCTOP_EMIF_AXI_ECC_WIDTH  = 64;  // should go to wuser

localparam MCTOP_REG_ON_REQFIFO_INPUT_EN  = 0;
localparam MCTOP_REG_ON_REQFIFO_OUTPUT_EN = 1;
localparam MCTOP_REG_ON_RSPFIFO_OUTPUT_EN = 0;

localparam MCTOP_MC_HA_DP_ADDR_WIDTH       = 46;  // 46 supports full cxl addr width [51:6]
localparam MCTOP_MC_HA_DP_DATA_WIDTH       = 512;
`ifdef IA780I
localparam MCTOP_MC_ECC_EN                 = 0;
`else
localparam MCTOP_MC_ECC_EN                 = 1;
`endif
localparam MCTOP_MC_ECC_ENC_LATENCY        = 1;
localparam MCTOP_MC_ECC_DEC_LATENCY        = 1;
localparam MCTOP_MC_RAM_INIT_W_ZERO_EN     = 1;
localparam MCTOP_MEMSIZE_WIDTH             = 64;

// These mc_top parameters are defined in mc_top as localparam.  Therefore, these localparam values
// can not be used as mc_top parameter inputs.  They are copied here to ensure the related signal
// widths are in sync with mc_top.
localparam MCTOP_MC_MDATA_WIDTH            = 14;
localparam MCTOP_MC_SR_STAT_WIDTH          = 5;
localparam MCTOP_MC_HA_DP_BITS_PER_SYMBOL  = 8;
localparam MCTOP_MC_HA_DP_BE_WIDTH = MCTOP_MC_HA_DP_DATA_WIDTH / MCTOP_MC_HA_DP_BITS_PER_SYMBOL;
localparam MCTOP_REQFIFO_DEPTH_WIDTH       = 6;
localparam MCTOP_RSPFIFO_DEPTH_WIDTH       = 6;

     // ==== MCTOP_ALTECC ====
localparam MCTOP_ALTECC_DATAWORD_WIDTH = 64;
localparam MCTOP_ALTECC_WIDTH_CODEWORD = 72;
localparam MCTOP_ALTECC_INST_NUMBER    = MCTOP_MC_HA_DP_DATA_WIDTH / MCTOP_ALTECC_DATAWORD_WIDTH;

// Specify lsb/msb for cxl-ip output cxlip2iafu_address_eclk.
// Set to full cxl addr width (addr[51:6]).
localparam MCTOP_CXLIP_FULL_ADDR_LSB = 6;
localparam MCTOP_CXLIP_FULL_ADDR_MSB = 51;

// The cxl-ip provides all cxl address bits for each memory request (addr[51:6]).
// The address bits to connect to a memory channel depends on the total amount
// of memory and the number of cxl-ip HDM request ports.
//
// If the cxl-ip is configured for one HDM request port, addr[n:6] is meaningful.
// (n is determined by the memory size).  If there is one memory channel, addr[n:6]
// from the HDM port should connect to the memory channel.  Note that addr[51:n+1]
// does not have to connect to the memory channel.
//
// If configured for two HDM request ports, addr[n:7] is meaningful and addr[6]
// is the interleave bit (one HDM port always has addr[6]=0 and the other
// HDM port always has addr[6]=1).  If there are two memory channels, addr[n:7]
// from each HDM port should connect to the corresponding memory channel.
//
// If configured for four HDM request ports, addr[n:8] is meaningful and addr[7:6]
// are the interleave bits (one HDM port always has addr[7:6]=00, one always
// has addr[7:6]=01, etc.).  If there are four memory channels, addr[n:8]
// from each HDM port should connect to the corresponding memory channel.
//
// The following table shows an example with 8GB of memory.
// In this case, 27 address bits are needed (2^27 * 64B = 8GB).
//
// Mem Size  Addr Bits  Mem Chan  Mem/Ch  Ch Addr Bits
// --------  ---------  --------  ------  ------------
//   8GB      [32:6]       1       8GB       [32:6]
//                         2       4GB       [32:7]
//                         4       2GB       [32:8]
localparam MCTOP_CXLIP_CHAN_ADDR_LSB = ( MCTOP_MC_CHANNEL == 4 ) ? 8 : (( MCTOP_MC_CHANNEL == 2 ) ? 7 : 6);
localparam MCTOP_CXLIP_CHAN_ADDR_MSB = MCTOP_CXLIP_FULL_ADDR_LSB + (MCTOP_MEMCNTRL_ADDR_WIDTH-1);

//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//
// parameters and structs copied from the CXLIP slice package


localparam MCTOP_NUM_SLICES = MCTOP_MC_CHANNEL; // 1,2 or 4


// @@copy for common_mctop_pkg@@start
 //2MB DevMem total regardless of number of slices
  localparam MCTOP_DEVMEM_SIZE_ADDR = 15 - $clog2(MCTOP_NUM_SLICES); //15, 14, 13 for MCTOP_NUM_SLICES = 1, 2, 4 respectively
                                                             //2MB, 32K Entry for the one slice,
                                                             //1MB, per slice for 2 slices,
                                                             //512KB, per slice for 4 slices.

//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//

// parameters and structs copied from CXLIP for the CXLIP-to-CAFU AXI interface

// @@copy for common_afu_pkg@@start
    localparam MCTOP_AFU_AXI_BURST_WIDTH            = 2;
    localparam MCTOP_AFU_AXI_CACHE_WIDTH            = 4;
    localparam MCTOP_AFU_AXI_LOCK_WIDTH             = 2;
    localparam MCTOP_AFU_AXI_MAX_ADDR_USER_WIDTH    = 5;
    localparam MCTOP_AFU_AXI_MAX_ADDR_WIDTH         = 64;
    localparam MCTOP_AFU_AXI_MAX_BRESP_USER_WIDTH   = 4;
    localparam MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH = 10;
    localparam MCTOP_AFU_AXI_MAX_DATA_USER_WIDTH    = 4;
    localparam MCTOP_AFU_AXI_MAX_DATA_WIDTH         = 512;
    localparam MCTOP_AFU_AXI_MAX_ID_WIDTH           = 12;
    localparam MCTOP_AFU_AXI_PROT_WIDTH             = 3;
    localparam MCTOP_AFU_AXI_QOS_WIDTH              = 4;
    localparam MCTOP_AFU_AXI_REGION_WIDTH           = 4;
    localparam MCTOP_AFU_AXI_RESP_WIDTH             = 2;
    localparam MCTOP_AFU_AXI_SIZE_WIDTH             = 3;
    localparam MCTOP_AFU_AXI_BUSER_WIDTH            = 4;
    localparam MCTOP_AFU_AXI_AWATOP_WIDTH           = 6;

// @@copy for common_afu_pkg@@start
//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 73, A4.7, Access Permissions
//  Table A4-6 Protection Encoding    
//------------------------------------------------------------------------
    typedef enum logic [MCTOP_AFU_AXI_PROT_WIDTH-1:0] {
        eprot_MCTOP_UNPRIV_SECURE_DATA        = 3'b000,
        eprot_MCTOP_UNPRIV_SECURE_INST        = 3'b001,
        eprot_MCTOP_UNPRIV_NONSEC_DATA        = 3'b010,
        eprot_MCTOP_UNPRIV_NONSEC_INST        = 3'b011,
        eprot_MCTOP_PRIV_SECURE_DATA          = 3'b100,
        eprot_MCTOP_PRIV_SECURE_INST          = 3'b101,
        eprot_MCTOP_PRIV_NONSEC_DATA          = 3'b110,
        eprot_MCTOP_PRIV_NONSEC_INST          = 3'b111
    } t_mctop_axi4_prot_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 48, A3.4.1, Access Permissions
//  Table A3-3 Burst type encoding    
//------------------------------------------------------------------------ 
    typedef enum logic [MCTOP_AFU_AXI_BURST_WIDTH-1:0] {
        eburst_MCTOP_FIXED     = 2'b00,
        eburst_MCTOP_INCR      = 2'b01,
        eburst_MCTOP_WRAP      = 2'b10,
        eburst_MCTOP_RSVD      = 2'b11
    } t_mctop_axi4_burst_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 47, A3.4.1, Access Permissions
//  Table A3-2 Burst size encoding    
//------------------------------------------------------------------------
    typedef enum logic [MCTOP_AFU_AXI_SIZE_WIDTH-1:0] {
        esize_MCTOP_128          = 3'b100,
        esize_MCTOP_256          = 3'b101,
        esize_MCTOP_512          = 3'b110,
        esize_MCTOP_1024         = 3'b111
    } t_mctop_axi4_burst_size_encoding;

//------------------------------------------------------------------------ 
//  AXI AFU HAS, page 32
//------------------------------------------------------------------------ 
    typedef enum logic [MCTOP_AFU_AXI_QOS_WIDTH-1:0] {
        eqos_MCTOP_BEST_EFFORT           = 4'h0,
        eqos_MCTOP_USER_LOW              = 4'h4,
        eqos_MCTOP_USER_HIGH             = 4'h8,
        eqos_MCTOP_LOW_LATENCY           = 4'hC
    } t_mctop_axi4_qos_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 67
//  Table A4-5 MEMORY TYPE ENCODING
//------------------------------------------------------------------------ 
    typedef enum logic [MCTOP_AFU_AXI_CACHE_WIDTH-1:0] {
        ecache_ar_MCTOP_DEVICE_NON_BUFFERABLE                 = 4'b0000,
        ecache_ar_MCTOP_DEVICE_BUFFERABLE                     = 4'b0001,
        ecache_ar_MCTOP_NORMAL_NON_CACHEABLE_NON_BUFFERABLE   = 4'b0010,
        ecache_ar_MCTOP_NORMAL_NON_CACHEABLE_BUFFERABLE       = 4'b0011,
        ecache_ar_MCTOP_WRITE_THROUGH_NO_ALLOCATE             = 4'b1010,
        ecache_ar_MCTOP_WRITE_BACK_NO_ALLOCATE                = 4'b1011,
        ecache_ar_MCTOP_WRITE_THROUGH_READ_ALLOCATE           = 4'b1110,
        ecache_ar_MCTOP_WRITE_BACK_READ_ALLOCATE              = 4'b1111
    } t_mctop_axi4_arcache_encoding;
 
//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 67
//  Table A4-5 MEMORY TYPE ENCODING
//------------------------------------------------------------------------ 
    typedef enum logic [MCTOP_AFU_AXI_CACHE_WIDTH-1:0] {
        ecache_aw_MCTOP_DEVICE_NON_BUFFERABLE                 = 4'b0000,
        ecache_aw_MCTOP_DEVICE_BUFFERABLE                     = 4'b0001,
        ecache_aw_MCTOP_NORMAL_NON_CACHEABLE_NON_BUFFERABLE   = 4'b0010,
        ecache_aw_MCTOP_NORMAL_NON_CACHEABLE_BUFFERABLE       = 4'b0011,
        ecache_aw_MCTOP_WRITE_THROUGH_NO_ALLOCATE             = 4'b0110,
        ecache_aw_MCTOP_WRITE_BACK_NO_ALLOCATE                = 4'b0111,
        ecache_aw_MCTOP_WRITE_THROUGH_WRITE_ALLOCATE          = 4'b1110,
        ecache_aw_MCTOP_WRITE_BACK_WRITE_ALLOCATE             = 4'b1111
    } t_mctop_axi4_awcache_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 100, A7.4
//  Table A7-1 AXI3 atomic access encoding    
//------------------------------------------------------------------------ 
    typedef enum logic [MCTOP_AFU_AXI_LOCK_WIDTH-1:0] {
        elock_MCTOP_NORMAL            = 2'b00,
        elock_MCTOP_EXECLUSIVE        = 2'b01,
        elock_MCTOP_LOCKED            = 2'b10,
        elock_MCTOP_RSVD              = 2'b11
    } t_mctop_axi4_lock_encoding;

//------------------------------------------------------------------------ 
//  AMBA AXI and ACE Protocol Specitifcation, Issue 4, 2013
//  page 57, A3.4.4
//  Table A3-4 RRESP and BRESP encoding   
//------------------------------------------------------------------------ 
    typedef enum logic [MCTOP_AFU_AXI_RESP_WIDTH-1:0] {
        eresp_MCTOP_OKAY              = 2'b00,
        eresp_MCTOP_EXOKAY            = 2'b01,
        eresp_MCTOP_SLVERR            = 2'b10,
        eresp_MCTOP_DECERR            = 2'b11
    } t_mctop_axi4_resp_encoding;

//------------------------------------------------------------------------
//  write operation select - CCV AFU
//------------------------------------------------------------------------
    typedef enum logic [3:0] {
       eWR_MCTOP_I_WO              = 4'h0,  
       eWR_MCTOP_M                 = 4'h1,  
       eWR_MCTOP_I_SO              = 4'h2,  
       eWR_MCTOP_BARRIER           = 4'h3,
       eWR_MCTOP_EVICT             = 4'h4,
       eWR_MCTOP_FLUSHHOSTCACHE    = 4'h5,
       eWR_MCTOP_FLUSHDEVCACHE     = 4'h6,
       eWR_MCTOP_ILLEGAL_WREQ      = 4'hf   // can be used to test slverr
    } t_mctop_axi4_awuser_opcode;

    typedef struct packed {
      logic                  AtomicSwapIfEM;
      logic                  target_hdm;
      logic                  do_not_send_d2hreq;
      t_mctop_axi4_awuser_opcode   opcode;
    } t_mctop_axi4_awuser;

    localparam MCTOP_AFU_AXI_AWUSER_WIDTH = $bits(t_mctop_axi4_awuser);

//------------------------------------------------------------------------
// Opcode mapping on WUSER - CCV AFU
//------------------------------------------------------------------------
    typedef struct packed {
      logic        poison;
    } t_mctop_axi4_wuser;

    localparam MCTOP_AFU_AXI_WUSER_WIDTH = $bits(t_mctop_axi4_wuser);

//------------------------------------------------------------------------
//  read operation select - CCV AFU
//------------------------------------------------------------------------
    typedef enum logic [3:0] {
       eRD_MCTOP_I            = 4'h0,  
       eRD_MCTOP_S            = 4'h1,  
       eRD_MCTOP_EM           = 4'h2,  
       eRD_MCTOP_ILLEGAL_RREQ = 4'hf   // can be used to test slverr
    } t_mctop_axi4_aruser_opcode;

    typedef struct packed {
      logic                  target_hdm;
      logic                  do_not_send_d2hreq;
      t_mctop_axi4_aruser_opcode   opcode;
    } t_mctop_axi4_aruser;

    localparam MCTOP_AFU_AXI_ARUSER_WIDTH = $bits(t_mctop_axi4_aruser);

//------------------------------------------------------------------------
// Opcode mapping on RUSER - CCV AFU
//------------------------------------------------------------------------
    typedef struct packed {
      logic        AtomicSwapSuccess;
      logic        poison;
    } t_mctop_axi4_ruser;

    localparam MCTOP_AFU_AXI_RUSER_WIDTH = $bits(t_mctop_axi4_ruser);

//------------------------------------------------------------------------
// AXI input & output buses.
// AXI3 + AXI4, no ACE IO
//------------------------------------------------------------------------
    typedef logic t_mctop_axi4_wr_addr_ready;
    
    typedef struct packed {
        logic [MCTOP_AFU_AXI_MAX_ID_WIDTH-1:0]            awid;
        logic [MCTOP_AFU_AXI_MAX_ADDR_WIDTH-1:0]          awaddr; 
        logic [MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0]  awlen;
        t_mctop_axi4_burst_size_encoding                  awsize;
        t_mctop_axi4_burst_encoding                       awburst;
        t_mctop_axi4_prot_encoding                        awprot;
        t_mctop_axi4_qos_encoding                         awqos;
        logic                                       awvalid;
        t_mctop_axi4_awcache_encoding                     awcache;
        t_mctop_axi4_lock_encoding                        awlock;
        logic [MCTOP_AFU_AXI_REGION_WIDTH-1:0]            awregion;
        t_mctop_axi4_awuser                               awuser;
        logic [MCTOP_AFU_AXI_AWATOP_WIDTH-1:0]            awatop;
    } t_mctop_axi4_wr_addr_ch;

    typedef logic t_mctop_axi4_wr_data_ready;
    
    typedef struct packed {
        logic [MCTOP_AFU_AXI_MAX_DATA_WIDTH-1:0]    wdata;
        logic [MCTOP_AFU_AXI_MAX_DATA_WIDTH/8-1:0]  wstrb;
        logic                                 wlast;
        logic                                 wvalid;
        t_mctop_axi4_wuser             		 	  wuser;  
    } t_mctop_axi4_wr_data_ch;

    typedef logic t_mctop_axi4_wr_resp_ready;
    
    typedef struct packed {
        logic [MCTOP_AFU_AXI_MAX_ID_WIDTH-1:0]  bid;
        t_mctop_axi4_resp_encoding              bresp;
        logic                             bvalid;
        logic [MCTOP_AFU_AXI_BUSER_WIDTH-1:0]   buser;
    } t_mctop_axi4_wr_resp_ch;

    typedef logic t_mctop_axi4_rd_addr_ready;
    
    typedef struct packed {
        logic [MCTOP_AFU_AXI_MAX_ID_WIDTH-1:0]            arid;
        logic [MCTOP_AFU_AXI_MAX_ADDR_WIDTH-1:0]          araddr;
        logic [MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0]  arlen;
        t_mctop_axi4_burst_size_encoding                  arsize;
        t_mctop_axi4_burst_encoding                       arburst;
        t_mctop_axi4_prot_encoding                        arprot;
        t_mctop_axi4_qos_encoding                         arqos;
        logic                                       arvalid;
        t_mctop_axi4_arcache_encoding                     arcache;
        t_mctop_axi4_lock_encoding                        arlock;
        logic [MCTOP_AFU_AXI_REGION_WIDTH-1:0]            arregion;
        t_mctop_axi4_aruser                               aruser;
    } t_mctop_axi4_rd_addr_ch;

    typedef logic t_mctop_axi4_rd_resp_ready;
    
    typedef struct packed {
        logic [MCTOP_AFU_AXI_MAX_ID_WIDTH-1:0]        rid;
        logic [MCTOP_AFU_AXI_MAX_DATA_WIDTH-1:0]      rdata;
        t_mctop_axi4_resp_encoding                    rresp;
        logic                                   rlast;
        logic                                   rvalid;
        t_mctop_axi4_ruser                            ruser;
    } t_mctop_axi4_rd_resp_ch;
    
    localparam MCTOP_AFU_AXI_WR_ADDR_CH_WIDTH = $bits(t_mctop_axi4_wr_addr_ch);
    localparam MCTOP_AFU_AXI_WR_DATA_CH_WIDTH = $bits(t_mctop_axi4_wr_data_ch);
    localparam MCTOP_AFU_AXI_WR_RESP_CH_WIDTH = $bits(t_mctop_axi4_wr_resp_ch);
    localparam MCTOP_AFU_AXI_RD_ADDR_CH_WIDTH = $bits(t_mctop_axi4_rd_addr_ch);
    localparam MCTOP_AFU_AXI_RD_RESP_CH_WIDTH = $bits(t_mctop_axi4_rd_resp_ch);

//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//

// parameters and structs copied from CXLIP for the MCTOP-to-CAFU AXI interface

// @@copy for common_mctop_pkg@@start
// @@copy for common_afu_pkg@@start
  localparam MCTOP_MC_AXI_WAC_REGION_BW  =  4; // awregion
  localparam MCTOP_MC_AXI_WAC_ADDR_BW    = 52; // awaddr  - using bits 51:6 of 64-bits, also grabbing the lower 6 bits?
  localparam MCTOP_MC_AXI_WAC_USER_BW    =  1; // awuser
  localparam MCTOP_MC_AXI_WAC_ID_BW      =  8; // awid    - feb2024 - changed from 12
  localparam MCTOP_MC_AXI_WAC_BLEN_BW    = 10; // awlen
  
  localparam MCTOP_MC_AXI_WDC_DATA_BW = 512; // wwdata
  localparam MCTOP_MC_AXI_WDC_USER_BW =  1;  // wuser  // currently only poison
  
  localparam MCTOP_MC_AXI_WDC_STRB_BW = MCTOP_MC_AXI_WDC_DATA_BW / 8; // wstrb
  
  localparam MCTOP_MC_AXI_WRC_ID_BW   =  8; // bid   - feb2024 - changed from 12
  localparam MCTOP_MC_AXI_WRC_USER_BW =  1; // buser
  
  localparam MCTOP_MC_AXI_RAC_REGION_BW  =  4; // arregion
  localparam MCTOP_MC_AXI_RAC_ID_BW      =  8; // arid    - feb2024 - changed from 12
  localparam MCTOP_MC_AXI_RAC_ADDR_BW    = 52; // araddr  - using bits 51:6 of 64-bits, also grabbing the lower 6 bits?
  localparam MCTOP_MC_AXI_RAC_BLEN_BW    = 10; // arlen
  localparam MCTOP_MC_AXI_RAC_USER_BW    =  1; // aruser
  
  localparam MCTOP_MC_AXI_RRC_ID_BW        =   8; // rid   - feb2024 - changed from 12
  localparam MCTOP_MC_AXI_RRC_DATA_BW      = 512; // rdata
  localparam MCTOP_MC_EMIF_AMM_RRC_DATA_BW = 576; // rdata from EMIF AMM.

// ================================================================================================
// struct for read response channel response field
// ================================================================================================
  typedef struct packed {
	logic poison;
  } t_rd_rsp_user_mctop;

  localparam MCTOP_MC_AXI_RRC_USER_BW = $bits( t_rd_rsp_user_mctop );
  
// ================================================================================================
// AXI signals from BBS to MC
// ================================================================================================
  typedef struct packed {
    t_mctop_axi4_wr_resp_ready   bready;
    t_mctop_axi4_rd_resp_ready   rready;
	
	logic [MCTOP_MC_AXI_WAC_ID_BW-1:0]                 awid;
	logic [MCTOP_MC_AXI_WAC_ADDR_BW-1:0]               awaddr;
	logic [MCTOP_MC_AXI_WAC_BLEN_BW-1:0]               awlen;
	t_mctop_axi4_burst_size_encoding   awsize;
	t_mctop_axi4_burst_encoding        awburst;
	t_mctop_axi4_prot_encoding         awprot;
	t_mctop_axi4_qos_encoding          awqos;
	logic                                        awvalid;
	t_mctop_axi4_awcache_encoding      awcache;
	t_mctop_axi4_lock_encoding         awlock;
	logic [MCTOP_MC_AXI_WAC_REGION_BW-1:0]             awregion;
	logic [MCTOP_MC_AXI_WAC_USER_BW-1:0]               awuser;
	
    logic [MCTOP_MC_AXI_WDC_DATA_BW-1:0] wdata;
	logic [MCTOP_MC_AXI_WDC_STRB_BW-1:0] wstrb;
	logic                          wlast;
	logic                          wvalid;
	logic [MCTOP_MC_AXI_WDC_USER_BW-1:0] wuser; // currently only poison
	
	logic [MCTOP_MC_AXI_RAC_ID_BW-1:0]                 arid;
	logic [MCTOP_MC_AXI_RAC_ADDR_BW-1:0]               araddr;
	logic [MCTOP_MC_AXI_RAC_BLEN_BW-1:0]               arlen;
    t_mctop_axi4_burst_size_encoding   arsize;
    t_mctop_axi4_burst_encoding        arburst;
    t_mctop_axi4_prot_encoding         arprot;
    t_mctop_axi4_qos_encoding          arqos;
	logic                                        arvalid;
    t_mctop_axi4_arcache_encoding      arcache;
    t_mctop_axi4_lock_encoding         arlock;
    logic [MCTOP_MC_AXI_RAC_REGION_BW-1:0]             arregion;
    logic [MCTOP_MC_AXI_RAC_USER_BW-1:0]               aruser;
  } t_to_mctop_axi4;
  
  localparam TO_MC_AXI4_BW = $bits(t_to_mctop_axi4);
  
// ================================================================================================
  typedef struct packed {
    t_mctop_axi4_wr_addr_ready   awready;
    t_mctop_axi4_wr_data_ready    wready;
    t_mctop_axi4_rd_addr_ready   arready;
	
	logic [MCTOP_MC_AXI_WRC_ID_BW-1:0]           bid;
	t_mctop_axi4_resp_encoding   bresp;
	logic                                  bvalid;
	logic [MCTOP_MC_AXI_WRC_USER_BW-1:0]         buser;
	
	logic [MCTOP_MC_AXI_RRC_ID_BW-1:0]           rid;
	logic [MCTOP_MC_AXI_RRC_DATA_BW-1:0]         rdata;
	t_mctop_axi4_resp_encoding   rresp;
	logic                                  rvalid;
	logic                                  rlast;
    //logic [MCTOP_MC_AXI_RRC_USER_BW-1:0]         ruser;
	t_rd_rsp_user_mctop                          ruser;
  } t_from_mctop_axi4;
  
  localparam MCTOP_FROM_MC_AXI4_BW = $bits(t_from_mctop_axi4);
  localparam MCTOP_FROM_MC_AXI4_BW_PARM = $bits(t_from_mctop_axi4);
// @@copy for common_afu_pkg@@end

// ================================================================================================
  typedef struct packed {
        t_mctop_axi4_rd_addr_ready   arready;
        logic                                  rd_id_fifo_almost_full;

        logic [MCTOP_MC_AXI_RRC_ID_BW-1:0]           rid;
        logic [MCTOP_MC_EMIF_AMM_RRC_DATA_BW-1:0]    rdata;
        t_mctop_axi4_resp_encoding   rresp;
        logic                                  rvalid;
        logic                                  rlast;
    //logic [MCTOP_MC_AXI_RRC_USER_BW-1:0]         ruser;
        t_rd_rsp_user_mctop                          ruser;
  } t_from_mctop_axi4_rchan;

  localparam MCTOP_FROM_MC_AXI4_RCHAN_BW = $bits(t_from_mctop_axi4_rchan);

// ================================================================================================
  typedef struct packed {

    t_mctop_axi4_wr_addr_ready   awready;
    t_mctop_axi4_wr_data_ready    wready;

        logic [MCTOP_MC_AXI_WRC_ID_BW-1:0]           bid;
        t_mctop_axi4_resp_encoding   bresp;
        logic                                  bvalid;
        logic [MCTOP_MC_AXI_WRC_USER_BW-1:0]         buser;
  } t_from_mctop_axi4_bchan;

  localparam MCTOP_FROM_MC_AXI4_BCHAN_BW = $bits(t_from_mctop_axi4_bchan);

  // ================================================================================================
  typedef struct packed {
    logic [MCTOP_MC_AXI_RRC_ID_BW-1:0]           rid;
    logic [MCTOP_MC_AXI_RRC_DATA_BW-1:0]         rdata;
    t_mctop_axi4_resp_encoding   rresp;
    logic                                  rvalid;
	  logic                                rlast;
    t_rd_rsp_user_mctop                          ruser;
  } t_mctop_rdrsp_axi4;

//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//


// parameters and structs from the mc_local_axi_if_pkg created in q24p1, q24p2


localparam MC_LOCAL_AXI_WAC_ID_BW = 9; // write addr chan
localparam MC_LOCAL_AXI_WRC_ID_BW = 9; // write resp chan
localparam MC_LOCAL_AXI_RAC_ID_BW = 9; //  read addr chan
localparam MC_LOCAL_AXI_RRC_ID_BW = 9; //  read resp chan


// a copy of the wr rsp channel from MC<=>CXLIP axi struct
typedef struct packed {
    logic [MC_LOCAL_AXI_WRC_ID_BW-1:0]   bid;
    t_mctop_axi4_resp_encoding           bresp;
    logic                                bvalid;
    logic [MCTOP_MC_AXI_WRC_USER_BW-1:0] buser;
} t_from_mc_local_axi4_bchan;

localparam FROM_MC_LOCAL_AXI4_BCHAN_BW = $bits(t_from_mc_local_axi4_bchan);


// a copy of the rd rsp channel from MC<=>CXLIP axi struct
typedef struct packed {
    t_mctop_axi4_rd_addr_ready   arready;
    logic                                     rd_id_fifo_almost_full;
    logic [MC_LOCAL_AXI_RRC_ID_BW-1:0]        rid;
    logic [MCTOP_MC_EMIF_AMM_RRC_DATA_BW-1:0] rdata;
    t_mctop_axi4_resp_encoding                rresp;
    logic                                     rvalid;
    logic                                     rlast;
    t_rd_rsp_user_mctop                       ruser;
} t_from_mc_local_axi4_rchan;

localparam FROM_MC_LOCAL_AXI4_RCHAN_BW = $bits(t_from_mc_local_axi4_rchan);


//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//
// the struct representing all rd and wr requests into the memory controller
typedef struct packed {
     logic                                 write;
     logic                                 partial_write;
     logic                                 read;
     logic [MC_LOCAL_AXI_WAC_ID_BW-1:0]    wr_id;
     logic [MC_LOCAL_AXI_RAC_ID_BW-1:0]    rd_id;
     logic [MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] address;
     logic [MCTOP_MC_MDATA_WIDTH-1:0]      req_mdata;
     logic                                 write_ras_sbe;
     logic                                 write_ras_dbe;
     logic                                 write_poison;
     logic [MCTOP_MC_HA_DP_BE_WIDTH-1:0]   byteenable;
     logic [MCTOP_MC_HA_DP_DATA_WIDTH-1:0] writedata;
} t_reqfifo_data;

localparam MC_LOCAL_REQFIFO_DATA_BW = $bits(t_reqfifo_data);


// struct representing all rd and wr requests into the memory controllers cdc_reqfifo
// this struct used after the read-modified-write block
// no longer need : partial_write, byteenable
//
typedef struct packed {
     logic                                 write;
     logic                                 read;
     logic [MC_LOCAL_AXI_WAC_ID_BW-1:0]    wr_id;
     logic [MC_LOCAL_AXI_RAC_ID_BW-1:0]    rd_id;
     logic [MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] address;
     logic [MCTOP_MC_MDATA_WIDTH-1:0]      req_mdata;
     logic                                 write_ras_sbe;
     logic                                 write_ras_dbe;
     logic                                 write_poison;
     logic [MCTOP_MC_HA_DP_DATA_WIDTH-1:0] writedata;
} t_reqfifo_data_postRMW_preECC;

localparam MC_LOCAL_REQFIFO_POSTRMW_DATA_BW = $bits(t_reqfifo_data_postRMW_preECC);


// the struct representing all rd and wr requests into the memory controller
// after the request has left the fifo and error-correction-code (ecc) has been encoded into wuser
// write data is 512 bits
typedef struct packed {
     logic                                 write;
     logic                                 read;
     logic [MC_LOCAL_AXI_WAC_ID_BW-1:0]    wr_id;
     logic [MC_LOCAL_AXI_RAC_ID_BW-1:0]    rd_id;
     logic [MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] address;
     logic [MCTOP_MC_HA_DP_DATA_WIDTH-1:0] writedata;
     logic [7:0][7:0]                      wuser_ecc;
} t_reqfifo_data_post_ecc_axi;


// the struct representing all rd and wr requests into the memory controller
// after the request has left the fifo and error-correction-code (ecc) has been encoded into writedata
// write data is 576 bits
typedef struct packed {
     logic                                 write;
     logic                                 read;
     logic                                 write_poison;
     logic [MC_LOCAL_AXI_WAC_ID_BW-1:0]    wr_id;
     logic [MC_LOCAL_AXI_RAC_ID_BW-1:0]    rd_id;
     logic [MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] address;
     logic [MCTOP_EMIF_AMM_DATA_WIDTH-1:0] writedata;
} t_reqfifo_data_post_ecc_avmm;


//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//
// the struct representing all rd rsp through the memory controller
typedef struct packed {
   logic [MCTOP_MC_AXI_WDC_DATA_BW-1:0] read_data;
   logic [MC_LOCAL_AXI_RRC_ID_BW-1:0]   read_id;
   logic                                read_poison;
   t_mctop_axi4_resp_encoding           read_axi_resp;
   logic                                read_resp_valid;
} t_rchan_rspfifo_data;

localparam MC_LOCAL_RHCAN_RSPFIFO_DATA_BW = $bits(t_rchan_rspfifo_data);


// the struct representing the ecc of all rd rsp through the memory controller
typedef struct packed {
   logic [MCTOP_ALTECC_INST_NUMBER-1:0] ecc_err_corrected;
   logic [MCTOP_ALTECC_INST_NUMBER-1:0] ecc_err_detected;
   logic [MCTOP_ALTECC_INST_NUMBER-1:0] ecc_err_fatal;
   logic [MCTOP_ALTECC_INST_NUMBER-1:0] ecc_err_syn_e;
   logic                                ecc_err_valid;
} t_rchan_rspfifo_ecc;

localparam MC_LOCAL_RHCAN_RSPFIFO_ECC_BW = $bits(t_rchan_rspfifo_ecc);


// struct of structs for storing rsp data and ecc in the rspfifo
typedef struct packed {
   t_rchan_rspfifo_data     read_rsp_intf;
   t_rchan_rspfifo_ecc      read_ecc_intf;
} t_rchan_rspfifo;

localparam MC_LOCAL_RHCAN_RSPFIFO_BW = $bits(t_rchan_rspfifo);


// the struct representing all wr rsp through the memory controller
typedef struct packed {
   logic [MCTOP_MC_AXI_WRC_USER_BW-1:0] write_user;
   logic [MC_LOCAL_AXI_WRC_ID_BW-1:0]   write_id;
   t_mctop_axi4_resp_encoding           write_axi_resp;
   logic                                write_resp_valid;
} t_bchan_rspfifo_data;

localparam MC_LOCAL_BHCAN_RSPFIFO_DATA_BW = $bits(t_bchan_rspfifo_data);


//
// INTEL PSG INTERNAL USE : DO NOT EDIT THIS AUTO-GENERATED, VERSION CONTROLLED FILE
// Please goto <MODEL_ROOT/scripts and run 'python gen_memory_controller_common_pkg.py'
//   to run the script that updates this version controlled file
// Please check in updated file.
//
typedef struct packed {
   logic clear_write_valid;
   logic clear_read_valid;
   logic mem_ready;
} t_emif_fsm_cntrl_to_ecc;


endpackage : ddr_mc_top_common_pkg
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL64bTGEFcZGjIzaHuqrrW1DYJ2496NzqgEUFxPaQ3b1Kf/usJPaDUDjRdKpF3Z1Kbw2lOWoaiOc5leic3A54/YFhEDfeD6Hs4YC0d0L0nSz3JKNtwkZp97fetPau6aKSWP02enRDnfSDEFyLXnETMtM43YFKiyw9jWxIKVEsjIaFzY0NY2PAhZFGlgLeEdZSIt719wv/17XKoP4ImIrXFtPehfm515CKH3gPhMyPyGoFKKT3hhuvAmIcwwBsmalujHffv05MVy/MTp61zgwce6NVrwlt1u00vdJU/o9GCqUMiTcPJn8iZW0+3wkh6st0wxQdWlD1xWgmI6sI0kSFF0CASUQprERE6Zj6mXJ/JyD20h2HwfPjmLXQKFU2x13duoqNWajqfnIapvcNQ7yl1LMTBlFcFQpJw7sbBK6aaSCrSTELA+dqad1A58uZn+WqlSoTi7SPmG8zrgfbTt4tTo1c9S7ff2zM4M7zQhP5kqoq/4d0S+w4RA4uKxdgcSnB2PrPilfBFjmNyMmGfPrjGNfQLQFSkvZv5sQp5fWudiW/x5UoPraLyW2Kqcj9792YbQutdFmpkn9BeN+o/t0lZ/kANaKcO0s4UPbpObDLm7vM9FHZgfpQxhtMG76gdihhsQ5WmcVWDCnvoWBvkXgwby35XFDutZnK7K3B+9e7xhzxRkWYWBjiVBU14ibCfW33XswZatk34BiR/LJOKOYjQPTYqITrJwwZ9I+R5zYQmoMpKD21IfBmdNL7RD5705/TzCgIS3q/k0/pGf2l+FCyE6u"
`endif
