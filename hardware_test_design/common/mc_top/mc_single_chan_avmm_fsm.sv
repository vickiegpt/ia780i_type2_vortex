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

module mc_single_chan_avmm_fsm
  import ddr_mc_top_common_pkg::*;
(
  input logic emifclk,                         // EMIF User Clock
  input logic emifresetn,                      // EMIF reset
  input logic emif_avmm_1_axi_0,

  /* signals to/from mc_ecc_req
  */
  input ddr_mc_top_common_pkg::t_reqfifo_data_post_ecc_avmm     from_mceccreq_new_req_emifclk,
 
  output ddr_mc_top_common_pkg::t_emif_fsm_cntrl_to_ecc     to_mceccreq_cntrl_emifclk,
  
  /* AVMM signals from emif
  */
  input logic from_emif_avmm_mem_ready_emifclk,

  /* AVMM signals to emif
  */
  output logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] to_emif_avmm_writedata_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_BE_WIDTH-1:0]   to_emif_avmm_byteenable_emifclk,
  output logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] to_emif_avmm_address_emifclk,

  output logic to_emif_avmm_write_emifclk,
  output logic to_emif_avmm_read_emifclk,
  output logic to_emif_avmm_write_poison_emifclk,
 
  /* signals to AVMM response handler
  */
  output logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] to_avmm_rsp_rd_id_emifclk,
  output logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] to_avmm_rsp_wr_id_emifclk,
 
  output logic to_avmm_rsp_valid_wr_id_emifclk,
  output logic to_avmm_rsp_valid_rd_id_emifclk
);

// ================================================================================================
logic internal_mem_ready;
logic internal_clear_read_valid;
logic internal_clear_write_valid;

assign to_mceccreq_cntrl_emifclk.mem_ready         = internal_mem_ready;
assign to_mceccreq_cntrl_emifclk.clear_read_valid  = internal_clear_read_valid;
assign to_mceccreq_cntrl_emifclk.clear_write_valid = internal_clear_write_valid;

assign to_emif_avmm_byteenable_emifclk = '1;

// ================================================================================================
typedef enum logic [1:0] {
  AVMM_IDLE              = 'd0,
  AVMM_RD_WAIT           = 'd1,
  AVMM_WR_WAIT           = 'd2,
  AVMM_WR_PRT_WAIT       = 'd3
} e_avmm_req_fsm;

e_avmm_req_fsm   avmm_state;
e_avmm_req_fsm   avmm_next_state;


always_ff @( posedge emifclk )
begin
  avmm_state <= ( ~emifresetn | ~emif_avmm_1_axi_0 ) ? AVMM_IDLE : avmm_next_state;
end


always_comb
begin
    to_avmm_rsp_valid_wr_id_emifclk = 1'b0;
    to_avmm_rsp_valid_rd_id_emifclk = 1'b0;
          to_avmm_rsp_wr_id_emifclk =  '0;
          to_avmm_rsp_rd_id_emifclk =  '0;
     to_emif_avmm_writedata_emifclk =  '0;
       to_emif_avmm_address_emifclk =  '0;
         to_emif_avmm_write_emifclk = 1'b0;
          to_emif_avmm_read_emifclk = 1'b0;
  to_emif_avmm_write_poison_emifclk = 1'b0;
         internal_clear_write_valid = 1'b0;		  
          internal_clear_read_valid = 1'b0;
                 internal_mem_ready = from_emif_avmm_mem_ready_emifclk;

  /* if something is on from_mceccreq_new_req_emifclk.read or from_mceccreq_new_req_emifclk.write
	 then emif_avmm_mem_ready was provided, so push onto the interface.
     emif_avmm_mem_ready will go low, hold the interface until it goes high but immed. pull it.
     But need to pull the wr_id and rd_id enables immediately.
  */
  case( avmm_state )
    AVMM_IDLE :
    begin
	  if( from_mceccreq_new_req_emifclk.read )
	  begin
		                 internal_mem_ready = 1'b0;	  
		    to_avmm_rsp_valid_rd_id_emifclk = from_mceccreq_new_req_emifclk.read;
		          to_emif_avmm_read_emifclk = from_mceccreq_new_req_emifclk.read;
		       to_emif_avmm_address_emifclk = from_mceccreq_new_req_emifclk.address;
                  to_avmm_rsp_rd_id_emifclk = from_mceccreq_new_req_emifclk.rd_id;
				  
		if( from_emif_avmm_mem_ready_emifclk ) internal_clear_read_valid = 1'b1;
				  
		if( from_emif_avmm_mem_ready_emifclk ) avmm_next_state = AVMM_IDLE;
		else                                   avmm_next_state = AVMM_RD_WAIT;
      end
	  else if( from_mceccreq_new_req_emifclk.write )
	  begin
		                 internal_mem_ready = 1'b0;	 
	        to_avmm_rsp_valid_wr_id_emifclk = from_mceccreq_new_req_emifclk.write;
		         to_emif_avmm_write_emifclk = from_mceccreq_new_req_emifclk.write;
		  to_emif_avmm_write_poison_emifclk = from_mceccreq_new_req_emifclk.write_poison;
		     to_emif_avmm_writedata_emifclk = from_mceccreq_new_req_emifclk.writedata;
		       to_emif_avmm_address_emifclk = from_mceccreq_new_req_emifclk.address;
                  to_avmm_rsp_wr_id_emifclk = from_mceccreq_new_req_emifclk.wr_id;
		
		if( from_emif_avmm_mem_ready_emifclk ) internal_clear_write_valid = 1'b1;
		  
		if( from_emif_avmm_mem_ready_emifclk ) avmm_next_state = AVMM_IDLE;
		else                                   avmm_next_state = AVMM_WR_WAIT;
      end
      else begin
                                               avmm_next_state = AVMM_IDLE;
	  end
	end  // AVMM_IDLE
	
    AVMM_RD_WAIT :
    begin
		          internal_mem_ready = 1'b0;
		   to_emif_avmm_read_emifclk = from_mceccreq_new_req_emifclk.read;
		to_emif_avmm_address_emifclk = from_mceccreq_new_req_emifclk.address;
		
      // emif avmm has NOT re-asserted mem_ready
      if( ~from_emif_avmm_mem_ready_emifclk ) avmm_next_state = AVMM_RD_WAIT;	
      else                                    avmm_next_state = AVMM_IDLE;
      
      if( from_emif_avmm_mem_ready_emifclk ) internal_clear_read_valid = 1'b1;
	end  // AVMM_RD_WAIT	

    AVMM_WR_WAIT :
    begin
		            internal_mem_ready = 1'b0;
		    to_emif_avmm_write_emifclk = from_mceccreq_new_req_emifclk.write;
		to_emif_avmm_write_poison_emifclk = from_mceccreq_new_req_emifclk.write_poison;
		to_emif_avmm_writedata_emifclk = from_mceccreq_new_req_emifclk.writedata;
		  to_emif_avmm_address_emifclk = from_mceccreq_new_req_emifclk.address; 
		  
      // emif avmm has NOT re-asserted mem_ready
      if( ~from_emif_avmm_mem_ready_emifclk ) avmm_next_state = AVMM_WR_WAIT;	
      else                                    avmm_next_state = AVMM_IDLE;
		  
      if( from_emif_avmm_mem_ready_emifclk ) internal_clear_write_valid = 1'b1;
	end  // AVMM_WR_WAIT

    default :               avmm_next_state = AVMM_IDLE;
  endcase
end

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL7lB0BBdgJ3W3AXvOuoIcXwcOZWbluAm2KLSCMZ+D0JwUapR7CwzDCkH4j4Jlorfl4djf3qWKEsX2t8sZUg2wvlwwz4KNOEdIw2Jo8sve3Pg/4xobLIUONlt6Pl9/tRLkEcXjbRHt/YizHckfwu3uV4nOBXd/ZMN4C0fViaQ4vfovakpz6VABAduDQCuBrM6Ft+iVZhwrlFujoCssDOuIUT0Iy3EeQZhPoXF0DsDliGg46F5GVSly/fThSSJmovpWDgqZMaf0nsCj1nX6j18Dq7Tj0gnnvq/6AGLefLZoJgjKFFzTwNdSgZYMOSM6KnOucaMdjHCyRemjDs2ZtlGZ/v1kmssN6FIUEGQWXfV9eB0HKNtykFh/tNSvLlWT7D8zaCFbSF5Y8XLawOSk+u1PKjyPqyIZep3bxeNMyCYbRuvUGOv9F3GWDgZ2UEvqYJHmIWtsPTSZd2zKysHMsWt6ImuNheyFCVONA70ZgdNTnj6lDD+g+oiFfoTXe//6WBS0MFDIZLKYaV9ES+/qtWdoaYP9tHp5ImD41a43mPe969wNf6CnwdLCFh5RRAGspEo3Qje/4ggI38ZXOBYaycPqMv1zxjpwyqBfriXFtus2YUEalIBa/iD1c7GQlJKGWjprMxyy7u2nmKOhVa1F0YmB8XKfA7RRnzi0giesZuAjVzrSLkcXMfBw/oi++nCueGxwIc+qMuIgXuXhGqYEzjhF0FFEIOu6X46m7MYMXGp49mj9dJq5qZQl3952K9rYm5q49MFbdSwEVVcmAh6/ULrX7+"
`endif
