%% UNTESTED UNTESTED UNTESTED
function fPaths = writedat(data, fPathRoot, varargin)
%% WriteDat
% Writes data to a binary file

%% Syntax
%# data = writedat(data, fPathRoot)
%# data = writedat(data, fPathRoot, ... 'precision', prec)
%# data = writedat(data, fPathRoot, ... 'allowoverlap', precedence)

%% Description
% Writes time series data to a binary file, Generates a corresponding _t.* 
% and _ch.* file for time stamps and chan maps.


%% INPUT
% * data - a structure with the following fields:
%     * traces - an 1xN cell array, each cell contains the traces 
%     in an MxT array, with each row containing the trace from a different
%     channel
%     * chans - an Mx2 cell array of channel names. The first column is a 
%     unique channel number, the second is the label for that channel.
%     * tPts - an 1xN cell array, each cell contains a 1xT numeric vector of
%     timestamps. Their should be the same number of time stamps as their
%     are time indices in the traces, or else an error is returned. The
%     series of N timestamp lists should be monotonically increasing, and
%     each timestamp should be unique.

%% OPTIONAL
% * 'precision' - the data format in the time series, the same as the
% precision setting on 'fread'. Default is 'int16'.
% * 'allowoverlap' - allows for data with overlapping timestamps to be
% written, and uses the precedence argument to determine whether the first
% instance ('first') or the last instance ('last') will be used. If
% precedence is empty, 'first' is the default.

%% OUTPUT
% * fPaths - a 3x1 cell array of strings, the first is the name of the dat
% file path (same as fPathRoot), the second is the name of the time stamps
% file, and the third is the name of the channel map file

%% Example

%% Executable code

% format inputs
if any(strcmp(varargin, 'precision'))
    prec = varargin{find(strcmp(varargin,'precision'))+1};
else
    prec = 'int16';
end

if any(strcmp(varargin, 'allowoverlap'))
    overlapYes = true;
    overlapDir = varargin{find(strcmp(varargin, 'allowoverlap'))+1};
    if isempty(overlapDir)
        overlapDir = 'first';
    end
else
    overlapYes = false;
end

% test that data is properly formatted and collapse all entries
if size(data.chans,1) ~= length(unique(cell2mat(data.chans(:,1))))
    error('Channel ID indices are non-unique');
end

for j = 1:length(data.traces)
    if size(data.traces{j},1) ~= size(data.chans,1)
        error('Inconsistent number of channels');
    end
    
    if size(data.traces{j},2) ~= size(data.tPts{j},2)
        error('Inconsistent number of timestamps');
    end
end

traces = cast(cell2mat(data.traces), prec);
tStamps = cell2mat(data.tPts);

% if overlap is allowed in data, then extract unique time points
if overlapYes
    tInds = 1:length(tStamps);
    tSorted = sortrows([tStamps' tInds'], 1);
    [~, tIndsSel, ~] = unique(tSorted(:,1), overlapDir);
    tStamps = tSorted(tIndsSel,1);
    tInds = tSorted(tIndsSel,2);
    traces = traces(:,tInds);
end

% test the validity of time stamps
if any(diff(tStamps)<=0)
    error('Timestamps are non-monotonic or nonunique');
elseif any(diff(sort(tStamps))==0)
    error('Timestamps are nonunique');
end

suffixInd = strfind(fPathRoot,'.');

if ~isempty(suffixInd)
    suffix = fPathRoot((suffixInd(end)+1):end);
    fPathRoot = fPathRoot(1:(suffixInd(end)-1));
else
    suffix = 'dat';
end
% create timestamps and channel files
tPath = [fPathRoot '_t.' suffix];
chPath = [fPathRoot '_ch.csv'];

tFID = fopen(tPath, 'w');
chFID = fopen(chPath, 'w');

fwrite(tFID, tStamps, 'double');
fclose(tFID);

for j = 1:size(data.chans,1)
    fprintf(chFID, '%u,%s\r\n', data.chans{j,:});
end
fclose(chFID);

% write out trace data
datPath = [fPathRoot '.' suffix];
datFID = fopen(datPath, 'w');

fwrite(datFID, traces, prec);
fclose(datFID);

fPaths{1} = datPath;
fPaths{2} = tPath;
fPaths{3} = chPath;