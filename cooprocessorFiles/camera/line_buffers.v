module line_buffers(input [31:0] datain, input [8:0]address, input [8:0]vertical_count, input save_data, input [1:0]size, input clk, output reg [199:0] matrix, input next_matrix);



reg [4095:0] BUFFER0, BUFFER1, BUFFER2, BUFFER3, BUFFER4;
reg [7:0] num [24:0];
wire [7:0] data [4:0];
wire [7:0] centralPixel3x3, centralPixel5x5;

assign centralPixel3x3 = BUFFER1[0 +:8];
assign centralPixel5x5 = BUFFER2[0 +:8];
assign new_line = !(|address);

assign is_line0 = vertical_count == 0;
assign is_line1 = vertical_count == 1;
assign is_lastline = vertical_count == 9'd479;
assign is_prelastline = vertical_count == 9'd478;

assign is_col0 = address == 0;
assign is_col1 = address == 1;
assign is_lastcol = address == 9'd511;
assign is_prelastcol = address == 9'd510;


//assign matrix = {num[24],num[23],num[22],num[21],num[20],
//						 num[19],num[18],num[17],num[16],num[15],
//						 num[14],num[13],num[12],num[11],num[10],
//						 num[9],num[8],num[7],num[6],num[5],
//						 num[4],num[3],num[2],num[1],num[0]};

always @(*) begin

	case (size)
		2'd0: begin // 2x2
			num[0] = BUFFER1[0+:8];
			num[1] = is_lastcol     ? 8'b0 : BUFFER1[8+:8];
			num[2] = is_lastline    ? 8'b0 : BUFFER0[0+:8];
			num[3] = (is_lastcol || is_lastline) ? 8'b0 : BUFFER0[8+:8];
			matrix = {8'b0, 8'b0, 8'b0, num[3], num[2],
						 8'b0, 8'b0, 8'b0, num[1], num[0]};
		end

		2'd1: begin // 3x3
			num[0] = (is_line0 || is_col0)     ? 8'b0 : BUFFER2[4088+:8];
			num[1] = is_line0                  ? 8'b0 : BUFFER2[0+:8];
			num[2] = (is_line0 || is_lastcol)  ? 8'b0 : BUFFER2[8+:8];

			num[3] = is_col0                   ? 8'b0 : BUFFER1[4088+:8];
			num[4] = centralPixel3x3;
			num[5] = is_lastcol                ? 8'b0 : BUFFER1[8+:8];

			num[6] = (is_lastline || is_col0)     ? 8'b0 : BUFFER0[4088+:8];
			num[7] = is_lastline                  ? 8'b0 : BUFFER0[0+:8];
			num[8] = (is_lastline || is_lastcol)  ? 8'b0 : BUFFER0[8+:8];

			matrix = {8'b0, 8'b0, num[8], num[7], num[6],
						 8'b0, 8'b0, num[5], num[4], num[3],
						 8'b0, 8'b0, num[2], num[1], num[0]};
		end

		2'd3: begin // 5x5
			num[0]  = (is_col1 || is_col0 || is_line1 || is_line0) ? 8'b0 : BUFFER4[4080+:8];
			num[1]  = (is_col0 || is_line1 || is_line0) ? 8'b0 : BUFFER4[4088+:8];
			num[2]  = (is_line1 || is_line0) ? 8'b0 : BUFFER4[0+:8];
			num[3]  = (is_lastcol || is_line1 || is_line0) ? 8'b0 : BUFFER4[8+:8];
			num[4]  = (is_prelastcol || is_lastcol || is_line1 || is_line0) ? 8'b0 : BUFFER4[16+:8];

			
			num[5]  = (is_col1 || is_col0 || is_line0) ? 8'b0 : BUFFER3[4080+:8];
			num[6]  = (is_col0 || is_line0) ? 8'b0 : BUFFER3[4088+:8];
			num[7]  = is_line0 ? 8'b0 : BUFFER3[0+:8];
			num[8]  = (is_lastcol || is_line0) ? 8'b0 : BUFFER3[8+:8];
			num[9]  = (is_prelastcol || is_lastcol || is_line0) ? 8'b0 : BUFFER3[16+:8];

			
			num[10] = (is_col1 || is_col0) ? 8'b0 : BUFFER2[4080+:8];
			num[11] = is_col0 ? 8'b0 : BUFFER2[4088+:8];
			num[12] = centralPixel5x5;
			num[13] = is_lastcol ? 8'b0 : BUFFER2[8+:8];
			num[14] = (is_prelastcol || is_lastcol) ? 8'b0 : BUFFER2[16+:8];

			
			num[15] = (is_col1 || is_col0 || is_lastline) ? 8'b0 : BUFFER1[4080+:8];
			num[16] = (is_col0 || is_lastline) ? 8'b0 : BUFFER1[4088+:8];
			num[17] = is_lastline ? 8'b0 : BUFFER1[0+:8];
			num[18] = (is_lastcol || is_lastline) ? 8'b0 : BUFFER1[8+:8];
			num[19] = (is_prelastcol || is_lastcol || is_lastline) ? 8'b0 : BUFFER1[16+:8];

			
			num[20] = (is_col1 || is_col0 || is_lastline || is_prelastline) ? 8'b0 : BUFFER0[4080+:8];
			num[21] = (is_col0 || is_lastline || is_prelastline) ? 8'b0 : BUFFER0[4088+:8];
			num[22] = (is_lastline || is_prelastline) ? 8'b0 : BUFFER0[0+:8];
			num[23] = (is_lastcol || is_lastline || is_prelastline) ? 8'b0 : BUFFER0[8+:8];
			num[24] = (is_prelastcol || is_lastcol || is_lastline || is_prelastline) ? 8'b0 : BUFFER0[16+:8];
		
		
			matrix = {num[24], num[23], num[22], num[21], num[20],
						 num[19], num[18], num[17], num[16], num[15],
						 num[14], num[13], num[12], num[11], num[10],
						 num[9],  num[8],  num[7],  num[6],  num[5],
						 num[4],  num[3],  num[2],  num[1],  num[0]};
		end
		
		default:
			matrix = 0;
	endcase

end

integer i;


always @(posedge clk) begin
	if(save_data) begin
		BUFFER0[address[8:2] * 32 +:32] <= datain;
		
		if(new_line) begin
			BUFFER1 <= BUFFER0;
			BUFFER2 <= BUFFER1;
			BUFFER3 <= BUFFER2;
			BUFFER4 <= BUFFER3;
		end
	end else if (next_matrix) begin
		for (i = 0; i < 511; i = i + 1) begin
			BUFFER0[(i*8)+:8] <= BUFFER0[(i+1)*8+:8];
			BUFFER1[(i*8)+:8] <= BUFFER1[(i+1)*8+:8];
			BUFFER2[(i*8)+:8] <= BUFFER2[(i+1)*8+:8];
			BUFFER3[(i*8)+:8] <= BUFFER3[(i+1)*8+:8];
			BUFFER4[(i*8)+:8] <= BUFFER4[(i+1)*8+:8];
		end
		BUFFER0[(511*8)+:8] <= BUFFER0[0+:8];
		BUFFER1[(511*8)+:8] <= BUFFER1[0+:8];
		BUFFER2[(511*8)+:8] <= BUFFER2[0+:8];
		BUFFER3[(511*8)+:8] <= BUFFER3[0+:8];
		BUFFER4[(511*8)+:8] <= BUFFER4[0+:8];
	end
end
//

//genvar i;
//generate
//        for (i = 0; i < 5; i = i + 1) begin : gen_data
//            begin
//                data[i] = BUFFER0[`PIXEL(address_array[i]) +: 8];
//            end
//        end
//    endgenerate

endmodule