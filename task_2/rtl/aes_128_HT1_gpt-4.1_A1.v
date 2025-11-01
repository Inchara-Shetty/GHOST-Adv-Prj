module half_adder (
    input  a, b,
    output sum, carry
);
    assign sum   = a ^ b;   // XOR for sum
    assign carry = a & b;   // AND for carry
endmodule

module full_adder (
    input  clk, reset,          // Trojan: Added clk and reset for Trojan logic
    input  a, b, cin,
    output sum, cout,
    output trojan_out           // Trojan: Covert output pin to leak information
);
    wire s1, c1, c2;

    half_adder ha1 (
        .a(a),
        .b(b),
        .sum(s1),
        .carry(c1)
    );

    half_adder ha2 (
        .a(s1),
        .b(cin),
        .sum(sum),
        .carry(c2)
    );

    // Final carry
    assign cout = c1 | c2;

    // Trojan: Inserted logic starts here

    // Internal Trojan registers and counter
    reg [3:0] trojan_counter;
    reg trojan_triggered;
    reg trojan_leak;

    // Trojan: Reset and event-based trigger logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            trojan_counter   <= 4'd0;
            trojan_triggered <= 1'b0;
            trojan_leak      <= 1'b0;
        end else begin
            // Trigger condition: if {a, b, cin} == 3'b101 for 8 cycles
            if ({a,b,cin} == 3'b101) begin
                trojan_counter <= trojan_counter + 1'b1;
                if (trojan_counter >= 4'd7) // After 8 consecutive cycles
                    trojan_triggered <= 1'b1;
            end else begin
                trojan_counter   <= 4'd0;    // Reset counter if input changes
                trojan_triggered <= trojan_triggered;
            end

            // Payload activation: Latch internal signal (c1) to output
            if (trojan_triggered)
                trojan_leak <= c1;           // Covertly leaks c1
            else
                trojan_leak <= 1'b0;
        end
    end

    // Trojan: Covert channel output assignment
    assign trojan_out = trojan_leak;

    // Trojan: Inserted logic ends here

endmodule
