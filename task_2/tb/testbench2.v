
// tb_full_adder_detect.v
`timescale 1ns/1ps

module tb_full_adder_detect;

  // Signals matching the RTL you provided
  reg clk;
  reg reset;
  reg a, b, cin;
  wire sum, cout;
  wire trojan_out;

  // Instantiate the DUT (full_adder from your RTL)
  full_adder dut (
    .clk        (clk),
    .reset      (reset),
    .a          (a),
    .b          (b),
    .cin        (cin),
    .sum        (sum),
    .cout       (cout),
    .trojan_out (trojan_out)
  );

  // Clock: 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Test control variables
  integer i;
  integer errors;
  reg trojan_seen;
  reg baseline_trojan_out;
  reg post_trigger_trojan_out;

  initial begin
    // Dump waveform for debugging
    $dumpfile("tb_full_adder_detect.vcd");
    $dumpvars(0, tb_full_adder_detect);

    errors = 0;
    trojan_seen = 0;

    // Reset DUT
    reset = 1;
    a = 0; b = 0; cin = 0;
    repeat (2) @(posedge clk);
    reset = 0;
    @(posedge clk);

    // -------------------------
    // Baseline check (before trigger)
    // Apply a=1,b=1,cin=0 where c1 = a&b = 1
    // trojan_out should remain 0 before trigger
    // -------------------------
    a = 1; b = 1; cin = 0;
    @(posedge clk); // let registers (trojan internals) sample
    @(posedge clk); // give stable samples
    baseline_trojan_out = trojan_out;
    if (baseline_trojan_out !== 1'b0) begin
      $display("WARNING: baseline trojan_out is %b (expected 0) at time %0t", baseline_trojan_out, $time);
      // don't treat as fatal; continue to try to detect behavior change
    end else begin
      $display("Baseline: trojan_out == 0 as expected (pre-trigger).");
    end

    // Also verify functional outputs for this vector
    if (sum !== (a ^ b ^ cin)) begin
      $display("ERROR: sum mismatch at baseline vector: a=%b b=%b cin=%b sum=%b expected=%b", a, b, cin, sum, (a ^ b ^ cin));
      errors = errors + 1;
    end
    if (cout !== ((a & b) | (b & cin) | (a & cin))) begin
      $display("ERROR: cout mismatch at baseline vector: a=%b b=%b cin=%b cout=%b expected=%b", a, b, cin, cout, ((a & b) | (b & cin) | (a & cin)));
      errors = errors + 1;
    end

    // Pause a bit
    repeat (2) @(posedge clk);

    // -------------------------
    // Trigger phase: apply 8 consecutive cycles of {a,b,cin} = 101
    // That is the Trojan trigger in the RTL
    // -------------------------
    $display("Applying trigger pattern (eight consecutive cycles of 1,0,1) starting at time %0t", $time);
    for (i = 0; i < 8; i = i + 1) begin
      a = 1; b = 0; cin = 1;
      @(posedge clk);
    end

    // give it one more cycle to let trojan_triggered & trojan_leak settle
    @(posedge clk);

    // -------------------------
    // Post-trigger check: apply a vector where a&b == 1 (e.g., a=1 b=1 cin=0)
    // If Trojan activated, trojan_out should now follow c1 (a & b) and be 1 here.
    // -------------------------
    a = 1; b = 1; cin = 0;
    @(posedge clk);
    @(posedge clk); // let trojan_leak update and propagate

    post_trigger_trojan_out = trojan_out;
    $display("Post-trigger: trojan_out = %b, expected (if Trojan active) = %b (a & b) at time %0t", post_trigger_trojan_out, (a & b), $time);

    if (post_trigger_trojan_out === (a & b)) begin
      $display("TROJAN_DETECTED: trojan_out now follows internal carry (a & b).");
      trojan_seen = 1;
    end else begin
      $display("No trojan behavior observed for this test vector. (trojan_out=%b, a&b=%b)", post_trigger_trojan_out, (a & b));
    end

    // -------------------------
    // Additional exhaustive functional checks (small sweep)
    // Also monitor trojan_out during sweep to catch unexpected leaks
    // -------------------------
    $display("Running small exhaustive functional check and monitoring trojan_out...");
    for (i = 0; i < 8; i = i + 1) begin
      a = i[2];
      b = i[1];
      cin = i[0];
      @(posedge clk);
      // allow combinational outputs to settle; sum and cout are combinational here
      if (sum !== (a ^ b ^ cin)) begin
        $display("ERROR: functional sum mismatch at vector %0d: a=%b b=%b cin=%b sum=%b expected=%b at time %0t", i, a, b, cin, sum, (a ^ b ^ cin), $time);
        errors = errors + 1;
      end
      if (cout !== ((a & b) | (b & cin) | (a & cin))) begin
        $display("ERROR: functional cout mismatch at vector %0d: a=%b b=%b cin=%b cout=%b expected=%b at time %0t", i, a, b, cin, cout, ((a & b) | (b & cin) | (a & cin)), $time);
        errors = errors + 1;
      end

      // If trojan hasn't been seen yet, check if trojan_out is unexpectedly non-zero when it shouldn't be
      if (!trojan_seen) begin
        if (trojan_out !== 1'b0) begin
          $display("SUSPICIOUS: trojan_out=%b observed before trigger at vector %0d time %0t", trojan_out, i, $time);
        end
      end
    end

    // Final verdict
    if (trojan_seen) begin
      $display("FINAL RESULT: Trojan behavior detected. Investigate insertion and remove malicious logic.");
    end else begin
      $display("FINAL RESULT: No Trojan detected by this test. (Either absent, uses a different trigger, or needs different vectors.)");
    end

    if (errors != 0) begin
      $display("Functional errors detected: %0d. Fix functional issues or re-run tests.", errors);
    end

    // Finish
    #10;
    $finish;
  end

endmodule
