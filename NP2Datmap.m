function [datPath, tPath, chPath] = NP2Datmap(fPath)
%% NP2Datmap
% Creates the metadata files needed for a spikeglx binary file to be read
% by datmap functions.

%% Syntax
% [datPath, tPath, chPath] = NP2Datmap(fPath)

%% Description
% Neuropixel recordings with SpikeGLX are stored as binary and .meta files.
% This function uses the parameters specified in the .meta file to create
% _t and _ch files that allow the binary file to be read by datmap
% functions.

%% INPUT
% * fPath - a string, the full file path for the SpikeGLX binary file.

%% OPTIONAL

%% OUTPUT
% * datPath - a string, the path to the binary file (same as fPath)
% * tPath - a string, the path to the _t file with time points
% * chPath - a string, the path to the _ch file with channel names

datPath = fPath;
% get file name parts
[fDir, fName, fExt] = fileparts(fPath);
    
% get recording parameters from meta file.
params = ReadNPMeta([fName '.meta'], fDir);

numChans = str2num(params.nSavedChans);
numTPts = str2num(params.fileSizeBytes)/(2*numChans);

if isfield(params, 'imSampRate')
    sampRate = str2num(params.imSampRate);
elseif isfield(params, 'niSampRate')
    sampRate = str2num(params.niSampRate);
else
    error('Unknown sample rate')
end

chanList = params.snsChanMap;

chanNames = regexp(chanList,'\((\w+);\d+\:\d+\)','tokens');

% create list of time points
tVals = (1:numTPts)/sampRate;

if rem(numTPts,1)~=0
    error('Meta file is indicates incorrect number of time points');
end

% write _t file
tPath = fullfile(fDir, [fName '_t' fExt]);
fidT = fopen(tPath,'w');
fwrite(fidT,tVals,'double');
fclose(fidT);

% write _ch file
chPath = fullfile(fDir, [fName '_ch.csv']);
chFID = fopen(chPath, 'w');
for j = 1:length(chanNames)
    fprintf(chFID, '%u,%s\r\n', j, chanNames{j}{1});
end
fclose(chFID);
