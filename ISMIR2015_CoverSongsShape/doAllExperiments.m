%Compile mex files
cd('SequenceAlignment');
mex swalignimp.cpp;
mex swalignimpconstrained.cpp;
cd('..');

for ExperimentIdx = 1:length(dim)*length(BeatsPerBlock)*length(Kappa)*3*3
    doBatchExperiment;
end