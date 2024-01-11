module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output clk2_fifo_flag1;
output clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

output reg fifo_clk3_flag1;
output reg fifo_clk3_flag2;
output reg fifo_clk3_flag3;
output reg fifo_clk3_flag4;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

reg flag ;
// rdata
//  Add one more register stage to rdata
always @(posedge rclk) begin
    if (rinc || flag)
        rdata <= rdata_q;
end

always @ (posedge rclk) begin 
	flag <= rinc ;
end

reg [6:0] waddr, raddr ;
reg [6:0] wq2_rptr,  rq2_wptr ;
reg [6:0] mid_wptr1, mid_wptr2 ;
reg [6:0] mid_rptr1, mid_rptr2 ;
reg [8:0] counter ;
wire write_en ;

assign write_en = (winc && ~wfull) ;
assign clk2_fifo_flag1 = (counter == 256) ;

always @ (posedge wclk or negedge rst_n) begin 
	if (!rst_n) counter <= 0 ;
	else begin 
		if (counter == 256) counter <= 0 ;
		else if (winc) counter <= counter + 1 ;
		else counter <= counter ;
	end
end

DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(1'b0),
    .WEBN(1'b1),
    .CSA(write_en),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(waddr[0]),
    .A1(waddr[1]),
    .A2(waddr[2]),
    .A3(waddr[3]),
    .A4(waddr[4]),
    .A5(waddr[5]),
    .B0(raddr[0]),
    .B1(raddr[1]),
    .B2(raddr[2]),
    .B3(raddr[3]),
    .B4(raddr[4]),
    .B5(raddr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIA16(wdata[16]),
    .DIA17(wdata[17]),
    .DIA18(wdata[18]),
    .DIA19(wdata[19]),
    .DIA20(wdata[20]),
    .DIA21(wdata[21]),
    .DIA22(wdata[22]),
    .DIA23(wdata[23]),
    .DIA24(wdata[24]),
    .DIA25(wdata[25]),
    .DIA26(wdata[26]),
    .DIA27(wdata[27]),
    .DIA28(wdata[28]),
    .DIA29(wdata[29]),
    .DIA30(wdata[30]),
    .DIA31(wdata[31]),
    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    .DIB8(1'b0),
    .DIB9(1'b0),
    .DIB10(1'b0),
    .DIB11(1'b0),
    .DIB12(1'b0),
    .DIB13(1'b0),
    .DIB14(1'b0),
    .DIB15(1'b0),
    .DIB16(1'b0),
    .DIB17(1'b0),
    .DIB18(1'b0),
    .DIB19(1'b0),
    .DIB20(1'b0),
    .DIB21(1'b0),
    .DIB22(1'b0),
    .DIB23(1'b0),
    .DIB24(1'b0),
    .DIB25(1'b0),
    .DIB26(1'b0),
    .DIB27(1'b0),
    .DIB28(1'b0),
    .DIB29(1'b0),
    .DIB30(1'b0),
    .DIB31(1'b0),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31])
) ;  

// ===============================================================
//  					waddr / raddr 
// ===============================================================

always @ (posedge wclk or negedge rst_n) begin 
	if (!rst_n) waddr <= 0 ; 
	else begin 
		if (winc && ((wptr ^ wq2_rptr) != 7'b1100000)) waddr <= waddr + 1 ;
		else waddr <= waddr ;
	end
end

always @ (posedge rclk or negedge rst_n) begin 
	if (!rst_n) raddr <= 0 ; 
	else begin 
		if (rinc && rptr != rq2_wptr) raddr <= raddr + 1 ;
		else raddr <= raddr ;
	end
end

// ===============================================================
//  				    wptr / rptr 
// ===============================================================
always @ (*) begin 
	case (waddr) 
		0 :   wptr = 7'b0000000 ;
		1 :   wptr = 7'b0000001 ;
		2 :   wptr = 7'b0000011 ;
		3 :   wptr = 7'b0000010 ;
		4 :   wptr = 7'b0000110 ;
		5 :   wptr = 7'b0000111 ;
		6 :   wptr = 7'b0000101 ;
		7 :   wptr = 7'b0000100 ;
		8 :   wptr = 7'b0001100 ;
		9 :   wptr = 7'b0001101 ;
		10 :  wptr = 7'b0001111 ;
		11 :  wptr = 7'b0001110 ;
		12 :  wptr = 7'b0001010 ;
		13 :  wptr = 7'b0001011 ;
		14 :  wptr = 7'b0001001 ;
		15 :  wptr = 7'b0001000 ;
		16 :  wptr = 7'b0011000 ;
		17 :  wptr = 7'b0011001 ;
		18 :  wptr = 7'b0011011 ;
		19 :  wptr = 7'b0011010 ;
		20 :  wptr = 7'b0011110 ;
		21 :  wptr = 7'b0011111 ;
		22 :  wptr = 7'b0011101 ;
		23 :  wptr = 7'b0011100 ;
		24 :  wptr = 7'b0010100 ;
		25 :  wptr = 7'b0010101 ;
		26 :  wptr = 7'b0010111 ;
		27 :  wptr = 7'b0010110 ;
		28 :  wptr = 7'b0010010 ;
		29 :  wptr = 7'b0010011 ;
		30 :  wptr = 7'b0010001 ;
		31 :  wptr = 7'b0010000 ;
		32 :  wptr = 7'b0110000 ;
		33 :  wptr = 7'b0110001 ;
		34 :  wptr = 7'b0110011 ;
		35 :  wptr = 7'b0110010 ;
		36 :  wptr = 7'b0110110 ;
		37 :  wptr = 7'b0110111 ;
		38 :  wptr = 7'b0110101 ;
		39 :  wptr = 7'b0110100 ;
		40 :  wptr = 7'b0111100 ;
		41 :  wptr = 7'b0111101 ;
		42 :  wptr = 7'b0111111 ;
		43 :  wptr = 7'b0111110 ;
		44 :  wptr = 7'b0111010 ;
		45 :  wptr = 7'b0111011 ;
		46 :  wptr = 7'b0111001 ;
		47 :  wptr = 7'b0111000 ;
		48 :  wptr = 7'b0101000 ;
		49 :  wptr = 7'b0101001 ;
		50 :  wptr = 7'b0101011 ;
		51 :  wptr = 7'b0101010 ;
		52 :  wptr = 7'b0101110 ;
		53 :  wptr = 7'b0101111 ;
		54 :  wptr = 7'b0101101 ;
		55 :  wptr = 7'b0101100 ;
		56 :  wptr = 7'b0100100 ;
		57 :  wptr = 7'b0100101 ;
		58 :  wptr = 7'b0100111 ;
		59 :  wptr = 7'b0100110 ;
		60 :  wptr = 7'b0100010 ;
		61 :  wptr = 7'b0100011 ;
		62 :  wptr = 7'b0100001 ;
		63 :  wptr = 7'b0100000 ;
		64 :  wptr = 7'b1100000 ;
		65 :  wptr = 7'b1100001 ;
		66 :  wptr = 7'b1100011 ;
		67 :  wptr = 7'b1100010 ;
		68 :  wptr = 7'b1100110 ;
		69 :  wptr = 7'b1100111 ;
		70 :  wptr = 7'b1100101 ;
		71 :  wptr = 7'b1100100 ;
		72 :  wptr = 7'b1101100 ;
		73 :  wptr = 7'b1101101 ;
		74 :  wptr = 7'b1101111 ;
		75 :  wptr = 7'b1101110 ;
		76 :  wptr = 7'b1101010 ;
		77 :  wptr = 7'b1101011 ;
		78 :  wptr = 7'b1101001 ;
		79 :  wptr = 7'b1101000 ;
		80 :  wptr = 7'b1111000 ;
		81 :  wptr = 7'b1111001 ;
		82 :  wptr = 7'b1111011 ;
		83 :  wptr = 7'b1111010 ;
		84 :  wptr = 7'b1111110 ;
		85 :  wptr = 7'b1111111 ;
		86 :  wptr = 7'b1111101 ;
		87 :  wptr = 7'b1111100 ;
		88 :  wptr = 7'b1110100 ;
		89 :  wptr = 7'b1110101 ;
		90 :  wptr = 7'b1110111 ;
		91 :  wptr = 7'b1110110 ;
		92 :  wptr = 7'b1110010 ;
		93 :  wptr = 7'b1110011 ;
		94 :  wptr = 7'b1110001 ;
		95 :  wptr = 7'b1110000 ;
		96 :  wptr = 7'b1010000 ;
		97 :  wptr = 7'b1010001 ;
		98 :  wptr = 7'b1010011 ;
		99 :  wptr = 7'b1010010 ;
		100 : wptr = 7'b1010110 ;
		101 : wptr = 7'b1010111 ;
		102 : wptr = 7'b1010101;
		103 : wptr = 7'b1010100 ;
		104 : wptr = 7'b1011100 ;
		105 : wptr = 7'b1011101 ;
		106 : wptr = 7'b1011111 ;
		107 : wptr = 7'b1011110 ;
		108 : wptr = 7'b1011010 ;
		109 : wptr = 7'b1011011 ;
		110 : wptr = 7'b1011001 ;
		111 : wptr = 7'b1011000 ;
		112 : wptr = 7'b1001000 ;
		113 : wptr = 7'b1001001 ;
		114 : wptr = 7'b1001011 ;
		115 : wptr = 7'b1001010 ;
		116 : wptr = 7'b1001110 ;
		117 : wptr = 7'b1001111 ;
		118 : wptr = 7'b1001101 ;
		119 : wptr = 7'b1001100 ;
		120 : wptr = 7'b1000100 ;
		121 : wptr = 7'b1000101 ;
		122 : wptr = 7'b1000111 ;
		123 : wptr = 7'b1000110 ;
		124 : wptr = 7'b1000010 ;
		125 : wptr = 7'b1000011 ;
		126 : wptr = 7'b1000001 ;
		127 : wptr = 7'b1000000 ;
		default : wptr = 7'b0000000 ;
	endcase          
end

always @ (*) begin 
	case (raddr) 
		0 :   rptr = 7'b0000000 ;
		1 :   rptr = 7'b0000001 ;
		2 :   rptr = 7'b0000011 ;
		3 :   rptr = 7'b0000010 ;
		4 :   rptr = 7'b0000110 ;
		5 :   rptr = 7'b0000111 ;
		6 :   rptr = 7'b0000101 ;
		7 :   rptr = 7'b0000100 ;
		8 :   rptr = 7'b0001100 ;
		9 :   rptr = 7'b0001101 ;
		10 :  rptr = 7'b0001111 ;
		11 :  rptr = 7'b0001110 ;
		12 :  rptr = 7'b0001010 ;
		13 :  rptr = 7'b0001011 ;
		14 :  rptr = 7'b0001001 ;
		15 :  rptr = 7'b0001000 ;
		16 :  rptr = 7'b0011000 ;
		17 :  rptr = 7'b0011001 ;
		18 :  rptr = 7'b0011011 ;
		19 :  rptr = 7'b0011010 ;
		20 :  rptr = 7'b0011110 ;
		21 :  rptr = 7'b0011111 ;
		22 :  rptr = 7'b0011101 ;
		23 :  rptr = 7'b0011100 ;
		24 :  rptr = 7'b0010100 ;
		25 :  rptr = 7'b0010101 ;
		26 :  rptr = 7'b0010111 ;
		27 :  rptr = 7'b0010110 ;
		28 :  rptr = 7'b0010010 ;
		29 :  rptr = 7'b0010011 ;
		30 :  rptr = 7'b0010001 ;
		31 :  rptr = 7'b0010000 ;
		32 :  rptr = 7'b0110000 ;
		33 :  rptr = 7'b0110001 ;
		34 :  rptr = 7'b0110011 ;
		35 :  rptr = 7'b0110010 ;
		36 :  rptr = 7'b0110110 ;
		37 :  rptr = 7'b0110111 ;
		38 :  rptr = 7'b0110101 ;
		39 :  rptr = 7'b0110100 ;
		40 :  rptr = 7'b0111100 ;
		41 :  rptr = 7'b0111101 ;
		42 :  rptr = 7'b0111111 ;
		43 :  rptr = 7'b0111110 ;
		44 :  rptr = 7'b0111010 ;
		45 :  rptr = 7'b0111011 ;
		46 :  rptr = 7'b0111001 ;
		47 :  rptr = 7'b0111000 ;
		48 :  rptr = 7'b0101000 ;
		49 :  rptr = 7'b0101001 ;
		50 :  rptr = 7'b0101011 ;
		51 :  rptr = 7'b0101010 ;
		52 :  rptr = 7'b0101110 ;
		53 :  rptr = 7'b0101111 ;
		54 :  rptr = 7'b0101101 ;
		55 :  rptr = 7'b0101100 ;
		56 :  rptr = 7'b0100100 ;
		57 :  rptr = 7'b0100101 ;
		58 :  rptr = 7'b0100111 ;
		59 :  rptr = 7'b0100110 ;
		60 :  rptr = 7'b0100010 ;
		61 :  rptr = 7'b0100011 ;
		62 :  rptr = 7'b0100001 ;
		63 :  rptr = 7'b0100000 ;
		64 :  rptr = 7'b1100000 ;
		65 :  rptr = 7'b1100001 ;
		66 :  rptr = 7'b1100011 ;
		67 :  rptr = 7'b1100010 ;
		68 :  rptr = 7'b1100110 ;
		69 :  rptr = 7'b1100111 ;
		70 :  rptr = 7'b1100101 ;
		71 :  rptr = 7'b1100100 ;
		72 :  rptr = 7'b1101100 ;
		73 :  rptr = 7'b1101101 ;
		74 :  rptr = 7'b1101111 ;
		75 :  rptr = 7'b1101110 ;
		76 :  rptr = 7'b1101010 ;
		77 :  rptr = 7'b1101011 ;
		78 :  rptr = 7'b1101001 ;
		79 :  rptr = 7'b1101000 ;
		80 :  rptr = 7'b1111000 ;
		81 :  rptr = 7'b1111001 ;
		82 :  rptr = 7'b1111011 ;
		83 :  rptr = 7'b1111010 ;
		84 :  rptr = 7'b1111110 ;
		85 :  rptr = 7'b1111111 ;
		86 :  rptr = 7'b1111101 ;
		87 :  rptr = 7'b1111100 ;
		88 :  rptr = 7'b1110100 ;
		89 :  rptr = 7'b1110101 ;
		90 :  rptr = 7'b1110111 ;
		91 :  rptr = 7'b1110110 ;
		92 :  rptr = 7'b1110010 ;
		93 :  rptr = 7'b1110011 ;
		94 :  rptr = 7'b1110001 ;
		95 :  rptr = 7'b1110000 ;
		96 :  rptr = 7'b1010000 ;
		97 :  rptr = 7'b1010001 ;
		98 :  rptr = 7'b1010011 ;
		99 :  rptr = 7'b1010010 ;
		100 : rptr = 7'b1010110 ;
		101 : rptr = 7'b1010111 ;
		102 : rptr = 7'b1010101;
		103 : rptr = 7'b1010100 ;
		104 : rptr = 7'b1011100 ;
		105 : rptr = 7'b1011101 ;
		106 : rptr = 7'b1011111 ;
		107 : rptr = 7'b1011110 ;
		108 : rptr = 7'b1011010 ;
		109 : rptr = 7'b1011011 ;
		110 : rptr = 7'b1011001 ;
		111 : rptr = 7'b1011000 ;
		112 : rptr = 7'b1001000 ;
		113 : rptr = 7'b1001001 ;
		114 : rptr = 7'b1001011 ;
		115 : rptr = 7'b1001010 ;
		116 : rptr = 7'b1001110 ;
		117 : rptr = 7'b1001111 ;
		118 : rptr = 7'b1001101 ;
		119 : rptr = 7'b1001100 ;
		120 : rptr = 7'b1000100 ;
		121 : rptr = 7'b1000101 ;
		122 : rptr = 7'b1000111 ;
		123 : rptr = 7'b1000110 ;
		124 : rptr = 7'b1000010 ;
		125 : rptr = 7'b1000011 ;
		126 : rptr = 7'b1000001 ;
		127 : rptr = 7'b1000000 ;
		default : rptr = 7'b0000000 ;
	endcase
end

// ===============================================================
//  					 rq2_wptr
// ===============================================================

NDFF_BUS_syn #(7) N0 (.D(wptr), .Q(rq2_wptr), .clk(rclk), .rst_n(rst_n)) ;

// ===============================================================
//  					 wq2_rptr
// ===============================================================

NDFF_BUS_syn #(7) N1 (.D(rptr), .Q(wq2_rptr), .clk(wclk), .rst_n(rst_n)) ;

// ===============================================================
//  					 full/empty
// ===============================================================

always @ (*) begin 
	if ((wptr ^ wq2_rptr) == 7'b1100000) wfull = 1 ; 
	else wfull = 0 ;
end

always @ (*) begin 
	if (rptr == rq2_wptr) rempty = 1 ; 
	else rempty = 0 ;
end

// ===============================================================
//  					 fifo_clk3_flag1
// ===============================================================
always @ (posedge rclk or negedge rst_n) begin 
	if (!rst_n) fifo_clk3_flag1 <= 0 ;
	else begin 
		if (rinc) fifo_clk3_flag1 <= 1 ;
		else fifo_clk3_flag1 <= 0 ;
	end
end

// ===============================================================
//  					 fifo_clk3_flag2
// ===============================================================
always @ (posedge rclk or negedge rst_n) begin 
	if (!rst_n) fifo_clk3_flag2 <= 0 ;
	else begin 
		if (fifo_clk3_flag1) fifo_clk3_flag2 <= 1 ;
		else fifo_clk3_flag2 <= 0 ;
	end
end

endmodule
