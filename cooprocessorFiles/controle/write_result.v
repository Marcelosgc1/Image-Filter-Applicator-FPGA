module write_result(
	input clk, 
	input [17:0] instruction_addr,
	input convolution_done,
	input [31:0] ram_data,
	input [7:0]new_data,
	output reg memory_acc,
	output reg done, 
	output reg WRITE_ENABLE, 
	output reg [31:0] data_in,
	output wire [15:0] phy_addr,
	output reg [3:0] byte_en_signal
);

reg [3:0]state, next_state;
wire [1:0] offset;
reg delay, true_done;

assign offset = instruction_addr[1:0];
assign phy_addr = instruction_addr[17:2];


always @(*) begin
	true_done = !delay & convolution_done;
	if (true_done || (|state)) begin
		case (offset)
			0: begin
				data_in = {24'h0, new_data};
				byte_en_signal = 4'b0001;
			end
			1: begin
				data_in = {16'h0, new_data, 8'h0};
				byte_en_signal = 4'b0010;
			end
			2: begin
				data_in = {8'h0, new_data, 16'h0};
				byte_en_signal = 4'b0100;
			end
			3: begin
				data_in = {new_data, 24'h0};
				byte_en_signal = 4'b1000;
			end
		endcase
	end
	else begin
		data_in = 32'h0;
		byte_en_signal = 4'b1111;
	end
	
	case (state) 
		0: begin
			if (true_done) begin
				next_state = 1;
				memory_acc = 1;
			end else begin
				next_state = 0;
				memory_acc = 0;
			end
			WRITE_ENABLE = 0;
			done = 0;
		end
		
		1: begin
			next_state = 2;
			WRITE_ENABLE = 1;
			done = 0;
			memory_acc = 1;
		end
		
		2: begin
			next_state = 0;
			WRITE_ENABLE = 0;
			done = 1;
			memory_acc = 1;
		end
		/*
		4: begin
			next_state = 5;
			WRITE_ENABLE = 0;
			done = 0;
			memory_acc = 1;
		end
		
		5: begin
			next_state = 6;
			WRITE_ENABLE = 0;
			done = 0;
			memory_acc = 1;
		end
		
		6: begin
			next_state = 7;
			WRITE_ENABLE = 0;
			done = 0;
			memory_acc = 1;
		end
		
		7: begin
			next_state = 8;
			done = 0;
			WRITE_ENABLE = 0;
			memory_acc = 1;
		end

		8: begin
			next_state = 9;
			done = 0;
			WRITE_ENABLE = 0;
			memory_acc = 1;
		end
		
		9: begin
			next_state = 10;
			done = 0;
			WRITE_ENABLE = 0;
			memory_acc = 1;
		end
		
		10: begin
			next_state = 0;
			done = 1;
			WRITE_ENABLE = 0;
			memory_acc = 1;
		end
		*/
		default: begin
			next_state = 0;
			WRITE_ENABLE = 0;
			done = 0;
			memory_acc = 0;
		end
	endcase
end


always @(posedge clk) begin
	delay <= convolution_done;
	state <= next_state;
end



endmodule