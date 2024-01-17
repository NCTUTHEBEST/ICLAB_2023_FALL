/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter PAT_NUM = 3600 ;
parameter LIMIT_LAT = 1000 ;
parameter OUT_NUM = 1 ;
parameter ACTION_SEED = 48756 ;
parameter TYPE_SEED   = 48756 ;
parameter SIZE_SEED   = 48756 ;
parameter DATE_SEED   = 48756 ;
parameter BOXID_SEED  = 45879 ;
parameter INGFR_SEED  = 48812 ;
parameter INGRA_SEED  = 47849 ;

integer SEED        = 1253761253 ;
integer CYCLE_SEED  = 48756 ;
integer i_pat ;
integer catch ;
integer exe_lat ;
integer out_lat ;
//================================================================
// wire & registers 
//================================================================
logic [10:0] count ;
logic [7:0]  golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box
logic [63:0] barrel_data ;
logic no_pass_expired, enough_ing, bt_overflow, gt_overflow, milk_overflow, pine_overflow ;
logic pattern_complete ;
logic [11:0] need_bt, need_gt, need_milk, need_pine ;
logic [20:0] global_count ;
Error_Msg pattern_err_msg ;

//================================================================
// class random
//================================================================

// input action
// class random_act ;
	// randc Action act_id ;
	// function new (int seed) ;
		// this.srandom(seed) ;
	// endfunction
	// constraint range {
		// act_id inside {Make_drink, Supply, Check_Valid_Date} ;
	// }
// endclass

// Action input_action ;
// random_act action_rand = new(ACTION_SEED) ;


class random_act_num ;
	randc logic [3:0] act_id ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		act_id inside {[1:14]} ;
	}
endclass

logic [3:0] action_num ;
Action input_action ;
random_act_num action_rand = new(ACTION_SEED) ;


// input drink type
class random_type ;
	randc logic [4:0] drink_type ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		drink_type inside {{Black_Tea, L}, {Black_Tea, M}, {Black_Tea, S}, {Green_Tea, L}, {Green_Tea, M}, {Green_Tea, S}, {Milk_Tea, L}, {Milk_Tea, M}, {Milk_Tea, S}, 
						   {Extra_Milk_Tea, L}, {Extra_Milk_Tea, M}, {Extra_Milk_Tea, S}, {Green_Milk_Tea, L}, {Green_Milk_Tea, M}, {Green_Milk_Tea, S}, {Pineapple_Juice, L}, {Pineapple_Juice, M}, {Pineapple_Juice, S}, 
						   {Super_Pineapple_Tea, L}, {Super_Pineapple_Tea, M}, {Super_Pineapple_Tea, S}, {Super_Pineapple_Milk_Tea, L}, {Super_Pineapple_Milk_Tea, M}, {Super_Pineapple_Milk_Tea, S}} ;
	}
endclass

logic [4:0] input_type ;
random_type type_rand = new(TYPE_SEED) ;

// input today 
class random_today ;
	randc Day   today_day ;
	randc Month today_mon ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		today_mon inside {[1:12]} ;
		today_day inside {[1:31]} ;
		if (today_mon == 2) {
			today_day inside {[1:28]} ;
		}
		else if (today_mon == 4 || today_mon == 6 || today_mon == 9 || today_mon == 11) { 
			today_day inside {[1:30]} ;
		}
	}
endclass

Day   input_day ;
Month input_month ;
random_today today_rand = new(DATE_SEED) ;

// input Box No.
class random_box ;
	randc Barrel_No box_id ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		box_id inside {[0:255]} ;
	}
endclass

Barrel_No input_box ;
random_box box_rand = new(BOXID_SEED) ;

// input Ing
class random_ing_front ;
	randc bit [4:0] ingredient_front ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
endclass

class random_ing_rare ;
	randc bit [6:0] ingredient_rare ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
endclass

ING input_bt, input_gt, input_m, input_p ;
bit [4:0] ing_front ;
bit [6:0] ing_rare  ;
random_ing_front ing_front_rand = new(INGFR_SEED) ;
random_ing_rare  ing_rare_rand  = new(INGRA_SEED) ;



//================================================================
// initial
//================================================================
initial begin 
	$readmemh (DRAM_p_r, golden_DRAM) ;
	reset_task ;
	global_count = 0 ;
	count = 0 ;
	for (i_pat = 0 ; i_pat < PAT_NUM ; i_pat = i_pat + 1) begin 
		input_task ;
		cal_task ;
		wait_task ;
		check_task ;
		// $display ("pass No.%d pattern", i_pat) ;
		global_count = global_count + 1 ;
	end
	pass_task ;
	$finish ;
end

//================================================================
// tasks
//================================================================
task reset_task ; begin 
	inf.rst_n            = 1;
    inf.sel_action_valid = 0;
    inf.type_valid       = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
    inf.D                = 'dx;

    #(10) inf.rst_n = 0;
    #(10) inf.rst_n = 1;
end endtask


task input_task ; begin 
	@(negedge clk) ;
	
	//=========================================================
	// input action
	//=========================================================
	// random action
	catch = action_rand.randomize() ;
	action_num = action_rand.act_id ;
	if (global_count < 2000) begin 
		input_action = Make_drink ;
	end
	else if (global_count <= 2200 && global_count >= 2000) begin 
		input_action = Check_Valid_Date ;
	end
	else if (global_count <= 2401 && global_count >= 2201) begin
		input_action = Supply ;
	end
	else if (global_count == 3599) begin 
		input_action = Make_drink ;
	end
	else begin 
		// $display("%d", global_count) ;
		case (global_count % 6)
			0 : input_action = Supply ;
			1 : input_action = Make_drink ;
			2 : input_action = Check_Valid_Date ;
			3 : input_action = Make_drink ;
			4 : input_action = Supply ;
			5 : input_action = Check_Valid_Date ;
		endcase
	end
	// case (input_action) 
		// Make_drink : $display ("Make_drink") ;
		// Supply : $display ("Supply") ;
		// Check_Valid_Date : $display ("Check_Valid_Date") ;
	// endcase 
	// give action input
	inf.sel_action_valid = 1 ;
	inf.D = input_action ;
	@(negedge clk) ;
	// pull_down_action_input
	inf.sel_action_valid = 0 ;
	inf.D = 'dx ;
	// margin cycle
	@(negedge clk) ;
	//========================================================
	
	case (input_action)
		Make_drink : begin 
			//=========================================================
			// Input Drink Type
			//=========================================================
			// random drink type
			catch = type_rand.randomize() ;
			input_type = type_rand.drink_type ;
			// if (input_type[4:2] == Milk_Tea && input_type[1:0] == L) begin 
				// count = count + 1 ;
				// $display ("%d", count) ;
			// end
			// give type input
			inf.type_valid = 1 ;
			inf.D = input_type[4:2] ;
			@(negedge clk) ;
			// pull down type input
			inf.type_valid = 0 ; 
			inf.D = 'dx ;
			// margin cycle
			//=========================================================
			
			//=========================================================
			// Input Drink Size
			//=========================================================
			// give input
			// case (input_type[1:0])
				// 0 : $display ("L") ;
				// 1 : $display ("M") ;
				// 3 : $display ("S") ;
			// endcase 
			inf.size_valid = 1 ;
			inf.D = input_type[1:0] ;
			@(negedge clk) ;
			// pull down input
			inf.size_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================
			
			//=========================================================
			// Input Today
			//=========================================================
			catch = today_rand.randomize() ;
			input_day   = today_rand.today_day ;
			input_month = today_rand.today_mon ;
			// $display ("%d/%d", input_month, input_day) ;
			// give input
			inf.date_valid = 1 ;
			inf.D = {input_month, input_day} ;
			@(negedge clk) ;
			// pull down input
			inf.date_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================
			
			//=========================================================
			// Input Box No.
			//=========================================================
			catch = box_rand.randomize() ;
			input_box = box_rand.box_id ;
			// $display ("%d", input_box) ;
			// give input
			inf.box_no_valid = 1 ;
			inf.D = input_box ;
			@(negedge clk) ;
			// pull down input
			inf.box_no_valid = 0 ;
			inf.D = 'dx ;
			//=========================================================
		end
		Supply : begin 
			//=========================================================
			// Input Today
			//=========================================================
			catch = today_rand.randomize() ;
			input_day   = today_rand.today_day ;
			input_month = today_rand.today_mon ;
			// $display ("%d/%d", input_month, input_day) ;
			// give input
			inf.date_valid = 1 ;
			inf.D = {input_month, input_day} ;
			@(negedge clk) ;
			// pull down input
			inf.date_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================
			
			//=========================================================
			// Input Box No.
			//=========================================================
			catch = box_rand.randomize() ;
			input_box = 20 ;
			// $display ("%d", input_box) ;
			// give input
			inf.box_no_valid = 1 ;
			inf.D = input_box ;
			@(negedge clk) ;
			// pull down input
			inf.box_no_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================
			
			//=========================================================
			// Input Black_Tea
			//=========================================================
			catch = ing_front_rand.randomize() ;
			catch = ing_rare_rand.randomize() ;
			ing_front = ing_front_rand.ingredient_front ;
			ing_rare  = ing_rare_rand.ingredient_rare ;
			input_bt = ing_front*128+ing_rare ;
			// $display ("input_black_tea       => %d", input_bt) ;
			// give input
			inf.box_sup_valid = 1 ;
			inf.D = input_bt ;
			@(negedge clk) ;
			// pull down input
			inf.box_sup_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================

			//=========================================================
			// Input Green Tea
			//=========================================================
			catch = ing_front_rand.randomize() ;
			catch = ing_rare_rand.randomize() ;
			ing_front = ing_front_rand.ingredient_front ;
			ing_rare  = ing_rare_rand.ingredient_rare ;
			input_gt = ing_front*128+ing_rare ;
			// $display ("input_green_tea       => %d", input_gt) ;
			// give input
			inf.box_sup_valid = 1 ;
			inf.D = input_gt ;
			@(negedge clk) ;
			// pull down input
			inf.box_sup_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================

			//=========================================================
			// Input Milk
			//=========================================================
			catch = ing_front_rand.randomize() ;
			catch = ing_rare_rand.randomize() ;
			ing_front = ing_front_rand.ingredient_front ;
			ing_rare  = ing_rare_rand.ingredient_rare ;
			input_m = ing_front*128+ing_rare ;
			// $display ("input_milk            => %d", input_m) ;
			// give input
			inf.box_sup_valid = 1 ;
			inf.D = input_m ;
			@(negedge clk) ;
			// pull down input
			inf.box_sup_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================
			
			//=========================================================
			// Input Pineapple_Juice
			//=========================================================
			catch = ing_front_rand.randomize() ;
			catch = ing_rare_rand.randomize() ;
			ing_front = ing_front_rand.ingredient_front ;
			ing_rare  = ing_rare_rand.ingredient_rare ;
			input_p = ing_front*128+ing_rare ;
			// $display ("input_pineapple_juice => %d", input_p) ;
			// give input
			inf.box_sup_valid = 1 ;
			inf.D = input_p ;
			@(negedge clk) ;
			// pull down input
			inf.box_sup_valid = 0 ;
			inf.D = 'dx ;
			//=========================================================
		end
		Check_Valid_Date : begin 
			//=========================================================
			// Input Today
			//=========================================================
			catch = today_rand.randomize() ;
			input_day   = today_rand.today_day ;
			input_month = today_rand.today_mon ;
			// $display ("%d/%d", input_month, input_day) ;
			// give input
			inf.date_valid = 1 ;
			inf.D = {input_month, input_day} ;
			@(negedge clk) ;
			// pull down input
			inf.date_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================
			
			//=========================================================
			// Input Box No.
			//=========================================================
			catch = box_rand.randomize() ;
			input_box = box_rand.box_id ;
			// $display ("%d", input_box) ;
			// give input
			inf.box_no_valid = 1 ;
			inf.D = input_box ;
			@(negedge clk) ;
			// pull down input
			inf.box_no_valid = 0 ;
			inf.D = 'dx ;
			//=========================================================
		end
	endcase 
end endtask 

task cal_task ; begin 
	barrel_data[7:0]   = golden_DRAM[65536+(input_box*8)] ;
	barrel_data[15:8]  = golden_DRAM[65536+(input_box*8)+1] ;
	barrel_data[23:16] = golden_DRAM[65536+(input_box*8)+2] ;
	barrel_data[31:24] = golden_DRAM[65536+(input_box*8)+3] ;
	barrel_data[39:32] = golden_DRAM[65536+(input_box*8)+4] ;
	barrel_data[47:40] = golden_DRAM[65536+(input_box*8)+5] ;
	barrel_data[55:48] = golden_DRAM[65536+(input_box*8)+6] ;
	barrel_data[63:56] = golden_DRAM[65536+(input_box*8)+7] ;
	no_pass_expired   = 1 ;
	enough_ing        = 1 ;
	bt_overflow       = 0 ;
	gt_overflow       = 0 ;
	milk_overflow     = 0 ;
	pine_overflow     = 0 ;
	
	case (input_action) 
		Make_drink : begin
			//=========================================================
			// Pass Expired Day Or Not
			//=========================================================
			if (input_month > barrel_data[39:32]) no_pass_expired = 0 ;
			else if (input_month == barrel_data[39:32] && input_day > barrel_data[7:0]) no_pass_expired = 0 ;
			else no_pass_expired = 1 ;
			
			//=========================================================
			// Get Needed Ing
			//=========================================================
			case (input_type[4:2])
				Black_Tea : begin 
					case (input_type[1:0])
						L : begin 
							need_bt   = 960 ;
							need_gt   = 0   ;
							need_milk = 0   ;
							need_pine = 0   ;
						end
						M : begin 
							need_bt   = 720 ;
							need_gt   = 0   ;
							need_milk = 0   ;
							need_pine = 0   ;
						end
						S : begin 
							need_bt   = 480 ;
							need_gt   = 0   ;
							need_milk = 0   ;
							need_pine = 0   ;
						end
					endcase 
				end
				Milk_Tea : begin 
					case (input_type[1:0])
						L : begin 
							need_bt   = 720  ;
							need_gt   = 0    ;
							need_milk = 240  ;
							need_pine = 0    ;
						end                  
						M : begin 
							need_bt   = 540  ;
							need_gt   = 0    ;
							need_milk = 180  ;
							need_pine = 0    ;
						end
						S : begin 
							need_bt   = 360  ;
							need_gt   = 0    ;
							need_milk = 120  ;
							need_pine = 0    ;
						end
					endcase 
				end
				Extra_Milk_Tea : begin 
					case (input_type[1:0])
						L : begin 
							need_bt   = 480   ;
							need_gt   = 0     ;
							need_milk = 480   ;
							need_pine = 0     ;
						end
						M : begin 
							need_bt   = 360    ;
							need_gt   = 0      ;
							need_milk = 360    ;
							need_pine = 0      ;
						end
						S : begin 
							need_bt   = 240 ;
							need_gt   = 0;
							need_milk = 240;
							need_pine = 0;
						end
					endcase 
				end
				Green_Tea : begin 
					case (input_type[1:0])
						L : begin 
							need_bt   = 0;
							need_gt   = 960;
							need_milk = 0;
							need_pine = 0; 
						end
						M : begin 
							need_bt   = 0      ;
							need_gt   = 720    ;
							need_milk = 0      ;
							need_pine = 0      ;
						end
						S : begin 
							need_bt   = 0      ;
							need_gt   = 480    ;
							need_milk = 0      ;
							need_pine = 0      ;
						end
					endcase 
				end
				Green_Milk_Tea : begin 
					case (input_type[1:0])
						L : begin 
							need_bt   = 0     ;
							need_gt   = 480   ;
							need_milk = 480   ;
							need_pine = 0     ;
						end
						M : begin 
							need_bt   = 0     ;
							need_gt   = 360   ;
							need_milk = 360   ;
							need_pine = 0     ;
						end
						S : begin 
							need_bt   = 0      ;
							need_gt   = 240    ;
							need_milk = 240    ;
							need_pine = 0      ;
						end
					endcase 
				end
				Pineapple_Juice : begin 
					case (input_type[1:0])
						L : begin 
							need_bt   = 0      ;
							need_gt   = 0      ;
							need_milk = 0      ;
							need_pine = 960    ;
						end
						M : begin 
							need_bt   = 0      ;
							need_gt   = 0      ;
							need_milk = 0      ;
							need_pine = 720    ;
						end
						S : begin 
							need_bt   = 0      ;
							need_gt   = 0      ;
							need_milk = 0      ;
							need_pine = 480    ;
						end
					endcase 
				end
				Super_Pineapple_Tea : begin 
					case (input_type[1:0])
						L : begin 
							need_bt   = 480    ;
							need_gt   = 0      ;
							need_milk = 0      ;
							need_pine = 480    ;
						end
						M : begin 
							need_bt   = 360     ;
							need_gt   = 0       ;
							need_milk = 0       ;
							need_pine = 360     ;
						end
						S : begin 
							need_bt   = 240     ;
							need_gt   = 0       ;
							need_milk = 0       ;
							need_pine = 240     ;
						end
					endcase 
				end
				Super_Pineapple_Milk_Tea : begin 
					case (input_type[1:0])
						L : begin 
							need_bt   = 480     ;
							need_gt   = 0       ;
							need_milk = 240     ;
							need_pine = 240     ;
						end
						M : begin 
							need_bt   = 360     ;
							need_gt   = 0       ;
							need_milk = 180     ;
							need_pine = 180     ;
						end
						S : begin 
							need_bt   = 240      ;
							need_gt   = 0        ;
							need_milk = 120      ;
							need_pine = 120      ;
						end                      
					endcase 
				end
			endcase 
			
			//=========================================================
			// Enough Ingredient Or Not
			//=========================================================
			if (no_pass_expired) begin 
				if (barrel_data[63:52] >= need_bt && barrel_data[51:40] >= need_gt && barrel_data[31:20] >= need_milk && barrel_data[19:8] >= need_pine) begin 
					enough_ing = 1 ;
				end
				else begin
					enough_ing = 0 ;
				end
			end
			
			//=========================================================
			// Make Drink
			//=========================================================
			if (no_pass_expired && enough_ing) begin 
				barrel_data[63:52] = barrel_data[63:52] - need_bt   ;
				barrel_data[51:40] = barrel_data[51:40] - need_gt   ;
				barrel_data[31:20] = barrel_data[31:20] - need_milk ;
				barrel_data[19:8]  = barrel_data[19:8]  - need_pine ;
			end
			
			//=========================================================
			// Update Dram
			//=========================================================
			golden_DRAM[65536+(input_box*8)]   = barrel_data[7:0]   ;
			golden_DRAM[65536+(input_box*8)+1] = barrel_data[15:8]  ;
			golden_DRAM[65536+(input_box*8)+2] = barrel_data[23:16] ;
			golden_DRAM[65536+(input_box*8)+3] = barrel_data[31:24] ;
			golden_DRAM[65536+(input_box*8)+4] = barrel_data[39:32] ;
			golden_DRAM[65536+(input_box*8)+5] = barrel_data[47:40] ;
			golden_DRAM[65536+(input_box*8)+6] = barrel_data[55:48] ;
			golden_DRAM[65536+(input_box*8)+7] = barrel_data[63:56] ;
		end 
		Supply : begin 
			//=========================================================
			// Ingredient Overflow Or Not
			//=========================================================
			if (barrel_data[63:52] + input_bt   < input_bt)   bt_overflow   = 1 ;
			if (barrel_data[51:40] + input_gt   < input_gt)   gt_overflow   = 1 ;
			if (barrel_data[31:20] + input_m < input_m) milk_overflow = 1 ;
			if (barrel_data[19:8]  + input_p < input_p) pine_overflow = 1 ;
			
			//=========================================================
			// Supply
			//=========================================================
			if (bt_overflow) barrel_data[63:52] = 4095 ;
			else barrel_data[63:52] = barrel_data[63:52] + input_bt ;
			if (gt_overflow) barrel_data[51:40] = 4095 ;
			else barrel_data[51:40] = barrel_data[51:40] + input_gt ;
			if (milk_overflow) barrel_data[31:20] = 4095 ;
			else barrel_data[31:20] = barrel_data[31:20] + input_m ;
			if (pine_overflow) barrel_data[19:8] = 4095 ;
			else barrel_data[19:8] = barrel_data[19:8] + input_p ;
		
			//=========================================================
			// Update Dram
			//=========================================================
			golden_DRAM[65536+(input_box*8)]   = input_day   ;
			golden_DRAM[65536+(input_box*8)+1] = barrel_data[15:8]  ;
			golden_DRAM[65536+(input_box*8)+2] = barrel_data[23:16] ;
			golden_DRAM[65536+(input_box*8)+3] = barrel_data[31:24] ;
			golden_DRAM[65536+(input_box*8)+4] = input_month ;
			golden_DRAM[65536+(input_box*8)+5] = barrel_data[47:40] ;
			golden_DRAM[65536+(input_box*8)+6] = barrel_data[55:48] ;
			golden_DRAM[65536+(input_box*8)+7] = barrel_data[63:56] ;
		end
		Check_Valid_Date : begin 
			//=========================================================
			// Pass Expired Day Or Not
			//=========================================================
			if (input_month > barrel_data[39:32]) no_pass_expired = 0 ;
			else if (input_month == barrel_data[39:32] && input_day > barrel_data[7:0]) no_pass_expired = 0 ;
			else no_pass_expired = 1 ;
		end
	endcase 
end endtask 

task wait_task ; begin 
	exe_lat = -1 ;
	while (inf.out_valid !== 1) begin 
        exe_lat = exe_lat + 1;
        @(negedge clk);
	end
end endtask 

task check_task ; begin 
	if (no_pass_expired == 0) begin 
		pattern_complete = 0 ;
		pattern_err_msg  = No_Exp ;
	end
	else if (enough_ing == 0) begin 
		pattern_complete = 0 ;
		pattern_err_msg  = No_Ing ; 
	end
	else if (bt_overflow | gt_overflow | milk_overflow | pine_overflow) begin 
		pattern_complete = 0 ;
		pattern_err_msg  = Ing_OF ;
	end
	else begin 
		pattern_complete = 1 ;
		pattern_err_msg  = No_Err ;
	end
	
	if (inf.complete !== pattern_complete || inf.err_msg !== pattern_err_msg) begin 
        $display("==========================================================================") ;
		$display("                            Wrong Answer                                  ") ;
        $display("==========================================================================") ;
		$finish ;
	end
end endtask 

task pass_task ; begin 
    $display("==========================================================================") ;
	$display("                            Congratulations                               ") ;
    $display("==========================================================================") ;
end endtask 

endprogram
