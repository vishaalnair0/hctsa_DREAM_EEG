%% Generate random direction consistency outcomes per participant to obtain the complete random distribution (EEG param.: 0.75-30Hz, 128Hz Fs)
% Here we use a more manual method, computing histograms of consistencies for each
% participant and then an average across participants

clear;
clc;

load('D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts\Filtered_output_and_operations.mat');
load('D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts\directions_and_thresholds.mat');

main_matrix = BF_NormalizeMatrix(filtered_output,'mixedSigmoid');
check_constvalues = find(std(main_matrix)==0);
main_matrix(:,check_constvalues) = [];
direction_matrix(:,check_constvalues) = [];
Operations_postfilter(check_constvalues,:) = [];

%% Variables List

load("Variable_list.mat");
load("channels_excluded.mat");
load("channel_names.mat");

%% All channel's Data Matrix

for channel = 1:length(channels) % we're going for all channels (19 is the number of channels)

    onechannel = find(channel_list == channel);
    chandata = main_matrix(onechannel,:); % The column parameter can be changed to specify just 1 feature, default is all
    
    direction_F7 = direction_matrix(channel,:); % Same comment as above
    
    % Set up permutations
    
    nPerms = 6000; % number of permutations 
    
    % 3 dreamful, 3 dreamless permutations: 20 total
    all_perms = nchoosek(1:6, 3);  % 20 x 3
    DC_null_all = zeros(length(nParticipants), nPerms);  % Each row = one participant
    
    % Loop over participants
    for p = 1:length(nParticipants)
        pid = nParticipants(p);
        
        % Get rows for this participant
        rows = find(subject_ID == pid);
        rowdata = chandata(rows, :);  % 6 trials x N features
    
        for i = 1:nPerms
            % Randomly sample one of the 20 permutations
            perm_idx = randi(20);  % Random integer from 1 to 20
            selected_perm = all_perms(perm_idx, :);
    
            % Build permuted labels (3 dreamful, 3 dreamless)
            labels = zeros(6,1);
            labels(selected_perm) = 1;
    
            % Split data using permuted labels
            dreamful_data = rowdata(labels == 1, :);
            dreamless_data = rowdata(labels == 0, :);
    
            % Compute DNVs (9 x N)
            DNVs = getDNV(dreamful_data, dreamless_data);
    
            % Compute direction consistency (scalar)
            DC_null_all(p, i) = getConsistency2r(DNVs,direction_F7);
        end
    end
    permutedConsistency_allparticipants = mean(DC_null_all, 1);
    permutedConsistency_allp_allchan{channel,:} = DC_null_all;
end

%% Get mean consistency across participants for each channel

for channel = 1:29
    data = permutedConsistency_allp_allchan{channel};

    permutedConsistency_allparticipants_allchan(channel,:) = mean(data,1);
end

%% Plot histograms per participant
figure('Color','white');
for p = 1:9
    subplot(3,3,p);
    histogram(DC_null_all(p,:));
    title(['Participant ' num2str(p)]);
    xlabel('Direction Consistency'); 
    ylabel('Participant');
end

%% Average across participants, and plot histogram

meanConsistency_permutedlables_allparticipants =  mean(DC_null_all, 1);

sig_threshold_95 = prctile(meanConsistency_permutedlables_allparticipants,95);

figure('Color','white');
histogram(meanConsistency_permutedlables_allparticipants,'HandleVisibility','off');
xlabel('Direction Consistency');
xline(sig_threshold_95,'DisplayName','95th percentile');
legend('95th percentile');
title('Permutation-Based Null Distribution of Direction Consistency');

%% Save the permutation-based null distribution

save('randperm_nulldistribution.mat',"permutedConsistency_allparticipants_allchan");

%% Significance threshold for each channel - 95th percentile

for chan = 1:29
    data = permutedConsistency_allparticipants_allchan(chan,:);

    sig_threshold_perchan(chan,:) = prctile(data,95);
end


%% 

histogram(permutedConsistency_allparticipants_allchan(1,:))

a = prctile(permutedConsistency_allparticipants_allchan(1,:),95);






