function Overall_HRV_features = ShaweenHRV_mhrv(ecgMatFile)
% SHAWEENHRV_MHRV  HRV feature extraction over CAP A-phase ECG epochs, calling
% the PhysioZoo mhrv toolbox DIRECTLY. This replaces the previous edited copies
% of the mhrv routines (hrv_time_edit / hrv_freq_edit / hrv_nonlinear_edit and
% the standalone poincare / freqband_power / dfa_edit / mse_edit helpers), per
% Reviewer 2: HRV is now computed only by mhrv, so no reimplemented routine can
% diverge from it.
%
% USAGE
%   feats = ShaweenHRV_mhrv('ECG_Epochs.mat')   % variable CAPECG_Epochs (samples x epochs)
%
% REQUIRES on the MATLAB path:
%   - the PhysioZoo mhrv toolbox  (https://physiozoo.com ; https://github.com/physiozoo/mhrv)
%   - pan_tompkin.m
%   - Signal Processing Toolbox
%
% mhrv exposes UNPACKAGED function names (hrv_time / hrv_freq / hrv_nonlinear)
% and requires its defaults to be loaded once via mhrv_init before any hrv_* call.

assert(exist('mhrv_init','file')~=0 || exist('mhrv_load_defaults','file')~=0, ...
    ['PhysioZoo mhrv toolbox not found on the path. Install it from ' ...
     'https://physiozoo.com and add its ROOT folder (the one that CONTAINS +mhrv) ' ...
     'with addpath(genpath(...)).']);
if     exist('mhrv_init','file'),          mhrv_init;           % load mhrv defaults (once)
elseif exist('mhrv_load_defaults','file'), mhrv_load_defaults;
end

fs = 200;                                   % ECG sampling rate (Hz)
b  = load(ecgMatFile);
all_ECG = b.CAPECG_Epochs;                  % samples x epochs
n = size(all_ECG, 2);
Overall_HRV_features = cell(1, n);

for i = 1:n
    sig = double(all_ECG(:, i));

    % --- R-peak detection (same fallback ladder as before) ---
    [~, qrs_i] = pan_tompkin(sig, fs, 0);
    if numel(qrs_i) <= 5, [~, qrs_i] = pan_tompkin(sig, fs/2, 0); end
    if numel(qrs_i) <= 5, [~, qrs_i] = pan_tompkin(sig(500:end), fs, 0); end
    if numel(qrs_i) <= 5, continue; end

    nni = diff(qrs_i(:)) / fs;              % R-R intervals in SECONDS
    nni = nni(nni > 0.33 & nni < 2.0);      % physiological guard
    if numel(nni) < 12, continue; end

    % --- HRV via PhysioZoo mhrv, called DIRECTLY (packaged namespace) ---
    td = mhrv.hrv.hrv_time(nni);
    fd = mhrv.hrv.hrv_freq(nni, 'methods', {'lomb'});
    nl = mhrv.hrv.hrv_nonlinear(nni);

    % histogram descriptors (kurtosis/skewness of the R-R series)
    hist_feat = table(kurtosis(nni), skewness(nni), ...
                      'VariableNames', {'Kurtosis','Skewness'});

    Overall_HRV_features{i} = [td, fd, nl, hist_feat];
end
end
