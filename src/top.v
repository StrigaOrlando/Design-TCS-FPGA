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

    // =========================
    // Сигналы VIO и тактирования
    // =========================
    // Раньше использовались и входы, и выходы VIO
    // Для LFSR нам достаточно только выходов VIO: reset и enable
    // wire [15:0] w_probe_in0;
    wire [1:0]  w_probe_out0;
    wire        w_clk_out1;

    // ===== Clock wizard =====
    clk_wiz_0 u_cw0(
        .reset   (1'b0),
        .clk_in1 (sysclk),
        .clk_out1(w_clk_out1),
        .locked  ()
    );

    // ===== VIO =====
    // probe_out0[0] = reset
    // probe_out0[1] = enable
    vio_0 u_vio0(
        .clk        (w_clk_out1),
        .probe_out0 (w_probe_out0)
    );

    // =========================================================
    // СТАРАЯ ЛОГИКА ИЗ ЛАБЫ СО СЧЁТЧИКОМ - ОСТАВЛЕНА КАК ИСТОРИЯ
    // =========================================================
    /*
    // Входы платы показываем в VIO (как было)
    assign w_probe_in0[3:0] = btn[3:0];
    assign w_probe_in0[5:4] = sw[1:0];
    assign w_probe_in0[15:6] = 10'd0; // чтобы не было "висячих" бит

    // ===== Счётчик до 8221028 и повтор =====
    localparam [22:0] MAX_CNT = 23'd8221028;

    reg [22:0] main_cnt   = 23'd0; // 0..8221028
    reg [1:0]  wrap_cnt   = 2'd0;  // сколько раз случился сброс main_cnt
    reg        led_blink  = 1'b0;  // видимое мигание

    wire wrap_pulse = (main_cnt == MAX_CNT); // 1 такт в момент достижения MAX

    // Для 50 МГц: один "круг" ~0.164 c.
    // Если переключать LED раз в 3 переполнения, получим ~1 Гц.
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
    */

    // =========================
    // НОВАЯ ЛОГИКА: LFSR
    // =========================
    // Полином для варианта 6:
    // [26, 24, 21, 17, 16, 14, 13, 11, 7, 6, 4, 1]

    reg [25:0] lfsr_state = 26'b1;

    wire feedback;
    wire rst_n;
    wire en;

    // Сброс:
    // - физическая кнопка btn[0]
    // - виртуальный reset из VIO
    // Если нажата кнопка или выставлен reset в VIO, регистр сбрасывается в начальное состояние
    assign rst_n = ~btn[0] & ~w_probe_out0[0];

    // Разрешение работы LFSR через VIO
    assign en = w_probe_out0[1];

    // Линейная обратная связь согласно полиному
    assign feedback = lfsr_state[25] ^ lfsr_state[23] ^ lfsr_state[20] ^
                      lfsr_state[16] ^ lfsr_state[15] ^ lfsr_state[13] ^
                      lfsr_state[12] ^ lfsr_state[10] ^ lfsr_state[6]  ^
                      lfsr_state[5]  ^ lfsr_state[3]  ^ lfsr_state[0];

    // Работа LFSR
    always @(posedge w_clk_out1) begin
        if (!rst_n)
            lfsr_state <= 26'b1;                  // ненулевое начальное состояние
        else if (en)
            lfsr_state <= {lfsr_state[24:0], feedback};
    end

    // =========================
    // Выходы на светодиоды
    // =========================
    // RGB были под VIO в лабораторной работе 1
    /*
    assign led4_b = w_probe_out0[9];
    assign led4_g = w_probe_out0[8];
    assign led4_r = w_probe_out0[7];
    assign led5_b = w_probe_out0[6];
    assign led5_g = w_probe_out0[5];
    assign led5_r = w_probe_out0[4];

    // led[0] - мигание от счётчика, led[3:1] - управляем из VIO
    assign led[0]   = led_blink;
    assign led[3:1] = w_probe_out0[3:1];
    */

    // Для LFSR выводим младшие 4 бита состояния на обычные LED
    assign led = lfsr_state[3:0];

    // RGB-светодиоды из лабораторной работы 1
    assign led4_b = 1'b0;
    assign led4_g = 1'b0;
    assign led4_r = 1'b0;
    assign led5_b = 1'b0;
    assign led5_g = 1'b0;
    assign led5_r = 1'b0;

    // =========================
    // ILA
    // =========================
    // Старая конфигурация ILA под счётчик:
    /*
    ila_0 u_ila0(
        .clk   (w_clk_out1),
        .probe0(main_cnt),
        .probe1(wrap_pulse),
        .probe2(wrap_cnt),
        .probe3(led_blink)
    );
    */

    // Новая конфигурация ILA под LFSR:
    // probe0 = состояние LFSR
    // probe1 = rst_n
    // probe2 = en
    ila_1 u_ila0(
        .clk   (w_clk_out1),
        .probe0(lfsr_state),
        .probe1(rst_n),
        .probe2(en)
    );

endmodule