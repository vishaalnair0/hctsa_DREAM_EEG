%% Computing Consistency - All Channels. Includes statistical testing (EEG param.: 0.75-30Hz, 128Hz Fs)

clear;
clc;

addpath('D:\DREAMEEG_hctsa\plot_topography');
load('custom_locations.mat');

load('D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts\Filtered_output_and_operations.mat');
load('D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts\directions_and_thresholds.mat');

main_matrix = BF_NormalizeMatrix(filtered_output,'mixedSigmoid');
check_constvalues = find(std(main_matrix)==0);
main_matrix(:,check_constvalues) = [];
Operations_postfilter(check_constvalues,:) = [];

direction_matrix(:,check_constvalues) = [];
threshold_matrix(:,check_constvalues) = [];

%% Variable List

load("Variable_list.mat");
load("channels_excluded.mat");
load("channel_names.mat");

%% Filter custom_locations 

ch_indexing = ismember(custom_locations.Number,channels_to_exclude);
check = find(ch_indexing);

custom_locations(check,:) = [];

%% Channel Iterations

for channel = 1:length(channels)  % to examine specific channels at line 187, we specify channel number in this line
    channel_data = find(channel_list == channels(channel));
    chandata = main_matrix(channel_data,:);

    for participant = 1:length(nParticipants)

        rows = find(subject_ID == participant);
        
        rowdata = chandata(rows,:);
        
        rows_condition = dream_status(rows);
        
        rows_dreamful = find(rows_condition);
        rows_dreamless = find(~rows_condition);
        
        rowdata_dreamful = rowdata(rows_dreamful,:);  % we can change to specific feature columns to continue at line 219, otherwise set to :
        rowdata_dreamless = rowdata(rows_dreamless,:); % same comment as above

        rowdata_dreamful_allsubj{participant} = rowdata_dreamful;
        rowdata_dreamless_allsubj{participant} = rowdata_dreamless; %comment this two lines out after completing line 219

        % Compute actual DNV
        DNV_persubject = getDNV(rowdata_dreamful,rowdata_dreamless);
        differences_all{participant} = DNV_persubject;
    end
    
    DNV_allsubjects = vertcat(differences_all{:});
    DNV_allsubjects_allchan{channel} = DNV_allsubjects;
    
    % Compute direction consistencies for one channel each iteration
    clear consistencies_allfeatures;

    for real_f = 1:size(DNV_allsubjects,2)
        count1 = 1;
        for DNV = 1:9:size(DNV_allsubjects,1)
            DNV_vector = DNV_allsubjects(DNV:DNV+8,real_f);
            direction1 = direction_matrix(channel,real_f); 
    
            consistency = getConsistency2r(DNV_vector,direction1); %getConsistency2 computes consistency from DNV values
            consistency_persubject(count1) = consistency;
            count1 = count1 + 1;
        end
        consistencies_allfeatures{:,real_f} = consistency_persubject';
    end

    consistencies_allfeatures = horzcat(consistencies_allfeatures{:});

    mConsistency_allfeatures = mean(consistencies_allfeatures);
    mConsistency_allf_allchan{channel,:} = mConsistency_allfeatures;
end

%% Mean consistency for each features each channel

mConsistency_allf_allchan = vertcat(mConsistency_allf_allchan{:}); % actual consistency

%% Load random null distribution - permutation

load("randperm_nulldistribution.mat"); % generated using permutation_based_nulldistribution script - 6000 permutations 

%% Remove channels not included in the report

mConsistency_allf_allchan(channels_to_exclude,:) = [];

permutedConsistency_allparticipants_allchan(channels_to_exclude,:) = [];

%% Significance threshold for each channel - 95th percentile

for chan = 1:19
    data = permutedConsistency_allparticipants_allchan(chan,:);

    sig_threshold_perchan(chan,:) = prctile(data,95);
end

%% Visualize average consistency for actual and permuted data for each channel

channel_names(channels_to_exclude,:) = [];

figure('Color','white');
for ch = 1:size(mConsistency_allf_allchan,1)
    data1 = mConsistency_allf_allchan(ch,:);
    data2 = permutedConsistency_allparticipants_allchan(ch,:);
    subplot(5,4,ch)

    histogram(data1,[0:0.01:1],'DisplayStyle','stairs','LineWidth',0.75);
    hold on
    histogram(data2,[0:0.01:1],'DisplayStyle','stairs','LineWidth',0.75);
    xline((prctile(data2,95)),'Color','k','LineWidth',1.0,LineStyle='--');
    title(channel_names(ch,1));
    legend('Actual consistency','Permuted consistency','p<0.05');
    hold off
end


%% Significant Features Per Channel

for ch = 1:size(mConsistency_allf_allchan)
    significant_consistency_idx = (mConsistency_allf_allchan(ch,:)>= prctile(permutedConsistency_allparticipants_allchan(ch,:),95));

    significant_featurecolumns = find(significant_consistency_idx);

    sig_features_perchannel{ch,:} = significant_featurecolumns;
end

%% Visualize no. of sig. features per channel

sig_features_perchannel(:,2) = channel_names(:,2);
sig_features_ch = cell2mat(sig_features_perchannel(:,2));

[~, sortIdx] = ismember(custom_locations.Number, sig_features_ch);

sig_features_perchannel_reordered = sig_features_perchannel(sortIdx,:);

for z = 1:length(sig_features_perchannel)
    no_sig_ch = sig_features_perchannel_reordered{z};

    sig_count = size(no_sig_ch,2);
    count_vector_forplot(1,z) = sig_count;
end

figure('Color','white');
scatter(1:length(count_vector_forplot),count_vector_forplot,'.');
hold on
plot(1:19,count_vector_forplot,'-','color','#D95319',HandleVisibility='off');
yline(0.05*6507,'g',DisplayName="Expected no. of features at p<0.05")
xlabel('Channel','FontWeight','bold');
xticks(1:1:19);
xticklabels(custom_locations.labels);
ylabel('N Sig. features','FontWeight','bold');
legend("No. of significant features", "Expected no. of features at p<0.05");
hold off

%% Topo plot for no. of significant feautures at each channel

ch_list = custom_locations{:,2};

%count_vector_forplot = count_vector_forplot(:,custom_locations.Number);

figure('Color','white');
[fig,ch_x,ch_y] = plot_topography_nosmooth(ch_list,count_vector_forplot,true,custom_locations,false,true,1000);
hold on
scatter(ch_x,ch_y,150,count_vector_forplot,"filled");
hold off


%% Find feature with highest consistency at each channel

[m,idx] = max(mConsistency_allf_allchan,[],2);

chan_bestconsistency_withFeatureID = [m idx];

%% Visualise feature values for specific channels and features - stop here if below code is not necessary

% rowdata_dreamful_allsubj = vertcat(rowdata_dreamful_allsubj{:});
% rowdata_dreamless_allsubj = vertcat(rowdata_dreamless_allsubj{:});
% 
% counts = 1:27;
% 
% figure("Color",'white');
% scatter(1:length(counts), rowdata_dreamful_allsubj,'o','filled','DisplayName','Dreamful');
% hold on
% scatter(1:length(counts)+0.5,rowdata_dreamless_allsubj,'x','LineWidth',1.5,'DisplayName','Dreamless');
% legend('Dreamful','Dreamless');
% title('Dreamful and Dreamless Feature Values for Best Performing Feature at Channel P3');
% xlabel('Participants');
% ylabel('Feature Value');
% ylim([-0.2 1.2])
% xline([3,6,9,12,15,18,21,24,27]+0.5, Alpha = 0.5,LineStyle='--',HandleVisibility='off');
% yline(0, Alpha = 0.5,HandleVisibility='off');
% 
% xticks(0.5:3:27.5);
% for tick1 = 1:9
%     xstringlabel{tick1} = ['P' num2str(tick1)];
% end
% xticklabels(xstringlabel);
% 
% hold off

%% Post-hoc analysis on spectral-power related features 
 
SP_feat_consistency = mConsistency_allf_allchan(:,3529:3884);

% Plot mean accuracy of SP features across channels
meanSP_acrosschan = mean(SP_feat_consistency);
meanSig_threshold = mean(sig_threshold_perchan);

figure('Color','white');
histogram(meanSP_acrosschan,HandleVisibility="off");
xline(meanSig_threshold,'r');
xlabel('Distribution of Classification Accuracies for Spectral Power Features');
legend('Significance Threshold');

% How many SP features are greater than the 0.05 threshold?

sig_SP_features_idx = meanSP_acrosschan>= meanSig_threshold; % this is the 0.05 threshold value from 'Statistical_testing_accuracies.m' script
sig_SP_featurecolumns = find(sig_SP_features_idx); % Result is none by the way

% Visualize the distribution of spectral power performance at each channel for the main 19 electrodes

figure('Color','white');
for s = 1:size(SP_feat_consistency,1)
    data = SP_feat_consistency(s,:);
    subplot(5,4,s)
    
    histogram(data)
    hold on 
    xline(meanSig_threshold,'Color','r','LineWidth',1.5)
    title(channel_names(s,1));
    xlabel('SP Features Classification Accuracies');
    hold off
end

% Are the features above the 0.05 threshold outliers? Check z-scores

for ch = 1:19
    acc_SP = SP_feat_consistency(ch,:);
    z = (acc_SP - mean(acc_SP)) / std(acc_SP);

    outlier_perchannel{ch,:} = find(z > 2.5);
end

SP_feature_outliers = unique([outlier_perchannel{:}]);

% Let's omit outliers

SP_feat_consistency(:,SP_feature_outliers) = [];

figure('Color','white');
for s = 1:size(SP_feat_consistency,1)
    data = SP_feat_consistency(s,:);
    subplot(5,4,s)
    
    histogram(data)
    hold on 
    xline(meanSig_threshold,'Color','r','LineWidth',1.5)
    title(channel_names(s,1));
    xlabel('SP Features Classification Accuracies');
    hold off
end

[m,idx] = max(SP_feat_consistency,[],2);
SP_bestconsistency_withFeatureID = [m idx];

% SP Operations

SP_Operations = Operations_postfilter(3529:3884,:);
SP_Operations(SP_feature_outliers,:) = [];

% The number of signicant SP features per channel

for ch = 1:size(SP_feat_consistency)
    significant_SPconsistency_idx = SP_feat_consistency(ch,:)>= meanSig_threshold;

    significant_SPfeaturecolumns = find(significant_SPconsistency_idx);

    sig_SPfeatures_perchannel{ch,:} = significant_SPfeaturecolumns;
end




