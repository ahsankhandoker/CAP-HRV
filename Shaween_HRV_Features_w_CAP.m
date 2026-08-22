clear; close all; clc;
% SHAWEEN_HRV_FEATURES_W_CAP  Main driver: EDF/annotation ingest, CAP A1/A2/A3
% epoching, R-peak detection (Pan-Tompkins) and HRV feature extraction.
%
% HRV is computed by calling the PhysioZoo mhrv toolbox DIRECTLY (per Reviewer 2).
% The previous edited copies (hrv_time_edit / hrv_freq_edit / hrv_nonlinear_edit /
% hrv_fragmentation_edit) have been removed, together with the repmat(...,1,70)
% tiling and the ./1000 and ./100 rescalings that only existed to compensate for
% those edited routines. mhrv already returns standard units, so no rescaling is
% applied here.
%
% REQUIRES on the MATLAB path:
%   - PhysioZoo mhrv toolbox  (https://physiozoo.com ; https://github.com/physiozoo/mhrv)
%   - pan_tompkin.m, natsort.m, edfread
%   - Signal Processing Toolbox; Statistics and Machine Learning Toolbox
%
% This build of mhrv is PACKAGED: HRV functions live in +mhrv/+hrv/ and are
% called as mhrv.hrv.hrv_time / hrv_freq / hrv_nonlinear / hrv_fragmentation.
% Add the mhrv ROOT (the folder that CONTAINS +mhrv) to the path, and load the
% defaults once via mhrv_init (or mhrv_load_defaults) before the first HRV call.

assert(exist('mhrv_init','file')~=0 || exist('mhrv_load_defaults','file')~=0, ...
    ['PhysioZoo mhrv toolbox not found on the path. Install it from ' ...
     'https://physiozoo.com and add its ROOT folder (the one that CONTAINS +mhrv) ' ...
     'with addpath(genpath(...)).']);
if     exist('mhrv_init','file'),          mhrv_init;           % load mhrv defaults (once)
elseif exist('mhrv_load_defaults','file'), mhrv_load_defaults;
end

cd('D:\KU Stuff\Shaween Stuff') % This folder has all the codes and functions.
HealthyDir = "C:\Users\Admin\Documents\MATLAB\KU Research\CAPHealthyEDF"; % This folder contains both EDF and txt files of subject n1-n16 from the CAP Sleep Database.
addpath(HealthyDir);
addpath("F:\ACPN_Data"); % This folder has some other functions that I used, like "natsort.m".
HealthyEDFFiles = dir(fullfile(HealthyDir, '*.edf')); % Get all EDF files that contain all signal data and information (i.e. Sampling frequencies, etc.).
HealthytxtFiles = dir(fullfile(HealthyDir, '*.txt')); % Get all txt files that contain all event information.
%% Extract the file names to make the loops easier
HealthyEDFs = string(zeros(numel(HealthyEDFFiles),1));
Healthytxts = string(zeros(numel(HealthytxtFiles),1));
for h = 1:numel(HealthyEDFFiles)
    HealthyEDFs(h) = HealthyEDFFiles(h).name;
    Healthytxts(h) = HealthytxtFiles(h).name;
end
HealthyEDFs = natsort(HealthyEDFs);
Healthytxts = natsort(Healthytxts); % Subjects 13 and 14 are missing headers, Subject 16 only has EEG
for subject = 1:numel(HealthyEDFs)
    if subject ~= 13 && subject ~= 14
        %% Signals from EDF Files
        [EDFInfo,EDFData] = edfread(HealthyEDFs(subject));
        EDFLabels = string(EDFInfo.label);
        Fs = EDFInfo.frequency;
        StartTime = duration(strrep(string(EDFInfo.starttime),".",":"));
        ECGData = EDFData(strcmpi(EDFLabels,"ECG"),:);
        FsECG = Fs(strcmpi(EDFLabels,"ECG"));
        if isempty(ECGData)
            ECGData = EDFData(strcmpi(EDFLabels,"ECG1"),:);
            FsECG = Fs(strcmpi(EDFLabels,"ECG1"));
        end
        if isempty(ECGData)
            ECGData = EDFData(strcmpi(EDFLabels,"EKG"),:);
            FsECG = Fs(strcmpi(EDFLabels,"EKG"));
        end
        if isempty(ECGData)
            ECGData = EDFData(strcmpi(EDFLabels,"ECG1ECG2"),:);
            FsECG = Fs(strcmpi(EDFLabels,"ECG1ECG2"));
        end
    else % if the external edfread.m does not work due to any missing headers, try MATLAB's built-in edfread.
        cd('D:\MATLAB\2024b\toolbox\signal\signal');
        [EDFData,EDFInfo] = edfread(HealthyEDFs(subject));
        EDFData = timetable2table(EDFData);
        ECGData = cell2mat(EDFData.ECG(:))';
        FsECG = numel(EDFData.ECG{1})/(seconds(EDFData.("Record Time")(2))-seconds(EDFData.("Record Time")(1)));
        cd('D:\KU Stuff\Shaween Stuff') % This folder has all the codes and functions.
    end

        SignalLength = length(ECGData);

        % FsEEG = Fs(strcmpi(EDFLabels,"C4A1"));
        % if FsECG ~= FsEEG
        %     [pECG,qECG] = rat(FsEEG/FsECG);
        %     ECGData = resample(ECGData,pECG,qECG,0);
        % end
        fs = FsECG;
        if mod(SignalLength,30*fs) ~= 0
            ECGData = ECGData(:,1:end-mod(SignalLength,30*fs));
            SignalLength = size(ECGData,2);
        end
        %% CAP Annotations and times from txt files
        TextInfo = readtable(Healthytxts(subject),'Delimiter',"\t"); % Read the txt file containing all CAP events
        if subject == 13 || subject == 14 % Header issues with Subject 13 and 14; Start Time is assumed to be the first event in the txt file:
            StartTime = TextInfo.Time_hh_mm_ss_(1);
        end
        EventStartTimes = TextInfo.Time_hh_mm_ss_;
        EventStartTimes(find(diff(EventStartTimes) < 0)+1:end) = EventStartTimes(find(diff(EventStartTimes) < 0)+1:end) + duration([24 00 00]);
        EventStartTimesseconds = seconds(EventStartTimes);
        Event = string(TextInfo.Event); % Note that sleep stages are recorded every 30 seconds, so that's what we use for epoching.
        %% Annotations/sleep stages are recorded every 30 or 60 seconds, so divide the ECG data into ~30-second epochs
        ECGData = reshape(ECGData,30*fs,[]); % Note that the number of epochs will be smaller than that in the Event variable since sleep stages and CAP are both scored as events.
        %% Phase A Subtype indices and start times in the same notation as the txt file as well as in seconds to be used in code
        CAPA1Event = Event(contains(Event,"CAP-A1"));
        CAPA2Event = Event(contains(Event,"CAP-A2"));
        CAPA3Event = Event(contains(Event,"CAP-A3"));
        CAPA1Idxs = find(contains(Event,"CAP-A1"));
        CAPA2Idxs = find(contains(Event,"CAP-A2"));
        CAPA3Idxs = find(contains(Event,"CAP-A3"));
        CAPA1StartTime = EventStartTimes(CAPA1Idxs);
        CAPA2StartTime = EventStartTimes(CAPA2Idxs);
        CAPA3StartTime = EventStartTimes(CAPA3Idxs);
        CAPA1StartTimeseconds = seconds(CAPA1StartTime);
        CAPA2StartTimeseconds = seconds(CAPA2StartTime);
        CAPA3StartTimeseconds = seconds(CAPA3StartTime);

        CAPA1StartsSeconds = CAPA1StartTimeseconds - seconds(StartTime);
        CAPA1EventDuration{subject} = TextInfo.Duration_s_(CAPA1Idxs);
        CAPA1EndsSeconds = CAPA1StartsSeconds + CAPA1EventDuration{subject};
        CAPA1Epochs = ceil(CAPA1StartsSeconds./30);
        CAPA1Epochs = unique(CAPA1Epochs);
        ECG_A1 = ECGData(:,CAPA1Epochs);

        CAPA2StartsSeconds = CAPA2StartTimeseconds - seconds(StartTime);
        CAPA2EventDuration{subject} = TextInfo.Duration_s_(CAPA2Idxs);
        CAPA2EndsSeconds = CAPA2StartsSeconds + CAPA2EventDuration{subject};
        CAPA2Epochs = ceil(CAPA2StartsSeconds./30);
        CAPA2Epochs = unique(CAPA2Epochs);
        ECG_A2 = ECGData(:,CAPA2Epochs);

        CAPA3StartsSeconds = CAPA3StartTimeseconds - seconds(StartTime);
        CAPA3EventDuration{subject} = TextInfo.Duration_s_(CAPA3Idxs);
        CAPA3EndsSeconds = CAPA3StartsSeconds + CAPA3EventDuration{subject};
        CAPA3Epochs = ceil(CAPA3StartsSeconds./30);
        CAPA3Epochs = unique(CAPA3Epochs);
        ECG_A3 = ECGData(:,CAPA3Epochs);

        %% CAP-A1 ECG epochs. Pan-Tompkins is applied to the whole epoch (not just the CAP-A1 span).
        for i = 1:size(ECG_A1,2)
            nni = rr_from_epoch(ECG_A1(:,i), fs);
            if numel(nni) < 12, Overall_HRV_features_A1{subject,i} = []; continue; end
            Overall_HRV_features_A1{subject,i} = epoch_hrv_mhrv(nni);
        end
        %% CAP-A2 ECG epochs.
        for i = 1:size(ECG_A2,2)
            nni = rr_from_epoch(ECG_A2(:,i), fs);
            if numel(nni) < 12, Overall_HRV_features_A2{subject,i} = []; continue; end
            Overall_HRV_features_A2{subject,i} = epoch_hrv_mhrv(nni);
        end
        %% CAP-A3 ECG epochs.
        for i = 1:size(ECG_A3,2)
            nni = rr_from_epoch(ECG_A3(:,i), fs);
            if numel(nni) < 12, Overall_HRV_features_A3{subject,i} = []; continue; end
            Overall_HRV_features_A3{subject,i} = epoch_hrv_mhrv(nni);
        end

end
% The main outputs of this file are the Overall_HRV_features_A1/A2/A3 cell arrays.
% Each non-empty cell is a 1-row MATLAB table whose named columns are the mhrv
% features (time, frequency-Lomb, nonlinear, fragmentation) plus Kurtosis/Skewness.
% Index columns by NAME (e.g. T.AVNN, T.SDNN, T.LF_to_HF, T.SD1, T.alpha1, T.SampEn)
% rather than by position, since the mhrv column set/order differs from the old
% edited routines.

%% ----- local helper functions -----
function nni = rr_from_epoch(selected_signal, fs)
% R-peak detection with the pipeline's fallback ladder, returning cleaned R-R
% intervals (in seconds). fs is the ECG sampling rate; detection runs at 200 Hz
% (the pipeline's fixed detector rate), consistent with the original driver.
    selected_signal = double(selected_signal);
    [~, qrs_i_raw] = pan_tompkin(selected_signal, 200, 0);
    if numel(qrs_i_raw) <= 5
        [~, qrs_i_raw] = pan_tompkin(selected_signal, 200/2, 0);
    end
    if numel(qrs_i_raw) <= 5
        ss = selected_signal(500:end);
        [~, qrs_i_raw] = pan_tompkin(ss, 200, 0);
    end
    if numel(qrs_i_raw) <= 5
        nni = [];
        return;
    end
    nni = diff(qrs_i_raw(:)) ./ 200;      % R-R intervals in SECONDS (detector rate = 200 Hz)
    nni = nni(nni > 0.33 & nni < 2.0);    % physiological guard (30-180 bpm)
end

function feat = epoch_hrv_mhrv(nni)
% HRV feature table for one epoch, computed by the PhysioZoo mhrv toolbox called
% DIRECTLY. nni are R-R intervals in seconds. No rescaling is applied: the units
% are exactly those returned by mhrv.
    td   = mhrv.hrv.hrv_time(nni);
    fd   = mhrv.hrv.hrv_freq(nni, 'methods', {'lomb'});
    nl   = mhrv.hrv.hrv_nonlinear(nni);
    frag = mhrv.hrv.hrv_fragmentation(nni);
    hist_feat = table(kurtosis(nni), skewness(nni), ...
                      'VariableNames', {'Kurtosis','Skewness'});
    feat = [td, fd, nl, frag, hist_feat];
end
