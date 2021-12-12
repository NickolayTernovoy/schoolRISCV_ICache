/*
 * schoolRISCV - small RISC-V CPU
 *
 * originally based on Sarah L. Harris MIPS CPU
 *                   & schoolMIPS project
 *
 * Copyright(c) 2017-2020 Stanislav Zhelnio
 *                        Aleksandr Romanov
 */

 module brom #(
  parameter DEPTH    = 1024,
  parameter AWIDTH   = 10,
  parameter DWIDTH   = 32,
  parameter MEM_DATA = "mem_data.bin"
  )
  (
  input  clk,
  input  [AWIDTH-1:0] addr,
  input  cs,
  output [DWIDTH -1:0] dout
  );

  logic [DWIDTH -1:0] mem [DEPTH -1:0];
  logic [DWIDTH -1:0] dout_ff;

  initial
  $readmemh(MEM_DATA, mem);

  always_ff @(posedge clk)
    if (cs)
      dout_ff <= mem[addr];

    assign dout = dout_ff;

 endmodule