
module optical_lx150t (

  input        clock, // 40 mhz logic clock

  output [1:0] tx_p,
  output [1:0] tx_n,

  input        refclk_p,
  input        refclk_n,

  input        reset_i

);

  parameter SIMULATION = 0;

  wire [1:0] rx_p = 2'b11;
  wire [1:0] rx_n = 2'b00;
  //
  // from here should be common with DMB:
  //-------------------

   wire clock_async;

   wire resetdone;

   wire [35:0] csp_control0;
   wire [35:0] csp_control1;

   reg  [403:0] csp_data;
   reg  [5:0]   csp_trig;

   wire [15:0] vio_out;

   // `define USE_CHIPSCOPE

   `ifdef USE_CHIPSCOPE
   csp_controller alct_optical_test_controller (
      .CONTROL0(csp_control0), // INOUT BUS [35:0]
      .CONTROL1(csp_control1)  // INOUT BUS [35:0]
   );

   csp_alct_optical csp_node_alct ( 
      .CONTROL                       (csp_control0), // INOUT BUS [35:0]
      .CLK                           (clock_async), // IN
      .DATA                          (csp_data),
      .TRIG0                         (csp_trig)
   );

   chipscope_vio YourInstanceName (
      .CONTROL  (csp_control1), // INOUT BUS [35:0]
      .CLK      (clock), // IN
      .SYNC_OUT (vio_out) // OUT BUS [7:0]
   );

   wire inj_err_vio              = ~SIMULATION & vio_out[15];

   wire [3:0] txdiffctrl_vio     = vio_out[14:11];
   wire [2:0] txpreemphasis_vio  = vio_out[10:8];

   wire reset_cnt                = ~simulation & vio_out[0];
   wire vio_ctrl_tx              = ~simulation & vio_out[1];
   wire reset_vio                = ~simulation & vio_out[2];
   `else
   wire inj_err_vio              = 0;
   wire [3:0] txdiffctrl_vio     = 0;
   wire [2:0] txpreemphasis_vio  = 0;
   wire reset_cnt                = 1'b0;
   wire vio_ctrl_tx              = 1'b0;
   wire reset_vio                = 1'b0;
  `endif

   wire reset = reset_i;



   wire [1:0] bonding_frame_received;

   wire [1:0] rxchanisaligned;

   wire [15:0] rx_data          [1:0];
   reg  [15:0] rx_data_r0       [1:0];
   reg  [31:0] rx_data_r1       [1:0];
   reg  [47:0] rx_data_r2       [1:0];
   reg  [63:0] rx_data_r3       [1:0];

   wire [1:0 ] rx_charisk       [1:0];
   reg  [1:0 ] rx_charisk_r0    [1:0];
   reg  [3:0 ] rx_charisk_r1    [1:0];
   reg  [5:0 ] rx_charisk_r2    [1:0];
   reg  [7:0 ] rx_charisk_r3    [1:0];

   reg [1:0] rx_frame [1:0];

   wire [63:0] rx_data_sync     [1:0];
   reg  [63:0] rx_charisk_dly_1    [1:0];
   reg  [63:0] rx_charisk_dly_2    [1:0];
   reg  [63:0] rx_charisk_dly_3    [1:0];
   reg  [63:0] rx_charisk_dly_4    [1:0];
   reg  [63:0] rx_data_dly_1    [1:0];
   reg  [63:0] rx_data_dly_2    [1:0];
   reg  [63:0] rx_data_dly_3    [1:0];
   reg  [63:0] rx_data_dly_4    [1:0];

   (* keep = "true" *) wire [63:0] rx_data0 = rx_data_dly_4[0];
   (* keep = "true" *) wire [63:0] rx_data1 = rx_data_dly_4[1];

   wire [7:0]  rx_charisk_sync [1:0];

   wire [47:0] prbs_data [1:0];

   (* keep = "true" *) wire [1:0] strt_ltncy_rx;

   reg  [63:0] tx_data;
   reg  [7:0]  txcharisk;

   wire [15:0] tx_data_sync;
   wire [1:0]  tx_charisk_sync;

   wire [47:0] prbs_data_tx;
   reg  [63:0] rx_expect [1:0];
   (* keep = "true" *) wire [63:0] rx_expect0 = rx_expect[0];
   (* keep = "true" *) wire [63:0] rx_expect1 = rx_expect[1];

   wire tx_clk160, rx_clk160;

   //--------------------------------------------------------------------------------------------------------------------
   // PRBS RX
   //--------------------------------------------------------------------------------------------------------------------

   (* keep = "true" *) reg   [1:0] waiting_for_rx_start = 2'b11;
   (* keep = "true" *) reg   [1:0] waiting_for_bonding  = 2'b11;
   (* keep = "true" *) reg   [1:0] rx_check_ready       = 2'b00;

   (* keep = "true" *) reg  [1:0] restart_sequence=0;
   (* keep = "true" *) wire [1:0] start_sequence_detect;
   (* keep = "true" *) wire [1:0] reset_rx_prbs;
   (* keep = "true" *) wire reset_tx_prbs = reset || !resetdone || reset_vio;
   reg  [1:0] reset_rx_prbs_dly1;

   (* keep = "true" *)
   reg  [1:0] link_error=0;

   reg [1:0] cnt_maxed;

   (* keep = "true" *)
   reg [31:0] error_frame_count [1:0];
   initial    error_frame_count [0] = 0;
   initial    error_frame_count [1] = 0;

   (* keep = "true" *)
   reg [41:0] good_frame_count [1:0];
   initial    good_frame_count [0] = 0;
   initial    good_frame_count [1] = 0;

   PRBS_tx prbs0  (
      .GEN_CLK    (clock_async),      //
      .RST        (reset_rx_prbs[0]), // keep the prbs off until the gtp is done
      .INJ_ERR    (inj_err_vio),      //
      .PRBS       (prbs_data[0]),     // 48 bit data
      .STRT_LTNCY (strt_ltncy_rx[0])  // first pattern starting after reset
   );

   PRBS_tx prbs1 (
      .GEN_CLK    (clock_async),            //
      .RST        (reset_rx_prbs[1]), // keep the prbs off until the gtp is done
      .INJ_ERR    (1'b0),             //
      .PRBS       (prbs_data[1]),     // 48 bit data
      .STRT_LTNCY (strt_ltncy_rx[1])  // first pattern starting after reset
   );

   genvar i;
   generate
      for (i=0; i<2; i=i+1'b1) begin : i_loop
         assign reset_rx_prbs[i] = !resetdone || reset || restart_sequence[i] || waiting_for_rx_start[i];

         assign start_sequence_detect [i] = (rx_data_sync[i]==64'hFCFCFCFCFCFCFCFC) && (rx_charisk_sync[i]==8'hff);

         assign bonding_frame_received[i] = (rx_data_dly_4[i] == bonding_sequence) && (rx_charisk_dly_4[i] == 8'hf0);

         always @(posedge clock_async) begin

            // strobe once per cycle
            if (reset)
               rx_check_ready[i] <= 1'b0;
            else if (bonding_frame_received[i])
               rx_check_ready[i] <= rxchanisaligned[i] & ~(waiting_for_rx_start[i] | waiting_for_bonding[i]);

            if (reset)
               rx_expect[i] <= ~64'hFCFCFCFCFCFCFCFC; // initialize to a stupid value to prevent trimming for chipscope
            else
               rx_expect[i] <= strt_ltncy_rx[i] ? (64'hFCFCFCFCFCFCFCFC) : ({prbs_data[i],16'h50bc});

            reset_rx_prbs_dly1 [i] <= reset_rx_prbs [i];

            rx_data_dly_1[i] <= rx_data_sync[i];
            rx_data_dly_2[i] <= rx_data_dly_1[i];
            rx_data_dly_3[i] <= rx_data_dly_2[i];
            rx_data_dly_4[i] <= rx_data_dly_3[i];

            rx_charisk_dly_1[i] <= rx_charisk_sync[i];
            rx_charisk_dly_2[i] <= rx_charisk_dly_1[i];
            rx_charisk_dly_3[i] <= rx_charisk_dly_2[i];
            rx_charisk_dly_4[i] <= rx_charisk_dly_3[i];

            if      (reset)                    waiting_for_rx_start[i] <= 1'b1;
            else if (start_sequence_detect[i]) waiting_for_rx_start[i] <= 1'b0;

            if      (reset)                     waiting_for_bonding[i] <= 1'b1;
            else if (bonding_frame_received[i]) waiting_for_bonding[i] <= 1'b0;

         end

         always @(posedge clock_async) begin
            restart_sequence[i] <=  start_sequence_detect[i];
            link_error[i]       <= !restart_sequence[i] && rx_check_ready[i] && ~bonding_frame_received[i] && |(rx_expect[i] ^ rx_data_dly_4[i]);
         end

         always @(posedge clock_async) begin

            cnt_maxed[i] <= (&error_frame_count[i]) | (&good_frame_count[i]);

            if      (reset_cnt || reset || !rx_check_ready[i])  error_frame_count[i] <= 0;
            else if (cnt_maxed[i])                              error_frame_count[i] <= error_frame_count[i];
            else if (link_error[i])                             error_frame_count[i] <= error_frame_count[i] + 1'b1;
            else                                                error_frame_count[i] <= error_frame_count[i];

            if      (reset_cnt || reset || !rx_check_ready[i])  good_frame_count[i] <= 0;
            else if (cnt_maxed[i])                              good_frame_count[i] <= good_frame_count[i];
            else if (!link_error[i])                            good_frame_count[i] <= good_frame_count[i] + 1'b1;
            else                                                good_frame_count[i] <= good_frame_count[i];

         end

      end // loop

   endgenerate

   //--------------------------------------------------------------------------------------------------------------------
   // PRBS for Loopback
   //--------------------------------------------------------------------------------------------------------------------

   // periodically (every ~1 second) restart the prbs and re-send the start-of-sequence marker
   // -- lets the receiving board "catch" the data without relying oon being active and connected at startup

   // parameter clock_count_max = 'h2638e98;
   parameter clock_count_max = 'h64;

   (* keep = "true" *) reg restart_tx_sequence=0;
   (* keep = "true" *) reg [1:0] restart_rx_sequence = 2'b00;
   reg [31:0] clock_counter_tx=0;;

   always @(posedge clock_async) begin
      //
      if      (reset_tx_prbs)                       clock_counter_tx <= 0;
      else if (clock_counter_tx == clock_count_max) clock_counter_tx <= 0;
      else                                          clock_counter_tx <= clock_counter_tx + 1'b1;
      //
      if      (reset_tx_prbs)                       restart_tx_sequence <= 1'b1;
      else if (clock_counter_tx == clock_count_max) restart_tx_sequence <= 1'b1;
      else                                          restart_tx_sequence <= 1'b0;
   end

   reg [31:0] clock_counter_rx [1:0];
   generate
      for (i=0; i < 2; i=i+1)
      begin: iloop_cnt_rx
         initial clock_counter_rx [i] = 0;

      always @(posedge clock_async) begin
         //
         if      (reset_tx_prbs ||start_sequence_detect[i]) clock_counter_rx[i] <= 0;
         else if (clock_counter_rx[i] == clock_count_max)   clock_counter_rx[i] <= 0;
         else                                               clock_counter_rx[i] <= clock_counter_rx[i] + 1'b1;
         //
         if    (clock_counter_rx[i] == clock_count_max) restart_rx_sequence[i] <= 1'b1;
         else                                           restart_rx_sequence[i] <= 1'b0;
      end

      end
   endgenerate

   reg       inj_err_tx = 1'b0;
   reg [1:0] inj_err_tx_r = 2'b00;
   always @(posedge clock_async) begin
      inj_err_tx_r <= {inj_err_tx_r[0], inj_err_vio};
      inj_err_tx <= (inj_err_tx_r == 2'b01); // trigger on rising edge for single clock error
   end

   PRBS_tx prbs  (
      .GEN_CLK    ( clock_async),
      .RST        ( reset_tx_prbs || restart_tx_sequence), // keep the prbs off until the gtx is done
      .INJ_ERR    ( inj_err_tx ),
      .PRBS       ( prbs_data_tx[47:0]), // 48 bit data
      .STRT_LTNCY ( strt_ltncy) // first pattern starting after reset
   );

   wire [63:0] bonding_sequence  = {8'hDC, 8'hFB, 8'hFE, 8'h1C, 32'h99999999};

   always @(posedge clock_async) begin

      if (clock_counter_tx==1) begin
         tx_data   <=  bonding_sequence;
         txcharisk <=  8'b11110000;
      end
      else if (strt_ltncy) begin
         tx_data    <= 64'hFCFCFCFCFCFCFCFC;
         txcharisk <= 8'b11111111;
      end
      else begin
         tx_data    <= {prbs_data_tx[47:0], 16'h50bc};
         txcharisk <= 8'b00000001;
      end
   end

   // need to properly transfer from CMS40

   (* keep = "true" *) wire tx_fifo_empty;

   fifo_cms_to_gtx data_synchronizer_out (
      .rst                           (reset),                           // input rst
      .wr_clk                        (clock_async),                           // input wr_clk
      .rd_clk                        (tx_clk160),                        // input rd_clk
      .din                           ({
                                       tx_data[15: 0],txcharisk[1:0] ,
                                       tx_data[31:16],txcharisk[3:2] , //
                                       tx_data[47:32],txcharisk[5:4] , //
                                       tx_data[63:48],txcharisk[7:6]   // input
                                       }),                             //
      .wr_en                         (1'b1),                           // input wr_en
      .rd_en                         (1'b1),                           // input rd_en
      .dout                          ({tx_data_sync,tx_charisk_sync}), // output [15 : 0] dout
      .full                          (),                               // output full
      .empty                         (tx_fifo_empty)                   // output empty
   );


   generate
      for (i=0; i < 2; i=i+1)
      begin: iloop

         initial rx_frame [i] = 0;

         always @(posedge rx_clk160) begin

            if ((rx_data[i][15:0]==16'h50bc) && (rx_charisk[i][1:0] == 2'b01))
               rx_frame[i] <= 2'd1;
            else
               rx_frame[i] <= rx_frame[i] + 1'b1;

            case (rx_frame[i])
               2'd0: rx_data_r0[i] <=  rx_data[i];
               2'd1: rx_data_r1[i] <= {rx_data[i], rx_data_r0[i]};
               2'd2: rx_data_r2[i] <= {rx_data[i], rx_data_r1[i]};
               2'd3: rx_data_r3[i] <= {rx_data[i], rx_data_r2[i]};
            endcase

            case (rx_frame[i])
               2'd0: rx_charisk_r0[i] <=  rx_charisk[i];
               2'd1: rx_charisk_r1[i] <= {rx_charisk[i], rx_charisk_r0[i]};
               2'd2: rx_charisk_r2[i] <= {rx_charisk[i], rx_charisk_r1[i]};
               2'd3: rx_charisk_r3[i] <= {rx_charisk[i], rx_charisk_r2[i]};
            endcase

         end

         fifo_gtx_to_cms data_synchronizer_rx (
            .rst                           (reset),                                 // input rst
            .wr_clk                        (rx_clk160),                              // input wr_clk
            .rd_clk                        (clock_async),                                 // input rd_clk
            .wr_en                         (rx_frame[i]==2'd0),                     // input wr_en
            .rd_en                         (1'b1),                                  // input rd_en
            .din                           ({rx_data_r3  [i], rx_charisk_r3  [i]}), // write 64 bits @ 40 MHz
            .dout                          ({rx_data_sync[i], rx_charisk_sync[i]}), // read  64 bits @ 40 MHz
            .full                          (),                                      // output full
            .empty                         ()                                       // output empty
         );

      end
   endgenerate

   // TXCHARISK is set High to send TXDATA as an 8B/10B K
   // character. TXCHARISK should only be asserted for TXDATA
   // values representing valid K-characters.
   // TXCHARISK[3] corresponds to TXDATA[31:24]
   // TXCHARISK[2] corresponds to TXDATA[23:16]
   // TXCHARISK[1] corresponds to TXDATA[15:8]
   // TXCHARISK[0] corresponds to TXDATA[7:0]

   //-------------------------------------------------------------------------------------------------------------------
   // ALCT Optical
   //-------------------------------------------------------------------------------------------------------------------

   wire [2:0] txpllrefseldy  = 3'd0;
   wire [2:0] rxpllrefseldy  = 3'd0;
   wire [2:0] rxeqmix        = 3'd0;

   wire [3:0] txdiffctrl_default     = 4'd6;
   wire [2:0] txpreemphasis_default  = 3'd0;

   wire [3:0] txdiffctrl     = vio_ctrl_tx ? txdiffctrl_vio     : txdiffctrl_default;
   wire [2:0] txpreemphasis  = vio_ctrl_tx ? txpreemphasis_vio  : txpreemphasis_default;

   reg rxenchansync = 0;
   always @(posedge clock) begin
      if (reset || !resetdone) rxenchansync = 1'b0;
      else                     rxenchansync = 1'b1;
   end

   reg rxenmcommaalign = 0;
   always @(posedge clock) begin
      if (reset || !resetdone) rxenmcommaalign = 1'b0;
      else                     rxenmcommaalign = 1'b1;
   end

   reg rxenpcommaalign = 0;
   always @(posedge clock) begin
      if (reset || !resetdone) rxenpcommaalign = 1'b0;
      else                     rxenpcommaalign = 1'b1;
   end

   always @(posedge clock_async) begin
   csp_data <= {
      rx_data1            [63:0], // 403-340
      rx_expect1          [63:0], // 339-276
      rx_data0            [63:0], // 275-212
      rx_expect0          [63:0], // 211-148
      good_frame_count [0][41:0], // 147-106
      good_frame_count [1][41:0], // 105-64
      error_frame_count[0][31:0], // 63-32
      error_frame_count[1][31:0]  // 0-31

      };

   csp_trig <= {

      link_error[1],       // 5
      link_error[0],       // 4
      strt_ltncy_rx[1],    // 3
      strt_ltncy_rx[0],    // 2
      restart_sequence[1], // 1
      restart_sequence[0]  // 0

      };

   end

   //-------------------------------------------------------------------------------------------------------------------
   // before here should be common with dmb
   //-------------------------------------------------------------------------------------------------------------------

   assign rx_clk160 = tx_clk160;

   s6_gtp_dual_wrapper #(
     .EXAMPLE_SIMULATION           (SIMULATION),
     .EXAMPLE_SIM_GTPRESET_SPEEDUP (SIMULATION)
   )
   gtp_dual(

     .reset (reset),

     .txcharisk (tx_charisk_sync),

     .rxcharisk0 (rx_charisk[0]),
     .rxcharisk1 (rx_charisk[1]),

     .txdiffctrl(txdiffctrl),

     .loopback (SIMULATION ? 3'b001 : 3'b000),

    // 000: Normal operation
    // 001: Near-End PCS Loopback
    // 010: Near-End PMA Loopback
    // 011: Reserved
    // 100: Far-End PMA Loopback
    // 101: Reserved
    // 110: Far-End PCS Loopback(1)

     .txpowerdown0 (1'b0),
     .txpowerdown1 (1'b0),

     .rxpowerdown0 (1'b0),
     .rxpowerdown1 (1'b0),

     .txpreemphasis (txpreemphasis[2:0]),

     .rxeqmix         (rxeqmix[1:0]),
     .rxenchansync    (rxenchansync),
     .rxenmcommaalign (rxenmcommaalign),
     .rxenpcommaalign (rxenpcommaalign),

     .tx_data0 (tx_data_sync [15:0]),
     .tx_data1 (tx_data_sync [15:0]),

     .rx_data0 (rx_data[0][15:0]),
     .rx_data1 (rx_data[1][15:0]),

     .refclk_p (refclk_p),
     .refclk_n (refclk_n),

     .tx_p (tx_p),
     .tx_n (tx_n),

     .rx_p (rx_p),
     .rx_n (rx_n),

     .tx_clk160 (tx_clk160),
     .tx_clk80  (tx_clk80),
     .tx_clk40 (clock_async),

     .rxchanisaligned (rxchanisaligned),

     .reset_done (resetdone)
   );

endmodule
