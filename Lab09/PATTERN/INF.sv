/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : INF.sv
Module Name : INF
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

interface INF();
    import  usertype::*;

    // BEV.sv INPUT from PATTERN
    logic rst_n;
    logic sel_action_valid;
    logic type_valid;
    logic size_valid;
    logic date_valid;
    logic box_no_valid;
    logic box_sup_valid;
    Data D;

    // BEV.sv INPUT from BRIDGE
    logic C_out_valid;      
    logic [63:0] C_data_r;  

    // BEV.sv OUTPUT TO PATTERN
    logic out_valid;
    Error_Msg err_msg;
    logic complete;

    // BEV.sv OUTPUT TO BRIDGE
    logic [7:0] C_addr;
    logic [63:0] C_data_w;
    logic C_in_valid;
    logic C_r_wb;

    // BRIDGE to DRAM
    logic AR_VALID, R_READY, AW_VALID, W_VALID, B_READY;
    logic [16:0] AR_ADDR, AW_ADDR;
    logic [63:0] W_DATA;

    // DRAM to BRIDGE
    logic AR_READY, R_VALID, AW_READY, W_READY, B_VALID;
    logic [1:0] R_RESP, B_RESP;
    logic [63:0] R_DATA;

    modport PATTERN(
        input out_valid, err_msg, complete,
        output rst_n, sel_action_valid, type_valid, size_valid, date_valid, box_no_valid, box_sup_valid, D
    );

    modport DRAM(
	    input  AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	    output AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
    );

    modport BEV_inf(
        input rst_n, sel_action_valid, type_valid, size_valid, date_valid, box_no_valid, box_sup_valid, D,
            C_out_valid, C_data_r,
        output out_valid, err_msg, complete,
            C_addr, C_data_w, C_in_valid, C_r_wb
    );

    modport bridge_inf(
	    input  rst_n,
		       C_addr, C_data_w, C_in_valid, C_r_wb,
			   AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
        output C_out_valid, C_data_r, 
		       AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY
    );

    // This setting will be used during demo
	// You can change the modport if you want to test the design independently
    modport PATTERN_BEV(
        input rst_n, sel_action_valid, type_valid, size_valid, date_valid, box_no_valid, box_sup_valid, D,  // from PATTERN
            out_valid, err_msg, complete,  // to PATTERN
            C_out_valid, C_data_r,  // from bridge
            C_addr, C_data_w, C_in_valid, C_r_wb // to bridge
    );

	// This setting will be used during demo
	// You can change the modport if you want to test the design independently
	modport PATTERN_bridge(
	    input  rst_n, C_in_valid,
		       C_out_valid, C_data_r, AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY, 
			   C_addr, C_data_w, C_r_wb,
			   AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
    );
    
endinterface //INF()