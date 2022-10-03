function dataInfo = datinfo(fPath, varargin)
%% datinfo
% Provides properties of the data file in fPath

%% Syntax
%# dataInfo = datinfo(fPath)
%# dataInfo = datinfo(fPath, ... 'chmapname', chMapFName)
%# dataInfo = datinfo(fPath, ... 'tmapname', tMapFName)
%# dataInfo = datinfo(fPath, ... 'precision', prec)
%# dataInfo = datinfo(fpath, ... 'returntimes');

%% Description
% For the dat file specified by fPath, datinfo provides a summary of that
% dat files properties based on the corresponding chMap and tMap files.


%% INPUT
% * fPath - a string, the name of the binary file

%% OPTIONAL
% * 'chmapname' - the name of the file containing the channel mapping
% * 'tmapname' - the name of the file containing the time stamps
% * 'precision' - the data format in the time series, the same as the
% precision setting on 'fread'. Default is 'int16'.
% * 'returntimes' - provides the time stamps for the dat file.

%% OUTPUT
% * dataInfo - a structure with the following fields:
%     * StartTime - the first time stamp.
%     * EndTime - the last time stamp.
%     * TimeStampCount - the number of time stamps
%     * DatSize - size of the dat file when expressed as a matlab array.
%     * TimeStep - the time between the first two samples. Only informative
%     if samples are acquired at a fixed rate.
%     * ChannelCount - the number of channels.
%     * ChannelNames - a cell array of channel names
%     * Precision - the format of the data in the dat file, assumed to be
%     16 bit or inherited from the 'precision' argument.
%     * TimeStamps - if the 'returntimes' argument is provided, then the 
%     datamap object of time stamps are provided in this field.

%% Example

%% Executable code

% format inputs

if any(strcmp(varargin, 'tmapname'))
    tFName = varargin{find(strcmp(varargin,'tmapname'))+1};
else
    tFName = [];
end

if any(strcmp(varargin, 'chmapname'))
    chFName = varargin{find(strcmp(varargin,'chmapname'))+1};
else
    chFName = [];
end

if any(strcmp(varargin, 'precision'))
    prec = varargin{find(strcmp(varargin,'precision'))+1};
else
    prec = 'int16';
end
byteNum = ByteSizeLUT(prec);

if any(strcmp(varargin, 'returntimes'))
    retTStamps = true;
else
    retTStamps = false;
end
% get file ids and check for length consistency
if isempty(tFName)
    dotInds = strfind(fPath, '.');
    tFile = [fPath(1:(dotInds(end)-1)) '_t' fPath(dotInds(end):end)];
else
    tFile = tFName;
end

if isempty(chFName)
    dotInds = strfind(fPath, '.');
    chFile = [fPath(1:(dotInds(end)-1)) '_ch.csv'];
else
    chFile = chFName;
end

% get timestamps and channel info
tMap = memmapfile(tFile, 'Format', 'double');
chFID = fopen(chFile, 'r');
chNames = textscan(chFID, '%u %s', 'delimiter', ',');
fclose(chFID);
chNames = [num2cell(chNames{1}) chNames{2}];
numChan = size(chNames,1);
numTPts = length(tMap.data);

% make sure number of channels and time points agrees with file size
datFProps = dir(fPath);
numSamps = datFProps.bytes/byteNum;
if numSamps ~= (numChan * numTPts)
    error('Chan map and time stamp files disagree with data file');
end

% create datamap, should throw an error if sizes do not agree
dataMap = memmapfile(fPath, 'Format', {prec [numChan numTPts] 'traces'});

dataInfo.StartTime = tMap.data(1);
dataInfo.EndTime = tMap.data(end);
dataInfo.TimeStampCount = numTPts;
dataInfo.DatSize = size(dataMap.data.traces);
if numTPts > 1
  dataInfo.TimeStep = tMap.data(2)-tMap.data(1);
else
  dataInfo.TimeStep = NaN;
end
dataInfo.ChannelCount = numChan;
dataInfo.ChannelNames = chNames(:,2);
dataInfo.Precision = prec;
if retTStamps
  dataInfo.TimeStamps = tMap;
end
dataInfo.TFile = tFile;
dataInfo.ChFile = chFile;
