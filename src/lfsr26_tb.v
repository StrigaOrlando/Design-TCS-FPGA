`timescale 1ns/1ns

module lfsr26_tb;

reg clk = 0;
reg rst_n = 0;
reg en = 0;

wire [25:0] state;

integer f;
integer i;

lfsr26 dut (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (en),
    .state (state)
);

parameter CLOCK_PERIOD = 10;

// генерация тактового сигнала
always #(CLOCK_PERIOD/2) clk = ~clk;

// запись VCD для просмотра временной диаграммы
initial begin
    $dumpfile("lfsr26_tb.vcd");
    $dumpvars(0, lfsr26_tb);
end

// основной сценарий теста
initial begin
    f = $fopen("lfsr26_states.txt", "w");

    // начальные условия
    rst_n = 0;
    en    = 0;

    // держим reset
    #20;
    rst_n = 1;
    en    = 1;

    // записываем 50 состояний
    for (i = 0; i < 50; i = i + 1) begin
        @(posedge clk);
        $fwrite(f, "%b\n", state);
    end

    $fclose(f);
    $finish;
end

endmodule