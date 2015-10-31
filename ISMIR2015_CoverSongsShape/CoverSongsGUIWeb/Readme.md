This folder contains code to export features from Matlab to Javascript to be viewed in the browser, which is an even more straightforward process than the Python GUI for quickly visualizing data.  No special libraries are required to run this code; simply a reasonably recent version of Firefox, Chrome, Safari, etc.  

There are two GUIs that are provided.  The first is the "Loop Ditty" visualization, which is a music-synchronized visulization of PCA on the MFCC sliding window features, which can be used to visually inspect the geometric patterns that are associated with the sound.  The second is the "cross-similarity GUI," which is a subset of the Python GUI that allows the user to switch between two songs in a cross-similarity matrix (described more in the paper).  Switching across a diagonal region in the matrix allows one to quickly switch between matching regions in the two songs and to quickly hear how they correspond and how they are different

##External library requirements
The LoopDitty code should work as long as the rastmat library for MFCC computation is downloaded and extracted to the <b>../BeatSyncFeatures</b> directory at the root folder of this project.  <a href = "http://labrosa.ee.columbia.edu/matlab/rastamat/rastamat.tgz">Click here</a> to download that library.  NOTE: With some minor changes to the Matlab code, you can substitute your own features.  I simply used MFCC in this project as an example.

For the beat-synchronous cross-similarity, I am using some beat tracking code that is in the covers80 dataset, so you will need to download and extract the file<a href = "http://labrosa.ee.columbia.edu/projects/coversongs/covers80/covers80.tgz">covers80.tgz</a> one directory up in order for this code to work out of the box.


##LoopDittyCustom.html
This is a more custom subset of the web site http://www.loopditty.net in which one can view music synchronized with features representing the sliding window embeddings.  First, run a script in Matlab to generate and export features to a text file.  The syntax is

~~~~~ matlab
prepareSongForLoopDitty(filename, tempoWindow, SamplesPerWindow, outprefix, range);
~~~~~

The meaning of the parameters is as follows:
* filename: The filename of the audio file to be processed
* tempoWindow: The length of the MFCC window to be used in the sliding window representation
* SamplesPerWindow: How many MFCC windows to slide through each "tempoWindow" interval
* outprefix: The program will output two files: outputprefix.txt and outputprefix.ogg.  outputprefix.txt contains all of the computed features.  outputprefix.ogg contains the associated audio that was processed.  These are the two files that are loaded into the browser
* range: A 2D array that describes the interval, in seconds, of the region of audio that is processed

For example
~~~~~ matlab
prepareSongForLoopDitty('BlurredLines.mp3', 0.5, 200, 'BlurredLines', [0, 30]);
~~~~~
Will extract the first 30 seconds of a song called "BlurredLines.mp3" with a 0.5 second MFCC window and approximately 30*(200/0.5) = 12000 MFCC windows.  It will output two files: BlurredLines.ogg and BlurredLines.txt


##CrossSimilarityGUI.html
This GUI is used to view cross-similarity matrices sychronized with audio for any two songs (not necessarily songs from the Covers80 dataset).  Features are computed for each song, and the L2 distance between all pairs of self-similarity matrices in one song and all the other song are computed.  The syntax for the Matlab code to export data is as follows

~~~~~ matlab
prepareSongsForWebGUI( foldername, songfilename1, songfilename2, tempobias1, tempobias2, dim, BeatsPerBlock )
~~~~~
The meaning of the parameters is as follows:
* foldername: A folder that will be created to house four files for this song: song1.ogg, song2.ogg, CSM.png, and info.txt
* songfilename1: The filename of the first song
* songfilename2: The filename of the second song
* tempobias1: A bias for the beat tracker for song 1
* tempobias2: A bias for the beat tracker for song 2
* dim: Resized dimension of the self-similarity matrices that are computed for the sliding window MFCCs
* BeatsPerBlock: The number of beat intervals computed in each self-similarity matrix

For example
~~~~~ matlab
prepareSongsForWebGUI( 'BlurredLines', 'BlurredLines.mp3', 'GotToGiveItUp.mp3', 120, 120, 200, 12 )
~~~~~
Will compare "Blurred Lines" to "Got To Give It Up," each with a 120bmp tempo-biased beat tracker, and 200x200 self-similarity matrices of MFCC windows in 12-beat blocks.  All features and music is saved to the folder "BlurredLines"

Once this code has been run, it will export 4 files to the specified folder, which can then be loaded into CrossSimilarityGUI.html.  After the 4 files are loaded, the cross-similarity matrix will be rendered.  Click "Play" to play the first song synchronized with that matrix.  Left click to jump to a different part of the matrix.  Hold down CTRL+Left click to jump to the other song.  Have fun!

