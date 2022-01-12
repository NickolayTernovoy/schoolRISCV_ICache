module bcd_cvt #(
  parameter BIN_VAL_WIDTH = 14,
  parameter DEC_DIGITS = 4
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic   [BIN_VAL_WIDTH-1:0] bin_val_i,
  input  logic                       req_i,
  output logic                 [3:0] single_7segm_o,
  output logic      [DEC_DIGITS-1:0] resp_o
);

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

logic      [DEC_DIGITS-1:0] resp_next;
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

assign resp_cnt_next = (bcd_fsm == S_WRITE) ? (resp_cnt + DIGIT_CNT_WIDTH'(1'd1)) : '0;

assign resp_next = (bcd_fsm == S_WRITE) ? ((resp_cnt == 0) ? DEC_DIGITS'(1'd1) : {resp_o[DEC_DIGITS-2:0], 1'd0}) : '0;

generate
  for (genvar i = 0; i < DEC_DIGITS; i++) begin
    assign dec_digits_next[i] = (bcd_fsm == S_IDLE) ? '0 :
                                (bcd_fsm == S_SHIFT) ? dec_digits_shifted[i] :
                                ((bcd_fsm == S_ADD) && (i == digit_idx) && (dec_digits[i] > 4'd4)) ? dec_digits[i] + 4'd3 :
                                dec_digits[i];
  end
endgenerate

always_ff @(posedge clk or negedge rst_n)
  if (~rst_n) begin
    bcd_fsm        <= S_IDLE;
    resp_o         <= '0;
    resp_cnt       <= '0;
    bin_val        <= '0;
    dec_digits     <= '0;
    digit_idx      <= '0;
    loop_cnt       <= '0;
    single_7segm_o <= '0;
  end
  else begin
    bcd_fsm        <= bcd_fsm_next;
    resp_o         <= resp_next;
    resp_cnt       <= resp_cnt_next;
    bin_val        <= bin_val_next;
    dec_digits     <= dec_digits_next;
    loop_cnt       <= loop_cnt_next;
    digit_idx      <= digit_idx_next;
    single_7segm_o <= dec_digits_next[resp_cnt];
  end
endmodule
