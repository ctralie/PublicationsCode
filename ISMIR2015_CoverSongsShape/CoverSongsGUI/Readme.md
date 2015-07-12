This folder contains a Python library that is used to interactively view the cross-similarity between two songs and to bring up the self-similarity matrices that were used to create each pixel in the cross-similarity matrix.  

##Dependencies:
There are a number of Python libraries that need to be installed in order to run this GUI.  They are as follows:
* Numpy/Scipy/Matplotlib
* PyOpenGL (for interactively viewing PCA of blocks)
* wxPython (for the GUI Interface)
* PyGame (for playing back synchronized sound)

##Setting up and running an example
To view the cross-similarity and self-similarity matrices for a pair of songs in covers80, it is first necessary to run some code in Matlab to extract information and make it available to Python.  The code below show an example of how to do this.  
<b>NOTE:</b>This code assumes that all of the beat-synchronous MFCC features have been precomputed in the "BeatSyncFeatures" directory.

~~~~~ matlab
%Load in the lists of cover songs in covers80
list1 = '../coversongs/covers32k/list1.list';
list2 = '../coversongs/covers32k/list2.list';
files1 = textread(list1, '%s\n');
files2 = textread(list2, '%s\n');
songIdx = 16; %"Don't Let It Bring You Down"

%Create a .mat file called "DontLetIt.mat" that can be loaded into the GUI
%It's taking the 120bpm biased beat tracking for both (2), 200x200 pixels per 
%self-similarity image per beat block, and 12 beats per beat block
prepareSongForGUI('DontLetIt.mat', files1{songIdx}, files2{songIdx}, 2, 2, 200, 12);
~~~~~

This particular code examples saves a file called "DontLetIt.mat" which can then be opened up in the viewer <b>CrossSimilarityGUI.py</b>.  To view different songs, simply change the "songIdx" parameter in one or both of the files list in the Matlab code above.

##Interacting with the GUI
Open a .mat file generated with the code in the previous section in the File Menu.  Once a file is loaded, left click somewhere on the cross-similarity matrix to play the first song at the corresponding time, and right click somewhere to switch to the second song at the corresponding time.  Double click on a pixel to bring up the self-similarity matrices from both songs that were used to generate that pixel in the cross-similarity matrix.  A new window will pop up where you can view the self-similarity matrices, as well as music-synchronized PCA on the blocks that gave rise to those matrices.
