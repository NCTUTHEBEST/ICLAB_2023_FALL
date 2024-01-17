`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
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

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [12:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;


integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat;
integer temp ;
integer i, count, t, out_valid_time ;


reg one ;
reg [12:0]two ;
reg [15:0]three ;
reg [63:0]veri_DRAM[0:8191] ;
reg [63:0]veri_SD  [0:65535] ;
reg [63:0]transfer_data ;
reg [63:0]design_transfer_data ;
reg [7:0] out_data_check ;

always @ (*) begin
	if(rst_n !== 0 && out_valid === 0 && out_data !== 0)begin
        $display("SPEC MAIN-2 FAIL");
		//repeat(9)@(negedge clk);
		$finish;			
	end	
end

always @ (*) begin 
	if (R_VALID === 1 && R_READY === 1) begin 
		design_transfer_data = R_DATA ;
	end
	else if (W_VALID === 1 && W_READY === 1) begin 
		design_transfer_data = W_DATA ;
	end
	else begin 
		design_transfer_data = design_transfer_data ;
	end
end

always @ (*) begin 
	if (out_valid === 1) begin 
		for (count = 0 ; count < 8192 ; count = count + 1) begin 
			// if (count == 8191) begin 
				// $display("ininininininininini") ;
			// end
			if (u_DRAM.DRAM[count] !== veri_DRAM[count]) begin 
				$display ("SPEC MAIN-6 FAIL");
				// repeat(9) @(negedge clk);
				$finish;	
			end
		end
		for (count = 0 ; count < 65536 ; count = count + 1) begin 
			// if (count == 65535) begin 
				// $display("456464646464546456456") ;
			// end
			if (u_SD.SD[count] !== veri_SD[count]) begin 
				$display ("SPEC MAIN-6 FAIL");
				// repeat(9) @(negedge clk);
				$finish;	
			end
		end
	end
end 

initial begin
	out_valid_time = 0 ;
    pat_read = $fopen("../00_TESTBED/Input.txt", "r") ;
	
	// read the intial memory value into dram and SD card
	$readmemh("../00_TESTBED/DRAM_init.dat", veri_DRAM) ;
	$readmemh("../00_TESTBED/SD_init.dat"  , veri_SD) ;
	
    reset_signal_task ;

    i_pat = 0 ;
    total_latency = 0 ;
    temp = $fscanf(pat_read, "%d", PAT_NUM) ;
    for (i_pat = 1 ; i_pat <= PAT_NUM ; i_pat = i_pat + 1) begin
		reset_pattern_signal;
        input_task ;
        wait_out_valid_task ; 
        check_ans_task ;
        total_latency = total_latency + latency ;
        $display("PASS PATTERN NO.%4d", i_pat) ;
    end
    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM);
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);
    YOU_PASS_task;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////

task reset_signal_task; begin 
    rst_n = 1'b1;
    in_valid = 1'b0;
	direction = 1'bx ;
	addr_dram = 13'dx ;
	addr_sd = 16'dx ;
	
    total_latency = 0;

    force clk = 0;

    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    if(out_valid !== 1'b0 || out_data !== 0 || AW_ADDR !== 0 || AW_VALID !== 0 || W_VALID !== 0 || W_DATA !== 0 || B_READY !== 0 || AR_ADDR !== 0 || AR_VALID !== 0 || R_READY !== 0 || MOSI !== 1) begin //out!==0
        $display("SPEC MAIN-1 FAIL");
        // repeat(2) #CYCLE;
        $finish;
    end
    
	#CYCLE; release clk;
end endtask

task reset_pattern_signal; begin 
    design_transfer_data = 0 ;
	out_valid_time = 0 ;
end endtask

task input_task; begin
    temp = $fscanf(pat_read, "%d ", one) ;
	temp = $fscanf(pat_read, "%d ", two) ;
	temp = $fscanf(pat_read, "%d ", three) ;
    t = $urandom_range(1, 4) ;
	//$display("one = %h", one);
	//$display("two = %h", two);
	repeat(t) @(negedge clk);
	in_valid = 1'b1;
	direction = one ;
	addr_dram = two ;
	addr_sd = three ;
	if (one == 0) begin 
		transfer_data = u_DRAM.DRAM[two] ;
		veri_SD[three] = transfer_data ;
	end
	else begin 
		transfer_data = u_SD.SD[three] ;
		veri_DRAM[two] = transfer_data ;
	end
	@(negedge clk);

    in_valid = 1'b0 ;	
	direction = 'bx ;	
	addr_dram = 'bx ;
    addr_sd = 'bx ;
    
end endtask 

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
		latency = latency + 1;
		if(latency == 10000) begin
			$display("SPEC MAIN-3 FAIL");
			repeat(2)@(negedge clk);
			$finish;
		end
		@(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
	i = 0 ;
	out_data_check = transfer_data[63:56] ;
	while (out_valid === 1) begin	
		out_valid_time = out_valid_time + 1 ;
		if (out_valid_time > 8) begin 
			$display ("SPEC MAIN-4 FAIL");
			repeat(9) @(negedge clk);
			$finish;
		end
		else if(out_data !== out_data_check)begin
			$display ("SPEC MAIN-5 FAIL");
			repeat(9) @(negedge clk);
			$finish;		
		end
		else begin	
			@(negedge clk);	
			i = i + 8 ;
			out_data_check = transfer_data[63 - i -: 8] ;
		end
		
	end	
	if (out_valid_time < 8) begin 
		$display ("SPEC MAIN-4 FAIL");
		repeat(9) @(negedge clk);
		$finish;	
	end
	

end endtask

//////////////////////////////////////////////////////////////////////

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule



