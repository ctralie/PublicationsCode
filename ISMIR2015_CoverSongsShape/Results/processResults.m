for k = 1:length(Kappas)
    %fprintf(1, '<h2>Kappa = %g</h2>\n<table border = "1">\n', Kappa(k));
    fprintf(1, '<table border = "1">\n');
    fprintf(1, '<tr><td>Kappa = %g</td>', Kappas(k));
    for b = 1:length(BeatsPerBlocks)
        fprintf(1, '<td>B = %i</td>', BeatsPerBlocks(b));
    end
    fprintf(1, '</tr>\n');
    for d = 1:length(dims)
        fprintf(1, '<tr><td>d = %i</td>', dims(d));
        for b = 1:length(BeatsPerBlocks)
            dirName = sprintf('%i_%i_%g', dims(d), BeatsPerBlocks(b), Kappas(k));
            ScoresMFCCF = zeros(80, 80);
            for beatIdx1 = beatIdxs1
                for beatIdx2 = beatIdxs2
                    filename = sprintf('%s/%i_%i.mat', dirName, beatIdx1, beatIdx2);
                    if exist(filename) %TODO: Some of the batch tests terminated by hitting memory ceiling
                        load(filename);
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
                        ScoresMFCCF = ScoresMFCCF./Norms;
                    end
                end
            end
            
            %Report rank-1 and median/mean rank
            [~, s] = max(ScoresMFCCF, [], 2);
            [~, idx] = sort(ScoresMFCCF, 2, 'descend');
            TrueIndices = 1:80;
            TrueIndices = repmat(TrueIndices(:), [1 80]);
            idx = (idx == TrueIndices);
            [~, idx] = max(idx, [], 2);
            fprintf(1, '<td>%i (%g / %g)</td>', sum(s' == 1:80), median(idx), mean(idx));
        end
        fprintf(1, '</tr>\n');
    end
    fprintf(1, '</table>');
end
