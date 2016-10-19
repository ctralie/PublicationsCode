%Export data from the covers80 dataset to be loaded into the Python GUI
function [Ds1, Ds2, CSM] = prepareCovers80SongForGUI( filenameout, filePrefix1, filePrefix2, beatIdx1, beatIdx2, dim, BeatsPerWin )
    addpath('../BeatSyncFeatures');
    addpath('../SimilarityMatrices');
    songfilename1 = sprintf('../coversongs/covers32k/%s.mp3', filePrefix1);
    songfilename2 = sprintf('../coversongs/covers32k/%s.mp3', filePrefix2);
    song1 = load(sprintf('../BeatSyncFeatures/%s.mat', filePrefix1));
    song2 = load(sprintf('../BeatSyncFeatures/%s.mat', filePrefix2));
    Fs = 16000; %This is the sampling rate of all songs in the dataset
    
    %Precompute cross-similarity matrix because this step is slow and is
    %better optimized in Matlab than within Python where the GUI is
    SampleDelays1 = song1.SampleDelaysMFCC;
    bts1 = song1.allbts{beatIdx1};
    MFCCs1 = song1.MFCC;
    fprintf(1, 'Computing self-similarity matrices for %s...\n', filePrefix1);
    [Ds1, beatIdx1] = getBeatSyncDistanceMatrices(MFCCs1, SampleDelays1, bts1, dim, BeatsPerWin);
    
    SampleDelays2 = song2.SampleDelaysMFCC;
    bts2 = song2.allbts{beatIdx2};
    MFCCs2 = song2.MFCC;
    fprintf(1, 'Computing self-similarity matrices for %s...\n', filePrefix2);
    [Ds2, beatIdx2] = getBeatSyncDistanceMatrices(MFCCs2, SampleDelays2, bts2, dim, BeatsPerWin);
    
    CSM = bsxfun(@plus, dot(Ds1, Ds1, 2), dot(Ds2, Ds2, 2)') - 2*(Ds1*Ds2');
    D = CSM; %Backwards compatibility
    save(filenameout, 'CSM', 'D', 'songfilename1', 'SampleDelays1', 'bts1', 'MFCCs1', ...
        'songfilename2', 'SampleDelays2', 'bts2', 'MFCCs2', 'dim', 'BeatsPerWin', 'Fs', ...
        'beatIdx1', 'beatIdx2');
end

