module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.
typedef enum logic [3:0]{
    S_IDLE ,
	S_GET_INFO ,
	S_ACCESS_DRAM ,
	S_WAIT_DRAM ,
    S_MAKE_OR_SUPPLY ,
	S_WRITE_BACK ,
	S_WAIT_WRITE ,
	S_CHECK_VALID_DATE ,
	S_OUT
} state_t ;

//======================================
//      Register
//======================================
state_t   	 curr_state, next_state ;
Action    	 store_action ;
Bev_Type  	 store_drink_type ;
Bev_Size  	 store_drink_size ;
Date         store_date ;  
logic supply_out_valid, supply_out_valid_nxt ;     
logic [7:0]  store_box_id ;
logic [11:0] supply_amount [0:3] ; // 0: Black tea, 1: Green tea, 2: Milk, 3: Pine juice 
logic [2:0]  count ;
logic [1:0]  make_count ;
logic [63:0] barrel_data ;
logic no_pass_expired, enough_ing, over_flag_comb, over_flag_seq ;
logic [11:0] total_black_tea, total_green_tea, total_milk, total_pine ;
logic [11:0] need_black_tea, need_green_tea, need_milk, need_pine ;
logic signed [12:0] add_out, add_in1, add_in2, add_out2 ;

//======================================
//            TOP_FSM
//======================================
always_ff @ ( posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
    if (!inf.rst_n) curr_state <= S_IDLE;
    else curr_state <= next_state;
end

always_comb begin : TOP_FSM_COMB
    case(curr_state)
        S_IDLE: begin
            if (inf.sel_action_valid) next_state = S_GET_INFO ;
            else next_state = S_IDLE ;
        end
		S_GET_INFO : begin 
			if (inf.box_no_valid) next_state = S_ACCESS_DRAM ;
			else next_state = S_GET_INFO ;
		end
		S_ACCESS_DRAM : begin 
			next_state = S_WAIT_DRAM ;
		end
		S_WAIT_DRAM : begin 
			if ((count == 4) && supply_out_valid) next_state = S_MAKE_OR_SUPPLY ;
			else if ((store_action != Supply) && inf.C_out_valid) next_state = S_CHECK_VALID_DATE ;
			else next_state = S_WAIT_DRAM ;
		end
		S_MAKE_OR_SUPPLY : begin
			if (make_count == 3) next_state = S_WRITE_BACK ;
			else next_state = S_MAKE_OR_SUPPLY ;
		end
		S_WRITE_BACK : begin 
			next_state = S_WAIT_WRITE ;
		end
		S_WAIT_WRITE : begin 
			if (inf.C_out_valid) next_state = S_OUT ; 
			else next_state = S_WAIT_WRITE ;
		end
		S_CHECK_VALID_DATE : begin 
			if (store_action == Make_drink && no_pass_expired && enough_ing) next_state = S_MAKE_OR_SUPPLY ;
			else next_state = S_IDLE ;
		end
		S_OUT : next_state = S_IDLE ;
        default: next_state = S_IDLE;
    endcase
end

//====================================================================================================================================================================================================================================
//        																									DESIGN
//====================================================================================================================================================================================================================================
//======================================
//          supply_out_valid
//======================================
always_comb begin 
	if (curr_state == S_IDLE) supply_out_valid_nxt = 0 ;
	else if (inf.C_out_valid) supply_out_valid_nxt = 1 ;
	else supply_out_valid_nxt = supply_out_valid ;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) supply_out_valid <= 0 ;
	else supply_out_valid <= supply_out_valid_nxt ;
end


//======================================
//       	  Store_action
//======================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) store_action <= Make_drink ;
	else begin
		if (inf.sel_action_valid) store_action <= inf.D.d_act[0] ;
		else store_action <= store_action ;
	end
end

//======================================
//       	 Store_drink_type
//======================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) store_drink_type <= Black_Tea ;
	else begin
		if (inf.type_valid) store_drink_type <= inf.D.d_type[0] ;
		else store_drink_type <= store_drink_type ;
	end
end

//======================================
//       	 Store_drink_size
//======================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) store_drink_size <= L ;
	else begin
		if (inf.size_valid) store_drink_size <= inf.D.d_size[0] ;
		else store_drink_size <= store_drink_size ;
	end
end

//======================================
//       	   Store_date
//======================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		store_date.M <= 0 ;
		store_date.D <= 0 ;
	end
	else begin
		if (inf.date_valid) begin 
			store_date <= inf.D.d_date[0] ;
		end
		else if (store_action == Make_drink && curr_state == S_MAKE_OR_SUPPLY) begin 
			store_date.M <= barrel_data[39:32] ;
			store_date.D <= barrel_data[7:0] ;
		end
		else begin 
			store_date.M <= store_date.M ;
			store_date.D <= store_date.D ;
		end
	end
end

//======================================
//       	   Store_box_no.
//======================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		store_box_id <= 0 ;
	end
	else begin
		if (inf.box_no_valid) begin 
			store_box_id <= inf.D.d_box_no[0] ;
		end
		else begin 
			store_box_id <= store_box_id ;
		end
	end
end

//======================================
//       	     count
//======================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) count <= 0 ;
		else if (inf.box_sup_valid) begin 
			count <= count + 1 ;
		end
		else begin 
			count <= count ;
		end
	end
end

//======================================
//        Store_box_supply
//======================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		for (int i = 0 ; i < 4 ; i = i + 1) begin 
			supply_amount[i] <= 0 ;
		end
	end
	else begin
		if (inf.box_sup_valid) begin 
			supply_amount[count] <= inf.D.d_ing[0] ;
		end
		else begin 
			for (int i = 0 ; i < 4 ; i = i + 1) begin 
				supply_amount[i] <= supply_amount[i] ;
			end
		end
	end
end

//======================================
//           barrel_data
//======================================
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		barrel_data <= 0 ;
	end
	else begin 
		if (inf.C_out_valid) barrel_data <= inf.C_data_r ;
		else barrel_data <= barrel_data ;
	end
end 

//======================================
//          make_count
//======================================
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		make_count <= 0 ;
	end
	else begin
		if (curr_state == S_IDLE) make_count <= 0 ;
		else if (next_state == S_MAKE_OR_SUPPLY ) make_count <= make_count + 1 ;
		else make_count <= make_count ;
	end
end


//======================================
//          total_black_tea
//======================================
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		total_black_tea <= 0 ;
	end
	else begin
		if ((curr_state == S_MAKE_OR_SUPPLY) && (make_count == 1)) begin 
			total_black_tea <= add_out2[11:0] ;
		end
		else begin 
			total_black_tea <= total_black_tea ;
		end
	end
end 


//======================================
//          total_green_tea
//======================================
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		total_green_tea <= 0 ;
	end
	else begin
		if ((curr_state == S_MAKE_OR_SUPPLY) && (make_count == 2)) begin 
			total_green_tea <= add_out2[11:0] ;
		end
		else begin 
			total_green_tea <= total_green_tea ;
		end
	end
end 

//======================================
//           total_milk
//======================================
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		total_milk <= 0 ;
	end
	else begin
		if ((curr_state == S_MAKE_OR_SUPPLY) && (make_count == 3)) begin 
			total_milk <= add_out2[11:0] ;
		end
		else begin 
			total_milk <= total_milk ;
		end
	end
end 



//======================================
//           co_adder
//======================================
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		add_in1 <= 0 ;
		add_in2 <= 0 ;
	end
	else begin 	
		if (store_action == Supply) begin 
			case (make_count)
				0 : begin 
					add_in1 <= barrel_data[63:52] ;
					add_in2 <= supply_amount[0] ;
				end
				1 : begin 
					add_in1 <= barrel_data[51:40] ;
					add_in2 <= supply_amount[1] ;
				end
				2 : begin 
					add_in1 <= barrel_data[31:20] ;
					add_in2 <= supply_amount[2] ;
				end
				3 : begin 
					add_in1 <= barrel_data[19:8] ;
					add_in2 <= supply_amount[3] ;
				end
				default : begin 
					add_in1 <= barrel_data[63:52] ;
					add_in2 <= supply_amount[0] ;
				end
			endcase 
		end
		else begin 
			case (make_count)
				0 : begin 
					add_in1 <= barrel_data[63:52] ;
					add_in2 <= ~{1'b0, need_black_tea} + 1 ;
				end
				1 : begin 
					add_in1 <= barrel_data[51:40] ;
					add_in2 <= ~{1'b0, need_green_tea} + 1 ;
				end
				2 : begin 
					add_in1 <= barrel_data[31:20] ;
					add_in2 <= ~{1'b0, need_milk} + 1 ;
				end
				3 : begin 
					add_in1 <= barrel_data[19:8] ;
					add_in2 <= ~{1'b0, need_pine} + 1 ;
				end
				default : begin 
					add_in1 <= barrel_data[63:52] ;
					add_in2 <= supply_amount[0] ;
				end
			endcase 
		end
	end
end

always_comb begin 
	add_out = add_in1 + add_in2 ;
	if ((curr_state == S_MAKE_OR_SUPPLY || curr_state == S_WRITE_BACK) && add_out[12] == 1) begin 
		add_out2 = 4095 ;
		over_flag_comb = 1 ;
	end
	else begin 
		add_out2 = add_out ;
		over_flag_comb = 0 ;
	end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) over_flag_seq <= 0 ;
	else begin 
		if (curr_state == S_IDLE) over_flag_seq <= 0 ;
		else over_flag_seq <= over_flag_seq | over_flag_comb ;
	end
end

//======================================
//           need_ingredient
//======================================
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		need_black_tea <= 0 ;
		need_green_tea <= 0 ;
		need_milk <= 0 ;
		need_pine <= 0 ;
	end
	else begin
		case (store_drink_type)
			Black_Tea : begin 
				case (store_drink_size)
					L : begin 
						need_black_tea <= 960 ;
						need_green_tea <= 0 ;
						need_milk <= 0 ;
						need_pine <= 0 ;
					end
					M : begin 
						need_black_tea <= 720 ;
						need_green_tea <= 0 ;
						need_milk <= 0 ;
						need_pine <= 0 ;
					end
					S : begin 
						need_black_tea <= 480 ;
					    need_green_tea <= 0 ;
					    need_milk <= 0 ;
					    need_pine <= 0 ;
					end
				endcase 
			end
			Milk_Tea : begin 
				case (store_drink_size)
					L : begin 
						need_black_tea <= 720 ;
						need_green_tea <= 0 ;
						need_milk <= 240 ;
						need_pine <= 0 ;
					end
					M : begin 
						need_black_tea <= 540 ;
						need_green_tea <= 0 ;
						need_milk <= 180 ;
						need_pine <= 0 ;
					end
					S : begin 
						need_black_tea <= 360 ;
					    need_green_tea <= 0 ;
					    need_milk <= 120 ;
					    need_pine <= 0 ;
					end
				endcase 
			end
			Extra_Milk_Tea : begin 
				case (store_drink_size)
					L : begin 
						need_black_tea <= 480 ;
						need_green_tea <= 0 ;
						need_milk <= 480 ;
						need_pine <= 0 ;
					end
					M : begin 
						need_black_tea <= 360 ;
						need_green_tea <= 0 ;
						need_milk <= 360 ;
						need_pine <= 0 ;
					end
					S : begin 
						need_black_tea <= 240 ;
					    need_green_tea <= 0 ;
					    need_milk <= 240 ;
					    need_pine <= 0 ;
					end
				endcase 
			end
			Green_Tea : begin 
				case (store_drink_size)
					L : begin 
						need_black_tea <= 0 ;
						need_green_tea <= 960 ;
						need_milk <= 0 ;
						need_pine <= 0 ;
					end
					M : begin 
						need_black_tea <= 0 ;
						need_green_tea <= 720 ;
						need_milk <= 0 ;
						need_pine <= 0 ;
					end
					S : begin 
						need_black_tea <= 0 ;
					    need_green_tea <= 480 ;
					    need_milk <= 0 ;
					    need_pine <= 0 ;
					end
				endcase 
			end
			Green_Milk_Tea : begin 
				case (store_drink_size)
					L : begin 
						need_black_tea <= 0 ;
						need_green_tea <= 480 ;
						need_milk <= 480 ;
						need_pine <= 0 ;
					end
					M : begin 
						need_black_tea <= 0 ;
						need_green_tea <= 360 ;
						need_milk <= 360 ;
						need_pine <= 0 ;
					end
					S : begin 
						need_black_tea <= 0 ;
					    need_green_tea <= 240 ;
					    need_milk <= 240 ;
					    need_pine <= 0 ;
					end
				endcase 
			end
			Pineapple_Juice : begin 
				case (store_drink_size)
					L : begin 
						need_black_tea <= 0 ;
						need_green_tea <= 0 ;
						need_milk <= 0 ;
						need_pine <= 960 ;
					end
					M : begin 
						need_black_tea <= 0 ;
						need_green_tea <= 0 ;
						need_milk <= 0 ;
						need_pine <= 720 ;
					end
					S : begin 
						need_black_tea <= 0 ;
					    need_green_tea <= 0 ;
					    need_milk <= 0 ;
					    need_pine <= 480 ;
					end
				endcase 
			end
			Super_Pineapple_Tea : begin 
				case (store_drink_size)
					L : begin 
						need_black_tea <= 480 ;
						need_green_tea <= 0 ;
						need_milk <= 0 ;
						need_pine <= 480 ;
					end
					M : begin 
						need_black_tea <= 360 ;
						need_green_tea <= 0 ;
						need_milk <= 0 ;
						need_pine <= 360 ;
					end
					S : begin 
						need_black_tea <= 240 ;
					    need_green_tea <= 0 ;
					    need_milk <= 0 ;
					    need_pine <= 240 ;
					end
				endcase 
			end
			Super_Pineapple_Milk_Tea : begin 
				case (store_drink_size)
					L : begin 
						need_black_tea <= 480 ;
						need_green_tea <= 0 ;
						need_milk <= 240 ;
						need_pine <= 240 ;
					end
					M : begin 
						need_black_tea <= 360 ;
						need_green_tea <= 0 ;
						need_milk <= 180 ;
						need_pine <= 180 ;
					end
					S : begin 
						need_black_tea <= 240 ;
					    need_green_tea <= 0 ;
					    need_milk <= 120 ;
					    need_pine <= 120 ;
					end
				endcase 
			end	
		endcase 
	end
end 

//======================================
//           enough_ing
//======================================
always_comb begin 
	if (curr_state == S_CHECK_VALID_DATE) begin 
		if (barrel_data[63:52] >= need_black_tea && barrel_data[51:40] >= need_green_tea && barrel_data[31:20] >= need_milk && barrel_data[19:8] >= need_pine) begin 
			enough_ing = 1 ;
		end
		else begin 
			enough_ing = 0 ;
		end
	end
	else enough_ing = 0 ;
end 


//======================================
//           no_pass_expired
//======================================
always_comb begin 
	if (curr_state == S_CHECK_VALID_DATE) begin 
		if (barrel_data[35:32] < store_date.M) begin 
			no_pass_expired = 0 ;
		end
		else if ((barrel_data[35:32] == store_date.M) && (barrel_data[4:0] < store_date.D)) begin 
			no_pass_expired = 0 ;
		end
		else begin 
			no_pass_expired = 1 ;
		end
	end
	else no_pass_expired = 0 ;
end 

//======================================
//       	 output_reg
//======================================

// always_ff @( posedge clk or negedge inf.rst_n) begin 
    // if (!inf.rst_n) begin 
		// inf.complete <= 0 ;
	// end
	// else if (curr_state == S_CHECK_VALID_DATE) begin 
		// if (no_pass_expired == 0) begin 
			// inf.complete <= 0 ;
		// end
		// else if ((store_action == Make_drink) && (enough_ing == 0)) begin 
			// inf.complete <= 0 ;
		// end
		// else if (store_action == Make_drink) begin 
			// inf.complete <= 0 ;
		// end
		// else begin 
			// inf.complete <= 1 ;
		// end
	// end
	// else if (curr_state == S_OUT) begin
		// if (over_flag_seq) begin 
			// inf.complete <= 0 ;
		// end
		// else begin 
			// inf.complete <= 1 ;
		// end
	// end
    // else begin 
		// inf.complete <= 0 ;
	// end 
// end

always_ff @( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) begin 
		inf.out_valid <= 0 ;
		inf.err_msg  <= No_Err ;
		inf.complete <= 0 ;
	end
	else if (curr_state == S_CHECK_VALID_DATE) begin 
		if (no_pass_expired == 0) begin 
			inf.out_valid <= 1 ;
			inf.err_msg <= No_Exp ;
			inf.complete <= 0 ;
		end
		else if ((store_action == Make_drink) && (enough_ing == 0)) begin 
			inf.out_valid <= 1 ;
			inf.err_msg <= No_Ing ;
			inf.complete <= 0 ;
		end
		else if (store_action == Make_drink) begin 
			inf.out_valid <= 0 ;
			inf.err_msg <= No_Err ;
			inf.complete <= 0 ;
		end
		else begin 
			inf.out_valid <= 1 ;
			inf.err_msg <= No_Err ;
			inf.complete <= 1 ;
		end
	end
	else if (curr_state == S_OUT) begin
		if (over_flag_seq) begin 
			inf.out_valid <= 1 ;
			inf.err_msg <= Ing_OF ;
			inf.complete <= 0 ;
		end
		else begin 
			inf.out_valid <= 1 ;
			inf.err_msg <= No_Err ;
			inf.complete <= 1 ;
		end
	end
    else begin 
		inf.out_valid <= 0 ;
	    inf.err_msg  <= No_Err ;
		inf.complete <= 0 ;
	end 
end


//====================================================================================================================================================================================================================================
//       	 																								Bridge output
//====================================================================================================================================================================================================================================

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		inf.C_addr <= 0 ;
		inf.C_data_w <= 0 ;
		inf.C_in_valid <= 0 ;
		inf.C_r_wb <= 0 ;
	end
	else begin 
		inf.C_addr <= store_box_id ;
		if (curr_state == S_ACCESS_DRAM) begin 
			inf.C_data_w <= 0 ;
			inf.C_in_valid <= 1 ;
			inf.C_r_wb <= 1 ;
		end
		else if (curr_state == S_WRITE_BACK) begin 
			inf.C_data_w <= {total_black_tea, total_green_tea, {4'd0,store_date.M}, total_milk, add_out2[11:0], {3'd0,store_date.D}} ;
			inf.C_in_valid <= 1 ;
			inf.C_r_wb <= 0 ;
		end
		else begin 
			inf.C_data_w <= 0 ;
			inf.C_in_valid <= 0 ;
			inf.C_r_wb <= 1 ;
		end
	end
end








endmodule