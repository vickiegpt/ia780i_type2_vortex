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


//------------------------------------------------------------
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
//------------------------------------------------------------
//---------------------------------------------
//   ed_top_wrapper_typ2
//---------------------------------------------

`include "avst4to1_pld_if.svh.iv"
`include "cxl_ed_defines.svh.iv"

module ed_top_wrapper_typ2 
import ed_cxlip_top_pkg::*;
import cafu_common_pkg::*;
import cafu_csr0_cfg_pkg::*;
import tmp_cafu_csr0_cfg_pkg::*;
import intel_cxl_pio_parameters :: *;
import mc_ecc_pkg::*;
import ed_mc_axi_if_pkg::*;
import ddr_mc_top_common_pkg::*;
import afu_axi_if_pkg::*;
#(

   localparam T1IP_ENABLE              = 1'b0 
)
(

    // Clocks
    input logic                ip2hdm_clk,             // SIP clk
    input   logic                     ip2cafu_avmm_clk,             //AVMM clock : 125MHz
    input   logic                     ip2csr_avmm_clk,              //AVMM clock : 125MHz
    // Resets
    input logic                ip2hdm_reset_n ,        // SIP RST 
    input   logic                     ip2cafu_avmm_rstn,            //cafu_AVMM_rst_n
    input   logic                     ip2csr_avmm_rstn,             //csr_AVMM_rst_n 

    //AVST_interface_Output_from_IP                                                                                                    
    input   logic                     ed_rx_st0_eop_i,              //AVST segment0 End of Packet
    input   logic                     ed_rx_st1_eop_i,              //AVST segment1 End of Packet 
    input   logic                     ed_rx_st2_eop_i,              //AVST segment2 End of Packet
    input   logic                     ed_rx_st3_eop_i,              //AVST segment3 End of Packet
    input   logic  [127:0]            ed_rx_st0_header_i,           //AVST segment0 Header 
    input   logic  [127:0]            ed_rx_st1_header_i,           //AVST segment1 Header 
    input   logic  [127:0]            ed_rx_st2_header_i,           //AVST segment2 Header 
    input   logic  [127:0]            ed_rx_st3_header_i,           //AVST segment3 Header 
    input   logic  [255:0]            ed_rx_st0_payload_i,          //AVST segment0 Data 
    input   logic  [255:0]            ed_rx_st1_payload_i,          //AVST segment1 Data 
    input   logic  [255:0]            ed_rx_st2_payload_i,          //AVST segment2 Data 
    input   logic  [255:0]            ed_rx_st3_payload_i,          //AVST segment3 Data 
    input   logic                     ed_rx_st0_sop_i,              //AVST segment0 Start of Packet 
    input   logic                     ed_rx_st1_sop_i,              //AVST segment1 Start of Packet 
    input   logic                     ed_rx_st2_sop_i,              //AVST segment2 Start of Packet 
    input   logic                     ed_rx_st3_sop_i,              //AVST segment3 Start of Packet 
    input   logic                     ed_rx_st0_hvalid_i,           //AVST segment0 Header Valid 
    input   logic                     ed_rx_st1_hvalid_i,           //AVST segment1 Header Valid 
    input   logic                     ed_rx_st2_hvalid_i,           //AVST segment2 Header Valid 
    input   logic                     ed_rx_st3_hvalid_i,           //AVST segment3 Header Valid 
    input   logic                     ed_rx_st0_dvalid_i,           //AVST segment0 Data Valid 
    input   logic                     ed_rx_st1_dvalid_i,           //AVST segment1 Data Valid 
    input   logic                     ed_rx_st2_dvalid_i,           //AVST segment2 Data Valid 
    input   logic                     ed_rx_st3_dvalid_i,           //AVST segment3 Data Valid 
    input   logic                     ed_rx_st0_pvalid_i,           //AVST segment0 Prefix Valid  
    input   logic                     ed_rx_st1_pvalid_i,           //AVST segment1 Prefix Valid  
    input   logic                     ed_rx_st2_pvalid_i,           //AVST segment2 Prefix Valid  
    input   logic                     ed_rx_st3_pvalid_i,           //AVST segment3 Prefix Valid  
    input   logic  [2:0]              ed_rx_st0_empty_i,            //AVST segment0 No.Of Dwords empty when corresponding EOP is asserted 
    input   logic  [2:0]              ed_rx_st1_empty_i,            //AVST segment1 No.Of Dwords empty when corresponding EOP is asserted 
    input   logic  [2:0]              ed_rx_st2_empty_i,            //AVST segment2 No.Of Dwords empty when corresponding EOP is asserted 
    input   logic  [2:0]              ed_rx_st3_empty_i,            //AVST segment3 No.Of Dwords empty when corresponding EOP is asserted 
    input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st0_pfnum_i,            //AVST segment0 PF number of TLP 
    input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st1_pfnum_i,            //AVST segment1 PF number of TLP 
    input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st2_pfnum_i,            //AVST segment2 PF number of TLP 
    input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st3_pfnum_i,            //AVST segment3 PF number of TLP 
    input   logic  [31:0]             ed_rx_st0_tlp_prfx_i,         //AVST segment0 PCIe TLP Prefix 
    input   logic  [31:0]             ed_rx_st1_tlp_prfx_i,         //AVST segment1 PCIe TLP Prefix 
    input   logic  [31:0]             ed_rx_st2_tlp_prfx_i,         //AVST segment2 PCIe TLP Prefix 
    input   logic  [31:0]             ed_rx_st3_tlp_prfx_i,         //AVST segment3 PCIe TLP Prefix 
    input   logic  [7:0]              ed_rx_st0_data_parity_i,      //AVST segment0 Parity for Data
    input   logic  [3:0]              ed_rx_st0_hdr_parity_i,       //AVST segment0 Parity for Header 
    input   logic                     ed_rx_st0_tlp_prfx_parity_i,  //AVST segment0 Parity for Prefix 
    input   logic                     ed_rx_st0_misc_parity_i,      //AVST segment0 
    input   logic  [7:0]              ed_rx_st1_data_parity_i,      //AVST segment1 Parity for Data    
    input   logic  [3:0]              ed_rx_st1_hdr_parity_i,       //AVST segment1 Parity for Header  
    input   logic                     ed_rx_st1_tlp_prfx_parity_i,  //AVST segment1 Parity for Prefix  
    input   logic                     ed_rx_st1_misc_parity_i,      //AVST segment1                    
    input   logic  [7:0]              ed_rx_st2_data_parity_i,      //AVST segment2 Parity for Data    
    input   logic  [3:0]              ed_rx_st2_hdr_parity_i,       //AVST segment2 Parity for Header  
    input   logic                     ed_rx_st2_tlp_prfx_parity_i,  //AVST segment2 Parity for Prefix  
    input   logic                     ed_rx_st2_misc_parity_i,      //AVST segment2                    
    input   logic  [7:0]              ed_rx_st3_data_parity_i,      //AVST segment3 Parity for Data    
    input   logic  [3:0]              ed_rx_st3_hdr_parity_i,       //AVST segment3 Parity for Header  
    input   logic                     ed_rx_st3_tlp_prfx_parity_i,  //AVST segment3 Parity for Prefix  
    input   logic                     ed_rx_st3_misc_parity_i,      //AVST segment3                    
    input   logic                     ed_rx_st0_passthrough_i,      //AVST segment0 indicates TLP is targetted to PF2 to PF7 
    input   logic                     ed_rx_st1_passthrough_i,      //AVST segment1 indicates TLP is targetted to PF2 to PF7  
    input   logic                     ed_rx_st2_passthrough_i,      //AVST segment2 indicates TLP is targetted to PF2 to PF7  
    input   logic                     ed_rx_st3_passthrough_i,      //AVST segment3 indicates TLP is targetted to PF2 to PF7  
    input   logic  [2:0]              ed_rx_st0_bar_i,              //AVST segment0 indicates BAR number 
    input   logic  [2:0]              ed_rx_st1_bar_i,              //AVST segment1 indicates BAR number 
    input   logic  [2:0]              ed_rx_st2_bar_i,              //AVST segment2 indicates BAR number 
    input   logic  [2:0]              ed_rx_st3_bar_i,              //AVST segment3 indicates BAR number 
    input   logic  [7:0]              ed_rx_bus_number,             //Bus number assigned by Host 
    input   logic  [4:0]              ed_rx_device_number,          //Device number assigned by Host  
    input   logic  [2:0]              ed_rx_function_number,        //Function Number assigned by Host  
    //--                                                                
    output  logic                     ed_rx_st_ready_o,             //AVST Ready 
    output  logic                     ed_clk,                       //  
    output  logic                     ed_rst_n,                     //  
    //                                                                  
    output  logic                     ed_tx_st0_eop_o,              //AVST segment0 End of Packet                                          
    output  logic                     ed_tx_st1_eop_o,              //AVST segment1 End of Packet                                          
    output  logic                     ed_tx_st2_eop_o,              //AVST segment2 End of Packet                                          
    output  logic                     ed_tx_st3_eop_o,              //AVST segment3 End of Packet                                          
    output  logic  [127:0]            ed_tx_st0_header_o,           //AVST segment0 Header                                                 
    output  logic  [127:0]            ed_tx_st1_header_o,           //AVST segment1 Header                                                 
    output  logic  [127:0]            ed_tx_st2_header_o,           //AVST segment2 Header                                                 
    output  logic  [127:0]            ed_tx_st3_header_o,           //AVST segment3 Header                                                 
    output  logic  [31:0]             ed_tx_st0_prefix_o,           //AVST segment0 Prefix  
    output  logic  [31:0]             ed_tx_st1_prefix_o,           //AVST segment1 Prefix    
    output  logic  [31:0]             ed_tx_st2_prefix_o,           //AVST segment2 Prefix    
    output  logic  [31:0]             ed_tx_st3_prefix_o,           //AVST segment3 Prefix    
    output  logic  [255:0]            ed_tx_st0_payload_o,          //AVST segment0 Data  
    output  logic  [255:0]            ed_tx_st1_payload_o,          //AVST segment1 Data   
    output  logic  [255:0]            ed_tx_st2_payload_o,          //AVST segment2 Data  
    output  logic  [255:0]            ed_tx_st3_payload_o,          //AVST segment3 Data  
    output  logic                     ed_tx_st0_sop_o,              //AVST segment0 Start of Packet  
    output  logic                     ed_tx_st1_sop_o,              //AVST segment1 Start of Packet  
    output  logic                     ed_tx_st2_sop_o,              //AVST segment2 Start of Packet  
    output  logic                     ed_tx_st3_sop_o,              //AVST segment3 Start of Packet  
    output  logic                     ed_tx_st0_dvalid_o,           //AVST segment0 Data Valid  
    output  logic                     ed_tx_st1_dvalid_o,           //AVST segment1 Data Valid  
    output  logic                     ed_tx_st2_dvalid_o,           //AVST segment2 Data Valid  
    output  logic                     ed_tx_st3_dvalid_o,           //AVST segment3 Data Valid  
    output  logic                     ed_tx_st0_pvalid_o,           //AVST segment0 Prefix Valid  
    output  logic                     ed_tx_st1_pvalid_o,           //AVST segment1 Prefix Valid  
    output  logic                     ed_tx_st2_pvalid_o,           //AVST segment2 Prefix Valid  
    output  logic                     ed_tx_st3_pvalid_o,           //AVST segment3 Prefix Valid  
    output  logic                     ed_tx_st0_hvalid_o,           //AVST segment0 Header Valid  
    output  logic                     ed_tx_st1_hvalid_o,           //AVST segment1 Header Valid  
    output  logic                     ed_tx_st2_hvalid_o,           //AVST segment2 Header Valid  
    output  logic                     ed_tx_st3_hvalid_o,           //AVST segment3 Header Valid  
    output  logic  [7:0]              ed_tx_st0_data_parity,        //AVST segment0 Data Parity  
    output  logic  [3:0]              ed_tx_st0_hdr_parity,         //AVST segment0 Header Parity  
    output  logic                     ed_tx_st0_prefix_parity,      //AVST segment0 Prefix Parity  
    output  logic  [2:0]              ed_tx_st0_empty,              //AVST segment0 Empty  
    output  logic                     ed_tx_st0_misc_parity,        //AVST segment0   
    output  logic  [7:0]              ed_tx_st1_data_parity,        //AVST segment1 Data Parity  
    output  logic  [3:0]              ed_tx_st1_hdr_parity,         //AVST segment1 Header Parity  
    output  logic                     ed_tx_st1_prefix_parity,      //AVST segment1 Prefix Parity  
    output  logic  [2:0]              ed_tx_st1_empty,              //AVST segment1 Empty  
    output  logic                     ed_tx_st1_misc_parity,        //AVST segment1   
    output  logic  [7:0]              ed_tx_st2_data_parity,        //AVST segment2 Data Parity      
    output  logic  [3:0]              ed_tx_st2_hdr_parity,         //AVST segment2 Header Parity    
    output  logic                     ed_tx_st2_prefix_parity,      //AVST segment2 Prefix Parity    
    output  logic  [2:0]              ed_tx_st2_empty,              //AVST segment2 Empty            
    output  logic                     ed_tx_st2_misc_parity,        //AVST segment2  
    output  logic  [7:0]              ed_tx_st3_data_parity,        //AVST segment3 Data Parity      
    output  logic  [3:0]              ed_tx_st3_hdr_parity,         //AVST segment3 Header Parity    
    output  logic                     ed_tx_st3_prefix_parity,      //AVST segment3 Prefix Parity    
    output  logic  [2:0]              ed_tx_st3_empty,              //AVST segment3 Empty            
    output  logic                     ed_tx_st3_misc_parity,        //AVST segment3   
    input   logic                     ed_tx_st_ready_i,             //AVST ready from IP   
    //                                                                
    output  logic  [2:0]              rx_st_hcrdt_update_o,         //Indicates Header credit is made available to Host. Bit[0] â PH, Bit[1] â NPH, Bit[2] â CPLH              //Rx_Header_credit_towards_HOST
    output  logic  [5:0]              rx_st_hcrdt_update_cnt_o,     //Indicate number of Header credits released to Host. Bit[1:0] â PH credits , Bit[3:2] â NPH credits, Bit[5:4] â CPLH credits 
    output  logic  [2:0]              rx_st_hcrdt_init_o,           //Credit Initialization indicator, remain high for entire initialization phase. 
    input   logic  [2:0]              rx_st_hcrdt_init_ack_i,       //Indicates host is ready for credit initialization phase  
    //                                                                  
    output  logic  [2:0]              rx_st_dcrdt_update_o,         //Indicates Data credit is made available. Bit[0] â PH, Bit[1] â NPH, Bit[2] â CPLH             // Rx_Data_credit_towards_HOST
    output  logic  [11:0]             rx_st_dcrdt_update_cnt_o,     //Indicate number of Header credits released. Bit[3:0] â PH credits , Bit[7:4] â NPH credits, Bit[11:8] â CPLH credits
    output  logic  [2:0]              rx_st_dcrdt_init_o,           //Credit Initialization indicator, remain high for entire initialization phase.
    input   logic  [2:0]              rx_st_dcrdt_init_ack_i,       //Indicates host is ready for credit initialization phase
    //                                                                     
    input   logic  [2:0]              tx_st_hcrdt_update_i,         //Indicates Header credit is made available by Host. Bit[0] â PH, Bit[1] â NPH, Bit[2] â CPLH  //Tx_Header_credit_from_HOST
    input   logic  [5:0]              tx_st_hcrdt_update_cnt_i,     //Indicate number of Header credits released to Host. Bit[1:0] â PH credits , Bit[3:2] â NPH credits, Bit[5:4] â CPLH credits  
    input   logic  [2:0]              tx_st_hcrdt_init_i,           //Credit Initialization indicator, remain high for entire initialization phase.  
    output  logic  [2:0]              tx_st_hcrdt_init_ack_o,       //Indicates Device (User Logic) is ready for credit initialization phase  
    //                                                                  
    input   logic  [2:0]              tx_st_dcrdt_update_i,         //Indicates Data credit is made available. Bit[0] â PH, Bit[1] â NPH, Bit[2] â CPLH  //Tx_Data_credit_from_HOST
    input   logic  [11:0]             tx_st_dcrdt_update_cnt_i,     //Indicate number of Header credits released. Bit[3:0] â PH credits , Bit[7:4] â NPH credits, Bit[11:8] â CPLH credits  
    input   logic  [2:0]              tx_st_dcrdt_init_i,           //Credit Initialization indicator, remain high for entire initialization phase.  
    output  logic  [2:0]              tx_st_dcrdt_init_ack_o,       //Indicates Device (User Logic) is ready for credit initialization phase  
    //                                                                                              
    input   logic  [31:0]             ccv_afu_conf_base_addr_high,  //bios_based_memory_base_address  
    input   logic                     ccv_afu_conf_base_addr_high_valid,                            
    input   logic  [27:0]             ccv_afu_conf_base_addr_low,                                   
    input   logic                     ccv_afu_conf_base_addr_low_valid,                             
    input   logic  [2:0]              pf0_max_payload_size,         //PF0 Max Payload Size                                
    input   logic  [2:0]              pf0_max_read_request_size,    //PF0 Max Read Request Size                                 
    input   logic                     pf0_bus_master_en,            //PF0 Bus master enable                                
    input   logic                     pf0_memory_access_en,         //PF0 Memory access enable                                
    input   logic  [2:0]              pf1_max_payload_size,         //PF1 Max Payload Size                                
    input   logic  [2:0]              pf1_max_read_request_size,    //PF0 Max Read Request Size                               
    input   logic                     pf1_bus_master_en,            //PF0 Bus master enable                                   
    input   logic                     pf1_memory_access_en,         //PF0 Memory access enable                                
    //From_User  Error Interface
    output   logic                    usr2ip_app_err_valid,   
    output   logic [31:0]             usr2ip_app_err_hdr,  
    output   logic [13:0]             usr2ip_app_err_info,
    output   logic [2:0]              usr2ip_app_err_func_num,
    //To_User  Error Interface
    input    logic                    ip2usr_app_err_ready,
    //FROM IP to USER
    input  logic                      ip2usr_aermsg_correctable_valid ,
    input  logic                      ip2usr_aermsg_uncorrectable_valid,
    input  logic                      ip2usr_aermsg_res ,  
    input  logic                      ip2usr_aermsg_bts ,  
    input  logic                      ip2usr_aermsg_bds ,  
    input  logic                      ip2usr_aermsg_rrs ,  
    input  logic                      ip2usr_aermsg_rtts,  
    input  logic                      ip2usr_aermsg_anes,  
    input  logic                      ip2usr_aermsg_cies,  
    input  logic                      ip2usr_aermsg_hlos,  
    input  logic [1:0]                ip2usr_aermsg_fmt ,  
    input  logic [4:0]                ip2usr_aermsg_type,  
    input  logic [2:0]                ip2usr_aermsg_tc  ,  
    input  logic                      ip2usr_aermsg_ido ,  
    input  logic                      ip2usr_aermsg_th  ,  
    input  logic                      ip2usr_aermsg_td  ,  
    input  logic                      ip2usr_aermsg_ep  ,  
    input  logic                      ip2usr_aermsg_ro  ,  
    input  logic                      ip2usr_aermsg_ns  ,  
    input  logic [1:0]                ip2usr_aermsg_at  ,  
    input  logic [9:0]                ip2usr_aermsg_length,
    input  logic [95:0]               ip2usr_aermsg_header,
    input  logic                      ip2usr_aermsg_und,   
    input  logic                      ip2usr_aermsg_anf,   
    input  logic                      ip2usr_aermsg_dlpes, 
    input  logic                      ip2usr_aermsg_sdes,  
    input  logic [4:0]                ip2usr_aermsg_fep,   
    input  logic                      ip2usr_aermsg_pts,   
    input  logic                      ip2usr_aermsg_fcpes, 
    input  logic                      ip2usr_aermsg_cts ,  
    input  logic                      ip2usr_aermsg_cas ,  
    input  logic                      ip2usr_aermsg_ucs ,  
    input  logic                      ip2usr_aermsg_ros ,  
    input  logic                      ip2usr_aermsg_mts ,  
    input  logic                      ip2usr_aermsg_uies,  
    input  logic                      ip2usr_aermsg_mbts,  
    input  logic                      ip2usr_aermsg_aebs,  
    input  logic                      ip2usr_aermsg_tpbes, 
    input  logic                      ip2usr_aermsg_ees,   
    input  logic                      ip2usr_aermsg_ures,  
    input  logic                      ip2usr_aermsg_avs ,     
    input  logic                      ip2usr_serr_out,
    //input    logic                    ip2usr_err_valid,
    //input    logic [127:0]            ip2usr_err_hdr,
    //input    logic [31:0]             ip2usr_err_tlp_prefix,
    //input    logic [13:0]             ip2usr_err_info,
    //Debug access
    input    logic                    ip2usr_debug_waitrequest,   
    input    logic [31:0]             ip2usr_debug_readdata,   
    input    logic                    ip2usr_debug_readdatavalid,   
    output   logic [31:0]             usr2ip_debug_writedata,   
    output   logic [31:0]             usr2ip_debug_address,   
    output   logic                    usr2ip_debug_write,   
    output   logic                    usr2ip_debug_read,   
    output   logic [3:0]              usr2ip_debug_byteenable,   
    //MSI-X_user_interface                                                                                              
    input   logic                     pf0_msix_enable,              //PF0 MSI-X enable                                 
    input   logic                     pf0_msix_fn_mask,             //PF0 MSI-X function mask                                
    input   logic                     pf1_msix_enable,              //PF1 MSI-X enable                                
    input   logic                     pf1_msix_fn_mask,             //PF1 MSI-X function mask                                
    output  logic  [63:0]             dev_serial_num,               //Device serial number for identification                                
    output  logic                     dev_serial_num_valid,         //Valid for Device serial number                                

    output  logic  [95:0]             cafu2ip_csr0_cfg_if,          //DVSEC values for IP
    input   logic  [5:0]              ip2cafu_csr0_cfg_if,          //
    //                                                                                              
    output  logic                     cafu2ip_avmm_waitrequest,     //CSR_Access_AVMM_Interface
    output  logic  [63:0]             cafu2ip_avmm_readdata,                                        
    output  logic                     cafu2ip_avmm_readdatavalid,                                   
    input   logic  [63:0]             ip2cafu_avmm_writedata,                                       
    input   logic                     ip2cafu_avmm_poison,                                           
    input   logic  [21:0]             ip2cafu_avmm_address,                                         
    input   logic                     ip2cafu_avmm_write,                                           
    input   logic                     ip2cafu_avmm_read,                                            
    input   logic  [7:0]              ip2cafu_avmm_byteenable,                                      

 
    output logic   [1:0]              usr2ip_qos_devload,

    //cafu_csr - AXI interface
    //AXI-MM interface - write address channel
    output logic   [11:0]               axi0_awid,
    output logic   [63:0]               axi0_awaddr, 
    output logic   [9:0]                axi0_awlen,
    output logic   [2:0]                axi0_awsize,
    output logic   [1:0]                axi0_awburst,
    output logic   [2:0]                axi0_awprot,
    output logic   [3:0]                axi0_awqos,
    output logic   [6:0]                axi0_awuser,
    output logic                        axi0_awvalid,
    output logic   [3:0]                axi0_awcache,
    output logic   [1:0]                axi0_awlock,
    output logic   [3:0]                axi0_awregion,
    output logic   [5:0]                axi0_awatop,
    input                               axi0_awready,
  
    //AXI-MM interface - write data channel
    output logic   [511:0]              axi0_wdata,
    output logic   [(512/8)-1:0]        axi0_wstrb,
    output logic                        axi0_wlast,
    output logic                        axi0_wuser,
    output logic                        axi0_wvalid,
    input                               axi0_wready,
  
   //AXI-MM interface - write response channel
    input  logic   [11:0]               axi0_bid,
    input  logic   [1:0]                axi0_bresp,
    input  logic   [3:0]                axi0_buser,
    input  logic                        axi0_bvalid,
    output logic                        axi0_bready,
  
   //AXI-MM interface - read address channel
    output logic   [11:0]               axi0_arid,
    output logic   [63:0]               axi0_araddr,
    output logic   [9:0]                axi0_arlen,
    output logic   [2:0]                axi0_arsize,
    output logic   [1:0]                axi0_arburst,
    output logic   [2:0]                axi0_arprot,
    output logic   [3:0]                axi0_arqos,
    output logic   [5:0]                axi0_aruser,
    output logic                        axi0_arvalid,
    output logic   [3:0]                axi0_arcache,
    output logic   [1:0]                axi0_arlock,
    output logic   [3:0]                axi0_arregion,
    input  logic                        axi0_arready,

   //AXI-MM interface - read response channel
    input  logic   [11:0]               axi0_rid,
    input  logic   [511:0]              axi0_rdata,
    input  logic   [1:0]                axi0_rresp,
    input  logic                        axi0_rlast,
    input  logic [AFU_AXI_RUSER_WIDTH-1:0] axi0_ruser,
    input  logic                        axi0_rvalid,
    output logic                        axi0_rready,
  

  // CXL-IP <--> AFU quiesce interface
    input  logic                        ip2cafu_quiesce_req,
    output logic                        cafu2ip_quiesce_ack,
    //CXL RESET handshake signal to ED 
    output logic                                usr2ip_cxlreset_initiate, 
    input  logic                                ip2usr_cxlreset_req,  
    output logic                                usr2ip_cxlreset_ack,  
    input  logic                                ip2usr_cxlreset_error,
    input  logic                                ip2usr_cxlreset_complete, 
  // GPF to Example design persistent memory flow handshake
    input  logic                                ip2usr_gpf_ph2_req_i,
    output logic                                usr2ip_gpf_ph2_ack_o,
  // CAFU to CXL-IP , to indicate the cache evict policy
    output logic [1:0]                          usr2ip_cache_evict_policy,
  // User AFU
  // AXI-MM interface - write address channel
    output logic [11:0]                 axi1_awid,
    output logic [63:0]                 axi1_awaddr, 
    output logic [9:0]                  axi1_awlen,
    output logic [2:0]                  axi1_awsize,
    output logic [1:0]                  axi1_awburst,
    output logic [2:0]                  axi1_awprot,
    output logic [3:0]                  axi1_awqos,
    output logic [6:0]                  axi1_awuser,
    output logic                        axi1_awvalid,
    output logic [3:0]                  axi1_awcache,
    output logic [1:0]                  axi1_awlock,
    output logic [3:0]                  axi1_awregion,
    output logic [5:0]                  axi1_awatop,
    input  logic                        axi1_awready,
  
  // AXI-MM interface - write data channel
    output logic [511:0]                axi1_wdata,
    output logic [(512/8)-1:0]          axi1_wstrb,
    output logic                        axi1_wlast,
    output logic                        axi1_wuser,
    output logic                        axi1_wvalid,
    input  logic                        axi1_wready,
  
// AXI-MM interface - write response channel
    input  logic [11:0]                 axi1_bid,
    input  logic [1:0]                  axi1_bresp,
    input  logic [3:0]                  axi1_buser,
    input  logic                        axi1_bvalid,
    output logic                        axi1_bready,
  
  
// AXI-MM interface - read address channel  
    output logic [11:0]                 axi1_arid,
    output logic [63:0]                 axi1_araddr,
    output logic [9:0]                  axi1_arlen,
    output logic [2:0]                  axi1_arsize,
    output logic [1:0]                  axi1_arburst,
    output logic [2:0]                  axi1_arprot,
    output logic [3:0]                  axi1_arqos,
    output logic [5:0]                  axi1_aruser,
    output logic                        axi1_arvalid,
    output logic [3:0]                  axi1_arcache,
    output logic [1:0]                  axi1_arlock,
    output logic [3:0]                  axi1_arregion,
    input                               axi1_arready,

// AXI-MM interface - read response channel
    input  logic [11:0]                 axi1_rid,
    input  logic [511:0]                axi1_rdata,
    input  logic [1:0]                  axi1_rresp,
    input  logic                        axi1_rlast,
    input  logic [AFU_AXI_RUSER_WIDTH-1:0] axi1_ruser,
    input  logic                        axi1_rvalid,
    output logic                        axi1_rready,

// DDRMC <--> CXL-IP 
    output  logic [63:0]              mc2ip_memsize,                //Not releavant for current implemntation



//Channel-0
    output  logic  [ed_cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]     mc2ip_0_sr_status,               //HDM controller status
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
  input   logic          ip2hdm_aximm0_rready     ,     
	

  
  
   // DDRMC <--> CXL-IP Slice
    output  logic  [ed_cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]     mc2ip_1_sr_status,               //HDM controller status

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
  input   logic          ip2hdm_aximm1_rready     ,






   //CLST - AXI_ST interface for Slice-0
    input  logic                        ip2cafu_axistd0_tvalid,
    input  logic  [71:0]                ip2cafu_axistd0_tdata, 
    input  logic  [8:0]                 ip2cafu_axistd0_tstrb,
    input  logic  [2:0]                 ip2cafu_axistd0_tdest,
    input  logic  [8:0]                 ip2cafu_axistd0_tkeep,
    input  logic                        ip2cafu_axistd0_tlast,
    input  logic  [7:0]                 ip2cafu_axistd0_tid,
    input  logic  [7:0]                 ip2cafu_axistd0_tuser,  
    output logic                        cafu2ip_axistd0_tready, 
    input  logic                        ip2cafu_axisth0_tvalid,
    input  logic  [71:0]                ip2cafu_axisth0_tdata, 
    input  logic  [8:0]                 ip2cafu_axisth0_tstrb,
    input  logic  [2:0]                 ip2cafu_axisth0_tdest,
    input  logic  [8:0]                 ip2cafu_axisth0_tkeep,
    input  logic                        ip2cafu_axisth0_tlast,
    input  logic  [7:0]                 ip2cafu_axisth0_tid,
    input  logic  [7:0]                 ip2cafu_axisth0_tuser,  
    output logic                        cafu2ip_axisth0_tready, 
  
   //CLST - AXI_ST interface for Slice-1
    input  logic                        ip2cafu_axistd1_tvalid,
    input  logic  [71:0]                ip2cafu_axistd1_tdata, 
    input  logic  [8:0]                 ip2cafu_axistd1_tstrb,
    input  logic  [2:0]                 ip2cafu_axistd1_tdest,
    input  logic  [8:0]                 ip2cafu_axistd1_tkeep,
    input  logic                        ip2cafu_axistd1_tlast,
    input  logic  [7:0]                 ip2cafu_axistd1_tid,
    input  logic  [7:0]                 ip2cafu_axistd1_tuser,  
    output logic                        cafu2ip_axistd1_tready, 
    input  logic                        ip2cafu_axisth1_tvalid,
    input  logic  [71:0]                ip2cafu_axisth1_tdata, 
    input  logic  [8:0]                 ip2cafu_axisth1_tstrb,
    input  logic  [2:0]                 ip2cafu_axisth1_tdest,
    input  logic  [8:0]                 ip2cafu_axisth1_tkeep,
    input  logic                        ip2cafu_axisth1_tlast,
    input  logic  [7:0]                 ip2cafu_axisth1_tid,
    input  logic  [7:0]                 ip2cafu_axisth1_tuser,  
    output logic                        cafu2ip_axisth1_tready, 
  

//AFU inline CSR avmm access
    output logic                        csr2ip_avmm_waitrequest,  
    output logic  [63:0]                csr2ip_avmm_readdata,     
    output logic                        csr2ip_avmm_readdatavalid,
    input  logic  [63:0]                ip2csr_avmm_writedata,
    input  logic                        ip2csr_avmm_poison,
    input  logic  [21:0]                ip2csr_avmm_address,
    input  logic                        ip2csr_avmm_write,
    input  logic                        ip2csr_avmm_read, 
    input  logic  [7:0]                 ip2csr_avmm_byteenable,


// DDR interface pins 
  input  [1:0]        mem_refclk     ,            // EMIF PLL reference clock
  output [1:0][0:0]   mem_ck         ,  // DDR4 interface signals
  output [1:0][0:0]   mem_ck_n       ,  //
  output [1:0][16:0]  mem_a          ,  //
  output [1:0]        mem_act_n      ,             //
  output [1:0][1:0]   mem_ba         ,  //
  output [1:0][1:0]   mem_bg         ,  //
`ifdef HDM_64G
  output [1:0][1:0]   mem_cke        ,  //
  output [1:0][1:0]   mem_cs_n       ,  //
  output [1:0][1:0]   mem_odt        ,  //
`else
  output [1:0][0:0]   mem_cke        ,  //
  output [1:0][0:0]   mem_cs_n       ,  //
  output [1:0][0:0]   mem_odt        ,  //
`endif
  output [1:0]        mem_reset_n    ,           //
  output [1:0]        mem_par        ,               //
  input  [1:0]        mem_oct_rzqin  ,         //
  input  [1:0]        mem_alert_n    ,
`ifdef ENABLE_DDR_DBI_PINS              //Micron DIMM
  inout  [1:0][`DDR_MEM_DQS_W-1:0]   mem_dqs        ,  //
  inout  [1:0][`DDR_MEM_DQS_W-1:0]   mem_dqs_n      ,  //
  inout  [1:0][`DDR_MEM_DQS_W-1:0]   mem_dbi_n      ,  //
`else
  inout  [1:0][17:0]  mem_dqs        ,  //
  inout  [1:0][17:0]  mem_dqs_n      ,  //
`endif  
  inout  [1:0][`DDR_MEM_DQ_W-1:0]  mem_dq            //


);


   
           localparam PF1_BAR01_SIZE_VALUE = 21;  



  //-------------------------------------------------------
  // Signals & Settings                                  --
  //-------------------------------------------------------


//User can implement the logic based on the queisce signal
    logic                                        ip2cafu_quiesce_req_f                ;                       
    logic                                        ip2cafu_quiesce_req_ff               ;                       

    logic                 [2:0]                  ed_rx_st0_chnum_i                    ; //Static signals
    logic                 [2:0]                  ed_rx_st1_chnum_i                    ;                                                    
    logic                 [2:0]                  ed_rx_st2_chnum_i                    ;                                                    
    logic                 [2:0]                  ed_rx_st3_chnum_i                    ;                                                    
    logic                 [10:0]                 ed_rx_st0_vfnum_i                    ;                                                    
    logic                 [10:0]                 ed_rx_st1_vfnum_i                    ;                                                    
    logic                 [10:0]                 ed_rx_st2_vfnum_i                    ;                                                    
    logic                 [10:0]                 ed_rx_st3_vfnum_i                    ;                                                    
    logic                                        ed_rx_st0_vfactive_i                 ;                                                    
    logic                                        ed_rx_st1_vfactive_i                 ;                                                    
    logic                                        ed_rx_st2_vfactive_i                 ;                                                    
    logic                                        ed_rx_st3_vfactive_i                 ;                                                    
    logic                                        ed_tx_st0_chnum                      ;                                                    
    logic                                        ed_tx_st1_chnum                      ;                                                    
    logic                                        ed_tx_st2_chnum                      ;                                                    
    logic                                        ed_tx_st3_chnum                      ;                                                    
    logic                 [2:0]                  ed_tx_st0_pfnum                      ;                                                    
    logic                 [2:0]                  ed_tx_st1_pfnum                      ;                                                    
    logic                 [2:0]                  ed_tx_st2_pfnum                      ;                                                    
    logic                 [2:0]                  ed_tx_st3_pfnum                      ;                                                    
    logic                 [10:0]                 ed_tx_st0_vfnum                      ;                                                    
    logic                 [10:0]                 ed_tx_st1_vfnum                      ;                                                    
    logic                 [10:0]                 ed_tx_st2_vfnum                      ;                                                    
    logic                 [10:0]                 ed_tx_st3_vfnum                      ;                                                    
    logic                                        ed_tx_st0_vfactive                   ;                                                    
    logic                                        ed_tx_st1_vfactive                   ;                                                    
    logic                                        ed_tx_st2_vfactive                   ;                                                    
    logic                                        ed_tx_st3_vfactive                   ;                                                    
    logic                                        ed_tx_st0_passthrough_o              ;                                                    
    logic                                        ed_tx_st1_passthrough_o              ;                                                    
    logic                                        ed_tx_st2_passthrough_o              ;                                                    
    logic                                        ed_tx_st3_passthrough_o              ;                                                    
    logic                 [35:0]                 hdm_size_256mb                       ; 

//CXLIP <---> iAFU
   
  // Error Correction Code (ECC)
  // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
  

  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ready_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_read_poison_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_readdatavalid_eclk;
  // Error Correction Code (ECC)
  // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
  logic [ed_cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_corrected_eclk  [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_detected_eclk   [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_fatal_eclk      [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_syn_e_eclk      [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ecc_err_valid_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc_rspfifo_full_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc_rspfifo_empty_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_cxlmem_ready;
  logic [ed_cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    mc2iafu_readdata_eclk           [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         mc2iafu_rsp_mdata_eclk          [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  
  
  logic [ed_cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    iafu2mc_writedata_eclk          [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      iafu2mc_byteenable_eclk         [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_read_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_poison_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_ras_sbe_eclk;    
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_ras_dbe_eclk;    
 // logic [ed_cxlip_top_pkg::MC_HA_DP_ADDR_WIDTH-1:0]    iafu2mc_address_eclk            [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [(ed_cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(ed_cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]   iafu2mc_address_eclk            [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         iafu2mc_req_mdata_eclk          [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  


  logic [ed_cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]       mc_sr_status_eclk                   [ed_cxlip_top_pkg::MC_CHANNEL-1:0];

  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_ready_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_read_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_write_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_write_poison_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_write_ras_sbe_eclk;    
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_write_ras_dbe_eclk;    
  
  logic [(ed_cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(ed_cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    cxlip2iafu_address_eclk            [ed_cxlip_top_pkg::MC_CHANNEL-1:0];  //added from 22ww18a
  logic [ed_cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         cxlip2iafu_req_mdata_eclk           [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    iafu2cxlip_readdata_eclk            [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         iafu2cxlip_rsp_mdata_eclk           [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    cxlip2iafu_writedata_eclk           [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      cxlip2iafu_byteenable_eclk          [ed_cxlip_top_pkg::MC_CHANNEL-1:0];

  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_read_poison_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_readdatavalid_eclk;
  // Error Correction Code (ECC)
  // Note *ecc_err_* are valid when iafu2cxlip_readdatavalid_eclk is active
  logic [ed_cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_corrected_eclk   [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_detected_eclk    [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_fatal_eclk       [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_syn_e_eclk       [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_ecc_err_valid_eclk;
  
  logic [ed_cxlip_top_pkg::RSPFIFO_DEPTH_WIDTH-1:0]    mc_rspfifo_fill_level_eclk  [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
    
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc_reqfifo_full_eclk;
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             mc_reqfifo_empty_eclk;
  logic [ed_cxlip_top_pkg::REQFIFO_DEPTH_WIDTH-1:0]    mc_reqfifo_fill_level_eclk  [ed_cxlip_top_pkg::MC_CHANNEL-1:0];
  
  logic [ed_cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_cxlmem_ready;
  
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][mc_ecc_pkg::MC_ERR_CNT_WIDTH-1:0] mc_err_cnt ;

  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][4:0] mc_status ;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][4:0] mc_sr_status_eclk_Q ;

  logic [63:0]                                             mc2ip_memsize_s[ed_cxlip_top_pkg::NUM_MC_TOP-1:0];
  logic                                                    mc_mem_active;
  tmp_cafu_csr0_cfg_pkg::tmp_MC_STATUS_t                   ddr_mc_status;
  tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MEM_DEV_STATUS_t      mem_dev_status ;



    logic                                        ip2hdm_reset_n_f                     ;
    logic                                        ip2hdm_reset_n_ff                    ;

    //--to/from afu                                                                                                              
     t_cafu_axi4_rd_addr_ch                            afu_axi_ar                           ;
     t_cafu_axi4_rd_addr_ready                         afu_axi_arready                      ;
     t_cafu_axi4_rd_resp_ch                            afu_axi_r                            ;
     t_cafu_axi4_rd_resp_ready                         afu_axi_rready                       ;
     t_cafu_axi4_wr_addr_ch                            afu_axi_aw                           ;
     t_cafu_axi4_wr_addr_ready                         afu_axi_awready                      ;
     t_cafu_axi4_wr_data_ch                            afu_axi_w                            ;
     t_cafu_axi4_wr_data_ready                         afu_axi_wready                       ;
     t_cafu_axi4_wr_resp_ch                            afu_axi_b                            ;
     t_cafu_axi4_wr_resp_ready                         afu_axi_bready                       ;
    //--to/from afu_cache                                                                                               
     t_cafu_axi4_rd_addr_ch                            afu_cache_axi_ar                     ;
     t_cafu_axi4_rd_addr_ready                         afu_cache_axi_arready                ;
     t_cafu_axi4_rd_resp_ch                            afu_cache_axi_r                      ;
     t_cafu_axi4_rd_resp_ready                         afu_cache_axi_rready                 ;
     t_cafu_axi4_wr_addr_ch                            afu_cache_axi_aw                     ;
     t_cafu_axi4_wr_addr_ready                         afu_cache_axi_awready                ;
     t_cafu_axi4_wr_data_ch                            afu_cache_axi_w                      ;
     t_cafu_axi4_wr_data_ready                         afu_cache_axi_wready                 ;
     t_cafu_axi4_wr_resp_ch                            afu_cache_axi_b                      ;
     t_cafu_axi4_wr_resp_ready                         afu_cache_axi_bready                 ;
    //--to/from afu_io                                                                                                  
     t_cafu_axi4_rd_addr_ch                            afu_io_axi_ar                        ;
     t_cafu_axi4_rd_addr_ready                         afu_io_axi_arready                   ;
     t_cafu_axi4_rd_resp_ch                            afu_io_axi_r                         ;
     t_cafu_axi4_rd_resp_ready                         afu_io_axi_rready                    ;
     t_cafu_axi4_wr_addr_ch                            afu_io_axi_aw                        ;
     t_cafu_axi4_wr_addr_ready                         afu_io_axi_awready                   ;
     t_cafu_axi4_wr_data_ch                            afu_io_axi_w                         ;
     t_cafu_axi4_wr_data_ready                         afu_io_axi_wready                    ;
     t_cafu_axi4_wr_resp_ch                            afu_io_axi_b                         ;
     t_cafu_axi4_wr_resp_ready                         afu_io_axi_bready                    ;
    logic                 [2:0]                  afu_axi_awsize                       ;  //AW* signals from AFU                                                  
    logic                 [1:0]                  afu_axi_awburst                      ;                                                    
    logic                 [2:0]                  afu_axi_awprot                       ;                                                    
    logic                 [3:0]                  afu_axi_awqos                        ;                                                    
    logic                 [3:0]                  afu_axi_awcache                      ;                                                    
    logic                 [1:0]                  afu_axi_awlock                       ;                                                    
    logic                 [2:0]                  afu_axi_arsize                       ;                                                    
    logic                 [1:0]                  afu_axi_arburst                      ;                                                    
    logic                 [2:0]                  afu_axi_arprot                       ;                                                    
    logic                 [3:0]                  afu_axi_arqos                        ;                                                    
    logic                 [3:0]                  afu_axi_arcache                      ;                                                    
    logic                 [1:0]                  afu_axi_arlock                       ;                                                    
    logic                                        cafu_user_enabled_cxl_io             ;  //Asserts 1 when user configured AFU to IO mode
    logic                 [2:0]                  ed_rx_bar                            ;  //AVST4to1 outputs                                                  
    logic                                        ed_rx_eop[1-1:0]                     ;                                                    
    logic                                        ed_rx_eop_i                          ;                                                    
    logic                 [127:0]                ed_rx_header[1-1:0]                  ;                                                    
    logic                 [511:0]                ed_rx_payload[1-1:0]                 ;                                                    
     logic [31:0]    ed_rx_prefix [0:0] ;
     logic	     ed_rx_prefix_valid[0:0] ;
    logic                                        ed_rx_sop[1-1:0]                     ;                                                    
    logic                                        ed_rx_sop_i                          ;                                                    
    logic                                        ed_rx_hvalid                         ;                                                    
    logic                                        ed_rx_valid                          ;                                                    
    logic                                        ed_rx_dvalid[1-1:0]                  ;                                                    
    logic                                        ed_rx_passthrough[1-1:0]             ;                                                    
    logic                                        ed_rx_ready                          ;                                                    
    logic                                        afu_pio_select                       ;  //if  afu_pio_select==1  then  select  afu  else  pio
    logic                                        afu_cache_io_select                  ;                                                    
    logic                 [2:0]                  pio_rx_bar                           ;  //PIO inputs                                                  
    logic                                        pio_rx_eop                           ;                                                    
    logic                                        pio_rx_valid                         ;                                                    
    logic                 [127:0]                pio_rx_header                        ;                                                    
    logic                 [255:0]                pio_rx_payload                       ;                                                    
    logic                                        pio_rx_sop                           ;                                                    
    logic                                        pio_to_send_cpl                      ;                                                    
    logic                                        pio_rx_hvalid                        ;                                                    
    logic                                        pio_rx_dvalid                        ;                                                    
     logic           pio_rx_pvalid	    ;   
     logic [31:0]    pio_rx_prefix ;
     logic [2:0]     aer_chk_rx_bar         ;      
     logic 	     aer_chk_rx_eop 	    ;      
     logic 	     aer_chk_rx_valid 	    ;      
     logic [127:0]   aer_chk_rx_header	    ;   
     logic [255:0]   aer_chk_rx_payload	    ;  
     logic  	     aer_chk_rx_sop	        ;      
     logic 	     aer_chk_rx_hvalid	    ;   
     logic           aer_chk_rx_dvalid	    ;   
     logic           aer_chk_rx_pvalid	    ;   
     logic [31:0]    aer_chk_rx_prefix ;
    logic                                        pio_rx_passthrough                   ;
    logic                                        pio_rx_ready                         ;
    // PIO-to-CSR bridge AVMM wires (CSR now on ip2csr bus; PIO outputs unused)
    logic                                        pio_csr_avmm_read                    ;
    logic                                        pio_csr_avmm_write                   ;
    logic                 [21:0]                 pio_csr_avmm_address                 ;
    logic                 [63:0]                 pio_csr_avmm_writedata               ;
    logic                 [7:0]                  pio_csr_avmm_byteenable              ;
    logic                                        pio_csr_avmm_poison                  ;
    // Dummy readdatavalid for PIO CSR port (1-cycle delayed from read)
    logic                                        pio_csr_dummy_rdv                    ;
    logic                                        pio_txc_ready                        ;
    logic                                        pio_txc_eop                          ; //PIO outputs                                                   
    logic                                        pio_txc_sop                          ;                                                    
    logic                 [127:0]                pio_txc_header                       ;                                                    
    logic                 [255:0]                pio_txc_payload                      ;                                                    
    logic                                        pio_txc_valid                        ;                                                    
    logic                                        pio_tx_st_ready_i                    ;                                                    
    logic 	                                 np_ca_rx_sop                         ; //CA output from AER
    logic 	                                 np_ca_rx_eop                         ;
    logic 	                                 np_ca_rx_hvalid                      ;
    logic 	                                 np_ca_rx_dvalid                      ;
    logic 	          [127:0]                np_ca_rx_header                      ;
    logic 	          [255:0]                np_ca_rx_data                        ;
    logic                 [2:0]                  default_config_rx_bar                ; //Default config inputs                                                   
    logic                                        default_config_rx_eop                ;                                                    
    logic                 [127:0]                default_config_rx_header             ;                                                    
    logic                 [255:0]                default_config_rx_payload            ;                                                    
    logic                                        default_config_rx_sop                ;                                                    
    logic                                        default_config_rx_hvalid             ;                                                    
    logic                                        default_config_rx_valid              ;                                                    
    logic                                        default_config_rx_dvalid             ;                                                    
    logic                                        default_config_rx_passthrough        ;                                                    
    logic                                        default_config_rx_ready              ;                                                    
    logic                 [127:0]                default_config_tx_st_header_update   ; //Default config outputs                                                   
    logic                 [127:0]                default_config_txc_header            ;                                                    
    logic                                        default_config_txc_eop               ;                                                    
    logic                 [255:0]                default_config_txc_payload           ;                                                    
    logic                                        default_config_txc_sop               ;                                                    
    logic                                        default_config_txc_valid             ;                                                    
    logic                                        dc_bam_rx_signal_ready_o             ;                                                    
    logic                                        dc_tx_hdr_valid_o                    ;                                                    
    logic                                        dc_tx_hdr_valid                      ;                                                    
    logic                                        default_config_tx_st0_passthrough_i  ;                                                    
    logic                                        default_config_tx_st1_passthrough_i  ;                                                    
    logic                                        default_config_tx_st2_passthrough_i  ;                                                    
    logic                                        default_config_tx_st3_passthrough_i  ;                                                    
    logic                 [2:0]                  afu_rx_bar                           ; //Inputs to axi_avst bridge                                                   
    logic                                        afu_rx_eop                           ;                                                    
    logic                 [127:0]                afu_rx_hdr                           ;                                                    
    logic                 [511:0]                afu_rx_data                          ;                                                    
    logic                                        afu_rx_sop                           ;                                                    
    logic                                        afu_rx_hvalid                        ;                                                    
    logic                                        afu_rx_dvalid                        ;                                                    
    logic                                        afu_rx_passthrough                   ;                                                    
    logic                                        afu_rx_ready                         ;                                                    
    logic                                        afu_tx_st0_dvalid_o                  ; //Outputs from axi_avst bridge                                              
    logic                                        afu_tx_st0_sop_o                     ;                                                    
    logic                                        afu_tx_st0_eop_o                     ;                                                    
    logic                 [511:0]                afu_tx_st0_data_o                    ;                                                    
    logic                 [127:0]                afu_tx_st0_hdr_o                     ;                                                    
    logic                                        afu_tx_st0_hvalid_o                  ;                                                    
    logic                                        afu_tx_st1_dvalid_o                  ;                                                    
    logic                                        afu_tx_st1_sop_o                     ;                                                    
    logic                                        afu_tx_st1_eop_o                     ;                                                    
    logic                 [255:0]                afu_tx_st1_data_o                    ;                                                    
    logic                 [127:0]                afu_tx_st1_hdr_o                     ;                                                    
    logic                                        afu_tx_st1_hvalid_o                  ;                                                    
    logic                                        afu_tx_st2_dvalid_o                  ;                                                    
    logic                                        afu_tx_st2_sop_o                     ;                                                    
    logic                                        afu_tx_st2_eop_o                     ;                                                    
    logic                 [255:0]                afu_tx_st2_data_o                    ;                                                    
    logic                 [127:0]                afu_tx_st2_hdr_o                     ;                                                    
    logic                                        afu_tx_st2_hvalid_o                  ;                                                    
    logic                                        wr_last                              ;
    logic                 [15:0]                 tx_p_data_counter                    ; //Credit counters for Tx side                                               
    logic                 [15:0]                 tx_np_data_counter                   ; //Credit counters for Tx side                                           
    logic                 [15:0]                 tx_cpl_data_counter                  ; //Credit counters for Tx side                                       
    logic                 [12:0]                 tx_p_header_counter                  ; //Credit counters for Tx side                                       
    logic                 [12:0]                 tx_np_header_counter                 ; //Credit counters for Tx side                       
    logic                 [12:0]                 tx_cpl_header_counter                ; //Credit counters for Tx side   
    logic                                        wr_tlp_fifo_empty                    ;                                                    
    logic                 [9:0]                  p_tlp_sent_tag                       ; //For Bresp of AFU.io
    logic                                        p_tlp_sent_tag_valid                 ;
    logic                 [127:0]                ed_rx_st0_header_update              ; //Reorder header                                                   
    logic                 [127:0]                ed_rx_st1_header_update              ; //Reorder header                                                   
    logic                 [127:0]                ed_rx_st2_header_update              ; //Reorder header                                                   
    logic                 [127:0]                ed_rx_st3_header_update              ; //Reorder header                                                   
    logic                                        avst4to1_rx_data_avail[1-1:0]        ;                                                    
    logic                                        avst4to1_rx_hdr_avail[1-1:0]         ;                                                    
    logic                                        avst4to1_rx_nph_hdr_avail[1-1:0]     ;                                                    
    logic                                        avst4to1_np_hdr_crd_pop              ; //Return credit for NP                                                   
    logic                 [15:0]                 ed_rx_dw_valid[1-1:0]                ;                                                    
    logic                 [127:0]                ed_rx_header_update                  ; //Reorder header from AVST4to1                                                   
    logic                                        Mem_Wr_tlp                           ; //Detect if TLP is Mem_Wr                                                   
    logic                                        Msg_tlp                              ; //Detect if TLP is Msg                                                   
    logic                                        MsgD_tlp                             ; //Detect if TLP is Msg_D                                                    
    logic                                        Cpl_tlp                              ; //Detect if TLP is Cpl                                                    
    logic                                        CplD_tlp                             ; //Detect if TLP is CplD                                                    
    logic                                        p_or_cpl_tlp                         ; //Detect if TLP is posted or completion                                                    
    logic                 [9:0]                  tx_hdr                               ; //Length of header                                                   
    logic                                        tx_hdr_valid                         ; //Valid for header length                                                   
    logic                 [7:0]                  tx_hdr_type                          ; //Type of TLP                                                   
    logic                 [127:0]                pio_txc_header_update                ; //Reorder header from PIO                                                   
    logic                 [9:0]                  dc_hdr_len_o                         ; //Default Config output signals                                                    
    logic                                        dc_hdr_valid_o                       ;                                                    
    logic                                        dc_hdr_is_rd_o                       ;                                                    
    logic                                        dc_hdr_is_rd_with_data_o             ;                                                    
    logic                                        dc_hdr_is_wr_o                       ;                                                    
    avst4to1_if                                  p0_pld_if()                          ;                                                                                         


   //From cfg to ATE
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_ENGINE_CTRL_t            afu_ate_ctrl ;
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_ENGINE_FORCE_DISABLE_t   afu_ate_force_disable ;
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_ENGINE_INITIATE_t        afu_ate_initiate ;
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_ATTR_BYTE_EN_t           afu_ate_attr_byte_en ;
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_TARGET_ADDRESS_t         afu_ate_target_address ;
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_COMPARE_VALUE_0_t        afu_ate_compare_value_0 ;
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_COMPARE_VALUE_1_t        afu_ate_compare_value_1 ;
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_SWAP_VALUE_0_t           afu_ate_swap_value_0 ;
   tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_SWAP_VALUE_1_t           afu_ate_swap_value_1 ;
   
   //From ATE to config
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_ENGINE_STATUS_t      afu_ate_status ;
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_0_t  afu_ate_read_data_value_0 ;
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_1_t  afu_ate_read_data_value_1 ;
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_2_t  afu_ate_read_data_value_2 ;
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_3_t  afu_ate_read_data_value_3 ;
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_4_t  afu_ate_read_data_value_4 ;
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_5_t  afu_ate_read_data_value_5 ;
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_6_t  afu_ate_read_data_value_6 ;
   tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_7_t  afu_ate_read_data_value_7 ;
   
   //usr csr decode for target memory
   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_GBL_CTRL_t                       hdm_dec_gbl_ctrl  ;
   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_CTRL_t                           hdm_dec_ctrl      ;
   tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1HIGH_t                     dvsec_fbrange1high;
   tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1LOW_t                      dvsec_fbrange1low ;
   tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZHIGH_t                   fbrange1_sz_high  ;
   tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZLOW_t                    fbrange1_sz_low   ;
   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_BASEHIGH_t                       hdm_dec_basehigh  ;
   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_BASELOW_t                        hdm_dec_baselow   ;
   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_SIZEHIGH_t                       hdm_dec_sizehigh  ;
   tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_SIZELOW_t                        hdm_dec_sizelow   ;


  /* only supporting the axi4 for HDM memory traffic to/from IP
   */
  /* External MC_TOP <--> CXL-IP - write address channels
   */
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        ip2hdm_aximm_awvalid  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_ID_BW-1:0]     ip2hdm_aximm_awid  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_ADDR_BW-1:0]   ip2hdm_aximm_awaddr  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_BLEN_BW-1:0]   ip2hdm_aximm_awlen  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_REGION_BW-1:0] ip2hdm_aximm_awregion  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_USER_BW-1:0]   ip2hdm_aximm_awuser  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]   ip2hdm_aximm_awsize  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]  ip2hdm_aximm_awburst  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]   ip2hdm_aximm_awprot  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]    ip2hdm_aximm_awqos  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]  ip2hdm_aximm_awcache  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]   ip2hdm_aximm_awlock  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        hdm2ip_aximm_awready  ;   
  /* External MC_TOP <--> CXL-IP - write data channel
   */
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_wvalid  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_DATA_BW-1:0] ip2hdm_aximm_wdata  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_STRB_BW-1:0] ip2hdm_aximm_wstrb  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_wlast  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_USER_BW-1:0] ip2hdm_aximm_wuser  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_wready  ;		  
  /* External MC_TOP <--> CXL-IP - write response channel
   */
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_bvalid  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_ID_BW-1:0]   hdm2ip_aximm_bid  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_USER_BW-1:0] hdm2ip_aximm_buser  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_bresp  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_bready  ;  
  /* External MC_TOP <--> CXL-IP - read address channel
   */
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        ip2hdm_aximm_arvalid  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_ID_BW-1:0]     ip2hdm_aximm_arid  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_ADDR_BW-1:0]   ip2hdm_aximm_araddr  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_BLEN_BW-1:0]   ip2hdm_aximm_arlen  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_REGION_BW-1:0] ip2hdm_aximm_arregion  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_USER_BW-1:0]   ip2hdm_aximm_aruser  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]   ip2hdm_aximm_arsize  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]  ip2hdm_aximm_arburst  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]   ip2hdm_aximm_arprot  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]    ip2hdm_aximm_arqos  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]  ip2hdm_aximm_arcache  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]   ip2hdm_aximm_arlock  ;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        hdm2ip_aximm_arready  ;  
  /* External MC_TOP <--> CXL-IP - read response channel
   */
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_rvalid  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_rlast  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_ID_BW-1:0]   hdm2ip_aximm_rid  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_DATA_BW-1:0] hdm2ip_aximm_rdata  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_USER_BW-1:0] hdm2ip_aximm_ruser  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_rresp  ;
   logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_rready   ;

// signal_assign
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MEMSIZE_WIDTH-1:0] mc_chan_memsize;
  
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_BURST_WIDTH-1:0] emif_amm_burstcount;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] emif_amm_address;
  /* Signals for M-Series: axi4 fabric connection for DDR5/HBMe2
  */
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] noc2hdm_aximm_awready_emifclk;
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] hdm2noc_aximm_awlen_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_REGION_WIDTH-1:0]           hdm2noc_aximm_awregion_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_AWATOP_WIDTH-1:0]           hdm2noc_aximm_awtop_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]            hdm2noc_aximm_awburst_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]            hdm2noc_aximm_awcache_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]             hdm2noc_aximm_awlock_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]             hdm2noc_aximm_awprot_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]              hdm2noc_aximm_awqos_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]             hdm2noc_aximm_awsize_emifclk;
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_AWADDR_BW-1:0] hdm2noc_aximm_awaddr_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_AWID_BW-1:0]   hdm2noc_aximm_awid_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_AWUSER_BW-1:0] hdm2noc_aximm_awuser_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                        hdm2noc_aximm_awvalid_emifclk;

  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] noc2hdm_aximm_wready_emifclk;
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_WDATA_BW-1:0]   hdm2noc_aximm_wdata_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                         hdm2noc_aximm_wlast_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_WSTRB_BW-1:0]   hdm2noc_aximm_wstrb_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_WUSER_t_BW-1:0] hdm2noc_aximm_wuser_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                         hdm2noc_aximm_wvalid_emifclk;
  
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] noc2hdm_aximm_arready_emifclk;
  
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] hdm2noc_aximm_arlen_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_REGION_WIDTH-1:0]           hdm2noc_aximm_arregion_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]            hdm2noc_aximm_arburst_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]            hdm2noc_aximm_arcache_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]             hdm2noc_aximm_arlock_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]             hdm2noc_aximm_arprot_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]              hdm2noc_aximm_arqos_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]             hdm2noc_aximm_arsize_emifclk;

  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_ARADDR_BW-1:0] hdm2noc_aximm_araddr_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_ARID_BW-1:0]   hdm2noc_aximm_arid_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_ARUSER_BW-1:0] hdm2noc_aximm_aruser_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                        hdm2noc_aximm_arvalid_emifclk; 
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2noc_aximm_bready_emifclk;
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] noc2hdm_aximm_bresp_emifclk;
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_BID_BW-1:0]   noc2hdm_aximm_bid_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_BUSER_BW-1:0] noc2hdm_aximm_buser_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                       noc2hdm_aximm_bvalid_emifclk; 
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2noc_aximm_rready_emifclk;
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] noc2hdm_aximm_rresp_emifclk;
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_RDATA_BW-1:0]   noc2hdm_aximm_rdata_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_RID_BW-1:0]     noc2hdm_aximm_rid_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                         noc2hdm_aximm_rlast_emifclk;  
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][hdm_axi_if_pkg::HDM_AXI_RUSER_t_BW-1:0] noc2hdm_aximm_ruser_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                         noc2hdm_aximm_rvalid_emifclk;
  
  /* emif clk in, emif reset in
     emif calibration signals for going to cafu_csr0_cfg space
  */
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emifresetn;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_pll_locked;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_reset_done;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_cal_success;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif_cal_fail;
  
  `ifdef HDM_SIM_CFG_USE_BASIC_MEM
     logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] mem_address_rmw_emifclk;
  `endif
  
  /* AVMM signals from emif
  */
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] emif2hdm_avmm_readdata_emifclk;
 
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif2hdm_avmm_readdatavalid_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif2hdm_avmm_ready_emifclk;

  /* AVMM signals to emif
  */
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] hdm2emif_avmm_writedata_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_BE_WIDTH-1:0]   hdm2emif_avmm_byteenable_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] hdm2emif_avmm_address_emifclk;

  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2emif_avmm_write_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2emif_avmm_read_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] hdm2emif_avmm_write_poison_emifclk;
  logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0] emif2hdm_avmm_read_poison_emifclk;
  logic emif_avmm_1_axi_0;

  // Connected to the poison sidecar in the following implementation task.
  assign emif2hdm_avmm_read_poison_emifclk = '0;


//-------------------------------------------------------
// Assignments                                  --
//-------------------------------------------------------
//=====================================================
 logic             cxl_reset ;
 logic             cxl_reset_n;
 logic             usr2ip_cxlreset_ack_d1;
 logic             cxl_or_conv_rst_n;


//Adding logic for cxl_reset and generate conventional_or_CXL reset
// This is logic detects the negedge event usr2ip_cxlreset_ack , and make it
// active low
 always @(posedge ip2hdm_clk) begin
  if(!ip2hdm_reset_n) begin
     usr2ip_cxlreset_ack_d1 <= 1'b0 ;
  end 
  else begin
     usr2ip_cxlreset_ack_d1 <= usr2ip_cxlreset_ack ;
  end      
end 

assign cxl_reset = usr2ip_cxlreset_ack_d1 && ~usr2ip_cxlreset_ack ;
assign cxl_reset_n = !cxl_reset ;
//cxl or conventional reset is generated by using 2 active low events and
//anding it 
assign cxl_or_conv_rst_n  = cxl_reset_n && ip2hdm_reset_n ; 
//=======================================================

//chip ID (device serial number) will be exported to Example design as an input and user can drive this signal based on avmm clk 
assign  dev_serial_num                           =  64'd0                                        ;
assign  dev_serial_num_valid                     =  1'b1                                         ;

assign  usr2ip_debug_writedata                   = '0                                            ;   
assign  usr2ip_debug_address                     = '0                                            ;   
assign  usr2ip_debug_write                       = '0                                            ;
assign  usr2ip_debug_read                        = '0                                            ;
assign  usr2ip_debug_byteenable                  = '0                                            ;

assign  afu_axi_aw.awsize                        =   t_cafu_axi4_burst_size_encoding'(afu_axi_awsize)  ;
assign  afu_axi_aw.awburst                       =   t_cafu_axi4_burst_encoding'(afu_axi_awburst)      ;
assign  afu_axi_aw.awprot                        =   t_cafu_axi4_prot_encoding'(afu_axi_awprot)        ;
assign  afu_axi_aw.awqos                         =   t_cafu_axi4_qos_encoding'(afu_axi_awqos)          ;
assign  afu_axi_aw.awcache                       =   t_cafu_axi4_awcache_encoding'(afu_axi_awcache)    ;
assign  afu_axi_aw.awlock                        =   t_cafu_axi4_lock_encoding'(afu_axi_awlock)        ;
assign  afu_axi_ar.arsize                        =   t_cafu_axi4_burst_size_encoding'(afu_axi_arsize)  ;
assign  afu_axi_ar.arburst                       =   t_cafu_axi4_burst_encoding'(afu_axi_arburst)      ;
assign  afu_axi_ar.arprot                        =   t_cafu_axi4_prot_encoding'(afu_axi_arprot)        ;
assign  afu_axi_ar.arqos                         =   t_cafu_axi4_qos_encoding'(afu_axi_arqos)          ;
assign  afu_axi_ar.arcache                       =   t_cafu_axi4_arcache_encoding'(afu_axi_arcache)    ;
assign  afu_axi_ar.arlock                        =   t_cafu_axi4_lock_encoding'(afu_axi_arlock)        ;

assign  cafu2ip_quiesce_ack                      =  ip2cafu_quiesce_req_ff                       ; 

assign  afu_cache_io_select                      =  cafu_user_enabled_cxl_io                     ;
assign  afu_pio_select                           =  afu_cache_io_select                          ;
     
assign  avst4to1_rx_data_avail[0]                =  1'b1                                         ;
assign  avst4to1_rx_hdr_avail[0]                 =  1'b1                                         ;
assign  avst4to1_rx_nph_hdr_avail[0]             =  1'b1                                         ;
assign  p0_pld_if.rx_st_sop_s0_o                 =  ed_rx_st0_sop_i                              ;
assign  p0_pld_if.rx_st_sop_s1_o                 =  ed_rx_st1_sop_i                              ;
assign  p0_pld_if.rx_st_sop_s2_o                 =  ed_rx_st2_sop_i                              ;
assign  p0_pld_if.rx_st_sop_s3_o                 =  ed_rx_st3_sop_i                              ;
assign  p0_pld_if.rx_st_eop_s0_o                 =  ed_rx_st0_eop_i                              ;
assign  p0_pld_if.rx_st_eop_s1_o                 =  ed_rx_st1_eop_i                              ;
assign  p0_pld_if.rx_st_eop_s2_o                 =  ed_rx_st2_eop_i                              ;
assign  p0_pld_if.rx_st_eop_s3_o                 =  ed_rx_st3_eop_i                              ;
assign  p0_pld_if.rx_st_empty_s0_o               =  ed_rx_st0_empty_i                            ;
assign  p0_pld_if.rx_st_empty_s1_o               =  ed_rx_st1_empty_i                            ;
assign  p0_pld_if.rx_st_empty_s2_o               =  ed_rx_st2_empty_i                            ;
assign  p0_pld_if.rx_st_empty_s3_o               =  ed_rx_st3_empty_i                            ;
assign  p0_pld_if.rx_st_data_s0_o                =  ed_rx_st0_payload_i                          ;
assign  p0_pld_if.rx_st_data_s1_o                =  ed_rx_st1_payload_i                          ;
assign  p0_pld_if.rx_st_data_s2_o                =  ed_rx_st2_payload_i                          ;
assign  p0_pld_if.rx_st_data_s3_o                =  ed_rx_st3_payload_i                          ;
assign  p0_pld_if.rx_st_data_par_s0_o            =  ed_rx_st0_data_parity_i                      ;
assign  p0_pld_if.rx_st_data_par_s1_o            =  ed_rx_st1_data_parity_i                      ;
assign  p0_pld_if.rx_st_data_par_s2_o            =  ed_rx_st2_data_parity_i                      ;
assign  p0_pld_if.rx_st_data_par_s3_o            =  ed_rx_st3_data_parity_i                      ;
assign  p0_pld_if.rx_st_dvalid_s0_o              =  ed_rx_st0_dvalid_i                           ;
assign  p0_pld_if.rx_st_dvalid_s1_o              =  ed_rx_st1_dvalid_i                           ;
assign  p0_pld_if.rx_st_dvalid_s2_o              =  ed_rx_st2_dvalid_i                           ;
assign  p0_pld_if.rx_st_dvalid_s3_o              =  ed_rx_st3_dvalid_i                           ;
assign  p0_pld_if.rx_st_hdr_s0_o                 =  ed_rx_st0_header_i                           ;
assign  p0_pld_if.rx_st_hdr_s1_o                 =  ed_rx_st1_header_i                           ;
assign  p0_pld_if.rx_st_hdr_s2_o                 =  ed_rx_st2_header_i                           ;
assign  p0_pld_if.rx_st_hdr_s3_o                 =  ed_rx_st3_header_i                           ;
assign  p0_pld_if.rx_st_hdr_par_s0_o             =  ed_rx_st0_hdr_parity_i                       ;
assign  p0_pld_if.rx_st_hdr_par_s1_o             =  ed_rx_st1_hdr_parity_i                       ;
assign  p0_pld_if.rx_st_hdr_par_s2_o             =  ed_rx_st2_hdr_parity_i                       ;
assign  p0_pld_if.rx_st_hdr_par_s3_o             =  ed_rx_st3_hdr_parity_i                       ;
assign  p0_pld_if.rx_st_hvalid_s0_o              =  ed_rx_st0_hvalid_i                           ;
assign  p0_pld_if.rx_st_hvalid_s1_o              =  ed_rx_st1_hvalid_i                           ;
assign  p0_pld_if.rx_st_hvalid_s2_o              =  ed_rx_st2_hvalid_i                           ;
assign  p0_pld_if.rx_st_hvalid_s3_o              =  ed_rx_st3_hvalid_i                           ;
assign  p0_pld_if.rx_st_tlp_prfx_s0_o            =  ed_rx_st0_tlp_prfx_i                         ;
assign  p0_pld_if.rx_st_tlp_prfx_s1_o            =  ed_rx_st1_tlp_prfx_i                         ;
assign  p0_pld_if.rx_st_tlp_prfx_s2_o            =  ed_rx_st2_tlp_prfx_i                         ;
assign  p0_pld_if.rx_st_tlp_prfx_s3_o            =  ed_rx_st3_tlp_prfx_i                         ;
assign  p0_pld_if.rx_st_tlp_prfx_par_s0_o        =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_prfx_par_s1_o        =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_prfx_par_s2_o        =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_prfx_par_s3_o        =  '0                                           ;
assign  p0_pld_if.rx_st_pvalid_s0_o              =  ed_rx_st0_pvalid_i                           ;
assign  p0_pld_if.rx_st_pvalid_s1_o              =  ed_rx_st1_pvalid_i                           ;
assign  p0_pld_if.rx_st_pvalid_s2_o              =  ed_rx_st2_pvalid_i                           ;
assign  p0_pld_if.rx_st_pvalid_s3_o              =  ed_rx_st3_pvalid_i                           ;
assign  p0_pld_if.rx_st_bar_s0_o                 =  ed_rx_st0_bar_i                              ;
assign  p0_pld_if.rx_st_bar_s1_o                 =  ed_rx_st1_bar_i                              ;
assign  p0_pld_if.rx_st_bar_s2_o                 =  ed_rx_st2_bar_i                              ;
assign  p0_pld_if.rx_st_bar_s3_o                 =  ed_rx_st3_bar_i                              ;
assign  p0_pld_if.rx_st_passthrough_s0_o         =  ed_rx_st0_passthrough_i                      ;
assign  p0_pld_if.rx_st_passthrough_s1_o         =  ed_rx_st1_passthrough_i                      ;
assign  p0_pld_if.rx_st_passthrough_s2_o         =  ed_rx_st2_passthrough_i                      ;
assign  p0_pld_if.rx_st_passthrough_s3_o         =  ed_rx_st3_passthrough_i                      ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_s0_o      =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_s1_o      =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_s2_o      =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_s3_o      =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_par_s0_o  =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_par_s1_o  =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_par_s2_o  =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_par_s3_o  =  '0                                           ;
assign  p0_pld_if.rx_st_vfactive_s0_o            =  '0                                           ;
assign  p0_pld_if.rx_st_vfactive_s1_o            =  '0                                           ;
assign  p0_pld_if.rx_st_vfactive_s2_o            =  '0                                           ;
assign  p0_pld_if.rx_st_vfactive_s3_o            =  '0                                           ;
assign  p0_pld_if.rx_st_vfnum_s0_o               =  '0                                           ;
assign  p0_pld_if.rx_st_vfnum_s1_o               =  '0                                           ;
assign  p0_pld_if.rx_st_vfnum_s2_o               =  '0                                           ;
assign  p0_pld_if.rx_st_vfnum_s3_o               =  '0                                           ;
assign  p0_pld_if.rx_st_pfnum_s0_o               =  '0                                           ;
assign  p0_pld_if.rx_st_pfnum_s1_o               =  '0                                           ;
assign  p0_pld_if.rx_st_pfnum_s2_o               =  '0                                           ;
assign  p0_pld_if.rx_st_pfnum_s3_o               =  '0                                           ;
assign  p0_pld_if.rx_Hcrdt_init_ack              =  rx_st_hcrdt_init_ack_i                       ;
assign  p0_pld_if.rx_Dcrdt_init_ack              =  rx_st_dcrdt_init_ack_i                       ;
assign  rx_st_hcrdt_update_cnt_o                 =  p0_pld_if.rx_Hcrdt_update_cnt                ;
assign  rx_st_hcrdt_update_o                     =  p0_pld_if.rx_Hcrdt_update                    ;
assign  rx_st_hcrdt_init_o                       =  p0_pld_if.rx_Hcrdt_init                      ;
assign  rx_st_dcrdt_update_cnt_o                 =  p0_pld_if.rx_Dcrdt_update_cnt                ;
assign  rx_st_dcrdt_update_o                     =  p0_pld_if.rx_Dcrdt_update                    ;
assign  rx_st_dcrdt_init_o                       =  p0_pld_if.rx_Dcrdt_init                      ;
    
// AXI-MM interface - write address channel
assign  axi0_awid                                =  afu_cache_axi_aw.awid                        ;
assign  axi0_awaddr                              =  afu_cache_axi_aw.awaddr                      ;
assign  axi0_awlen                               =  afu_cache_axi_aw.awlen                       ;
assign  axi0_awsize                              =  afu_cache_axi_aw.awsize                      ;
assign  axi0_awburst                             =  afu_cache_axi_aw.awburst                     ;
assign  axi0_awprot                              =  afu_cache_axi_aw.awprot                      ;
assign  axi0_awqos                               =  afu_cache_axi_aw.awqos                       ;
assign  axi0_awuser                              =  afu_cache_axi_aw.awuser                      ;
assign  axi0_awvalid                             =  afu_cache_axi_aw.awvalid                     ;
assign  axi0_awcache                             =  afu_cache_axi_aw.awcache                     ;
assign  axi0_awlock                              =  afu_cache_axi_aw.awlock                      ;
assign  axi0_awregion                            =  afu_cache_axi_aw.awregion                    ;
assign  axi0_awatop                              =  6'b000000                                    ;
assign  afu_cache_axi_awready                    =  axi0_awready                                 ;
  
//      AXI-MM_interface_write_data_channel                                                      
assign  axi0_wdata                               =  afu_cache_axi_w.wdata                        ;
assign  axi0_wstrb                               =  afu_cache_axi_w.wstrb                        ;
assign  axi0_wlast                               =  afu_cache_axi_w.wlast                        ;
assign  axi0_wuser                               =  afu_cache_axi_w.wuser                        ;
assign  axi0_wvalid                              =  afu_cache_axi_w.wvalid                       ;
assign  afu_cache_axi_wready                     =  axi0_wready                                  ;

//  AXI-MM interface - write response channel
assign  afu_cache_axi_b.bid                      =  axi0_bid                                     ;
assign  afu_cache_axi_b.bresp                    =  axi0_bresp == 'h0 ? eresp_CAFU_OKAY : eresp_CAFU_SLVERR;    
assign  afu_cache_axi_b.buser                    =  axi0_buser                                   ;
assign  afu_cache_axi_b.bvalid                   =  axi0_bvalid                                  ;
assign  axi0_bready                              =  afu_cache_axi_bready                         ;
  
//      AXI-MM_interface_read_address_channel                                                    
assign  axi0_arid                                =  afu_cache_axi_ar.arid                        ;
assign  axi0_araddr                              =  afu_cache_axi_ar.araddr                      ;
assign  axi0_arlen                               =  afu_cache_axi_ar.arlen                       ;
assign  axi0_arsize                              =  afu_cache_axi_ar.arsize                      ;
assign  axi0_arburst                             =  afu_cache_axi_ar.arburst                     ;
assign  axi0_arprot                              =  afu_cache_axi_ar.arprot                      ;
assign  axi0_arqos                               =  afu_cache_axi_ar.arqos                       ;
assign  axi0_aruser                              =  afu_cache_axi_ar.aruser                      ;
assign  axi0_arvalid                             =  afu_cache_axi_ar.arvalid                     ;
assign  axi0_arcache                             =  afu_cache_axi_ar.arcache                     ;
assign  axi0_arlock                              =  afu_cache_axi_ar.arlock                      ;
assign  axi0_arregion                            =  afu_cache_axi_ar.arregion                    ;
assign  afu_cache_axi_arready                    =  axi0_arready                                 ;

//      AXI-MM_interface_read_response_channel                                                   
assign  afu_cache_axi_r.rid                      =  axi0_rid                                     ;
assign  afu_cache_axi_r.rdata                    =  axi0_rdata                                   ;
assign  afu_cache_axi_r.rresp                    =  axi0_rresp == 'h0 ? eresp_CAFU_OKAY : eresp_CAFU_SLVERR;  
assign  afu_cache_axi_r.rlast                    =  axi0_rlast                                   ;
assign  afu_cache_axi_r.ruser                    =  axi0_ruser                                   ;
assign  afu_cache_axi_r.rvalid                   =  axi0_rvalid                                  ;
assign  axi0_rready                              =  afu_cache_axi_rready                         ;

assign  ed_rx_st0_chnum_i                        =  '0                                           ;
assign  ed_rx_st1_chnum_i                        =  '0                                           ;
assign  ed_rx_st2_chnum_i                        =  '0                                           ;
assign  ed_rx_st3_chnum_i                        =  '0                                           ;
assign  ed_rx_st0_vfnum_i                        =  '0                                           ;
assign  ed_rx_st1_vfnum_i                        =  '0                                           ;
assign  ed_rx_st2_vfnum_i                        =  '0                                           ;
assign  ed_rx_st3_vfnum_i                        =  '0                                           ;
assign  ed_rx_st0_vfactive_i                     =  '0                                           ;
assign  ed_rx_st1_vfactive_i                     =  '0                                           ;
assign  ed_rx_st2_vfactive_i                     =  '0                                           ;
assign  ed_rx_st3_vfactive_i                     =  '0                                           ;
assign  ed_rx_hvalid                             =  ed_rx_sop[0] & (|ed_rx_header[0])            ;                                                                
assign  ed_rx_sop_i                              =  ed_rx_sop[0]                                 ;
assign  ed_rx_eop_i                              =  ed_rx_eop[0]                                 ;
assign  pio_txc_header_update                    =  {pio_txc_header[31:0],pio_txc_header[63:32],pio_txc_header[95:64],pio_txc_header[127:96]} ;
assign  tx_hdr                                   =  ed_tx_st0_hvalid_o ? ed_tx_st0_header_o[105:96] : 10'h0                                   ;                          
assign  tx_hdr_valid                             =  ed_tx_st0_hvalid_o                                                                        ;
assign  tx_hdr_type                              =  ed_tx_st0_hvalid_o ? ed_tx_st0_header_o[127:120] : 8'h0                                   ;                          
assign  ed_rx_st0_header_update                  =  {ed_rx_st0_header_i[31:0],ed_rx_st0_header_i[63:32],ed_rx_st0_header_i[95:64],ed_rx_st0_header_i[127:96]}  ;
assign  ed_rx_st1_header_update                  =  {ed_rx_st1_header_i[31:0],ed_rx_st1_header_i[63:32],ed_rx_st1_header_i[95:64],ed_rx_st1_header_i[127:96]}  ;
assign  ed_rx_st2_header_update                  =  {ed_rx_st2_header_i[31:0],ed_rx_st2_header_i[63:32],ed_rx_st2_header_i[95:64],ed_rx_st2_header_i[127:96]}  ;
assign  ed_rx_st3_header_update                  =  {ed_rx_st3_header_i[31:0],ed_rx_st3_header_i[63:32],ed_rx_st3_header_i[95:64],ed_rx_st3_header_i[127:96]}  ;
assign  ed_rx_valid                              =  |ed_rx_dw_valid[0]                           ;
assign  Mem_Wr_tlp                               =  (ed_rx_header_update[31:29]==3'b010 || ed_rx_header_update[31:29]==3'b011) && (ed_rx_header_update[28:24]==5'h0);                 
assign  Msg_tlp                                  =  (ed_rx_header_update[31:29]==3'b001) && (ed_rx_header_update[28:27]==2'b10);                
assign  MsgD_tlp                                 =  (ed_rx_header_update[31:29]==3'b011) && (ed_rx_header_update[28:27]==2'b10);                
assign  CplD_tlp                                 =  (ed_rx_header_update[31:24]==8'h4A)          ;                                                                
assign  Cpl_tlp                                  =  (ed_rx_header_update[31:24]==8'hA)           ;                                                                
assign  p_or_cpl_tlp                             =  Mem_Wr_tlp || Msg_tlp || MsgD_tlp ||  CplD_tlp  ||  Cpl_tlp  ;
assign  {default_config_tx_st_header_update[31:0],default_config_tx_st_header_update[63:32],default_config_tx_st_header_update[95:64],default_config_tx_st_header_update[127:96]} =  default_config_txc_header ;                              	
assign  ed_rx_header_update                      = {ed_rx_header[0][103:96], ed_rx_header[0][111:104],ed_rx_header[0][119:112], ed_rx_header[0][127:120],  
                                                    ed_rx_header[0][71:64],  ed_rx_header[0][79:72],   ed_rx_header[0][87:80],   ed_rx_header[0][95:88],   
                                                    ed_rx_header[0][39:32],  ed_rx_header[0][47:40],   ed_rx_header[0][55:48],   ed_rx_header[0][63:56],   
                                                    ed_rx_header[0][7:0],    ed_rx_header[0][15:8],    ed_rx_header[0][23:16],   ed_rx_header[0][31:24] };   

  assign   usr2ip_qos_devload = 2'b00;

  assign   cafu2ip_axistd0_tready = 1'b1;
  assign   cafu2ip_axistd1_tready = 1'b1;
  assign   cafu2ip_axisth0_tready = 1'b1;
  assign   cafu2ip_axisth1_tready = 1'b1;

//--------------------------------------------------------------------
// DDR Memory Controller assignments
//--------------------------------------------------------------------
// ================================================================================================

//HDM SIZE
// Total amount of HDM expressed as a multiple of 256MB.
// This is a CXL-IP input and is used to advertise HDM size via CXL-IP DVSEC registers.
//
// HDM Size  hdm_size_256mb
// --------  --------------
//  256MB       36'h001
//  512MB       36'h002
//    1GB       36'h004
//    2GB       36'h008
//    4GB       36'h010
//    8GB       36'h020
//   16GB       36'h040
//   32GB       36'h080
//   64GB       36'h100
//  128GB       36'h200
//  256GB       36'h400
//  512GB       36'h800
//  (etc.)      (etc.)


`ifdef HDM_64G
      assign hdm_size_256mb = 36'h100;// HDM_64G
`else
      assign hdm_size_256mb = 36'h40; // HDM_16G
`endif



/* i/o signal that user should set for selecting between AVMM and AXI for HDM access
     non-clocked signal, tied to 1 or 0
*/

assign emif_avmm_1_axi_0 = 1'b1; 



  always_ff @(posedge ip2hdm_clk) begin
    mc_sr_status_eclk_Q <= mc_status ; //mc_sr_status_eclk;
  end

  generate
    if (ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL == 2) begin : GenMc2
      assign ddr_mc_status.mc0_status = {11'b0,mc_sr_status_eclk_Q[0]};
      assign ddr_mc_status.mc1_status = {11'b0,mc_sr_status_eclk_Q[1]};
      assign mc_mem_active = mc_sr_status_eclk_Q[0][4] & mc_sr_status_eclk_Q[1][4];
    end
    else if (ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL == 4) begin : GenMc4
      assign ddr_mc_status.mc0_status = {3'b000,mc_sr_status_eclk_Q[2],3'b000,mc_sr_status_eclk_Q[0]};
      assign ddr_mc_status.mc1_status = {3'b000,mc_sr_status_eclk_Q[3],3'b000,mc_sr_status_eclk_Q[1]};
      assign mc_mem_active = mc_sr_status_eclk_Q[0][4] & mc_sr_status_eclk_Q[1][4] & mc_sr_status_eclk_Q[2][4] & mc_sr_status_eclk_Q[3][4] ;
    end
    else begin : GenMc1
      assign ddr_mc_status.mc0_status = {11'b0,mc_sr_status_eclk_Q[0]};
      assign ddr_mc_status.mc1_status = '0;
      assign mc_mem_active = mc_sr_status_eclk_Q[0][4];
    end
  endgenerate

  assign mem_dev_status = {5'b00010, mc_mem_active, 2'b00};

  generate for( genvar chanCount = 0; chanCount < ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL; chanCount=chanCount+1 )
  begin : GEN_CHAN_MEMSIZE_BURSTCOUNT
    //    assign mc_chan_memsize[chanCount] = 64'h20_0000_0000;  // 128 GB
    //    assign mc_chan_memsize[chanCount] = 64'h8_0000_0000;  // 32 GB
    //    assign mc_chan_memsize[chanCount] = 64'h2_0000_0000;  // 8 GB
    // == memory channel size in bytes (assuming 512 bit words, not counting 64 ECC bits) ==
    assign mc_chan_memsize[chanCount] = (2**(ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH)) << 6;  // shift left by 6 as each row has 64 bytes

    assign emif_amm_burstcount[chanCount] = {{ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_BURST_WIDTH-1{1'b0}},1'b1};
	
    assign emif_amm_address[chanCount] = hdm2emif_avmm_address_emifclk[chanCount][ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0];
  end
  endgenerate


  always_comb // Size (in bytes) of memory exposed to BIOS (assigned constant value)
  begin
    mc2ip_memsize = 0;
    for (int i=0; i < ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL ; i=i+1)
    begin
`ifndef DRAM_DISABLE
      mc2ip_memsize = mc2ip_memsize + mc_chan_memsize[i];
`else
      mc2ip_memsize = 64'h2_0000_0000;
`endif
    end
  end
  
  assign noc2hdm_aximm_awready_emifclk   = '0 ;
  assign noc2hdm_aximm_wready_emifclk    = '0 ;
  assign noc2hdm_aximm_arready_emifclk   = '0 ;
  assign noc2hdm_aximm_bresp_emifclk     = '0 ;
  assign noc2hdm_aximm_bid_emifclk       = '0 ;
  assign noc2hdm_aximm_buser_emifclk     = '0 ;
  assign noc2hdm_aximm_bvalid_emifclk    = '0 ; 
  assign noc2hdm_aximm_rresp_emifclk     = '0 ;
  assign noc2hdm_aximm_rdata_emifclk     = '0 ;
  assign noc2hdm_aximm_rid_emifclk       = '0 ;
  assign noc2hdm_aximm_rlast_emifclk     = '0 ;  
  assign noc2hdm_aximm_ruser_emifclk     = '0 ;
  assign noc2hdm_aximm_rvalid_emifclk    = '0 ;


always @(posedge ip2hdm_clk ) begin                 
    if(!ip2hdm_reset_n) begin                          
        ip2cafu_quiesce_req_f  <= 1'b0;                    
        ip2cafu_quiesce_req_ff <= 1'b0;                    
    end                                                
    else begin                                         
        ip2cafu_quiesce_req_f <= ip2cafu_quiesce_req;     
        ip2cafu_quiesce_req_ff <= ip2cafu_quiesce_req_f;  
    end                                                
end             

 //ED HANDSHAKE logic for CXL RESET, User can use this ip2usr_cxlreset_req to reset all the sticky registers in ED
 // ip2usr_cxlreset_req: This signal allows user logic to quiesce any logic related to CXL Reset.
 //                      This signal is asserted when CXL IP initiates CXL reset.This signal is 
 //                      deasserted once CXL reset sequence is complete.     
 //usr2ip_cxlreset_ack : When set,this signal indicates user logic has completed the CXL Reset quiescing.
 //                      User need to de assert this signal once the  âusr2ip_cxlreset_reqÂ´is deasserted.
 //                      CXL IP waits for de-assertion of this signal before setting âip2usr_cxlreset_completeâ or âip2usr_cxlreset_error â
  always @(posedge ip2hdm_clk) begin
  if(!ip2hdm_reset_n) begin           
    usr2ip_cxlreset_ack   <= 1'b0 ;
  end                           
  else begin                    
    usr2ip_cxlreset_ack   <= ip2usr_cxlreset_req;
  end                            
 end 
                                                                                                                                                                                                                 
always_ff@(posedge ip2hdm_clk) ip2hdm_reset_n_f <= ip2hdm_reset_n ;
always_ff@(posedge ip2hdm_clk) ip2hdm_reset_n_ff <= ip2hdm_reset_n_f ;

  //-------------------------------------------------------
  // Example design Modules instatances
  //-------------------------------------------------------

  //-------------------------------------------------------
  // AVMM address decode for CXL IP internal AVMM master (ip2cafu_avmm_*)
  // Routes GPU CSR requests (0x180100-0x18013C) to ex_default_csr_top
  // This works because 0x180000+ is properly routed by CXL IP (unlike vendor CSR)
  //-------------------------------------------------------
  logic gpu_csr_addr_hit;
  logic [21:0] gpu_csr_remapped_address;

  // Detect GPU CSR range: 0x180100-0x18013C
  // 0x180100 >> 8 = 0x1801, so [21:8] = 14'h181
  assign gpu_csr_addr_hit = (ip2cafu_avmm_address[21:8] == 14'h181) && (ip2cafu_avmm_address[7:2] < 6'h0F);

  // Remap 0x180100-0x18013C to 0x000100-0x00013C (where GPU CSR registers are defined)
  assign gpu_csr_remapped_address = gpu_csr_addr_hit ?
    {6'h0, 6'h01, ip2cafu_avmm_address[7:0]} :
    ip2cafu_avmm_address[21:0];

  // Signals to cafu_csr0_avmm_wrapper (CXL IP AVMM master, non-GPU range)
  logic        cafu_avmm_write_gated;
  logic        cafu_avmm_read_gated;
  logic [21:0] cafu_avmm_address_gated;

  assign cafu_avmm_write_gated = ip2cafu_avmm_write && !gpu_csr_addr_hit;
  assign cafu_avmm_read_gated  = ip2cafu_avmm_read  && !gpu_csr_addr_hit;
  assign cafu_avmm_address_gated = ip2cafu_avmm_address[21:0];

  // GPU CSR routing signals (to ex_default_csr_top via csr_avmm bus)
  logic        gpu_csr_avmm_write;
  logic        gpu_csr_avmm_read;
  logic [21:0] gpu_csr_avmm_address;

  assign gpu_csr_avmm_write   = ip2cafu_avmm_write && gpu_csr_addr_hit;
  assign gpu_csr_avmm_read    = ip2cafu_avmm_read  && gpu_csr_addr_hit;
  assign gpu_csr_avmm_address = gpu_csr_remapped_address;

  // Response mux for CXL IP AVMM master
  logic        cafu_avmm_waitrequest_int;
  logic [63:0] cafu_avmm_readdata_int;
  logic        cafu_avmm_readdatavalid_int;

  // Mux GPU CSR waitrequest as well
  assign cafu2ip_avmm_waitrequest   = (ip2cafu_avmm_write || ip2cafu_avmm_read) && gpu_csr_addr_hit ? gpu_csr_waitrequest : cafu_avmm_waitrequest_int;
  // Mux GPU CSR responses into cafu2ip when responding to GPU CSR requests
  assign cafu2ip_avmm_readdata      = csr_response_is_gpu ? gpu_csr_readdata : cafu_avmm_readdata_int;
  assign cafu2ip_avmm_readdatavalid = csr_response_is_gpu ? gpu_csr_readdatavalid : cafu_avmm_readdatavalid_int;

  //-------------------------------------------------------
  // GPU CSR Remapping for PIO Bridge: BAR0+0x080000 → vendor CSR region
  // SIMPLIFIED: Remap GPU CSR addresses from 0x080000 to 0x000100
  //-------------------------------------------------------

  logic pio_gpu_hit;
  logic [21:0] pio_gpu_remapped_addr;

  // Detect GPU CSR range in PIO CSR output: BAR0+0x080000-0x08FFFF
  assign pio_gpu_hit = (pio_csr_avmm_address[20:16] == 5'h08);

  // Remap address: BAR0+0x080000 → vendor CSR 0x000100
  // Address[15:0] stays the same, upper bits become 0x0001
  assign pio_gpu_remapped_addr = pio_gpu_hit ?
    {10'h0, 6'h01, pio_csr_avmm_address[15:0]} :  // 0x0100+offset
    pio_csr_avmm_address;

  // Route remapped GPU CSR to the same ip2csr_avmm response path
  // The CSR register file (ex_default_csr_top) will receive these at correct addresses
  logic pio_resp_waitrequest;
  logic [63:0] pio_resp_readdata;
  logic pio_resp_readdatavalid;
  logic pio_dummy_rdv;

  always_ff @(posedge ip2hdm_clk or negedge ip2hdm_reset_n_f) begin
      if (!ip2hdm_reset_n_f)
          pio_dummy_rdv <= 1'b0;
      else
          pio_dummy_rdv <= pio_csr_avmm_read && !pio_gpu_hit;
  end

  // For GPU CSR hits, response comes from CSR register file (indirectly through CXL IP)
  // For non-hits, return dummy 0
  assign pio_resp_waitrequest   = pio_gpu_hit ? 1'b0 : 1'b0;  // CSR is synchronous
  assign pio_resp_readdata      = 64'h0;  // Will be replaced by actual CSR data
  assign pio_resp_readdatavalid = pio_gpu_hit ? 1'b1 : pio_dummy_rdv;


cafu_csr0_avmm_wrapper
#(
  .T1IP_ENABLE            (T1IP_ENABLE        )
)
cafu_csr0_avmm_wrapper_inst
(
        // Clocks
        .csr_avmm_clk                       (        ip2cafu_avmm_clk                   ),    // AVMM clock : 125MHz
        .rtl_clk                            (        ip2hdm_clk                         ),    // IP clk
        .axi4_mm_clk                        (        ip2hdm_clk                         ),
        // Resets
        .csr_avmm_rstn                      (        ip2cafu_avmm_rstn                  ),                                  
        .rst_n                              (        ip2hdm_reset_n                     ),                                  
        .axi4_mm_rst_n                      (        ip2hdm_reset_n                     ),                                  
        .cxl_or_conv_rst_n                  (        cxl_or_conv_rst_n                  ),	
        // Misc
        .cafu_user_enabled_cxl_io           (        cafu_user_enabled_cxl_io           ),                                  
        .hdm_size_256mb                     (        hdm_size_256mb                     ),                                  
        .ddr_mc_status                      (        ddr_mc_status                      ),
        .mc_mem_active                      (        mc_mem_active                      ),
        .mem_dev_status                     (        mem_dev_status                     ),
        .mc_err_cnt                         (        mc_err_cnt                         ),                                  
        .ccv_afu_conf_base_addr_high        (        ccv_afu_conf_base_addr_high        ),                                  
        .ccv_afu_conf_base_addr_high_valid  (        ccv_afu_conf_base_addr_high_valid  ),                                  
        .ccv_afu_conf_base_addr_low         (        ccv_afu_conf_base_addr_low         ),                                  
        .ccv_afu_conf_base_addr_low_valid   (        ccv_afu_conf_base_addr_low_valid   ),                                  
        // AXI-MM interface - write address channel     
        .awid                               (        afu_axi_aw.awid                    ),                                  
        .awaddr                             (        afu_axi_aw.awaddr                  ),                                  
        .awlen                              (        afu_axi_aw.awlen                   ),                                  
        .awsize                             (        afu_axi_awsize                     ),                                  
        .awburst                            (        afu_axi_awburst                    ),                                  
        .awprot                             (        afu_axi_awprot                     ),                                  
        .awqos                              (        afu_axi_awqos                      ),                                  
        .awuser                             (        afu_axi_aw.awuser                  ),                                  
        .awvalid                            (        afu_axi_aw.awvalid                 ),                                  
        .awcache                            (        afu_axi_awcache                    ),                                  
        .awlock                             (        afu_axi_awlock                     ),                                  
        .awregion                           (        afu_axi_aw.awregion                ),                                  
        .awready                            (        afu_axi_awready                    ),                                  
        // AXI-MM interface - write data channel     
        .wdata                              (        afu_axi_w.wdata                    ),                                  
        .wstrb                              (        afu_axi_w.wstrb                    ),                                  
        .wlast                              (        afu_axi_w.wlast                    ),                                  
        .wuser                              (        afu_axi_w.wuser                    ),                                  
        .wvalid                             (        afu_axi_w.wvalid                   ),                                  
        .wready                             (        afu_axi_wready                     ),                                  
        // AXI-MM interface - write response channel     
        .bid                                (        afu_axi_b.bid                      ),                                  
        .bresp                              (        afu_axi_b.bresp                    ),                                  
        .buser                              (        afu_axi_b.buser                    ),                                  
        .bvalid                             (        afu_axi_b.bvalid                   ),                                  
        .bready                             (        afu_axi_bready                     ),                                  
        // AXI-MM interface - read address channel     
        .arid                               (        afu_axi_ar.arid                    ),                                  
        .araddr                             (        afu_axi_ar.araddr                  ),                                  
        .arlen                              (        afu_axi_ar.arlen                   ),                                  
        .arsize                             (        afu_axi_arsize                     ),                                  
        .arburst                            (        afu_axi_arburst                    ),                                  
        .arprot                             (        afu_axi_arprot                     ),                                  
        .arqos                              (        afu_axi_arqos                      ),                                  
        .aruser                             (        afu_axi_ar.aruser                  ),                                  
        .arvalid                            (        afu_axi_ar.arvalid                 ),                                  
        .arcache                            (        afu_axi_arcache                    ),                                  
        .arlock                             (        afu_axi_arlock                     ),                                  
        .arregion                           (        afu_axi_ar.arregion                ),                                  
        .arready                            (        afu_axi_arready                    ),                                  
        // AXI-MM interface - read response channel     
        .rid                                (        afu_axi_r.rid                      ),                                  
        .rdata                              (        afu_axi_r.rdata                    ),                                  
        .rresp                              (        afu_axi_r.rresp                    ),                                  
        .rlast                              (        afu_axi_r.rlast                    ),                                  
        .ruser                              (        afu_axi_r.ruser                    ),                                  
        .rvalid                             (        afu_axi_r.rvalid                   ),                                  
        .rready                             (        afu_axi_rready                     ),                                  
        // cfg signals
	.cafu2ip_csr0_cfg_if                (        cafu2ip_csr0_cfg_if                ),                                  
        .ip2cafu_csr0_cfg_if                (        ip2cafu_csr0_cfg_if                ), 
        .usr2ip_cxlreset_initiate           (        usr2ip_cxlreset_initiate           ), 
        .ip2usr_cxlreset_error              (        ip2usr_cxlreset_error              ),
        .ip2usr_cxlreset_complete           (        ip2usr_cxlreset_complete           ),                                  
        .ip2usr_gpf_ph2_req_i               (        ip2usr_gpf_ph2_req_i               ),                                  
        .usr2ip_gpf_ph2_ack_o               (        usr2ip_gpf_ph2_ack_o               ),                                  
        // CAFU to CXL-IP , to indicate the cache evict policy
        .usr2ip_cache_evict_policy          (        usr2ip_cache_evict_policy          ),                                  
        // Between AFU and CXL_IP CSR Access  AVMM  Bus                           
        .csr_avmm_waitrequest               (        cafu_avmm_waitrequest_int          ),
        .csr_avmm_readdata                  (        cafu_avmm_readdata_int             ),
        .csr_avmm_readdatavalid             (        cafu_avmm_readdatavalid_int        ),
        .csr_avmm_writedata                 (        ip2cafu_avmm_writedata             ),
        .csr_avmm_address                   (        ip2cafu_avmm_address               ),
        .csr_avmm_write                     (        cafu_avmm_write_gated              ),
        .csr_avmm_read                      (        cafu_avmm_read_gated               ),
        .csr_avmm_poison                    (        ip2cafu_avmm_poison                ),
        .csr_avmm_byteenable                (        ip2cafu_avmm_byteenable            ),                                   
	// ATE interface signals
        .afu_ate_ctrl             (afu_ate_ctrl           ), 
        .afu_ate_force_disable    (afu_ate_force_disable  ), 
        .afu_ate_initiate         (afu_ate_initiate       ), 
        .afu_ate_attr_byte_en     (afu_ate_attr_byte_en   ), 
        .afu_ate_target_address   (afu_ate_target_address ), 
        .afu_ate_compare_value_0  (afu_ate_compare_value_0), 
        .afu_ate_compare_value_1  (afu_ate_compare_value_1), 
        .afu_ate_swap_value_0     (afu_ate_swap_value_0   ), 
        .afu_ate_swap_value_1     (afu_ate_swap_value_1   ), 

        .afu_ate_status            (afu_ate_status           ),
        .afu_ate_read_data_value_0 (afu_ate_read_data_value_0),
        .afu_ate_read_data_value_1 (afu_ate_read_data_value_1),
        .afu_ate_read_data_value_2 (afu_ate_read_data_value_2),
        .afu_ate_read_data_value_3 (afu_ate_read_data_value_3),
        .afu_ate_read_data_value_4 (afu_ate_read_data_value_4),
        .afu_ate_read_data_value_5 (afu_ate_read_data_value_5),
        .afu_ate_read_data_value_6 (afu_ate_read_data_value_6),
        .afu_ate_read_data_value_7 (afu_ate_read_data_value_7),
                                   
        .hdm_dec_gbl_ctrl          (hdm_dec_gbl_ctrl         ),
        .hdm_dec_ctrl              (hdm_dec_ctrl             ),
        .dvsec_fbrange1high        (dvsec_fbrange1high       ),
        .dvsec_fbrange1low         (dvsec_fbrange1low        ),
        .fbrange1_sz_high          (fbrange1_sz_high         ),
        .fbrange1_sz_low           (fbrange1_sz_low          ),
        .hdm_dec_basehigh          (hdm_dec_basehigh         ),
        .hdm_dec_baselow           (hdm_dec_baselow          ),
        .hdm_dec_sizehigh          (hdm_dec_sizehigh         ),
        .hdm_dec_sizelow           (hdm_dec_sizelow          )
);


// AXI1 is the generated CAFU/CXL.cache interface.  Its original ATE/cust
// master keeps the read path directly; these write-side signals are serialized
// with CIRA completion stores by cira_axi_write_arbiter below.
logic [11:0]  legacy_axi1_awid;
logic [63:0]  legacy_axi1_awaddr;
logic [9:0]   legacy_axi1_awlen;
logic [2:0]   legacy_axi1_awsize;
logic [1:0]   legacy_axi1_awburst;
logic [2:0]   legacy_axi1_awprot;
logic [3:0]   legacy_axi1_awqos;
logic [6:0]   legacy_axi1_awuser;
logic         legacy_axi1_awvalid;
logic [3:0]   legacy_axi1_awcache;
logic [1:0]   legacy_axi1_awlock;
logic [3:0]   legacy_axi1_awregion;
logic [5:0]   legacy_axi1_awatop;
logic         legacy_axi1_awready;
logic [511:0] legacy_axi1_wdata;
logic [63:0]  legacy_axi1_wstrb;
logic         legacy_axi1_wlast;
logic         legacy_axi1_wuser;
logic         legacy_axi1_wvalid;
logic         legacy_axi1_wready;
logic [11:0]  legacy_axi1_bid;
logic [1:0]   legacy_axi1_bresp;
logic [3:0]   legacy_axi1_buser;
logic         legacy_axi1_bvalid;
logic         legacy_axi1_bready;

logic         cira_cache_req_valid;
logic [31:0]  cira_cache_req_status;
logic [63:0]  cira_cache_req_result;
logic [63:0]  cira_cache_req_hpa;
logic         cira_cache_req_busy;
logic         cira_cache_req_done;
logic         cira_cache_req_error;

logic [11:0]  cira_axi1_awid;
logic [63:0]  cira_axi1_awaddr;
logic [9:0]   cira_axi1_awlen;
logic [2:0]   cira_axi1_awsize;
logic [1:0]   cira_axi1_awburst;
logic [2:0]   cira_axi1_awprot;
logic [3:0]   cira_axi1_awqos;
logic [6:0]   cira_axi1_awuser;
logic         cira_axi1_awvalid;
logic [3:0]   cira_axi1_awcache;
logic [1:0]   cira_axi1_awlock;
logic [3:0]   cira_axi1_awregion;
logic [5:0]   cira_axi1_awatop;
logic         cira_axi1_awready;
logic [511:0] cira_axi1_wdata;
logic [63:0]  cira_axi1_wstrb;
logic         cira_axi1_wlast;
logic         cira_axi1_wuser;
logic         cira_axi1_wvalid;
logic         cira_axi1_wready;
logic [11:0]  cira_axi1_bid;
logic [1:0]   cira_axi1_bresp;
logic [3:0]   cira_axi1_buser;
logic         cira_axi1_bvalid;
logic         cira_axi1_bready;

cira_cxl_cache_completion_writer cira_cache_completion_writer_inst (
    .clk                (ip2hdm_clk),
    .rst_n              (ip2hdm_reset_n),
    .req_valid          (cira_cache_req_valid),
    .req_status         (cira_cache_req_status),
    .req_result         (cira_cache_req_result),
    .req_completion_hpa (cira_cache_req_hpa),
    .req_busy           (cira_cache_req_busy),
    .req_done           (cira_cache_req_done),
    .req_error          (cira_cache_req_error),
    .awid               (cira_axi1_awid),
    .awaddr             (cira_axi1_awaddr),
    .awlen              (cira_axi1_awlen),
    .awsize             (cira_axi1_awsize),
    .awburst            (cira_axi1_awburst),
    .awprot             (cira_axi1_awprot),
    .awqos              (cira_axi1_awqos),
    .awuser             (cira_axi1_awuser),
    .awvalid            (cira_axi1_awvalid),
    .awcache            (cira_axi1_awcache),
    .awlock             (cira_axi1_awlock),
    .awregion           (cira_axi1_awregion),
    .awatop             (cira_axi1_awatop),
    .awready            (cira_axi1_awready),
    .wdata              (cira_axi1_wdata),
    .wstrb              (cira_axi1_wstrb),
    .wlast              (cira_axi1_wlast),
    .wuser              (cira_axi1_wuser),
    .wvalid             (cira_axi1_wvalid),
    .wready             (cira_axi1_wready),
    .bid                (cira_axi1_bid),
    .bresp              (cira_axi1_bresp),
    .buser              (cira_axi1_buser),
    .bvalid             (cira_axi1_bvalid),
    .bready             (cira_axi1_bready)
);

cira_axi_write_arbiter cira_axi1_write_arbiter_inst (
    .clk                (ip2hdm_clk), .rst_n(ip2hdm_reset_n),
    .legacy_awid        (legacy_axi1_awid), .legacy_awaddr(legacy_axi1_awaddr),
    .legacy_awlen       (legacy_axi1_awlen), .legacy_awsize(legacy_axi1_awsize),
    .legacy_awburst     (legacy_axi1_awburst), .legacy_awprot(legacy_axi1_awprot),
    .legacy_awqos       (legacy_axi1_awqos), .legacy_awuser(legacy_axi1_awuser),
    .legacy_awvalid     (legacy_axi1_awvalid), .legacy_awcache(legacy_axi1_awcache),
    .legacy_awlock      (legacy_axi1_awlock), .legacy_awregion(legacy_axi1_awregion),
    .legacy_awatop      (legacy_axi1_awatop), .legacy_awready(legacy_axi1_awready),
    .legacy_wdata       (legacy_axi1_wdata), .legacy_wstrb(legacy_axi1_wstrb),
    .legacy_wlast       (legacy_axi1_wlast), .legacy_wuser(legacy_axi1_wuser),
    .legacy_wvalid      (legacy_axi1_wvalid), .legacy_wready(legacy_axi1_wready),
    .legacy_bid         (legacy_axi1_bid), .legacy_bresp(legacy_axi1_bresp),
    .legacy_buser       (legacy_axi1_buser), .legacy_bvalid(legacy_axi1_bvalid),
    .legacy_bready      (legacy_axi1_bready),
    .cira_awid          (cira_axi1_awid), .cira_awaddr(cira_axi1_awaddr),
    .cira_awlen         (cira_axi1_awlen), .cira_awsize(cira_axi1_awsize),
    .cira_awburst       (cira_axi1_awburst), .cira_awprot(cira_axi1_awprot),
    .cira_awqos         (cira_axi1_awqos), .cira_awuser(cira_axi1_awuser),
    .cira_awvalid       (cira_axi1_awvalid), .cira_awcache(cira_axi1_awcache),
    .cira_awlock        (cira_axi1_awlock), .cira_awregion(cira_axi1_awregion),
    .cira_awatop        (cira_axi1_awatop), .cira_awready(cira_axi1_awready),
    .cira_wdata         (cira_axi1_wdata), .cira_wstrb(cira_axi1_wstrb),
    .cira_wlast         (cira_axi1_wlast), .cira_wuser(cira_axi1_wuser),
    .cira_wvalid        (cira_axi1_wvalid), .cira_wready(cira_axi1_wready),
    .cira_bid           (cira_axi1_bid), .cira_bresp(cira_axi1_bresp),
    .cira_buser         (cira_axi1_buser), .cira_bvalid(cira_axi1_bvalid),
    .cira_bready        (cira_axi1_bready),
    .phy_awid           (axi1_awid), .phy_awaddr(axi1_awaddr),
    .phy_awlen          (axi1_awlen), .phy_awsize(axi1_awsize),
    .phy_awburst        (axi1_awburst), .phy_awprot(axi1_awprot),
    .phy_awqos          (axi1_awqos), .phy_awuser(axi1_awuser),
    .phy_awvalid        (axi1_awvalid), .phy_awcache(axi1_awcache),
    .phy_awlock         (axi1_awlock), .phy_awregion(axi1_awregion),
    .phy_awatop         (axi1_awatop), .phy_awready(axi1_awready),
    .phy_wdata          (axi1_wdata), .phy_wstrb(axi1_wstrb),
    .phy_wlast          (axi1_wlast), .phy_wuser(axi1_wuser),
    .phy_wvalid         (axi1_wvalid), .phy_wready(axi1_wready),
    .phy_bid            (axi1_bid), .phy_bresp(axi1_bresp),
    .phy_buser          (axi1_buser), .phy_bvalid(axi1_bvalid),
    .phy_bready         (axi1_bready)
);

`ifdef BYPASS_ATE 

cust_afu_wrapper cust_afu_wrapper_inst
(
 // Clocks
  .axi4_mm_clk                           (ip2hdm_clk), 
 // Resets
  .axi4_mm_rst_n                         (ip2hdm_reset_n),

// AXI-MM interface - write address channel
  .awid                                  (legacy_axi1_awid),
  .awaddr                                (legacy_axi1_awaddr),
  .awlen                                 (legacy_axi1_awlen),
  .awsize                                (legacy_axi1_awsize),
  .awburst                               (legacy_axi1_awburst),
  .awprot                                (legacy_axi1_awprot),
  .awqos                                 (legacy_axi1_awqos),
  .awuser                                (legacy_axi1_awuser),
  .awvalid                               (legacy_axi1_awvalid),
  .awcache                               (legacy_axi1_awcache),
  .awlock                                (legacy_axi1_awlock),
  .awregion                              (legacy_axi1_awregion),
  .awatop                                (legacy_axi1_awatop),
  .awready                               (legacy_axi1_awready),
  
// AXI-MM interface - write data channel
  .wdata                                 (legacy_axi1_wdata),
  .wstrb                                 (legacy_axi1_wstrb),
  .wlast                                 (legacy_axi1_wlast),
  .wuser                                 (legacy_axi1_wuser),
  .wvalid                                (legacy_axi1_wvalid),
  .wready                                (legacy_axi1_wready),
  
//  AXI-MM interface - write response channel
   .bid                                  (legacy_axi1_bid),
   .bresp                                (legacy_axi1_bresp),
   .buser                                (legacy_axi1_buser),
   .bvalid                               (legacy_axi1_bvalid),
   .bready                               (legacy_axi1_bready),
  
// AXI-MM interface - read address channel
  .arid                                  (axi1_arid),
  .araddr                                (axi1_araddr),
  .arlen                                 (axi1_arlen),
  .arsize                                (axi1_arsize),
  .arburst                               (axi1_arburst),
  .arprot                                (axi1_arprot),
  .arqos                                 (axi1_arqos),
  .aruser                                (axi1_aruser),
  .arvalid                               (axi1_arvalid),
  .arcache                               (axi1_arcache),
  .arlock                                (axi1_arlock),
  .arregion                              (axi1_arregion),
  .arready                               (axi1_arready),

// AXI-MM interface - read response channel
  .rid                                   (axi1_rid),
  .rdata                                 (axi1_rdata),
  .rresp                                 (axi1_rresp),
  .rlast                                 (axi1_rlast),
  .ruser                                 (axi1_ruser),
  .rvalid                                (axi1_rvalid),
  .rready                                (axi1_rready)
  
  
);

`else

afu_atomic_test_engine afu_atomic_test_engine(
   .rtl_clk (ip2hdm_clk  ),
   .reset_n (ip2hdm_reset_n),
   .awaddr  (legacy_axi1_awaddr   ),
   .awburst (legacy_axi1_awburst  ),
   .awcache (legacy_axi1_awcache  ),
   .awid    (legacy_axi1_awid     ),
   .awlen   (legacy_axi1_awlen    ),
   .awlock  (legacy_axi1_awlock   ),
   .awqos   (legacy_axi1_awqos    ),
   .awprot  (legacy_axi1_awprot   ),
   .awready (legacy_axi1_awready  ),
   .awregion(legacy_axi1_awregion ),
   .awsize  (legacy_axi1_awsize   ),
   .awatop  (legacy_axi1_awatop   ),
   .awuser  (legacy_axi1_awuser   ),
   .awvalid (legacy_axi1_awvalid  ),
                      
   .wdata   (legacy_axi1_wdata    ),
   .wid     (axi1_wid      ),
   .wlast   (legacy_axi1_wlast    ),
   .wready  (legacy_axi1_wready   ),
   .wstrb   (legacy_axi1_wstrb    ),
   .wuser   (legacy_axi1_wuser    ),
   .wvalid  (legacy_axi1_wvalid   ),
                      
   .bid     (legacy_axi1_bid      ),
   .bready  (legacy_axi1_bready   ),
   .bresp   (legacy_axi1_bresp    ),
   .buser   (legacy_axi1_buser    ),
   .bvalid  (legacy_axi1_bvalid   ),
                      
   .araddr  (axi1_araddr   ),
   .arburst (axi1_arburst  ),
   .arcache (axi1_arcache  ),
   .arid    (axi1_arid     ),
   .arlen   (axi1_arlen    ),
   .arlock  (axi1_arlock   ),
   .arprot  (axi1_arprot   ),
   .arqos   (axi1_arqos    ),
   .arready (axi1_arready  ),
   .arregion(axi1_arregion ),
   .arsize  (axi1_arsize   ),
   .aruser  (axi1_aruser   ),
   .arvalid (axi1_arvalid  ),
                      
   .rdata   (axi1_rdata    ),
   .rid     (axi1_rid      ),
   .rlast   (axi1_rlast    ),
   .rready  (axi1_rready   ),
   .rresp   (axi1_rresp    ),
   .ruser   (axi1_ruser    ),
   .rvalid  (axi1_rvalid   ),
   
   .afu_ate_ctrl             (afu_ate_ctrl           ), 
   .afu_ate_force_disable    (afu_ate_force_disable  ), 
   .afu_ate_initiate         (afu_ate_initiate       ), 
   .afu_ate_attr_byte_en     (afu_ate_attr_byte_en   ), 
   .afu_ate_target_address   (afu_ate_target_address ), 
   .afu_ate_compare_value_0  (afu_ate_compare_value_0), 
   .afu_ate_compare_value_1  (afu_ate_compare_value_1), 
   .afu_ate_swap_value_0     (afu_ate_swap_value_0   ), 
   .afu_ate_swap_value_1     (afu_ate_swap_value_1   ), 

   .afu_ate_status            (afu_ate_status           ),
   .afu_ate_read_data_value_0 (afu_ate_read_data_value_0),
   .afu_ate_read_data_value_1 (afu_ate_read_data_value_1),
   .afu_ate_read_data_value_2 (afu_ate_read_data_value_2),
   .afu_ate_read_data_value_3 (afu_ate_read_data_value_3),
   .afu_ate_read_data_value_4 (afu_ate_read_data_value_4),
   .afu_ate_read_data_value_5 (afu_ate_read_data_value_5),
   .afu_ate_read_data_value_6 (afu_ate_read_data_value_6),
   .afu_ate_read_data_value_7 (afu_ate_read_data_value_7),
                              
   .hdm_dec_gbl_ctrl          (hdm_dec_gbl_ctrl         ),
   .hdm_dec_ctrl              (hdm_dec_ctrl             ),
   .dvsec_fbrange1high        (dvsec_fbrange1high       ),
   .dvsec_fbrange1low         (dvsec_fbrange1low        ),
   .fbrange1_sz_high          (fbrange1_sz_high         ),
   .fbrange1_sz_low           (fbrange1_sz_low          ),
   .hdm_dec_basehigh          (hdm_dec_basehigh         ),
   .hdm_dec_baselow           (hdm_dec_baselow          ),
   .hdm_dec_sizehigh          (hdm_dec_sizehigh         ),
   .hdm_dec_sizelow           (hdm_dec_sizelow          )
);

`endif

  //-------------------------------------------------------
  // AVST4TO1 - CONVERGE 4 AVST TO 1 AVST SEGMENT                                  
  //-------------------------------------------------------

cxl_ed_avst_4to1_rx_side #(
        .APP_CORES             (  1   ),
        .P_HDR_CRDT            (  8   ),
        .NP_HDR_CRDT           (  8   ),
        .CPL_HDR_CRDT          (  8   ),
        .P_DATA_CRDT           (  32  ),
        .NP_DATA_CRDT          (  32  ),
        .CPL_DATA_CRDT         (  32  ),
        .DATA_FIFO_ADDR_WIDTH  (  5   )
) rx_side_inst (
        .pld_clk                         (  ip2hdm_clk                 ),
        .pld_rst_n                       (  ip2hdm_reset_n_f           ),
        .pld_init_done_rst_n             (  ip2hdm_reset_n_f           ),
        .pld_rx                          (  p0_pld_if.rx               ),
        .pld_rx_crd                      (  p0_pld_if.rx_crd           ),
        .crd_prim_rst_n                  (  ip2hdm_reset_n_f           ),
        .avst4to1_prim_clk               (  ip2hdm_clk                 ),
        .avst4to1_prim_rst_n             (  ip2hdm_reset_n_f           ),
        .avst4to1_core_max_payload       (  2'b00                      ),
        .tx_init                         (  tx_st_hcrdt_init_i         ),
        .avst4to1_rx_sop                 (  ed_rx_sop                  ),
        .avst4to1_rx_eop                 (  ed_rx_eop                  ),
        .avst4to1_rx_hdr                 (  ed_rx_header               ),
        .avst4to1_rx_passthrough         (  ed_rx_passthrough          ),
        .avst4to1_rx_data                (  ed_rx_payload              ),
        .avst4to1_rx_data_dw_valid       (  ed_rx_dw_valid             ),
        .avst4to1_rx_prefix              (  ed_rx_prefix               ),                         
        .avst4to1_rx_prefix_valid        (  ed_rx_prefix_valid         ),                         
        .avst4to1_rx_RSSAI_prefix        (                             ),                         
        .avst4to1_rx_RSSAI_prefix_valid  (                             ),                         
        .avst4to1_vf_active              (                             ),                         
        .avst4to1_vf_num                 (                             ),                         
        .avst4to1_pf_num                 (                             ),                         
        .avst4to1_bar_range              (                             ),                         
        .avst4to1_rx_tlp_abort           (                             ),                         
        .avst4to1_np_hdr_crd_pop         (  avst4to1_np_hdr_crd_pop    ),
        .avst4to1_rx_data_avail          (  avst4to1_rx_data_avail     ),
        .avst4to1_rx_hdr_avail           (  avst4to1_rx_hdr_avail      ),
        .avst4to1_rx_nph_hdr_avail       (  avst4to1_rx_nph_hdr_avail  )
);
// SignalTap IP commented out (sigtap_512.ip not available)
//`ifndef VCSSIM
//    wire [31:0]  cxl_io_mon_trig;
//    wire [511:0] cxl_io_mon_data;
//    sigtap_512 cxl_io_mon (
//        .acq_clk        (ip2hdm_clk),
//        .acq_trigger_in (cxl_io_mon_trig),
//        .acq_data_in    (cxl_io_mon_data)
//    );
//    assign cxl_io_mon_trig[0]     = ed_rx_hvalid;
//    assign cxl_io_mon_trig[1]     = ed_rx_sop_i;
//    assign cxl_io_mon_trig[2]     = ed_rx_eop_i;
//
//    assign cxl_io_mon_data[127:0] = ed_rx_header_update;
//    assign cxl_io_mon_data[128]   = ed_rx_hvalid;
//    assign cxl_io_mon_data[129]   = ed_rx_sop_i;
//    assign cxl_io_mon_data[130]   = ed_rx_eop_i;
//`endif
//--------------------------------------------------
// intel_cxl_pf_checker
//--------------------------------------------------
intel_cxl_pf_checker  inst_cxl_pf_checker  (                                                                             
		.clk                                         (    ip2hdm_clk                     ),                                             
		//--ed                                                                                                                          
		.ed_rx_st_bar_i                              (    '0                             ),                                             
		.ed_rx_st_eop_i                              (    ed_rx_eop_i                    ),                                             
		.ed_rx_st_header_i                           (    ed_rx_header_update            ),                                              
		.ed_rx_st_payload_i                          (    ed_rx_payload[0]               ),                                             
		.ed_rx_st_sop_i                              (    ed_rx_sop_i                    ),                                              
		.ed_rx_st_hvalid_i                           (    ed_rx_hvalid                   ),                  
		.ed_rx_st_dvalid_i                           (    ed_rx_valid                    ),                         
		.ed_rx_st_pvalid_i                           (    ed_rx_prefix_valid[0]            ),                                             
		.ed_rx_st_empty_i                            (    '0                            ),                                             
		.ed_rx_st_pfnum_i                            (    '0                            ),                                             
		.ed_rx_st_tlp_prfx_i                         (    ed_rx_prefix[0]                  ),                                             
		.ed_rx_st_data_parity_i                      (    '0                             ),                                             
		.ed_rx_st_hdr_parity_i                       (    '0                             ),                                             
		.ed_rx_st_tlp_prfx_parity_i                  (    '0                             ),                                             
		.ed_rx_st_rssai_prefix_i                     (    '0                             ),                                             
		.ed_rx_st_rssai_prefix_parity_i              (    '0                             ),                                             
		.ed_rx_st_vfactive_i                         (    '0                             ),                                             
		.ed_rx_st_vfnum_i                            (    '0                             ),                                             
		.ed_rx_st_chnum_i                            (    '0                             ),                                             
		.ed_rx_st_misc_parity_i                      (    '0                             ),                                             
		.ed_rx_st_passthrough_i                      (    ed_rx_passthrough[0]           ),                                             
		.ed_rx_st_ready_o                            (    ed_rx_ready                    ),                                             
                .pf0_memory_access_en                        (    pf0_memory_access_en           ),
                .pf1_memory_access_en                        (    pf1_memory_access_en           ),
		//--default config                                                                             
		.default_config_rx_st_bar_o                  (    default_config_rx_bar          ),                                             
		.default_config_rx_st_eop_o                  (    default_config_rx_eop          ),                                             
		.default_config_rx_st_header_o               (    default_config_rx_header       ),                                             
		.default_config_rx_st_payload_o              (    default_config_rx_payload      ),                                             
		.default_config_rx_st_sop_o                  (    default_config_rx_sop          ),                                             
		.default_config_rx_st_hvalid_o               (    default_config_rx_hvalid       ),                                             
		.default_config_rx_st_dvalid_o               (    default_config_rx_dvalid       ),                                             
		.default_config_rx_st_pvalid_o               (                                   ),                                             
		.default_config_rx_st_empty_o                (                                   ),                                             
		.default_config_rx_st_pfnum_o                (                                   ),                                             
		.default_config_rx_st_tlp_prfx_o             (                                   ),                                             
		.default_config_rx_st_data_parity_o          (                                   ),                                             
		.default_config_rx_st_hdr_parity_o           (                                   ),                                             
		.default_config_rx_st_tlp_prfx_parity_o      (                                   ),                                             
		.default_config_rx_st_rssai_prefix_o         (                                   ),                                             
		.default_config_rx_st_rssai_prefix_parity_o  (                                   ),                                             
		.default_config_rx_st_vfactive_o             (                                   ),                                             
		.default_config_rx_st_vfnum_o                (                                   ),                                             
		.default_config_rx_st_chnum_o                (                                   ),                                             
		.default_config_rx_st_misc_parity_o          (                                   ),                                             
		.default_config_rx_st_passthrough_o          (    default_config_rx_passthrough  ),                                             
		.default_config_rx_st_ready_i                (    default_config_rx_ready        ),                                             
		//--pio                                                                                                                         
		.pio_rx_st_bar_o                             (     pio_rx_bar                    ),                                             
		.pio_rx_st_eop_o                             (     aer_chk_rx_eop                    ),                                             
		.pio_rx_st_header_o                          (     aer_chk_rx_header                 ),                                             
		.pio_rx_st_payload_o                         (     aer_chk_rx_payload                ),                                             
		.pio_rx_st_sop_o                             (     aer_chk_rx_sop                    ),                                             
		.pio_rx_st_hvalid_o                          (     aer_chk_rx_hvalid                 ),                                             
		.pio_rx_st_dvalid_o                          (     aer_chk_rx_dvalid                 ),                                             
		.pio_rx_st_pvalid_o                          (     aer_chk_rx_pvalid                 ),                                             
		.pio_rx_st_empty_o                           (                                   ),                                             
		.pio_rx_st_pfnum_o                           (                                   ),                                             
		.pio_rx_st_tlp_prfx_o                        (     aer_chk_rx_prefix                 ),                                             
		.pio_rx_st_data_parity_o                     (                                   ),                                             
		.pio_rx_st_hdr_parity_o                      (                                   ),                                             
		.pio_rx_st_tlp_prfx_parity_o                 (                                   ),                                             
		.pio_rx_st_rssai_prefix_o                    (                                   ),                                             
		.pio_rx_st_rssai_prefix_parity_o             (                                   ),                                             
		.pio_rx_st_vfactive_o                        (                                   ),                                             
		.pio_rx_st_vfnum_o                           (                                   ),                                             
		.pio_rx_st_chnum_o                           (                                   ),                                             
		.pio_rx_st_misc_parity_o                     (                                   ),                                             
		.pio_rx_st_passthrough_o                     (    pio_rx_passthrough             ),                                             
		.pio_rx_st_ready_i                           (    pio_rx_ready                   ),                                             
		//--afu                                                                                                                         
		.afu_rx_st_bar_o                             (     afu_rx_bar                    ),                                             
		.afu_rx_st_eop_o                             (     afu_rx_eop                    ),                                             
		.afu_rx_st_header_o                          (     afu_rx_hdr                    ),                                             
		.afu_rx_st_payload_o                         (     afu_rx_data                   ),                                             
		.afu_rx_st_sop_o                             (     afu_rx_sop                    ),                                             
		.afu_rx_st_hvalid_o                          (     afu_rx_hvalid                 ),                                             
		.afu_rx_st_dvalid_o                          (     afu_rx_dvalid                 ),                                             
		.afu_rx_st_pvalid_o                          (                                   ),                                             
		.afu_rx_st_empty_o                           (                                   ),                                             
		.afu_rx_st_pfnum_o                           (                                   ),                                             
		.afu_rx_st_tlp_prfx_o                        (                                   ),                                             
		.afu_rx_st_data_parity_o                     (                                   ),                                             
		.afu_rx_st_hdr_parity_o                      (                                   ),                                             
		.afu_rx_st_tlp_prfx_parity_o                 (                                   ),                                             
		.afu_rx_st_rssai_prefix_o                    (                                   ),                                             
		.afu_rx_st_rssai_prefix_parity_o             (                                   ),                                             
		.afu_rx_st_vfactive_o                        (                                   ),                                             
		.afu_rx_st_vfnum_o                           (                                   ),                                             
		.afu_rx_st_chnum_o                           (                                   ),                                             
		.afu_rx_st_misc_parity_o                     (                                   ),                                             
		.afu_rx_st_passthrough_o                     (    afu_rx_passthrough             ),                                             
		.afu_rx_st_ready_i                           (    afu_rx_ready                   ),                                             
		.afu_pio_select                              (    afu_pio_select                 ),  
		.rstn                                        (    ip2hdm_reset_n_f               )                                              
);                                                                                                                                              

//------------------------------------------
// default config block for sending UR
//-----------------------------------------



intel_cxl_default_config inst_cxl_default_config  (
	.clk                                (  ip2hdm_clk    			    ),              
	.rst_n                              (  ip2hdm_reset_n_f    		    ),
        .default_config_rx_bar              (  default_config_rx_bar                ),
        .default_config_rx_sop_i            (  default_config_rx_sop                ),
        .default_config_rx_eop_i            (  default_config_rx_eop                ),
        .default_config_rx_header_i         (  default_config_rx_header             ),
        .default_config_rx_payload_i        (  default_config_rx_payload            ),
        .default_config_rx_valid_i          (  default_config_rx_hvalid             ),
        .default_config_rx_st_ready_o       (  default_config_rx_ready              ),
        .default_config_tx_st_ready_i       (  pio_txc_ready                        ),
        .default_config_rx_bus_number       (  ed_rx_bus_number                     ),
        .default_config_rx_device_number    (  ed_rx_device_number                  ),
        .default_config_rx_function_number  (  ed_rx_function_number                ),
        .default_config_txc_eop             (  default_config_txc_eop               ),
        .default_config_txc_header          (  default_config_txc_header            ),
        .default_config_txc_payload         (  default_config_txc_payload           ),
        .default_config_txc_sop             (  default_config_txc_sop               ),
        .default_config_txc_valid           (  default_config_txc_valid             ),
        .ed_tx_st0_passthrough_o            (  default_config_tx_st0_passthrough_i  )
        );


intel_cxl_aer intel_cxl_aer_inst (
		.clk               (  ip2hdm_clk               ),
		.rst               (  ip2hdm_reset_n_f         ),
		.rx_sop            (  aer_chk_rx_sop           ),
		.rx_eop            (  aer_chk_rx_eop           ),
		.rx_hvalid         (  aer_chk_rx_hvalid        ),
		.rx_dvalid         (  aer_chk_rx_dvalid        ),
		.rx_header         (  aer_chk_rx_header        ),
		.rx_data           (  aer_chk_rx_payload       ),
		.rx_prefix         (  aer_chk_rx_prefix        ),
		.rx_pvalid         (  aer_chk_rx_pvalid        ),
		.rx_bus_number     (  ed_rx_bus_number         ),
		.rx_device_number  (  ed_rx_device_number      ),
		.pio_to_send_cpl   (  pio_to_send_cpl          ),
		.no_err_rx_sop     (  pio_rx_sop               ),
		.no_err_rx_eop     (  pio_rx_eop               ),
		.no_err_rx_hvalid  (  pio_rx_hvalid            ),
		.no_err_rx_dvalid  (  pio_rx_dvalid            ),
		.no_err_rx_header  (  pio_rx_header            ),
		.no_err_rx_data    (  pio_rx_payload           ),
		.np_ca_rx_sop      (  np_ca_rx_sop             ),
		.np_ca_rx_eop      (  np_ca_rx_eop             ),
		.np_ca_rx_hvalid   (  np_ca_rx_hvalid          ),
		.np_ca_rx_dvalid   (  np_ca_rx_dvalid          ),
		.np_ca_rx_header   (  np_ca_rx_header          ),
		.np_ca_rx_data     (  np_ca_rx_data            ),
		.app_err_ready     (  ip2usr_app_err_ready     ),
		.app_err_valid     (  usr2ip_app_err_valid     ),
		.app_err_hdr       (  usr2ip_app_err_hdr       ),
		.app_err_info      (  usr2ip_app_err_info      ),
		.app_err_func_num  (  usr2ip_app_err_func_num  )
		);


  //-------------------------------------------------------
  // CXL PIO
  //-------------------------------------------------------

// -------------------------------------------------------
// PIO-to-CSR bridge: connects PIO TLP engine to CAFU/GPU CSR space.
// The PIO bridge decodes BAR0 MMIO reads/writes into AVMM transactions.
// Its CSR AVMM output drives the same mux as ip2cafu_avmm (which is dead
// because the CXL IP's mm_interconnect/MEM0 was removed).
// Response signals are fed back from the cafu2ip_avmm mux.
// -------------------------------------------------------

intel_cxl_pio_ed_top #(.PF1_BAR01_SIZE_VALUE (PF1_BAR01_SIZE_VALUE ))
      intel_cxl_pio_ed_top_inst  (
		.Clk_i                     (     ip2hdm_clk                ),
		.Rstn_i                    (     ip2hdm_reset_n_f          ),
		.pio_rx_bar                (     pio_rx_bar                ),
		.pio_rx_eop                (     pio_rx_eop                ),
		.pio_rx_header             (     pio_rx_header             ),
		.pio_rx_payload            (     pio_rx_payload            ),
		.pio_rx_sop                (     pio_rx_sop                ),
		.pio_rx_valid              (     pio_rx_hvalid             ),
		.pio_rx_ready              (     pio_rx_ready              ),
		.pio_txc_ready             (     pio_txc_ready             ),
		.pio_txc_eop               (     pio_txc_eop               ),
		.pio_txc_header            (     pio_txc_header            ),
		.pio_txc_payload           (     pio_txc_payload           ),
		.pio_txc_sop               (     pio_txc_sop               ),
		.pio_txc_valid             (     pio_txc_valid             ),
    		.pio_to_send_cpl	   (	 pio_to_send_cpl	   ),
		.ed_rx_bus_number          (     ed_rx_bus_number          ),
		.ed_rx_device_number       (     ed_rx_device_number       ),
		// CSR AVMM bridge: PIO generates AVMM transactions.
		// Response comes from dedicated PIO response mux (GPU CSR + dummy).
		// Does NOT touch cafu2ip_avmm (which belongs to CXL IP AVMM master).
		.csr_avmm_read             (     pio_csr_avmm_read         ),
		.csr_avmm_write            (     pio_csr_avmm_write        ),
		.csr_avmm_address          (     pio_csr_avmm_address      ),
		.csr_avmm_writedata        (     pio_csr_avmm_writedata    ),
		.csr_avmm_byteenable       (     pio_csr_avmm_byteenable   ),
		.csr_avmm_poison           (     pio_csr_avmm_poison       ),
		.csr_avmm_readdata         (     pio_resp_readdata          ),
		.csr_avmm_waitrequest      (     pio_resp_waitrequest       ),
		.csr_avmm_readdatavalid    (     pio_resp_readdatavalid     )
		);


  //-------------------------------------------------------
  // CXL TX REDIT INTERFACE                                  
  //-------------------------------------------------------


intel_cxl_tx_crdt_intf inst_cxl_tx_crdt_intf (
        .clk                       (  ip2hdm_clk                ),                              
        .rst_n                     (  ip2hdm_reset_n_f          ),                              
        .tx_st_hcrdt_update_i      (  tx_st_hcrdt_update_i      ),                              
        .tx_st_hcrdt_update_cnt_i  (  tx_st_hcrdt_update_cnt_i  ),                              
        .tx_st_hcrdt_init_i        (  tx_st_hcrdt_init_i        ),                              
        .tx_st_hcrdt_init_ack_o    (  tx_st_hcrdt_init_ack_o    ),                              
        .tx_st_dcrdt_update_i      (  tx_st_dcrdt_update_i      ),                              
        .tx_st_dcrdt_update_cnt_i  (  tx_st_dcrdt_update_cnt_i  ),                              
        .tx_st_dcrdt_init_i        (  tx_st_dcrdt_init_i        ),                              
        .tx_st_dcrdt_init_ack_o    (  tx_st_dcrdt_init_ack_o    ),                              
        .pio_tx_st_ready_i         (  ed_tx_st_ready_i          ),                              
        .bam_tx_signal_ready_o     (  pio_txc_ready             ),                              
        .tx_hdr_i                  (  tx_hdr                    ),                              
        .tx_hdr_valid_i            (  tx_hdr_valid              ),                              
        .tx_hdr_type_i             (  tx_hdr_type               ),                              
        .dc_tx_hdr_valid_i         (  1'b0                      ),
        .tx_p_data_counter         (  tx_p_data_counter         ),                              
        .tx_np_data_counter        (  tx_np_data_counter        ),                              
        .tx_cpl_data_counter       (  tx_cpl_data_counter       ),                              
        .tx_p_header_counter       (  tx_p_header_counter       ),                              
        .tx_np_header_counter      (  tx_np_header_counter      ),                              
        .tx_cpl_header_counter     (  tx_cpl_header_counter     )                               
        );                                                                                      



  //-------------------------------------------------------
  // CXL AFU - CACHE/IO DEMUX                                  
  //-------------------------------------------------------



intel_cxl_afu_cache_io_demux  inst_intel_cxl_afu_cache_io_demux ( 
		.clk                    (  ip2hdm_clk             ),                                                     
		.rst                    (  ip2hdm_reset_n_f       ),                                                     
		.afu_cache_io_select    (  afu_cache_io_select    ),  //afu_cache_io_select  ==  1  ?  select  io  else  cache
		//--to/from afu                                                                              
		.afu_axi_ar             (  afu_axi_ar             ),                                                     
		.afu_axi_arready        (  afu_axi_arready        ),                                                     
		.afu_axi_r              (  afu_axi_r              ),                                                     
		.afu_axi_rready         (  afu_axi_rready         ),                                                     
		.afu_axi_aw             (  afu_axi_aw             ),                                                     
		.afu_axi_awready        (  afu_axi_awready        ),                                                     
		.afu_axi_w              (  afu_axi_w              ),                                                     
		.afu_axi_wready         (  afu_axi_wready         ),                                                     
		.afu_axi_b              (  afu_axi_b              ),                                                     
		.afu_axi_bready         (  afu_axi_bready         ),                                                     
		//--to/from  cache                                                                   
		.afu_cache_axi_ar       (  afu_cache_axi_ar       ),                                                     
		.afu_cache_axi_arready  (  afu_cache_axi_arready  ),                                                     
		.afu_cache_axi_r        (  afu_cache_axi_r        ),                                                     
		.afu_cache_axi_rready   (  afu_cache_axi_rready   ),                                                     
		.afu_cache_axi_aw       (  afu_cache_axi_aw       ),                                                     
		.afu_cache_axi_awready  (  afu_cache_axi_awready  ),                                                     
		.afu_cache_axi_w        (  afu_cache_axi_w        ),                                                     
		.afu_cache_axi_wready   (  afu_cache_axi_wready   ),                                                     
		.afu_cache_axi_b        (  afu_cache_axi_b        ),                                                     
		.afu_cache_axi_bready   (  afu_cache_axi_bready   ),                                                     
		//--to/from  io                                                                      
		.afu_io_axi_ar          (  afu_io_axi_ar          ),                                                     
		.afu_io_axi_arready     (  afu_io_axi_arready     ),                                                     
		.afu_io_axi_r           (  afu_io_axi_r           ),                                                     
		.afu_io_axi_rready      (  afu_io_axi_rready      ),                                                     
		.afu_io_axi_aw          (  afu_io_axi_aw          ),                                                     
		.afu_io_axi_awready     (  afu_io_axi_awready     ),                                                     
		.afu_io_axi_w           (  afu_io_axi_w           ),                                                     
		.afu_io_axi_wready      (  afu_io_axi_wready      ),                                                     
		.afu_io_axi_b           (  afu_io_axi_b           ),                                                     
		.afu_io_axi_bready      (  afu_io_axi_bready      )                                                      
		);                                                                                                             

  //-------------------------------------------------------
  // CXL AXI <--> AVST bridge                                  
  //-------------------------------------------------------
axi_to_avst_bridge      inst_axi_to_avst_bridge  (                                                      
		.clk                    (    ip2hdm_clk             ),                              
		.rst                    (    ip2hdm_reset_n_f       ),
		.axi_ar                 (    afu_io_axi_ar          ),                              
		.axi_arready            (    afu_io_axi_arready     ),                              
		.axi_r                  (    afu_io_axi_r           ),                              
		.axi_rready             (    afu_io_axi_rready      ),                              
		.axi_aw                 (    afu_io_axi_aw          ),                              
		.axi_awready            (    afu_io_axi_awready     ),                              
		.axi_w                  (    afu_io_axi_w           ),                              
		.axi_wready             (    afu_io_axi_wready      ),                              
		.axi_b                  (    afu_io_axi_b           ),                              
		.axi_bready             (    afu_io_axi_bready      ),                              
                .pf0_bus_master_en      (    pf0_bus_master_en      ),      
		.bus_number             (    ed_rx_bus_number       ),                              
		.device_number          (    ed_rx_device_number    ),                              
		.function_number        (    ed_rx_function_number  ),                              
                .wr_tlp_fifo_empty      (    wr_tlp_fifo_empty      ), 
                .wr_tlp_fifo_almost_full(    wr_tlp_fifo_almost_full),
                .rd_tlp_fifo_almost_full(    rd_tlp_fifo_almost_full),
                .p_tlp_sent_tag         (    p_tlp_sent_tag         ),
                .p_tlp_sent_tag_valid   (    p_tlp_sent_tag_valid   ), 
		.rx_st_dvalid           (    afu_rx_dvalid          ),                              
		.rx_st_sop              (    afu_rx_sop             ),  
		.rx_st_eop              (    afu_rx_eop             ),                              
		.rx_st_data             (    afu_rx_data            ),  
		.rx_st_hdr              (    afu_rx_hdr             ),                              
		.rx_st_hvalid           (    afu_rx_hvalid          ),                              
		.tx_st_ready            (			    ),                                                     
		.tx_st_dvalid           (    afu_tx_st0_dvalid_o    ),                              
		.tx_st_sop              (    afu_tx_st0_sop_o       ),                              
		.tx_st_eop              (    afu_tx_st0_eop_o       ),                              
		.tx_st_data             (    afu_tx_st0_data_o      ),                              
		.tx_st_hdr              (    afu_tx_st0_hdr_o       ),                              
                .wr_last                (    wr_last                ),
		.tx_st_hvalid           (    afu_tx_st0_hvalid_o    ),                              
		.tx_p_data_counter      (    tx_p_data_counter      ),                              
		.tx_np_data_counter     (    tx_np_data_counter     ),                              
		.tx_cpl_data_counter    (    tx_cpl_data_counter    ),                              
		.tx_p_header_counter    (    tx_p_header_counter    ),                              
		.tx_np_header_counter   (    tx_np_header_counter   ),                              
		.tx_cpl_header_counter  (    tx_cpl_header_counter  )                               
		);                                                                                                      

  //-------------------------------------------------------
  // TX_TLP_FIFO                                  
  //-------------------------------------------------------

intel_cxl_tx_tlp_fifos  inst_tlp_fifos  (                              
        .clk                         (  ip2hdm_clk                          ),
        .rst                         (  ip2hdm_reset_n_f                    ),
        .ip_tx_ready                 (  ed_tx_st_ready_i                    ),
        .afu_pio_select              (  afu_pio_select                      ),
        .afu_tx_st_dvalid            (  afu_tx_st0_dvalid_o                 ),
        .afu_tx_st_sop               (  afu_tx_st0_sop_o                    ),
        .afu_tx_st_eop               (  afu_tx_st0_eop_o                    ),
        .afu_tx_st_passthrough       (  afu_tx_st0_passthrough_o            ),
        .afu_tx_st_data              (  afu_tx_st0_data_o                   ),
        .afu_tx_st_hdr               (  afu_tx_st0_hdr_o                    ),
        .wr_last                     (  wr_last                             ),
        .afu_tx_st_hvalid            (  afu_tx_st0_hvalid_o                 ),
        .default_config_txc_eop      (  default_config_txc_eop              ),
        .default_config_txc_header   (  default_config_tx_st_header_update  ),
        .default_config_txc_payload  (  default_config_txc_payload          ),
        .default_config_txc_sop      (  default_config_txc_sop              ),
        .default_config_txc_valid    (  default_config_txc_valid            ),
        .pio_txc_eop                 (  pio_txc_eop                         ),
        .pio_txc_header              (  pio_txc_header_update               ),
        .pio_txc_payload             (  pio_txc_payload                     ),
        .pio_txc_sop                 (  pio_txc_sop                         ),
        .pio_txc_valid               (  pio_txc_valid                       ),
	.np_ca_rx_sop      	     (  np_ca_rx_sop             	    ),
	.np_ca_rx_eop      	     (  np_ca_rx_eop             	    ),
	.np_ca_rx_hvalid   	     (  np_ca_rx_hvalid          	    ),
	.np_ca_rx_dvalid   	     (  np_ca_rx_dvalid          	    ),
	.np_ca_rx_header   	     (  np_ca_rx_header          	    ),
	.np_ca_rx_data     	     (  np_ca_rx_data            	    ),
        .tx_p_data_counter           (  tx_p_data_counter                   ),
        .tx_np_data_counter          (  tx_np_data_counter                  ),
        .tx_cpl_data_counter         (  tx_cpl_data_counter                 ),
        .tx_p_header_counter         (  tx_p_header_counter                 ),
        .tx_np_header_counter        (  tx_np_header_counter                ),
        .tx_cpl_header_counter       (  tx_cpl_header_counter               ),
        .p_tlp_sent_tag              (  p_tlp_sent_tag                      ),
        .p_tlp_sent_tag_valid        (  p_tlp_sent_tag_valid                ), 
        .wr_tlp_fifo_empty           (  wr_tlp_fifo_empty                   ),
        .wr_tlp_fifo_almost_full     (  wr_tlp_fifo_almost_full             ),
        .rd_tlp_fifo_almost_full     (  rd_tlp_fifo_almost_full             ),
        .avst4to1_np_hdr_crd_pop     (  avst4to1_np_hdr_crd_pop             ),
        .tx_st0_dvalid               (  ed_tx_st0_dvalid_o                  ),
        .tx_st0_sop                  (  ed_tx_st0_sop_o                     ),
        .tx_st0_eop                  (  ed_tx_st0_eop_o                     ),
        .tx_st0_passthrough          (  ed_tx_st0_passthrough_o             ),
        .tx_st0_data                 (  ed_tx_st0_payload_o                 ),
        .tx_st0_data_parity          (  ed_tx_st0_data_parity               ),
        .tx_st0_hdr                  (  ed_tx_st0_header_o                  ),
        .tx_st0_hdr_parity           (  ed_tx_st0_hdr_parity                ),
        .tx_st0_hvalid               (  ed_tx_st0_hvalid_o                  ),
        .tx_st0_prefix               (  ed_tx_st0_prefix_o                  ),
        .tx_st0_prefix_parity        (  ed_tx_st0_prefix_parity             ),
        .tx_st0_RSSAI_prefix         (                                      ),
        .tx_st0_RSSAI_prefix_parity  (                                      ),
        .tx_st0_pvalid               (  ed_tx_st0_pvalid_o                  ),
        .tx_st0_vfactive             (  ed_tx_st0_vfactive                  ),
        .tx_st0_vfnum                (  ed_tx_st0_vfnum                     ),
        .tx_st0_pfnum                (  ed_tx_st0_pfnum                     ),
        .tx_st0_chnum                (  ed_tx_st0_chnum                     ),
        .tx_st0_empty                (  ed_tx_st0_empty                     ),
        .tx_st0_misc_parity          (  ed_tx_st0_misc_parity               ),
        .tx_st1_dvalid               (  ed_tx_st1_dvalid_o                  ),
        .tx_st1_sop                  (  ed_tx_st1_sop_o                     ),
        .tx_st1_eop                  (  ed_tx_st1_eop_o                     ),
        .tx_st1_passthrough          (  ed_tx_st1_passthrough_o             ),
        .tx_st1_data                 (  ed_tx_st1_payload_o                 ),
        .tx_st1_data_parity          (  ed_tx_st1_data_parity               ),
        .tx_st1_hdr                  (  ed_tx_st1_header_o                  ),
        .tx_st1_hdr_parity           (  ed_tx_st1_hdr_parity                ),
        .tx_st1_hvalid               (  ed_tx_st1_hvalid_o                  ),
        .tx_st1_prefix               (  ed_tx_st1_prefix_o                  ),
        .tx_st1_prefix_parity        (  ed_tx_st1_prefix_parity             ),
        .tx_st1_RSSAI_prefix         (                                      ),
        .tx_st1_RSSAI_prefix_parity  (                                      ),
        .tx_st1_pvalid               (  ed_tx_st1_pvalid_o                  ),
        .tx_st1_vfactive             (  ed_tx_st1_vfactive                  ),
        .tx_st1_vfnum                (  ed_tx_st1_vfnum                     ),
        .tx_st1_pfnum                (  ed_tx_st1_pfnum                     ),
        .tx_st1_chnum                (  ed_tx_st1_chnum                     ),
        .tx_st1_empty                (  ed_tx_st1_empty                     ),
        .tx_st1_misc_parity          (  ed_tx_st1_misc_parity               ),
        .tx_st2_dvalid               (  ed_tx_st2_dvalid_o                  ),
        .tx_st2_sop                  (  ed_tx_st2_sop_o                     ),
        .tx_st2_eop                  (  ed_tx_st2_eop_o                     ),
        .tx_st2_passthrough          (  ed_tx_st2_passthrough_o             ),
        .tx_st2_data                 (  ed_tx_st2_payload_o                 ),
        .tx_st2_data_parity          (  ed_tx_st2_data_parity               ),
        .tx_st2_hdr                  (  ed_tx_st2_header_o                  ),
        .tx_st2_hdr_parity           (  ed_tx_st2_hdr_parity                ),
        .tx_st2_hvalid               (  ed_tx_st2_hvalid_o                  ),
        .tx_st2_prefix               (  ed_tx_st2_prefix_o                  ),
        .tx_st2_prefix_parity        (  ed_tx_st2_prefix_parity             ),
        .tx_st2_RSSAI_prefix         (                                      ),
        .tx_st2_RSSAI_prefix_parity  (                                      ),
        .tx_st2_pvalid               (  ed_tx_st2_pvalid_o                  ),
        .tx_st2_vfactive             (  ed_tx_st2_vfactive_o                ),
        .tx_st2_vfnum                (  ed_tx_st2_vfnum                     ),
        .tx_st2_pfnum                (  ed_tx_st2_pfnum                     ),
        .tx_st2_chnum                (  ed_tx_st2_chnum                     ),
        .tx_st2_empty                (  ed_tx_st2_empty                     ),
        .tx_st2_misc_parity          (  ed_tx_st2_misc_parity               ),
        .tx_st3_dvalid               (  ed_tx_st3_dvalid_o                  ),
        .tx_st3_sop                  (  ed_tx_st3_sop_o                     ),
        .tx_st3_eop                  (  ed_tx_st3_eop_o                     ),
        .tx_st3_passthrough          (  ed_tx_st3_passthrough_o             ),
        .tx_st3_data                 (  ed_tx_st3_payload_o                 ),
        .tx_st3_data_parity          (  ed_tx_st3_data_parity               ),
        .tx_st3_hdr                  (  ed_tx_st3_header_o                  ),
        .tx_st3_hdr_parity           (  ed_tx_st3_hdr_parity                ),
        .tx_st3_hvalid               (  ed_tx_st3_hvalid_o                  ),
        .tx_st3_prefix               (  ed_tx_st3_prefix_o                  ),
        .tx_st3_prefix_parity        (  ed_tx_st3_prefix_parity             ),
        .tx_st3_RSSAI_prefix         (                                      ),
        .tx_st3_RSSAI_prefix_parity  (                                      ),
        .tx_st3_pvalid               (  ed_tx_st3_pvalid_o                  ),
        .tx_st3_vfactive             (  ed_tx_st3_vfactive                  ),
        .tx_st3_vfnum                (  ed_tx_st3_vfnum                     ),
        .tx_st3_pfnum                (  ed_tx_st3_pfnum                     ),
        .tx_st3_chnum                (  ed_tx_st3_chnum                     ),
        .tx_st3_empty                (  ed_tx_st3_empty                     ),
        .tx_st3_misc_parity          (  ed_tx_st3_misc_parity               )
        );                                                                  


//Passthrough User can implement the AFU logic here 

  //-------------------------------------------------------
  // CSR Address Remapping: BAR0+0x080000 → vendor CSR 0x000100
  // Enables GPU CSR to be accessed through vendor CSR region
  //-------------------------------------------------------
  // Removed address remapping - CSR was already broken before remapping
  // Using original address directly

  //-------------------------------------------------------
  // PF1 BAR2 example CSR + Vortex GPU CSR registers     --
  //-------------------------------------------------------
wire [31:0] read_delay;

// Vortex GPU CSR interface signals
wire        vx_launch_trigger;
wire [63:0] vx_kernel_addr;
wire [63:0] vx_kernel_args;
wire [31:0] vx_grid_dim_x;
wire [31:0] vx_grid_dim_y;
wire [31:0] vx_grid_dim_z;
wire [31:0] vx_block_dim_x;
wire [31:0] vx_block_dim_y;
wire [31:0] vx_block_dim_z;

// Real GPU status from vortex_gpu_wrapper (via afu_top, ip2hdm_clk domain)
logic [7:0]  gpu_status_from_afu;
logic [63:0] gpu_cycles_from_afu;
logic [63:0] gpu_instrs_from_afu;

// CDC: Launch trigger pulse (ip2csr_avmm_clk 125 MHz) -> toggle for afu_top.
// vx_launch_trigger is a single-cycle pulse from ex_default_csr_top.
// Convert to a toggle here so afu_top can safely 2-FF sync + edge-detect it
// in the ip2hdm_clk (400 MHz) domain.
logic vx_launch_toggle;

always_ff @(posedge ip2csr_avmm_clk or negedge ip2csr_avmm_rstn) begin
    if (!ip2csr_avmm_rstn)
        vx_launch_toggle <= 1'b0;
    else if (vx_launch_trigger)
        vx_launch_toggle <= ~vx_launch_toggle;
end

// CDC: GPU status (ip2hdm_clk ~400 MHz) -> CSR domain (ip2csr_avmm_clk 125 MHz)
// Status is quasi-static (changes on kernel launch/completion), 2-FF sync is safe.
// Cycle/instruction counters are frozen after kernel completion, so they are
// stable when the host reads them (host polls STATUS=DONE first).
logic [7:0]  vx_status_r;
logic [63:0] vx_cycles_r;
logic [63:0] vx_instrs_r;

logic [7:0]  gpu_status_sync1;
logic [63:0] gpu_cycles_sync1;
logic [63:0] gpu_instrs_sync1;

always_ff @(posedge ip2csr_avmm_clk or negedge ip2csr_avmm_rstn) begin
    if (!ip2csr_avmm_rstn) begin
        gpu_status_sync1 <= 8'h00;
        vx_status_r      <= 8'h00;
        gpu_cycles_sync1 <= 64'h0;
        vx_cycles_r      <= 64'h0;
        gpu_instrs_sync1 <= 64'h0;
        vx_instrs_r      <= 64'h0;
    end else begin
        gpu_status_sync1 <= gpu_status_from_afu;
        vx_status_r      <= gpu_status_sync1;
        gpu_cycles_sync1 <= gpu_cycles_from_afu;
        vx_cycles_r      <= gpu_cycles_sync1;
        gpu_instrs_sync1 <= gpu_instrs_from_afu;
        vx_instrs_r      <= gpu_instrs_sync1;
    end
end

 // CSR register file driven by CXL IP's internal AVMM interconnect (ip2csr bus).
 // UPDATED: Also handles GPU CSR requests from cafu bus (0x180100-0x18013C range)
 // Request mux: GPU CSR has priority over normal CSR if both request simultaneously
 logic [21:0] csr_muxed_address;
 logic csr_muxed_write;
 logic csr_muxed_read;
 logic [63:0] csr_muxed_writedata;
 logic [7:0] csr_muxed_byteenable;
 logic csr_muxed_poison;

 assign csr_muxed_address   = gpu_csr_avmm_write | gpu_csr_avmm_read ? gpu_csr_avmm_address   : ip2csr_avmm_address;
 assign csr_muxed_write     = gpu_csr_avmm_write | gpu_csr_avmm_read ? gpu_csr_avmm_write     : ip2csr_avmm_write;
 assign csr_muxed_read      = gpu_csr_avmm_write | gpu_csr_avmm_read ? gpu_csr_avmm_read      : ip2csr_avmm_read;
 assign csr_muxed_writedata = gpu_csr_avmm_write ? ip2cafu_avmm_writedata : ip2csr_avmm_writedata;
 assign csr_muxed_byteenable = gpu_csr_avmm_write ? ip2cafu_avmm_byteenable : ip2csr_avmm_byteenable;
 assign csr_muxed_poison    = 1'b0;  // GPU CSR never has poison

 // Response routing: route responses back to appropriate source
 logic csr_response_is_gpu;  // Latch which source gets the response
 always_ff @(posedge ip2csr_avmm_clk or negedge ip2csr_avmm_rstn) begin
     if (!ip2csr_avmm_rstn)
         csr_response_is_gpu <= 1'b0;
     else if (csr_muxed_read | csr_muxed_write)
         csr_response_is_gpu <= (gpu_csr_avmm_write | gpu_csr_avmm_read);
 end

 // Route responses to appropriate sink
 logic gpu_csr_waitrequest;
 logic [63:0] gpu_csr_readdata;
 logic gpu_csr_readdatavalid;

 assign gpu_csr_waitrequest   = csr2ip_avmm_waitrequest;
 assign gpu_csr_readdata      = csr2ip_avmm_readdata;
 assign gpu_csr_readdatavalid = csr2ip_avmm_readdatavalid && csr_response_is_gpu;

 ex_default_csr_top ex_default_csr_top_inst(
    .csr_avmm_clk                        ( ip2csr_avmm_clk                   ),
    .csr_avmm_rstn                       ( ip2csr_avmm_rstn                  ),
    .csr_avmm_waitrequest                ( csr2ip_avmm_waitrequest           ),
    .csr_avmm_readdata                   ( csr2ip_avmm_readdata              ),
    .csr_avmm_readdatavalid              ( csr2ip_avmm_readdatavalid         ),
    .csr_avmm_writedata                  ( csr_muxed_writedata               ),
    .csr_avmm_poison                     ( csr_muxed_poison                  ),
    .csr_avmm_address                    ( csr_muxed_address                 ),
    .csr_avmm_write                      ( csr_muxed_write                   ),
    .csr_avmm_read                       ( csr_muxed_read                    ),
    .csr_avmm_byteenable                 ( csr_muxed_byteenable              ),
    .read_delay                          ( read_delay                        ),
    // Vortex GPU CSR interface
    .vx_launch_trigger                   ( vx_launch_trigger                 ),
    .vx_kernel_addr                      ( vx_kernel_addr                    ),
    .vx_kernel_args                      ( vx_kernel_args                    ),
    .vx_grid_dim_x                       ( vx_grid_dim_x                     ),
    .vx_grid_dim_y                       ( vx_grid_dim_y                     ),
    .vx_grid_dim_z                       ( vx_grid_dim_z                     ),
    .vx_block_dim_x                      ( vx_block_dim_x                    ),
    .vx_block_dim_y                      ( vx_block_dim_y                    ),
    .vx_block_dim_z                      ( vx_block_dim_z                    ),
    .vx_status                           ( vx_status_r                       ),
    .vx_cycles                           ( vx_cycles_r                       ),
    .vx_instrs                           ( vx_instrs_r                       )
 );

// SignalTap IP commented out (sigtap_512.ip not available)
//`ifndef VCSSIM
//    // PF1, BAR2
//    wire [31:0]  ex_csr_mon_trig;
//    wire [511:0] ex_csr_mon_data;
//    sigtap_512 ex_csr_mon (
//        .acq_clk        (ip2csr_avmm_clk),
//        .acq_trigger_in (ex_csr_mon_trig),
//        .acq_data_in    (ex_csr_mon_data)
//    );
//    assign ex_csr_mon_trig[0]     = ip2csr_avmm_write;
//    assign ex_csr_mon_trig[1]     = ip2csr_avmm_read;
//    assign ex_csr_mon_trig[2]     = csr2ip_avmm_waitrequest;
//    assign ex_csr_mon_trig[3]     = csr2ip_avmm_readdatavalid;
//
//    assign ex_csr_mon_data[31:0] = ip2csr_avmm_address;
//    assign ex_csr_mon_data[63:32]= ip2csr_avmm_writedata;
//    assign ex_csr_mon_data[95:64]= csr2ip_avmm_readdata;
//    assign ex_csr_mon_data[96]   = csr2ip_avmm_readdatavalid;
//    assign ex_csr_mon_data[97]   = csr2ip_avmm_waitrequest;
//    assign ex_csr_mon_data[98]   = ip2csr_avmm_write;
//    assign ex_csr_mon_data[99]   = ip2csr_avmm_read;
//`endif


//--------------------------------------------------------------------
// i-AFU
//--------------------------------------------------------------------

 afu_top afu_top_inst(
     

    // DDRMC <--> CXL-IP Slice

    .mc2ip_0_sr_status                     (mc2ip_0_sr_status          ),
	
     /* write address channel
      */
    //Channel-->0	  
	
   .ip2hdm_aximm0_awvalid   ( ip2hdm_aximm0_awvalid   ) ,       
   .ip2hdm_aximm0_awid      ( ip2hdm_aximm0_awid      ) ,       
   .ip2hdm_aximm0_awaddr    ( ip2hdm_aximm0_awaddr    ) ,       
   .ip2hdm_aximm0_awlen     ( ip2hdm_aximm0_awlen     ) ,       
   .ip2hdm_aximm0_awregion  ( ip2hdm_aximm0_awregion  ) ,       
   .ip2hdm_aximm0_awuser    ( ip2hdm_aximm0_awuser    ) ,       
   .ip2hdm_aximm0_awsize    ( ip2hdm_aximm0_awsize    ) ,      
   .ip2hdm_aximm0_awburst   ( ip2hdm_aximm0_awburst   ) ,      
   .ip2hdm_aximm0_awprot    ( ip2hdm_aximm0_awprot    ) ,      
   .ip2hdm_aximm0_awqos     ( ip2hdm_aximm0_awqos     ) ,      
   .ip2hdm_aximm0_awcache   ( ip2hdm_aximm0_awcache   ) ,      
   .ip2hdm_aximm0_awlock    ( ip2hdm_aximm0_awlock    ) ,      
   .hdm2ip_aximm0_awready   ( hdm2ip_aximm0_awready   ) ,
     /* write data channel
      */
   .ip2hdm_aximm0_wvalid    ( ip2hdm_aximm0_wvalid   ) ,          
   .ip2hdm_aximm0_wdata     ( ip2hdm_aximm0_wdata    ) ,           
   .ip2hdm_aximm0_wstrb     ( ip2hdm_aximm0_wstrb    ) ,           
   .ip2hdm_aximm0_wlast     ( ip2hdm_aximm0_wlast    ) ,           
   .ip2hdm_aximm0_wuser     ( ip2hdm_aximm0_wuser    ) ,           
   .hdm2ip_aximm0_wready  	( hdm2ip_aximm0_wready   ) ,
     /* write response channel
      */
   .hdm2ip_aximm0_bvalid    ( hdm2ip_aximm0_bvalid   ) ,
   .hdm2ip_aximm0_bid       ( hdm2ip_aximm0_bid      ) ,
   .hdm2ip_aximm0_buser     ( hdm2ip_aximm0_buser    ) ,
   .hdm2ip_aximm0_bresp     ( hdm2ip_aximm0_bresp    ) ,
   .ip2hdm_aximm0_bready    ( ip2hdm_aximm0_bready   ) ,               
     /* read address channel
      */
   .ip2hdm_aximm0_arvalid   ( ip2hdm_aximm0_arvalid  ) ,         
   .ip2hdm_aximm0_arid      ( ip2hdm_aximm0_arid     ) ,         
   .ip2hdm_aximm0_araddr    ( ip2hdm_aximm0_araddr   ) ,         
   .ip2hdm_aximm0_arlen     ( ip2hdm_aximm0_arlen    ) ,         
   .ip2hdm_aximm0_arregion  ( ip2hdm_aximm0_arregion ) ,         
   .ip2hdm_aximm0_aruser    ( ip2hdm_aximm0_aruser   ) ,         
   .ip2hdm_aximm0_arsize    ( ip2hdm_aximm0_arsize   ) ,         
   .ip2hdm_aximm0_arburst   ( ip2hdm_aximm0_arburst  ) ,         
   .ip2hdm_aximm0_arprot    ( ip2hdm_aximm0_arprot   ) ,         
   .ip2hdm_aximm0_arqos     ( ip2hdm_aximm0_arqos    ) ,         
   .ip2hdm_aximm0_arcache   ( ip2hdm_aximm0_arcache  ) ,         
   .ip2hdm_aximm0_arlock    ( ip2hdm_aximm0_arlock   ) ,         
   .hdm2ip_aximm0_arready   ( hdm2ip_aximm0_arready  ) , 
     /* read response channel
      */
   .hdm2ip_aximm0_rvalid    ( hdm2ip_aximm0_rvalid  )  ,
   .hdm2ip_aximm0_rlast     ( hdm2ip_aximm0_rlast  )  ,
   .hdm2ip_aximm0_rid       ( hdm2ip_aximm0_rid     )  ,
   .hdm2ip_aximm0_rdata     ( hdm2ip_aximm0_rdata   )  ,
   .hdm2ip_aximm0_ruser     ( hdm2ip_aximm0_ruser   )  ,
   .hdm2ip_aximm0_rresp     ( hdm2ip_aximm0_rresp   )  ,
   .ip2hdm_aximm0_rready    ( ip2hdm_aximm0_rready  )  ,  



    .mc2ip_1_sr_status                     (mc2ip_1_sr_status          ),
  

//Channel-1
     /* write address channel
      */
   .ip2hdm_aximm1_awvalid   ( ip2hdm_aximm1_awvalid   ) ,       
   .ip2hdm_aximm1_awid      ( ip2hdm_aximm1_awid      ) ,       
   .ip2hdm_aximm1_awaddr    ( ip2hdm_aximm1_awaddr    ) ,       
   .ip2hdm_aximm1_awlen     ( ip2hdm_aximm1_awlen     ) ,       
   .ip2hdm_aximm1_awregion  ( ip2hdm_aximm1_awregion  ) ,       
   .ip2hdm_aximm1_awuser    ( ip2hdm_aximm1_awuser    ) ,       
   .ip2hdm_aximm1_awsize    ( ip2hdm_aximm1_awsize    ) ,      
   .ip2hdm_aximm1_awburst   ( ip2hdm_aximm1_awburst   ) ,      
   .ip2hdm_aximm1_awprot    ( ip2hdm_aximm1_awprot    ) ,      
   .ip2hdm_aximm1_awqos     ( ip2hdm_aximm1_awqos     ) ,      
   .ip2hdm_aximm1_awcache   ( ip2hdm_aximm1_awcache   ) ,      
   .ip2hdm_aximm1_awlock    ( ip2hdm_aximm1_awlock    ) ,      
   .hdm2ip_aximm1_awready   ( hdm2ip_aximm1_awready   ) ,
     /* write data channel
      */
   .ip2hdm_aximm1_wvalid    ( ip2hdm_aximm1_wvalid   ) ,          
   .ip2hdm_aximm1_wdata     ( ip2hdm_aximm1_wdata    ) ,           
   .ip2hdm_aximm1_wstrb     ( ip2hdm_aximm1_wstrb    ) ,           
   .ip2hdm_aximm1_wlast     ( ip2hdm_aximm1_wlast    ) ,           
   .ip2hdm_aximm1_wuser     ( ip2hdm_aximm1_wuser    ) ,           
   .hdm2ip_aximm1_wready  	( hdm2ip_aximm1_wready   ) ,
     /* write response channel
      */
   .hdm2ip_aximm1_bvalid    ( hdm2ip_aximm1_bvalid   ) ,
   .hdm2ip_aximm1_bid       ( hdm2ip_aximm1_bid      ) ,
   .hdm2ip_aximm1_buser     ( hdm2ip_aximm1_buser    ) ,
   .hdm2ip_aximm1_bresp     ( hdm2ip_aximm1_bresp    ) ,
   .ip2hdm_aximm1_bready    ( ip2hdm_aximm1_bready   ) ,               
     /* read address channel
      */
   .ip2hdm_aximm1_arvalid   ( ip2hdm_aximm1_arvalid  ) ,         
   .ip2hdm_aximm1_arid      ( ip2hdm_aximm1_arid     ) ,         
   .ip2hdm_aximm1_araddr    ( ip2hdm_aximm1_araddr   ) ,         
   .ip2hdm_aximm1_arlen     ( ip2hdm_aximm1_arlen    ) ,         
   .ip2hdm_aximm1_arregion  ( ip2hdm_aximm1_arregion ) ,         
   .ip2hdm_aximm1_aruser    ( ip2hdm_aximm1_aruser   ) ,         
   .ip2hdm_aximm1_arsize    ( ip2hdm_aximm1_arsize   ) ,         
   .ip2hdm_aximm1_arburst   ( ip2hdm_aximm1_arburst  ) ,         
   .ip2hdm_aximm1_arprot    ( ip2hdm_aximm1_arprot   ) ,         
   .ip2hdm_aximm1_arqos     ( ip2hdm_aximm1_arqos    ) ,         
   .ip2hdm_aximm1_arcache   ( ip2hdm_aximm1_arcache  ) ,         
   .ip2hdm_aximm1_arlock    ( ip2hdm_aximm1_arlock   ) ,         
   .hdm2ip_aximm1_arready   ( hdm2ip_aximm1_arready  ) , 
     /* read response channel
      */
   .hdm2ip_aximm1_rvalid    ( hdm2ip_aximm1_rvalid  )  ,
   .hdm2ip_aximm1_rlast     ( hdm2ip_aximm1_rlast  )  ,
   .hdm2ip_aximm1_rid       ( hdm2ip_aximm1_rid     )  ,
   .hdm2ip_aximm1_rdata     ( hdm2ip_aximm1_rdata   )  ,
   .hdm2ip_aximm1_ruser     ( hdm2ip_aximm1_ruser   )  ,
   .hdm2ip_aximm1_rresp     ( hdm2ip_aximm1_rresp   )  ,
   .ip2hdm_aximm1_rready    ( ip2hdm_aximm1_rready  )  ,

    // GPU CSR via PIO bridge (400MHz direct path, BAR0+0x080000)
   .gpu_avmm_clk            ( ip2hdm_clk                ),
   .gpu_avmm_rstn           ( ip2hdm_reset_n            ),
   .gpu_avmm_address        ( gpu_avmm_address_mux      ),
   .gpu_avmm_writedata      ( gpu_avmm_writedata_mux    ),
   .gpu_avmm_write          ( gpu_avmm_write_mux        ),
   .gpu_avmm_read           ( gpu_avmm_read_mux         ),
   .gpu_avmm_byteenable     ( pio_csr_avmm_byteenable   ),
   .gpu_avmm_waitrequest    ( gpu_avmm_waitrequest       ),
   .gpu_avmm_readdata       ( gpu_avmm_readdata          ),
   .gpu_avmm_readdatavalid  ( gpu_avmm_readdatavalid     ),

     /* External MC_TOP <--> BBS - AXI channels
     */
    .mc_status             ( mc_status ),
    .ip2hdm_aximm_awvalid  ( ip2hdm_aximm_awvalid ),
    .ip2hdm_aximm_awid     ( ip2hdm_aximm_awid ),
    .ip2hdm_aximm_awaddr   ( ip2hdm_aximm_awaddr ),
    .ip2hdm_aximm_awlen    ( ip2hdm_aximm_awlen ),
    .ip2hdm_aximm_awregion ( ip2hdm_aximm_awregion ),
    .ip2hdm_aximm_awuser   ( ip2hdm_aximm_awuser ),
    .ip2hdm_aximm_awsize   ( ip2hdm_aximm_awsize ),
    .ip2hdm_aximm_awburst  ( ip2hdm_aximm_awburst ),
    .ip2hdm_aximm_awprot   ( ip2hdm_aximm_awprot ),
    .ip2hdm_aximm_awqos    ( ip2hdm_aximm_awqos ),
    .ip2hdm_aximm_awcache  ( ip2hdm_aximm_awcache ),
    .ip2hdm_aximm_awlock   ( ip2hdm_aximm_awlock ),
    .hdm2ip_aximm_awready  ( hdm2ip_aximm_awready ),
    .ip2hdm_aximm_wvalid   ( ip2hdm_aximm_wvalid ),
    .ip2hdm_aximm_wdata    ( ip2hdm_aximm_wdata ),
    .ip2hdm_aximm_wstrb    ( ip2hdm_aximm_wstrb ),
    .ip2hdm_aximm_wlast    ( ip2hdm_aximm_wlast ),
    .ip2hdm_aximm_wuser    ( ip2hdm_aximm_wuser ),
    .hdm2ip_aximm_wready   ( hdm2ip_aximm_wready ),
    .hdm2ip_aximm_bvalid   ( hdm2ip_aximm_bvalid ),
    .hdm2ip_aximm_bid      ( hdm2ip_aximm_bid ),
    .hdm2ip_aximm_buser    ( hdm2ip_aximm_buser ),
    .hdm2ip_aximm_bresp    ( hdm2ip_aximm_bresp ),
    .ip2hdm_aximm_bready   ( ip2hdm_aximm_bready ),
    .ip2hdm_aximm_arvalid  ( ip2hdm_aximm_arvalid ),
    .ip2hdm_aximm_arid     ( ip2hdm_aximm_arid ),
    .ip2hdm_aximm_araddr   ( ip2hdm_aximm_araddr ),
    .ip2hdm_aximm_arlen    ( ip2hdm_aximm_arlen ),
    .ip2hdm_aximm_arregion ( ip2hdm_aximm_arregion ),
    .ip2hdm_aximm_aruser   ( ip2hdm_aximm_aruser ),
    .ip2hdm_aximm_arsize   ( ip2hdm_aximm_arsize ),
    .ip2hdm_aximm_arburst  ( ip2hdm_aximm_arburst ),
    .ip2hdm_aximm_arprot   ( ip2hdm_aximm_arprot ),
    .ip2hdm_aximm_arqos    ( ip2hdm_aximm_arqos ),
    .ip2hdm_aximm_arcache  ( ip2hdm_aximm_arcache ),
    .ip2hdm_aximm_arlock   ( ip2hdm_aximm_arlock ),
    .hdm2ip_aximm_arready  ( hdm2ip_aximm_arready ),
    .hdm2ip_aximm_rvalid   ( hdm2ip_aximm_rvalid ),
    .hdm2ip_aximm_rlast    ( hdm2ip_aximm_rlast ),
    .hdm2ip_aximm_rid      ( hdm2ip_aximm_rid ),
    .hdm2ip_aximm_rdata    ( hdm2ip_aximm_rdata ),
    .hdm2ip_aximm_ruser    ( hdm2ip_aximm_ruser ),
    .hdm2ip_aximm_rresp    ( hdm2ip_aximm_rresp ),
    .ip2hdm_aximm_rready   ( ip2hdm_aximm_rready )  

,   .ip2hdm_clk     (ip2hdm_clk)
,   .ip2hdm_reset_n (ip2hdm_reset_n_ff)
,   .read_delay     (read_delay)

    // GPU status outputs (ip2hdm_clk domain -> CDC -> CSR domain)
,   .gpu_status_out          (gpu_status_from_afu)
,   .gpu_cycles_out          (gpu_cycles_from_afu)
,   .gpu_instrs_out          (gpu_instrs_from_afu)

    // GPU launch trigger — toggle-encoded for safe CDC into ip2hdm_clk inside afu_top.
    // vx_launch_toggle is generated below from the CSR pulse in ip2csr_avmm_clk.
,   .ext_vx_launch_toggle    (vx_launch_toggle)
,   .ext_vx_kernel_addr      (vx_kernel_addr)
,   .ext_vx_kernel_args      (vx_kernel_args)


    // CIRA completion request/result handshake, all in ip2hdm_clk.
,   .cira_cache_req_valid      (cira_cache_req_valid)
,   .cira_cache_req_status     (cira_cache_req_status)
,   .cira_cache_req_result     (cira_cache_req_result)
,   .cira_cache_req_hpa        (cira_cache_req_hpa)
,   .cira_cache_req_busy       (cira_cache_req_busy)
,   .cira_cache_req_done       (cira_cache_req_done)
,   .cira_cache_req_error      (cira_cache_req_error)
);


`ifndef DRAM_DISABLE
// ================================================================================================
// DDR Memory Controller Module
//--------------------------------------------------------------------
// Basic mem model replaces MC+DDR and is only used during RTL development.
// All standard sims should use MC+DDR.

  // ------------------------------------------------------------------------------------------------------------------
  // ------------------------------------------------------------------------------------------------------------------
  mc_top     mc_top
  (
    .ipclk ( ip2hdm_clk ),
    .ipresetn ( ip2hdm_reset_n_ff ),
    .emif_avmm_1_axi_0 ( emif_avmm_1_axi_0 ),
    .mc_sr_status_ipclk ( mc_status ),
    .mc_err_cnt_ipclk ( mc_err_cnt ),

     /* External MC_TOP <--> BBS - AXI channels
     */
    .ip2hdm_aximm_awvalid ( ip2hdm_aximm_awvalid ),
    .ip2hdm_aximm_awid ( ip2hdm_aximm_awid ),
    .ip2hdm_aximm_awaddr ( ip2hdm_aximm_awaddr ),
    .ip2hdm_aximm_awlen ( ip2hdm_aximm_awlen ),
    .ip2hdm_aximm_awregion ( ip2hdm_aximm_awregion ),
    .ip2hdm_aximm_awuser ( ip2hdm_aximm_awuser ),
    .ip2hdm_aximm_awsize ( ip2hdm_aximm_awsize ),
    .ip2hdm_aximm_awburst ( ip2hdm_aximm_awburst ),
    .ip2hdm_aximm_awprot ( ip2hdm_aximm_awprot ),
    .ip2hdm_aximm_awqos ( ip2hdm_aximm_awqos ),
    .ip2hdm_aximm_awcache ( ip2hdm_aximm_awcache ),
    .ip2hdm_aximm_awlock ( ip2hdm_aximm_awlock ),
    .hdm2ip_aximm_awready ( hdm2ip_aximm_awready ),
    .ip2hdm_aximm_wvalid ( ip2hdm_aximm_wvalid ),
    .ip2hdm_aximm_wdata ( ip2hdm_aximm_wdata ),
    .ip2hdm_aximm_wstrb ( ip2hdm_aximm_wstrb ),
    .ip2hdm_aximm_wlast ( ip2hdm_aximm_wlast ),
    .ip2hdm_aximm_wuser ( ip2hdm_aximm_wuser ),
    .hdm2ip_aximm_wready ( hdm2ip_aximm_wready ),
    .hdm2ip_aximm_bvalid ( hdm2ip_aximm_bvalid ),
    .hdm2ip_aximm_bid ( hdm2ip_aximm_bid ),
    .hdm2ip_aximm_buser ( hdm2ip_aximm_buser ),
    .hdm2ip_aximm_bresp ( hdm2ip_aximm_bresp ),
    .ip2hdm_aximm_bready ( ip2hdm_aximm_bready ),
    .ip2hdm_aximm_arvalid ( ip2hdm_aximm_arvalid ),
    .ip2hdm_aximm_arid ( ip2hdm_aximm_arid ),
    .ip2hdm_aximm_araddr ( ip2hdm_aximm_araddr ),
    .ip2hdm_aximm_arlen ( ip2hdm_aximm_arlen ),
    .ip2hdm_aximm_arregion ( ip2hdm_aximm_arregion ),
    .ip2hdm_aximm_aruser ( ip2hdm_aximm_aruser ),
    .ip2hdm_aximm_arsize ( ip2hdm_aximm_arsize ),
    .ip2hdm_aximm_arburst ( ip2hdm_aximm_arburst ),
    .ip2hdm_aximm_arprot ( ip2hdm_aximm_arprot ),
    .ip2hdm_aximm_arqos ( ip2hdm_aximm_arqos ),
    .ip2hdm_aximm_arcache ( ip2hdm_aximm_arcache ),
    .ip2hdm_aximm_arlock ( ip2hdm_aximm_arlock ),
    .hdm2ip_aximm_arready ( hdm2ip_aximm_arready ),
    .hdm2ip_aximm_rvalid ( hdm2ip_aximm_rvalid ),
    .hdm2ip_aximm_rlast ( hdm2ip_aximm_rlast ),
    .hdm2ip_aximm_rid ( hdm2ip_aximm_rid ),
    .hdm2ip_aximm_rdata ( hdm2ip_aximm_rdata ),
    .hdm2ip_aximm_ruser ( hdm2ip_aximm_ruser ),
    .hdm2ip_aximm_rresp ( hdm2ip_aximm_rresp ),
    .ip2hdm_aximm_rready ( ip2hdm_aximm_rready ), 
 
     /* External MC_TOP <--> FPGA FABRIC - AXI channels
     */
     .noc2hdm_aximm_awready_emifclk ( noc2hdm_aximm_awready_emifclk ),
     .hdm2noc_aximm_awlen_emifclk ( hdm2noc_aximm_awlen_emifclk ),
     .hdm2noc_aximm_awregion_emifclk ( hdm2noc_aximm_awregion_emifclk ),
     .hdm2noc_aximm_awtop_emifclk ( hdm2noc_aximm_awtop_emifclk ),
     .hdm2noc_aximm_awburst_emifclk ( hdm2noc_aximm_awburst_emifclk ),
     .hdm2noc_aximm_awcache_emifclk ( hdm2noc_aximm_awcache_emifclk ),
     .hdm2noc_aximm_awlock_emifclk ( hdm2noc_aximm_awlock_emifclk ),
     .hdm2noc_aximm_awprot_emifclk ( hdm2noc_aximm_awprot_emifclk ),
     .hdm2noc_aximm_awqos_emifclk ( hdm2noc_aximm_awqos_emifclk ),
     .hdm2noc_aximm_awsize_emifclk ( hdm2noc_aximm_awsize_emifclk ),
     .hdm2noc_aximm_awaddr_emifclk ( hdm2noc_aximm_awaddr_emifclk ),
     .hdm2noc_aximm_awid_emifclk ( hdm2noc_aximm_awid_emifclk ),
     .hdm2noc_aximm_awuser_emifclk ( hdm2noc_aximm_awuser_emifclk ),
     .hdm2noc_aximm_awvalid_emifclk ( hdm2noc_aximm_awvalid_emifclk ),
     .noc2hdm_aximm_wready_emifclk ( noc2hdm_aximm_wready_emifclk ),
     .hdm2noc_aximm_wdata_emifclk ( hdm2noc_aximm_wdata_emifclk ),
     .hdm2noc_aximm_wlast_emifclk ( hdm2noc_aximm_wlast_emifclk ),
     .hdm2noc_aximm_wstrb_emifclk ( hdm2noc_aximm_wstrb_emifclk ),
     .hdm2noc_aximm_wuser_emifclk ( hdm2noc_aximm_wuser_emifclk ),
     .hdm2noc_aximm_wvalid_emifclk ( hdm2noc_aximm_wvalid_emifclk ),
     .noc2hdm_aximm_arready_emifclk ( noc2hdm_aximm_arready_emifclk ),
     .hdm2noc_aximm_arlen_emifclk ( hdm2noc_aximm_arlen_emifclk ),
     .hdm2noc_aximm_arregion_emifclk ( hdm2noc_aximm_arregion_emifclk ),
     .hdm2noc_aximm_arburst_emifclk ( hdm2noc_aximm_arburst_emifclk ),
     .hdm2noc_aximm_arcache_emifclk ( hdm2noc_aximm_arcache_emifclk ),
     .hdm2noc_aximm_arlock_emifclk ( hdm2noc_aximm_arlock_emifclk ),
     .hdm2noc_aximm_arprot_emifclk ( hdm2noc_aximm_arprot_emifclk ),
     .hdm2noc_aximm_arqos_emifclk ( hdm2noc_aximm_arqos_emifclk ),
     .hdm2noc_aximm_arsize_emifclk ( hdm2noc_aximm_arsize_emifclk ),
     .hdm2noc_aximm_araddr_emifclk ( hdm2noc_aximm_araddr_emifclk ),
     .hdm2noc_aximm_arid_emifclk ( hdm2noc_aximm_arid_emifclk ),
     .hdm2noc_aximm_aruser_emifclk ( hdm2noc_aximm_aruser_emifclk ),
     .hdm2noc_aximm_arvalid_emifclk ( hdm2noc_aximm_arvalid_emifclk ),
     .hdm2noc_aximm_bready_emifclk ( hdm2noc_aximm_bready_emifclk ),
     .noc2hdm_aximm_bresp_emifclk ( noc2hdm_aximm_bresp_emifclk ),
     .noc2hdm_aximm_bid_emifclk ( noc2hdm_aximm_bid_emifclk ),
     .noc2hdm_aximm_buser_emifclk ( noc2hdm_aximm_buser_emifclk ),
     .noc2hdm_aximm_bvalid_emifclk ( noc2hdm_aximm_bvalid_emifclk ),
     .hdm2noc_aximm_rready_emifclk ( hdm2noc_aximm_rready_emifclk ),
     .noc2hdm_aximm_rresp_emifclk ( noc2hdm_aximm_rresp_emifclk ),
     .noc2hdm_aximm_rdata_emifclk ( noc2hdm_aximm_rdata_emifclk ),
     .noc2hdm_aximm_rid_emifclk ( noc2hdm_aximm_rid_emifclk ),
     .noc2hdm_aximm_rlast_emifclk ( noc2hdm_aximm_rlast_emifclk ),
     .noc2hdm_aximm_ruser_emifclk ( noc2hdm_aximm_ruser_emifclk ),
     .noc2hdm_aximm_rvalid_emifclk ( noc2hdm_aximm_rvalid_emifclk ),
  
     /* emif clk in, emif reset in
       emif calibration signals for going to cafu_csr0_cfg space
     */
	 .emifclk ( emifclk ),
	 .emifresetn ( emifresetn ),
	 .emif_pll_locked ( emif_pll_locked ),
	 .emif_reset_done ( emif_reset_done ),
	 .emif_cal_success ( emif_cal_success ),
	 .emif_cal_fail ( emif_cal_fail ),
	 
  `ifdef HDM_SIM_CFG_USE_BASIC_MEM
	 .mem_address_rmw_emifclk ( mem_address_rmw_emifclk ),
  `endif

     /* AVMM signals from emif
     */
	 .emif2hdm_avmm_ready_emifclk ( emif2hdm_avmm_ready_emifclk ),

     /* AVMM signals to emif
     */
	 .hdm2emif_avmm_byteenable_emifclk ( hdm2emif_avmm_byteenable_emifclk ),
	 .hdm2emif_avmm_writedata_emifclk  ( hdm2emif_avmm_writedata_emifclk  ),
	 .hdm2emif_avmm_address_emifclk    ( hdm2emif_avmm_address_emifclk    ),
	 .hdm2emif_avmm_write_emifclk      ( hdm2emif_avmm_write_emifclk      ),
	 .hdm2emif_avmm_read_emifclk       ( hdm2emif_avmm_read_emifclk       ),
	 .hdm2emif_avmm_write_poison_emifclk ( hdm2emif_avmm_write_poison_emifclk ),

     /* AVMM signals from emif
     */
	 .emif2hdm_avmm_readdatavalid_emifclk ( emif2hdm_avmm_readdatavalid_emifclk ),
	 .emif2hdm_avmm_readdata_emifclk      ( emif2hdm_avmm_readdata_emifclk      ),
	 .emif2hdm_avmm_read_poison_emifclk   ( emif2hdm_avmm_read_poison_emifclk   )
  ); 


  // ------------------------------------------------------------------------------------------------------------------
  // ------------------------------------------------------------------------------------------------------------------
  /* EMIF AVMM
  */
  

  mc_emif_avmm   inst_emif_avmm
  (
    .mem_refclk ( mem_refclk  ),  //emif_pll_refclk ),
    .pll_locked ( emif_pll_locked ),
    .local_reset_done ( emif_reset_done ),
    .local_cal_success ( emif_cal_success ),
    .local_cal_fail ( emif_cal_fail ),
    .emif_usr_reset_n ( emifresetn ),
    .emif_usr_clk ( emifclk ),

    /* DDR4 signals
    */
    .mem_ck ( mem_ck ),
    .mem_ck_n ( mem_ck_n ),
    .mem_a ( mem_a ),
    .mem_act_n ( mem_act_n ),
    .mem_ba ( mem_ba ),
    .mem_bg ( mem_bg ),
    .mem_cke ( mem_cke ),
    .mem_cs_n ( mem_cs_n ),
    .mem_odt ( mem_odt ),
    .mem_reset_n ( mem_reset_n ),
    .mem_par ( mem_par ),
    .mem_alert_n ( mem_alert_n ),
    .mem_dqs ( mem_dqs ),
    .mem_dqs_n ( mem_dqs_n ),
    .mem_dq ( mem_dq ),
    .mem_dbi_n ( mem_dbi_n ),
    .mem_oct_rzqin ( mem_oct_rzqin ),
  
    /* AVMM signals
    */
    .emif_amm_burstcount    ( emif_amm_burstcount ),
    .emif_amm_address       ( emif_amm_address    ), //hdm2emif_avmm_address_emifclk ),
    .emif_amm_writedata     ( hdm2emif_avmm_writedata_emifclk ),
    .emif_amm_byteenable    ( hdm2emif_avmm_byteenable_emifclk ),
    .emif_amm_write         ( hdm2emif_avmm_write_emifclk ),
    .emif_amm_read          ( hdm2emif_avmm_read_emifclk ),
    .emif_amm_readdata      ( emif2hdm_avmm_readdata_emifclk ),
    .emif_amm_readdatavalid ( emif2hdm_avmm_readdatavalid_emifclk ),
    .emif_amm_ready         ( emif2hdm_avmm_ready_emifclk )
  );


// ================================================================================================
`endif




endmodule
//------------------------------------------------------------------------------------
//
//
// End ed_top_wrapper_typ2.sv
//
//------------------------------------------------------------------------------------
//set foldmethod=marker
//set foldmarker=<<<,>>>
