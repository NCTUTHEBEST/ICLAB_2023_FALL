//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
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
	   rready_m_inf,
	
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
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ===============================================================
//  					  Parameter
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32 ;
parameter S_IDLE = 3'b000, S_INPUT_MAP = 3'b001, S_INPUT_WEI = 3'b010 ;
parameter S_SET_TERMINAL_AND_RESET = 3'b011, S_BFS_START  = 3'b100 ;
parameter S_TRACE_BACK = 3'b101, S_WRITE_SRAM = 3'b110, S_WRITE_BACK = 3'b111 ;


// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

// ===============================================================
//  				  fixed
// ===============================================================
assign arid_m_inf    = 4'b0000 ; 
assign arsize_m_inf  = 3'b100 ;
assign arburst_m_inf = 2'b01 ;

assign awid_m_inf = 0 ;
assign awburst_m_inf = 2'b01 ;
assign awsize_m_inf = 3'b100 ;

// ===============================================================
//  				  wire / reg
// ===============================================================

// for input store
reg [4:0] which_frame ;
reg [3:0] macro_name [0:14] ;
reg [3:0] macro_count ;
reg [5:0] begin_row  [0:14] ;
reg [5:0] begin_col  [0:14] ;
reg [5:0] end_row [0:14] ;
reg [5:0] end_col [0:14] ;
reg take_name_flag ;

// store map & weight
reg [1:0] map_use_to_wave [0:63][0:63] ;
reg [6:0] dram_count ;

// for BFS
reg [3:0] which_macro ;
reg [1:0] propagate_value ;
reg [1:0] propagate_count ;

// for trace back
reg  [5:0] trace_back_row ;
reg  [5:0] trace_back_col ;
wire [6:0] trace_back_up, trace_back_down, trace_back_left, trace_back_right ;
// wire cost_acc_flag ; 
reg  wait_write ;

// for map sram 
reg  [6:0] map_addr ;
reg  [127:0] map_in ;
wire [127:0] map_out ;
reg  map_write_en, map_chip_en ; 

// for weight sram
reg  [6:0] addr ;
wire [127:0] d_in, d_out ;
reg  write_en, chip_en ;

// ===============================================================
//  					FSM
// ===============================================================

reg [2:0] curr_state, next_state ;

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) curr_state <= S_IDLE ;
	else curr_state <= next_state ;
end

always @ (*) begin 
	case (curr_state)
		S_IDLE : begin 
			if (in_valid) next_state = S_INPUT_MAP ;
			else next_state = S_IDLE ;
		end
		S_INPUT_MAP : begin 
			if (rlast_m_inf) next_state = S_INPUT_WEI ;
			else next_state = S_INPUT_MAP ;
		end
		S_INPUT_WEI : begin 
			if (rlast_m_inf) next_state = S_SET_TERMINAL_AND_RESET ;
			else next_state = S_INPUT_WEI ;
		end
		S_SET_TERMINAL_AND_RESET : begin 
			if (which_macro == macro_count) next_state = S_WRITE_BACK ;
			else next_state = S_BFS_START ;
		end
		S_BFS_START : begin 
			if (map_use_to_wave[end_row[which_macro]][end_col[which_macro]][1] == 1) next_state = S_TRACE_BACK ;
			else next_state = S_BFS_START ;
		end
		S_TRACE_BACK : begin
			next_state = S_WRITE_SRAM ;
		end
		S_WRITE_SRAM : begin
			if (map_use_to_wave[begin_row[which_macro]][begin_col[which_macro]][1] != 1) next_state = S_SET_TERMINAL_AND_RESET ;		
			else next_state = S_TRACE_BACK ;
		end
		S_WRITE_BACK : begin 
			if (bvalid_m_inf) next_state = S_IDLE ;
			else next_state = S_WRITE_BACK ;
		end
		default : next_state = S_IDLE ;
	endcase
end

// ==============================================================================================================================================================================================================================
//  				   																					INPUT_REG
// ==============================================================================================================================================================================================================================

// ===============================================================
//  				  which_frame
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) which_frame <= 0 ;
	else begin 
		if (in_valid) which_frame <= frame_id ;
		else which_frame <= which_frame ;
	end
end

// ===============================================================
//  				  take_name_flag
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		take_name_flag <= 1 ;
	end
	else begin 
		if (in_valid) take_name_flag <= ~take_name_flag ;
		else take_name_flag <= 1 ;
	end
end

// ===============================================================
//  				   macro_count
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		macro_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) macro_count <= 0 ;
		else if (in_valid && (~take_name_flag)) macro_count <= macro_count + 1 ;
		else macro_count <= macro_count ;
	end
end

// ===============================================================
//  				  	macro name
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 15 ; i = i + 1) begin 
			macro_name[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid && take_name_flag) macro_name[macro_count] <= net_id ;
		else begin 
			for (int i = 0 ; i < 15 ; i = i + 1) begin 
				macro_name[i] <= macro_name[i] ;
			end
		end
	end
end

// ===============================================================
//  				   begin_row / begin_col
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 15 ; i = i + 1) begin 
			begin_row[i] <= 0 ;
			begin_col[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid && take_name_flag) begin 
			begin_row[macro_count] <= loc_y ;
			begin_col[macro_count] <= loc_x ;
		end
		else begin 
			for (int i = 0 ; i < 15 ; i = i + 1) begin 
				begin_row[i] <= begin_row[i] ;
				begin_col[i] <= begin_col[i] ;
			end
		end
	end
end

// ===============================================================
//  				    end_row / end_col
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 15 ; i = i + 1) begin 
			end_row[i] <= 0 ;
			end_col[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid && (~take_name_flag)) begin 
			end_row[macro_count] <= loc_y ;
			end_col[macro_count] <= loc_x ;
		end
		else begin 
			for (int i = 0 ; i < 15 ; i = i + 1) begin 
				end_row[i] <= end_row[i] ;
				end_col[i] <= end_col[i] ;
			end
		end
	end
end

// ==============================================================================================================================================================================================================================
//  				   																			map_store & BFS_operation
// ==============================================================================================================================================================================================================================

// ===============================================================
//  				    dram count
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) dram_count <= 0 ;
	else begin 
		if (rvalid_m_inf || wready_m_inf) dram_count <= dram_count + 1 ;
		else dram_count <= 0 ;
	end
end

// ===============================================================
//  				    	which_macro
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) which_macro <= 0 ;
	else begin
		if (curr_state == S_IDLE) which_macro <= 0 ;
		else if (curr_state == S_WRITE_SRAM && (map_use_to_wave[begin_row[which_macro]][begin_col[which_macro]][1] != 1)) which_macro <= which_macro + 1 ;
		else which_macro <= which_macro ;
	end
end

// ===============================================================
//  				      propagate_count
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) propagate_count <= 0 ;
	else begin
		if (curr_state == S_IDLE) propagate_count <= 0 ;
		else if (curr_state == S_WRITE_SRAM && next_state == S_SET_TERMINAL_AND_RESET) propagate_count <= 0 ;
		else if (curr_state == S_SET_TERMINAL_AND_RESET || (curr_state == S_BFS_START && next_state == S_BFS_START)) propagate_count <= propagate_count + 1 ;
		else if (curr_state == S_BFS_START && next_state == S_TRACE_BACK) propagate_count <= propagate_count - 2 ;
		else if (curr_state == S_TRACE_BACK) propagate_count <= propagate_count - 1 ;
		else propagate_count <= propagate_count ;
	end
end

// ===============================================================
//  				    map_use_to_wave[1:0]
// ===============================================================
always @ (posedge clk) begin 
	// if (!rst_n) begin 
		// for (int row = 0 ; row < 64 ; row = row + 1) begin 
			// for (int col = 0 ; col < 64 ; col = col + 1) begin 
				// map_use_to_wave[row][col] <= 0 ;
			// end
		// end
	// end
	// else begin 
		if (curr_state == S_INPUT_MAP) begin 
			for (int i = 0 ; i < 32 ; i = i + 1) begin 
				map_use_to_wave[dram_count/2][(dram_count%2)*32+i] <= {1'b0, (|rdata_m_inf[i*4+:4])} ; // 0: road / 1: obstacle / 2&3: wave propagation
			end
		end
		else if (curr_state == S_SET_TERMINAL_AND_RESET) begin 
			map_use_to_wave[begin_row[which_macro]][begin_col[which_macro]] <= 2 ; // from begin start to propagate
			map_use_to_wave[end_row  [which_macro]][end_col  [which_macro]] <= 0 ; // propagate to end and stop
			for (int row = 0 ; row < 64 ; row = row + 1) begin 
				for (int col = 0 ; col < 64 ; col = col + 1) begin 
					if (map_use_to_wave[row][col][1]) begin 
						map_use_to_wave[row][col] <= 0 ;                           // other grid, except macro reset to 0 (road)
					end
				end
			end
		end
		else if (curr_state == S_BFS_START && next_state == S_BFS_START) begin
			// middle of map
			for (int row = 1 ; row < 63 ; row = row + 1) begin  
				for (int col = 1 ; col < 63 ; col = col + 1) begin 
					if (map_use_to_wave[row][col] == 0 && (map_use_to_wave[row-1][col][1] | map_use_to_wave[row+1][col][1] | map_use_to_wave[row][col-1][1] | map_use_to_wave[row][col+1][1])) begin 
						map_use_to_wave[row][col] <= {1'b1, propagate_count[1]} ;
					end
				end
			end
			// boundary of map
			for (int row = 1 ; row < 63 ; row = row + 1) begin 
				if (map_use_to_wave[row][0]  == 0 && (map_use_to_wave[row+1][0][1]  | map_use_to_wave[row-1][0][1]  | map_use_to_wave[row][1][1]))  map_use_to_wave[row][0]  <= {1'b1, propagate_count[1]} ;
				if (map_use_to_wave[row][63] == 0 && (map_use_to_wave[row+1][63][1] | map_use_to_wave[row-1][63][1] | map_use_to_wave[row][62][1])) map_use_to_wave[row][63] <= {1'b1, propagate_count[1]} ;
			end
			for (int col = 1 ; col < 63 ; col = col + 1) begin 
				if (map_use_to_wave[0][col]  == 0 && (map_use_to_wave[0][col+1][1]  | map_use_to_wave[0][col-1][1]  | map_use_to_wave[1][col][1]))  map_use_to_wave[0][col]  <= {1'b1, propagate_count[1]} ;
				if (map_use_to_wave[63][col] == 0 && (map_use_to_wave[63][col+1][1] | map_use_to_wave[63][col-1][1] | map_use_to_wave[62][col][1])) map_use_to_wave[63][col] <= {1'b1, propagate_count[1]} ;
			end
			// corner of map
			if (map_use_to_wave[0][0] == 0 && (map_use_to_wave[0][1][1] | map_use_to_wave[1][0][1])) map_use_to_wave[0][0] <= {1'b1, propagate_count[1]} ;
			if (map_use_to_wave[63][63] == 0 && (map_use_to_wave[63][62][1] | map_use_to_wave[62][63][1])) map_use_to_wave[63][63] <= {1'b1, propagate_count[1]} ;
			if (map_use_to_wave[0][63]  == 0 && (map_use_to_wave[1][63][1]  | map_use_to_wave[0][62][1]))  map_use_to_wave[0][63]  <= {1'b1, propagate_count[1]} ;
			if (map_use_to_wave[63][0]  == 0 && (map_use_to_wave[63][1][1]  | map_use_to_wave[62][0][1]))  map_use_to_wave[63][0]  <= {1'b1, propagate_count[1]} ;
		end
		else if (curr_state == S_TRACE_BACK) begin 
			map_use_to_wave[trace_back_row][trace_back_col] <= 1 ;  // set the already routed road to obstacle 
		end
		else begin 
			for (int row = 0 ; row < 64 ; row = row + 1) begin 
				for (int col = 0 ; col < 64 ; col = col + 1) begin 
					map_use_to_wave[row][col] <= map_use_to_wave[row][col] ;
				end
			end
		end
	// end
end

// ==============================================================================================================================================================================================================================
//  				   																				  RETRACE
// ==============================================================================================================================================================================================================================

assign trace_back_up    = trace_back_row - 1 ;
assign trace_back_down  = trace_back_row + 1 ;
assign trace_back_left  = trace_back_col - 1 ;
assign trace_back_right = trace_back_col + 1 ;

// ===============================================================
//  				  trace_back_row/col
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		trace_back_row <= 0 ;
		trace_back_col <= 0 ;
	end
	else begin 
		if (curr_state == S_BFS_START) begin 
			trace_back_row <= end_row[which_macro] ;
			trace_back_col <= end_col[which_macro] ;
		end
		else if (curr_state == S_TRACE_BACK) begin 
			if ((~trace_back_down[6]) && (map_use_to_wave[trace_back_down][trace_back_col] == {1'b1, propagate_count[1]})) begin 
				trace_back_row <= trace_back_down ;
				trace_back_col <= trace_back_col ;
			end
			else if ((~trace_back_up[6]) && (map_use_to_wave[trace_back_up][trace_back_col] == {1'b1, propagate_count[1]})) begin 
				trace_back_row <= trace_back_up ;
				trace_back_col <= trace_back_col ;
			end
			else if ((~trace_back_right[6]) && (map_use_to_wave[trace_back_row][trace_back_right] == {1'b1, propagate_count[1]})) begin 
				trace_back_row <= trace_back_row ;
				trace_back_col <= trace_back_right ;
			end
			else begin 
				trace_back_row <= trace_back_row ;
				trace_back_col <= trace_back_left ;
			end
		end
		else begin 
			trace_back_row <= trace_back_row ;
			trace_back_col <= trace_back_col ;
		end
	end
end

// ===============================================================
//  				    cost_acc_flag
// ===============================================================
// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) cost_acc_flag <= 0 ;
	// else begin 
		// if ((trace_back_col != end_col[which_macro] || trace_back_row != end_row[which_macro]) && (trace_back_row != begin_row[which_macro] || trace_back_col != begin_col[which_macro])) begin 
			// cost_acc_flag <= 1 ;
		// end
		// else cost_acc_flag <= 0 ;
	// end
// end

// ==============================================================================================================================================================================================================================
//  				   																				 OUTPUT_REG
// ==============================================================================================================================================================================================================================

// ===============================================================
//  				       busy
// ===============================================================
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) busy <= 0 ;
	else if (next_state == S_IDLE || in_valid) busy <= 0 ;
	else busy <= 1 ;
end

// ===============================================================
//  				       Cost
// ===============================================================
always @ (posedge clk or negedge rst_n) begin  
	if (!rst_n) cost <= 0 ;
	else begin 
		if (curr_state == S_IDLE) cost <= 0 ;
		else if (curr_state == S_TRACE_BACK) begin 
			if ((trace_back_col != end_col[which_macro] || trace_back_row != end_row[which_macro]) && (trace_back_row != begin_row[which_macro] || trace_back_col != begin_col[which_macro])) begin 
				cost <= cost + d_out[{trace_back_col[4:0], 2'b11} -: 4] ;
			end
			else cost <= cost ;
		end
	end
end

// ==============================================================================================================================================================================================================================
//  				   																			SRAM control signal
// ==============================================================================================================================================================================================================================

// ===============================================================
//  				        map sram
// ===============================================================
always@(*) begin
	if (curr_state == S_INPUT_MAP && rvalid_m_inf) map_write_en = 0 ; 
	else if (curr_state == S_TRACE_BACK) map_write_en = ~((trace_back_col != end_col[which_macro] || trace_back_row != end_row[which_macro]) && (trace_back_row != begin_row[which_macro] || trace_back_col != begin_col[which_macro])) ; 
	else map_write_en = 1 ;
end

always@(*) begin
	if (curr_state == S_INPUT_MAP) map_addr = dram_count ;
	else if (curr_state == S_WRITE_SRAM || curr_state == S_TRACE_BACK) map_addr = {trace_back_row, trace_back_col[5]} ;
	else if (curr_state == S_WRITE_BACK) begin 
		if (wready_m_inf) map_addr = dram_count + 'd1 ;
		else map_addr = 'd0 ;
	end
	else map_addr = dram_count ;
end

always@(*) begin
	if (curr_state == S_INPUT_MAP) map_in = rdata_m_inf ;
	else if (curr_state == S_TRACE_BACK || curr_state == S_WRITE_SRAM) begin 
		map_in = map_out ;
		map_in[{trace_back_col[4:0], 2'b11} -: 4] = macro_name[which_macro] ;
	end
	else map_in = 0 ;
end

// ===============================================================
//  				       weight sram
// ===============================================================
// always @ (*) begin 
	// if ((curr_state == S_INPUT_WEI) && rvalid_m_inf) addr = dram_count ;
	// else if (curr_state == S_TRACE_BACK || curr_state == S_WRITE_SRAM) addr = {trace_back_row, trace_back_col[5]} ;
	// else addr = 0 ;
// end
always @ (*) begin 
	if ((curr_state == S_INPUT_WEI) && rvalid_m_inf) chip_en = 1 ;
	else if (curr_state == S_TRACE_BACK || curr_state == S_WRITE_SRAM) chip_en = 1 ;
	else chip_en = 0 ;
end
always @ (*) begin 
	if ((curr_state == S_INPUT_WEI) && rvalid_m_inf) write_en = 0 ;
	else write_en = 1 ;
end
assign d_in = (curr_state == S_INPUT_WEI) ? rdata_m_inf : 0 ;

// ==============================================================================================================================================================================================================================
//  				   																					SRAM
// ==============================================================================================================================================================================================================================

map_weight128X128  map  (.A0(map_addr[0])    ,.A1(map_addr[1])    ,.A2(map_addr[2])    ,.A3(map_addr[3])    ,.A4(map_addr[4])    ,.A5(map_addr[5])    ,.A6(map_addr[6]),
						 .DO0  (map_out[0])   ,.DO1  (map_out[1])   ,.DO2  (map_out[2])   ,.DO3  (map_out[3])   ,.DO4  (map_out[4])   ,.DO5  (map_out[5])   ,.DO6  (map_out[6])   ,.DO7  (map_out[7])   ,.DO8  (map_out[8])   ,.DO9 (map_out[9]),
						 .DO10 (map_out[10])  ,.DO11 (map_out[11])  ,.DO12 (map_out[12])  ,.DO13 (map_out[13])  ,.DO14 (map_out[14])  ,.DO15 (map_out[15])  ,.DO16 (map_out[16])  ,.DO17 (map_out[17])  ,.DO18 (map_out[18])  ,.DO19(map_out[19]),
						 .DO20 (map_out[20])  ,.DO21 (map_out[21])  ,.DO22 (map_out[22])  ,.DO23 (map_out[23])  ,.DO24 (map_out[24])  ,.DO25 (map_out[25])  ,.DO26 (map_out[26])  ,.DO27 (map_out[27])  ,.DO28 (map_out[28])  ,.DO29(map_out[29]),
						 .DO30 (map_out[30])  ,.DO31 (map_out[31])  ,.DO32 (map_out[32])  ,.DO33 (map_out[33])  ,.DO34 (map_out[34])  ,.DO35 (map_out[35])  ,.DO36 (map_out[36])  ,.DO37 (map_out[37])  ,.DO38 (map_out[38])  ,.DO39(map_out[39]),
						 .DO40 (map_out[40])  ,.DO41 (map_out[41])  ,.DO42 (map_out[42])  ,.DO43 (map_out[43])  ,.DO44 (map_out[44])  ,.DO45 (map_out[45])  ,.DO46 (map_out[46])  ,.DO47 (map_out[47])  ,.DO48 (map_out[48])  ,.DO49(map_out[49]),
						 .DO50 (map_out[50])  ,.DO51 (map_out[51])  ,.DO52 (map_out[52])  ,.DO53 (map_out[53])  ,.DO54 (map_out[54])  ,.DO55 (map_out[55])  ,.DO56 (map_out[56])  ,.DO57 (map_out[57])  ,.DO58 (map_out[58])  ,.DO59(map_out[59]),
						 .DO60 (map_out[60])  ,.DO61 (map_out[61])  ,.DO62 (map_out[62])  ,.DO63 (map_out[63])  ,.DO64 (map_out[64])  ,.DO65 (map_out[65])  ,.DO66 (map_out[66])  ,.DO67 (map_out[67])  ,.DO68 (map_out[68])  ,.DO69(map_out[69]),
						 .DO70 (map_out[70])  ,.DO71 (map_out[71])  ,.DO72 (map_out[72])  ,.DO73 (map_out[73])  ,.DO74 (map_out[74])  ,.DO75 (map_out[75])  ,.DO76 (map_out[76])  ,.DO77 (map_out[77])  ,.DO78 (map_out[78])  ,.DO79(map_out[79]),
                         .DO80 (map_out[80])  ,.DO81 (map_out[81])  ,.DO82 (map_out[82])  ,.DO83 (map_out[83])  ,.DO84 (map_out[84])  ,.DO85 (map_out[85])  ,.DO86 (map_out[86])  ,.DO87 (map_out[87])  ,.DO88 (map_out[88])  ,.DO89(map_out[89]),
						 .DO90 (map_out[90])  ,.DO91 (map_out[91])  ,.DO92 (map_out[92])  ,.DO93 (map_out[93])  ,.DO94 (map_out[94])  ,.DO95 (map_out[95])  ,.DO96 (map_out[96])  ,.DO97 (map_out[97])  ,.DO98 (map_out[98])  ,.DO99(map_out[99]),
						 .DO100(map_out[100]) ,.DO101(map_out[101]) ,.DO102(map_out[102]) ,.DO103(map_out[103]) ,.DO104(map_out[104]) ,.DO105(map_out[105]) ,.DO106(map_out[106]) ,.DO107(map_out[107]) ,.DO108(map_out[108]) ,.DO109(map_out[109]),
						 .DO110(map_out[110]) ,.DO111(map_out[111]) ,.DO112(map_out[112]) ,.DO113(map_out[113]) ,.DO114(map_out[114]) ,.DO115(map_out[115]) ,.DO116(map_out[116]) ,.DO117(map_out[117]) ,.DO118(map_out[118]) ,.DO119(map_out[119]),
						 .DO120(map_out[120]) ,.DO121(map_out[121]) ,.DO122(map_out[122]) ,.DO123(map_out[123]) ,.DO124(map_out[124]) ,.DO125(map_out[125]) ,.DO126(map_out[126]) ,.DO127(map_out[127]) ,
						 .DI0  (map_in[0])    ,.DI1  (map_in[1])    ,.DI2  (map_in[2])    ,.DI3  (map_in[3])    ,.DI4  (map_in[4])    ,.DI5  (map_in[5])    ,.DI6  (map_in[6])    ,.DI7  (map_in[7])    ,.DI8 (map_in[8])    ,.DI9(map_in[9]),
						 .DI10 (map_in[10])   ,.DI11 (map_in[11])   ,.DI12 (map_in[12])   ,.DI13 (map_in[13])   ,.DI14 (map_in[14])   ,.DI15 (map_in[15])   ,.DI16 (map_in[16])   ,.DI17 (map_in[17])   ,.DI18(map_in[18])  ,.DI19(map_in[19]),
						 .DI20 (map_in[20])   ,.DI21 (map_in[21])   ,.DI22 (map_in[22])   ,.DI23 (map_in[23])   ,.DI24 (map_in[24])   ,.DI25 (map_in[25])   ,.DI26 (map_in[26])   ,.DI27 (map_in[27])   ,.DI28(map_in[28])  ,.DI29(map_in[29]),
						 .DI30 (map_in[30])   ,.DI31 (map_in[31])   ,.DI32 (map_in[32])   ,.DI33 (map_in[33])   ,.DI34 (map_in[34])   ,.DI35 (map_in[35])   ,.DI36 (map_in[36])   ,.DI37 (map_in[37])   ,.DI38(map_in[38])  ,.DI39(map_in[39]),
						 .DI40 (map_in[40])   ,.DI41 (map_in[41])   ,.DI42 (map_in[42])   ,.DI43 (map_in[43])   ,.DI44 (map_in[44])   ,.DI45 (map_in[45])   ,.DI46 (map_in[46])   ,.DI47 (map_in[47])   ,.DI48(map_in[48])  ,.DI49(map_in[49]),
						 .DI50 (map_in[50])   ,.DI51 (map_in[51])   ,.DI52 (map_in[52])   ,.DI53 (map_in[53])   ,.DI54 (map_in[54])   ,.DI55 (map_in[55])   ,.DI56 (map_in[56])   ,.DI57 (map_in[57])   ,.DI58(map_in[58])  ,.DI59(map_in[59]),
						 .DI60 (map_in[60])   ,.DI61 (map_in[61])   ,.DI62 (map_in[62])   ,.DI63 (map_in[63])   ,.DI64 (map_in[64])   ,.DI65 (map_in[65])   ,.DI66 (map_in[66])   ,.DI67 (map_in[67])   ,.DI68(map_in[68])  ,.DI69(map_in[69]),
						 .DI70 (map_in[70])   ,.DI71 (map_in[71])   ,.DI72 (map_in[72])   ,.DI73 (map_in[73])   ,.DI74 (map_in[74])   ,.DI75 (map_in[75])   ,.DI76 (map_in[76])   ,.DI77 (map_in[77])   ,.DI78(map_in[78])  ,.DI79(map_in[79]),
						 .DI80 (map_in[80])   ,.DI81 (map_in[81])   ,.DI82 (map_in[82])   ,.DI83 (map_in[83])   ,.DI84 (map_in[84])   ,.DI85 (map_in[85])   ,.DI86 (map_in[86])   ,.DI87 (map_in[87])   ,.DI88(map_in[88])  ,.DI89(map_in[89]),
						 .DI90 (map_in[90])   ,.DI91 (map_in[91])   ,.DI92 (map_in[92])   ,.DI93 (map_in[93])   ,.DI94 (map_in[94])   ,.DI95 (map_in[95])   ,.DI96 (map_in[96])   ,.DI97 (map_in[97])   ,.DI98(map_in[98])  ,.DI99(map_in[99]),
						 .DI100(map_in[100])  ,.DI101(map_in[101])  ,.DI102(map_in[102])  ,.DI103(map_in[103])  ,.DI104(map_in[104])  ,.DI105(map_in[105])  ,.DI106(map_in[106])  ,.DI107(map_in[107])  ,.DI108(map_in[108]) ,.DI109(map_in[109]),
                         .DI110(map_in[110])  ,.DI111(map_in[111])  ,.DI112(map_in[112])  ,.DI113(map_in[113])  ,.DI114(map_in[114])  ,.DI115(map_in[115])  ,.DI116(map_in[116])  ,.DI117(map_in[117])  ,.DI118(map_in[118]) ,.DI119(map_in[119]),
						 .DI120(map_in[120])  ,.DI121(map_in[121])  ,.DI122(map_in[122])  ,.DI123(map_in[123])  ,.DI124(map_in[124])  ,.DI125(map_in[125])  ,.DI126(map_in[126])  ,.DI127(map_in[127])  ,
						 .CK(clk)    ,.WEB(map_write_en)   ,.OE(1'b1)    ,.CS(1'b1));

map_weight128X128 wei   (.A0(map_addr[0])    ,.A1(map_addr[1])    ,.A2(map_addr[2])    ,.A3(map_addr[3])    ,.A4(map_addr[4])    ,.A5(map_addr[5])    ,.A6(map_addr[6]),
						 .DO0  (d_out[0])   ,.DO1 (d_out[1])   ,.DO2 (d_out[2])   ,.DO3 (d_out[3])   ,.DO4 (d_out[4])   ,.DO5 (d_out[5])   ,.DO6 (d_out[6])   ,.DO7 (d_out[7])   ,.DO8 (d_out[8])   ,.DO9 (d_out[9]),
						 .DO10 (d_out[10])  ,.DO11(d_out[11])  ,.DO12(d_out[12])  ,.DO13(d_out[13])  ,.DO14(d_out[14])  ,.DO15(d_out[15])  ,.DO16(d_out[16])  ,.DO17(d_out[17])  ,.DO18(d_out[18])  ,.DO19(d_out[19]),
						 .DO20 (d_out[20])  ,.DO21(d_out[21])  ,.DO22(d_out[22])  ,.DO23(d_out[23])  ,.DO24(d_out[24])  ,.DO25(d_out[25])  ,.DO26(d_out[26])  ,.DO27(d_out[27])  ,.DO28(d_out[28])  ,.DO29(d_out[29]),
						 .DO30 (d_out[30])  ,.DO31(d_out[31])  ,.DO32(d_out[32])  ,.DO33(d_out[33])  ,.DO34(d_out[34])  ,.DO35(d_out[35])  ,.DO36(d_out[36])  ,.DO37(d_out[37])  ,.DO38(d_out[38])  ,.DO39(d_out[39]),
						 .DO40 (d_out[40])  ,.DO41(d_out[41])  ,.DO42(d_out[42])  ,.DO43(d_out[43])  ,.DO44(d_out[44])  ,.DO45(d_out[45])  ,.DO46(d_out[46])  ,.DO47(d_out[47])  ,.DO48(d_out[48])  ,.DO49(d_out[49]),
						 .DO50 (d_out[50])  ,.DO51(d_out[51])  ,.DO52(d_out[52])  ,.DO53(d_out[53])  ,.DO54(d_out[54])  ,.DO55(d_out[55])  ,.DO56(d_out[56])  ,.DO57(d_out[57])  ,.DO58(d_out[58])  ,.DO59(d_out[59]),
						 .DO60 (d_out[60])  ,.DO61(d_out[61])  ,.DO62(d_out[62])  ,.DO63(d_out[63])  ,.DO64(d_out[64])  ,.DO65(d_out[65])  ,.DO66(d_out[66])  ,.DO67(d_out[67])  ,.DO68(d_out[68])  ,.DO69(d_out[69]),
						 .DO70 (d_out[70])  ,.DO71(d_out[71])  ,.DO72(d_out[72])  ,.DO73(d_out[73])  ,.DO74(d_out[74])  ,.DO75(d_out[75])  ,.DO76(d_out[76])  ,.DO77(d_out[77])  ,.DO78(d_out[78])  ,.DO79(d_out[79]),
                         .DO80 (d_out[80])  ,.DO81(d_out[81])  ,.DO82(d_out[82])  ,.DO83(d_out[83])  ,.DO84(d_out[84])  ,.DO85(d_out[85])  ,.DO86(d_out[86])  ,.DO87(d_out[87])  ,.DO88(d_out[88])  ,.DO89(d_out[89]),
						 .DO90 (d_out[90])  ,.DO91(d_out[91])  ,.DO92(d_out[92])  ,.DO93(d_out[93])  ,.DO94(d_out[94])  ,.DO95(d_out[95])  ,.DO96(d_out[96])  ,.DO97(d_out[97])  ,.DO98(d_out[98])  ,.DO99(d_out[99]),
						 .DO100(d_out[100]) ,.DO101(d_out[101]) ,.DO102(d_out[102]) ,.DO103(d_out[103]) ,.DO104(d_out[104]) ,.DO105(d_out[105]) ,.DO106(d_out[106]) ,.DO107(d_out[107]) ,.DO108(d_out[108]) ,.DO109(d_out[109]),
						 .DO110(d_out[110]) ,.DO111(d_out[111]) ,.DO112(d_out[112]) ,.DO113(d_out[113]) ,.DO114(d_out[114]) ,.DO115(d_out[115]) ,.DO116(d_out[116]) ,.DO117(d_out[117]) ,.DO118(d_out[118]) ,.DO119(d_out[119]),
						 .DO120(d_out[120]) ,.DO121(d_out[121]) ,.DO122(d_out[122]) ,.DO123(d_out[123]) ,.DO124(d_out[124]) ,.DO125(d_out[125]) ,.DO126(d_out[126]) ,.DO127(d_out[127]) ,
						 .DI0  (d_in[0])   ,.DI1(d_in[1])    ,.DI2(d_in[2])    ,.DI3(d_in[3])    ,.DI4(d_in[4])    ,.DI5(d_in[5])    ,.DI6(d_in[6])    ,.DI7(d_in[7])    ,.DI8(d_in[8])    ,.DI9(d_in[9]),
						 .DI10 (d_in[10])  ,.DI11(d_in[11])  ,.DI12(d_in[12])  ,.DI13(d_in[13])  ,.DI14(d_in[14])  ,.DI15(d_in[15])  ,.DI16(d_in[16])  ,.DI17(d_in[17])  ,.DI18(d_in[18])  ,.DI19(d_in[19]),
						 .DI20 (d_in[20])  ,.DI21(d_in[21])  ,.DI22(d_in[22])  ,.DI23(d_in[23])  ,.DI24(d_in[24])  ,.DI25(d_in[25])  ,.DI26(d_in[26])  ,.DI27(d_in[27])  ,.DI28(d_in[28])  ,.DI29(d_in[29]),
						 .DI30 (d_in[30])  ,.DI31(d_in[31])  ,.DI32(d_in[32])  ,.DI33(d_in[33])  ,.DI34(d_in[34])  ,.DI35(d_in[35])  ,.DI36(d_in[36])  ,.DI37(d_in[37])  ,.DI38(d_in[38])  ,.DI39(d_in[39]),
						 .DI40 (d_in[40])  ,.DI41(d_in[41])  ,.DI42(d_in[42])  ,.DI43(d_in[43])  ,.DI44(d_in[44])  ,.DI45(d_in[45])  ,.DI46(d_in[46])  ,.DI47(d_in[47])  ,.DI48(d_in[48])  ,.DI49(d_in[49]),
						 .DI50 (d_in[50])  ,.DI51(d_in[51])  ,.DI52(d_in[52])  ,.DI53(d_in[53])  ,.DI54(d_in[54])  ,.DI55(d_in[55])  ,.DI56(d_in[56])  ,.DI57(d_in[57])  ,.DI58(d_in[58])  ,.DI59(d_in[59]),
						 .DI60 (d_in[60])  ,.DI61(d_in[61])  ,.DI62(d_in[62])  ,.DI63(d_in[63])  ,.DI64(d_in[64])  ,.DI65(d_in[65])  ,.DI66(d_in[66])  ,.DI67(d_in[67])  ,.DI68(d_in[68])  ,.DI69(d_in[69]),
						 .DI70 (d_in[70])  ,.DI71(d_in[71])  ,.DI72(d_in[72])  ,.DI73(d_in[73])  ,.DI74(d_in[74])  ,.DI75(d_in[75])  ,.DI76(d_in[76])  ,.DI77(d_in[77])  ,.DI78(d_in[78])  ,.DI79(d_in[79]),
						 .DI80 (d_in[80])  ,.DI81(d_in[81])  ,.DI82(d_in[82])  ,.DI83(d_in[83])  ,.DI84(d_in[84])  ,.DI85(d_in[85])  ,.DI86(d_in[86])  ,.DI87(d_in[87])  ,.DI88(d_in[88])  ,.DI89(d_in[89]),
						 .DI90 (d_in[90])  ,.DI91(d_in[91])  ,.DI92(d_in[92])  ,.DI93(d_in[93])  ,.DI94(d_in[94])  ,.DI95(d_in[95])  ,.DI96(d_in[96])  ,.DI97(d_in[97])  ,.DI98(d_in[98])  ,.DI99(d_in[99]),
						 .DI100(d_in[100]) ,.DI101(d_in[101]) ,.DI102(d_in[102]) ,.DI103(d_in[103]) ,.DI104(d_in[104]) ,.DI105(d_in[105]) ,.DI106(d_in[106]) ,.DI107(d_in[107]) ,.DI108(d_in[108]) ,.DI109(d_in[109]),
                         .DI110(d_in[110]) ,.DI111(d_in[111]) ,.DI112(d_in[112]) ,.DI113(d_in[113]) ,.DI114(d_in[114]) ,.DI115(d_in[115]) ,.DI116(d_in[116]) ,.DI117(d_in[117]) ,.DI118(d_in[118]) ,.DI119(d_in[119]),
						 .DI120(d_in[120]) ,.DI121(d_in[121]) ,.DI122(d_in[122]) ,.DI123(d_in[123]) ,.DI124(d_in[124]) ,.DI125(d_in[125]) ,.DI126(d_in[126]) ,.DI127(d_in[127]) ,
						 .CK(clk)    ,.WEB(write_en)   ,.OE(1'b1)    ,.CS(chip_en));


// ==============================================================================================================================================================================================================================
//  				   																				DRAM control signal
// ==============================================================================================================================================================================================================================

reg arvalid, awvalid, wvalid ;

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel

assign arlen_m_inf   = 127 ;  
assign araddr_m_inf  = (curr_state == S_INPUT_MAP) ? {16'h0001 , which_frame , 11'd0} : {16'h0002 , which_frame , 11'd0} ;
// always @ (*) begin 
	// if (read_map && (~arready_m_inf)) araddr_m_inf = {16'h0001 , which_frame , 11'd0} ;
	// else if (read_weight && (~arready_m_inf)) araddr_m_inf = {16'h0002 , which_frame , 11'd0} ;
	// else araddr_m_inf = 0 ;
// end

assign arvalid_m_inf = arvalid ;
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) arvalid <= 0 ;
	else begin 
		if (curr_state == S_IDLE && next_state == S_INPUT_MAP) arvalid <= 1 ;                    // for read map
		else if (curr_state == S_INPUT_MAP && next_state == S_INPUT_WEI) arvalid <= 1 ;          // for read weight  
		else if (arready_m_inf) arvalid <= 0 ;
		else arvalid <= arvalid ;
	end
end

// (2)	axi read data channel 
assign rready_m_inf  = 1 ;

// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 

assign awlen_m_inf = 127 ;
assign awaddr_m_inf = {16'h0001 , which_frame , 11'd0} ;

assign awvalid_m_inf = awvalid ;
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) awvalid <= 0 ;
	else begin 
		if (next_state == S_WRITE_BACK && curr_state == S_SET_TERMINAL_AND_RESET) awvalid <= 1 ;
		else if (awready_m_inf) awvalid <= 0 ;
	end
end
// (2)	axi write data channel 
assign wlast_m_inf = (dram_count == 127) ? 1 : 0 ;
assign wdata_m_inf = map_out ;

assign wvalid_m_inf = wvalid ;
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) wvalid <= 0 ;
	else begin 
		if (awready_m_inf) wvalid <= 1 ;
		else if (dram_count == 127) wvalid <= 0 ;
	end
end


// (3)	axi write response channel 
assign bready_m_inf = 1 ;



endmodule

