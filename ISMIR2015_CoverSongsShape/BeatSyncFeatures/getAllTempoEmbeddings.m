addpath(genpath('../coversongs'));
files1 = textread('../coversongs/covers32k/list1.list', '%s\n');
files2 = textread('../coversongs/covers32k/list2.list', '%s\n');

files = cell(length(files1) + length(files1), 1);
files(1:length(files1)) = files1;
files(length(files1)+1:end) = files2;

tempos = [60, 120, 180];
windowsPerBeat = 10;

for songIdx = 1:length(files)
    tic;
    outname = sprintf('%s.mat', files{songIdx});
    if exist(outname)
        continue;
    end
    [pathstr, ~, ~] = fileparts(outname);
    pathstr = ['./', pathstr];
    if ~exist(pathstr)
        mkdir(pathstr);
    end
    
    filename = sprintf('../coversongs/covers32k/%s.mp3', files{songIdx});
    fprintf(1, 'Loading %s...\n', files{songIdx});
    [X, Fs] = audioread(filename);
    if size(X, 2) > 1
        X = mean(X, 2);
    end
    fprintf(1, 'Finished loading %s\n', files{songIdx});
    
    allbts = cell(length(tempos), 1);
    
    for tempoidx = 1:length(tempos)
        tempo = tempos(tempoidx);
        bts = beat(X, Fs, tempo, 6);
        allbts{tempoidx} = bts;
        makeBeatsAudio( files{songIdx}, sprintf('%sBts%i', files{songIdx}, tempo), bts );
    end
    
    fprintf(1, 'Getting MFCC features for %s %i...\n', files{songIdx});

    tempoPeriod = mean(allbts{2}(2:end) - allbts{2}(1:end-1));
    [MFCC, SampleDelaysMFCC] = getMFCCTempoWindow(X, Fs, tempoPeriod, windowsPerBeat);

    save(outname, 'tempos', 'allbts', 'MFCC', 'SampleDelaysMFCC');
    toc;
    
end
