addpath('../BeatSyncFeatures');
addpath('../SequenceAlignment');
addpath('../SimilarityMatrices');
addpath('../PatchMatch');

%Initialize parameters for matching
list1 = '../coversongs/covers32k/list1.list';
list2 = '../coversongs/covers32k/list2.list';
files2 = textread(list2, '%s\n');
for ii = 1:length(files2)
    files2{ii} = ['../BeatSyncFeatures', filesep, files2{ii}, '.mat'];
end
files2{end+1} = 'GotToGiveItUp.mat';
N = length(files2);

beatIdx1 = 3;
beatIdx2 = 3;
dim = 200;
BeatsPerWin = 14;
Kappa = 0.1;

Scores = zeros(1, N);
CScores = zeros(1, N);

fprintf(1, 'Precomputing self-similarity matrices for original songs ..\n');
DsOrig = cell(1, N);
for ii = 1:N
    tic;
    song = load(files2{ii});
    fprintf(1, 'Getting self-similarity matrices for %s\n', files2{ii});
    DsOrig{ii} = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx1}, ...
        song.allSampleDelaysMFCC{beatIdx1}, song.allbts{beatIdx1}, dim, BeatsPerWin));
    toc;
end

%Now test out Blurred Lines


song = load('BlurredLines.mat');
thisDs = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx2}, ...
    song.allSampleDelaysMFCC{beatIdx2}, song.allbts{beatIdx2}, dim, BeatsPerWin));

for ii = 1:N
    %Step 1: Compute MFCC Self-Similarity features
    %Precompute L2 cross-similarity matrix and find Kappa percent mutual nearest
    %neighbors
    CSM = bsxfun(@plus, dot(DsOrig{ii}, DsOrig{ii}, 2), dot(thisDs, thisDs, 2)') - 2*(DsOrig{ii}*thisDs');
    MMFCC = groundTruthKNN( CSM, round(size(CSM, 2)*Kappa) );
    MMFCC = MMFCC.*groundTruthKNN( CSM', round(size(CSM', 2)*Kappa) )';
    Scores(ii) = swalignimp(double(full(MMFCC)));
    CScores(ii) = swalignimpconstrained(double(full(MMFCC)));
    fprintf(1, '.');
end

save('BlurredLinesCovers80Scores.mat', 'Scores', 'CScores');