module top(
	input [31:0] instruction,
	input [1:0] activate_signal,
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
					PHOTO_CONV = 4'b1110,
					READ_IMAGE = 4'b1111;
					
	assign data_read = hps_read_image ? ram_data_out : coprocessor_data;
	 
	wire done_conv, activate_instruction, activate_ipu;
	
	assign activate_instruction = activate_signal[0];
	assign activate_ipu = activate_signal[0];
	
	wire [199:0] operandA, operandB; 
	wire [31:0] matrix_C, sent_instruction, fetched_instruction;
	wire [15:0] coprocessor_data;
	wire [3:0] opcode;
	
	assign sent_instruction = ipu_request ? ipu_inst : instruction;
	
	
	convolution_coprocessor(
		clk,
		sent_instruction,
		(activate_instruction | ipu_request), 
		coprocessor_data,
		wait_signal,
		ipu_request,
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
	
	decode_ipu(
		instruction_code,
		size,
		current_opcode,
		kernel
	);

	
	parameter
					WAIT_CONV	= 2'b00,
					LOAD_BUFFER	= 2'b01,
					SEND_CONV 	= 2'b10,
					STB_DELAY 	= 2'b11;
	
	reg write_vga, start_process, ipu_request, start_buf, next_matrix;
	reg [1:0]ipu_state;
	reg [2:0]loader, instruction_code;
	reg [7:0]pixel_color;
	reg [8:0]h_count_conv, v_count_conv, h_count_buf, v_count_buf;
	reg [31:0] ipu_inst;
	wire [199:0] buf_matrix, kernel;
	wire [31:0] cam_data, conv_data, ram_data_out, data_in;						
	wire [15:0] cam_address, conv_address, addr, hps_image_address, address_buf;
	wire [8:0]h_count, v_count;
	wire [3:0]current_opcode;
	wire [1:0]size;
	wire cam_valid_pixel, cam_clock, cam_we, conv_we, memory_clk;
	
	assign address_buf = {v_count_buf, h_count_buf[8:2]};
	assign WRITE_ENABLE = cam_we | conv_we;
	assign addr = start_buf ? address_buf : hps_read_image ? hps_image_address : cam_we | cam_valid_pixel ? cam_address : conv_address;
	assign memory_clk = cam_we | cam_valid_pixel ? cam_clock : clk;
	assign data_in = cam_we | cam_valid_pixel ? cam_data : conv_data;
	
	//LEMBRAR DE TESTAR start_buf ? .. : ..; depois
	assign h_count = ipu_state==LOAD_BUFFER ? h_count_buf : h_count_conv;
	assign v_count = ipu_state==LOAD_BUFFER ? v_count_buf : v_count_conv;
	
	assign hps_read_image = instruction[3:0]==READ_IMAGE;
	assign hps_image_address = instruction[19:4];
	assign last_col = (h_count_buf == 9'd508);
	
	always @ (posedge clk) begin
		case (ipu_state)
			WAIT_CONV: begin
				if((instruction[3:0]==PHOTO_CONV) & !start_process) begin
					ipu_state <= LOAD_BUFFER;
					instruction_code <= (sw[6:4] == 3'b111) ? instruction[6:4] : sw[6:4];
					start_process <= 1;
				end else if (instruction[3:0]!=PHOTO_CONV) begin
					start_process <= 0;
				end
				start_buf <= 0;
				loader <= 0;
				h_count_buf <= 0;
				v_count_buf <= 0;
				h_count_conv <= 0;
				v_count_conv <= 0;
				ipu_request <= 0;
				next_matrix <= 0;
			end
			
			LOAD_BUFFER: begin
				next_matrix <= 0;
				if (!start_buf) begin
					start_buf <= 1;
					loader <= size + 1;
				end else begin
					if (last_col) begin
						h_count_buf <= 0;
						v_count_buf <= v_count_buf + 1;
						if (loader == 0) begin
							ipu_state <= SEND_CONV;
							start_buf <= 0;
							loader <= loader;
						end else begin
							ipu_state <= LOAD_BUFFER;
							start_buf <= 1;
							loader <= loader - 1;
						end
					end else begin
						loader <= loader;
						h_count_buf <= h_count_buf + 4;
						v_count_buf <= v_count_buf;
						start_buf <= 1;
					end
					
				
				end
			end
			
			SEND_CONV: begin
				loader <= 0;
				
				if (!wait_signal) begin
					ipu_request <= 1;
					ipu_inst <= {v_count_conv,h_count_conv,current_opcode};
					next_matrix <= 0;
				end else if (ipu_request & done_conv) begin
					ipu_request <= 0;
					next_matrix <= 1;
					start_buf <= 0;
					if(h_count_conv==9'h1ff)begin
						if (v_count_conv==9'h1df) begin
							h_count_conv <= 0;
							v_count_conv <= 0;
							ipu_state <= WAIT_CONV;
						end else begin
							h_count_conv <= 0;
							v_count_conv <= v_count_conv + 1;
							ipu_state <= STB_DELAY;
						end
					end
					
					else begin
						h_count_conv <= h_count_conv + 1;
						v_count_conv <= v_count_conv;
						ipu_state <= SEND_CONV;
						start_buf <= 0;
					end
				end else begin
					next_matrix <= 0;
				end
			end
			
			STB_DELAY: begin
				start_buf <= 1;
				next_matrix <= 0;
				ipu_state <= LOAD_BUFFER;
			end
			
			default: begin
				ipu_state <= WAIT_CONV;
			end
				
		endcase
	
	
		
		
		if (done_conv & !write_vga) begin
			pixel_color <= (opcode==CONV) ? (matrix_C[7:0]) : (matrix_C[23:16]);
			write_vga <= 1;
		end
		else if (write_vga & vga_ram_done) begin
			write_vga <= 0;
		end
	end
	
	DE2_D5M(
		clk,
		key,
		sw,
		h0,h1,h2,h3,h4,h5,
		leds,
		GPIO_0,
		GPIO_1,
		cam_data,
		cam_address,
		cam_valid_pixel,
		cam_clock,
		cam_we
	);
	

	
	vga_control(
		sw[3:2],
		fetched_instruction[21:4], 
		clk,
		(write_vga | done_conv),
		pixel_color,
		ram_data_out,
		vga_ram_done,
		conv_address,
		conv_data,
		conv_we,
		hsync, 
		vsync,
		red,
		green,
		blue,			
		vga_sync,
		vga_clk,
		vga_blank
);


	vgaMemory (  
		addr,
		memory_clk,
		data_in,
		WRITE_ENABLE, 
		ram_data_out
	);
	
	
	line_buffers(
		ram_data_out, 
		h_count, 
		v_count,
		start_buf,
		size,
		clk,
		buf_matrix,
		next_matrix
	);
	

endmodule