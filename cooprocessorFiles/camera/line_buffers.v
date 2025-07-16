module line_buffers(
    input [31:0] datain,
    input [8:0] address,
    input [8:0] vertical_count,
    input save_data,
    input [1:0] size,
    input clk,
    output reg [199:0] matrix
);


reg [7:0] BUFFER0 [0:511], BUFFER1 [0:511], BUFFER2 [0:511], BUFFER3 [0:511], BUFFER4 [0:511];
reg [7:0] num [0:24];

wire [7:0] centralPixel3x3, centralPixel5x5;

assign centralPixel3x3 = BUFFER1[address];
assign centralPixel5x5 = BUFFER2[address];

wire new_line = (address == 0);

wire is_line0        = (vertical_count == 0);
wire is_line1        = (vertical_count == 1);
wire is_prelastline  = (vertical_count == 478);
wire is_lastline     = (vertical_count == 479);

wire is_col0         = (address == 0);
wire is_col1         = (address == 1);
wire is_prelastcol   = (address == 510);
wire is_lastcol      = (address == 511);

integer i;

always @(*) begin
	case (size)
		2'd0: begin // 2x2
			num[0] = BUFFER1[address];
			num[1] = is_lastcol     ? 0 : BUFFER1[address + 1];
			num[2] = is_lastline    ? 0 : BUFFER0[address];
			num[3] = (is_lastcol || is_lastline) ? 0 : BUFFER0[address + 1];
			matrix = {8'b0, 8'b0, 8'b0, num[3], num[2],
						 8'b0, 8'b0, 8'b0, num[1], num[0]};
		end

		2'd1: begin // 3x3
			num[0] = (is_line0 || is_col0)     ? 0 : BUFFER2[address - 1];
			num[1] = is_line0                  ? 0 : BUFFER2[address];
			num[2] = (is_line0 || is_lastcol)  ? 0 : BUFFER2[address + 1];

			num[3] = is_col0                   ? 0 : BUFFER1[address - 1];
			num[4] = centralPixel3x3;
			num[5] = is_lastcol                ? 0 : BUFFER1[address + 1];

			num[6] = (is_lastline || is_col0)     ? 0 : BUFFER0[address - 1];
			num[7] = is_lastline                  ? 0 : BUFFER0[address];
			num[8] = (is_lastline || is_lastcol)  ? 0 : BUFFER0[address + 1];

			matrix = {8'b0, 8'b0, num[8], num[7], num[6],
						 8'b0, 8'b0, num[5], num[4], num[3],
						 8'b0, 8'b0, num[2], num[1], num[0]};
		end

		2'd3: begin // 5x5
			num[0]  = (is_col1 || is_col0 || is_line1 || is_line0) ? 0 : BUFFER4[address - 2];
			num[1]  = (is_col0 || is_line1 || is_line0) ? 0 : BUFFER4[address - 1];
			num[2]  = (is_line1 || is_line0) ? 0 : BUFFER4[address];
			num[3]  = (is_lastcol || is_line1 || is_line0) ? 0 : BUFFER4[address + 1];
			num[4]  = (is_prelastcol || is_lastcol || is_line1 || is_line0) ? 0 : BUFFER4[address + 2];

			
			num[5]  = (is_col1 || is_col0 || is_line0) ? 0 : BUFFER3[address - 2];
			num[6]  = (is_col0 || is_line0) ? 0 : BUFFER3[address - 1];
			num[7]  = is_line0 ? 0 : BUFFER3[address];
			num[8]  = (is_lastcol || is_line0) ? 0 : BUFFER3[address + 1];
			num[9]  = (is_prelastcol || is_lastcol || is_line0) ? 0 : BUFFER3[address + 2];

			
			num[10] = (is_col1 || is_col0) ? 0 : BUFFER2[address - 2];
			num[11] = is_col0 ? 0 : BUFFER2[address - 1];
			num[12] = centralPixel5x5;
			num[13] = is_lastcol ? 0 : BUFFER2[address + 1];
			num[14] = (is_prelastcol || is_lastcol) ? 0 : BUFFER2[address + 2];

			
			num[15] = (is_col1 || is_col0 || is_lastline) ? 0 : BUFFER1[address - 2];
			num[16] = (is_col0 || is_lastline) ? 0 : BUFFER1[address - 1];
			num[17] = is_lastline ? 0 : BUFFER1[address];
			num[18] = (is_lastcol || is_lastline) ? 0 : BUFFER1[address + 1];
			num[19] = (is_prelastcol || is_lastcol || is_lastline) ? 0 : BUFFER1[address + 2];

			
			num[20] = (is_col1 || is_col0 || is_lastline || is_prelastline) ? 0 : BUFFER0[address - 2];
			num[21] = (is_col0 || is_lastline || is_prelastline) ? 0 : BUFFER0[address - 1];
			num[22] = (is_lastline || is_prelastline) ? 0 : BUFFER0[address];
			num[23] = (is_lastcol || is_lastline || is_prelastline) ? 0 : BUFFER0[address + 1];
			num[24] = (is_prelastcol || is_lastcol || is_lastline || is_prelastline) ? 0 : BUFFER0[address + 2];
		
		
			matrix = {num[24], num[23], num[22], num[21], num[20],
						 num[19], num[18], num[17], num[16], num[15],
						 num[14], num[13], num[12], num[11], num[10],
						 num[9],  num[8],  num[7],  num[6],  num[5],
						 num[4],  num[3],  num[2],  num[1],  num[0]};
		end

		default: matrix = 0;
	endcase
end

// Escrita dos dados nos buffers
always @(posedge clk) begin
	if (save_data) begin
		BUFFER0[{address[8:2], 2'b00}] <= datain[7:0];
		BUFFER0[{address[8:2], 2'b01}] <= datain[15:8];
		BUFFER0[{address[8:2], 2'b10}] <= datain[23:16];
		BUFFER0[{address[8:2], 2'b11}] <= datain[31:24];

		if (new_line) begin
			for (i = 0; i < 512; i = i + 1) begin
				BUFFER1[i] <= BUFFER0[i];
				BUFFER2[i] <= BUFFER1[i];
				BUFFER3[i] <= BUFFER2[i];
				BUFFER4[i] <= BUFFER3[i];
			end
		end
	end
end




endmodule
