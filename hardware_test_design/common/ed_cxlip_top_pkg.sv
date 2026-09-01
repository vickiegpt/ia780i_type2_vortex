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


// Copyright 2023 Intel Corporation.
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

`include "cxl_ed_defines.svh.iv"

package ed_cxlip_top_pkg;
 import cafu_common_pkg::*;

// To help simplify setting proper widths for signals connected to mc_top, various mc_top
// parameters are pulled out and defined here and then used as mc_top parameter inputs.


//-----------------------NOTE---------------------------------------
// below parameter values are defined for HDM_16G
// parameters will vary based on EMIF IP configurations
//------------------------------------------------------------------



`ifdef ENABLE_4_SLICE
localparam MC_CHANNEL                = cafu_common_pkg::CAFU_MC_CHANNEL ;  //4;  
localparam DDR_CHANNEL               = 2;  //MC_TOP: MC_CHANNEL;
localparam NUM_MC_TOP                = 2;  //MC_TOP: MC_CHANNEL;
`elsif ENABLE_1_SLICE
localparam MC_CHANNEL                = cafu_common_pkg::CAFU_MC_CHANNEL ; //1;  
localparam DDR_CHANNEL               = 1;  //MC_TOP: MC_CHANNEL;
localparam NUM_MC_TOP                = 1;  //MC_TOP: MC_CHANNEL;
`else
localparam MC_CHANNEL                = cafu_common_pkg::CAFU_MC_CHANNEL  ; //2;  
localparam DDR_CHANNEL               = 2;  //MC_TOP: MC_CHANNEL;
localparam NUM_MC_TOP                = 1;  //MC_TOP: MC_CHANNEL;
`endif
localparam MC_HA_DDR4_ADDR_WIDTH     = 17; 
localparam MC_HA_DDR4_BA_WIDTH       = 2;  
localparam MC_HA_DDR4_BG_WIDTH       = 2;  
localparam MC_HA_DDR4_CK_WIDTH       = 1;  
`ifdef IA780I
  localparam MC_HA_DDR4_DQ_WIDTH       = 64;
  localparam MC_HA_DDR4_DQS_WIDTH      = 8;
  localparam MC_HA_DDR4_DBI_WIDTH      = 8;
`elsif ENABLE_DDR_DBI_PINS
  localparam MC_HA_DDR4_DQ_WIDTH       = 72;
  localparam MC_HA_DDR4_DQS_WIDTH      = 9;
  localparam MC_HA_DDR4_DBI_WIDTH      = 9;
`else
  localparam MC_HA_DDR4_DQ_WIDTH       = 72;
  localparam MC_HA_DDR4_DQS_WIDTH      = 18;
`endif

`ifdef HDM_64G
  localparam EMIF_AMM_ADDR_WIDTH       = 29;
  localparam MC_HA_DDR4_CKE_WIDTH      = 2;  
  localparam MC_HA_DDR4_CS_WIDTH       = 2;  
  localparam MC_HA_DDR4_ODT_WIDTH      = 2;  
`else
  localparam EMIF_AMM_ADDR_WIDTH       = 27;
  localparam MC_HA_DDR4_CKE_WIDTH      = 1;  
  localparam MC_HA_DDR4_CS_WIDTH       = 1;  
  localparam MC_HA_DDR4_ODT_WIDTH      = 1;  
`endif

localparam EMIF_AMM_BURST_WIDTH     = 7;
`ifdef IA780I
localparam EMIF_AMM_DATA_WIDTH      = 512;
localparam EMIF_AMM_BE_WIDTH        = 64;
`else
localparam EMIF_AMM_DATA_WIDTH      = 576;
localparam EMIF_AMM_BE_WIDTH        = 72;
`endif
localparam REG_ON_REQFIFO_INPUT_EN  = 0;
localparam REG_ON_REQFIFO_OUTPUT_EN = 1;
localparam REG_ON_RSPFIFO_OUTPUT_EN = 1;

localparam MC_HA_DP_ADDR_WIDTH       = 46;  // 46 supports full cxl addr width [51:6]
localparam MC_HA_DP_DATA_WIDTH       = 512;
`ifdef IA780I
localparam MC_ECC_EN                 = 0;
`else
localparam MC_ECC_EN                 = 1;
`endif
localparam MC_ECC_ENC_LATENCY        = 1;
localparam MC_ECC_DEC_LATENCY        = 1;
localparam MC_RAM_INIT_W_ZERO_EN     = 1;
localparam MEMSIZE_WIDTH             = 64;

// These mc_top parameters are defined in mc_top as localparam.  Therefore, these localparam values
// can not be used as mc_top parameter inputs.  They are copied here to ensure the related signal
// widths are in sync with mc_top.
localparam MC_MDATA_WIDTH            = 14;
localparam MC_SR_STAT_WIDTH          = 5;
localparam MC_HA_DP_BITS_PER_SYMBOL  = 8;
localparam MC_HA_DP_BE_WIDTH = MC_HA_DP_DATA_WIDTH / MC_HA_DP_BITS_PER_SYMBOL;
localparam REQFIFO_DEPTH_WIDTH       = 6;
localparam RSPFIFO_DEPTH_WIDTH       = 6;
     // ==== ALTECC ====
localparam ALTECC_DATAWORD_WIDTH = 64;
localparam ALTECC_WIDTH_CODEWORD = 72;
localparam ALTECC_INST_NUMBER    = MC_HA_DP_DATA_WIDTH / ALTECC_DATAWORD_WIDTH;


// Specify lsb/msb for cxl-ip output cxlip2iafu_address_eclk.
// Set to full cxl addr width (addr[51:6]).
localparam CXLIP_FULL_ADDR_LSB = 6;
localparam CXLIP_FULL_ADDR_MSB = 51;

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

//localparam CXLIP_CHAN_ADDR_LSB = 6;
localparam CXLIP_CHAN_ADDR_LSB = (MC_CHANNEL == 4) ? 8 : ((MC_CHANNEL == 2) ? 7 : 6);
localparam CXLIP_CHAN_ADDR_MSB = CXLIP_CHAN_ADDR_LSB + (EMIF_AMM_ADDR_WIDTH - 1);


endpackage
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "wJaiUQVZA/rvovcoNOJGlBO6DCGE7ABmqgUXUj8zOr5pW/RmuJpy7vfokaAGTtwq7+XXhIASoNO8/1w9gnglJEDZAsQE6bSIxKANtOiBndjIysDudBOHQoche6DbKrf0181Y+vNClaBJNBy9zgI5I3EE0VBTuEeshhmDbDjf57ZnCzhiTrhBeqKS6mAbx69qZGB02C/X/b0jY2bRWmm+DMoF7+OPN51M+D5t4T3g+aJ0/E+H8jHXJ39UFBMZsw3l0ik/xF1gSyGhaCV60WB+G7rccgU5S9lb1gEldZpRx1NN6Cq2CJRiaya8CTQa88b/FCPOL191Cl6AlFooNi11w7aEIEGQo4L9gM1NF5tK0SnqjTFrVXOmbXg1GAPDZ08tRmZtjsIogmPiW8mq0vdJIebjQ/0tsIeMrOmqJiTWf29IIaPjsGI8cEo4cYrKtQirgw6lLanwZrxV4irE7oUiIJ71nXvtCZBB8jkjFsg+CAUXKRqO3LDdNBpIGB5DbOZ/3eq+NMK7PM5Ng9rsQHNreVfEZ5rhkyj37tf+YElSVNDs3HYtBFQQrgmxg3+k/VmBz/6YHASTya7nplKxpOugmtvVhbls70BcqW0ghOtOfoU+sr6IMUyYdK8AK04XN2/WJRic+QIgzO8GwrY645c4s6djIpu4WspmLRj0HYejJretZPm6xocZ3exqMhiGj3ByCYyUWGz+xtE9/Q3XGBBcoO4cNtZxSDdA6tgwGGJSIKTdHISTEpDG1wyWIwDEMDt1K06Tp7kHoGU0XLsgtth/ZWgVdVfErXm4s20rpn2jPw6tyxpzDBK2JTfwKvqzAYSfGmkEekx1o6pzC2zaEmQGKviFSazGZqOkfXQQXzyl9l8AsOwVznMELT3Q3FjCLVplc/s7QAfYRYsdobgbZbhN2MZMJk9nIPe+B+575slltX/L7JqWrPQMXE7PBAVfUhyhxcSkIfXryJlc8cg5+XL7tVL8wEdCDG6l/eF32GM2lUh6IKM4CQKlqQHd0kEtsB/u"
`endif
