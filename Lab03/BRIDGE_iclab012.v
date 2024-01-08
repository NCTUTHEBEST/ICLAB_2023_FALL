//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE = 4'd0, INPUT = 4'd1, DRAM_READ_ADDR = 4'd2, DRAM_READ_DATA = 4'd3 ;
parameter SD_COMMAND = 4'd4, WAIT_RESPONSE = 4'd5, SD_WRITE_WAIT = 4'd6, SD_WRITE = 4'd7 ;
parameter WAIT_DATA_RESPONSE = 4'd8, BUSY = 4'd9, SD_READ = 4'd10, DRAM_WRITE_ADDR = 4'd11 ;
parameter DRAM_WRITE_DATA = 4'd12, DRAM_WRITE_RESPONSE = 4'd13, OUT = 4'd14  ;


//==============================================//
//           reg & wire declaration             //
//==============================================//
reg store_direction ;
reg start_read ;
reg [31:0]  store_addr_dram ;
reg [31:0]  store_addr_sd ;
reg [63:0]  store_dram_data ;
reg [6:0]   encode_crc7 ;
reg [15:0]  encode_crc16 ;
reg [10:0]  command_counter ;
reg [10:0]  wait_counter ;
reg [10:0]  write_wait_counter ;
reg [10:0]  data_counter ;
reg [10:0]  store_sd_data_counter ;
reg [10:0]  out_counter ;
reg [7:0]   data_response ;
reg [64:0]  store_sd_data ;
wire [47:0] send_command ;
wire [87:0] send_data ;
//==============================================//
//                   FSM                        //
//==============================================//
reg [3:0] curr_state, next_state ;

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) curr_state <= IDLE ;
	else curr_state <= next_state ;
end

always @ (*) begin 
	case (curr_state)
		IDLE : begin
			if (in_valid) next_state = INPUT ;
			else next_state = IDLE ;
		end
		INPUT : begin 
			if (store_direction == 0) next_state = DRAM_READ_ADDR ;
			else next_state = SD_COMMAND ;
		end
		DRAM_READ_ADDR : begin 
			if (AR_READY && AR_VALID) next_state = DRAM_READ_DATA ;
			else next_state = DRAM_READ_ADDR ;
		end
		DRAM_READ_DATA : begin 
			if (R_READY && R_VALID) next_state = SD_COMMAND ;
			else next_state = DRAM_READ_DATA ;
		end
		SD_COMMAND : begin 
			if (command_counter == 48) next_state = WAIT_RESPONSE ;
			else next_state = SD_COMMAND ;
		end
		WAIT_RESPONSE : begin 
			if (wait_counter == 7) begin 
				if (store_direction == 0) next_state = SD_WRITE_WAIT ;
				else next_state = SD_READ ;
			end
			else next_state = WAIT_RESPONSE ;
		end
		SD_WRITE_WAIT : begin 
			if (write_wait_counter == 8) next_state = SD_WRITE ;
			else next_state = SD_WRITE_WAIT ;
		end
		SD_WRITE : begin
			if (data_counter == 88) next_state = WAIT_DATA_RESPONSE ;
			else next_state = SD_WRITE ;
		end
		WAIT_DATA_RESPONSE : begin 
			if (data_response == 8'b00000101) next_state = BUSY ;
			else next_state = WAIT_DATA_RESPONSE ;
		end
		BUSY : begin 
			if (MISO == 1) next_state = OUT ;
			else next_state = BUSY ;
		end
		SD_READ : begin 
			if (store_sd_data_counter == 64) next_state = DRAM_WRITE_ADDR ;
			else next_state = SD_READ ;
		end
		DRAM_WRITE_ADDR : begin 
			if (AW_VALID && AW_READY) next_state = DRAM_WRITE_DATA ;
			else next_state = DRAM_WRITE_ADDR ;
		end
		DRAM_WRITE_DATA : begin 
			if (W_READY && W_VALID) next_state = DRAM_WRITE_RESPONSE ;
			else next_state = DRAM_WRITE_DATA ;
		end
		DRAM_WRITE_RESPONSE : begin 
			if (B_VALID && B_READY) next_state = OUT ;
			else next_state = DRAM_WRITE_RESPONSE ;
		end
		OUT : begin
			if (out_counter == 64) next_state = IDLE ;
			else next_state = OUT ;
		end
		default : next_state = IDLE ;
	endcase
end



//==============================================//
//                  design                      //
//==============================================//

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin 
		store_direction <= 0 ;
		store_addr_dram <= 0 ;
		store_addr_sd   <= 0 ;
	end
	else if (in_valid) begin 
		store_direction <= direction ;
		store_addr_dram <= addr_dram ;
		store_addr_sd   <= addr_sd ;
	end
	else begin 
		store_direction <= store_direction ;
		store_addr_dram <= store_addr_dram ;
		store_addr_sd   <= store_addr_sd ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) out_counter <= 0 ;
	else if (next_state == OUT) out_counter <= out_counter + 8 ;
	else out_counter <= 0 ;
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		out_valid <= 0 ;
		out_data  <= 0 ;
	end
	else begin 
		if (next_state == OUT) begin 
			out_valid <= 1 ;
			if (store_direction == 0) out_data <= store_dram_data[63 - out_counter -: 8] ;
			else out_data <= store_sd_data[63 - out_counter -: 8] ;
		end
		else begin 
			out_valid <= 0 ; 
			out_data <= 0 ;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		AW_ADDR  <= 0 ;
		AW_VALID <= 0 ;
	end
	else begin 
		if (AW_VALID && AW_READY) begin 
			AW_ADDR <= 0 ;
			AW_VALID <= 0 ;
		end
		else if (store_direction == 1 && next_state == DRAM_WRITE_ADDR) begin 
			AW_ADDR <= store_addr_dram ;
			AW_VALID <= 1 ;
		end
		else begin 
			AW_ADDR <= 0 ;
			AW_VALID <= 0 ;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		W_VALID <= 0 ; 
		W_DATA  <= 0 ;
	end
	else begin 
		if (W_VALID && W_READY) begin 
			W_DATA <= 0 ;
			W_VALID <= 0 ;
		end
		else if (next_state == DRAM_WRITE_DATA) begin 
			W_DATA <= store_sd_data ;
			W_VALID <= 1 ;
		end
		else begin 
			W_DATA <= 0 ;
			W_VALID <= 0 ;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		B_READY <= 0 ;
	end
	else begin 
		if (B_VALID && B_READY) B_READY <= 0 ;
		else if (next_state == DRAM_WRITE_RESPONSE) B_READY <= 1 ;
		else B_READY <= 0 ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		AR_ADDR  <= 0 ;
		AR_VALID <= 0 ;
	end
	else begin 
		if (AR_VALID && AR_READY) begin 
			AR_ADDR  <= 0 ;
			AR_VALID <= 0 ;
		end
		else if (store_direction == 0 && next_state == DRAM_READ_ADDR) begin 
			AR_ADDR <= store_addr_dram ;
			AR_VALID <= 1 ;
		end
		else begin 
			AR_ADDR  <= 0 ;
			AR_VALID <= 0 ;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		R_READY <= 0 ;
	end
	else begin
		if (R_VALID && R_READY) begin 
			R_READY <= 0 ;
			store_dram_data <= R_DATA ;
		end
		else if (next_state == DRAM_READ_DATA) begin 
			R_READY <= 1 ;
			store_dram_data <= 0 ;
		end
		else begin 
			R_READY <= 0 ;
			store_dram_data <= store_dram_data ;
		end
	end
end


always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		encode_crc7 <= 0 ;
	end
	else begin 
		if (next_state == SD_COMMAND && store_direction == 1) encode_crc7 <= CRC7({2'b01, 6'd17, store_addr_sd}) ;
		else if (next_state == SD_COMMAND && store_direction == 0) encode_crc7 <= CRC7({2'b01, 6'd24, store_addr_sd}) ;
		else encode_crc7 <= encode_crc7 ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		encode_crc16 <= 0 ;
	end
	else begin 
		if (next_state == SD_WRITE) encode_crc16 <= CRC16_CCITT(store_dram_data) ;
		else encode_crc16 <= encode_crc16 ;
	end
end

assign send_command = (store_direction) ? {2'b01, 6'd17, store_addr_sd, encode_crc7, 1'b1} : {2'b01, 6'd24, store_addr_sd, encode_crc7, 1'b1} ;
assign send_data = {8'hFE, store_dram_data, encode_crc16} ;

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) command_counter <= 0 ;
	else if (next_state == SD_COMMAND) command_counter <= command_counter + 1 ;
	else command_counter <= 0 ;
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) wait_counter <= 0 ;
	else if (next_state == WAIT_RESPONSE && MISO == 0) wait_counter <= wait_counter + 1 ;
	else wait_counter <= 0 ;
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) write_wait_counter <= 0 ;
	else if (next_state == SD_WRITE_WAIT) write_wait_counter <= write_wait_counter + 1 ;
	else write_wait_counter <= 0 ;
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) data_counter <= 0 ;
	else if (next_state == SD_WRITE) data_counter <= data_counter + 1 ;
	else data_counter <= 0 ;
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) data_response <= 0 ;
	else if (next_state == WAIT_DATA_RESPONSE) begin 
		data_response[0] <= MISO ;
		data_response[1] <= data_response[0] ;
		data_response[2] <= data_response[1] ;
		data_response[3] <= data_response[2] ;
		data_response[4] <= data_response[3] ;
		data_response[5] <= data_response[4] ;
		data_response[6] <= data_response[5] ;
		data_response[7] <= data_response[6] ;
		
	end
	else data_response <= 0 ;
end


always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		MOSI <= 1 ;
	end
	else begin 
		if (next_state == SD_COMMAND) MOSI <= send_command[47 - command_counter] ;
		else if (next_state == SD_WRITE) MOSI <= send_data[87 - data_counter] ;
		else MOSI <= 1 ;
	end
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) store_sd_data_counter <= 0 ;
	else if (next_state == SD_READ && start_read) store_sd_data_counter <= store_sd_data_counter + 1 ;
	else store_sd_data_counter <= 0 ;
end

always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		store_sd_data <= 0 ;
		start_read <= 0 ;
	end
	else begin 
		if (curr_state == SD_READ && MISO == 0 && start_read == 0) begin 
			start_read <= 1 ;
			store_sd_data <= 0 ;
		end
		else if (next_state == SD_READ && start_read) begin 
			start_read <= 1 ;
			store_sd_data[63 - store_sd_data_counter] <= MISO ;
		end
		else begin 
			start_read <= 0 ;
			store_sd_data <= store_sd_data ;
		end
	end
end


function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;
    input [63:0] data;   
    reg [15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;  // x^7 + x^3 + 1

    begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
endfunction

endmodule