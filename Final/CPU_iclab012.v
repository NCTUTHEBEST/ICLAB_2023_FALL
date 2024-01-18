// //############################################################################
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //   (C) Copyright Laboratory System Integration and Silicon Implementation
// //   All Right Reserved
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //
// //   ICLAB 2021 Final Project: Customized ISA Processor 
// //   Author              : Hsi-Hao Huang
// //
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //
// //   File Name   : CPU.v
// //   Module Name : CPU.v
// //   Release version : V1.0 (Release Date: 2021-May)
// //
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;
// axi parameter
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/
// -----------------------------
// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

//========================================================================
//						 	   PARAMETER
//========================================================================

parameter S_IDLE 			= 0 ;
parameter S_FETCH_INST 		= 1 ;
parameter S_EXE 		    = 2 ;
parameter S_WAIT	 		= 3 ;
parameter S_LD_OR_ST 		= 4 ;
parameter S_INST_TRASH      = 5 ;
parameter S_JUMP	 		= 6 ;

//========================================================================
//						 	    REG/WIRE
//========================================================================

wire         [6:0] data_sram_addr ;
wire               data_sram_r_or_w ;
wire        [15:0] data_sram_in_data ;
wire 			   set_less_than ;
wire 			   equal ;
wire               funct ;
wire               inst_out_valid ;
wire               read_or_write ;
wire               data_out_valid ;
wire        [15:0] data_dram_out ; 
wire        [15:0] inst_dram_out ;
wire        [2:0]  opcode ;
wire        [3:0]  rs_register ;
wire        [3:0]  rt_register ;
wire        [3:0]  rd_register ;
wire        [15:0] sram_out ;
wire        [10:0] data_addr ;
wire        [12:0] address;
wire signed [4:0]  immediate ;
reg                sram_r_or_w ;
reg                inst_in_valid ;
wire signed [31:0] multi ;
wire signed [15:0] ld_st_addr ;
reg                data_in_valid ;
wire signed [15:0] jump_addr ;
wire signed [15:0] add ;
wire signed [15:0] sub ;

reg  signed [15:0] pc ;
reg  signed [15:0] rs_data ;
reg  signed [15:0] rt_data ;
reg  signed [15:0] rd_data ;
wire               inst_sram_r_or_w ;
reg                inst_sram_not_empty ;
reg  signed [15:0] next_inst_in_addr ;
reg  signed [15:0] next_rt_data ;
reg         [15:0] sram_in ;
reg          [7:0] sram_addr ;
reg                data_sram_not_empty ;
wire         [6:0] inst_sram_addr ;

//========================================================================
//						 	   FSM
//========================================================================

reg [2:0] curr_state ;
reg [2:0] next_state ;

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		curr_state <= S_IDLE ;
	end
	else begin
		curr_state <= next_state ;
	end
end

always @ (*) begin
	case (curr_state)
		S_IDLE : next_state = S_FETCH_INST ;
		S_FETCH_INST : begin 
			if (opcode[1] && inst_out_valid) next_state = S_LD_OR_ST ;
			else if (inst_out_valid) next_state = (opcode[2]) ? S_JUMP : S_EXE ;
			else next_state = curr_state ;
		end
		S_JUMP      : next_state = S_INST_TRASH ;
		S_LD_OR_ST : next_state = (data_out_valid) ? S_INST_TRASH : curr_state ;
		S_INST_TRASH : next_state = S_FETCH_INST ;
		S_EXE   : next_state = (opcode[0] && funct) ? S_WAIT : S_INST_TRASH ;
		S_WAIT      : next_state = S_INST_TRASH ;
		default     : next_state = S_IDLE ;
	endcase
end

//========================================================================
//						        PC
//========================================================================

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin 
		pc <= 'h1000 ;
	end
	else begin 
		case (curr_state)
			S_JUMP : begin
				if(equal && (~opcode[0])) pc <= pc + 2 + (immediate << 1) ;
				else pc <= (opcode[0]) ? jump_addr : pc + 2 ;
			end
			S_EXE : pc <= pc + 2 ;
			S_LD_OR_ST : pc <= (data_out_valid) ? pc + 2 : pc ;
			default : pc <= pc ;
		endcase 
	end
end

//========================================================================
//						   DECODE_INSTRUCTION
//========================================================================

assign {opcode, rs_register, rt_register, rd_register, funct} = inst_dram_out ;
assign address   = inst_dram_out[11:0] ;
assign immediate = inst_dram_out[4:0] ;


//========================================================================
//						      RS_DATA
//========================================================================

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rs_data <= 0;
	end
	else begin 
		if (inst_out_valid) begin 
			if (rs_register == 0)       rs_data <= core_r0 ;
			else if (rs_register == 1)  rs_data <= core_r1 ;
			else if (rs_register == 2)  rs_data <= core_r2 ;
			else if (rs_register == 3)  rs_data <= core_r3 ;
			else if (rs_register == 4)  rs_data <= core_r4 ;
			else if (rs_register == 5)  rs_data <= core_r5 ;
			else if (rs_register == 6)  rs_data <= core_r6 ;
			else if (rs_register == 7)  rs_data <= core_r7 ;
			else if (rs_register == 8)  rs_data <= core_r8 ;
			else if (rs_register == 9)  rs_data <= core_r9 ;
			else if (rs_register == 10) rs_data <= core_r10 ;
			else if (rs_register == 11) rs_data <= core_r11 ;
			else if (rs_register == 12) rs_data <= core_r12 ;
			else if (rs_register == 13) rs_data <= core_r13 ;
			else if (rs_register == 14) rs_data <= core_r14 ;
			else if (rs_register == 15) rs_data <= core_r15 ;
			else rs_data <= rs_data ;
		end
		else rs_data <= rs_data ;
	end
end

//========================================================================
//						      RT_DATA
//========================================================================

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n)  rt_data <= 0 ;
	else  rt_data <= next_rt_data ;
end

always@(*) begin
	if (rt_register == 0)       next_rt_data = core_r0 ;
	else if (rt_register == 1)  next_rt_data = core_r1 ;
	else if (rt_register == 2)  next_rt_data = core_r2 ;
	else if (rt_register == 3)  next_rt_data = core_r3 ;
	else if (rt_register == 4)  next_rt_data = core_r4 ;
	else if (rt_register == 5)  next_rt_data = core_r5 ;
	else if (rt_register == 6)  next_rt_data = core_r6 ;
	else if (rt_register == 7)  next_rt_data = core_r7 ;
	else if (rt_register == 8)  next_rt_data = core_r8 ;
	else if (rt_register == 9)  next_rt_data = core_r9 ;
	else if (rt_register == 10) next_rt_data = core_r10 ;
	else if (rt_register == 11) next_rt_data = core_r11 ;
	else if (rt_register == 12) next_rt_data = core_r12 ;
	else if (rt_register == 13) next_rt_data = core_r13 ;
	else if (rt_register == 14) next_rt_data = core_r14 ;
	else next_rt_data = core_r15 ;
end

//========================================================================
//						      RD_DATA
//========================================================================

always @ (*) begin
	if ({opcode[0], funct} == 2'b01) rd_data = sub ;
	else if ({opcode[0], funct} == 2'b00) rd_data = add ;
	else rd_data = set_less_than ;
end

//========================================================================
//						    ALU_RESULT
//========================================================================

assign jump_addr[15:13] = 3'b000 ;
assign jump_addr[12:0]  = inst_dram_out[12:0] ;
ALU alu(
	.rs_data(rs_data),
	.rt_data(rt_data), 
	.add_out(add),
	.sub_out(sub),
	.multi_out(multi),
	.set_less_than_out(set_less_than),
	.equal_out(equal)
) ;
assign ld_st_addr = ((rs_data + immediate) << 1) + $signed(16'b0001000000000000) ;

 


//========================================================================
//						   CORE_REGISTER
//========================================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		core_r0 <= 0 ;
		core_r1 <= 0 ;
		core_r2 <= 0 ;
		core_r3 <= 0 ;
		core_r4 <= 0 ;
		core_r5 <= 0 ;
		core_r6 <= 0 ;
		core_r7 <= 0 ;
		core_r8 <= 0 ;
		core_r9 <= 0 ;
		core_r10 <= 0 ;
		core_r11 <= 0 ;
		core_r12 <= 0 ;
		core_r13 <= 0 ;
		core_r14 <= 0 ;
		core_r15 <= 0 ;
	end
	else begin 
		if (read_or_write && data_out_valid) begin 
			case (rt_register)
				0 : core_r0 <= data_dram_out ;
				1 : core_r1 <= data_dram_out ;
				2 : core_r2 <= data_dram_out ;
				3 : core_r3 <= data_dram_out ;
				4 : core_r4 <= data_dram_out ;
				5 : core_r5 <= data_dram_out ;
				6 : core_r6 <= data_dram_out ;
				7 : core_r7 <= data_dram_out ;
				8 : core_r8 <= data_dram_out ;
				9 : core_r9 <= data_dram_out ;
				10 : core_r10 <= data_dram_out ;
				11 : core_r11 <= data_dram_out ;
				12 : core_r12 <= data_dram_out ;
				13 : core_r13 <= data_dram_out ;
				14 : core_r14 <= data_dram_out ;
				15 : core_r15 <= data_dram_out ;
				default : core_r0 <= data_dram_out ;
			endcase 
		end
		else if (curr_state == S_WAIT) begin 
			case (rd_register)
				0 : core_r0 <= multi[15:0] ;
				1 : core_r1 <= multi[15:0] ;
				2 : core_r2 <= multi[15:0] ;
				3 : core_r3 <= multi[15:0] ;
				4 : core_r4 <= multi[15:0] ;
				5 : core_r5 <= multi[15:0] ;
				6 : core_r6 <= multi[15:0] ;
				7 : core_r7 <= multi[15:0] ;
				8 : core_r8 <= multi[15:0] ;
				9 : core_r9 <= multi[15:0] ;
				10 : core_r10 <= multi[15:0] ;
				11 : core_r11 <= multi[15:0] ;
				12 : core_r12 <= multi[15:0] ;
				13 : core_r13 <= multi[15:0] ;
				14 : core_r14 <= multi[15:0] ;
				15 : core_r15 <= multi[15:0] ;
				default : core_r0 <= multi[15:0] ;
			endcase 
		end
		else if (curr_state == S_EXE) begin 
			case (rd_register)
				0 : core_r0 <= rd_data ;
				1 : core_r1 <= rd_data ;
				2 : core_r2 <= rd_data ;
				3 : core_r3 <= rd_data ;
				4 : core_r4 <= rd_data ;
				5 : core_r5 <= rd_data ;
				6 : core_r6 <= rd_data ;
				7 : core_r7 <= rd_data ;
				8 : core_r8 <= rd_data ;
				9 : core_r9 <= rd_data ;
				10 : core_r10 <= rd_data ;
				11 : core_r11 <= rd_data ;
				12 : core_r12 <= rd_data ;
				13 : core_r13 <= rd_data ;
				14 : core_r14 <= rd_data ;
				15 : core_r15 <= rd_data ;
				default : core_r0 <= rd_data ;
			endcase 
		end
		else begin 
			core_r0 <= core_r0 ;
			core_r1 <= core_r1 ;
			core_r2 <= core_r2 ;
			core_r3 <= core_r3 ;
			core_r4 <= core_r4 ;
			core_r5 <= core_r5 ;
			core_r6 <= core_r6 ;
			core_r7 <= core_r7 ;
			core_r8 <= core_r8 ;
			core_r9 <= core_r9 ;
			core_r10 <= core_r10 ;
			core_r11 <= core_r11 ;
			core_r12 <= core_r12 ;
			core_r13 <= core_r13 ;
			core_r14 <= core_r14 ;
			core_r15 <= core_r15 ;
		end
	end
end

//========================================================================
//						      IO_STALL
//========================================================================

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		IO_stall <= 1 ;
	end 
	else begin 
		IO_stall <= (curr_state != S_FETCH_INST && next_state == S_FETCH_INST && curr_state != S_IDLE) ? 0 : 1 ;
	end
end

//=============================================================================================================================================================================================================================================================================================================
//              																									SRAM CACHE
//=============================================================================================================================================================================================================================================================================================================

//========================================================================
//				           SRAM_PORT_SIGNAL
//========================================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		sram_in     <= 0 ;
		sram_addr   <= 0 ;
		sram_r_or_w <= 0 ;
	
	end
	else begin 
		if (curr_state == S_FETCH_INST || curr_state == S_INST_TRASH) begin 
			sram_in     <= rdata_m_inf[2*DATA_WIDTH-1 : DATA_WIDTH] ;
			sram_addr   <= {1'b1, inst_sram_addr} ;
			sram_r_or_w <= inst_sram_r_or_w ;
		end
		else begin 
			sram_in     <= data_sram_in_data ;
			sram_addr   <= {1'b0, data_sram_addr} ;
			sram_r_or_w <= data_sram_r_or_w ;
		end
	end
end


//========================================================================
//				           SRAM_CONNECTION
//========================================================================

CPU_CACHE CACHE (.A0(sram_addr[0]),   .A1(sram_addr[1]),   .A2(sram_addr[2]),   .A3(sram_addr[3]),   .A4(sram_addr[4]),   .A5(sram_addr[5]),   .A6(sram_addr[6]),  .A7(sram_addr[7]),
				 .DO0(sram_out[0]),  .DO1(sram_out[1]),  .DO2 (sram_out[2]),  .DO3(sram_out[3]),  .DO4(sram_out[4]),  .DO5(sram_out[5]),  .DO6(sram_out[6]),  .DO7(sram_out[7]),  
				 .DO8(sram_out[8]),  .DO9(sram_out[9]),  .DO10(sram_out[10]), .DO11(sram_out[11]), .DO12(sram_out[12]), .DO13(sram_out[13]), .DO14(sram_out[14]), .DO15(sram_out[15]), 
				 .DI0(sram_in[0]),  .DI1(sram_in[1]),  .DI2(sram_in[2]),  .DI3(sram_in[3]),  .DI4(sram_in[4]),  .DI5(sram_in[5]),  .DI6(sram_in[6]),  .DI7(sram_in[7]), 
				 .DI8(sram_in[8]),  .DI9(sram_in[9]),  .DI10(sram_in[10]), .DI11(sram_in[11]), .DI12(sram_in[12]), .DI13(sram_in[13]), .DI14(sram_in[14]), .DI15(sram_in[15]),
				 .CK(clk),   .WEB(sram_r_or_w),  .OE(1'd1),   .CS(1'd1)) ;



//=============================================================================================================================================================================================================================================================================================================
//              																									DRAM
//=============================================================================================================================================================================================================================================================================================================

//========================================================================
//				            DATA_SIGNAL
//========================================================================

assign arid_m_inf    = 0 ;
assign awid_m_inf    = 0 ;
assign awsize_m_inf  = 1 ;
assign awburst_m_inf = 1 ;
assign awlen_m_inf   = 0 ;
assign arlen_m_inf   = 14'b11111111111111 ;
assign arsize_m_inf  = 6'b001001 ;
assign arburst_m_inf = 4'b0101 ;

//========================================================================
//						   DRAM_VALID_SIGNAL
//========================================================================

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin 
		inst_in_valid <= 0 ;
	end
	else begin 
		inst_in_valid <= (curr_state != S_FETCH_INST && next_state == S_FETCH_INST) ? 1 : 0 ;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin 
		data_in_valid <= 0 ;
	end
	else begin 
		data_in_valid <= (curr_state != S_LD_OR_ST && next_state == S_LD_OR_ST) ? 1 : 0 ;
	end
end

//========================================================================
//				     DATA_SRAM_READ_OR_WRITE (+ADDR)
//========================================================================

assign data_addr = ld_st_addr[11:1] ;
assign read_or_write = (opcode[0]) ? 0 : 1 ;

//========================================================================
//				         DRAM_EMPTY_OR_NOT
//========================================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		inst_sram_not_empty <= 0 ;
	end
	else begin 
		if (curr_state == S_EXE || curr_state == S_LD_OR_ST || curr_state == S_JUMP) inst_sram_not_empty <= 1 ;
		else inst_sram_not_empty <= inst_sram_not_empty ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		data_sram_not_empty <= 0 ;
	end
	else begin 
		if (curr_state == S_LD_OR_ST) data_sram_not_empty <= 1 ;
		else data_sram_not_empty <= data_sram_not_empty ;
	end
end

//========================================================================
//						 INST_BRIDGE_CONNECTION
//========================================================================

INST_BRIDGE inst_bridge(
	.clk(clk), .rst_n(rst_n), .in_valid(inst_in_valid),
	.in_addr(pc[11:1]), .sram_not_empty(inst_sram_not_empty),
	.out_valid(inst_out_valid), .inst_dram_out(inst_dram_out),
	.sram_out(sram_out), .inst_sram_r_or_w(inst_sram_r_or_w),
	.inst_sram_addr(inst_sram_addr),
	   
    .araddr_m_inf(araddr_m_inf[2*ADDR_WIDTH-1:ADDR_WIDTH]),
    .arvalid_m_inf(arvalid_m_inf[1]), .arready_m_inf(arready_m_inf[1]), 
                 
    .rdata_m_inf(rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH]),
    .rlast_m_inf(rlast_m_inf[1]), .rvalid_m_inf(rvalid_m_inf[1]),
    .rready_m_inf(rready_m_inf[1]) 
);

//========================================================================
//						 DATA_BRIDGE_CONNECTION
//========================================================================

DATA_BRIDGE data_bridge (
	.clk(clk), .rst_n(rst_n), .in_valid(data_in_valid), .read(read_or_write),
	.in_data(next_rt_data), .in_addr(data_addr), .sram_not_empty(data_sram_not_empty),
	.out_valid(data_out_valid), .data_dram_out(data_dram_out), .sram_out(sram_out), .data_sram_addr(data_sram_addr),
	.data_sram_r_or_w(data_sram_r_or_w), .data_sram_in_data(data_sram_in_data),
		
    .awaddr_m_inf(awaddr_m_inf), .awvalid_m_inf(awvalid_m_inf), .awready_m_inf(awready_m_inf),
                   
    .wdata_m_inf(wdata_m_inf), .wlast_m_inf(wlast_m_inf), .wvalid_m_inf(wvalid_m_inf),
    .wready_m_inf(wready_m_inf), .bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf),
	  
    .araddr_m_inf(araddr_m_inf[ADDR_WIDTH-1:0]), .arvalid_m_inf(arvalid_m_inf[0]), .arready_m_inf(arready_m_inf[0]), 
                
    .rdata_m_inf(rdata_m_inf[DATA_WIDTH-1:0]), .rlast_m_inf(rlast_m_inf[0]),
    .rvalid_m_inf(rvalid_m_inf[0]), .rready_m_inf(rready_m_inf[0])
);



endmodule

//========================================================================
//						     ALU_MODULE
//========================================================================

module ALU (
	rs_data,
	rt_data, 
	add_out,
	sub_out,
	multi_out,
	set_less_than_out,
	equal_out
) ;

input  signed [15:0] rs_data ;
input  signed [15:0] rt_data ;
output reg signed [15:0] add_out, sub_out ;
output reg signed [31:0] multi_out ;
output reg set_less_than_out, equal_out ;

always @ (*) begin 
	add_out           = rs_data + rt_data ;
	sub_out           = rs_data - rt_data ;
	multi_out         = rs_data * rt_data ;
	set_less_than_out = (rs_data < rt_data) ;
	equal_out         = (rs_data == rt_data) ;
end

endmodule

//=============================================================================================================================================================================================================================================================================================================
//              																								DATA_DRAM_INTERFACE
//=============================================================================================================================================================================================================================================================================================================

module DATA_BRIDGE (
	clk,
	rst_n,
	in_valid,
	read,
	in_data,
	in_addr,
	sram_not_empty,
	out_valid,
	data_dram_out,
	sram_out,
	data_sram_addr,
	data_sram_r_or_w,
	data_sram_in_data,
	
    awaddr_m_inf,
    awvalid_m_inf,
    awready_m_inf,
				
	wdata_m_inf,
	wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,
				
    bvalid_m_inf,
    bready_m_inf,
   
    araddr_m_inf,
    arvalid_m_inf,			
    arready_m_inf, 
	
	rdata_m_inf,
	rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf
) ;

//========================================================================
//						        PARAMETER
//========================================================================

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=1, WRIT_NUMBER=1 ;
parameter S_IDLE          = 0 ;
parameter S_REQUEST       = 1 ;
parameter S_WAIT          = 2 ;
parameter S_HIT           = 3 ;
parameter S_HIT_TRASH     = 4 ;
parameter S_WRITE_REQUEST = 5 ;
parameter S_WRITE_SEND    = 6 ;
parameter S_WRITE_WAIT    = 7 ;
 
//========================================================================
//						        IN/OUT PORT
//========================================================================
input clk, rst_n, sram_not_empty, in_valid, read ;
input [15:0] in_data ;
input [10:0] in_addr ;
input [15:0] sram_out ;
output     data_sram_r_or_w ;
output     out_valid ;
output     [15:0] data_dram_out ;
output reg [15:0] data_sram_in_data ;
output reg [6:0] data_sram_addr ;


input       [WRIT_NUMBER-1:0]                awready_m_inf ;
output  reg [WRIT_NUMBER-1:0]                awvalid_m_inf ;
output  reg [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf ;

input       [WRIT_NUMBER-1:0]                 wready_m_inf ;
output  reg [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf ;
output  reg [WRIT_NUMBER-1:0]                  wlast_m_inf ;
output  reg [WRIT_NUMBER-1:0]                 wvalid_m_inf ;

input       [WRIT_NUMBER-1:0]             	  bvalid_m_inf ;
output  reg [WRIT_NUMBER-1:0]                 bready_m_inf ;

input       [DRAM_NUMBER-1:0]               arready_m_inf ;
output  reg [DRAM_NUMBER-1:0]               arvalid_m_inf ;
output  reg [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf ;

input       [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf ;
input       [DRAM_NUMBER-1:0]                  rlast_m_inf ;
input       [DRAM_NUMBER-1:0]                 rvalid_m_inf ;
output  reg [DRAM_NUMBER-1:0]                 rready_m_inf ;

//========================================================================
//						       REGISTER/WIRE
//========================================================================


wire start_write ;
wire hit ;
reg hit_to_out ;

//========================================================================
//						       	 READ_FSM
//========================================================================

reg [2:0] curr_state ;
reg [2:0] next_state ;

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state <= S_IDLE ;
	end
	else begin
		curr_state <= next_state ;
	end
end

always @ (*) begin
	case(curr_state)
		S_IDLE : begin 
			if(in_valid && hit && read) next_state = S_HIT_TRASH ;
			else if (in_valid) next_state = (read) ? S_REQUEST : S_WRITE_REQUEST ;
			else next_state = curr_state ;
		end
		S_HIT_TRASH : next_state = S_HIT ;
		S_REQUEST : next_state = (arready_m_inf) ? S_WAIT : curr_state ;
		S_WAIT    : next_state = (rlast_m_inf) ? S_HIT : curr_state ;
		S_HIT     : next_state = (hit_to_out) ? S_IDLE : curr_state ;
		S_WRITE_REQUEST : next_state = S_IDLE ;
		default: next_state = S_IDLE ;
	endcase
end

//========================================================================
//						       	WRITE_SRAM
//========================================================================

reg [2:0] write_curr_state ;
reg [2:0] write_next_state ;

always @ (posedge clk or negedge rst_n) begin 
	if(!rst_n) begin
		write_curr_state <= S_IDLE ;
	end else begin
		write_curr_state <= write_next_state ;
	end
end

always @ (*) begin 
	case (write_curr_state)
		S_IDLE : begin 
			if (start_write) write_next_state = S_WRITE_REQUEST ;
			else write_next_state = S_IDLE ;
		end
		S_WRITE_REQUEST : write_next_state = (awready_m_inf) ? S_WRITE_SEND : write_curr_state ;
		S_WRITE_SEND    : write_next_state = (wready_m_inf)  ? S_WRITE_WAIT : write_curr_state ;
		S_WRITE_WAIT    : write_next_state = (bvalid_m_inf)  ? S_IDLE : write_curr_state ;
		default : write_next_state = S_IDLE ;
	endcase 
end

//========================================================================
//						      DRAM_CONTROL_OUT
//========================================================================

always @ (*) begin 
	if (in_valid || curr_state == S_REQUEST) begin 
		araddr_m_inf = {20'd1 , in_addr[10:7] , 8'd0} ;
	end
	else begin 
		araddr_m_inf = 0 ;
	end
end

always @ (*) begin 
	if (( in_valid && read && ~hit ) || curr_state == S_REQUEST) begin 
		arvalid_m_inf = 1 ;
	end
	else begin 
		arvalid_m_inf = 0 ;
	end
end

always @ (*) begin 
	if (curr_state == S_REQUEST || curr_state == S_WAIT) begin 
		rready_m_inf = 1 ;
	end
	else begin 
		rready_m_inf = 0 ;
	end
end

always @ (*) begin 
	if ((in_valid || write_curr_state == S_WRITE_REQUEST)) begin 
		awaddr_m_inf = {20'd1 , in_addr[10:0], 1'd0}  ;
	end
	else begin 
		awaddr_m_inf = 0 ;
	end
end

always @ (*) begin 
	if ((in_valid && ~read) || write_curr_state == S_WRITE_REQUEST) begin 
		awvalid_m_inf = 1 ;
	end
	else begin 
		awvalid_m_inf = 0 ;
	end
end

always @ (*) begin 
	if (write_curr_state == S_WRITE_SEND || write_curr_state == S_WRITE_WAIT) begin 
		bready_m_inf = 1 ;
	end
	else begin 
		bready_m_inf = 0 ;
	end
end

always @ (*) begin 
	if (write_curr_state == S_WRITE_SEND) begin 
		wlast_m_inf = 1 ;
	end
	else begin 
		wlast_m_inf = 0 ;
	end
end

always @ (*) begin 
	if (write_curr_state == S_WRITE_SEND) begin 
		wvalid_m_inf = 1 ;
	end
	else begin 
		wvalid_m_inf = 0 ;
	end
end

always @ (*) begin 
	if (wvalid_m_inf) begin 
		wdata_m_inf = in_data ;
	end
	else begin 
		wdata_m_inf = 0 ;
	end
end

//========================================================================
//						 JUDGE_CACHE_HIT_OR_NOT
//========================================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) hit_to_out <= 0 ;
	else begin 
		if (curr_state == S_HIT) hit_to_out <= 1 ;
		else if (curr_state == S_WAIT && rlast_m_inf) hit_to_out <= 1 ;
		else hit_to_out <= 0 ;
	end
end

//========================================================================
//						    STORE_SRAM_ADDR
//========================================================================

reg [6:0] store_sram_addr ;

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		store_sram_addr <= 0;
	end 
	else begin 
		store_sram_addr <= (rvalid_m_inf) ? store_sram_addr + 1 : store_sram_addr ;
	end
end

//========================================================================
//						        PRE_ADDR
//========================================================================

reg [3:0] pre_addr ;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		pre_addr <= 0;
	end 
	else begin 
		pre_addr <= (in_valid && read) ? in_addr[10:7] : pre_addr ;
	end
end

//========================================================================
//						      OUT_DATA_REG
//========================================================================

reg [15:0] out_data_reg ;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_data_reg <= 0;
	end 
	else begin 
		if ((rvalid_m_inf && in_addr[6:0] == data_sram_addr) || (curr_state == S_HIT && !hit_to_out)) begin 
			out_data_reg <= (rvalid_m_inf && in_addr[6:0] == data_sram_addr) ? rdata_m_inf : sram_out ;
		end
		else begin 
			out_data_reg <= out_data_reg ;
		end
	end
end

//========================================================================
//						      START_WRITE
//========================================================================

assign start_write = (curr_state == S_WRITE_REQUEST) ? 1 : 0 ;


//========================================================================
//						      TOP_CPU_OUT
//========================================================================

assign out_valid = hit_to_out || bvalid_m_inf ;
assign hit = sram_not_empty && (pre_addr == in_addr[10:7]) ;
assign data_sram_r_or_w = (curr_state == S_WAIT || (write_curr_state == S_WRITE_REQUEST && hit)) ? 0 : 1 ;
assign data_sram_in_data    = (curr_state == S_WAIT) ? rdata_m_inf : in_data ;
assign data_sram_addr       = (curr_state == S_WAIT) ? store_sram_addr : in_addr ;
assign data_dram_out = out_data_reg ;


endmodule

//=============================================================================================================================================================================================================================================================================================================
//              																								INST_DRAM_INTERFACE
//=============================================================================================================================================================================================================================================================================================================

module INST_BRIDGE(
	clk,
	rst_n,
	in_valid,
	in_addr,
	sram_not_empty,
	out_valid,
	inst_dram_out,
    sram_out,
    inst_sram_r_or_w,
    inst_sram_addr, 
	
    araddr_m_inf,
    arvalid_m_inf,
				
    arready_m_inf, 
	rdata_m_inf,
	rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf  
);

//========================================================================
//						        PARAMETER
//========================================================================
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=1 ;
parameter S_IDLE        = 2'b00 ; 
parameter S_SEND_REQ    = 2'b01 ;
parameter S_WAIT_DATA   = 2'b10 ;
parameter S_CACHE_HIT   = 2'b11 ;


//========================================================================
//						        IN/OUT PORT
//========================================================================
input clk ;
input rst_n ;
input sram_not_empty ;
input in_valid ;
input [10:0] in_addr ;
input  [15:0] sram_out ;
output reg [6:0] inst_sram_addr ;
output reg inst_sram_r_or_w ;
output reg out_valid ;
output reg [15:0] inst_dram_out ;

output reg [DRAM_NUMBER * ADDR_WIDTH-1:0]    araddr_m_inf ;
output reg [DRAM_NUMBER-1:0]                arvalid_m_inf ;
input       [DRAM_NUMBER-1:0]               arready_m_inf ;

input       [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf ;
input       [DRAM_NUMBER-1:0]                  rlast_m_inf ;
input       [DRAM_NUMBER-1:0]                 rvalid_m_inf ;
output reg [DRAM_NUMBER-1:0]                  rready_m_inf ;

//========================================================================
//						       REGISTER/WIRE
//========================================================================

reg hit_to_out ;
wire hit ;

//========================================================================
//						       	   FSM
//========================================================================

reg [1:0]  curr_state ;
reg [1:0]  next_state ;

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state <= S_IDLE ;
	end
	else begin
		curr_state <= next_state ;
	end
end

always @ (*) begin
	case(curr_state)
		S_IDLE :
			if (in_valid) next_state = (hit == 1) ? S_CACHE_HIT : S_SEND_REQ ;
			else next_state = S_IDLE ;
		S_SEND_REQ : next_state  = (arready_m_inf) ? S_WAIT_DATA : curr_state ;
		S_WAIT_DATA : next_state = (rlast_m_inf) ? S_CACHE_HIT : curr_state ;
		S_CACHE_HIT : next_state = (hit_to_out) ? S_IDLE : curr_state ; 
		default : next_state = S_IDLE ;
	endcase
end

//========================================================================
//						      DRAM_CONTROL_OUT
//========================================================================


always @ (*) begin 
	if (in_valid || curr_state == S_SEND_REQ) begin 
		araddr_m_inf = {20'd1 , in_addr[10:7] , 8'd0} ;
	end
	else begin 
		araddr_m_inf = 0 ;
	end
end

always @ (*) begin 
	if (( in_valid && ~hit ) || curr_state == S_SEND_REQ) begin 
		arvalid_m_inf = 1 ;
	end
	else begin 
		arvalid_m_inf = 0 ;
	end
end

always @ (*) begin 
	if (curr_state == S_SEND_REQ || curr_state == S_WAIT_DATA) begin 
		rready_m_inf = 1 ;
	end
	else begin 
		rready_m_inf = 0 ;
	end	
end

//========================================================================
//						 JUDGE_CACHE_HIT_OR_NOT
//========================================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) hit_to_out <= 0 ;
	else begin 
		if (curr_state == S_CACHE_HIT) hit_to_out <= 1 ;
		else if (curr_state == S_WAIT_DATA && rlast_m_inf) hit_to_out <= 1 ;
		else hit_to_out <= 0 ;
	end
end


//========================================================================
//						    STORE_SRAM_ADDR
//========================================================================

reg [6:0]  store_sram_addr ;

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		store_sram_addr <= 0;
	end 
	else begin 
		store_sram_addr <= (rvalid_m_inf) ? store_sram_addr + 1 : store_sram_addr ;
	end
end

//========================================================================
//						      OUT_DATA_REG
//========================================================================

reg [15:0] out_data_reg ;

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_data_reg <= 0;
	end 
	else begin
		if ((rvalid_m_inf && in_addr[6:0] == inst_sram_addr) || (curr_state == S_CACHE_HIT && hit_to_out != 1)) begin 
			out_data_reg <= (rvalid_m_inf && in_addr[6:0] == inst_sram_addr) ? rdata_m_inf : sram_out ;
		end
		else begin 
			out_data_reg <= out_data_reg ;
		end
	end
end

//========================================================================
//						        PRE_ADDR
//========================================================================

reg [3:0]  pre_addr ;

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		pre_addr <= 0;
	end 
	else begin 
		pre_addr <= (in_valid) ? in_addr[10:7] : pre_addr ;
	end
end

//========================================================================
//						      TOP_CPU_OUT
//========================================================================

assign inst_sram_r_or_w = (curr_state == S_WAIT_DATA) ? 0 : 1 ;
assign inst_sram_addr = (curr_state == S_WAIT_DATA) ? store_sram_addr : in_addr ;
assign hit = sram_not_empty && (pre_addr == in_addr[10:7]) ;
assign inst_dram_out = out_data_reg ;

always @ (*) begin 
	if (hit_to_out) out_valid = 1 ;
	else out_valid = 0 ;
end

endmodule
