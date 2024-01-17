`timescale 1ns/100ps

`include "Usertype_BEV.sv"
`include "INF.sv"
`include "PATTERN_BEV.sv"

`ifdef RTL
  `include "BEV.sv"
`endif

module TESTBED;
  
  parameter simulation_cycle = 2.3;
  reg  SystemClock;

  INF  inf();
  PATTERN_BEV test_p(.clk(SystemClock), .inf(inf.PATTERN_BEV));
  
  `ifdef RTL
	BEV dut(.clk(SystemClock), .inf(inf.BEV_inf) );
  `endif
  
 //------ Generate Clock ------------
  initial begin
    SystemClock = 0;
	#30
    forever begin
      #(simulation_cycle/2.0)
        SystemClock = ~SystemClock;
    end
  end
  
//------ Dump FSDB File ------------  
initial begin
  `ifdef RTL
    $fsdbDumpfile("BEV.fsdb");
    $fsdbDumpvars(0,"+all");
    $fsdbDumpSVA;
  `endif
end

endmodule
