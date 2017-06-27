`timescale 1ns / 1ps
//------------------------------------------------------------------------------------------------------------------
//	1-to-2 De-multiplexer converts 80MHz data to 40MHz ALCT
//
//	03/11/2009	Initial
//	04/25/2012	Mod for alct single cable test
//------------------------------------------------------------------------------------------------------------------
	module x_demux_alct (din,clock_1x,clock_2x,dout1st,dout2nd);

// Generic
	parameter WIDTH = 1;

// Ports
	input	[WIDTH-1:0]	din;		// 40 MHz data in
	input				clock_1x;	// 40 MHz clock
	input				clock_2x;	// 80 MHz clock
	output	[WIDTH-1:0]	dout1st;	// 1st in time out
	output	[WIDTH-1:0]	dout2nd;	// 2nd in time out

// Local
	reg		[WIDTH-1:0]	din_ff;
	reg		[WIDTH-1:0]	xfer_ff;
	reg		[WIDTH-1:0]	dout1st;
	reg		[WIDTH-1:0]	dout2nd;

// Latch 80 MHz multiplexed inputs in IOB FFs
	always @(posedge clock_2x) begin
	din_ff <= din;
	end

// Transfer 1st-in-time to holding FFs
	always @(posedge clock_2x) begin
	xfer_ff <= din_ff;
	end

// Synchoronize to 40MHz main clock
	always @(posedge clock_1x) begin
	dout1st <= xfer_ff;
	dout2nd <= din_ff;
	end

	endmodule
