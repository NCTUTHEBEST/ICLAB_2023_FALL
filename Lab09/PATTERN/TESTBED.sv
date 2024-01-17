/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : TESTBED.sv
Module Name : TESTBED
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`timescale 1ns/1ps

`include "Usertype_BEV.sv"
`include "INF.sv"
`include "PATTERN.sv"
`include "PATTERN_bridge.sv"
`include "PATTERN_BEV.sv"
`include "../00_TESTBED/pseudo_DRAM.sv"

`ifdef RTL
  `include "bridge.sv"
  `include "BEV.sv"
  `define CYCLE_TIME 2.3
`endif

`ifdef GATE
  `include "bridge_SYN.v"
  `include "bridge_Wrapper.sv"
  `include "BEV_SYN.v"
  `include "BEV_Wrapper.sv"
  `define CYCLE_TIME 2.3
`endif

module TESTBED;
  
parameter simulation_cycle = `CYCLE_TIME;
  reg  SystemClock;

  INF             inf();
  PATTERN         test_p(.clk(SystemClock), .inf(inf.PATTERN));
  PATTERN_bridge  test_pb(.clk(SystemClock), .inf(inf.PATTERN_bridge));
  PATTERN_BEV      test_pp(.clk(SystemClock), .inf(inf.PATTERN_BEV));
  pseudo_DRAM     dram_r(.clk(SystemClock), .inf(inf.DRAM)); 

  `ifdef RTL
	bridge  dut_b(.clk(SystemClock), .inf(inf.bridge_inf) );
	BEV      dut_p(.clk(SystemClock), .inf(inf.BEV_inf) );
  `endif
  
  `ifdef GATE
	bridge_svsim  dut_b(.clk(SystemClock), .inf(inf.bridge_inf) );
	BEV_svsim     dut_p(.clk(SystemClock), .inf(inf.BEV_inf) );
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
  `elsif GATE
    $fsdbDumpfile("BEV_SYN.fsdb");
    $sdf_annotate("bridge_SYN.sdf",dut_b.bridge);      
    $sdf_annotate("BEV_SYN.sdf",dut_p.BEV);      
    $fsdbDumpvars(0,"+all");
  `endif
end

endmodule
