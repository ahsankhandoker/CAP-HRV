function T = worked_example(csvFile, outCsv)
% WORKED_EXAMPLE  End-to-end demonstration of the CAP-HRV pipeline on the bundled
% demo dataset. For each CAP A1-event ECG epoch it detects R-peaks (Pan-Tompkins)
% and computes the HRV feature set by calling the PhysioZoo mhrv toolbox directly.
%
% USAGE
%   worked_example                              % uses bundled demo_CAP_ECG_A1.csv
%   T = worked_example('demo_CAP_ECG_A1.csv', 'demo_output.csv');
%
% INPUT
%   csvFile : columns = 5-minute CAP A1-event ECG epochs, fs = 200 Hz. The
%             bundled demo (demo_CAP_ECG_A1.csv) is FULLY SYNTHETIC (5 epochs),
%             provided only to exercise the pipeline; it is not physiological data.
%
% REQUIRES on the path: pan_tompkin.m and the PhysioZoo mhrv toolbox
%   (https://physiozoo.com). HRV is computed by mhrv directly; no HRV routine is
%   reimplemented here. mhrv exposes UNPACKAGED function names (hrv_time, hrv_freq,
%   hrv_nonlinear) and must have its defaults loaded once via mhrv_init.

if nargin < 1 || isempty(csvFile), csvFile = 'demo_CAP_ECG_A1.csv'; end
if nargin < 2 || isempty(outCsv),  outCsv  = 'demo_output.csv';      end
fs = 200;

assert(exist('mhrv_init','file')~=0 || exist('mhrv_load_defaults','file')~=0, ...
    ['PhysioZoo mhrv toolbox not found. Install it from https://physiozoo.com and ' ...
     'add its ROOT folder (the one that CONTAINS +mhrv) with addpath(genpath(...)).']);
if     exist('mhrv_init','file'),          mhrv_init;           % load mhrv defaults (once)
elseif exist('mhrv_load_defaults','file'), mhrv_load_defaults;
end

ECG = readmatrix(csvFile);                 % 60000 x nEpochs
nEpochs = size(ECG, 2);
rows = {};
fprintf('Worked example: %d CAP A1-event ECG epochs (fs = %d Hz)\n', nEpochs, fs);

for i = 1:nEpochs
    sig = double(ECG(:,i));

    % --- R-peak detection (with the pipeline's fallback ladder) ---
    [~, qrs_i] = pan_tompkin(sig, fs, 0);
    if numel(qrs_i) <= 5, [~, qrs_i] = pan_tompkin(sig, fs/2, 0); end
    if numel(qrs_i) <= 5, [~, qrs_i] = pan_tompkin(sig(500:end), fs, 0); end
    if numel(qrs_i) <= 5, warning('Epoch %d: too few R-peaks, skipped.', i); continue; end

    rr = diff(qrs_i(:))./fs;                 % R-R intervals (seconds)
    rr = rr(rr > 0.33 & rr < 2.0);
    if numel(rr) < 12, warning('Epoch %d: <12 RR, skipped.', i); continue; end

    hr = 60/mean(rr); sdnn_ms = std(rr)*1000;
    if hr < 50 || sdnn_ms > 300
        warning('Epoch %d: failed QC (HR=%.1f, SDNN=%.0f ms), skipped.', i, hr, sdnn_ms); continue;
    end

    % --- HRV via PhysioZoo mhrv, called DIRECTLY (packaged namespace) ---
    td = mhrv.hrv.hrv_time(rr);
    fd = mhrv.hrv.hrv_freq(rr, 'methods', {'lomb'});
    nl = mhrv.hrv.hrv_nonlinear(rr);

    r = struct('Epoch', i, 'nRR', numel(rr), 'HR_bpm', hr, ...
               'AVNN_ms', local_get(td,{'AVNN'}), 'SDNN_ms', local_get(td,{'SDNN'}), ...
               'RMSSD_ms', local_get(td,{'RMSSD'}), ...
               'LF_HF', local_get(fd,{'LF_to_HF','LF_TO_HF_LOMB','LF_to_HF_LOMB'}), ...
               'DFA_a1', local_get(nl,{'alpha1','DFA_alpha1'}), ...
               'SampEn', local_get(nl,{'SampEn','SampEn_a'}));
    rows{end+1} = r; %#ok<AGROW>
end

if isempty(rows), error('No usable epochs.'); end
T = struct2table([rows{:}]);
disp(T); writetable(T, outCsv);
fprintf('\nWritten %s (%d epochs).\n', outCsv, height(T));
end

function v = local_get(tbl, fields)
    v = NaN;
    try
        nm = tbl.Properties.VariableNames;
        for k = 1:numel(fields)
            idx = find(strcmpi(nm, fields{k}), 1);
            if ~isempty(idx), v = tbl{1, idx}; return; end
        end
    catch
    end
end
