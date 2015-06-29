
~~~~~ octave
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
