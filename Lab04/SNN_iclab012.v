//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network 
//   Author     		: Jia-Yu Lee (maggie8905121@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################







module SNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER & integer
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
parameter IDLE = 0, CONV = 1, IMG1_COM = 2, IMG2_COM = 3 ;

integer i ;

//---------------------------------------------------------------------
//   I/O port 
//---------------------------------------------------------------------
input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   wire & reg  
//---------------------------------------------------------------------
reg  [1:0]row, col ;
reg  [7:0]global_count ;
reg  [7:0]global_count2 ;

reg  [inst_sig_width+inst_exp_width:0] img_row1 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] img_row2 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] img_row3 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] img_row4 [0:3] ;
									   
reg  [inst_sig_width+inst_exp_width:0] kernel_save1 [0:8] ;
reg  [inst_sig_width+inst_exp_width:0] kernel_save2 [0:8] ;
reg  [inst_sig_width+inst_exp_width:0] kernel_save3 [0:8] ;
									   
reg  [inst_sig_width+inst_exp_width:0] weight_save [0:3] ;
reg  [1:0] opt_save ; 

reg  [inst_sig_width+inst_exp_width:0] shift_img_reg1 [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] shift_img_reg2 [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] shift_img_reg3 [0:2] ;

reg  [inst_sig_width+inst_exp_width:0] final_chosen_pixel [0:2] ;
wire [inst_sig_width+inst_exp_width:0] dp3_out [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] dp3 [0:2] ;

reg  [inst_sig_width+inst_exp_width:0] feature_map [0:3][0:3] ;
wire [inst_sig_width+inst_exp_width:0] sum3_out ;
wire [inst_sig_width+inst_exp_width:0] add_out  ;

reg  [inst_sig_width+inst_exp_width:0] max_pool [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] cmp1, cmp2, big_one, small_one ;

reg  [inst_sig_width+inst_exp_width:0] fully_flattern [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] fully_add_out ;

reg  [inst_sig_width+inst_exp_width:0] norm_max, norm_min ;
reg  [inst_sig_width+inst_exp_width:0] cmp3, cmp4, big_o, small_o ;
reg  [inst_sig_width+inst_exp_width:0] norm_nomi, norm_domi ;
wire [inst_sig_width+inst_exp_width:0] norm_out ;
reg  [inst_sig_width+inst_exp_width:0] norm ;
reg [inst_sig_width+inst_exp_width:0] div_nomi, div_domi ; 

wire [inst_sig_width+inst_exp_width:0] exp_out ;
reg  [inst_sig_width+inst_exp_width:0] exp [0:3] ;

reg [inst_sig_width+inst_exp_width:0] recip_in ;
wire [inst_sig_width+inst_exp_width:0] recip_out ;
reg [inst_sig_width+inst_exp_width:0] recip [0:3] ; 

reg [inst_sig_width+inst_exp_width:0] add1, add2, add3, add4 ;
wire [inst_sig_width+inst_exp_width:0] add_out1, add_out2 ; 

reg [inst_sig_width+inst_exp_width:0] one_plus_exp ; 
reg [inst_sig_width+inst_exp_width:0] exp_plus_exp, exp_minus_exp ; 

reg [inst_sig_width+inst_exp_width:0] tanh_or_sigmoid [0:3] ;

reg [inst_sig_width+inst_exp_width:0] encoding_vec [0:3] ;



//---------------------------------------------------------------------
//   FSM 
//---------------------------------------------------------------------
reg [1:0] curr_state, next_state ;

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) curr_state <= IDLE ;
	else curr_state <= next_state ;
end


always @ (*) begin 
	case (curr_state)
		IDLE : begin 
			if (in_valid) next_state = CONV ;
			else next_state = IDLE ;
		end
		CONV : begin 
			if (global_count == 44) next_state = IMG1_COM ;
			else next_state = CONV ;
		end
		IMG1_COM : begin 
			if (global_count2 == 27) next_state = IMG2_COM ;
			else next_state = IMG1_COM ;
		end
		IMG2_COM : begin 
			if (global_count2 == 28) next_state = IDLE ;
			else next_state = IMG2_COM ;
		end
		default : next_state = IDLE ;
	endcase
end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//   																													D-Flip Flop  
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------
//   global_count  
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		global_count <= 0 ;
	end
	else begin 
		if (curr_state == IMG1_COM && global_count == 57) global_count <= 10 ;
		else if (in_valid || curr_state == CONV || curr_state == IMG1_COM || curr_state == IMG2_COM) global_count <= global_count + 1 ;
		else global_count <= 0 ;
	end
end

//---------------------------------------------------------------------
//   global_count2 
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		global_count2 <= 0 ;
	end
	else begin
		if (curr_state == IMG1_COM && global_count2 == 27) global_count2 <= 0 ;
		else if (curr_state == IMG1_COM || (curr_state == IMG2_COM && global_count >= 45)) global_count2 <= global_count2 + 1 ;
		else global_count2 <= 0 ;
	end
end

//---------------------------------------------------------------------
//   row  
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		row <= 0 ;
	end
	else begin 
		if (curr_state == IDLE) row <= 0 ;
		else if (col == 3) row <= row + 1 ;
		else row <= row ;
	end
end

//---------------------------------------------------------------------
//   col  
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		col <= 0 ;
	end
	else begin 
		if (global_count >= 8) col <= col + 1 ;
		else col <= 0 ;
	end
end

//---------------------------------------------------------------------
//   save image_row 
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			img_row1[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid && global_count[3:0] < 4) begin 
			img_row1[3] <= Img ;
			img_row1[2] <= img_row1[3] ;
			img_row1[1] <= img_row1[2] ;
			img_row1[0] <= img_row1[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				img_row1[i] <= img_row1[i] ;
			end

		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			img_row2[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid && global_count[3:0] >= 4 && global_count[3:0] < 8) begin 
			img_row2[3] <= Img ;
			img_row2[2] <= img_row2[3] ;
			img_row2[1] <= img_row2[2] ;
			img_row2[0] <= img_row2[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				img_row2[i] <= img_row2[i] ;
			end

		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			img_row3[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid &&  global_count[3:0] >= 8 && global_count[3:0] < 12) begin 
			img_row3[3] <= Img ;
			img_row3[2] <= img_row3[3] ;
			img_row3[1] <= img_row3[2] ;
			img_row3[0] <= img_row3[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				img_row3[i] <= img_row3[i] ;
			end

		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			img_row4[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid && global_count[3:0] >= 12 && global_count[3:0] < 16) begin 
			img_row4[3] <= Img ;
			img_row4[2] <= img_row4[3] ;
			img_row4[1] <= img_row4[2] ;
			img_row4[0] <= img_row4[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				img_row4[i] <= img_row4[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   save kernel    
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			kernel_save1[i] <= 0 ;
		end
	end
	else begin 
		if (global_count < 9) begin 
			kernel_save1[8] <= Kernel ;
			kernel_save1[7] <= kernel_save1[8] ;
			kernel_save1[6] <= kernel_save1[7] ;
			kernel_save1[5] <= kernel_save1[6] ;
			kernel_save1[4] <= kernel_save1[5] ;
			kernel_save1[3] <= kernel_save1[4] ;
			kernel_save1[2] <= kernel_save1[3] ;
			kernel_save1[1] <= kernel_save1[2] ;
			kernel_save1[0] <= kernel_save1[1] ;
		end
		else begin 
			for (i = 0 ; i < 9 ; i = i + 1) begin 
				kernel_save1[i] <= kernel_save1[i] ;
			end
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			kernel_save2[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid && curr_state == CONV && global_count >= 9 && global_count < 18) begin 
			kernel_save2[8] <= Kernel ;
			kernel_save2[7] <= kernel_save2[8] ;
			kernel_save2[6] <= kernel_save2[7] ;
			kernel_save2[5] <= kernel_save2[6] ;
			kernel_save2[4] <= kernel_save2[5] ;
			kernel_save2[3] <= kernel_save2[4] ;
			kernel_save2[2] <= kernel_save2[3] ;
			kernel_save2[1] <= kernel_save2[2] ;
			kernel_save2[0] <= kernel_save2[1] ;
		end
		else begin 
			for (i = 0 ; i < 9 ; i = i + 1) begin 
				kernel_save2[i] <= kernel_save2[i] ;
			end
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			kernel_save3[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid && curr_state == CONV && global_count >= 18 && global_count < 27) begin 
			kernel_save3[8] <= Kernel ;
			kernel_save3[7] <= kernel_save3[8] ;
			kernel_save3[6] <= kernel_save3[7] ;
			kernel_save3[5] <= kernel_save3[6] ;
			kernel_save3[4] <= kernel_save3[5] ;
			kernel_save3[3] <= kernel_save3[4] ;
			kernel_save3[2] <= kernel_save3[3] ;
			kernel_save3[1] <= kernel_save3[2] ;
			kernel_save3[0] <= kernel_save3[1] ;
		end
		else begin 
			for (i = 0 ; i < 9 ; i = i + 1) begin 
				kernel_save3[i] <= kernel_save3[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   save weight   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			weight_save[i] <= 0 ;
		end
	end
	else begin 
		if (global_count < 4) begin 
			weight_save[3] <= Weight ;
			weight_save[2] <= weight_save[3] ;
			weight_save[1] <= weight_save[2] ;
			weight_save[0] <= weight_save[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				weight_save[i] <= weight_save[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   save opt   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		opt_save <= 0 ;
	end
	else begin 
		if (global_count < 1) begin 
			opt_save <= Opt ;
		end
		else begin 
			opt_save <= opt_save ;
		end
	end
end


//---------------------------------------------------------------------
//   cal_dp3   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 3 ; i = i + 1) begin 
			shift_img_reg1[i] <= 0 ;
			shift_img_reg2[i] <= 0 ;
			shift_img_reg3[i] <= 0 ;
		end
	end
	else begin 
		if (global_count >= 8) begin 
			shift_img_reg1[2] <= final_chosen_pixel[0] ;
			shift_img_reg2[2] <= final_chosen_pixel[1];
			shift_img_reg3[2] <= final_chosen_pixel[2];
			shift_img_reg1[1] <= shift_img_reg1[2] ;
			shift_img_reg2[1] <= shift_img_reg2[2] ;
			shift_img_reg3[1] <= shift_img_reg3[2] ;
			shift_img_reg1[0] <= shift_img_reg1[1] ;
			shift_img_reg2[0] <= shift_img_reg2[1] ;
			shift_img_reg3[0] <= shift_img_reg3[1] ;
		end
		else begin 
			for (i = 0 ; i < 3 ; i = i + 1) begin 
				shift_img_reg1[i] <= shift_img_reg1[i] ;
				shift_img_reg2[i] <= shift_img_reg2[i] ;
				shift_img_reg3[i] <= shift_img_reg3[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   dp3   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 3 ; i = i + 1) begin 
			dp3[i] <= 0 ;
		end
	end
	else begin 
		dp3[0] <= dp3_out[0] ;
		dp3[1] <= dp3_out[1] ;
		dp3[2] <= dp3_out[2] ;
	end
end


//---------------------------------------------------------------------
//   feature_map   
//---------------------------------------------------------------------

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[0][3] <= 0 ;
	end
	else begin 
		if (global_count == 45 || global_count <= 10) feature_map[0][3] <= 0 ;
		else if (col == 3 && row == 0) feature_map[0][3] <= add_out ;
		else feature_map[0][3] <= feature_map[0][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[1][0] <= 0 ;
	end
	else begin 
		if (global_count == 45 || global_count <= 10) feature_map[1][0] <= 0 ;
		else if (col == 0 && row == 1) feature_map[1][0] <= add_out ;
		else feature_map[1][0] <= feature_map[1][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[1][1] <= 0 ;
	end
	else begin 
		if (global_count == 47 || global_count <= 10) feature_map[1][1] <= 0 ;
		else if (col == 1 && row == 1) feature_map[1][1] <= add_out ;
		else feature_map[1][1] <= feature_map[1][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[1][2] <= 0 ;
	end
	else begin 
		if (global_count == 47 || global_count <= 10) feature_map[1][2] <= 0 ;
		else if (col == 2 && row == 1) feature_map[1][2] <= add_out ;
		else feature_map[1][2] <= feature_map[1][2] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[1][3] <= 0 ;
	end
	else begin 
		if (global_count == 48 || global_count <= 10) feature_map[1][3] <= 0 ;
		else if (col == 3 && row == 1) feature_map[1][3] <= add_out ;
		else feature_map[1][3] <= feature_map[1][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[2][0] <= 0 ;
	end
	else begin 
		if (global_count == 49 || global_count <= 10) feature_map[2][0] <= 0 ;
		else if (col == 0 && row == 2) feature_map[2][0] <= add_out ;
		else feature_map[2][0] <= feature_map[2][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[2][1] <= 0 ;
	end
	else begin 
		if (global_count == 50 || global_count <= 10) feature_map[2][1] <= 0 ;
		else if (col == 1 && row == 2) feature_map[2][1] <= add_out ;
		else feature_map[2][1] <= feature_map[2][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[2][2] <= 0 ;
	end
	else begin 
		if (global_count == 51 || global_count <= 10) feature_map[2][2] <= 0 ;
		else if (col == 2 && row == 2) feature_map[2][2] <= add_out ;
		else feature_map[2][2] <= feature_map[2][2] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[2][3] <= 0 ;
	end
	else begin 
		if (global_count == 53 || global_count <= 10) feature_map[2][3] <= 0 ;
		else if (col == 3 && row == 2) feature_map[2][3] <= add_out ;
		else feature_map[2][3] <= feature_map[2][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[3][0] <= 0 ;
	end
	else begin 
		if (global_count == 53 || global_count <= 10) feature_map[3][0] <= 0 ;
		else if (col == 0 && row == 3) feature_map[3][0] <= add_out ;
		else feature_map[3][0] <= feature_map[3][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[3][1] <= 0 ;
	end
	else begin 
		if (global_count == 55 || global_count <= 10) feature_map[3][1] <= 0 ;
		else if (col == 1 && row == 3) feature_map[3][1] <= add_out ;
		else feature_map[3][1] <= feature_map[3][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[3][2] <= 0 ;
	end
	else begin 
		if (global_count == 55 || global_count <= 10) feature_map[3][2] <= 0 ;
		else if (col == 2 && row == 3) feature_map[3][2] <= add_out ;
		else feature_map[3][2] <= feature_map[3][2] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[3][3] <= 0 ;
	end
	else begin 
		if (global_count == 56 || global_count <= 10) feature_map[3][3] <= 0 ;
		else if (col == 3 && row == 3) feature_map[3][3] <= add_out ;
		else feature_map[3][3] <= feature_map[3][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[0][0] <= 0 ;
	end
	else begin 
		if (global_count == 57 || global_count <= 10) feature_map[0][0] <= 0 ;
		else if (col == 0 && row == 0) feature_map[0][0] <= add_out ;
		else feature_map[0][0] <= feature_map[0][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[0][1] <= 0 ;
	end
	else begin 
		if (global_count2 == 13 || global_count <= 10) feature_map[0][1] <= 0 ;
		else if (col == 1 && row == 0) feature_map[0][1] <= add_out ;
		else feature_map[0][1] <= feature_map[0][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[0][2] <= 0 ;
	end
	else begin 
		if (global_count2 == 14 || (curr_state == CONV && global_count <= 10)) feature_map[0][2] <= 0 ;
		else if (col == 2 && row == 0) feature_map[0][2] <= add_out ;
		else feature_map[0][2] <= feature_map[0][2] ;
	end
end

//---------------------------------------------------------------------
//   max_pool   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 3 ; i = i + 1) begin 
			max_pool[i] <= 0 ;
		end
	end
	else begin 
		if (global_count2 == 0 || global_count2 == 3 || global_count2 == 4) begin 
			max_pool[0] <= big_one ;
			max_pool[1] <= max_pool[1] ;
			max_pool[2] <= max_pool[2] ;
			max_pool[3] <= max_pool[3] ;
		end
		else if (global_count2 == 2 || global_count2 == 5 || global_count2 == 6) begin 
			max_pool[0] <= max_pool[0] ;
			max_pool[1] <= big_one ;
			max_pool[2] <= max_pool[2] ;
			max_pool[3] <= max_pool[3] ;
		end
		else if (global_count2 == 8 || global_count2 == 11 || global_count2 == 12) begin 
			max_pool[0] <= max_pool[0] ;
			max_pool[1] <= max_pool[1] ;
			max_pool[2] <= big_one ;
			max_pool[3] <= max_pool[3] ;
		end
		else if (global_count2 == 10 || global_count2 == 13 || global_count2 == 14) begin 
			max_pool[0] <= max_pool[0] ;
			max_pool[1] <= max_pool[1] ;
			max_pool[2] <= max_pool[2] ;
			max_pool[3] <= big_one ;
		end
		else begin 
			max_pool[0] <= max_pool[0] ;
			max_pool[1] <= max_pool[1] ;
			max_pool[2] <= max_pool[2] ;
			max_pool[3] <= max_pool[3] ;
		end
	end
end

//---------------------------------------------------------------------
//   fully_connected   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		fully_flattern[0] <= 0 ;
	end
	else begin 
		if (global_count2 == 0) fully_flattern[0] <= 0 ;
		else if (global_count2 == 5 || global_count2 == 7) fully_flattern[0] <= fully_add_out ;
		else fully_flattern[0] <= fully_flattern[0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		fully_flattern[1] <= 0 ;
	end
	else begin 
		if (global_count2 == 0) fully_flattern[1] <= 0 ;
		else if (global_count2 == 6 || global_count2 == 8) fully_flattern[1] <= fully_add_out ;
		else fully_flattern[1] <= fully_flattern[1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		fully_flattern[2] <= 0 ;
	end
	else begin 
		if (global_count2 == 0) fully_flattern[2] <= 0 ;
		else if (global_count2 == 13 || global_count2 == 15) fully_flattern[2] <= fully_add_out ;
		else fully_flattern[2] <= fully_flattern[2] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		fully_flattern[3] <= 0 ;
	end
	else begin 
		if (global_count2 == 0) fully_flattern[3] <= 0 ;
		else if (global_count2 == 14 || global_count2 == 16) fully_flattern[3] <= fully_add_out ;
		else fully_flattern[3] <= fully_flattern[3] ;
	end
end


//---------------------------------------------------------------------
//   norm_max   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		norm_max <= 0 ;
	end
	else begin 
		if (global_count2 == 9 || global_count2 == 16 || global_count2 == 17) norm_max <= big_one ;
		else norm_max <= norm_max ;
	end
end

//---------------------------------------------------------------------
//   norm_min   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		norm_min <= 0 ;
	end
	else begin 
		if (global_count2 == 9) norm_min <= small_one ;
		else if (global_count2 == 16 || global_count2 == 17) norm_min <= small_o ;
		else norm_min <= norm_min ;
	end
end

//---------------------------------------------------------------------
//   norm_domi   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		norm_domi <= 1 ;
	end
	else begin 
		if (global_count2 == 18) norm_domi <= fully_add_out ;
		else norm_domi <= norm_domi ;
	end
end

//---------------------------------------------------------------------
//   norm_nomi   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		norm_nomi <= 0 ;
	end
	else begin 
		if (global_count2 == 18) norm_nomi <= add_out1 ;
		else norm_nomi <= fully_add_out ;
	end
end

//---------------------------------------------------------------------
//   norm   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		norm <= 0 ;
	end
	else begin 
		norm <= norm_out ;
	end
end

//---------------------------------------------------------------------
//   exp   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i +1) begin 
			exp[i] <= 0 ;
		end
	end
	else begin 
		if ((global_count2 >= 20 && global_count2 < 24)) begin 
			exp[3] <= exp_out ;
			exp[2] <= exp[3] ;
			exp[1] <= exp[2] ;
			exp[0] <= exp[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i +1) begin 
				exp[i] <= exp[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   recip   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i +1) begin 
			recip[i] <= 0 ;
		end
	end
	else begin 
		if ((global_count2 >= 21 && global_count2 < 25)) begin 
			recip[3] <= recip_out ;
			recip[2] <= recip[3] ;
			recip[1] <= recip[2] ;
			recip[0] <= recip[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i +1) begin 
				recip[i] <= recip[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   one_plus_exp   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		one_plus_exp <= 0 ;
	end
	else begin 
		one_plus_exp <= add_out1 ;
	end
end

//---------------------------------------------------------------------
//   exp_plus_exp   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		exp_plus_exp <= 0 ;
	end
	else begin 
		exp_plus_exp <= add_out2 ;
	end
end

//---------------------------------------------------------------------
//   exp_minus_exp   
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		exp_minus_exp <= 0 ;
	end
	else begin 
		exp_minus_exp <= fully_add_out ;
	end
end

//---------------------------------------------------------------------
//   tanh_or_sigmoid
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i +1) begin 
			tanh_or_sigmoid[i] <= 0 ;
		end
	end
	else begin 
		if ((global_count2 >= 23 && global_count2 < 27)) begin 
			tanh_or_sigmoid[3] <= norm_out ;
			tanh_or_sigmoid[2] <= tanh_or_sigmoid[3] ;
			tanh_or_sigmoid[1] <= tanh_or_sigmoid[2] ;
			tanh_or_sigmoid[0] <= tanh_or_sigmoid[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i +1) begin 
				tanh_or_sigmoid[i] <= tanh_or_sigmoid[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   encoding_vec
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i +1) begin 
			encoding_vec[i] <= 0 ;
		end
	end
	else begin
		if (curr_state == IDLE) begin 
			for (i = 0 ; i < 4 ; i = i +1) begin 
				encoding_vec[i] <= 0 ;
			end
		end
		else if (curr_state == IMG1_COM && global_count2 == 27) begin 
			encoding_vec[3] <= tanh_or_sigmoid[3] ;
			encoding_vec[2] <= tanh_or_sigmoid[2] ;
			encoding_vec[1] <= tanh_or_sigmoid[1] ;
			encoding_vec[0] <= tanh_or_sigmoid[0] ;
		end
		else if (curr_state == IMG2_COM && global_count2 == 27) begin 
			encoding_vec[3] <= (fully_add_out[31] == 1) ? {~fully_add_out[31], fully_add_out[30:0]} : fully_add_out ;
			encoding_vec[2] <= (add_out2[31] == 1) ? {~add_out2[31], add_out2[30:0]} : add_out2 ;
			encoding_vec[1] <= (sum3_out[31] == 1) ? {~sum3_out[31], sum3_out[30:0]} : sum3_out ;
			encoding_vec[0] <= (add_out1[31] == 1) ? {~add_out1[31], add_out1[30:0]} : add_out1 ;
		end
		else begin
			for (i = 0 ; i < 4 ; i = i +1) begin 
				encoding_vec[i] <= encoding_vec[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   out & out_valid  
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		out_valid <= 0 ;
		out <= 0 ;
	end
	else begin 
		if (global_count2 == 28) begin 
			out_valid <= 1 ;
			out <= fully_add_out ;
		end
		else begin 
			out_valid <= 0 ;
			out <= 0 ;
		end
	end
end


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//   																										  Hardware_signal  
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
reg  [inst_sig_width+inst_exp_width:0] chosen_pixel  [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] cal_dp3_1     [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] cal_dp3_2     [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] cal_dp3_3     [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] multi_in      [0:1] ;
reg  [inst_sig_width+inst_exp_width:0] multi_out          ;
reg  [inst_sig_width+inst_exp_width:0] fully_add_in  [0:1] ; 
reg  [inst_sig_width+inst_exp_width:0] dp3_in        [0:8] ;
reg  [inst_sig_width+inst_exp_width:0] sum3_in       [0:2] ;




always @ (*) begin 
	if (col == 0) begin 
		chosen_pixel[0] = img_row1[0] ;
		chosen_pixel[1] = img_row2[0] ;
		chosen_pixel[2] = img_row3[0] ;
		chosen_pixel[3] = img_row4[0] ;
	end
	else if (col == 1) begin 
		chosen_pixel[0] = img_row1[1] ;
		chosen_pixel[1] = img_row2[1] ;
		chosen_pixel[2] = img_row3[1] ;
		chosen_pixel[3] = img_row4[1] ;
	end
	else if (col == 2) begin 
		chosen_pixel[0] = img_row1[2] ;
		chosen_pixel[1] = img_row2[2] ;
		chosen_pixel[2] = img_row3[2] ;
		chosen_pixel[3] = img_row4[2] ;
	end
	else begin 
		chosen_pixel[0] = img_row1[3] ;
		chosen_pixel[1] = img_row2[3] ;
		chosen_pixel[2] = img_row3[3] ;
		chosen_pixel[3] = img_row4[3] ;
	end
end

always @ (*) begin 
	case (opt_save)
		0, 2 : begin 
			if (row == 0) begin 
				final_chosen_pixel[0] = chosen_pixel[0] ;
				final_chosen_pixel[1] = chosen_pixel[0] ;
				final_chosen_pixel[2] = chosen_pixel[1] ;
			end
			else if (row == 1) begin 
				final_chosen_pixel[0] = chosen_pixel[0] ;
				final_chosen_pixel[1] = chosen_pixel[1] ;
				final_chosen_pixel[2] = chosen_pixel[2] ;
			end
			else if (row == 2) begin 
				final_chosen_pixel[0] = chosen_pixel[1] ;
				final_chosen_pixel[1] = chosen_pixel[2] ;
				final_chosen_pixel[2] = chosen_pixel[3] ;
			end
			else begin 
				final_chosen_pixel[0] = chosen_pixel[2] ;
				final_chosen_pixel[1] = chosen_pixel[3] ;
				final_chosen_pixel[2] = chosen_pixel[3] ;
			end
		end
		default : begin 
			if (row == 0) begin 
				final_chosen_pixel[0] = 32'b00000000000000000000000000000000 ;
				final_chosen_pixel[1] = chosen_pixel[0] ;
				final_chosen_pixel[2] = chosen_pixel[1] ;
			end
			else if (row == 1) begin 
				final_chosen_pixel[0] = chosen_pixel[0] ;
				final_chosen_pixel[1] = chosen_pixel[1] ;
				final_chosen_pixel[2] = chosen_pixel[2] ;
			end
			else if (row == 2) begin 
				final_chosen_pixel[0] = chosen_pixel[1] ;
				final_chosen_pixel[1] = chosen_pixel[2] ;
				final_chosen_pixel[2] = chosen_pixel[3] ;
			end
			else begin 
				final_chosen_pixel[0] = chosen_pixel[2] ;
				final_chosen_pixel[1] = chosen_pixel[3] ;
				final_chosen_pixel[2] = 32'b00000000000000000000000000000000 ;
			end
		end
	endcase 
end


always @ (*) begin 
	case (opt_save)
		0, 2 : begin 
			if (col == 2) begin 
				cal_dp3_1[0] = shift_img_reg1[1] ;
				cal_dp3_2[0] = shift_img_reg2[1] ;
				cal_dp3_3[0] = shift_img_reg3[1] ;
				cal_dp3_1[1] = shift_img_reg1[1] ;
				cal_dp3_2[1] = shift_img_reg2[1] ;
				cal_dp3_3[1] = shift_img_reg3[1] ;
				cal_dp3_1[2] = shift_img_reg1[2] ;
				cal_dp3_2[2] = shift_img_reg2[2] ;
				cal_dp3_3[2] = shift_img_reg3[2] ;
			end
			else if (col == 1) begin 
				cal_dp3_1[0] = shift_img_reg1[0] ;
				cal_dp3_2[0] = shift_img_reg2[0] ;
				cal_dp3_3[0] = shift_img_reg3[0] ;
				cal_dp3_1[1] = shift_img_reg1[1] ;
				cal_dp3_2[1] = shift_img_reg2[1] ;
				cal_dp3_3[1] = shift_img_reg3[1] ;
				cal_dp3_1[2] = shift_img_reg1[1] ;
				cal_dp3_2[2] = shift_img_reg2[1] ;
				cal_dp3_3[2] = shift_img_reg3[1] ;
			end
			else begin 
				cal_dp3_1[0] = shift_img_reg1[0] ;
				cal_dp3_2[0] = shift_img_reg2[0] ;
				cal_dp3_3[0] = shift_img_reg3[0] ;
				cal_dp3_1[1] = shift_img_reg1[1] ;
				cal_dp3_2[1] = shift_img_reg2[1] ;
				cal_dp3_3[1] = shift_img_reg3[1] ;
				cal_dp3_1[2] = shift_img_reg1[2] ;
				cal_dp3_2[2] = shift_img_reg2[2] ;
				cal_dp3_3[2] = shift_img_reg3[2] ;
			end
		end
		default : begin 
			if (col == 2) begin 
				cal_dp3_1[0] = 32'b00000000000000000000000000000000 ;
				cal_dp3_2[0] = 32'b00000000000000000000000000000000 ;
				cal_dp3_3[0] = 32'b00000000000000000000000000000000 ;
				cal_dp3_1[1] = shift_img_reg1[1] ;
				cal_dp3_2[1] = shift_img_reg2[1] ;
				cal_dp3_3[1] = shift_img_reg3[1] ;
				cal_dp3_1[2] = shift_img_reg1[2] ;
				cal_dp3_2[2] = shift_img_reg2[2] ;
				cal_dp3_3[2] = shift_img_reg3[2] ;
			end
			else if (col == 1) begin 
				cal_dp3_1[0] = shift_img_reg1[0] ;
				cal_dp3_2[0] = shift_img_reg2[0] ;
				cal_dp3_3[0] = shift_img_reg3[0] ;
				cal_dp3_1[1] = shift_img_reg1[1] ;
				cal_dp3_2[1] = shift_img_reg2[1] ;
				cal_dp3_3[1] = shift_img_reg3[1] ;
				cal_dp3_1[2] = 32'b00000000000000000000000000000000 ;
				cal_dp3_2[2] = 32'b00000000000000000000000000000000 ;
				cal_dp3_3[2] = 32'b00000000000000000000000000000000 ;
			end
			else begin 
				cal_dp3_1[0] = shift_img_reg1[0] ;
				cal_dp3_2[0] = shift_img_reg2[0] ;
				cal_dp3_3[0] = shift_img_reg3[0] ;
				cal_dp3_1[1] = shift_img_reg1[1] ;
				cal_dp3_2[1] = shift_img_reg2[1] ;
				cal_dp3_3[1] = shift_img_reg3[1] ;
				cal_dp3_1[2] = shift_img_reg1[2] ;
				cal_dp3_2[2] = shift_img_reg2[2] ;
				cal_dp3_3[2] = shift_img_reg3[2] ;
			end
		end
	endcase 
end

always @ (*) begin 
	if (global_count < 26) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			dp3_in[i] = kernel_save1[i] ;
		end
	end
	else if ((global_count >= 26 && global_count < 42)) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			dp3_in[i] = kernel_save2[i] ;
		end
	end
	else if ((global_count >= 42 && global_count < 58)) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			dp3_in[i] = kernel_save3[i] ;
		end
	end
	else begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			dp3_in[i] = 0 ;
		end
	end
end


always @ (*) begin 
	if (curr_state == IMG2_COM && global_count2 == 27) begin 
		sum3_in[0] = 32'b00000000000000000000000000000000 ;
		sum3_in[1] = tanh_or_sigmoid[1] ;
		sum3_in[2] = {~encoding_vec[1][31], encoding_vec[1][30:0]} ;
	end
	else begin 
		sum3_in[0] = dp3[0] ;
		sum3_in[1] = dp3[1] ;
		sum3_in[2] = dp3[2] ;
	end
end

always @ (*) begin 
	if (global_count2 == 0) begin 
		cmp1 = feature_map[0][3] ;
		cmp2 = feature_map[1][0] ;
	end
	else if (global_count2 == 2 ) begin 
		cmp1 = feature_map[1][1] ;
		cmp2 = feature_map[1][2] ;
	end
	else if (global_count2 == 3) begin 
		cmp1 = max_pool[0] ;
		cmp2 = feature_map[1][3] ;
	end
	else if (global_count2 == 4) begin 
		cmp1 = max_pool[0] ;
		cmp2 = feature_map[2][0] ;
	end
	else if (global_count2 == 5 ) begin 
		cmp1 = max_pool[1] ;
		cmp2 = feature_map[2][1] ;
	end
	else if (global_count2 == 6) begin 
		cmp1 = max_pool[1] ;
		cmp2 = feature_map[2][2] ;
	end
	else if (global_count2 == 8 ) begin 
		cmp1 = feature_map[2][3] ;
		cmp2 = feature_map[3][0] ;
	end
	else if (global_count2 == 9 ) begin 
		cmp1 = fully_flattern[0] ;
		cmp2 = fully_flattern[1] ;
	end 
	else if (global_count2 == 10 ) begin 
		cmp1 = feature_map[3][1] ;
		cmp2 = feature_map[3][2] ;
	end
	else if (global_count2 == 11) begin 
		cmp1 = max_pool[2] ;
		cmp2 = feature_map[3][3] ;
	end
	else if (global_count2 == 12 ) begin 
		cmp1 = max_pool[2] ;
		cmp2 = feature_map[0][0] ;
	end
	else if (global_count2 == 13) begin 
		cmp1 = max_pool[3] ;
		cmp2 = feature_map[0][1] ;
	end
	else if (global_count2 == 14) begin 
		cmp1 = max_pool[3] ;
		cmp2 = feature_map[0][2] ;
	end
	else if (global_count2 == 16) begin 
		cmp1 = fully_flattern[2] ;
		cmp2 = norm_max ;
	end
	else if (global_count2 == 17) begin 
		cmp1 = fully_flattern[3] ;
		cmp2 = norm_max ;
	end
	else begin 
		cmp1 = feature_map[0][2] ;
		cmp2 = feature_map[0][3] ;
	end
end

always @ (*) begin 
	if (global_count2 == 5) begin 
		multi_in[0] = max_pool[0] ;
		multi_in[1] = weight_save[0] ;
	end
	else if (global_count2 == 6) begin 
		multi_in[0] = max_pool[0] ;
		multi_in[1] = weight_save[1] ;
	end
	else if (global_count2 == 7) begin 
		multi_in[0] = max_pool[1] ;
		multi_in[1] = weight_save[2] ;
	end
	else if (global_count2 == 8) begin 
		multi_in[0] = max_pool[1] ;
		multi_in[1] = weight_save[3] ;
	end
	else if (global_count2 == 13) begin 
		multi_in[0] = max_pool[2] ;
		multi_in[1] = weight_save[0] ;
	end
	else if (global_count2 == 14) begin 
		multi_in[0] = max_pool[2] ;
		multi_in[1] = weight_save[1] ;
	end
	else if (global_count2 == 15) begin 
		multi_in[0] = max_pool[3] ;
		multi_in[1] = weight_save[2] ;
	end
	else if (global_count2 == 16) begin 
		multi_in[0] = max_pool[3] ;
		multi_in[1] = weight_save[3] ;
	end
	else begin 
		multi_in[0] = 0 ;
		multi_in[1] = 0 ;
	end
end

always @ (*) begin 
	if (global_count2 == 5) begin 
		fully_add_in[0] = fully_flattern[0] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 6) begin 
		fully_add_in[0] = fully_flattern[1] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 7) begin 
		fully_add_in[0] = fully_flattern[0] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 8) begin 
		fully_add_in[0] = fully_flattern[1] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 13) begin 
		fully_add_in[0] = fully_flattern[2] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 14) begin 
		fully_add_in[0] = fully_flattern[3] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 15) begin 
		fully_add_in[0] = fully_flattern[2] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 16) begin 
		fully_add_in[0] = fully_flattern[3] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 18) begin 
		fully_add_in[0] = norm_max ;
		fully_add_in[1] = {~norm_min[31], norm_min[30:0]} ;
	end
	else if (global_count2 == 19) begin 
		fully_add_in[0] = fully_flattern[1] ;
		fully_add_in[1] = {~norm_min[31], norm_min[30:0]} ;
	end
	else if (global_count2 == 20) begin 
		fully_add_in[0] = fully_flattern[2] ;
		fully_add_in[1] = {~norm_min[31], norm_min[30:0]} ;
	end
	else if (global_count2 == 21) begin 
		fully_add_in[0] = fully_flattern[3] ;
		fully_add_in[1] = {~norm_min[31], norm_min[30:0]} ;
	end
	else if ((global_count2 >= 22 && global_count2 < 25)) begin 
		fully_add_in[0] = exp[2] ;
		fully_add_in[1] = {~recip[3][31], recip[3][30:0]} ;
	end
	else if (global_count2 == 25) begin 
		fully_add_in[0] = exp[3] ;
		fully_add_in[1] = {~recip[3][31], recip[3][30:0]} ;
	end
	else if (global_count2 == 27) begin 
		fully_add_in[0] = tanh_or_sigmoid[3] ;
		fully_add_in[1] =  {~encoding_vec[3][31], encoding_vec[3][30:0]} ;
	end
	else if (global_count2 == 28) begin 
		fully_add_in[0] = encoding_vec[3] ;
		fully_add_in[1] = add_out2 ;
	end
	else begin 
		fully_add_in[0] = 0 ;
		fully_add_in[1] = 0 ;
	end
end


always @ (*) begin 
	if (global_count2 == 16) begin 
		cmp3 = norm_min ;
		cmp4 = fully_flattern[2] ;
	end
	else if (global_count2 == 17) begin 
		cmp3 = norm_min ;
		cmp4 = fully_flattern[3] ;
	end
	else begin 
		cmp3 = norm_min ;
		cmp4 = fully_flattern[2] ;
	end
end

always @ (*) begin 
	if ((global_count2 >= 19 && global_count2 < 23)) begin 
		div_nomi = norm_nomi ;
		div_domi = norm_domi ;
	end
	else if ((opt_save == 2 || opt_save == 3) && (global_count2 >= 23 && global_count2 < 27)) begin 
		div_nomi = exp_minus_exp ;
		div_domi = exp_plus_exp ;
	end
	else if ((opt_save == 0 || opt_save == 1) && (global_count2 >= 23 && global_count2 < 27)) begin 
		div_nomi = 32'b00111111100000000000000000000000 ;
		div_domi = one_plus_exp ;
	end
	else begin 
		div_nomi = 0 ;
		div_domi = 0 ;
	end
end


always @ (*) begin 
	if ((global_count2 >= 21 && global_count2 < 25)) begin 
		recip_in = exp[3] ;
	end
	else begin 
		recip_in = 1 ;
	end
end

always @ (*) begin 
	if (global_count2 == 18) begin 
		add1 = fully_flattern[0] ;
		add2 = {~norm_min[31], norm_min[30:0]} ;
	end
	else if ((global_count2 >= 22 && global_count2 < 26)) begin 
		add1 = 32'b00111111100000000000000000000000 ;
		add2 = recip[3] ;
	end
	else if (global_count2 == 27) begin 
		add1 = tanh_or_sigmoid[0] ;
		add2 = {~encoding_vec[0][31], encoding_vec[0][30:0]} ;
	end
	else if (global_count2 == 28) begin 
		add1 = encoding_vec[0] ;
		add2 = encoding_vec[1] ;
	end
	else begin 
		add1 = 0 ;
		add2 = 0 ;
	end
end

always @ (*) begin 
	if ((global_count2 >= 22 && global_count2 < 25) ) begin 
		add3 = exp[2] ;
		add4 = recip[3] ;
	end
	else if (global_count2 == 25) begin 
		add3 = exp[3] ;
		add4 = recip[3] ;
	end
	else if (global_count2 == 27) begin 
		add3 = tanh_or_sigmoid[2] ;
		add4 = {~encoding_vec[2][31], encoding_vec[2][30:0]} ;
	end
	else if (global_count2 == 28) begin 
		add3 = add_out1 ;
		add4 = encoding_vec[2] ;
	end
	else begin 
		add3 = 0 ;
		add4 = 0 ;
	end
end


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//   																											   Hardware  
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

seperate_dp3 U1 (.dp3_a(cal_dp3_1[0]), .dp3_b(dp3_in[0]), .dp3_c(cal_dp3_1[1]), .dp3_d(dp3_in[1]), .dp3_e(cal_dp3_1[2]), .dp3_f(dp3_in[2]), .rnd(3'b000), .dp3_out(dp3_out[0]));
seperate_dp3 U2 (.dp3_a(cal_dp3_2[0]), .dp3_b(dp3_in[3]), .dp3_c(cal_dp3_2[1]), .dp3_d(dp3_in[4]), .dp3_e(cal_dp3_2[2]), .dp3_f(dp3_in[5]), .rnd(3'b000), .dp3_out(dp3_out[1]));
seperate_dp3 U3 (.dp3_a(cal_dp3_3[0]), .dp3_b(dp3_in[6]), .dp3_c(cal_dp3_3[1]), .dp3_d(dp3_in[7]), .dp3_e(cal_dp3_3[2]), .dp3_f(dp3_in[8]), .rnd(3'b000), .dp3_out(dp3_out[2]));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U4 (.a(sum3_in[0]), .b(sum3_in[1]), .c(sum3_in[2]), .rnd(3'b000), .z(sum3_out), .status() ) ;
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U5 ( .a(feature_map[row][col]), .b(sum3_out), .rnd(3'b000), .z(add_out), .status() );
DW_fp_cmp  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U6 (.a(cmp1), .b(cmp2), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(small_one), .z1(big_one), .status0(), .status1() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U7  ( .a(multi_in[0]), .b(multi_in[1]), .rnd(3'b000), .z(multi_out), .status());
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U14 ( .a(fully_add_in[0]), .b(fully_add_in[1]), .rnd(3'b000), .z(fully_add_out), .status() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U8 (.a(cmp3), .b(cmp4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(small_o), .z1(big_o), .status0(), .status1() );
seperate_Divide U9 (.nominator(div_nomi), .dominator(div_domi), .rnd(3'b000), .div_out(norm_out)) ;
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U10 (.a(norm), .z(exp_out), .status() );
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance,0) U11 (.a(recip_in), .rnd(3'b000), .z(recip_out), .status() );
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U12 ( .a(add1), .b(add2), .rnd(3'b000), .z(add_out1), .status() );
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U13 ( .a(add3), .b(add4), .rnd(3'b000), .z(add_out2), .status() );
endmodule


module seperate_dp3(dp3_a, dp3_b, dp3_c, dp3_d, dp3_e, dp3_f, rnd, dp3_out);

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;

input  [2:0] rnd ;
input  [inst_sig_width+inst_exp_width:0] dp3_a, dp3_b, dp3_c, dp3_d, dp3_e, dp3_f ;
output [inst_sig_width+inst_exp_width:0] dp3_out ;

wire   [inst_sig_width+inst_exp_width:0] mult_out1, mult_out2, mult_out3;

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M0( .a(dp3_a), .b(dp3_b), .rnd(rnd), .z(mult_out1), .status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1( .a(dp3_c), .b(dp3_d), .rnd(rnd), .z(mult_out2), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2( .a(dp3_e), .b(dp3_f), .rnd(rnd), .z(mult_out3), .status() );
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S0( .a(mult_out1), .b(mult_out2), .c(mult_out3), .rnd(rnd), .z(dp3_out), .status());

// synopsys dc_script_begin
// set_implementation rtl M0
// set_implementation rtl M1
// set_implementation rtl M2
// set_implementation rtl S0
// synopsys dc_script_end

endmodule



module seperate_Divide(nominator, dominator, rnd, div_out);

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;

input  [2:0] rnd ;
input  [inst_sig_width+inst_exp_width:0] nominator, dominator ;
output [inst_sig_width+inst_exp_width:0] div_out ;

wire   [inst_sig_width+inst_exp_width:0] recip_out;


DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance,0) R0 (.a(dominator), .rnd(rnd), .z(recip_out), .status());
DW_fp_mult  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M0( .a(recip_out), .b(nominator), .rnd(rnd), .z(div_out), .status());

// synopsys dc_script_begin
// set_implementation rtl M0
// synopsys dc_script_end

endmodule