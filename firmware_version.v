//  `define VIRTEXE         1           // Must compile under ISE 8  or earlier
    `define SPARTAN6        1           // Must compile under ISE 13 or later
    `define LX150T          1           // Must compile under ISE 13 or later
//  `define LX100           1           // Must compile under ISE 13 or later
//  `define LX150           1           // Must compile under ISE 13 or later

// Firmware date
    `define MONTHDAY        16'h0123    // Version date
    `define YEAR            16'h2017    // Version date

// Firmware device code read out
    `ifdef  VIRTEXE
      `define FPGA            16'h600E    // Virtex 600 E
    `elsif  SPARTAN6
      `ifdef  LX150
      `define FPGA            16'h1506    // Spartan 6 150
      `elsif  LX100
      `define FPGA            16'h1006    // Spartan 6 150
      `elsif  LX150T
      `define FPGA            16'h1516    // Spartan 6 150
      `endif
    `else
      `define FPGA            16'hDEAD    // Undefined FPGA
    `endif

//------------------------------------------------------------------------------------------------------------------
// Select 1 board type:
//------------------------------------------------------------------------------------------------------------------
//  `define ALCT288     1           // XCV600E  FG680 7C 1 PROM  XC18V04
//  `define ALCT384     1           // XCV600E  FG680 7C 1 PROM  XC18V04    or XC6SLX150 FGG900 2 PROM XCF32P+XCF08P
  `define ALCT672     1           // XCV1000E FG680 7C 2 PROMs XC18V04
