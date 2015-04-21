%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step 0: Compile mex files for sequence alignment
%NOTE: Precompiled binaries for 64 bit windows and linux are provided
%so this step can be skipped if you are on these architectures and your
%compiler is not configured
cd('SequenceAlignment');
mex swalignimp.cpp;
mex swalignimpconstrained.cpp;
cd('..');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step 1: Compute all chroma/mfcc features (this may take a while if this is
%the first time.  They also take up about 15 GB!  But precomputing saves
%a lot of time when varying parameters)
disp('Computing MFCC/Chroma Features (may take a while if first time)...');
cd('BeatSyncFeatures');
getAllTempoEmbeddings;
cd('..');

%Self-Similarity parameters
BeatsPerWin = 12;
dim = 200;

Kappa = 0.1;
%Kappa = -1; %Do patch match
%NIters = 5;
%Alpha = 0.05;
%K = 7;

beatIdx1 = 2;
beatIdx2 = 2;
doSingleExperiment;
