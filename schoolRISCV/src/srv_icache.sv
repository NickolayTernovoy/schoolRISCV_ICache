/*
 * schoolRISCV - small RISC-V CPU
 *
 * originally based on Sarah L. Harris MIPS CPU
 *                   & schoolMIPS project
 *
 * Copyright(c) 2017-2020 Stanislav Zhelnio
 *                        Aleksandr Romanov
 */

// Fully associative instruction cache

 module srv_icache
(
    input  logic          clk,         // clock
    input  logic          rst_n,       // reset
    input  logic          imem_req_i,  // Memory request
    input  logic  [31:0]  imAddr,      // instruction memory address                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  q,      // instruction memory address
    output logic  [31:0]  imData,      // instruction memory data
    output logic          im_drdy,

    // MIF
    output logic  [31:0]  ext_addr_o,
    output logic          ext_req_o,
    input  logic          ext_rsp_i,
    input  logic  [31:0]  ext_data_i
);

localparam NWAYS = 32;
localparam L1I_SIZE = 128;
localparam TAG_WIDTH  = 32 - $clog2(L1I_SIZE);

logic                  cache_way_en      [NWAYS -1:0];
logic [L1I_SIZE  -1:0] cache_data_ff     [NWAYS -1:0];
logic [TAG_WIDTH -1:0] cache_tag_ff      [NWAYS -1:0];
logic                  cache_state_ff    [2*NWAYS -1:0];
logic                  cache_state_next  [2*NWAYS -1:0];
logic                  cache_state_en;
logic                  plru_set          [NWAYS -1:0];
logic                  cache_plru        [NWAYS -1:0];
logic                  cache_valid       [NWAYS -1:0];
logic                  cache_plru_new    [NWAYS -1:0];
logic                  cache_valid_new   [NWAYS -1:0];
logic                  cache_vict        [NWAYS -1:0];

logic [31:0]           req_addr_ff;
logic                  l1i_req_val_ff;

logic [TAG_WIDTH -1:0] in_tag;
logic            [1:0] cl_offs;
logic [TAG_WIDTH -1:0] in_tag_ff;
logic            [1:0] cl_offs_ff;
logic                  cl_hit;
logic                  cl_hit_ff;
logic [31        -1:0] hit_data;
logic [31        -1:0] rsp_data_next;
logic [31        -1:0] rsp_data_ff;
logic [NWAYS     -1:0] cl_hit_vec;

logic cl_refill_ff;
logic [L1I_SIZE-1:0] cl_refill_data_ff;

  // Latch input data;
  always_ff @(posedge clk)
    if (imem_req_i)
      req_addr_ff <= imAddr;

  always_ff @(posedge clk or negedge rst_n )
    if (~rst_n)
      l1i_req_val_ff <= '0;
    else
      l1i_req_val_ff <= imem_req_i;

  assign in_tag = imem_req_i ? imAddr[31 -:TAG_WIDTH] : req_addr_ff[31 -:TAG_WIDTH];

  assign cl_ofs = imem_req_i ? imAddr[3:2] :req_addr_ff[3:2];


  // Hit/Miss detection and data bypass interface
  always_comb begin
    for (integer idx = 0 ; idx < NWAYS; idx = idx + 1)
      cl_hit_vec[idx] = (in_tag == cache_tag_ff[idx]) & cache_state_ff[idx];
  end

  assign cl_hit = (|cl_hit_vec);

  always_comb begin
    hit_data    = '0;
    for (integer idx = 0 ; idx < NWAYS; idx = idx + 1)
      hit_data    |= {31{ cl_hit_vec[idx]}} & cache_data_ff[idx][32*cl_ofs +:32];
  end

  assign rsp_data_next = cl_hit ? hit_data : ext_data_i[32*cl_ofs +:32];
  always_ff @(posedge clk )
    if (cl_hit | ext_rsp_i)
      rsp_data_ff <= rsp_data_next;

  assign im_drdy = cl_hit_ff | cl_refill_ff;
  assign imData  = rsp_data_ff;

  // Memory interface
  assign ext_req_o  = ~cl_hit & l1i_req_val_ff;
  assign ext_addr_o = req_addr_ff;

  always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)  begin
      cl_hit_ff    <= 0;
      cl_refill_ff <= 0;
    end else begin
      cl_hit_ff    <= cl_hit;
      cl_refill_ff <= ext_rsp_i;
    end

  always_ff @(posedge clk)
    if (ext_rsp_i)
      cl_refill_data_ff <= ext_data_i;

  // Refill logic
  always_comb begin
    cache_vict[0] = &(cache_valid) ? ~cache_plru[0] : ~cache_valid[0];
    for (integer way_idx = 1; way_idx < NWAYS; way_idx = way_idx + 1)
      cache_vict[way_idx] = &(cache_valid) ? (~cache_plru[way_idx] & &(cache_plru[way_idx -1 : 0]))
                                           : (~cache_valid[way_idx] & &(cache_valid[way_idx -1 : 0]));
  end

  assign cache_plru       = cache_state_ff[NWAYS+:NWAYS];
  assign cache_valid      = cache_state_ff[NWAYS-1:0];

  assign cache_state_en   = (cl_hit & l1i_req_val_ff ) | cl_refill_ff;
  assign cache_valid_new  = (cache_valid | cache_vict);
  assign plru_set         = (cl_hit ? cl_hit_vec : cache_vict);
  assign cache_plru_new   = &(cache_plru | cache_set) ? cache_set
                                                      : (cache_plru | cache_set);

  assign cache_state_next = {cache_plru_new, cache_valid_new};

  assign cache_way_en  = cache_vict & {NWAYS{cl_refill_ff}};

  always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)
      cache_state_ff <= '0;
    else (cache_state_en)
      cache_state_ff <= cache_state_next;

    for (genvar way_idx = 0; way_idx < NWAYS; way_idx = way_idx + 1) begin : g_cache_memories
      always_ff @(posedge clk)
        if (cache_way_en[way_idx]) begin
          cache_data_ff[way_idx] <= cl_refill_data_ff;
          cache_tag_ff[way_idx]  <= req_addr_ff;
        end

    end : g_cache_memories


endmodule