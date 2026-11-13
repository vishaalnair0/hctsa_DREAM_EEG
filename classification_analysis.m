%% Median Classification for All Channels All Features with 9 Cross-Validations - 128Hz FS, 0.75-30Hz Bandpass
clear;
clc;

load('D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts\Filtered_output_and_operations.mat');

main_matrix = filtered_output;

%% Dream Status, Channels and Participants

load('channels_excluded.mat');
load('Variable_list.mat');
load('channel_names.mat');


%% Loop through all channels to retrieve trainrows and testrows
for channel = 1:length(channels)
    channel_ID = find(channel_list == channels(channel));
    chandata = main_matrix(channel_ID,:);
    
    for feature = 1:size(chandata,2) 
        for test_participant = 1: length(nParticipants)
            
            trainrows = find(~(subject_ID == test_participant));
            
            traindata = chandata(trainrows,feature);
            
            trainrows_condition = dream_status(trainrows);
            
            trainrows_dreamful = find(trainrows_condition);
            trainrows_dreamless = find(~trainrows_condition);
            
            traindata_dreamful = traindata(trainrows_dreamful);
            traindata_dreamless = traindata(trainrows_dreamless);
            
            median_dreamful = median(traindata_dreamful);
            median_dreamless = median(traindata_dreamless); 
            
            threshold = (median_dreamful + median_dreamless)/2;
            threshold_vector{channel,feature} = threshold;
            
            % Test Data here
            
            testrows = find(subject_ID == test_participant);
            
            testdata = chandata(testrows,feature);
            
            testrows_condition = dream_status(testrows);
            
            testrows_dreamful = find(testrows_condition);
            testrows_dreamless = find(~testrows_condition);
            
            testdata_dreamful = testdata(testrows_dreamful);
            testdata_dreamless = testdata(testrows_dreamless);
            
            testvalues = [testdata_dreamful;testdata_dreamless];
            test_labels = sort(testrows_condition,"descend");
            
            %% loop through test data and save prediction
            row_counter = 1;
            clear prediction_list;
            
            for i = 1:size(testvalues,1)
                test_value = testvalues(i);
                if median_dreamful > median_dreamless
                    direction{channel,feature} = 1;
                    if test_value >= threshold
                        prediction = 1;
                    else %test_value < threshold
                        prediction = 0;
                    end
                else % median_dreamful <= median_dreamless
                    direction{channel,feature} = -1;
                    if test_value <= threshold
                        prediction = 1;
                    else %test_value > threshold
                        prediction = 0;
                    end
                end 
                prediction_list{row_counter} = prediction;
                row_counter = row_counter + 1;
            end
            
            prediction_list = cell2mat(prediction_list);
            
            %% Accuracy check
            
            accurate = 0; 
            
            for c = 1:size(prediction_list,2)
                if prediction_list(1,c) == test_labels(c,1)
                    accurate = accurate + 1;
                end
            end
            acc_percentage = (accurate/size(prediction_list,2))*100;
        
            acc_matrix(test_participant,:) = acc_percentage;

        end
        mean_accuracy = mean(acc_matrix, 1);
        feature_accuracies(:,feature) = mean_accuracy;
    end
    chan_feat_accuracies(channel,:) = feature_accuracies;
end

%% Obtain direction and threshold matrices

threshold_matrix = cell2mat(threshold_vector);
direction_matrix = cell2mat(direction);

%% Best Feature Accuracy for each channel

[m,idx] = max(chan_feat_accuracies,[],2);

chan_bestacc_withFeatureID = [m idx];

load('channel_names.mat');
%channel_names(channels_to_not_included,:) = [];


%% Performance Distribution for each Channel

figure();
for s = 1:size(chan_feat_accuracies,1)
    data = chan_feat_accuracies(s,:);
    subplot(5,6,s)
    
    nbins = 0.9:(100/54):100;
    [N_norm,edges] = histcounts(data,nbins);
    plot (edges(1:end-1) , N_norm , 'b')
    hold on 
    xline(median(chan_feat_accuracies(s,:)),'Color','r','LineWidth',1.5)
    title([channel_names(s,1)]);
    %title(['Ch' num2str(k) ':' ' ' num2str(round(median(data),2))]);
end


%% Visualize the feature values of feature column Y (best-performing) at channel X for each case

channel_of_interest = 21; % change to channel of interest
featurecolumn_of_interest = 2726; % change to feature column of interest

onechannel_idx = find(channel_list == channel_of_interest); 

onechannel_featurevalues = main_matrix(onechannel_idx,featurecolumn_of_interest); 
df_idx_onechannel = find(dream_status);
dl_idx_onechannel = find(~dream_status);
onechannel_featurevalues_df = onechannel_featurevalues(df_idx_onechannel);
onechannel_featurevalues_dl = onechannel_featurevalues(dl_idx_onechannel);

figure('Color','White');
scatter(1:27,onechannel_featurevalues_df','DisplayName','Dreamful Condition','MarkerFaceColor','flat');
hold on
scatter(28:54,onechannel_featurevalues_dl','DisplayName','Dreamless Condition','MarkerFaceColor','flat');
yline(threshold_matrix(channel_of_interest,featurecolumn_of_interest),'r','DisplayName',"Classification Threshold"); % change threshold matrix (rows,cols) as well
title("Values for the Best-performing Feature at Channel Cz");
xlabel("Cases","FontWeight","bold");
ylabel("Feature Value","FontWeight","bold");
legend("Dreamful Condition","Dreamless Condition","Classification Threshold");
set(gca,'FontSize',12);

%% Post-hoc analysis on spectral-power related features 
 
SP_feat_accuracies = chan_feat_accuracies(:,3543:3898);

% Plot mean accuracy of SP features across channels
meanSP_acrosschan = mean(SP_feat_accuracies);

figure('Color','white');
histogram(meanSP_acrosschan,HandleVisibility="off");
xline(61.11,'r');
xlabel('Distribution of Classification Accuracies for Spectral Power Features');
legend('Significance Threshold');

% How many SP features are greater than the 0.05 threshold?

sig_SP_features_idx = meanSP_acrosschan>= 61.11; % this is the 0.05 threshold value from 'Statistical_testing_accuracies.m' script
sig_SP_featurecolumns = find(sig_SP_features_idx); % Result is none by the way

% Visualize the distribution of spectral power performance at each channel for the main 19 electrodes

SP_feat_accuracies(channels_to_exclude,:) = [];
channel_names(channels_to_exclude,:) = [];

figure('Color','white');
for s = 1:size(SP_feat_accuracies,1)
    data = SP_feat_accuracies(s,:);
    subplot(5,4,s)
    
    histogram(data)
    hold on 
    xline(61.11,'Color','r','LineWidth',1.5)
    title(channel_names(s,1));
    xlabel('SP Features Classification Accuracies');
    hold off
end

% Are the features above the 0.05 threshold outliers? Check z-scores

for ch = 1:19
    acc_SP = SP_feat_accuracies(ch,:);
    z = (acc_SP - mean(acc_SP)) / std(acc_SP);

    outlier_perchannel{ch,:} = find(z > 2.5);
end


%% Let me try something

SP_feature_outliers = [53,76,175,179,292,296];

SP_feat_accuracies(:,SP_feature_outliers) = [];

figure('Color','white');
for s = 1:size(SP_feat_accuracies,1)
    data = SP_feat_accuracies(s,:);
    subplot(5,4,s)
    
    histogram(data)
    hold on 
    xline(61.11,'Color','r','LineWidth',1.5)
    title(channel_names(s,1));
    xlabel('SP Features Classification Accuracies');
    hold off
end

[m,idx] = max(SP_feat_accuracies,[],2);
SP_bestacc_withFeatureID = [m idx];

% Get the operations list

SP_Operations = Operations_postfilter(3543:3898,:);
SP_Operations(SP_feature_outliers,:) = [];

% Number of significant SP features per channel

for ch = 1:size(SP_feat_accuracies)
    significant_SPaccuracy_idx = SP_feat_accuracies(ch,:)>= 61.11;

    significant_SPfeaturecolumns = find(significant_SPaccuracy_idx);

    sig_SPfeatures_perchannel{ch,:} = significant_SPfeaturecolumns;
end


%% Visualize the feature values of feature column Y (best-performing) at channel X for each case

channel_of_interest = 17; % change to channel of interest
featurecolumn_of_interest = 3614; % change to feature column of interest

onechannel_idx = find(channel_list == channel_of_interest); 

onechannel_featurevalues = main_matrix(onechannel_idx,featurecolumn_of_interest); 
df_idx_onechannel = find(dream_status);
dl_idx_onechannel = find(~dream_status);
onechannel_featurevalues_df = onechannel_featurevalues(df_idx_onechannel);
onechannel_featurevalues_dl = onechannel_featurevalues(dl_idx_onechannel);

figure('Color','White');
scatter(1:27,onechannel_featurevalues_df','DisplayName','Dreamful Condition','MarkerFaceColor','flat');
hold on
scatter(28:54,onechannel_featurevalues_dl','DisplayName','Dreamless Condition','MarkerFaceColor','flat');
yline(threshold_matrix(channel_of_interest,featurecolumn_of_interest),'r','DisplayName',"Classification Threshold"); % change threshold matrix (rows,cols) as well
title("Values for the Best-performing Spectral Power-related Feature at Channel O1");
xlabel("Cases","FontWeight","bold");
ylabel("Feature Value","FontWeight","bold");
legend("Dreamful Condition","Dreamless Condition","Classification Threshold");
set(gca,'FontSize',12);


