clear; close all; clc;
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
        TextInfo = readtable(Healthytxts(subject),'Delimiter',"	"); % Read the txt file containing all CAP events
        if subject == 13 || subject == 14 % Header issues with Subject 13 and 14; Start Time is assumed to be the first event in the txt file:
            StartTime = TextInfo.Time_hh_mm_ss_(1);
        end
        EventStartTimes = TextInfo.Time_hh_mm_ss_; 
        EventStartTimes(find(diff(EventStartTimes) < 0)+1:end) = EventStartTimes(find(diff(EventStartTimes) < 0)+1:end) + duration([24 00 00]);
        EventStartTimesseconds = seconds(EventStartTimes);
        Event = string(TextInfo.Event); % Note that sleep stages are recorded every 30 seconds, so that's what we use for epoching.
        %% Annotations/sleep stages are recorded every 30 or 60 seconds, so divide the ECG data into ~30-second epochs
        ECGData = reshape(ECGData,30*fs,[]); % Note that the number of epochs will be smaller than that in the Event variable since sleep stages and CAP are both scored as events.
        % EpochStarts = zeros(size(ECGData,1),1);
        % for e = 2:size(ECGData,1)
        %     EpochStarts(e) = ((e-1)*30*fs);
        % end
        % EpochStarts(1) = 1;
        % EpochStarts = EpochStarts - seconds(StartTime);
        %% Phase A Subtype indices and start times in the same notation as the txt file as well as in seconds to be used in code 
        CAPA1Event = Event(contains(Event,"CAP-A1"));
        CAPA2Event = Event(contains(Event,"CAP-A2"));
        CAPA3Event = Event(contains(Event,"CAP-A3"));
        % CAPIdxs = find(contains(Event,"CAP")); 
        CAPA1Idxs = find(contains(Event,"CAP-A1"));
        CAPA2Idxs = find(contains(Event,"CAP-A2"));
        CAPA3Idxs = find(contains(Event,"CAP-A3"));
        % CAPStartTime = EventStartTimes(CAPIdxs); % Comment out if we are looking into the phase A subtypes
        CAPA1StartTime = EventStartTimes(CAPA1Idxs);
        CAPA2StartTime = EventStartTimes(CAPA2Idxs);
        CAPA3StartTime = EventStartTimes(CAPA3Idxs);
        % CAPStartTimeseconds = seconds(CAPStartTime); % Comment out if we are looking into the phase A subtypes
        CAPA1StartTimeseconds = seconds(CAPA1StartTime);
        CAPA2StartTimeseconds = seconds(CAPA2StartTime);
        CAPA3StartTimeseconds = seconds(CAPA3StartTime);
        %
        % CAPStartsSeconds = CAPStartTimeseconds - seconds(StartTime); % Comment out if we are looking into the phase A subtypes
        % CAPEventDuration = TextInfo.Duration_s_(CAPIdxs); % Comment out if we are looking into the phase A subtypes
        % CAPEndsSeconds = CAPStartsSeconds + CAPEventDuration; % Comment out if we are looking into the phase A subtypes
        % CAPStarts = CAPStartsSeconds*fs; % Comment out if we are looking into the phase A subtypes
        % CAPEnds = CAPEndsSeconds*fs; % Comment out if we are looking into the phase A subtypes
    
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
        %% This loop is only for CAP-A1 ECG Epochs. Bear in mind, this applies Pan-Tompkins algorithm for the entire epoch, not just the duration of CAP-A1
        for i = 1:size(ECG_A1,2)
            selected_signal = ECG_A1(:,i);
            [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
        
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200/2,0);
           end
        
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              selected_signal = selected_signal(500:end);
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
           end
           
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              selected_signal = Overall_filtered_signals;
              selected_signal(selected_signal > 2) = 0;
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
           end
           
           selected_portion = diff(qrs_i_raw)./200;
            
           selected_portion_kurtosis = kurtosis(selected_portion);
           selected_portion_skewness = skewness(selected_portion);   
           
           selected_portion_freq = repmat(selected_portion,1,70);
        
            [hrv_td] = hrv_time_edit(selected_portion,50/1000);
            AVNN = hrv_td.AVNN./1000;
            SDNN = hrv_td.SDNN./1000;
            RMSSD = hrv_td.RMSSD./1000;
            pNN50 = hrv_td.pNN0./100;
            SEM = hrv_td.SEM./1000;
            time_features = [AVNN;SDNN;RMSSD;pNN50;SEM];
            
            [hrv_fd] = hrv_freq_edit(selected_portion_freq);
            hrv_fd2 = table2array(hrv_fd);
            hrv_fd2 = hrv_fd2./1000;
            freq_features = [hrv_fd2'];
            
            [hrv_nl] = hrv_nonlinear_edit(selected_portion_freq);
            hrv_nl2 = table2array(hrv_nl);
            hrv_nl2(1,1) = hrv_nl2(1,1)./100;
            hrv_nl2(1,2) = hrv_nl2(1,2)./100;
            nonlinear_features = hrv_nl2';
            
            [hrv_frag] = hrv_fragmentation_edit(selected_portion);
            hrv_frag2 = table2array(hrv_frag);
            fragmentation_features = hrv_frag2'./100;
            FeatureNames = [string(hrv_td.Properties.VariableNames) string(hrv_fd.Properties.VariableNames) string(hrv_nl.Properties.VariableNames) string(hrv_frag.Properties.VariableNames)];
            all_hrv_features = [time_features;freq_features;nonlinear_features;fragmentation_features];
            histogram_features = [selected_portion_kurtosis;selected_portion_skewness];
            Overall_HRV_features_A1{subject,i} = [all_hrv_features;histogram_features];
        end
        %% This loop is only for CAP-A2 ECG Epochs. Bear in mind, this applies Pan-Tompkins algorithm for the entire epoch, not just the duration of CAP-A2
        for i = 1:size(ECG_A2,2)
            selected_signal = ECG_A2(:,i);
            [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
        
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200/2,0);
           end
        
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              selected_signal = selected_signal(500:end);
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
           end
           
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              selected_signal = Overall_filtered_signals;
              selected_signal(selected_signal > 2) = 0;
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
           end
           
           selected_portion = diff(qrs_i_raw)./200;
            
           selected_portion_kurtosis = kurtosis(selected_portion);
           selected_portion_skewness = skewness(selected_portion);   
           
           selected_portion_freq = repmat(selected_portion,1,70);
        
            [hrv_td] = hrv_time_edit(selected_portion,50/1000);
            AVNN = hrv_td.AVNN./1000;
            SDNN = hrv_td.SDNN./1000;
            RMSSD = hrv_td.RMSSD./1000;
            pNN50 = hrv_td.pNN0./100;
            SEM = hrv_td.SEM./1000;
            time_features = [AVNN;SDNN;RMSSD;pNN50;SEM];
            
            [hrv_fd] = hrv_freq_edit(selected_portion_freq);
            hrv_fd2 = table2array(hrv_fd);
            hrv_fd2 = hrv_fd2./1000;
            freq_features = [hrv_fd2'];
            
            [hrv_nl] = hrv_nonlinear_edit(selected_portion_freq);
            hrv_nl2 = table2array(hrv_nl);
            hrv_nl2(1,1) = hrv_nl2(1,1)./100;
            hrv_nl2(1,2) = hrv_nl2(1,2)./100;
            nonlinear_features = hrv_nl2';
            
            [hrv_frag] = hrv_fragmentation_edit(selected_portion);
            hrv_frag2 = table2array(hrv_frag);
            fragmentation_features = hrv_frag2'./100;
            FeatureNames = [string(hrv_td.Properties.VariableNames) string(hrv_fd.Properties.VariableNames) string(hrv_nl.Properties.VariableNames) string(hrv_frag.Properties.VariableNames)];
            all_hrv_features = [time_features;freq_features;nonlinear_features;fragmentation_features];
            histogram_features = [selected_portion_kurtosis;selected_portion_skewness];
            Overall_HRV_features_A2{subject,i} = [all_hrv_features;histogram_features];
        end
        %% This loop is only for CAP-A3 ECG Epochs. Bear in mind, this applies Pan-Tompkins algorithm for the entire epoch, not just the duration of CAP-A3
        for i = 1:size(ECG_A3,2)
            selected_signal = ECG_A3(:,i);
            [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
        
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200/2,0);
           end
        
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              selected_signal = selected_signal(500:end);
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
           end
           
           if (length(qrs_i_raw) <= 5) || (isempty(qrs_i_raw) == 1)
              selected_signal = Overall_filtered_signals;
              selected_signal(selected_signal > 2) = 0;
              [qrs_amp_raw,qrs_i_raw,delay] = pan_tompkin(double(selected_signal),200,0);
           end
           
           selected_portion = diff(qrs_i_raw)./200;
            
           selected_portion_kurtosis = kurtosis(selected_portion);
           selected_portion_skewness = skewness(selected_portion);   
           
           selected_portion_freq = repmat(selected_portion,1,70);
        
            [hrv_td] = hrv_time_edit(selected_portion,50/1000);
            AVNN = hrv_td.AVNN./1000;
            SDNN = hrv_td.SDNN./1000;
            RMSSD = hrv_td.RMSSD./1000;
            pNN50 = hrv_td.pNN0./100;
            SEM = hrv_td.SEM./1000;
            time_features = [AVNN;SDNN;RMSSD;pNN50;SEM];
            
            [hrv_fd] = hrv_freq_edit(selected_portion_freq);
            hrv_fd2 = table2array(hrv_fd);
            hrv_fd2 = hrv_fd2./1000;
            freq_features = [hrv_fd2'];
            
            [hrv_nl] = hrv_nonlinear_edit(selected_portion_freq);
            hrv_nl2 = table2array(hrv_nl);
            hrv_nl2(1,1) = hrv_nl2(1,1)./100;
            hrv_nl2(1,2) = hrv_nl2(1,2)./100;
            nonlinear_features = hrv_nl2';
            
            [hrv_frag] = hrv_fragmentation_edit(selected_portion);
            hrv_frag2 = table2array(hrv_frag);
            fragmentation_features = hrv_frag2'./100;
            FeatureNames = [string(hrv_td.Properties.VariableNames) string(hrv_fd.Properties.VariableNames) string(hrv_nl.Properties.VariableNames) string(hrv_frag.Properties.VariableNames)];
            all_hrv_features = [time_features;freq_features;nonlinear_features;fragmentation_features];
            histogram_features = [selected_portion_kurtosis;selected_portion_skewness];
            Overall_HRV_features_A3{subject,i} = [all_hrv_features;histogram_features];
        end

end
% The main outputs of this file are the Overall_HRV_features variables for
% CAP-A1, CAP-A2, and CAP-A3