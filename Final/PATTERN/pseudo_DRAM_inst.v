`ifdef FUNC
`define LAT_MAX 20
`define LAT_MIN 1
`endif
`ifdef PERF
`define LAT_MAX 500
`define LAT_MIN 300
`endif

module pseudo_DRAM_inst#(parameter ID_WIDTH=4, ADDR_WIDTH=32, DATA_WIDTH=16, BURST_LEN=7) (
// Glbal Signal
  	  input clk,
  	  input rst_n,
// slave interface 
      // axi write address channel 
      // src master
      input wire [ID_WIDTH-1:0]     awid_s_inf,
      input wire [ADDR_WIDTH-1:0] awaddr_s_inf,
      input wire [2:0]            awsize_s_inf,
      input wire [1:0]           awburst_s_inf,
      input wire [BURST_LEN-1:0]   awlen_s_inf,
      input wire                 awvalid_s_inf,
      // src slave
      output reg                 awready_s_inf,
      // -----------------------------
   
      // axi write data channel 
      // src master
      input wire [DATA_WIDTH-1:0]  wdata_s_inf,
      input wire                   wlast_s_inf,
      input wire                  wvalid_s_inf,
      // src slave
      output reg                  wready_s_inf,
   
      // axi write response channel 
      // src slave
      output reg  [ID_WIDTH-1:0]     bid_s_inf,
      output reg  [1:0]            bresp_s_inf,
      output reg                  bvalid_s_inf,
      // src master 
      input wire                  bready_s_inf,
      // -----------------------------
   
      // axi read address channel 
      // src master
      input wire [ID_WIDTH-1:0]     arid_s_inf,
      input wire [ADDR_WIDTH-1:0] araddr_s_inf,
      input wire [BURST_LEN-1:0]   arlen_s_inf,
      input wire [2:0]            arsize_s_inf,
      input wire [1:0]           arburst_s_inf,
      input wire                 arvalid_s_inf,
      // src slave
      output reg                 arready_s_inf,
      // -----------------------------
   
      // axi read data channel 
      // slave
      output reg [ID_WIDTH-1:0]      rid_s_inf,
      output reg [DATA_WIDTH-1:0]  rdata_s_inf,
      output reg [1:0]             rresp_s_inf,
      output reg                   rlast_s_inf,
      output reg                  rvalid_s_inf,
      // master
      input wire                  rready_s_inf
      // -----------------------------
);
// Modify your "dat" in this directory path to initialized DRAM Value

parameter DRAM_p_r = "../00_TESTBED/DRAM/DRAM_inst.dat";
// Modify DRAM_R_LAT           for Initial Read Data Latency, 
//        DRAM_W_LAT           for Initial Write Data Latency
//        MAX_WAIT_READY_CYCLE for control the Upperlimit time to wait Response Ready Signal
//
//        reg [7:0] DRMA_r [0:4*64*1024-1] is the storage element in this simulation model

parameter DRAM_R_LAT = 1, DRAM_W_LAT =1, MAX_WAIT_READY_CYCLE=300;
reg	[7:0]	DRAM_r	[0:8191];   // addr from 00000000 to 000203FF

integer dram_r_lat;
parameter LAT_MAX = `LAT_MAX;
parameter LAT_MIN = `LAT_MIN;

integer dram_w_lat;
integer ready_wait_cnt ;
integer read_cnt ;
integer wait_cnt ,x, y,z;
reg [ID_WIDTH-1:0]      wid_s_inf;
// ---------------------  address channel handling init -----------------------
// Recording 
reg [15:0]            awid_lock;          // for master0 ~ master15
reg [ADDR_WIDTH-1:0] awaddr_m0_m1_r[0:15];// for master0 ~ master15
reg [BURST_LEN-1:0]  awlen_m0_m1_r [0:15];// for master0 ~ master15
reg [BURST_LEN:0]  awcnt_m0_m1_r [0:15];// for master0 ~ master15  for counting write data match burst length
reg [15:0]            resp_undone;        // for master0 ~ master15                        
                                                                  
reg [15:0]            arid_lock;          // for master0 ~ master15                        
reg [ADDR_WIDTH-1:0] araddr_m0_m1_r[0:15];// for master0 ~ master15
reg [BURST_LEN-1:0]  arlen_m0_m1_r [0:15];// for master0 ~ master15

reg [31:0] DRAM_addr_write, DRAM_addr_read;
integer file_DRAM_O;
initial begin
   $readmemh(DRAM_p_r, DRAM_r);
   arid_lock = 0;
   rid_s_inf = 0; rdata_s_inf = 0; rresp_s_inf = 0; rlast_s_inf = 0; rvalid_s_inf = 0;
   arready_s_inf=0;

   awid_lock = 0;
   for(z=0; z <16 ; z= z+1)begin
       awaddr_m0_m1_r[z] = 0;
       awlen_m0_m1_r [z] = 0;
       awcnt_m0_m1_r [z] = 0;
       araddr_m0_m1_r[z] = 0;
       arlen_m0_m1_r [z] = 0;
   end
   
   resp_undone = 0;

   bvalid_s_inf =0;
   bid_s_inf    =0;
   bresp_s_inf  =0;
end

integer w_lock;		//after AWVALID&WAVALID, will count DRAM latency, when w_lock = DRAM_W_LAT, DRAM will start to output data
initial begin
   forever @(posedge clk)begin
       if(awready_s_inf & awvalid_s_inf) 
		    w_lock    =  0 ;
       else if(wvalid_s_inf & wready_s_inf === 0 & awcnt_m0_m1_r[wid_s_inf]===0 )begin
		    w_lock    =  w_lock + 1 ;
	   end
	   else ;
   end
end
//  Write Channel Handling 
      // ack received write addr command
      always@(posedge clk or negedge rst_n)begin
	      if(!rst_n)begin
                awready_s_inf <= 1'b0 ;
          	    wready_s_inf  <= 1'b0 ;
	      end
	      else begin
                awready_s_inf <= (awvalid_s_inf) ? 1'b1 : 1'b0;

	            if(wvalid_s_inf & wready_s_inf & wlast_s_inf)begin
          	          wready_s_inf  <= 1'b0 ;
	        	end
	        	else if(wvalid_s_inf==1 && 
					    awcnt_m0_m1_r[wid_s_inf]==0 && 
					    awid_lock[wid_s_inf]==1 
						&& (w_lock > dram_w_lat))begin// first write
          	          wready_s_inf  <= 1'b1 ;
	        	end
	        	else begin
          	          wready_s_inf  <= wready_s_inf;
	        	end
          end
      end
      
	  // write addr
      initial begin
	     forever @(posedge clk)begin
            if(awvalid_s_inf === 1 && awready_s_inf===1)begin  // aw_ack
             write_addr_check;
             update_write_info;
            end
         end
      end
      
	  // write data
      initial begin
	     forever @(posedge clk)begin
            if(wvalid_s_inf === 1 && wready_s_inf===1)begin  
             write_mem;
            end
         end
      end
      
	  // write resp
      initial begin // if there is 2 last signal
          forever @(posedge clk) begin// when last signal rise
		     for (x = 0 ; x < 16 ; x = x + 1)begin
                 if(resp_undone[x] === 1)begin 
                       write_resp(x);
                 end
			 end
          end
      end

//  Read Channel Handling 
      // ack received read addr command
      
	  // read addr
      initial begin
          forever @(posedge clk)
		  begin
               if(arvalid_s_inf == 1)begin  
      	         axi_read_addr_check;
      		     // New Command
			     //if(arid_lock[arid_s_inf]===1) begin
				 //    MemoryError;
				 //    $display("DRAM Fail: Sorry, This memory didn't support outstanding read transaction");
				 //    $finish;
		         //    wait(arid_lock[arid_s_inf]==0);
		         //    arid_lock[arid_s_inf] = 1;
			     //end
		         //arid_lock[arid_s_inf] = 1;
			     arready_s_inf = 1;
      		     update_read_info;
				 @(posedge clk);
			     arready_s_inf = 0;
      	       end
			   else begin
		         arready_s_inf = 0;
			   end
          end
	  end
	  // read data
      initial begin // if there is 2 last signal
          forever @(posedge clk) begin// when last signal rise
		        for (y = 0 ; y < 16 ; y = y + 1)begin
                    if(arid_lock[y] === 1)begin 
			              @(posedge clk);
						  dram_r_lat = $urandom_range(LAT_MIN, LAT_MAX);
                          read_mem(y);
                    end
			    end
          end
      end

// ------------------------  task for write address ------------------------		
task update_write_info;begin
     awaddr_m0_m1_r[awid_s_inf] = awaddr_s_inf;
     awlen_m0_m1_r [awid_s_inf] = awlen_s_inf;
	 awcnt_m0_m1_r [awid_s_inf] = 0;
     wid_s_inf = awid_s_inf;
	 dram_w_lat = $urandom_range(LAT_MIN, LAT_MAX);
end endtask

task write_addr_check; begin// check consecutive burst req 
     if(awid_lock[awid_s_inf]===1)begin
	     MemoryError;
	     $display("DRAM Fail : Address Write ID is busy with Previous Write Operation(Your AXI should avoid Consecutive Write Burst !!!)");
         #(30);
		 $finish;
	 end
	 else begin
	     if(awburst_s_inf ===`DEF_INCR)
		     awid_lock[awid_s_inf] = 1;// lock the awid for Burst
		 else if (awsize_s_inf !== `DEF_BUSRT_SIZE) begin
			 MemoryError;
	         $display("DRAM Fail: This DRAM Only Support BURST_size == 010 Operation: Your burst: %b", awsize_s_inf);
             #(30);
		     $finish;
		 end
		 else begin
		     MemoryError;
	         $display("DRAM Fail: This DRAM Only Support INCR mode Type Operation: Your burst: %b", awburst_s_inf);
             #(30);
		     $finish;
		 end
	 end
end endtask


// ---------------------  task for write data channel handling-----------------------
task write_mem;
integer i;
begin
         DRAM_addr_write  = awaddr_m0_m1_r[wid_s_inf] + awcnt_m0_m1_r[wid_s_inf]*2; //*4 because every data is 32 bit, and every address store 1byte/8bit data (4*8=32)
		 /* modify invalid ADDR */
		 if((DRAM_addr_write[31:12] !== 'b1)||((DRAM_addr_write+1)>32'h00001fff))begin
		     MemoryError;
	         $display("DRAM Fail: WRITING  Segmentation Fault  ");
	         $display("           Write address should be from 0x0000_1000 ~ 0x0000_1FFF ");
	         $display("           Your write address :   %h", DRAM_addr_write);
             #(30);
			 $finish;
		 end

	     
		 /* modify data length */
		 DRAM_r[DRAM_addr_write+ 0] =  wdata_s_inf[  7:  0];
	     DRAM_r[DRAM_addr_write+ 1] =  wdata_s_inf[ 15:  8];
	     //DRAM_r[DRAM_addr_write+ 2] =  wdata_s_inf[ 23: 16];
	     //DRAM_r[DRAM_addr_write+ 3] =  wdata_s_inf[ 31: 24];
		 //DRAM_r[DRAM_addr_write+ 4] =  wdata_s_inf[ 39: 32];
	     //DRAM_r[DRAM_addr_write+ 5] =  wdata_s_inf[ 47: 40];
	     //DRAM_r[DRAM_addr_write+ 6] =  wdata_s_inf[ 55: 48];
	     //DRAM_r[DRAM_addr_write+ 7] =  wdata_s_inf[ 63: 56];
		 //DRAM_r[DRAM_addr_write+ 8] =  wdata_s_inf[ 71: 64];
	     //DRAM_r[DRAM_addr_write+ 9] =  wdata_s_inf[ 79: 72];
	     //DRAM_r[DRAM_addr_write+10] =  wdata_s_inf[ 87: 80];
	     //DRAM_r[DRAM_addr_write+11] =  wdata_s_inf[ 95: 88];
		 //DRAM_r[DRAM_addr_write+12] =  wdata_s_inf[103: 96];
	     //DRAM_r[DRAM_addr_write+13] =  wdata_s_inf[111:104];
	     //DRAM_r[DRAM_addr_write+14] =  wdata_s_inf[119:112];
	     //DRAM_r[DRAM_addr_write+15] =  wdata_s_inf[127:120];


		 if( wlast_s_inf === 1'b1 )begin
		     if (awcnt_m0_m1_r[wid_s_inf] === (awlen_m0_m1_r[wid_s_inf]))begin// Last Write Data, unlock , clean counter
                awid_lock[wid_s_inf]     = 0;
				awcnt_m0_m1_r[wid_s_inf] = 0;
				resp_undone[wid_s_inf]   = 1;
			 end
			 else begin
		        MemoryError;
	            $display("DRAM Fail : last signal not matched with Burst len : \nBurst addr (hex)%h \nBurst len (hex)%h",awaddr_m0_m1_r[wid_s_inf],awlen_s_inf[wid_s_inf]);
				$finish;
			 end
		 end
		 else begin
		    awcnt_m0_m1_r[wid_s_inf] = awcnt_m0_m1_r[wid_s_inf] + 1;
		 end

		 if (awcnt_m0_m1_r[wid_s_inf] >  (awlen_m0_m1_r[wid_s_inf]))begin // Write Data more than expected
		        MemoryError;
	            $display("DRAM Fail : Your Write Data is not matched with Burst len : wdata cnt: %d , awlen (hex)%d",awcnt_m0_m1_r[wid_s_inf],awlen_s_inf[wid_s_inf]);
				$finish;
		 end

		 `ifdef NOISY
	     $display("DRAM WRITING:  addr- %h  data- %d   wdata-%d",DRAM_addr_write,{//DRAM_r[DRAM_addr_write+3],
						                                                          //DRAM_r[DRAM_addr_write+2],
                                                                                  DRAM_r[DRAM_addr_write+1],
                                                                                  DRAM_r[DRAM_addr_write] },
																				  wdata_s_inf);
         `endif
end endtask

// ---------------------  write resp channel handling-----------------------
task write_resp; input [3:0] wid_for_resp;
begin
     // set the response signal
     bid_s_inf    = wid_for_resp;
	 bresp_s_inf  = `DEF_OKAY;
	 bvalid_s_inf = 1'b1;
	 @(posedge clk);

	 ready_wait_cnt = 0;
     while( (bready_s_inf & bvalid_s_inf) === 0)begin
	    if(ready_wait_cnt === MAX_WAIT_READY_CYCLE)begin
		        MemoryError;
	            $display("DRAM Fail : write resp ready wait over %d cycles",ready_wait_cnt );
	            $display("You could modify MAX_WAIT_READY_CYCLE to have more cycle to wait.\nIf you believe your design is correct XD !");
                #(30);
				$finish;
		end
	    @(posedge clk);
	    ready_wait_cnt = ready_wait_cnt + 1;
	 end

     // clear the response signal
	 resp_undone[wid_for_resp] = 0;
     bid_s_inf    = 0;
	 bresp_s_inf  = 0;
	 bvalid_s_inf = 1'b0;
end endtask


// ---------------------  read address channel handling-----------------------
task update_read_info;begin
     araddr_m0_m1_r[arid_s_inf] = araddr_s_inf;
     arlen_m0_m1_r [arid_s_inf] = arlen_s_inf;
end endtask


task axi_read_addr_check;begin// check consecutive burst req 
     if(arid_lock[arid_s_inf]===1)begin
		 MemoryError;
	     $display("DRAM Fail: Address Read ID is busy with Previous Burst(You should avoid Consecutive Read Address Request !!!)");
         #(30);
		 $finish;
	 end
	 else begin
	     if(arburst_s_inf ===`DEF_INCR)
		     arid_lock[arid_s_inf] = 1;// lock the awid for Burst
		 else if (arsize_s_inf !== `DEF_BUSRT_SIZE) begin
			 MemoryError;
	         $display("DRAM Fail: This DRAM Only Support BURST_size == 010 Operation: Your burst: %b", arsize_s_inf);
             #(30);
		     $finish;
		 end
		 else begin
		     MemoryError;
	         $display("DRAM Fail: This DRAM Only Support BURST Type Operation: Your burst: %b", awburst_s_inf);
             #(30);
		     $finish;
		 end
	 end
end endtask
   
// ---------------------  read data channel handling-----------------------

task read_mem; input [3:0]rid_for_read;
begin 
      rid_s_inf = rid_for_read;
      if(arid_lock[rid_for_read]===1'b1) begin// addr confirm
         read_cnt = 0;
	     for (read_cnt=0 ; read_cnt <= arlen_m0_m1_r[rid_for_read] ; read_cnt = read_cnt + 1 )begin
			 if(read_cnt==0)
                //repeat(DRAM_R_LAT)@(posedge clk); 
                repeat(dram_r_lat)@(posedge clk); 

             DRAM_addr_read  = araddr_m0_m1_r[rid_s_inf] + read_cnt*2;
		     if( DRAM_addr_read[31:12] === 0)begin
		         MemoryError;
	             $display("DRAM : Reading Segmentation Fault  ");
	             $display("       Read address should be from 0x0000_1000 ~ 0x0000_1fff ");
	             $display("       Your read address :   %h", DRAM_addr_read);
	             $display("       You're not supposed to hack the kernel !!!");
                 #(30);
		         $finish;
		     end
		     if( (DRAM_addr_read[31:12] !== 1) /*&& 
			     (DRAM_addr_read[31:16] !== 2)   */)begin
		         MemoryError;
	             $display("DRAM : Reading Segmentation Fault  ");
	             $display("       Read address should be from 0x0000_1000 ~ 0x0000_1fff ");
	             $display("       Your read address :   %h", DRAM_addr_read);
                 #(30);
		         $finish;
		     end
		     if( (DRAM_addr_read + 1) > 32'h00001fff    )begin                       //* new, modify by TzuYun 
		         MemoryError;
	             $display("DRAM : Reading Segmentation Fault  ");
	             $display("       Read address should be from 0x0000_1000 ~ 0x0000_1fff ");
	             $display("       Your read address :   %h", DRAM_addr_read);
                 #(30);
		         $finish;
		     end
			 // ---------------- output signal ---------------------
		     if(read_cnt === arlen_m0_m1_r[rid_for_read])begin // last read
                arid_lock[rid_s_inf] = 0; // clean lock
				rlast_s_inf          = 1;
			 end
			 else begin
				rlast_s_inf          = 0;
			 end
			 rid_s_inf     = rid_for_read;
		     rdata_s_inf = {/*DRAM_r[DRAM_addr_read+15],
					        DRAM_r[DRAM_addr_read+14],
					        DRAM_r[DRAM_addr_read+13],
					        DRAM_r[DRAM_addr_read+12],
					        DRAM_r[DRAM_addr_read+11],
					        DRAM_r[DRAM_addr_read+10],
					        DRAM_r[DRAM_addr_read+9],
					        DRAM_r[DRAM_addr_read+8],
					        DRAM_r[DRAM_addr_read+7],
					        DRAM_r[DRAM_addr_read+6],
					        DRAM_r[DRAM_addr_read+5],
					        DRAM_r[DRAM_addr_read+4],*/
					        //DRAM_r[DRAM_addr_read+3],
					        //DRAM_r[DRAM_addr_read+2],
							DRAM_r[DRAM_addr_read+1],
							DRAM_r[DRAM_addr_read+0]};
		     rresp_s_inf   = `DEF_OKAY;
		     rvalid_s_inf  = 1;
			 `ifdef NOISY
	         $display("DRAM READING:  addr- %h  data- %d",DRAM_addr_read ,{//DRAM_r[DRAM_addr_read+3],
						                                                   //DRAM_r[DRAM_addr_read+2],
                                                                           DRAM_r[DRAM_addr_read+1],
                                                                           DRAM_r[DRAM_addr_read] });
             `endif
			    @(posedge clk);

			 // ---------------- wait ready ---------------------
			    wait_ready;
		 end
             rlast_s_inf   = 0;
             rid_s_inf     = 0;
             rdata_s_inf   = 0;
		     rvalid_s_inf  = 0;
		     rresp_s_inf   = 0;
             rid_s_inf     = 0;
      end
	  else begin
		 MemoryError;
	     $display("Fail DRAM : No read address req before.(Master Fail )");
         #(30);
		 $finish;
	  end
end endtask


task wait_ready; 
begin
     wait_cnt =0;
     while( rready_s_inf === 1'b0)begin
	    if(wait_cnt === MAX_WAIT_READY_CYCLE)begin
		        MemoryError;
	            $display("Fail DRAM :  wait rready  over %d cycles",wait_cnt );
                #(30);
				$finish;
		end
	    @(posedge clk);
	    wait_cnt = wait_cnt + 1;
	 end
end endtask
   
task MemoryError; begin
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@                                                                                                         @");
$display("@                #                                                                                        @");
$display("@        #      #                                                                                         @");
$display("@              #                                                                                          @");
$display("@              #                                                                                          @");
$display("@              #                                                                                          @");
$display("@              #                                                                                          @");
$display("@        #      #                                                                                         @");
$display("@                #                                                                                        @");
$display("@                                                                                                         @");
$display("@                                                                                                         @");
$display("@                                                                                                         @");
$display("@                                                                                                         @");
$display("@                                                                                                         @");
$display("@        Your DRAM_inst ran into a problem and needs to restart. We're just collecting some error info ,  @");
$display("@        and we'll restart for you (0 percentage complete)                                                @");
$display("@                                                                                                         @");
$display("@        if you'd like to know more, you can search online later for this error                           @");
$display("@                                                                                                         @");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
end endtask
endmodule

