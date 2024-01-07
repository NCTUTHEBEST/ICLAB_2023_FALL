// ############################################################################
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  // (C) Copyright Laboratory System Integration and Silicon Implementation
  // All Right Reserved
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // ICLAB 2023 Fall
  // Lab01 Exercise		: Supper MOSFET Calculator
  // Author     		: Lin-Hung Lai (lhlai@ieee.org)

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // File Name   : SMC.v
  // Module Name : SMC
  // Release version : V1.0 (Release Date: 2023-09)

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ############################################################################


module SMC(
  // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Output signals
    out_n
);

// ================================================================
  // INPUT AND OUTPUT DECLARATION                         
// ================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
// output [7:0] out_n;         					// use this if using continuous assignment for out_n  // Ex: assign out_n = XXX;
output reg [7:0] out_n; 								// use this if using procedure assignment for out_n   // Ex: always@(*) begin out_n = XXX; end

// ================================================================
   // Wire & Registers 
// ================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [7:0] Id_or_Gm0 ;
wire [7:0] Id_or_Gm1 ;
wire [7:0] Id_or_Gm2 ;
wire [7:0] Id_or_Gm3 ;
wire [7:0] Id_or_Gm4 ;
wire [7:0] Id_or_Gm5 ;

wire [7:0] temp0, temp1, temp2, temp3 ;
wire [7:0] temp4, temp5, temp6, temp7 ;
wire [7:0] temp8, temp9, temp10, temp11 ;
wire [7:0] temp12, temp13, temp14, temp15 ;
wire [7:0] temp16, temp17 ;
wire [7:0] n0, n1, n2, n3, n4, n5 ;
wire [6:0] out ;


// ================================================================
   // DESIGN
// ================================================================

/*Calculate Id or gm*/
Cal_Id_Gm c0 (.mode(mode[0]), .w(W_0), .vgs(V_GS_0), .vds(V_DS_0), .Id_or_Gm(Id_or_Gm0)) ;
Cal_Id_Gm c1 (.mode(mode[0]), .w(W_1), .vgs(V_GS_1), .vds(V_DS_1), .Id_or_Gm(Id_or_Gm1)) ;
Cal_Id_Gm c2 (.mode(mode[0]), .w(W_2), .vgs(V_GS_2), .vds(V_DS_2), .Id_or_Gm(Id_or_Gm2)) ;
Cal_Id_Gm c3 (.mode(mode[0]), .w(W_3), .vgs(V_GS_3), .vds(V_DS_3), .Id_or_Gm(Id_or_Gm3)) ;
Cal_Id_Gm c4 (.mode(mode[0]), .w(W_4), .vgs(V_GS_4), .vds(V_DS_4), .Id_or_Gm(Id_or_Gm4)) ;
Cal_Id_Gm c5 (.mode(mode[0]), .w(W_5), .vgs(V_GS_5), .vds(V_DS_5), .Id_or_Gm(Id_or_Gm5)) ;


/*Sort*/
comparator c6  (.in1(Id_or_Gm0), .in2(Id_or_Gm5), .out1(temp0), .out2(temp1)) ;
comparator c7  (.in1(Id_or_Gm1), .in2(Id_or_Gm3), .out1(temp2), .out2(temp3)) ;
comparator c8  (.in1(Id_or_Gm2), .in2(Id_or_Gm4), .out1(temp4), .out2(temp5)) ;
comparator c9  (.in1(temp2), .in2(temp4), .out1(temp6), .out2(temp7)) ;
comparator c10 (.in1(temp3), .in2(temp5), .out1(temp8), .out2(temp9)) ;
comparator c11 (.in1(temp0), .in2(temp8), .out1(temp10), .out2(temp11)) ;
comparator c12 (.in1(temp7), .in2(temp1), .out1(temp12), .out2(temp13)) ;
comparator c13 (.in1(temp10), .in2(temp6), .out1(n0), .out2(temp14)) ;
comparator c14 (.in1(temp12), .in2(temp11), .out1(temp15), .out2(temp16)) ;
comparator c15 (.in1(temp9), .in2(temp13), .out1(temp17), .out2(n5)) ;
comparator c16 (.in1(temp14), .in2(temp15), .out1(n1), .out2(n2)) ;
comparator c17 (.in1(temp16), .in2(temp17), .out1(n3), .out2(n4)) ;


/*Select according to mode*/
Cal_out c18 (.mode(mode), .n0(n0), .n1(n1), .n2(n2), .n3(n3), .n4(n4), .n5(n5), .out(out)) ;


/*Output*/
always @(*) begin 
	out_n = out ;
end

endmodule


// ================================================================
  // SUB MODULE
// ================================================================

module Cal_Id_Gm (mode, w, vgs, vds, Id_or_Gm);

input  mode ;
input  [2:0] w, vgs, vds ;
output [7:0] Id_or_Gm ;

wire [2:0] vgs_m1 ;
wire [3:0] Gm_satur ;
wire [6:0] vgs_m1_sh_vds ;
wire [3:0] Gm_triode ;
wire [2:0] vds_or_vgs_m1 ;
wire [5:0] squ_out ;
wire [5:0] Cu_triode ;
wire [5:0] mux_temp1 ;
wire [5:0] mux_temp2 ;
wire [5:0] mux_out ;

// assign vgs_m1 = vgs - 1 ;      //  vgs - 1
assign vgs_m1[2] = vgs[2] & (vgs[1] | vgs[0]) ;
assign vgs_m1[1] = ~(vgs[1] ^ vgs[0]) ;
assign vgs_m1[0] = ~vgs[0] ;
assign Gm_satur = vgs_m1 << 1 ;  // (vgs - 1)*2 
four_bit_muti f0 (.in1(Gm_satur), .in2(vds), .out(vgs_m1_sh_vds)) ;
// assign vgs_m1_sh_vds = Gm_satur * vds ;  // 2(vgs - 1)*vds 
assign Gm_triode = vds << 1 ;     //  2*vds

assign vds_or_vgs_m1 = (vgs_m1 > vds) ? vds : vgs_m1 ; 
// two_to_one_mux t0 (.ina(vgs_m1[0]), .inb(vds[0]), .sel(vgs_m1 > vds), .out(vds_or_vgs_m1[0])) ;
// two_to_one_mux t1 (.ina(vgs_m1[1]), .inb(vds[1]), .sel(vgs_m1 > vds), .out(vds_or_vgs_m1[1])) ;
// two_to_one_mux t2 (.ina(vgs_m1[2]), .inb(vds[2]), .sel(vgs_m1 > vds), .out(vds_or_vgs_m1[2])) ;

square_LUT s0 (.in(vds_or_vgs_m1), .squ_out(squ_out)) ; // vds or (vgs-1) square
assign Cu_triode = vgs_m1_sh_vds - squ_out ; // 2(vgs - 1)*vds  - vds^2
assign mux_temp1 = (mode) ? Cu_triode : Gm_triode ;
assign mux_temp2 = (mode) ? squ_out : Gm_satur ;
assign mux_out = (vgs_m1 > vds) ? mux_temp1 : mux_temp2 ;
assign Id_or_Gm = mux_out * w ;
// six_bit_muti f1 (.in1(mux_out), .in2(w), .out(Id_or_Gm)) ;
// assign Id_or_Gm = time_width / 3 ;

endmodule


module comparator (in1, in2, out1, out2) ;

input  [7:0] in1, in2 ;
output [7:0] out1, out2 ;

assign out1 = (in1 > in2) ? in1 : in2 ;
assign out2 = (in1 > in2) ? in2 : in1 ;

endmodule


module Cal_out (mode, n0, n1, n2, n3, n4, n5, out) ;

input [1:0] mode ;
input [7:0] n0, n1, n2, n3, n4, n5 ;
output [6:0] out ;

wire [7:0] n0_or_n3 ;
wire [7:0] n1_or_n4 ;
wire [7:0] n2_or_n5 ;
wire [6:0] div_n0_n3 ;
wire [6:0] div_n1_n4 ;
wire [6:0] div_n2_n5 ;
wire [8:0] three_time ;
wire [8:0] four_time ;
wire [8:0] five_time ;
wire [9:0] add1, add2, add3, add4, add5 ; 
wire [7:0] wire_line ;



assign n0_or_n3 = (mode[1]) ? n0 : n3 ;
assign n1_or_n4 = (mode[1]) ? n1 : n4 ;
assign n2_or_n5 = (mode[1]) ? n2 : n5 ;
div_three_LUT d10 (.in(n0_or_n3), .div_out(div_n0_n3)) ;
div_three_LUT d12 (.in(n1_or_n4), .div_out(div_n1_n4)) ;
div_three_LUT d11 (.in(n2_or_n5), .div_out(div_n2_n5)) ;
// assign div_n0_n3 = n0_or_n3 / 3 ;
// assign div_n1_n4 = n1_or_n4 / 3 ;
// assign div_n2_n5 = n2_or_n5 / 3 ;
assign three_time = div_n0_n3 + {div_n0_n3, 1'b0} ;
assign four_time = {div_n1_n4, 2'b00} ;
assign five_time = div_n2_n5 + {div_n2_n5, 2'b00} ;
assign add1 = (mode[0]) ? three_time : div_n0_n3 ;
assign add2 = (mode[0]) ? four_time : div_n1_n4 ;
assign add3 = (mode[0]) ? five_time : div_n2_n5 ;
// ten_bit_adder t110 (.in1(add1), .in2(add2), .out(add4)) ;
// ten_bit_adder t111 (.in1(add3), .in2(add4), .out(add5)) ;

assign add4 = add1 + add2 ;
assign add5 = add4 + add3 ;
assign wire_line = (mode[0]) ? (add5 >> 2) : add5 ;
// div_three_LUT d1 (.in(wire_line), .div_out(out)) ;
assign out = wire_line / 3 ;

endmodule


module square_LUT (in, squ_out) ;

input  [2:0] in ;
output reg [5:0] squ_out ;

always @ (*) begin 
	case (in)
		3'd0 : squ_out = 0 ;
		3'd1 : squ_out = 1 ;
		3'd2 : squ_out = 4 ;
		3'd3 : squ_out = 9 ;
		3'd4 : squ_out = 16 ;
		3'd5 : squ_out = 25 ;
		3'd6 : squ_out = 36 ;
		3'd7 : squ_out = 49 ;
		default : squ_out = 0 ;
	endcase 
end

endmodule


module  div_three_LUT (in, div_out) ;

input  [7:0] in ;
output reg [6:0] div_out ;

always @ (*) begin 
	case (in)
		8'd0 : div_out = 0 ; 8'd1 : div_out = 0 ; 8'd2 : div_out = 0 ;
		8'd3 : div_out = 1 ; 8'd4 : div_out = 1 ; 8'd5 : div_out = 1 ;
		8'd6 : div_out = 2 ; 8'd7 : div_out = 2 ; 8'd8 : div_out = 2 ;
		8'd9 : div_out = 3 ; 8'd10 : div_out = 3 ; 8'd11 : div_out = 3 ;
		8'd12 : div_out = 4 ; 8'd13 : div_out = 4 ; 8'd14 : div_out = 4 ;
		8'd15 : div_out = 5 ; 8'd16 : div_out = 5 ; 8'd17 : div_out = 5 ;
		8'd18 : div_out = 6 ; 8'd19 : div_out = 6 ; 8'd20 : div_out = 6 ;
		8'd21 : div_out = 7 ; 8'd22 : div_out = 7 ; 8'd23 : div_out = 7 ;
		8'd24 : div_out = 8 ; 8'd25 : div_out = 8 ; 8'd26 : div_out = 8 ;
		8'd27 : div_out = 9 ; 8'd28 : div_out = 9 ; 8'd29 : div_out = 9 ;
		8'd30 : div_out = 10 ; 8'd31 : div_out = 10 ; 8'd32 : div_out = 10 ;
		8'd33 : div_out = 11 ; 8'd34 : div_out = 11 ; 8'd35 : div_out = 11 ;
		8'd36 : div_out = 12 ; 8'd37 : div_out = 12 ; 8'd38 : div_out = 12 ;
		8'd39 : div_out = 13 ; 8'd40 : div_out = 13 ; 8'd41 : div_out = 13 ;
		8'd42 : div_out = 14 ; 8'd43 : div_out = 14 ; 8'd44 : div_out = 14 ;
		8'd45 : div_out = 15 ; 8'd46 : div_out = 15 ; 8'd47 : div_out = 15 ;
		8'd48 : div_out = 16 ; 8'd49 : div_out = 16 ; 8'd50 : div_out = 16 ;
		8'd51 : div_out = 17 ; 8'd52 : div_out = 17 ; 8'd53 : div_out = 17 ;
		8'd54 : div_out = 18 ; 8'd55 : div_out = 18 ; 8'd56 : div_out = 18 ;
		8'd57 : div_out = 19 ; 8'd58 : div_out = 19 ; 8'd59 : div_out = 19 ;
		8'd60 : div_out = 20 ; 8'd61 : div_out = 20 ; 8'd62 : div_out = 20 ;
		8'd63 : div_out = 21 ; 8'd64 : div_out = 21 ; 8'd65 : div_out = 21 ;
		8'd66 : div_out = 22 ; 8'd67 : div_out = 22 ; 8'd68 : div_out = 22 ;
		8'd69 : div_out = 23 ; 8'd70 : div_out = 23 ; 8'd71 : div_out = 23 ;
		8'd72 : div_out = 24 ; 8'd73 : div_out = 24 ; 8'd74 : div_out = 24 ;
		8'd75 : div_out = 25 ; 8'd76 : div_out = 25 ; 8'd77 : div_out = 25 ;
		8'd78 : div_out = 26 ; 8'd79 : div_out = 26 ; 8'd80 : div_out = 26 ;
		8'd81 : div_out = 27 ; 8'd82 : div_out = 27 ; 8'd83 : div_out = 27 ;
		8'd84 : div_out = 28 ; 8'd85 : div_out = 28 ; 8'd86 : div_out = 28 ;
		8'd87 : div_out = 29 ; 8'd88 : div_out = 29 ; 8'd89 : div_out = 29 ;
		8'd90 : div_out = 30 ; 8'd91 : div_out = 30 ; 8'd92 : div_out = 30 ;
		8'd93 : div_out = 31 ; 8'd94 : div_out = 31 ; 8'd95 : div_out = 31 ;
		8'd96 : div_out = 32 ; 8'd97 : div_out = 32 ; 8'd98 : div_out = 32 ;
		8'd99 : div_out = 33 ; 8'd100 : div_out = 33 ; 8'd101 : div_out = 33 ;
		8'd102 : div_out = 34 ; 8'd103 : div_out = 34 ; 8'd104 : div_out = 34 ;
		8'd105 : div_out = 35 ; 8'd106 : div_out = 35 ; 8'd107 : div_out = 35 ;
		8'd108 : div_out = 36 ; 8'd109 : div_out = 36 ; 8'd110 : div_out = 36 ;
		8'd111 : div_out = 37 ; 8'd112 : div_out = 37 ; 8'd113 : div_out = 37 ;
		8'd114 : div_out = 38 ; 8'd115 : div_out = 38 ; 8'd116 : div_out = 38 ;
		8'd117 : div_out = 39 ; 8'd118 : div_out = 39 ; 8'd119 : div_out = 39 ;
		8'd120 : div_out = 40 ; 8'd121 : div_out = 40 ; 8'd122 : div_out = 40 ;
		8'd123 : div_out = 41 ; 8'd124 : div_out = 41 ; 8'd125 : div_out = 41 ;
		8'd126 : div_out = 42 ; 8'd127 : div_out = 42 ; 8'd128 : div_out = 42 ;
		8'd129 : div_out = 43 ; 8'd130 : div_out = 43 ; 8'd131 : div_out = 43 ;
		8'd132 : div_out = 44 ; 8'd133 : div_out = 44 ; 8'd134 : div_out = 44 ;
		8'd135 : div_out = 45 ; 8'd136 : div_out = 45 ; 8'd137 : div_out = 45 ;
		8'd138 : div_out = 46 ; 8'd139 : div_out = 46 ; 8'd140 : div_out = 46 ;
		8'd141 : div_out = 47 ; 8'd142 : div_out = 47 ; 8'd143 : div_out = 47 ;
		8'd144 : div_out = 48 ; 8'd145 : div_out = 48 ; 8'd146 : div_out = 48 ;
		8'd147 : div_out = 49 ; 8'd148 : div_out = 49 ; 8'd149 : div_out = 49 ;
		8'd150 : div_out = 50 ; 8'd151 : div_out = 50 ; 8'd152 : div_out = 50 ;
		8'd153 : div_out = 51 ; 8'd154 : div_out = 51 ; 8'd155 : div_out = 51 ;
		8'd156 : div_out = 52 ; 8'd157 : div_out = 52 ; 8'd158 : div_out = 52 ;
		8'd159 : div_out = 53 ; 8'd160 : div_out = 53 ; 8'd161 : div_out = 53 ;
		8'd162 : div_out = 54 ; 8'd163 : div_out = 54 ; 8'd164 : div_out = 54 ;
		8'd165 : div_out = 55 ; 8'd166 : div_out = 55 ; 8'd167 : div_out = 55 ;
		8'd168 : div_out = 56 ; 8'd169 : div_out = 56 ; 8'd170 : div_out = 56 ;
		8'd171 : div_out = 57 ; 8'd172 : div_out = 57 ; 8'd173 : div_out = 57 ;
		8'd174 : div_out = 58 ; 8'd175 : div_out = 58 ; 8'd176 : div_out = 58 ;
		8'd177 : div_out = 59 ; 8'd178 : div_out = 59 ; 8'd179 : div_out = 59 ;
		8'd180 : div_out = 60 ; 8'd181 : div_out = 60 ; 8'd182 : div_out = 60 ;
		8'd183 : div_out = 61 ; 8'd184 : div_out = 61 ; 8'd185 : div_out = 61 ;
		8'd186 : div_out = 62 ; 8'd187 : div_out = 62 ; 8'd188 : div_out = 62 ;		
		8'd189 : div_out = 63 ; 8'd190 : div_out = 63 ; 8'd191 : div_out = 63 ;
		8'd192 : div_out = 64 ; 8'd193 : div_out = 64 ; 8'd194 : div_out = 64 ;
		8'd195 : div_out = 65 ; 8'd196 : div_out = 65 ; 8'd197 : div_out = 65 ;
		8'd198 : div_out = 66 ; 8'd199 : div_out = 66 ; 8'd200 : div_out = 66 ;
		8'd201 : div_out = 67 ; 8'd202 : div_out = 67 ; 8'd203 : div_out = 67 ;
		8'd204 : div_out = 68 ; 8'd205 : div_out = 68 ; 8'd206 : div_out = 68 ;
		8'd207 : div_out = 69 ; 8'd208 : div_out = 69 ; 8'd209 : div_out = 69 ;
		8'd210 : div_out = 70 ; 8'd211 : div_out = 70 ; 8'd212 : div_out = 70 ;
		8'd213 : div_out = 71 ; 8'd214 : div_out = 71 ; 8'd215 : div_out = 71 ;
		8'd216 : div_out = 72 ; 8'd217 : div_out = 72 ; 8'd218 : div_out = 72 ;
		8'd219 : div_out = 73 ; 8'd220 : div_out = 73 ; 8'd221 : div_out = 73 ;
		8'd222 : div_out = 74 ; 8'd223 : div_out = 74 ; 8'd224 : div_out = 74 ;
		8'd225 : div_out = 75 ; 8'd226 : div_out = 75 ; 8'd227 : div_out = 75 ;
		8'd228 : div_out = 76 ; 8'd229 : div_out = 76 ; 8'd230 : div_out = 76 ;
		8'd231 : div_out = 77 ; 8'd232 : div_out = 77 ; 8'd233 : div_out = 77 ;
		8'd234 : div_out = 78 ; 8'd235 : div_out = 78 ; 8'd236 : div_out = 78 ;
		8'd237 : div_out = 79 ; 8'd238 : div_out = 79 ; 8'd239 : div_out = 79 ;
		8'd240 : div_out = 80 ; 8'd241 : div_out = 80 ; 8'd242 : div_out = 80 ;
		8'd243 : div_out = 81 ; 8'd244 : div_out = 81 ; 8'd245 : div_out = 81 ;
		8'd246 : div_out = 82 ; 8'd247 : div_out = 82 ; 8'd248 : div_out = 82 ;
		8'd249 : div_out = 83 ; 8'd250 : div_out = 83 ; 8'd251 : div_out = 83 ;
		8'd252 : div_out = 84 ; 8'd253 : div_out = 84 ; 8'd254 : div_out = 84 ;
		8'd255 : div_out = 85 ;
	endcase
end


endmodule



module four_bit_muti (in1, in2, out) ;

input [3:0] in1 ;
input [2:0] in2 ;
output [6:0] out ;

wire [5:0] temp ;

five_bit_adder s10 (.in1({1'b0, in1&{4{in2[0]}}}), .in2({in1, 1'b0} & {5{in2[1]}}), .out(temp)) ;
six_bit_adder s11 (.in1(temp), .in2({in1, 2'b00} & {6{in2[2]}}), .out(out)) ;

endmodule


module six_bit_muti (in1, in2, out) ;

input  [5:0] in1 ;
input  [2:0] in2 ;
output [7:0] out ;


wire [7:0] temp ;

seven_bit_adder s0 (.in1({1'b0, in1&{6{in2[0]}}}), .in2({in1, 1'b0} & {7{in2[1]}}), .out(temp)) ;
custom_eight_bit_adder s1 (.in1(temp), .in2({in1, 2'b00} & {8{in2[2]}}), .out(out)) ;

endmodule


module five_bit_adder (in1, in2, out) ;

input  [4:0]in1, in2 ;
output [5:0]out ;

wire [3:0]cin ;

FA m20 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA m21 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA m22 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA m23 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA m24 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(out[5])) ;

endmodule

module six_bit_adder (in1, in2, out) ;

input  [5:0]in1, in2 ;
output [6:0]out ;

wire [4:0]cin ;

FA m30 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA m31 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA m32 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA m33 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA m34 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
FA m35 (.in1(in1[5]), .in2(in2[5]), .cin(cin[4]), .sum(out[5]), .cout(out[6])) ;

endmodule




module seven_bit_adder (in1, in2, out) ;

input  [6:0]in1, in2 ;
output [7:0]out ;

wire [5:0]cin ;

FA m0 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA m1 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA m2 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA m3 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA m4 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
FA m5 (.in1(in1[5]), .in2(in2[5]), .cin(cin[4]), .sum(out[5]), .cout(cin[5])) ;
FA m6 (.in1(in1[6]), .in2(in2[6]), .cin(cin[5]), .sum(out[6]), .cout(out[7])) ;

endmodule

module eight_bit_adder (in1, in2, out) ;

input  [7:0]in1, in2 ;
output [8:0]out ;

wire [6:0]cin ;

FA m7 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA m8 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA m9 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA m10 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA m11 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
FA m12 (.in1(in1[5]), .in2(in2[5]), .cin(cin[4]), .sum(out[5]), .cout(cin[5])) ;
FA m13 (.in1(in1[6]), .in2(in2[6]), .cin(cin[5]), .sum(out[6]), .cout(cin[6])) ;
FA m14 (.in1(in1[7]), .in2(in2[7]), .cin(cin[6]), .sum(out[7]), .cout(out[8])) ;

endmodule

module nine_bit_adder (in1, in2, out) ;

input  [8:0]in1, in2 ;
output [8:0]out ;

wire [8:0]cin ;

FA m47 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA m48 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA m49 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA m50 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA m51 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
FA m52 (.in1(in1[5]), .in2(in2[5]), .cin(cin[4]), .sum(out[5]), .cout(cin[5])) ;
FA m53 (.in1(in1[6]), .in2(in2[6]), .cin(cin[5]), .sum(out[6]), .cout(cin[6])) ;
FA m54 (.in1(in1[7]), .in2(in2[7]), .cin(cin[6]), .sum(out[7]), .cout(cin[7])) ;
FA m55 (.in1(in1[8]), .in2(in2[8]), .cin(cin[7]), .sum(out[8]), .cout(cin[8])) ;

endmodule

module ten_bit_adder (in1, in2, out) ;

input  [9:0]in1, in2 ;
output [9:0]out ;

wire [9:0]cin ;

FA m47 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA m48 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA m49 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA m50 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA m51 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
FA m52 (.in1(in1[5]), .in2(in2[5]), .cin(cin[4]), .sum(out[5]), .cout(cin[5])) ;
FA m53 (.in1(in1[6]), .in2(in2[6]), .cin(cin[5]), .sum(out[6]), .cout(cin[6])) ;
FA m54 (.in1(in1[7]), .in2(in2[7]), .cin(cin[6]), .sum(out[7]), .cout(cin[7])) ;
FA m55 (.in1(in1[8]), .in2(in2[8]), .cin(cin[7]), .sum(out[8]), .cout(cin[8])) ;
FA m155 (.in1(in1[9]), .in2(in2[9]), .cin(cin[8]), .sum(out[9]), .cout(cin[9])) ;

endmodule

module custom_eight_bit_adder (in1, in2, out) ;

input  [7:0]in1, in2 ;
output [7:0]out ;

wire [7:0]cin ;

FA m7 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
FA m8 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
FA m9 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
FA m10 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
FA m11 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
FA m12 (.in1(in1[5]), .in2(in2[5]), .cin(cin[4]), .sum(out[5]), .cout(cin[5])) ;
FA m13 (.in1(in1[6]), .in2(in2[6]), .cin(cin[5]), .sum(out[6]), .cout(cin[6])) ;
FA m14 (.in1(in1[7]), .in2(in2[7]), .cin(cin[6]), .sum(out[7]), .cout(cin[7])) ;

endmodule

module FA (in1, in2, cin, sum, cout) ;

input in1, in2, cin ;
output sum, cout ;

assign sum = in1 ^ in2 ^ cin ;
assign cout = (in1 & in2) | (in1 & cin) | (in2 & cin) ;

endmodule

module two_to_one_mux (ina, inb, sel, out) ;

input ina, inb, sel ;
output out ;

assign out = (~sel & ina) + (sel & inb) ; 

endmodule
// --------------------------------------------------



