module convolution_coprocessor(
	////////////////////	  GENERAL	////////////////////
	input clk,
	input [31:0] instruction,
	input activate_instruction, 
	
	////////////////////	HPS RELATED ////////////////////
	output reg [15:0] output_reg,
	output wait_signal,
	
	////////////////////	IPU RELATED	////////////////////
	input ipu_request,
	input [199:0] external_matrix_A,	external_matrix_B,
	output done,
	output [31:0] matrix_C, fetched_instruction_ipu,
	output [3:0] opcode
	
	
);

	parameter 	//STATES
					FETCH = 3'b000,
					DECODE = 3'b001,
					EXECUTE = 3'b010,
					MEMORY = 3'b100,
					
					//MEM-OPERATIONS
					READ = 4'b0001,
					WRITE = 4'b0010,
					
					//ARI-OPERATIONS
					CONV = 4'b0101, 	//conv. 1 matriz
					CONV_TRSP = 4'b0110,	//conv. 2 matriz transposta
					CONV_ROB = 4'b0111,	//conv. 2 matriz 45 graus
					B2G = 4'b1000;
					
	
	
	reg [31:0] fetched_instruction;
	reg [2:0] state = FETCH;
	
	reg start, write_enable_reg; 
	
	wire [199:0] matrix_A, operandA, matrix_B, operandB; 
	
	wire [23:0] convolution_result, matrix_result;
	wire [15:0] decoded_data, result_ula;
	wire [7:0] address_instruction, grey_result;
	
	wire start_conv, start_grey, done_conv;
	
	
	
	decoder cop_decoder(
		fetched_instruction,
		opcode,
		address_instruction,
		decoded_data
	);
	
	bayer2grey b2g(
		operandA,
		{fetched_instruction[13],fetched_instruction[4]},
		clk, 
		start_grey,
		grey_result, 
		done_grey
	);
	
	conv_geratriz convolution(
		operandA, 
		operandB, 
		opcode[1:0], 
		clk, 
		start_conv, 
		convolution_result, 
		done_conv
	);
	
	br bank_register(
		clk,
		write_enable_reg,
		done,
		decoded_data,
		address_instruction[5:0],
		matrix_result,
		matrix_A,
		matrix_B,
		matrix_C,
		result_ula
	);
	
	assign done = (done_conv | done_grey);
	assign {start_conv, start_grey} = IS_GREY ? {1'b0,start} : {start,1'b0};
	assign matrix_result = IS_GREY ? {grey_result,grey_result,grey_result} : convolution_result;
	
	assign fetched_instruction_ipu = fetched_instruction;
	assign operandA = ipu_request ? external_matrix_A 
											: matrix_A;

	assign operandB = ipu_request ? external_matrix_B
											: matrix_B;
	
	
	//ALIAS
	assign wait_signal = (state != FETCH);
	assign IS_MEM_OP = (instruction[3:0] == WRITE) | (instruction[3:0] == READ);
	assign IS_WR_OP = (opcode == WRITE);
	assign IS_GREY = (opcode == B2G);
	
	always @(posedge clk) begin
		//MEF
		case (state)
			//Estado de busca
			FETCH: begin
				//quando recebe activate_instruction, muda de estado
				if (activate_instruction) begin
					fetched_instruction <= instruction;
					state <= IS_MEM_OP ? MEMORY : EXECUTE;
				end else begin
					state <= FETCH;
				end
				
				//RESTART SIGNALS
				write_enable_reg <= 0;
				start <= 0;
			end
			
			
			//Estado para operacoes de memoria
			MEMORY: begin
				//operacao explicita de memoria
				write_enable_reg <= IS_WR_OP;
				output_reg <= result_ula;
				state <= FETCH;
			end
			
			//realiza operacoes de matriz
			EXECUTE: begin
				//manda escrever na memoria
				if (!done) begin
					start <= 1;
				//aguarda alu terminar operacao
				end else begin
					start <= 0;
					state <= FETCH;
				end
			end
			
			default: state <= FETCH;
			
		endcase
	end

endmodule