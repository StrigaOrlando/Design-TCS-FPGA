clear;
clc;
close all;

%% =========================
% ПАРАМЕТРЫ
% =========================
LUT_LEN    = 128;   % длина LUT
ACTIVE_LEN = 64;    % длина синус-участка
PAC_BITS   = 6;     % разрядность

SIGNED_MAX = 2^(PAC_BITS-1) - 1;  % 31
SIGNED_MIN = -2^(PAC_BITS-1);     % -32

%% =========================
% 1. ФОРМИРОВАНИЕ СИГНАЛА
% =========================
lut_real = zeros(1, LUT_LEN);

n = 0:ACTIVE_LEN-1;

% один период синуса
lut_real(1:ACTIVE_LEN) = sin(2*pi*n/ACTIVE_LEN);

% вторая половина = 0

%% =========================
% 2. КВАНТОВАНИЕ
% =========================
lut_quant = round(lut_real * SIGNED_MAX);

% ограничение диапазона
lut_quant(lut_quant > SIGNED_MAX) = SIGNED_MAX;
lut_quant(lut_quant < SIGNED_MIN) = SIGNED_MIN;

%% =========================
% 3. ГРАФИКИ
% =========================
x = 0:LUT_LEN-1;

% идеальный сигнал
figure;
plot(x, lut_real, 'LineWidth', 2);
hold on;
stem(x, lut_real, 'filled');
grid on;
title('Идеальный сигнал №2');
xlabel('Номер отсчёта');
ylabel('Амплитуда');
legend('Линия', 'Отсчёты');

% квантованный сигнал
figure;
plot(x, lut_quant, 'LineWidth', 2);
hold on;
stem(x, lut_quant, 'filled');
grid on;
title('Квантованный сигнал (signed 6-bit)');
xlabel('Номер отсчёта');
ylabel('Код амплитуды');
legend('Линия', 'Отсчёты');

% сравнение
figure;
plot(x, lut_real, 'LineWidth', 2);
hold on;
plot(x, lut_quant / SIGNED_MAX, 'o-', 'LineWidth', 1.5, 'MarkerSize', 4);
grid on;
title('Сравнение сигналов');
xlabel('Номер отсчёта');
ylabel('Амплитуда');
legend('Идеальный', 'Квантованный', 'Location', 'best');

% ошибка квантования
figure;
plot(x, lut_real - lut_quant / SIGNED_MAX, 'LineWidth', 1.5);
grid on;
title('Ошибка квантования');
xlabel('Номер отсчёта');
ylabel('Ошибка');

%% =========================
% 4. СОХРАНЕНИЕ В ФАЙЛЫ
% =========================

% HEX (для $readmemh)
fid = fopen('lut_signal2.hex', 'w');

for k = 1:LUT_LEN
    val = lut_quant(k);

    if val < 0
        val_tc = 2^PAC_BITS + val;  % two's complement
    else
        val_tc = val;
    end

    fprintf(fid, '%02X\n', val_tc);
end

fclose(fid);

% BIN (для $readmemb)
fid = fopen('lut_signal2.bin', 'w');

for k = 1:LUT_LEN
    val = lut_quant(k);

    if val < 0
        val_tc = 2^PAC_BITS + val;
    else
        val_tc = val;
    end

    fprintf(fid, '%s\n', dec2bin(val_tc, PAC_BITS));
end

fclose(fid);

%% =========================
% 5. ПРОВЕРКА
% =========================
disp('Первые 16 значений LUT:');
disp(lut_quant(1:16));