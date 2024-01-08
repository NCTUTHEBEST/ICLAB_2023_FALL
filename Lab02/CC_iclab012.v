// module CC(
    // //Input Port
    // clk,
    // rst_n,
	// in_valid,
	// mode,
    // xi,
    // yi,

    // //Output Port
    // out_valid,
	// xo,
	// yo
    // );

// input              clk, rst_n, in_valid;
// input       [1:0]   mode;
// input       [7:0]   xi, yi;  

// output reg          out_valid;
// output reg  [7:0]   xo, yo;
// //==============================================//
// //             Parameter and Integer            //
// //==============================================//
// parameter IDLE = 3'd0, INPUT = 3'd1, MODE0 = 3'd2, MODE1 = 3'd3, MODE2 = 3'd4 ;



// //==============================================//
// //            FSM State Declaration             //
// //==============================================//
// reg [2:0] curr_state, next_state ;

// //==============================================//
// //             reg & wire declaration           //
// //==============================================//
// reg signed [7:0] x_input [0:3] ;
// reg signed [7:0] y_input [0:3] ;
// reg [1:0] mode_input ;
// reg signed [8:0] count_row ;
// reg signed [7:0] out_row, out_col ;
 
// wire start_no_remainder, final_no_remainder ;
// wire signed [8:0] nominator, dominator_l, dominator_r ;
// wire signed [8:0] add_start_point1, add_final_point1 ;
// wire signed [8:0] add_start_point, add_final_point ;
// wire signed [7:0] start_point, final_point ;

// //==============================================//
// //             Current State Block              //
// //==============================================//
// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) curr_state <= IDLE ;
	// else curr_state <= next_state ;
// end


// //==============================================//
// //              Next State Block                //
// //==============================================//
// always @ (*) begin 
	// case (curr_state)
		// IDLE : next_state = (in_valid) ? INPUT : IDLE ; 
		
		// INPUT: begin 
			// if (in_valid) next_state = INPUT ;
			// else if (mode_input == 0) next_state = MODE0 ;
			// else if (mode_input == 1) next_state = MODE1 ;
			// else next_state = MODE2 ;
		// end
		// MODE0: begin 
			// if (out_row == y_input[3] && out_col == final_point) next_state = IDLE ;
			// else next_state = MODE0 ;
		// end
		// MODE1: begin
			// next_state = IDLE ;
		// end
		// MODE2 : begin 
			// next_state = IDLE ;
		// end
		// default : next_state = IDLE ;
	// endcase 
// end

// //==============================================//
// //                  Input Block                 //
// //==============================================//

// // x_input[0:3] => xdr, xdl, xur, xul / d1, c1, b1, a1
// // y_input[0:3] => yd, yd, yu, yu     / d2, c2, b2, a2
// always @ (posedge  clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// x_input[0] <= 0 ;
		// y_input[0] <= 0 ;
		// x_input[1] <= 0 ;
		// y_input[1] <= 0 ;
		// x_input[2] <= 0 ;
		// y_input[2] <= 0 ;
		// x_input[3] <= 0 ;
		// y_input[3] <= 0 ;
		// mode_input <= 0 ;
	// end
	// else if (in_valid) begin 
		// x_input[0] <= xi ;
		// y_input[0] <= yi ;
		// x_input[1] <= x_input[0] ;
		// y_input[1] <= y_input[0] ;
		// x_input[2] <= x_input[1] ;
		// y_input[2] <= y_input[1] ;
		// x_input[3] <= x_input[2] ;
		// y_input[3] <= y_input[2] ;
		// mode_input <= mode ;
	// end
	// else begin 
		// x_input[0] <= x_input[0] ;
		// y_input[0] <= y_input[0] ;
		// x_input[1] <= x_input[1] ;
		// y_input[1] <= y_input[1] ;
		// x_input[2] <= x_input[2] ;
		// y_input[2] <= y_input[2] ;
		// x_input[3] <= x_input[3] ;
		// y_input[3] <= y_input[3] ;
		// mode_input <= mode_input ;
	// end
// end

// //==============================================//
// //              Calculation Block1              //
// //==============================================//
// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) count_row <= 0 ;
	// else if ( next_state == IDLE) count_row <= 0 ;
	// else if (out_col == final_point) count_row <= count_row + 1 ;
	// else count_row <= count_row ;
// end

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) out_row <= 0 ;
	// else if ( next_state == IDLE) out_row <= 0 ;
	// else if (next_state == INPUT) out_row <= yi ; // initial start row to bottom 
	// else if (out_col == final_point) out_row <= out_row + 1 ;
	// else out_row <= out_row ;
// end

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) out_col <= 0 ;
	// else if (next_state == INPUT || next_state == IDLE) out_col <= 0 ;
	// else if (curr_state == INPUT) out_col <= x_input[1] ;
	// else if (out_col != final_point) out_col <= out_col + 1 ;
	// else out_col <= start_point ;
// end

// Cal_Slope   c0 (x_input[3], x_input[1], x_input[2], x_input[0], y_input[2], y_input[1], nominator, dominator_r, dominator_l) ;
// row_slope   r0 (nominator, dominator_l, (count_row + 9'd1), add_start_point1, start_no_remainder) ;
// row_slope   r1 (nominator, dominator_r, count_row, add_final_point1, final_no_remainder) ;
// assign add_start_point = (nominator[8] == dominator_l[8] || start_no_remainder) ? add_start_point1 : add_start_point1 - 1 ;
// assign add_final_point = (nominator[8] == dominator_r[8] || final_no_remainder) ? add_final_point1 : add_final_point1 - 1 ;
// assign start_point = x_input[1] + add_start_point ;
// assign final_point = x_input[0] + add_final_point ;


// //==============================================//
// //              Calculation Block2              //
// //==============================================//

// wire signed [8:0] a1_minus, a2_minus ;
// wire signed [7:0] a1_target, a2_target ;
// wire signed [7:0] mux_out1, mux_out2 ;
// wire signed [8:0] b2_minus_d2, b1_minus_d1 ;
// wire signed [8:0] multi_target1, multi_target2 ;
// wire signed [7:0] twos_comple ;
// wire signed [16:0] multi_result1, multi_result2 ;
// wire signed [16:0] add_result ;
// wire signed [15:0] final_result ;
// wire signed [11:0] poly_c ; 
// wire signed [15:0] square_c1_minus_d1, square_c2_minus_d2 ;
// wire signed [15:0] square_a, square_b ;
// wire signed [15:0] dominator ;
// wire signed [30:0] dominator_squ ;
// wire signed [30:0] compare ;

// assign a1_target = (mode_input == 1) ? x_input[2] : x_input[1] ;
// assign a2_target = (mode_input == 1) ? y_input[2] : y_input[1] ;
// assign a1_minus = a1_target - x_input[3] ;
// assign a2_minus = a2_target - y_input[3] ;
// assign mux_out1 = (mode_input == 1) ? y_input[1] : y_input[2] ;
// assign mux_out2 = (mode_input == 1) ? x_input[1] : x_input[2] ;
// assign b2_minus_d2 = mux_out1 - y_input[0] ;
// assign b1_minus_d1 = mux_out2 - x_input[0] ;
// assign multi_target1 = (mode_input == 1) ? y_input[3] : b2_minus_d2 ;
// assign multi_target2 = (mode_input == 1) ? x_input[3] : b1_minus_d1 ;
// assign multi_result1 = multi_target1 * a1_minus ;
// assign multi_result2 = multi_target2 * a2_minus ;
// assign add_result = multi_result1 - multi_result2 ;
// assign final_result = (add_result[16] == 1) ? (~(add_result) + 1) >> 1 : add_result >> 1 ;
// assign poly_c = ~(add_result[11:0]) + 1 ;
// // square_LUT s0 (.in(b2_minus_d2), .squ_out(square_c2_minus_d2)) ;
// // square_LUT s1 (.in(b1_minus_d1), .squ_out(square_c1_minus_d1)) ;
// // square_LUT s2 (.in(a1_minus), .squ_out(square_a)) ;
// // square_LUT s3 (.in(a2_minus), .squ_out(square_b)) ;
// assign square_c2_minus_d2 = b2_minus_d2 * b2_minus_d2 ;
// assign square_c1_minus_d1 = b1_minus_d1 * b1_minus_d1 ;
// assign square_a = a1_minus * a1_minus ;
// assign square_b = a2_minus * a2_minus ;
// assign dominator = (a2_minus * x_input[1]) - (a1_minus * y_input[1]) - poly_c ;
// assign dominator_squ = dominator * dominator ;
// assign compare = (square_a + square_b) * (square_c1_minus_d1 + square_c2_minus_d2) ;


// //==============================================//
// //              Calculation Block3              //
// //==============================================//





// //==============================================//
// //                Output Block                  //
// //==============================================//

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) out_valid <= 0 ;
	// else if (curr_state == MODE0 || next_state == MODE1 || next_state == MODE2) out_valid <= 1 ;
	// else out_valid <= 0 ;
// end

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) begin 
		// xo <= 0 ;
		// yo <= 0 ;
	// end
	// else if (curr_state == MODE0) begin 
		// xo <= out_col ;
		// yo <= out_row ;
	// end
	// else if (next_state == MODE1) begin
		// if (dominator_squ > compare) begin 
			// xo <= 0 ;
			// yo <= 0 ;
		// end
		// else if (dominator_squ == compare) begin 
			// xo <= 0 ;
			// yo <= 2 ;
		// end
		// else begin 
			// xo <= 0 ;
			// yo <= 1 ;
		// end
	// end
	// else if (next_state == MODE2) begin 
		// xo <= final_result[15:8] ;
		// yo <= final_result[7:0] ;
	// end
	// else begin 
		// xo <= 0 ;
		// yo <= 0 ;
	// end
// end

// endmodule 


// module Cal_Slope (xul, xdl, xur, xdr, yu, yd, nominator, dominator_r, dominator_l) ;

// input  signed [7:0] xul, xdl, xur, xdr, yu, yd ;
// output signed [8:0] nominator, dominator_l, dominator_r ;

// assign nominator = yd - yu ;
// assign dominator_l =  xdl - xul ;
// assign dominator_r = xdr - xur ;

// endmodule

// module row_slope (nominator, dominator, row_count, add_point, no_remainder) ;

// input  signed [8:0] nominator, dominator ;
// input  signed [8:0] row_count ;
// output signed [8:0] add_point ;
// output no_remainder ;

// wire signed [18:0] temp ;

// assign temp = (dominator * row_count) ;
// assign add_point = temp / nominator ;
// assign no_remainder = (temp % nominator == 0) ? 1 : 0 ; 

// endmodule

// module square_LUT (in, squ_out) ;

// input  signed [7:0] in ;
// output reg [15:0] squ_out ;

// always @ (*) begin 
	// case (in)
		// -8'd1, 8'd1 : squ_out= 1 ;
		// -8'd2, 8'd2 : squ_out = 4 ; 
		// -8'd3, 8'd3 : squ_out= 9 ;
		// -8'd4, 8'd4 : squ_out = 16 ;
		// -8'd5, 8'd5 : squ_out= 25 ;
		// -8'd6, 8'd6 : squ_out = 36 ;
		// -8'd7, 8'd7 : squ_out= 49 ;
		// -8'd8, 8'd8 : squ_out = 64 ;
		// -8'd9, 8'd9 : squ_out= 81 ;
		// -8'd10, 8'd10 : squ_out = 100 ;
		// -8'd11, 8'd11 : squ_out= 121 ;
		// -8'd12, 8'd12 : squ_out = 144 ;
		// -8'd13, 8'd13 : squ_out= 169 ;
		// -8'd14, 8'd14 : squ_out = 196 ;
		// -8'd15, 8'd15 : squ_out= 225 ;
		// -8'd16, 8'd16 : squ_out = 256 ;
		// -8'd17, 8'd17 : squ_out= 289 ;
		// -8'd18, 8'd18 : squ_out = 324 ;
		// -8'd19, 8'd19 : squ_out = 361 ;
		// -8'd20, 8'd20 : squ_out = 400 ;
		// -8'd21, 8'd21 : squ_out= 441 ;
		// -8'd22, 8'd22 : squ_out = 484 ;
		// -8'd23, 8'd23 : squ_out= 529 ;
		// -8'd24, 8'd24 : squ_out = 576 ;
		// -8'd25, 8'd25 : squ_out= 625 ;
		// -8'd26, 8'd26 : squ_out = 676 ;
		// -8'd27, 8'd27 : squ_out= 729 ;
		// -8'd28, 8'd28 : squ_out = 784 ;
		// -8'd29, 8'd29 : squ_out = 841 ;
		// -8'd30, 8'd30 : squ_out = 900 ;
		// -8'd31, 8'd31 : squ_out= 961 ;
		// -8'd32, 8'd32 : squ_out = 1024 ;
		// -8'd33, 8'd33 : squ_out= 1089 ;
		// -8'd34, 8'd34 : squ_out = 1156 ;
		// -8'd35, 8'd35 : squ_out= 1225 ;
		// -8'd36, 8'd36 : squ_out = 1296 ;
		// -8'd37, 8'd37 : squ_out= 1369 ;
		// -8'd38, 8'd38 : squ_out = 1444 ;
		// -8'd39, 8'd39 : squ_out = 1521 ;
		// -8'd40, 8'd40 : squ_out = 1600 ;
		// -8'd41, 8'd41 : squ_out= 1681 ;
		// -8'd42, 8'd42 : squ_out = 1764 ;
		// -8'd43, 8'd43 : squ_out= 1849 ;
		// -8'd44, 8'd44 : squ_out = 1936 ;
		// -8'd45, 8'd45 : squ_out= 2025 ;
		// -8'd46, 8'd46 : squ_out = 2116 ;
		// -8'd47, 8'd47 : squ_out= 2209 ;
		// -8'd48, 8'd48 : squ_out = 2304 ;
		// -8'd49, 8'd49 : squ_out = 2401 ;
		// default : squ_out = 0 ;
	// endcase
// end



// endmodule
















module CC(
    //Input Port
    clk,
    rst_n,
	in_valid,
	mode,
    xi,
    yi,

    //Output Port
    out_valid,
	xo,
	yo
    );

input              clk, rst_n, in_valid;
input       [1:0]   mode;
input       [7:0]   xi, yi;  

output reg          out_valid;
output reg  [7:0]   xo, yo;
//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE = 3'd0, INPUT = 3'd1, MODE0 = 3'd2, MODE1 = 3'd3, MODE2 = 3'd4 ;



//==============================================//
//            FSM State Declaration             //
//==============================================//
reg [2:0] curr_state, next_state ;

//==============================================//
//             reg & wire declaration           //
//==============================================//
reg [1:0] mode_input ;
reg signed [7:0] x_input [0:3] ;
reg signed [7:0] y_input [0:3] ;
reg signed [7:0] start_count_row, final_count_row ;
reg signed [7:0] out_row, out_col ;

wire start_no_remainder, final_no_remainder ;
wire [8:0] pos_nominator, pos_dominator_l, pos_dominator_r ;
wire signed [8:0] nominator, dominator_l, dominator_r ;
reg  signed [7:0] add_start_point1, add_final_point1 ;
wire signed [7:0] temp_add_start_point, temp_add_final_point ;
wire signed [7:0] add_start_point, add_final_point ;
wire signed [7:0] start_point, final_point ;
wire signed [8:0] temp_ans1, temp_ans2 ;
wire signed [7:0] temp_ans3, temp_ans4 ;
wire signed [8:0] update_value_l, update_value_r ;
wire signed [8:0] remain_l, remain_r ;

//==============================================//
//             Current State Block              //
//==============================================//
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) curr_state <= IDLE ;
	else curr_state <= next_state ;
end


//==============================================//
//              Next State Block                //
//==============================================//
always @ (*) begin 
	case (curr_state)
		IDLE : next_state = (in_valid) ? INPUT : IDLE ; 
		
		INPUT: begin 
			if (in_valid) next_state = INPUT ;
			else if (mode_input == 0) next_state = MODE0 ;
			else if (mode_input == 1) next_state = MODE1 ;
			else next_state = MODE2 ;
		end
		MODE0: begin 
			if (out_row == y_input[3] && out_col == final_point) next_state = IDLE ;
			else next_state = MODE0 ;
		end
		MODE1: begin
			next_state = IDLE ;
		end
		MODE2 : begin 
			next_state = IDLE ;
		end
		default : next_state = IDLE ;
	endcase 
end

//==============================================//
//                  Input Block                 //
//==============================================//

// x_input[0:3] => xdr, xdl, xur, xul / d1, c1, b1, a1
// y_input[0:3] => yd, yd, yu, yu     / d2, c2, b2, a2
always @ (posedge  clk or negedge rst_n) begin 
	if (!rst_n) begin 
		x_input[0] <= 0 ;
		y_input[0] <= 0 ;
		x_input[1] <= 0 ;
		y_input[1] <= 0 ;
		x_input[2] <= 0 ;
		y_input[2] <= 0 ;
		x_input[3] <= 0 ;
		y_input[3] <= 0 ;
		mode_input <= 0 ;
	end
	else if (in_valid) begin 
		x_input[0] <= xi ;
		y_input[0] <= yi ;
		x_input[1] <= x_input[0] ;
		y_input[1] <= y_input[0] ;
		x_input[2] <= x_input[1] ;
		y_input[2] <= y_input[1] ;
		x_input[3] <= x_input[2] ;
		y_input[3] <= y_input[2] ;
		mode_input <= mode ;
	end
	else begin 
		x_input[0] <= x_input[0] ;
		y_input[0] <= y_input[0] ;
		x_input[1] <= x_input[1] ;
		y_input[1] <= y_input[1] ;
		x_input[2] <= x_input[2] ;
		y_input[2] <= y_input[2] ;
		x_input[3] <= x_input[3] ;
		y_input[3] <= y_input[3] ;
		mode_input <= mode_input ;
	end
end

//==============================================//
//              Calculation Block1              //
//==============================================//
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) start_count_row <= 0 ;
	else if (curr_state == IDLE) begin 
		start_count_row <= 0 ;
	end
	else if ((next_state == MODE0 && (curr_state == INPUT || out_col == final_point))) begin 
		if ((start_count_row + pos_dominator_l) >= pos_nominator) start_count_row <= remain_l ;
		else start_count_row <= start_count_row + pos_dominator_l ;
	end
	else begin 
		start_count_row <= start_count_row ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) final_count_row <= 0 ;
	else if (curr_state == INPUT) final_count_row <= 0 ;
	else if (out_col == final_point) begin 
		if ((final_count_row + pos_dominator_r) >= pos_nominator ) final_count_row <= remain_r ;
		else final_count_row <= final_count_row + pos_dominator_r ;
	end
	else begin 
		final_count_row <= final_count_row ;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) add_start_point1 <= 0 ;
	else if (curr_state == IDLE) begin 
		add_start_point1 <= 0 ;
	end
	else if ((next_state == MODE0 && (curr_state == INPUT || out_col == final_point))) begin 
		if ((start_count_row + pos_dominator_l) >= pos_nominator) begin 
			add_start_point1 <= add_start_point1 + update_value_l ;
		end
		else add_start_point1 <= add_start_point1 ;
	end
	else add_start_point1 <= add_start_point1 ; 
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) add_final_point1 <= 0 ;
	else if (curr_state == INPUT) add_final_point1 <= 0 ; 
	else if (out_col == final_point) begin 
		if ((final_count_row + pos_dominator_r) >= pos_nominator ) begin 
			add_final_point1 <= add_final_point1 + update_value_r ;
		end
		else add_final_point1 <= add_final_point1 ;
	end
	else add_final_point1 <= add_final_point1 ;
end


always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) out_row <= 0 ;
	else if ( next_state == IDLE) out_row <= 0 ;
	else if (next_state == INPUT) out_row <= yi ; // initial start row to bottom 
	else if (out_col == final_point) out_row <= out_row + 1 ;
	else out_row <= out_row ;
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) out_col <= 0 ;
	else if (next_state == INPUT) out_col <= x_input[0] ;
	else if (out_col != final_point) out_col <= out_col + 1 ;
	else out_col <= start_point ;
end

Cal_Slope   c0 (x_input[3], x_input[1], x_input[2], x_input[0], y_input[2], y_input[1], nominator, dominator_r, dominator_l) ;
assign pos_nominator = (nominator[8] == 1) ? -nominator : nominator ;
assign pos_dominator_l = (dominator_l[8] == 1) ? -dominator_l : dominator_l ;
assign pos_dominator_r = (dominator_r[8] == 1) ? -dominator_r : dominator_r ;
assign temp_ans1  = (start_count_row + pos_dominator_l) ;
assign temp_ans2  = (final_count_row + pos_dominator_r) ;
eight_divider e0 (.dividend(temp_ans1), .divisor(pos_nominator), .quotient(temp_ans3), .remain(remain_l)) ;
eight_divider e1 (.dividend(temp_ans2), .divisor(pos_nominator), .quotient(temp_ans4), .remain(remain_r)) ;
// assign temp_ans3 = temp_ans1 / pos_nominator ;
// assign temp_ans4 = temp_ans2 / pos_nominator ;
assign update_value_l  = (nominator[8] == dominator_l[8]) ? temp_ans3 : -temp_ans3 ;
assign update_value_r  = (nominator[8] == dominator_r[8]) ? temp_ans4 : -temp_ans4 ;

assign add_start_point = (nominator[8] == dominator_l[8] | start_count_row == 0) ? add_start_point1 : add_start_point1 - 1 ;
assign add_final_point = (nominator[8] == dominator_r[8] | final_count_row == 0) ? add_final_point1 : add_final_point1 - 1 ;
assign start_point = x_input[1] + add_start_point ;
assign final_point = x_input[0] + add_final_point ;


//==============================================//
//         Calculation Block2 & Block3          //
//==============================================//

wire signed [8:0] a1_minus, a2_minus ;
wire signed [7:0] a1_target, a2_target ;
wire signed [7:0] mux_out1, mux_out2 ;
wire signed [8:0] b2_minus_d2, b1_minus_d1 ;
wire signed [8:0] multi_target1, multi_target2 ;
wire signed [16:0] multi_result1, multi_result2 ;
wire signed [16:0] add_result ;
wire signed [16:0] final_result ;
wire signed [11:0] poly_c ; 
wire signed [12:0] square_c1_minus_d1, square_c2_minus_d2 ;
wire signed [12:0] square_a, square_b ;
wire signed [12:0] dominator ;
wire signed [24:0] dominator_squ ;
wire signed [24:0] compare ;
wire signed [16:0] temp_add ;
wire [5:0] temp_add1, temp_add2, temp_add3, temp_add4 ;

wire [5:0] pos_b2_minus_d2, pos_b1_minus_d1 ;
wire [5:0] pos_a1_minus, pos_a2_minus ;


assign a1_target = (mode_input == 1) ? x_input[2] : x_input[1] ;
assign a2_target = (mode_input == 1) ? y_input[2] : y_input[1] ;
assign a1_minus = a1_target - x_input[3] ;
assign a2_minus = a2_target - y_input[3] ;
assign mux_out1 = (mode_input == 1) ? y_input[1] : y_input[2] ;
assign mux_out2 = (mode_input == 1) ? x_input[1] : x_input[2] ;
assign b2_minus_d2 = mux_out1 - y_input[0] ;
assign b1_minus_d1 = mux_out2 - x_input[0] ;
assign multi_target1 = (mode_input == 1) ? y_input[3] : b2_minus_d2 ;
assign multi_target2 = (mode_input == 1) ? x_input[3] : b1_minus_d1 ;
assign multi_result1 = multi_target1 * a1_minus ;
assign multi_result2 = multi_target2 * a2_minus ;
assign add_result = multi_result1 - multi_result2 ;
Plus1 p0 (.in(~(add_result)), .out(temp_add)) ;
assign final_result = (add_result[16] == 1) ? temp_add[16:1] : add_result >> 1 ;
assign poly_c = ~(add_result[11:0]) + 1 ;

ninebit_Plus1 n0 (.in(~(a1_minus)), .out(temp_add1)) ;
ninebit_Plus1 n1 (.in(~(a2_minus)), .out(temp_add2)) ;
ninebit_Plus1 n2 (.in(~(b1_minus_d1)), .out(temp_add3)) ;
ninebit_Plus1 n3 (.in(~(b2_minus_d2)), .out(temp_add4)) ;
assign pos_a1_minus = (a1_minus[8] == 1) ? temp_add1 : a1_minus ;
assign pos_a2_minus = (a2_minus[8] == 1) ? temp_add2 : a2_minus ;
assign pos_b1_minus_d1 = (b1_minus_d1[8] == 1) ? temp_add3 : b1_minus_d1 ;
assign pos_b2_minus_d2 = (b2_minus_d2[8] == 1) ? temp_add4 : b2_minus_d2 ;
square_LUT s0 (.in(pos_b2_minus_d2), .squ_out(square_c2_minus_d2)) ;
square_LUT s1 (.in(pos_b1_minus_d1), .squ_out(square_c1_minus_d1)) ;
square_LUT s2 (.in(pos_a1_minus), .squ_out(square_a)) ;
square_LUT s3 (.in(pos_a2_minus), .squ_out(square_b)) ;
// assign square_c2_minus_d2 = pos_b2_minus_d2 * pos_b2_minus_d2 ;
// assign square_c1_minus_d1 = pos_b1_minus_d1 * pos_b1_minus_d1 ;
// assign square_a = pos_a1_minus * pos_a1_minus ;
// assign square_b = pos_a2_minus * pos_a2_minus ;
assign dominator = (a2_minus * x_input[1]) - (a1_minus * y_input[1]) - poly_c ;
assign dominator_squ = dominator * dominator ;
assign compare = (square_a + square_b) * (square_c1_minus_d1 + square_c2_minus_d2) ;

//==============================================//
//                Output Block                  //
//==============================================//

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) out_valid <= 0 ;
	else if (next_state == MODE0 || curr_state == MODE0 || next_state == MODE1 || next_state == MODE2) out_valid <= 1 ;
	else out_valid <= 0 ;
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		xo <= 0 ;
		yo <= 0 ;
	end
	else if (next_state == MODE0 || curr_state == MODE0) begin 
		xo <= out_col ;
		yo <= out_row ;
	end
	else if (next_state == MODE1) begin
		if (dominator_squ > compare) begin 
			xo <= 0 ;
			yo <= 0 ;
		end
		else if (dominator_squ == compare) begin 
			xo <= 0 ;
			yo <= 2 ;
		end
		else begin 
			xo <= 0 ;
			yo <= 1 ;
		end
	end
	else if (next_state == MODE2) begin 
		xo <= final_result[15:8] ;
		yo <= final_result[7:0] ;
	end
	else begin 
		xo <= 0 ;
		yo <= 0 ;
	end
end

endmodule 


module Cal_Slope (xul, xdl, xur, xdr, yu, yd, nominator, dominator_r, dominator_l) ;

input  signed [7:0] xul, xdl, xur, xdr, yu, yd ;
output signed [8:0] nominator, dominator_l, dominator_r ;

assign nominator = yd - yu ;
assign dominator_l =  xdl - xul ;
assign dominator_r = xdr - xur ;

endmodule

module square_LUT (in, squ_out) ;

input  signed [5:0] in ;
output reg signed [12:0] squ_out ;

always @ (*) begin 
	case (in)
		6'd1 : squ_out= 1 ;
		6'd2 : squ_out = 4 ; 
		6'd3 : squ_out= 9 ;
		6'd4 : squ_out = 16 ;
		6'd5 : squ_out= 25 ;
		6'd6 : squ_out = 36 ;
		6'd7 : squ_out= 49 ;
		6'd8 : squ_out = 64 ;
		6'd9 : squ_out= 81 ;
		6'd10 : squ_out = 100 ;
		6'd11 : squ_out= 121 ;
		6'd12 : squ_out = 144 ;
		6'd13 : squ_out= 169 ;
		6'd14 : squ_out = 196 ;
		6'd15 : squ_out= 225 ;
		6'd16 : squ_out = 256 ;
		6'd17 : squ_out= 289 ;
		6'd18 : squ_out = 324 ;
		6'd19 : squ_out = 361 ;
		6'd20 : squ_out = 400 ;
		6'd21 : squ_out= 441 ;
		6'd22 : squ_out = 484 ;
		6'd23 : squ_out= 529 ;
		6'd24 : squ_out = 576 ;
		6'd25 : squ_out= 625 ;
		6'd26 : squ_out = 676 ;
		6'd27 : squ_out= 729 ;
		6'd28 : squ_out = 784 ;
		6'd29 : squ_out = 841 ;
		6'd30 : squ_out = 900 ;
		6'd31 : squ_out= 961 ;
		6'd32 : squ_out = 1024 ;
		6'd33 : squ_out= 1089 ;
		6'd34 : squ_out = 1156 ;
		6'd35 : squ_out= 1225 ;
		6'd36 : squ_out = 1296 ;
		6'd37 : squ_out= 1369 ;
		6'd38 : squ_out = 1444 ;
		6'd39 : squ_out = 1521 ;
		6'd40 : squ_out = 1600 ;
		6'd41 : squ_out= 1681 ;
		6'd42 : squ_out = 1764 ;
		6'd43 : squ_out= 1849 ;
		6'd44 : squ_out = 1936 ;
		6'd45 : squ_out= 2025 ;
		6'd46 : squ_out = 2116 ;
		6'd47 : squ_out= 2209 ;
		6'd48 : squ_out = 2304 ;
		6'd49 : squ_out = 2401 ;
		6'd50 : squ_out = 2500 ;
		6'd51 : squ_out= 2601 ;
		6'd52 : squ_out = 2704 ;
		6'd53 : squ_out= 2809 ;
		6'd54 : squ_out = 2916 ;
		6'd55 : squ_out= 3025 ;
		6'd56 : squ_out = 3136 ;
		6'd57 : squ_out= 3249 ;
		6'd58 : squ_out = 3364 ;
		6'd59 : squ_out = 3481 ;
		6'd60 : squ_out = 3600 ;
		6'd61 : squ_out= 3721 ;
		6'd62 : squ_out = 3844 ;
		6'd63 : squ_out= 3969 ;
		default : squ_out = 0 ;
	endcase
end
endmodule

module ninebit_Plus1 (in, out) ;

input [8:0] in ;
output [5:0] out ;

wire [5:0] cin ;

FA f0 (.in1(in[0]), .in2(1'b1), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA f1 (.in1(in[1]), .in2(1'b0), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA f2 (.in1(in[2]), .in2(1'b0), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA f3 (.in1(in[3]), .in2(1'b0), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA f4 (.in1(in[4]), .in2(1'b0), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
FA f5 (.in1(in[5]), .in2(1'b0), .cin(cin[4]), .sum(out[5]), .cout(cin[5])) ;
endmodule


module eight_divider (dividend, divisor, quotient, remain) ;

input  [8:0]  dividend ;
input  [8:0]  divisor ;
output [7:0]  quotient ;
output [8:0]  remain ;

wire [8:0] remain0, remain1, remain2, remain3, remain4, remain5, remain6, remain7 ;

assign quotient[7] = (divisor > dividend[8:7]) ? 0 : 1 ;
assign remain0 = (quotient[7] == 1) ? dividend[8:7] - divisor : dividend[8:7] ;
assign quotient[6] = (divisor > {remain0, dividend[6]}) ? 0 : 1 ;
assign remain1 = (quotient[6] == 1) ? {remain0, dividend[6]} - divisor : {remain0, dividend[6]} ;
assign quotient[5] = (divisor > {remain1, dividend[5]}) ? 0 : 1 ;
assign remain2 = (quotient[5] == 1) ? {remain1, dividend[5]} - divisor : {remain1, dividend[5]} ;
assign quotient[4] = (divisor > {remain2, dividend[4]}) ? 0 : 1 ;
assign remain3 = (quotient[4] == 1) ? {remain2, dividend[4]} - divisor : {remain2, dividend[4]} ;
assign quotient[3] = (divisor > {remain3, dividend[3]}) ? 0 : 1 ;
assign remain4 = (quotient[3] == 1) ? {remain3, dividend[3]} - divisor : {remain3, dividend[3]} ;
assign quotient[2] = (divisor > {remain4, dividend[2]}) ? 0 : 1 ;
assign remain5 = (quotient[2] == 1) ? {remain4, dividend[2]} - divisor : {remain4, dividend[2]} ;
assign quotient[1] = (divisor > {remain5, dividend[1]}) ? 0 : 1 ;
assign remain6 = (quotient[1] == 1) ? {remain5, dividend[1]} - divisor : {remain5, dividend[1]} ;
assign quotient[0] = (divisor > {remain6, dividend[0]}) ? 0 : 1 ;
assign remain = (quotient[0] == 1) ? {remain6, dividend[0]} - divisor : {remain6, dividend[0]} ;

endmodule

module Plus1 (in, out) ;

input [16:0] in ;
output [16:0] out ;

wire [16:0] cin ;

FA f0 (.in1(in[0]), .in2(1'b1), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA f1 (.in1(in[1]), .in2(1'b0), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA f2 (.in1(in[2]), .in2(1'b0), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA f3 (.in1(in[3]), .in2(1'b0), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA f4 (.in1(in[4]), .in2(1'b0), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
FA f5 (.in1(in[5]), .in2(1'b0), .cin(cin[4]), .sum(out[5]), .cout(cin[5])) ;
FA f6 (.in1(in[6]), .in2(1'b0), .cin(cin[5]), .sum(out[6]), .cout(cin[6])) ;
FA f7 (.in1(in[7]), .in2(1'b0), .cin(cin[6]), .sum(out[7]), .cout(cin[7])) ;
FA f8 (.in1(in[8]), .in2(1'b0), .cin(cin[7]), .sum(out[8]), .cout(cin[8])) ;
FA f9 (.in1(in[9]), .in2(1'b0), .cin(cin[8]), .sum(out[9]), .cout(cin[9])) ;
FA f10 (.in1(in[10]), .in2(1'b0), .cin(cin[9]), .sum(out[10]), .cout(cin[10])) ;
FA f11 (.in1(in[11]), .in2(1'b0), .cin(cin[10]), .sum(out[11]), .cout(cin[11])) ;
FA f12 (.in1(in[12]), .in2(1'b0), .cin(cin[11]), .sum(out[12]), .cout(cin[12])) ;
FA f13 (.in1(in[13]), .in2(1'b0), .cin(cin[12]), .sum(out[13]), .cout(cin[13])) ;
FA f14 (.in1(in[14]), .in2(1'b0), .cin(cin[13]), .sum(out[14]), .cout(cin[14])) ;
FA f15 (.in1(in[15]), .in2(1'b0), .cin(cin[14]), .sum(out[15]), .cout(out[16])) ;

endmodule

module eight_bit_sub (ina, inb, out) ;

input  [7:0] ina, inb ;
output [7:0] out ;



endmodule

module FA (in1, in2, cin, sum, cout) ;

input in1, in2, cin ;
output sum, cout ;

assign sum = in1 ^ in2 ^ cin ;
assign cout = (in1 & in2) | (in1 & cin) | (in2 & cin) ;

endmodule

module FS (in1, in2, bin, diff, bout) ;

input  in1, in2, bin ;
output diff, bout ;

assign diff = in1 ^ in2 ^ bin ;
assign bout = (~in1 & bin) | (~in1 & in2) | (in2 & bin) ;

endmodule
