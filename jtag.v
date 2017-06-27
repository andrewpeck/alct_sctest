//------------------------------------------------------------------------------------------------------------------
// JTAG TAP Controller
//
// 08/25/04 Initial
// 10/17/05 Conform trst to jtag standard, active low, async, goes to tlr
// 12/21/05 Change tdi latch to posedge
//
//------------------------------------------------------------------------------------------------------------------
	module jtag
	(	
	tck,
	tms,
	tdi,
	tdo,
	ntrst,
	state
	);

// Constants
	parameter MXSTATE	= 4;				// Number tap bits

// IO Ports
	input					tck;			// Test Clock
	input					tms;			// Test Mode Select
	input					tdi;			// Test Data Input
	input					ntrst;			// Test Reset, active low
	output					tdo;			// Test Data Output
	output	[MXSTATE-1:0]	state; 			// JTAG machine status

// Test Access Port state machine declarations
	(* fsm_encoding="user" *)
	reg 	[MXSTATE-1:0]	tap;

	parameter test_logic_reset	=	4'h0;
	parameter run_test_idle		=	4'h1;
	parameter select_dr_scan	=	4'h2;
	parameter capture_dr		=	4'h3;
	parameter shift_dr			=	4'h4;
	parameter exit1_dr			=	4'h5;
	parameter pause_dr			=	4'h6;
	parameter exit2_dr			=	4'h7;
	parameter update_dr			=	4'h8;
	parameter select_ir_scan	=	4'h9;
	parameter capture_ir		=	4'hA;
	parameter shift_ir			=	4'hB;
	parameter exit1_ir			=	4'hC;
	parameter pause_ir			=	4'hD;
	parameter exit2_ir			=	4'hE;
	parameter update_ir			=	4'hF;

	parameter L					=	0;
	parameter H					=	1;

// TDO transitions on falling edge of tck, so latch it on rising edge
	reg	tdo=0;	

	always @(posedge tck) begin
	tdo	<= tdi;
	end

// Status output
	assign state = tap;

//xsynthesis attribute fsm_encoding of tap is "user"
// TAP State Machine
	always @(posedge tck or negedge ntrst) begin	
	if (!ntrst)       tap = test_logic_reset;
	else begin

	case (tap)

	test_logic_reset:
		if (tms == L) tap = run_test_idle;

	run_test_idle:
		if (tms == H) tap = select_dr_scan;

	select_dr_scan:
		if (tms == H) tap = select_ir_scan;
	 	else		  tap = capture_dr;

	capture_dr:
		if (tms == H) tap = exit1_dr;
	 	else		  tap = shift_dr;

	shift_dr:
		if (tms == H) tap = exit1_dr;

	exit1_dr:
		if (tms == H) tap = update_dr;
	 	else		  tap = pause_dr;

	pause_dr:
		if (tms == H) tap = exit2_dr;

	exit2_dr:
		if (tms == H) tap = update_dr;
		else		  tap = shift_dr;

	update_dr:
		if (tms == H) tap = select_dr_scan;
		else		  tap = run_test_idle;

	select_ir_scan:
		if (tms == H) tap = test_logic_reset;
		else		  tap = capture_ir;

	capture_ir:
		if (tms == H) tap = exit1_ir;
		else		  tap = shift_ir;

	shift_ir:
		if (tms == H) tap = exit1_ir;

	exit1_ir:
		if (tms == H) tap = update_ir;
		else		  tap = pause_ir;

	pause_ir:
		if (tms == H) tap = exit2_ir;

	exit2_ir:
		if (tms == H) tap = update_ir;
		else		  tap = shift_ir;

	update_ir:
		if (tms == H) tap = select_dr_scan;
	 	else		  tap = run_test_idle;

	default:
	 				  tap = test_logic_reset;
	endcase
	end
	end

	endmodule
