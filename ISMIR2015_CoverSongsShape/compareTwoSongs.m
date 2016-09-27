%Purpose: To compute the cross-similarity matrix and Smith Waterman score
%for a pair of songs
%Inputs:
%filename1 (path to first file), filename2 (path to second file)
%dim: Dimension of self-similarity images
%BeatsPerBlock: The number of beats per block
%Kappa: The mutual nearest neighbor threshold 
function [MaxScore, MaxCSM] = compareTwoSongs( filename1, filename2, dim, BeatsPerBlock, Kappa )
    addpath(genpath('BeatSyncFeatures'));
    addpath('SequenceAlignment');
    addpath('SimilarityMatrices');
    addpath('PatchMatch');
    addpath(genpath('coversongs'));
    
    tempos = [60, 120, 180];
    windowsPerBeat = 10;
    
    %Step 1: Load all MFCC features
    [X1, Fs1] = audioread(filename1);
    if size(X1, 2) > 1
        X1 = mean(X1, 2);
    end
    [X2, Fs2] = audioread(filename2);
    if size(X2, 2) > 1
        X2 = mean(X2, 2);
    end
    
    %Step 2: Estimate beat onsets with different biases
    AllBts1 = {};
    AllBts2 = {};
    for ii = 1:length(tempos)
        AllBts1{end+1} = beat(X1, Fs1, tempos(ii), 6);
        AllBts2{end+1} = beat(X2, Fs2, tempos(ii), 6);
    end
    
    %Step 3: Compute CSMs at all combinations of tempo bias levels
    MaxScore = 0;
    MaxCSM = 0;
    for ii = 1:length(AllBts1)
        %Get MFCCs and self-similarity matrices for first song
        bts1 = AllBts1{ii};
        tempoPeriod1 = mean(bts1(2:end)-bts1(1:end-1));
        [MFCCs1, SampleDelays1] = getMFCCTempoWindow(X1, Fs1, tempoPeriod1, windowsPerBeat);
        [Ds1, ~] = getBeatSyncDistanceMatrices(MFCCs1, SampleDelays1, AllBts1{ii}, dim, BeatsPerBlock);
        for jj = 1:length(AllBts2)
            fprintf(1, 'Doing tempo bias %ibmp for song 1 and %ibmp for song 2...\n', tempos(ii), tempos(jj));
            %Get MFCCs and self-similarity matrices for second song
            bts2 = AllBts2{jj};
            tempoPeriod2 = mean(bts2(2:end)-bts2(1:end-1));
            [MFCCs2, SampleDelays2] = getMFCCTempoWindow(X2, Fs2, tempoPeriod2, windowsPerBeat);
            [Ds2, ~] = getBeatSyncDistanceMatrices(MFCCs2, SampleDelays2, AllBts2{jj}, dim, BeatsPerBlock);
            %Compute cross-similarity matrix
            CSM = bsxfun(@plus, dot(Ds1, Ds1, 2), dot(Ds2, Ds2, 2)') - 2*(Ds1*Ds2');
            %Make CSM binary
            MMFCC = groundTruthKNN( CSM, round(size(CSM, 2)*Kappa) );
            MMFCC = MMFCC.*groundTruthKNN( CSM', round(size(CSM', 2)*Kappa) )';
            %Do Smith Waterman
            score = swalignimpconstrained(double(full(MMFCC)));
            if score > MaxScore
                MaxScore = score;
                MaxCSM = CSM;
            end
        end
    end
end

