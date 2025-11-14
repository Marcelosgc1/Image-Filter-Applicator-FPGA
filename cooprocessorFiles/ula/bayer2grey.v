module bayer2grey(
	input [199:0] matriz_a,
	input [18:0]data,
	input clk,
	output [7:0] result,
	output reg [18:0] data5
);
	
	reg [8:0]  v1,v2,v3,v4,v5,u1,u2,u3,u4,u5;
	reg [9:0]  v6,v7;
	reg [7:0]  green, red, blue;
	reg [15:0] wGreen, wRed, wBlue, wBlue2;
	reg [16:0] partial;
	reg [17:0] finalSum;
	
	reg [20:0] data1, data2, data3, data4;
	
	reg [2:0]  stage;
	assign result = finalSum[15:8];

	
	always @(*) begin
		case ({data2[10],data2[1]})
			2'b00: begin
				green = v1[7:0];
				red = v3[8:1];
				blue = v2[8:1];
			end
			2'b01: begin
				red = v1[7:0];
				green = v6[9:2];
				blue = v7[9:2];
			end
			2'b10: begin
				blue = v1[7:0];
				green = v6[9:2];
				red = v7[9:2];
			end
			2'b11: begin
				green = v1[7:0];
				red = v2[8:1];
				blue = v3[8:1];
			end
		endcase


	end
  
  
  

	always @(posedge clk) begin
		//Parte 1
		u1 <= matriz_a[(40*1) + (8*1) +:8];
		u2 <= matriz_a[(40*0) + (8*1) +:8] + matriz_a[(40*2) + (8*1) +:8]; //vertical
		u3 <= matriz_a[(40*1) + (8*0) +:8] + matriz_a[(40*1) + (8*2) +:8]; //horizontal
		u4 <= matriz_a[(40*0) + (8*0) +:8] + matriz_a[(40*0) + (8*2) +:8]; //diag1
		u5 <= matriz_a[(40*2) + (8*0) +:8] + matriz_a[(40*2) + (8*2) +:8]; //diag2
		
		//Parte 2
		v1 <= u1;
		v2 <= u2;
		v3 <= u3;
		v4 <= u4;
		v5 <= u5;
		v6 <= u2 + u3; //cruz
		v7 <= u4 + u5; //diagonal_full
		
		//Parte 3
		wGreen <= green * 8'hB7;
		wRed <= red * 8'h36;
		wBlue <= blue * 8'h13;
		
		//Parte 4
		partial <= wGreen + wRed;
		wBlue2 <= wBlue;
		
		//Parte 5
		finalSum <= partial + wBlue2;
		
		
		
		data1 <= data;
		data2 <= data1;
		data3 <= data2;
		data4 <= data3;
		data5 <= data4;
		
	end

endmodule
