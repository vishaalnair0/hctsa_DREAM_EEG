%% hctsa Computation for All Cases All Channels - bandpass filtering (0.75 - 30Hz) and resampling (128Hz). 
% This is the corrected script using EEGLAB's resample and bandpassing function

clear;
clc;

addpath 'D:\DREAMEEG_hctsa' %% custom file location where data is stored in local device

% File directory for the cases
file_dir = 'D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts\Cases';
cd(file_dir)
files = dir([file_dir '\*.cnt']);

%% Load cases 

datapoints = 7680; % expected datapoints after resampling to 128 fs

allcases_allchan = NaN(datapoints,29,54); %% resampling to 128Hz brings data points to 7680

for i = 1:length(files)
    subfile = files(i).name;

    % Load data
    datafile = pop_loadcnt(subfile);

    % Resample from 2000Hz to 128Hz for each case
    ID_resampled = pop_resample(datafile, 128);

    % Apply the Bandpass Filter (0.75–30 Hz)
    ID_bandpassed = pop_eegfiltnew(ID_resampled, 0.75, 30);

    % Retrieve all channels for each case
    for chan = 1:size(ID_bandpassed.data, 1)
        allcases_allchan(:,chan,i) = ID_bandpassed.data(chan,:);
    end
end

% Collapse Dimensions to get the main data matrix

allcases_allchan = reshape(allcases_allchan, datapoints, (29*54));
allcases_allchan = (allcases_allchan)'; % transpose matrix

% File directory for main script and variables
file_dir = 'D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts';
cd(file_dir)

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

% ------------------------------------------------ TS_Initialize on a separate script -------------------------------------------------%












