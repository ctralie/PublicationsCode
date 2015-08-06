%Perform an experiment on covers80
%for a particular choice of beatIdx1 and beatIdx2 for the tempos in the
%first group and the tempos in the second group, as well as the parameters
%NIters, K, and Alpha for PatchMatch and dim, BeatsPerBlock
addpath('BeatSyncFeatures');
addpath('SequenceAlignment');
addpath('SimilarityMatrices');
addpath('PatchMatch');

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
fprintf(1, 'dim = %i, BeatsPerBlock = %i\n', dim, BeatsPerBlock);
if DOPATCHMATCH
    fprintf(1, 'PatchMatch K = %i, NIters = %i, Alpha = %g\n', K, NIters, Alpha);
else
    fprintf(1, 'Nearest Neighbor Kappa = %g\n', Kappa);
end
fprintf(1, 'beatIdx1 = %i, beatIdx2 = %i\n', beatIdx1, beatIdx2);
disp('======================================================');
fprintf(1, '\n\n\n');

%Scores for Smith Waterman with constraints
CScoresMFCC = zeros(N, N); %MFCC by itself

%Keep track of the sizes of all of the cross-similarity matrices for
%convenience
CrossSizes = cell(N, N);

%Split the precomputation of distance matrices into 4 groups to save memory
%(at the cost of some computation time since the cover distance matrices are
%recomputed 4 times)
for batch = 0:3
    fprintf(1, 'Precomputing self-similarity matrices for original songs batch %i of 4...\n', batch+1);
    DsOrig = cell(1, N/4);
    ChromasOrig = cell(1, N/4);
    for ii = 1:N/4
        tic;
        song = load(['BeatSyncFeatures', filesep, files1{ii+batch*N/4}, '.mat']);
        fprintf(1, 'Getting self-similarity matrices for %s\n', files1{ii+batch*N/4});
        DsOrig{ii} = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx1}, ...
            song.allSampleDelaysMFCC{beatIdx1}, song.allbts{beatIdx1}, dim, BeatsPerBlock));
        ChromasOrig{ii} = song.allBeatSyncChroma{beatIdx1};
        toc;
    end

    %Now loop through the cover songs
    for jj = 1:N
        fprintf(1, 'Comparing cover song %i of %i\n', jj, N);
        tic
        song = load(['BeatSyncFeatures', filesep, files2{jj}, '.mat']);
        fprintf(1, 'Getting self-similarity matrices for %s\n', files2{jj});
        thisDs = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx2}, ...
            song.allSampleDelaysMFCC{beatIdx2}, song.allbts{beatIdx2}, dim, BeatsPerBlock));
        ChromaY = song.allBeatSyncChroma{beatIdx2};

        thisMsMFCC = cell(N, 1);
        for ii = 1:N/4
            %Step 1: Compute MFCC Self-Similarity features
            %Precompute L2 cross-similarity matrix and find Kappa percent mutual nearest
            %neighbors
            CSM = bsxfun(@plus, dot(DsOrig{ii}, DsOrig{ii}, 2), dot(thisDs, thisDs, 2)') - 2*(DsOrig{ii}*thisDs');
            CrossSizes{ii+batch*N/4, jj} = size(CSM);
            if DOPATCHMATCH
                MMFCC = patchMatch1DIMPMatlab( CSM, NIters, K, Alpha );
            else
                MMFCC = groundTruthKNN( CSM, round(size(CSM, 2)*Kappa) );
                MMFCC = MMFCC.*groundTruthKNN( CSM', round(size(CSM', 2)*Kappa) )';
            end
            CScoresMFCC(ii+batch*N/4, jj) = swalignimpconstrained(double(full(MMFCC)));
            fprintf(1, '.');
        end
    end
end

save(outfilename, 'CrossSizes', 'CScoresMFCC');
