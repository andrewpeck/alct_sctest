module s6_gtp_dual_wrapper (

  input        reset,

  input [1:0]  txcharisk,

  output [1:0]  rxcharisk0,
  output [1:0]  rxcharisk1,

  input [15:0] tx_data0,
  input [15:0] tx_data1,

  output [15:0] rx_data0,
  output [15:0] rx_data1,

  input [3:0]  txdiffctrl,
  input [2:0]  txpreemphasis,

  input [2:0] loopback,

  input rxenmcommaalign,
  input rxenpcommaalign,

  input txpowerdown0,
  input txpowerdown1,

  input rxpowerdown0,
  input rxpowerdown1,

  input rxenchansync,
  input [1:0] rxeqmix,

  input refclk_p,
  input refclk_n,

  output [1:0] tx_p,
  output [1:0] tx_n,

  output [1:0] rxchanisaligned,

  input  [1:0] rx_p,
  input  [1:0] rx_n,

  output tx_clk40,
  output tx_clk80,
  output tx_clk160,

  output reset_done

  );

 wire tile0_gtpclkout0_bufio2;
 wire plllkdet;

   //-------------------------------------------------------------------------------------------------------------------
   // below here should be copy pasted from s6_gtpwizard_v1-11_top.v
   //-------------------------------------------------------------------------------------------------------------------

    //---------------------- Loopback and Powerdown Ports ----------------------
    wire    [2:0]   tile0_loopback0_i;
    wire    [2:0]   tile0_loopback1_i;
    wire    [1:0]   tile0_rxpowerdown0_i;
    wire    [1:0]   tile0_rxpowerdown1_i;
    wire    [1:0]   tile0_txpowerdown0_i;
    wire    [1:0]   tile0_txpowerdown1_i;
    //------------------------------- PLL Ports --------------------------------
    wire            tile0_gtpreset0_i;
    wire            tile0_gtpreset1_i;
    wire            tile0_plllkdet0_i;
    wire            tile0_resetdone0_i;
    wire            tile0_resetdone1_i;
    //--------------------- Receive Ports - 8b10b Decoder ----------------------
    wire    [1:0]   tile0_rxchariscomma0_i;
    wire    [1:0]   tile0_rxchariscomma1_i;
    wire    [1:0]   tile0_rxcharisk0_i;
    wire    [1:0]   tile0_rxcharisk1_i;
    wire    [1:0]   tile0_rxdisperr0_i;
    wire    [1:0]   tile0_rxdisperr1_i;
    wire    [1:0]   tile0_rxnotintable0_i;
    wire    [1:0]   tile0_rxnotintable1_i;
    //-------------------- Receive Ports - Channel Bonding ---------------------
    wire            tile0_rxchanbondseq0_i;
    wire            tile0_rxchanbondseq1_i;
    wire            tile0_rxchanisaligned0_i;
    wire            tile0_rxchanisaligned1_i;
    wire            tile0_rxchanrealign0_i;
    wire            tile0_rxchanrealign1_i;
    wire            tile0_rxenchansync0_i;
    wire            tile0_rxenchansync1_i;
    wire            tile0_rxenmcommaalign0_i;
    wire            tile0_rxenmcommaalign1_i;
    wire            tile0_rxenpcommaalign0_i;
    wire            tile0_rxenpcommaalign1_i;
    //----------------- Receive Ports - RX Data Path interface -----------------
    wire    [15:0]  tile0_rxdata0_i;
    wire    [15:0]  tile0_rxdata1_i;
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    wire    [1:0]   tile0_rxeqmix0_i;
    wire    [1:0]   tile0_rxeqmix1_i;
    //-------------------------- TX/RX Datapath Ports --------------------------
    wire    [1:0]   tile0_gtpclkout0_i;
    wire    [1:0]   tile0_gtpclkout1_i;
    //----------------- Transmit Ports - 8b10b Encoder Control -----------------
    wire    [1:0]   tile0_txcharisk0_i;
    wire    [1:0]   tile0_txcharisk1_i;
    //---------------- Transmit Ports - TX Data Path interface -----------------
    wire    [15:0]  tile0_txdata0_i;
    wire    [15:0]  tile0_txdata1_i;
    wire            tile0_txoutclk0_i;
    wire            tile0_txoutclk1_i;
    //------------- Transmit Ports - TX Driver and OOB signalling --------------
    wire    [3:0]   tile0_txdiffctrl0_i;
    wire    [3:0]   tile0_txdiffctrl1_i;
    wire    [2:0]   tile0_txpreemphasis0_i;
    wire    [2:0]   tile0_txpreemphasis1_i;


    //----------------------------- Global Signals -----------------------------
    wire            tied_to_ground_i;
    wire    [191:0] tied_to_ground_vec_i;
    wire            tied_to_vcc_i;
    wire    [7:0]   tied_to_vcc_vec_i;
    
    
    //--------------------------- User Clocks ---------------------------------
    wire            tile0_txusrclk0_i;
    wire            tile0_txusrclk20_i;

   //-------------------------------------------------------------------------------------------------------------------
   // above here should be copy pasted from s6_gtpwizard_v1-11_top.v
   //-------------------------------------------------------------------------------------------------------------------

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
       .I                              (tile0_gtpclkout0_i[0]),
       .DIVCLK                         (tile0_gtpclkout0_bufio2),
       .IOCLK                          (),
       .SERDESSTROBE                   ()
   );

 //----------------------------------------------------------------------------------------------------
 // use a CMT PLL to generate user clocks for fabric
 //----------------------------------------------------------------------------------------------------

   wire pll_fb_out;
   wire pll_reset = ~plllkdet;

   // Instantiate a DCM module to divide the reference clock. Uses internal feedback
   // for improved jitter performance, and to avoid consuming an additional BUFG
   PLL_BASE # (
        .CLKFBOUT_MULT     (4),
        .DIVCLK_DIVIDE     (2),
        .CLK_FEEDBACK      ("CLKFBOUT"),
        .CLKFBOUT_PHASE    (0),
        .COMPENSATION      ("SYSTEM_SYNCHRONOUS"),

        .CLKIN_PERIOD      (3.125), // taken from 320 MHz txoutclk

        .CLKOUT0_DIVIDE    (16), // 40 MHz  = 320 * 2 / 16
        .CLKOUT1_DIVIDE    (8),  // 80 MHz  = 320 * 2 / 8
        .CLKOUT2_DIVIDE    (4),  // 160 MHz = 320 * 2 / 4
        .CLKOUT3_DIVIDE    (2),

        .CLKOUT0_PHASE     (0),
        .CLKOUT1_PHASE     (0),
        .CLKOUT2_PHASE     (0),
        .CLKOUT3_PHASE     (0)
   )
   pll_adv_i (
        .CLKIN             (tile0_gtpclkout0_bufio2),
        .CLKFBIN           (pll_fb_out),
        .CLKFBOUT          (pll_fb_out),

        .CLKOUT0           (tx_clk40_pll),
        .CLKOUT1           (tx_clk80_pll),
        .CLKOUT2           (tx_clk160_pll),
        .CLKOUT3           (tx_clk320_pll),

        .CLKOUT4           (),
        .CLKOUT5           (),
        .LOCKED            (),
        .RST               (pll_reset)
   );

   BUFG tx_clk40_pll_bufg   (.O (tx_clk40),  .I (tx_clk40_pll) );
   BUFG tx_clk80_pll_bufg   (.O (tx_clk80),  .I (tx_clk80_pll) );
   BUFG tx_clk160_pll_bufg  (.O (tx_clk160), .I (tx_clk160_pll) );
   BUFG tx_clk320_pll_bufg  (.O (tx_clk320), .I (tx_clk320_pll) );

   assign tile0_txusrclk0_i  = tx_clk320;
   assign tile0_txusrclk20_i = tx_clk160;

   assign tile0_txusrclk1_i  = tx_clk320;
   assign tile0_txusrclk21_i = tx_clk160;

   //----------------------------------------------------------------------------------------------------
   // ibufds for refclk
   //----------------------------------------------------------------------------------------------------

   wire refclk;

   IBUFDS refclk_ibufds (
     .O                              (refclk),
     .I                              (refclk_p),
     .IB                             (refclk_n)
   );

   //-------------------------------------------------------------------------------------------------------------------
   // IO name mappings
   //-------------------------------------------------------------------------------------------------------------------

   assign tile0_loopback0_i = loopback;
   assign tile0_loopback1_i = loopback;

   assign tile0_txpowerdown1_i = {2{txpowerdown1}};
   assign tile0_txpowerdown0_i = {2{txpowerdown0}};

   assign tile0_rxpowerdown1_i = {2{rxpowerdown1}};
   assign tile0_rxpowerdown0_i = {2{rxpowerdown0}};

   assign plllkdet = tile0_plllkdet0_i;

   assign reset_done = tile0_resetdone0_i || tile0_resetdone1_i;

   assign rx_data0 = tile0_rxdata0_i;
   assign rx_data1 = tile0_rxdata1_i;

   assign tile0_txdata0_i = tx_data0;
   assign tile0_txdata1_i = tx_data1;

   assign rxchanisaligned = {2{|{tile0_rxchanisaligned0_i, tile0_rxchanisaligned1_i}}};

   assign tile0_rxenchansync0_i = rxenchansync;
   assign tile0_rxenchansync1_i = rxenchansync;

   assign tile0_gtpreset0_i = reset;
   assign tile0_gtpreset1_i = reset;

   assign tile0_rxeqmix0_i = rxeqmix;
   assign tile0_rxeqmix1_i = rxeqmix;

   assign tile0_txcharisk0_i = txcharisk;
   assign tile0_txcharisk1_i = txcharisk;

   assign rxcharisk0 = tile0_rxcharisk0_i;
   assign rxcharisk1 = tile0_rxcharisk1_i;

   assign tile0_txdiffctrl0_i = txdiffctrl;
   assign tile0_txdiffctrl1_i = txdiffctrl;

   assign tile0_txpreemphasis0_i = txpreemphasis;
   assign tile0_txpreemphasis1_i = txpreemphasis;

   assign tile0_gtp0_refclk_i = refclk;
   assign tile0_gtp0_refclk_i = refclk;

   assign tile0_rxenmcommaalign0_i = rxenmcommaalign;
   assign tile0_rxenmcommaalign1_i = rxenmcommaalign;
   assign tile0_rxenpcommaalign0_i = rxenpcommaalign;
   assign tile0_rxenpcommaalign1_i = rxenpcommaalign;

   wire [1:0] RXN_IN = rx_n;
   wire [1:0] RXP_IN = rx_p;

   wire [1:0] TXN_OUT;
   wire [1:0] TXP_OUT;

   assign tx_n = TXN_OUT;
   assign tx_p = TXP_OUT;

   parameter EXAMPLE_SIM_GTPRESET_SPEEDUP = 0;
   parameter EXAMPLE_SIMULATION           = 0;

    //  Static signal Assigments    
    assign tied_to_ground_i             = 1'b0;
    assign tied_to_ground_vec_i         = 192'h000000000000000000000000000000000000000000000000;
    assign tied_to_vcc_i                = 1'b1;
    assign tied_to_vcc_vec_i            = 8'hff;

   wire sump =  tile0_rxdisperr0_i |
                tile0_rxdisperr1_i |
                tile0_rxnotintable0_i |
                tile0_rxnotintable1_i;

   //-------------------------------------------------------------------------------------------------------------------
   // below here should be copy pasted from s6_gtpwizard_v1-11_top.v
   //-------------------------------------------------------------------------------------------------------------------
    s6_gtpwizard_v1_11 #
    (
        .WRAPPER_SIM_GTPRESET_SPEEDUP           (EXAMPLE_SIM_GTPRESET_SPEEDUP),
        .WRAPPER_CLK25_DIVIDER_0                (4),
        .WRAPPER_CLK25_DIVIDER_1                (4),
        .WRAPPER_PLL_DIVSEL_FB_0                (4),
        .WRAPPER_PLL_DIVSEL_FB_1                (4),
        .WRAPPER_PLL_DIVSEL_REF_0               (1),
        .WRAPPER_PLL_DIVSEL_REF_1               (1),
        .WRAPPER_SIM_REFCLK0_SOURCE              (3'b000),
        .WRAPPER_SIM_REFCLK1_SOURCE              (3'b000),
        .WRAPPER_SIMULATION                     (EXAMPLE_SIMULATION)
    )
    s6_gtpwizard_v1_11_i
    (

 
 
 
 
 
 
 
        //_____________________________________________________________________
        //_____________________________________________________________________
        //TILE0  (X0_Y1)

        //---------------------- Loopback and Powerdown Ports ----------------------
        .TILE0_LOOPBACK0_IN             (tile0_loopback0_i),
        .TILE0_LOOPBACK1_IN             (tile0_loopback1_i),
        .TILE0_RXPOWERDOWN0_IN          (tile0_rxpowerdown0_i),
        .TILE0_RXPOWERDOWN1_IN          (tile0_rxpowerdown1_i),
        .TILE0_TXPOWERDOWN0_IN          (tile0_txpowerdown0_i),
        .TILE0_TXPOWERDOWN1_IN          (tile0_txpowerdown1_i),
        //------------------------------- PLL Ports --------------------------------
        .TILE0_CLK00_IN                 (tile0_gtp0_refclk_i),
        .TILE0_CLK01_IN                 (tile0_gtp0_refclk_i),
        .TILE0_CLK10_IN                 (tied_to_ground_i),
        .TILE0_CLK11_IN                 (tied_to_ground_i),
        .TILE0_CLKINEAST0_IN            (tied_to_ground_i),
        .TILE0_CLKINEAST1_IN            (tied_to_ground_i),
        .TILE0_CLKINWEST0_IN            (tied_to_ground_i),
        .TILE0_CLKINWEST1_IN            (tied_to_ground_i),
        .TILE0_GTPRESET0_IN             (tile0_gtpreset0_i),
        .TILE0_GTPRESET1_IN             (tile0_gtpreset1_i),
        .TILE0_PLLLKDET0_OUT            (tile0_plllkdet0_i),
        .TILE0_PLLLKDET1_OUT            (tile0_plllkdet1_i),
        .TILE0_REFSELDYPLL0_IN          (tied_to_ground_vec_i[2:0]),
        .TILE0_REFSELDYPLL1_IN          (tied_to_ground_vec_i[2:0]),
        .TILE0_RESETDONE0_OUT           (tile0_resetdone0_i),
        .TILE0_RESETDONE1_OUT           (tile0_resetdone1_i),
        //--------------------- Receive Ports - 8b10b Decoder ----------------------
        .TILE0_RXCHARISCOMMA0_OUT       (tile0_rxchariscomma0_i),
        .TILE0_RXCHARISCOMMA1_OUT       (tile0_rxchariscomma1_i),
        .TILE0_RXCHARISK0_OUT           (tile0_rxcharisk0_i),
        .TILE0_RXCHARISK1_OUT           (tile0_rxcharisk1_i),
        .TILE0_RXDISPERR0_OUT           (tile0_rxdisperr0_i),
        .TILE0_RXDISPERR1_OUT           (tile0_rxdisperr1_i),
        .TILE0_RXNOTINTABLE0_OUT        (tile0_rxnotintable0_i),
        .TILE0_RXNOTINTABLE1_OUT        (tile0_rxnotintable1_i),
        //-------------------- Receive Ports - Channel Bonding ---------------------
        .TILE0_RXCHANBONDSEQ0_OUT       (tile0_rxchanbondseq0_i),
        .TILE0_RXCHANBONDSEQ1_OUT       (tile0_rxchanbondseq1_i),
        .TILE0_RXCHANISALIGNED0_OUT     (tile0_rxchanisaligned0_i),
        .TILE0_RXCHANISALIGNED1_OUT     (tile0_rxchanisaligned1_i),
        .TILE0_RXCHANREALIGN0_OUT       (tile0_rxchanrealign0_i),
        .TILE0_RXCHANREALIGN1_OUT       (tile0_rxchanrealign1_i),
        .TILE0_RXCHBONDMASTER0_IN       (tied_to_vcc_i),
        .TILE0_RXCHBONDMASTER1_IN       (tied_to_ground_i),
        .TILE0_RXCHBONDSLAVE0_IN        (tied_to_ground_i),
        .TILE0_RXCHBONDSLAVE1_IN        (tied_to_vcc_i),
        .TILE0_RXENCHANSYNC0_IN         (tile0_rxenchansync0_i),
        .TILE0_RXENCHANSYNC1_IN         (tile0_rxenchansync1_i),
        //------------- Receive Ports - Comma Detection and Alignment --------------
        .TILE0_RXENMCOMMAALIGN0_IN      (tile0_rxenmcommaalign0_i),
        .TILE0_RXENMCOMMAALIGN1_IN      (tile0_rxenmcommaalign1_i),
        .TILE0_RXENPCOMMAALIGN0_IN      (tile0_rxenpcommaalign0_i),
        .TILE0_RXENPCOMMAALIGN1_IN      (tile0_rxenpcommaalign1_i),
        //----------------- Receive Ports - RX Data Path interface -----------------
        .TILE0_RXDATA0_OUT              (tile0_rxdata0_i),
        .TILE0_RXDATA1_OUT              (tile0_rxdata1_i),
        .TILE0_RXUSRCLK0_IN             (tile0_txusrclk0_i),
        .TILE0_RXUSRCLK1_IN             (tile0_txusrclk0_i),
        .TILE0_RXUSRCLK20_IN            (tile0_txusrclk20_i),
        .TILE0_RXUSRCLK21_IN            (tile0_txusrclk20_i),
        //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        .TILE0_RXEQMIX0_IN              (tile0_rxeqmix0_i),
        .TILE0_RXEQMIX1_IN              (tile0_rxeqmix1_i),
        .TILE0_RXN0_IN                  (RXN_IN[0]),
        .TILE0_RXN1_IN                  (RXN_IN[1]),
        .TILE0_RXP0_IN                  (RXP_IN[0]),
        .TILE0_RXP1_IN                  (RXP_IN[1]),
        //-------------------------- TX/RX Datapath Ports --------------------------
        .TILE0_GTPCLKOUT0_OUT           (tile0_gtpclkout0_i),
        .TILE0_GTPCLKOUT1_OUT           (tile0_gtpclkout1_i),
        //----------------- Transmit Ports - 8b10b Encoder Control -----------------
        .TILE0_TXCHARISK0_IN            (tile0_txcharisk0_i),
        .TILE0_TXCHARISK1_IN            (tile0_txcharisk1_i),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .TILE0_TXDATA0_IN               (tile0_txdata0_i),
        .TILE0_TXDATA1_IN               (tile0_txdata1_i),
        .TILE0_TXOUTCLK0_OUT            (tile0_txoutclk0_i),
        .TILE0_TXOUTCLK1_OUT            (tile0_txoutclk1_i),
        .TILE0_TXUSRCLK0_IN             (tile0_txusrclk0_i),
        .TILE0_TXUSRCLK1_IN             (tile0_txusrclk0_i),
        .TILE0_TXUSRCLK20_IN            (tile0_txusrclk20_i),
        .TILE0_TXUSRCLK21_IN            (tile0_txusrclk20_i),
        //------------- Transmit Ports - TX Driver and OOB signalling --------------
        .TILE0_TXDIFFCTRL0_IN           (tile0_txdiffctrl0_i),
        .TILE0_TXDIFFCTRL1_IN           (tile0_txdiffctrl1_i),
        .TILE0_TXN0_OUT                 (TXN_OUT[0]),
        .TILE0_TXN1_OUT                 (TXN_OUT[1]),
        .TILE0_TXP0_OUT                 (TXP_OUT[0]),
        .TILE0_TXP1_OUT                 (TXP_OUT[1]),
        .TILE0_TXPREEMPHASIS0_IN        (tile0_txpreemphasis0_i),
        .TILE0_TXPREEMPHASIS1_IN        (tile0_txpreemphasis1_i)


    );
   //-------------------------------------------------------------------------------------------------------------------
   // above here should be copy pasted from s6_gtpwizard_v1-11_top.v
   //-------------------------------------------------------------------------------------------------------------------

endmodule
