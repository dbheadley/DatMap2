function [tVid, qualMetrics] = viddattimealign(fPathVid,fPathRef,roiVid,chanRef)
%% viddattimealign
% Synchronizes the timing of a video and dat file

%% Syntax
%# [tVid, qualMetrics] = viddattimealign(fPathVid,fPathRef,roiVid,chanRef)

%% Description
% A synchonization pulse train shared between a video and dat file, fPathVid and
% fPathRef, is used to synchronize their times. The pulse train signals are
% on roiVid and chanRef, respectively. A _t file of fPathVid is created
% to reflect the timestamps in fPathRef. Thus, the two files can now be
% called with the same time reference.

%% INPUT
%  * fPathVid - a string, the name of the video file that will generate a
% _t file.
%  * fPathRef - a string, the name of the binary file that will be
% used as the timing reference.
%  * roiVid - an Nx6 array of integers, the ROIs used for detecting
%  the signal from the synchronization LED. Each row is formatted as: 
% [startX, startY, width, height, startFrame, stopFrame]. 
% If only one ROI is to be used, then startInd = 1 and stopInd = inf. 
%  * chanRef - an interger or string, the channel carrying the
%  synchronization signal in fPathRef.


%% OUTPUT
% * tVid - an array of numbers, the new timestamps for fPathVid that are
% aligned with those in fPathRef
% * qualMetrics - a structure, metrics for the quality of the time
% alignment.
%       -MedianDT: the median time step based on interpolation
%       -MinDT: the shortest time step based on interpolation
%       -MaxDT: the longest time step based on interpolation
%       -InterpPercent: the percentage of time points aligned via interpolation


%% Example

%% Executable code

% load synchrony channels
syncRef = readdat(fPathRef,'selchans', chanRef);

% reference time points
refTPts = syncRef.tPts{1};

% convert to boolean
syncRef = syncRef.traces{1}>1;

% load video ROI sync signal
vid = VideoReader(fPathVid);
vidRate = vid.FrameRate;
vidEstLength = vid.Duration*vidRate;
roiVid = round(roiVid);
fCounter = 0;
vecFunc = @(x)x(:);
waitH = waitbar(0,'Processing Video ROI');
while hasFrame(vid)
    fCounter = fCounter + 1;
    waitbar(fCounter/vidEstLength,waitH);
    currFrame = readFrame(vid);
    
    % determine the current ROI
    currROI = roiVid(find((fCounter>=roiVid(:,5))&(fCounter<=roiVid(:,6)),1),1:4);

    ledVid(fCounter) = mean(vecFunc(currFrame(currROI(2):(currROI(2)+currROI(4)),...
        currROI(1):(currROI(1)+currROI(3)),:)));
end
close(waitH);
[b, a] = butter(2,0.1/(vidRate/2),'high');
ledVid = filtfilt(b,a,ledVid);
% convert binary
ledVid = zscore(ledVid) >= 0;


% get pulse duration sequence
seqVid = regionprops(ledVid,{'Area' 'PixelIdxList'});
seqRef = regionprops(syncRef,{'Area' 'PixelIdxList'});

% align pulse sequences
pulseAligns = MeasureAlignment(vertcat(seqRef.Area),vertcat(seqVid.Area),30);
pulseEdgesVid = cellfun(@(x)x(1),{seqVid(pulseAligns(:,2)).PixelIdxList});
pulseEdgesRef = cellfun(@(x)x(1),{seqRef(pulseAligns(:,1)).PixelIdxList});
pulseEdgesVid = pulseEdgesVid(:);
pulseEdgesRef = pulseEdgesRef(:);

% if pulse is at the beginning, remove it because its start is ambiguous
if (pulseEdgesRef(1)==1)
    pulseEdgesRef(1) = [];
    pulseEdgesVid(1) = [];
end

% match pulse edges to time points
tPulseEdgesRef = refTPts(pulseEdgesRef);

% generate new time points for oth that are aligned with ref
tVid = interp1(pulseEdgesVid', tPulseEdgesRef', ...
                  pulseEdgesVid(1):pulseEdgesVid(end));

% calculate quality metrics based on interpolation results
dTList = diff(tVid);
medDT = median(dTList);
minDT = min(dTList);
maxDT = max(dTList);
qualMetrics.MedianDT = medDT;
qualMetrics.MinDT = minDT;
qualMetrics.MaxDT = maxDT;
qualMetrics.InterpPercent = length(tVid)/length(ledVid);

% add times for the beginning and end of the file
tVid = [(-((pulseEdgesVid(1)-1):-1:1)*medDT)+tVid(1) tVid];

remTPts = length(ledVid)-length(tVid);
tVid = [tVid tVid(end) + ((1:remTPts)*medDT)];

% overwrite old _t file for oth with new time points
[dirVid, fNameVid, extVid] = fileparts(fPathVid);
data.traces = {ledVid};
data.chans = {1, 'led'};
data.tPts = {tVid};
writedat(data, fullfile(dirVid,[fNameVid '_AVI']), 'precision','double');

% vidFID = fopen(fullfile(dirVid,[fNameVid '_AVI_t.dat']),'w');
% fwrite(vidFID,tVid,'double');
% fclose(vidFID);
