// //############################################################################
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //    (C) Copyright System Integration and Silicon Implementation Laboratory
// //    All Right Reserved
// //		Date		: 2023/10
// //		Version		: v1.0
// //   	File Name   : SORT_IP.v
// //   	Module Name : SORT_IP
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //############################################################################
// module SORT_IP #(parameter IP_WIDTH = 7) (
    // // Input signals
    // IN_character, IN_weight,
    // // Output signals
    // OUT_character
// );

// // ===============================================================
// // Input & Output
// // ===============================================================
// input [IP_WIDTH*4-1:0]  IN_character;
// input [IP_WIDTH*5-1:0]  IN_weight;

// output [IP_WIDTH*4-1:0] OUT_character;

// // ===============================================================
// // Design
// // ===============================================================

// reg [3:0] input_charac [0:IP_WIDTH-1] ;
// reg [4:0] input_weight [0:IP_WIDTH-1] ;

// wire [3:0] out_seg [0:IP_WIDTH-1] ;


// genvar i ;
// generate 
	// for (i = 0 ; i < 3 + ((IP_WIDTH - 3) * (IP_WIDTH + 2)) / 2 ; i = i + 1) begin : sort1
		// wire [3:0] out_cha [0:1] ;
		// wire [4:0] out_wei [0:1] ;
		// if (i == 0) begin 
			// comparator c0 (.in_c1(IN_character[3:0]), .in_c2(IN_character[IP_WIDTH*4-1 -: 4]), .in_w1(IN_weight[4:0]), .in_w2(IN_weight[IP_WIDTH*5-1 -: 5]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		// else if (i > 0 && i < IP_WIDTH-1) begin 
			// comparator c1 (.in_c1(sort1[i-1].out_cha[0]), .in_c2(IN_character[(IP_WIDTH-i)*4-1 -: 4]), .in_w1(sort1[i-1].out_wei[0]), .in_w2(IN_weight[(IP_WIDTH-i)*5-1 -: 5]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		// else if (i == IP_WIDTH-1) begin 
			// comparator c2 (.in_c1(sort1[i-1].out_cha[1]), .in_c2(sort1[0].out_cha[1]), .in_w1(sort1[i-1].out_wei[1]), .in_w2(sort1[0].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
			
		// end
		// else if (i > IP_WIDTH-1 && i < 2*IP_WIDTH-3) begin 
			// comparator c3 (.in_c1(sort1[i-1].out_cha[0]), .in_c2(sort1[i-(IP_WIDTH-1)].out_cha[1]), .in_w1(sort1[i-1].out_wei[0]), .in_w2(sort1[i-(IP_WIDTH-1)].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		// else if (i == 2*IP_WIDTH-3) begin 
			// comparator c4 (.in_c1(sort1[i-1].out_cha[1]), .in_c2(sort1[IP_WIDTH-1].out_cha[1]), .in_w1(sort1[i-1].out_wei[1]), .in_w2(sort1[IP_WIDTH-1].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
			
		// end
		// else if (i > 2*IP_WIDTH-3 && i < 3*IP_WIDTH-6) begin 
			// comparator c5 (.in_c1(sort1[i-1].out_cha[0]), .in_c2(sort1[i-(IP_WIDTH-2)].out_cha[1]), .in_w1(sort1[i-1].out_wei[0]), .in_w2(sort1[i-(IP_WIDTH-2)].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		// else if (i == 3*IP_WIDTH-6) begin 
			// comparator c6 (.in_c1(sort1[i-1].out_cha[1]), .in_c2(sort1[2*IP_WIDTH-3].out_cha[1]), .in_w1(sort1[i-1].out_wei[1]), .in_w2(sort1[2*IP_WIDTH-3].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
			
		// end
		// else if (i > 3*IP_WIDTH-6 && i < 4*IP_WIDTH-10) begin 
			// comparator c7 (.in_c1(sort1[i-1].out_cha[0]), .in_c2(sort1[i-(IP_WIDTH-3)].out_cha[1]), .in_w1(sort1[i-1].out_wei[0]), .in_w2(sort1[i-(IP_WIDTH-3)].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		// else if (i == 4*IP_WIDTH-10) begin 
			// comparator c8 (.in_c1(sort1[i-1].out_cha[1]), .in_c2(sort1[3*IP_WIDTH-6].out_cha[1]), .in_w1(sort1[i-1].out_wei[1]), .in_w2(sort1[3*IP_WIDTH-6].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
			
		// end
		// else if (i > 4*IP_WIDTH-10 && i < 5*IP_WIDTH-15) begin 
			// comparator c9 (.in_c1(sort1[i-1].out_cha[0]), .in_c2(sort1[i-(IP_WIDTH-4)].out_cha[1]), .in_w1(sort1[i-1].out_wei[0]), .in_w2(sort1[i-(IP_WIDTH-4)].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		// else if (i == 5*IP_WIDTH-15) begin 
			// comparator c10 (.in_c1(sort1[i-1].out_cha[1]), .in_c2(sort1[4*IP_WIDTH-10].out_cha[1]), .in_w1(sort1[i-1].out_wei[1]), .in_w2(sort1[4*IP_WIDTH-10].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		// else if (i == 26) begin 
			// comparator c11 (.in_c1(sort1[i-1].out_cha[0]), .in_c2(sort1[i-(IP_WIDTH-5)].out_cha[1]), .in_w1(sort1[i-1].out_wei[0]), .in_w2(sort1[i-(IP_WIDTH-5)].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		// else if (i == 27) begin 
			// comparator c12 (.in_c1(sort1[i-1].out_cha[1]), .in_c2(sort1[5*IP_WIDTH-15].out_cha[1]), .in_w1(sort1[i-1].out_wei[1]), .in_w2(sort1[5*IP_WIDTH-15].out_wei[1]), .big_c(out_cha[0]), .big_w(out_wei[0]), .small_c(out_cha[1]), .small_w(out_wei[1])) ;
		// end
		
		
		// if (IP_WIDTH == 8 && i == 27) begin
			// assign OUT_character = {sort1[i-21].out_cha[0], sort1[i-15].out_cha[0], sort1[i-10].out_cha[0], sort1[i-6].out_cha[0], sort1[i-3].out_cha[0], sort1[i-1].out_cha[0], out_cha[0], out_cha[1]} ;
		// end
		// else if (IP_WIDTH == 7 && i == 20) begin 
			// assign OUT_character = {sort1[i-15].out_cha[0], sort1[i-10].out_cha[0], sort1[i-6].out_cha[0], sort1[i-3].out_cha[0], sort1[i-1].out_cha[0], out_cha[0], out_cha[1]} ;
		// end
		// else if (IP_WIDTH == 6 && i == 14) begin 
			// assign OUT_character = {sort1[i-10].out_cha[0], sort1[i-6].out_cha[0], sort1[i-3].out_cha[0], sort1[i-1].out_cha[0], out_cha[0], out_cha[1]} ;
		// end
		// else if (IP_WIDTH == 5 && i == 9) begin 
			// assign OUT_character = {sort1[i-6].out_cha[0], sort1[i-3].out_cha[0], sort1[i-1].out_cha[0], out_cha[0], out_cha[1]} ;
		// end
		// else if (IP_WIDTH == 4 && i == 5) begin 
			// assign OUT_character = {sort1[i-3].out_cha[0], sort1[i-1].out_cha[0], out_cha[0], out_cha[1]} ;
		// end
		// else if (IP_WIDTH == 3 && i == 2) begin 
			// assign OUT_character = {sort1[i-1].out_cha[0], out_cha[0], out_cha[1]} ;
		// end
	// end
// endgenerate



// endmodule


// module comparator (in_c1, in_c2, in_w1, in_w2, big_c, big_w, small_c, small_w) ;

// input [3:0] in_c1, in_c2 ;
// input [4:0] in_w1, in_w2 ;
// output reg [3:0] big_c, small_c ;
// output reg [4:0] big_w, small_w ;
	
// always @ (*) begin 
	// if (in_w1 > in_w2 || (in_w1 == in_w2 && in_c1 > in_c2)) begin 
		// big_c = in_c1 ;
		// big_w = in_w1 ;
		// small_c = in_c2 ;
		// small_w = in_w2 ;
	// end
	// else begin 
		// big_c = in_c2 ;
		// big_w = in_w2 ;
		// small_c = in_c1 ;
		// small_w = in_w1 ;
	// end
// end	

// endmodule





//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;

// ===============================================================
// Design
// ===============================================================

wire [3:0] input_charac [0:7] ;
wire [4:0] input_weight [0:7] ;
wire [3:0] w_cha [0:37] ;
wire [4:0] w_wei [0:37] ;



genvar i, j ;
generate 
	for (i = 0 ; i < 8 ; i  = i + 1) begin 
		if (i < IP_WIDTH) begin 
			assign input_charac[i] = IN_character[(IP_WIDTH-i)*4-1 -: 4] ;
			assign input_weight[i] = IN_weight[(IP_WIDTH-i)*5-1 -: 5] ;
		end
		else begin 
			assign input_charac[i] = 0 ;
			assign input_weight[i] = 0 ;
		end
	end
endgenerate

comparator c0 (.in_c1(input_charac[0]), .in_c2(input_charac[1]), .in_w1(input_weight[0]), .in_w2(input_weight[1]), .big_c(w_cha[30]), .small_c(w_cha[31]), .big_w(w_wei[30]), .small_w(w_wei[31])) ;
comparator c1 (.in_c1(input_charac[2]), .in_c2(input_charac[3]), .in_w1(input_weight[2]), .in_w2(input_weight[3]), .big_c(w_cha[32]), .small_c(w_cha[33]), .big_w(w_wei[32]), .small_w(w_wei[33])) ;
comparator c2 (.in_c1(input_charac[4]), .in_c2(input_charac[5]), .in_w1(input_weight[4]), .in_w2(input_weight[5]), .big_c(w_cha[34]), .small_c(w_cha[35]), .big_w(w_wei[34]), .small_w(w_wei[35])) ;
comparator c3 (.in_c1(input_charac[6]), .in_c2(input_charac[7]), .in_w1(input_weight[6]), .in_w2(input_weight[7]), .big_c(w_cha[36]), .small_c(w_cha[37]), .big_w(w_wei[36]), .small_w(w_wei[37])) ;
comparator c4 (.in_c1(w_cha[30]), .in_c2(w_cha[32]), .in_w1(w_wei[30]), .in_w2(w_wei[32]), .big_c(w_cha[22]), .small_c(w_cha[23]), .big_w(w_wei[22]), .small_w(w_wei[23])) ;
comparator c5 (.in_c1(w_cha[31]), .in_c2(w_cha[33]), .in_w1(w_wei[31]), .in_w2(w_wei[33]), .big_c(w_cha[24]), .small_c(w_cha[25]), .big_w(w_wei[24]), .small_w(w_wei[25])) ;
comparator c6 (.in_c1(w_cha[34]), .in_c2(w_cha[36]), .in_w1(w_wei[34]), .in_w2(w_wei[36]), .big_c(w_cha[26]), .small_c(w_cha[27]), .big_w(w_wei[26]), .small_w(w_wei[27])) ;
comparator c7 (.in_c1(w_cha[35]), .in_c2(w_cha[37]), .in_w1(w_wei[35]), .in_w2(w_wei[37]), .big_c(w_cha[28]), .small_c(w_cha[29]), .big_w(w_wei[28]), .small_w(w_wei[29])) ;
comparator c8 (.in_c1(w_cha[22]), .in_c2(w_cha[26]), .in_w1(w_wei[22]), .in_w2(w_wei[26]), .big_c(w_cha[0]), .small_c(w_cha[16]), .big_w(w_wei[0]), .small_w(w_wei[16])) ;
comparator c9 (.in_c1(w_cha[23]), .in_c2(w_cha[24]), .in_w1(w_wei[23]), .in_w2(w_wei[24]), .big_c(w_cha[17]), .small_c(w_cha[18]), .big_w(w_wei[17]), .small_w(w_wei[18])) ;
comparator c10 (.in_c1(w_cha[27]), .in_c2(w_cha[28]), .in_w1(w_wei[27]), .in_w2(w_wei[28]), .big_c(w_cha[19]), .small_c(w_cha[20]), .big_w(w_wei[19]), .small_w(w_wei[20])) ;
comparator c11 (.in_c1(w_cha[25]), .in_c2(w_cha[29]), .in_w1(w_wei[25]), .in_w2(w_wei[29]), .big_c(w_cha[21]), .small_c(w_cha[7]), .big_w(w_wei[21]), .small_w(w_wei[7])) ;
comparator c12 (.in_c1(w_cha[18]), .in_c2(w_cha[20]), .in_w1(w_wei[18]), .in_w2(w_wei[20]), .big_c(w_cha[12]), .small_c(w_cha[13]), .big_w(w_wei[12]), .small_w(w_wei[13])) ;
comparator c13 (.in_c1(w_cha[17]), .in_c2(w_cha[19]), .in_w1(w_wei[17]), .in_w2(w_wei[19]), .big_c(w_cha[14]), .small_c(w_cha[15]), .big_w(w_wei[14]), .small_w(w_wei[15])) ;
comparator c14 (.in_c1(w_cha[16]), .in_c2(w_cha[12]), .in_w1(w_wei[16]), .in_w2(w_wei[12]), .big_c(w_cha[8]), .small_c(w_cha[9]), .big_w(w_wei[8]), .small_w(w_wei[9])) ;
comparator c15 (.in_c1(w_cha[15]), .in_c2(w_cha[21]), .in_w1(w_wei[15]), .in_w2(w_wei[21]), .big_c(w_cha[10]), .small_c(w_cha[11]), .big_w(w_wei[10]), .small_w(w_wei[11])) ;
comparator c16 (.in_c1(w_cha[8]), .in_c2(w_cha[14]), .in_w1(w_wei[8]), .in_w2(w_wei[14]), .big_c(w_cha[1]), .small_c(w_cha[2]), .big_w(w_wei[1]), .small_w(w_wei[2])) ;
comparator c17 (.in_c1(w_cha[9]), .in_c2(w_cha[10]), .in_w1(w_wei[9]), .in_w2(w_wei[10]), .big_c(w_cha[3]), .small_c(w_cha[4]), .big_w(w_wei[3]), .small_w(w_wei[4])) ;
comparator c18 (.in_c1(w_cha[13]), .in_c2(w_cha[11]), .in_w1(w_wei[13]), .in_w2(w_wei[11]), .big_c(w_cha[5]), .small_c(w_cha[6]), .big_w(w_wei[5]), .small_w(w_wei[6])) ;

generate 
	for (i = 0 ; i < IP_WIDTH ; i  = i + 1) begin 
		assign OUT_character[(IP_WIDTH-i)*4-1 -: 4] = w_cha[i] ;
	end
endgenerate


endmodule


module comparator (in_c1, in_c2, in_w1, in_w2, big_c, small_c, big_w, small_w) ;

input [3:0] in_c1, in_c2 ;
input [4:0] in_w1, in_w2 ;
output reg[3:0] big_c, small_c ;
output reg[4:0] big_w, small_w ;



always @ (*) begin 
	if (in_w1 > in_w2 || (in_w1 == in_w2 && in_c1 > in_c2)) begin 
		big_c = in_c1 ;
		big_w = in_w1 ;
		small_c = in_c2 ;
		small_w = in_w2 ;
	end
	else begin 
		big_c = in_c2 ;
		big_w = in_w2 ;
		small_c = in_c1 ;
		small_w = in_w1 ;
	end
end	

endmodule







