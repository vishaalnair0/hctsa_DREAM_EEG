%% Median Classification for All Channels All Features with 9 Cross-Validations
clear;
clc;

load('D:\hctsa Project\General Workspace\Filtered_hctsa_output&operations.mat');

main_matrix = filtered_output;

%% Dream Status, Channels and Participants

load('Variable_list.mat');

%% Loop through all channels to retrieve trainrows and testrows
for channel = 1:length(channels)
    channel_ID = find(channel_list == channel);
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


%% Performance Distribution for each Channel

figure();
for k = 1:size(chan_feat_accuracies,1)
    data = chan_feat_accuracies(k,:);
    subplot(5,6,k)
    
    nbins = 0.9:(100/54):100;
    [N_norm,edges] = histcounts(data,nbins);
    plot (edges(1:end-1) , N_norm , 'b')
    hold on 
    xline(median(chan_feat_accuracies(k,:)),'Color','r','LineWidth',1.5)
    title(['Ch' num2str(k) ':' ' ' num2str(round(median(data),2))]);
end


%% Visualize the feature values of feature column 5090 (best-performing) for channel 20 for each case

channelFz_idx = find(channel_list==20);

channelFz_featurevalues = main_matrix(channelFz_idx,5090);
df_idx_chFz = find(dream_status);
dl_idx_chFz = find(~dream_status);
chFz_featurevalues_df = channelFz_featurevalues(df_idx_chFz);
chFz_featurevalues_dl = channelFz_featurevalues(dl_idx_chFz);

figure('Color','White');
scatter(1:27,chFz_featurevalues_df','DisplayName','Dreamful Condition','MarkerFaceColor','flat');
hold on
scatter(28:54,chFz_featurevalues_dl','DisplayName','Dreamless Condition','MarkerFaceColor','flat');
yline(threshold_matrix(20,5090),'r','DisplayName',"Classification Threshold");
title("Values for the Best-performing Feature at Channel Fz");
xlabel("Cases","FontWeight","bold");
ylabel("Feature Value","FontWeight","bold");
legend("Dreamful Condition","Dreamless Condition","Classification Threshold");

%% ADDITIONAL - I'm generating a hypothesised distribution for a candidate set of features 

% Arbitrary values 
start_value = 40.00;
end_value = 85.25;
desired_mean = 64;
num_points = 356;

% Generate a normally distributed random vector
mu = desired_mean;
sigma = (end_value - start_value) / 6; % Approximation for the standard deviation
random_vector = normrnd(mu, sigma, [1, num_points]);

% Clamp the values within the specified range
random_vector(random_vector < start_value) = start_value;
random_vector(random_vector > end_value) = end_value;

% Shuffle the vector
randomized_vector = random_vector(randperm(length(random_vector)));

