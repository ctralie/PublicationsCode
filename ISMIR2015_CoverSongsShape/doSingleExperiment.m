%Perform an experiment on covers80
%for a particular choice of beatIdx1 and beatIdx2 for the tempos in the
%first group and the tempos in the second group, as well as the parameters
%NIters, K, and Alpha for PatchMatch and dim, BeatsPerWin
addpath('BeatSyncFeatures');
addpath('SequenceAlignment');
addpath('SimilarityMatrices');
addpath('PatchMatch');

DOPATCHMATCH = 0;
if Kappa == -1
    DOPATCHMATCH = 1;
end

%Make directory to hold the results if it doesn't exist
if DOPATCHMATCH
    dirName = sprintf('Results/%i_%i_%i_%i_%g', dim, BeatsPerWin, NIters, K, Alpha);
else
    dirName = sprintf('Results/%i_%i_%g', dim, BeatsPerWin, Kappa);
end
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
fprintf(1, 'dim = %i, BeatsPerWin = %i\n', dim, BeatsPerWin);
if DOPATCHMATCH
    fprintf(1, 'PatchMatch K = %i, NIters = %i, Alpha = %g\n', K, NIters, Alpha);
else
    fprintf(1, 'Nearest Neighbor Kappa = %g\n', Kappa);
end
fprintf(1, 'beatIdx1 = %i, beatIdx2 = %i\n', beatIdx1, beatIdx2);
disp('======================================================');
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

ScoresChroma = zeros(N, N); %Chroma by itself
ScoresMFCC = zeros(N, N); %MFCC by itself
Scores = zeros(N, N); %Combined
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
    for ii = 1:N
        %Step 1: Compute MFCC Self-Similarity features
        %Precompute L2 cross-similarity matrix and find Kappa percent mutual nearest
        %neighbors
        CSM = bsxfun(@plus, dot(DsOrig{ii}, DsOrig{ii}, 2), dot(thisDs, thisDs, 2)') - 2*(DsOrig{ii}*thisDs');
        DiagNorm = min(size(CSM))*sqrt(2); %Normalize by the diagonal of the smaller song
        if DOPATCHMATCH
            MMFCC = patchMatch1DIMPMatlab( CSM, NIters, K, Alpha );
        else
            MMFCC = groundTruthKNN( CSM, round(size(CSM, 2)*Kappa) );
            MMFCC = MMFCC.*groundTruthKNN( CSM', round(size(CSM', 2)*Kappa) )';
        end
        ScoresMFCC(ii, jj) = swalignimpconstrained(double(full(MMFCC))) / DiagNorm;
        
        %Step 2: Compute transposed chroma delay features
        ChromaX = ChromasOrig{ii};
        ChromaX = getBeatSyncChromaDelay(ChromaX, BeatsPerWin, 0);
        allScoresChroma = zeros(1, size(ChromaY, 2));
        allScoresCombined = zeros(1, size(ChromaY, 2));
        for oti = 0:size(ChromaY, 2) - 1 
            %Transpose chroma features
            thisY = getBeatSyncChromaDelay(ChromaY, BeatsPerWin, 0);
            %Compute the OTI of each delay window
            Comp = zeros(size(ChromaX, 1), size(thisY, 1), size(ChromaX, 2));
            for cc = 0:size(ChromaY, 2)-1
                thisY = getBeatSyncChromaDelay(ChromaY, BeatsPerWin, oti + cc);
                Comp(:, :, cc+1) = ChromaX*thisY'; %Cosine distance
            end
            [~, Comp] = max(Comp, [], 3);
            CSMChroma = (Comp == 1);%Only keep elements with no shift

            allScoresChroma(oti+1) = swalignimpconstrained(double(CSMChroma)) / DiagNorm;
            dims = [size(CSMChroma); size(MMFCC)];
            dims = min(dims, [], 1);
            M = double(CSMChroma(1:dims(1), 1:dims(2)) + MMFCC(1:dims(1), 1:dims(2)) );
            M = double(M > 0);
            M = full(M);
            allScoresCombined(oti+1) = swalignimpconstrained(M) / DiagNorm;
        end
        %Find best scores over transpositions
        [ChromaScore, idx] = max(allScoresChroma);
        ScoresChroma(ii, jj) = ChromaScore;
        MinTransp(ii, jj) = idx;
        [Score, idx] = max(allScoresCombined);
        Scores(ii, jj) = Score;
        MinTranspCombined(ii, jj) = idx;
        fprintf(1, '.');
    end
end

save(sprintf('%s/%i_%i.mat', dirName, beatIdx1, beatIdx2), ...
    'ScoresChroma', 'ScoresMFCC', 'Scores', 'MinTransp', 'MinTranspCombined');
