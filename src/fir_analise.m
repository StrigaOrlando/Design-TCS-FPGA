clear; clc; close all;

file = 'C:\Users\maria\Desktop\4_2\project_1\project_1.sim\sim_1\behav\xsim\fir_impulse_response.txt';

txt = fileread(file);

tokens = regexp(txt, '[-+]?\d+', 'match');
y = str2double(tokens(:));

disp(size(y));
disp([min(y), max(y)]);

figure;
stem(y(1:60), 'filled');
grid on;
title('Импульсная характеристика из Vivado');
xlabel('n');
ylabel('filter\_out');

h = y / 32768;

Fs = 120e6;
Nfft = 4096;

H = fft(h, Nfft);
f = (0:Nfft/2-1) * Fs / Nfft;
mag = 20*log10(abs(H(1:Nfft/2)) + 1e-12);

figure;
plot(f/1e6, mag, 'LineWidth', 1.2);
grid on;
xlabel('Frequency, MHz');
ylabel('Magnitude, dB');
title('АЧХ fixed-point FIR из Vivado');
xlim([0 60]);
ylim([-100 10]);
