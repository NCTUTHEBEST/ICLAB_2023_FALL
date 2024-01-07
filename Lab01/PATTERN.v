//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab01 Exercise		: Supper MOSFET Calculator
//   Author     		: Lin-Hung Lai (lhlai@ieee.org)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME 20.0

`ifdef RTL
	`define PATTERN_NUM 40
`endif
`ifdef GATE
	`define PATTERN_NUM 40
`endif

module PATTERN(
  // Output signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Input signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg [2:0] W_0, V_GS_0, V_DS_0;
output reg [2:0] W_1, V_GS_1, V_DS_1;
output reg [2:0] W_2, V_GS_2, V_DS_2;
output reg [2:0] W_3, V_GS_3, V_DS_3;
output reg [2:0] W_4, V_GS_4, V_DS_4;
output reg [2:0] W_5, V_GS_5, V_DS_5;
output reg [1:0] mode;
input [7:0] out_n;

//================================================================
// parameters & integer
//================================================================
integer PATNUM;
integer patcount;
integer input_file, output_file;
integer k,i,j;

//================================================================
// wire & registers 
//================================================================
reg [2:0] input_reg[17:0];
reg [9:0] golden_ans;

//================================================================
// clock
//================================================================
reg clk;
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
// Hint
//================================================================
// if you want to use c++/python to generate test data, here is 
// a sample format for you. You can change for your convinience.
/* input.txt format
1. [PATTERN_NUM] 

repeat(PATTERN_NUM)
	1. [mode] 
	2. [W_0 V_GS_0 V_DS_0]
	3. [W_1 V_GS_1 V_DS_1]
	4. [W_2 V_GS_2 V_DS_2]
	5. [W_3 V_GS_3 V_DS_3]
	6. [W_4 V_GS_4 V_DS_4]
	7. [W_5 V_GS_5 V_DS_5]
*/

/* output.txt format
1. [out_n]
*/

//================================================================
// initial
//================================================================
initial begin
	input_file=$fopen("../00_TESTBED/input.txt","r");
    output_file=$fopen("../00_TESTBED/output.txt","r");
    W_0 = 'bx; V_GS_0 = 'bx; V_DS_0 = 'bx;
    W_1 = 'bx; V_GS_1 = 'bx; V_DS_1 = 'bx;
    W_2 = 'bx; V_GS_2 = 'bx; V_DS_2 = 'bx;
    W_3 = 'bx; V_GS_3 = 'bx; V_DS_3 = 'bx;
    W_4 = 'bx; V_GS_4 = 'bx; V_DS_4 = 'bx;
    W_5 = 'bx; V_GS_5 = 'bx; V_DS_5 = 'bx;
	mode = 'dx;
    repeat(5) @(negedge clk);
    k = $fscanf(input_file,"%d",PATNUM);
    // PATNUM = `PATTERN_NUM;
	
	$monitor ("i am monitor") ;
	$display ("i am display") ;
	$strobe  ("strobe  => %d", W_0)  ;
	$monitor ("monitor => %d", W_0) ;
	
	for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin		
        input_task;
        repeat(1) @(negedge clk);
		check_ans;
		repeat($urandom_range(3, 5)) @(negedge clk);
	end
	display_pass;
    repeat(3) @(negedge clk);
    $finish;
end

//================================================================
// task
//================================================================

task input_task; begin
    k = $fscanf(input_file,"%d",mode);
    for(i=0;i<18;i=i+1) 
	    k = $fscanf(input_file,"%d",input_reg[i]);
    W_0 = input_reg[0]; V_GS_0 = input_reg[1]; V_DS_0 = input_reg[2];
    W_1 = input_reg[3]; V_GS_1 = input_reg[4]; V_DS_1 = input_reg[5];
    W_2 = input_reg[6]; V_GS_2 = input_reg[7]; V_DS_2 = input_reg[8];
    W_3 = input_reg[9]; V_GS_3 = input_reg[10]; V_DS_3 = input_reg[11];
    W_4 = input_reg[12]; V_GS_4 = input_reg[13]; V_DS_4 = input_reg[14];
    W_5 = input_reg[15]; V_GS_5 = input_reg[16]; V_DS_5 = input_reg[17];

end endtask

task check_ans; begin
    k = $fscanf(output_file,"%d",golden_ans);    
    if(out_n!==golden_ans) begin
        display_fail;
        $display ("-------------------------------------------------------------------");
		$display("*                            PATTERN NO.%4d 	                      ", patcount);
        $display ("             answer should be : %d , your answer is : %d           ", golden_ans, out_n);
        $display ("-------------------------------------------------------------------");
        #(100);
        $finish ;
    end
    else $display ("             \033[0;32mPass Pattern NO. %d\033[m         ", patcount);
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



//================================================================
// Supplement
//================================================================
// if you want to use verilog to impliment a test data, here is 
// a sample code for you. Notice that use it carefully.
//================================================================

// task gen_data; begin
//     in_n0=$random(seed)%'d16;
//     in_n1=$random(seed)%'d16;
//     in_n2=$random(seed)%'d16;
//     in_n3=$random(seed)%'d16;
//     in_n4=$random(seed)%'d16;
//     in_n5=$random(seed)%'d16;
//     opt = $random(seed)%'d8;
//     equ = $random(seed)%'d4; 
// end endtask

// task gen_golden; begin
// 	n[0]=(opt[0])? {in_n0[3],in_n0}:{1'b0,in_n0};
//     n[1]=(opt[0])? {in_n1[3],in_n1}:{1'b0,in_n1};
//     n[2]=(opt[0])? {in_n2[3],in_n2}:{1'b0,in_n2};
//     n[3]=(opt[0])? {in_n3[3],in_n3}:{1'b0,in_n3};
//     n[4]=(opt[0])? {in_n4[3],in_n4}:{1'b0,in_n4};
//     n[5]=(opt[0])? {in_n5[3],in_n5}:{1'b0,in_n5};
//     $display("opt: %d equ: %d in_n0[0]=%d in_n0[1]=%d in_n0[2]=%d in_n0[3]=%d in_n0[4]=%d in_n0[5]=%d",opt, equ,n[0],n[1],n[2],n[3],n[4],n[5]);
    
//     for(i=0;i<5;i=i+1) begin
//         for(j=0;j<5-i;j=j+1) begin
//             if(n[j]>n[j+1]) begin
//                 temp=n[j];
//                 n[j]=n[j+1];
//                 n[j+1]=temp;
//             end
//         end
//     end
//     if(opt[1]) begin
//         temp = n[0];
//         n[0] = n[5];
//         n[5] = temp;
//         temp = n[1];
//         n[1] = n[4];
//         n[4] = temp;
//         temp = n[2];
//         n[2] = n[3];
//         n[3] = temp;
//     end
//     $display("n[0]=%d n[1]=%d n[2]=%d n[3]=%d n[4]=%d n[5]=%d",n[0],n[1],n[2],n[3],n[4],n[5]);
//     avg = (n[0] + n[5]) / 2;
//     $display(" avg = %d",avg);
//     if(opt[2]) begin
//         n[0]=n[0]-avg;
//         n[1]=n[1]-avg;
//         n[2]=n[2]-avg;
//         n[3]=n[3]-avg;
//         n[4]=n[4]-avg;
//         n[5]=n[5]-avg;
//     end
//     //$display("n[0]=%d n[1]=%d n[2]=%d n[3]=%d n[4]=%d n[5]=%d",n[0],n[1],n[2],n[3],n[4],n[5]);
//     temp_0 = (n[0] - (n[1] * n[2]) + n[5]) / 3;
//     temp_1 = (n[3] * 3) - (n[0] * n[4]);
//     out_n_ans=(equ==0)?temp_0:(temp_1[8])? ~temp_1+1:temp_1;
// end endtask

endmodule

