%% Statistical testing - Median Based Classifcation (EEG param.: 0.75-30Hz, 128Hz Fs)

clear;
clc;

addpath('D:\DREAMEEG_hctsa\plot_topography');
load('custom_locations.mat');

load("classification_accuracies.mat");

%% Variable list
load("channels_excluded.mat");
load("channel_names.mat");

channel_names(channels_to_exclude,:) = [];

%% Filter custom_locations 

ch_indexing = ismember(custom_locations.Number,channels_to_exclude);
check = find(ch_indexing);

custom_locations(check,:) = [];

%% Defining variables and dimensions

test_labels = [1 1 1 0 0 0];
prediction_list = nan(size(test_labels,2),1);
nParticipants = 1:9;
acc_matrix = nan(size(nParticipants,2),1);

% At this stage we omit the channels that are excluded in the registered report
chan_feat_accuracies(channels_to_exclude,:) = []; 

%% Loop and save predictions

for feature = 1:size(chan_feat_accuracies,2)
    for test_participant = 1: length(nParticipants)

    % Make predictions

        prediction_list = randsample(2,6,true)-1; % -1 because labels range from 0 to 1
            
            %% Accuracy check
            
            accurate = 0; 
            
            for c = 1:size(prediction_list,1)
                if prediction_list(c,1) == test_labels(1,c)
                    accurate = accurate + 1;
                end
            end
            acc_percentage = (accurate/size(prediction_list,1))*100;
        
            acc_matrix(test_participant) = acc_percentage;

    end
        mean_accuracy = mean(acc_matrix, 1);
        random_feature_accuracies(feature) = mean_accuracy;
end

%% Features greater than the accuracy at 95th percentile is statistically significant

sig_accuracy = prctile(random_feature_accuracies,95); 

%% P-value list for each feature at each channel

for ch = 1:size(chan_feat_accuracies,1)
    for f = 1:size(chan_feat_accuracies,2)
        
        percentile_value = sum(random_feature_accuracies >= chan_feat_accuracies(ch,f));
        sig_level(ch,f) = percentile_value / numel(random_feature_accuracies);
    end
end

%% Significant features per channel

row_counter = 1;
for i = 1:size(chan_feat_accuracies,1)
    [~,sig_features] = find(chan_feat_accuracies(i,:) >= sig_accuracy);

    sig_features_perchannel{row_counter,1} = sig_features;
    sig_values_perchannel{row_counter,:} = sig_level(i,(sig_features));

    row_counter = row_counter +1;
end

%% No. of sig features per channel plot - visualization

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
yline(0.05*6516,'g',DisplayName="Expected no. of features at p<0.05");
xlabel('Channel','FontWeight','bold');
ylabel('N Sig. features','FontWeight','bold');
xticks(1:1:19);
xticklabels(custom_locations.labels);
legend("No. of significant features", "Expected no. of features at p<0.05");
title("No. of significant features at each channel");
hold off

%% Topo plot for no. of significant feautures at each channel

ch_list = custom_locations{:,2};

%count_vector_forplot = count_vector_forplot(:,custom_locations.Number);

figure('Color','white');
[fig,ch_x,ch_y] = plot_topography_nosmooth(ch_list,count_vector_forplot,true,custom_locations,false,true,1000);
hold on
scatter(ch_x,ch_y,150,count_vector_forplot,"filled");
title("No. of significant features at each channel");
hold off

%% Random Distribution and Performance Distribution Visualization for each channel

figure('Color','white');
for k = 1:size(chan_feat_accuracies,1)
    data = chan_feat_accuracies(k,:);
    subplot(5,4,k)
    
    nbins = 0.9:(100/54):100;
    [N_norm,edges] = histcounts(data,nbins);
    plot (edges(1:end-1) , N_norm , 'b')
    hold on 
    %xline(median(chan_feat_accuracies(k,:)),'Color','r','LineWidth',1.0)
    %title(['Ch' num2str(k) ':' ' ' num2str(round(median(data),2))]);
    xline(sig_accuracy,'Color','r','LineWidth',1.0);
    title([channel_names(k,1)]);

    hold on
    histogram(random_feature_accuracies, (0:1.8519:100), 'DisplayStyle', 'stairs','EdgeColor',[0.4660 0.6740 0.1880],'LineWidth',1.0);
    hold off
end
