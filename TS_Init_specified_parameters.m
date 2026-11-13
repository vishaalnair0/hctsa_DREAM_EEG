%% TS_Initialize with specified parameters to exclude figure generation

clear;
clc;

load('.\AllCases_AllChan.mat');

% Initialize hctsa analysis with  specified beVocal parameter


TS_Init('AllCases_AllChan.mat',[],[],[false,false,false]);