addpath(genpath('../coversongs'));
files1 = textread('../coversongs/covers32k/list1.list', '%s\n');
files2 = textread('../coversongs/covers32k/list2.list', '%s\n');

files = cell(length(files1) + length(files1), 1);
files(1:length(files1)) = files1;
files(length(files1)+1:end) = files2;

tempos = [60, 120, 180];
windowsPerBeat = 200;

for songIdx = 1:length(files)
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
    allChroma = cell(length(tempos), 1);
    allSampleDelaysChroma = cell(length(tempos), 1);
    allMFCC = cell(length(tempos), 1);
    allSampleDelaysMFCC = cell(length(tempos), 1);
    allBeatSyncChroma = cell(length(tempos), 1);
    
    for tempoidx = 1:length(tempos)
        tempo = tempos(tempoidx);
        fprintf(1, 'Getting features for %s %i BPM Seed...\n', files{songIdx}, tempo);
        bts = beat(X, Fs, tempo, 6);
        makeBeatsAudio( files{songIdx}, sprintf('%sBts%i', files{songIdx}, tempo), bts );

        tempoPeriod = mean(bts(2:end) - bts(1:end-1));
        disp('Getting MFCC...');
        [MFCC, SampleDelaysMFCC] = getMFCCTempoWindow(X, Fs, tempoPeriod, windowsPerBeat);
        disp('Getting Chroma...');
        %[Chroma, SampleDelaysChroma] = getChromaTempoWindow(X, Fs, tempoPeriod, windowsPerBeat, 36);
        BeatSyncChroma = getBeatSyncChromaMatrixEllis(X, Fs, bts);
        
        allbts{tempoidx} = bts;
        %allChroma{tempoidx} = Chroma;
        %allSampleDelaysChroma{tempoidx} = SampleDelaysChroma;
        allMFCC{tempoidx} = MFCC;
        allSampleDelaysMFCC{tempoidx} = SampleDelaysMFCC;
        allBeatSyncChroma{tempoidx} = BeatSyncChroma;
    end
    save(outname, 'tempos', 'allbts', 'allChroma', 'allSampleDelaysChroma', 'allMFCC', 'allSampleDelaysMFCC', 'allBeatSyncChroma');
end
