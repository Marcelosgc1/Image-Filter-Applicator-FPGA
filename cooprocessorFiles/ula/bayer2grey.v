module bayer2grey(
	input [199:0] matriz_a,
	input [1:0]pixel_region,
	input clk,
	input start,
	output [7:0] result,
	output reg done
);
	
	reg [8:0] v1,v2,v3,v4,v5;
	reg [9:0] v6,v7;
	reg [7:0] green, red, blue;
	reg [15:0] wGreen, wRed, wBlue;
	reg [16:0] partial;
	reg [17:0] final;
	
	
	reg [2:0]  stage;
	assign result = final[15:8];

	
	always @(*) begin
		case (pixel_region)
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
		if (!start) begin
			stage <= 0;
			done <= 0;
		end else begin
			case (stage) //matriz_a[(40*y) + (8*x) +:8]
				0: begin
					v1 <= matriz_a[(40*1) + (8*1) +:8];
					v2 <= matriz_a[(40*0) + (8*1) +:8] + matriz_a[(40*2) + (8*1) +:8]; //vertical
					v3 <= matriz_a[(40*1) + (8*0) +:8] + matriz_a[(40*1) + (8*2) +:8]; //horizontal
					v4 <= matriz_a[(40*0) + (8*0) +:8] + matriz_a[(40*0) + (8*2) +:8]; //diag1
					v5 <= matriz_a[(40*2) + (8*0) +:8] + matriz_a[(40*2) + (8*2) +:8]; //diag2
					stage <= 1;
					done <= 0;
				end

				1: begin
					v6 <= v2 + v3; //cruz
					v7 <= v4 + v5; //diagonal_full
					stage <= 2;
				end
				
				2: begin
					wGreen <= green * 8'h96;
					wRed <= red * 8'h4D;
					wBlue <= blue * 8'h1D;
					stage <= 3;
				end
				
				3: begin
					partial <= wGreen + wRed;
					stage <= 4;
				end
				
				4: begin
					final <= partial + wBlue;
					stage <= 4;
					done <= 1;
				end
				
			endcase
		end
	end

endmodule
