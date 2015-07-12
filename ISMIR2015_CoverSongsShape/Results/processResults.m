RANK_1 = 1;
MEDIAN_RANK = 2;
ResultsType = RANK_1;

for k = 1:length(Kappa)
    %fprintf(1, '<h2>Kappa = %g</h2>\n<table border = "1">\n', Kappa(k));
    fprintf(1, '<table border = "1">\n');
    fprintf(1, '<tr><td>Kappa = %g</td>', Kappa(k));
    for b = 1:length(BeatsPerBlock)
        fprintf(1, '<td>B = %i</td>', BeatsPerBlock(b));
    end
    fprintf(1, '</tr>\n');
    for d = 1:length(dim)
        fprintf(1, '<tr><td>d = %i</td>', dim(d));
        for b = 1:length(BeatsPerBlock)
            dirName = sprintf('%i_%i_%g', dim(d), BeatsPerBlock(b), Kappa(k));
            ScoresF = zeros(80, 80);
            ScoresChromaF = zeros(80, 80);
            ScoresMFCCF = zeros(80, 80);
            for beatIdx1 = beatIdxs
                for beatIdx2 = beatIdxs
                    filename = sprintf('%s/%i_%i.mat', dirName, beatIdx1, beatIdx2);
                    if exist(filename) %TODO: Some of the batch tests terminated by hitting memory ceiling
                        load(filename);
                        ScoresF = max(ScoresF, Scores);
                        ScoresChromaF = max(ScoresChromaF, ScoresChroma);
                        ScoresMFCCF = max(ScoresMFCCF, CScoresMFCC);
                        %Compute norm based on CSM sizes
                        Norms = zeros(80, 80);
                        for ii = 1:80
                            for jj = 1:80
                                %Norms(ii, jj) = sqrt(prod(CrossSizes{ii, jj}));
                                %Norms(ii, jj) = min(CrossSizes{ii, jj})*sqrt(2);
                                Norms(ii, jj) = 1;
                            end
                        end
                        ScoresF = ScoresF./Norms;
                        ScoresChromaF = ScoresChromaF./Norms;
                        ScoresMFCCF = ScoresMFCCF./Norms;
                    end
                end
            end
            ToScore = ScoresMFCCF;
            if ResultsType == RANK_1
                [~, s] = max(ToScore, [], 2);
                fprintf(1, '<td>%i</td>', sum(s' == 1:80));
            elseif ResultsType == MEDIAN_RANK
                [~, idx] = sort(ToScore, 2, 'descend');
                TrueIndices = 1:80;
                TrueIndices = repmat(TrueIndices(:), [1 80]);
                idx = (idx == TrueIndices);
                [~, idx] = max(idx, [], 2);
                fprintf(1, '<td>%g (%g)</td>', median(idx), mean(idx));
            end
        end
        fprintf(1, '</tr>\n');
    end
    fprintf(1, '</table>');
end
