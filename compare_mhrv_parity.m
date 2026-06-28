function T = compare_mhrv_parity(rr_seconds, outCsv)
% COMPARE_MHRV_PARITY  Demonstrate the agreement between this pipeline's ported
% HRV routines (hrv_*_edit) and the PhysioZoo mhrv library called directly, on
% IDENTICAL R-R inputs. Addresses Reviewer 2: rather than asserting bit-level
% equivalence, this script measures it and writes the result for the repository.
%
% USAGE
%   % use a built-in fixed example R-R series (reproducible):
%   T = compare_mhrv_parity();
%   % or supply your own R-R intervals in seconds:
%   T = compare_mhrv_parity(rr_seconds, 'mhrv_parity.csv');
%
% REQUIREMENTS on the path:
%   - this pipeline's hrv_time_edit.m, hrv_freq_edit.m, hrv_nonlinear_edit.m
%   - the PhysioZoo mhrv toolbox (provides mhrv.hrv.hrv_time / hrv_freq /
%     hrv_nonlinear and the *_defaults). Install from
%     https://physiozoo.com / https://github.com/physiozoo/mhrv
%
% OUTPUT
%   A table comparing each metric: ported value, mhrv value, absolute diff,
%   and relative diff (%). Written to outCsv. Commit this CSV (and the script)
%   to the repository so the agreement is documented, per Reviewer 2.
%
% NOTE ON INTERPRETATION
%   Metrics computed by shared definitions should agree to within numerical
%   tolerance when given the *same* R-R array and *same* parameters. Any
%   residual difference localizes the discrepancy to the wrapper (the "_edit"
%   modifications) rather than to the algorithm, which is exactly the point
%   raised by the reviewer. Do NOT claim exact equivalence unless the relative
%   differences below are at machine-precision level; otherwise report the
%   achieved agreement honestly.

if nargin < 1 || isempty(rr_seconds)
    rng(0);
    % reproducible synthetic NN series ~ 1 s mean, realistic variability
    rr_seconds = 1.0 + 0.05*randn(300,1);
    rr_seconds = max(0.4, min(1.5, rr_seconds));
end
if nargin < 2 || isempty(outCsv), outCsv = 'mhrv_parity.csv'; end
rr = rr_seconds(:);

names = {}; ported = []; mh = [];

% ---------- TIME DOMAIN ----------
td = hrv_time_edit(rr, 50/1000);                 % pipeline (ms internally)
% PhysioZoo mhrv: mhrv.hrv.hrv_time expects NN in SECONDS, returns a table in ms
mtd = mhrv.hrv.hrv_time(rr);                      % <<< confirm function name/path
pairs_td = { 'AVNN', td.AVNN,  mtd.AVNN; ...
             'SDNN', td.SDNN,  mtd.SDNN; ...
             'RMSSD',td.RMSSD, mtd.RMSSD };
for k=1:size(pairs_td,1)
    names{end+1}=pairs_td{k,1}; ported(end+1)=pairs_td{k,2}; mh(end+1)=pairs_td{k,3}; %#ok<AGROW>
end

% ---------- FREQUENCY DOMAIN (Lomb) ----------
fd  = hrv_freq_edit(rr);                          % pipeline
mfd = mhrv.hrv.hrv_freq(rr, 'methods', {'lomb'}); % <<< confirm name/params
% map common fields (edit names on the left as needed to match your tables)
fmap = { 'TOTAL_POWER_LOMB','TOT_PWR'; 'LF_POWER_LOMB','LF_PWR'; ...
         'HF_POWER_LOMB','HF_PWR'; 'LF_TO_HF_LOMB','LF_to_HF' };
for k=1:size(fmap,1)
    a = local_get(fd,  fmap{k,1});
    b = local_get(mfd, fmap{k,2});
    if ~isnan(a) && ~isnan(b)
        names{end+1}=fmap{k,1}; ported(end+1)=a; mh(end+1)=b; %#ok<AGROW>
    end
end

% ---------- NONLINEAR ----------
nl  = hrv_nonlinear_edit(rr);                     % pipeline
mnl = mhrv.hrv.hrv_nonlinear(rr);                 % <<< confirm name
nmap = { 'SD1','SD1'; 'SD2','SD2'; 'alpha1','alpha1'; 'alpha2','alpha2'; 'SampEn','SampEn' };
for k=1:size(nmap,1)
    a = local_get(nl,  nmap{k,1});
    b = local_get(mnl, nmap{k,2});
    if ~isnan(a) && ~isnan(b)
        names{end+1}=nmap{k,1}; ported(end+1)=a; mh(end+1)=b; %#ok<AGROW>
    end
end

ported = ported(:); mh = mh(:);
absdiff = abs(ported - mh);
reldiff = 100*absdiff ./ max(abs(mh), eps);
T = table(names(:), ported, mh, absdiff, reldiff, ...
    'VariableNames', {'Metric','Ported','mhrv_direct','AbsDiff','RelDiff_pct'});
disp(T);
writetable(T, outCsv);
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
        if istable(tbl) && any(strcmpi(tbl.Properties.VariableNames, field))
            idx = find(strcmpi(tbl.Properties.VariableNames, field),1);
            v = tbl{1, idx};
        end
    catch
    end
end
