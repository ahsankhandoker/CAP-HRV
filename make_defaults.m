function make_defaults()
% MAKE_DEFAULTS  Create Frequency_defaults.mat and Nonlinear_defaults.mat with
% the standard parameter values expected by hrv_freq_edit.m and
% hrv_nonlinear_edit.m. Run once (in the repository folder) to regenerate the
% two parameter files if they are missing.
%
% NOTE: these are standard-definition defaults chosen so the pipeline runs and
% matches conventional HRV settings (Lomb spectrum; VLF 0.003-0.04, LF
% 0.04-0.15, HF 0.15-0.40 Hz; total-power normalization; SampEn m=2, r=0.2).
% If your original analysis used different settings, edit the values below to
% match before regenerating.

% ---------------- Frequency_defaults ----------------
DEFAULT_METHODS         = {'lomb'};
DEFAULT_POWER_METHODS   = {'lomb'};
DEFAULT_NORM_METHOD     = 'total';        % nLF/nHF/nVLF as % of total power
DEFAULT_BAND_FACTOR     = 1.0;
DEFAULT_BETA_BAND       = [0.003 0.04];   % band for the 1/f slope (beta)
DEFAULT_VLF_BAND        = [0.003 0.04];
DEFAULT_LF_BAND         = [0.04 0.15];
DEFAULT_HF_BAND         = [0.15 0.40];
DEFAULT_EXTRA_BANDS     = {};             % keep empty (avoids mhrv.util call)
DEFAULT_WINDOW_MINUTES  = [];
DEFAULT_AR_ORDER        = 24;
DEFAULT_WELCH_OVERLAP   = 50;
DEFAULT_NUM_PEAKS       = 5;
DEFAULT_RESAMPLE_FACTOR = 4;
DEFAULT_FREQ_OSF        = 2;
DEFAULT_WIN_FUNC        = @hamming;
save('Frequency_defaults.mat', ...
  'DEFAULT_METHODS','DEFAULT_POWER_METHODS','DEFAULT_NORM_METHOD',...
  'DEFAULT_BAND_FACTOR','DEFAULT_BETA_BAND','DEFAULT_VLF_BAND','DEFAULT_LF_BAND',...
  'DEFAULT_HF_BAND','DEFAULT_EXTRA_BANDS','DEFAULT_WINDOW_MINUTES','DEFAULT_AR_ORDER',...
  'DEFAULT_WELCH_OVERLAP','DEFAULT_NUM_PEAKS','DEFAULT_RESAMPLE_FACTOR',...
  'DEFAULT_FREQ_OSF','DEFAULT_WIN_FUNC');

% ---------------- Nonlinear_defaults ----------------
DEFAULT_MSE_MAX_SCALE = 1;                % scale 1 -> plain sample entropy
DEFAULT_MSE_METRICS   = false;
DEFAULT_SAMPEN_R      = 0.2;
DEFAULT_SAMPEN_M      = 2;
save('Nonlinear_defaults.mat', ...
  'DEFAULT_MSE_MAX_SCALE','DEFAULT_MSE_METRICS','DEFAULT_SAMPEN_R','DEFAULT_SAMPEN_M');

fprintf('Wrote Frequency_defaults.mat and Nonlinear_defaults.mat\n');
end
