%A wrapper around doSingleExperiment for SLURM
%Input Parameter: ExperimentIdx

%Compile mex files
cd('SequenceAlignment');
mex swalignimp.cpp;
mex swalignimpconstrained.cpp;
cd('..');

%Self-Similarity parameters
dim = [100, 200, 300];
BeatsPerWin = [8, 10, 12, 14];
Kappa = [0.05, 0.1, 0.15];

beatIdx1 = 1:3;
beatIdx2 = 1:3;

[a, b, c, d, e] = ind2sub([length(dim), length(BeatsPerWin), length(Kappa), 3, 3], ExperimentIdx);

dim = dim(a);
BeatsPerWin = BeatsPerWin(b);
Kappa = Kappa(c);
beatIdx1 = beatIdx1(d);
beatIdx2 = beatIdx2(e);

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

outfilename = sprintf('%s/%i_%i.mat', dirName, beatIdx1, beatIdx2);
if ~exist(outfilename)
    doSingleExperiment;
end
