`timescale 1ns / 1ps

module fir_hpf_fixed (
    input  wire clk,
    input  wire reset,
    input  wire clk_enable,
    input  wire signed [15:0] filter_in,
    output reg  signed [15:0] filter_out
);

    // коэффициенты
    reg signed [15:0] coeff [0:49];

    initial begin
    $readmemh("C:/Users/maria/Desktop/4_2/project_1/project_1.srcs/sim_1/new/fir_coeff.hex", coeff);
    end

    // линия задержки
    reg signed [15:0] delay [0:49];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 50; i = i + 1)
                delay[i] <= 0;
        end else if (clk_enable) begin
            delay[0] <= filter_in;
            for (i = 1; i < 50; i = i + 1)
                delay[i] <= delay[i-1];
        end
    end

    // умножение + суммирование
    reg signed [31:0] acc;

    always @(*) begin
        acc = 0;
        for (i = 0; i < 50; i = i + 1)
            acc = acc + delay[i] * coeff[i];
    end

    // масштабирование обратно
    always @(posedge clk) begin
        if (clk_enable)
            filter_out <= acc >>> 15;
    end

endmodule