`timescale 1ps / 1ps
//------------------------------------------------------------------------------------------------------------------
// Spartan-6 clock output mirror
//
//	04/19/2012	Initial
//------------------------------------------------------------------------------------------------------------------
	module clock_mirror (input clock, input clock_180, output mirror);

	ODDR2 #(
	.DDR_ALIGNMENT	("NONE"),			// Sets output alignment to "NONE", "C0" or "C1"
	.INIT			(1'b0),				// Sets initial state of the Q output to 1'b0 or 1'b1
	.SRTYPE			("SYNC")			// Specifies "SYNC" or "ASYNC" set/reset
	) uoddr2 (
	.C0				(clock),			// In	1-bit clock
	.C1				(clock_180),		// In	1-bit clock
	.CE				(1'b1),				// In	1-bit clock enable
	.R				(1'b0),				// In	1-bit reset
	.S				(1'b0),				// In	1-bit set
	.D0				(1'b1),				// In	1-bit data associated with C0
	.D1				(1'b0),				// In	1-bit data associated with C1
	.Q				(mirror)			// Out	1-bit DDR data
	);

	endmodule
//------------------------------------------------------------------------------------------------------------------
// End of clock_mirror.v
//------------------------------------------------------------------------------------------------------------------
