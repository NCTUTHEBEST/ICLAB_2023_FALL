module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1 ;
input clk1_handshake_flag2 ;
output clk1_handshake_flag3 ;
output clk1_handshake_flag4 ;

reg [31:0] seed_reg ;

// always @ (posedge clk or negedge rst_n) begin 
	// if (!rst_n) seed_reg <= 0 ;
	// else begin 
		// if (in_valid) seed_reg <= seed_in ;
		// else seed_reg <= seed_reg ;
	// end
// end 

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		seed_out <= 0 ;
		out_valid <= 0 ;
	end
	else begin 
		if (in_valid && out_idle) begin 
			seed_out <= seed_in ;
			out_valid <= 1 ;
		end
		else begin 
			seed_out  <= seed_out ;
			out_valid <= 0 ;
		end
	end
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output out_valid;
output [31:0] rand_num;
output busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
input clk2_fifo_flag3;
input clk2_fifo_flag4;

reg  [31:0] mid_result ;
wire [31:0] mid_result1, mid_result2 ;

reg flag ;

assign busy = (flag && ~fifo_full) ? 1 : 0 ;
assign mid_result1 = mid_result  ^ (mid_result << 13) ; 
assign mid_result2 = mid_result1 ^ (mid_result1 >> 17) ;
assign rand_num    = mid_result2 ^ (mid_result2 << 5) ;
assign out_valid = (flag && ~fifo_full) ? 1 : 0 ;

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) flag <= 0 ;
	else begin 
		if (in_valid) flag <= in_valid ;
		else if (clk2_fifo_flag1) flag <= 0 ;
		else flag <= flag ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		mid_result <= 0 ;
	end
	else begin
		if (flag == 0) begin 
			if (in_valid) mid_result <= seed ;
			else mid_result <= 0 ;
		end
		else begin 
			if (~fifo_full) mid_result <= rand_num ;
			else mid_result <= mid_result ;
		end
	end
end

endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
input fifo_clk3_flag3;
input fifo_clk3_flag4;

reg [8:0] clk3_counter ;

assign fifo_rinc = (fifo_empty) ? 0 : 1 ;

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) clk3_counter <= 0 ;
	else begin 
		if (fifo_clk3_flag2 && clk3_counter < 256) clk3_counter <= clk3_counter + 1 ;
		else clk3_counter <= 0 ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) out_valid <= 0 ;
	else begin 
		if (fifo_clk3_flag2 && clk3_counter < 256) out_valid <= 1 ;
		else out_valid <= 0 ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) rand_num <= 0 ;
	else begin 
		if (fifo_clk3_flag2 && clk3_counter < 256) rand_num <= fifo_rdata ;
		else rand_num <= 0 ;
	end
end

endmodule