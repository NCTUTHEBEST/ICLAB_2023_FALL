// //############################################################################
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //    (C) Copyright System Integration and Silicon Implementation Laboratory
// //    All Right Reserved
// //		Date		: 2023/10
// //		Version		: v1.0
// //   	File Name   : HT_TOP.v
// //   	Module Name : HT_TOP
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //############################################################################

// //synopsys translate_off
// `include "SORT_IP.v"
// //synopsys translate_on

// module HT_TOP(
    // // Input signals
    // clk,
	// rst_n,
	// in_valid,
    // in_weight, 
	// out_mode,
    // // Output signals
    // out_valid, 
	// out_code
// );

// // ===============================================================
// // Input & Output Declaration
// // ===============================================================
// input clk, rst_n, in_valid, out_mode;
// input [2:0] in_weight;

// output reg out_valid, out_code;

// // ===============================================================
// // parameter
// // ===============================================================
// parameter S_IDLE = 4'b0000, S_INPUT = 4'b0001 ;
// parameter S_VAR8 = 4'b0010, S_VAR7  = 4'b0011 ;
// parameter S_VAR6 = 4'b0100, S_VAR5  = 4'b0101 ;
// parameter S_VAR4 = 4'b0110, S_VAR3  = 4'b0111 ;
// parameter S_VAR2 = 4'b1000, S_OUT   = 4'b1001 ;

// parameter IP_WIDTH = 8 ;

// // ===============================================================
// // Reg & Wire Declaration
// // ===============================================================
// reg [3:0] character [0:7]  ;
// reg [4:0] weight    [0:13] ; // index is character priority, A=14 / B=13 / C=12/ E=11 / I=10 / L=9 / O=8 / V=7 ...
// reg [7:0] subtree   [0:13] ;
// reg [6:0] huff_enc  [0:7]  ;
// reg [2:0] huff_count[0:7]  ; // max code length is 7
// reg [6:0] output_counter ;
// reg mode ;

// reg  [8*4-1 : 0]in_cha ;
// reg  [8*5-1 : 0]in_wei ;
// wire [8*4-1 : 0]out_cha ;
// wire [50:0] out_concat ;


// // ===============================================================
// // FSM
// // ===============================================================
// reg [3:0] next_state, curr_state ;

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) curr_state <= S_IDLE ;
	// else curr_state <= next_state ;
// end

// always @ (*) begin 
	// case (curr_state)
		// S_IDLE : begin 
			// if (in_valid) next_state = S_INPUT ;
			// else next_state = S_IDLE ;
		// end
		// S_INPUT : begin 
			// if (in_valid) next_state = S_INPUT ;
			// else next_state = S_VAR8 ;
		// end
		// S_VAR8 : begin 
			// next_state = S_VAR7 ;
		// end
		// S_VAR7 : begin 
			// next_state = S_VAR6 ;
		// end
		// S_VAR6 : begin 
			// next_state = S_VAR5 ;
		// end
		// S_VAR5 : begin 
			// next_state = S_VAR4 ;
		// end
		// S_VAR4 : begin 
			// next_state = S_VAR3 ;
		// end
		// S_VAR3 : begin 
			// next_state = S_VAR2 ;
		// end
		// S_VAR2 : begin 
			// next_state = S_OUT ;
		// end
		// S_OUT : begin 
			// if (mode == 1) begin 
				// if (output_counter == 6 && huff_count[6] == 0) next_state = S_IDLE ;
				// else next_state = S_OUT ;
			// end
			// else begin 
				// if (output_counter == 4 && huff_count[4] == 0) next_state = S_IDLE ;
				// else next_state = S_OUT ;
			// end
		// end
		// default : next_state = S_IDLE ;
	// endcase 
// end

// // ===============================================================
// // Design
// // ===============================================================

// // // ===============================================================
// // // store character
// // // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// for (int i = 0 ; i < 8 ; i = i + 1) begin 
			// character[i] <= 0 ;
		// end
	// end
	// else begin 
		// if (curr_state == S_IDLE) begin 
			// character[7] <= 4'd13 ;
			// character[6] <= 4'd12 ;
			// character[5] <= 4'd11 ;
			// character[4] <= 4'd10 ;
			// character[3] <= 4'd9 ;
			// character[2] <= 4'd8  ;
			// character[1] <= 4'd7  ;
			// character[0] <= 4'd6  ;
		// end
		// else if (curr_state == S_VAR8) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= out_cha[31:28] ;
			// character[5] <= out_cha[27:24] ;
			// character[4] <= out_cha[23:20] ;
			// character[3] <= out_cha[19:16] ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd5  ;
		// end
		// else if (curr_state == S_VAR7) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= out_cha[27:24] ;
			// character[4] <= out_cha[23:20] ;
			// character[3] <= out_cha[19:16] ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd4  ;
		// end
		// else if (curr_state == S_VAR6) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= 4'd15 ;
			// character[4] <= out_cha[23:20] ;
			// character[3] <= out_cha[19:16] ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd3  ;
		// end
		// else if (curr_state == S_VAR5) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= 4'd15 ;
			// character[4] <= 4'd15 ;
			// character[3] <= out_cha[19:16] ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd2  ;
		// end
		// else if (curr_state == S_VAR4) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= 4'd15 ;
			// character[4] <= 4'd15 ;
			// character[3] <= 4'd15 ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd1  ;
		// end
		// else if (curr_state == S_VAR3) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= 4'd15 ;
			// character[4] <= 4'd15 ;
			// character[3] <= 4'd15 ;
			// character[2] <= 4'd15 ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd0  ;
		// end
		// else begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// character[i] <= character[i] ;
			// end
		// end
	// end
// end





// // ===============================================================
// // store weight
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// for (int i = 0 ; i < 14 ; i = i + 1) begin 
			// weight[i] <= 0 ;
		// end
	// end
	// else begin 
		// if (in_valid) begin 
			// for (int i = 0 ; i < 6 ; i = i + 1) begin 
				// weight[i] <= 0 ;
			// end
			// weight[6] <= in_weight ;
			// weight[7] <= weight[6] ;
			// weight[8] <= weight[7] ;
			// weight[9] <= weight[8] ;
			// weight[10] <= weight[9] ;
			// weight[11] <= weight[10] ;
			// weight[12] <= weight[11] ;
			// weight[13] <= weight[12] ;
		// end
		// else if (curr_state == S_VAR8) begin 
			// weight[5] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR7) begin 
			// weight[4] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR6) begin 
			// weight[3] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR5) begin 
			// weight[2] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR4) begin 
			// weight[1] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR3) begin 
			// weight[0] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else begin 
			// for (int i = 0 ; i < 14 ; i = i + 1) begin
				// weight[i] <= weight[i] ;
			// end
		// end	
	// end
// end

// // ===============================================================
// // subtree  =>  MSB : A  /  LSB : V
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// for (int i = 0 ; i < 14 ; i = i + 1) begin 
			// subtree[i] <= 0 ;
		// end
	// end
	// else begin 
		// if (curr_state == S_IDLE) begin 
			// for (int i = 0 ; i < 6 ; i = i + 1) begin 
				// subtree[i] <= 0 ;
			// end
			// subtree[13] <= 8'b10000000 ;
			// subtree[12] <= 8'b01000000 ;
			// subtree[11] <= 8'b00100000 ;
			// subtree[10] <= 8'b00010000 ;
			// subtree[9] <= 8'b00001000 ;
			// subtree[8]  <= 8'b00000100 ;
			// subtree[7]  <= 8'b00000010 ;
			// subtree[6]  <= 8'b00000001 ;
		// end
		// else if (curr_state == S_VAR8) begin 
			// subtree[5] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR7) begin 
			// subtree[4] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR6) begin 
			// subtree[3] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR5) begin 
			// subtree[2] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR4) begin 
			// subtree[1] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR3) begin 
			// subtree[0] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else begin 
			// for (int i = 0 ; i < 14 ; i = i + 1) begin 
				// subtree[i] <= subtree[i] ;
			// end
		// end
	// end
// end

// // ===============================================================
// // store mode
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// mode <= 0 ;
	// end
	// else begin 
		// if (curr_state == S_IDLE && next_state == S_INPUT) mode <= out_mode ;
		// else mode <= mode ;
	// end
// end

// // ===============================================================
// // huff_enc
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin
		// for (int i = 0 ; i < 8 ; i = i + 1) begin 
			// huff_enc[i] <= 0 ;
		// end
	// end
	// else begin 
		// if (curr_state == S_VAR8 || curr_state == S_VAR7 || curr_state == S_VAR6 || curr_state == S_VAR5 || curr_state == S_VAR4 || curr_state == S_VAR3 || curr_state == S_VAR2) begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// huff_enc[i][huff_count[i]] <= (subtree[out_cha[3:0]][i] & 1'b1) | (subtree[out_cha[7:4]][i] & 1'b0) ;
			// end			
		// end

	// end
// end

// // ===============================================================
// // huff_count
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin
		// for (int i = 0 ; i < 8 ; i = i + 1) begin 
			// huff_count[i] <= 0 ;
		// end
	// end
	// else begin
		// if (curr_state == S_IDLE) begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// huff_count[i] <= 0 ;
			// end
		// end
		// else if (curr_state == S_VAR8 || curr_state == S_VAR7 || curr_state == S_VAR6 || curr_state == S_VAR5 || curr_state == S_VAR4 || curr_state == S_VAR3) begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// huff_count[i] <= huff_count[i] + subtree[out_cha[3:0]][i] + subtree[out_cha[7:4]][i] ;
			// end
		// end
		// else if (curr_state == S_OUT) begin 
			// huff_count[output_counter] <= huff_count[output_counter] - 1 ;
		// end
		// else begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// huff_count[i] <= huff_count[i] ;
			// end
		// end
	// end
// end


// // ===============================================================
// // out_valid & out_code
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// out_code <= 0 ;
		// out_valid <= 0 ;
	// end
	// else if (curr_state == S_OUT) begin 
		// out_valid <= 1 ;
		// out_code  <= huff_enc[output_counter][huff_count[output_counter]] ;
	// end
	// else begin 
		// out_code <= 0 ;
		// out_valid <= 0 ;
	// end
// end

// // ===============================================================
// // output_counter
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) output_counter <= 0 ;
	// else begin 
		// if (curr_state == S_IDLE) output_counter <= 3 ;
		// else if (curr_state == S_OUT) begin 
			// if (mode == 1) begin 
				// if (huff_count[3] == 7 && huff_count[5] == 7 && huff_count[2] == 7 && huff_count[7] == 0) output_counter <= 6 ;
				// else if (huff_count[3] == 7 && huff_count[5] == 7 && huff_count[2] == 0) output_counter <= 7 ;
				// else if (huff_count[3] == 7 && huff_count[5] == 0) output_counter <= 2 ;
				// else if (huff_count[3] == 0) output_counter <= 5 ;
				// else output_counter <= output_counter ;
			// end
			// else begin 
				// if (huff_count[3] == 7 && huff_count[2] == 7 && huff_count[1] == 7 && huff_count[0] == 0) output_counter <= 4 ;
				// else if (huff_count[3] == 7 && huff_count[2] == 7 && huff_count[1] == 0) output_counter <= 0 ;
				// else if (huff_count[3] == 7 && huff_count[2] == 0) output_counter <= 1 ;
				// else if (huff_count[3] == 0) output_counter <= 2 ;
				// else output_counter <= output_counter ;
			// end
		// end
		// else output_counter <= output_counter ;
	// end
// end

// // ===============================================================
// // output_concat
// // ===============================================================

// assign out_concat = (mode) ? {huff_enc[3], huff_enc[5], huff_enc[2], huff_enc[7], huff_enc[6]} : {huff_enc[3], huff_enc[2], huff_enc[1], huff_enc[0], huff_enc[4]} ;

// // ===============================================================
// // SORT_IP 
// // ===============================================================

// always @ (*) begin 
	// if (curr_state == S_VAR8) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {weight[13], weight[12], weight[11], weight[10], weight[9], weight[8], weight[7], weight[6]} ;
	// end
	// else if (curr_state == S_VAR7) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, weight[character[6]], weight[character[5]], weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[5]} ;
	// end
	// else if (curr_state == S_VAR6) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, weight[character[5]], weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[4]} ;
	// end
	// else if (curr_state == S_VAR5) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, 5'd31, weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[3]} ;
	// end
	// else if (curr_state == S_VAR4) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, 5'd31, 5'd31, weight[character[3]], weight[character[2]], weight[character[1]], weight[2]} ;
	// end
	// else if (curr_state == S_VAR3) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, 5'd31, 5'd31, 5'd31, weight[character[2]], weight[character[1]], weight[1]} ;
	// end
	// else if (curr_state == S_VAR2) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, 5'd31, 5'd31, 5'd31, 5'd31, weight[character[1]], weight[0]} ;
	// end
	// else begin
		// in_cha = 0 ;
		// in_wei = 0 ;
	// end
// end

// SORT_IP #(.IP_WIDTH(IP_WIDTH)) I_SORT_IP(.IN_character(in_cha), .IN_weight(in_wei), .OUT_character(out_cha)); 

// endmodule




















// //############################################################################
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //    (C) Copyright System Integration and Silicon Implementation Laboratory
// //    All Right Reserved
// //		Date		: 2023/10
// //		Version		: v1.0
// //   	File Name   : HT_TOP.v
// //   	Module Name : HT_TOP
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //############################################################################

// //synopsys translate_off
// `include "SORT_IP.v"
// //synopsys translate_on

// module HT_TOP(
    // // Input signals
    // clk,
	// rst_n,
	// in_valid,
    // in_weight, 
	// out_mode,
    // // Output signals
    // out_valid, 
	// out_code
// );

// // ===============================================================
// // Input & Output Declaration
// // ===============================================================
// input clk, rst_n, in_valid, out_mode;
// input [2:0] in_weight;

// output reg out_valid, out_code;

// // ===============================================================
// // parameter
// // ===============================================================
// parameter S_IDLE = 4'b0000, S_INPUT = 4'b0001 ;
// parameter S_VAR8 = 4'b0010, S_VAR7  = 4'b0011 ;
// parameter S_VAR6 = 4'b0100, S_VAR5  = 4'b0101 ;
// parameter S_VAR4 = 4'b0110, S_VAR3  = 4'b0111 ;
// parameter S_VAR2 = 4'b1000, S_OUT   = 4'b1001 ;

// parameter IP_WIDTH = 8 ;

// // ===============================================================
// // Reg & Wire Declaration
// // ===============================================================
// reg [3:0] character [0:7]  ;
// reg [4:0] weight    [0:13] ; // index is character priority, A=14 / B=13 / C=12/ E=11 / I=10 / L=9 / O=8 / V=7 ...
// reg [7:0] subtree   [0:13] ;
// reg [6:0] huff_enc  [0:7]  ;
// reg [2:0] huff_count[0:7]  ; // max code length is 7
// reg [6:0] output_counter ;
// reg [2:0] early_start ;
// reg mode ;

// reg  [8*4-1 : 0]in_cha ;
// reg  [8*5-1 : 0]in_wei ;
// wire [8*4-1 : 0]out_cha ;
// wire [50:0] out_concat ;


// // ===============================================================
// // FSM
// // ===============================================================
// reg [3:0] next_state, curr_state ;

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) curr_state <= S_IDLE ;
	// else curr_state <= next_state ;
// end

// always @ (*) begin 
	// case (curr_state)
		// S_IDLE : begin 
			// if (in_valid) next_state = S_INPUT ;
			// else next_state = S_IDLE ;
		// end
		// S_INPUT : begin 
			// if (early_start == 7) next_state = S_VAR8 ;
			// else next_state = S_INPUT ;
		// end
		// S_VAR8 : begin 
			// next_state = S_VAR7 ;
		// end
		// S_VAR7 : begin 
			// next_state = S_VAR6 ;
		// end
		// S_VAR6 : begin 
			// next_state = S_VAR5 ;
		// end
		// S_VAR5 : begin 
			// next_state = S_VAR4 ;
		// end
		// S_VAR4 : begin 
			// next_state = S_VAR3 ;
		// end
		// S_VAR3 : begin 
			// next_state = S_VAR2 ;
		// end
		// S_VAR2 : begin 
			// next_state = S_OUT ;
		// end
		// S_OUT : begin 
			// if (mode == 1) begin 
				// if (output_counter == 6 && huff_count[6] == 0) next_state = S_IDLE ;
				// else next_state = S_OUT ;
			// end
			// else begin 
				// if (output_counter == 4 && huff_count[4] == 0) next_state = S_IDLE ;
				// else next_state = S_OUT ;
			// end
		// end
		// default : next_state = S_IDLE ;
	// endcase 
// end

// // ===============================================================
// // Design
// // ===============================================================

// // ===============================================================
// // early start
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// early_start <= 0 ;
	// end
	// else begin 
		// if (in_valid) early_start <= early_start + 1 ;
		// else early_start <= 0 ;
	// end
// end

// // ===============================================================
// // store character
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// for (int i = 0 ; i < 8 ; i = i + 1) begin 
			// character[i] <= 0 ;
		// end
	// end
	// else begin 
		// if (curr_state == S_IDLE) begin 
			// character[7] <= 4'd13 ;
			// character[6] <= 4'd12 ;
			// character[5] <= 4'd11 ;
			// character[4] <= 4'd10 ;
			// character[3] <= 4'd9 ;
			// character[2] <= 4'd8  ;
			// character[1] <= 4'd7  ;
			// character[0] <= 4'd6  ;
		// end
		// else if (curr_state == S_VAR8) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= out_cha[31:28] ;
			// character[5] <= out_cha[27:24] ;
			// character[4] <= out_cha[23:20] ;
			// character[3] <= out_cha[19:16] ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd5  ;
		// end
		// else if (curr_state == S_VAR7) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= out_cha[27:24] ;
			// character[4] <= out_cha[23:20] ;
			// character[3] <= out_cha[19:16] ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd4  ;
		// end
		// else if (curr_state == S_VAR6) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= 4'd15 ;
			// character[4] <= out_cha[23:20] ;
			// character[3] <= out_cha[19:16] ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd3  ;
		// end
		// else if (curr_state == S_VAR5) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= 4'd15 ;
			// character[4] <= 4'd15 ;
			// character[3] <= out_cha[19:16] ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd2  ;
		// end
		// else if (curr_state == S_VAR4) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= 4'd15 ;
			// character[4] <= 4'd15 ;
			// character[3] <= 4'd15 ;
			// character[2] <= out_cha[15:12] ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd1  ;
		// end
		// else if (curr_state == S_VAR3) begin 
			// character[7] <= 4'd15 ;
			// character[6] <= 4'd15 ;
			// character[5] <= 4'd15 ;
			// character[4] <= 4'd15 ;
			// character[3] <= 4'd15 ;
			// character[2] <= 4'd15 ;
			// character[1] <= out_cha[11:8]  ;
			// character[0] <= 4'd0  ;
		// end
		// else begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// character[i] <= character[i] ;
			// end
		// end
	// end
// end





// // ===============================================================
// // store weight
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// for (int i = 0 ; i < 14 ; i = i + 1) begin 
			// weight[i] <= 0 ;
		// end
	// end
	// else begin 
		// if (in_valid) begin 
			// for (int i = 0 ; i < 6 ; i = i + 1) begin 
				// weight[i] <= 0 ;
			// end
			// weight[6] <= in_weight ;
			// weight[7] <= weight[6] ;
			// weight[8] <= weight[7] ;
			// weight[9] <= weight[8] ;
			// weight[10] <= weight[9] ;
			// weight[11] <= weight[10] ;
			// weight[12] <= weight[11] ;
			// weight[13] <= weight[12] ;
		// end
		// else if (curr_state == S_VAR8) begin 
			// weight[5] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR7) begin 
			// weight[4] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR6) begin 
			// weight[3] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR5) begin 
			// weight[2] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR4) begin 
			// weight[1] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else if (curr_state == S_VAR3) begin 
			// weight[0] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		// end
		// else begin 
			// for (int i = 0 ; i < 14 ; i = i + 1) begin
				// weight[i] <= weight[i] ;
			// end
		// end	
	// end
// end

// // ===============================================================
// // subtree  =>  MSB : A  /  LSB : V
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// for (int i = 0 ; i < 14 ; i = i + 1) begin 
			// subtree[i] <= 0 ;
		// end
	// end
	// else begin 
		// if (curr_state == S_IDLE) begin 
			// for (int i = 0 ; i < 6 ; i = i + 1) begin 
				// subtree[i] <= 0 ;
			// end
			// subtree[13] <= 8'b10000000 ;
			// subtree[12] <= 8'b01000000 ;
			// subtree[11] <= 8'b00100000 ;
			// subtree[10] <= 8'b00010000 ;
			// subtree[9] <= 8'b00001000 ;
			// subtree[8]  <= 8'b00000100 ;
			// subtree[7]  <= 8'b00000010 ;
			// subtree[6]  <= 8'b00000001 ;
		// end
		// else if (curr_state == S_VAR8) begin 
			// subtree[5] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR7) begin 
			// subtree[4] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR6) begin 
			// subtree[3] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR5) begin 
			// subtree[2] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR4) begin 
			// subtree[1] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else if (curr_state == S_VAR3) begin 
			// subtree[0] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		// end
		// else begin 
			// for (int i = 0 ; i < 14 ; i = i + 1) begin 
				// subtree[i] <= subtree[i] ;
			// end
		// end
	// end
// end

// // ===============================================================
// // store mode
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// mode <= 0 ;
	// end
	// else begin 
		// if (curr_state == S_IDLE && next_state == S_INPUT) mode <= out_mode ;
		// else mode <= mode ;
	// end
// end

// // ===============================================================
// // huff_enc
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin
		// for (int i = 0 ; i < 8 ; i = i + 1) begin 
			// huff_enc[i] <= 0 ;
		// end
	// end
	// else begin 
		// if (curr_state == S_VAR8 || curr_state == S_VAR7 || curr_state == S_VAR6 || curr_state == S_VAR5 || curr_state == S_VAR4 || curr_state == S_VAR3 || curr_state == S_VAR2) begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// huff_enc[i][huff_count[i]] <= (subtree[out_cha[3:0]][i] & 1'b1) | (subtree[out_cha[7:4]][i] & 1'b0) ;
			// end			
		// end

	// end
// end

// // ===============================================================
// // huff_count
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin
		// for (int i = 0 ; i < 8 ; i = i + 1) begin 
			// huff_count[i] <= 0 ;
		// end
	// end
	// else begin
		// if (curr_state == S_IDLE) begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// huff_count[i] <= 0 ;
			// end
		// end
		// else if (curr_state == S_VAR8 || curr_state == S_VAR7 || curr_state == S_VAR6 || curr_state == S_VAR5 || curr_state == S_VAR4 || curr_state == S_VAR3) begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// huff_count[i] <= huff_count[i] + subtree[out_cha[3:0]][i] + subtree[out_cha[7:4]][i] ;
			// end
		// end
		// else if (curr_state == S_OUT) begin 
			// huff_count[output_counter] <= huff_count[output_counter] - 1 ;
		// end
		// else begin 
			// for (int i = 0 ; i < 8 ; i = i + 1) begin 
				// huff_count[i] <= huff_count[i] ;
			// end
		// end
	// end
// end


// // ===============================================================
// // out_valid & out_code
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// out_code <= 0 ;
		// out_valid <= 0 ;
	// end
	// else if (curr_state == S_OUT) begin 
		// out_valid <= 1 ;
		// out_code  <= huff_enc[output_counter][huff_count[output_counter]] ;
	// end
	// else begin 
		// out_code <= 0 ;
		// out_valid <= 0 ;
	// end
// end

// // ===============================================================
// // output_counter
// // ===============================================================

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) output_counter <= 0 ;
	// else begin 
		// if (curr_state == S_IDLE) output_counter <= 3 ;
		// else if (curr_state == S_OUT) begin 
			// if (mode == 1) begin 
				// if (huff_count[3] == 7 && huff_count[5] == 7 && huff_count[2] == 7 && huff_count[7] == 0) output_counter <= 6 ;
				// else if (huff_count[3] == 7 && huff_count[5] == 7 && huff_count[2] == 0) output_counter <= 7 ;
				// else if (huff_count[3] == 7 && huff_count[5] == 0) output_counter <= 2 ;
				// else if (huff_count[3] == 0) output_counter <= 5 ;
				// else output_counter <= output_counter ;
			// end
			// else begin 
				// if (huff_count[3] == 7 && huff_count[2] == 7 && huff_count[1] == 7 && huff_count[0] == 0) output_counter <= 4 ;
				// else if (huff_count[3] == 7 && huff_count[2] == 7 && huff_count[1] == 0) output_counter <= 0 ;
				// else if (huff_count[3] == 7 && huff_count[2] == 0) output_counter <= 1 ;
				// else if (huff_count[3] == 0) output_counter <= 2 ;
				// else output_counter <= output_counter ;
			// end
		// end
		// else output_counter <= output_counter ;
	// end
// end

// // ===============================================================
// // output_concat
// // ===============================================================

// assign out_concat = (mode) ? {huff_enc[3], huff_enc[5], huff_enc[2], huff_enc[7], huff_enc[6]} : {huff_enc[3], huff_enc[2], huff_enc[1], huff_enc[0], huff_enc[4]} ;

// // ===============================================================
// // SORT_IP 
// // ===============================================================

// always @ (*) begin 
	// if (curr_state == S_VAR8) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {weight[13], weight[12], weight[11], weight[10], weight[9], weight[8], weight[7], weight[6]} ;
	// end
	// else if (curr_state == S_VAR7) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, weight[character[6]], weight[character[5]], weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[5]} ;
	// end
	// else if (curr_state == S_VAR6) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, weight[character[5]], weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[4]} ;
	// end
	// else if (curr_state == S_VAR5) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, 5'd31, weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[3]} ;
	// end
	// else if (curr_state == S_VAR4) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, 5'd31, 5'd31, weight[character[3]], weight[character[2]], weight[character[1]], weight[2]} ;
	// end
	// else if (curr_state == S_VAR3) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, 5'd31, 5'd31, 5'd31, weight[character[2]], weight[character[1]], weight[1]} ;
	// end
	// else if (curr_state == S_VAR2) begin 
		// in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		// in_wei = {5'd31, 5'd31, 5'd31, 5'd31, 5'd31, 5'd31, weight[character[1]], weight[0]} ;
	// end
	// else begin
		// in_cha = 0 ;
		// in_wei = 0 ;
	// end
// end

// SORT_IP #(.IP_WIDTH(IP_WIDTH)) I_SORT_IP(.IN_character(in_cha), .IN_weight(in_wei), .OUT_character(out_cha)); 

// endmodule
























//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// parameter
// ===============================================================
parameter S_IDLE = 4'b0000, S_INPUT = 4'b0001 ;
parameter S_VAR8 = 4'b0010, S_VAR7  = 4'b0011 ;
parameter S_VAR6 = 4'b0100, S_VAR5  = 4'b0101 ;
parameter S_VAR4 = 4'b0110, S_VAR3  = 4'b0111 ;
parameter S_VAR2 = 4'b1000, S_OUT   = 4'b1001 ;

parameter IP_WIDTH = 8 ;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
reg [3:0] character [0:7]  ;
reg [4:0] weight    [0:13] ; // index is character priority, A=14 / B=13 / C=12/ E=11 / I=10 / L=9 / O=8 / V=7 ...
reg [7:0] subtree   [0:13] ;
reg [6:0] huff_enc  [0:7]  ;
reg [2:0] huff_count[0:7]  ; // max code length is 7
reg [3:0] output_counter ;
reg [2:0] early_start ;
reg mode ;

reg  [8*4-1 : 0]in_cha ;
reg  [8*5-1 : 0]in_wei ;
wire [8*4-1 : 0]out_cha ;
wire [50:0] out_concat ;


// ===============================================================
// FSM
// ===============================================================
reg [3:0] next_state, curr_state ;

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) curr_state <= S_IDLE ;
	else curr_state <= next_state ;
end

always @ (*) begin 
	case (curr_state)
		S_IDLE : begin 
			if (in_valid) next_state = S_INPUT ;
			else next_state = S_IDLE ;
		end
		S_INPUT : begin 
			if (early_start == 7) next_state = S_VAR8 ;
			else next_state = S_INPUT ;
		end
		S_VAR8 : begin 
			next_state = S_VAR7 ;
		end
		S_VAR7 : begin 
			next_state = S_VAR6 ;
		end
		S_VAR6 : begin 
			next_state = S_VAR5 ;
		end
		S_VAR5 : begin 
			next_state = S_VAR4 ;
		end
		S_VAR4 : begin 
			next_state = S_VAR3 ;
		end
		S_VAR3 : begin 
			next_state = S_VAR2 ;
		end
		S_VAR2 : begin 
			next_state = S_OUT ;
		end
		S_OUT : begin 
			if (mode == 1) begin 
				if (output_counter == 6 && huff_count[6] == 0) next_state = S_IDLE ;
				else next_state = S_OUT ;
			end
			else begin 
				if (output_counter == 4 && huff_count[4] == 0) next_state = S_IDLE ;
				else next_state = S_OUT ;
			end
		end
		default : next_state = S_IDLE ;
	endcase 
end

// ===============================================================
// Design
// ===============================================================

// ===============================================================
// early start
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		early_start <= 0 ;
	end
	else begin 
		if (in_valid) early_start <= early_start + 1 ;
		else early_start <= 0 ;
	end
end

// ===============================================================
// store character
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 8 ; i = i + 1) begin 
			character[i] <= 0 ;
		end
	end
	else begin 
		if (curr_state == S_IDLE) begin 
			character[7] <= 4'd13 ;
			character[6] <= 4'd12 ;
			character[5] <= 4'd11 ;
			character[4] <= 4'd10 ;
			character[3] <= 4'd9 ;
			character[2] <= 4'd8  ;
			character[1] <= 4'd7  ;
			character[0] <= 4'd6  ;
		end
		else if (curr_state == S_VAR8) begin 
			character[7] <= 4'd15 ;
			character[6] <= out_cha[31:28] ;
			character[5] <= out_cha[27:24] ;
			character[4] <= out_cha[23:20] ;
			character[3] <= out_cha[19:16] ;
			character[2] <= out_cha[15:12] ;
			character[1] <= out_cha[11:8]  ;
			character[0] <= 4'd5  ;
		end
		else if (curr_state == S_VAR7) begin 
			character[7] <= 4'd15 ;
			character[6] <= 4'd15 ;
			character[5] <= out_cha[27:24] ;
			character[4] <= out_cha[23:20] ;
			character[3] <= out_cha[19:16] ;
			character[2] <= out_cha[15:12] ;
			character[1] <= out_cha[11:8]  ;
			character[0] <= 4'd4  ;
		end
		else if (curr_state == S_VAR6) begin 
			character[7] <= 4'd15 ;
			character[6] <= 4'd15 ;
			character[5] <= 4'd15 ;
			character[4] <= out_cha[23:20] ;
			character[3] <= out_cha[19:16] ;
			character[2] <= out_cha[15:12] ;
			character[1] <= out_cha[11:8]  ;
			character[0] <= 4'd3  ;
		end
		else if (curr_state == S_VAR5) begin 
			character[7] <= 4'd15 ;
			character[6] <= 4'd15 ;
			character[5] <= 4'd15 ;
			character[4] <= 4'd15 ;
			character[3] <= out_cha[19:16] ;
			character[2] <= out_cha[15:12] ;
			character[1] <= out_cha[11:8]  ;
			character[0] <= 4'd2  ;
		end
		else if (curr_state == S_VAR4) begin 
			character[7] <= 4'd15 ;
			character[6] <= 4'd15 ;
			character[5] <= 4'd15 ;
			character[4] <= 4'd15 ;
			character[3] <= 4'd15 ;
			character[2] <= out_cha[15:12] ;
			character[1] <= out_cha[11:8]  ;
			character[0] <= 4'd1  ;
		end
		else if (curr_state == S_VAR3) begin 
			character[7] <= 4'd15 ;
			character[6] <= 4'd15 ;
			character[5] <= 4'd15 ;
			character[4] <= 4'd15 ;
			character[3] <= 4'd15 ;
			character[2] <= 4'd15 ;
			character[1] <= out_cha[11:8]  ;
			character[0] <= 4'd0  ;
		end
		else begin 
			for (int i = 0 ; i < 8 ; i = i + 1) begin 
				character[i] <= character[i] ;
			end
		end
	end
end





// ===============================================================
// store weight
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 14 ; i = i + 1) begin 
			weight[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid) begin 
			for (int i = 0 ; i < 6 ; i = i + 1) begin 
				weight[i] <= 0 ;
			end
			weight[6] <= in_weight ;
			weight[7] <= weight[6] ;
			weight[8] <= weight[7] ;
			weight[9] <= weight[8] ;
			weight[10] <= weight[9] ;
			weight[11] <= weight[10] ;
			weight[12] <= weight[11] ;
			weight[13] <= weight[12] ;
		end
		else if (curr_state == S_VAR8) begin 
			weight[5] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		end
		else if (curr_state == S_VAR7) begin 
			weight[4] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		end
		else if (curr_state == S_VAR6) begin 
			weight[3] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		end
		else if (curr_state == S_VAR5) begin 
			weight[2] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		end
		else if (curr_state == S_VAR4) begin 
			weight[1] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		end
		else if (curr_state == S_VAR3) begin 
			weight[0] <= weight[out_cha[7:4]] + weight[out_cha[3:0]] ;
		end
		else begin 
			for (int i = 0 ; i < 14 ; i = i + 1) begin
				weight[i] <= weight[i] ;
			end
		end	
	end
end

// ===============================================================
// subtree  =>  MSB : A  /  LSB : V
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 14 ; i = i + 1) begin 
			subtree[i] <= 0 ;
		end
	end
	else begin 
		if (curr_state == S_IDLE) begin 
			for (int i = 0 ; i < 6 ; i = i + 1) begin 
				subtree[i] <= 0 ;
			end
			subtree[13] <= 8'b10000000 ;
			subtree[12] <= 8'b01000000 ;
			subtree[11] <= 8'b00100000 ;
			subtree[10] <= 8'b00010000 ;
			subtree[9] <= 8'b00001000 ;
			subtree[8]  <= 8'b00000100 ;
			subtree[7]  <= 8'b00000010 ;
			subtree[6]  <= 8'b00000001 ;
		end
		else if (curr_state == S_VAR8) begin 
			subtree[5] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		end
		else if (curr_state == S_VAR7) begin 
			subtree[4] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		end
		else if (curr_state == S_VAR6) begin 
			subtree[3] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		end
		else if (curr_state == S_VAR5) begin 
			subtree[2] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		end
		else if (curr_state == S_VAR4) begin 
			subtree[1] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		end
		else if (curr_state == S_VAR3) begin 
			subtree[0] <= subtree[out_cha[3:0]] | subtree[out_cha[7:4]] ;
		end
		else begin 
			for (int i = 0 ; i < 14 ; i = i + 1) begin 
				subtree[i] <= subtree[i] ;
			end
		end
	end
end

// ===============================================================
// store mode
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		mode <= 0 ;
	end
	else begin 
		if (curr_state == S_IDLE && next_state == S_INPUT) mode <= out_mode ;
		else mode <= mode ;
	end
end

// ===============================================================
// huff_enc
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		for (int i = 0 ; i < 8 ; i = i + 1) begin 
			huff_enc[i] <= 0 ;
		end
	end
	else begin 
		if (curr_state == S_VAR8 || curr_state == S_VAR7 || curr_state == S_VAR6 || curr_state == S_VAR5 || curr_state == S_VAR4 || curr_state == S_VAR3 || curr_state == S_VAR2) begin 
			for (int i = 0 ; i < 8 ; i = i + 1) begin 
				huff_enc[i][huff_count[i]] <= (subtree[out_cha[3:0]][i] & 1'b1) | (subtree[out_cha[7:4]][i] & 1'b0) ;
			end			
		end

	end
end

// ===============================================================
// huff_count
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		for (int i = 0 ; i < 8 ; i = i + 1) begin 
			huff_count[i] <= 0 ;
		end
	end
	else begin
		if (curr_state == S_IDLE) begin 
			for (int i = 0 ; i < 8 ; i = i + 1) begin 
				huff_count[i] <= 0 ;
			end
		end
		else if (curr_state == S_VAR8 || curr_state == S_VAR7 || curr_state == S_VAR6 || curr_state == S_VAR5 || curr_state == S_VAR4 || curr_state == S_VAR3) begin 
			for (int i = 0 ; i < 8 ; i = i + 1) begin 
				huff_count[i] <= huff_count[i] + subtree[out_cha[3:0]][i] + subtree[out_cha[7:4]][i] ;
			end
		end
		else if (curr_state == S_OUT) begin 
			huff_count[output_counter] <= huff_count[output_counter] - 1 ;
		end
		else begin 
			for (int i = 0 ; i < 8 ; i = i + 1) begin 
				huff_count[i] <= huff_count[i] ;
			end
		end
	end
end


// ===============================================================
// out_valid & out_code
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		out_code <= 0 ;
		out_valid <= 0 ;
	end
	else if (curr_state == S_OUT) begin 
		out_valid <= 1 ;
		out_code  <= huff_enc[output_counter][huff_count[output_counter]] ;
	end
	else begin 
		out_code <= 0 ;
		out_valid <= 0 ;
	end
end

// ===============================================================
// output_counter
// ===============================================================

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) output_counter <= 0 ;
	else begin 
		if (curr_state == S_IDLE) output_counter <= 3 ;
		else if (curr_state == S_OUT) begin 
			if (mode == 1) begin 
				if (output_counter == 3 && huff_count[3] == 0) output_counter <= 5 ;
				else if (output_counter == 5 && huff_count[5] == 0) output_counter <= 2 ;
				else if (output_counter == 2 && huff_count[2] == 0) output_counter <= 7 ;
				else if (output_counter == 7 && huff_count[7] == 0) output_counter <= 6 ;
				else output_counter <= output_counter ;
			end
			else begin 
				if (output_counter == 0 && huff_count[0] == 0) output_counter <= 4 ;
				else if (output_counter == 1 && huff_count[1] == 0) output_counter <= 0 ;
				else if (output_counter == 2 && huff_count[2] == 0) output_counter <= 1 ;
				else if (output_counter == 3 && huff_count[3] == 0) output_counter <= 2 ;
				else output_counter <= output_counter ;
			end
		end
		else output_counter <= output_counter ;
	end
end

// ===============================================================
// output_concat
// ===============================================================

assign out_concat = (mode) ? {huff_enc[3], huff_enc[5], huff_enc[2], huff_enc[7], huff_enc[6]} : {huff_enc[3], huff_enc[2], huff_enc[1], huff_enc[0], huff_enc[4]} ;

// ===============================================================
// SORT_IP 
// ===============================================================

always @ (*) begin 
	if (curr_state == S_VAR8) begin 
		in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		in_wei = {weight[13], weight[12], weight[11], weight[10], weight[9], weight[8], weight[7], weight[6]} ;
	end
	else if (curr_state == S_VAR7) begin 
		in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		in_wei = {5'd31, weight[character[6]], weight[character[5]], weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[5]} ;
	end
	else if (curr_state == S_VAR6) begin 
		in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		in_wei = {5'd31, 5'd31, weight[character[5]], weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[4]} ;
	end
	else if (curr_state == S_VAR5) begin 
		in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		in_wei = {5'd31, 5'd31, 5'd31, weight[character[4]], weight[character[3]], weight[character[2]], weight[character[1]], weight[3]} ;
	end
	else if (curr_state == S_VAR4) begin 
		in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		in_wei = {5'd31, 5'd31, 5'd31, 5'd31, weight[character[3]], weight[character[2]], weight[character[1]], weight[2]} ;
	end
	else if (curr_state == S_VAR3) begin 
		in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		in_wei = {5'd31, 5'd31, 5'd31, 5'd31, 5'd31, weight[character[2]], weight[character[1]], weight[1]} ;
	end
	else if (curr_state == S_VAR2) begin 
		in_cha = {character[7], character[6], character[5], character[4], character[3], character[2], character[1], character[0]} ;
		in_wei = {5'd31, 5'd31, 5'd31, 5'd31, 5'd31, 5'd31, weight[character[1]], weight[0]} ;
	end
	else begin
		in_cha = 0 ;
		in_wei = 0 ;
	end
end

SORT_IP #(.IP_WIDTH(IP_WIDTH)) I_SORT_IP(.IN_character(in_cha), .IN_weight(in_wei), .OUT_character(out_cha)); 

endmodule