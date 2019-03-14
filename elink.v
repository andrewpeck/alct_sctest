// file: elink_o.v
// (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//----------------------------------------------------------------------------

module elink_o #(
   // width of the data for the system
   parameter sys_w = 1,
   // width of the data for the device
   parameter dev_w = 8)
 (
   // From the device out to the system
   input  [dev_w-1:0] DATA_OUT_FROM_DEVICE,
   output [sys_w-1:0] DATA_OUT_TO_PINS_P,
   output [sys_w-1:0] DATA_OUT_TO_PINS_N,
   input              CLK_DIV, // slow clock input
   input              SERDES_CLOCK, // fast clock input
   input              SERDES_STROBE,
   input              IO_RESET
);

  localparam         num_serial_bits = dev_w/sys_w;
  // Signal declarations
  ////------------------------------
  wire               clock_enable = 1'b1;
  // Before the buffer
  wire   [sys_w-1:0] data_out_to_pins_int;
  // Between the delay and serdes
  wire   [sys_w-1:0] data_out_to_pins_predelay;
  // Array to use intermediately from the serdes to the internal
  //  devices. bus "0" is the leftmost bus
  wire [sys_w-1:0]  oserdes_d[0:7];   // fills in starting with 7
  // Create the clock logic

  // We have multiple bits- step over every bit, instantiating the required elements
  genvar pin_count;
  genvar slice_count;
  generate for (pin_count = 0; pin_count < sys_w; pin_count = pin_count + 1) begin: pins
    // Instantiate the buffers
    ////------------------------------
    // Instantiate a buffer for every bit of the data bus
    OBUFDS
      #(.IOSTANDARD ("PPDS_33"))
     obufds_inst
       (.O          (DATA_OUT_TO_PINS_P  [pin_count]),
        .OB         (DATA_OUT_TO_PINS_N  [pin_count]),
        .I          (data_out_to_pins_int[pin_count]));

    // Instantiate the delay primitive
    ////-------------------------------
    IODELAY2
     #(.DATA_RATE                  ("SDR"),
       .ODELAY_VALUE               (0),
       .IDELAY_TYPE                ("FIXED"),
       .COUNTER_WRAPAROUND         ("STAY_AT_LIMIT"),
       .DELAY_SRC                  ("ODATAIN"),
       .SERDES_MODE                ("NONE"),
       .SIM_TAPDELAY_VALUE         (75))
     iodelay2_bus
      (
       // required datapath
       .T                      (1'b0),
       .DOUT                   (data_out_to_pins_int     [pin_count]),
       .ODATAIN                (data_out_to_pins_predelay[pin_count]),
       // inactive data connections
       .IDATAIN                (1'b0),
       .TOUT                   (),
       .DATAOUT                (),
       .DATAOUT2               (),
       // connect up the clocks
       .IOCLK0                 (1'b0),                 // No calibration needed
       .IOCLK1                 (1'b0),                 // No calibration needed
       // Tie of the variable delay programming
       .CLK                    (1'b0),
       .CAL                    (1'b0),
       .INC                    (1'b0),
       .CE                     (1'b0),
       .BUSY                   (),
       .RST                    (1'b0));


     // Instantiate the serdes primitive
     ////------------------------------
     // local wire only for use in this generate loop
     wire cascade_ms_d;
     wire cascade_ms_t;
     wire cascade_sm_d;
     wire cascade_sm_t;

     // declare the oserdes
     OSERDES2 #(
        .DATA_RATE_OQ ("SDR"),
        .DATA_RATE_OT   ("SDR"),
        .TRAIN_PATTERN  (0),
        .DATA_WIDTH     (num_serial_bits),
        .SERDES_MODE    ("MASTER"),
        .OUTPUT_MODE    ("SINGLE_ENDED")
      )
      oserdes2_master (
        .D1         (oserdes_d[3][pin_count]),
        .D2         (oserdes_d[2][pin_count]),
        .D3         (oserdes_d[1][pin_count]),
        .D4         (oserdes_d[0][pin_count]),
        .T1         (1'b0),
        .T2         (1'b0),
        .T3         (1'b0),
        .T4         (1'b0),
        .SHIFTIN1   (1'b1),
        .SHIFTIN2   (1'b1),
        .SHIFTIN3   (cascade_sm_d),
        .SHIFTIN4   (cascade_sm_t),
        .SHIFTOUT1  (cascade_ms_d),
        .SHIFTOUT2  (cascade_ms_t),
        .SHIFTOUT3  (),
        .SHIFTOUT4  (),
        .TRAIN      (1'b0),
        .OCE        (clock_enable),
        .CLK0       (SERDES_CLOCK),
        .CLK1       (1'b0),
        .CLKDIV     (CLK_DIV),
        .OQ         (data_out_to_pins_predelay[pin_count]),
        .TQ         (),
        .IOCE       (SERDES_STROBE),
        .TCE        (clock_enable),
        .RST        (IO_RESET)
     );


     OSERDES2
       #(.DATA_RATE_OQ   ("SDR"),
         .DATA_RATE_OT   ("SDR"),
         .DATA_WIDTH     (num_serial_bits),
         .SERDES_MODE    ("SLAVE"),
         .TRAIN_PATTERN  (0),
         .OUTPUT_MODE    ("SINGLE_ENDED"))
      oserdes2_slave
       (.D1         (oserdes_d[7][pin_count]),
        .D2         (oserdes_d[6][pin_count]),
        .D3         (oserdes_d[5][pin_count]),
        .D4         (oserdes_d[4][pin_count]),
        .T1         (1'b0),
        .T2         (1'b0),
        .T3         (1'b0),
        .T4         (1'b0),
        .SHIFTIN1   (cascade_ms_d),
        .SHIFTIN2   (cascade_ms_t),
        .SHIFTIN3   (1'b1),
        .SHIFTIN4   (1'b1),
        .SHIFTOUT1  (),
        .SHIFTOUT2  (),
        .SHIFTOUT3  (cascade_sm_d),
        .SHIFTOUT4  (cascade_sm_t),
        .TRAIN      (1'b0),
        .OCE        (clock_enable),
        .CLK0       (SERDES_CLOCK),
        .CLK1       (1'b0),
        .CLKDIV     (CLK_DIV),
        .OQ         (),
        .TQ         (),
        .IOCE       (SERDES_STROBE),
        .TCE        (clock_enable),
        .RST        (IO_RESET));
     // Concatenate the serdes outputs together. Keep the timesliced
     //   bits together, and placing the earliest bits on the right
     //   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
     //       the output will be 3210, 7654, ...
     ////---------------------------------------------------------
     for (slice_count = 0; slice_count < num_serial_bits; slice_count = slice_count + 1) begin: out_slices
        // This places the first data in time on the right
        assign oserdes_d[8-slice_count-1] = DATA_OUT_FROM_DEVICE[slice_count];
        // To place the first data in time on the left, use the
        //   following code, instead
        // assign oserdes_d[slice_count] =
        //    DATA_OUT_FROM_DEVICE[slice_count];
     end
  end
  endgenerate

endmodule
