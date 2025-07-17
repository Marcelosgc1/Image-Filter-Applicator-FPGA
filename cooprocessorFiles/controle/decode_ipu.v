module decode_ipu(
	input [2:0] code,
	output reg [1:0] size,
	output reg [3:0] opcode,
	output reg [199:0] kernel
);
	parameter
					CONV = 4'b0101, 	//conv. 1 matriz
					CONV_TRSP = 4'b0110,	//conv. 2 matriz transposta
					CONV_ROB = 4'b0111,	//conv. 2 matriz 45 graus
					B2G = 4'b1000;
	/*
		0: roberts
		1: sobel
		2: prewitt
		3: sobel expandido
		4: laplace
		5: sharpen
		6: escala cinza
		7: -----
	*/





	always @(*) begin

		case (code)
			0: begin
				size = 2'b00;
				opcode = CONV_ROB;
				kernel = {8'h00,8'h00,8'h00,8'h00,8'h00,
							 8'h00,8'h00,8'h00,8'hFF,8'h00,
							 8'h00,8'h00,8'h00,8'h00,8'h01};
			end
			1: begin
				size = 2'b01;
				opcode = CONV_TRSP;
				kernel = {8'h00,8'h00,8'h01,8'h00,8'hFF,
							 8'h00,8'h00,8'h02,8'h00,8'hFE,
							 8'h00,8'h00,8'h01,8'h00,8'hFF};
			end
			2: begin
				size = 2'b01;
				opcode = CONV_TRSP;
				kernel = {8'h00,8'h00,8'h01,8'h00,8'hFF,
							 8'h00,8'h00,8'h01,8'h00,8'hFF,
							 8'h00,8'h00,8'h01,8'h00,8'hFF};
			end
			3: begin
				size = 2'b11;
				opcode = CONV_TRSP;
				kernel = {8'hFE,8'hFE,8'hFC,8'hFE,8'hFE,
							 8'hFF,8'hFF,8'hFE,8'hFF,8'hFF,
							 8'h00,8'h00,8'h00,8'h00,8'h00,
							 8'h01,8'h01,8'h02,8'h01,8'h01,
							 8'h02,8'h02,8'h04,8'h02,8'h02};
			end
			4: begin
				size = 2'b11;
				opcode = CONV;
				kernel = {8'h00,8'h00,8'hFF,8'h00,8'h00,
							 8'h00,8'hFF,8'hFE,8'hFF,8'h00,
							 8'hFF,8'hFE,8'h10,8'hFE,8'hFF,
							 8'h00,8'hFF,8'hFE,8'hFF,8'h00,
							 8'h00,8'h00,8'hFF,8'h00,8'h00};
			end
			5: begin
				size = 2'b01;
				opcode = CONV;
				kernel = {8'h00,8'h00,8'h00,8'hFF,8'h00,
							 8'h00,8'h00,8'hFF,8'h05,8'hFF,
							 8'h00,8'h00,8'h00,8'hFF,8'h00};
			end
			6: begin
				size = 2'b01;
				opcode = B2G;
				kernel = 0;
			end
			
			default: begin
				size = 0;
				opcode = 0;
				kernel = 0;
			end
			
		
		endcase

	end
	
endmodule