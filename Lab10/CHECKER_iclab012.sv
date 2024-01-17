/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/*
    Coverage Part
*/


class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
endclass

BEV bev_info = new() ;

always_ff @(posedge clk) begin
	// $display ("%d", bev_info.bev_type) ;
    if (inf.type_valid) begin
        bev_info.bev_type = inf.D.d_type[0] ;
    end
end

always_ff @(posedge clk) begin
    if (inf.size_valid) begin
        bev_info.bev_size = inf.D.d_size[0];
    end
end

/*
1. Each case of Beverage_Type should be select at least 100 times.
*/

covergroup Spec1 @(posedge clk iff(inf.type_valid));
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint inf.D.d_type[0] {
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup

Spec1 spec1_inst = new() ;

/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/

covergroup Spec2 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least = 100;
    bsize : coverpoint inf.D.d_size[0] {
        bins b_bev_size [] = {[L:S]} ;
    }
endgroup

Spec2 spec2_inst = new() ;


/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/

covergroup Spec3 @(negedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least = 100;
	cross bev_info.bev_size, bev_info.bev_type ;
endgroup

Spec3 spec3_inst = new() ;


/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/

covergroup Spec4 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
    option.at_least = 20;
	out : coverpoint inf.err_msg {
		bins e_err [] = {[No_Err:Ing_OF]} ;
	}
endgroup

Spec4 spec4_inst = new() ;

/*
5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/

covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1 ;
    option.at_least = 200 ;
	act : coverpoint inf.D.d_act[0] {
		bins a_act [] = ([Make_drink:Check_Valid_Date] => [Make_drink:Check_Valid_Date]) ;
	}
endgroup

Spec5 spec5_inst = new() ;

/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/

covergroup Spec6 @(posedge clk iff(inf.box_sup_valid));
    option.per_instance = 1 ;
    option.at_least = 1 ;
	input_ing : coverpoint inf.D.d_ing[0] {
		option.auto_bin_max = 32 ;
	}
endgroup

Spec6 spec6_inst = new() ;

/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/
// Spec1_2_3 cov_inst_1_2_3 = new();

/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/

Action store_action ;
logic last_invalid ;
logic store_cinvalid ;
logic [2:0] count ;

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		count = 0 ;
	end
	else begin 
		if (inf.box_sup_valid) count = count + 1 ;
		else if (count == 4) count = 0 ;
	end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin  
	if (!inf.rst_n) store_action = Make_drink ;
	else begin 
		if (inf.sel_action_valid)
			store_action = inf.D.d_act[0] ;
	end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) last_invalid = 0 ;
	else begin 
		case (store_action)
			Make_drink : begin 
				if (inf.box_no_valid) last_invalid = 1 ;
				else last_invalid = 0 ;
			end
			Supply : begin 
				if (count == 4) last_invalid = 1 ;
				else last_invalid = 0 ;
			end
			Check_Valid_Date : begin 
				if (inf.box_no_valid) last_invalid = 1 ;
				else last_invalid = 0 ;
			end
		endcase
	end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) store_cinvalid = 0 ;
	else begin 
		if (inf.C_in_valid) store_cinvalid = 1 ;
		else if (inf.C_out_valid) store_cinvalid = 0 ;
	end
end	


/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/

always @ (negedge inf.rst_n) begin 
	#(5) ;
	Assertion1 : assert (inf.out_valid === 0 && inf.err_msg === 0 && inf.complete === 0 && 
						   inf.C_addr === 0 && inf.C_data_w === 0 && inf.C_in_valid === 0 && inf.C_r_wb === 0 &&
						   inf.C_out_valid === 0 && inf.C_data_r === 0 && inf.AR_VALID === 0 && inf.AR_ADDR === 0 &&
						   inf.R_READY === 0 && inf.AW_VALID === 0 && inf.AW_ADDR === 0 && inf.W_VALID === 0 &&
						   inf.W_DATA === 0 && inf.B_READY === 0) 
				else begin 
					$display("==========================================================================") ;
					$display("                       Assertion 1 is violated                            ") ;			
					$display("==========================================================================") ;
					$fatal ;
				end
end
						
/*
    2.	Latency should be less than 1000 cycles for each operation.
*/
always @ (posedge clk)
	Assertion2 : assert property (p_last_invalid)
				 else begin 
					$display("==========================================================================") ;
					$display("                       Assertion 2 is violated                            ") ;
					$display("==========================================================================") ;
					$fatal ;
				 end

property p_last_invalid ;
	@ (posedge clk) last_invalid |-> (##[1:1000] inf.out_valid) ;
endproperty : p_last_invalid 

/*
    3. If out_valid does not pull up, complete should be 0.
*/

always @ (negedge clk)
	Assertion3 : assert property (p_complete)
				 else begin 
					$display("==========================================================================") ;
					$display("                      Assertion 3 is violated                             ") ;
					$display("==========================================================================") ;
					$fatal ;
				 end

property p_complete ;
	@ (negedge clk) inf.complete |-> (inf.err_msg == No_Err) ;
endproperty : p_complete

/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/

always @ (posedge clk) begin
	
	if (inf.sel_action_valid) begin 
		Asseration4 : assert property (p_begin)
				  else begin 
					$display("==========================================================================") ;
					$display("                       Assertion 4 is violated                            ") ;
					$display("==========================================================================") ;
					$fatal ;
				  end
	end
	else if (store_action == Make_drink) begin 
		Assertion4_MD : assert property (p_make_drink)
					 else begin 
						$display("==========================================================================") ;
						$display("                       Assertion 4 is violated                            ") ;
						$display("==========================================================================") ;
						$fatal ;
					 end
	end
	else if (store_action == Supply) begin 
		Assertion4_S : assert property (p_supply)
					 else begin 
						$display("==========================================================================") ;
						$display("                       Assertion 4 is violated                            ") ;
						$display("==========================================================================") ;
						$fatal ;
					 end
	end
	else if (store_action == Check_Valid_Date) begin 
		Assertion4_CVD : assert property (p_check_date)
					 else begin 
						$display("==========================================================================") ;
						$display("                       Assertion 4 is violated                            ") ;
						$display("==========================================================================") ;
						$fatal ;
					 end
	end
end

property p_begin ;
	@ (posedge clk) inf.sel_action_valid |-> (##[1:4] (inf.type_valid | inf.date_valid)) ;
endproperty : p_begin

property p_make_drink ;
	@ (posedge clk) inf.type_valid |-> (##[1:4] inf.size_valid ##[1:4] inf.date_valid ##[1:4] inf.box_no_valid) ;
endproperty : p_make_drink 

property p_supply ;
	@ (posedge clk) inf.date_valid |-> (##[1:4] inf.box_no_valid ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid) ;
endproperty : p_supply 

property p_check_date ;
	@ (posedge clk) inf.date_valid |-> (##[1:4] inf.box_no_valid) ;
endproperty : p_check_date 

/*
    5. All input valid signals won't overlap with each other. 
*/

always @ (posedge clk) begin 
	Asseration_action_overlap : assert property (p_action_overlap)
							else begin 
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_type_overlap   : assert property (p_type_overlap)
							else begin 
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_size_overlap   : assert property (p_size_overlap)
							else begin 
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_date_overlap   : assert property (p_date_overlap)
							else begin 
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_boxno_overlap  : assert property (p_boxno_overlap)
							else begin 
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_boxsup_overlap : assert property (p_boxsup_overlap)
							else begin 
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
end
	
property p_action_overlap ;
	@ (posedge clk) inf.sel_action_valid |-> ((inf.type_valid | inf.size_valid | inf.date_valid | inf.box_no_valid | inf.box_sup_valid) == 0) ;
endproperty : p_action_overlap 

property p_type_overlap ;
	@ (posedge clk) inf.type_valid |-> ((inf.sel_action_valid | inf.size_valid | inf.date_valid | inf.box_no_valid | inf.box_sup_valid) == 0) ;
endproperty : p_type_overlap 

property p_size_overlap ;
	@ (posedge clk) inf.size_valid |-> ((inf.sel_action_valid | inf.type_valid | inf.date_valid | inf.box_no_valid | inf.box_sup_valid) == 0) ;
endproperty : p_size_overlap 

property p_date_overlap ;
	@ (posedge clk) inf.date_valid |-> ((inf.sel_action_valid | inf.type_valid | inf.size_valid | inf.box_no_valid | inf.box_sup_valid) == 0) ;
endproperty : p_date_overlap 

property p_boxno_overlap ;
	@ (posedge clk) inf.box_no_valid |-> ((inf.sel_action_valid | inf.type_valid | inf.size_valid | inf.date_valid | inf.box_sup_valid) == 0) ;
endproperty : p_boxno_overlap 

property p_boxsup_overlap ;
	@ (posedge clk) inf.box_sup_valid |-> ((inf.sel_action_valid | inf.type_valid | inf.size_valid | inf.date_valid | inf.box_no_valid) == 0) ;
endproperty : p_boxsup_overlap 

/*
    6. Out_valid can only be high for exactly one cycle.
*/

always @ (posedge clk)
	Asseration_outvalid : assert property (p_outvalid)
						else begin 
							$display("==========================================================================") ;
							$display("                        Assertion 6 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end

property p_outvalid ;
	@ (posedge clk) inf.out_valid |-> (##1 (inf.out_valid == 0)) ;
endproperty : p_outvalid

/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/

always @ (posedge clk)
	Asseration_gap : assert property (p_gap)
						else begin 
							$display("==========================================================================") ;
							$display("                        Assertion 7 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end

property p_gap ;
	@ (posedge clk) inf.out_valid |-> (##[1:4] inf.sel_action_valid) ;
endproperty : p_gap

/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/

always @ (posedge clk) begin
	Asseration_check_month : assert property (p_check_month)
						else begin 
							$display("==========================================================================") ;
							$display("                        Assertion 8 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
	
	Asseration_big_month : assert property (p_big_month)
						else begin 
							$display("==========================================================================") ;
							$display("                        Assertion 8 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
	Asseration_small_month : assert property (p_small_month)
						else begin 
							$display("==========================================================================") ;
							$display("                        Assertion 8 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end					
	Asseration_february : assert property (p_February)
						else begin 
							$display("==========================================================================") ;
							$display("                        Assertion 8 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
end

property p_check_month ;
	@ (posedge clk) inf.date_valid |-> (inf.D.d_date[0].M <= 12 && inf.D.d_date[0].M >= 1) ;
endproperty : p_check_month ;

property p_big_month ;
	@ (posedge clk) (inf.date_valid && (inf.D.d_date[0].M == 1 | inf.D.d_date[0].M == 3 |inf.D.d_date[0].M == 5 |inf.D.d_date[0].M == 7 |inf.D.d_date[0].M == 8 |inf.D.d_date[0].M == 10 | inf.D.d_date[0].M == 12)) |-> (inf.D.d_date[0].D <= 31 && inf.D.d_date[0].D >= 1) ;
endproperty : p_big_month

property p_small_month ;
	@ (posedge clk) (inf.date_valid && (inf.D.d_date[0].M == 4 | inf.D.d_date[0].M == 6 |inf.D.d_date[0].M == 9 |inf.D.d_date[0].M == 11)) |-> (inf.D.d_date[0].D <= 30 && inf.D.d_date[0].D >= 1) ;
endproperty : p_small_month

property p_February ;
	@ (posedge clk) (inf.date_valid && (inf.D.d_date[0].M == 2)) |-> (inf.D.d_date[0].D <= 28 && inf.D.d_date[0].D >= 1) ;
endproperty : p_February

/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/

always @ (posedge clk) begin 
	Asseration_only_one : assert property (p_cinvalid_only_one)
						else begin 
							$display("==========================================================================") ;
							$display("                        Assertion 9 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
	Asseration_high_again : assert property (p_cinvalid_high_again)
						else begin 
							$display("==========================================================================") ;
							$display("                        Assertion 9 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end					
end

property p_cinvalid_only_one ;
	@ (posedge clk) inf.C_in_valid |-> (##1 inf.C_in_valid == 0) ; 
endproperty : p_cinvalid_only_one

property p_cinvalid_high_again ;
	@ (posedge clk) store_cinvalid |-> (inf.C_in_valid == 0) ;
endproperty : p_cinvalid_high_again



endmodule






















