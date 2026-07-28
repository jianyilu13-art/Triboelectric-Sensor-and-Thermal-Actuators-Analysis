%% === Configuration ===
files = {'cd1.csv','cd2.csv','cd3.csv','cd4.csv'};
xlimits = [0 4];
minPeakDistance = 0.1;
plotRaw = true;
outputFolder = 'CleanedCSV';

%% === Create output folder ===
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% === Loop through files ===
figure;
hold on;
colors = hsv(length(files));

for k = 1:length(files)

    filename = files{k};

    %% Step 1: Detect header line safely
    fid = fopen(filename);
    lineNum = 0;

    while true
        line = fgetl(fid);

        if ~ischar(line)
            error(['Header line not found in file: ' filename]);
        end

        lineNum = lineNum + 1;

        if contains(line,'index')
            break;
        end
    end

    fclose(fid);

    %% Step 2: Import data
    opts = delimitedTextImportOptions('NumVariables',2);
    opts.DataLines = [lineNum+1 Inf];
    opts.Delimiter = ',';
    opts.VariableNames = {'index','CH1_Voltage_mV'};
    opts.VariableTypes = {'double','double'};

    data = readtable(filename,opts);

    voltages = data.CH1_Voltage_mV;

    %% Clean NaNs/Infs
    if any(isnan(voltages))
        voltages = fillmissing(voltages,'linear');
    end

    voltages(~isfinite(voltages)) = 0;
    voltages = voltages(:);

    %% ============================================================
    %% NEW: Remove 50 Hz power-line noise
    %% ============================================================

    N = length(voltages);
    Fs = N/4;              % 4-second recording

    d = designfilt('bandstopiir', ...
        'FilterOrder',2,...
        'HalfPowerFrequency1',49,...
        'HalfPowerFrequency2',51,...
        'SampleRate',Fs);

    voltages = filtfilt(d,voltages);

    %% ============================================================

    %% Step 3: Convert index to time
    time = linspace(0,4,N);

    %% Step 4: Peak detection
    minSamples = round(minPeakDistance*Fs);

    [pks,locs] = findpeaks(voltages,...
        'MinPeakDistance',minSamples);

    cleanedSignal = zeros(size(voltages));

    for i = 1:length(locs)

        startIdx = max(locs(i)-minSamples/2,1);
        endIdx = min(locs(i)+minSamples/2,N);

        [maxVal,maxLoc] = max(voltages(round(startIdx):round(endIdx)));

        peakIdx = round(startIdx)-1+maxLoc;

        cleanedSignal(peakIdx)=maxVal;

    end

    %% Step 5: Plot
    [~,name,~] = fileparts(filename);

    if plotRaw
        plot(time,voltages,...
            'Color',[0.8 0.8 0.8],...
            'LineWidth',1);
    end

    plot(time,cleanedSignal,...
        'Color',colors(k,:),...
        'LineWidth',1.5,...
        'DisplayName',name);

    %% Step 6: Save cleaned CSV
    cleanedTable = table(...
        time',...
        cleanedSignal,...
        'VariableNames',{'Time_s','Voltage_mV'});

    writetable(...
        cleanedTable,...
        fullfile(outputFolder,[name '_cleaned.csv']));
end

xlabel('Time (s)');
ylabel('Voltage (mV)');
title('Merged Peak Signals (Max Only per Event)');
grid on;
xlim(xlimits);
legend show;
hold off;

disp(['Cleaned CSV files saved to folder: ' outputFolder]);