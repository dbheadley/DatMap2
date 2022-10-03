%% Files to process
% Note: ap0 will be used as the reference time for all other files.
ap0Path = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1_g0_imec0\21-06-05_AD25_RRITSingles1_g0_t0.imec0.ap.bin';
lf0Path = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1_g0_imec0\21-06-05_AD25_RRITSingles1_g0_t0.imec0.lf.bin';
ap1Path = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1_g0_imec1\21-06-05_AD25_RRITSingles1_g0_t0.imec1.ap.bin';
lf1Path = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1_g0_imec1\21-06-05_AD25_RRITSingles1_g0_t0.imec1.lf.bin';
ap2Path = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1_g0_imec2\21-06-05_AD25_RRITSingles1_g0_t0.imec2.ap.bin';
lf2Path = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1_g0_imec2\21-06-05_AD25_RRITSingles1_g0_t0.imec2.lf.bin';
ap3Path = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1_g0_imec3\21-06-05_AD25_RRITSingles1_g0_t0.imec3.ap.bin';
lf3Path = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1_g0_imec3\21-06-05_AD25_RRITSingles1_g0_t0.imec3.lf.bin';
vidPath = 'F:\21-06-05_AD25_RRITSingles1_g0\21-06-05_AD25_RRITSingles1.avi';

%% Format spikeglx output files to be compatible with datmap
NP2Datmap(ap0Path)
NP2Datmap(lf0Path)
NP2Datmap(ap1Path)
NP2Datmap(lf1Path)
NP2Datmap(ap2Path)
NP2Datmap(lf2Path)
NP2Datmap(ap3Path)
NP2Datmap(lf3Path)

%% Align spikeglx recording files
[tLF0, qmLF0] = datdattimealign(lf0Path,ap0Path,{'SY0'},{'SY0'});
[tAP1, qmAP1] = datdattimealign(ap1Path,ap0Path,{'SY0'},{'SY0'});
[tLF1, qmLF1] = datdattimealign(lf1Path,ap0Path,{'SY0'},{'SY0'});
[tAP2, qmAP2] = datdattimealign(ap2Path,ap0Path,{'SY0'},{'SY0'});
[tLF2, qmLF2] = datdattimealign(lf2Path,ap0Path,{'SY0'},{'SY0'});
[tAP3, qmAP3] = datdattimealign(ap3Path,ap0Path,{'SY0'},{'SY0'});
[tLF3, qmLF3] = datdattimealign(lf3Path,ap0Path,{'SY0'},{'SY0'});


%% Align video frames with recorded data
% Get video frame to find ROI
vid = VideoReader(vidPath);
currFrame = readFrame(vid);
image(currFrame);
roiVid = [34, 140, 16, 10, 1, inf];
[tVid, qmVid] = viddattimealign(vidPath,ap0Path,roiVid,{'SY0'});


%% You can check if the data are time aligned
% just load in the sync channels from your spikeglx recording files at an
% arbitary time point plot them on top of each other.

syAP0 = readdat(ap0Path, 'twindows', [1000 1010], 'selchans', {'SY0'});
syAP1 = readdat(ap1Path, 'twindows', [1000 1010], 'selchans', {'SY0'});
syAP2 = readdat(ap2Path, 'twindows', [1000 1010], 'selchans', {'SY0'});
syAP3 = readdat(ap2Path, 'twindows', [1000 1010], 'selchans', {'SY0'});
syLF0 = readdat(lf0Path, 'twindows', [1000 1010], 'selchans', {'SY0'});
syLF1 = readdat(lf1Path, 'twindows', [1000 1010], 'selchans', {'SY0'});
syLF2 = readdat(lf2Path, 'twindows', [1000 1010], 'selchans', {'SY0'});
syLF3 = readdat(lf2Path, 'twindows', [1000 1010], 'selchans', {'SY0'});

figure;
plot(syAP0.tPts{1},syAP0.traces{1}); hold on;
plot(syAP1.tPts{1},syAP1.traces{1});
plot(syAP2.tPts{1},syAP2.traces{1});
plot(syAP3.tPts{1},syAP3.traces{1});
plot(syLF0.tPts{1},syLF0.traces{1}, ':');
plot(syLF1.tPts{1},syLF1.traces{1}, ':');
plot(syLF2.tPts{1},syLF2.traces{1}, ':');
plot(syLF3.tPts{1},syLF3.traces{1}, ':');
legend({'AP0' 'AP1' 'AP2' 'AP3' 'LF0' 'LF1' 'LF2' 'LF3'});