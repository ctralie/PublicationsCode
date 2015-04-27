%See what the scores is between "Blurred Lines" and "Got To Give It Up"
%to showcase this work

addpath(genpath('../coversongs'));
addpath(genpath('../BeatSyncFeatures'));
addpath(genpath('../SequenceAlignment'));
addpath(genpath('../PatchMatch'));
addpath(genpath('../SimilarityMatrices'));
files = {'BlurredLines', 'GotToGiveItUp'};

tempos = [60, 120, 180];

for songIdx = 1:length(files)
    outname = sprintf('%s.mat', files{songIdx});
    if exist(outname)
        continue;
    end
    
    filename = sprintf('%s.mp3', files{songIdx});
    fprintf(1, 'Loading %s...\n', files{songIdx});
    [X, Fs] = audioread(filename);
    if size(X, 2) > 1
        X = mean(X, 2);
    end
    fprintf(1, 'Finished loading %s\n', files{songIdx});
    
    allbts = cell(length(tempos), 1);
    allMFCC = cell(length(tempos), 1);
    allSampleDelaysMFCC = cell(length(tempos), 1);
    
    for tempoidx = 1:length(tempos)
        tempo = tempos(tempoidx);
        fprintf(1, 'Getting features for %s %i BPM Seed...\n', files{songIdx}, tempo);
        bts = beat(X, Fs, tempo, 6);
        makeBlurredLinesBeatsAudio( files{songIdx}, sprintf('%sBts%i', files{songIdx}, tempo), bts );

        tempoPeriod = mean(bts(2:end) - bts(1:end-1));
        disp('Getting MFCC...');
        [MFCC, SampleDelaysMFCC] = getMFCCTempoWindow(X, Fs, tempoPeriod);
        
        allbts{tempoidx} = bts;
        allMFCC{tempoidx} = MFCC;
        allSampleDelaysMFCC{tempoidx} = SampleDelaysMFCC;
    end
    save(outname, 'tempos', 'allbts', 'allMFCC', 'allSampleDelaysMFCC');
end

dim = 200;
BeatsPerWin = 14;

Kappa = 0.1;
CSMs = cell(3, 3);
BLScores = zeros(3, 3);

for beatIdx1 = 1:3
    song1 = load([files{1}, '.mat']);
    fprintf(1, 'Getting self-similarity matrices for %s beatIdx1 = %i\n', files{1}, beatIdx1);
    D1 = single(getBeatSyncDistanceMatrices(song1.allMFCC{beatIdx1}, ...
        song1.allSampleDelaysMFCC{beatIdx1}, song1.allbts{beatIdx1}, dim, BeatsPerWin)); 
    
    for beatIdx2 = 1:3
        song2 = load([files{2}, '.mat']);
        fprintf(1, 'Getting self-similarity matrices for %s beatIdx2 = %i\n', files{2}, beatIdx2);
        D2 = single(getBeatSyncDistanceMatrices(song2.allMFCC{beatIdx2}, ...
            song2.allSampleDelaysMFCC{beatIdx2}, song2.allbts{beatIdx2}, dim, BeatsPerWin));

        CSM = bsxfun(@plus, dot(D1, D1, 2), dot(D2, D2, 2)') - 2*(D1*D2');
        MMFCC = groundTruthKNN( CSM, round(size(CSM, 2)*Kappa) );
        MMFCC = MMFCC.*groundTruthKNN( CSM', round(size(CSM', 2)*Kappa) )';

        [score, S] = swalignimpconstrained(double(full(MMFCC)));
        BLScores(beatIdx1, beatIdx2) = score;
        CSMs{beatIdx1, beatIdx2} = MMFCC;
    end
end

save('BlurredLinesScores.mat', 'CSMs', 'BLScores');

%Output the cross-similarity matrix for the GUI
songfilename1 = [files{1}, '.mp3'];
songfilename2 = [files{2}, '.mp3'];
SampleDelays1 = song1.allbts{beatIdx1};
SampleDelays2 = song2.allbts{beatIdx2};
D = double(full(MMFCC));
save('BlurredCross.mat', 'songfilename1', 'songfilename2', 'SampleDelays1', 'SampleDelays2', 'D', 'Fs');