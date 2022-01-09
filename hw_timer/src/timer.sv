// File: <timer.sv>
// Brief: The parametrized hardware timer

module timer #(
  // The clock frequency. The default value is 50 MHz
  parameter CLK_FREQ     = 50_000_000,
  // The width fot the us counter
  parameter NS_CNT_WIDTH = 30,
  // The period of a cycle
  // The period for default value (50 MHz) = 1/50MHz = 1/5 * 10^-7 sec = 20 ns
  localparam PERIOD_IN_NS = ($rtoi(1e+9/CLK_FREQ))
) (
  input  logic                    clk,
  input  logic                    rst_n,

  input  logic                    to_clear_timer_i, // Sets counters to 0
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
      ns_cnt_o <= ns_cnt_next;
      if (overflow)
        overflow_was <= 1'd1;
    end
  end
end

// Check if the parameters are legal
if (PERIOD_IN_NS < 1)
  $error($sformatf("Illegal period value: %0d ns. Too high frequency?", PERIOD_IN_NS));

if (NS_CNT_WIDTH < $clog2(PERIOD_IN_NS))
  $error($sformatf("The value for the NS_CNT_WIDTH parameter is too low (%0d) for the calculated cycle period (%0d ns)",
         NS_CNT_WIDTH, PERIOD_IN_NS));

endmodule : timer
