addpath('BeatSyncFeatures');
addpath('SequenceAlignment');
addpath('PatchMatch');

list1 = 'coversongs/covers32k/list1.list';
list2 = 'coversongs/covers32k/list2.list';
files1 = textread(list1, '%s\n');
files2 = textread(list2, '%s\n');

files = cell(length(files1) + length(files1), 1);
files(1:length(files1)) = files1;
files(length(files1)+1:end) = files2;

load('Chromas.mat');
BeatsPerWin = 10;
tempo = 120;

% Chromas = cell(length(files), 1);
% parfor ii = 1:length(files)
%     filename = sprintf('coversongs/covers32k/%s.mp3', files{ii});
%     fprintf(1, 'Loading %s...\n', files{ii});
%     [X, Fs] = audioread(filename);
%     if size(X, 2) > 1
%         X = mean(X, 2);
%     end
%     fprintf(1, 'Finished loading %s\n', files{ii});
%     
%     bts = beat(X, Fs, tempo, 6);
%     Chromas{ii} = getBeatSyncChromaMatrixEllis(X, Fs, bts);
% end

Ks = 1:5;
NIters = 1:5;
Alphas = 0:0.1:0.5;

[Ks, NIters, Alphas] = ndgrid(Ks, NIters, Alphas);
Ks = Ks(:); NIters = NIters(:); Alphas = Alphas(:);
K = Ks(PMType);
NIters = NIters(PMType);
Alpha = Alphas(PMType);

Scores = inf*ones(80, 80);

fprintf(1, 'Doing K = %g, NIters = %i, Alpha = %g...\n\n', K, NIters, Alpha);
for ii = 1:80
    X = getBeatSyncChromaDelay(Chromas{ii}, BeatsPerWin, 0);
    parfor jj = 1:80
        fprintf(1, 'Doing %i - %i\n', ii, jj);
        for cc = 0:11
            Y = getBeatSyncChromaDelay(Chromas{jj+80}, BeatsPerWin, cc);
            D = bsxfun(@plus, dot(X, X, 2), dot(Y, Y, 2)') - 2*(X*Y');
            CSM = patchMatch1DIMPMatlab(D, NIters, K, Alpha);
            CSM = double(full(CSM));
            Scores(ii, jj) = min(Scores(ii, jj), sqrt(size(Y, 1))/swalignimp(CSM));
        end
    end
end

if ~exist('ChromaScores')
    mkdir('ChromaScores');
end
save(sprintf('ChromaScores/%i.mat', PMType), 'Scores', 'K', 'NIters', 'Alpha');
