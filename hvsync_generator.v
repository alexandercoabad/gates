// Video sync generator, used to drive a VGA monitor.
// Timing from: http://www.tinyvga.com/vga-timing
// To use:
//  - Wire the hsync and vsync signals to top level outputs
//  - Add a 3-bit (or more) "rgb" output to the top level

module hvsync_generator(clk, reset, hsync, vsync, display_on, hpos, vpos);

	input wire clk;
	input wire reset;
	output reg hsync, vsync;
	output wire display_on;
	output reg [9:0] hpos; // horizontal position counter
	output reg [9:0] vpos; // vertical position counter

	// VGA  640 x 480 @ 60 fps (25.175 MHz)
	parameter H_ACTIVE_PIXELS = 640; // horizontal display width
	parameter H_FRONT_PORCH   =  16; // horizontal right border
	parameter H_SYNC_WIDTH    =  96; // horizontal sync width
	parameter H_BACK_PORCH    =  48; // horizontal left border
	parameter H_SYNC          =   0; // 0 (-), 1 (+)
	parameter V_ACTIVE_LINES  = 480; // vertical display height
	parameter V_FRONT_PORCH   =  10; // vertical bottom border
	parameter V_SYNC_HEIGHT   =   2; // vertical sync # lines
	parameter V_BACK_PORCH    =  33; // vertical top border
	parameter V_SYNC          =   0; // 0 (-), 1 (+)

	// derived constants
	wire [9:0] h_sync_start = H_ACTIVE_PIXELS + H_FRONT_PORCH;
	wire [9:0] h_sync_end   = h_sync_start + H_SYNC_WIDTH - 1;
	wire [9:0] h_max        = h_sync_end + H_BACK_PORCH;
	wire [9:0] v_sync_start = V_ACTIVE_LINES + V_FRONT_PORCH;
	wire [9:0] v_sync_end   = v_sync_start + V_SYNC_HEIGHT - 1;
	wire [9:0] v_max        = v_sync_end + V_BACK_PORCH;

	wire hmaxxed = (hpos == h_max) || reset; // set when hpos is maximum
	wire vmaxxed = (vpos == v_max) || reset; // set when vpos is maximum
	wire hactive = (hpos >= h_sync_start) && (hpos <= h_sync_end);
	wire vactive = (vpos >= v_sync_start) && (vpos <= v_sync_end);

	always @(posedge clk)
	begin
		hsync <= hactive ^ ~H_SYNC;
		hpos <= hmaxxed ? 0 : hpos + 1;
		vsync <= vactive ^ ~V_SYNC;
		vpos <= hmaxxed ? (vmaxxed ? 0 : vpos + 1) : vpos;
	end

	// display_on is set when beam is in "safe" visible frame
	assign display_on = (hpos < H_ACTIVE_PIXELS) && (vpos < V_ACTIVE_LINES);

endmodule
