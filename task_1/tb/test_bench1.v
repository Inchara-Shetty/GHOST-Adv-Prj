`timescale 1ns/1ps
module tb_detect_aes128_ht1;
  // Clock / reset
  reg clk = 0;
  always #5 clk = ~clk; // 100 MHz-ish simulated clock

  reg rstn;

  // Full adder inputs/outputs
  reg a, b, cin;
  wire sum, cout;

  // Instantiate your Trojan'ed full adder
  // Make sure the path/name matches the file you compiled with (aes_128_HT1_gpt-4.1_A1.v)
  full_adder dut (
    .clk(clk),
    .rstn(rstn),
    .a(a),
    .b(b),
    .cin(cin),
    .sum(sum),
    .cout(cout)
  );

  // helper to compute expected values (combinational)
  function automatic [1:0] golden;
    input a_i, b_i, cin_i;
    reg s_g;
    reg c_g;
    begin
      s_g = a_i ^ b_i ^ cin_i;
      c_g = (a_i & b_i) | (b_i & cin_i) | (a_i & cin_i);
      golden = {c_g, s_g}; // [1]=cout, [0]=sum
    end
  endfunction

  integer i;
  reg [1:0] g; // golden outputs

  initial begin
    $dumpfile("tb_aes128_ht1.vcd");
    $dumpvars(0, tb_detect_aes128_ht1);

    // Reset
    rstn = 0;
    a = 0; b = 0; cin = 0;
    #20;
    rstn = 1;
    #20;

    $display("\n=== Sanity check: Verify normal functionality before triggering Trojan ===");
    // test a few input patterns
    for (i = 0; i < 8; i = i + 1) begin
      {a,b,cin} = i[2:0];
      #10; // let outputs settle on posedge domain (we use 10ns per vector)
      g = golden(a,b,cin);
      if ({cout, sum} !== g) begin
        $display("ERROR: pre-trigger mismatch for inputs a=%b b=%b cin=%b : got (cout,sum)=(%b,%b) expected=(%b,%b)",
                  a,b,cin, cout, sum, g[1], g[0]);
      end else begin
        $display("OK pre-trigger: a=%b b=%b cin=%b -> sum=%b cout=%b", a,b,cin, sum, cout);
      end
      #10;
    end

    $display("\n=== Applying Trojan trigger sequence: (a=1,b=1,cin=0) repeated 8 times ===");
    // Apply the trigger pattern 8 times (matches file's trigger threshold)
    for (i = 0; i < 8; i = i + 1) begin
      a = 1; b = 1; cin = 0;
      #10;
      $display("Trigger step %0d: a=%b b=%b cin=%b (cout,sum)=(%b,%b)", i+1, a,b,cin, cout, sum);
      #10;
    end

    // Small gap to let the design latch the trojan_active flag if implemented with edges
    #20;

    $display("\n=== After trigger: apply the Trojan-sensitive vector (a=1,b=0,cin=1) ===");
    a = 1; b = 0; cin = 1;
    #10;
    g = golden(a,b,cin);
    $display("After trigger inputs a=%b b=%b cin=%b -> expected (cout,sum)=(%b,%b), got (cout,sum)=(%b,%b)",
             a,b,cin, g[1], g[0], cout, sum);

    // Detection logic: The Trojan in this file flips the sum when trojan_active and (a=1,b=0,cin=1)
    if (sum !== g[0]) begin
      $display("\n*** TROJAN DETECTED: sum is corrupted after trigger. Testbench result: FAIL (Trojan active) ***");
    end else begin
      $display("\nNo corruption observed for the sensitive vector: Trojan not triggered or different payload.");
    end

    $display("\n=== Done. Dumpfile: tb_aes128_ht1.vcd ===\n");
    #20;
    $finish;
  end

endmodule
