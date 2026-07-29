function T = compare_mhrv_parity(rr_seconds, outCsv)
% COMPARE_MHRV_PARITY  Demonstrate the agreement between this pipeline's ported
% HRV routines (hrv_*_edit) and the PhysioZoo mhrv library called directly, on
% IDENTICAL R-R inputs. Addresses Reviewer 2: rather than asserting bit-level
% equivalence, this script measures it and writes the result for the repository.
%
% USAGE
%   T = compare_mhrv_parity();                       % built-in synthetic R-R
%   T = compare_mhrv_parity(rr_seconds, 'mhrv_parity.csv');
%
% REQUIREMENTS on the path:
%   - this pipeline's hrv_time_edit.m, hrv_freq_edit.m, hrv_nonlinear_edit.m,
%     dfa_edit.m, mse_edit.m, and Frequency_defaults.mat / Nonlinear_defaults.mat
%   - the PhysioZoo mhrv toolbox (provides poincare, freqband_power,
%     mhrv.util.freqband_power, and mhrv.hrv.hrv_time / hrv_freq / hrv_nonlinear).
%     Install from https://physiozoo.com / https://github.com/physiozoo/mhrv
%   - MATLAB Signal Processing + Image Processing toolboxes.
%
% OUTPUT: a table comparing each metric (ported vs mhrv, absolute & relative
% difference), written to outCsv. Commit this CSV (and this script) to the
% repository so the agreement is documented, per Reviewer 2.
%
% NOTE: metrics computed by shared definitions should agree to numerical
% tolerance when given the same R-R array and parameters. Report the achieved
% agreement; do NOT claim exact equivalence unless the relative differences are
% at machine-precision level.

if nargin < 1 || isempty(rr_seconds)
    rng(0);
    rr_seconds = 1.0 + 0.05*randn(300,1);
    rr_seconds = max(0.4, min(1.5, rr_seconds));
end
if nargin < 2 || isempty(outCsv), outCsv = 'mhrv_parity.csv'; end
rr = rr_seconds(:);

% ---------- dependency preflight (fail helpfully, not cryptically) ----------
missing = {};
if exist('Frequency_defaults','file')==0 && exist('Frequency_defaults.mat','file')==0
    missing{end+1} = 'Frequency_defaults.mat (loaded by hrv_freq_edit.m)'; end %#ok<AGROW>
if exist('Nonlinear_defaults','file')==0 && exist('Nonlinear_defaults.mat','file')==0
    missing{end+1} = 'Nonlinear_defaults.mat (loaded by hrv_nonlinear_edit.m)'; end %#ok<AGROW>
for f = {'dfa_edit','mse_edit'}
    if exist(f{1},'file')==0, missing{end+1} = [f{1} '.m (called by hrv_nonlinear_edit.m)']; end %#ok<AGROW>
end
if exist('poincare','file')==0
    missing{end+1} = 'poincare (PhysioZoo mhrv)'; end %#ok<AGROW>
if exist('mhrv.hrv.hrv_time','file')==0 && exist('mhrv','dir')==0
    missing{end+1} = 'PhysioZoo mhrv toolbox (https://physiozoo.com) on the path'; end %#ok<AGROW>
if ~isempty(missing)
    fprintf(2, 'Missing dependencies (some blocks will be skipped):\n');
    fprintf(2, '  - %s\n', missing{:});
end

names = {}; ported = []; mh = [];

% ---------- TIME DOMAIN ----------
try
    td  = hrv_time_edit(rr, 50/1000);
    mtd = mhrv.hrv.hrv_time(rr);                  % <<< confirm function name/path
    P = {'AVNN',td.AVNN,mtd.AVNN; 'SDNN',td.SDNN,mtd.SDNN; 'RMSSD',td.RMSSD,mtd.RMSSD};
    for k=1:size(P,1), names{end+1}=P{k,1}; ported(end+1)=P{k,2}; mh(end+1)=P{k,3}; end %#ok<AGROW>
catch ME, fprintf(2,'Time-domain block skipped: %s\n', ME.message); end

% ---------- FREQUENCY DOMAIN (Lomb) ----------
try
    fd  = hrv_freq_edit(rr);
    mfd = mhrv.hrv.hrv_freq(rr, 'methods', {'lomb'});   % <<< confirm name/params
    fmap = {'TOTAL_POWER_LOMB','TOT_PWR'; 'LF_POWER_LOMB','LF_PWR'; ...
            'HF_POWER_LOMB','HF_PWR'; 'LF_TO_HF_LOMB','LF_to_HF'};
    for k=1:size(fmap,1)
        a=local_get(fd,fmap{k,1}); b=local_get(mfd,fmap{k,2});
        if ~isnan(a)&&~isnan(b), names{end+1}=fmap{k,1}; ported(end+1)=a; mh(end+1)=b; end %#ok<AGROW>
    end
catch ME, fprintf(2,'Frequency block skipped: %s\n', ME.message); end

% ---------- NONLINEAR ----------
try
    nl  = hrv_nonlinear_edit(rr);
    mnl = mhrv.hrv.hrv_nonlinear(rr);            % <<< confirm name
    nmap = {'SD1','SD1'; 'SD2','SD2'; 'alpha1','alpha1'; 'alpha2','alpha2'; 'SampEn','SampEn'};
    for k=1:size(nmap,1)
        a=local_get(nl,nmap{k,1}); b=local_get(mnl,nmap{k,2});
        if ~isnan(a)&&~isnan(b), names{end+1}=nmap{k,1}; ported(end+1)=a; mh(end+1)=b; end %#ok<AGROW>
    end
catch ME, fprintf(2,'Nonlinear block skipped: %s\n', ME.message); end

if isempty(names)
    error('No metrics computed. Resolve the missing dependencies above and re-run.');
end

ported = ported(:); mh = mh(:);
absdiff = abs(ported - mh);
reldiff = 100*absdiff ./ max(abs(mh), eps);
T = table(names(:), ported, mh, absdiff, reldiff, ...
    'VariableNames', {'Metric','Ported','mhrv_direct','AbsDiff','RelDiff_pct'});
disp(T); writetable(T, outCsv);
fprintf('\nWritten %s. Max relative difference: %.3g%%\n', outCsv, max(reldiff));
if max(reldiff) < 1e-6
    fprintf('Agreement is at machine precision -> exact equivalence is justified.\n');
else
    fprintf(['Residual differences exist -> report the achieved agreement; do NOT ' ...
             'claim exact equivalence.\n']);
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
