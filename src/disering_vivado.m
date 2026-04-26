clear;
clc;
close all;

%% =========================================================
%  ПАРАМЕТРЫ
% ==========================================================
fclk = 1e6;          % частота дискретизации, Гц
fmax_plot = 100e3;   % верхняя граница спектра для отображения, Гц
ymin_plot = -120;    % нижняя граница по оси Y для спектров, дБ

%% =========================================================
%  ЗАГРУЗКА ДАННЫХ ИЗ ФАЙЛОВ VIVADO
% ==========================================================
x1 = load('nco_out_no_dither.txt');   % сигнал без дизеринга
x2 = load('nco_out_dither.txt');      % сигнал с дизерингом

x1 = x1(:);
x2 = x2(:);

N = min(length(x1), length(x2));
x1 = x1(1:N);
x2 = x2(1:N);

fprintf('Число отсчётов без дизеринга: %d\n', length(x1));
fprintf('Число отсчётов с дизерингом:  %d\n', length(x2));

%% =========================================================
%  ВРЕМЕННАЯ ОСЬ
% ==========================================================
t = (0:N-1) / fclk * 1e6;   % время, мкс

%% =========================================================
%  ВРЕМЕННЫЕ ГРАФИКИ
% ==========================================================
figure;
plot(t, x1, 'LineWidth', 1.2);
hold on;
plot(t, x2, 'LineWidth', 1.2);
grid on;
title('Сравнение сигналов NCO во временной области');
xlabel('Время, мкс');
ylabel('Амплитуда');
legend('Без дизеринга', 'С дизерингом');

idx_t = t <= 40;   % участок около одного периода

figure;
plot(t(idx_t), x1(idx_t), 'LineWidth', 1.5);
hold on;
plot(t(idx_t), x2(idx_t), 'LineWidth', 1.5);
grid on;
title('Участок сигнала');
xlabel('Время, мкс');
ylabel('Амплитуда');
legend('Без дизеринга', 'С дизерингом');

%% =========================================================
%  FFT
% ==========================================================
s1 = x1 - mean(x1);
s2 = x2 - mean(x2);

S1 = fft(s1);
S2 = fft(s2);

S1 = abs(S1(1:floor(N/2)));
S2 = abs(S2(1:floor(N/2)));

S1 = S1 / max(S1);
S2 = S2 / max(S2);

S1_dB = 20 * log10(S1 + 1e-12);
S2_dB = 20 * log10(S2 + 1e-12);

f = (0:length(S1)-1) * fclk / N;

%% =========================================================
%  SFDR БЕЗ ДИЗЕРИНГА
% ==========================================================
[main1, idx_main1] = max(S1(2:end));
idx_main1 = idx_main1 + 1;

S1_tmp = S1;
guard = 3;

left1  = max(1, idx_main1 - guard);
right1 = min(length(S1_tmp), idx_main1 + guard);

S1_tmp(left1:right1) = 0;

[spur1, idx_spur1] = max(S1_tmp);

SFDR1 = 20 * log10(main1 / (spur1 + 1e-12));

%% =========================================================
%  SFDR С ДИЗЕРИНГОМ
% ==========================================================
[main2, idx_main2] = max(S2(2:end));
idx_main2 = idx_main2 + 1;

S2_tmp = S2;

left2  = max(1, idx_main2 - guard);
right2 = min(length(S2_tmp), idx_main2 + guard);

S2_tmp(left2:right2) = 0;

[spur2, idx_spur2] = max(S2_tmp);

SFDR2 = 20 * log10(main2 / (spur2 + 1e-12));

%% =========================================================
%  ПОДГОТОВКА ДАННЫХ ДЛЯ ОТОБРАЖЕНИЯ СПЕКТРА
% ==========================================================
idx_plot = f <= fmax_plot;

f_plot  = f(idx_plot);
S1_plot = S1_dB(idx_plot);
S2_plot = S2_dB(idx_plot);

% Поиск заметных пиков
minDist = 1;
[pks1, locs1] = findpeaks(S1_plot, 'MinPeakHeight', -80, 'MinPeakDistance', minDist);
[pks2, locs2] = findpeaks(S2_plot, 'MinPeakHeight', -80, 'MinPeakDistance', minDist);

%% =========================================================
%  СПЕКТР БЕЗ ДИЗЕРИНГА (ПАЛОЧКАМИ)
% ==========================================================
figure;
stem(f_plot/1e3, S1_plot, 'filled', 'MarkerSize', 3);
hold on;
stem(f_plot(locs1)/1e3, pks1, 'r', 'filled', 'LineWidth', 1.2);
grid on;
title('Спектр NCO без дизеринга');
xlabel('Частота, кГц');
ylabel('Амплитуда, дБ');
ylim([ymin_plot 5]);

for k = 1:min(length(locs1), 5)
    text(f_plot(locs1(k))/1e3, pks1(k)+3, ...
        sprintf('%.1f кГц', f_plot(locs1(k))/1e3), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
end

%% =========================================================
%  СПЕКТР С ДИЗЕРИНГОМ (ПАЛОЧКАМИ)
% ==========================================================
figure;
stem(f_plot/1e3, S2_plot, 'filled', 'MarkerSize', 3);
hold on;
stem(f_plot(locs2)/1e3, pks2, 'r', 'filled', 'LineWidth', 1.2);
grid on;
title('Спектр NCO с дизерингом');
xlabel('Частота, кГц');
ylabel('Амплитуда, дБ');
ylim([ymin_plot 5]);

for k = 1:min(length(locs2), 5)
    text(f_plot(locs2(k))/1e3, pks2(k)+3, ...
        sprintf('%.1f кГц', f_plot(locs2(k))/1e3), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
end

%% =========================================================
%  СРАВНЕНИЕ СПЕКТРОВ
% ==========================================================
figure;
plot(f_plot/1e3, S1_plot, 'LineWidth', 1.2);
hold on;
plot(f_plot/1e3, S2_plot, 'LineWidth', 1.2);
grid on;
title('Сравнение спектров NCO');
xlabel('Частота, кГц');
ylabel('Амплитуда, дБ');
legend('Без дизеринга', 'С дизерингом');
ylim([ymin_plot 5]);

%% =========================================================
%  ВЫВОД РЕЗУЛЬТАТОВ В КОНСОЛЬ
% ==========================================================
fprintf('\n================ РЕЗУЛЬТАТЫ ================\n');

fprintf('\nБез дизеринга:\n');
fprintf('Основной пик: %.3f кГц\n', f(idx_main1)/1e3);
fprintf('Наибольший spur: %.3f кГц\n', f(idx_spur1)/1e3);
fprintf('SFDR = %.2f дБ\n', SFDR1);

fprintf('\nС дизерингом:\n');
fprintf('Основной пик: %.3f кГц\n', f(idx_main2)/1e3);
fprintf('Наибольший spur: %.3f кГц\n', f(idx_spur2)/1e3);
fprintf('SFDR = %.2f дБ\n', SFDR2);

fprintf('\nИзменение SFDR: %.2f дБ\n', SFDR2 - SFDR1);
fprintf('============================================\n');