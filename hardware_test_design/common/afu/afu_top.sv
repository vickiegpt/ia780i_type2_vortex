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




`include "vortex/VX_define.vh"

module afu_top

import ddr_mc_top_common_pkg::*;
import cxl_memuring_vortex_pkg::*;
(
    
`ifdef ENABLE_1_SLICE   

    output  logic  [4:0]     mc2ip_0_sr_status,               //HDM controller status
//Channel-0
     /* write address channel
      */
  input logic          ip2hdm_aximm0_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm0_awid       ,       
  input logic  [51:0]  ip2hdm_aximm0_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm0_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm0_awregion   ,       
  input logic          ip2hdm_aximm0_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm0_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm0_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm0_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm0_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm0_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm0_awlock     ,      
  output  logic          hdm2ip_aximm0_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm0_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm0_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm0_wstrb      ,           
  input logic          ip2hdm_aximm0_wlast      ,           
  input logic          ip2hdm_aximm0_wuser      ,           
  output logic           hdm2ip_aximm0_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm0_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm0_bid        ,
  output  logic          hdm2ip_aximm0_buser      ,
  output  logic [1:0]    hdm2ip_aximm0_bresp      ,
  input logic          ip2hdm_aximm0_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm0_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm0_arid       ,         
  input logic  [51:0]  ip2hdm_aximm0_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm0_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm0_arregion   ,         
  input logic          ip2hdm_aximm0_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm0_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm0_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm0_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm0_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm0_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm0_arlock     ,         
  output logic          hdm2ip_aximm0_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm0_rvalid     , 
  output  logic          hdm2ip_aximm0_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm0_rid        ,
  output  logic  [511:0] hdm2ip_aximm0_rdata      ,
  output  logic          hdm2ip_aximm0_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm0_rresp      ,
  input   logic          ip2hdm_aximm0_rready    ,     
	


`elsif ENABLE_4_SLICE   // MC_CHANNEL=4

  output  logic  [4:0]     mc2ip_0_sr_status,               //HDM controller status
  output  logic  [4:0]     mc2ip_1_sr_status,               //HDM controller status
  output  logic  [4:0]     mc2ip_2_sr_status,               //HDM controller status
  output  logic  [4:0]     mc2ip_3_sr_status,               //HDM controller status
//Channel-0
     /* write address channel
      */
  input logic          ip2hdm_aximm0_awvalid    ,       
  input logic  [7:0]   ip2hdm_aximm0_awid       ,       
  input logic  [51:0]  ip2hdm_aximm0_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm0_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm0_awregion   ,       
  input logic          ip2hdm_aximm0_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm0_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm0_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm0_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm0_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm0_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm0_awlock     ,      
  output  logic          hdm2ip_aximm0_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm0_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm0_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm0_wstrb      ,           
  input logic          ip2hdm_aximm0_wlast      ,           
  input logic          ip2hdm_aximm0_wuser      ,           
  output logic           hdm2ip_aximm0_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm0_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm0_bid        ,
  output  logic          hdm2ip_aximm0_buser      ,
  output  logic [1:0]    hdm2ip_aximm0_bresp      ,
  input logic          ip2hdm_aximm0_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm0_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm0_arid       ,         
  input logic  [51:0]  ip2hdm_aximm0_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm0_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm0_arregion   ,         
  input logic          ip2hdm_aximm0_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm0_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm0_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm0_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm0_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm0_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm0_arlock     ,         
  output logic          hdm2ip_aximm0_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm0_rvalid     , 
  output  logic          hdm2ip_aximm0_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm0_rid        ,
  output  logic  [511:0] hdm2ip_aximm0_rdata      ,
  output  logic          hdm2ip_aximm0_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm0_rresp      ,
  input   logic          ip2hdm_aximm0_rready    ,     
	

//Channel-1
     /* write address channel
      */
  input logic          ip2hdm_aximm1_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm1_awid       ,       
  input logic  [51:0]  ip2hdm_aximm1_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm1_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm1_awregion   ,       
  input logic          ip2hdm_aximm1_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm1_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm1_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm1_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm1_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm1_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm1_awlock     ,      
  output  logic          hdm2ip_aximm1_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm1_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm1_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm1_wstrb      ,           
  input logic          ip2hdm_aximm1_wlast      ,           
  input logic          ip2hdm_aximm1_wuser      ,           
  output logic           hdm2ip_aximm1_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm1_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm1_bid        ,
  output  logic          hdm2ip_aximm1_buser      ,
  output  logic [1:0]    hdm2ip_aximm1_bresp      ,
  input logic          ip2hdm_aximm1_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm1_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm1_arid       ,         
  input logic  [51:0]  ip2hdm_aximm1_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm1_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm1_arregion   ,         
  input logic          ip2hdm_aximm1_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm1_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm1_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm1_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm1_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm1_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm1_arlock     ,         
  output logic          hdm2ip_aximm1_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm1_rvalid     , 
  output  logic          hdm2ip_aximm1_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm1_rid        ,
  output  logic  [511:0] hdm2ip_aximm1_rdata      ,
  output  logic          hdm2ip_aximm1_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm1_rresp      ,
  input   logic          ip2hdm_aximm1_rready    ,  
    

//Channel-2
     /* write address channel
      */
  input logic          ip2hdm_aximm2_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm2_awid       ,       
  input logic  [51:0]  ip2hdm_aximm2_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm2_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm2_awregion   ,       
  input logic          ip2hdm_aximm2_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm2_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm2_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm2_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm2_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm2_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm2_awlock     ,      
  output  logic          hdm2ip_aximm2_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm2_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm2_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm2_wstrb      ,           
  input logic          ip2hdm_aximm2_wlast      ,           
  input logic          ip2hdm_aximm2_wuser      ,           
  output logic           hdm2ip_aximm2_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm2_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm2_bid        ,
  output  logic          hdm2ip_aximm2_buser      ,
  output  logic [1:0]    hdm2ip_aximm2_bresp      ,
  input logic          ip2hdm_aximm2_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm2_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm2_arid       ,         
  input logic  [51:0]  ip2hdm_aximm2_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm2_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm2_arregion   ,         
  input logic          ip2hdm_aximm2_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm2_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm2_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm2_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm2_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm2_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm2_arlock     ,         
  output logic          hdm2ip_aximm2_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm2_rvalid     , 
  output  logic          hdm2ip_aximm2_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm2_rid        ,
  output  logic  [511:0] hdm2ip_aximm2_rdata      ,
  output  logic          hdm2ip_aximm2_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm2_rresp      ,
  input   logic          ip2hdm_aximm2_rready     ,

//Channel-3
     /* write address channel
      */
  input logic          ip2hdm_aximm3_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm3_awid       ,       
  input logic  [51:0]  ip2hdm_aximm3_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm3_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm3_awregion   ,       
  input logic          ip2hdm_aximm3_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm3_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm3_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm3_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm3_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm3_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm3_awlock     ,      
  output  logic          hdm2ip_aximm3_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm3_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm3_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm3_wstrb      ,           
  input logic          ip2hdm_aximm3_wlast      ,           
  input logic          ip2hdm_aximm3_wuser      ,           
  output logic           hdm2ip_aximm3_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm3_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm3_bid        ,
  output  logic          hdm2ip_aximm3_buser      ,
  output  logic [1:0]    hdm2ip_aximm3_bresp      ,
  input logic          ip2hdm_aximm3_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm3_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm3_arid       ,         
  input logic  [51:0]  ip2hdm_aximm3_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm3_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm3_arregion   ,         
  input logic          ip2hdm_aximm3_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm3_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm3_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm3_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm3_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm3_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm3_arlock     ,         
  output logic          hdm2ip_aximm3_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm3_rvalid     , 
  output  logic          hdm2ip_aximm3_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm3_rid        ,
  output  logic  [511:0] hdm2ip_aximm3_rdata      ,
  output  logic          hdm2ip_aximm3_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm3_rresp      ,
  input   logic          ip2hdm_aximm3_rready   ,  
  

   `else

  output  logic  [4:0]     mc2ip_0_sr_status,               //HDM controller status
  output  logic  [4:0]     mc2ip_1_sr_status,               //HDM controller status
//Channel-0
     /* write address channel
      */
  input logic          ip2hdm_aximm0_awvalid    ,       
  input logic  [7:0]   ip2hdm_aximm0_awid       ,       
  input logic  [51:0]  ip2hdm_aximm0_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm0_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm0_awregion   ,       
  input logic          ip2hdm_aximm0_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm0_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm0_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm0_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm0_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm0_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm0_awlock     ,      
  output  logic          hdm2ip_aximm0_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm0_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm0_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm0_wstrb      ,           
  input logic          ip2hdm_aximm0_wlast      ,           
  input logic          ip2hdm_aximm0_wuser      ,           
  output logic           hdm2ip_aximm0_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm0_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm0_bid        ,
  output  logic          hdm2ip_aximm0_buser      ,
  output  logic [1:0]    hdm2ip_aximm0_bresp      ,
  input logic          ip2hdm_aximm0_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm0_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm0_arid       ,         
  input logic  [51:0]  ip2hdm_aximm0_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm0_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm0_arregion   ,         
  input logic          ip2hdm_aximm0_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm0_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm0_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm0_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm0_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm0_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm0_arlock     ,         
  output logic          hdm2ip_aximm0_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm0_rvalid     , 
  output  logic          hdm2ip_aximm0_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm0_rid        ,
  output  logic  [511:0] hdm2ip_aximm0_rdata      ,
  output  logic          hdm2ip_aximm0_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm0_rresp      ,
  input   logic          ip2hdm_aximm0_rready    ,     
	

//Channel-1
     /* write address channel
      */
  input logic          ip2hdm_aximm1_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm1_awid       ,       
  input logic  [51:0]  ip2hdm_aximm1_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm1_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm1_awregion   ,       
  input logic          ip2hdm_aximm1_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm1_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm1_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm1_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm1_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm1_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm1_awlock     ,      
  output  logic          hdm2ip_aximm1_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm1_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm1_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm1_wstrb      ,           
  input logic          ip2hdm_aximm1_wlast      ,           
  input logic          ip2hdm_aximm1_wuser      ,           
  output logic           hdm2ip_aximm1_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm1_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm1_bid        ,
  output  logic          hdm2ip_aximm1_buser      ,
  output  logic [1:0]    hdm2ip_aximm1_bresp      ,
  input logic          ip2hdm_aximm1_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm1_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm1_arid       ,         
  input logic  [51:0]  ip2hdm_aximm1_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm1_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm1_arregion   ,         
  input logic          ip2hdm_aximm1_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm1_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm1_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm1_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm1_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm1_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm1_arlock     ,         
  output logic          hdm2ip_aximm1_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm1_rvalid     , 
  output  logic          hdm2ip_aximm1_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm1_rid        ,
  output  logic  [511:0] hdm2ip_aximm1_rdata      ,
  output  logic          hdm2ip_aximm1_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm1_rresp      ,
  input   logic          ip2hdm_aximm1_rready    ,

  // GPU CSR via CAFU AVMM (125 MHz domain)
  input  logic        gpu_avmm_clk,
  input  logic        gpu_avmm_rstn,
  input  logic [21:0] gpu_avmm_address,
  input  logic [63:0] gpu_avmm_writedata,
  input  logic        gpu_avmm_write,
  input  logic        gpu_avmm_read,
  input  logic [7:0]  gpu_avmm_byteenable,
  output logic        gpu_avmm_waitrequest,
  output logic [63:0] gpu_avmm_readdata,
  output logic        gpu_avmm_readdatavalid,

`endif

  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][4:0] mc_status,
  /* only supporting the axi4 for HDM memory traffic to/from IP
   */
  /* External MC_TOP <--> CXL-IP - write address channels
   */
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        ip2hdm_aximm_awvalid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_ID_BW-1:0]     ip2hdm_aximm_awid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_ADDR_BW-1:0]   ip2hdm_aximm_awaddr,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_BLEN_BW-1:0]   ip2hdm_aximm_awlen,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_REGION_BW-1:0] ip2hdm_aximm_awregion,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_USER_BW-1:0]   ip2hdm_aximm_awuser,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]   ip2hdm_aximm_awsize,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]  ip2hdm_aximm_awburst,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]   ip2hdm_aximm_awprot,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]    ip2hdm_aximm_awqos,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]  ip2hdm_aximm_awcache,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]   ip2hdm_aximm_awlock,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        hdm2ip_aximm_awready,   
  /* External MC_TOP <--> CXL-IP - write data channel
   */
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_wvalid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_DATA_BW-1:0] ip2hdm_aximm_wdata,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_STRB_BW-1:0] ip2hdm_aximm_wstrb,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_wlast,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_USER_BW-1:0] ip2hdm_aximm_wuser,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_wready,		  
  /* External MC_TOP <--> CXL-IP - write response channel
   */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_bvalid,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_ID_BW-1:0]   hdm2ip_aximm_bid,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_USER_BW-1:0] hdm2ip_aximm_buser,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_bresp,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_bready,  
  /* External MC_TOP <--> CXL-IP - read address channel
   */
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        ip2hdm_aximm_arvalid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_ID_BW-1:0]     ip2hdm_aximm_arid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_ADDR_BW-1:0]   ip2hdm_aximm_araddr,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_BLEN_BW-1:0]   ip2hdm_aximm_arlen,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_REGION_BW-1:0] ip2hdm_aximm_arregion,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_USER_BW-1:0]   ip2hdm_aximm_aruser,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]   ip2hdm_aximm_arsize,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]  ip2hdm_aximm_arburst,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]   ip2hdm_aximm_arprot,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]    ip2hdm_aximm_arqos,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]  ip2hdm_aximm_arcache,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]   ip2hdm_aximm_arlock,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        hdm2ip_aximm_arready,  
  /* External MC_TOP <--> CXL-IP - read response channel
   */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_rvalid,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_rlast,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_ID_BW-1:0]   hdm2ip_aximm_rid,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_DATA_BW-1:0] hdm2ip_aximm_rdata,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_USER_BW-1:0] hdm2ip_aximm_ruser,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_rresp,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_rready


, input ip2hdm_clk
, input ip2hdm_reset_n
, input [31:0] read_delay

// GPU status outputs (ip2hdm_clk domain, exported for host CSR via CDC)
, output logic [7:0]  gpu_status_out
, output logic [63:0] gpu_cycles_out
, output logic [63:0] gpu_instrs_out

// GPU launch toggle from ed_top_wrapper (pulse-to-toggle in ip2csr_avmm_clk 125 MHz)
// Safe to 2-FF sync into ip2hdm_clk (400 MHz) — toggle is level-based.
, input  logic        ext_vx_launch_toggle
, input  logic [63:0] ext_vx_kernel_addr
, input  logic [63:0] ext_vx_kernel_args


// CIRA completion requests cross to the AXI1/CXL.cache writer in
// ed_top_wrapper_typ2.  All signals share ip2hdm_clk.
, output logic        cira_cache_req_valid
, output logic [31:0] cira_cache_req_status
, output logic [63:0] cira_cache_req_result
, output logic [63:0] cira_cache_req_hpa
, input  logic        cira_cache_req_busy
, input  logic        cira_cache_req_done
, input  logic        cira_cache_req_error
);




//Passthrough User can implement the AFU logic here 

`ifdef ENABLE_1_SLICE   

 assign   mc2ip_0_sr_status      =  mc_status[0]                   ;
//Channel-0
 assign ip2hdm_aximm_awid    [0] = ip2hdm_aximm0_awid ;
 assign ip2hdm_aximm_awaddr  [0] = ip2hdm_aximm0_awaddr ;
 assign ip2hdm_aximm_awlen   [0] = ip2hdm_aximm0_awlen ;
 assign ip2hdm_aximm_awregion[0] = ip2hdm_aximm0_awregion ;
 assign ip2hdm_aximm_awuser  [0] = ip2hdm_aximm0_awuser ;
 assign ip2hdm_aximm_awsize  [0] = ip2hdm_aximm0_awsize  ;
 assign ip2hdm_aximm_awburst [0] = ip2hdm_aximm0_awburst ;
 assign ip2hdm_aximm_awprot  [0] = ip2hdm_aximm0_awprot  ;
 assign ip2hdm_aximm_awqos   [0] = ip2hdm_aximm0_awqos   ;
 assign ip2hdm_aximm_awcache [0] = ip2hdm_aximm0_awcache ;
 assign ip2hdm_aximm_awlock  [0] = ip2hdm_aximm0_awlock  ;
 assign ip2hdm_aximm_awvalid [0] = ip2hdm_aximm0_awvalid;
 assign ip2hdm_aximm_wdata   [0] = ip2hdm_aximm0_wdata ;
 assign ip2hdm_aximm_wstrb   [0] = ip2hdm_aximm0_wstrb ;
 assign ip2hdm_aximm_wlast   [0] = ip2hdm_aximm0_wlast ;
 assign ip2hdm_aximm_wuser   [0] = ip2hdm_aximm0_wuser ;
 assign ip2hdm_aximm_wvalid  [0] = ip2hdm_aximm0_wvalid;
 assign ip2hdm_aximm_bready  [0] = ip2hdm_aximm0_bready ;
 assign ip2hdm_aximm_arid    [0] = ip2hdm_aximm0_arid ;
 assign ip2hdm_aximm_araddr  [0] = ip2hdm_aximm0_araddr ;
 assign ip2hdm_aximm_arlen   [0] = ip2hdm_aximm0_arlen ;
 assign ip2hdm_aximm_arregion[0] = ip2hdm_aximm0_arregion ;
 assign ip2hdm_aximm_aruser  [0] = ip2hdm_aximm0_aruser ;
 assign ip2hdm_aximm_arsize  [0] = ip2hdm_aximm0_arsize ;
 assign ip2hdm_aximm_arburst [0] = ip2hdm_aximm0_arburst ;
 assign ip2hdm_aximm_arprot  [0] = ip2hdm_aximm0_arprot  ;
 assign ip2hdm_aximm_arqos   [0] = ip2hdm_aximm0_arqos  ;
 assign ip2hdm_aximm_arcache [0] = ip2hdm_aximm0_arcache ;
 assign ip2hdm_aximm_arlock  [0] = ip2hdm_aximm0_arlock ;
 assign ip2hdm_aximm_arvalid [0] = ip2hdm_aximm0_arvalid;
 
 assign hdm2ip_aximm0_awready    =  hdm2ip_aximm_awready[0] ;
 assign hdm2ip_aximm0_wready     =  hdm2ip_aximm_wready [0] ;
 assign hdm2ip_aximm0_bvalid     =  hdm2ip_aximm_bvalid [0] ;
 assign hdm2ip_aximm0_bid        =  hdm2ip_aximm_bid    [0] ;
 assign hdm2ip_aximm0_buser      =  hdm2ip_aximm_buser  [0] ;
 assign hdm2ip_aximm0_bresp      =  hdm2ip_aximm_bresp  [0] ;
 assign hdm2ip_aximm0_arready    =  hdm2ip_aximm_arready[0] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm0_rvalid     =  hdm2ip_aximm_rvalid [0] ;
 assign hdm2ip_aximm0_rlast      =  hdm2ip_aximm_rlast  [0] ;
 assign hdm2ip_aximm0_rid        =  hdm2ip_aximm_rid    [0] ;
 assign hdm2ip_aximm0_rdata      =  hdm2ip_aximm_rdata  [0] ;
 assign hdm2ip_aximm0_ruser      =  hdm2ip_aximm_ruser  [0] ;
 assign hdm2ip_aximm0_rresp      =  hdm2ip_aximm_rresp  [0] ;
 assign ip2hdm_aximm_rready  [0] = ip2hdm_aximm0_rready ;
`endif

`elsif ENABLE_4_SLICE   

 assign   mc2ip_0_sr_status      =  mc_status[0]                   ;
 assign   mc2ip_1_sr_status      =  mc_status[1]                   ;
 assign   mc2ip_2_sr_status      =  mc_status[2]                   ;
 assign   mc2ip_3_sr_status      =  mc_status[3]                   ;


//Channel-0
 assign ip2hdm_aximm_awid    [0] = ip2hdm_aximm0_awid ;
 assign ip2hdm_aximm_awaddr  [0] = ip2hdm_aximm0_awaddr ;
 assign ip2hdm_aximm_awlen   [0] = ip2hdm_aximm0_awlen ;
 assign ip2hdm_aximm_awregion[0] = ip2hdm_aximm0_awregion ;
 assign ip2hdm_aximm_awuser  [0] = ip2hdm_aximm0_awuser ;
 assign ip2hdm_aximm_awsize  [0] = ip2hdm_aximm0_awsize  ;
 assign ip2hdm_aximm_awburst [0] = ip2hdm_aximm0_awburst ;
 assign ip2hdm_aximm_awprot  [0] = ip2hdm_aximm0_awprot  ;
 assign ip2hdm_aximm_awqos   [0] = ip2hdm_aximm0_awqos   ;
 assign ip2hdm_aximm_awcache [0] = ip2hdm_aximm0_awcache ;
 assign ip2hdm_aximm_awlock  [0] = ip2hdm_aximm0_awlock  ;
 assign ip2hdm_aximm_awvalid [0] = ip2hdm_aximm0_awvalid;
 assign ip2hdm_aximm_wdata   [0] = ip2hdm_aximm0_wdata ;
 assign ip2hdm_aximm_wstrb   [0] = ip2hdm_aximm0_wstrb ;
 assign ip2hdm_aximm_wlast   [0] = ip2hdm_aximm0_wlast ;
 assign ip2hdm_aximm_wuser   [0] = ip2hdm_aximm0_wuser ;
 assign ip2hdm_aximm_wvalid  [0] = ip2hdm_aximm0_wvalid;
 assign ip2hdm_aximm_bready  [0] = ip2hdm_aximm0_bready ;
 assign ip2hdm_aximm_arid    [0] = ip2hdm_aximm0_arid ;
 assign ip2hdm_aximm_araddr  [0] = ip2hdm_aximm0_araddr ;
 assign ip2hdm_aximm_arlen   [0] = ip2hdm_aximm0_arlen ;
 assign ip2hdm_aximm_arregion[0] = ip2hdm_aximm0_arregion ;
 assign ip2hdm_aximm_aruser  [0] = ip2hdm_aximm0_aruser ;
 assign ip2hdm_aximm_arsize  [0] = ip2hdm_aximm0_arsize ;
 assign ip2hdm_aximm_arburst [0] = ip2hdm_aximm0_arburst ;
 assign ip2hdm_aximm_arprot  [0] = ip2hdm_aximm0_arprot  ;
 assign ip2hdm_aximm_arqos   [0] = ip2hdm_aximm0_arqos  ;
 assign ip2hdm_aximm_arcache [0] = ip2hdm_aximm0_arcache ;
 assign ip2hdm_aximm_arlock  [0] = ip2hdm_aximm0_arlock ;
 assign ip2hdm_aximm_arvalid [0] = ip2hdm_aximm0_arvalid;
 
 assign hdm2ip_aximm0_awready    =  hdm2ip_aximm_awready[0] ;
 assign hdm2ip_aximm0_wready     =  hdm2ip_aximm_wready [0] ;
 assign hdm2ip_aximm0_bvalid     =  hdm2ip_aximm_bvalid [0] ;
 assign hdm2ip_aximm0_bid        =  hdm2ip_aximm_bid    [0] ;
 assign hdm2ip_aximm0_buser      =  hdm2ip_aximm_buser  [0] ;
 assign hdm2ip_aximm0_bresp      =  hdm2ip_aximm_bresp  [0] ;
 assign hdm2ip_aximm0_arready    =  hdm2ip_aximm_arready[0] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm0_rvalid     =  hdm2ip_aximm_rvalid [0] ;
 assign hdm2ip_aximm0_rlast      =  hdm2ip_aximm_rlast  [0] ;
 assign hdm2ip_aximm0_rid        =  hdm2ip_aximm_rid    [0] ;
 assign hdm2ip_aximm0_rdata      =  hdm2ip_aximm_rdata  [0] ;
 assign hdm2ip_aximm0_ruser      =  hdm2ip_aximm_ruser  [0] ;
 assign hdm2ip_aximm0_rresp      =  hdm2ip_aximm_rresp  [0] ;
 assign ip2hdm_aximm_rready  [0] = ip2hdm_aximm0_rready ;
`endif

//Channel-1
 assign ip2hdm_aximm_awid    [1] = ip2hdm_aximm1_awid ;
 assign ip2hdm_aximm_awaddr  [1] = ip2hdm_aximm1_awaddr ;
 assign ip2hdm_aximm_awlen   [1] = ip2hdm_aximm1_awlen ;
 assign ip2hdm_aximm_awregion[1] = ip2hdm_aximm1_awregion ;
 assign ip2hdm_aximm_awuser  [1] = ip2hdm_aximm1_awuser ;
 assign ip2hdm_aximm_awsize  [1] = ip2hdm_aximm1_awsize  ;
 assign ip2hdm_aximm_awburst [1] = ip2hdm_aximm1_awburst ;
 assign ip2hdm_aximm_awprot  [1] = ip2hdm_aximm1_awprot  ;
 assign ip2hdm_aximm_awqos   [1] = ip2hdm_aximm1_awqos   ;
 assign ip2hdm_aximm_awcache [1] = ip2hdm_aximm1_awcache ;
 assign ip2hdm_aximm_awlock  [1] = ip2hdm_aximm1_awlock  ;
 assign ip2hdm_aximm_awvalid [1] = ip2hdm_aximm1_awvalid;
 assign ip2hdm_aximm_wdata   [1] = ip2hdm_aximm1_wdata ;
 assign ip2hdm_aximm_wstrb   [1] = ip2hdm_aximm1_wstrb ;
 assign ip2hdm_aximm_wlast   [1] = ip2hdm_aximm1_wlast ;
 assign ip2hdm_aximm_wuser   [1] = ip2hdm_aximm1_wuser ;
 assign ip2hdm_aximm_wvalid  [1] = ip2hdm_aximm1_wvalid;
 assign ip2hdm_aximm_bready  [1] = ip2hdm_aximm1_bready ;
 assign ip2hdm_aximm_arid    [1] = ip2hdm_aximm1_arid ;
 assign ip2hdm_aximm_araddr  [1] = ip2hdm_aximm1_araddr ;
 assign ip2hdm_aximm_arlen   [1] = ip2hdm_aximm1_arlen ;
 assign ip2hdm_aximm_arregion[1] = ip2hdm_aximm1_arregion ;
 assign ip2hdm_aximm_aruser  [1] = ip2hdm_aximm1_aruser ;
 assign ip2hdm_aximm_arsize  [1] = ip2hdm_aximm1_arsize ;
 assign ip2hdm_aximm_arburst [1] = ip2hdm_aximm1_arburst ;
 assign ip2hdm_aximm_arprot  [1] = ip2hdm_aximm1_arprot  ;
 assign ip2hdm_aximm_arqos   [1] = ip2hdm_aximm1_arqos  ;
 assign ip2hdm_aximm_arcache [1] = ip2hdm_aximm1_arcache ;
 assign ip2hdm_aximm_arlock  [1] = ip2hdm_aximm1_arlock ;
 assign ip2hdm_aximm_arvalid [1] = ip2hdm_aximm1_arvalid;
 
 assign hdm2ip_aximm1_awready    =  hdm2ip_aximm_awready[1] ;
 assign hdm2ip_aximm1_wready     =  hdm2ip_aximm_wready [1] ;
 assign hdm2ip_aximm1_bvalid     =  hdm2ip_aximm_bvalid [1] ;
 assign hdm2ip_aximm1_bid        =  hdm2ip_aximm_bid    [1] ;
 assign hdm2ip_aximm1_buser      =  hdm2ip_aximm_buser  [1] ;
 assign hdm2ip_aximm1_bresp      =  hdm2ip_aximm_bresp  [1] ;
 assign hdm2ip_aximm1_arready    =  hdm2ip_aximm_arready[1] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm1_rvalid     =  hdm2ip_aximm_rvalid [1] ;
 assign hdm2ip_aximm1_rlast      =  hdm2ip_aximm_rlast  [1] ;
 assign hdm2ip_aximm1_rid        =  hdm2ip_aximm_rid    [1] ;
 assign hdm2ip_aximm1_rdata      =  hdm2ip_aximm_rdata  [1] ;
 assign hdm2ip_aximm1_ruser      =  hdm2ip_aximm_ruser  [1] ;
 assign hdm2ip_aximm1_rresp      =  hdm2ip_aximm_rresp  [1] ;
 assign ip2hdm_aximm_rready  [1] = ip2hdm_aximm1_rready ;
`endif


//Channel-2
 assign ip2hdm_aximm_awid    [2] = ip2hdm_aximm2_awid ;
 assign ip2hdm_aximm_awaddr  [2] = ip2hdm_aximm2_awaddr ;
 assign ip2hdm_aximm_awlen   [2] = ip2hdm_aximm2_awlen ;
 assign ip2hdm_aximm_awregion[2] = ip2hdm_aximm2_awregion ;
 assign ip2hdm_aximm_awuser  [2] = ip2hdm_aximm2_awuser ;
 assign ip2hdm_aximm_awsize  [2] = ip2hdm_aximm2_awsize  ;
 assign ip2hdm_aximm_awburst [2] = ip2hdm_aximm2_awburst ;
 assign ip2hdm_aximm_awprot  [2] = ip2hdm_aximm2_awprot  ;
 assign ip2hdm_aximm_awqos   [2] = ip2hdm_aximm2_awqos   ;
 assign ip2hdm_aximm_awcache [2] = ip2hdm_aximm2_awcache ;
 assign ip2hdm_aximm_awlock  [2] = ip2hdm_aximm2_awlock  ;
 assign ip2hdm_aximm_awvalid [2] = ip2hdm_aximm2_awvalid;
 assign ip2hdm_aximm_wdata   [2] = ip2hdm_aximm2_wdata ;
 assign ip2hdm_aximm_wstrb   [2] = ip2hdm_aximm2_wstrb ;
 assign ip2hdm_aximm_wlast   [2] = ip2hdm_aximm2_wlast ;
 assign ip2hdm_aximm_wuser   [2] = ip2hdm_aximm2_wuser ;
 assign ip2hdm_aximm_wvalid  [2] = ip2hdm_aximm2_wvalid;
 assign ip2hdm_aximm_bready  [2] = ip2hdm_aximm2_bready ;
 assign ip2hdm_aximm_arid    [2] = ip2hdm_aximm2_arid ;
 assign ip2hdm_aximm_araddr  [2] = ip2hdm_aximm2_araddr ;
 assign ip2hdm_aximm_arlen   [2] = ip2hdm_aximm2_arlen ;
 assign ip2hdm_aximm_arregion[2] = ip2hdm_aximm2_arregion ;
 assign ip2hdm_aximm_aruser  [2] = ip2hdm_aximm2_aruser ;
 assign ip2hdm_aximm_arsize  [2] = ip2hdm_aximm2_arsize ;
 assign ip2hdm_aximm_arburst [2] = ip2hdm_aximm2_arburst ;
 assign ip2hdm_aximm_arprot  [2] = ip2hdm_aximm2_arprot  ;
 assign ip2hdm_aximm_arqos   [2] = ip2hdm_aximm2_arqos  ;
 assign ip2hdm_aximm_arcache [2] = ip2hdm_aximm2_arcache ;
 assign ip2hdm_aximm_arlock  [2] = ip2hdm_aximm2_arlock ;
 assign ip2hdm_aximm_arvalid [2] = ip2hdm_aximm2_arvalid;
 
 assign hdm2ip_aximm2_awready    =  hdm2ip_aximm_awready[2] ;
 assign hdm2ip_aximm2_wready     =  hdm2ip_aximm_wready [2] ;
 assign hdm2ip_aximm2_bvalid     =  hdm2ip_aximm_bvalid [2] ;
 assign hdm2ip_aximm2_bid        =  hdm2ip_aximm_bid    [2] ;
 assign hdm2ip_aximm2_buser      =  hdm2ip_aximm_buser  [2] ;
 assign hdm2ip_aximm2_bresp      =  hdm2ip_aximm_bresp  [2] ;
 assign hdm2ip_aximm2_arready    =  hdm2ip_aximm_arready[2] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm2_rvalid     =  hdm2ip_aximm_rvalid [2] ;
 assign hdm2ip_aximm2_rlast      =  hdm2ip_aximm_rlast  [2] ;
 assign hdm2ip_aximm2_rid        =  hdm2ip_aximm_rid    [2] ;
 assign hdm2ip_aximm2_rdata      =  hdm2ip_aximm_rdata  [2] ;
 assign hdm2ip_aximm2_ruser      =  hdm2ip_aximm_ruser  [2] ;
 assign hdm2ip_aximm2_rresp      =  hdm2ip_aximm_rresp  [2] ;
 assign ip2hdm_aximm_rready  [2] = ip2hdm_aximm2_rready ;
`endif

//Channel-3
 assign ip2hdm_aximm_awid    [3] = ip2hdm_aximm3_awid ;
 assign ip2hdm_aximm_awaddr  [3] = ip2hdm_aximm3_awaddr ;
 assign ip2hdm_aximm_awlen   [3] = ip2hdm_aximm3_awlen ;
 assign ip2hdm_aximm_awregion[3] = ip2hdm_aximm3_awregion ;
 assign ip2hdm_aximm_awuser  [3] = ip2hdm_aximm3_awuser ;
 assign ip2hdm_aximm_awsize  [3] = ip2hdm_aximm3_awsize  ;
 assign ip2hdm_aximm_awburst [3] = ip2hdm_aximm3_awburst ;
 assign ip2hdm_aximm_awprot  [3] = ip2hdm_aximm3_awprot  ;
 assign ip2hdm_aximm_awqos   [3] = ip2hdm_aximm3_awqos   ;
 assign ip2hdm_aximm_awcache [3] = ip2hdm_aximm3_awcache ;
 assign ip2hdm_aximm_awlock  [3] = ip2hdm_aximm3_awlock  ;
 assign ip2hdm_aximm_awvalid [3] = ip2hdm_aximm3_awvalid;
 assign ip2hdm_aximm_wdata   [3] = ip2hdm_aximm3_wdata ;
 assign ip2hdm_aximm_wstrb   [3] = ip2hdm_aximm3_wstrb ;
 assign ip2hdm_aximm_wlast   [3] = ip2hdm_aximm3_wlast ;
 assign ip2hdm_aximm_wuser   [3] = ip2hdm_aximm3_wuser ;
 assign ip2hdm_aximm_wvalid  [3] = ip2hdm_aximm3_wvalid;
 assign ip2hdm_aximm_bready  [3] = ip2hdm_aximm3_bready ;
 assign ip2hdm_aximm_arid    [3] = ip2hdm_aximm3_arid ;
 assign ip2hdm_aximm_araddr  [3] = ip2hdm_aximm3_araddr ;
 assign ip2hdm_aximm_arlen   [3] = ip2hdm_aximm3_arlen ;
 assign ip2hdm_aximm_arregion[3] = ip2hdm_aximm3_arregion ;
 assign ip2hdm_aximm_aruser  [3] = ip2hdm_aximm3_aruser ;
 assign ip2hdm_aximm_arsize  [3] = ip2hdm_aximm3_arsize ;
 assign ip2hdm_aximm_arburst [3] = ip2hdm_aximm3_arburst ;
 assign ip2hdm_aximm_arprot  [3] = ip2hdm_aximm3_arprot  ;
 assign ip2hdm_aximm_arqos   [3] = ip2hdm_aximm3_arqos  ;
 assign ip2hdm_aximm_arcache [3] = ip2hdm_aximm3_arcache ;
 assign ip2hdm_aximm_arlock  [3] = ip2hdm_aximm3_arlock ;
 assign ip2hdm_aximm_arvalid [3] = ip2hdm_aximm3_arvalid;
 
 assign hdm2ip_aximm3_awready    =  hdm2ip_aximm_awready[3] ;
 assign hdm2ip_aximm3_wready     =  hdm2ip_aximm_wready [3] ;
 assign hdm2ip_aximm3_bvalid     =  hdm2ip_aximm_bvalid [3] ;
 assign hdm2ip_aximm3_bid        =  hdm2ip_aximm_bid    [3] ;
 assign hdm2ip_aximm3_buser      =  hdm2ip_aximm_buser  [3] ;
 assign hdm2ip_aximm3_bresp      =  hdm2ip_aximm_bresp  [3] ;
 assign hdm2ip_aximm3_arready    =  hdm2ip_aximm_arready[3] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm3_rvalid     =  hdm2ip_aximm_rvalid [3] ;
 assign hdm2ip_aximm3_rlast      =  hdm2ip_aximm_rlast  [3] ;
 assign hdm2ip_aximm3_rid        =  hdm2ip_aximm_rid    [3] ;
 assign hdm2ip_aximm3_rdata      =  hdm2ip_aximm_rdata  [3] ;
 assign hdm2ip_aximm3_ruser      =  hdm2ip_aximm_ruser  [3] ;
 assign hdm2ip_aximm3_rresp      =  hdm2ip_aximm_rresp  [3] ;
 assign ip2hdm_aximm_rready  [3] = ip2hdm_aximm3_rready ;
`endif


 `else // 2_SLICE

 assign   mc2ip_0_sr_status      =  mc_status[0]                   ;
 assign   mc2ip_1_sr_status      =  mc_status[1]                   ;


//Channel-0 : Passthrough (Host HDM traffic)
 assign ip2hdm_aximm_awid    [0] = ip2hdm_aximm0_awid ;
 assign ip2hdm_aximm_awaddr  [0] = ip2hdm_aximm0_awaddr ;
 assign ip2hdm_aximm_awlen   [0] = ip2hdm_aximm0_awlen ;
 assign ip2hdm_aximm_awregion[0] = ip2hdm_aximm0_awregion ;
 assign ip2hdm_aximm_awuser  [0] = ip2hdm_aximm0_awuser ;
 assign ip2hdm_aximm_awsize  [0] = ip2hdm_aximm0_awsize  ;
 assign ip2hdm_aximm_awburst [0] = ip2hdm_aximm0_awburst ;
 assign ip2hdm_aximm_awprot  [0] = ip2hdm_aximm0_awprot  ;
 assign ip2hdm_aximm_awqos   [0] = ip2hdm_aximm0_awqos   ;
 assign ip2hdm_aximm_awcache [0] = ip2hdm_aximm0_awcache ;
 assign ip2hdm_aximm_awlock  [0] = ip2hdm_aximm0_awlock  ;
 assign ip2hdm_aximm_awvalid [0] = ip2hdm_aximm0_awvalid;
 assign ip2hdm_aximm_wdata   [0] = ip2hdm_aximm0_wdata ;
 assign ip2hdm_aximm_wstrb   [0] = ip2hdm_aximm0_wstrb ;
 assign ip2hdm_aximm_wlast   [0] = ip2hdm_aximm0_wlast ;
 assign ip2hdm_aximm_wuser   [0] = ip2hdm_aximm0_wuser ;
 assign ip2hdm_aximm_wvalid  [0] = ip2hdm_aximm0_wvalid;
 assign ip2hdm_aximm_bready  [0] = ip2hdm_aximm0_bready ;
 assign ip2hdm_aximm_arid    [0] = ip2hdm_aximm0_arid ;
 assign ip2hdm_aximm_araddr  [0] = ip2hdm_aximm0_araddr ;
 assign ip2hdm_aximm_arlen   [0] = ip2hdm_aximm0_arlen ;
 assign ip2hdm_aximm_arregion[0] = ip2hdm_aximm0_arregion ;
 assign ip2hdm_aximm_aruser  [0] = ip2hdm_aximm0_aruser ;
 assign ip2hdm_aximm_arsize  [0] = ip2hdm_aximm0_arsize ;
 assign ip2hdm_aximm_arburst [0] = ip2hdm_aximm0_arburst ;
 assign ip2hdm_aximm_arprot  [0] = ip2hdm_aximm0_arprot  ;
 assign ip2hdm_aximm_arqos   [0] = ip2hdm_aximm0_arqos  ;
 assign ip2hdm_aximm_arcache [0] = ip2hdm_aximm0_arcache ;
 assign ip2hdm_aximm_arlock  [0] = ip2hdm_aximm0_arlock ;
 assign ip2hdm_aximm_arvalid [0] = ip2hdm_aximm0_arvalid;

 assign hdm2ip_aximm0_awready    =  hdm2ip_aximm_awready[0] ;
 assign hdm2ip_aximm0_wready     =  hdm2ip_aximm_wready [0] ;
 assign hdm2ip_aximm0_bvalid     =  hdm2ip_aximm_bvalid [0] ;
 assign hdm2ip_aximm0_bid        =  hdm2ip_aximm_bid    [0] ;
 assign hdm2ip_aximm0_buser      =  hdm2ip_aximm_buser  [0] ;
 assign hdm2ip_aximm0_bresp      =  hdm2ip_aximm_bresp  [0] ;
 assign hdm2ip_aximm0_arready    =  hdm2ip_aximm_arready[0] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm0_rvalid     =  hdm2ip_aximm_rvalid [0] ;
 assign hdm2ip_aximm0_rlast      =  hdm2ip_aximm_rlast  [0] ;
 assign hdm2ip_aximm0_rid        =  hdm2ip_aximm_rid    [0] ;
 assign hdm2ip_aximm0_rdata      =  hdm2ip_aximm_rdata  [0] ;
 assign hdm2ip_aximm0_ruser      =  hdm2ip_aximm_ruser  [0] ;
 assign hdm2ip_aximm0_rresp      =  hdm2ip_aximm_rresp  [0] ;
 assign ip2hdm_aximm_rready  [0] = ip2hdm_aximm0_rready ;
`endif

//=========================================================================
// Channel-1 : Shared between Host HDM and GPU via AXI Arbiter
//
// - HDM Ch1 AXI (host DAX) -> AXI Arbiter port 0 -> MC Ch1
// - GPU wrapper Port1       -> AXI Arbiter port 1 -> MC Ch1
// - GPU CSR control via AVMM (BAR MMIO from host)
// - GPU wrapper Port0 -> tied off (unused)
//=========================================================================

// GPU wrapper internal signals
logic        gpu_csr_valid;
logic        gpu_csr_write;
logic [13:0] gpu_csr_addr;
logic [63:0] gpu_csr_wdata;
logic        gpu_csr_ready;
logic [63:0] gpu_csr_rdata;

// CIRA job dispatch <-> Vortex launch handshake. Declared here because the
// launch arbitration below runs ahead of the dispatcher instantiation, and an
// undeclared identifier would silently become a 1-bit implicit wire.
logic        cira_launch_valid;
logic        cira_launch_ready;
logic [63:0] cira_kernel_addr;
logic [63:0] cira_kernel_args;
logic        cira_speculative;

logic        gpu_kernel_done;
logic [31:0] gpu_kernel_status;

vortex_perf_counters_t gpu_perf_counters;

// GPU status output signals (from vortex_gpu_wrapper)
logic [7:0]  gpu_status_internal;
logic [63:0] gpu_cycles_internal;
logic [63:0] gpu_instrs_internal;
logic        gpu_kernel_launch_ready_int;

// Export GPU status to ed_top_wrapper_typ2
assign gpu_status_out = gpu_status_internal;
assign gpu_cycles_out = gpu_cycles_internal;
assign gpu_instrs_out = gpu_instrs_internal;

//=========================================================================
// CDC: External launch toggle (125 MHz) -> GPU clock domain (ip2hdm_clk)
// Toggle-based pulse synchronizer:
//   Stage 1 (pulse -> toggle) is done in ed_top_wrapper_typ2.sv
//           in ip2csr_avmm_clk (125 MHz) domain.
//   Stage 2: 2-FF sync of toggle into ip2hdm_clk (400 MHz)
//   Stage 3: XOR edge-detect on synced toggle -> single-cycle pulse
//=========================================================================

(* preserve *) logic ext_toggle_s1, ext_toggle_s2, ext_toggle_s_prev;
logic ext_launch_pulse;

always_ff @(posedge ip2hdm_clk or negedge ip2hdm_reset_n) begin
    if (!ip2hdm_reset_n) begin
        ext_toggle_s1     <= 1'b0;
        ext_toggle_s2     <= 1'b0;
        ext_toggle_s_prev <= 1'b0;
    end else begin
        ext_toggle_s1     <= ext_vx_launch_toggle;  // metastability resolve
        ext_toggle_s2     <= ext_toggle_s1;          // stable sample
        ext_toggle_s_prev <= ext_toggle_s2;          // for edge detect
    end
end

// Any toggle transition = one launch pulse in ip2hdm_clk domain
assign ext_launch_pulse = (ext_toggle_s2 ^ ext_toggle_s_prev);

// Latch external kernel config and generate launch via kernel_launch interface
logic ext_launch_pending;
vortex_kernel_args_t ext_kernel_args;

always_ff @(posedge ip2hdm_clk or negedge ip2hdm_reset_n) begin
    if (!ip2hdm_reset_n) begin
        ext_launch_pending <= 1'b0;
        ext_kernel_args    <= '0;
    end else begin
        if (ext_launch_pulse && !ext_launch_pending) begin
            ext_launch_pending           <= 1'b1;
            ext_kernel_args.pc_start     <= ext_vx_kernel_addr;
            ext_kernel_args.kernel_param_ptr <= ext_vx_kernel_args;
            // Single workgroup: all SIMT threads participate within 1x1x1 grid.
            // The Vortex runtime expects grid/block = 1; thread distribution is
            // handled by hardware (warps * threads_per_warp).
            ext_kernel_args.grid_x       <= 16'h1;
            ext_kernel_args.grid_y       <= 16'h1;
            ext_kernel_args.grid_z       <= 16'h1;
            ext_kernel_args.block_x      <= 16'h1;
            ext_kernel_args.block_y      <= 16'h1;
            ext_kernel_args.block_z      <= 16'h1;
        end
        if (ext_launch_pending && gpu_kernel_launch_ready_int) begin
            ext_launch_pending <= 1'b0;
        end
    end
end

//=========================================================================
// Kernel launch arbitration: CIRA dispatcher vs. the legacy ext_vx_* path.
// The dispatcher takes priority, and the two never overlap in practice --
// ext_vx_* is the bring-up path, CIRA is the production one.
//=========================================================================

logic                gpu_launch_valid_mux;
vortex_kernel_args_t gpu_kernel_args_mux;
vortex_kernel_args_t cira_kernel_args_packed;

always_comb begin
    cira_kernel_args_packed                  = '0;
    cira_kernel_args_packed.pc_start         = cira_kernel_addr;
    cira_kernel_args_packed.kernel_param_ptr = cira_kernel_args;
    // Single workgroup, same convention as the ext_vx_* path: the Vortex
    // runtime expects grid/block = 1 and spreads threads over warps itself.
    cira_kernel_args_packed.grid_x           = 16'h1;
    cira_kernel_args_packed.grid_y           = 16'h1;
    cira_kernel_args_packed.grid_z           = 16'h1;
    cira_kernel_args_packed.block_x          = 16'h1;
    cira_kernel_args_packed.block_y          = 16'h1;
    cira_kernel_args_packed.block_z          = 16'h1;

    gpu_launch_valid_mux = cira_launch_valid || ext_launch_pending;
    gpu_kernel_args_mux  = cira_launch_valid ? cira_kernel_args_packed
                                             : ext_kernel_args;
end

// The dispatcher owns the handshake whenever it is the one launching.
assign cira_launch_ready = cira_launch_valid && gpu_kernel_launch_ready_int;

//=========================================================================
// AVMM-to-CSR Bridge: CAFU AVMM (125 MHz) -> GPU CSR (400 MHz ip2hdm_clk)
// Simple req/ack handshake CDC
//=========================================================================

// AVMM side (125 MHz domain)
logic        avmm_csr_req;
logic        avmm_csr_write_r;
logic [13:0] avmm_csr_addr_r;
logic [63:0] avmm_csr_wdata_r;
logic        avmm_csr_done;     // synced back from ip2hdm_clk domain
logic [63:0] avmm_csr_rdata_r;  // captured read data

// CDC: req from 125MHz -> 400MHz
logic avmm_req_sync1, avmm_req_sync2;
// CDC: ack from 400MHz -> 125MHz
logic avmm_ack_fast;
logic avmm_ack_sync1, avmm_ack_sync2;
// CDC: read data from 400MHz -> 125MHz (stable when ack asserts)
logic [63:0] avmm_rdata_fast;

// 125 MHz domain: capture AVMM request, generate req toggle
logic avmm_req_toggle;
logic avmm_busy;

always_ff @(posedge gpu_avmm_clk or negedge gpu_avmm_rstn) begin
    if (!gpu_avmm_rstn) begin
        avmm_req_toggle    <= 1'b0;
        avmm_busy          <= 1'b0;
        avmm_csr_write_r   <= 1'b0;
        avmm_csr_addr_r    <= 14'h0;
        avmm_csr_wdata_r   <= 64'h0;
        avmm_csr_rdata_r   <= 64'h0;
        avmm_ack_sync1     <= 1'b0;
        avmm_ack_sync2     <= 1'b0;
        gpu_avmm_readdatavalid <= 1'b0;
    end else begin
        // Sync ack from fast domain
        avmm_ack_sync1 <= avmm_ack_fast;
        avmm_ack_sync2 <= avmm_ack_sync1;

        gpu_avmm_readdatavalid <= 1'b0;

        if (!avmm_busy) begin
            if (gpu_avmm_write || gpu_avmm_read) begin
                // Address filtering done in ed_top_wrapper_typ2
                avmm_busy        <= 1'b1;
                avmm_csr_write_r <= gpu_avmm_write;
                avmm_csr_addr_r  <= gpu_avmm_address[13:0];
                avmm_csr_wdata_r <= gpu_avmm_writedata;
                avmm_req_toggle  <= ~avmm_req_toggle;
            end
        end else begin
            // Wait for ack toggle to match req toggle
            if (avmm_ack_sync2 == avmm_req_toggle) begin
                avmm_busy <= 1'b0;
                if (!avmm_csr_write_r) begin
                    avmm_csr_rdata_r       <= avmm_rdata_fast;
                    gpu_avmm_readdatavalid <= 1'b1;
                end
            end
        end
    end
end

assign gpu_avmm_waitrequest = avmm_busy;
assign gpu_avmm_readdata    = avmm_csr_rdata_r;

// 400 MHz domain: sync req toggle, issue CSR, generate ack toggle
logic avmm_req_toggle_sync1, avmm_req_toggle_sync2, avmm_req_toggle_prev;
logic avmm_ack_toggle;

always_ff @(posedge ip2hdm_clk or negedge ip2hdm_reset_n) begin
    if (!ip2hdm_reset_n) begin
        avmm_req_toggle_sync1 <= 1'b0;
        avmm_req_toggle_sync2 <= 1'b0;
        avmm_req_toggle_prev  <= 1'b0;
        avmm_ack_toggle       <= 1'b0;
        gpu_csr_valid          <= 1'b0;
        gpu_csr_write          <= 1'b0;
        gpu_csr_addr           <= 14'h0;
        gpu_csr_wdata          <= 64'h0;
        avmm_rdata_fast        <= 64'h0;
    end else begin
        // Sync req toggle
        avmm_req_toggle_sync1 <= avmm_req_toggle;
        avmm_req_toggle_sync2 <= avmm_req_toggle_sync1;
        avmm_req_toggle_prev  <= avmm_req_toggle_sync2;

        // FIX: Only clear gpu_csr_valid when handshake completes, not every cycle!
        // This allows gpu_csr_valid to be held until gpu_csr_ready is asserted.
        if (gpu_csr_valid && gpu_csr_ready) begin
            // Handshake complete - clear valid and capture response
            gpu_csr_valid <= 1'b0;
            avmm_rdata_fast <= gpu_csr_rdata;
            avmm_ack_toggle <= avmm_req_toggle_sync2;
        end else begin
            // Detect req toggle edge (and set valid if not already in handshake)
            if (avmm_req_toggle_sync2 != avmm_req_toggle_prev) begin
                gpu_csr_valid <= 1'b1;
                gpu_csr_write <= avmm_csr_write_r;
                gpu_csr_addr  <= avmm_csr_addr_r;
                gpu_csr_wdata <= avmm_csr_wdata_r;
            end
        end
    end
end

assign avmm_ack_fast = avmm_ack_toggle;

//=========================================================================
// GPU CSR window split
//
//   BAR0+0x080000 .. +0x080FFF   legacy Vortex wrapper CSRs (0x100..0x13C)
//   BAR0+0x082000 .. +0x083FFF   CIRA control window (cira_cxl_job.h)
//
// Address bit 13 selects between them. The legacy map is left exactly where
// it was so existing probe/launch tools keep working; the CIRA window needs
// its own 8 KB because the protocol puts the status line at 0x1F20 and the
// arg slots at 0x100..0x14FF, which would collide with the legacy registers.
//=========================================================================

logic        cira_win_sel;
logic        cira_csr_valid;
logic        cira_csr_ready;
logic [63:0] cira_csr_rdata;
logic        vx_csr_valid;
logic        vx_csr_ready;
logic [63:0] vx_csr_rdata;

assign cira_win_sel   = gpu_csr_addr[13];
assign cira_csr_valid = gpu_csr_valid &&  cira_win_sel;
assign vx_csr_valid   = gpu_csr_valid && !cira_win_sel;

assign gpu_csr_ready  = cira_win_sel ? cira_csr_ready : vx_csr_ready;
assign gpu_csr_rdata  = cira_win_sel ? cira_csr_rdata : vx_csr_rdata;

//=========================================================================
// CIRA job dispatch: doorbell -> validate -> launch -> republish status.
// This is the device side of the protocol in runtime/include/cira_cxl_job.h.
//=========================================================================

logic        cira_wb_kernel_done;
logic [31:0] cira_wb_kernel_status;
logic [63:0] cira_wb_kernel_result;
logic [63:0] cira_wb_completion_addr;

logic [31:0] cira_jobs_accepted;
logic [31:0] cira_jobs_rejected;
logic [63:0] cira_last_seq;
logic [3:0]  cira_state;

// Completion publication uses the generated AXI1 CAFU/CXL.cache port.  The
// writer itself lives in ed_top_wrapper_typ2, where it is serialized with the
// existing ATE master before reaching the physical port.
localparam logic CIRA_WB_ENABLE = 1'b1;

cira_job_dispatch #(
    .ADDR_WIDTH (13)
) cira_dispatch_inst (
    .clk                (ip2hdm_clk),
    .rst_n              (ip2hdm_reset_n),

    .csr_valid          (cira_csr_valid),
    .csr_write          (gpu_csr_write),
    .csr_addr           (gpu_csr_addr[12:0]),
    .csr_wdata          (gpu_csr_wdata),
    .csr_ready          (cira_csr_ready),
    .csr_rdata          (cira_csr_rdata),

    .job_launch_valid   (cira_launch_valid),
    .job_launch_ready   (cira_launch_ready),
    .job_kernel_addr    (cira_kernel_addr),
    .job_kernel_args    (cira_kernel_args),
    .job_speculative    (cira_speculative),

    .job_done           (gpu_kernel_done),
    .job_status         (gpu_kernel_status),
    .job_result         (gpu_cycles_internal),

    .wb_kernel_done     (cira_wb_kernel_done),
    .wb_kernel_status   (cira_wb_kernel_status),
    .wb_kernel_result   (cira_wb_kernel_result),
    .wb_completion_addr (cira_wb_completion_addr),
    .wb_enable          (CIRA_WB_ENABLE),
    .wb_done            (cira_cache_req_done),
    .wb_error           (cira_cache_req_error),
    .wb_busy            (cira_cache_req_busy),

    .dbg_jobs_accepted  (cira_jobs_accepted),
    .dbg_jobs_rejected  (cira_jobs_rejected),
    .dbg_last_seq       (cira_last_seq),
    .dbg_state          (cira_state)
);

assign cira_cache_req_valid  = cira_wb_kernel_done;
assign cira_cache_req_status = cira_wb_kernel_status;
assign cira_cache_req_result = cira_wb_kernel_result;
assign cira_cache_req_hpa    = cira_wb_completion_addr;

//=========================================================================
// HDM Ch1 -> Arbiter port 0 response signals (directly driven by arbiter)
// GPU Port1 intermediate wires (GPU wrapper -> Arbiter port 1)
//=========================================================================

// Arbiter <-> MC Ch1 intermediate wires
logic        arb_mc1_awvalid, arb_mc1_awready;
logic [7:0]  arb_mc1_awid;
logic [51:0] arb_mc1_awaddr;
logic [9:0]  arb_mc1_awlen;
logic [2:0]  arb_mc1_awsize;
logic [1:0]  arb_mc1_awburst;
logic [3:0]  arb_mc1_awcache;
logic [2:0]  arb_mc1_awprot;
logic [3:0]  arb_mc1_awqos;
logic [3:0]  arb_mc1_awregion;
logic        arb_mc1_awuser;
logic [1:0]  arb_mc1_awlock;
logic        arb_mc1_wvalid, arb_mc1_wready;
logic [511:0] arb_mc1_wdata;
logic [63:0] arb_mc1_wstrb;
logic        arb_mc1_wlast;
logic        arb_mc1_wuser;
logic        arb_mc1_bvalid, arb_mc1_bready;
logic [7:0]  arb_mc1_bid;
logic [1:0]  arb_mc1_bresp;
logic        arb_mc1_buser;
logic        arb_mc1_arvalid, arb_mc1_arready;
logic [7:0]  arb_mc1_arid;
logic [51:0] arb_mc1_araddr;
logic [9:0]  arb_mc1_arlen;
logic [2:0]  arb_mc1_arsize;
logic [1:0]  arb_mc1_arburst;
logic [3:0]  arb_mc1_arcache;
logic [2:0]  arb_mc1_arprot;
logic [3:0]  arb_mc1_arqos;
logic [3:0]  arb_mc1_arregion;
logic        arb_mc1_aruser;
logic [1:0]  arb_mc1_arlock;
logic        arb_mc1_rvalid, arb_mc1_rready;
logic [7:0]  arb_mc1_rid;
logic [511:0] arb_mc1_rdata;
logic [1:0]  arb_mc1_rresp;
logic        arb_mc1_rlast;
logic        arb_mc1_ruser;

// GPU Port1 wires (GPU wrapper outputs)
logic [3:0]   gpu_p1_awid;
logic [63:0]  gpu_p1_awaddr;
logic [7:0]   gpu_p1_awlen;
logic [2:0]   gpu_p1_awsize;
logic [1:0]   gpu_p1_awburst;
logic         gpu_p1_awlock;
logic [3:0]   gpu_p1_awcache;
logic [2:0]   gpu_p1_awprot;
logic         gpu_p1_awvalid;

logic [511:0] gpu_p1_wdata;
logic [63:0]  gpu_p1_wstrb;
logic         gpu_p1_wlast;
logic         gpu_p1_wvalid;

logic         gpu_p1_bready;

logic [3:0]   gpu_p1_arid;
logic [63:0]  gpu_p1_araddr;
logic [7:0]   gpu_p1_arlen;
logic [2:0]   gpu_p1_arsize;
logic [1:0]   gpu_p1_arburst;
logic         gpu_p1_arlock;
logic [3:0]   gpu_p1_arcache;
logic [2:0]   gpu_p1_arprot;
logic         gpu_p1_arvalid;

logic         gpu_p1_rready;

//=========================================================================
// Vortex GPU Wrapper Instance
//=========================================================================

// GPU Port1 response wires (from arbiter back to GPU)
logic        gpu_p1_awready;
logic        gpu_p1_wready;
logic [3:0]  gpu_p1_bid;
logic [1:0]  gpu_p1_bresp;
logic        gpu_p1_bvalid;
logic        gpu_p1_arready;
logic [3:0]  gpu_p1_rid;
logic [511:0] gpu_p1_rdata;
logic [1:0]  gpu_p1_rresp;
logic        gpu_p1_rlast;
logic        gpu_p1_rvalid;

vortex_gpu_wrapper vortex_gpu_inst (
    .clk                    (ip2hdm_clk),
    .rst_n                  (ip2hdm_reset_n),

    // CSR interface (from AVMM-to-CSR bridge above)
    .csr_valid              (vx_csr_valid),
    .csr_write              (gpu_csr_write),
    .csr_addr               (gpu_csr_addr[11:0]),
    .csr_wdata              (gpu_csr_wdata),
    .csr_ready              (vx_csr_ready),
    .csr_rdata              (vx_csr_rdata),

    // Kernel launch interface: CIRA dispatcher, or the legacy ext_vx_* path
    .kernel_launch_valid    (gpu_launch_valid_mux),
    .kernel_args            (gpu_kernel_args_mux),
    .kernel_launch_ready    (gpu_kernel_launch_ready_int),
    .kernel_done            (gpu_kernel_done),
    .kernel_status          (gpu_kernel_status),

    // Performance counters
    .perf_counters          (gpu_perf_counters),

    // Status outputs (for CDC export to host CSR domain)
    .status_out             (gpu_status_internal),
    .cycles_out             (gpu_cycles_internal),
    .instrs_out             (gpu_instrs_internal),

    // AXI Port 0 (Host Memory) - unused, tied off inside wrapper
    .m_axi_port0_awid       (),
    .m_axi_port0_awaddr     (),
    .m_axi_port0_awlen      (),
    .m_axi_port0_awsize     (),
    .m_axi_port0_awburst    (),
    .m_axi_port0_awlock     (),
    .m_axi_port0_awcache    (),
    .m_axi_port0_awprot     (),
    .m_axi_port0_awvalid    (),
    .m_axi_port0_awready    (1'b1),
    .m_axi_port0_wdata      (),
    .m_axi_port0_wstrb      (),
    .m_axi_port0_wlast      (),
    .m_axi_port0_wvalid     (),
    .m_axi_port0_wready     (1'b1),
    .m_axi_port0_bid        (4'h0),
    .m_axi_port0_bresp      (2'b00),
    .m_axi_port0_bvalid     (1'b0),
    .m_axi_port0_bready     (),
    .m_axi_port0_arid       (),
    .m_axi_port0_araddr     (),
    .m_axi_port0_arlen      (),
    .m_axi_port0_arsize     (),
    .m_axi_port0_arburst    (),
    .m_axi_port0_arlock     (),
    .m_axi_port0_arcache    (),
    .m_axi_port0_arprot     (),
    .m_axi_port0_arvalid    (),
    .m_axi_port0_arready    (1'b1),
    .m_axi_port0_rid        (4'h0),
    .m_axi_port0_rdata      (512'h0),
    .m_axi_port0_rresp      (2'b00),
    .m_axi_port0_rlast      (1'b0),
    .m_axi_port0_rvalid     (1'b0),
    .m_axi_port0_rready     (),

    // AXI Port 1 (Device Memory) -> Arbiter port 1
    .m_axi_port1_awid       (gpu_p1_awid),
    .m_axi_port1_awaddr     (gpu_p1_awaddr),
    .m_axi_port1_awlen      (gpu_p1_awlen),
    .m_axi_port1_awsize     (gpu_p1_awsize),
    .m_axi_port1_awburst    (gpu_p1_awburst),
    .m_axi_port1_awlock     (gpu_p1_awlock),
    .m_axi_port1_awcache    (gpu_p1_awcache),
    .m_axi_port1_awprot     (gpu_p1_awprot),
    .m_axi_port1_awvalid    (gpu_p1_awvalid),
    .m_axi_port1_awready    (gpu_p1_awready),
    .m_axi_port1_wdata      (gpu_p1_wdata),
    .m_axi_port1_wstrb      (gpu_p1_wstrb),
    .m_axi_port1_wlast      (gpu_p1_wlast),
    .m_axi_port1_wvalid     (gpu_p1_wvalid),
    .m_axi_port1_wready     (gpu_p1_wready),
    .m_axi_port1_bid        (gpu_p1_bid),
    .m_axi_port1_bresp      (gpu_p1_bresp),
    .m_axi_port1_bvalid     (gpu_p1_bvalid),
    .m_axi_port1_bready     (gpu_p1_bready),
    .m_axi_port1_arid       (gpu_p1_arid),
    .m_axi_port1_araddr     (gpu_p1_araddr),
    .m_axi_port1_arlen      (gpu_p1_arlen),
    .m_axi_port1_arsize     (gpu_p1_arsize),
    .m_axi_port1_arburst    (gpu_p1_arburst),
    .m_axi_port1_arlock     (gpu_p1_arlock),
    .m_axi_port1_arcache    (gpu_p1_arcache),
    .m_axi_port1_arprot     (gpu_p1_arprot),
    .m_axi_port1_arvalid    (gpu_p1_arvalid),
    .m_axi_port1_arready    (gpu_p1_arready),
    .m_axi_port1_rid        (gpu_p1_rid),
    .m_axi_port1_rdata      (gpu_p1_rdata),
    .m_axi_port1_rresp      (gpu_p1_rresp),
    .m_axi_port1_rlast      (gpu_p1_rlast),
    .m_axi_port1_rvalid     (gpu_p1_rvalid),
    .m_axi_port1_rready     (gpu_p1_rready)
);

//=========================================================================
// AXI MC Arbiter: Host HDM Ch1 (port 0) + GPU Port1 (port 1) -> MC Ch1
//=========================================================================

axi_mc_arbiter #(
    .ID_WIDTH   (8),
    .ADDR_WIDTH (52),
    .DATA_WIDTH (512),
    .LEN_WIDTH  (10),
    .GPU_ID_W   (4)
) u_axi_mc_arbiter (
    .clk        (ip2hdm_clk),
    .rst_n      (ip2hdm_reset_n),

    // Master 0: Host HDM Channel 1 from CXL IP
    .m0_awvalid (ip2hdm_aximm1_awvalid),
    .m0_awready (hdm2ip_aximm1_awready),
    .m0_awid    (ip2hdm_aximm1_awid),
    .m0_awaddr  (ip2hdm_aximm1_awaddr),
    .m0_awlen   (ip2hdm_aximm1_awlen),
    .m0_awsize  (ip2hdm_aximm1_awsize),
    .m0_awburst (ip2hdm_aximm1_awburst),
    .m0_awcache (ip2hdm_aximm1_awcache),
    .m0_awprot  (ip2hdm_aximm1_awprot),
    .m0_awqos   (ip2hdm_aximm1_awqos),
    .m0_awregion(ip2hdm_aximm1_awregion),
    .m0_awuser  (ip2hdm_aximm1_awuser),
    .m0_awlock  (ip2hdm_aximm1_awlock),
    .m0_wvalid  (ip2hdm_aximm1_wvalid),
    .m0_wready  (hdm2ip_aximm1_wready),
    .m0_wdata   (ip2hdm_aximm1_wdata),
    .m0_wstrb   (ip2hdm_aximm1_wstrb),
    .m0_wlast   (ip2hdm_aximm1_wlast),
    .m0_wuser   (ip2hdm_aximm1_wuser),
    .m0_bvalid  (hdm2ip_aximm1_bvalid),
    .m0_bready  (ip2hdm_aximm1_bready),
    .m0_bid     (hdm2ip_aximm1_bid),
    .m0_bresp   (hdm2ip_aximm1_bresp),
    .m0_buser   (hdm2ip_aximm1_buser),
    .m0_arvalid (ip2hdm_aximm1_arvalid),
    .m0_arready (hdm2ip_aximm1_arready),
    .m0_arid    (ip2hdm_aximm1_arid),
    .m0_araddr  (ip2hdm_aximm1_araddr),
    .m0_arlen   (ip2hdm_aximm1_arlen),
    .m0_arsize  (ip2hdm_aximm1_arsize),
    .m0_arburst (ip2hdm_aximm1_arburst),
    .m0_arcache (ip2hdm_aximm1_arcache),
    .m0_arprot  (ip2hdm_aximm1_arprot),
    .m0_arqos   (ip2hdm_aximm1_arqos),
    .m0_arregion(ip2hdm_aximm1_arregion),
    .m0_aruser  (ip2hdm_aximm1_aruser),
    .m0_arlock  (ip2hdm_aximm1_arlock),
    .m0_rvalid  (hdm2ip_aximm1_rvalid),
    .m0_rready  (ip2hdm_aximm1_rready),
    .m0_rid     (hdm2ip_aximm1_rid),
    .m0_rdata   (hdm2ip_aximm1_rdata),
    .m0_rresp   (hdm2ip_aximm1_rresp),
    .m0_rlast   (hdm2ip_aximm1_rlast),
    .m0_ruser   (hdm2ip_aximm1_ruser),

    // Master 1: GPU Port1
    .m1_awvalid (gpu_p1_awvalid),
    .m1_awready (gpu_p1_awready),
    .m1_awid    (gpu_p1_awid),
    .m1_awaddr  (gpu_p1_awaddr),
    .m1_awlen   (gpu_p1_awlen),
    .m1_awsize  (gpu_p1_awsize),
    .m1_awburst (gpu_p1_awburst),
    .m1_awcache (gpu_p1_awcache),
    .m1_awprot  (gpu_p1_awprot),
    .m1_awlock  (gpu_p1_awlock),
    .m1_wvalid  (gpu_p1_wvalid),
    .m1_wready  (gpu_p1_wready),
    .m1_wdata   (gpu_p1_wdata),
    .m1_wstrb   (gpu_p1_wstrb),
    .m1_wlast   (gpu_p1_wlast),
    .m1_bvalid  (gpu_p1_bvalid),
    .m1_bready  (gpu_p1_bready),
    .m1_bid     (gpu_p1_bid),
    .m1_bresp   (gpu_p1_bresp),
    .m1_arvalid (gpu_p1_arvalid),
    .m1_arready (gpu_p1_arready),
    .m1_arid    (gpu_p1_arid),
    .m1_araddr  (gpu_p1_araddr),
    .m1_arlen   (gpu_p1_arlen),
    .m1_arsize  (gpu_p1_arsize),
    .m1_arburst (gpu_p1_arburst),
    .m1_arcache (gpu_p1_arcache),
    .m1_arprot  (gpu_p1_arprot),
    .m1_arlock  (gpu_p1_arlock),
    .m1_rvalid  (gpu_p1_rvalid),
    .m1_rready  (gpu_p1_rready),
    .m1_rid     (gpu_p1_rid),
    .m1_rdata   (gpu_p1_rdata),
    .m1_rresp   (gpu_p1_rresp),
    .m1_rlast   (gpu_p1_rlast),

    // Slave: MC Channel 1 (via intermediate wires)
    .s_awvalid  (arb_mc1_awvalid),
    .s_awready  (arb_mc1_awready),
    .s_awid     (arb_mc1_awid),
    .s_awaddr   (arb_mc1_awaddr),
    .s_awlen    (arb_mc1_awlen),
    .s_awsize   (arb_mc1_awsize),
    .s_awburst  (arb_mc1_awburst),
    .s_awcache  (arb_mc1_awcache),
    .s_awprot   (arb_mc1_awprot),
    .s_awqos    (arb_mc1_awqos),
    .s_awregion (arb_mc1_awregion),
    .s_awuser   (arb_mc1_awuser),
    .s_awlock   (arb_mc1_awlock),
    .s_wvalid   (arb_mc1_wvalid),
    .s_wready   (arb_mc1_wready),
    .s_wdata    (arb_mc1_wdata),
    .s_wstrb    (arb_mc1_wstrb),
    .s_wlast    (arb_mc1_wlast),
    .s_wuser    (arb_mc1_wuser),
    .s_bvalid   (arb_mc1_bvalid),
    .s_bready   (arb_mc1_bready),
    .s_bid      (arb_mc1_bid),
    .s_bresp    (arb_mc1_bresp),
    .s_buser    (arb_mc1_buser),
    .s_arvalid  (arb_mc1_arvalid),
    .s_arready  (arb_mc1_arready),
    .s_arid     (arb_mc1_arid),
    .s_araddr   (arb_mc1_araddr),
    .s_arlen    (arb_mc1_arlen),
    .s_arsize   (arb_mc1_arsize),
    .s_arburst  (arb_mc1_arburst),
    .s_arcache  (arb_mc1_arcache),
    .s_arprot   (arb_mc1_arprot),
    .s_arqos    (arb_mc1_arqos),
    .s_arregion (arb_mc1_arregion),
    .s_aruser   (arb_mc1_aruser),
    .s_arlock   (arb_mc1_arlock),
    .s_rvalid   (arb_mc1_rvalid),
    .s_rready   (arb_mc1_rready),
    .s_rid      (arb_mc1_rid),
    .s_rdata    (arb_mc1_rdata),
    .s_rresp    (arb_mc1_rresp),
    .s_rlast    (arb_mc1_rlast),
    .s_ruser    (arb_mc1_ruser)
);

//=========================================================================
// Arbiter output -> MC Channel 1 signal assignments
//=========================================================================

// Write address channel (Arbiter -> MC)
assign ip2hdm_aximm_awid    [1] = arb_mc1_awid;
assign ip2hdm_aximm_awaddr  [1] = arb_mc1_awaddr;
assign ip2hdm_aximm_awlen   [1] = arb_mc1_awlen;
assign ip2hdm_aximm_awregion[1] = arb_mc1_awregion;
assign ip2hdm_aximm_awuser  [1] = arb_mc1_awuser;
assign ip2hdm_aximm_awsize  [1] = arb_mc1_awsize;
assign ip2hdm_aximm_awburst [1] = arb_mc1_awburst;
assign ip2hdm_aximm_awprot  [1] = arb_mc1_awprot;
assign ip2hdm_aximm_awqos   [1] = arb_mc1_awqos;
assign ip2hdm_aximm_awcache [1] = arb_mc1_awcache;
assign ip2hdm_aximm_awlock  [1] = arb_mc1_awlock;
assign ip2hdm_aximm_awvalid [1] = arb_mc1_awvalid;

// Write data channel (Arbiter -> MC)
assign ip2hdm_aximm_wdata   [1] = arb_mc1_wdata;
assign ip2hdm_aximm_wstrb   [1] = arb_mc1_wstrb;
assign ip2hdm_aximm_wlast   [1] = arb_mc1_wlast;
assign ip2hdm_aximm_wuser   [1] = arb_mc1_wuser;
assign ip2hdm_aximm_wvalid  [1] = arb_mc1_wvalid;

// Write response channel (MC -> Arbiter)
assign arb_mc1_awready = hdm2ip_aximm_awready[1];
assign arb_mc1_wready  = hdm2ip_aximm_wready[1];
assign arb_mc1_bvalid  = hdm2ip_aximm_bvalid[1];
assign arb_mc1_bid     = hdm2ip_aximm_bid[1];
assign arb_mc1_bresp   = hdm2ip_aximm_bresp[1];
assign arb_mc1_buser   = hdm2ip_aximm_buser[1];
assign ip2hdm_aximm_bready[1] = arb_mc1_bready;

// Read address channel (Arbiter -> MC)
assign ip2hdm_aximm_arid    [1] = arb_mc1_arid;
assign ip2hdm_aximm_araddr  [1] = arb_mc1_araddr;
assign ip2hdm_aximm_arlen   [1] = arb_mc1_arlen;
assign ip2hdm_aximm_arregion[1] = arb_mc1_arregion;
assign ip2hdm_aximm_aruser  [1] = arb_mc1_aruser;
assign ip2hdm_aximm_arsize  [1] = arb_mc1_arsize;
assign ip2hdm_aximm_arburst [1] = arb_mc1_arburst;
assign ip2hdm_aximm_arprot  [1] = arb_mc1_arprot;
assign ip2hdm_aximm_arqos   [1] = arb_mc1_arqos;
assign ip2hdm_aximm_arcache [1] = arb_mc1_arcache;
assign ip2hdm_aximm_arlock  [1] = arb_mc1_arlock;
assign ip2hdm_aximm_arvalid [1] = arb_mc1_arvalid;

// Read response channel (MC -> Arbiter)
assign arb_mc1_arready = hdm2ip_aximm_arready[1];
assign arb_mc1_rvalid  = hdm2ip_aximm_rvalid[1];
assign arb_mc1_rid     = hdm2ip_aximm_rid[1];
assign arb_mc1_rdata   = hdm2ip_aximm_rdata[1];
assign arb_mc1_rresp   = hdm2ip_aximm_rresp[1];
assign arb_mc1_rlast   = hdm2ip_aximm_rlast[1];
assign arb_mc1_ruser   = hdm2ip_aximm_ruser[1];
assign ip2hdm_aximm_rready[1] = arb_mc1_rready;


`endif

typedef struct packed {
  logic          rlast      ;
  logic  [7:0]   rid        ;
  logic  [511:0] rdata      ;
  logic          ruser      ;
  logic  [1:0]   rresp      ;
} axi_r_ch_t;

`ifdef DELAY_BUFFER_EN
  `ifdef ENABLE_1_SLICE
    // TODO
  `elsif ENABLE_4_SLICE
    // TODO
  `else // 2_SLICE
    // Channel 0: delay buffer for host HDM traffic (CXL IP <-> MC)
    axi_r_ch_t r_ch_in_0, r_ch_out_0;

    assign r_ch_in_0.rlast = hdm2ip_aximm_rlast[0];
    assign r_ch_in_0.rid   = hdm2ip_aximm_rid[0];
    assign r_ch_in_0.rdata = hdm2ip_aximm_rdata[0];
    assign r_ch_in_0.ruser = hdm2ip_aximm_ruser[0];
    assign r_ch_in_0.rresp = hdm2ip_aximm_rresp[0];

    assign hdm2ip_aximm0_rlast = r_ch_out_0.rlast;
    assign hdm2ip_aximm0_rid   = r_ch_out_0.rid;
    assign hdm2ip_aximm0_rdata = r_ch_out_0.rdata;
    assign hdm2ip_aximm0_ruser = r_ch_out_0.ruser;
    assign hdm2ip_aximm0_rresp = r_ch_out_0.rresp;

    axi_r db_0 (
      .clock (ip2hdm_clk),
      .reset (~ip2hdm_reset_n),

      .io_read_delay      (read_delay),

      .io_axi_r_in_valid  (hdm2ip_aximm_rvalid[0]),
      .io_axi_r_in_bits   (r_ch_in_0),
      .io_axi_r_in_ready  (ip2hdm_aximm_rready[0]),

      .io_axi_r_out_valid (hdm2ip_aximm0_rvalid),
      .io_axi_r_out_bits  (r_ch_out_0),
      .io_axi_r_out_ready (ip2hdm_aximm0_rready)
      );

    // Channel 1: No delay buffer needed - arbiter handles response routing
    // MC Ch1 responses routed by arbiter to host (via hdm2ip_aximm1_*) or GPU
  `endif
`endif // DELAY_BUFFER_EN

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "osvEnW2fOZy+hTAFgpB6qCKl1JvF4ZMF6nvTShx+aOLwY2zbxI2NHps4d1a04Mku7n/VJVNrAGvV17JR/ig1Ero/WSZjglXgRRvVNck9uy2CYvYTWZZGK2Q1zpiyLFOEaMbteTMayu7JRDJd+13nwlQuD2emt6jJA9iKcbGr08GJgDgW21fpriFGm2EQ6gy6LHfn7fYx6nZR5tHB+uV+HCqTvPZjErmopGXmAbE3UzoCJqlGacsSZq+MA+0AkxsVB7+Qi85U+bx42IAMMjTCr8jTioJW8zxCoJPKkFi4LaH7JXgvDrZ+XQcQys+OdlGlNQg/zIC8aN4+pId1uzlJtKvhyd4bmB6Z4BVJwDTMo/iVt8awxghVi5x1jInkxuxfh3V0HYP5Amcq7UhQDx886GQUluSUzRhw8XmWogYCeRjhH23Sw7CJvcpvJZ8kSPLiRBu6a/B72d/FMKXnZexLXT9gnD9WHBjc5xDus87NDe8o3wpYNFXNRFKzKqz093Emgs9SNj8JAo3CGhFi/zhZF3VXlo+DNSmATRtWj1WtvRyYc6EKpGEuBriYGhpt/+tAD45tCB1SQ4cdptEfEKgx1xpk4lUJGvY+Fm1uyDkWwE3ycjnSZ4TJeVOz26nLZ5rJDy3x3u2N2jIbv72OwDvw8O6eSec7hHk4pdmEo27nWABJaj0b3NmoklchE7NvV50SFMoOMST549MnzZZ3nhTRsZGDFgdlB0rUKolzwF2pF/yqRG+kNvoOGjxtjAX7FJN+jObSeASNRISeUjz7ygDq5spxUeZGZG2PynYPfH3lmN1fX+km1ghr4nbtewAjUBbpQum1Lri3DUDPy+npg0lvXKTYUPDMu0ry1mcD0i397jcPODt0YbDKbcOzfN7X3y4vxef1GHicp1Xc0eOqpoQ9m/JZvUvVuR77NZnrWuoEOINhmhUU2UpGipOtksNXcsLwNHWZx4XAtn8NMB1T7Y7411FulV/Dy+TcdluOFpXZkbfiPirGuE1i1+XJx6/12okh"
`endif
