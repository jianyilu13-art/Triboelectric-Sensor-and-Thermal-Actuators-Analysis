%% MATLAB: Repeatability / Peak Analysis (Unified Method)
clear; clc; close all;

%% --- Step 1: CSV files & sampling rate ---
files = {"10HZCD.csv", "5HZCD.csv", "2HZCD.csv"};
frequencies = [10, 5, 2];   % input frequencies
numFiles = numel(files);

Fs = 5000;  % sampling rate in Hz
voltage_column = 2;  % column containing voltage

% Store results
mean_peaks = zeros(numFiles,1);
std_peaks  = zeros(numFiles,1);
repeatability = zeros(numFiles,1);

%% --- Step 2: Loop through each file ---
for k = 1:numFiles
    % Load CSV
    data = readmatrix(files{k});
    voltage = data(:, voltage_column);
    voltage = voltage(~isnan(voltage));
    
    % Remove global DC offset
    voltage = voltage - mean(voltage);
    
    % --- Smooth signal slightly to remove small noise ---
    smooth_window = 5; % small fixed window for all frequencies
    voltage_smooth = smooth(voltage, smooth_window);
    
    % --- Detect peaks ---
    period_samples = round(Fs/frequencies(k));
    min_peak_distance = round(period_samples*0.8);  % ensure one peak per impact
    min_peak_height = 0.1 * max(abs(voltage_smooth)); % 10% of max signal
    
    % Positive peaks
    [pks_pos, locs_pos] = findpeaks(voltage_smooth, ...
                                     'MinPeakDistance', min_peak_distance, ...
                                     'MinPeakHeight', min_peak_height);
    % Negative peaks
    [pks_neg, locs_neg] = findpeaks(-voltage_smooth, ...
                                     'MinPeakDistance', min_peak_distance, ...
                                     'MinPeakHeight', min_peak_height);
    pks_neg = -pks_neg;
    
    % --- Combine absolute peaks ---
    peaks = abs([pks_pos; pks_neg]);
    locs_combined = [locs_pos; locs_neg];
    [locs_combined, sort_idx] = sort(locs_combined);
    peaks = peaks(sort_idx);
    
    % --- Compute statistics ---
    mean_peaks(k) = mean(peaks);
    std_peaks(k) = std(peaks);
    repeatability(k) = (std_peaks(k)/mean_peaks(k))*100;
    
    % --- Plot waveform with detected peaks ---
    figure(k);
    plot(voltage_smooth);
    hold on;
    scatter(locs_combined, peaks, 'r', 'filled');
    xlabel('Sample Number'); ylabel('Voltage (mV)');
    title(sprintf('Sensor Response at %d Hz', frequencies(k)));
    legend('Smoothed Signal', 'Detected Peaks');
    grid on;
end

%% --- Step 3: Display results summary ---
disp('=== Repeatability Results ===');
for k = 1:numFiles
    fprintf('%d Hz: Mean Peak = %.2f mV, Std = %.2f mV, Repeatability = %.2f %%\n', ...
        frequencies(k), mean_peaks(k), std_peaks(k), repeatability(k));
end
