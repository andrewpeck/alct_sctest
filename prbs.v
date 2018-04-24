`timescale 1ns / 1ps

module PRBS_tx(
    input GEN_CLK,
    input RST,
    input INJ_ERR,
    output reg [47:0] PRBS,
    output reg STRT_LTNCY
);

parameter start_pattern = 48'hFFFFFF000000;

wire [23:0] lfsr;
wire [23:0] lfsr_a;
wire [23:0] lfsr_b;

reg rst1 = 1'b1;

wire rst_lfsr;
wire start_pat;

assign rst_lfsr = RST || rst1;

assign start_pat = rst1 & (!RST);  // start pat when reset goes low

always @(posedge GEN_CLK) begin

  rst1       <= RST;
  STRT_LTNCY <= start_pat;

  if (start_pat)
    PRBS <= start_pattern;
  else
    if(INJ_ERR)
      PRBS <= {lfsr_a,lfsr_b}^48'h608000400100;
    else
      PRBS <= {lfsr_a,lfsr_b};
end

// Linear Feedback Shift Register
// [24,23,22,17] Fibonacci Implementation

   lfsr_R24 #(.init_fill(24'h83B62E))
   tx_lfsra(
       .CLK(GEN_CLK),
       .RST(rst_lfsr),
       .LFSR(lfsr_a)
   );

   lfsr_R24 #(.init_fill(24'hE26B38))
   tx_lfsrb(
       .CLK(GEN_CLK),
       .RST(rst_lfsr),
       .LFSR(lfsr_b)
   );

endmodule

module PRBS_112 (
    input GEN_CLK,
    input RST,
    input INJ_ERR,
    output reg [111:0] PRBS,
    output reg STRT_LTNCY
);

parameter start_pattern = 112'hfeeeeeeeeeeddeadbeeeeeeeeeef;

wire [23:0] lfsr_a;
wire [23:0] lfsr_b;
wire [23:0] lfsr_c;
wire [23:0] lfsr_d;
wire [23:0] lfsr_e;

reg rst1 = 1'b1;

wire rst_lfsr;
wire start_pat;

assign rst_lfsr = RST || rst1;

assign start_pat = rst1; // RST  ;// & (!RST);  // start pat when reset goes low

always @(posedge GEN_CLK) begin
  rst1       <= RST;
  STRT_LTNCY <= start_pat;

  if (start_pat)
    PRBS <= start_pattern;
  else
    if(INJ_ERR)
      PRBS <= ({lfsr_a,lfsr_b,lfsr_c,lfsr_d,lfsr_e})^112'hffffffffffffffffffffffffffff;
    else
      PRBS <= ({lfsr_a,lfsr_b,lfsr_c,lfsr_d,lfsr_e});
end

// Linear Feedback Shift Register
// [24,23,22,17] Fibonacci Implementation

   lfsr_R24 #(.init_fill(24'h83B62E))
   tx_lfsra(
       .CLK(GEN_CLK),
       .RST(rst_lfsr),
       .LFSR(lfsr_a)
   );

   lfsr_R24 #(.init_fill(24'hE26B38))
   tx_lfsrb(
       .CLK(GEN_CLK),
       .RST(rst_lfsr),
       .LFSR(lfsr_b)
   );

   lfsr_R24 #(.init_fill(24'h5a10af))
   tx_lfsrc(
       .CLK(GEN_CLK),
       .RST(rst_lfsr),
       .LFSR(lfsr_c)
   );

   lfsr_R24 #(.init_fill(24'h67afb1))
   tx_lfsrd(
       .CLK(GEN_CLK),
       .RST(rst_lfsr),
       .LFSR(lfsr_d)
   );

   lfsr_R24 #(.init_fill(24'haca519))
   tx_lfsre(
       .CLK(GEN_CLK),
       .RST(rst_lfsr),
       .LFSR(lfsr_e)
   );

endmodule
