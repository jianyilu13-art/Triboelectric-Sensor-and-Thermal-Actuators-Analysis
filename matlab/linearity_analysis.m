% MATLAB code to analyze triboelectric sensor linearity & sensitivity
% using robust maximum voltage in mV from 4 CSV files

clear; clc; close all;

% === Step 1: CSV files ===
files = {
    "CleanedCSV/cd1_cleaned.csv"
    "CleanedCSV/cd2_cleaned.csv"
    "CleanedCSV/cd3_cleaned.csv"
    "CleanedCSV/cd4_cleaned.csv"
};
numFiles = numel(files);

% Known forces for each ball (N) – update as needed
known_forces = [0.78, 0.43, 0.165, 0.089];  

% Voltage column index (adjust to the column that contains voltage in your CSV)
voltage_column = 2;  % <-- change this if voltage is in another column

% Store results
all_forces = zeros(numFiles,1);
all_voltages = zeros(numFiles,1);

for k = 1:numFiles
    % Load CSV data (skip header if needed)
    data = readmatrix(files{k}, 'NumHeaderLines', 0);
    
    % Extract voltage column
    voltage = data(:, voltage_column);
    
    % Remove NaNs
    voltage = voltage(~isnan(voltage));
    
    % Optional: filter out unrealistic spikes
    voltage(voltage > 1000) = [];  % discard any values > 1000 mV
    
    % Take maximum voltage
    voltage_peak = max(voltage);
    
    % Store results
    all_forces(k) = known_forces(k);
    all_voltages(k) = voltage_peak;
    
    % Optional: plot the waveform for verification
    figure(k);
    plot(voltage);
    xlabel('Sample Number');
    ylabel('Voltage (mV)');
    title(['Voltage waveform - ' files{k}]);
end

% === Step 2: Linear fit (voltage vs force) ===
p = polyfit(all_forces, all_voltages, 1);
fit_voltage = polyval(p, all_forces);

% Sensitivity = slope (mV/N)
sensitivity = p(1);

% Linearity = R²
SS_res = sum((all_voltages - fit_voltage).^2);
SS_tot = sum((all_voltages - mean(all_voltages)).^2);
R2 = 1 - SS_res/SS_tot;

% === Step 3: Plot summary ===
figure;
scatter(all_forces, all_voltages, 80, 'filled', 'DisplayName', 'Experimental Data');
hold on;
plot(all_forces, fit_voltage, '-r', 'LineWidth', 2, 'DisplayName', 'Linear Fit');
xlabel('Force (N)');
ylabel('Peak Voltage (mV)');
title('Triboelectric Sensor Linearity & Sensitivity');
legend('show');
grid on;

% === Step 4: Display results ===
disp('=== Results ===');
fprintf('Sensitivity = %.4f mV/N\n', sensitivity);
fprintf('Linearity (R²) = %.4f\n', R2);



