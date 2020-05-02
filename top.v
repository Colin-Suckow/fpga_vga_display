module top (
	input wire clk,
	output wire h_sync,
	output wire v_sync,
	output wire green,
	output wire blue,
	output wire red,
	input SCK,
	input SSEL,
	input MOSI,
	output MISO
);

	reg [32:0] h_pixel_count;
	reg [32:0] v_line_count;
	wire pixel_clk;
	wire main_clk;
	wire [7:0] pixel_data;
	wire [0:7] pixel_data_reverse = pixel_data;
	reg [0:7] pixel_data_reverse_latch;
	
	
	
	wire [15:0] write_address;
	wire [7:0] write_data;
	wire write_enable;
	
	reg state_changed;
	
	wire data_valid;
	wire [7:0] data;
	reg [7:0] byte_to_send;
	wire send_byte;
	
	
	localparam HS_START = 16;
	localparam HS_END = 16 + 96;
	localparam HPX_START = 16 + 96 + 48;
	localparam LINE_COUNT = 800;
	
	localparam VS_START = 480 + 11;
	localparam VS_END = 480 + 11 + 2;
	localparam VPX_END = 480;
	localparam SCREEN_HEIGHT = 525;
	
	reg [15:0] byte_count;
	reg [23:0] message_buffer;
	
	pixel_pll pll (
		.inclk0(clk),
		.c0(main_clk)
	);
	
	reg [4:0] pixel_clk_cnt;
	
	always @(posedge main_clk)
	begin
		pixel_clk_cnt <= pixel_clk_cnt + 1;
	end
	
	assign pixel_clk = pixel_clk_cnt[2];
	
	/*
	screen_rom screen (
		.clock(pixel_clk),
		.address((((h_pixel_count - HPX_START)/8) + ((v_line_count * 640) / 8))),
		.q(pixel_data)
	);
	*/
	
	screen_ram screen (
		.clock(main_clk),
		.data(write_data),
		.rdaddress((((h_pixel_count - HPX_START)/8) + ((v_line_count * 640) / 8))),
		.wraddress(write_address),
		.wren(write_enable),
		.q(pixel_data)
	);
	
	SPI_Slave spi (
		.i_Rst_L(1),
		.i_Clk(main_clk),
		.i_SPI_Clk(SCK),
		.i_SPI_CS_n(SSEL),
		.i_SPI_MOSI(MOSI),
		.o_SPI_MISO(MISO),
		.o_RX_DV(data_valid),
		.o_RX_Byte(data),
		.i_TX_Byte(byte_to_send),
		.i_TX_DV(send_byte)
	);
	
	reg [15:0] init_write_address;
	
	always @(posedge main_clk)
	begin
	
		if(SSEL)
		begin
			byte_count <= 0;
			init_write_address <= 0;
		end
		if(data_valid)
		begin
			byte_count <= byte_count + 1'b1;
			message_buffer <= {message_buffer[15:0], data};
		end
		
		if(byte_count == 3)
		begin
			init_write_address <= message_buffer[23:8];
		end
			
	end
	

	assign write_address = init_write_address + (byte_count - 3);
	assign write_data = message_buffer[7:0];
	assign write_enable = (byte_count >= 3);

	initial begin
		h_pixel_count <= 0;
		v_line_count <= 0;
	end

	reg last_pixel_clk;
	
	always @(posedge main_clk) begin
	
		if(pixel_clk != last_pixel_clk)
		begin
			h_pixel_count <= h_pixel_count + 1;
			if (h_pixel_count >= LINE_COUNT)
			begin
					h_pixel_count <= 0;
					v_line_count <= v_line_count + 1;
			end;
					
			if (v_line_count >= SCREEN_HEIGHT)
				v_line_count <= 0;
				
			pixel_data_reverse_latch <= pixel_data_reverse;
				
		end
		
		last_pixel_clk <= pixel_clk;
		
	end
	
	

	assign h_sync = ~((h_pixel_count >= HS_START) & (h_pixel_count < HS_END));
	assign v_sync = ~((v_line_count >= VS_START) & (v_line_count < VS_END));
	
	
	assign green = ((h_pixel_count > HPX_START) & (v_line_count < VPX_END) & pixel_data_reverse_latch[h_pixel_count - 1 % 8]);
	assign red = ((h_pixel_count > HPX_START) & (v_line_count < VPX_END) & pixel_data_reverse_latch[h_pixel_count - 1 % 8]);
	assign blue = ((h_pixel_count > HPX_START) & (v_line_count < VPX_END) & pixel_data_reverse_latch[h_pixel_count - 1 % 8]);

endmodule