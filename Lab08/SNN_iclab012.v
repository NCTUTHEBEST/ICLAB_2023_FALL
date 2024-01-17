//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network
//   Author     		: Hsien-Chi Peng (jhpeng2012@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SNN(
    //Input Port
    clk,
    rst_n,
    cg_en,
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
//   PARAMETER
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
//   INPUTS & OUTPUTS
//---------------------------------------------------------------------
input rst_n, clk, in_valid;
input cg_en;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   wire & reg  
//---------------------------------------------------------------------
reg  [1:0]row, col ;
reg  [6:0]global_count ;
reg  [9:0]global_count2 ;

reg  [inst_sig_width+inst_exp_width:0] img_row1 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] img_row2 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] img_row3 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] img_row4 [0:3] ;
									   
reg  [inst_sig_width+inst_exp_width:0] kernel_save1 [0:8] ;
reg  [inst_sig_width+inst_exp_width:0] kernel_save2 [0:8] ;
reg  [inst_sig_width+inst_exp_width:0] kernel_save3 [0:8] ;
									   
reg  [inst_sig_width+inst_exp_width:0] weight_save [0:3] ;
reg  [1:0] opt_save ; 

reg  [inst_sig_width+inst_exp_width:0] shift_img_reg1 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] shift_img_reg2 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] shift_img_reg3 [0:3] ;

reg  [inst_sig_width+inst_exp_width:0] final_chosen_pixel [0:2] ;
wire [inst_sig_width+inst_exp_width:0] dp3_out [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] dp3 [0:2] ;

//---------------------------------------------------------------------
//   equalization   
//---------------------------------------------------------------------

reg  [inst_sig_width+inst_exp_width:0] e_img_row1 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] e_img_row2 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] e_img_row3 [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] e_img_row4 [0:3] ;

reg  [inst_sig_width+inst_exp_width:0] e_shift_img_reg1 [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] e_shift_img_reg2 [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] e_shift_img_reg3 [0:2] ;

reg  [inst_sig_width+inst_exp_width:0] e_final_chosen_pixel [0:2] ;
wire [inst_sig_width+inst_exp_width:0] e_sum3_out1, e_sum3_out2, e_sum3_out3 ;
wire [inst_sig_width+inst_exp_width:0] final_sum3_out  ;

reg  [inst_sig_width+inst_exp_width:0] e_div_nomi ;
//---------------------------------------------------------------------

reg  [inst_sig_width+inst_exp_width:0] feature_map [0:3][0:3] ;
reg  [inst_sig_width+inst_exp_width:0] top_feature_map [0:3][0:3] ;
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

// wire G_clock_state ;
// wire G_sleep_state = !(curr_state == IDLE || global_count == 44 || global_count2 == 35 || global_count2 == 36) ;
// GATED_OR GATED_gstate (.CLOCK(clk), .SLEEP_CTRL(G_sleep_state && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_state)) ;
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
			if (global_count2 == 35) next_state = IMG2_COM ;
			else next_state = IMG1_COM ;
		end
		IMG2_COM : begin 
			if (global_count2 == 990) next_state = IDLE ;
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
wire G_clock_gc ;
wire G_sleep_gc = (curr_state == IMG2_COM && global_count == 66) ;
GATED_OR GATED_gc (.CLOCK(clk), .SLEEP_CTRL(G_sleep_gc && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_gc)) ;
always @ (posedge G_clock_gc or negedge rst_n) begin 
	if (!rst_n) begin 
		global_count <= 0 ;
	end
	else begin
		if (curr_state == IMG2_COM && global_count == 66) global_count <= global_count ;
		else if (curr_state == IMG1_COM && global_count == 57) global_count <= 10 ;
		else if (in_valid || curr_state == CONV || curr_state == IMG1_COM || curr_state == IMG2_COM) global_count <= global_count + 1 ;
		else global_count <= 0 ;
	end
end

//---------------------------------------------------------------------
//   global_count2 
//---------------------------------------------------------------------
wire G_clock_gc2 ;
wire G_sleep_gc2 = (curr_state == CONV) ;
GATED_OR GATED_gc2 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_gc2 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_gc2)) ;
always @ (posedge G_clock_gc2 or negedge rst_n) begin 
	if (!rst_n) begin 
		global_count2 <= 0 ;
	end
	else begin
		if (curr_state == IMG1_COM && global_count2 == 35) global_count2 <= 0 ;
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
wire G_clock_col ;
wire G_sleep_col = !(global_count < 66) ;
GATED_OR GATED_gcol (.CLOCK(clk), .SLEEP_CTRL(G_sleep_col && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_col)) ;
always @ (posedge G_clock_col or negedge rst_n) begin 
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
wire G_clock_img_r1 ;
wire G_sleep_img_r1 = !(global_count[3:0] < 4) ;
GATED_OR GATED_imgr1 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_img_r1 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_img_r1)) ; 
always @ (posedge G_clock_img_r1 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			img_row1[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid) begin
			if (global_count[3:0] == 0) img_row1[0] <= Img ;
			else if (global_count[3:0] == 1) img_row1[1] <= Img ;
			else if (global_count[3:0] == 2) img_row1[2] <= Img ;
			else if (global_count[3:0] == 3) img_row1[3] <= Img ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				img_row1[i] <= img_row1[i] ;
			end
		end
	end
end

wire G_clock_img_r2 ;
wire G_sleep_img_r2 = !(global_count[3:0] < 8 && global_count[3:0] >= 4) ;
GATED_OR GATED_imgr2 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_img_r2 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_img_r2)) ; 
always @ (posedge G_clock_img_r2 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			img_row2[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid) begin 
			if (global_count[3:0] == 4) img_row2[0] <= Img ;
			else if (global_count[3:0] == 5) img_row2[1] <= Img ;
			else if (global_count[3:0] == 6) img_row2[2] <= Img ;
			else if (global_count[3:0] == 7) img_row2[3] <= Img ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				img_row2[i] <= img_row2[i] ;
			end

		end
	end
end

wire G_clock_img_r3 ;
wire G_sleep_img_r3 = !(global_count[3:0] < 12 && global_count[3:0] >= 8) ;
GATED_OR GATED_imgr3 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_img_r3 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_img_r3)) ; 
always @ (posedge G_clock_img_r3 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			img_row3[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid &&  global_count[3:0] >= 8 && global_count[3:0] < 12) begin 
			if (global_count[3:0] == 8) img_row3[0] <= Img ;
			else if (global_count[3:0] == 9) img_row3[1] <= Img ;
			else if (global_count[3:0] == 10) img_row3[2] <= Img ;
			else if (global_count[3:0] == 11) img_row3[3] <= Img ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				img_row3[i] <= img_row3[i] ;
			end

		end
	end
end

wire G_clock_img_r4 ;
wire G_sleep_img_r4 = !(global_count[3:0] >= 12) ;
GATED_OR GATED_imgr4 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_img_r4 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_img_r4)) ; 
always @ (posedge G_clock_img_r4 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			img_row4[i] <= 0 ;
		end
	end
	else begin 
		if (in_valid) begin 
			if (global_count[3:0] == 12) img_row4[0] <= Img ;
			else if (global_count[3:0] == 13) img_row4[1] <= Img ;
			else if (global_count[3:0] == 14) img_row4[2] <= Img ;
			else if (global_count[3:0] == 15) img_row4[3] <= Img ;
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
wire G_clock_kernel ;
wire G_sleep_kernel = !(global_count < 9) ;
GATED_OR GATED_gkernel (.CLOCK(clk), .SLEEP_CTRL(G_sleep_kernel && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_kernel)) ; 
always @ (posedge G_clock_kernel or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			kernel_save1[i] <= 0 ;
		end
	end
	else begin 
		if (global_count < 9) begin 
			kernel_save1[global_count] <= Kernel ;
		end
		else begin 
			for (i = 0 ; i < 9 ; i = i + 1) begin 
				kernel_save1[i] <= kernel_save1[i] ;
			end
		end
	end
end

wire G_clock_kernel2 ;
wire G_sleep_kernel2 = !(curr_state == CONV && global_count >= 9 && global_count < 18) ;
GATED_OR GATED_gkernel2 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_kernel2 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_kernel2)) ;
always @ (posedge G_clock_kernel2 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			kernel_save2[i] <= 0 ;
		end
	end
	else begin 
		if (curr_state == CONV) begin 
			if (global_count == 9) kernel_save2[0] <= Kernel ;
			else if (global_count == 10) kernel_save2[1] <= Kernel ;
			else if (global_count == 11) kernel_save2[2] <= Kernel ;
			else if (global_count == 12) kernel_save2[3] <= Kernel ;
			else if (global_count == 13) kernel_save2[4] <= Kernel ;
			else if (global_count == 14) kernel_save2[5] <= Kernel ;
			else if (global_count == 15) kernel_save2[6] <= Kernel ;
			else if (global_count == 16) kernel_save2[7] <= Kernel ;
			else if (global_count == 17) kernel_save2[8] <= Kernel ;
		end
		else begin 
			for (i = 0 ; i < 9 ; i = i + 1) begin 
				kernel_save2[i] <= kernel_save2[i] ;
			end
		end
	end
end

wire G_clock_kernel3 ;
wire G_sleep_kernel3 = !(curr_state == CONV && global_count >= 15 && global_count < 30) ;
GATED_OR GATED_gkernel3 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_kernel3 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_kernel3)) ;
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 9 ; i = i + 1) begin 
			kernel_save3[i] <= 0 ;
		end
	end
	else begin 
		if (curr_state == CONV) begin 
			if (global_count == 18) kernel_save3[0] <= Kernel ;
			else if (global_count == 19) kernel_save3[1] <= Kernel ;
			else if (global_count == 20) kernel_save3[2] <= Kernel ;
			else if (global_count == 21) kernel_save3[3] <= Kernel ;
			else if (global_count == 22) kernel_save3[4] <= Kernel ;
			else if (global_count == 23) kernel_save3[5] <= Kernel ;
			else if (global_count == 24) kernel_save3[6] <= Kernel ;
			else if (global_count == 25) kernel_save3[7] <= Kernel ;
			else if (global_count == 26) kernel_save3[8] <= Kernel ;
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
wire G_clock_weight ;
wire G_sleep_weight = !(global_count < 4) ;
GATED_OR GATED_gweight (.CLOCK(clk), .SLEEP_CTRL(G_sleep_weight && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_weight)) ;
always @ (posedge G_clock_weight or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			weight_save[i] <= 0 ;
		end
	end
	else begin 
		if (global_count < 4) begin 
			weight_save[global_count] <= Weight ;
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
wire G_clock_opt ;
wire G_sleep_opt = !(global_count < 1) ;
GATED_OR GATED_gopt (.CLOCK(clk), .SLEEP_CTRL(G_sleep_opt && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_opt)) ;
always @ (posedge G_clock_opt or negedge rst_n) begin 
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
// wire G_clock_shi ;
// wire G_sleep_shi = !(global_count >= 8 && global_count < 62) ;
// GATED_OR GATED_gshi (.CLOCK(clk), .SLEEP_CTRL(G_sleep_shi && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_shi)) ;
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 3 ; i = i + 1) begin 
			shift_img_reg1[i] <= 0 ;
			shift_img_reg2[i] <= 0 ;
			shift_img_reg3[i] <= 0 ;
		end
	end
	else begin 
		if (global_count >= 8 && global_count < 62) begin
			if (col == 0) begin 
				shift_img_reg1[3] <= final_chosen_pixel[0] ;
				shift_img_reg2[3] <= final_chosen_pixel[1] ;
				shift_img_reg3[3] <= final_chosen_pixel[2] ;
			end
			else if (col == 1) begin 
				shift_img_reg1[2] <= final_chosen_pixel[0] ;
				shift_img_reg2[2] <= final_chosen_pixel[1] ;
				shift_img_reg3[2] <= final_chosen_pixel[2] ;
			end
			else if (col == 2) begin 
				shift_img_reg1[1] <= final_chosen_pixel[0] ;
				shift_img_reg2[1] <= final_chosen_pixel[1] ;
				shift_img_reg3[1] <= final_chosen_pixel[2] ;
			end
			else begin 
				shift_img_reg1[0] <= final_chosen_pixel[0] ;
				shift_img_reg2[0] <= final_chosen_pixel[1];
				shift_img_reg3[0] <= final_chosen_pixel[2];
			end
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
wire G_clock_dp3 ;
wire G_sleep_dp3 = !(curr_state != IMG2_COM || (global_count >= 10 && global_count < 58)) ;
GATED_OR GATED_gdp3 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_dp3 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_dp3)) ;
always @ (posedge G_clock_dp3 or negedge rst_n) begin 
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
//   equalization   
//---------------------------------------------------------------------
wire G_clock_eimgr1 ;
wire G_sleep_eimgr1 = !(global_count >= 43 && global_count < 47) ;
GATED_OR GATED_eimgr1 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_eimgr1 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_eimgr1)) ;
always @ (posedge G_clock_eimgr1 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			e_img_row1[i] <= 0 ;
		end
	end
	else begin 
		if (global_count == 43) e_img_row1[0] <= add_out ;
		else if (global_count == 44) e_img_row1[1] <= add_out ;
		else if (global_count == 45) e_img_row1[2] <= add_out ;
		else if (global_count == 46) e_img_row1[3] <= add_out ;
	end
end	

wire G_clock_eimgr2 ;
wire G_sleep_eimgr2 = !(global_count2 >= 2 && global_count2 < 6) ;
GATED_OR GATED_eimgr2 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_eimgr2 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_eimgr2)) ;
always @ (posedge G_clock_eimgr2 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			e_img_row2[i] <= 0 ;
		end
	end
	else begin 
		if (global_count2 == 2) e_img_row2[0] <= add_out ;
		else if (global_count2 == 3) e_img_row2[1] <= add_out ;
		else if (global_count2 == 4) e_img_row2[2] <= add_out ;
		else if (global_count2 == 5) e_img_row2[3] <= add_out ;
	end
end	

wire G_clock_eimgr3 ;
wire G_sleep_eimgr3 = !(global_count2 >= 6 && global_count2 < 10) ;
GATED_OR GATED_eimgr3 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_eimgr3 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_eimgr3)) ;
always @ (posedge G_clock_eimgr3 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			e_img_row3[i] <= 0 ;
		end
	end
	else begin 
		if (global_count2 == 6) e_img_row3[0] <= add_out ;
		else if (global_count2 == 7) e_img_row3[1] <= add_out ;
		else if (global_count2 == 8) e_img_row3[2] <= add_out ;
		else if (global_count2 == 9) e_img_row3[3] <= add_out ;
	end
end	

wire G_clock_eimgr4 ;
wire G_sleep_eimgr4 = !(global_count2 >= 10 && global_count2 < 14) ;
GATED_OR GATED_eimgr4 (.CLOCK(clk), .SLEEP_CTRL(G_sleep_eimgr4 && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_eimgr4)) ;
always @ (posedge G_clock_eimgr4 or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			e_img_row4[i] <= 0 ;
		end
	end
	else begin 
		if (global_count2 == 10) e_img_row4[0] <= add_out ;
		else if (global_count2 == 11) e_img_row4[1] <= add_out ;
		else if (global_count2 == 12) e_img_row4[2] <= add_out ;
		else if (global_count2 == 13) e_img_row4[3] <= add_out ;
	end
end	

wire G_clock_eshift ;
wire G_sleep_eshift = !(global_count2 >= 3 && global_count2 <= 25) ;
GATED_OR GATED_eshift (.CLOCK(clk), .SLEEP_CTRL(G_sleep_eshift && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_eshift)) ;
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 3 ; i = i + 1) begin 
			e_shift_img_reg1[i] <= 0 ;
			e_shift_img_reg2[i] <= 0 ;
			e_shift_img_reg3[i] <= 0 ;
		end
	end
	else begin 
		if (global_count2 >= 3 && global_count2 <= 22) begin 
			e_shift_img_reg1[2] <= e_final_chosen_pixel[0] ;
			e_shift_img_reg2[2] <= e_final_chosen_pixel[1];
			e_shift_img_reg3[2] <= e_final_chosen_pixel[2];
			e_shift_img_reg1[1] <= e_shift_img_reg1[2] ;
			e_shift_img_reg2[1] <= e_shift_img_reg2[2] ;
			e_shift_img_reg3[1] <= e_shift_img_reg3[2] ;
			e_shift_img_reg1[0] <= e_shift_img_reg1[1] ;
			e_shift_img_reg2[0] <= e_shift_img_reg2[1] ;
			e_shift_img_reg3[0] <= e_shift_img_reg3[1] ;
		end
		else begin 
			for (i = 0 ; i < 3 ; i = i + 1) begin 
				e_shift_img_reg1[i] <= e_shift_img_reg1[i] ;
				e_shift_img_reg2[i] <= e_shift_img_reg2[i] ;
				e_shift_img_reg3[i] <= e_shift_img_reg3[i] ;
			end
		end
	end
end

wire G_clock_enomi ;
wire G_sleep_enomi = !(global_count2 >= 5 && global_count2 <= 20) ;
GATED_OR GATED_enomi (.CLOCK(clk), .SLEEP_CTRL(G_sleep_enomi && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_enomi)) ;
always @ (posedge G_clock_enomi or negedge rst_n) begin 
	if (!rst_n) e_div_nomi <= 0 ;
	else begin
		if (global_count2 >= 5 && global_count2 <= 20) e_div_nomi <= final_sum3_out ;
		else e_div_nomi <= ~e_div_nomi ;
	end
end

wire G_clock_efeature ;
wire G_sleep_efeature = !(global_count2 <= 26) ;
GATED_OR GATED_efeature (.CLOCK(clk), .SLEEP_CTRL(G_sleep_efeature && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_efeature)) ;
always @ (posedge G_clock_efeature or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[0][3] <= 0 ;
	end
	else begin 
		if (global_count2 == 6) feature_map[0][3] <= norm_out ;
		else feature_map[0][3] <= feature_map[0][3] ;
	end
end

always @ (posedge G_clock_efeature or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[1][0] <= 0 ;
	end
	else begin 
		if (global_count2 == 7) feature_map[1][0] <= norm_out ;
		else feature_map[1][0] <= feature_map[1][0] ;
	end
end

always @ (posedge G_clock_efeature or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[1][1] <= 0 ;
	end
	else begin 
		if (global_count2 == 8) feature_map[1][1] <= norm_out ;
		else feature_map[1][1] <= feature_map[1][1] ;
	end
end

always @ (posedge G_clock_efeature or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[1][2] <= 0 ;
	end
	else begin 
		if (global_count2 == 9) feature_map[1][2] <= norm_out ;
		else feature_map[1][2] <= feature_map[1][2] ;
	end
end

always @ (posedge G_clock_efeature or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[1][3] <= 0 ;
	end
	else begin 
		if (global_count2 == 10) feature_map[1][3] <= norm_out ;
		else feature_map[1][3] <= feature_map[1][3] ;
	end
end

always @ (posedge G_clock_efeature or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[2][0] <= 0 ;
	end
	else begin 
		if (global_count2 == 11) feature_map[2][0] <= norm_out ;
		else feature_map[2][0] <= feature_map[2][0] ;
	end
end

always @ (posedge G_clock_efeature or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[2][1] <= 0 ;
	end
	else begin 
		if (global_count2 == 12) feature_map[2][1] <= norm_out ;
		else feature_map[2][1] <= feature_map[2][1] ;
	end
end

always @ (posedge G_clock_efeature or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[2][2] <= 0 ;
	end
	else begin 
		if (global_count2 == 13) feature_map[2][2] <= norm_out ;
		else feature_map[2][2] <= feature_map[2][2] ;
	end
end

always @ (posedge G_clock_efeature or negedge rst_n) begin //////////////////////////////////////////
	if (!rst_n) begin 
		feature_map[2][3] <= 0 ;
	end
	else begin 
		if (global_count2 == 14) feature_map[2][3] <= norm_out ;
		else feature_map[2][3] <= feature_map[2][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[3][0] <= 0 ;
	end
	else begin 
		if (global_count2 == 15) feature_map[3][0] <= norm_out ;
		else feature_map[3][0] <= feature_map[3][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[3][1] <= 0 ;
	end
	else begin 
		if (global_count2 == 16) feature_map[3][1] <= norm_out ;
		else feature_map[3][1] <= feature_map[3][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[3][2] <= 0 ;
	end
	else begin 
		if (global_count2 == 17) feature_map[3][2] <= norm_out ;
		else feature_map[3][2] <= feature_map[3][2] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[3][3] <= 0 ;
	end
	else begin 
		if (global_count2 == 18) feature_map[3][3] <= norm_out ;
		else feature_map[3][3] <= feature_map[3][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[0][0] <= 0 ;
	end
	else begin 
		if (global_count2 == 19) feature_map[0][0] <= norm_out ;
		else feature_map[0][0] <= feature_map[0][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[0][1] <= 0 ;
	end
	else begin 
		if (global_count2 == 20) feature_map[0][1] <= norm_out ;
		else feature_map[0][1] <= feature_map[0][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		feature_map[0][2] <= 0 ;
	end
	else begin 
		if (global_count2 == 21) feature_map[0][2] <= norm_out ;
		else feature_map[0][2] <= feature_map[0][2] ;
	end
end


//---------------------------------------------------------------------
//   feature_map   
//---------------------------------------------------------------------
always @ (posedge G_clock_dp3 or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[0][3] <= 0 ;
	end
	else begin 
		if (global_count == 45 || global_count <= 10) top_feature_map[0][3] <= 0 ;
		else if (col == 3 && row == 0) top_feature_map[0][3] <= add_out ;
		else top_feature_map[0][3] <= top_feature_map[0][3] ;
	end
end

always @ (posedge G_clock_dp3 or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[1][0] <= 0 ;
	end
	else begin 
		if (global_count == 45 || global_count <= 10) top_feature_map[1][0] <= 0 ;
		else if (col == 0 && row == 1) top_feature_map[1][0] <= add_out ;
		else top_feature_map[1][0] <= top_feature_map[1][0] ;
	end
end

always @ (posedge G_clock_dp3 or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[1][1] <= 0 ;
	end
	else begin 
		if (global_count == 47 || global_count <= 10) top_feature_map[1][1] <= 0 ;
		else if (col == 1 && row == 1) top_feature_map[1][1] <= add_out ;
		else top_feature_map[1][1] <= top_feature_map[1][1] ;
	end
end

always @ (posedge G_clock_dp3 or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[1][2] <= 0 ;
	end
	else begin 
		if (global_count == 47 || global_count <= 10) top_feature_map[1][2] <= 0 ;
		else if (col == 2 && row == 1) top_feature_map[1][2] <= add_out ;
		else top_feature_map[1][2] <= top_feature_map[1][2] ;
	end
end

always @ (posedge G_clock_dp3 or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[1][3] <= 0 ;
	end
	else begin 
		if (global_count == 48 || global_count <= 10) top_feature_map[1][3] <= 0 ;
		else if (col == 3 && row == 1) top_feature_map[1][3] <= add_out ;
		else top_feature_map[1][3] <= top_feature_map[1][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[2][0] <= 0 ;
	end
	else begin 
		if (global_count == 49 || global_count <= 10) top_feature_map[2][0] <= 0 ;
		else if (col == 0 && row == 2) top_feature_map[2][0] <= add_out ;
		else top_feature_map[2][0] <= top_feature_map[2][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[2][1] <= 0 ;
	end
	else begin 
		if (global_count == 50 || global_count <= 10) top_feature_map[2][1] <= 0 ;
		else if (col == 1 && row == 2) top_feature_map[2][1] <= add_out ;
		else top_feature_map[2][1] <= top_feature_map[2][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[2][2] <= 0 ;
	end
	else begin 
		if (global_count == 51 || global_count <= 10) top_feature_map[2][2] <= 0 ;
		else if (col == 2 && row == 2) top_feature_map[2][2] <= add_out ;
		else top_feature_map[2][2] <= top_feature_map[2][2] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[2][3] <= 0 ;
	end
	else begin 
		if (global_count == 53 || global_count <= 10) top_feature_map[2][3] <= 0 ;
		else if (col == 3 && row == 2) top_feature_map[2][3] <= add_out ;
		else top_feature_map[2][3] <= top_feature_map[2][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[3][0] <= 0 ;
	end
	else begin 
		if (global_count == 53 || global_count <= 10) top_feature_map[3][0] <= 0 ;
		else if (col == 0 && row == 3) top_feature_map[3][0] <= add_out ;
		else top_feature_map[3][0] <= top_feature_map[3][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[3][1] <= 0 ;
	end
	else begin 
		if (global_count == 55 || global_count <= 10) top_feature_map[3][1] <= 0 ;
		else if (col == 1 && row == 3) top_feature_map[3][1] <= add_out ;
		else top_feature_map[3][1] <= top_feature_map[3][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[3][2] <= 0 ;
	end
	else begin 
		if (global_count == 55 || global_count <= 10) top_feature_map[3][2] <= 0 ;
		else if (col == 2 && row == 3) top_feature_map[3][2] <= add_out ;
		else top_feature_map[3][2] <= top_feature_map[3][2] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[3][3] <= 0 ;
	end
	else begin 
		if (global_count == 56 || global_count <= 10) top_feature_map[3][3] <= 0 ;
		else if (col == 3 && row == 3) top_feature_map[3][3] <= add_out ;
		else top_feature_map[3][3] <= top_feature_map[3][3] ;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin 
		top_feature_map[0][0] <= 0 ;
	end
	else begin 
		if (global_count == 57 || global_count <= 10) top_feature_map[0][0] <= 0 ;
		else if (col == 0 && row == 0) top_feature_map[0][0] <= add_out ;
		else top_feature_map[0][0] <= top_feature_map[0][0] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[0][1] <= 0 ;
	end
	else begin 
		if (global_count2 == 13 || global_count <= 10) top_feature_map[0][1] <= 0 ;
		else if (col == 1 && row == 0) top_feature_map[0][1] <= add_out ;
		else top_feature_map[0][1] <= top_feature_map[0][1] ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		top_feature_map[0][2] <= 0 ;
	end
	else begin 
		if (global_count2 == 14 || (curr_state == CONV && global_count <= 10)) top_feature_map[0][2] <= 0 ;
		else if (col == 2 && row == 0) top_feature_map[0][2] <= add_out ;
		else top_feature_map[0][2] <= top_feature_map[0][2] ;
	end
end

//---------------------------------------------------------------------
//   max_pool   
//---------------------------------------------------------------------
wire G_clock_maxpool ;
wire G_sleep_maxpool = !(global_count2 >= 8 && global_count2 <= 22) ;
GATED_OR GATED_maxpool (.CLOCK(clk), .SLEEP_CTRL(G_sleep_maxpool && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_maxpool)) ;
always @ (posedge G_clock_maxpool or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 3 ; i = i + 1) begin 
			max_pool[i] <= 0 ;
		end
	end
	else begin 
		if (global_count2 == 8 || global_count2 == 11 || global_count2 == 12) begin 
			max_pool[0] <= big_one ;
			max_pool[1] <= max_pool[1] ;
			max_pool[2] <= max_pool[2] ;
			max_pool[3] <= max_pool[3] ;
		end
		else if (global_count2 == 10 || global_count2 == 13 || global_count2 == 14) begin 
			max_pool[0] <= max_pool[0] ;
			max_pool[1] <= big_one ;
			max_pool[2] <= max_pool[2] ;
			max_pool[3] <= max_pool[3] ;
		end
		else if (global_count2 == 16 || global_count2 == 19 || global_count2 == 20) begin 
			max_pool[0] <= max_pool[0] ;
			max_pool[1] <= max_pool[1] ;
			max_pool[2] <= big_one ;
			max_pool[3] <= max_pool[3] ;
		end
		else if (global_count2 == 18 || global_count2 == 21 || global_count2 == 22) begin 
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
wire G_clock_fully ;
wire G_sleep_fully = !((global_count2 >= 12 && global_count2 <= 16) || (global_count2 >= 21 && global_count2 <= 24)) ;
GATED_OR GATED_fully (.CLOCK(clk), .SLEEP_CTRL(G_sleep_fully && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_fully)) ;
always @ (posedge G_clock_fully or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i + 1) begin 
			fully_flattern[i] <= 0 ;
		end
	end
	else begin 
		if (global_count2 == 12) begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				fully_flattern[i] <= 0 ;
			end
		end
		else if (global_count2 == 13 || global_count2 == 15) begin 
			fully_flattern[0] <= fully_add_out ;
			fully_flattern[1] <= fully_flattern[1] ;
			fully_flattern[2] <= fully_flattern[2] ;
			fully_flattern[3] <= fully_flattern[3] ;
		end
		else if (global_count2 == 14 || global_count2 == 16) begin 
			fully_flattern[0] <= fully_flattern[0] ;
			fully_flattern[1] <= fully_add_out ;
			fully_flattern[2] <= fully_flattern[2] ;
			fully_flattern[3] <= fully_flattern[3] ;
		end
		else if (global_count2 == 21 || global_count2 == 23) begin 
			fully_flattern[0] <= fully_flattern[0] ;
			fully_flattern[1] <= fully_flattern[1] ;
			fully_flattern[2] <= fully_add_out ;
			fully_flattern[3] <= fully_flattern[3] ;
		end
		else if (global_count2 == 22 || global_count2 == 24) begin 
			fully_flattern[0] <= fully_flattern[0] ;
			fully_flattern[1] <= fully_flattern[1] ;
			fully_flattern[2] <= fully_flattern[2] ;
			fully_flattern[3] <= fully_add_out ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i + 1) begin 
				fully_flattern[i] <= fully_flattern[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   norm_max   
//---------------------------------------------------------------------
wire G_clock_nmax ;
wire G_sleep_nmax = !(global_count2 == 17 || global_count2 == 24 || global_count2 == 25) ;
GATED_OR GATED_nmax (.CLOCK(clk), .SLEEP_CTRL(G_sleep_nmax && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_nmax)) ;
always @ (posedge G_clock_nmax or negedge rst_n) begin 
	if (!rst_n) begin 
		norm_max <= 0 ;
	end
	else begin 
		if (global_count2 == 17 || global_count2 == 24 || global_count2 == 25) norm_max <= big_one ;
		else norm_max <= ~norm_max ;
	end
end

//---------------------------------------------------------------------
//   norm_min   
//---------------------------------------------------------------------
always @ (posedge G_clock_nmax or negedge rst_n) begin 
	if (!rst_n) begin 
		norm_min <= 0 ;
	end
	else begin 
		if (global_count2 == 17) norm_min <= small_one ;
		else if (global_count2 == 24 || global_count2 == 25) norm_min <= small_o ;
		else norm_min <= norm_min ;
	end
end

//---------------------------------------------------------------------
//   norm_domi   
//---------------------------------------------------------------------
wire G_clock_ndomi ;
wire G_sleep_ndomi = !(global_count2 == 26) ;
GATED_OR GATED_ndomi (.CLOCK(clk), .SLEEP_CTRL(G_sleep_ndomi && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_ndomi)) ;
always @ (posedge G_clock_ndomi or negedge rst_n) begin 
	if (!rst_n) begin 
		norm_domi <= 1 ;
	end
	else begin 
		if (global_count2 == 26) norm_domi <= fully_add_out ;
		else norm_domi <= norm_domi ;
	end
end

//---------------------------------------------------------------------
//   norm_nomi   
//---------------------------------------------------------------------
wire G_clock_nnomi ;
wire G_sleep_nnomi = !(global_count2 >= 26 && global_count2 <= 29) ;
GATED_OR GATED_nnomi (.CLOCK(clk), .SLEEP_CTRL(G_sleep_nnomi && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_nnomi)) ;
always @ (posedge G_clock_nnomi or negedge rst_n) begin 
	if (!rst_n) begin 
		norm_nomi <= 0 ;
	end
	else begin 
		if (global_count2 == 26) norm_nomi <= add_out1 ;
		else norm_nomi <= fully_add_out ;
	end
end

//---------------------------------------------------------------------
//   norm   
//---------------------------------------------------------------------
wire G_clock_norm ;
wire G_sleep_norm = !(global_count2 >= 27 && global_count2 <= 30) ;
GATED_OR GATED_gnorm (.CLOCK(clk), .SLEEP_CTRL(G_sleep_norm && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_norm)) ;
always @ (posedge G_clock_norm or negedge rst_n) begin 
	if (!rst_n) begin 
		norm <= 0 ;
	end
	else begin 
		if (global_count2 >= 27 && global_count2 <= 30) norm <= norm_out ;
		else norm <= ~norm ;
	end
end

//---------------------------------------------------------------------
//   exp   
//---------------------------------------------------------------------
wire G_clock_exp ;
wire G_sleep_exp = !(global_count2 >= 28 && global_count2 < 32) ;
GATED_OR GATED_gexp (.CLOCK(clk), .SLEEP_CTRL(G_sleep_exp && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_exp)) ;
always @ (posedge G_clock_exp or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i +1) begin 
			exp[i] <= 0 ;
		end
	end
	else begin 
		if ((global_count2 >= 28 && global_count2 < 32)) begin 
			exp[3] <= exp_out ;
			exp[2] <= exp[3] ;
			exp[1] <= exp[2] ;
			exp[0] <= exp[1] ;
		end
		else if (global_count2 == 32) begin 
			for (i = 0 ; i < 4 ; i = i +1) begin 
				exp[i] <= exp[i] ;
			end
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i +1) begin 
				exp[i] <= ~exp[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   recip   
//---------------------------------------------------------------------
wire G_clock_recip ;
wire G_sleep_recip = !(global_count2 >= 29 && global_count2 < 33) ;
GATED_OR GATED_grecip (.CLOCK(clk), .SLEEP_CTRL(G_sleep_recip && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_recip)) ;
always @ (posedge G_clock_recip or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i +1) begin 
			recip[i] <= 0 ;
		end
	end
	else begin 
		if ((global_count2 >= 29 && global_count2 < 33)) begin 
			recip[3] <= recip_out ;
			recip[2] <= recip[3] ;
			recip[1] <= recip[2] ;
			recip[0] <= recip[1] ;
		end
		else begin 
			for (i = 0 ; i < 4 ; i = i +1) begin 
				recip[i] <= ~recip[i] ;
			end
		end
	end
end

//---------------------------------------------------------------------
//   one_plus_exp   
//---------------------------------------------------------------------
wire G_clock_ope ;
wire G_sleep_ope = !(global_count2 >= 30 && global_count2 < 34) ;
GATED_OR GATED_ope (.CLOCK(clk), .SLEEP_CTRL(G_sleep_ope && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_ope)) ;
always @ (posedge G_clock_ope or negedge rst_n) begin 
	if (!rst_n) begin 
		one_plus_exp <= 0 ;
	end
	else begin 
		if (global_count2 >= 30 && global_count2 < 34) one_plus_exp <= add_out1 ;
		else one_plus_exp <= ~one_plus_exp ;
	end
end

//---------------------------------------------------------------------
//   exp_plus_exp   
//---------------------------------------------------------------------
always @ (posedge G_clock_ope or negedge rst_n) begin 
	if (!rst_n) begin 
		exp_plus_exp <= 0 ;
	end
	else begin 
		if (global_count2 >= 30 && global_count2 < 34) exp_plus_exp <= add_out2 ;
		else exp_plus_exp <= ~exp_plus_exp ;
	end
end

//---------------------------------------------------------------------
//   exp_minus_exp   
//---------------------------------------------------------------------
always @ (posedge G_clock_ope or negedge rst_n) begin 
	if (!rst_n) begin 
		exp_minus_exp <= 0 ;
	end
	else begin 
		if (global_count2 >= 30 && global_count2 < 34) exp_minus_exp <= fully_add_out ;
		else exp_minus_exp <= ~exp_minus_exp ;
	end
end

//---------------------------------------------------------------------
//   tanh_or_sigmoid
//---------------------------------------------------------------------
wire G_clock_tos ;
wire G_sleep_tos = !(global_count2 >= 31 && global_count2 < 35) ;
GATED_OR GATED_tos (.CLOCK(clk), .SLEEP_CTRL(G_sleep_tos && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_tos)) ;
always @ (posedge G_clock_tos or negedge rst_n) begin 
	if (!rst_n) begin 
		for (i = 0 ; i < 4 ; i = i +1) begin 
			tanh_or_sigmoid[i] <= 0 ;
		end
	end
	else begin 
		if ((global_count2 >= 31 && global_count2 < 35)) begin 
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
wire G_clock_ev ;
wire G_sleep_ev = !(curr_state == IDLE || global_count2 == 35) ;
GATED_OR GATED_ev (.CLOCK(clk), .SLEEP_CTRL(G_sleep_ev && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_ev)) ;
always @ (posedge G_clock_ev or negedge rst_n) begin 
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
		else if (curr_state == IMG1_COM && global_count2 == 35) begin 
			encoding_vec[3] <= tanh_or_sigmoid[3] ;
			encoding_vec[2] <= tanh_or_sigmoid[2] ;
			encoding_vec[1] <= tanh_or_sigmoid[1] ;
			encoding_vec[0] <= tanh_or_sigmoid[0] ;
		end
		else if (curr_state == IMG2_COM && global_count2 == 35) begin 
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
wire G_clock_out ;
wire G_sleep_out = !(global_count2 >= 36) ;
GATED_OR GATED_gout (.CLOCK(clk), .SLEEP_CTRL(G_sleep_out && cg_en), .RST_N(rst_n), .CLOCK_GATED(G_clock_out)) ;
always @ (posedge G_clock_out or negedge rst_n) begin 
	if (!rst_n) begin 
		out_valid <= 0 ;
		out <= 0 ;
	end
	else begin 
		if (global_count2 == 990) begin 
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
reg  [inst_sig_width+inst_exp_width:0] chosen_pixel    [0:3] ;
reg  [inst_sig_width+inst_exp_width:0] cal_dp3_1       [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] cal_dp3_2       [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] cal_dp3_3       [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] multi_in        [0:1] ;
reg  [inst_sig_width+inst_exp_width:0] multi_out            ;
reg  [inst_sig_width+inst_exp_width:0] fully_add_in    [0:1] ; 
reg  [inst_sig_width+inst_exp_width:0] dp3_in          [0:8] ;
reg  [inst_sig_width+inst_exp_width:0] sum3_in         [0:2] ;

reg  [inst_sig_width+inst_exp_width:0] e_chosen_pixel  [0:3] ; 
reg  [inst_sig_width+inst_exp_width:0] e_sum_1         [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] e_sum_2         [0:2] ;
reg  [inst_sig_width+inst_exp_width:0] e_sum_3         [0:2] ;



always @ (*) begin 
	if (global_count >= 8 && global_count <= 57) begin 
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
	else begin 
		chosen_pixel[0] = 0 ;
		chosen_pixel[1] = 0 ;
		chosen_pixel[2] = 0 ;
		chosen_pixel[3] = 0 ;
	end
end

always @ (*) begin 
	if (global_count >= 8 && global_count <= 57) begin
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
	else begin 
		final_chosen_pixel[0] = 0 ;
	    final_chosen_pixel[1] = 0 ;
	    final_chosen_pixel[2] = 0 ;
	end
end


always @ (*) begin 
	case (opt_save)
		0, 2 : begin 
			if (col == 2) begin 
				cal_dp3_1[0] = shift_img_reg1[3] ;
				cal_dp3_2[0] = shift_img_reg2[3] ;
				cal_dp3_3[0] = shift_img_reg3[3] ;
				cal_dp3_1[1] = shift_img_reg1[3] ;
				cal_dp3_2[1] = shift_img_reg2[3] ;
				cal_dp3_3[1] = shift_img_reg3[3] ;
				cal_dp3_1[2] = shift_img_reg1[2] ;
				cal_dp3_2[2] = shift_img_reg2[2] ;
				cal_dp3_3[2] = shift_img_reg3[2] ;
			end
			else if (col == 3) begin 
				cal_dp3_1[0] = shift_img_reg1[3] ;
				cal_dp3_2[0] = shift_img_reg2[3] ;
				cal_dp3_3[0] = shift_img_reg3[3] ;
				cal_dp3_1[1] = shift_img_reg1[2] ;
				cal_dp3_2[1] = shift_img_reg2[2] ;
				cal_dp3_3[1] = shift_img_reg3[2] ;
				cal_dp3_1[2] = shift_img_reg1[1] ;
				cal_dp3_2[2] = shift_img_reg2[1] ;
				cal_dp3_3[2] = shift_img_reg3[1] ;
			end
			else if (col == 0) begin 
				cal_dp3_1[0] = shift_img_reg1[2] ;
				cal_dp3_2[0] = shift_img_reg2[2] ;
				cal_dp3_3[0] = shift_img_reg3[2] ;
				cal_dp3_1[1] = shift_img_reg1[1] ;
				cal_dp3_2[1] = shift_img_reg2[1] ;
				cal_dp3_3[1] = shift_img_reg3[1] ;
				cal_dp3_1[2] = shift_img_reg1[0] ;
				cal_dp3_2[2] = shift_img_reg2[0] ;
				cal_dp3_3[2] = shift_img_reg3[0] ;
			end
			else begin 
				cal_dp3_1[0] = shift_img_reg1[1] ;
				cal_dp3_2[0] = shift_img_reg2[1] ;
				cal_dp3_3[0] = shift_img_reg3[1] ;
				cal_dp3_1[1] = shift_img_reg1[0] ;
				cal_dp3_2[1] = shift_img_reg2[0] ;
				cal_dp3_3[1] = shift_img_reg3[0] ;
				cal_dp3_1[2] = shift_img_reg1[0] ;
				cal_dp3_2[2] = shift_img_reg2[0] ;
				cal_dp3_3[2] = shift_img_reg3[0] ;
			end
		end
		default : begin 
			if (col == 2) begin 
				cal_dp3_1[0] = 32'b00000000000000000000000000000000 ;
				cal_dp3_2[0] = 32'b00000000000000000000000000000000 ;
				cal_dp3_3[0] = 32'b00000000000000000000000000000000 ;
				cal_dp3_1[1] = shift_img_reg1[3] ;
				cal_dp3_2[1] = shift_img_reg2[3] ;
				cal_dp3_3[1] = shift_img_reg3[3] ;
				cal_dp3_1[2] = shift_img_reg1[2] ;
				cal_dp3_2[2] = shift_img_reg2[2] ;
				cal_dp3_3[2] = shift_img_reg3[2] ;
			end
			else if (col == 3) begin 
				cal_dp3_1[0] = shift_img_reg1[3] ;
				cal_dp3_2[0] = shift_img_reg2[3] ;
				cal_dp3_3[0] = shift_img_reg3[3] ;
				cal_dp3_1[1] = shift_img_reg1[2] ;
				cal_dp3_2[1] = shift_img_reg2[2] ;
				cal_dp3_3[1] = shift_img_reg3[2] ;
				cal_dp3_1[2] = shift_img_reg1[1] ;
				cal_dp3_2[2] = shift_img_reg2[1] ;
				cal_dp3_3[2] = shift_img_reg3[1] ;
			end
			else if (col == 0) begin 
				cal_dp3_1[0] = shift_img_reg1[2] ;
				cal_dp3_2[0] = shift_img_reg2[2] ;
				cal_dp3_3[0] = shift_img_reg3[2] ;
				cal_dp3_1[1] = shift_img_reg1[1] ;
				cal_dp3_2[1] = shift_img_reg2[1] ;
				cal_dp3_3[1] = shift_img_reg3[1] ;
				cal_dp3_1[2] = shift_img_reg1[0] ;
				cal_dp3_2[2] = shift_img_reg2[0] ;
				cal_dp3_3[2] = shift_img_reg3[0] ;
			end
			else begin 
				cal_dp3_1[0] = shift_img_reg1[1] ;
				cal_dp3_2[0] = shift_img_reg2[1] ;
				cal_dp3_3[0] = shift_img_reg3[1] ;
				cal_dp3_1[1] = shift_img_reg1[0] ;
				cal_dp3_2[1] = shift_img_reg2[0] ;
				cal_dp3_3[1] = shift_img_reg3[0] ;
				cal_dp3_1[2] = 32'b00000000000000000000000000000000 ;
				cal_dp3_2[2] = 32'b00000000000000000000000000000000 ;
				cal_dp3_3[2] = 32'b00000000000000000000000000000000 ;
			end
		end
	endcase 
end

always @ (*) begin 
	if (global_count >= 10 && global_count < 26) begin 
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
	if (global_count >= 10 && global_count <= 58)begin 
		sum3_in[0] = dp3[0] ;
		sum3_in[1] = dp3[1] ;
		sum3_in[2] = dp3[2] ;
	end
	else if (global_count2 == 35) begin 
		sum3_in[0] = 32'b00000000000000000000000000000000 ;
		sum3_in[1] = tanh_or_sigmoid[1] ;
		sum3_in[2] = {~encoding_vec[1][31], encoding_vec[1][30:0]} ;
	end
	else begin 
		sum3_in[0] = 0 ;
		sum3_in[1] = 0 ;
		sum3_in[2] = 0 ;
	end
end

//---------------------------------------------------------------------
//   	equalization
//---------------------------------------------------------------------
always @ (*) begin 
	if (global_count2 >= 3 && global_count2 <= 19) begin 
		if (col == 0) begin 
			e_chosen_pixel[0] = e_img_row1[0] ;
			e_chosen_pixel[1] = e_img_row2[0] ;
			e_chosen_pixel[2] = e_img_row3[0] ;
			e_chosen_pixel[3] = e_img_row4[0] ;
		end
		else if (col == 1) begin 
			e_chosen_pixel[0] = e_img_row1[1] ;
			e_chosen_pixel[1] = e_img_row2[1] ;
			e_chosen_pixel[2] = e_img_row3[1] ;
			e_chosen_pixel[3] = e_img_row4[1] ;
		end
		else if (col == 2) begin 
			e_chosen_pixel[0] = e_img_row1[2] ;
			e_chosen_pixel[1] = e_img_row2[2] ;
			e_chosen_pixel[2] = e_img_row3[2] ;
			e_chosen_pixel[3] = e_img_row4[2] ;
		end
		else begin 
			e_chosen_pixel[0] = e_img_row1[3] ;
			e_chosen_pixel[1] = e_img_row2[3] ;
			e_chosen_pixel[2] = e_img_row3[3] ;
			e_chosen_pixel[3] = e_img_row4[3] ;
		end
	end
	else begin 
		e_chosen_pixel[0] = 0 ;
		e_chosen_pixel[1] = 0 ;
		e_chosen_pixel[2] = 0 ;
		e_chosen_pixel[3] = 0 ;
	end
end

always @ (*) begin 
	if (global_count2 >= 3 && global_count2 <= 19) begin 
		case (opt_save)
			0, 2 : begin 
				if (row == 2) begin 
					e_final_chosen_pixel[0] = e_chosen_pixel[0] ;
					e_final_chosen_pixel[1] = e_chosen_pixel[0] ;
					e_final_chosen_pixel[2] = e_chosen_pixel[1] ;
				end
				else if (row == 3) begin 
					e_final_chosen_pixel[0] = e_chosen_pixel[0] ;
					e_final_chosen_pixel[1] = e_chosen_pixel[1] ;
					e_final_chosen_pixel[2] = e_chosen_pixel[2] ;
				end
				else if (row == 0) begin 
					e_final_chosen_pixel[0] = e_chosen_pixel[1] ;
					e_final_chosen_pixel[1] = e_chosen_pixel[2] ;
					e_final_chosen_pixel[2] = e_chosen_pixel[3] ;
				end
				else begin 
					e_final_chosen_pixel[0] = e_chosen_pixel[2] ;
					e_final_chosen_pixel[1] = e_chosen_pixel[3] ;
					e_final_chosen_pixel[2] = e_chosen_pixel[3] ;
				end
			end
			default : begin 
				if (row == 2) begin 
					e_final_chosen_pixel[0] = 32'b00000000000000000000000000000000 ;
					e_final_chosen_pixel[1] = e_chosen_pixel[0] ;
					e_final_chosen_pixel[2] = e_chosen_pixel[1] ;
				end
				else if (row == 3) begin 
					e_final_chosen_pixel[0] = e_chosen_pixel[0] ;
					e_final_chosen_pixel[1] = e_chosen_pixel[1] ;
					e_final_chosen_pixel[2] = e_chosen_pixel[2] ;
				end
				else if (row == 0) begin 
					e_final_chosen_pixel[0] = e_chosen_pixel[1] ;
					e_final_chosen_pixel[1] = e_chosen_pixel[2] ;
					e_final_chosen_pixel[2] = e_chosen_pixel[3] ;
				end
				else begin 
					e_final_chosen_pixel[0] = e_chosen_pixel[2] ;
					e_final_chosen_pixel[1] = e_chosen_pixel[3] ;
					e_final_chosen_pixel[2] = 32'b00000000000000000000000000000000 ;
				end
			end
		endcase 
	end
	else begin 
		e_final_chosen_pixel[0] = 0 ;
	    e_final_chosen_pixel[1] = 0 ;
	    e_final_chosen_pixel[2] = 0 ;
	end
end


always @ (*) begin 
	case (opt_save)
		0, 2 : begin 
			if (col == 2) begin 
				e_sum_1[0] = e_shift_img_reg1[1] ;
				e_sum_2[0] = e_shift_img_reg2[1] ;
				e_sum_3[0] = e_shift_img_reg3[1] ;
				e_sum_1[1] = e_shift_img_reg1[1] ;
				e_sum_2[1] = e_shift_img_reg2[1] ;
				e_sum_3[1] = e_shift_img_reg3[1] ;
				e_sum_1[2] = e_shift_img_reg1[2] ;
				e_sum_2[2] = e_shift_img_reg2[2] ;
				e_sum_3[2] = e_shift_img_reg3[2] ;
			end
			else if (col == 1) begin 
				e_sum_1[0] = e_shift_img_reg1[0] ;
				e_sum_2[0] = e_shift_img_reg2[0] ;
				e_sum_3[0] = e_shift_img_reg3[0] ;
				e_sum_1[1] = e_shift_img_reg1[1] ;
				e_sum_2[1] = e_shift_img_reg2[1] ;
				e_sum_3[1] = e_shift_img_reg3[1] ;
				e_sum_1[2] = e_shift_img_reg1[1] ;
				e_sum_2[2] = e_shift_img_reg2[1] ;
				e_sum_3[2] = e_shift_img_reg3[1] ;
			end
			else begin 
				e_sum_1[0] = e_shift_img_reg1[0] ;
				e_sum_2[0] = e_shift_img_reg2[0] ;
				e_sum_3[0] = e_shift_img_reg3[0] ;
				e_sum_1[1] = e_shift_img_reg1[1] ;
				e_sum_2[1] = e_shift_img_reg2[1] ;
				e_sum_3[1] = e_shift_img_reg3[1] ;
				e_sum_1[2] = e_shift_img_reg1[2] ;
				e_sum_2[2] = e_shift_img_reg2[2] ;
				e_sum_3[2] = e_shift_img_reg3[2] ;
			end
		end
		default : begin 
			if (col == 2) begin 
				e_sum_1[0] = 32'b00000000000000000000000000000000 ;
				e_sum_2[0] = 32'b00000000000000000000000000000000 ;
				e_sum_3[0] = 32'b00000000000000000000000000000000 ;
				e_sum_1[1] = e_shift_img_reg1[1] ;
				e_sum_2[1] = e_shift_img_reg2[1] ;
				e_sum_3[1] = e_shift_img_reg3[1] ;
				e_sum_1[2] = e_shift_img_reg1[2] ;
				e_sum_2[2] = e_shift_img_reg2[2] ;
				e_sum_3[2] = e_shift_img_reg3[2] ;
			end
			else if (col == 1) begin 
				e_sum_1[0] = e_shift_img_reg1[0] ;
				e_sum_2[0] = e_shift_img_reg2[0] ;
				e_sum_3[0] = e_shift_img_reg3[0] ;
				e_sum_1[1] = e_shift_img_reg1[1] ;
				e_sum_2[1] = e_shift_img_reg2[1] ;
				e_sum_3[1] = e_shift_img_reg3[1] ;
				e_sum_1[2] = 32'b00000000000000000000000000000000 ;
				e_sum_2[2] = 32'b00000000000000000000000000000000 ;
				e_sum_3[2] = 32'b00000000000000000000000000000000 ;
			end
			else begin 
				e_sum_1[0] = e_shift_img_reg1[0] ;
				e_sum_2[0] = e_shift_img_reg2[0] ;
				e_sum_3[0] = e_shift_img_reg3[0] ;
				e_sum_1[1] = e_shift_img_reg1[1] ;
				e_sum_2[1] = e_shift_img_reg2[1] ;
				e_sum_3[1] = e_shift_img_reg3[1] ;
				e_sum_1[2] = e_shift_img_reg1[2] ;
				e_sum_2[2] = e_shift_img_reg2[2] ;
				e_sum_3[2] = e_shift_img_reg3[2] ;
			end
		end
	endcase 
end


//---------------------------------------------------------------------

always @ (*) begin 
	if (global_count2 == 8) begin 
		cmp1 = feature_map[0][3] ;
		cmp2 = feature_map[1][0] ;
	end
	else if (global_count2 == 10) begin 
		cmp1 = feature_map[1][1] ;
		cmp2 = feature_map[1][2] ;
	end
	else if (global_count2 == 11) begin 
		cmp1 = max_pool[0] ;
		cmp2 = feature_map[1][3] ;
	end
	else if (global_count2 == 12) begin 
		cmp1 = max_pool[0] ;
		cmp2 = feature_map[2][0] ;
	end
	else if (global_count2 == 13) begin 
		cmp1 = max_pool[1] ;
		cmp2 = feature_map[2][1] ;
	end
	else if (global_count2 == 14) begin 
		cmp1 = max_pool[1] ;
		cmp2 = feature_map[2][2] ;
	end
	else if (global_count2 == 16) begin 
		cmp1 = feature_map[2][3] ;
		cmp2 = feature_map[3][0] ;
	end
	else if (global_count2 == 17) begin 
		cmp1 = fully_flattern[0] ;
		cmp2 = fully_flattern[1] ;
	end 
	else if (global_count2 == 18) begin 
		cmp1 = feature_map[3][1] ;
		cmp2 = feature_map[3][2] ;
	end
	else if (global_count2 == 19) begin 
		cmp1 = max_pool[2] ;
		cmp2 = feature_map[3][3] ;
	end
	else if (global_count2 == 20) begin 
		cmp1 = max_pool[2] ;
		cmp2 = feature_map[0][0] ;
	end
	else if (global_count2 == 21) begin 
		cmp1 = max_pool[3] ;
		cmp2 = feature_map[0][1] ;
	end
	else if (global_count2 == 22) begin 
		cmp1 = max_pool[3] ;
		cmp2 = feature_map[0][2] ;
	end
	else if (global_count2 == 24) begin 
		cmp1 = fully_flattern[2] ;
		cmp2 = norm_max ;
	end
	else if (global_count2 == 25) begin 
		cmp1 = fully_flattern[3] ;
		cmp2 = norm_max ;
	end
	else begin 
		cmp1 = feature_map[0][2] ;
		cmp2 = feature_map[0][3] ;
	end
end

always @ (*) begin 
	if (global_count2 == 13) begin 
		multi_in[0] = max_pool[0] ;
		multi_in[1] = weight_save[0] ;
	end
	else if (global_count2 == 14) begin 
		multi_in[0] = max_pool[0] ;
		multi_in[1] = weight_save[1] ;
	end
	else if (global_count2 == 15) begin 
		multi_in[0] = max_pool[1] ;
		multi_in[1] = weight_save[2] ;
	end
	else if (global_count2 == 16) begin 
		multi_in[0] = max_pool[1] ;
		multi_in[1] = weight_save[3] ;
	end
	else if (global_count2 == 21) begin 
		multi_in[0] = max_pool[2] ;
		multi_in[1] = weight_save[0] ;
	end
	else if (global_count2 == 22) begin 
		multi_in[0] = max_pool[2] ;
		multi_in[1] = weight_save[1] ;
	end
	else if (global_count2 == 23) begin 
		multi_in[0] = max_pool[3] ;
		multi_in[1] = weight_save[2] ;
	end
	else if (global_count2 == 24) begin 
		multi_in[0] = max_pool[3] ;
		multi_in[1] = weight_save[3] ;
	end
	else begin 
		multi_in[0] = max_pool[1] ;
		multi_in[1] = weight_save[3] ;
	end
end

always @ (*) begin 
	if (global_count2 == 13) begin 
		fully_add_in[0] = fully_flattern[0] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 14) begin 
		fully_add_in[0] = fully_flattern[1] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 15) begin 
		fully_add_in[0] = fully_flattern[0] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 16) begin 
		fully_add_in[0] = fully_flattern[1] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 21) begin 
		fully_add_in[0] = fully_flattern[2] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 22) begin 
		fully_add_in[0] = fully_flattern[3] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 23) begin 
		fully_add_in[0] = fully_flattern[2] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 24) begin 
		fully_add_in[0] = fully_flattern[3] ;
		fully_add_in[1] = multi_out ;
	end
	else if (global_count2 == 26) begin 
		fully_add_in[0] = norm_max ;
		fully_add_in[1] = {~norm_min[31], norm_min[30:0]} ;
	end
	else if (global_count2 == 27) begin 
		fully_add_in[0] = fully_flattern[1] ;
		fully_add_in[1] = {~norm_min[31], norm_min[30:0]} ;
	end
	else if (global_count2 == 28) begin 
		fully_add_in[0] = fully_flattern[2] ;
		fully_add_in[1] = {~norm_min[31], norm_min[30:0]} ;
	end
	else if (global_count2 == 29) begin 
		fully_add_in[0] = fully_flattern[3] ;
		fully_add_in[1] = {~norm_min[31], norm_min[30:0]} ;
	end
	else if ((global_count2 >= 30 && global_count2 < 33)) begin 
		fully_add_in[0] = exp[2] ;
		fully_add_in[1] = {~recip[3][31], recip[3][30:0]} ;
	end
	else if (global_count2 == 33) begin 
		fully_add_in[0] = exp[3] ;
		fully_add_in[1] = {~recip[3][31], recip[3][30:0]} ;
	end
	else if (global_count2 == 35) begin 
		fully_add_in[0] = tanh_or_sigmoid[3] ;
		fully_add_in[1] =  {~encoding_vec[3][31], encoding_vec[3][30:0]} ;
	end
	else if (global_count2 == 990) begin 
		fully_add_in[0] = encoding_vec[3] ;
		fully_add_in[1] = add_out2 ;
	end
	else begin 
		fully_add_in[0] = 0 ;
		fully_add_in[1] = 0 ;
	end
end


always @ (*) begin 
	if (global_count2 == 24) begin 
		cmp3 = norm_min ;
		cmp4 = fully_flattern[2] ;
	end
	else if (global_count2 == 25) begin 
		cmp3 = norm_min ;
		cmp4 = fully_flattern[3] ;
	end
	else begin 
		cmp3 = norm_min ;
		cmp4 = 0 ;
	end
end

always @ (*) begin 
	if (global_count2 >= 6 && global_count2 < 22) begin 
		div_nomi = e_div_nomi ;
		div_domi = 32'b01000001000100000000000000000000 ;
	end
	else if ((global_count2 >= 27 && global_count2 < 31)) begin 
		div_nomi = norm_nomi ;
		div_domi = norm_domi ;
	end
	else if ((opt_save == 2 || opt_save == 3) && (global_count2 >= 31 && global_count2 < 35)) begin 
		div_nomi = exp_minus_exp ;
		div_domi = exp_plus_exp ;
	end
	else if ((opt_save == 0 || opt_save == 1) && (global_count2 >= 31 && global_count2 < 35)) begin 
		div_nomi = 32'b00111111100000000000000000000000 ;
		div_domi = one_plus_exp ;
	end
	else begin 
		div_nomi = 0 ;
		div_domi = 0 ;
	end
end


always @ (*) begin 
	if ((global_count2 >= 29 && global_count2 < 33)) begin 
		recip_in = exp[3] ;
	end
	else begin 
		recip_in = 1 ;
	end
end

always @ (*) begin 
	if (global_count2 == 26) begin 
		add1 = fully_flattern[0] ;
		add2 = {~norm_min[31], norm_min[30:0]} ;
	end
	else if ((global_count2 >= 30 && global_count2 < 34)) begin 
		add1 = 32'b00111111100000000000000000000000 ;
		add2 = recip[3] ;
	end
	else if (global_count2 == 35) begin 
		add1 = tanh_or_sigmoid[0] ;
		add2 = {~encoding_vec[0][31], encoding_vec[0][30:0]} ;
	end
	else if (global_count2 == 990) begin 
		add1 = encoding_vec[0] ;
		add2 = encoding_vec[1] ;
	end
	else begin 
		add1 = 0 ;
		add2 = 0 ;
	end
end

always @ (*) begin 
	if ((global_count2 >= 30 && global_count2 < 33) ) begin 
		add3 = exp[2] ;
		add4 = recip[3] ;
	end
	else if (global_count2 == 33) begin 
		add3 = exp[3] ;
		add4 = recip[3] ;
	end
	else if (global_count2 == 35) begin 
		add3 = tanh_or_sigmoid[2] ;
		add4 = {~encoding_vec[2][31], encoding_vec[2][30:0]} ;
	end
	else if (global_count2 == 990) begin 
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
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U5 ( .a(top_feature_map[row][col]), .b(sum3_out), .rnd(3'b000), .z(add_out), .status() );

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U18 (.a(e_sum_1[0]), .b(e_sum_1[1]), .c(e_sum_1[2]), .rnd(3'b000), .z(e_sum3_out1), .status() ) ;
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U15 (.a(e_sum_2[0]), .b(e_sum_2[1]), .c(e_sum_2[2]), .rnd(3'b000), .z(e_sum3_out2), .status() ) ;
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U16 (.a(e_sum_3[0]), .b(e_sum_3[1]), .c(e_sum_3[2]), .rnd(3'b000), .z(e_sum3_out3), .status() ) ;
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U17 (.a(e_sum3_out1), .b(e_sum3_out2), .c(e_sum3_out3), .rnd(3'b000), .z(final_sum3_out), .status() ) ;

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


