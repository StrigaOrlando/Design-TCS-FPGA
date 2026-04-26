`timescale 1ns/1ps

module tb_nco_no_dither;

localparam PHASE_W = 7;
localparam AMP_W   = 6;
localparam N_SAMPLES = 1000;   // ужное количество отсчетов

reg clk;
reg rst_n;
reg en;
reg [PHASE_W-1:0] fcw;

wire signed [AMP_W-1:0] nco_out;
wire [PHASE_W-1:0] phase_dbg;

integer file_out;
integer sample_count;

nco_top #(
    .PHASE_W(PHASE_W),
    .AMP_W(AMP_W),
    .ROM_FILE("lut_signal2.hex")
) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .en       (en),
    .fcw      (fcw),
    .nco_out  (nco_out),
    .phase_dbg(phase_dbg)
);

/* ============================
   clk = 1 ћ√ц
   ============================ */
initial begin
    clk = 1'b0;
    forever #500 clk = ~clk;
end

/* ============================
   основной сценарий
   ============================ */
initial begin
    $display("TB START");

    rst_n = 0;
    en    = 0;
    fcw   = 7'd4;
    sample_count = 0;

    file_out = $fopen("nco_out_no_dither.txt", "w");

    if (file_out == 0) begin
        $display("ERROR: fopen failed");
        $finish;
    end

    #2000;
    rst_n = 1;
    en    = 1;
end

/* ============================
   запись + остановка
   ============================ */
always @(posedge clk) begin
    if (rst_n && en) begin
        $fdisplay(file_out, "%0d", nco_out);

        sample_count = sample_count + 1;

        if (sample_count == N_SAMPLES) begin
            $display("DONE, samples = %0d", sample_count);

            $fclose(file_out);

            #10;
            $finish;
        end
    end
end

endmodule