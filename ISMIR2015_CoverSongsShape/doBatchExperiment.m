%A wrapper around doSingleExperiment for SLURM
%Input Parameter: ExperimentIdx

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

doSingleExperiment;