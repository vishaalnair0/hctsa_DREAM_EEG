%% Filtering NaNs, constant values and errors from Raw HCTSA output - logical indexing

clear;
clc;

load('D:\hctsa Project\All cases all channels\HCTSA.mat'); %%custom location in local device

%% Finding errors and NaNs based on TS_Quality 
% 1 = fatal error, 2 = NaN values

mask = (TS_Quality == 1 | TS_Quality == 2);

TS_DataMat_filled = TS_DataMat;
TS_DataMat_filled(mask) = NaN; % for indexing, because hctsa converts NaNs to 0 in raw output matrix

checkNaN = any(isnan(TS_DataMat_filled));
NaN_total = sum(checkNaN);

%% Finding constant values 

constant_features = any((std(TS_DataMat_filled)==0),1);
constant_total = sum(constant_features);

%% Identifying features columns to omit  - stage 1 filter

bad_featurecolumns = constant_features | checkNaN;

badfeature_indices = find(bad_featurecolumns);

%% Identifying omitted feature IDs / operations

badfeature_indices = badfeature_indices';

featureIDs_removed = Operations(badfeature_indices,:);

Operations_postfilter = Operations;
Operations_postfilter(badfeature_indices,:) = [];

%% Omit columns from main output

filtered_output_beforenorm = TS_DataMat;
filtered_output_beforenorm(:,badfeature_indices) = []; % before normalisation - output for classification analysis

%% Normalize output 

filtered_output_afternorm = BF_NormalizeMatrix(filtered_output_beforenorm,'mixedSigmoid');

%% Omitting constant values after normalisation - stage 3 filter

constant_cols_afternormed = find(std(filtered_output_afternorm)==0);

filtered_output_afternorm(:,constant_cols_afternormed) = []; % after normalization - output for consistency analysis


%% Identifying feature IDs / operations

filtered_Operations = Operations;
filtered_Operations(badfeature_indices,:) = []; 

featureIDs_removed_afternormed = filtered_Operations(constant_cols_afternormed,:);

%% All removed Operations

all_removedOperations = [featureIDs_removed;featureIDs_removed_afternormed];
all_removedOperations = sortrows(all_removedOperations,"ID","ascend");

