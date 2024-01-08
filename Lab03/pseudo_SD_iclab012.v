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
//   File Name   : pseudo_SD.v
//   Module Name : pseudo_SD
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_SD (
    clk,
    MOSI,
    MISO
);

input clk;
input MOSI;
output reg MISO;

parameter SD_p_r = "../00_TESTBED/SD_init.dat";
integer count ;
integer wait_count, response_count ;
reg [63:0] SD [0:65535] ;

//------------------------------
// 			for all 
//------------------------------
reg start_bit, trans_bit ;
reg [5:0]  command ;
reg [31:0] address ;
reg [6:0]  store_crc7 ;
reg [6:0]  checker_crc7 ;
reg end_bit ;
//------------------------------

//------------------------------
// 			for read 
//------------------------------
reg [15:0] send_crc16 ;
reg [63:0] send_data ;
reg [87:0] send_information ;
integer give_count ;
//------------------------------

//------------------------------
// 			for write 
//------------------------------
integer get_data_count ;
integer wait_count2 ;
integer busy_count ;
reg [63:0] receive_data ;
reg [15:0] store_crc16 ;
reg [15:0] checker_crc16 ;
//------------------------------

initial begin 
	$readmemh(SD_p_r, SD);
	MISO = 1 ;
	count = 0 ;
	wait_count = 0 ;
	wait_count2 = 0 ;
	response_count = 0 ;
	give_count = 0 ;
	get_data_count = 0 ;
	busy_count = 0 ;
end

always @ (*) begin 
	if (MOSI == 0) begin 
		reset_task ;
		get_command_format ;
		check_command_format ;
		get_address ;
		check_address ;
		get_CRC7 ;
		check_CRC7 ;
		get_end_bit ;
		wait_response ;
		give_response ;
		hold_stable ;
		if (command == 17) begin // read form
			wait_read_data ;
			read_data ;
			give_data ;
		end
		else begin // write form
			wait_response_and_check_unit ;
			get_data ;
			get_CRC16 ;
			check_CRC16 ;
			give_data_response ;
			write_data_and_busy ;
		end
	end
end



//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////

task reset_task; begin 
	count = 0 ;
	wait_count = 0 ;
	wait_count2 = 0 ;
	response_count = 0 ;
	give_count = 0 ;
	get_data_count = 0 ;
	busy_count = 0 ;
end endtask

task get_command_format; begin 
	while (count < 8) begin 
		@(posedge clk) ;
		if (count == 0) begin 
			start_bit = MOSI ;
		end
		else if (count == 1) begin 
			trans_bit = MOSI ;
		end
		else if (count >= 2) begin 
			command[7 - count] = MOSI ;
		end
		count = count + 1 ;
	end
end endtask

task check_command_format; begin 
	if (start_bit != 0 || (command !== 24 && command !== 17) || trans_bit != 1) begin 
		$display("SPEC SD-1 FAIL") ;
        $finish ;
	end
end endtask

task get_address; begin 
	while (count < 40) begin 
		@(posedge clk) ;
		address[39 - count] = MOSI ;
		count = count + 1 ;
	end
end endtask

task check_address; begin 
	if (address < 0 || address > 65535) begin 
		$display("SPEC SD-2 FAIL") ;
        $finish ;
	end
end endtask

task get_CRC7; begin 
	while (count < 47) begin 
		@(posedge clk) ;
		store_crc7[46 - count] = MOSI ;
		count = count + 1 ;
	end
end endtask

task check_CRC7; begin 
	checker_crc7 = CRC7({2'b01, command, address}) ;
	if (store_crc7 !== checker_crc7) begin 
		$display("SPEC SD-3 FAIL") ;
        $finish ;
	end
end endtask

task get_end_bit; begin 
	while (count < 48) begin 
		@(posedge clk) ;
		end_bit = MOSI ;
		count = count + 1 ;
	end
	if (end_bit != 1) begin 
		$display("SPEC SD-1 FAIL") ;
        $finish ;
	end
end endtask

task wait_response; begin 
	while (wait_count < 16) begin 
		wait_count = wait_count + 1 ;
		@(posedge clk) ;
	end
end endtask

task give_response; begin 
	wait_count = 0 ;
	while (response_count < 8) begin 
		MISO = 0 ;
		response_count = response_count + 1 ;
		@(posedge clk) ;
	end
end endtask

task hold_stable; begin 
	MISO = 1 ;
end endtask

task wait_read_data; begin 
	while (wait_count < 256) begin 
		wait_count = wait_count + 1 ;
		@(posedge clk) ;
	end
end endtask

task read_data; begin 
	send_data = SD[address] ;
	send_crc16 = CRC16_CCITT(send_data) ;
	send_information = {8'hFE, send_data, send_crc16} ;
end endtask

task give_data; begin 
	while (give_count < 88) begin 
		MISO = send_information[87 - give_count] ;
		give_count = give_count + 1 ;
		@(posedge clk) ;
	end
	MISO = 1 ;
end endtask

task wait_response_and_check_unit; begin 
	while (MOSI == 1) begin 
		wait_count2 = wait_count2 + 1 ;
		@(posedge clk) ;
	end
	if (wait_count2 < 16 || wait_count2 % 8 !== 0) begin 
		$display("SPEC SD-5 FAIL") ;
        $finish ;
	end
end endtask

task get_data; begin 
	while (get_data_count < 64) begin 
		@(posedge clk) ;
		receive_data[63 - get_data_count] = MOSI ;
		get_data_count = get_data_count + 1 ;
	end
end endtask

task get_CRC16; begin 
	while (get_data_count < 80) begin 
		@(posedge clk) ;
		store_crc16[79 - get_data_count] = MOSI ;
		get_data_count = get_data_count + 1 ;
	end
end endtask

task check_CRC16; begin 
	checker_crc16 = CRC16_CCITT(receive_data) ;
	// $display ("receive_data = %h", receive_data) ;
	// $display ("checker_crc16 = %h", checker_crc16) ;
	if (store_crc16 !== checker_crc16) begin 
		$display("SPEC SD-4 FAIL") ;
        $finish ;
	end
end endtask

task give_data_response; begin 
	MISO = 0 ;
	@(posedge clk) ;
	MISO = 0 ;
	@(posedge clk) ;
	MISO = 0 ;
	@(posedge clk) ;
	MISO = 0 ;
	@(posedge clk) ;
	MISO = 0 ;
	@(posedge clk) ;
	MISO = 1 ;
	@(posedge clk) ;
	MISO = 0 ;
	@(posedge clk) ;
	MISO = 1 ;
	@(posedge clk) ;
end endtask


task write_data_and_busy; begin 
	while (busy_count < 32) begin 
		MISO = 0 ;
		busy_count = busy_count + 1 ;
		@(posedge clk) ;
	end
	SD[address] = receive_data ;
	MISO = 1 ;
end endtask


//////////////////////////////////////////////////////////////////////




task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                 Error message from pseudo_SD.v                        *");
end endtask

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

