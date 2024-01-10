 module CAD (
	clk, 
	rst_n,
	in_valid,
	in_valid2,
	matrix_size,
	matrix,
	matrix_idx,
	mode,
	out_valid,
	out_value
	) ;
	
//---------------------------------------------------------------------
//   PARAMETER & integer
//---------------------------------------------------------------------
parameter S_IDLE     = 4'b0000 ;
parameter S_INPUT1   = 4'b0001 ;
parameter S_INPUT2   = 4'b0010 ;
parameter S_KERNEL   = 4'b0011 ;
parameter S_WAIT     = 4'b0100 ;
parameter S_START_IMG = 4'b0101 ;
parameter S_WAIT2   = 4'b0110 ;
parameter S_FILL_BUF = 4'b0111 ;
parameter S_START_CONV = 4'b1000 ;
parameter S_MAXPOOL = 4'b1001 ;
parameter S_OUT  = 4'b1010 ;



//---------------------------------------------------------------------
//   I/O port 
//---------------------------------------------------------------------
input clk, rst_n, in_valid, in_valid2, mode ;
input [1:0] matrix_size ;
input [3:0] matrix_idx  ;
input [7:0] matrix ;

output reg out_valid ;
output reg out_value ;


//---------------------------------------------------------------------
//   wire & reg  
//---------------------------------------------------------------------

reg         flag ;
reg 	    update_candidate ;
reg 		save_mode ;
reg [1:0]   save_matrix_size ;
reg [5:0]   real_matrix_size ;
reg [3:0]   cal_image_idx  ;
reg [3:0]   cal_kernel_idx ;
reg [4:0]   matrix_id ;
reg [6:0]   word_count ;
reg [2:0]   pixel_count ;
reg [63:0]  input_temp ;
reg [7:0]   kernel [0:24] ;
reg [7:0]   line_buf[0:4][0:39] ;
reg [7:0]   candidate[0:39] ;
reg [2:0]   line_buf_full_count ;
reg [5:0]   conv_count ;
reg [2:0]   exe_count ;
reg [8:0]   out_count ;
reg [3:0]  finish_count ;
reg [5:0]  padding_zero_count ;
reg max_pool_count ;
reg signed [19:0] mac_out ;
reg signed [19:0] conv_out_reg ;
reg signed [19:0] out_reg ;
reg signed [19:0] feature_map[0:27] ;
reg [279:0] maxpool_result ;

//---------------------------------------------------------------------
//      FSM  
//---------------------------------------------------------------------

reg [3:0] curr_state, next_state ;

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
		S_IDLE : begin 
			if (in_valid) next_state = S_INPUT1 ;
			else if (in_valid2) next_state = S_INPUT2 ;
			else next_state = S_IDLE ;
		end
		S_INPUT1 : begin 
			if (in_valid) next_state = S_INPUT1 ;
			else next_state = S_IDLE ;
		end
		S_INPUT2 : begin 
			if (in_valid2) next_state = S_INPUT2 ;
			else next_state =  S_KERNEL ;
		end
		S_KERNEL : begin 
			if (matrix_id == 3) next_state = S_WAIT ;
			else next_state = S_KERNEL ;
		end
		S_WAIT : begin 
			next_state = S_START_IMG ;
		end
		S_START_IMG : begin 
			if (save_matrix_size == 0) next_state = S_WAIT2 ;
			else if (save_matrix_size == 1 && matrix_id == 1) next_state = S_WAIT2 ;
			else if (save_matrix_size == 2 && matrix_id == 3) next_state = S_WAIT2 ;
			else next_state = S_START_IMG ;
		end
		S_WAIT2 : next_state = S_FILL_BUF ;
		S_FILL_BUF : begin 
			if (save_mode == 1) next_state = S_START_CONV ;
			else begin 
				if (line_buf_full_count == 4) next_state = S_START_CONV ;
				else next_state = S_START_IMG ;
			end
		end
		S_START_CONV : begin 
			if (save_mode == 1) begin
				if (exe_count == 4) next_state = S_OUT ;
				else next_state = S_START_CONV ;
			end
			else begin 
				if (max_pool_count == 1 && conv_count == real_matrix_size - 5 && exe_count == 4) next_state = S_MAXPOOL ;
				else next_state = S_START_CONV ;
			end
		end
		S_MAXPOOL : next_state = S_OUT ;
		S_OUT : begin 
			if (save_mode == 0) begin 
				if (save_matrix_size == 0 && finish_count == 1 && out_count == 39) next_state = S_IDLE ; 
				else if (save_matrix_size == 1 && finish_count == 5 && out_count == 119) next_state = S_IDLE ; 
				else if (save_matrix_size == 2 && finish_count == 13 && out_count == 279) next_state = S_IDLE ; 
				else next_state = S_OUT ;
			end
			else begin 
				if (padding_zero_count == real_matrix_size - 4 && out_count == 19) next_state = S_IDLE ;
				else next_state = S_OUT ;
			end
		end
		default : begin 
			next_state = S_IDLE ;
		end
	endcase
end


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//      																								SRAM I/O port   
//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

reg  [63:0] sram_in   ;
reg  [11:0] sram_addr ;
wire [63:0] sram_out  ;
reg sram_CS  ;
reg sram_WEB ;
wire [6:0] get_kernel_addr ;

//---------------------------------------------------------------------
//      Address  
//---------------------------------------------------------------------

assign get_kernel_addr = (cal_kernel_idx << 2) + matrix_id ;

always @ (*) begin 
	case (curr_state)
		S_IDLE   : sram_addr = 0 ;
		S_INPUT1 : sram_addr = {matrix_id, word_count} ; 
		S_KERNEL : sram_addr = {5'b10000, get_kernel_addr} ;
		S_START_IMG, S_START_CONV, S_OUT : sram_addr = {cal_image_idx, word_count} ;
		default  : sram_addr = 0 ;
	endcase 
end

//---------------------------------------------------------------------
//      sram_in 
//---------------------------------------------------------------------

always @ (*) begin 
	case (curr_state)
		S_IDLE   : sram_in = 0 ;
		S_INPUT1 : begin 
			if (matrix_id == 5'b10000 && word_count[1:0] == 2'b11) sram_in = {input_temp[63:56], 56'd0} ;
			else sram_in = {input_temp[63:56], input_temp[55:48], input_temp[47:40], input_temp[39:32], input_temp[31:24], input_temp[23:16], input_temp[15:8], input_temp[7:0]} ;
		end
		default : sram_in = 0 ;
	endcase
end

//---------------------------------------------------------------------
//      WEB  
//---------------------------------------------------------------------

always @ (*) begin 
	case (curr_state)
		S_IDLE : sram_WEB = 0 ;
		S_INPUT1 : sram_WEB = 0 ;
		S_KERNEL : sram_WEB = 1 ;
		S_START_IMG, S_START_CONV, S_OUT : sram_WEB = 1 ;
		default : sram_WEB = 1 ;
	endcase 
end

//---------------------------------------------------------------------
//      CS  
//---------------------------------------------------------------------

always @ (*) begin 
	case (curr_state)
		S_IDLE   : sram_CS = 0 ;
		S_INPUT1 : begin 
			if (matrix_id == 5'b10000) begin 
				if (word_count[1:0] != 3 && pixel_count == 7) sram_CS = 1 ;
				else if (word_count[1:0] == 3) sram_CS = 1 ;
				else sram_CS = 0 ;
			end
			else if (pixel_count == 7) sram_CS = 1 ;
			else sram_CS = 0 ;
		end
		S_KERNEL : sram_CS = 1 ;
		S_START_IMG, S_START_CONV, S_OUT : sram_CS = 1 ;
		default : sram_CS = 1 ;
	endcase 
end


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//      																									DFF   
//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------
//      save_matrix_size  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		save_matrix_size <= 0 ;
	end
	else begin 
		if (curr_state == S_IDLE && in_valid) save_matrix_size <= matrix_size ;
		else save_matrix_size <= save_matrix_size ;
	end
end

always @ (*) begin 
	if (save_mode == 0) begin 
		if (save_matrix_size == 0) real_matrix_size = 8 ;
		else if (save_matrix_size == 1) real_matrix_size = 16 ;
		else real_matrix_size = 32 ;
	end
	else begin 
		if (save_matrix_size == 0) real_matrix_size = 16 ;
		else if (save_matrix_size == 1) real_matrix_size = 24 ;
		else real_matrix_size = 40 ;
	end
end

//---------------------------------------------------------------------
//      pixel_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		pixel_count <= 0 ;
	end
	else begin 
		if (matrix_id == 5'b10000 && word_count[1:0] == 2'b11) pixel_count <= 0 ;
		else if (curr_state == S_INPUT1) pixel_count <= pixel_count + 1 ;
		else pixel_count <= 0 ;
	end
end

//---------------------------------------------------------------------
//      word_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		word_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) word_count <= 0 ;
		else if (curr_state == S_START_IMG) word_count <= word_count + 1 ;
		else if ((curr_state == S_START_CONV || curr_state == S_MAXPOOL || curr_state == S_OUT) && flag == 1) word_count <= word_count + 1 ;
		else if (save_matrix_size == 0 && word_count == 7  && pixel_count == 3'b111) word_count <=  0 ;
		else if (save_matrix_size == 1 && word_count == 31 && pixel_count == 3'b111) word_count <=  0 ;
		else if (save_matrix_size == 2 && word_count == 127 && pixel_count == 3'b111) word_count <=  0 ;
		else if (matrix_id == 5'b10000 && word_count[1:0] == 2'b11) word_count <= word_count + 1 ;
		else if (pixel_count == 3'b111) word_count <= word_count + 1 ; 
		else word_count <= word_count ;
	end
end

//---------------------------------------------------------------------
//      matrix_id  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		matrix_id <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE || curr_state == S_WAIT || curr_state == S_WAIT2 || ((conv_count == real_matrix_size - 5) && exe_count == 4)) matrix_id <= 0 ;
		else if (save_matrix_size == 1 && (curr_state == S_START_CONV || curr_state == S_OUT) && matrix_id == 1) matrix_id <= matrix_id ;
		else if (save_matrix_size == 2 && (curr_state == S_START_CONV || curr_state == S_OUT) && matrix_id == 3) matrix_id <= matrix_id ;
		else if (curr_state == S_KERNEL || curr_state == S_START_IMG) matrix_id <= matrix_id + 1 ;
		else if (matrix_id == 5'b10000) matrix_id <= matrix_id ;
		else if (save_matrix_size == 0 && word_count[2:0] == 3'b111 && pixel_count == 3'b111)     matrix_id <= matrix_id + 1 ; 
		else if (save_matrix_size == 1 && word_count[4:0] == 5'b11111 && pixel_count == 3'b111)   matrix_id <= matrix_id + 1 ;		
		else if (save_matrix_size == 2 && word_count[6:0] == 7'b1111111 && pixel_count == 3'b111) matrix_id <= matrix_id + 1 ;
		else matrix_id <= matrix_id ;
	end
end

//---------------------------------------------------------------------
//      flag  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		flag <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) flag <= 0 ;
		else if (save_mode == 0) begin 
			if (save_matrix_size == 0 && (curr_state == S_START_CONV || curr_state == S_MAXPOOL || curr_state == S_OUT) && conv_count == real_matrix_size - 5 && exe_count == 4) flag <= 1 ;
			else if (save_matrix_size == 1 && (curr_state == S_START_CONV || curr_state == S_MAXPOOL || curr_state == S_OUT) && ((conv_count == real_matrix_size - 5 && exe_count == 4) || (conv_count == 0 && exe_count < 1))) flag <= 1 ;
			else if (save_matrix_size == 2 && (curr_state == S_START_CONV || curr_state == S_MAXPOOL || curr_state == S_OUT) && ((conv_count == real_matrix_size - 5 && exe_count == 4) || (conv_count == 0 && exe_count < 3))) flag <= 1 ;
			else flag <= 0 ;
		end
		else if (save_mode == 1) begin 
			if (curr_state == S_START_CONV) begin 
				if (save_matrix_size == 0 && conv_count == real_matrix_size - 5 && exe_count == 4) flag <= 1 ;
				else if (save_matrix_size == 1 && ((conv_count == real_matrix_size - 5 && exe_count == 4) || (conv_count == 0 && exe_count < 1))) flag <= 1 ;
				else if (save_matrix_size == 2 && ((conv_count == real_matrix_size - 5 && exe_count == 4) || (conv_count == 0 && exe_count < 3))) flag <= 1 ;
				else flag <= 0 ;
			end
			else if (curr_state == S_MAXPOOL || curr_state == S_OUT) begin 
				if (save_matrix_size == 0 && conv_count == real_matrix_size - 5 && exe_count == 4) flag <= 1 ;
				else if (save_matrix_size == 1 && ((conv_count == real_matrix_size - 5 && exe_count == 4) || (conv_count == 0 && out_count < 1))) flag <= 1 ;
				else if (save_matrix_size == 2 && ((conv_count == real_matrix_size - 5 && exe_count == 4) || (conv_count == 0 && out_count < 3))) flag <= 1 ;
				else flag <= 0 ;
			end
			else flag <= 0 ;
		end
		else flag <= 0 ;
	end
end

//---------------------------------------------------------------------
//      input_register  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		input_temp <= 0 ;
	end
	else begin 
		if (in_valid) begin
			input_temp[63:56] <= matrix ;
			input_temp[55:48] <= input_temp[63:56] ;
			input_temp[47:40] <= input_temp[55:48] ;
			input_temp[39:32] <= input_temp[47:40] ;
			input_temp[31:24] <= input_temp[39:32] ;
			input_temp[23:16] <= input_temp[31:24] ;
			input_temp[15:8]  <= input_temp[23:16] ;
			input_temp[7:0]   <= input_temp[15:8]  ;
		end
		else input_temp <= 0 ;
	end
end

//---------------------------------------------------------------------
//      save mode  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		save_mode <= 0 ;
	end
	else begin 
		if (curr_state == S_IDLE && in_valid2) begin
			save_mode <= mode ;
		end
		else save_mode <= save_mode ;
	end
end

//---------------------------------------------------------------------
//      save cal image kernel index  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		cal_image_idx <= 0 ;
		cal_kernel_idx <= 0 ;
	end
	else begin 
		if (in_valid2) begin
			cal_kernel_idx <= matrix_idx ;
			cal_image_idx  <= cal_kernel_idx ;
		end
		else begin 
			cal_image_idx  <= cal_image_idx ;
			cal_kernel_idx <= cal_kernel_idx ;
		end
	end
end

//---------------------------------------------------------------------
//      	cal_kernel  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 5 ; i = i + 1) begin 
			for (int j = 0 ; j < 5 ; j = j + 1) begin 
				kernel[i][j] <= 0 ;
			end
		end
	end
	else begin 
		if (curr_state == S_KERNEL) begin 
			if (save_mode == 0) begin 
				kernel[16] <= sram_out[7:0] ;
				kernel[17] <= sram_out[15:8] ;
				kernel[18] <= sram_out[23:16] ;
				kernel[19] <= sram_out[31:24] ;
				kernel[20] <= sram_out[39:32] ;
				kernel[21] <= sram_out[47:40] ;
				kernel[22] <= sram_out[55:48] ;
				kernel[23] <= sram_out[63:56] ;
				
				kernel[8]  <= kernel[16] ;
				kernel[9]  <= kernel[17] ;
				kernel[10] <= kernel[18] ;
				kernel[11] <= kernel[19] ;
				kernel[12] <= kernel[20] ;
				kernel[13] <= kernel[21] ;
				kernel[14] <= kernel[22] ;
				kernel[15] <= kernel[23] ;
				
				kernel[0]  <= kernel[8] ;
				kernel[1]  <= kernel[9] ;
				kernel[2]  <= kernel[10] ;
				kernel[3]  <= kernel[11] ;
				kernel[4]  <= kernel[12] ;
				kernel[5]  <= kernel[13] ;
				kernel[6]  <= kernel[14] ;
				kernel[7]  <= kernel[15] ;
			end
			else begin 
				kernel[1] <= sram_out[63:56] ;
				kernel[2] <= sram_out[55:48] ;
				kernel[3] <= sram_out[47:40] ;
				kernel[4] <= sram_out[39:32] ;
				kernel[5] <= sram_out[31:24] ;
				kernel[6] <= sram_out[23:16] ;
				kernel[7] <= sram_out[15:8] ;
				kernel[8] <= sram_out[7:0] ;
				
				kernel[9]  <= kernel[1] ;
				kernel[10] <= kernel[2] ;
				kernel[11] <= kernel[3] ;
				kernel[12] <= kernel[4] ;
				kernel[13] <= kernel[5] ;
				kernel[14] <= kernel[6] ;
				kernel[15] <= kernel[7] ;
				kernel[16] <= kernel[8] ;
				
				kernel[17] <= kernel[9] ;
				kernel[18] <= kernel[10] ;
				kernel[19] <= kernel[11] ;
				kernel[20] <= kernel[12] ;
				kernel[21] <= kernel[13] ;
				kernel[22] <= kernel[14] ;
				kernel[23] <= kernel[15] ;
				kernel[24] <= kernel[16] ;
			end
		end
		else if (curr_state == S_WAIT) begin 
			if (save_mode == 0) kernel[24] <= sram_out[63:56] ;
			else kernel[0] <= sram_out[63:56] ;
		end
		else begin 
			for (int i = 0 ; i < 5 ; i = i + 1) begin 
				for (int j = 0 ; j < 5 ; j = j + 1) begin 
					kernel[i][j] <= kernel[i][j] ;
				end
			end
		end
	end
end

//---------------------------------------------------------------------
//      	candidate buffer  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int j = 0 ; j < 40 ; j = j + 1) begin 
			candidate[j] <= 0 ;
		end
	end
	else begin
		if (save_mode == 1) begin 
			if (update_candidate) begin 
				if (save_matrix_size == 0) begin 
					if (padding_zero_count < 7) begin 
						for (int i = 39 ; i > 11 ; i = i - 1) candidate[i] <= 0 ;
						candidate[11] <= sram_out[63:56] ; candidate[10] <= sram_out[55:48] ;
						candidate[9]  <= sram_out[47:40] ; candidate[8]  <= sram_out[39:32] ; candidate[7] <= sram_out[31:24] ;
						candidate[6]  <= sram_out[23:16] ; candidate[5]  <= sram_out[15:8]  ; candidate[4] <= sram_out[7:0] ;
						candidate[3] <= 0; candidate[2] <= 0; candidate[1] <= 0; candidate[0] <= 0; 
					end
					else begin 
						for (int j = 0 ; j < 40 ; j = j + 1) begin 
							candidate[j] <= 0 ;
						end
					end
				end
				else if (save_matrix_size == 1) begin 
					if (padding_zero_count < 15) begin 
						for (int i = 39 ; i > 19 ; i = i - 1) candidate[i] <= 0 ;
						candidate[19] <= sram_out[63:56] ; candidate[18] <= sram_out[55:48] ;
						candidate[17] <= sram_out[47:40] ; candidate[16] <= sram_out[39:32] ; candidate[15] <= sram_out[31:24] ;
						candidate[14] <= sram_out[23:16] ; candidate[13] <= sram_out[15:8]  ; candidate[12] <= sram_out[7:0] ;
						candidate[11] <= candidate[19] ; candidate[10] <= candidate[18] ; candidate[9] <= candidate[17] ;
						candidate[8] <= candidate[16] ; candidate[7] <= candidate[15] ; candidate[6] <= candidate[14] ;
						candidate[5] <= candidate[13] ; candidate[4] <= candidate[12] ;
						candidate[3] <= 0; candidate[2] <= 0; candidate[1] <= 0; candidate[0] <= 0; 
					end
					else begin 
						for (int j = 0 ; j < 40 ; j = j + 1) begin 
							candidate[j] <= 0 ;
						end
					end
				end
				else begin
					if (padding_zero_count < 31) begin 
						for (int i = 39 ; i > 35 ; i = i - 1) candidate[i] <= 0 ;
						
						candidate[35] <= sram_out[63:56] ; candidate[34] <= sram_out[55:48] ;
						candidate[33] <= sram_out[47:40] ; candidate[32] <= sram_out[39:32] ; candidate[31] <= sram_out[31:24] ;
						candidate[30] <= sram_out[23:16] ; candidate[29] <= sram_out[15:8]  ; candidate[28] <= sram_out[7:0] ;
						
						candidate[27] <= candidate[35] ; candidate[26] <= candidate[34] ; candidate[25] <= candidate[33] ;
						candidate[24] <= candidate[32] ; candidate[23] <= candidate[31] ; candidate[22] <= candidate[30] ;
						candidate[21] <= candidate[29] ; candidate[20] <= candidate[28] ;
						
						candidate[19] <= candidate[27] ; candidate[18] <= candidate[26] ; candidate[17] <= candidate[25] ;
						candidate[16] <= candidate[24] ; candidate[15] <= candidate[23] ; candidate[14] <= candidate[22] ;
						candidate[13] <= candidate[21] ; candidate[12] <= candidate[20] ;
						
						candidate[11] <= candidate[19] ; candidate[10] <= candidate[18] ; candidate[9] <= candidate[17] ;
						candidate[8] <= candidate[16] ; candidate[7] <= candidate[15] ; candidate[6] <= candidate[14] ;
						candidate[5] <= candidate[13] ; candidate[4] <= candidate[12] ;
						candidate[3] <= 0; candidate[2] <= 0; candidate[1] <= 0; candidate[0] <= 0; 
					end
					else begin 
						for (int j = 0 ; j < 40 ; j = j + 1) begin 
							candidate[j] <= 0 ;
						end
					end
				end
			end
			else begin 
				for (int j = 0 ; j < 40 ; j = j + 1) begin 
					candidate[j] <= candidate[j] ;
				end
			end
		end
		else begin 
			if (update_candidate) begin 
				if (save_matrix_size == 0) begin 
					for (int i = 39 ; i > 7 ; i = i - 1) candidate[i] <= 0 ;
					candidate[7]  <= sram_out[63:56] ; candidate[6] <= sram_out[55:48] ;
					candidate[5]  <= sram_out[47:40] ; candidate[4]  <= sram_out[39:32] ; candidate[3] <= sram_out[31:24] ;
					candidate[2]  <= sram_out[23:16] ; candidate[1]  <= sram_out[15:8]  ; candidate[0] <= sram_out[7:0] ;
				end
				else if (save_matrix_size == 1) begin 
					for (int i = 39 ; i > 15 ; i = i - 1) candidate[i] <= 0 ;
					candidate[15] <= sram_out[63:56] ; candidate[14] <= sram_out[55:48] ;
					candidate[13] <= sram_out[47:40] ; candidate[12] <= sram_out[39:32] ; candidate[11] <= sram_out[31:24] ;
					candidate[10] <= sram_out[23:16] ; candidate[9]  <= sram_out[15:8]  ; candidate[8] <= sram_out[7:0] ;
					candidate[7] <= candidate[15] ; candidate[6] <= candidate[14] ; candidate[5] <= candidate[13] ;
					candidate[4] <= candidate[12] ; candidate[3] <= candidate[11] ; candidate[2] <= candidate[10] ;
					candidate[1] <= candidate[9]  ; candidate[0] <= candidate[8] ;
				end
				else begin
					for (int i = 39 ; i > 31 ; i = i - 1) candidate[i] <= 0 ;
					
					candidate[31] <= sram_out[63:56] ; candidate[30] <= sram_out[55:48] ;
					candidate[29] <= sram_out[47:40] ; candidate[28] <= sram_out[39:32] ; candidate[27] <= sram_out[31:24] ;
					candidate[26] <= sram_out[23:16] ; candidate[25] <= sram_out[15:8]  ; candidate[24] <= sram_out[7:0] ;
					
					candidate[23] <= candidate[31] ; candidate[22] <= candidate[30] ; candidate[21] <= candidate[29] ;
					candidate[20] <= candidate[28] ; candidate[19] <= candidate[27] ; candidate[18] <= candidate[26] ;
					candidate[17] <= candidate[25] ; candidate[16] <= candidate[24] ;
					
					candidate[15] <= candidate[23] ; candidate[14] <= candidate[22] ; candidate[13] <= candidate[21] ;
					candidate[12] <= candidate[20] ; candidate[11] <= candidate[19] ; candidate[10] <= candidate[18] ;
					candidate[9]  <= candidate[17] ; candidate[8]  <= candidate[16] ;
					
					candidate[7] <= candidate[15] ; candidate[6] <= candidate[14] ; candidate[5] <= candidate[13] ;
					candidate[4] <= candidate[12] ; candidate[3] <= candidate[11] ; candidate[2] <= candidate[10] ;
					candidate[1] <= candidate[9]  ; candidate[0] <= candidate[8] ;
				end
			end
			else begin 
				for (int j = 0 ; j < 40 ; j = j + 1) begin 
					candidate[j] <= candidate[j] ;
				end
			end
		end
	end
end

//---------------------------------------------------------------------
//      	update_candidate  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) update_candidate <= 0 ;
	else begin 
		if (curr_state == S_START_IMG) update_candidate <= 1 ; // 拔掉啊
		else if (save_mode == 0) begin 
			if (save_matrix_size == 0 && (curr_state == S_START_CONV || curr_state == S_OUT) && conv_count == 0 && exe_count == 1) update_candidate <= 1 ;
			else if (save_matrix_size == 1 && (curr_state == S_START_CONV || curr_state == S_OUT) && conv_count == 0 && (exe_count == 1 || exe_count == 2)) update_candidate <= 1 ;
			else if (save_matrix_size == 2 && (curr_state == S_START_CONV || curr_state == S_OUT) && conv_count == 0 && exe_count >= 1) update_candidate <= 1 ;
			else update_candidate <= 0 ;
		end
		else if (save_mode == 1) begin 
			if (curr_state == S_START_CONV) begin 
				if (save_matrix_size == 0 && conv_count == 0 && exe_count == 1) update_candidate <= 1 ;
				else if (save_matrix_size == 1 && conv_count == 0 && (exe_count == 1 || exe_count == 2)) update_candidate <= 1 ;
				else if (save_matrix_size == 2 && conv_count == 0 && exe_count >= 1) update_candidate <= 1 ;
				else update_candidate <= 0 ;
			end
			else if (curr_state == S_OUT) begin 
				if (save_matrix_size == 0 && conv_count == 0 && out_count == 1) update_candidate <= 1 ;
				else if (save_matrix_size == 1 && conv_count == 0 && (out_count == 1 || out_count == 2)) update_candidate <= 1 ;
				else if (save_matrix_size == 2 && conv_count == 0 && out_count >= 1 && out_count <= 4) update_candidate <= 1 ;
				else update_candidate <= 0 ;
			end
			else update_candidate <= 0 ;
		end
		else update_candidate <= 0 ;
	end
end



//---------------------------------------------------------------------
//      	line buffer  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 5 ; i = i + 1) begin 
			for (int j = 0 ; j < 40 ; j = j + 1) begin 
				line_buf[i][j] <= 0 ;
			end
		end	
	end
	else begin
		case (curr_state)
			S_FILL_BUF : begin 
				if (save_mode == 1) begin 
					line_buf[4] <= candidate ;
					for (int i = 0 ; i < 40 ; i = i + 1) begin 
						line_buf[3][i] <= 0 ;
						line_buf[2][i] <= 0 ;
						line_buf[1][i] <= 0 ;
						line_buf[0][i] <= 0 ;
					end
				end
				else begin 
					line_buf[4] <= candidate ;
					line_buf[3] <= line_buf[4] ;
					line_buf[2] <= line_buf[3] ;
					line_buf[1] <= line_buf[2] ;
					line_buf[0] <= line_buf[1] ;
				end
			end
			S_START_CONV, S_OUT : begin 
				if ( (conv_count == real_matrix_size - 5) && exe_count == 4) begin 
					line_buf[4] <= candidate ;
					line_buf[3] <= line_buf[4] ;
					line_buf[2] <= line_buf[3] ;
					line_buf[1] <= line_buf[2] ;
					line_buf[0] <= line_buf[1] ;
				end
				else begin
					line_buf[4] <= line_buf[4] ;
					line_buf[3] <= line_buf[3] ;
					line_buf[2] <= line_buf[2] ;
					line_buf[1] <= line_buf[1] ;
					line_buf[0] <= line_buf[0] ;
				end
			end
			default : begin 
				line_buf[4] <= line_buf[4] ;
				line_buf[3] <= line_buf[3] ;
				line_buf[2] <= line_buf[2] ;
				line_buf[1] <= line_buf[1] ;
				line_buf[0] <= line_buf[0] ;
			end
		endcase 
	end
end

//---------------------------------------------------------------------
//      conv_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		conv_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) conv_count <= 0 ;
		else if ((conv_count == real_matrix_size - 5) && exe_count == 4) conv_count <= 0 ;
		else if ((curr_state == S_START_CONV || curr_state == S_OUT) && exe_count == 4) conv_count <= conv_count + 1 ;
		else conv_count <= conv_count ;
	end
end

//---------------------------------------------------------------------
//      exe_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		exe_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) exe_count <= 0 ;
		else if (exe_count == 4) exe_count <= 0 ;
		else if (save_mode == 1 && (curr_state == S_START_CONV || curr_state == S_MAXPOOL || (curr_state == S_OUT && out_count >= 15))) exe_count <= exe_count + 1 ;
		else if (save_mode == 0 && (curr_state == S_START_CONV || curr_state == S_MAXPOOL || (curr_state == S_OUT)))exe_count <= exe_count + 1 ;
		else exe_count <= exe_count ;
	end
end

//---------------------------------------------------------------------
//      line_buf_full_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		line_buf_full_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) line_buf_full_count <= 0 ;
		else if (curr_state == S_FILL_BUF) line_buf_full_count <= line_buf_full_count + 1 ;
		else line_buf_full_count <= line_buf_full_count ;
	end
end

//---------------------------------------------------------------------
//      conv_out_reg  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		conv_out_reg <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) conv_out_reg <= 0 ;
		else if (exe_count == 4) conv_out_reg <= 0 ;
		else if (save_mode == 0 && (curr_state == S_START_CONV || curr_state == S_MAXPOOL || curr_state == S_OUT)) conv_out_reg <= conv_out_reg + mac_out ;
		else if (save_mode == 1 && out_count >= 15) conv_out_reg <= conv_out_reg + mac_out ;
		else conv_out_reg <= conv_out_reg ;
	end
end

//---------------------------------------------------------------------
//      feature_map  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 28 ; i= i + 1) feature_map[i] <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) begin 
			for (int i = 0 ; i < 28 ; i= i + 1) feature_map[i] <= 0 ;
		end
		else if (exe_count == 4) begin 
			if (max_pool_count == 0) feature_map[conv_count] <= conv_out_reg + mac_out ;
			else feature_map[conv_count] <= (conv_out_reg + mac_out > feature_map[conv_count]) ? conv_out_reg + mac_out : feature_map[conv_count] ;
		end
		else begin 
			for (int i = 0 ; i < 28 ; i= i + 1) feature_map[i] <= feature_map[i] ;
		end
	end
end

//---------------------------------------------------------------------
//      max_pool_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		max_pool_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) max_pool_count <= 0 ;
		else if ((curr_state == S_START_CONV || curr_state == S_OUT) && conv_count == real_matrix_size - 5 && exe_count == 4) max_pool_count <= max_pool_count + 1 ;
		else max_pool_count <= max_pool_count ;
	end
end

//---------------------------------------------------------------------
//      maxpool_result  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) maxpool_result <= 0 ;
	else begin 
		if (curr_state == S_MAXPOOL || (curr_state == S_OUT && max_pool_count == 0 && conv_count == 0 && exe_count == 0)) begin 
			maxpool_result[19:0]    <= (feature_map[0] > feature_map[1]) ? feature_map[0] : feature_map[1] ;
			maxpool_result[39:20]   <= (feature_map[2] > feature_map[3]) ? feature_map[2] : feature_map[3] ;
			maxpool_result[59:40]   <= (feature_map[4] > feature_map[5]) ? feature_map[4] : feature_map[5] ;
			maxpool_result[79:60]   <= (feature_map[6] > feature_map[7]) ? feature_map[6] : feature_map[7] ;
			maxpool_result[99:80]   <= (feature_map[8] > feature_map[9]) ? feature_map[8] : feature_map[9] ;
			maxpool_result[119:100] <= (feature_map[10] > feature_map[11]) ? feature_map[10] : feature_map[11] ;
			maxpool_result[139:120] <= (feature_map[12] > feature_map[13]) ? feature_map[12] : feature_map[13] ;
			maxpool_result[159:140] <= (feature_map[14] > feature_map[15]) ? feature_map[14] : feature_map[15] ;
			maxpool_result[179:160] <= (feature_map[16] > feature_map[17]) ? feature_map[16] : feature_map[17] ;
			maxpool_result[199:180] <= (feature_map[18] > feature_map[19]) ? feature_map[18] : feature_map[19] ;
			maxpool_result[219:200] <= (feature_map[20] > feature_map[21]) ? feature_map[20] : feature_map[21] ;
			maxpool_result[239:220] <= (feature_map[22] > feature_map[23]) ? feature_map[22] : feature_map[23] ;
			maxpool_result[259:240] <= (feature_map[24] > feature_map[25]) ? feature_map[24] : feature_map[25] ;
			maxpool_result[279:260] <= (feature_map[26] > feature_map[27]) ? feature_map[26] : feature_map[27] ;
		end
		else begin 
			maxpool_result <= maxpool_result ;
		end
	end
end




//---------------------------------------------------------------------
//      out_reg  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		out_reg <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) out_reg <= 0 ;
		else if (exe_count == 4) out_reg <= conv_out_reg + mac_out ;
		else out_reg <= out_reg ;
	end
end

//---------------------------------------------------------------------
//      out_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		out_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) out_count <= 0 ;
		else if (save_mode == 1 && out_count == 19) out_count <= 0 ;
		else if (save_matrix_size == 0 && save_mode == 0 && out_count == 39) out_count <= 0 ;
		else if (save_matrix_size == 1 && save_mode == 0 && out_count == 119) out_count <= 0 ;
		else if (save_matrix_size == 2 && save_mode == 0 && out_count == 279) out_count <= 0 ;
		else if (curr_state == S_OUT) out_count <= out_count + 1 ;
		else out_count <= 0 ;
	end
end

//---------------------------------------------------------------------
//      finish_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		finish_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) finish_count <= 0 ;
		else if (save_matrix_size == 0 && out_count == 39) finish_count <= finish_count + 1 ;
		else if (save_matrix_size == 1 && out_count == 119) finish_count <= finish_count + 1 ;
		else if (save_matrix_size == 2 && out_count == 279) finish_count <= finish_count + 1 ;
		else if (curr_state == S_OUT) finish_count <= finish_count ;
		else finish_count <= 0 ;
	end
end

//---------------------------------------------------------------------
//      padding_zero_count  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		padding_zero_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) padding_zero_count <= 0 ;
		else if (conv_count == real_matrix_size - 5 && exe_count == 4) padding_zero_count <= padding_zero_count + 1 ;
		else padding_zero_count <= padding_zero_count ;
	end
end


//---------------------------------------------------------------------
//      out_valid_out_value  
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		out_valid <= 0 ;
		out_value <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) begin 
			out_valid <= 0 ;
			out_value <= 0 ;
		end
		else if (curr_state == S_OUT) begin 
			if (save_mode == 1) begin 
				out_valid <= 1 ;
				out_value <= out_reg[out_count] ;
			end
			else begin 
				out_valid <= 1 ;
				out_value <= maxpool_result[out_count] ;
			end
		end
		else begin 
			out_valid <= 0 ;
			out_valid <= 0 ;
		end
	end
end


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//      																								   HARDWARE   
//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

reg signed [7:0]  img1, img2, img3, img4, img5 ;
reg signed [7:0]  ker1, ker2, ker3, ker4, ker5 ;

assign img1 = line_buf[0][conv_count + exe_count] ;
assign img2 = line_buf[1][conv_count + exe_count] ;
assign img3 = line_buf[2][conv_count + exe_count] ;
assign img4 = line_buf[3][conv_count + exe_count] ;
assign img5 = line_buf[4][conv_count + exe_count] ;
assign ker1 = kernel[0 + exe_count] ;
assign ker2 = kernel[5 + exe_count] ;
assign ker3 = kernel[10 + exe_count] ;
assign ker4 = kernel[15 + exe_count] ;
assign ker5 = kernel[20 + exe_count] ;

MAC_operation M0 (.img1(img1), .img2(img2), .img3(img3), .img4(img4), .img5(img5), .ker1(ker1), .ker2(ker2), .ker3(ker3), .ker4(ker4), .ker5(ker5), .out(mac_out)) ; 


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//      																									MEMORY   
//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MY_SRAM_2112X64 S0 (	.A0(sram_addr[0])   ,.A1(sram_addr[1])   ,.A2(sram_addr[2])   ,.A3(sram_addr[3])   ,.A4(sram_addr[4]),
						.A5(sram_addr[5])   ,.A6(sram_addr[6])   ,.A7(sram_addr[7])   ,.A8(sram_addr[8])   ,.A9(sram_addr[9]),
						.A10(sram_addr[10]) ,.A11(sram_addr[11]) ,                    
						.DO0(sram_out[0])   ,.DO1(sram_out[1])   ,.DO2(sram_out[2])   ,.DO3 (sram_out[3])  ,.DO4 (sram_out[4])  ,.DO5 (sram_out[5]),
						.DO6 (sram_out[6])  ,.DO7 (sram_out[7])  ,.DO8 (sram_out[8])  ,.DO9 (sram_out[9])  ,.DO10(sram_out[10]) ,.DO11(sram_out[11]) ,.DO12(sram_out[12]) ,.DO13(sram_out[13]) ,.DO14(sram_out[14]),
						.DO15(sram_out[15]) ,.DO16(sram_out[16]) ,.DO17(sram_out[17]) ,.DO18(sram_out[18]) ,.DO19(sram_out[19]) ,.DO20(sram_out[20]) ,.DO21(sram_out[21]) ,.DO22(sram_out[22]) ,.DO23(sram_out[23]),
						.DO24(sram_out[24]) ,.DO25(sram_out[25]) ,.DO26(sram_out[26]) ,.DO27(sram_out[27]) ,.DO28(sram_out[28]) ,.DO29(sram_out[29]) ,.DO30(sram_out[30]) ,.DO31(sram_out[31]) ,.DO32(sram_out[32]),
						.DO33(sram_out[33]) ,.DO34(sram_out[34]) ,.DO35(sram_out[35]) ,.DO36(sram_out[36]) ,.DO37(sram_out[37]) ,.DO38(sram_out[38]) ,.DO39(sram_out[39]) ,.DO40(sram_out[40]) ,.DO41(sram_out[41]),
						.DO42(sram_out[42]) ,.DO43(sram_out[43]) ,.DO44(sram_out[44]) ,.DO45(sram_out[45]) ,.DO46(sram_out[46]) ,.DO47(sram_out[47]) ,.DO48(sram_out[48]) ,.DO49(sram_out[49]) ,.DO50(sram_out[50]),
						.DO51(sram_out[51]) ,.DO52(sram_out[52]) ,.DO53(sram_out[53]) ,.DO54(sram_out[54]) ,.DO55(sram_out[55]) ,.DO56(sram_out[56]) ,.DO57(sram_out[57]) ,.DO58(sram_out[58]) ,.DO59(sram_out[59]),
						.DO60(sram_out[60]) ,.DO61(sram_out[61]) ,.DO62(sram_out[62]) ,.DO63(sram_out[63]) ,
						.DI0 (sram_in[0])   ,.DI1 (sram_in[1])   ,.DI2 (sram_in[2])   ,.DI3 (sram_in[3])   ,.DI4 (sram_in[4])   ,.DI5(sram_in[5]),
                        .DI6 (sram_in[6])   ,.DI7 (sram_in[7])   ,.DI8 (sram_in[8])   ,.DI9 (sram_in[9])   ,.DI10(sram_in[10])  ,.DI11(sram_in[11])  ,.DI12(sram_in[12])  ,.DI13(sram_in[13]), .DI14(sram_in[14]),
                        .DI15(sram_in[15])  ,.DI16(sram_in[16])  ,.DI17(sram_in[17])  ,.DI18(sram_in[18])  ,.DI19(sram_in[19])  ,.DI20(sram_in[20])  ,.DI21(sram_in[21])  ,.DI22(sram_in[22]),
                        .DI23(sram_in[23])  ,.DI24(sram_in[24])  ,.DI25(sram_in[25])  ,.DI26(sram_in[26])  ,.DI27(sram_in[27])  ,.DI28(sram_in[28])  ,.DI29(sram_in[29])  ,.DI30(sram_in[30]),
                        .DI31(sram_in[31])  ,.DI32(sram_in[32])  ,.DI33(sram_in[33])  ,.DI34(sram_in[34])  ,.DI35(sram_in[35])  ,.DI36(sram_in[36])  ,.DI37(sram_in[37])  ,.DI38(sram_in[38]),
                        .DI39(sram_in[39])  ,.DI40(sram_in[40])  ,.DI41(sram_in[41])  ,.DI42(sram_in[42])  ,.DI43(sram_in[43])  ,.DI44(sram_in[44])  ,.DI45(sram_in[45])  ,.DI46(sram_in[46]),
                        .DI47(sram_in[47])  ,.DI48(sram_in[48])  ,.DI49(sram_in[49])  ,.DI50(sram_in[50])  ,.DI51(sram_in[51])  ,.DI52(sram_in[52])  ,.DI53(sram_in[53])  ,.DI54(sram_in[54]),
                        .DI55(sram_in[55])  ,.DI56(sram_in[56])  ,.DI57(sram_in[57])  ,.DI58(sram_in[58])  ,.DI59(sram_in[59])  ,.DI60(sram_in[60])  ,.DI61(sram_in[61])  ,.DI62(sram_in[62]),
                        .DI63(sram_in[63])  ,.CK(clk), .WEB(sram_WEB), .OE(1'b1) , .CS(sram_CS));          
endmodule





module MAC_operation (
	input signed [7:0] img1, 
	input signed [7:0] ker1,
	input signed [7:0] img2, 
	input signed [7:0] ker2,
	input signed [7:0] img3, 
	input signed [7:0] ker3,
	input signed [7:0] img4, 
	input signed [7:0] ker4,
	input signed [7:0] img5, 
	input signed [7:0] ker5,
	output signed [19:0] out
	) ;
 
 wire signed [15:0] partial0 ;
 wire signed [15:0] partial1 ;
 wire signed [15:0] partial2 ;
 wire signed [15:0] partial3 ;
 wire signed [15:0] partial4 ;
 wire signed [19:0] partial_out[0:3] ;
 wire carry[0:4] ;
 
 assign partial0 = img1 * ker1 ;
 assign partial1 = img2 * ker2 ;
 assign partial2 = img3 * ker3 ;
 assign partial3 = img4 * ker4 ;
 assign partial4 = img5 * ker5 ;
 assign partial_out[0] = partial0 + partial1 ;
 assign partial_out[1] = partial_out[0] + partial2 ;
 assign partial_out[2] = partial_out[1] + partial3 ;
 assign out = partial_out[2] + partial4 ;
 
 
 // DW02_mult #(8, 8) M1(.A(img1),.B(ker1),.TC(1'd1),.PRODUCT(partial0));
 // DW02_mult #(8, 8) M2(.A(img2),.B(ker2),.TC(1'd1),.PRODUCT(partial1));
 // DW02_mult #(8, 8) M3(.A(img3),.B(ker3),.TC(1'd1),.PRODUCT(partial2));
 // DW02_mult #(8, 8) M4(.A(img4),.B(ker4),.TC(1'd1),.PRODUCT(partial3));
 // DW02_mult #(8, 8) M5(.A(img5),.B(ker5),.TC(1'd1),.PRODUCT(partial4));
 
 // DW01_add  #(20)   A1(.A({ {4{partial0[15]}} ,partial0}), .B({ {4{partial1[15]}} ,partial1}), .CI(1'b0), .SUM(partial_out[0]), .CO(carry[0])) ;
 // DW01_add  #(20)   A2(.A({ {4{partial2[15]}} ,partial2}), .B(partial_out[0]),.CI(carry[0]),.SUM(partial_out[1]), .CO(carry[1])) ;
 // DW01_add  #(20)   A3(.A({ {4{partial3[15]}} ,partial3}), .B(partial_out[1]),.CI(carry[1]),.SUM(partial_out[2]), .CO(carry[2])) ;
 // DW01_add  #(20)   A4(.A({ {4{partial4[15]}} ,partial4}), .B(partial_out[2]),.CI(carry[2]),.SUM(partial_out[3]), .CO(carry[3])) ;
 
 // assign out = (carry[3] == 1) ? partial_out[3] : partial_out[3] - 1 ;
 
endmodule
 
 
 
 