%% Computing Consistency - All Channels. Includes statistical testing 

clear;
clc;

load('D:\hctsa Project\General Workspace\Filtered_hctsa_output&operations.mat');
load('direction&threshold_allfeat_allchan.mat');

main_matrix = BF_NormalizeMatrix(filtered_output,'mixedSigmoid');
check_constvalues = find(std(main_matrix)==0);
main_matrix(:,check_constvalues) = [];
Operations_postfilter(check_constvalues,:) = [];

%% Variable List

load("Variable_list.mat");

%% Channel Iterations

for channel = 1:29
    channel_data = find(channel_list == channel);
    chandata = main_matrix(channel_data,:);

    for participant = 1:length(nParticipants)

        rows = find(subject_ID == participant);
        
        rowdata = chandata(rows,:);
        
        rows_condition = dream_status(rows);
        
        rows_dreamful = find(rows_condition);
        rows_dreamless = find(~rows_condition);
        
        rowdata_dreamful = rowdata(rows_dreamful,:);
        rowdata_dreamless = rowdata(rows_dreamless,:);

        % Compute actual DNV
        DNV_persubject = getDNV(rowdata_dreamful,rowdata_dreamless);
        differences_all{participant} = DNV_persubject;
    end
    
    DNV_allsubjects = vertcat(differences_all{:});
    DNV_allsubjects_allchan{channel} = DNV_allsubjects;
    
    load("Random_DNVs.mat"); % generated using random permutation of df/dl labels and saved - refer to "randperm_randdistribution..." script


    % Compute actual and random consistencies for one channel in this iteration
    % Actual consistencies
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

    % Random consistencies
    clear random_consistencies_allfeatures;

    for rand_f = 1:size(rand_differences_all,2)
        count2 = 1;
        for rDNV = 1:9:size(rand_differences_all,1)
            rDNV_vector = rand_differences_all(rDNV:rDNV+8,rand_f);
            direction2 = direction_matrix(channel,rand_f); 
    
            rand_consistency = getConsistency2r(rDNV_vector,direction2); %getConsistency2 computes consistency from DNV values
            Rconsistency_persubject(count2) = rand_consistency;
            count2 = count2 + 1;
        end
    random_consistencies_allfeatures{:,rand_f} = Rconsistency_persubject';
    end
    rand_consistencymatrix = horzcat(random_consistencies_allfeatures{:});

    mRandom_consistency_allfeatures = mean(rand_consistencymatrix);
    mRandom_consistency_allf_allchan{channel,:} = mRandom_consistency_allfeatures;
end

%% Mean consistency for each features each channel

mConsistency_allf_allchan = vertcat(mConsistency_allf_allchan{:}); % actual consistency
mRandom_consistency_allf_allchan = vertcat(mRandom_consistency_allf_allchan{:}); % random consistency


%% Visualize average consistency for actual and permuted data for each channel

figure();
for ch = 1:size(mConsistency_allf_allchan,1)
    data1 = mRandom_consistency_allf_allchan(ch,:);
    data2 = mConsistency_allf_allchan(ch,:);
    subplot(5,6,ch)

    histogram(data1,[0:0.01:1],'DisplayStyle','stairs','LineWidth',0.75);
    hold on
    histogram(data2,[0:0.01:1],'DisplayStyle','stairs','LineWidth',0.75);
    xline((prctile(data2,95)),'Color','k','LineWidth',1.0,LineStyle='--');
    title(['Ch' ' ' num2str(ch)]);
    hold off
end

%% Significance threshold value at each channel

for ch = 1:size(mRandom_consistency_allf_allchan,1)
    c = mRandom_consistency_allf_allchan(ch,:);
    
    sig_thresholdval_perchan(ch,1) = prctile(c,95);
end

%% Significant Features Per Channel

for ch = 1:size(mConsistency_allf_allchan)
    significant_consistency_idx = (mConsistency_allf_allchan(ch,:)>= sig_thresholdval_perchan(ch,1));

    significant_featurecolumns = find(significant_consistency_idx);

    sig_features_perchannel{ch,:} = significant_featurecolumns;
end

%% Visualize no. of sig. features per channel

for z = 1:length(sig_features_perchannel)
    no_sig_ch = sig_features_perchannel{z};

    sig_count = size(no_sig_ch,2);
    count_vector_forplot(1,z) = sig_count;
end

figure('Color','white');
scatter(1:length(count_vector_forplot),count_vector_forplot,'.');
hold on
plot(1:29,count_vector_forplot,'-','color','#D95319',HandleVisibility='off');
yline(0.05*6507,'g',DisplayName="Expected no. of features at p<0.05")
xlabel('Channel','FontWeight','bold');
ylabel('N Sig. features','FontWeight','bold');
legend("No. of significant features", "Expected no. of features at p<0.05");
hold off



%% P-value list for each feature at each channel
% P-value is computed per channel, hence mRandom_consistency_allf_allchan(ch,:)

for ch = 1:size(mConsistency_allf_allchan,1)
    for f = 1:size(mConsistency_allf_allchan,2)
        
        percentile_value = sum(mRandom_consistency_allf_allchan(ch,:) >= mConsistency_allf_allchan(ch,f));
        pvalue_perfeature(ch,f) = percentile_value / numel(mRandom_consistency_allf_allchan(ch,:));
    end
end


%% Find feature with highest consistency at each channel

[m,idx] = max(mConsistency_allf_allchan,[],2);

chan_bestconsistency_withFeatureID = [m idx];



