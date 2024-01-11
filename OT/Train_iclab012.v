module Train(
    //Input Port
    clk,
    rst_n,
	in_valid,
	data,

    //Output Port
    out_valid,
	result
);

input        clk;
input 	     in_valid;
input        rst_n;
input  [3:0] data;
output   reg out_valid;
output   reg result; 

parameter S_IDLE = 3'b000, S_INPUT_CYCLE = 3'b001, S_INPUT_TRAIN = 3'b010 ;
parameter S_PUSH = 3'b011, S_CHECK = 3'b100, S_OUT = 3'b101 ;

reg [2:0] curr_state, next_state ;
reg [3:0] train_num ;
reg [3:0] in_train [0:9] ;
reg [3:0] store_train[0:9] ;
reg [3:0] target_train[0:9] ;
reg [3:0] count ;
reg [3:0] push_count ;
reg [3:0] store_count; 
reg [3:0] out_count ;
reg [3:0] input_count ;
reg success ;

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) curr_state <= S_IDLE ;
	else curr_state <= next_state ;
end

always @ (*) begin 
	case (curr_state) 
		S_IDLE : begin 
			if (in_valid) next_state = S_INPUT_CYCLE ;
			else next_state = S_IDLE ;
		end
		S_INPUT_CYCLE : next_state = S_INPUT_TRAIN ;
		S_INPUT_TRAIN : begin 
			if (in_valid) next_state = S_INPUT_TRAIN ;
			else next_state = S_PUSH ;
		end
		S_PUSH : begin 
			if (in_train[0] == target_train[out_count]) next_state = S_CHECK ;
			else if (push_count > target_train[out_count]) next_state = S_OUT ;
			else next_state = S_PUSH ;
		end
		S_CHECK : begin 
			if (out_count == train_num) next_state = S_OUT ;
			else if (store_count == 0 || store_train[store_count-1] != target_train[out_count]) next_state = S_PUSH ;
			else next_state = S_CHECK ;
		end
		S_OUT : next_state = S_IDLE ;
		default : next_state = S_IDLE ;
	endcase
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) train_num <= 0 ;
	else begin 
		if (in_valid && next_state == S_INPUT_CYCLE) train_num <= data ;
		else train_num <= train_num ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) input_count <= 0 ;
	else begin 
		if (next_state == S_INPUT_TRAIN) begin 
			input_count <= input_count + 1 ;
		end
		else begin 
			input_count <= 0 ;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 10 ; i = i + 1) begin 
			target_train[i] <= 0 ;
		end
	end
	else begin
		if (curr_state == S_IDLE) begin 
			for (int i = 0 ; i < 10 ; i = i + 1) begin 
				target_train[i] <= 0 ;
			end
		end
		else if (next_state == S_INPUT_TRAIN) begin
			target_train[input_count] <= data ;
		end
		else begin 
			for (int i = 0 ; i < train_num ; i= i+ 1) begin 
				target_train[i] <= target_train[i] ;
			end
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		out_valid <= 0 ;
		result <= 0 ;
	end
	else begin
		if (curr_state == S_OUT) begin 
			if (out_count >= train_num) begin 
				out_valid <= 1 ;
				result <= 1 ;
			end
			else begin 
				out_valid <= 1 ;
				result <= 0 ;
			end
		end
		else begin 
			out_valid <= 0 ;
			result <= 0 ;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) push_count <= 0 ;
	else begin 
		if (curr_state == S_IDLE) push_count <= 0 ;
		else if (curr_state == S_PUSH && push_count < (train_num-1)) push_count <= push_count + 1 ;
		else push_count <= push_count ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) count <= 0 ;
	else begin 
		if (curr_state == S_PUSH) count <= count + 1 ;
	
	
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 10 ; i = i + 1) begin 
			in_train[i] <= 0 ;
		end
	end
	else begin 
		if (curr_state == S_INPUT_CYCLE) begin 
			for (int i = 0 ; i < train_num ; i = i + 1) begin 
				in_train[i] <= i + 1 ;
			end
		end
		else if (curr_state == S_PUSH) begin 
			for (int i = 0 ; i < 9 ; i = i + 1) begin 
				in_train[i] <= in_train[i+1] ;
			end
		end
		else begin 
			for (int i = 0 ; i < train_num ; i = i + 1) begin 
				in_train[i] <= in_train[i];
			end
		end
	end
end


always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) out_count <= 0 ;
	else begin
		if (curr_state == S_IDLE) out_count <= 0 ;
		else if (curr_state == S_CHECK && store_train[store_count-1] == target_train[out_count]) out_count <= out_count + 1 ;
		else out_count <= out_count ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) store_count <= 0 ;
	else begin
		if (curr_state == S_IDLE) store_count <= 0 ;
		else if (curr_state == S_PUSH) store_count <= store_count + 1 ;
		else if (curr_state == S_CHECK) begin 
			if (store_train[store_count-1] == target_train[out_count] && store_count > 0) store_count <= store_count-1 ;
			else store_count <= store_count ;
		end
		else store_count <= store_count ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		for (int i = 0 ; i < 10 ; i=i+1) begin 
			store_train[i] <= 0 ;
		end
	end
	else begin
		if (curr_state == S_IDLE) begin 
			for (int i = 0 ; i < 10 ; i=i+1) begin 
				store_train[i] <= 0 ;
			end
		end
		else if (curr_state == S_PUSH) store_train[store_count] <= in_train[0] ;
		else begin 
			for (int i = 0 ; i < 10 ; i=i+1) begin 
				store_train[i] <= store_train[i] ;
			end
		end
	end
end

endmodule