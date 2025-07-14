module conv_geratriz(
  input signed [199:0] matriz_a, 
  input signed [199:0] matriz_b, 
  input [1:0]seletor,
  input clk,
  input wire start,
  output [23:0] result, 
  output done_o
);


parameter ZERO = 8'b00000000;

wire [199:0] matriz_c, matriz_d, aux_kernel;
wire [7:0]   absSum, modulo1, modulo2, result1;

//LOGICA DO SEGUNDO KERNEL
matriz_transposta(matriz_b, matriz_c);
assign matriz_d = {matriz_b[8+:8],matriz_b[48+:8],ZERO,ZERO,ZERO,matriz_b[0+:8],matriz_b[40+:8]};
assign aux_kernel = seletor[0] ? matriz_d : matriz_c;


matriz_conv uni_mtr(matriz_a, matriz_b, clk, start, modulo1, signal, done1);
matriz_conv transp(matriz_a, aux_kernel, clk, start, modulo2, , done2);


assign result1 = (!seletor[1] & signal) ? 8'h00 : modulo1;


//SELETOR:
//
//0X = 1 matriz (fazer saturaçao dupla)
//10 = tipo sobel, 2 kernel transposta
//11 = tipo roberts, 2 kernel 45 graus



reg [8:0]tempSum;
reg done, lvl_to_pulse;

assign done_o = done & !lvl_to_pulse;
assign absSum = tempSum[8] ? 8'hff : tempSum[7:0];

always @ (posedge clk) begin

	tempSum <= modulo1 + modulo2;
	lvl_to_pulse <= done;
	
	if (start & !done & done1 & done2) begin
		done <= 1;
	end else if (!start) begin
		done <= 0;
	end

end


assign result = {absSum,modulo2,result1};



endmodule
