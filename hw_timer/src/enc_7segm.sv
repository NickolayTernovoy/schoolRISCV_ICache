// File: <enc_7segm.sv>
// Brief: The 7-segment display ecnoder

module enc_7segm #(
  parameter BIN_VAL_WIDTH = 14,
  parameter DEC_DIGITS = 4
) (
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic [BIN_VAL_WIDTH-1:0] bin_val_i,
  input  logic                     req_i,
  output logic               [7:0] single_7segm_o,
  output logic    [DEC_DIGITS-1:0] digit_select_o
);

//----------------------------------------------------------------------------------------------------------------------
// Declarations, types and parameters
//----------------------------------------------------------------------------------------------------------------------

localparam LOOP_CNT_WIDTH  = $clog2(BIN_VAL_WIDTH);
localparam DIGIT_CNT_WIDTH = $clog2(DEC_DIGITS);

typedef enum logic[2:0] {
  S_IDLE,
  S_SHIFT,
  S_ADD,
  S_WRITE
} type_enum_bcd_fsm;

type_enum_bcd_fsm bcd_fsm;
type_enum_bcd_fsm bcd_fsm_next;

logic      [DEC_DIGITS-1:0] digit_select_next;
logic [DIGIT_CNT_WIDTH-1:0] resp_cnt;
logic [DIGIT_CNT_WIDTH-1:0] resp_cnt_next;
logic   [BIN_VAL_WIDTH-1:0] bin_val;
logic   [BIN_VAL_WIDTH-1:0] bin_val_next;
logic [3:0][DEC_DIGITS-1:0] dec_digits;
logic [3:0][DEC_DIGITS-1:0] dec_digits_next;
logic [3:0][DEC_DIGITS-1:0] dec_digits_shifted;
logic      [DEC_DIGITS-1:0] digit_idx;
logic      [DEC_DIGITS-1:0] digit_idx_next;
logic  [LOOP_CNT_WIDTH-1:0] loop_cnt;
logic  [LOOP_CNT_WIDTH-1:0] loop_cnt_next;
logic                 [7:0] single_7segm_next;

logic                [15:0] clk_reduction_cnt_next;
logic                [5:0] clk_reduction_cnt;
logic                       clk_reduction;

//----------------------------------------------------------------------------------------------------------------------
// Binary -> Binary Coded Decimal (BCD)
//----------------------------------------------------------------------------------------------------------------------

// Following FSM is made for double dabble algorithm, which is used to convert a common binary value to separate
// decimal digits, so called BCDs

always_comb
  case (bcd_fsm)
    S_IDLE:  bcd_fsm_next = req_i ? S_SHIFT : S_IDLE;
    S_SHIFT: bcd_fsm_next = (loop_cnt == BIN_VAL_WIDTH-1) ? S_WRITE : S_ADD;
    S_ADD:   bcd_fsm_next = (digit_idx == DEC_DIGITS-1) ? S_SHIFT : S_ADD;
    S_WRITE: bcd_fsm_next = (resp_cnt < DEC_DIGITS-1) ? S_WRITE : S_IDLE;
  endcase

assign bin_val_next = (bcd_fsm == S_IDLE)   ?  bin_val_i :
                      (bcd_fsm == S_SHIFT)  ? {bin_val[BIN_VAL_WIDTH-2:0], 1'd0} :
                                               bin_val;

// << 1, [0] = bin_val MSB
assign dec_digits_shifted = {dec_digits[DEC_DIGITS-1][2:0], dec_digits[DEC_DIGITS-2:0], bin_val[BIN_VAL_WIDTH-1]};

// To keep track on current iteration or digit
assign loop_cnt_next  = (bcd_fsm != S_SHIFT) ? loop_cnt :
                        ((loop_cnt == BIN_VAL_WIDTH-1) ? '0 : (loop_cnt + LOOP_CNT_WIDTH'(1'd1)));
assign digit_idx_next = (bcd_fsm != S_ADD)   ? digit_idx :
                        ((digit_idx == DEC_DIGITS-1)   ? '0 : (digit_idx + DEC_DIGITS'(1'd1)));

// To determine a proper digit to select
assign resp_cnt_next = (bcd_fsm == S_WRITE) ? (resp_cnt + DIGIT_CNT_WIDTH'(1'd1)) : '0;

// Selects a proper digit
//!assign digit_select_next = (bcd_fsm == S_WRITE) ? ((resp_cnt == 0) ? DEC_DIGITS'(1'd1) : {digit_select_o[DEC_DIGITS-2:0], 1'd0}) : '0;
assign digit_select_next = (bcd_fsm == S_WRITE) ? ((resp_cnt == 0) ? DEC_DIGITS'(-2'd2) : {digit_select_o[DEC_DIGITS-2:0], 1'd1}) : {DEC_DIGITS{1'd1}};

genvar i;

generate
  for (i = 0; i < DEC_DIGITS; i++) begin : g_dec_digits
    assign dec_digits_next[i] = (bcd_fsm == S_IDLE) ? '0 :
                                (bcd_fsm == S_SHIFT) ? dec_digits_shifted[i] :
                                ((bcd_fsm == S_ADD) && (i == digit_idx) && (dec_digits[i] > 4'd4)) ? dec_digits[i] + 4'd3 :
                                dec_digits[i];
  end
endgenerate

//----------------------------------------------------------------------------------------------------------------------
// Select segments
//----------------------------------------------------------------------------------------------------------------------

always_comb
  case (dec_digits_next[resp_cnt])
    4'h0: single_7segm_next = 8'hc0;
    4'h1: single_7segm_next = 8'hf9;
    4'h2: single_7segm_next = 8'ha4;
    4'h3: single_7segm_next = 8'hb0;
    4'h4: single_7segm_next = 8'h99;
    4'h5: single_7segm_next = 8'h92;
    4'h6: single_7segm_next = 8'h82;
    4'h7: single_7segm_next = 8'hf8;
    4'h8: single_7segm_next = 8'h80;
    4'h9: single_7segm_next = 8'h90;

    default: single_7segm_next = 8'h8e;

    //!4'h0: single_7segm_next = 8'hc0; // 0
    //!4'h1: single_7segm_next = 8'hf9; // 1
    //!4'h2: single_7segm_next = 8'ha4; // 2
    //!4'h3: single_7segm_next = 8'hb0; // 3
    //!4'h4: single_7segm_next = 8'h99; // 4
    //!4'h5: single_7segm_next = 8'h92; // 5
    //!4'h6: single_7segm_next = 8'h82; // 6
    //!4'h7: single_7segm_next = 8'hf8; // 7
    //!4'h8: single_7segm_next = 8'h80; // 8
    //!4'h9: single_7segm_next = 8'h90; // 9

    //!4'ha: single_7segm_next = 8'he3; // o
    //!4'ha: single_7segm_next = 8'hc0; // o
    //!4'ha: single_7segm_next = 8'h8e; // f

    //!4'ha: single_7segm_next = 8'h88; // a
    //!4'hb: single_7segm_next = 8'h83; // b
    //!4'hc: single_7segm_next = 8'hc6; // c
    //!4'hd: single_7segm_next = 8'ha1; // d
    //!4'he: single_7segm_next = 8'h86; // e
    //!4'hf: single_7segm_next = 8'h8e; // f
  endcase


assign clk_reduction_cnt_next = clk_reduction_cnt + 1'd1;

assign clk_reduction = (clk_reduction_cnt == '0);

always_ff @(posedge clk or negedge rst_n)
  if (~rst_n) begin
    clk_reduction_cnt <= '0;
  end
  else begin
    clk_reduction_cnt <= clk_reduction_cnt_next;
  end

always_ff @(posedge clk or negedge rst_n)
  if (~rst_n) begin
    bcd_fsm           <= S_IDLE;
    digit_select_o    <= {DEC_DIGITS{1'd1}};
    resp_cnt          <= '0;
    bin_val           <= '0;
    dec_digits        <= '0;
    digit_idx         <= '0;
    loop_cnt          <= '0;
    single_7segm_o    <= '0;
  end
  else if (clk_reduction) begin
    bcd_fsm           <= bcd_fsm_next;
    digit_select_o    <= digit_select_next;
    resp_cnt          <= resp_cnt_next;
    bin_val           <= bin_val_next;
    dec_digits        <= dec_digits_next;
    loop_cnt          <= loop_cnt_next;
    digit_idx         <= digit_idx_next;
    single_7segm_o    <= single_7segm_next;
  end

endmodule : enc_7segm
