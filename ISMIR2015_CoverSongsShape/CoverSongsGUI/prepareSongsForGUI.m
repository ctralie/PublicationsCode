%Export data from to chosen songs to be loaded into the Python GUI
%This file both computes features and exports the data (as opposed to the
%covers80 version which uses precomputed features)
function [Ds1, Ds2, CSM] = prepareSongsForGUI( filenameout, songfilename1, songfilename2, tempobias1, tempobias2, dim, BeatsPerWin )
    addpath(genpath('../coversongs'));
    addpath(genpath('../BeatSyncFeatures'));
    addpath(genpath('../SequenceAlignment'));
    addpath(genpath('../PatchMatch'));
    addpath(genpath('../SimilarityMatrices'));

    %Compute beat-synchronous MFCC for both songs
    [X, Fs] = audioread(songfilename1);
    if size(X, 2) > 1
        X = mean(X, 2);
    end
    bts1 = beat(X, Fs, tempobias1, 6);
    tempoPeriod = mean(bts1(2:end) - bts1(1:end-1));
    [MFCCs1, SampleDelays1] = getMFCCTempoWindow(X, Fs, tempoPeriod, 200);
    fprintf(1, 'Computing self-similarity matrices for %s...\n', songfilename1);
    [Ds1, beatIdx1] = getBeatSyncDistanceMatrices(MFCCs1, SampleDelays1, bts1, dim, BeatsPerWin);
    
    %Compute beat-synchronous MFCC for both songs
    [X, Fs] = audioread(songfilename2);
    if size(X, 2) > 1
        X = mean(X, 2);
    end
    bts2 = beat(X, Fs, tempobias2, 6);
    tempoPeriod = mean(bts2(2:end) - bts2(1:end-1));
    [MFCCs2, SampleDelays2] = getMFCCTempoWindow(X, Fs, tempoPeriod, 200);
    fprintf(1, 'Computing self-similarity matrices for %s...\n', songfilename2);
    [Ds2, beatIdx2] = getBeatSyncDistanceMatrices(MFCCs2, SampleDelays2, bts2, dim, BeatsPerWin);
    
    %Precompute cross-similarity matrix because this step is slow and is
    %better optimized in Matlab than within Python where the GUI is    
    CSM = bsxfun(@plus, dot(Ds1, Ds1, 2), dot(Ds2, Ds2, 2)') - 2*(Ds1*Ds2');
    D = CSM; %Backwards compatibility
    save(filenameout, 'CSM', 'D', 'songfilename1', 'SampleDelays1', 'bts1', 'MFCCs1', ...
        'songfilename2', 'SampleDelays2', 'bts2', 'MFCCs2', 'dim', 'BeatsPerWin', 'Fs', ...
        'beatIdx1', 'beatIdx2');
end

