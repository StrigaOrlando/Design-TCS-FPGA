module nco_dither_top #(
    parameter PHASE_W  = 7,
    parameter AMP_W    = 6,
    parameter ROM_FILE = "lut_signal2.hex"
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    en,
    input  wire [PHASE_W-1:0]      fcw,
    output wire signed [AMP_W-1:0] nco_out,
    output wire [PHASE_W-1:0]      phase_dbg,
    output wire                    dither_dbg,
    output wire [PHASE_W-1:0]      addr_dbg,
    output wire [25:0]             lfsr_dbg
);

wire [PHASE_W-1:0] phase;
wire [25:0] lfsr_state;
wire [PHASE_W-1:0] addr_dithered;

/* ================================
   Фазовый аккумулятор
   ================================ */
phase_accumulator #(
    .PHASE_W(PHASE_W)
) u_phase_accumulator (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (en),
    .fcw   (fcw),
    .phase (phase)
);

/* ================================
   Твой LFSR26
   ================================ */
lfsr26 u_lfsr26 (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (en),
    .state (lfsr_state)
);

/* ================================
   Дизеринг:
   используем младший бит LFSR
   0 -> +0
   1 -> +1
   ================================ */
assign addr_dithered = phase + lfsr_state[0];

/* ================================
   LUT / ROM
   ================================ */
nco_rom #(
    .ADDR_W   (PHASE_W),
    .DATA_W   (AMP_W),
    .ROM_FILE (ROM_FILE)
) u_nco_rom (
    .addr (addr_dithered),
    .data (nco_out)
);

/* ================================
   Отладочные сигналы
   ================================ */
assign phase_dbg  = phase;
assign dither_dbg = lfsr_state[0];
assign addr_dbg   = addr_dithered;
assign lfsr_dbg   = lfsr_state;

endmodule