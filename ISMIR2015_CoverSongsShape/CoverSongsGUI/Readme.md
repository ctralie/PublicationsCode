This folder contains a Python library that is used to interactively view the cross-similarity between two songs and to bring up the self-similarity matrices that were used to create each pixel in the cross-similarity matrix.  

##Dependencies:
There are a number of Python libraries that need to be installed in order to run this GUI.  They are as follows:
* Numpy/Scipy/Matplotlib
* PyOpenGL (for interactively viewing PCA of blocks)
* wxPython (for the GUI Interface)
* PyGame (for playing back synchronized sound)

##Setting examples from the covers80 dataset
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
prepareCovers80SongForGUI('DontLetIt.mat', files1{songIdx}, files2{songIdx}, 2, 2, 200, 12);
~~~~~

This particular code examples saves a file called "DontLetIt.mat" which can then be opened up in the viewer <b>CrossSimilarityGUI.py</b>.  To view different songs, simply change the "songIdx" parameter in one or both of the files list in the Matlab code above.

###Precomputed Examples
For those who want to avoid the lengthy process of computing all of the MFCC and Chroma features in the database, there are some example .mat files that can be loaded right into the GUI.  As long as you have downloaded the <a href = "http://labrosa.ee.columbia.edu/projects/coversongs/covers80/covers80.tgz">covers80.tgz</a> file containing the music and extracted it one directory up, you can view the following examples:

* DontLetIt.mat: "Don't Let It Bring You Down" performed by Neil Young and Annie Lennox.  This is an example shown in the paper because the instrumentals and vocals are strikingly different between the two versions but there are still strong diagonals
* MyGeneration.mat: "My Generation" performed by The Who and Green Day.  This one is interesting because of the repetitive nature of the verse and chorus, leading to diagonals that are packed closely to each other.  Also some regions that are just instrumental match up with regions that have instrumental + vocal.
* WeCanWorkItOut.mat: "We Can Work It Out" performed by The Beatles and Five Man Acoustical Jam.  This was the best match in the covers80 database.  The songs are indeed similar, but one is performed live and one is a studio version.
* NeverLetMeDown.mat: "Never Let Me Down Again" by Depeche Mode and The Smashing Pumpkins.  The diagonal lines here are fainter but it is still possible to pick up the matching

##Setting up your own examples
If you want to bypass the Covers80 dataset completely, you prepare your own songs for the GUI using the "prepareSongsForGUI.m" file.  For instance, take the following code:

~~~~~ matlab
prepareSongsForGUI('BlurredLines.mat', 'BlurredLines.mp3', 'GotToGiveItUp.mp3', 120, 120, 200, 12);
~~~~~

This code will extract info from Robin Thicke's "Blurred Lines" and Marvin Gaye's "Got To Give It Up," each at a 120 bmp beat bias for tempo tracking, with resized self-similarity images at 200x200 pixels, and with 12 beats per block, and it will save the features and cross-similarity matrix to a file called "BlurredLines.mat" which can then be opened in the CoverSongs GUI.

##Interacting with the GUI
Open a .mat file generated with the code in the previous section in the File Menu.  Once a file is loaded, left click somewhere on the cross-similarity matrix to play the first song at the corresponding time, and right click somewhere to switch to the second song at the corresponding time.  Double click on a pixel to bring up the self-similarity matrices from both songs that were used to generate that pixel in the cross-similarity matrix.  A new window will pop up where you can view the self-similarity matrices, as well as music-synchronized PCA on the blocks that gave rise to those matrices.  A zoomed in portion of the cross-similarity matrix around the chosen pixel is also shown in the self-similarity matrix GUI.  Use the arrow keys to move to nearby pixels
