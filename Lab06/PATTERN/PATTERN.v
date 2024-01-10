// TA demo pattern~~~~

`ifdef RTL
    `define CYCLE_TIME 12.4
`endif
`ifdef GATE
    `define CYCLE_TIME 12.4
`endif

module PATTERN(
    // Output signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Input signals
    out_valid, 
	out_code
);

// ========================================
// Input & Output
// ========================================
output reg clk, rst_n, in_valid, out_mode;
output reg [2:0] in_weight;

input out_valid, out_code;

//================================================================
// wire & registers 
//================================================================

reg [2:0] weight ;
reg [99:0] golden_ans ;
reg golden_ans_bit;
reg mode ;

// ========================================
// Parameter
// ========================================
integer PATNUM;
integer patcount, total_latency, latency;
integer input_file, output_file;
integer k,i,j,a,t;
integer golden_len ;

//================================================================
// clock
//================================================================
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
// initial
//================================================================

always@(negedge clk)begin
	if(rst_n === 1 && out_code !== 0 && out_valid === 0)begin
        $display("**************************************************************");  
        $display("                            FAIL!                             ");   
        $display("*  The out_code should be reset when your out_valid is low  *");
        $display("**************************************************************");
        $finish;			
	end	
end

initial begin
	input_file=$fopen("../00_TESTBED/input.txt","r");
    output_file=$fopen("../00_TESTBED/output.txt","r");
	reset_task ;
    k = $fscanf(input_file,"%d",PATNUM);

	for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin		
		input_task;
		wait_out_valid_task ;
		check_ans;
	end
	display_pass;
    repeat(3) @(negedge clk);
    $finish;
end



task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    in_weight = 'bx;
	out_mode = 'bx;
    total_latency = 0;
    
    force clk = 0;

    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    
    if(out_valid !== 1'b0 || out_code !== 1'b0) begin //out!==0
        $display("************************************************************");  
        $display("                          FAIL!                              ");    
        $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
        $display("************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
	#CYCLE; release clk;
end endtask

task input_task; begin
	t = $urandom_range(2, 4);
	repeat(t) @(negedge clk);
	golden_ans = 0;
	
	a = $fscanf(input_file, "%h ", mode);
	
	for (i = 0 ; i < 8 ; i = i + 1) begin 
		a = $fscanf(input_file, "%h ", weight);
		in_valid = 1'b1;
		if (i === 0) out_mode = mode ;
		else out_mode = 'dx ;
		in_weight = weight ;
		@(negedge clk);	
	end
    in_valid = 1'b0;	
	in_weight = 'dx ;
end endtask 

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
	latency = latency + 1;
      if( latency == 2000) begin
          $display("********************************************************");     
          $display("                          FAIL!                              ");
          $display("*  The execution latency are over 100 cycles  at %8t   *",$time);//over max
          $display("********************************************************");
	    repeat(2)@(negedge clk);
	    $finish;
      end
     @(negedge clk);
   end
   $display ("             \033[0;32m Lantency %d\033[m         ", latency);
   total_latency = total_latency + latency;
end endtask

task check_ans; begin 
	k = $fscanf(output_file,"%d ",golden_len);   
	k = $fscanf(output_file,"%b ",golden_ans);
	for (i = golden_len-1 ; i >= 0; i = i - 1) begin 
		golden_ans_bit = golden_ans[i];
		if(out_code!==golden_ans[i]) begin
			display_fail;
			$display ("-------------------------------------------------------------------");
			$display("*                            PATTERN NO.%4d 	                      ", patcount);
			$display ("             answer should be : %d , your answer is : %d           ", golden_ans[i], out_code);
			$display ("-------------------------------------------------------------------");
			repeat(5)@(negedge clk);
			$finish ;
		end
		@(negedge clk);
		
	end
	$display ("             \033[0;32mPass Pattern NO. %d\033[m         ", patcount);
end endtask 


task display_fail; begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  OOPS!!                --      / X,X  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  \033[0;31mSimulation FAIL!!\033[m   --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end endtask

task display_pass; begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  Congratulations !!    --      / O.O  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  \033[0;32mSimulation PASS!!\033[m     --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end endtask


endmodule


