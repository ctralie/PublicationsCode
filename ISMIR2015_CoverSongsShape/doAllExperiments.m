%Compile mex files
cd('SequenceAlignment');
mex swalignimp.cpp;
mex swalignimpconstrained.cpp;
cd('..');

for ExperimentIdx = 1:length(dims)*length(BeatsPerBlocks)*length(Kappas)*length(beatIdxs1)*length(beatIdxs2)
    doBatchExperiment;
end