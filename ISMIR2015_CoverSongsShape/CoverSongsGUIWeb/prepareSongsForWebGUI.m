%Export data from to chosen songs to be loaded into the Python GUI
%This file both computes features and exports the data (as opposed to the
%covers80 version which uses precomputed features)
function [Ds1, Ds2, CSM, MFCCs1, SampleDelays1, MFCCs2, SampleDelays2, beatIdx1, beatIdx2] = prepareSongsForWebGUI( foldername, songfilename1, songfilename2, tempobias1, tempobias2, dim, BeatsPerBlock )
    addpath(genpath('../coversongs'));
    addpath(genpath('../BeatSyncFeatures'));
    addpath(genpath('../SequenceAlignment'));
    addpath(genpath('../PatchMatch'));
    addpath(genpath('../SimilarityMatrices'));
    %% Compute features
    %Compute beat-synchronous MFCC for both songs
    [XAudio1, Fs1] = audioread(songfilename1);
    if size(XAudio1, 2) > 1
        XAudio1 = mean(XAudio1, 2);
    end
    bts1 = beat(XAudio1, Fs1, tempobias1, 6);
    tempoPeriod = mean(bts1(2:end) - bts1(1:end-1));
    [MFCCs1, SampleDelays1] = getMFCCTempoWindow(XAudio1, Fs1, tempoPeriod, 200);
    fprintf(1, 'Computing self-similarity matrices for %s...\n', songfilename1);
    [Ds1, beatIdx1] = getBeatSyncDistanceMatrices(MFCCs1, SampleDelays1, bts1, dim, BeatsPerBlock);
    
    %Compute beat-synchronous MFCC for both songs
    [XAudio2, Fs2] = audioread(songfilename2);
    if size(XAudio2, 2) > 1
        XAudio2 = mean(XAudio2, 2);
    end
    bts2 = beat(XAudio2, Fs2, tempobias2, 6);
    tempoPeriod = mean(bts2(2:end) - bts2(1:end-1));
    [MFCCs2, SampleDelays2] = getMFCCTempoWindow(XAudio2, Fs2, tempoPeriod, 200);
    fprintf(1, 'Computing self-similarity matrices for %s...\n', songfilename2);
    [Ds2, beatIdx2] = getBeatSyncDistanceMatrices(MFCCs2, SampleDelays2, bts2, dim, BeatsPerBlock);
    
    %Precompute cross-similarity matrix because this step is slow and is
    %better optimized in Matlab than within Python where the GUI is    
    CSM = bsxfun(@plus, dot(Ds1, Ds1, 2), dot(Ds2, Ds2, 2)') - 2*(Ds1*Ds2');    
    
    %% Output all information to a folder which can be loaded into Javascript
    mkdir(foldername);
    %Step 1: Export cross-similarity matrix to an image file
    L = 256;
    Colors = round(interp1(linspace(min(CSM(:)),max(CSM(:)),L),1:L,CSM));
    C = colormap(sprintf('jet(%i)', L));
    CSM = reshape(C(Colors(:), :), [size(CSM, 1), size(CSM, 2), 3]);
    imwrite(CSM, sprintf('%s/CSM.png', foldername));
    
    %Step 2: Write audio files
    audiowrite(sprintf('%s/song1.ogg', foldername), XAudio1, Fs1);
    audiowrite(sprintf('%s/song2.ogg', foldername), XAudio2, Fs2);
    
    %Step 3: Write out Feature, SampleDelay, and beats information
    %for both songs
    beatIdx1 = beatIdx1 - 1; %Javascript is zero-indexed
    beatIdx2 = beatIdx2 - 1;
    
    %General information
    fout = fopen(sprintf('%s/info.txt', foldername), 'w');
    fprintf(fout, '%i,%i,', dim, BeatsPerBlock);
    fprintf(fout, '%s,%s,', songfilename1, songfilename2);
    fprintf(fout, '%i,%i,', tempobias1, tempobias2);
    
    %Song 1
    %Write out beats information
    fprintf(fout, '%i,', length(beatIdx1));
    for ii = 1:length(beatIdx1)
        fprintf(fout, '%i,%g,', beatIdx1(ii), bts1(ii));
    end
    %Write out feature and sample delays information
    fprintf(fout, '%i,%i,', size(MFCCs1, 1), size(MFCCs1, 2));
    for ii = 1:size(MFCCs1, 1)
        fprintf(fout, '%g,', SampleDelays1(ii));
        for kk = 1:size(MFCCs1, 2)
            fprintf(fout, '%g,', MFCCs1(ii, kk));
        end
    end
    
    %Song 2
    %Write out beats information
    fprintf(fout, '%i,', length(beatIdx2));
    for ii = 1:length(beatIdx2)
        fprintf(fout, '%i,%g,', beatIdx2(ii), bts2(ii));
    end
    %Write out feature and sample delays information
    fprintf(fout, '%i,%i,', size(MFCCs2, 1), size(MFCCs2, 2));
    for ii = 1:size(MFCCs2, 1)
        fprintf(fout, '%g,', SampleDelays2(ii));
        for kk = 1:size(MFCCs2, 2)
            fprintf(fout, '%g,', MFCCs2(ii, kk));
        end
    end
    
    %disp('Zipping everything up...');
    %zip([foldername, '.zip'], {'CSM.png', 'info.txt', 'song1.ogg', 'song1.txt', 'song2.ogg', 'song2.txt'}, foldername);
end

