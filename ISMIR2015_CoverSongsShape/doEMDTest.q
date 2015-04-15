#!/bin/bash
#
#SBATCH --output=EMDVerbose.out
#SBATCH --mem-per-cpu=8000

/opt/apps/MATLAB/R2012b/bin/matlab -nodisplay -r "songIdx=$SLURM_ARRAY_TASK_ID;BeatsPerWin=8;dim=200;doEMDTest;quit"

