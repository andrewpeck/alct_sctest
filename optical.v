module optical_lx150t (

  input        clock, // 40 mhz logic clock

  output [1:0] tx_p,
  output [1:0] tx_n,

  input        refclk_p,
  input        refclk_n,

  input        reset

);

  wire tx_clk80;

  wire [3:0] tx_diffctrl    = 4'd8;  // check this value against vttx datasheet
  wire [2:0] tx_preemphasis = 3'd0;  // check this value

  wire inj_err = 1'b0;

  wire strt_ltncy;

  wire [1:0] gtp_reset_done;

  wire [63:0] bonding_sequence  = {8'h1C, 8'hFE, 8'hFB, 8'hDC, 32'h0};

  // CHAN_BOND_1_MAX_SKEW and CHAN_BOND_2_MAX_SKEW are used to set the
  // maximum skew allowed for channel bonding sequences 1 and 2, respectively. The
  // maximum skew range is 1 to 14. The channel bond skew must be set no higher than the
  // minimum distance allowed between channel bonding sequences in the data stream. This
  // minimum distance is determined by the protocol being used.

  // keep a minimum distance netween successive channel bonding sequences
  reg [4:0] bonding_frame_cnt = 0;
  always @(posedge clock) begin
    if (reset || !(&gtp_reset_done)) bonding_frame_cnt <= 0;
    else                             bonding_frame_cnt <= bonding_frame_cnt + 1'b1;
  end

  // send a number of bonding sequences at startup before sending normal data
  reg [7:0] bonding_sequence_cnt  = 0;

  wire bonding_done  = &bonding_sequence_cnt;

  always @(posedge clock) begin
    if      (reset || !(&gtp_reset_done))         bonding_sequence_cnt <= 0;
    else if (&bonding_frame_cnt && !bonding_done) bonding_sequence_cnt <= bonding_sequence_cnt + 1'b1;
  end

  wire [63:0] data_bonding = (&bonding_frame_cnt) ? bonding_sequence : 64'h0;

  reg [63:0] tx_data;
  reg [7:0] tx_iskchar;

  wire [47:0] prbs_data;

  //--------------------------------------------------------------------------------------------------------------------
  // periodically (every ~1 second) restart the prbs and re-send the start-of-sequence marker
  // -- lets the receiving board "catch" the data without relying oon being active and connected at startup
  //--------------------------------------------------------------------------------------------------------------------

  parameter clock_count_max = 'h2638e98;
  reg [31:0] clock_counter;
  reg restart_sequence;
  always @(posedge clock) begin
    if      (reset)
      clock_counter <= 0;
    else if (clock_counter == clock_count_max)
      clock_counter <= 0;
    else
      clock_counter <= clock_counter + 1'b1;
  end

  always @(posedge clock) begin
    if (clock_counter == clock_count_max)
      restart_sequence <= 1'b1;
    else
      restart_sequence <= 1'b0;
  end


  //--------------------------------------------------------------------------------------------------------------------
  // PRBS
  //--------------------------------------------------------------------------------------------------------------------

  PRBS_tx prbs  (
    .GEN_CLK    ( clock),
    .RST        ( reset || !(&gtp_reset_done) || !(bonding_done) || restart_sequence), // keep the prbs off until the gtp is done
    .INJ_ERR    ( inj_err),
    .PRBS       ( prbs_data[47:0]), // 48 bit data
    .STRT_LTNCY ( strt_ltncy) // first pattern starting after reset
  );

  always @(posedge clock) begin
    if (!bonding_done) begin
      tx_data    <=  data_bonding;
      tx_iskchar <=  (&bonding_frame_cnt)  ? 8'b00001111 : 8'b00000000;
    end
    else if (strt_ltncy) begin
        tx_data    <= 64'hFCFCFCFCFCFCFCFC;
        tx_iskchar <= 8'b11111111;
    end
    else begin
        tx_data    <= {prbs_data[47:0], 16'hBC50};
        tx_iskchar <= 8'b00000011;
    end
  end

  // need to properly transfer from CMS40 to async80

  wire [31:0] tx_data_sync;
  wire [3:0]  tx_iskchar_sync;

  gtp_data_fifo data_synchronizer (
    .rst(reset),         // input rst
    .wr_clk(clock),      // input wr_clk
    .rd_clk(tx_clk80),   // input rd_clk
    .din(tx_data),       // input [63 : 0] din
    .wr_en(1'b1),        // input wr_en
    .rd_en(1'b1),        // input rd_en
    .dout(tx_data_sync), // output [31 : 0] dout
    .full(),             // output full
    .empty()             // output empty
  );

  gtp_kchar_fifo kchar_synchronizer (
    .rst(reset),            // input rst
    .wr_clk(clock),         // input wr_clk
    .rd_clk(tx_clk80),      // input rd_clk
    .din(tx_iskchar),       // input [63 : 0] din
    .wr_en(1'b1),           // input wr_en
    .rd_en(1'b1),           // input rd_en
    .dout(tx_iskchar_sync), // output [31 : 0] dout
    .full(),                // output full
    .empty()                // output empty
  );

  // TXCHARISK is set High to send TXDATA as an 8B/10B K
  // character. TXCHARISK should only be asserted for TXDATA
  // values representing valid K-characters.
  // TXCHARISK[3] corresponds to TXDATA[31:24]
  // TXCHARISK[2] corresponds to TXDATA[23:16]
  // TXCHARISK[1] corresponds to TXDATA[15:8]
  // TXCHARISK[0] corresponds to TXDATA[7:0]

  s6_gtp_dual_wrapper gtp_dual(

    .reset (reset),

    .tx_is_kchar (tx_iskchar_sync[3:0]),

    .tx_powerdown (2'b00),

    .tx_data0 (tx_data_sync [31:0]),
    .tx_data1 (tx_data_sync [31:0]),

    .tx_diffctrl (tx_diffctrl),
    .tx_preemphasis (tx_preemphasis),

    .refclk_p (refclk_p),
    .refclk_n (refclk_n),

    .tx_p (tx_p),
    .tx_n (tx_n),

    .tx_clk80 (tx_clk80),

    .reset_done (gtp_reset_done)
  );

endmodule
