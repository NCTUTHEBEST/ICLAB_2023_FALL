`define CYCLE_TIME 12 //cycle
`define PAT_NUM 17

module PATTERN(
    //Input Port
    clk,
    rst_n,
	in_valid,
	mode,
    xi,
    yi,

    //Output Port
    out_valid,
	xo,
	yo
);


/* Input to design */
output reg   clk, rst_n, in_valid;
output reg   [1:0]   mode;
output reg   [7:0]   xi;
output reg   [7:0]   yi;

/* Output to pattern */
input         out_valid;
input [7:0]   xo, yo;

/* define clock cycle */
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

/* parameter and integer*/
integer patnum = `PAT_NUM;
integer i_pat, i, j, a, t;
integer f_in, f_ans,f_xy,f_out,f_area_in,f_area_out;
integer latency;
integer total_latency;
integer golden_cost;
integer out_num;
integer golden_out_num[0:16];
integer seed = 214 ;
/* reg declaration */
reg signed[15:0] one, two, three, four;
reg signed[15:0] golden;
reg signed[7:0] golden_x,golden_y;
reg signed[7:0] a1,a2,b1,b2,c1,c2,d1,d2;
//reg signed[7:0] a,b,c,d,e,f,g,h;
reg [15:0] golden_area;


always@(*)begin
	if(in_valid && out_valid)begin
        $display("************************************************************");  
        $display("                          FAIL!                             ");    
        $display("*  The out_valid cannot overlap with in_valid   *"           );
        $display("************************************************************");
		//repeat(9)@(negedge clk);
		$finish;			
	end	
end

initial begin
  f_in  = $fopen("../00_TESTBED/input.txt", "r");
  f_ans = $fopen("../00_TESTBED/ans.txt", "r");
  f_xy  = $fopen("../00_TESTBED/coordinate_in.txt", "r");
  f_out = $fopen("../00_TESTBED/coordinate_out.txt", "r"); 
  f_area_in  = $fopen("../00_TESTBED/area_in.txt", "r");
  f_area_out = $fopen("../00_TESTBED/area_out.txt", "r");
  reset_task;
  //a = $fscanf(f_in, "%d", patnum);

  golden_out_num = {162,512,512,510,510,512,510,202,16482,398,4,4,4,4,33153,32897,33151};
  $display ("------------------------------------------------------------------------------------------------------------------------------------------");
  $display ("                                                    START TRAPEZOID RENDERING!                                                            ");
  $display ("------------------------------------------------------------------------------------------------------------------------------------------"); 
  
  for (i_pat = 0; i_pat < patnum; i_pat = i_pat+1)
	begin
		input_task1;
        wait_out_valid_task;
        check_ans_task1;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",i_pat ,latency);
    end

  $display ("------------------------------------------------------------------------------------------------------------------------------------------");
  $display ("                                                    START CIRCLE AND LINE RELATION!                                                       ");
  $display ("------------------------------------------------------------------------------------------------------------------------------------------"); 
  
  for (i_pat = 0; i_pat < 119; i_pat = i_pat+1)
	begin
		input_task2;
        wait_out_valid_task;
        check_ans_task2;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",i_pat ,latency);
    end	

  $display ("------------------------------------------------------------------------------------------------------------------------------------------");
  $display ("                                                    START AREA CALCULATION!                                                               ");
  $display ("------------------------------------------------------------------------------------------------------------------------------------------"); 	
  for (i_pat = 0; i_pat < 94; i_pat = i_pat+1)
	begin
		input_task3;
        wait_out_valid_task;
        check_ans_task3;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",i_pat ,latency);
    end		
	
  YOU_PASS_task;
  
end


task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    xi = 'bx;
    yi = 'bx;
	mode = 'bx;
    total_latency = 0;

    force clk = 0;

    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    
    if(out_valid !== 1'b0 || xo !== 'b0 || yo !== 'b0) begin //out!==0
        $display("************************************************************");  
        $display("                          FAIL!                              ");    
        $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
        $display("************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
	#CYCLE; release clk;
end endtask


task input_task1; begin
    a = $fscanf(f_in, "%h ", one);
	a = $fscanf(f_in, "%h ", two);
	a = $fscanf(f_in, "%h ", three);
	a = $fscanf(f_in, "%h ", four);	
    t = $urandom_range(1, 4);
	//$display("one = %h", one);
	//$display("two = %h", two);
	repeat(t) @(negedge clk);
	in_valid = 1'b1;
	mode = 2'b00;	
	xi = one[15:8];
	yi = one[7:0];
	@(negedge clk);

	xi = two[15:8];
	yi = two[7:0];
	@(negedge clk);	

	xi = three[15:8];
	yi = three[7:0];
	@(negedge clk);	
	
	xi = four[15:8];
	yi = four[7:0];
	@(negedge clk);		


    in_valid = 1'b0;	
	mode = 'bx;	
	xi = 'bx;
    yi = 'bx;
    
end endtask 


task input_task2; begin
    a = $fscanf(f_xy, "%d ", a1);
	a = $fscanf(f_xy, "%d ", a2);
    a = $fscanf(f_xy, "%d ", b1);
	a = $fscanf(f_xy, "%d ", b2);
    a = $fscanf(f_xy, "%d ", c1);
	a = $fscanf(f_xy, "%d ", c2);
    a = $fscanf(f_xy, "%d ", d1);
	a = $fscanf(f_xy, "%d ", d2);	
    t = $urandom_range(1, 4);
	//$display("a1 = %h", a1);
	//$display("a2 = %h", a2);
	//$display("b1 = %h", b1);
	//$display("b2 = %h", b2);	
	repeat(t) @(negedge clk);
	in_valid = 1'b1;
	mode = 2'b01;		
	xi = a1;
	yi = a2;
	@(negedge clk);
			
	xi = b1;
	yi = b2;
	@(negedge clk);	
		
	xi = c1;
	yi = c2;
	@(negedge clk);	
			
	xi = d1;
	yi = d2;
	@(negedge clk);		
		
    in_valid = 1'b0;	
	mode = 'bx;	
	xi = 'bx;
    yi = 'bx;
    
end endtask 

task input_task3; begin
    a = $fscanf(f_area_in, "%d ", a1);
	a = $fscanf(f_area_in, "%d ", a2);
    a = $fscanf(f_area_in, "%d ", b1);
	a = $fscanf(f_area_in, "%d ", b2);
    a = $fscanf(f_area_in, "%d ", c1);
	a = $fscanf(f_area_in, "%d ", c2);
    a = $fscanf(f_area_in, "%d ", d1);
	a = $fscanf(f_area_in, "%d ", d2);
	//$display("a1 = %d", a1);
	//$display("a2 = %d", a2);
	//$display("b1 = %d", b1);
	//$display("b2 = %d", b2);	
	//$display("c1 = %d", c1);
	//$display("c2 = %d", c2);
	//$display("d1 = %d", d1);
	//$display("d2 = %d", d2);	
	repeat(t) @(negedge clk);
	in_valid = 1'b1;
	mode = 2'b10;		
	xi = a1;
	yi = a2;
	@(negedge clk);
			
	xi = b1;
	yi = b2;
	@(negedge clk);	
			
	xi = c1;
	yi = c2;
	@(negedge clk);	
		
	xi = d1;
	yi = d2;
	@(negedge clk);		
		
    in_valid = 1'b0;	
	mode = 'bx;	
	xi = 'bx;
    yi = 'bx;
    
end endtask 

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
	latency = latency + 1;
      if( latency == 100) begin
          $display("********************************************************");     
          $display("                          FAIL!                              ");
          $display("*  The execution latency are over 100 cycles  at %8t   *",$time);//over max
          $display("********************************************************");
	    repeat(2)@(negedge clk);
	    $finish;
      end
     @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task1; begin

	out_num = 0;	
	while(out_valid === 1)begin
		a = $fscanf(f_ans, "%h", golden);
		golden_x = golden[15:8];
		golden_y = golden[7:0];		
		if(xo !== golden[15:8] || yo !== golden[7:0])begin
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                      FAIL!                                                               ");
			$display ("                                                                 Golden coordinate :    %d      %d                                        ",golden_x, golden_y); 
			$display ("                                                                 Your coordinate :      %d      %d                                        ",xo, yo);
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(9) @(negedge clk);
			$finish;		
		end
		else begin		
			//$write("PASS coordinate %1d", out_num);
			//$display ("                                                                 Golden coordinate :    %d      %d                                        ",golden_x, golden_y); //show ans			
			@(negedge clk);
			out_num = out_num + 1;
		end
	end	
	if(golden_out_num[i_pat]!==out_num)begin
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                      FAIL!                                                               ");
			$display ("                                                                 Golden coordinate amounts:    %d                                         ",golden_out_num[i_pat]);
			$display ("                                                                 Your coordinate amounts :     %d                                         ",out_num);
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(9) @(negedge clk);
			$finish;			
	end
	//$display("golden_out_num = ",golden_out_num[i_pat]);
	
end endtask


task check_ans_task2; begin

	while(out_valid === 1)begin
		a = $fscanf(f_out, "%d", golden);
		if(xo !== golden[15:8] || yo !== golden[7:0])begin
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                      FAIL!                                                               ");
			$display ("                                                                 Golden out :    %4d                                                       ",golden); //show ans
			$display ("                                                                 Your   out :    %4d                                                       ",{xo,yo}); //show output
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(9) @(negedge clk);
			$finish;		
		end
		else begin
			@(negedge clk);
		end
	end	
	
end endtask

task check_ans_task3; begin


	golden_area = 0;
	while(out_valid === 1)begin
		a = $fscanf(f_area_out, "%d", golden_area);
		if( {xo,yo} !== golden_area )begin
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                      FAIL!                                                               ");
			$display ("                                                                 Coordiante :    A:(%1d,%1d) B:(%1d,%1d) C:(%1d,%1d) D:(%1d,%1d)          ",a1,a2,b1,b2,c1,c2,d1,d2); //show ans			
			$display ("                                                                 Golden out :    %4d                                                       ",golden_area); //show ans
			$display ("                                                                 Your   out :    %4d                                                       ",{xo,yo}); //show output
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(9) @(negedge clk);
			$finish;		
		end
		else begin
			@(negedge clk);
		end
	end	
	
end endtask

task YOU_PASS_task; begin
    $display ("----------------------------------------------------------------------------------------------------------------------");
    $display ("                                                  Congratulations!                                                                       ");
    $display ("                                           You have passed all patterns!                                                                 ");
    $display ("                                           Your execution cycles = %5d cycles                                                            ", total_latency);
    $display ("                                           Your clock period = %.1f ns                                                               ", CYCLE);
    $display ("                                           Total Latency = %.1f ns                                                               ", total_latency*CYCLE);
    $display ("----------------------------------------------------------------------------------------------------------------------");     
    repeat(2)@(negedge clk);
    $finish;
end endtask


endmodule





