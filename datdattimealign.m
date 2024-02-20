function [tOthNew, qualMetrics] = datdattimealign(fPathOth,fPathRef,chanOth,chanRef)
%% datdattimealign
% Synchronizes the timing of two dat files

%% Syntax
%# timesOthNew = datdattimealign(fPathOth,fPathRef,chanOth,chanRef)

%% Description
% A synchonization pulse train shared between two dat files, fPathOth and
% fPathRef, is used to synchronize their times. The pulse train signals are
% on chanOth and chanRef, respectively. The _t file of fPathOth is changed
% to reflect the timestamps in fPathRef. The original _t file for fPathOth
% is overwritten with the new timestamps. Thus, the two files can now be
% called with the same time reference.

%% INPUT
%  * fPathOth - a string, the name of the binary file whose _t file will
% be synchronized.
%  * fPathRef - a string, the name of the binary file that will be
% used as the timing reference.
%  * chanOth - an interger or string, the channel carrying the
%  synchronization signal in fPathOth.
%  * chanRef - an interger or string, the channel carrying the
%  synchronization signal in fPathRef.


%% OUTPUT
% * tOthNew - an array of number, the new timestamps for fPathOth that are
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
syncOth = readdat(fPathOth,'selchans', chanOth);
syncRef = readdat(fPathRef,'selchans', chanRef);

othInfo = datinfo(fPathOth);

% reference time points
refTPts = syncRef.tPts{1};

% convert to boolean
syncOth = zscore(syncOth.traces{1})>0;
syncRef = zscore(syncRef.traces{1})>0;

% get pulse duration sequence
seqOth = regionprops(syncOth,{'Area' 'PixelIdxList'});
seqRef = regionprops(syncRef,{'Area' 'PixelIdxList'});

% align pulse sequences
pulseAligns = MeasureAlignment(vertcat(seqRef.Area),vertcat(seqOth.Area),30);
pulseEdgesOth = cellfun(@(x)x(1),{seqOth(pulseAligns(:,2)).PixelIdxList});
pulseEdgesRef = cellfun(@(x)x(1),{seqRef(pulseAligns(:,1)).PixelIdxList});
pulseEdgesOth = pulseEdgesOth(:);
pulseEdgesRef = pulseEdgesRef(:);

% if pulse is at the beginning, remove it because its start is ambiguous
if (pulseEdgesRef(1)==1)
    pulseEdgesRef(1) = [];
    pulseEdgesOth(1) = [];
end

% match pulse edges to time points
tPulseEdgesRef = refTPts(pulseEdgesRef);

% generate new time points for oth that are aligned with ref
tOthNew = interp1(pulseEdgesOth', tPulseEdgesRef', ...
                  pulseEdgesOth(1):pulseEdgesOth(end));

% calculate quality metrics based on interpolation results
dTList = diff(tOthNew);
medDT = median(dTList);
minDT = min(dTList);
maxDT = max(dTList);
qualMetrics.MedianDT = medDT;
qualMetrics.MinDT = minDT;
qualMetrics.MaxDT = maxDT;
qualMetrics.InterpPercent = length(tOthNew)/length(syncOth);

% add times for the beginning and end of the file
tOthNew = [(-((pulseEdgesOth(1)-1):-1:1)*medDT)+tOthNew(1) tOthNew];

remTPts = length(syncOth)-length(tOthNew);
tOthNew = [tOthNew tOthNew(end) + ((1:remTPts)*medDT)];


% overwrite old _t file for oth with new time points
othFID = fopen(othInfo.TFile,'w');
fwrite(othFID,tOthNew,'double');
fclose(othFID);

