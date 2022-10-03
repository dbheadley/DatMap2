function data = readdat(fPath, varargin)
%% readdat
% Loads data from binary file

%% Syntax
%# data = readdat(fPath)
%# data = readdat(fPath, ... 'chmapname', chMapFName)
%# data = readdat(fPath, ... 'tmapname', tMapFName)
%# data = readdat(fPath, ... 'precision', prec)
%# data = readdat(fPath, ... 'twindows', tWinds)
%# data = readdat(fpath, ... 'chunkread', [chkDur chkOLap])
%# data = readdat(fPath, ... 'selchans', selChans)
%# data = readdat(fPath, ... 'EQUDUR')

%% Description
% Extracts time series from a binary file at particular time points and
% electrodes. Looks for a corresponding _t.* and _cm.* files to obtain time
% stamps and electrode maps.


%% INPUT
% * fPath - a string, the name of the binary file

%% OPTIONAL
% * 'chmapname' - the name of the file containing the channel mapping
% * 'tmapname' - the name of the file containing the time stamps
% * 'twindows - an Nx2 array specifying the segments that will be returned
% each row is a different segment, with the first column being the start
% time and the second the finish. Time is given in seconds. If a twindow
% begins or ends outside the range of time stamps, then the entire trace
% for that window is returned as a NaN, or a list of NaNs if EQUDUR is
% specified.
% * 'chunkread' - a 2 element vector, with the first element specifying the
% chunk size in seconds, and the second the amount of overlap between
% chunks, also in seconds. The overlap time must be less than the chunk 
% duration. Overrides the 'twindows' argument.
% * 'selchans' - a vector of the channels to return. If numeric, then
% channels are specified by the chan index column in the chan map file. If
% instead it is a cell array of strings, than the chan names are used.
% Indexing starts at 1.
% * 'precision' - the data format in the time series, the same as the
% precision setting on 'fread'. Default is 'int16'.
% * 'EQUDUR' - specified that all windows should have the same length.
% Uses the median length to set to window length for all segments

%% OUTPUT
% * data - a structure with the following fields:
%     * traces - an 1xN cell array, each cell contains the series traces across the
%     selected electrodes in an MxT array, with each row containing the trace
%     from a different channel
%     * chans - an Mx2 cell array of channel names based on chan file. The
%     first column is a unique channel number, the second is the label for
%     that channel.
%     * tPts - an 1xN cell array, each cell contains a 1xT numeric vector of
%     timestamps
%     * tOff - an 2xN numeric array, each row is a different sample window.
%     Column 1 is the error in the startT time point, while column 2 is the
%     error for the duration of the window
%     * settings - specifies parameters of the file that was read.
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

dataInfo = datinfo(fPath, 'precision', prec, 'chmapname', chFName, ...
  'tmapname', tFName, 'returntimes');

if any(strcmp(varargin, 'chunkread'))
    chkParams= varargin{find(strcmp(varargin,'chunkread'))+1};
    chkDur = chkParams(1);
    chkOLap = chkParams(2); 
    chkReadYes = true;
else
    chkReadYes = false;
    if any(strcmp(varargin, 'twindows'))
        winT = varargin{find(strcmp(varargin,'twindows'))+1};
    else
        winT = [dataInfo.StartTime dataInfo.EndTime];
    end
end

if any(strcmp(varargin, 'selchans'))
    selChans = varargin{find(strcmp(varargin,'selchans'))+1};
    if ~isempty(selChans)
        specChanYes = true;
        if ischar(selChans)
            selChans = {selChans};
        end
    else
        specChanYes = false;
    end
else
    specChanYes = false;
end

if any(strcmp(varargin, 'EQUDUR'))
    eqDurYes = true;
else
    eqDurYes = false;
end

% get timestamps and channel info
tStamps = dataInfo.TimeStamps.data;
numChan = dataInfo.ChannelCount;
chNames = [num2cell(1:numChan)' dataInfo.ChannelNames(:)];
numTPts = dataInfo.TimeStampCount;

% if specific channels are requested, than find their indices
if specChanYes
    if iscell(selChans)
        if length(unique(chNames(:,2))) < length(chNames(:,2))
            error('Redundant channel names');
        end
        
        retChans = cellfun(@(x)find(strcmp(x, chNames(:,2))), selChans, ...
            'UniformOutput', false);
        if any(cellfun(@(x)isempty(x), retChans))
            error('Unmatched channel name');
        end
        retChans = cell2mat(retChans);
    else
        retChans = selChans;
    end
else
    retChans = 1:numChan;
end

% create datamap, should throw an error if sizes do not agree
dataMap = memmapfile(fPath, 'Format', {prec [numChan numTPts] 'traces'});


% calculate all start points and durations
if chkReadYes
    tDur = dataInfo.EndTime - dataInfo.StartTime;
    if tDur < (chkDur+chkOLap)
        winT = [dataInfo.StartTime dataInfo.EndTime];
    else
        winT = [dataInfo.StartTime (chkDur+chkOLap)];
        currT = dataInfo.StartTime + chkDur;
        while (currT+chkDur+chkOLap)<dataInfo.EndTime
            winT(end+1,:) = [(currT-chkOLap) (currT+chkDur+chkOLap)];
            currT = currT + chkDur;
        end
        winT(end+1,:) = [currT-chkOLap dataInfo.EndTime];
    end
end
    
numWin = size(winT,1);   

if numWin == 0
    data.chans = chNames(retChans,:);
    data.settings.precision = prec;
    data.tOff = [];
    data.traces = [];
    data.tPts = [];
    return;
end
    
tOff = nan(numWin,2);
startInd = nan(numWin,1);
stopInd = nan(numWin,1);
for j = 1:numWin
    currStartT = winT(j,1);
    currFinishT = winT(j,2);
    
    if currFinishT == inf
        currFinishT = tStamps(end);
    elseif currFinishT == -inf
        currFinishT = tStamps(1);
    end
    
    if currStartT == -inf
        currStartT = tStamps(1);
    elseif currStartT == inf
        currStartT = tStamps(end);
    end

    startInd(j,1) = FindClosest(currStartT, tStamps);
    tOff(j,1) = tStamps(startInd(j,1)) - currStartT;

    stopInd(j,1) = FindClosest(currFinishT, tStamps); 
    tOff(j,2) = tStamps(stopInd(j,1)) - currFinishT;

end


% if all trace durations must be equal, than find the median duration
if eqDurYes
    winLen = floor(nanmedian(stopInd-startInd));
    validStops = ~isnan(stopInd);
    winList = repmat(winLen, sum(validStops), 1);
    stopInd(validStops) = startInd(validStops)+winList;
    %recalculate tOff
    tOff(validStops,2) = tStamps(validStops) - winT(validStops,2);
    nanLen = winLen+1;
else
    nanLen = 1;
end


data.chans = chNames(retChans,:);
data.settings.precision = prec;
data.tOff = tOff;

% get data
for j = 1:numWin
    disp(['Read in ' num2str(j) ' of ' num2str(numWin) ' time windows'])
    if isnan(startInd(j)) || isnan(stopInd(j)) || (stopInd(j) > numTPts)
      data.traces{1,j} = nan(length(retChans), nanLen);
      data.tPts{1,j} = nan(nanLen,1);
    else
      data.traces{1,j} = double(dataMap.data.traces(retChans, startInd(j):stopInd(j)));
      data.tPts{1,j} = tStamps(startInd(j):stopInd(j))';
    end
end


