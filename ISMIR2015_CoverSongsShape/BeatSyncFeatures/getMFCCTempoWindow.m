function [MFCC, SampleDelays] = getMFCCTempoWindow( X, Fs, tempoPeriod, windowsPerBeat )
    addpath('rastamat');
    
    %Get as close as possible to "windowsPerBeat" samples per window
    hopSize = round(Fs*tempoPeriod/windowsPerBeat);
    windowSize = hopSize*windowsPerBeat;
    
    %Do MFCC on chunks of 10 beats at a time to avoid memory issues but to
    %still get the advantage of overlapping windows
    ChunkLen = windowSize*10;
    NChunks = ceil(length(X)/ChunkLen);
    M = cell(NChunks, 1);
    parfor ii = 1:NChunks
        idx = (1:ChunkLen+windowSize-hopSize) + (ii-1)*ChunkLen;
        idx = idx(idx <= length(X));
        M{ii} = melfcc(X(idx), Fs, 'maxfreq', 8000, 'numcep', 20, 'nbands', 40, 'fbtype', ...
            'fcmel', 'dcttype', 1, 'usecmp', 1, 'wintime', windowSize/Fs, 'hoptime', hopSize/Fs, 'preemph', 0, 'dither', 1)';
    end
    
    MFCC = cell2mat(M);
    SampleDelays = 1:size(MFCC, 1);
    SampleDelays = (SampleDelays-1)*hopSize/Fs;
end