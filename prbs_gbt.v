//`define FIXED_PATTERN

module prbs_gbt (

  input gbt_clk40_p, // 40 mhz e-link frame clock (from GBTx)
  input gbt_clk40_n, // 40 mhz e-link frame clock (from GBTx)
   
  input gbt_clk320_p, // 320 mhz e-link frame clock (from GBTx)
  input gbt_clk320_n, // 320 mhz e-link frame clock (from GBTx)

  output [13:0] elink_p, // 14 e-link outputs
  output [13:0] elink_n, // 14 e-link outputs

  input gbt_txrdy,

  input reset


);

wire [111:0] prbs_data_tx;
wire [111:0] prbs_data_expect;
wire [111:0] data_expect_masked;

parameter [15:0] inj_err_counter_max=88;
reg [31:0] inj_err_counter=0;
// wire inj_err = (inj_err_counter == inj_err_counter_max);

reg inj_err = 1;
always @(posedge clock) begin

  if      (reset) inj_err <= 1'b1;
  else            inj_err <= 1'b0;

  if      (reset)   inj_err_counter <= 0;
  else if (inj_err) inj_err_counter <= 0;
  else              inj_err_counter <= inj_err_counter + 1'b1;
end

wire [7:0] pattern [15:0] = { 8'hFF, 8'hEE, 8'hDD, 8'hCC, 8'hBB, 8'hAA, 8'h99, 8'h88, 8'h77, 8'h66, 8'h55, 8'h44, 8'h33, 8'h22, 8'h11, 8'h00};

reg [3:0] pat_cnt_tx=0;
reg [3:0] pat_cnt_expect=4'hF;

reg start_pattern_received=0;
reg start_pattern_received_r1=0;
reg start_pattern_received_r2=0;

reg [9:0] rx_start_frame_counter=0;

always @(posedge clock) begin

  if (reset) pat_cnt_tx <= 0;
  else       pat_cnt_tx <= pat_cnt_tx + 1'b1;

  if (reset || start_pattern_received) pat_cnt_expect <= 4'hF;
  else                                 pat_cnt_expect <= pat_cnt_expect + 1'b1;

  if      (reset || !start_pattern_received)  rx_start_frame_counter <= tx_start_frame_counter_max;
  else if (rx_start_frame_counter>0)           rx_start_frame_counter <= rx_start_frame_counter - 1'b1;

end

(* keep = "true" *)
wire [7:0] pat_data   = pattern[pat_cnt_tx];
//wire [7:0] pat_data   = (8'h55 & {8{inj_err}}) ^ pattern[pat_cnt_tx];
(* keep = "true" *)
wire [7:0] pat_expect = pattern[pat_cnt_expect];

// add a hold until GBT rx ready

wire [111:0] data_tx;
wire [111:0] data_expect;

`ifdef FIXED_PATTERN
(* keep = "true" *)
  assign data_tx = {14{pat_data}};
(* keep = "true" *)
  assign data_expect= {14{pat_expect}};
  parameter start_pattern = 112'h0000000000000000000000000000;
`else
  assign data_tx = prbs_data_tx;
  assign data_expect= prbs_data_expect;
  parameter start_pattern = 112'h5555555555555555555555555555;
`endif

optical_gbt #(
  .elink_is_valid (elink_is_valid)
)
optical (

  .gbt_clk40_p (gbt_clk40_p),
  .gbt_clk40_n (gbt_clk40_n),
  
  .gbt_clk320_p (gbt_clk320_p),
  .gbt_clk320_n (gbt_clk320_n),

  .data_i ( data_tx [111:0]), // 112 bit data input

  .elink_p (elink_p), // 14 e-link outputs
  .elink_n (elink_n), // 14 e-link outputs

  .gbt_txrdy (gbt_txrdy),

  .clock_out (clock),

  .reset   ( reset)

);

parameter tx_sequence_counter_max = 'h2638e34;
//parameter tx_sequence_counter_max = 'd2000;

parameter tx_start_frame_counter_max = 256;

reg [9:0] tx_start_frame_counter=0;
reg [31:0] tx_sequence_counter=0;

wire tx_sequence_reset = (tx_sequence_counter == tx_sequence_counter_max);

always @(posedge clock) begin
  if      (reset)             tx_sequence_counter <= 0;
  else if (tx_sequence_reset) tx_sequence_counter <= 0;
  else                        tx_sequence_counter <= tx_sequence_counter + 1'b1;

  if      (reset || tx_sequence_reset)  tx_start_frame_counter <= tx_start_frame_counter_max;
  else if (tx_start_frame_counter>0)    tx_start_frame_counter <= tx_start_frame_counter - 1'b1;
end

wire tx_prbs_reset  = (reset | (tx_start_frame_counter > 0));

PRBS_112 # ( .start_pattern ( start_pattern))
prbs_tx (
  .GEN_CLK    ( clock),
  .RST        ( tx_prbs_reset), // keep the prbs off until the gtp is done
  .INJ_ERR    ( inj_err),
  .PRBS       ( prbs_data_tx[111:0]), // 48 bit data
  .STRT_LTNCY ( strt_ltncy) // first pattern starting after reset
);

PRBS_112 # ( .start_pattern ( start_pattern))
prbs_expect (
  .GEN_CLK    ( clock),
  .RST        (rx_start_frame_counter == 10'd1), // keep the prbs off until the gtp is done
  .INJ_ERR    ( 1'b0),
  .PRBS       ( prbs_data_expect [111:0]), // 48 bit data
  .STRT_LTNCY (strt_ltncy_expect )         // first pattern starting after reset
);

parameter [13:0] elink_is_valid = { // assign ELINKs to BUFIO2 clocks based on half-banks (consult schematics)
  1'b1, // 13
  1'b1, // 12
  1'b1, // 11
  1'b1, // 10
  1'b1, // 9
  1'b1, // 8
  1'b1, // 7
  1'b1, // 6
  1'b1, // 5
  1'b1, // 4
  1'b1, // 3
  1'b1, // 2
  1'b1, // 1
  1'b1  // 0
};


wire [111:0] start_pattern_masked;

reg  [111:0] data_tx_delay_r0;
reg  [111:0] data_tx_delay_r1;
reg  [111:0] data_tx_delayed;

wire [111:0] data_tx_masked;

reg  [111:0] data_mismatch_mask;

reg [31:0] error_frame_count [13:0];
reg [31:0] good_frame_count  [13:0];

always @(posedge clock) begin
  data_tx_delay_r0 <= data_tx_masked;
  data_tx_delay_r1 <= data_tx_delay_r0;
  data_tx_delayed  <= data_tx_delay_r1;

  start_pattern_received    <= (start_pattern_masked==data_tx_masked);
  start_pattern_received_r1 <= start_pattern_received;
  start_pattern_received_r2 <= start_pattern_received_r1;

  data_mismatch_mask <= (data_expect_masked ^ data_tx_delayed);
end

wire [13:0] link_error;
wire [13:0] link_good;

wire cnt_reset=0;

genvar ilink;
generate
  for (ilink=0; ilink<14; ilink=ilink+1) begin: linkloop

    initial good_frame_count  [ilink]  = 0;
    initial error_frame_count [ilink] = 0;

    assign start_pattern_masked     [(ilink+1)*8-1:ilink*8] = {8{elink_is_valid[ilink]}} & start_pattern [(ilink+1)*8-1:ilink*8];
    assign data_tx_masked           [(ilink+1)*8-1:ilink*8] = {8{elink_is_valid[ilink]}} & data_tx       [(ilink+1)*8-1:ilink*8];
    assign data_expect_masked       [(ilink+1)*8-1:ilink*8] = {8{elink_is_valid[ilink]}} & data_expect   [(ilink+1)*8-1:ilink*8];

    assign link_error[ilink] = !start_pattern_received_r2 &  (|data_mismatch_mask [ilink*8+:8]);
    assign link_good [ilink] = !start_pattern_received_r2 & ~(|data_mismatch_mask [ilink*8+:8]);

    always @(posedge clock) begin

      if      (cnt_reset)                                    good_frame_count[ilink] <= 0;
      else if (elink_is_valid[ilink] && link_good   [ilink]) good_frame_count[ilink] <= good_frame_count[ilink]+1'b1;

      if      (cnt_reset)                                   error_frame_count[ilink] <= 0;
      else if (elink_is_valid[ilink] && link_error [ilink]) error_frame_count[ilink] <= error_frame_count[ilink]+1'b1;

    end

  end
endgenerate

(* keep = "true" *)
wire clock_lac;

reg lac_pos=0;
reg lac_neg=0;

always @(posedge clock) lac_pos <= ~lac_pos;
always @(negedge clock) lac_neg <= ~lac_neg;

assign clock_lac = lac_pos ^ lac_neg;

endmodule
