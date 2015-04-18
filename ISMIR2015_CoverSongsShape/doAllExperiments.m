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
disp('Computing MFCC/Chroma Features (may take a while if first time)...');
cd('BeatSyncFeatures');
getAllTempoEmbeddings;
cd('..');


%Patch match parameters
NIters = 3;
K = 3;
Alpha = 0.3;

%Self-Similarity parameters
dim = 200;
BeatsPerWin = 8;


beatIdx1 = 2;
beatIdx2 = 2;
doSingleExperiment;

% for beatIdx1 = 1:3
%     for beatIdx2 = 1:3
%         doSingleExperiment;
%     end
% end