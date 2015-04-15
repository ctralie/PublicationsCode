#!/bin/bash
#
#SBATCH --output=chromaVerbose.out
#SBATCH --mem-per-cpu=4000

/opt/apps/MATLAB/R2012b/bin/matlab -nodisplay -r "PMType=$SLURM_ARRAY_TASK_ID;doChromaTest;quit"

