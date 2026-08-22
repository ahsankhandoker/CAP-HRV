function results = validate_CAP_A1(dbDir, records, outCsv)
% VALIDATE_CAP_A1  Benchmark YOUR rule-based CAP A1 detector against the
% expert annotations of the PhysioNet CAP Sleep Database (capslpdb v1.0.0).
%
% Addresses Reviewer 1, Comment 1 (and the Editor note): reports sensitivity,
% specificity, PPV, F1, and Cohen's kappa for CAP A1 detection vs. expert
% scoring, at both 1-second and event levels, restricted to SWS (S3/S4).
%
% This version uses PhysioNet's own ScoringReader.m (shipped with the
% database), so you do NOT parse the .txt files yourself.
%
% USAGE
%   r = validate_CAP_A1('capslpdb/', {'n1','n2','sdb1','sdb2'}, 'cap_a1_val.csv')
%   r = validate_CAP_A1('capslpdb/', [], 'cap_a1_val.csv')   % uses RECORDS file
%
% INPUTS
%   dbDir    folder holding the downloaded capslpdb files (*.edf, *.txt,
%            ScoringReader.m, RECORDS). Put this .m file there or add to path.
%   records  cell array of record names WITHOUT extension, e.g. {'n1','sdb1'}.
%            If empty, all names in the RECORDS file are used.
%            RECOMMENDED for a CAP-A1/SWS benchmark: the 16 controls
%            {'n1'..'n16'} (clean SWS) plus the 4 SDB records {'sdb1'..'sdb4'}.
%   outCsv   path for the per-record results table.
%
% >>> THE ONLY LINE YOU MUST EDIT is marked "WIRE HERE": call your detector. <<<
%   Your detector must return Nx2 [onset_sec offset_sec] of detected A1 events.
%
% REQUIREMENTS
%   - MATLAB R2023b+ (edfread/edfinfo), or replace local_load_eeg with your reader
%   - ScoringReader.m from the database (on the MATLAB path)
%   - Your CAP A1 module
%
% Author: prepared for the Frontiers in Physiology revision. CC-BY 4.0.

if nargin < 3 || isempty(outCsv), outCsv = 'cap_a1_validation.csv'; end
if nargin < 2 || isempty(records)
    records = local_read_records(fullfile(dbDir,'RECORDS'));
end
assert(exist('ScoringReader','file')==2, ...
    'ScoringReader.m not found on path. Add the capslpdb folder to the MATLAB path.');

rows = {}; allTP=0; allFP=0; allTN=0; allFN=0;

for i = 1:numel(records)
    rec  = records{i};
    txt  = fullfile(dbDir,[rec '.txt']);
    edf  = fullfile(dbDir,[rec '.edf']);
    if ~isfile(txt) || ~isfile(edf)
        warning('Missing files for %s, skipping.', rec); continue;
    end

    % ---- 1. Expert annotations via PhysioNet's ScoringReader.m -----------
    % ScoringReader returns the macrostructure hypnogram (0=W,1..4=S1..S4,5=REM)
    % and three arrays for the CAP A phases: start time (s), duration (s),
    % subtype (1=A1, 2=A2, 3=A3). Adjust the output order if your copy differs.
    [hypno, capStart, capDur, capType] = ScoringReader(txt);   % see note above
    hypno   = hypno(:);
    isA1    = (capType(:) == 1);
    a1_exp  = [capStart(isA1), capStart(isA1)+capDur(isA1)];    % Nx2 sec

    % ---- 2. Load the central EEG derivation -----------------------------
    [eeg, fs, chan] = local_load_eeg(edf);

    % ---- 3. Run YOUR detector (WIRE HERE) -------------------------------
    caps_det = detect_cap_a1(eeg, fs, hypno);     % <<< WIRE HERE: your A1 module

    % ---- 4. Build 1-second SWS masks (gold vs detected) -----------------
    T    = max([numel(hypno)*30, ceil(max([a1_exp(:);0])), ...
                ceil(max([caps_det(:);0]))]);
    sws  = local_stage_mask(hypno, T, [3 4]);          % S3/S4 only
    gold = local_events_to_mask(a1_exp,  T) & sws;
    pred = local_events_to_mask(caps_det,T) & sws;

    TP=sum(pred&gold); FP=sum(pred&~gold); FN=sum(~pred&gold); TN=sum(~pred&~gold);
    [se,sp,f1,kap,ppv] = local_metrics(TP,FP,TN,FN);
    [evSe,evPpv,evF1]  = local_event_match(caps_det, a1_exp, sws, T, 0.5);

    rows(end+1,:) = {rec, char(chan), sum(isA1 & local_onset_in_sws(capStart,hypno,[3 4])),...
        size(caps_det,1), se, sp, ppv, f1, kap, evSe, evPpv, evF1}; %#ok<AGROW>
    allTP=allTP+TP; allFP=allFP+FP; allTN=allTN+TN; allFN=allFN+FN;
    fprintf('%-8s [%s]  Se=%.3f Sp=%.3f F1=%.3f kappa=%.3f (eventF1=%.3f)\n',...
        rec, chan, se, sp, f1, kap, evF1);
end

[se,sp,f1,kap,ppv] = local_metrics(allTP,allFP,allTN,allFN);
fprintf('\nPOOLED (1-s, SWS): Se=%.3f Sp=%.3f PPV=%.3f F1=%.3f Cohen kappa=%.3f\n',...
    se,sp,ppv,f1,kap);

V = cell2table(rows,'VariableNames',{'record','channel','n_expert_A1_SWS',...
    'n_detected','sensitivity','specificity','PPV','F1','kappa',...
    'event_sensitivity','event_PPV','event_F1'});
writetable(V,outCsv);
results = struct('perRecord',V,'pooled',...
    struct('Se',se,'Sp',sp,'PPV',ppv,'F1',f1,'kappa',kap));
fprintf('Per-record results written to %s\n', outCsv);
fprintf(['\nReport in the manuscript (Section 2.4 / 3): pooled Se, Sp, F1 and ' ...
         'Cohen''s kappa above, plus the per-record table as supplementary.\n']);
end

% ============================ helpers ===================================
function recs = local_read_records(f)
    recs = {};
    if isfile(f)
        fid=fopen(f); c=textscan(fid,'%s'); fclose(fid); recs=c{1};
    else
        % default: controls + SDB
        recs = [arrayfun(@(k)sprintf('n%d',k),1:16,'uni',0), ...
                arrayfun(@(k)sprintf('sdb%d',k),1:4,'uni',0)];
        warning('RECORDS file not found; defaulting to controls n1-n16 + sdb1-4.');
    end
end

function [eeg, fs, chan] = local_load_eeg(edfPath)
    info = edfinfo(edfPath);
    labels = string(info.SignalLabels);
    pick = find(contains(labels,["C4-A1","C3-A2","C4A1","C3A2"],'IgnoreCase',true),1);
    if isempty(pick), pick = find(contains(labels,["C4","C3"],'IgnoreCase',true),1); end
    if isempty(pick), pick = find(contains(labels,"EEG",'IgnoreCase',true),1); end
    if isempty(pick), pick = 1; end
    chan = labels(pick);
    fs   = double(info.NumSamples(pick))/seconds(info.DataRecordDuration);
    tt   = edfread(edfPath,'SelectedSignals',cellstr(chan));
    eeg  = cell2mat(tt.(matlab.lang.makeValidName(chan)));
    eeg  = double(eeg(:));
    [b,a]= butter(4,[0.5 4]/(fs/2),'bandpass');   % delta band, matches A1 morphology
    eeg  = filtfilt(b,a,eeg);
end

function m = local_events_to_mask(ev, T)
    m = false(1,T);
    for k=1:size(ev,1)
        a=max(1,floor(ev(k,1))+1); b=min(T,ceil(ev(k,2)));
        if b>=a, m(a:b)=true; end
    end
end

function msk = local_stage_mask(hypno, T, stages)
    msk = false(1,T);
    for e=1:numel(hypno)
        if any(hypno(e)==stages)
            a=(e-1)*30+1; b=min(T,e*30); msk(a:b)=true;
        end
    end
    if ~any(msk), msk=true(1,T); end   % if hypnogram empty, do not gate
end

function tf = local_onset_in_sws(starts, hypno, stages)
    tf = false(numel(starts),1);
    for k=1:numel(starts)
        e=floor(starts(k)/30)+1;
        if e>=1 && e<=numel(hypno) && any(hypno(e)==stages), tf(k)=true; end
    end
end

function [se,sp,f1,kap,ppv] = local_metrics(TP,FP,TN,FN)
    se =TP/max(TP+FN,1); sp =TN/max(TN+FP,1); ppv=TP/max(TP+FP,1);
    f1 =2*ppv*se/max(ppv+se,eps);
    N=TP+FP+TN+FN; po=(TP+TN)/max(N,1);
    pe=((TP+FP)*(TP+FN)+(TN+FN)*(TN+FP))/max(N^2,1);
    kap=(po-pe)/max(1-pe,eps);
end

function [se,ppv,f1] = local_event_match(det, exp, sws, T, ovl)
    det=local_restrict(det,sws,T); exp=local_restrict(exp,sws,T);
    mE=false(size(exp,1),1);
    for i=1:size(det,1)
        for j=1:size(exp,1)
            if mE(j), continue; end
            o=min(det(i,2),exp(j,2))-max(det(i,1),exp(j,1));
            if o<=0, continue; end
            shorter=min(diff(det(i,:)),diff(exp(j,:)));
            if o/max(shorter,eps)>=ovl, mE(j)=true; break; end
        end
    end
    TP=sum(mE); se=TP/max(size(exp,1),1); ppv=TP/max(size(det,1),1);
    f1=2*ppv*se/max(ppv+se,eps);
end

function ev = local_restrict(ev, sws, T)
    keep=false(size(ev,1),1);
    for k=1:size(ev,1)
        a=max(1,floor(ev(k,1))+1); b=min(T,ceil(ev(k,2)));
        if b>=a && any(sws(a:b)), keep(k)=true; end
    end
    ev=ev(keep,:);
end
