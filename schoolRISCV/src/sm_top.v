/*
 * schoolRISCV - small RISC-V CPU
 *
 * originally based on Sarah L. Harris MIPS CPU
 *                   & schoolMIPS project
 *
 * Copyright(c) 2017-2020 Stanislav Zhelnio
 *                        Aleksandr Romanov
 */

//hardware top level module
module sm_top
#( 
  parameter CACHE_EN = 1
)
(
    input           clkIn,
    input           rst_n,
    input   [ 3:0 ] clkDevide,
    input           clkEnable,
    output          clk,
    input   [ 4:0 ] regAddr,
    output  [31:0 ] regData,
    output  [31:0 ] cycleCnt_o
);
    //metastability input filters
    wire    [ 3:0 ] devide;
    wire            enable;
    wire    [ 4:0 ] addr;
    //instruction memory
    wire    [31:0]  imAddr;
    wire    [31:0]  imData;
    wire            im_req;
    wire            im_drdy;
    wire     [31:0] ext_addr;
    wire            ext_req;
    wire            ext_rsp;
    wire    [127:0] ext_data;
    wire    [31:0]  rom_data;
    wire    [31:0]  rom_addr;

    //data memory
    wire    [31:0]  mem_addr;
    wire    [31:0]  mem_data;
    wire            memWrite;

    sm_debouncer #(.SIZE(4)) f0(clkIn, clkDevide, devide);
    sm_debouncer #(.SIZE(1)) f1(clkIn, clkEnable, enable);
    sm_debouncer #(.SIZE(5)) f2(clkIn, regAddr,   addr  );

    //cores
    //clock devider
    sm_clk_divider sm_clk_divider
    (
        .clkIn      ( clkIn     ),
        .rst_n      ( rst_n     ),
        .devide     ( devide    ),
        .enable     ( enable    ),
        .clkOut     ( clk       )
    );



    sm_rom reset_rom(rom_addr, rom_data);

    srv_mem mem_ctrl(
    .clk        (clk      ),
    .rst_n      (rst_n    ),
    .ext_addr_i (ext_addr ),
    .ext_req_i  (ext_req  ),
    .ext_rsp_o  (ext_rsp  ),
    .ext_data_o (ext_data ),
    .rom_data_i (rom_data ),
    .rom_addr_o (rom_addr )
    );

    sr_cpu sm_cpu
    (
        .clk        ( clk       ),
        .rst_n      ( rst_n     ),
        .regAddr    ( addr      ),
        .regData    ( regData   ),
        .im_req     ( im_req    ),
        .imAddr     ( imAddr    ),
        .imData     ( imData    ),
        .im_drdy    ( im_drdy   ),
        .addr_o     ( mem_addr  ),
        .data_o     ( mem_data  ),
        .memWrite_o ( memWrite  )
    );

    srv_icache #(
    .CACHE_EN(CACHE_EN)
    ) sm_icache (
     .clk        (clk     ),
     .rst_n      (rst_n   ),
     .imem_req_i (im_req  ),
     .imAddr     (imAddr  ),
     .imData     (imData  ),
     .im_drdy    (im_drdy ),
     .ext_addr_o (ext_addr),
     .ext_req_o  (ext_req ),
     .ext_rsp_i  (ext_rsp ),
     .ext_data_i (ext_data)
    );

    reg cnt_en_ff;
    reg cnt_clear_ff;

    // cycle counter enable
    always @(posedge clk or negedge rst_n)
        if (~rst_n)
            cnt_en_ff <= 1'b0;
        else if (memWrite && (mem_addr == 32'h200))
            cnt_en_ff <= mem_data[0];

    // cycle counter clear signal
    always @(posedge clk or negedge rst_n)
        if (~rst_n)
            cnt_clear_ff <= 1'b0;
        else if (memWrite && (mem_addr == 32'h201))
            cnt_clear_ff <= mem_data[0];

    cycle_counter i_cycle_cnt (
        .clk        (clk         ),
        .rst_n      (rst_n       ),
        .en_i       (cnt_en_ff   ),
        .clear_i    (cnt_clear_ff),
        .cycleCnt_o (cycleCnt_o  )
    );

endmodule

//metastability input debouncer module
module sm_debouncer
#(
    parameter SIZE = 1
)
(
    input                      clk,
    input      [ SIZE - 1 : 0] d,
    output reg [ SIZE - 1 : 0] q
);
    reg        [ SIZE - 1 : 0] data;

    always @ (posedge clk) begin
        data <= d;
        q    <= data;
    end

endmodule

//tunable clock devider
module sm_clk_divider
#(
    parameter shift  = 16,
              bypass = 0
)
(
    input           clkIn,
    input           rst_n,
    input   [ 3:0 ] devide,
    input           enable,
    output          clkOut
);
    wire [31:0] cntr;
    wire [31:0] cntrNext = cntr + 1;
    sm_register_we r_cntr(clkIn, rst_n, enable, cntrNext, cntr);

    assign clkOut = bypass ? clkIn
                           : cntr[shift + devide];
endmodule

module cycle_counter (
    input             clk,
    input             rst_n,
    input             en_i,
    input             clear_i,
    output reg [31:0] cycleCnt_o
);

wire [31:0] cycleCnt_next;

assign cycleCnt_next = clear_i ? 32'd0 : (en_i ? cycleCnt_o + 32'd1 : cycleCnt_o);

// cycle counter
always @(posedge clk or negedge rst_n)
    if (~rst_n) cycleCnt_o <= 32'd0;
    else        cycleCnt_o <= cycleCnt_next;

endmodule
