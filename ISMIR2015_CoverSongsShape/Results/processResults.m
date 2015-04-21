

%Self-Similarity parameters
dim = [100, 200, 300];
BeatsPerWin = [8, 10, 12, 14];
Kappa = [0.05, 0.1, 0.15];

for k = 1:length(Kappa)
    fprintf(1, '<h1>Kappa = %g</h1>\n<table border = "1">\n', Kappa(k));
    fprintf(1, '<tr><td></td>');
    for b = 1:length(BeatsPerWin)
        fprintf(1, '<td>BeatsPerWin = %i</td>', BeatsPerWin(b));
    end
    fprintf(1, '</tr>\n');
    for d = 1:length(dim)
        fprintf(1, '<tr><td>dim = %i</td>', dim(d));
        for b = 1:length(BeatsPerWin)
            dirName = sprintf('%i_%i_%g', dim(d), BeatsPerWin(b), Kappa(k));
            ScoresF = zeros(80, 80);
            ScoresChromaF = zeros(80, 80);
            ScoresMFCCF = zeros(80, 80);
            for beatIdx1 = 1:3
                for beatIdx2 = 1:3
                    filename = sprintf('%s/%i_%i.mat', dirName, beatIdx1, beatIdx2);
                    if exist(filename) %TODO: Some of the batch tests terminated by hitting memory ceiling
                        load(filename);
                        ScoresF = max(ScoresF, Scores);
                        ScoresChromaF = max(ScoresChromaF, ScoresChroma);
                        ScoresMFCCF = max(ScoresMFCCF, ScoresMFCC);
                    end
                end
            end
            [~, s] = max(ScoresMFCC, [], 2);
            fprintf(1, '<td><h2>%i</h2></td>', sum(s' == 1:80));
        end
        fprintf(1, '</tr>\n');
    end
    fprintf(1, '</table>');
end