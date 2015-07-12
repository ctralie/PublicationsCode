#Overview
This repository contains all of the code used to generate the results presented in the paper

<table border = "1"><tr><td>
Christopher J Tralie and Paul Bendich. Cover song identification with timbral shape. In <i>16th International
Society for Music Information Retrieval (ISMIR) Conference,</i> 2015.
</td></tr></table>

Most of the code is written in Matlab to take advantage of fast matrix multiplication routines and existing libraries for music feature extraction, but a few files (sequence alignment) are written in C++, and the GUI is written in Python.

#Getting Started and Running Experiments
Below is a list of instructions to replicate the results reported in the paper


1. Download the <a href = "http://labrosa.ee.columbia.edu/projects/coversongs/covers80/">"covers 80"</a> benchmark dataset (<a href = "http://labrosa.ee.columbia.edu/projects/coversongs/covers80/covers80.tgz">covers80.tgz</a>) and extract to the root of this directory.  When this is done, you should have a folder "coversongs" at the root of this directory which contains two folders: "covers32k" and "src"
2. Download the <a href = "http://labrosa.ee.columbia.edu/matlab/rastamat/rastamat.tgz">rastamat</a> library for computing MFCC features and extract to the <b>BeatSyncFeatures</b> directory
2. Run the Matlab file "getAllTempoEmbedding.m" in <b>BeatSyncFeatures/</b> to precompute all MFCC and Chroma features.  This may take a while the first time
3. Choose a set of parameters and loop through all combinations of these parameters in a series of batch tests.  Each parameter is described more in the paper.  Run the following Matlab code at the root of this directory to perform experiments on the covers80 dataset

~~~~~ matlab
%Parameters to try
dim = 200; %Resized dimension of self-similarity matrices
BeatsPerBlock = 12; %Number of beats per block
Kappa = 0.1; %Fraction of mutual nearest neighbors to take when converting a cross-similarity matrix to a binary cross-similarity matrix
beatIdx1 = 1:3;%Tempo levels to try for the first song (1: 60bpm bias, 2: 120bmp bias, 3:180bmp bias)
beatIdx2 = 1:3;%Tempo levels to try for the second song

doAllExperiments;
~~~~~

To loop through additional parameters, you simply make the corresponding parameter variables into lists.  For instance, to try out a self-similarity dimension of 100, 200, and 300 along with the other parameter choices, change dim to
~~~~~ matlab
dim = [100, 200, 300];
~~~~~

The script will try all combinations of parameters that are specified.  
<b>NOTE:</b> If you have access to a cluster computer with the SLURM system, you can parallelize the different parameter choices by modifying and running the script "doBatchExperiments.q"



#Code Folders Information:
Below is a description of the code in each directory in this repository

* BeatSyncFeatures: Code used to precompute beat-synchronous MFCC and Chroma embeddings for all of the songs in the covers80 database given

* BlurredLinesExperiment: Some code for running the experiment that compares Robin Thicke's "Blurred Lines" to Marvin Gaye's "Got To Give It Up"

* CoverSongsGUI: Code for interactively viewing cross-similarity matrices

* EMD: Code for doing L1 Earth mover's distance between self-similarity matrices (results not reported in paper)

* PatchMatch: Code for computing cross-similarity matrices and for performing Patch Match (Patch Match results not reported in paper)

* Results: Code for processing the results of a batch tests

* SequenceAlignment: C++ implementations of Smith Waterman and constrained Smith Waterman, which have MEX interfaces so they can be called from Matlab

* SimilarityMatrices: Code for computing self-similarity matrices for the blocks 

