module conv_geratriz(
	input signed [199:0] matriz_a, 
	input signed [199:0] matriz_b,
	input [20:0] data,
	input clk,
	output reg [7:0] result, 
	output reg [20:0] output_data
);


	parameter ZERO = 8'b00000000;

	wire [199:0] matriz_c, matriz_d, aux_kernel;
	wire [7:0]   absSum, modulo1, modulo2;
	wire [20:0]	 conv_data;

	//LOGICA DO SEGUNDO KERNEL
	matriz_transposta trp_kernel(matriz_b, matriz_c);
	assign matriz_d = {matriz_b[8+:8],matriz_b[48+:8],ZERO,ZERO,ZERO,matriz_b[0+:8],matriz_b[40+:8]};
	assign aux_kernel = data[19] ? matriz_d : matriz_c;


	matriz_conv uni_mtr(matriz_a, matriz_b, data, clk, modulo1, signal, conv_data);
	matriz_conv transp(matriz_a, aux_kernel, data, clk, modulo2, , );


	//SELETOR: data[20:19]
	//
	//0X = 1 matriz (fazer saturaçao dupla)
	//10 = tipo sobel, 2 kernel transposta
	//11 = tipo roberts, 2 kernel 45 graus



	reg [8:0] tempSum;
	reg [7:0] result1;
	assign absSum = tempSum[8] ? 8'hff : tempSum[7:0];

	always @ (posedge clk) begin
		output_data <= conv_data;
		tempSum <= modulo1 + modulo2;
		result1 <= (!data[20] & signal) ? 8'h00 : modulo1;
	end

	always @(*) begin
		case(output_data[20:19])
			2'b01: result = result1;
			2'b1?: result = absSum;
			default: result = 0;
		endcase
	end

endmodule
