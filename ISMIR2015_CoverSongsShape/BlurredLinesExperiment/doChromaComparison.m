%See what the scores is between "Blurred Lines" and "Got To Give It Up"
%to showcase this work

addpath(genpath('../coversongs'));
addpath(genpath('../BeatSyncFeatures'));
addpath(genpath('../SequenceAlignment'));
addpath(genpath('../PatchMatch'));
addpath(genpath('../SimilarityMatrices'));
files = {'BlurredLines', 'GotToGiveItUp'};

tempo = 180;
Chromas = cell(1, length(files));
BeatsPerBlock = 14;
Kappa = 0.1;

for songIdx = 1:length(files)
    filename = sprintf('%s.mp3', files{songIdx});
    fprintf(1, 'Loading %s...\n', files{songIdx});
    [X, Fs] = audioread(filename);
    if size(X, 2) > 1
        X = mean(X, 2);
    end
    fprintf(1, 'Finished loading %s\n', files{songIdx});
    
    fprintf(1, 'Getting features for %s %i BPM Seed...\n', files{songIdx}, tempo);
    bts = beat(X, Fs, tempo, 6);
    BeatSyncChroma = getBeatSyncChromaMatrixEllis(X, Fs, bts);
    
    Chromas{songIdx} = BeatSyncChroma;
end


Chroma1 = getBeatSyncChromaDelay(Chromas{1}, BeatsPerBlock, 0);
BCSMs = cell(1, 12);
allScores = zeros(1, 12);

for transpose = 0:11
    Chroma2 = getBeatSyncChromaDelay(Chromas{2}, BeatsPerBlock, transpose);
    CSM = bsxfun(@plus, dot(Chroma1, Chroma1, 2), dot(Chroma2, Chroma2, 2)') - 2*(Chroma1*Chroma2');
    MChroma = groundTruthKNN( CSM, round(size(CSM, 2)*Kappa) );
    MChroma = MChroma.*groundTruthKNN( CSM', round(size(CSM', 2)*Kappa) )';
    BCSMs{transpose+1} = MChroma;
    allScores(transpose+1) = swalignimpconstrained(double(full(MChroma)));
end

[score, idx] = max(allScores);
MChroma = BCSMs{idx};

save('BlurredLinesChroma.mat', 'MChroma', 'score', 'allScores', 'BCSMs', 'Chromas');