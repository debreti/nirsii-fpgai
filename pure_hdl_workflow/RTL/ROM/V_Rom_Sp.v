/* ============================================================================
*  WARNING: ATOMIC MEMORY PRIMITIVE
*
*  This Verilog module represents a low-level, single-port memory primitive.
*  It is intentionally implemented in Verilog to allow memory initialization
*  via $readmemh and to enable consistent inference or replacement across
*  different FPGA/ASIC vendor toolchains.
*
*  This module is instantiated from VHDL and treated as an atomic component.
*  It MUST be considered a black box building block.
*
*  DO NOT:
*    - Modify the internal implementation
*    - Analyze or refactor this module as part of the surrounding design
*    - Assume behavioral semantics beyond its defined interface
*
*  Any changes to this file may break portability, vendor-specific memory
*  mapping, or simulation/synthesis consistency.
*
*  If a different memory behavior or configuration is required, create a new
*  wrapper or provide a vendor-specific alternative at a higher abstraction
*  level.
*
*  ============================================================================ */
module V_Rom_Sp #(
  parameter DATA_WIDTH  = 8,
  parameter ADR_WIDTH   = 8,
  parameter CELLS_CNT   = 8,
  parameter FILE_PATH   = "rom.mem"
) (
  input clk,
  input [ADR_WIDTH - 1 : 0] adr,
  output reg [DATA_WIDTH - 1 : 0] q
);
  reg [DATA_WIDTH - 1 : 0] rom [0 : CELLS_CNT - 1]; // ROM data array
  initial 
    $readmemh(FILE_PATH, rom);
  always@(posedge clk) 
    q <= rom[adr];
endmodule
