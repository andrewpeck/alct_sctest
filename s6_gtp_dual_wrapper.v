module s6_gtp_dual_wrapper (

  input        reset,

  input [3:0]  tx_is_kchar,

  input [31:0] tx_data0,
  input [31:0] tx_data1,

  input [3:0]  tx_diffctrl,
  input [2:0]  tx_preemphasis,

  input [1:0] tx_powerdown,

  input refclk_p,
  input refclk_n,

  output [1:0] tx_p,
  output [1:0] tx_n,

  output tx_clk80,

  output [1:0] reset_done

  );

 wire txusrclk,  txusrclk_pll;  // 320 MHz TXUSRCLK   = line rate (3200) / internal data width (10)
 wire txusrclk2, txusrclk2_pll; // 80  MHz TXUSERCLK2 = TXUSRCLK / 4

 assign tx_clk80 = txusrclk2;

 wire [1:0] tile0_gtp_clkout0;
 wire tile0_gtp_clkout0_bufio2;
 wire [1:0] plllkdet;

 //----------------------------------------------------------------------------------------------------
 // take the user out clock recovered from the pll in the gtp (TXOUTCLK) and pass it into a bufio2
 // txoutclk frequency = line rate / 10 = 320 MHz
 //----------------------------------------------------------------------------------------------------

   BUFIO2 # (
       .DIVIDE                         (1),
       .DIVIDE_BYPASS                  ("TRUE")
   )
   gtp_bufio2
   (
       .I                              (tile0_gtp_clkout0[0]),
       .DIVCLK                         (tile0_gtp_clkout0_bufio2),
       .IOCLK                          (),
       .SERDESSTROBE                   ()
   );

 //----------------------------------------------------------------------------------------------------
 // use a CMT PLL to generate user clocks for fabric
 //----------------------------------------------------------------------------------------------------

   wire pll_fb_out;
   wire pll_reset = ~plllkdet[0];

   // Instantiate a DCM module to divide the reference clock. Uses internal feedback
   // for improved jitter performance, and to avoid consuming an additional BUFG
   PLL_BASE # (
        .CLKFBOUT_MULT     (2),
        .DIVCLK_DIVIDE     (1),
        .CLK_FEEDBACK      ("CLKFBOUT"),
        .CLKFBOUT_PHASE    (0),
        .COMPENSATION      ("SYSTEM_SYNCHRONOUS"),

        .CLKIN_PERIOD      (3.125),

        .CLKOUT0_DIVIDE    (8),
        .CLKOUT1_DIVIDE    (2),
        .CLKOUT2_DIVIDE    (1),
        .CLKOUT3_DIVIDE    (1),

        .CLKOUT0_PHASE     (0),
        .CLKOUT1_PHASE     (0),
        .CLKOUT2_PHASE     (0),
        .CLKOUT3_PHASE     (0)
   )
   pll_adv_i (
        .CLKIN             (tile0_gtp_clkout0_bufio2),
        .CLKFBIN           (pll_fb_out),
        .CLKFBOUT          (pll_fb_out),

        .CLKOUT0           (txusrclk2_pll),
        .CLKOUT1           (txusrclk_pll),
        .CLKOUT2           (),
        .CLKOUT3           (),

        .CLKOUT4           (),
        .CLKOUT5           (),
        .LOCKED            (),
        .RST               (pll_reset)
   );

   BUFG txusrclk_bufg  (.O (txusrclk),   .I (txusrclk_pll));
   BUFG txusrclk2_bufg (.O (txusrclk2), .I (txusrclk2_pll));

 //----------------------------------------------------------------------------------------------------
 // ibufds for refclk
 //----------------------------------------------------------------------------------------------------

   wire refclk;

   wire         tied_to_ground_i     = 1'b0;
   wire [191:0] tied_to_ground_vec_i = 192'b0;

   IBUFDS refclk_ibufds (
       .O                              (refclk),
       .I                              (refclk_p),
       .IB                             (refclk_n)
   );

   //--------------------------- The GTP Wrapper -----------------------------

   s6_gtpwizard_v1_11 # (
       .WRAPPER_SIM_GTPRESET_SPEEDUP           (0),      // Set this to 1 for simulation
       .WRAPPER_SIMULATION                     (0)       // Set this to 1 for simulation
   )
   s6_gtpwizard_v1_11_i (
       //_____________________________________________________________________
       //_____________________________________________________________________
       //TILE0  (X0_Y1)

       //---------------------- Loopback and Powerdown Ports ----------------------

       .TILE0_TXPOWERDOWN0_IN          ({2{tx_powerdown[0]}}),
       .TILE0_TXPOWERDOWN1_IN          ({2{tx_powerdown[1]}}),
       .TILE0_RXPOWERDOWN0_IN          (2'b00),
       .TILE0_RXPOWERDOWN1_IN          (2'b00),

       //------------------------------- PLL Ports --------------------------------

       .TILE0_CLK00_IN                 (refclk),
       .TILE0_CLK01_IN                 (refclk),

       .TILE0_GTPRESET0_IN             (reset),
       .TILE0_GTPRESET1_IN             (reset),

       .TILE0_PLLLKDET0_OUT            (plllkdet[0]),
       .TILE0_PLLLKDET1_OUT            (plllkdet[1]),

       .TILE0_RESETDONE0_OUT           (reset_done[0]),
       .TILE0_RESETDONE1_OUT           (reset_done[1]),

       //--------------------- Receive Ports - 8b10b Decoder ----------------------

       .TILE0_RXDISPERR0_OUT           (),
       .TILE0_RXDISPERR1_OUT           (),
       .TILE0_RXNOTINTABLE0_OUT        (),
       .TILE0_RXNOTINTABLE1_OUT        (),

       //----------------- Receive Ports - RX Data Path interface -----------------

       .TILE0_RXDATA0_OUT              (),
       .TILE0_RXDATA1_OUT              (),
       .TILE0_RXUSRCLK0_IN             (txusrclk),
       .TILE0_RXUSRCLK1_IN             (txusrclk),
       .TILE0_RXUSRCLK20_IN            (txusrclk2),
       .TILE0_RXUSRCLK21_IN            (txusrclk2),

       //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------

       .TILE0_RXEQMIX0_IN              (2'b00),
       .TILE0_RXEQMIX1_IN              (2'b00),
       .TILE0_RXP0_IN                  (1'b1),
       .TILE0_RXN0_IN                  (1'b0),
       .TILE0_RXP1_IN                  (1'b1),
       .TILE0_RXN1_IN                  (1'b0),

       //-------------------------- TX/RX Datapath Ports --------------------------

       .TILE0_GTPCLKOUT0_OUT           (tile0_gtp_clkout0),
       .TILE0_GTPCLKOUT1_OUT           (),

       //----------------- Transmit Ports - 8b10b Encoder Control -----------------

       .TILE0_TXCHARISK0_IN            (tx_is_kchar),
       .TILE0_TXCHARISK1_IN            (tx_is_kchar),

       //---------------- Transmit Ports - TX Data Path interface -----------------

       .TILE0_TXDATA0_IN               (tx_data0),
       .TILE0_TXDATA1_IN               (tx_data1),

       .TILE0_TXUSRCLK0_IN             (txusrclk),
       .TILE0_TXUSRCLK1_IN             (txusrclk),
       .TILE0_TXUSRCLK20_IN            (txusrclk2),
       .TILE0_TXUSRCLK21_IN            (txusrclk2),

       .TILE0_TXOUTCLK0_OUT            (),
       .TILE0_TXOUTCLK1_OUT            (),

       //------------- Transmit Ports - TX Driver and OOB signalling --------------

       .TILE0_TXDIFFCTRL0_IN           (tx_diffctrl[3:0]),
       .TILE0_TXDIFFCTRL1_IN           (tx_diffctrl[3:0]),
       .TILE0_TXN0_OUT                 (tx_n[0]),
       .TILE0_TXN1_OUT                 (tx_n[1]),
       .TILE0_TXP0_OUT                 (tx_p[0]),
       .TILE0_TXP1_OUT                 (tx_p[1]),
       .TILE0_TXPREEMPHASIS0_IN        (tx_preemphasis[2:0]),
       .TILE0_TXPREEMPHASIS1_IN        (tx_preemphasis[2:0])
   );


endmodule
