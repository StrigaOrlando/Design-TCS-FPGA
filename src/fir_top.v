`timescale 1ns / 1ps

module top_fixed (
    input  wire clk,
    input  wire reset,
    input  wire clk_enable,
    input  wire signed [15:0] filter_in,
    output wire signed [15:0] filter_out
);

    (* KEEP = "TRUE" *) wire signed [15:0] filter_out_internal;

    (* DONT_TOUCH = "TRUE" *)
    fir_hpf_fixed u_fir_hpf_fixed (
        .clk        (clk),
        .reset      (reset),
        .clk_enable (clk_enable),
        .filter_in  (filter_in),
        .filter_out (filter_out_internal)
    );

    assign filter_out = filter_out_internal;

endmodule