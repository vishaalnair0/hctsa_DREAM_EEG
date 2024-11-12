%% Statistical testing - Median Based Classifcation

clear;
clc;

load("Feature_Accuracies_results.mat");

%% Defining variables and dimensions

test_labels = [1 1 1 0 0 0];
prediction_list = nan(size(test_labels,2),1);
nParticipants = 1:9;
acc_matrix = nan(size(nParticipants,2),1);

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

for z = 1:length(sig_features_perchannel)
    no_sig_ch = sig_features_perchannel{z};

    sig_count = size(no_sig_ch,2);
    count_vector_forplot(1,z) = sig_count;
end

figure('Color','white');
scatter(1:length(count_vector_forplot),count_vector_forplot,'.');
hold on
plot(1:29,count_vector_forplot,'-','color','#D95319',HandleVisibility='off');
yline(0.05*6516,'g',DisplayName="Expected no. of features at p<0.05");
xlabel('Channel','FontWeight','bold');
ylabel('N Sig. features','FontWeight','bold');
legend("No. of significant features", "Expected no. of features at p<0.05");
hold off


%% Random Distribution and Performance Distribution Visualization for each channel

figure();
for k = 1:size(chan_feat_accuracies,1)
    data = chan_feat_accuracies(k,:);
    subplot(5,6,k)
    
    nbins = 0.9:(100/54):100;
    [N_norm,edges] = histcounts(data,nbins);
    plot (edges(1:end-1) , N_norm , 'b')
    hold on 
    %xline(median(chan_feat_accuracies(k,:)),'Color','r','LineWidth',1.0)
    title(['Ch' num2str(k) ':' ' ' num2str(round(median(data),2))]);
    xline(sig_accuracy,'Color','r','LineWidth',1.0);

    hold on
    histogram(random_feature_accuracies, (0:1.8519:100), 'DisplayStyle', 'stairs','EdgeColor',[0.4660 0.6740 0.1880],'LineWidth',1.0);
    hold off
end
