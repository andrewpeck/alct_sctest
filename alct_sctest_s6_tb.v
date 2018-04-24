`timescale 1ns / 1ps

`include "firmware_version.v"

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   15:54:23 03/01/2018
// Design Name:   alct_sctest
// Module Name:   D:/Dropbox/CMS/OALCT/alct_sctest_s6/alct_sctest_s6_tb.v
// Project Name:  alct_sctest_s6_lx100
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: alct_sctest
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module alct_sctest_s6_tb;

   `ifdef ALCT672
   parameter MXCLKOUT = 2;
   `else
   parameter MXCLKOUT = 1;
   `endif

`ifdef ALCT672
    parameter N=7;
    parameter MXADBS=N*6;
`elsif ALCT384
    parameter N=4;
    parameter MXADBS=N*6;
`elsif ALCT288
    parameter N=3;
    parameter MXADBS=N*6;
`endif


    // Inputs
    reg clock_mez;
    reg clock_en;
    reg [47:0] lct0_;
    reg [47:0] lct1_;
    reg [47:0] lct2_;
    reg [47:0] lct3_;
    reg [47:0] lct4_;
    reg [47:0] lct5_;
    reg [47:0] lct6_;
    reg m_ext_inject;
    reg m_l1_accept;
    reg [3:0] m_ccb_brcst;
    reg m_brcst_str1;
    reg m_dout_str;
    reg tck_ctrl;
    reg tms_ctrl;
    reg tdi_ctrl;
    reg [N-1:0] dout_dly;
    reg async_adb;
    reg tp_start_ext;
    reg [1:0] m_seq_cmd;
    reg sc_done;
    reg [1:0] m_reserved_in;
    reg adc_sdo;
    reg adc_eoc;
    reg init_b;
    reg [1:0] m;
    reg rdwr_b;
    reg refclk_p;
    reg gbt_txrdy;

    wire [1:0] gbt_clk40_p = {2{clock_mez}};
    wire [1:0]  gbt_clk40_n = ~gbt_clk40_p;

    wire refclk_n = ~refclk_p;
    wire [13:0] elink_p, elink_n;
    wire gbt_tx_datavalid;

    // Outputs
    wire [MXCLKOUT-1:0] clk80;
    wire [MXCLKOUT-1:0] clk40sh;
    wire nmx_oe;
    wire m_active_feb;
    wire m_valid;
    wire [6:0] m_key;
    wire [1:0] m_quality;
    wire m_amu;
    wire [2:0] m_bxn;
    wire [6:0] m_daq_data;
    wire m_lct_special;
    wire m_ddu_special;
    wire jstate0_grn;
    wire jstate1_grn;
    wire jstate2_grn;
    wire jstate3_grn;
    wire feb0_grn;
    wire feb1_grn;
    wire feb2_grn;
    wire feb3_grn;
    wire feb4_grn;
    wire feb5_grn;
    wire feb6_grn;
    wire tck_grn;
    wire tms_grn;
    wire tdi_grn;
    wire tdo_grn;
    wire halt_red;
    wire l1a_ok_grn;
    wire no_l1a_red;
    wire invpat_red;
    wire amu_grn;
    wire pretrig_blu;
    wire [31:0] tp1_;
    wire tdo_ctrl;
    wire clk_dly;
    wire din_dly;
    wire nrs_dly;
    wire seltst_dly;
    wire [N-1:0] ncs_dly;
    wire test_pulse;
    wire [1:0] m_seq_status;
    wire [1:0] m_reserved_out;
    wire adc_sck;
    wire adc_sdi;
    wire adc_ncs;
    wire [1:0] tx_p;
    wire [1:0] tx_n;

    // Bidirs
    wire [31:0] tp0_;
    wire alct_sn;
    wire mez_sn;

    // Instantiate the Unit Under Test (UUT)
    alct_sctest uut (
        .clock_mez(clock_mez),
        .clock_en(clock_en),
        .clk80(clk80),
        .clk40sh(clk40sh),
        .nmx_oe(nmx_oe),
     `ifdef ALCT672
        .lct0_(lct0_),
        .lct1_(lct1_),
        .lct2_(lct2_),
        .lct3_(lct3_),
        .lct4_(lct4_),
        .lct5_(lct5_),
        .lct6_(lct6_),
     `elsif ALCT384
        .lct0_(lct0_),
        .lct1_(lct1_),
        .lct2_(lct2_),
        .lct3_(lct3_),
     `elsif ALCT288
        .lct0_(lct0_),
        .lct1_(lct1_),
        .lct2_(lct2_),
     `endif
        .m_ext_inject(m_ext_inject),
        .m_active_feb(m_active_feb),
        .m_valid(m_valid),
        .m_key(m_key),
        .m_quality(m_quality),
        .m_amu(m_amu),
        .m_bxn(m_bxn),
        .m_l1_accept(m_l1_accept),
        .m_daq_data(m_daq_data),
        .m_lct_special(m_lct_special),
        .m_ddu_special(m_ddu_special),
        .m_ccb_brcst(m_ccb_brcst),
        .m_brcst_str1(m_brcst_str1),
        .m_dout_str(m_dout_str),
        .jstate0_grn(jstate0_grn),
        .jstate1_grn(jstate1_grn),
        .jstate2_grn(jstate2_grn),
        .jstate3_grn(jstate3_grn),
        .feb0_grn(feb0_grn),
        .feb1_grn(feb1_grn),
        .feb2_grn(feb2_grn),
        .feb3_grn(feb3_grn),
        .feb4_grn(feb4_grn),
        .feb5_grn(feb5_grn),
        .feb6_grn(feb6_grn),
        .tck_grn(tck_grn),
        .tms_grn(tms_grn),
        .tdi_grn(tdi_grn),
        .tdo_grn(tdo_grn),
        .halt_red(halt_red),
        .l1a_ok_grn(l1a_ok_grn),
        .no_l1a_red(no_l1a_red),
        .invpat_red(invpat_red),
        .amu_grn(amu_grn),
        .pretrig_blu(pretrig_blu),
        .tp0_(tp0_),
        .tp1_(tp1_),
        .tck_ctrl(tck_ctrl),
        .tms_ctrl(tms_ctrl),
        .tdi_ctrl(tdi_ctrl),
        .tdo_ctrl(tdo_ctrl),
        .clk_dly(clk_dly),
        .din_dly(din_dly),
        .nrs_dly(nrs_dly),
        .seltst_dly(seltst_dly),
        .ncs_dly(ncs_dly),
        .dout_dly(dout_dly),
        .async_adb(async_adb),
        .test_pulse(test_pulse),
        .tp_start_ext(tp_start_ext),
        .m_seq_cmd(m_seq_cmd),
        .m_seq_status(m_seq_status),
        .sc_done(sc_done),
        .m_reserved_in(m_reserved_in),
        .m_reserved_out(m_reserved_out),
        .alct_sn(alct_sn),
        .mez_sn(mez_sn),
        .adc_sck(adc_sck),
        .adc_sdi(adc_sdi),
        .adc_ncs(adc_ncs),
        .adc_sdo(adc_sdo),
        .adc_eoc(adc_eoc),
        .init_b(init_b),
        .m(m),
        .rdwr_b(rdwr_b)
	`ifdef LX150T
	 , .tx_p(tx_p)
	 , .tx_n(tx_n)
	 , .refclk_p(refclk_p)
	 , .refclk_n(refclk_n)
	`elsif LX100
	 , .elink_p            	 (elink_p)
	 , .elink_n            	 (elink_n)

	 , .gbt_clk40_p        	 (gbt_clk40_p)
	 , .gbt_clk40_n        	 (gbt_clk40_n)

	 , .gbt_txrdy          	 (gbt_txrdy)
	 , .gbt_tx_datavalid   	 (gbt_tx_datavalid)
	`endif
    );

    initial begin
        // Initialize Inputs
        clock_mez = 0;
        clock_en = 0;
        lct0_ = 0;
        lct1_ = 0;
        lct2_ = 0;
        lct3_ = 0;
        lct4_ = 0;
        lct5_ = 0;
        lct6_ = 0;
        m_ext_inject = 0;
        m_l1_accept = 0;
        m_ccb_brcst = 0;
        m_brcst_str1 = 0;
        m_dout_str = 0;
        tck_ctrl = 0;
        tms_ctrl = 0;
        tdi_ctrl = 0;
        dout_dly = 0;
        async_adb = 0;
        tp_start_ext = 0;
        m_seq_cmd = 0;
        sc_done = 0;
        m_reserved_in = 0;
        adc_sdo = 0;
        adc_eoc = 0;
        init_b = 0;
        m = 0;
        rdwr_b = 0;
        refclk_p = 0;
	gbt_txrdy = 0;

        // Wait 100 ns for global reset to finish
        #100;

        // Add stimulus here
	gbt_txrdy = 1;

    end

   //--------------------------------------------------------------------------------------------------------
   // 40MHz main clock 50% duty cycle
   //--------------------------------------------------------------------------------------------------------

   parameter real  PERIOD     = 25.0;
   parameter real  DUTY_CYCLE = 0.5;
   parameter real  OFFSET     = 100.0-(PERIOD*DUTY_CYCLE);

   initial begin
      clock_mez= 1'b0;
      #OFFSET;

      forever begin
     clock_mez = 1'b0;
     #(PERIOD-(PERIOD*DUTY_CYCLE))
     clock_mez = 1'b1;
     #(PERIOD*DUTY_CYCLE);
      end
   end

   //--------------------------------------------------------------------------------------------------------
   // 80MHz reference clock 50% duty cycle
   //--------------------------------------------------------------------------------------------------------

   parameter real  MGT_PERIOD     = 12.5;
   parameter real  MGT_DUTY_CYCLE = 0.5;
   parameter real  MGT_OFFSET     = 100.0-(MGT_PERIOD*MGT_DUTY_CYCLE);

   initial begin
      refclk_p= 1'b0;
      #MGT_OFFSET;

      forever begin
     refclk_p = 1'b0;
     #(MGT_PERIOD-(MGT_PERIOD*MGT_DUTY_CYCLE))
     refclk_p = 1'b1;
     #(MGT_PERIOD*MGT_DUTY_CYCLE);
      end
   end


endmodule
