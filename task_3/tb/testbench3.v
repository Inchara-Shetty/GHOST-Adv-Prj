`timescale 1ns/1ps

module tb_full_adder_detect_fixed;

  reg clk;
  reg rst_n;
  reg a, b, cin;
  wire sum, cout;

  // Instantiate DUT (use the RTL you provided)
  full_adder dut (
    .clk   (clk),
    .rst_n (rst_n),
    .a     (a),
    .b     (b),
    .cin   (cin),
    .sum   (sum),
    .cout  (cout)
  );

  // Clock: 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  integer i;
  integer trojan_flag;
  reg [1:0] exp_sum_cout; // {exp_sum, exp_cout}

  // Compute expected combinational outputs (for checking)
  task compute_expected;
    input aa, bb, cc;
    output [1:0] result;
    reg esum, ecout;
    begin
      esum  = aa ^ bb ^ cc;
      ecout = (aa & bb) | (bb & cc) | (aa & cc);
      result[1] = esum;
      result[0] = ecout;
    end
  endtask

  initial begin
    $dumpfile("tb_full_adder_detect_fixed.vcd");
    $dumpvars(0, tb_full_adder_detect_fixed);

    trojan_flag = 0;

    // Reset (active low)
    rst_n = 0;
    a = 0; b = 0; cin = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Baseline quick check (ensure DUT nominally behaves)
    $display("\nBaseline check (all 8 vectors):");
    for (i = 0; i < 8; i = i + 1) begin
      {a,b,cin} = i[2:0];
      @(posedge clk);
      // wait an extra clock because outputs are registered in DUT
      @(posedge clk);
      compute_expected(a,b,cin,exp_sum_cout);
      if (sum !== exp_sum_cout[1] || cout !== exp_sum_cout[0]) begin
        $display("Baseline mismatch for inputs %b: got sum=%b cout=%b expected sum=%b cout=%b",
                 i[2:0], sum, cout, exp_sum_cout[1], exp_sum_cout[0]);
      end
    end
    $display("Baseline done.");

    // Small pause
    repeat (2) @(posedge clk);

    // Apply longer trigger: 6 consecutive cycles of {a,b,cin} = 101
    $display("\nApplying 6 consecutive trigger vectors {a,b,cin} = 101");
    for (i = 0; i < 6; i = i + 1) begin
      a = 1; b = 0; cin = 1;
      @(posedge clk);
      // Print status every cycle for visibility
      $display("Trigger cycle %0d at time %0t: sum=%b cout=%b", i+1, $time, sum, cout);
    end

    // After these cycles, on the next posedge the Trojan payload should be active
    // Check immediately after the trigger burst (one extra clock to let regs update)
    @(posedge clk); // let registers present new trojan_active and payload effect
    @(posedge clk); // wait one more to ensure sum/cout updated under trojan

    // With inputs still 101, expected sum=0, expected cout=1.
    compute_expected(a,b,cin,exp_sum_cout);
    $display("\nAfter trigger burst: observed sum=%b cout=%b expected sum=%b cout=%b",
             sum, cout, exp_sum_cout[1], exp_sum_cout[0]);

    // Trojan forces sum=0 cout=0. If cout became 0 while expected cout is 1, trojan active.
    if (cout === 1'b0 && exp_sum_cout[0] === 1'b1) begin
      $display("TROJAN_DETECTED: cout forced to 0 when expected 1. Time=%0t", $time);
      trojan_flag = 1;
    end else begin
      $display("No immediate trojan behavior observed on this sample.");
    end

    // Extra verification: while keeping trojan potentially active, test a different vector
    // If trojan is truly active, outputs will be forced to zero even for vectors where expected outputs are 1.
    repeat (1) @(posedge clk);
    a = 1; b = 1; cin = 0; // expected cout = 1 normally
    @(posedge clk);
    @(posedge clk); // allow registered outputs to update
    compute_expected(a,b,cin,exp_sum_cout);
    $display("Post-trigger different vector: a=1 b=1 cin=0 -> observed sum=%b cout=%b expected sum=%b cout=%b",
             sum, cout, exp_sum_cout[1], exp_sum_cout[0]);

    if (sum === 1'b0 && cout === 1'b0 && (exp_sum_cout != 2'b00)) begin
      $display("TROJAN_CONFIRMED: outputs forced to zero on different vector after trigger. Time=%0t", $time);
      trojan_flag = 1;
    end

    // Final result
    $display("\n--- TEST RESULT ---");
    if (trojan_flag) $display("FINAL: Trojan detected. Investigate RTL payload.");
    else $display("FINAL: No Trojan detected by this test. Try longer or alternate trigger sequences.");

    #10;
    $finish;
  end

Endmodule
