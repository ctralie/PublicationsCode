%A wrapper around doSingleExperiment for SLURM
%Input Parameter: ExperimentIdx

%Patch match parameters
PMParams = {struct(), struct()};
%High Bias
PMParams{1}.NIters = 2;
PMParams{1}.K = 3;
PMParams{1}.Alpha = 0.2;
%Lower Bias
PMParams{2}.NIters = 5;
PMParams{2}.K = 3;
PMParams{2}.Alpha = 0.5;


%Self-Similarity parameters
dim = [100, 200, 300];
BeatsPerWin = [4, 8, 12];

beatIdx1 = 1:3;
beatIdx2 = 1:3;

[a, b, c, d, e] = ind2sub([2, 3, 3, 3, 3], ExperimentIdx);
NIters = PMParams{a}.NIters;
K = PMParams{a}.K;
Alpha = PMParams{a}.Alpha;
dim = dim(b);
BeatsPerWin = BeatsPerWin(c);
beatIdx1 = beatIdx1(d);
beatIdx2 = beatIdx2(e);

doSingleExperiment;