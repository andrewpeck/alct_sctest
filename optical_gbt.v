`timescale 1ps/1ps

module optical_gbt (

  // need to sync this to the bufio 40 clock at some point..

  input [111:0] data_i, // 112 bit data input

  output [13:0] elink_p, // 14 e-link outputs
  output [13:0] elink_n, // 14 e-link outputs

  input [1:0]   gbt_clk40_p, // bufio clocks for half-banks
  input [1:0]   gbt_clk40_n, // bufio clocks for half-banks

  input gbt_txrdy,

  input        reset

);

  wire [1:0] gbt_clk40;
  wire [1:0] clk_div;
  wire [1:0] clk_in_int_buf;

  wire [1:0] CLK_DIV_OUT;

  wire [1:0] clock_fbin;
  wire [1:0] clock_fbout;
  wire [1:0] clock_320_pll;
  wire [1:0] clock_40_pll;
  wire [1:0] clock_40_bufg;
  wire [1:0] clock_lock;
  wire [1:0] ioclock;
  wire [1:0] serdesstrobe;
  wire [1:0] serdeslocked;

  genvar iclk;
  generate
    for (iclk=0; iclk<=1; iclk=iclk+1) begin: clkloop

      IBUFGDS #(
        .IOSTANDARD ("lvds_25")
      )
      ibufds_clk_inst (
        .I   (gbt_clk40_p[iclk]),
        .IB  (gbt_clk40_n[iclk]),
        .O   (gbt_clk40[iclk])
      );

      // PLL generates clocks
      PLL_BASE # (

        .BANDWIDTH              ("OPTIMIZED"),          // "HIGH", "LOW" or "OPTIMIZED"
        .CLKFBOUT_MULT          (8),                    // Multiply value for all CLKOUT clock outputs (1-64)
        .CLKFBOUT_PHASE         (0.0),                  // Phase offset in degrees of the clock feedback output (0.0-360.0).
        .CLKIN_PERIOD           ("25.000"),             // Input clock period in ns to ps resolution (i.e. 33.333 is 30

        .CLK_FEEDBACK           ("CLKFBOUT"),           // Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
        .COMPENSATION           ("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL"
        .DIVCLK_DIVIDE          (1),                    // Division value for all output clocks (1-52)
        .REF_JITTER             (0.01),                 // Reference Clock Jitter in UI (0.000-0.999).
        .RESET_ON_LOSS_OF_LOCK  ("FALSE"),              // Must be set to FALSE

        .CLKOUT0_DIVIDE         (1),                    // 320 MHz       Divide amount for CLKOUT# clock output (1-128)
        .CLKOUT1_DIVIDE         (8),                    //  40 MHz
        .CLKOUT2_DIVIDE         (8),                    //
        .CLKOUT3_DIVIDE         (8),                    //  40 MHz
        .CLKOUT4_DIVIDE         (8),                    //  40 MHz
        .CLKOUT5_DIVIDE         (8),                    //  40 MHz

        .CLKOUT0_DUTY_CYCLE     (0.5),                  //Duty cycle for CLKOUT# clock output (0.01-0.99)
        .CLKOUT1_DUTY_CYCLE     (0.5),
        .CLKOUT2_DUTY_CYCLE     (0.5),
        .CLKOUT3_DUTY_CYCLE     (0.5),
        .CLKOUT4_DUTY_CYCLE     (0.5),
        .CLKOUT5_DUTY_CYCLE     (0.5),

        .CLKOUT0_PHASE          (0.0),                // Output phase relationship for CLKOUT# clock output (-360.0-360.0)
        .CLKOUT1_PHASE          (0.0),
        .CLKOUT2_PHASE          (0.0),
        .CLKOUT3_PHASE          (0.0),
        .CLKOUT4_PHASE          (0.0),
        .CLKOUT5_PHASE          (0.0)

      ) upll_base (

        .CLKIN                  (gbt_clk40[iclk]),     // 1-bit input:  Clock input
        .CLKFBIN                (clock_fbin[iclk]),     // 1-bit input:  Feedback clock input
        .CLKFBOUT               (clock_fbout[iclk]),    // 1-bit output: PLL_BASE feedback output
        .RST                    (1'b0),                 // 1-bit input:  Reset input
        .LOCKED                 (clock_lock[iclk]),     // 1-bit output: PLL_BASE lock status output

        .CLKOUT0                (clock_320_pll[iclk] ),
        .CLKOUT1                (clock_40_pll[iclk] ),
        .CLKOUT2                (),
        .CLKOUT3                (),
        .CLKOUT4                (),
        .CLKOUT5                ()
      );

      // Buffer up the divided clock
      BUFG clkdiv_buf_inst (
        .I (clock_40_pll[iclk]),
        .O (clock_40_bufg[iclk])
      );

      BUFPLL #(
        .DIVIDE (8),
        .ENABLE_SYNC ("TRUE")
      )
      bufpll
      (
        .PLLIN (clock_320_pll[iclk]),
        .GCLK (clock_40_bufg[iclk]),
        .LOCKED (clock_lock[iclk]),
        .IOCLK (ioclock[iclk]),
        .SERDESSTROBE (serdesstrobe[iclk]),
        .LOCK (serdeslocked[iclk])
      );

    end
  endgenerate

  // flip-flop synchronizer to bring global reset into the BUFIO clock domain
  // hold reset for N clocks to satisfy OSERDES reset requirements
  // can just use a single reset on bufg0 since it is on a global clock on they are in phase

  wire reset_sync;
  reg [2:0] reset_r;
  always @(posedge clock_40_bufg[0]) begin
    reset_r [2:0] <= {reset_r[1:0],reset || !gbt_txrdy};
  end
  assign reset_sync = reset_r[2];

  reg [4:0] reset_hold=0;
  always @(posedge clock_40_bufg[0]) begin
    if         (reset_sync)  reset_hold <= 0;
    else if (!(&reset_sync)) reset_hold <= reset_hold + 1'b1;
  end

  wire reset_done = &reset_hold;


  wire [13:0] clock_region = { // assign ELINKs to BUFIO2 clocks based on half-banks (consult schematics)
    1'b1, // 13
    1'b0, // 12
    1'b0, // 11
    1'b0, // 10
    1'b0, // 9
    1'b1, // 8
    1'b0, // 7
    1'b0, // 6
    1'b0, // 5
    1'b0, // 4
    1'b1, // 3
    1'b1, // 2
    1'b0, // 1
    1'b0  // 0
  };

  genvar ilink;
  generate
    for (ilink=0; ilink<8; ilink=ilink+1) begin: linkloop
      elink_o elink (
        .DATA_OUT_FROM_DEVICE (data_i [ilink*8+:8]),
        .DATA_OUT_TO_PINS_P   (elink_p[ilink]),
        .DATA_OUT_TO_PINS_N   (elink_n[ilink]),
        .SERDES_CLOCK         (ioclock[clock_region[ilink]]),
        .CLK_DIV              (clock_40_bufg[clock_region[ilink]]),
        .IO_RESET             (~reset_done) // reset synced to the GBT 40MHz frame clock
      );
    end
  endgenerate

endmodule
