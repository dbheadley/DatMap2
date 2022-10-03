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
syncOth = syncOth.traces{1}>1;
syncRef = syncRef.traces{1}>1;

% get pulse duration sequence
seqOth = regionprops(syncOth,{'Area' 'PixelIdxList'});
seqRef = regionprops(syncRef,{'Area' 'PixelIdxList'});

% align pulse sequences
pulseAligns = MeasureAlignment(vertcat(seqRef.Area),vertcat(seqOth.Area));
pulseAligns(any(isnan(pulseAligns),2),:) = [];
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

end

function seqPairs = MeasureAlignment(ser1, ser2)
    % seqPairs are the matched entries in ser1 and ser2. For every matched
    % pair the index of the entry in ser1 is given in column 1, and the
    % corresponding entry in ser2 is given in column 2.
    ser1 = zscore(ser1(:));
    ser2 = zscore(ser2(:));
    diffMat = abs(repmat(ser1,1,length(ser2))-repmat(ser2',length(ser1),1));
    diffMat = bwareaopen(imopen(diffMat<1,eye(30)),30);
%     rows = size(diffMat,1);
%     cols = size(diffMat,2);
%     if rows < cols
%         diffMat = [diffMat; zeros(cols-rows,cols)];
%     else
%         diffMat = [diffMat, zeros(rows, rows-cols)];
%     end
%     for i = [-size(diffMat,1):-500, 500:size(diffMat,1)]
%         diffMat = diffMat - diag(diag(diffMat, i),i);
%     end
%     diffMat=diffMat(1:rows,1:cols);

    seqPairs = [];
    ser1Pt = 1;
    ser2Pt = 1;
    waitH = waitbar(0,'Aligning pulse sequences');
    while ((ser1Pt <= (length(ser1))) && (ser2Pt <= length(ser2)))
        waitbar(ser1Pt/length(ser1),waitH);
        if ~diffMat(ser1Pt,ser2Pt)
            newStart = find(diffMat(ser1Pt,ser2Pt:end),1,'first');
            if ~isempty(newStart)
                seqPairs(end+1,2) = ser2Pt+newStart-1;
                seqPairs(end,1) = ser1Pt;
                ser2Pt = ser2Pt+newStart;
                ser1Pt = ser1Pt+1;
            else
                seqPairs(end+1,2) = nan;
                seqPairs(end,1) = ser1Pt;
                ser1Pt = ser1Pt+1;
            end
        else
            seqPairs(end+1,2) = ser2Pt;
            seqPairs(end,1) = ser1Pt;
            ser1Pt = ser1Pt+1;
            ser2Pt = ser2Pt+1;
        end
    end
    close(waitH);
end            
            