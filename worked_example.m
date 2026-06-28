function T = worked_example(csvFile, outCsv)
% WORKED_EXAMPLE  End-to-end demonstration of the CAP-HRV pipeline on the
% bundled demo dataset. For each CAP A1-event ECG epoch it detects R-peaks
% (Pan-Tompkins), then computes time-domain and fragmentation HRV (always) and
% frequency-domain and nonlinear HRV (if the PhysioZoo mhrv toolbox is on the
% path), and writes a per-epoch feature table.
%
% USAGE
%   worked_example                              % uses bundled demo_CAP_ECG_A1.csv
%   T = worked_example('demo_CAP_ECG_A1.csv', 'demo_output.csv');
%
% INPUT
%   csvFile : columns = 5-minute CAP A1-event ECG epochs, fs = 200 Hz.
%             The bundled demo (demo_CAP_ECG_A1.csv) is FULLY SYNTHETIC
%             (5 epochs) and is provided only to exercise the pipeline end to
%             end; it is not physiological data.
%
% REQUIRES on the path: pan_tompkin.m, hrv_time_edit.m, hrv_fragmentation_edit.m,
%   and (optionally) hrv_freq_edit.m + hrv_nonlinear_edit.m with the PhysioZoo
%   mhrv toolbox (https://physiozoo.com). Without mhrv, the example still runs
%   and reports the time-domain and fragmentation features.
%
% Prepared for the Frontiers in Physiology (Technology and Code) submission.

if nargin < 1 || isempty(csvFile), csvFile = 'demo_CAP_ECG_A1.csv'; end
if nargin < 2 || isempty(outCsv),  outCsv  = 'demo_output.csv';      end
fs = 200;

ECG = readmatrix(csvFile);                 % 60000 x nEpochs
nEpochs = size(ECG, 2);
rows = {};
have_mhrv = exist('mhrv.hrv.hrv_freq','file') || exist('hrv_freq_edit','file');

fprintf('Worked example: %d CAP A1-event ECG epochs (fs = %d Hz)\n', nEpochs, fs);
for i = 1:nEpochs
    sig = double(ECG(:,i));

    % --- 1. R-peak detection (with the same fallback ladder as the pipeline) ---
    [~, qrs_i] = pan_tompkin(sig, fs, 0);
    if numel(qrs_i) <= 5, [~, qrs_i] = pan_tompkin(sig, fs/2, 0); end
    if numel(qrs_i) <= 5, [~, qrs_i] = pan_tompkin(sig(500:end), fs, 0); end
    if numel(qrs_i) <= 5
        warning('Epoch %d: too few R-peaks, skipped.', i); continue;
    end

    rr = diff(qrs_i)./fs;                   % R-R intervals (seconds)
    rr = rr(rr > 0.33 & rr < 2.0);          % physiological guard
    if numel(rr) < 12, warning('Epoch %d: <12 RR, skipped.', i); continue; end

    % --- 2. quality control (manuscript criteria) ---
    hr = 60/mean(rr); sdnn_ms = std(rr)*1000;
    if hr < 50 || sdnn_ms > 300
        warning('Epoch %d: failed QC (HR=%.1f, SDNN=%.0f ms), skipped.', i, hr, sdnn_ms);
        continue;
    end

    % --- 3. time-domain + fragmentation (no external dependency) ---
    td = hrv_time_edit(rr, 50/1000);
    fr = table2array(hrv_fragmentation_edit(rr));
    r = struct('Epoch', i, 'nRR', numel(rr), 'HR_bpm', hr, ...
               'AVNN_ms', td.AVNN, 'SDNN_ms', td.SDNN, 'RMSSD_ms', td.RMSSD, ...
               'pNN_pct', td.(sprintf('pNN%d',0))*1, 'SEM_ms', td.SEM, ...
               'PIP', fr(1), 'IALS', fr(2), 'PSS', fr(3), 'PAS', fr(4));

    % --- 4. frequency + nonlinear (require PhysioZoo mhrv) ---
    r.LF_HF = NaN; r.DFA_a1 = NaN; r.SampEn = NaN;
    try
        fd = hrv_freq_edit(rr);  nl = hrv_nonlinear_edit(rr);
        r.LF_HF  = local_get(fd, 'LF_TO_HF_LOMB');
        r.DFA_a1 = local_get(nl, 'alpha1');
        r.SampEn = local_get(nl, 'SampEn');
    catch ME
        if i==1, fprintf('  (frequency/nonlinear skipped: %s)\n', ME.message); end
    end
    rows{end+1} = r; %#ok<AGROW>
end

T = struct2table([rows{:}]);
disp(T);
writetable(T, outCsv);
fprintf('\nWritten %s (%d epochs).\n', outCsv, height(T));
if ~have_mhrv
    fprintf(['Note: PhysioZoo mhrv toolbox not found -> frequency/nonlinear ' ...
             'columns are NaN. Install mhrv and re-run for the full feature set.\n']);
end
end

function v = local_get(tbl, field)
    v = NaN;
    try
        nm = tbl.Properties.VariableNames;
        idx = find(strcmpi(nm, field), 1);
        if ~isempty(idx), v = tbl{1, idx}; end
    catch
    end
end
