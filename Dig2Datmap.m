function [datPath, tPath, chPath] = Dig2Datmap(fPath, varargin)
%% Dig2Datmap
% Formats a digitalin binary file from Intan to be read by datmap functions.

%% Syntax
% [datPath, tPath, chPath] = Dig2Datmap(fPath)

%% Description
% Digital inputs from the Intan recording system are stored as 16 bit 
% binary numbers. Each bit corresponds to one digital input. The sample
% rate is defined in the info.rhd of the same directory.
% This function creates a new binary file with each digital input split 
% into a separate channel and the times set by the sample rate in info.rhd.
% 
% Also returned are the corresponding _t and _ch files that allow the
% binary file to be read by datmap functions.

%% INPUT
% * fPath - a string, the full file path for the digitalin binary file.

%% OPTIONAL
% * SAMPLERATE - a number, the sample rate to be used for the digitalin
% file. Call this if the info.rhd is not present or you want to override
% the sample rate given by it.
% * CHANNAMES - a 16 length cell array of strings, the names of all the 
% channels.

%% OUTPUT
% * datPath - a string, the path to the binary file (same as fPath)
% * tPath - a string, the path to the _t file with time points
% * chPath - a string, the path to the _ch file with channel names

% get file name parts
[fDir, fName, fExt] = fileparts(fPath);
    

% get sample rate from info.rhd file.
if any(strcmp(varargin, 'SAMPLERATE'))
    sampRate = varargin{find(strcmp(varargin, 'SAMPLERATE'))+1};
else
    rhdFID = fopen(fullfile(fDir, 'info.rhd'));
    fseek(rhdFID, 8, 0);
    sampRate = fread(rhdFID,1,'single');
end

if any(strcmp(varargin,'CHANNAMES'))
    chanNames = varargin{find(strcmp(varargin,'CHANNAMES'))+1};
    if numel(chanNames) ~= 16
        error('The number of channel names specified was not 16');
    end
else
    chanNames = arrayfun(@(x)['DigitalIn' num2str(x)],1:16,'uniformoutput',false);
end

% create list of time points
fProps = dir(fPath);
numTPts = fProps.bytes/2; % data is int16, so 2 bytes per sample
tVals = (1:numTPts)/sampRate;

if rem(numTPts,1)~=0
    error('digitalin file appears corrupted');
end

% write new binary file with digital inputs broken out
datPath = fullfile(fDir, [fName '_dm' fExt]);
origFID = fopen(fPath,'r');
origData = fread(origFID,inf,'uint16');
fclose(origFID);

newData = (dec2bin(origData,16)=='1')';
newFID = fopen(datPath,'w');
fwrite(newFID,newData,'int16');
fclose(newFID);


% write _t file
tPath = fullfile(fDir, [fName '_dm_t' fExt]);
fidT = fopen(tPath,'w');
fwrite(fidT,tVals,'double');
fclose(fidT);

% write _ch file
chPath = fullfile(fDir, [fName '_dm_ch.csv']);
chFID = fopen(chPath, 'w');
for j = 1:length(chanNames)
    fprintf(chFID, '%u,%s\r\n', j, chanNames{j});
end
fclose(chFID);
