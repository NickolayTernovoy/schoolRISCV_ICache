// File: <timer.sv>
// Brief: The parametrized hardware timer

module timer #(
  // The clock frequency. The default value is 50 MHz
  //!parameter CLK_FREQ     = 50_000_000,
  // The width fot the us counter
  parameter NS_CNT_WIDTH = 30,
  // The period of a cycle
  // The period for default value (50 MHz) = 1/50MHz = 1/5 * 10^-7 sec = 20 ns
  //!parameter PERIOD_IN_NS = ($rtoi(1e+9/CLK_FREQ)),
  parameter PERIOD_IN_NS = 20
) (
  input  logic                    clk,
  input  logic                    rst_n,

  input  logic                    to_clear_timer_i, // Sets counters to 0
  input  logic                    to_stall_timer_i, // Stops the timer
  output logic [NS_CNT_WIDTH-1:0] ns_cnt_o,         // us passed after reset/clear signal
  output logic                    overflow_was      // This signal indicates if the timer was overflowed
);

// Declarations
logic                    overflow;
logic [NS_CNT_WIDTH-1:0] ns_cnt_next;

// Add cycle period to the counter
assign {overflow, ns_cnt_next} = {1'd0, ns_cnt_o} + (NS_CNT_WIDTH+1)'(PERIOD_IN_NS);

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    ns_cnt_o     <= '0;
    overflow_was <= '0;
  end
  else begin
    if (to_clear_timer_i) begin
      ns_cnt_o     <= '0;
      overflow_was <= '0;
    end
    else begin
      if (~to_stall_timer_i)
        ns_cnt_o <= ns_cnt_next;
      else
        ns_cnt_o <= ns_cnt_o;

      if (overflow)
        overflow_was <= 1'd1;
      else
        overflow_was <= overflow_was;
    end
  end
end

endmodule : timer
