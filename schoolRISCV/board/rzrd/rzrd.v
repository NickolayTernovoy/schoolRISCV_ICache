
/*
 * Copyright(c) 2020 Petr Krasnoshchekov
 *                   Black_Storm
 */

module rzrd
(
    input         clk,
    input         rst_n,
    input  [ 3:0] key_sw,
    output [ 3:0] led,
    output [ 7:0] hex,
    output [ 3:0] digit,
    output        buzzer
);
    // wires & inputs
    wire          clkCpu;
    wire          clkIn     =  clk;
    wire          clkEnable =  key_sw[1]; //  s2 на плате
    wire [  3:0 ] clkDevide =  4'b0010;
    wire [  4:0 ] regAddr   =  key_sw[2] ? 5'h0 : 5'ha; //  s3 на плате
    wire [ 31:0 ] regData;
    wire [ 31:0 ] cycleCnt;

    //cores
    sm_top sm_top
    (
        .clkIn      ( clkIn     ),
        .rst_n      ( rst_n     ),
        .clkDevide  ( clkDevide ),
        .clkEnable  ( clkEnable ),
        .clk        ( clkCpu    ),
        .regAddr    ( regAddr   ),
        .regData    ( regData   ),
        .cycleCnt_o ( cycleCnt  )
    );

    //outputs
    assign led[0]   = ~clkCpu;
    assign led[3:1] = ~regData[2:0];

    //hex out
    wire [ 31:0 ] h7segment;
    wire clkHex;

    assign h7segment = key_sw[3] ? cycleCnt : regData; // s4 на плате

    sm_clk_divider hex_clk_divider
    (
        .clkIn   ( clkIn  ),
        .rst_n   ( rst_n  ),
        .devide  ( 4'b0   ),
        .enable  ( 1'b1   ),
        .clkOut  ( clkHex )
    );

    wire [ 7:0] anodes;
    assign digit = anodes [ 3:0];

    sm_hex_display_8 sm_hex_display_8
    (
        .clock          ( clkHex     ),
        .resetn         ( rst_n      ),
        .number         ( h7segment  ),
        .seven_segments ( hex[6:0]   ),
        .dot            ( hex[7]     ),
        .anodes         ( anodes     )
    );

    assign buzzer = 1'b1;

endmodule
