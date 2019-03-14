`timescale 1ns / 1ps
//------------------------------------------------------------------------------------------------------------------
//
// ALCT Single Cable Test:  For Spartan-6 and Virtex-E Mezzanine Cards
//
`include "firmware_version.v"
//
//------------------------------------------------------------------------------------------------------------------
//  04/17/2012  Initial, adapted from alct_loop_demo.v with jtag state machine from rat2005e
//  04/18/2012  Add test points and multiplexer clocks
//  04/19/2012  Add status registers
//  04/20/2012  Add mirrors for clock outputs
//  04/20/2012  Add ADC and digital serial numbers
//  04/24/2012  Pulse scsi outputs at 625KHz ala old firmware
//  04/25/2012  Add delay asic reset
//  04/26/2012  Fix scsi signal order
//  04/30/2012  Add push button address increment
//  05/01/2012  Change registers to match alct test software
//  05/03/2012  Float dual purpose pins
//  05/05/2012  Replace DLL with PLL
//  05/07/2012  Add SEU and unconnected adb register
//  05/08/2012  Add latch for unconnected adb register
//  01/10/2018  Additions for testing of lx100 and lx150t mezzanines
//------------------------------------------------------------------------------------------------------------------
//  J5 ALCT Cable-1 Connector [Transmiter]
//------------------------------------------------------------------------------------------------------------------
//Pair Inv   Pins   Dir Logic   rx/tx   Multiplexed Signals
//           +  -                       First_in_Time  Second_in_Time
//  1   !   1+  2-  Out LVDS    tx[4]    first_valid    second_valid
//  2       49+ 50- Out LVDS    tx[5]    first_amu      second_amu
//  3   !   3+  4-  Out LVDS    tx[6]    first_quality0 second_quality0
//  4       47+ 48- Out LVDS    tx[7]    first_quality1 second_quality1
//  5   !   5+  6-  Out LVDS    tx[8]    first_key0     second_key0
//  6       45+ 46- Out LVDS    tx[9]    first_key1     second_key1
//  7   !   7+  8-  Out LVDS    tx[10]   first_key2     second_key2
//  8       43+ 44- Out LVDS    tx[11]   first_key3     second_key3
//  9   !   9+  10- Out LVDS    tx[12]   first_key4     second_key4
//  10      41+ 42- Out LVDS    tx[13]   first_key5     second_key5
//  11  !   11+ 12- Out LVDS    tx[14]   first_key6     second_key6
//  12      39+ 40- Out LVDS    tx[15]   bxn0           bxn3
//  13  !   13+ 14- Out LVDS    tx[16]   bxn1           bxn4
//  14      37+ 38- Out LVDS    tx[17]   bxn2           /wr_fifo
//  15  !   15+ 16- Out LVDS    tx[18]   daq_data0      daq_data7
//  16      35+ 36- Out LVDS    tx[19]   daq_data1      daq_data8
//  17  !   17+ 18- Out LVDS    tx[20]   daq_data2      daq_data9
//  18      33+ 34- Out LVDS    tx[21]   daq_data3      daq_data10
//  19  !   19+ 20- Out LVDS    tx[22]   daq_data4      daq_data11
//  20      31+ 32- Out LVDS    tx[23]   daq_data5      daq_data12
//  21  !   21+ 22- Out LVDS    tx[24]   daq_data6      daq_data13
//  22      29+ 30- Out LVDS    tx[25]   lct_special    first_frame
//  23  !   23+ 24- Out LVDS    tx[26]   seq_status0    seu_status0
//  24      27+ 28- Out LVDS    tx[27]   seq_status1    seu_status1
//  25  !   25+ 26- Out LVDS    tx[28]   ddu_special    last_frame
//
//------------------------------------------------------------------------------------------------------------------
//  J4 ALCT Cable-2 Connector [Receiver]
//------------------------------------------------------------------------------------------------------------------
//Pair Inv   Pins   Dir Logic   rx/tx   Multiplexed Signals
//           +  -                       First_in_Time  Second_in_Time
//  1       1+  2-  In  LVDS    rx[0]           tdi
//  2   !   49+ 50- In  LVDS    rx[1]           tms
//  3       3+  4-  In  LVDS    rx[2]           tck
//  4   !   47+ 48- In  LVDS    rx[3]           jtag_select0
//  5       5+  6-  In  LVDS    rx[4]           jtag_select1
//  6   !   45+ 46- In  LVDS    rx[5]    ccb_brcst0     ccb_brcst4
//  7       7+  8-  In  LVDS    rx[6]    ccb_brcst1     ccb_brcst5
//  8   !   43+ 44- In  LVDS    rx[7]    ccb_brcst2     ccb_brcst6
//  9       9+  10- In  LVDS    rx[8]    ccb_brcst3     ccb_brcst7
//  10  !   41+ 42- In  LVDS    rx[9]    brcst_str1     subaddr_str
//  11      11+ 12- In  LVDS    rx[10]   dout_str       bx0
//  12  !   39+ 40- In  LVDS    rx[11]   ext_inject     ext_trig
//  13      13+ 14- In  LVDS    rx[12]   level1_accept  sync_adb_pulse
//  14  !   37+ 38- In  LVDS    rx[13]   seq_cmd0       seq_cmd2
//  15      15+ 16- In  LVDS    rx[14]   seq_cmd1       reserved_in4
//  16  !   35+ 36- In  LVDS    rx[15]   reserved_in0   reserved_in2
//  17      17+ 18- In  LVDS    rx[16]   reserved_in1   reserved_in3
//  18  !   33+ 34- In  LVDS    rx[17]          async_adb_pulse
//  19      19+ 20- In  LVDS    rx[18]          /hard_reset
//  20  !   31+ 32- In  LVDS    rx[19]          clock_en
//  21      21+ 22- In  LVDS    rx[20]          clock
//  22      29+ 30- Out LVDS    tx[0]           tdo
//  23  !   23+ 24- Out LVDS    tx[1]    reserved_out0  reserved_out2
//  24      27+ 28- Out LVDS    tx[2]    reserved_out1  reserved_out3
//  25  !   25+ 26- Out LVDS    tx[3]    active_feb_flag cfg_done
//
//------------------------------------------------------------------------------------------------------------------
    module alct_sctest
//------------------------------------------------------------------------------------------------------------------
    (
// Clock
    clock_mez,
    clock_en,

// ADB Multiplexer
    clk80,
    clk40sh,
    nmx_oe,

// ADB Signal Inputs 80MHz
`ifdef ALCT672
    lct0_,              // ADB one-shots    672 384 288
    lct1_,              // ADB one-shots    672 384 288
    lct2_,              // ADB one-shots    672 384 288
    lct3_,              // ADB one-shots    672 384
    lct4_,              // ADB one-shots    672
    lct5_,              // ADB one-shots    672
    lct6_,              // ADB one-shots    672
`elsif ALCT384
    lct0_,              // ADB one-shots    672 384 288
    lct1_,              // ADB one-shots    672 384 288
    lct2_,              // ADB one-shots    672 384 288
    lct3_,              // ADB one-shots    672 384
`elsif ALCT288
    lct0_,              // ADB one-shots    672 384 288
    lct1_,              // ADB one-shots    672 384 288
    lct2_,              // ADB one-shots    672 384 288
`endif

// Trigger Path
    m_ext_inject,
    m_active_feb,
    m_valid,
    m_key,
    m_quality,
    m_amu,
    m_bxn,

// DAQ Path
    m_l1_accept,
    m_daq_data,
    m_lct_special,
    m_ddu_special,

// CCB IOs
    m_ccb_brcst,
    m_brcst_str1,
    m_dout_str,

// LEDs low enables
    jstate0_grn,
    jstate1_grn,
    jstate2_grn,
    jstate3_grn,
    feb0_grn,
    feb1_grn,
    feb2_grn,
    feb3_grn,
    feb4_grn,
    feb5_grn,
    feb6_grn,
    tck_grn,
    tms_grn,
    tdi_grn,
    tdo_grn,
    halt_red,
    l1a_ok_grn,
    no_l1a_red,
    invpat_red,
    amu_grn,
    pretrig_blu,

// Test points
    tp0_,
    tp1_,

// User JTAG
    tck_ctrl,
    tms_ctrl,
    tdi_ctrl,
    tdo_ctrl,

// Delay ASICs
    clk_dly,
    din_dly,
    nrs_dly,
    seltst_dly,
    ncs_dly,
    dout_dly,

// Test Pulse
    async_adb,
    test_pulse,
    tp_start_ext,

// Sequencer Status
    m_seq_cmd,
    m_seq_status,
    sc_done,

// Reserved
    m_reserved_in,
    m_reserved_out,

// Serial Number
    alct_sn,
    mez_sn

`ifdef SPARTAN6
// Spartan-6 ADC
    ,adc_sck
    ,adc_sdi
    ,adc_ncs
    ,adc_sdo
    ,adc_eoc

// Spartan-6 dual purpose pins
    ,init_b
    ,m
    ,rdwr_b

`ifdef LX150T
   , tx_p
   , tx_n

   , refclk_p
   , refclk_n
 `elsif LX100
   , elink_p
   , elink_n

   , gbt_clk40_p
   , gbt_clk40_n
   , gbt_clk320_p
   , gbt_clk320_n

   , gbt_txrdy
   , gbt_tx_datavalid
  `endif
`endif
    );

//------------------------------------------------------------------------------------------------------------------
// ALCT384 IO Ports
//------------------------------------------------------------------------------------------------------------------
// Clock
    input           clock_mez;      // 40MHz mezzanine clock GCLK0
    input           clock_en;       // Clock enable

// ADB Multiplexer
   `ifdef ALCT672
   parameter MXCLKOUT = 2;
   `else
   parameter MXCLKOUT = 1;
   `endif

    output  [MXCLKOUT-1:0] clk80;          // Multiplexer clocks 80MHz obuf f 24
    output  [MXCLKOUT-1:0] clk40sh;        // Multiplexer clocks 40MHz
    output                 nmx_oe;         // Multiplexer enable, 0=en, pullup onboard

// ADB Signal Inputs 80MHz
`ifdef ALCT672
    parameter N=7;
    parameter MXADBS=N*6;
    input   [47:0]  lct0_;          // ADB one-shots    672 384 288
    input   [47:0]  lct1_;          // ADB one-shots    672 384 288
    input   [47:0]  lct2_;          // ADB one-shots    672 384 288
    input   [47:0]  lct3_;          // ADB one-shots    672 384
    input   [47:0]  lct4_;          // ADB one-shots    672
    input   [47:0]  lct5_;          // ADB one-shots    672
    input   [47:0]  lct6_;          // ADB one-shots    672
`elsif ALCT384
    parameter N=4;
    parameter MXADBS=N*6;
    input   [47:0]  lct0_;          // ADB one-shots    672 384 288
    input   [47:0]  lct1_;          // ADB one-shots    672 384 288
    input   [47:0]  lct2_;          // ADB one-shots    672 384 288
    input   [47:0]  lct3_;          // ADB one-shots    672 384
`elsif ALCT288
    parameter N=3;
    parameter MXADBS=N*6;
    input   [47:0]  lct0_;          // ADB one-shots    672 384 288
    input   [47:0]  lct1_;          // ADB one-shots    672 384 288
    input   [47:0]  lct2_;          // ADB one-shots    672 384 288
`endif
// Trigger Path
    input           m_ext_inject;   // External inject/ext_trig
    output          m_active_feb;   // LCT active feb
    output          m_valid;        // LCT valid patter flag
    output  [6:0]   m_key;          // LCT key wire group
    output  [1:0]   m_quality;      // LCT quality
    output          m_amu;          // LCT accelerator muon
    output  [2:0]   m_bxn;          // LCT bxn

// DAQ Path
    input           m_l1_accept;    // Level 1 accept/sync_adb_pulse
    output  [6:0]   m_daq_data;     // DAQ data
    output          m_lct_special;  // LCT special word flag
    output          m_ddu_special;  // DDU special word flag

// CCB IOs
    input   [3:0]   m_ccb_brcst;    // CCB commands         ccb_brcst[3:0]/ccb_brcst[7:4]
    input           m_brcst_str1;   // CCB_command_strobe   brcst_str1/subaddr_str
    input           m_dout_str;     // CCB_data_strobe      dout_str/bx0

// LEDs low enables
    output          jstate0_grn;    // D26
    output          jstate1_grn;    // D27
    output          jstate2_grn;    // D28
    output          jstate3_grn;    // D29
    output          feb0_grn;       // D19
    output          feb1_grn;       // D20
    output          feb2_grn;       // D21
    output          feb3_grn;       // D22
    output          feb4_grn;       // D23
    output          feb5_grn;       // D25
    output          feb6_grn;       // D24
    output          tck_grn;        // D15
    output          tms_grn;        // D18
    output          tdi_grn;        // D17
    output          tdo_grn;        // D16
    output          halt_red;       // D14
    output          l1a_ok_grn;     // D10
    output          no_l1a_red;     // D12
    output          invpat_red;     // D11
    output          amu_grn;        // D13
    output          pretrig_blu;    // D5

// Test points
    inout   [31:0]  tp0_;           // Pin rows
    output  [31:0]  tp1_;           // Pin rows

// User JTAG
    input           tck_ctrl;       // jtag clock
    input           tms_ctrl;       // jtag command
    input           tdi_ctrl;       // jtag data in
    output          tdo_ctrl;       // jtag data out

// Delay ASICs
    output          clk_dly;        // Clock to   delay asics
    output  reg     din_dly;        // Serial data  to   delay asics
    output          nrs_dly;        // Reset
    output          seltst_dly;     // Select test mode data from delay asics
    output  [N-1:0] ncs_dly;        // *chip select 672[6:0] 384[3:0] 288[2:0]
    input   [N-1:0] dout_dly;       // Serial data from delay asics

// Test Pulse
    input           async_adb;      // Test pulse from TMB
    output          test_pulse;     // Fire adb test pulser
    input           tp_start_ext;   // Test pulse from lemo input

// Sequencer Status
    input   [1:0]   m_seq_cmd;      // Commands to sequencer    seq_cmd[1:0]/{seq_cmd2,seq_cmd3}
    output  [1:0]   m_seq_status;   // Sequencer status
    input           sc_done;        // Slow Control fpga done

// Reserved
    input   [1:0]   m_reserved_in;  // Future use               reserved_in0/reserved_in2
    output  [1:0]   m_reserved_out; // Future use               reserved_in1/reserved_in3

// Serial Number
    inout           alct_sn;        // ALCT main board
    inout           mez_sn;         // Mezzanine

`ifdef SPARTAN6
// Spartan-6 ADC

    output          adc_sck;        // Serial clock
    output          adc_sdi;        // Serial data to ADC
    output          adc_ncs;        // Chip select active low
    input           adc_sdo;        // Serial data from ADC
    input           adc_eoc;        // End of conversion

// Spartan-6 dual purpose pins
    input           init_b;         // INIT_B
    input   [1:0]   m;              // M0, M1
    input           rdwr_b;         // RDWR_B

   `ifdef LX150T
   output [1:0] tx_p;
   output [1:0] tx_n;
   input refclk_p;
   input refclk_n;
  `elsif LX100
   output [13:0] elink_p;
   output [13:0] elink_n;

   input gbt_clk40_p;
   input gbt_clk40_n;

   input gbt_clk320_p;
   input gbt_clk320_n;

   input gbt_txrdy;
   output gbt_tx_datavalid;
   `endif
`endif

//------------------------------------------------------------------------------------------------------------------
// Display global definitions
//------------------------------------------------------------------------------------------------------------------
    `ifdef VIRTEXE      initial $display ("VIRTEXE     "); `endif
    `ifdef SPARTAN6     initial $display ("SPARTAN6    "); `endif

    `ifdef ALCT288      initial $display ("ALCT288     "); `endif
    `ifdef ALCT384      initial $display ("ALCT384     "); `endif
    `ifdef ALCT672      initial $display ("ALCT672     "); `endif

//------------------------------------------------------------------------------------------------------------------
// Virtex-E Global Clock Buffers and DLL
//------------------------------------------------------------------------------------------------------------------
`ifdef VIRTEXE

    IBUFG uibufg_clock   (.I(clock_mez   ), .O(clock_mez_ibufg));
    BUFG  ubufg_clock_1x (.I(clock_1x_dll), .O(clock          ));
    BUFG  ubufg_clock_2x (.I(clock_2x_dll), .O(clock_2x       ));

// Multiplexer enable, 0=en, pullup onboard
    assign nmx_oe = 0;

// Receive multiplexer clocks 40MHz
    reg [1:0] clk40sh = 0;
    reg       sel     = 0;

    always @(negedge clock_2x) begin
    clk40sh[1:0] <= {sel,sel};
    sel          <= !sel;
    end

// Receive multiplexer clocks 80MHz obuf fast 24ma
    OBUF uclk80_0 (.I(clock_2x_dll), .O(clk80[0]));
    OBUF uclk80_1 (.I(clock_2x_dll), .O(clk80[1]));

// DLL generates clocks 1x=40MHz, 2x=80MHz
    CLKDLLE udll0p (
    .CLKIN      (clock_mez_ibufg),
    .CLKFB      (clock_2x),
    .RST        (1'b0),
    .CLK0       (clock_1x_dll),
    .CLK90      (),
    .CLK180     (),
    .CLK270     (),
    .CLK2X      (clock_2x_dll),
    .CLK2X180   (),
    .CLKDV      (),
    .LOCKED     (clock_lock));

// VirtexE location constraints
    // synthesis attribute LOC of uibufg_clock   is "GCLKPAD0"
    // synthesis attribute LOC of ubufg_clock_2x is "GCLKBUF0"
    // synthesis attribute LOC of ubufg_clock_1x is "GCLKBUF1"
    // synthesis attribute LOC of udll0p         is "DLL0P"

    defparam udll0p.STARTUP_WAIT            = "TRUE";
    defparam udll0p.DUTY_CYCLE_CORRECTION   = "TRUE";

//------------------------------------------------------------------------------------------------------------------
// Spartan-6 Global Clock Buffers and PLL
//------------------------------------------------------------------------------------------------------------------
`elsif SPARTAN6

    IBUFG uibufg_clock       (.I(clock_mez       ), .O(clock_mez_ibufg));
    BUFG  uibufg_clock_fb    (.I(clock_fbout     ), .O(clock_fbin));

    BUFG  ubufg_clock_1x     (.I(clock_1x_pll    ), .O(clock          ));
    BUFG  ubufg_clock_2x     (.I(clock_2x_pll    ), .O(clock_2x       ));
    BUFG  ubufg_clock_1x_base  (.I(clock_1x_base_pll ), .O(clock_1x_base    ));
    //BUFG  ubufg_clock_1x_270 (.I(clock_1x_270_pll), .O(clock_1x_270   ));
    BUFG  ubufg_clock_2x_base  (.I(clock_2x_base_pll ), .O(clock_2x_base    ));
    //BUFG  ubufg_clock_2x_270 (.I(clock_2x_270_pll), .O(clock_2x_270   ));

// Receive multiplexer enable, 0=en, pullup onboard
    assign nmx_oe = 0;

// Receive multiplexer clocks 80MHz ddr obuf fast 24ma
`ifdef ALCT288
    clock_mirror uclk40_0 (.clock(clock_1x_base),.clock_180(~clock_1x_base), .mirror(clk40sh[0]));
    clock_mirror uclk80_0 (.clock(clock_2x_base),.clock_180(~clock_2x_base), .mirror(clk80[0]));
`elsif ALCT384
    clock_mirror uclk40_0 (.clock(clock_1x_base),.clock_180(~clock_1x_base), .mirror(clk40sh[0]));
    clock_mirror uclk80_0 (.clock(clock_2x_base),.clock_180(~clock_2x_base), .mirror(clk80[0]));
`elsif ALCT672
    clock_mirror uclk40_0 (.clock(clock_1x_base), .clock_180(~clock_1x_base), .mirror(clk40sh[0]));
    clock_mirror uclk40_1 (.clock(clock_1x_base), .clock_180(~clock_1x_base), .mirror(clk40sh[1]));
    clock_mirror uclk80_0 (.clock(clock_2x_base), .clock_180(~clock_2x_base), .mirror(clk80[0]  ));
    clock_mirror uclk80_1 (.clock(clock_2x_base), .clock_180(~clock_2x_base), .mirror(clk80[1]  ));
`endif

// PLL generates clocks 1x=40MHz, 2x=80MHz and phase offsets for LCT multiplexers
    PLL_BASE #
    (
    .BANDWIDTH              ("OPTIMIZED"),          // "HIGH", "LOW" or "OPTIMIZED"
    .CLKFBOUT_MULT          (12),                   // Multiply value for all CLKOUT clock outputs (1-64)
    .CLKFBOUT_PHASE         (0.0),                  // Phase offset in degrees of the clock feedback output (0.0-360.0).
    .CLKIN_PERIOD           (25.000),               // Input clock period in ns to ps resolution (i.e. 33.333 is 30)

    .CLK_FEEDBACK           ("CLKFBOUT"),           // Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
    .COMPENSATION           ("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL"
    .DIVCLK_DIVIDE          (1),                    // Division value for all output clocks (1-52)
    .REF_JITTER             (0.01),                 // Reference Clock Jitter in UI (0.000-0.999).
    .RESET_ON_LOSS_OF_LOCK  ("FALSE"),              // Must be set to FALSE

    .CLKOUT0_DIVIDE         (12),                   // 40 MHz       Divide amount for CLKOUT# clock output (1-128)
    .CLKOUT1_DIVIDE         (12),                   // 40 MHz
    .CLKOUT2_DIVIDE         (12),                   // 40 MHz
    .CLKOUT3_DIVIDE         (6),                    // 80 MHz
    .CLKOUT4_DIVIDE         (6),                    // 80 MHz
    .CLKOUT5_DIVIDE         (6),                    // 80 MHz

    .CLKOUT0_DUTY_CYCLE     (0.5),                  //Duty cycle for CLKOUT# clock output (0.01-0.99)
    .CLKOUT1_DUTY_CYCLE     (0.5), // baseboard 40MHz
    .CLKOUT2_DUTY_CYCLE     (0.5),
    .CLKOUT3_DUTY_CYCLE     (0.5),
    .CLKOUT4_DUTY_CYCLE     (0.3), // baseboard 80MHz
    .CLKOUT5_DUTY_CYCLE     (0.5),

    .CLKOUT0_PHASE          (  0.0),                // Output phase relationship for CLKOUT# clock output (-360.0-360.0)

    `ifdef ALCT288
    .CLKOUT1_PHASE          ( 90.0),
    `elsif ALCT384
    .CLKOUT1_PHASE          (135.0),
    `elsif ALCT672
    .CLKOUT1_PHASE          (45.0),
    `else
    .CLKOUT1_PHASE          (99999),
    `endif

    .CLKOUT2_PHASE          (270.0),
    .CLKOUT3_PHASE          (  0.0),

    `ifdef ALCT288
    .CLKOUT4_PHASE          (135.0),
    `elsif ALCT384
    .CLKOUT4_PHASE          (135.0),
    `elsif ALCT672
    .CLKOUT4_PHASE          (0.0),
    `else
    `endif

    .CLKOUT5_PHASE          (270.0)

    ) upll_base (

    .CLKIN                  (clock_mez_ibufg), // 1-bit input:  Clock input
    .CLKFBIN                (clock_fbin),      // 1-bit input:  Feedback clock input
    .CLKFBOUT               (clock_fbout),     // 1-bit output: PLL_BASE feedback output
    .RST                    (1'b0),            // 1-bit input:  Reset input
    .LOCKED                 (clock_lock),      // 1-bit output: PLL_BASE lock status output

    .CLKOUT0                (clock_1x_pll    ),   // 40 MHz
    .CLKOUT1                (clock_1x_base_pll ), // 40 MHz for base board mux select
    .CLKOUT2                (),                   // 40 MHz
    .CLKOUT3                (clock_2x_pll    ),   // 80 MHz
    .CLKOUT4                (clock_2x_base_pll ), // 80 MHz for base board mux select
    .CLKOUT5                ()                    // 80 MHz 270 degrees for clock mirrors
    );

`endif

//------------------------------------------------------------------------------------------------------------------
// Digital Serial numbers
//------------------------------------------------------------------------------------------------------------------
// Power-up defaults
    reg  [9:0] dsn_wr_reg;
    reg  [9:0] dsn_wr_sr=0;

    wire [9:0] dsn_rd_reg;
    reg  [9:0] dsn_rd_sr=0;

    initial begin
    dsn_wr_reg[0]           = 1'b0;     // ALCT Digital Serial SM Start
    dsn_wr_reg[1]           = 1'b0;     // ALCT Digital Serial Write Pulse
    dsn_wr_reg[2]           = 1'b0;     // ALCT Digital Serial Init Pulse
    dsn_wr_reg[4:3]         = 0;
    dsn_wr_reg[5]           = 1'b0;     // MEZ  Digital Serial SM Start
    dsn_wr_reg[6]           = 1'b0;     // MEZ  Digital Serial Write Pulse
    dsn_wr_reg[7]           = 1'b0;     // MEZ  Digital Serial Init Pulse
    dsn_wr_reg[9:8]         = 0;
    end

// Map dsn signals to JTAG registers
    wire alct_sn_busy;
    wire alct_sn_data;

    wire mez_sn_busy;
    wire mez_sn_data;

    wire alct_sn_start      =   dsn_wr_reg[0];
    wire alct_sn_write      =   dsn_wr_reg[1];
    wire alct_sn_init       =   dsn_wr_reg[2];

    wire mez_sn_start       =   dsn_wr_reg[5];
    wire mez_sn_write       =   dsn_wr_reg[6];
    wire mez_sn_init        =   dsn_wr_reg[7];

    assign dsn_rd_reg[2:0]  =   dsn_wr_reg[2:0];
    assign dsn_rd_reg[3]    =   alct_sn_busy;
    assign dsn_rd_reg[4]    =   alct_sn_data;

    assign dsn_rd_reg[7:5]  =   dsn_wr_reg[7:5];
    assign dsn_rd_reg[8]    =   mez_sn_busy;
    assign dsn_rd_reg[9]    =   mez_sn_data;

// Base board DSN
    dsn_alct udsn_alct (
    .clock          (clock),            // In   Clock
    .global_reset   (!clock_lock),      // In   Global reset
    .start          (alct_sn_start),    // In   Begin counting
    .dsn_io         (alct_sn),          // Bi   DSN chip I/O pin
    .wr_data        (alct_sn_write),    // In   DSN data bit to output
    .wr_init        (alct_sn_init),     // In   DSN init mode
    .busy           (alct_sn_busy),     // Out  DSN chip is busy
    .rd_data        (alct_sn_data));    // Out  DSN data read from chip

// Mezzanine board DSN
    dsn_alct udsn_mez (
    .clock          (clock),            // In   Clock
    .global_reset   (!clock_lock),      // In   Global reset
    .start          (mez_sn_start),     // In   Begin counting
    .dsn_io         (mez_sn),           // Bi   DSN chip I/O pin
    .wr_data        (mez_sn_write),     // In   DSN data bit to output
    .wr_init        (mez_sn_init),      // In   DSN init mode
    .busy           (mez_sn_busy),      // Out  DSN chip is busy
    .rd_data        (mez_sn_data));     // Out  DSN data read from chip

//------------------------------------------------------------------------------------------------------------------
// Spartan-6 ADC
//------------------------------------------------------------------------------------------------------------------
`ifdef SPARTAN6
    reg  [4:0] adc_wr_reg;
    reg  [4:0] adc_wr_sr=0;

    wire [4:0] adc_rd_reg;
    reg  [4:0] adc_rd_sr=0;

    initial begin
    adc_wr_reg[0] = 0;                      // Serial clock
    adc_wr_reg[1] = 0;                      // Serial data to ADC
    adc_wr_reg[2] = 1;                      // Chip select active low
    adc_wr_reg[3] = 0;                      // Unused
    adc_wr_reg[4] = 0;                      // Unused
    end

    assign adc_sck = adc_wr_reg[0];         // Serial clock
    assign adc_sdi = adc_wr_reg[1];         // Serial data to ADC
    assign adc_ncs = adc_wr_reg[2];         // Chip select active low

    assign adc_rd_reg[0] = adc_wr_reg[0];   // Serial clock
    assign adc_rd_reg[1] = adc_wr_reg[1];   // Serial data to ADC
    assign adc_rd_reg[2] = adc_wr_reg[2];   // Chip select active low
    assign adc_rd_reg[3] = adc_sdo;         // Serial data from ADC
    assign adc_rd_reg[4] = adc_eoc;         // End of conversion

`elsif VIRTEXE
    reg  [4:0] adc_wr_reg=0;
    reg  [4:0] adc_wr_sr=0;

    wire [4:0] adc_rd_reg=0;
    reg  [4:0] adc_rd_sr=0;
`endif

//------------------------------------------------------------------------------------------------------------------
// Spartan-6 SEU detection
//------------------------------------------------------------------------------------------------------------------
`ifdef SPARTAN6

    POST_CRC_INTERNAL upost_crc_internal (.CRCERROR(crc_error)); // 1-bit output: Post-configuration CRC error output

`elsif VIRTEXE
    wire crc_error = 0;
`endif

//------------------------------------------------------------------------------------------------------------------
// Sync JTAG inputs to main clock to bypass clock routing error on tck_ctrl IOB
//------------------------------------------------------------------------------------------------------------------
    reg tck = 0;
    reg tms = 0;
    reg tdi = 0;
    reg tdo = 0;

    wire   ntrst    = clock_lock;
    assign tdo_ctrl = tdo;

    always @(posedge clock_2x) begin
    tck <= tck_ctrl;
    tms <= tms_ctrl;
    tdi <= tdi_ctrl;
    end

//------------------------------------------------------------------------------------------------------------------
// JTAG Tap Controller
//------------------------------------------------------------------------------------------------------------------
// Test Access Port state machine declarations
    parameter MXSTATE       = 4;    // Number tap bits
    reg      [MXSTATE-1:0]  tap;

    parameter test_logic_reset    =   4'h0;
    parameter run_test_idle       =   4'h1;
    parameter select_dr_scan      =   4'h2;
    parameter capture_dr          =   4'h3;
    parameter shift_dr            =   4'h4;
    parameter exit1_dr            =   4'h5;
    parameter pause_dr            =   4'h6;
    parameter exit2_dr            =   4'h7;
    parameter update_dr           =   4'h8;
    parameter select_ir_scan      =   4'h9;
    parameter capture_ir          =   4'hA;
    parameter shift_ir            =   4'hB;
    parameter exit1_ir            =   4'hC;
    parameter pause_ir            =   4'hD;
    parameter exit2_ir            =   4'hE;
    parameter update_ir           =   4'hF;

    parameter L                   =   0;
    parameter H                   =   1;

    parameter Ox0                 =   5'h00;      // Bypass
    parameter Ox01read            =   5'h01;      // Read  fpga type
    parameter Ox02read            =   5'h02;      // Read  monthday
    parameter Ox03read            =   5'h03;      // Read  year
    parameter Ox04read            =   5'h04;      // Read  Todd
    parameter Ox05read            =   5'h05;      // Read  Teven
    parameter Ox06read            =   5'h06;      // Read  dsn
    parameter Ox07write           =   5'h07;      // Write dsn
    parameter Ox08read            =   5'h08;      // Read  ADC
    parameter Ox09write           =   5'h09;      // Write ADC
    parameter Ox0Aread            =   5'h0A;      // Read  adb_hit
    parameter Ox0Bread            =   5'h0B;      // Read  crc_error
    parameter Ox15read            =   5'h15;      // Read  adb_adr
    parameter Ox16write           =   5'h16;      // Write adb_adr
    parameter Ox17read            =   5'h17;      // Read  scsi_data
    parameter Ox18write           =   5'h18;      // Write scsi data
    parameter Ox19read            =   5'h19;      // Read  adb looped-back data
    parameter Ox1Aread            =   5'h1A;      // Read  delay asics
    parameter Ox1Bwrite           =   5'h1B;      // Write delay asics
    parameter Ox1Cread            =   5'h1C;      // Read  delay asics select
    parameter Ox1Dwrite           =   5'h1D;      // Write delay asics select

// JTAG registers
    reg [4:0]   ir                = 0;            // Instruction register
    reg [4:0]   sr                = 0;            // IR shift register
    reg [4:0]   tdo_adr           = 0;            // Pointer to TDO source

// Data registers
    wire [15:0] fpga_reg          = `FPGA;        // 0x01 Mezzanine FPGA type                     16 bits
    reg  [15:0] fpga_sr           = 0;

    wire [15:0] monthday_reg      = `MONTHDAY;    // 0x02 Firmware date                           16 bits
    reg  [15:0] monthday_sr       = 0;

    wire [15:0] year_reg          = `YEAR;        // 0x03 Firmware date                           16 bits
    reg  [15:0] year_sr           = 0;

    wire [15:0] todd_reg          = 16'h5555;     // 0x04 Read odd  test pattern                  16 bits
    reg  [15:0] todd_sr           = 0;

    wire [15:0] teven_reg         = 16'hAAAA;     // 0x05 Read even test pattern                  16 bits
    reg  [15:0] teven_sr          = 0;

    reg  [MXADBS-1:0] adb_hit_reg = 0;            // 0x0A Read ADB hit list                       24 bits
    reg  [MXADBS-1:0] adb_hit_sr  = 0;

    wire [ 0:0] crc_err_reg       = crc_error;    // 0x0B Read SEU induced crc error bit           1 bit
    reg  [ 0:0] crc_err_sr        = 0;

    reg  [ 8:0] adb_adr_sr        = 0;            // 0x15 Read  single cable channel number        9 bits
    reg  [ 8:0] adb_adr_reg       = 0;            // 0x16 Write single cable channel number        9 bits

    reg  [15:0] scsi_data_sr      = 0;            // 0x17 Read  test pattern to send to SCSI      16 bits
    reg  [15:0] scsi_data_reg     = 0;            // 0x18 Write test pattern to send to SCSI      16 bits

    reg  [15:0] lct_rx_sr         = 0;            // 0x19 Read  test pattern from ADB
    reg  [15:0] lct_rx_map        = 0;

    reg  [2:0] dly_sel_sr         = 0;            // 0x1C Read  delay chip select register (0-5)
    reg  [2:0] dly_sel_reg        = 0;            // 0x1D Write delay chip select register (0-5)

// TAP State Machine
    always @(posedge tck or negedge ntrst) begin
    if (!ntrst)       tap = test_logic_reset;
    else begin

      dly_clk_en <= 0;
      din_dly    <= 0;

      case (tap)

        test_logic_reset:
          if (tms == L) tap = run_test_idle;

        run_test_idle:
          if (tms == H) tap = select_dr_scan;

        select_dr_scan:
          if (tms == H) tap = select_ir_scan;
          else          tap = capture_dr;

        capture_dr:
          begin
            if (tms == H) tap = exit1_dr;
            else          tap = shift_dr;

            case (ir)
              Ox01read:       begin tdo_adr = 1;  fpga_sr     <= fpga_reg;        end // Read  FPGA type
              Ox02read:       begin tdo_adr = 2;  monthday_sr <= monthday_reg;    end // Read  monthday
              Ox03read:       begin tdo_adr = 3;  year_sr     <= year_reg;        end // Read  year
              Ox04read:       begin tdo_adr = 4;  todd_sr     <= todd_reg;        end // Read  Todd
              Ox05read:       begin tdo_adr = 5;  teven_sr    <= teven_reg;       end // Read  Teven

              Ox06read:       begin tdo_adr = 6;  dsn_rd_sr   <= dsn_rd_reg;      end // Read  dsn
              Ox07write:      begin tdo_adr = 7;  dsn_wr_sr   <= dsn_wr_reg;      end // Write dsn

              Ox08read:       begin tdo_adr = 8;  adc_rd_sr   <= adc_rd_reg;      end // Read  ADC
              Ox09write:      begin tdo_adr = 9;  adc_wr_sr   <= adc_wr_reg;      end // Write ADC

              Ox0Aread:       begin tdo_adr =10;  adb_hit_sr  <= adb_hit_reg;     end // Read  adb_hit

              Ox0Bread:       begin tdo_adr =11;  crc_err_sr  <= crc_err_reg;     end // Read  crc_error

              Ox15read:       begin tdo_adr =12;  adb_adr_sr  <= adb_adr_reg;     end // Read  adb_adr
              Ox16write:      begin tdo_adr =12;  end                                 // Write adb_adr

              Ox17read:       begin tdo_adr =13;  scsi_data_sr<= scsi_data_reg;   end // Read  scsi tx data
              Ox18write:      begin tdo_adr =13;  end                                 // Write scsi tx data

              Ox19read:       begin tdo_adr =14;  lct_rx_sr   <= lct_rx_map;      end // Read  adb  rx data

              Ox1Aread:       begin tdo_adr =15;  end
              Ox1Bwrite:      begin tdo_adr =15;  end

              Ox1Cread:       begin tdo_adr =16;  dly_sel_sr <= dly_sel_reg;      end
              Ox1Dwrite:      begin tdo_adr =16;  end

              default:        begin tdo_adr = 0;  end
            endcase
          end

        shift_dr:
          begin
            if (tms == H) tap = exit1_dr;

            case (ir)
              Ox01read:                fpga_sr      <= {tdi,fpga_sr[15:1]};
              Ox02read:                monthday_sr  <= {tdi,monthday_sr[15:1]};
              Ox03read:                year_sr      <= {tdi,year_sr[15:1]};
              Ox04read:                todd_sr      <= {tdi,todd_sr[15:1]};
              Ox05read:                teven_sr     <= {tdi,teven_sr[15:1]};

              Ox06read:                dsn_rd_sr    <= {tdi,dsn_rd_sr[9:1]};
              Ox07write:               dsn_wr_sr    <= {tdi,dsn_wr_sr[9:1]};

              Ox08read:                adc_rd_sr    <= {tdi,adc_rd_sr[4:1]};
              Ox09write:               adc_wr_sr    <= {tdi,adc_wr_sr[4:1]};

              Ox0Aread:                adb_hit_sr   <= {tdi,adb_hit_sr[MXADBS-1:1]};

              Ox0Bread:                crc_err_sr   <= {tdi};

              Ox15read, Ox16write:     adb_adr_sr   <= {tdi,adb_adr_sr[8:1]};

              Ox17read, Ox18write:     scsi_data_sr <= {tdi,scsi_data_sr[15:1]};

              Ox19read:                lct_rx_sr    <= {tdi,lct_rx_sr[15:1]};

              Ox1Aread, Ox1Bwrite:
                begin
                                       din_dly    <= tdi; dly_clk_en <= 1'b1;
                end

              Ox1Cread, Ox1Dwrite:     dly_sel_sr <= {tdi,dly_sel_sr[2:1]};

            endcase
          end

        exit1_dr:
          if (tms == H) tap = update_dr;
          else          tap = pause_dr;

        pause_dr:
          if (tms == H) tap = exit2_dr;

        exit2_dr:
          if (tms == H) tap = update_dr;
          else          tap = shift_dr;

        update_dr:
          begin
            if (tms == H) tap = select_dr_scan;
            else          tap = run_test_idle;

            case (ir)
              Ox07write:  dsn_wr_reg    <= dsn_wr_sr;
              Ox09write:  adc_wr_reg    <= adc_wr_sr;
              Ox16write:  adb_adr_reg   <= adb_adr_sr;
              Ox18write:  scsi_data_reg <= scsi_data_sr;
              Ox1Dwrite:  dly_sel_reg   <= dly_sel_sr;
            endcase
          end

        select_ir_scan:
          if (tms == H) tap = test_logic_reset;
          else          tap = capture_ir;

        capture_ir:
          begin
            if (tms == H) tap = exit1_ir;
            else          tap = shift_ir;

            sr     <= ir;
            tdo_adr = 0;
          end

        shift_ir:
          begin
            if (tms == H) tap = exit1_ir;

            sr <= {tdi, sr[4:1]};
          end

        exit1_ir:
          if (tms == H) tap = update_ir;
          else          tap = pause_ir;

        pause_ir:
          if (tms == H) tap = exit2_ir;

        exit2_ir:
          if (tms == H) tap = update_ir;
          else          tap = shift_ir;

        update_ir:
          begin
            if (tms == H) tap = select_dr_scan;
            else          tap = run_test_idle;

            ir = sr;
          end

        default:          tap = test_logic_reset;
      endcase
    end
    end

// TDO multiplexer
    always @(negedge tck) begin
      case (tdo_adr)
      5'd0:       tdo <= sr[0];           // Passthrough
      5'd1:       tdo <= fpga_sr[0];      // FPGA type
      5'd2:       tdo <= monthday_sr[0];  // Firmware month and day
      5'd3:       tdo <= year_sr[0];      // Firmware year
      5'd4:       tdo <= todd_sr[0];      // Odd  test pattern
      5'd5:       tdo <= teven_sr[0];     // Even test pattern


      5'd6:       tdo <= dsn_rd_sr[0];    // Read  dsn
      5'd7:       tdo <= dsn_wr_sr[0];    // Write dsn
      5'd8:       tdo <= adc_rd_sr[0];    // Read  ADC
      5'd9:       tdo <= adc_wr_sr[0];    // Write ADC

      5'd10:      tdo <= adb_hit_sr[0];   // Read  ADB hit list
      5'd11:      tdo <= crc_err_sr[0];   // Read  CRC error bit

      5'd12:      tdo <= adb_adr_sr[0];   // ADB  channel
      5'd13:      tdo <= scsi_data_sr[0]; // SCSI data
      5'd14:      tdo <= lct_rx_sr[0];    // ADB  cable data
      5'd15:      tdo <= dout_dly_mux[0]; // Multiplexed Dout from delay chips
      5'd16:      tdo <= dly_sel_sr[0];   // Read delay select
      default:    tdo <= sr[0];           // Passthrough
      endcase
    end

//------------------------------------------------------------------------------------------------------------------
// Transmit data to SCSI connector
//------------------------------------------------------------------------------------------------------------------
// Pulse SCSI output data at 625KHz = 40MHz/64
    reg [15:0] scsi_tx = 0;
    reg [5:0]  div_ctr = 0;

    always @(posedge clock) begin
    div_ctr <= div_ctr + 1'b1;
    end

    always @(posedge clock) begin
    if (div_ctr[5]) scsi_tx <= scsi_data_reg;
    else            scsi_tx <= 0;
    end

    wire latch_adb = (div_ctr==37);

// Map tx data to SCSI output signals as received at the J6 connector: scsi_tx bit 0 goes to J6.1
    wire [28:1] alct_tx;

    assign alct_tx[18] = scsi_tx[ 0];   // m_daq_data[0]    alct_tx[18] = J6.1  Outs0   LCT0_7
    assign alct_tx[16] = scsi_tx[ 1];   // m_bxn[1]         alct_tx[16] = J6.3  Outs1   LCT0_6
    assign alct_tx[14] = scsi_tx[ 2];   // m_key[6]         alct_tx[14] = J6.5  Outs2   LCT0_5
    assign alct_tx[12] = scsi_tx[ 3];   // m_key[4]         alct_tx[12] = J6.7  Outs3   LCT0_4
    assign alct_tx[10] = scsi_tx[ 4];   // m_key[2]         alct_tx[10] = J6.9  Out_0   LCT0_15
    assign alct_tx[ 8] = scsi_tx[ 5];   // m_key[0]         alct_tx[ 8] = J6.11 Out_1   LCT0_14
    assign alct_tx[ 6] = scsi_tx[ 6];   // m_quality[0]     alct_tx[ 6] = J6.13 Out_2   LCT0_13
    assign alct_tx[ 4] = scsi_tx[ 7];   // m_valid          alct_tx[ 4] = J6.15 Out_3   LCT0_12
    assign alct_tx[ 5] = scsi_tx[ 8];   // m_amu            alct_tx[ 5] = J6.17 Outs4   LCT0_3
    assign alct_tx[ 7] = scsi_tx[ 9];   // m_quality[1]     alct_tx[ 7] = J6.19 Outs5   LCT0_2
    assign alct_tx[ 9] = scsi_tx[10];   // m_key[1]         alct_tx[ 9] = J6.21 Outs6   LCT0_1
    assign alct_tx[11] = scsi_tx[11];   // m_key[3]         alct_tx[11] = J6.23 Outs7   LCT0_0
    assign alct_tx[13] = scsi_tx[12];   // m_key[5]         alct_tx[13] = J6.25 Out_4   LCT0_11
    assign alct_tx[15] = scsi_tx[13];   // m_bxn[0]         alct_tx[15] = J6.27 Out_5   LCT0_10
    assign alct_tx[17] = scsi_tx[14];   // m_bxn[2]         alct_tx[17] = J6.29 Out_6   LCT0_9
    assign alct_tx[19] = scsi_tx[15];   // m_daq_data[1]    alct_tx[19] = J6.31 Out_7   LCT0_8

    assign alct_tx[3:1]   = 0;
    assign alct_tx[28:20] = 0;

// Connect transmit signals to ALCT schematic symbols, alct_tx[0] is tdo and not multiplxed
//                                              first               second          Cable   Pins
//                                              -----------         ----------      -----   ------
    assign m_reserved_out[0]    = alct_tx[1];   // reserved_out0    reserved_out2   2       23  24
    assign m_reserved_out[1]    = alct_tx[2];   // reserved_out1    reserved_out3   2       27  28
    assign m_active_feb         = alct_tx[3];   // active_feb_flag  cfg_done        2       25  26

    assign m_valid              = alct_tx[4];   // first_valid      second_valid    1       1   2
    assign m_amu                = alct_tx[5];   // first_amu        second_amu      1       49  50
    assign m_quality[0]         = alct_tx[6];   // first_quality0   second_quality0 1       3   4
    assign m_quality[1]         = alct_tx[7];   // first_quality1   second_quality1 1       47  48

    assign m_key[0]             = alct_tx[8];   // first_key0       second_key0     1       5   6
    assign m_key[1]             = alct_tx[9];   // first_key1       second_key1     1       45  46
    assign m_key[2]             = alct_tx[10];  // first_key2       second_key2     1       7   8
    assign m_key[3]             = alct_tx[11];  // first_key3       second_key3     1       43  44
    assign m_key[4]             = alct_tx[12];  // first_key4       second_key4     1       9   10
    assign m_key[5]             = alct_tx[13];  // first_key5       second_key5     1       41  42
    assign m_key[6]             = alct_tx[14];  // first_key6       second_key6     1       11  12

    assign m_bxn[0]             = alct_tx[15];  // bxn0             bxn3            1       39  40
    assign m_bxn[1]             = alct_tx[16];  // bxn1             bxn4            1       13  14
    assign m_bxn[2]             = alct_tx[17];  // bxn2             /wr_fifo        1       37  38

    assign m_daq_data[0]        = alct_tx[18];  // daq_data0        daq_data7       1       15  16
    assign m_daq_data[1]        = alct_tx[19];  // daq_data1        daq_data8       1       35  36
    assign m_daq_data[2]        = alct_tx[20];  // daq_data2        daq_data9       1       17  18
    assign m_daq_data[3]        = alct_tx[21];  // daq_data3        daq_data10      1       33  34
    assign m_daq_data[4]        = alct_tx[22];  // daq_data4        daq_data11      1       19  20
    assign m_daq_data[5]        = alct_tx[23];  // daq_data5        daq_data12      1       31  32
    assign m_daq_data[6]        = alct_tx[24];  // daq_data6        daq_data13      1       21  22

    assign m_lct_special        = alct_tx[25];  // lct_special      first_frame     1       29  30
    assign m_seq_status[0]      = alct_tx[26];  // seq_status0      seu_status0     1       23  24
    assign m_seq_status[1]      = alct_tx[27];  // seq_status1      seu_status1     1       27  28
    assign m_ddu_special        = alct_tx[28];  // ddu_special      last_frame      1       25  26

//------------------------------------------------------------------------------------------------------------------
// Latch ADB connector inputs at 80MHz and unpack 1 to 2
//------------------------------------------------------------------------------------------------------------------

  `ifdef ALCT672
    wire [47:0] lct0_rx_1st;
    wire [47:0] lct1_rx_1st;
    wire [47:0] lct2_rx_1st;
    wire [47:0] lct3_rx_1st;
    wire [47:0] lct4_rx_1st;
    wire [47:0] lct5_rx_1st;
    wire [47:0] lct6_rx_1st;
  `elsif ALCT384
    wire [47:0] lct0_rx_1st;
    wire [47:0] lct1_rx_1st;
    wire [47:0] lct2_rx_1st;
    wire [47:0] lct3_rx_1st;
  `elsif ALCT288
    wire [47:0] lct0_rx_1st;
    wire [47:0] lct1_rx_1st;
    wire [47:0] lct2_rx_1st;
  `endif

  `ifdef ALCT672
    wire [47:0] lct0_rx_2nd;
    wire [47:0] lct1_rx_2nd;
    wire [47:0] lct2_rx_2nd;
    wire [47:0] lct3_rx_2nd;
    wire [47:0] lct4_rx_2nd;
    wire [47:0] lct5_rx_2nd;
    wire [47:0] lct6_rx_2nd;
  `elsif ALCT384
    wire [47:0] lct0_rx_2nd;
    wire [47:0] lct1_rx_2nd;
    wire [47:0] lct2_rx_2nd;
    wire [47:0] lct3_rx_2nd;
  `elsif ALCT288
    wire [47:0] lct0_rx_2nd;
    wire [47:0] lct1_rx_2nd;
    wire [47:0] lct2_rx_2nd;
  `endif


  `ifdef ALCT672
    x_demux_alct #(48) ulct0 (.din(lct0_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct0_rx_1st),.dout2nd(lct0_rx_2nd));
    x_demux_alct #(48) ulct1 (.din(lct1_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct1_rx_1st),.dout2nd(lct1_rx_2nd));
    x_demux_alct #(48) ulct2 (.din(lct2_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct2_rx_1st),.dout2nd(lct2_rx_2nd));
    x_demux_alct #(48) ulct3 (.din(lct3_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct3_rx_1st),.dout2nd(lct3_rx_2nd));
    x_demux_alct #(48) ulct4 (.din(lct4_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct4_rx_1st),.dout2nd(lct4_rx_2nd));
    x_demux_alct #(48) ulct5 (.din(lct5_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct5_rx_1st),.dout2nd(lct5_rx_2nd));
    x_demux_alct #(48) ulct6 (.din(lct6_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct6_rx_1st),.dout2nd(lct6_rx_2nd));
  `elsif ALCT384
    x_demux_alct #(48) ulct0 (.din(lct0_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct0_rx_1st),.dout2nd(lct0_rx_2nd));
    x_demux_alct #(48) ulct1 (.din(lct1_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct1_rx_1st),.dout2nd(lct1_rx_2nd));
    x_demux_alct #(48) ulct2 (.din(lct2_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct2_rx_1st),.dout2nd(lct2_rx_2nd));
    x_demux_alct #(48) ulct3 (.din(lct3_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct3_rx_1st),.dout2nd(lct3_rx_2nd));
  `elsif ALCT288
    x_demux_alct #(48) ulct0 (.din(lct0_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct0_rx_1st),.dout2nd(lct0_rx_2nd));
    x_demux_alct #(48) ulct1 (.din(lct1_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct1_rx_1st),.dout2nd(lct1_rx_2nd));
    x_demux_alct #(48) ulct2 (.din(lct2_),.clock_1x(clock),.clock_2x(clock_2x),.dout1st(lct2_rx_1st),.dout2nd(lct2_rx_2nd));
  `endif

//------------------------------------------------------------------------------------------------------------------
// Map 672 LCT bits to up to 42 ADB 16-bit connectors: even channels are 1st in time, odd channels 2nd in time
//------------------------------------------------------------------------------------------------------------------

    wire [15:0] adb [MXADBS-1:0];

  `ifdef ALCT672
    assign adb[ 0] = lct0_rx_1st[15:0];     assign adb[ 1] = lct0_rx_2nd[15:0];
    assign adb[ 2] = lct0_rx_1st[31:16];    assign adb[ 3] = lct0_rx_2nd[31:16];
    assign adb[ 4] = lct0_rx_1st[47:32];    assign adb[ 5] = lct0_rx_2nd[47:32];

    assign adb[ 6] = lct1_rx_1st[15:0];     assign adb[ 7] = lct1_rx_2nd[15:0];
    assign adb[ 8] = lct1_rx_1st[31:16];    assign adb[ 9] = lct1_rx_2nd[31:16];
    assign adb[10] = lct1_rx_1st[47:32];    assign adb[11] = lct1_rx_2nd[47:32];

    assign adb[12] = lct2_rx_1st[15:0];     assign adb[13] = lct2_rx_2nd[15:0];
    assign adb[14] = lct2_rx_1st[31:16];    assign adb[15] = lct2_rx_2nd[31:16];
    assign adb[16] = lct2_rx_1st[47:32];    assign adb[17] = lct2_rx_2nd[47:32];

    assign adb[18] = lct3_rx_1st[15:0];     assign adb[19] = lct3_rx_2nd[15:0];
    assign adb[20] = lct3_rx_1st[31:16];    assign adb[21] = lct3_rx_2nd[31:16];
    assign adb[22] = lct3_rx_1st[47:32];    assign adb[23] = lct3_rx_2nd[47:32];

    assign adb[24] = lct4_rx_1st[15:0];     assign adb[25] = lct4_rx_2nd[15:0];
    assign adb[26] = lct4_rx_1st[31:16];    assign adb[27] = lct4_rx_2nd[31:16];
    assign adb[28] = lct4_rx_1st[47:32];    assign adb[29] = lct4_rx_2nd[47:32];

    assign adb[30] = lct5_rx_1st[15:0];     assign adb[31] = lct5_rx_2nd[15:0];
    assign adb[32] = lct5_rx_1st[31:16];    assign adb[33] = lct5_rx_2nd[31:16];
    assign adb[34] = lct5_rx_1st[47:32];    assign adb[35] = lct5_rx_2nd[47:32];

    assign adb[36] = lct6_rx_1st[15:0];     assign adb[37] = lct6_rx_2nd[15:0];
    assign adb[38] = lct6_rx_1st[31:16];    assign adb[39] = lct6_rx_2nd[31:16];
    assign adb[40] = lct6_rx_1st[47:32];    assign adb[41] = lct6_rx_2nd[47:32];
  `elsif ALCT384
    assign adb[ 0] = lct0_rx_1st[15:0];     assign adb[ 1] = lct0_rx_2nd[15:0];
    assign adb[ 2] = lct0_rx_1st[31:16];    assign adb[ 3] = lct0_rx_2nd[31:16];
    assign adb[ 4] = lct0_rx_1st[47:32];    assign adb[ 5] = lct0_rx_2nd[47:32];

    assign adb[ 6] = lct1_rx_1st[15:0];     assign adb[ 7] = lct1_rx_2nd[15:0];
    assign adb[ 8] = lct1_rx_1st[31:16];    assign adb[ 9] = lct1_rx_2nd[31:16];
    assign adb[10] = lct1_rx_1st[47:32];    assign adb[11] = lct1_rx_2nd[47:32];

    assign adb[12] = lct2_rx_1st[15:0];     assign adb[13] = lct2_rx_2nd[15:0];
    assign adb[14] = lct2_rx_1st[31:16];    assign adb[15] = lct2_rx_2nd[31:16];
    assign adb[16] = lct2_rx_1st[47:32];    assign adb[17] = lct2_rx_2nd[47:32];

    assign adb[18] = lct3_rx_1st[15:0];     assign adb[19] = lct3_rx_2nd[15:0];
    assign adb[20] = lct3_rx_1st[31:16];    assign adb[21] = lct3_rx_2nd[31:16];
    assign adb[22] = lct3_rx_1st[47:32];    assign adb[23] = lct3_rx_2nd[47:32];
  `elsif ALCT288
    assign adb[ 0] = lct0_rx_1st[15:0];     assign adb[ 1] = lct0_rx_2nd[15:0];
    assign adb[ 2] = lct0_rx_1st[31:16];    assign adb[ 3] = lct0_rx_2nd[31:16];
    assign adb[ 4] = lct0_rx_1st[47:32];    assign adb[ 5] = lct0_rx_2nd[47:32];

    assign adb[ 6] = lct1_rx_1st[15:0];     assign adb[ 7] = lct1_rx_2nd[15:0];
    assign adb[ 8] = lct1_rx_1st[31:16];    assign adb[ 9] = lct1_rx_2nd[31:16];
    assign adb[10] = lct1_rx_1st[47:32];    assign adb[11] = lct1_rx_2nd[47:32];

    assign adb[12] = lct2_rx_1st[15:0];     assign adb[13] = lct2_rx_2nd[15:0];
    assign adb[14] = lct2_rx_1st[31:16];    assign adb[15] = lct2_rx_2nd[31:16];
    assign adb[16] = lct2_rx_1st[47:32];    assign adb[17] = lct2_rx_2nd[47:32];
  `endif

//------------------------------------------------------------------------------------------------------------------
// List ADBs having any hits, only one should be hit during single cable test
//------------------------------------------------------------------------------------------------------------------

    reg [MXADBS-1:0] adb_hit_list=0;

    genvar i;
    generate
    for (i=0; i<=MXADBS-1; i=i+1) begin: gen_hit
    always @(posedge clock) begin
    adb_hit_list[i] <= |adb[i][15:0];
    end
    end
    endgenerate

//------------------------------------------------------------------------------------------------------------------
// Select 1 of 42 ADB channels to output via JTAG
//------------------------------------------------------------------------------------------------------------------

    reg [15:0] adb_mux;
    reg  [5:0] adb_channel;
    wire [8:0] adb_adr_masked = adb_adr_reg & ~9'h040; // Software ORs ch with 0x40, so blank it here
    always @(posedge clock) begin
      if (adb_adr_reg >= MXADBS)
        adb_channel <= {6{1'b1}};
      else
        adb_channel <= adb_adr_masked[5:0];
    end

    always @(posedge clock) begin
      if (adb_adr_reg >= MXADBS)
         adb_mux <= 16'hDEAD;
      else
         adb_mux <= adb[adb_channel];
    end

 // Latch LCTx_[] from multiplexer
    reg [15:0] lct_rx = 0;

    always @(posedge clock) begin
    if (latch_adb) begin
      lct_rx[15:0] <= adb_mux[15:0];
      adb_hit_reg  <= adb_hit_list;
    end
    end

//------------------------------------------------------------------------------------------------------------------
// Remap multiplexer output order
//------------------------------------------------------------------------------------------------------------------
    always @(posedge clock) begin

// Even adb channel addresses   (J6, J8, etc)
    if (adb_channel[0]==0)  begin
    lct_rx_map[ 0] <= lct_rx[7];    // m_daq_data[0]    alct_tx[18] = J6.1  Outs0   LCT0_7
    lct_rx_map[ 1] <= lct_rx[6];    // m_bxn[1]         alct_tx[16] = J6.3  Outs1   LCT0_6
    lct_rx_map[ 2] <= lct_rx[5];    // m_key[6]         alct_tx[14] = J6.5  Outs2   LCT0_5
    lct_rx_map[ 3] <= lct_rx[4];    // m_key[4]         alct_tx[12] = J6.7  Outs3   LCT0_4

    lct_rx_map[ 4] <= lct_rx[15];   // m_key[2]         alct_tx[10] = J6.9  Out_0   LCT0_15
    lct_rx_map[ 5] <= lct_rx[14];   // m_key[0]         alct_tx[ 8] = J6.11 Out_1   LCT0_14
    lct_rx_map[ 6] <= lct_rx[13];   // m_quality[0]     alct_tx[ 6] = J6.13 Out_2   LCT0_13
    lct_rx_map[ 7] <= lct_rx[12];   // m_valid          alct_tx[ 4] = J6.15 Out_3   LCT0_12

    lct_rx_map[ 8] <= lct_rx[3];    // m_amu            alct_tx[ 5] = J6.17 Outs4   LCT0_3
    lct_rx_map[ 9] <= lct_rx[2];    // m_quality[1]     alct_tx[ 7] = J6.19 Outs5   LCT0_2
    lct_rx_map[10] <= lct_rx[1];    // m_key[1]         alct_tx[ 9] = J6.21 Outs6   LCT0_1
    lct_rx_map[11] <= lct_rx[0];    // m_key[3]         alct_tx[11] = J6.23 Outs7   LCT0_0

    lct_rx_map[12] <= lct_rx[11];   // m_key[5]         alct_tx[13] = J6.25 Out_4   LCT0_11
    lct_rx_map[13] <= lct_rx[10];   // m_bxn[0]         alct_tx[15] = J6.27 Out_5   LCT0_10
    lct_rx_map[14] <= lct_rx[9];    // m_bxn[2]         alct_tx[17] = J6.29 Out_6   LCT0_9
    lct_rx_map[15] <= lct_rx[8];    // m_daq_data[1]    alct_tx[19] = J6.31 Out_7   LCT0_8
    end

// Odd adb channel addresses    (J7, J9, etc)
    else begin
    lct_rx_map[11] <= lct_rx[7];    // m_daq_data[0]    alct_tx[18] = J6.1  Outs0   LCT0_7
    lct_rx_map[10] <= lct_rx[6];    // m_bxn[1]         alct_tx[16] = J6.3  Outs1   LCT0_6
    lct_rx_map[ 9] <= lct_rx[5];    // m_key[6]         alct_tx[14] = J6.5  Outs2   LCT0_5
    lct_rx_map[ 8] <= lct_rx[4];    // m_key[4]         alct_tx[12] = J6.7  Outs3   LCT0_4

    lct_rx_map[15] <= lct_rx[15];   // m_key[2]         alct_tx[10] = J6.9  Out_0   LCT0_15
    lct_rx_map[14] <= lct_rx[14];   // m_key[0]         alct_tx[ 8] = J6.11 Out_1   LCT0_14
    lct_rx_map[13] <= lct_rx[13];   // m_quality[0]     alct_tx[ 6] = J6.13 Out_2   LCT0_13
    lct_rx_map[12] <= lct_rx[12];   // m_valid          alct_tx[ 4] = J6.15 Out_3   LCT0_12

    lct_rx_map[ 3] <= lct_rx[3];    // m_amu            alct_tx[ 5] = J6.17 Outs4   LCT0_3
    lct_rx_map[ 2] <= lct_rx[2];    // m_quality[1]     alct_tx[ 7] = J6.19 Outs5   LCT0_2
    lct_rx_map[ 1] <= lct_rx[1];    // m_key[1]         alct_tx[ 9] = J6.21 Outs6   LCT0_1
    lct_rx_map[ 0] <= lct_rx[0];    // m_key[3]         alct_tx[11] = J6.23 Outs7   LCT0_0

    lct_rx_map[ 7] <= lct_rx[11];   // m_key[5]         alct_tx[13] = J6.25 Out_4   LCT0_11
    lct_rx_map[ 6] <= lct_rx[10];   // m_bxn[0]         alct_tx[15] = J6.27 Out_5   LCT0_10
    lct_rx_map[ 5] <= lct_rx[9];    // m_bxn[2]         alct_tx[17] = J6.29 Out_6   LCT0_9
    lct_rx_map[ 4] <= lct_rx[8];    // m_daq_data[1]    alct_tx[19] = J6.31 Out_7   LCT0_8
    end
    end

//------------------------------------------------------------------------------------------------------------------
// ALCT test point assignments
//------------------------------------------------------------------------------------------------------------------
// TP0
    wire sump;
    wire ram_sump;
    wire ram_rd_en;

    wire lct_rx_1st = |lct0_rx_1st;
    wire lct_rx_2nd = |lct0_rx_2nd;
    wire adb_mux_tp = |adb_mux;

    assign tp0_[ 0] = clock_lock;
    assign tp0_[ 1] = latch_adb;
    assign tp0_[ 2] = sump;
    assign tp0_[ 3] = lct_rx_1st;
    assign tp0_[ 4] = 0;
    assign tp0_[ 5] = lct_rx_2nd;
    assign tp0_[ 6] = 0;
    assign tp0_[ 7] = adb_mux_tp;
    assign tp0_[ 8] = 0;
    assign tp0_[ 9] = ram_rd_en;
    assign tp0_[10] = 0;
    assign tp0_[11] = crc_error;

    assign tp0_[29:12] = 0;

// Readout RAM when tp0_30 is pulled to 0 by a shunt to gnd, increment read address on tp0_31 to gnd
`ifdef VIRTEXE
    PULLUP upullup30 (.O(tp0_[30]));    // Spartan6 implements PULLUP in the UCF
    PULLUP upullup31 (.O(tp0_[31]));
`endif

    wire ram_rd_start = !tp0_[30];
    wire push_button  = !tp0_[31];

// TP1
    assign tp1_[ 0] = scsi_tx[ 0];      assign tp1_[ 1] = adb_mux[ 0];
    assign tp1_[ 2] = scsi_tx[ 1];      assign tp1_[ 3] = adb_mux[ 1];
    assign tp1_[ 4] = scsi_tx[ 2];      assign tp1_[ 5] = adb_mux[ 2];
    assign tp1_[ 6] = scsi_tx[ 3];      assign tp1_[ 7] = adb_mux[ 3];
    assign tp1_[ 8] = scsi_tx[ 4];      assign tp1_[ 9] = adb_mux[ 4];
    assign tp1_[10] = scsi_tx[ 5];      assign tp1_[11] = adb_mux[ 5];
    assign tp1_[12] = scsi_tx[ 6];      assign tp1_[13] = adb_mux[ 6];
    assign tp1_[14] = scsi_tx[ 7];      assign tp1_[15] = adb_mux[ 7];
    assign tp1_[16] = scsi_tx[ 8];      assign tp1_[17] = adb_mux[ 8];
    assign tp1_[18] = scsi_tx[ 9];      assign tp1_[19] = adb_mux[ 9];
    assign tp1_[20] = scsi_tx[10];      assign tp1_[21] = adb_mux[10];
    assign tp1_[22] = scsi_tx[11];      assign tp1_[23] = adb_mux[11];
    assign tp1_[24] = scsi_tx[12];      assign tp1_[25] = adb_mux[12];
    assign tp1_[26] = scsi_tx[13];      assign tp1_[27] = adb_mux[13];
    assign tp1_[28] = scsi_tx[14];      assign tp1_[29] = adb_mux[14];
    assign tp1_[30] = scsi_tx[15];      assign tp1_[31] = adb_mux[15];

//------------------------------------------------------------------------------------------------------------------
//  Cylon sequence generator for onboard LEDs, shows board is powered and FPGA loaded from PROM
//------------------------------------------------------------------------------------------------------------------
// Scale clock down below visual fusion
    parameter MXPRE = 19;
    reg [MXPRE-1:0] prescaler;

    always @(posedge clock) begin
    prescaler = prescaler + 1'b1;
    end

    wire next = (prescaler == 0);

// Init
    wire [3:0]  pdly = 0;
    wire        init;

    SRL16E uinit (.CLK(clock),.CE(!init),.D(1'b1),.A0(pdly[0]),.A1(pdly[1]),.A2(pdly[2]),.A3(pdly[3]),.Q(init));

// Pointer runs 0 to 22
    reg [4:0]   pointer=0;

    always @(posedge clock) begin
    if (next) begin
    if      (pointer==22-1) pointer <= 0;
    else if (init         ) pointer <= pointer + 1'b1;
    end
    end

// Display pattern selected by pointer
    reg [15:0]  display;

    always @(posedge clock) begin   // Infers block ram, so expand width from 12 to 16 to use all bram output ports
    case (pointer)
    5'd0:   display =   16'b0000000000000001;
    5'd1:   display =   16'b0000000000000010;
    5'd2:   display =   16'b0000000000000100;
    5'd3:   display =   16'b0000000000001000;
    5'd4:   display =   16'b0000000000010000;
    5'd5:   display =   16'b0000000000100000;
    5'd6:   display =   16'b0000000001000000;
    5'd7:   display =   16'b0000000010000000;
    5'd8:   display =   16'b0000000100000000;
    5'd9:   display =   16'b0000001000000000;
    5'd10:  display =   16'b0000010000000000;
    5'd11:  display =   16'b1111100000000000;
    5'd12:  display =   16'b0000010000000000;
    5'd13:  display =   16'b0000001000000000;
    5'd14:  display =   16'b0000000100000000;
    5'd15:  display =   16'b0000000010000000;
    5'd16:  display =   16'b0000000001000000;
    5'd17:  display =   16'b0000000000100000;
    5'd18:  display =   16'b0000000000010000;
    5'd19:  display =   16'b0000000000001000;
    5'd20:  display =   16'b0000000000000100;
    5'd21:  display =   16'b0000000000000010;
    5'd22:  display =   16'b0000000000000001;
    5'd23:  display =   16'b0000000000000001;
    5'd24:  display =   16'b0000000000000001;
    5'd25:  display =   16'b0000000000000001;
    5'd26:  display =   16'b0000000000000001;
    5'd27:  display =   16'b0000000000000001;
    5'd28:  display =   16'b0000000000000001;
    5'd29:  display =   16'b0000000000000001;
    5'd30:  display =   16'b0000000000000001;
    5'd31:  display =   16'b0000000000000001;
    default:display =   16'b0000000000000001;
    endcase
    end

    wire [11:0] cylon = display[11:0];

// TAP state display
    reg [3:0] state;

    always @* begin
    case (tap)
    test_logic_reset:   state = test_logic_reset;
    run_test_idle:      state = run_test_idle;
    select_dr_scan:     state = select_dr_scan;
    capture_dr:         state = capture_dr;
    shift_dr:           state = shift_dr;
    exit1_dr:           state = exit1_dr;
    pause_dr:           state = pause_dr;
    exit2_dr:           state = exit2_dr;
    update_dr:          state = update_dr;
    select_ir_scan:     state = select_ir_scan;
    capture_ir:         state = capture_ir;
    shift_ir:           state = shift_ir;
    exit1_ir:           state = exit1_ir;
    pause_ir:           state = pause_ir;
    exit2_ir:           state = exit2_ir;
    update_ir:          state = update_ir;
    default:            state = test_logic_reset;
    endcase
    end

//------------------------------------------------------------------------------------------------------------------
// Flash onboard LEDs
//------------------------------------------------------------------------------------------------------------------
// Assert Cylon mode for a few seconds after power up
    reg [27:0]  cylon_cnt  = 0;
    reg         cylon_mode = 1;

    wire cylon_cnt_en = (cylon_cnt[27] == 0);

    always @(posedge clock) begin
    if (cylon_cnt_en) cylon_cnt <= cylon_cnt+1'b1;
    end

    always @(posedge clock) begin
    cylon_mode <= cylon_cnt_en;
    end

// Engage Cylon mode at power up
    reg  [29:0] led;
    wire [29:0] txled;
    wire [29:0] ramled;

    always @* begin
    if (cylon_mode) begin
    led[4:0]= 5'h1F;
    led[9:6]= 4'hF;
    led[5]  = cylon[0];
    led[10] = cylon[1];     led[12]=cylon[1];
    led[11] = cylon[2];     led[13]=cylon[2];
    led[14] = cylon[3];
    led[15] = cylon[4];     led[17]=cylon[4];
    led[16] = cylon[5];     led[18]=cylon[5];
    led[19] = cylon[6];     led[20]=cylon[6];
    led[21] = cylon[7];     led[22]=cylon[7];
    led[23] = cylon[8];     led[25]=cylon[8];
    led[24] = cylon[9];
    led[26] = cylon[10];    led[27]=cylon[10];
    led[28] = cylon[11];    led[29]=cylon[11];
    end
    else if (ram_rd_start)  led[29:0] = ramled[29:0];
    else                    led[29:0] = txled[29:0];
    end

// RAM readout LED assigments
    reg  [9:0] ram_radr = 0;
    wire [3:0] ram_dob;

    assign ramled[4:0]= 0;              // No LED
    assign ramled[9:6]= 0;              // No LED

    assign ramled[5]  = ram_dob[0];     // D5   TCK
    assign ramled[10] = 0;              // D10

    assign ramled[11] = ram_radr[9];    // D11  ram adr 9
    assign ramled[12] = 0;              // D12
    assign ramled[13] = 0;              // D13
    assign ramled[14] = ram_radr[8];    // D14  ram adr 8

    assign ramled[15] = ram_radr[7];    // D15  ram adr 7
    assign ramled[16] = ram_radr[6];    // D16  ram adr 6
    assign ramled[17] = 0;              // D17
    assign ramled[18] = 0;              // D18

    assign ramled[19] = ram_radr[5];    // D19  ram adr 5
    assign ramled[20] = ram_dob[1];     // D20  TMS
    assign ramled[21] = ram_radr[4];    // D21  ram adr 4
    assign ramled[22] = ram_dob[2];     // D22  TDI
    assign ramled[23] = ram_radr[3];    // D23  ram adr 3
    assign ramled[24] = ram_radr[2];    // D24  ram adr 2

    assign ramled[25] = ram_dob[3];     // D25  TDO

    assign ramled[26] = ram_radr[1];    // D26  ram adr 1
    assign ramled[27] = 0;              // D27
    assign ramled[28] = ram_radr[0];    // D28  ram adr 0
    assign ramled[29] = 0;              // D29

// Dim LEDs to match old firmware brightness, was not done by clocking before, dunno how
    parameter NDIM=5;
    reg [NDIM-1:0] dim_ctr=0;

    always @(posedge clock) begin
    dim_ctr <= dim_ctr + 1'b1;
    end

    wire dim = (dim_ctr==0);

// Attach cable signals to LEDs after cylon completes
    assign txled[4:0]= 0;               // No LED
    assign txled[9:6]= 0;               // No LED

    assign txled[5]  = crc_error;       // D5
    assign txled[10] = 0;               // D10

    assign txled[11] = dim;             // D11  Single cable test indication
    assign txled[12] = dim;             // D12
    assign txled[13] = 0;               // D13
    assign txled[14] = dim;             // D14

    assign txled[15] = ir[0];           // D15
    assign txled[16] = ir[1];           // D16
    assign txled[17] = ir[2];           // D17
    assign txled[18] = ir[3];           // D18

    assign txled[19] = adb_channel[0];  // D19  ADB channel selected
    assign txled[20] = adb_channel[4];  // D20
    assign txled[21] = adb_channel[1];  // D21
    assign txled[22] = ir[4];           // D22
    assign txled[23] = adb_channel[2];  // D23
    assign txled[24] = adb_channel[3];  // D24

    assign txled[25] =  0;              // D25

    assign txled[26] = state[0];        // D26  jtag state0
    assign txled[27] = state[1];        // D27  jtag state1
    assign txled[28] = state[2];        // D28  jtag state2
    assign txled[29] = state[3];        // D29  jtag state3

// Map LED names, low enables
    assign pretrig_blu  =   !led[ 5];   // D5       Ext_trig
    assign l1a_ok_grn   =   !led[10];   // D10      L1A
    assign invpat_red   =   !led[11];   // D11      !Sync_rx_1st_ok
    assign no_l1a_red   =   !led[12];   // D12      !Sync_rx_2nd_ok
    assign amu_grn      =   !led[13];   // D13      Ext_inject
    assign halt_red     =   !led[14];   // D14      Sync mode
    assign tck_grn      =   !led[15];   // D15      user jtag clock
    assign tdo_grn      =   !led[16];   // D16      user jtag tdo
    assign tdi_grn      =   !led[17];   // D17      user jtag tdi
    assign tms_grn      =   !led[18];   // D18      user jtag tms
    assign feb0_grn     =   !led[19];   // D19      brcst_str1
    assign feb1_grn     =   !led[20];   // D20      subaddr_str
    assign feb2_grn     =   !led[21];   // D21      sync_adb_pulse
    assign feb3_grn     =   !led[22];   // D22      bx0
    assign feb4_grn     =   !led[23];   // D23      Sync_rx_1st_ok & sync_rx_2nd_ok
    assign feb6_grn     =   !led[24];   // D24      ttc_start_trigger
    assign feb5_grn     =   !led[25];   // D25      ttc_bx0
    assign jstate0_grn  =   !led[26];   // D26      jtag state0
    assign jstate1_grn  =   !led[27];   // D27      jtag state1
    assign jstate2_grn  =   !led[28];   // D28      jtag state2
    assign jstate3_grn  =   !led[29];   // D29      jtag state3

//------------------------------------------------------------------------------------------------------------------
// 80MHz signals from TMB are not used for single cable test
//------------------------------------------------------------------------------------------------------------------
// Pack ALCT mezzanine input signals
    wire [16:5] alct_rx;
//                                          first               second          Cable   Pins
//                                          -----------         ----------      -----   ------
    assign alct_rx[5]   = m_ccb_brcst[0];   // ccb_brcst0       ccb_brcst4      2       45  46
    assign alct_rx[6]   = m_ccb_brcst[1];   // ccb_brcst1       ccb_brcst5      2       7   8
    assign alct_rx[7]   = m_ccb_brcst[2];   // ccb_brcst2       ccb_brcst6      2       43  44
    assign alct_rx[8]   = m_ccb_brcst[3];   // ccb_brcst3       ccb_brcst7      2       9   10
    assign alct_rx[9]   = m_brcst_str1;     // brcst_str1       subaddr_str     2       41  42
    assign alct_rx[10]  = m_dout_str;       // dout_str         bx0             2       11  12
    assign alct_rx[11]  = m_ext_inject;     // ext_inject       ext_trig        2       39  40
    assign alct_rx[12]  = m_l1_accept;      // level1_accept    sync_adb_pulse  2       13  14
    assign alct_rx[13]  = m_seq_cmd[0];     // seq_cmd0         seq_cmd2        2       37  38
    assign alct_rx[14]  = m_seq_cmd[1];     // seq_cmd1         seq_cmd3        2       15  16  (2nd was reserved_in4)
    assign alct_rx[15]  = m_reserved_in[0]; // reserved_in0     reserved_in2    2       35  36
    assign alct_rx[16]  = m_reserved_in[1]; // reserved_in1     reserved_in3    2       17  18

//------------------------------------------------------------------------------------------------------------------
// Delay ASICs
//------------------------------------------------------------------------------------------------------------------

    reg dly_clk_en;
    assign seltst_dly = 1'b0;
    assign nrs_dly = 1'b1;

    reg [7:0] power_up_ctr=0;

    wire power_up = power_up_ctr[7];

    always @(posedge clock) begin
    if (!power_up) power_up_ctr = power_up_ctr + 1'b1;
    end

    assign test_pulse   = 0;            // Fire adb test pulser

    wire [0:0] dout_dly_mux = dout_dly[dly_sel_reg[2:0]];

    assign ncs_dly [0] = !(dly_clk_en && dly_sel_reg==3'd0);
    assign ncs_dly [1] = !(dly_clk_en && dly_sel_reg==3'd1);
    assign ncs_dly [2] = !(dly_clk_en && dly_sel_reg==3'd2);
     `ifndef ALCT288
    assign ncs_dly [3] = !(dly_clk_en && dly_sel_reg==3'd3);
        `ifdef ALCT672
        assign ncs_dly [4] = !(dly_clk_en && dly_sel_reg==3'd4);
        assign ncs_dly [5] = !(dly_clk_en && dly_sel_reg==3'd5);
        assign ncs_dly [6] = !(dly_clk_en && dly_sel_reg==3'd6);
        `endif
     `endif

    assign clk_dly  = (dly_clk_en) ? !tck : 1'b0;

//------------------------------------------------------------------------------------------------------------------
// Occupy unused ALCT board signals to force pin instantiation
//------------------------------------------------------------------------------------------------------------------
`ifdef SPARTAN6
    wire sump_s6 = init_b | (|m[1:0]) | rdwr_b;
`else
    wire sump_s6 = 0;
`endif

    assign sump =
    sump_s6             |       // Spartan-6 dual purpose pins
    ram_sump            |       // Unused RAM outputs
    clock_en            |       // Clock enable
    (|alct_rx[16:5])    |       // SCSI inputs
    (|dout_dly)         |       // Serial data from delay asics
    async_adb           |       // Test pulse from TMB
    tp_start_ext        |       // Test pulse from lemo input
    sc_done             |       // Slow Control fpga done
    (|led[9:6])         |       // Unused LEDs
    (|led[4:0])         |       // Unused LEDs
    (|display[15:12]);          // Display mux

//------------------------------------------------------------------------------------------------------------------
//  Debug RAM stores JTAG signals
//------------------------------------------------------------------------------------------------------------------
    reg  [9:0] ram_wadr = 0;
    wire [3:0] ram_wdata;
    wire [3:0] ram_doa;

    assign ram_sump = |ram_doa[3:0];

// Write JTAG to RAM
    assign ram_wdata[0] = tck;
    assign ram_wdata[1] = tms;
    assign ram_wdata[2] = tdi;
    assign ram_wdata[3] = tdo;

    always @(posedge tck) begin
    ram_wadr <= ram_wadr + 1'b1;
    end

// Debounce RAM read address push button
    reg [2:0] pb_sm;

    parameter idle  = 3'd0;
    parameter pulse = 3'd1;
    parameter wdone = 3'd2;

    wire   button_down = (push_button && ram_rd_start);
    assign ram_rd_en   = (pb_sm==pulse);
    wire   pb_ctr_done;

    always @(posedge clock) begin
    if (!power_up)          pb_sm <= idle;
    else begin
    case (pb_sm)
    idle:   if(button_down) pb_sm <= pulse;
    pulse:                  pb_sm <= wdone;
    wdone:  if(pb_ctr_done) pb_sm <= idle;
    default:                pb_sm <= idle;
    endcase
    end
    end

// Wait for button to debounce
    parameter NVIS = 28;
    reg [NVIS-1:0] pb_ctr=0;

    wire clear_ctr = (pb_sm==idle ) || button_down;

    always @(posedge clock) begin
    if      (clear_ctr) pb_ctr <= 0;
    else                pb_ctr <= pb_ctr + 1'b1;
    end

    assign pb_ctr_done = (pb_ctr >= 4000000);   // 1/10 second

// Increment RAM read address
    always @(posedge clock) begin
    if      (!ram_rd_start     )    ram_radr <= 0;                  // Hold read adr at 0 until shunt inserted
    else if (ram_rd_en         ) begin
    if      (ram_radr==ram_wadr)    ram_radr <= 0;                  // Wrap at last address written
    else                            ram_radr <= ram_radr + 1'b1;    // Increment at visual speed
    end
    end

// JTAG storage RAM writes JTAG data to Port A, reads from Port B
`ifdef VIRTEXE
   RAMB4_S4_S4 #
   (
    .SIM_COLLISION_CHECK    ("ALL"),    // "NONE", "WARNING_ONLY", "GENERATE_X_ONLY", "ALL"
    .INIT_00    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_01    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_02    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_03    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_04    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_05    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_06    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_07    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_08    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_09    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0A    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0B    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0C    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0D    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0E    (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0F    (256'h0000000000000000000000000000000000000000000000000000000000000000)

   ) uramb4 (

    .CLKA       (tck),              // Port A clock input
    .ENA        (1'b1),             // Port A RAM enable input
    .RSTA       (1'b0),             // Port A Synchronous reset input
    .WEA        (1'b1),             // Port A RAM write enable input
    .ADDRA      (ram_wadr[9:0]),    // Port A 10-bit address input
    .DIA        (ram_wdata[3:0]),   // Port A 4-bit data input
    .DOA        (ram_doa[3:0]),     // Port A 4-bit data output

    .CLKB       (clock),            // Port B clock input
    .ENB        (1'b1),             // Port B RAM enable input
    .RSTB       (1'b0),             // Port B Synchronous reset input
    .WEB        (1'b0),             // Port B RAM write enable input
    .ADDRB      (ram_radr[9:0]),    // Port B 10-bit address input
    .DIB        (4'h0),             // Port B 4-bit data input
    .DOB        (ram_dob[3:0])      // Port B 4-bit data output
    );

`elsif SPARTAN6
// Map Virtex-E RAM ports into larger Spartan6 RAM
    wire [13:0] ram_wadr_s6  = { 2'b00,ram_wadr[9:0],2'b00};    // 4-bit data use addr[13:2]
    wire [13:0] ram_radr_s6  = { 2'b00,ram_radr[9:0],2'b00};

    wire [31:0] ram_wdata_s6;
    wire [31:0] ram_doa_s6;
    wire [31:0] ram_dob_s6;

    assign ram_wdata_s6[31:0] = ram_wdata[3:0];
    assign ram_doa[3:0]       = ram_doa_s6[3:0];
    assign ram_dob[3:0]       = ram_dob_s6[3:0];

    RAMB16BWER #(
    .DATA_WIDTH_A   (4),        // 0, 1, 2, 4, 9, 18, or 36
    .DATA_WIDTH_B   (4),

    .DOA_REG        (0),        // Optional output register (0 or 1)
    .DOB_REG        (0),

    .EN_RSTRAM_A    ("TRUE"),   // Enable/disable RST
    .EN_RSTRAM_B    ("TRUE"),

    .INITP_00       (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_01       (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_02       (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_03       (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_04       (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_05       (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_06       (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_07       (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_00        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_01        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_02        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_03        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_04        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_05        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_06        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_07        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_08        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_09        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0A        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0B        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0C        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0D        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0E        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0F        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_10        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_11        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_12        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_13        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_14        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_15        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_16        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_17        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_18        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_19        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1A        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1B        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1C        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1D        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1E        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1F        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_20        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_21        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_22        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_23        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_24        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_25        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_26        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_27        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_28        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_29        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_2A        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_2B        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_2C        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_2D        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_2E        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_2F        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_30        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_31        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_32        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_33        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_34        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_35        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_36        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_37        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_38        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_39        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3A        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3B        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3C        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3D        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3E        (256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3F        (256'h0000000000000000000000000000000000000000000000000000000000000000),

    .INIT_A         (36'h000000000),        // Initial values on output port
    .INIT_B         (36'h000000000),
    .INIT_FILE      ("NONE"),               // Optional file used to specify initial RAM contents
    .RSTTYPE        ("SYNC"),               // "SYNC" or "ASYNC"
    .RST_PRIORITY_A ("CE"),                 // "CE" or "SR"
    .RST_PRIORITY_B ("CE"),
    .SIM_COLLISION_CHECK ("ALL"),           // Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
    .SIM_DEVICE     ("SPARTAN6"),           // Must be set to "SPARTAN6" for proper simulation behavior
    .SRVAL_A        (36'h000000000),        // Set/Reset value for RAM output
    .SRVAL_B        (36'h000000000),
    .WRITE_MODE_A   ("WRITE_FIRST"),        // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    .WRITE_MODE_B   ("WRITE_FIRST")

    ) uramb16bwer (

    .CLKA           (tck),                  //  1-bit input:  A port clock input
    .ENA            (1'b1),                 //  1-bit input:  A port enable input
    .REGCEA         (1'b0),                 //  1-bit input:  A port register clock enable input
    .RSTA           (1'b0),                 //  1-bit input:  A port register set/reset input
    .WEA            (4'b1111),              //  4-bit input:  A port byte-wide write enable input
    .ADDRA          (ram_wadr_s6[13:0]),    // 14-bit input:  A port address input
    .DIA            (ram_wdata_s6[31:0]),   // 32-bit input:  A port data input
    .DIPA           (4'h0),                 //  4-bit input:  A port parity input
    .DOA            (ram_doa_s6[31:0]),     // 32-bit output: A port data output
    .DOPA           (),                     //  4-bit output: A port parity output

    .CLKB           (clock),                //  1-bit input:  B port clock input
    .ENB            (1'b1),                 //  1-bit input:  B port enable input
    .REGCEB         (1'b0),                 //  1-bit input:  B port register clock enable input
    .RSTB           (1'b0),                 //  1-bit input:  B port register set/reset input
    .WEB            (4'b0000),              //  4-bit input:  B port byte-wide write enable input
    .ADDRB          (ram_radr_s6[13:0]),    // 14-bit input:  B port address input
    .DIB            (32'h0),                // 32-bit input:  B port data input
    .DIPB           (4'h0),                 //  4-bit input:  B port parity input
    .DOB            (ram_dob_s6[31:0]),     // 32-bit output: B port data output
    .DOPB           ()                      //  4-bit output: B port parity output
    );
`endif

//------------------------------------------------------------------------------------------------------------------
//  Outputs for Optical Mezzanines
//------------------------------------------------------------------------------------------------------------------

`ifdef SPARTAN6
  `ifdef LX150T

    optical_lx150t  optical_prbs (

      .clock(clock) , // 40 mhz logic clock

      .tx_p(tx_p),
      .tx_n(tx_n),

      .refclk_p(refclk_p),
      .refclk_n(refclk_n),

      .reset_i(!clock_lock)

    );

  `endif
  `ifdef LX100

    assign gbt_tx_datavalid = 1'b1;


    prbs_gbt  prbs_gbt (

      .elink_p(elink_p),
      .elink_n(elink_n),

      .gbt_clk40_p(gbt_clk40_p),
      .gbt_clk40_n(gbt_clk40_n),

      .gbt_clk320_p(gbt_clk320_p),
      .gbt_clk320_n(gbt_clk320_n),

      .gbt_txrdy (gbt_txrdy),

      .reset(!clock_lock)

    );


  `endif
`endif

//------------------------------------------------------------------------------------------------------------------
    endmodule
//------------------------------------------------------------------------------------------------------------------
