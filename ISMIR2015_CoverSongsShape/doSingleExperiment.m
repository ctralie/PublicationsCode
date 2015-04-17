%Perform an experiment on covers80
%for a particular choice of beatIdx1 and beatIdx2 for the tempos in the
%first group and the tempos in the second group, as well as the parameters
%NIters, K, and Alpha for PatchMatch and dim, BeatsPerWin
addpath('BeatSyncFeatures');
addpath('PatchMatch');
addpath('SequenceAlignment');
addpath('SimilarityMatrices');


%Initialize parameters for matching
list1 = 'coversongs/covers32k/list1.list';
list2 = 'coversongs/covers32k/list2.list';
files1 = textread(list1, '%s\n');
files2 = textread(list2, '%s\n');
N = length(files1);


%Run all cross-similarity experiments between songs and covers
fprintf(1, '\n\n\n');
disp('=====================================');
fprintf(1, 'Running experiments for beatIdx1 = %i, beatIdx2 = %i\n', beatIdx1, beatIdx2);
fprintf(1, 'Patch Match NIters = %i, K = %i, Alpha = %g\n', NIters, K, Alpha);
fprintf(1, 'dim = %i, BeatsPerWin = %i\n', dim, BeatsPerWin);
disp('=====================================');
fprintf(1, '\n\n\n');

DsOrig = cell(1, N);
ChromasOrig = cell(1, N);
disp('Precomputing self-similarity matrices for original songs...');
for ii = 1:N
    tic;
    song = load(['BeatSyncFeatures', filesep, files1{ii}, '.mat']);
    fprintf(1, 'Getting self-similarity matrices for %s\n', files1{ii});
    DsOrig{ii} = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx1}, ...
        song.allSampleDelaysMFCC{beatIdx1}, song.allbts{beatIdx1}, dim, BeatsPerWin));
    ChromasOrig{ii} = song.allBeatSyncChroma{beatIdx1};
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
    tic
    song = load(['BeatSyncFeatures', filesep, files2{jj}, '.mat']);
    fprintf(1, 'Getting self-similarity matrices for %s\n', files2{jj});
    thisDs = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx2}, ...
        song.allSampleDelaysMFCC{beatIdx2}, song.allbts{beatIdx2}, dim, BeatsPerWin));
    ChromaY = song.allBeatSyncChroma{beatIdx2};

    thisMsMFCC = cell(N, 1);
    parfor ii = 1:N
        %Step 1: Compute MFCC Self-Similarity features
        %Precompute L2 cross-similarity matrix
        CSM = bsxfun(@plus, dot(DsOrig{ii}, DsOrig{ii}, 2), dot(thisDs, thisDs, 2)') - 2*(DsOrig{ii}*thisDs');
        CSM = sqrt(CSM);
        %Do patch match
        MMFCC = patchMatch1DIMPMatlab( CSM, NIters, K, Alpha );
        thisMsMFCC{ii} = sparse(MMFCC);
        ScoresMFCC(ii, jj) = sqrt(prod(size(MMFCC)))/swalignimp(double(full(MMFCC)));
        
        %Step 2: Compute transposed chroma delay features
        ChromaX = ChromasOrig{ii};
        ChromaX = getBeatSyncChromaDelay(ChromaX, BeatsPerWin, 0);
        allScoresChroma = zeros(1, size(ChromaY, 2));
        allScoresCombined = zeros(1, size(ChromaY, 2));
        for oti = 0:size(ChromaY, 2) - 1
            %Full oti comparison matrix
            Comp = zeros(size(ChromaX, 1), size(ChromaY, 1), size(ChromaY, 2));
            %Do OTI on each element individually
            for cc = 0:size(ChromaY, 2)-1
                thisY = getBeatSyncChromaDelay(ChromaY, BeatsPerWin, oti + cc);
                Comp(:, :, cc+1) = ChromaX*ChromaY'; %Cosine distance
            end
            [~, Comp] = max(Comp, [], 3);
            CSMChroma = (Comp == 1);
            allScoresChroma(oti+1) = sqrt(prod(size(CSMChroma)))/swalignimp(double(CSMChroma));
            M = double(CSMChroma) + MMFCC;
            M = double(M > 0);
            allScoresCombined(oti+1) = sqrt(prod(size(M)))/swalignimp(M);
        end
        [ChromaScore, idx] = min(allChromaScores);
        ScoresChroma(ii, jj) = ChromaScore;
        MinTransp(ii, jj) = idx;
        [Score, idx] = min(allScoresCombined);
        Scores(ii, jj) = Score;
        MinTranspCombined(ii, jj) = idx;
        fprintf(1, '.');
    end
    AllMsMFCC(:, jj) = thisMsMFCC;
end

save(sprintf('Results%i_%i_%i.mat', BeatsPerWin, beatIdx1, beatIdx2), ...
    'AllMsMFCC', 'ScoresChroma', 'ScoresMFCC', 'Scores', 'MinTransp', 'MinTranspCombined');