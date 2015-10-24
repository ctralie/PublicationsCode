This folder contains code to precompute beat-synchronous MFCC and Chroma features.  Ensure that the "rastamat" library for computing MFCC is downloaded and extracted to this directory

http://labrosa.ee.columbia.edu/matlab/rastamat/

and that you have downloaded and extracted the covers80 dataset one directory up.  Run the file "getAllTempoEmbeddings.m" to precompute all of the MFCC and chroma features.  With the current settings computing only MFCC features, this may take up to an hour, and the resulting feature files will take up about 200MB.
