module top2(
    input  wire        sysclk,
    input  wire [1:0]  sw,
    output wire        led4_b,
    output wire        led4_g,
    output wire        led4_r,
    output wire        led5_b,
    output wire        led5_g,
    output wire        led5_r,
    output wire [3:0]  led,
    input  wire [3:0]  btn
);

    wire [15:0] w_probe_in0;
    wire [15:0] w_probe_out0;
    wire        w_clk_out1;

    // ===== Clock wizard =====
    clk_wiz_0 u_cw0(
        .reset   (1'b0),
        .clk_in1 (sysclk),
        .clk_out1(w_clk_out1),
        .locked  ()
    );

    // ===== VIO =====
    vio_0 u_vio0(
        .clk        (w_clk_out1),
        .probe_in0  (w_probe_in0),
        .probe_out0 (w_probe_out0)
    );

    // Входы платы показываем в VIO 
    assign w_probe_in0[3:0] = btn[3:0];
    assign w_probe_in0[5:4] = sw[1:0];
    assign w_probe_in0[15:6] = 10'd0; 

    // ===== Счётчик до 8221028 и повтор =====
    localparam [22:0] MAX_CNT = 23'd8221028;

    reg [22:0] main_cnt   = 23'd0; // 0..8221028
    reg [1:0]  wrap_cnt   = 2'd0;  // сколько раз случился сброс main_cnt
    reg        led_blink  = 1'b0;  // видимое мигание

    wire wrap_pulse = (main_cnt == MAX_CNT); // 1 такт в момент достижения MAX

 
    localparam [1:0] WRAPS_PER_TOGGLE = 2'd2; // 0,1,2 -> на 3-м wrap переключаем

    always @(posedge w_clk_out1) begin
        // Главный счётчик
        if (wrap_pulse)
            main_cnt <= 23'd0;
        else
            main_cnt <= main_cnt + 1'b1;

        // Делитель "по переполнениям" для мигания
        if (wrap_pulse) begin
            if (wrap_cnt == WRAPS_PER_TOGGLE) begin
                wrap_cnt  <= 2'd0;
                led_blink <= ~led_blink;
            end else begin
                wrap_cnt <= wrap_cnt + 1'b1;
            end
        end
    end

    // ===== Выходы на светодиоды =====
    assign led4_b = w_probe_out0[9];
    assign led4_g = w_probe_out0[8];
    assign led4_r = w_probe_out0[7];
    assign led5_b = w_probe_out0[6];
    assign led5_g = w_probe_out0[5];
    assign led5_r = w_probe_out0[4];

    // led[0] - мигание от счётчика, led[3:1] - управляем из VIO
    assign led[0]   = led_blink;
    assign led[3:1] = w_probe_out0[3:1];

    // ===== ILA  =====

    ila_0 u_ila0(
        .clk   (w_clk_out1),
        .probe0(main_cnt),
        .probe1(wrap_pulse),
        .probe2(wrap_cnt),
        .probe3(led_blink)
    );

endmodule