module matriz_conv (
	input [199:0] matriz_a,
	input signed [199:0] matriz_b,
	input [20:0] data,
	input clk,
	output [7:0] result, 
	output signal,
	output reg [20:0] s6_data
);
	
	reg [20:0] mult_data, s1_data, s2_data, s3_data, s4_data, s5_data;
	
	reg signed [15:0] mult [0:24];
	reg signed [16:0] stage1 [0:12];
	reg signed [17:0] stage2 [0:6];
	reg signed [18:0] stage3 [0:3];
	reg signed [19:0] stage4 [0:1];
	reg signed [20:0] stage5;
	reg [21:0] stage6;
  
  
	assign result = (|stage6[20:8]) ? 8'hff : stage6[7:0];
	assign signal = stage6[21];
  

 

	integer i;
	
	always @(posedge clk) begin

		for (i = 0; i < 25; i = i + 1) begin
			mult[i] <= $signed(matriz_b[i*8 +: 8]) * matriz_a[i*8 +: 8];
		end

		for (i = 0; i < 12; i = i + 1)
			stage1[i] <= mult[2*i] + mult[2*i+1];
		stage1[12] <= mult[24]; 

		for (i = 0; i < 6; i = i + 1)
			stage2[i] <= stage1[2*i] + stage1[2*i+1];
		stage2[6] <= stage1[12];

		for (i = 0; i < 3; i = i + 1)
			stage3[i] <= stage2[2*i] + stage2[2*i+1];
		stage3[3] <= stage2[6];

		stage4[0] <= stage3[0] + stage3[1];
		stage4[1] <= stage3[2] + stage3[3];
		
		stage5 <= stage4[0] + stage4[1];

		stage6[20:0] <= stage5[20] ? (~stage5 + 1'b1) : stage5;
		stage6[21] <= stage5[20];
	
		mult_data <= data;
		s1_data <= mult_data;
		s2_data <= s1_data;
		s3_data <= s2_data;
		s4_data <= s3_data;
		s5_data <= s4_data;
		s6_data <= s5_data;
	
	end
	

endmodule