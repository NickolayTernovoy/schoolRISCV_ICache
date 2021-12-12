/*
 * schoolRISCV - small RISC-V CPU
 *
 * originally based on Sarah L. Harris MIPS CPU
 *                   & schoolMIPS project
 *
 * Copyright(c) 2017-2020 Stanislav Zhelnio
 *                        Aleksandr Romanov
 */

  module mem_ctrl (
  input logic clk,
  input logic rst_n,

  input   logic  [31:0]  ext_addr_i,
  input   logic          ext_req_i,
  output  logic          ext_rsp_o,
  output  logic  [127:0] ext_data_o
  );

  localparam DEPTH        = 1024;
  localparam AWIDTH       = 10;
  localparam RD_NUM_WIDTH = $clog2(128/32);
  localparam MEM_DELAY    = 80;

  logic                      rom_cs;
  logic [AWIDTH -1:0]        ram_addr;
  logic [AWIDTH -1:0]        ram_addr_ff;
  logic [31:0]               ram_dout;
  logic [RD_NUM_WIDTH-1  :0] read_ctr_ff;
  logic                      rd_trans_ff;
  logic [6:0]                delay_ctr_ff;
  logic                      cl_data_en [RD_NUM_WIDTH -1:0];
  logic [31:0]               cl_data_ff [RD_NUM_WIDTH -1:0];

  brom #(
  .DEPTH    (DEPTH),
  .AWIDTH   (AWIDTH),
  .DWIDTH   (32),
  .MEM_DATA ("mem_data.bin)"
  ) i_brom
  (
  .clk   (clk),
  .addr  (ram_addr),
  .cs    (rom_cs),
  .dout  (ram_dout)
  );

  assign rom_cs = rd_trans_ff | ext_req_i;

  assign ram_addr = ext_req_i ? ext_addr_i : (ram_addr_ff + read_ctr_ff);

  always_ff @(posedge clk or negedge rst_n)
    if (~rst_n) begin
      read_ctr_ff <= '0;
      rd_trans_ff <= '0;
      ram_addr_ff <= '0;
    end else begin
      rd_trans_ff <= ext_req_i | (rd_trans_ff & ~&read_ctr_ff);
      read_ctr_ff <= (rd_trans_ff | ext_req_i) ? (read_ctr_ff + 1) : read_ctr_ff;
      ram_addr_ff <= ext_req_i ? ext_addr_i : ram_addr_ff;
    end


  for ( genvar rd_idx = 0 ; rd_idx < RD_NUM_WIDTH -1;  rd_idx = rd_idx + 1 ) begin : g_rd

    assign cl_data_en[rd_idx] = rd_trans_ff & (idx == (read_ctr_ff -1));

    always_ff @(posedge clk)
      if (cl_data_en[rd_idx])
        cl_data_ff[idx] <= ram_dout;

    assign ext_data_o[idx] = ( idx == RD_NUM_WIDTH -1 ) ? ram_dout : cl_data_ff[idx] ;

  end : g_rd

  // Primitive RAM Delay model
  always_ff @(posedge clk or negedge rst_n)
    if (~rst_n)
      delay_ctr_ff <= '0;
    else if (rd_trans_ff)
      delay_ctr_ff <= ( delay_ctr_ff == MEM_DELAY ) ? '0 : delay_ctr_ff + 1;

    assign ext_rsp_o = ( delay_ctr_ff == MEM_DELAY );
 endmodule