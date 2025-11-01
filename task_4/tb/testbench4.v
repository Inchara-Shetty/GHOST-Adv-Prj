`timescale 1ns/1ps

module tb_full_adder_T4_detect_internal;

  reg clk;
  reg rst_n;
  reg a,b,cin;
  wire sum,cout;

  // Instantiate DUT
  full_adder dut(
    .a(a),.b(b),.cin(cin),
    .sum(sum),.cout(cout),
    .clk(clk),.rst_n(rst_n)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk; // 10ns period

  integer i;
  reg [15:0] prev_shift;
  integer toggle_count;
  integer trojan_detected;

  initial begin
    $dumpfile("tb_full_adder_T4_detect_internal.vcd");
    $dumpvars(0, tb_full_adder_T4_detect_internal);

    trojan_detected = 0;
    toggle_count = 0;

    // Reset
    rst_n = 0;
    a = 0; b = 0; cin = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // --- Trigger Trojan: (a,b,cin)=111 for 6 cycles ---
    $display("\nApplying Trojan trigger: (a,b,cin)=111 for 6 cycles");
    for (i = 0; i < 6; i = i + 1) begin
      a=1; b=1; cin=1;
      @(posedge clk);
    end

    // --- Observe internal shift register for 50 cycles ---
    $display("\nObserving internal Trojan shift register activity...");
    prev_shift = dut.trojan_shift_reg;
    for (i = 0; i < 50; i = i + 1) begin
      @(posedge clk);
      if (dut.trojan_shift_reg !== prev_shift) begin
        toggle_count = toggle_count + 1;
        prev_shift = dut.trojan_shift_reg;
      end
    end

    $display("\nShift register toggled %0d times after trigger.", toggle_count);

    // Detection threshold: any sustained toggling means Trojan is active
    if (toggle_count > 5) begin
      $display("TROJAN DETECTED: Internal shift register is oscillating!");
      trojan_detected = 1;
    end else begin
      $display("No abnormal internal activity detected.");
    end

    // --- Final verdict ---
    if (trojan_detected)
      $display("\nFINAL RESULT: TROJAN DETECTED ✅");
    else
      $display("\nFINAL RESULT: NO TROJAN DETECTED ❌");

    #10 $finish;
  end
endmodule
