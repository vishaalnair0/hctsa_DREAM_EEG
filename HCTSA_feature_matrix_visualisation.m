%% %% Correlation distance clustering for all channels - sorted by dream condition

clear;
clc;

load('D:\hctsa Project\General Workspace\Filtered_hctsa_output&operations.mat');

main_matrix = BF_NormalizeMatrix(filtered_output,'mixedSigmoid');
check_constvalues = find(std(main_matrix)==0);
main_matrix(:,check_constvalues) = [];

%% Variables List

load('Variable_list.mat');

%% Sort by Dream Condition

df_idx = find(dreamstate_list);
dl_idx = find(~dreamstate_list);

df_main_matrix = main_matrix(df_idx,:);
dl_main_matrix = main_matrix(dl_idx,:);


%% Channel-sorted Data Matrix

for channel = 1:length(channels)
    chanID_idx = find(channel_list(1:783) == channel);

    chanIdx_list{channel} = chanID_idx;
end
chanIdx_list = vertcat(chanIdx_list{:});

%% Sort Matrix by both Channel and Dream Condition

df_matrix_chansorted = df_main_matrix(chanIdx_list,:);
dl_matrix_chansorted = dl_main_matrix(chanIdx_list,:);

matrix_sortedfinal = [df_matrix_chansorted;dl_matrix_chansorted];

%% Compute correlation distance matrix

corr_dist = 1 - corr(matrix_sortedfinal,'type','Spearman');

%% Cluster tree

tree = linkage(squareform(corr_dist), 'average');
[h, T, order] = dendrogram(tree, 0);

%% HCTSA feature matrix final visualization - sorted by dream cond., chan, corr. clustering order

figure('Color','white');
imagesc(matrix_sortedfinal(:, order));
cb = colorbar();
ylabel(cb,"Feature Value");
ylabelHandle = ylabel("Time-Series Sorted by Channel and Dream Condition",FontWeight="bold");
xlabel("Features");

%yticks(1:27:1566);
set(gca,'YTick',(1:27:783));
set(gca,'YTickLabel',channels');

% Adjust position of the ylabel
ylabelPosition = get(ylabelHandle, 'Position');
ylabelPosition(1) = ylabelPosition(1) - 1; % Move the y-label further to the left
set(ylabelHandle, 'Position', ylabelPosition);



