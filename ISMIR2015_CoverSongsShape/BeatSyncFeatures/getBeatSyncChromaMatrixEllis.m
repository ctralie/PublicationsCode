%Drop in Ellis's covers80 code with whatever he did
function [ ChromaAvg ] = getBeatSyncChromaMatrixEllis( X, Fs, bts )
    addpath(genpath('../coversongs'));
    ChromaAvg = getChromaBeatFtrs(X, Fs, bts, 12)';
end

