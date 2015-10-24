%filename: Name of sound file
%tempoWindow: The time in seconds of each window
%SamplesPerWindow: The number of sliding windows taken over each tempoWindow interval
%outprefix: The prefix of the output files
%range: The range in seconds of what should be played
function [X, SampleDelays] = prepareSongForLoopDitty(filename, tempoWindow, SamplesPerWindow, outprefix, range )
    addpath(genpath('../BeatSyncFeatures'));
    readSuccess = 0;
    while readSuccess == 0
        try
            [XAudio, Fs] = audioread(filename);
            readSuccess = 1;
            if size(XAudio, 2) > 1
                XAudio = mean(XAudio, 2);
            end
        catch
            readSuccess = 0;
        end
    end
    
    if nargin > 4
        i1 = round(range(1)*Fs);
        i2 = round(range(2)*Fs);
        i1 = max(1, i1); i1 = min(length(XAudio), i1);
        i2 = max(1, i2); i2 = min(length(XAudio), i2);
        XAudio = XAudio(i1:i2);
    end
    
    [X, SampleDelays] = getMFCCTempoWindow(XAudio, Fs, tempoWindow, SamplesPerWindow);
    X = bsxfun(@minus, mean(X), X);
    X = bsxfun(@times, 1./sqrt(sum(X.^2, 2)), X);
    N = size(X, 1);
    [~, Y, latent] = pca(X);
    
    audiowrite(sprintf('%s.ogg', outprefix), XAudio, Fs);
    fout = fopen(sprintf('%s.txt', outprefix), 'w');
    for ii = 1:N
       fprintf(fout, '%g,%g,%g,%g,', Y(ii, 1), Y(ii, 2), Y(ii, 3), SampleDelays(ii)); 
    end
    fprintf(fout, '%g', sum(latent(1:3))/sum(latent));%Variance explained
    fclose(fout);
end
