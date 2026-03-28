module lfsr26(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    output reg [25:0]  state
);

wire feedback;

// Полином для варианта 6:
// [26, 24, 21, 17, 16, 14, 13, 11, 7, 6, 4, 1]
assign feedback = state[25] ^ state[23] ^ state[20] ^
                  state[16] ^ state[15] ^ state[13] ^
                  state[12] ^ state[10] ^ state[6]  ^
                  state[5]  ^ state[3]  ^ state[0];

always @(posedge clk) begin
    if (!rst_n)
        state <= 26'b1; // ненулевое начальное состояние
    else if (en)
        state <= {state[24:0], feedback};
end

endmodule
