%Perform an experiment on covers80
%for a particular choice of beatIdx1 and beatIdx2 for the tempos in the
%first group and the tempos in the second group, as well as the parameters
%NIters, K, and Alpha for PatchMatch and BeatsPerWin
addpath('BeatSyncFeatures');
addpath('PatchMatch');
addpath('SequenceAlignment');
addpath('SimilarityMatrices');

%Make directory to hold the results if it doesn't exist
dirName = sprintf('ResultsDim_%i_%i_%i_%g', BeatsPerWin, NIters, K, Alpha);
if ~exist(dirName);
    mkdir(dirName);
end

%Initialize parameters for matching
list1 = 'coversongs/covers32k/list1.list';
list2 = 'coversongs/covers32k/list2.list';
files1 = textread(list1, '%s\n');
files2 = textread(list2, '%s\n');
N = length(files1);


%Run all cross-similarity experiments between songs and covers
fprintf(1, '\n\n\n');
disp('======================================================');
fprintf(1, 'RUNNING EXPERIMENTS\n');
fprintf(1, 'Patch Match NIters = %i, K = %i, Alpha = %g\n', NIters, K, Alpha);
fprintf(1, 'BeatsPerWin = %i\n', BeatsPerWin);
fprintf(1, 'beatIdx1 = %i, beatIdx2 = %i\n', beatIdx1, beatIdx2);
disp('======================================================');
fprintf(1, '\n\n\n');

ChromasOrig = cell(1, N);
disp('Loading chroma for original songs...');
for ii = 1:N
    tic;
    A = load(['BeatSyncFeatures', filesep, files1{ii}, '.mat'], 'allBeatSyncChroma');
    ChromasOrig{ii} = A.allBeatSyncChroma{beatIdx1};
    toc;
end

AllMsMFCC = cell(N, N);%Store sparse cross-similarity matrices from patch match

ScoresChroma = inf*ones(N, N); %Chroma by itself
ScoresMFCC = inf*ones(N, N); %MFCC by itself
Scores = inf*ones(N, N); %Combined
MinTransp = zeros(N, N); %Transposition that led to the lowest score
MinTranspCombined = zeros(N, N);

%Now loop through the cover songs
for jj = 1:N
    fprintf(1, 'Comparing cover song %i of %i\n', jj, N);
    song = load(['BeatSyncFeatures', filesep, files2{jj}, '.mat'], 'allBeatSyncChroma', 'allMFCC', 'allSampleDelaysMFCC', 'allbts');
    fprintf(1, 'Getting self-similarity matrices for %s\n', files2{jj});
    ChromaY = song.allBeatSyncChroma{beatIdx2};
    MFCCsY = song.allMFCC{beatIdx2};
    SampleDelaysY = song.allSampleDelaysMFCC{beatIdx2};
    bts2 = song.allbts{beatIdx2};
    
    thisMsMFCC = cell(N, 1);
    for ii = 1:N
        song = load(['BeatSyncFeatures', filesep, files1{ii}, '.mat'], 'allBeatSyncChroma', 'allMFCC', 'allSampleDelaysMFCC', 'allbts');
        MFCCsX = song.allMFCC{beatIdx1};
        SampleDelaysX = song.allSampleDelaysMFCC{beatIdx1};
        bts1 = song.allbts{beatIdx1};
        %Step 1: Do patch match, computing self-similarity matrices on
        %demand
        fprintf(1, 'Comparing %i versus %i\n', jj, ii);
        disp('Doing PatchMatch...');
        tic;
        MMFCC = patchMatch1DMatlab( MFCCsX, SampleDelaysX, bts1, MFCCsY, SampleDelaysY, bts2, BeatsPerWin, NIters, K, Alpha );
        toc;
        disp('Finished PatchMatch...');
        thisMsMFCC{ii} = sparse(MMFCC);
        ScoresMFCC(ii, jj) = sqrt(prod(size(MMFCC)))/swalignimp(double(full(MMFCC)));
        
        %Step 2: Compute transposed chroma delay features
        ChromaX = ChromasOrig{ii};
        ChromaX = getBeatSyncChromaDelay(ChromaX, BeatsPerWin, 0);
        allScoresChroma = zeros(1, size(ChromaY, 2));
        allScoresCombined = zeros(1, size(ChromaY, 2));
        for oti = 0:size(ChromaY, 2) - 1
            thisY = getBeatSyncChromaDelay(ChromaY, BeatsPerWin, 0);
            %Full oti comparison matrix
            Comp = zeros(size(ChromaX, 1), size(thisY, 1), size(ChromaX, 2));
            %Do OTI on each element individually
            for cc = 0:size(ChromaY, 2)-1
                thisY = getBeatSyncChromaDelay(ChromaY, BeatsPerWin, oti + cc);
                Comp(:, :, cc+1) = ChromaX*thisY'; %Cosine distance
            end
            [~, Comp] = max(Comp, [], 3);
            CSMChroma = (Comp == 1);
            allScoresChroma(oti+1) = sqrt(prod(size(CSMChroma)))/swalignimp(double(CSMChroma));
            dims = [size(CSMChroma); size(MMFCC)];
            dims = min(dims, [], 1);
            M = double(CSMChroma(1:dims(1), 1:dims(2)) + MMFCC(1:dims(1), 1:dims(2)) );
            M = double(M > 0);
            allScoresCombined(oti+1) = sqrt(prod(size(M)))/swalignimp(M);
        end
        [ChromaScore, idx] = min(allScoresChroma);
        ScoresChroma(ii, jj) = ChromaScore;
        MinTransp(ii, jj) = idx;
        [Score, idx] = min(allScoresCombined);
        Scores(ii, jj) = Score;
        MinTranspCombined(ii, jj) = idx;
        fprintf(1, '.');
    end
    AllMsMFCC(:, jj) = thisMsMFCC;
end

save(sprintf('%s/%i_%i.mat', dirName, beatIdx1, beatIdx2), ...
    'AllMsMFCC', 'ScoresChroma', 'ScoresMFCC', 'Scores', 'MinTransp', 'MinTranspCombined');