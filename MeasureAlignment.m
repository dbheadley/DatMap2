function seqPairs = MeasureAlignment(ser1, ser2, matchLen)
    % seqPairs are the matched entries in ser1 and ser2. For every matched
    % pair the index of the entry in ser1 is given in column 1, and the
    % corresponding entry in ser2 is given in column 2.
    % matchLen should be an even number
    
    if rem(matchLen,2) == 1
        error('Match Length must be an even number');
    end
    
    serLen1 = length(ser1)+matchLen;
    serLen2 = length(ser2)+matchLen;
    
    % pad with infs to handle edge effects
    ser1 = [inf(matchLen,1); zscore(ser1(:)); inf(matchLen,1)];
    ser2 = [inf(matchLen,1); zscore(ser2(:)); inf(matchLen,1)];

    serPt1 = matchLen+1;
    serPt2 = matchLen+1;
    
    seqPairs = [];
    waitH = waitbar(0,'Aligning pulse sequences');
    % matching loop
    while (serPt1 <= serLen1)
        waitbar(serPt1/serLen1,waitH);
        
        serOff2 = 0;
        while ((serPt2+serOff2) <= serLen2)
            
            seqDiff = bwareaopen(abs(ser1(serPt1+[-matchLen:matchLen])...
                                     -ser2((serPt2+serOff2)+[-matchLen:matchLen]))<1,matchLen);
            if seqDiff(matchLen+1)
                serPt2 = serPt2 + serOff2;
                seqPairs(end+1,:) = [serPt1 serPt2];
                serPt2 = serPt2 + 1;
                break;
            else
                serOff2 = serOff2 + 1;
            end
        end
        serPt1 = serPt1 + 1;
    end
    
    close(waitH);      
    seqPairs = seqPairs-matchLen;
end            
            