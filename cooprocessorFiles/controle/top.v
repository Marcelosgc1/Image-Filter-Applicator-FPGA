module top(
	input [31:0] instruction,
	input [31:0] activate_signal,
	input clk,
	input [6:0] key,
	input [9:0] sw,
	//output
	output [31:0] data_read,
	output wait_signal,
	output [6:0] h0,
	output [6:0] h1,
	output [6:0] h2,
	output [6:0] h3,
	output [6:0] h4,
	output [6:0] h5,
	output [9:0] leds,
	inout	[35:0] GPIO_0,
	inout	[35:0] GPIO_1,
	//vga outputs
	output hsync, 
	output vsync,
	output [7:0]red,
	output [7:0]green,
	output [7:0]blue,
	output vga_sync,
	output vga_clk,
	output vga_blank
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
					B2G = 4'b1000,
					WRI_IMAGE = 4'b1101,
					PHOTO_CONV = 4'b1110,
					READ_IMAGE = 4'b1111;
					
	assign data_read = hps_read_image ? ram_data_out : coprocessor_data;
	 
	wire done_conv;
	
	
	wire [199:0] operandA, operandB; 
	wire [31:0] matrix_C, sent_instruction, fetched_instruction;
	wire [15:0] coprocessor_data;
	wire [3:0] opcode;
	
	assign sent_instruction = ipu_request ? ipu_inst : instruction;
	
	convolution_coprocessor new_coprocessor(
		clk,
		sent_instruction,
		ipu_request, 
		coprocessor_data,
		wait_signal,
		ipu_control,
		operandA, 
		operandB,
		done_conv,
		matrix_C, 
		fetched_instruction,
		opcode
);
	
	
	
	
	assign operandA = buf_matrix;


	assign operandB = kernel;
  
/*
	* IPU
	* IPU
	* IPU
	* IPU
	* IPU
	* IPU
	* IPU
	* IPU
	* IPU
	* IPU
	*/
	
	
	decode_ipu ipu_signals(
		instruction_code,
		size,
		current_opcode,
		initial_vertical_buffer,
		kernel
	);

	
	parameter
					IDLE			= 3'b000,
					INIT_IPU		= 4'b1001,
					READ_LINE	= 4'b1010,
					NEW_LINE		= 4'b1011,
					SEND_INST	= 3'b100,
					WAIT_PROC	= 3'b101,
					SAVE_RES 	= 3'b110,
					EXT_DELAY	= 3'b111,
					TEST			= 4'b1000;
	
	reg write_vga, start_process, ipu_request, ipu_control, next_matrix, new_flag, next_start, buf_control;
	reg [3:0]ipu_state;
	reg [3:0]loader, instruction_code, next_instruction_code;
	reg [8:0]h_count_conv, v_count_conv, h_count_buf, v_count_buf, valor_H, valor_V;
	reg [31:0] ipu_inst, count_debug;
	wire [199:0] buf_matrix, kernel;
	wire [31:0] cam_data, conv_data, ram_data_out, data_in;						
	wire [15:0] cam_address, addr_vga, addr, hps_image_address, address_buf, addr_conv;
	wire [8:0]h_count, v_count, initial_vertical_buffer;
	wire [7:0]pixel_color;
	wire [3:0]current_opcode;
	wire [1:0]size;
	wire cam_valid_pixel, cam_clock, cam_we, conv_we, memory_clk;
	
	assign address_buf = {v_count_buf, h_count_buf[8:2]};
	assign WRITE_ENABLE = cam_we | conv_we | hps_write_image;
	assign addr = 	buf_control ? address_buf : 
						hps_read_image ? hps_image_address : 
						cam_we | cam_valid_pixel ? cam_address : 
						result_writing ? addr_conv : 
						addr_vga;

	assign memory_clk = cam_we | cam_valid_pixel ? cam_clock : clk;
	assign data_in = hps_write_image ? activate_signal[31:0] : cam_we | cam_valid_pixel ? cam_data : conv_data;
	
	assign pixel_color = (opcode==CONV) ? (matrix_C[7:0]) : (matrix_C[23:16]);
	
	//LEMBRAR DE TESTAR start_buf ? .. : ..; depois
	
	assign hps_write_image = instruction[3:0]==WRI_IMAGE;
	assign hps_read_image = instruction[3:0]==READ_IMAGE | hps_write_image;
	assign hps_image_address = instruction[19:4];
	

	reg save_buf, next_line;
	reg [3:0] next_ipu;
	reg [8:0] next_H_buffer, next_V_buffer, next_H_CONVOLUTION, next_V_CONVOLUTION;
	reg [3:0] next_loader;
	always @(*) begin
		case(ipu_state)
			IDLE: begin
				//MAIN LOGIC
				if ((instruction[3:0]==PHOTO_CONV) & !start_process) begin
					next_ipu = INIT_IPU;
					next_instruction_code = instruction[7:4];
					next_start = 1'b1;
				end else if (instruction[3:0]!=PHOTO_CONV) begin
					next_ipu = IDLE;
					next_instruction_code = instruction_code;
					next_start = 1'b0;
				end else begin
					next_ipu = IDLE;
					next_instruction_code = instruction_code;
					next_start = start_process;
				end
				
				//EXTRA
				buf_control = 1'b0;
				next_loader = 4'b0;
				next_V_buffer = 9'b0;
				next_H_buffer = 9'b0;
				next_H_CONVOLUTION = 9'b0;
				next_V_CONVOLUTION = 9'b0;
				save_buf = 1'b0;
				next_line = 1'b0;
				ipu_request = 1'b0;
				ipu_control = 1'b0;
				next_matrix = 1'b0;
				ipu_inst = 32'b0;
			
			end
	
			
			INIT_IPU: begin
				//MAIN LOGIC
				next_ipu = TEST;
				next_loader = size + 1'b1;
				next_V_buffer = initial_vertical_buffer;
				next_H_buffer = 9'b0;
				buf_control = 1'b1;
				
				//EXTRA
				next_H_CONVOLUTION = h_count_conv;
				next_V_CONVOLUTION = v_count_conv;
				save_buf = 1'b0;
				next_line = 1'b0;
				ipu_request = 1'b0;
				ipu_control = 1'b0;
				next_matrix = 1'b0;
				ipu_inst = 32'b0;
				next_instruction_code = instruction_code;
				next_start = start_process;
			end
			
			TEST: begin
				//MAIN LOGIC
				next_ipu = EXT_DELAY;
				buf_control = 1'b1;
				
				//EXTRA
				next_loader = loader;
				next_V_buffer = v_count_buf;
				next_H_buffer = h_count_buf;
				next_H_CONVOLUTION = h_count_conv;
				next_V_CONVOLUTION = v_count_conv;
				save_buf = 1'b0;
				next_line = 1'b0;
				ipu_request = 1'b0;
				ipu_control = 1'b0;
				next_matrix = 1'b0;
				ipu_inst = 32'b0;
				next_instruction_code = instruction_code;
				next_start = start_process;
			end
			
			EXT_DELAY: begin
				//MAIN LOGIC
				next_ipu = READ_LINE;
				buf_control = 1'b1;
				
				//EXTRA
				next_loader = loader;
				next_V_buffer = v_count_buf;
				next_H_buffer = h_count_buf;
				next_H_CONVOLUTION = h_count_conv;
				next_V_CONVOLUTION = v_count_conv;
				save_buf = 1'b0;
				next_line = 1'b0;
				ipu_request = 1'b0;
				ipu_control = 1'b0;
				next_matrix = 1'b0;
				ipu_inst = 32'b0;
				next_instruction_code = instruction_code;
				next_start = start_process;
			end
			
			READ_LINE: begin
				save_buf = 1'b1;
				buf_control = 1'b1;
				if (h_count_buf == 9'h1FC & loader != 0) begin
					next_ipu = NEW_LINE;
					next_H_buffer = 9'b0;
				end else if (h_count_buf == 9'h1FC) begin
					next_ipu = SEND_INST;
					next_H_buffer = 9'b0;
				end else begin
					next_ipu = TEST;
					next_H_buffer = h_count_buf + 3'b100;
				end
				
				//EXTRA
				next_loader = loader;
				next_V_buffer = v_count_buf;
				next_H_CONVOLUTION = h_count_conv;
				next_V_CONVOLUTION = v_count_conv;
				next_line = 1'b0;
				ipu_request = 1'b0;
				ipu_control = 1'b0;
				next_matrix = 1'b0;
				ipu_inst = 32'b0;
				next_instruction_code = instruction_code;
				next_start = start_process;
			end
			
			NEW_LINE: begin
				next_ipu = TEST;
				buf_control = 1'b1;
				next_line = 1'b1;
				if(loader == 4'b0) next_loader = 4'b0;
				else next_loader = loader - 4'b1;
				if (v_count_buf == 9'h1DF) next_V_buffer = 1'b0;
				else next_V_buffer = v_count_buf + 1'b1;
				
				//EXTRA
				next_H_buffer = h_count_buf;
				next_H_CONVOLUTION = h_count_conv;
				next_V_CONVOLUTION = v_count_conv;
				save_buf = 1'b0;
				ipu_request = 1'b0;
				ipu_control = 1'b0;
				next_matrix = 1'b0;
				ipu_inst = 32'b0;
				next_instruction_code = instruction_code;
				next_start = start_process;
			end
			
			SEND_INST: begin
				next_ipu = WAIT_PROC;
				ipu_control = 1'b1;
				ipu_request = 1'b1;
				ipu_inst = {v_count_conv,h_count_conv,current_opcode};
				
				//EXTRA
				buf_control = 1'b0;
				next_loader = loader;
				next_V_buffer = v_count_buf;
				next_H_buffer = h_count_buf;
				next_H_CONVOLUTION = h_count_conv;
				next_V_CONVOLUTION = v_count_conv;
				save_buf = 1'b0;
				next_line = 1'b0;
				next_matrix = 1'b0;
				next_instruction_code = instruction_code;
				next_start = start_process;
			end
			
			
			WAIT_PROC: begin
				ipu_control = 1'b1;
				ipu_inst = {v_count_conv,h_count_conv,current_opcode};
			
				if (conv_write_done) begin
					next_ipu = SAVE_RES;
				end else begin
					next_ipu = WAIT_PROC;
				end
				
				//EXTRA
				buf_control = 1'b0;
				next_loader = loader;
				next_V_buffer = v_count_buf;
				next_H_buffer = h_count_buf;
				next_H_CONVOLUTION = h_count_conv;
				next_V_CONVOLUTION = v_count_conv;
				save_buf = 1'b0;
				next_line = 1'b0;
				ipu_request = 1'b0;
				next_matrix = 1'b0;
				next_instruction_code = instruction_code;
				next_start = start_process;
			end
			
			SAVE_RES: begin
				next_matrix = 1'b1;
				if(h_count_conv != 9'h1ff) begin
					next_ipu = SEND_INST;
					next_H_CONVOLUTION = h_count_conv + 1'b1;
					next_V_CONVOLUTION = v_count_conv;
				end else if (v_count_conv != 9'h1df) begin
					next_ipu = NEW_LINE;
					next_H_CONVOLUTION = 9'b0;
					next_V_CONVOLUTION = v_count_conv + 1'b1;
				end else begin
					next_ipu = IDLE;
					next_H_CONVOLUTION = 9'b0;
					next_V_CONVOLUTION = 9'b0;
				end
				
				//EXTRA
				buf_control = 1'b0;
				next_loader = loader;
				next_V_buffer = v_count_buf;
				next_H_buffer = h_count_buf;
				save_buf = 1'b0;
				next_line = 1'b0;
				ipu_request = 1'b0;
				ipu_control = 1'b0;
				ipu_inst = 32'b0;
				next_instruction_code = instruction_code;
				next_start = start_process;
			
			end
			
			default: begin
				buf_control = 1'b0;
				next_ipu = IDLE;
				next_loader = 4'b0;
				next_V_buffer = 9'b0;
				next_H_buffer = 9'b0;
				next_H_CONVOLUTION = 9'b0;
				next_V_CONVOLUTION = 9'b0;
				save_buf = 1'b0;
				next_line = 1'b0;
				ipu_request = 1'b0;
				ipu_control = 1'b0;
				next_matrix = 1'b0;
				ipu_inst = 32'b0;
				next_instruction_code = 4'b0;
				next_start = 1'b0;
			end
		endcase
	
	
	end
	
	
	
	
	
	
	
	
	
	always @ (posedge clk) begin
		ipu_state <= next_ipu;
		instruction_code <= next_instruction_code;
		start_process <= next_start;
		h_count_buf <= next_H_buffer;
		v_count_buf <= next_V_buffer;
		loader <= next_loader;
		h_count_conv <= next_H_CONVOLUTION;
		v_count_conv <= next_V_CONVOLUTION;
	end

	
	DE2_D5M camera_interface(
		clk,
		key,
		sw,
		,,,,,,
		leds,
		GPIO_0,
		GPIO_1,
		cam_data,
		cam_address,
		cam_valid_pixel,
		cam_clock,
		cam_we
	);
	

	write_result coprocessor_result_writer(
		clk,
		ipu_inst[21:4],
		done_conv,
		ram_data_out,
		pixel_color,
		result_writing,
		conv_write_done,
		conv_we,
		conv_data,
		addr_conv
	);
	
	
	vga_control vga_control_instance(
		clk,
		ram_data_out,
		addr_vga,
		hsync, 
		vsync,
		red,
		green,
		blue,			
		vga_sync,
		vga_clk,
		vga_blank
);


	vgaMemory main_memory(
		addr,
		memory_clk,
		data_in,
		WRITE_ENABLE, 
		ram_data_out
	);
	
	
	line_buffers temporary_memory(
		clk,
		ram_data_out, 
		h_count_buf,
		save_buf,
		next_matrix,
		next_line,
		size,
		buf_matrix, t0,t1,u0,u1,v0,v1
	);

endmodule
