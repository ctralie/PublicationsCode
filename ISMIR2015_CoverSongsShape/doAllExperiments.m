%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step 0: Compile mex files for sequence alignment
%NOTE: Precompiled binaries for 64 bit windows and linux are provided
%so this step can be skipped if you are on these architectures and your
%compiler is not configured
cd('SequenceAlignment');
mex swalignimp.cpp;
cd('..');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step 1: Compute all chroma/mfcc features (this may take a while if this is
%the first time.  They also take up about 15 GB!  But precomputing saves
%a lot of time when varying parameters)
disp('Step 1: Computing MFCC/Chroma Features...');
cd('BeatSyncFeatures');
getAllTempoEmbeddings;
cd('..');
addpath('PatchMatch');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step 2: Initialize parameters for matching
disp('Step 2: Initializing parameters...');
list1 = 'coversongs/covers32k/list1.list';
list2 = 'coversongs/covers32k/list2.list';
files1 = textread(list1, '%s\n');
files2 = textread(list2, '%s\n');
N = length(files1);

%Patch match parameters
NIters = 5;
K = 3;
Alpha = 0.5;

%Self-Similarity parameters
dim = 200;
BeatsPerWin = 8;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step 3: Precompute self-similarity shape matrices for MFCC
disp('Step 3: Precomputing self-similarity matrices for original songs...');
beatIdx = 2;
addpath('SimilarityMatrices');
DsOrig = cell(1, N);
parfor ii = 1:N
    song = load(['BeatSyncFeatures', filesep, files1{ii}, '.mat']);
    fprintf(1, 'Getting self-similarity matrices for %s\n', files1{ii});
    tic;
    DsOrig{ii} = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx}, ...
        song.allSampleDelaysMFCC{beatIdx}, song.allbts{beatIdx}, dim, BeatsPerWin));
    toc;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step 4: Run all cross-similarity experiments between songs and covers
disp('Step 4: Running experiments...');
addpath('PatchMatch');
addpath('SequenceAlignment');
AllMs = cell(N, N);
Scores = zeros(N, N);

for ii = 1:N
    fprintf(1, 'Doing %i of %i\n', ii, N);
    tic
    song = load(['BeatSyncFeatures', filesep, files2{ii}, '.mat']);
    fprintf(1, 'Getting self-similarity matrices for %s\n', files2{ii});
    thisDs = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx}, ...
        song.allSampleDelaysMFCC{beatIdx}, song.allbts{beatIdx}, dim, BeatsPerWin));
    
    thisMs = cell(1, N);
    parfor jj = 1:N
        %Precompute L2 cross-similarity matrix
        CSM = bsxfun(@plus, dot(DsOrig{jj}, DsOrig{jj}, 2), dot(thisDs, thisDs, 2)') - 2*(DsOrig{jj}*thisDs');
        CSM = sqrt(CSM);
        %Do patch match
        M = patchMatch1DIMPMatlab( CSM, NIters, K, Alpha );
        thisMs{jj} = sparse(M);
        Scores(ii, jj) = sqrt(prod(size(M)))/swalignimp(double(full(M)));
        fprintf(1, '.');
    end
    AllMs(ii, :) = thisMs;
    save(sprintf('Results%i.mat', BeatsPerWin), 'AllMs', 'Scores');
    fprintf(1, '\n');
    toc
end

[~, idx] = min(Scores, [], 2);
sum(idx' == 1:80)
