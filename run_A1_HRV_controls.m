function run_A1_HRV_controls(matFile, outXlsx, tileFreq)
% RUN_A1_HRV_CONTROLS  Per-subject HRV over CAP A1 events, 15 control subjects,
% using YOUR existing ShaweenHRV pipeline (pan_tompkin + hrv_*_edit).
%
% This adapts ShaweenHRV.m into a proper per-subject loop over the A1 cells in
% CAP_ECG_Epochs.mat (ECG_A1 = cell{1,15}, each 60000 x N_events, fs = 200 Hz).
%
% USAGE
%   run_A1_HRV_controls('CAP_ECG_Epochs.mat', 'A1_HRV_per_control_subject.xlsx', false)
%
% INPUTS
%   matFile  path to CAP_ECG_Epochs.mat (must contain ECG_A1).
%   outXlsx  output spreadsheet path.
%   tileFreq logical. If true, reproduces ShaweenHRV.m's repmat(rr,1,70) before
%            the frequency/nonlinear step. DEFAULT false (recommended): each
%            column here is a full 5-minute epoch (~300 R-R intervals), so the
%            x70 tiling is unnecessary and creates artificial periodicity that
%            distorts LF/HF/total-power and the nonlinear metrics. Set true only
%            to match the older "Average CAP Features over Phase-A segments" file.
%
% REQUIRES on the path: pan_tompkin.m, hrv_time_edit.m, hrv_freq_edit.m,
%   hrv_nonlinear_edit.m, hrv_fragmentation_edit.m, and the PhysioZoo mhrv
%   helpers they call (poincare, dfa_edit, mse_edit, *_defaults.mat).
%
% Prepared for the Frontiers in Physiology revision. CC-BY 4.0.

if nargin < 1 || isempty(matFile), matFile = 'CAP_ECG_Epochs.mat'; end
if nargin < 2 || isempty(outXlsx), outXlsx = 'A1_HRV_per_control_subject.xlsx'; end
if nargin < 3 || isempty(tileFreq), tileFreq = false; end
fs = 200;

S = load(matFile);
assert(isfield(S,'ECG_A1'), 'CAP_ECG_Epochs.mat must contain ECG_A1.');
ECG_A1 = S.ECG_A1;                 % cell {1,15}
nSubj  = numel(ECG_A1);

subjMean = [];  featNames = {};  rowNames = {};
for s = 1:nSubj
    all_ECG = ECG_A1{s};                         % 60000 x N_events
    nev = size(all_ECG,2);
    perEvent = [];
    for i = 1:nev
        sig = double(all_ECG(:,i));
        [~,qrs_i] = pan_tompkin(sig, fs, 0);
        if numel(qrs_i) <= 5
            [~,qrs_i] = pan_tompkin(sig, fs/2, 0);
        end
        if numel(qrs_i) <= 5
            [~,qrs_i] = pan_tompkin(sig(500:end), fs, 0);
        end
        if numel(qrs_i) <= 5, continue; end

        rr = diff(qrs_i)./fs;                     % R-R intervals (seconds)
        rr = rr(rr>0.33 & rr<2.0);                % physiological guard
        if numel(rr) < 12, continue; end

        % --- quality control consistent with the manuscript ---
        hr = 60/mean(rr);
        sdnn_ms = std(rr)*1000;
        if hr < 50 || sdnn_ms > 300, continue; end

        kurt = kurtosis(rr); skew = skewness(rr);
        rr_freq = rr;
        if tileFreq, rr_freq = repmat(rr,1,70); end   % off by default (see header)

        td = hrv_time_edit(rr, 50/1000);
        time_features = [td.AVNN/1000; td.SDNN/1000; td.RMSSD/1000; ...
                         td.(sprintf('pNN%d',50))/100; td.SEM/1000];
        fd = table2array(hrv_freq_edit(rr_freq));     % keep ms^2 (no /1000 here)
        nl = table2array(hrv_nonlinear_edit(rr_freq));
        fr = table2array(hrv_fragmentation_edit(rr))./100;

        vec = [time_features; fd'; nl'; fr'; kurt; skew];
        if isempty(featNames)
            featNames = [string(td.Properties.VariableNames), ...
                         "BETA","HF_NORM","HF_PEAK","HF_POWER","LF_NORM","LF_PEAK",...
                         "LF_POWER","LF_TO_HF","TOTAL_POWER","VLF_NORM","VLF_POWER",...
                         "SD1","SD2","alpha1","alpha2","SampEn","PIP","IALS","PSS","PAS",...
                         "Kurtosis","Skewness"];
        end
        perEvent = [perEvent, vec]; %#ok<AGROW>
    end
    if isempty(perEvent)
        subjMean(:,s) = nan(numel(featNames),1);  %#ok<AGROW>
    else
        subjMean(:,s) = mean(perEvent,2,'omitnan'); %#ok<AGROW>
    end
    rowNames{s} = sprintf('Control %d', s); %#ok<AGROW>
    fprintf('Subject %2d: %d A1 events, %d usable\n', s, nev, size(perEvent,2));
end

T = array2table(subjMean', 'VariableNames', cellstr(featNames), 'RowNames', rowNames);
writetable(T, outXlsx, 'WriteRowNames', true, 'Sheet', 'Per-subject A1 HRV');

% group summary
G = table(mean(subjMean,2,'omitnan'), std(subjMean,0,2,'omitnan'), ...
          'VariableNames', {'mean','SD'}, 'RowNames', cellstr(featNames));
writetable(G, outXlsx, 'WriteRowNames', true, 'Sheet', 'Group summary');
fprintf('\nWritten: %s\n', outXlsx);
end
