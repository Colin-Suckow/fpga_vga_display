

module top (
	input wire clk,
	output wire h_sync,
	output wire v_sync,
	output wire green,
	output wire blue,
	output wire red
);

	reg [32:0] h_pixel_count;
	reg [32:0] v_line_count;
	wire pixel_clk;
	wire [7:0] pixel_data;
	wire [7:0] pixel_position;
	
	localparam HS_START = 16;
	localparam HS_END = 16 + 96;
	localparam HPX_START = 16 + 96 + 48;
	localparam LINE_COUNT = 800;
	
	localparam VS_START = 480 + 11;
	localparam VS_END = 480 + 11 + 2;
	localparam VPX_END = 480;
	localparam SCREEN_HEIGHT = 525;
	
	pixel_pll pll (
		.inclk0(clk),
		.c0(pixel_clk)
	);
	
	screen_rom screen (
		.clock(pixel_clk),
		.address((((h_pixel_count - HPX_START)/8) + ((v_line_count * 640) / 8))),
		.q(pixel_data)
	);

	initial begin

		h_pixel_count <= 0;
		v_line_count <= 0;

	end

	always @(posedge pixel_clk) begin
		
		h_pixel_count <= h_pixel_count + 1;
		if (h_pixel_count >= LINE_COUNT)
		begin
				h_pixel_count <= 0;
				v_line_count <= v_line_count + 1;
		end;
				
		if (v_line_count >= SCREEN_HEIGHT)
			v_line_count <= 0;
		
			
	end

	assign h_sync = ~((h_pixel_count >= HS_START) & (h_pixel_count < HS_END));
	assign v_sync = ~((v_line_count >= VS_START) & (v_line_count < VS_END));
	

	
	assign green = ((h_pixel_count > HPX_START) & (v_line_count < VPX_END) & pixel_data[((7-h_pixel_count-6)) % 8]);
	assign red = ((h_pixel_count > HPX_START) & (v_line_count < VPX_END) & pixel_data[(7-h_pixel_count-6) % 8]);
	assign blue = ((h_pixel_count > HPX_START) & (v_line_count < VPX_END) & pixel_data[(7-h_pixel_count-6) % 8]);

endmodule