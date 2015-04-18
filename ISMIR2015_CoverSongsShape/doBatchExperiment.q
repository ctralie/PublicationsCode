#!/bin/bash
#
#SBATCH --output=BatchVerbose.out
#SBATCH --mem-per-cpu=16000

/opt/apps/MATLAB/R2012b/bin/matlab -nodisplay -r "ExperimentIdx=$SLURM_ARRAY_TASK_ID;doBatchExperiment;quit"

