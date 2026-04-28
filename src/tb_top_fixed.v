`timescale 1ns / 1ps

module tb_top_fixed;

    reg clk = 0;
    reg reset = 1;
    reg clk_enable = 1;
    reg signed [15:0] filter_in;
    wire signed [15:0] filter_out;

    integer f;
    integer n;

    top_fixed dut (
        .clk(clk),
        .reset(reset),
        .clk_enable(clk_enable),
        .filter_in(filter_in),
        .filter_out(filter_out)
    );

    // 120 MHz clock: period ? 8.333 ns
    always #4.166 clk = ~clk;

    initial begin
        f = $fopen("fir_impulse_response.txt", "w");

        filter_in = 0;

        // reset
        repeat(5) @(posedge clk);
        reset = 0;

        // единичный импульс в Q1.15: 1.0 ? 32767
        @(posedge clk);
        filter_in = 16'sd32767;

        @(posedge clk);
        filter_in = 16'sd0;

        // записываем выходные отсчёты
        for (n = 0; n < 200; n = n + 1) begin
            @(posedge clk);
            $fwrite(f, "%d\n", filter_out);
        end

        $fclose(f);
        $stop;
    end

endmodule