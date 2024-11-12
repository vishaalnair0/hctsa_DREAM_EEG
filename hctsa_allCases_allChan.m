%% hctsa Computation for All Cases All Channels - resampled 100Hz

addpath 'D:\hctsa Project' %% custom file location where data is stored in local device

% File directory
file_dir = 'D:\hctsa Project\Cases\Cases';
cd(file_dir)
files = dir([file_dir '\*.cnt']);

%% Load and resample cases

allcases_allchan = NaN(6000,29,54);

for i = 1:length(files)
    subfile = files(i).name;

    % Load data
    datafile = pop_loadcnt(subfile);

    % Resample from 2000Hz to 100Hz for each case
    ID_resampled = pop_resample(datafile, 100);

    % Retrieve all channels for each case
    for chan = 1:size(ID_resampled.data, 1)
        allcases_allchan(:,chan,i) = ID_resampled.data(chan,:);
    end
end

%% Collapse Dimensions
allcases_allchan = reshape(allcases_allchan, 6000, (29*54));
allcases_allchan = (allcases_allchan)'; % transpose matrix

%% Assign labels
nCases = 54;
nChannels = 29;
label = cell(nCases*nChannels, 1);
row_counter = 01;
for cases = 1:nCases
    for ch = 1:nChannels
        names =  ['ID' num2str(cases) '_ch' num2str(ch)];
        label_names{row_counter} = names;
        row_counter = row_counter + 1;
    end
end

label_names = (label_names)';

%% Assign keywords
dream_status = [1 0 1 1 0 1 1 0 0 0 0 1 1 0 0 1 1 0 1 1 1 0 1 0 0 0 1 0 0 1 1 0 0 0 0 1 0 1 1 1 1 1 0 1 0 0 0 0 0 1 0 1 1 1];
% 1 = dreamful, 0 = dreamless

x = repmat(dream_status,[29,1]);
dreamstate_list = reshape(x, [54*29, 1]);

nCases = 54;
nChannels = 29;
key = cell(nCases*nChannels, 1);
row_counter = 1;
for cases = 1:nCases
    for ch = 1:nChannels
        status = dream_status(cases);
        if status == 1
            status_string = "Dreamful";
        elseif status == 0
            status_string = "Dreamless";
        end
        names = strcat('ID',num2str(cases),',ch',num2str(ch),',',status_string);
        keyword_list{row_counter} = names;
        row_counter = row_counter + 1;
    end
end

keyword_list = (keyword_list)';

%% Assign input files for HCTSA
timeSeriesData = allcases_allchan;
labels = label_names;
keywords = keyword_list;
    
% Save input files -MAT 
save('AllCases_AllChan.mat','timeSeriesData','labels','keywords');

%% Initialize hctsa analysis with default feature library
TS_Init('AllCases_AllChan.mat');

%% Compute all missing values in HCTSA.mat, with parallel processing:
TS_Compute(true);

%% Inspect Quality
TS_InspectQuality();

%% Automatic Labelling to Existing Keywords
TS_LabelGroups('raw',{});

%% Normalize operation outputs, filtering time-series with errors/special values
TS_Normalize('mixedSigmoid', [0.9 1]);

%% Create order list
dreamful_state = find(dreamstate_list)';
dreamless_state = find(~dreamstate_list)';

Order = [dreamful_state dreamless_state];

%% Plot Data Matrix

figure(1);
imagesc(TS_DataMat(Order,op_clust.ord));
colorbar;
title("Time-Series by Feature Matrix");
ylabel("Time Series");
xlabel("Features");
set(gca,'fontsize',12,'LineWidth',2);

figure(2);
tiledlayout(2,1);
ax1 = nexttile;
imagesc(TS_DataMat(Order,op_clust.ord));
colorbar;
title("Dreamful State");
ylabel("Time Series");
xlabel("Features");
ylim(ax1,[0 783]);

ax2 = nexttile;
imagesc(TS_DataMat(Order,op_clust.ord));
colorbar;
title("Dreamless State");
ylabel("Time Series");
xlabel("Features");
ylim(ax2,[784 1566]);


