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
(
    input           clkIn,
    input           rst_n,
    input   [ 3:0 ] clkDevide,
    input           clkEnable,
    output          clk,
    input   [ 4:0 ] regAddr,
    output  [31:0 ] regData
);
    //metastability input filters
    wire    [ 3:0 ] devide;
    wire            enable;
    wire    [ 4:0 ] addr;

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

    srv_icache sm_icache
    (
     .clk        (clk     ),
     .rst_n      (rst_n   ),
     .imem_req_i (im_req  ),
     .imAddr     (imAddr  ),                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      q,      // instruction memory address
     .imData     (imData  ),
     .im_drdy    (im_drdy ),
     .ext_addr_o (ext_addr),
     .ext_req_o  (ext_req ),
     .ext_rsp_i  (ext_rsp ),
     .ext_data_i (ext_data)
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
        .im_drdy    ( im_drdy   )
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
