%% Filtering NaNs, constant values and errors from Raw HCTSA output via logical indexing
% (EEG param.: 0.75-30Hz, 128Hz Fs)

clear;
clc;

load('D:\DREAMEEG_hctsa\Corrected Bandpassfiltered data and cleaned scripts\HCTSA.mat'); %%custom location in local device

%% Finding errors and NaNs based on TS_Quality 
% 1 = fatal error, 2 = NaN values

mask = (TS_Quality == 1 | TS_Quality == 2);

TS_DataMat_filled = TS_DataMat;
TS_DataMat_filled(mask) = NaN; % for indexing, because hctsa converts NaNs to 0 in raw output matrix

checkNaN = any(isnan(TS_DataMat_filled));
NaN_total = sum(checkNaN);

%% Finding constant values 

constant_features = any((std(TS_DataMat_filled)==0),1); % we use std to find constant vals
constant_total = sum(constant_features);

%% Identifying features columns to omit  - stage 1 filter

bad_featurecolumns = constant_features | checkNaN;

badfeature_indices = find(bad_featurecolumns); % this includes both NANs and constants

%% Identifying omitted feature IDs / operations

badfeature_indices = badfeature_indices';

featureIDs_removed = Operations(badfeature_indices,:);

Operations_postfilter = Operations;
Operations_postfilter(badfeature_indices,:) = [];

%% Omit columns from main output

filtered_output = TS_DataMat;
filtered_output(:,badfeature_indices) = []; % no normalisation 

%% Save output

save('Filtered_output_and_operations.mat',"filtered_output","Operations_postfilter");

% reminder-this is from 128Hz resampled data with 0.75-30Hz bandpass range


