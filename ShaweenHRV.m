clear; close all; clc;
% a = load('One_Epoch.mat'); 
b = load('CAP_ECG_Epochs.mat');
all_ECG = b.ECG_A1;
% SubjectDetails = readtable('MostafaSDP2 Data-2.xlsx');                          % Read the table with subject details.
% for s = 1:numel(Subjects)
    % Filenames = string(lower(SubjectDetails.Patient_));                        % Study number, used for file names, extracted from table.
    % SubjectEDF = Filenames(Subject)+".edf";                                    % Setting subject edf file name.
    % [EDFInfo,EDFData] = edfread(SubjectEDF);                                   % Reading and extracting info from the EDF file.
    % EDFLabels = string(EDFInfo.label);
    %%
    % Put the code to extract epochs for each subject here, between the two
    % %% signs.
    %%
    for i = 1:size(all_ECG,2)
        selected_signal = all_ECG(:,i);
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
        Overall_HRV_features{s,i} = [all_hrv_features;histogram_features];
    end
% end