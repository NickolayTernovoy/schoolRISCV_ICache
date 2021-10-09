// File: <timer_tb.sv>

`timescale 1ns/1ns

module timer_tb ();

//----------------------------------------------------------------------------------------------------------------------
// Parameters and declarations
//----------------------------------------------------------------------------------------------------------------------

// The clock frequency. The default value is 50 MHz
localparam CLK_FREQ     = 50_000_000;
// The width fot the us counter
localparam NS_CNT_WIDTH = 2;
// The period of a cycle
// The period for default value (50 MHz) = 1/50MHz = 1/5 * 10^-7 sec = 20 ns
localparam PERIOD_IN_NS = ($rtoi(1e+9/CLK_FREQ));

logic                    tb_clk;
logic                    tb_rst_n;
logic                    tb_to_clear_timer;
logic [NS_CNT_WIDTH-1:0] tb_ns_cnt;
logic                    tb_overflow_was;

//----------------------------------------------------------------------------------------------------------------------
// DUT
//----------------------------------------------------------------------------------------------------------------------

timer #(
  .CLK_FREQ     (CLK_FREQ),
  .NS_CNT_WIDTH (NS_CNT_WIDTH)
) Dut (
  .clk              (tb_clk),
  .rst_n            (tb_rst_n),
  .to_clear_timer_i (tb_to_clear_timer),
  .ns_cnt_o         (tb_ns_cnt),
  .overflow_was     (tb_overflow_was)
);

//----------------------------------------------------------------------------------------------------------------------
// Test
//----------------------------------------------------------------------------------------------------------------------

// Messages
initial begin
  $write("\nSelected frequency: %d MHz", CLK_FREQ/(1_000_000));
  $write("\nCalculated period:  %d ns", PERIOD_IN_NS);
  $write("\nMax counter value for\nthe selected width:  %d ns\n", (2**NS_CNT_WIDTH)-1);

  forever begin
    #PERIOD_IN_NS;

    if (tb_to_clear_timer) begin
      $write("\nTest time: %t ns;  The timer has been reset at value %d ns\n", $time, tb_ns_cnt);
    end

    if (tb_overflow_was) begin
      $write("\nTest time: %t ns;  Overflow occurred\n", $time);
      $stop;
    end
  end
end

// Clock
initial begin
  tb_clk = '1;
  forever #(PERIOD_IN_NS/2) tb_clk = ~tb_clk;
end

initial begin
  tb_to_clear_timer = '0;

  tb_rst_n                   = '0;
  #(PERIOD_IN_NS/2) tb_rst_n = '1;

  #(4*PERIOD_IN_NS) tb_to_clear_timer = '1;
  #PERIOD_IN_NS     tb_to_clear_timer = '0;
end

endmodule : timer_tb
