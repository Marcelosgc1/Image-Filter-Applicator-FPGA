//banco de registradores

module br(
	input clk,
	input we_in,
	input we_out,
	input [15:0] data_in,
	input [5:0] endereco,
	input [23:0] matrix_ula,
	output reg [199:0] matrix_A,
	output reg [199:0] matrix_B,
	output [31:0] matrix_C,
	output reg [15:0] data_out
);

	assign matrix_C = {8'h00,matrix_C_save};
	reg [3:0] posicao;
	reg [23:0] matrix_C_save;
	
	always @(*) begin
		posicao = endereco[3:0];
		data_out = matrix_C[posicao[1] * 16 +:16];
	end
	
	
	always @(posedge clk) begin
		
		if(we_out) matrix_C_save <= matrix_ula;
		
		case (endereco[5:4])
			//salva valor de entrada em registrador da matriz A ou B
			0: if(we_in) matrix_A[posicao * 16 +:16] <= data_in;
			1: if(we_in) matrix_B[posicao * 16 +:16] <= data_in;
		endcase
	end




endmodule