%% HCTSA matrix visualization - feature values from 128Hz resampled and 0.75-30Hz bandpass filtered data

clear;clc;

load('D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts\Filtered_output_and_operations.mat');

main_matrix = BF_NormalizeMatrix(filtered_output,'mixedSigmoid');
check_constvalues = find(std(main_matrix)==0);
main_matrix(:,check_constvalues) = [];
Operations_postfilter(check_constvalues,:) = [];

%% Variables List

load('channels_excluded.mat');
load('Variable_list.mat');
load('channel_names.mat');

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

%% Omit channels that will not be included

ch_list = repelem((channels)', 27); % total cases = 54, 1 condition = 27
ch_omit_idx = find(ismember(ch_list,channels_to_exclude));

df_matrix_chansorted(ch_omit_idx,:) = [];
dl_matrix_chansorted(ch_omit_idx,:) = [];

matrix_sortedfinal = [df_matrix_chansorted;dl_matrix_chansorted];

%% Compute correlation distance matrix

corr_dist = 1 - corr(matrix_sortedfinal,'type','Spearman');

check_Diag = diag(corr_dist);
NaN_idx = isnan(check_Diag);

NaN_cols = find(NaN_idx);

matrix_sortedfinal(:,NaN_cols) = [];
Operations_postfilter(NaN_cols,:) = [];

corr_dist = 1 - corr(matrix_sortedfinal,'type','Spearman');

%% Cluster tree

tree = linkage(squareform(corr_dist), 'average');
[h, T, order] = dendrogram(tree, 0);

%% HCTSA feature matrix final visualization - sorted by dream cond., chan, corr. clustering order

channel_names(channels_to_exclude,:) = [];

figure('Color','white');
imagesc(matrix_sortedfinal(:, order));
cb = colorbar();
ylabel(cb,"Feature Value");
ylabelHandle = ylabel("Time-Series Sorted by Channel and Dream Condition",FontWeight="bold");
xlabel("Features sorted by Hier. Clustering");
yline(513.5,Color="red",LineWidth=2.5);

% Combine the tick positions
ytick_positions = [1:27:513, 514:27:1026];

% Repeat the channel names for both halves
ytick_labels = repmat(channel_names(:,1), 2, 1);

% Set the combined tick positions and labels
set(gca, 'YTick', ytick_positions);
set(gca, 'YTickLabel', ytick_labels);

%set(gca,'YTick',(1:27:513));
%set(gca,'YTickLabel',channel_names(:,1));

% Adjust position of the ylabel
ylabelPosition = get(ylabelHandle, 'Position');
ylabelPosition(1) = ylabelPosition(1); % Move the y-label further to the left
set(ylabelHandle, 'Position', ylabelPosition);

%% HCTSA feature matrix final visualization - alternative y-axis labelling and order

ch_names_toReorder_idx = [1;2;3;4;5;6;17;7;8;9;10;18;11;12;13;14;19;15;16];
channel_names_reordered = channel_names(ch_names_toReorder_idx);

matrix_sortedfinal_df = matrix_sortedfinal(1:513,:);
matrix_sortedfinal_dl = matrix_sortedfinal(514:1026,:);

rows_perblock = 27; % 27 cases
blocks_df = mat2cell(matrix_sortedfinal_df, repmat(rows_perblock,19,1),size(matrix_sortedfinal_df,2));
blocks_dl = mat2cell(matrix_sortedfinal_dl, repmat(rows_perblock,19,1),size(matrix_sortedfinal_dl,2));

reordered_blocks_df = blocks_df(ch_names_toReorder_idx);
reordered_blocks_dl = blocks_dl(ch_names_toReorder_idx);

reordered_df_matrix = vertcat(reordered_blocks_df{:});
reordered_dl_matrix = vertcat(reordered_blocks_dl{:});

matrix_sortedfinal_newsort = [reordered_df_matrix;reordered_dl_matrix];

% Plot
figure('Color','white');
imagesc(matrix_sortedfinal_newsort(:, order));
cb = colorbar();
ylabel(cb,"Feature Value");
ylabelHandle = ylabel("Time-Series Sorted by Channel and Dream Condition",FontWeight="bold");
xlabel("Features sorted by Hier. Clustering");
yline(513.5,Color="red",LineWidth=2.5);

% Y-ticks
tick1_blocks = [1:6 7];     % Blocks 1-6 and 17 are now in positions 1-6 and 7
tick2_blocks = [8:11 12];   % Blocks 7-10 and 18 are now in positions 8-11 and 12
tick3_blocks = [13:16 17];  % Blocks 11-14 and 19 are now in positions 13-16 and 17


% Compute tick centers for one half (top 513 rows)
tick1_start = (min(tick1_blocks)-1) * rows_perblock  + 1;
tick2_start = (min(tick2_blocks)-1) * rows_perblock + 1;
tick3_start = (min(tick3_blocks)-1) * rows_perblock + 1;

tick_half = [tick1_start; tick2_start; tick3_start];

ytick_positions = [tick_half; tick_half + 513];
ytick_labels = {'Frontal', 'Central', 'Occipital', 'Frontal', 'Central', 'Occipital'};

yticks(ytick_positions);
yticklabels(ytick_labels);
set(gca,'FontSize',12);
