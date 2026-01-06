module vga_control(
	input clk,
	input [31:0] ram_data,
	output [15:0] addr,
	output hsync, 
	output vsync,
	output [7:0]red,
	output [7:0]green,
	output [7:0]blue,
	output vga_sync,
	output vga_clk,
	output vga_blank
);


wire [9:0] x, y;
reg [7:0] color;
reg MHz25;
wire [1:0] offset;
wire [7:0] pixel_color;

assign pixel_color = (x[9]||y[9]) ? 8'h0 : color;
assign offset = x[1:0];
assign addr = {y[8:0],x[8:2]};
	 
	 
vga_driver vga_main_driver(
	MHz25,
	0,
	pixel_color, 
	x, 
	y,
	hsync,
	vsync,
	red,
	green,
	blue,
	vga_sync,
	vga_clk,
	vga_blank
);
	
	
always @(*) begin
    case (offset)
        0: begin
            color   = ram_data[7:0];
        end
        1: begin
            color   = ram_data[15:8];
        end
        2: begin
            color   = ram_data[23:16];
        end
        3: begin
            color   = ram_data[31:24];
        end
        default: begin
            color   = 0;
        end
    endcase
end

	
always @(posedge clk) begin
	MHz25 <= ~MHz25;
end
	

	 
endmodule