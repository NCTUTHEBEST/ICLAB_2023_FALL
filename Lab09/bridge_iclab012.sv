module bridge(input clk, INF.bridge_inf inf);

//================================================================
// State 
//================================================================
typedef enum logic [2:0] {
	S_IDLE,
	S_READ_DATA,
	S_WRITE_DATA,
	S_WAIT_RESP,
	S_OUT
} state_t ;

state_t curr_state, next_state ;

always_ff @ (posedge clk or negedge inf.rst_n) begin : c_state
	if (!inf.rst_n) curr_state <= S_IDLE ;
	else curr_state <= next_state ;
end

always_comb begin : n_state
	case (curr_state)
		S_IDLE : begin 
			if (inf.AR_READY) next_state = S_READ_DATA ;
			else if (inf.AW_READY) next_state = S_WRITE_DATA ;
			else next_state = S_IDLE ;
		end
		S_READ_DATA : begin 
			if (inf.R_VALID) next_state = S_OUT ;
			else next_state = S_READ_DATA ;
		end
		S_WRITE_DATA : begin 
			if (inf.W_READY) next_state = S_WAIT_RESP ;
			else next_state = S_WRITE_DATA ;
		end
		S_WAIT_RESP : begin 
			if (inf.B_VALID) next_state = S_OUT ;
			else next_state = S_WAIT_RESP ;
		end
		S_OUT : next_state = S_IDLE ;
		default : next_state = S_IDLE ;
	endcase 
end

//================================================================
// Design 
//================================================================
logic [16:0] store_addr ;
logic [63:0] store_data ;

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) store_addr <= 0 ;
	else begin 
		if (inf.C_in_valid) store_addr <= 65536 + ({9'd0, (inf.C_addr)} << 3) ;
		else store_addr <= store_addr ;
	end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) store_data <= 0 ;
	else begin 
		if (inf.C_in_valid) store_data <= inf.C_data_w ;
		else if (inf.R_VALID) store_data <= inf.R_DATA ;
		else store_data <= store_data ;
	end
end

always_comb begin : DRAM_ARADDR
	inf.AR_ADDR = store_addr ;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin : DRAM_ARVALID
	if (!inf.rst_n) inf.AR_VALID <= 0 ;
	else begin 
		if (inf.C_in_valid) begin 
			// if (inf.C_r_wb && (~inf.AR_READY)) begin 
				// inf.AR_VALID <= 1 ;
			// end
			// else begin 
				// inf.AR_VALID <= 0 ;
			// end
			inf.AR_VALID <= inf.C_r_wb ;
		end
		else begin 
			if (inf.AR_READY) inf.AR_VALID <= 0 ;
			else inf.AR_VALID <= inf.AR_VALID ;
		end
	end
end

always_comb begin : DRAM_R_READY
	if (curr_state == S_READ_DATA) inf.R_READY = 1 ;
	else inf.R_READY = 0 ;
	// inf.R_READY = 1 ;
end

always_comb begin : DRAM_AWADDR
	inf.AW_ADDR = store_addr ;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin : DRAM_AWVALID
	if (!inf.rst_n) inf.AW_VALID <= 0 ;
	else begin 
		if (inf.C_in_valid) begin 
			// if (~(inf.C_r_wb) && (~inf.AW_READY)) begin 
				// inf.AW_VALID <= 1 ;
			// end
			// else begin 
				// inf.AW_VALID <= 0 ;
			// end
			inf.AW_VALID <= ~(inf.C_r_wb) ;
		end
		else begin 
			if (inf.AW_READY) inf.AW_VALID <= 0 ;
			else inf.AW_VALID <= inf.AW_VALID ;
		end
	end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin : DRAM_W_VALID
	if (!inf.rst_n) inf.W_VALID <= 0 ;
	else begin 
		if (curr_state == S_WRITE_DATA) begin 
			if (~inf.W_READY) inf.W_VALID <= 1 ;
			else inf.W_VALID <= 0 ;
		end
		else inf.W_VALID <= 0 ;
	end
end

always_comb begin : DRAM_W_DATA
	inf.W_DATA = store_data ;
end

always_comb begin : DRAM_B_READY
	if (curr_state == S_WAIT_RESP) inf.B_READY = 1 ;
	else inf.B_READY = 0 ;
	// inf.B_READY = 1 ;
end

// always_comb begin : C_out
	// if (curr_state == S_OUT) begin 
		// inf.C_out_valid = 1 ;
		// inf.C_data_r = store_data ;
	// end
	// else begin 
		// inf.C_out_valid = 0 ;
		// inf.C_data_r = 0 ;
	// end
// end

always_ff @ (posedge clk or negedge inf.rst_n) begin : C_out
	if (!inf.rst_n) begin 
		inf.C_out_valid <= 0 ;
		inf.C_data_r <= 0 ;
	end
	else begin
		if (curr_state == S_OUT) begin 
			inf.C_out_valid <= 1 ;
			inf.C_data_r <= store_data ;
		end
		else begin 
			inf.C_out_valid <= 0 ;
			inf.C_data_r <= 0 ;
		end
	end
end

endmodule