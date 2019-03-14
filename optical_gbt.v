`timescale 1ps/1ps

module optical_gbt (

  // need to sync this to the bufio 40 clock at some point..
  output clock_out,

  input  [111:0] data_i, // 112 bit data input

  output [13:0] elink_p, // 14 e-link outputs
  output [13:0] elink_n, // 14 e-link outputs

  input gbt_clk40_p, // bufio clocks for half-banks
  input gbt_clk40_n, // bufio clocks for half-banks
  
  input gbt_clk320_p, // bufio clocks for half-banks
  input gbt_clk320_n, // bufio clocks for half-banks

  input gbt_txrdy,

  input        reset

);

  wire gbt_clk40;
  wire gbt_clk320;

  wire clock_fbin;
  wire clock_fbout;
  wire clock_320_pll;
  wire clock_40_pll;
  wire clock_40_bufg;
  wire clock_lock;
  wire ioclock;
  wire serdesstrobe;
  wire serdeslocked;

      IBUFGDS #(
        .IOSTANDARD ("PPDS_33")
      )
      ibufds_clk_inst (
        .I   (gbt_clk40_p),
        .IB  (gbt_clk40_n),
        .O   (gbt_clk40)
      );

      IBUFGDS #(
        .IOSTANDARD ("LVDS_33")
      )
      ibufds_clk_inst2 (
        .I   (gbt_clk320_p),
        .IB  (gbt_clk320_n),
        .O   (gbt_clk320)
      );

      // see ug382 figure 1-38

      // PLL generates clocks
      PLL_BASE # (

        .BANDWIDTH              ("OPTIMIZED"),          // "HIGH", "LOW" or "OPTIMIZED"
        .CLKFBOUT_MULT          (16),                   // Multiply value for all CLKOUT clock outputs (1-64)
        .CLKFBOUT_PHASE         (0.0),                  // Phase offset in degrees of the clock feedback output (0.0-360.0).
        .CLKIN_PERIOD           (25.000),               // Input clock period in ns to ps resolution (i.e. 33.333 is 30

        .CLK_FEEDBACK           ("CLKFBOUT"),           // Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
        .COMPENSATION           ("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL"
        .DIVCLK_DIVIDE          (1),                    // Division value for all output clocks (1-52)
        .REF_JITTER             (0.01),                 // Reference Clock Jitter in UI (0.000-0.999).
        .RESET_ON_LOSS_OF_LOCK  ("FALSE"),              // Must be set to FALSE

        .CLKOUT0_DIVIDE         (2),                    // 320 MHz       Divide amount for CLKOUT# clock output (1-128)
        .CLKOUT1_DIVIDE         (16),                   //  40 MHz
        .CLKOUT2_DIVIDE         (16),                   //
        .CLKOUT3_DIVIDE         (16),                   //  40 MHz
        .CLKOUT4_DIVIDE         (16),                   //  40 MHz
        .CLKOUT5_DIVIDE         (16),                   //  40 MHz

        .CLKOUT0_DUTY_CYCLE     (0.5),                  //Duty cycle for CLKOUT# clock output (0.01-0.99)
        .CLKOUT1_DUTY_CYCLE     (0.5),
        .CLKOUT2_DUTY_CYCLE     (0.5),
        .CLKOUT3_DUTY_CYCLE     (0.5),
        .CLKOUT4_DUTY_CYCLE     (0.5),
        .CLKOUT5_DUTY_CYCLE     (0.5),

        .CLKOUT0_PHASE          (0.0), // Output phase relationship for CLKOUT# clock output (-360.0-360.0)
        .CLKOUT1_PHASE          (0.0), //
        .CLKOUT2_PHASE          (0.0),
        .CLKOUT3_PHASE          (0.0),
        .CLKOUT4_PHASE          (0.0),
        .CLKOUT5_PHASE          (0.0)

      ) upll_base (

        .CLKIN                  (gbt_clk40),      // 1-bit input:  Clock input
        .CLKFBIN                (clock_fbin),     // 1-bit input:  Feedback clock input
        .CLKFBOUT               (clock_fbout),    // 1-bit output: PLL_BASE feedback output
        .RST                    (1'b0),                 // 1-bit input:  Reset input
        .LOCKED                 (clock_lock),     // 1-bit output: PLL_BASE lock status output

        .CLKOUT0                (clock_320_pll),
        .CLKOUT1                (clock_40_pll),
        .CLKOUT2                (),
        .CLKOUT3                (),
        .CLKOUT4                (),
        .CLKOUT5                ()
      );

      BUFG  clock_fbout_bufg    (.I(clock_fbout), .O(clock_fbin));

      // Buffer up the divided clock
      BUFG clkdiv_buf_inst (
        // .CE (clock_lock  ),
        .I (clock_40_pll ),
        .O (clock_40_bufg)
      );

      BUFPLL #(
        .DIVIDE (8),
        .ENABLE_SYNC ("TRUE")
      )
      bufpll (
        .PLLIN        ( clock_320_pll), // Clock input from PLL (CLKOUT0, CLKOUT1) directly connected to the PLL.
        .GCLK         ( clock_40_bufg), // Clock input from BUFG or GCLK. The GCLK frequency must match the expected SERDESSTROBE frequency FGCLK = FPLLIN/DIVIDE
        .LOCKED       ( clock_lock   ), // LOCKED signal from PLL
        .IOCLK        ( ioclock      ), // I/O clock network output. Connects to IOSERDES2 (CLK0), BUFIO2FB (I), or IODELAY2 (IOCLK0, IOCLK1)
        .SERDESSTROBE ( serdesstrobe ), // I/O clock network output used to drive IOSERDES2 (IOCE).
        .LOCK         ( serdeslocked )  // Synchronized LOCK output directly connected to the PLL
      );

  assign clock_out = clock_40_bufg;

  // flip-flop synchronizer to bring global reset into the BUFIO clock domain
  // hold reset for N clocks to satisfy OSERDES reset requirements
  // can just use a single reset on bufg0 since it is on a global clock on they are in phase

  wire reset_sync;
  reg [2:0] reset_r=3'b111;

  always @(posedge clock_out) begin
    reset_r [2:0] <= {reset_r[1:0],   (reset || (~clock_lock))};
  end

  assign reset_sync = reset_r[2];

  reg [4:0] reset_hold=0;
  always @(posedge clock_out) begin
    if         (reset_sync)  reset_hold <= 0;
    else if (!(&reset_hold)) reset_hold <= reset_hold + 1'b1;
    else                     reset_hold <= reset_hold;
  end

  wire reset_done = &reset_hold;
  wire io_reset   = ~reset_done;

  parameter widebus =1'b1;
  parameter v2 = 1'b1;

  parameter [13:0] elink_is_valid = { // assign ELINKs to BUFIO2 clocks based on half-banks (consult schematics)
    (1'b1 | v2) & widebus ,           // 14  requires widebus; disabled for now...
    (1'b1 | v2) & widebus ,           // 13  requires widebus
    (1'b1 | v2) & widebus ,           // 12  requires widebus
    (1'b1 | v2) & widebus ,           // 11  requires widebus
    (1'b1 | v2) & widebus ,           // 10  requires widebus
     1'b0 | v2,                       // 9
     1'b1 | v2,                       // 8
     1'b0 | v2,                       // 7
     1'b0 | v2,                       // 6
     1'b0 | v2,                       // 5
     1'b0 | v2,                       // 4
     1'b0 | v2,                       // 3
     1'b1 | v2,                       // 2
     1'b0 | v2,                       // 1
     1'b0 | v2                        // 0
  };

  genvar ilink;
  generate
    for (ilink=0; ilink<14; ilink=ilink+1) begin: linkloop
      if (elink_is_valid[ilink] || v2) begin
         //OBUFDS obuf (
         //   .I  (data_i [ilink*8]),
         //   .O  (elink_p[ilink]),
         //   .OB (elink_n[ilink])
         //);

       elink_o elink (
         .DATA_OUT_FROM_DEVICE ( data_i        [ilink*8+:8]           ),
         .DATA_OUT_TO_PINS_P   ( elink_p       [ilink]                ),
         .DATA_OUT_TO_PINS_N   ( elink_n       [ilink]                ),
         .SERDES_CLOCK         ( ioclock                              ),
         .SERDES_STROBE        ( serdesstrobe                         ),
         .CLK_DIV              ( clock_out                            ),
         .IO_RESET             ( io_reset                             ) // reset synced to the GBT 40MHz frame clock
                                                                     ) ;

      end
    end
  endgenerate

endmodule
