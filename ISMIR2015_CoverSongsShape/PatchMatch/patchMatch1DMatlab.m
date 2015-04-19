%A slow implementation of generalized patch match in Matlab for testing purposes
%NNFunction is a function which takes two patches and a patch dimension
%NIters: Number of iterations (not many are needed before convergence)
%K: Number of nearest neighbors to consider in the nearest neighbor field
%(for reshaping purposes) and returns a distance
function [ D, NNF, Queries ] = patchMatch1DMatlab( MFCCsX, SampleDelaysX, bts1, ...
                                                MFCCsY, SampleDelaysY, bts2, BeatsPerWin, NIters, K, Alpha )
    addpath('../SimilarityMatrices');
    SwitchOddEven = 0;
        
    N = length(bts1);
    M = length(bts2);
    
    beatIdx1 = zeros(1, length(bts1));
    idx = 1;
    for ii = 1:N
        while(SampleDelaysX(idx) < bts1(ii) && idx < length(SampleDelaysX))
            idx = idx + 1;
        end
        beatIdx1(ii) = idx;
        if idx == length(SampleDelaysX)
            break;
        end
    end
    beatIdx2 = zeros(1, length(bts2));
    idx = 1;
    for ii = 1:M
        while(SampleDelaysY(idx) < bts2(ii) && idx < length(SampleDelaysY))
            idx = idx + 1;
        end
        if idx == length(SampleDelaysY)
            break;
        end
        beatIdx2(ii) = idx;
    end        
    N = N - BeatsPerWin;
    M = M - BeatsPerWin;
    
    Queried = zeros(N, M);%Keep track of distances that are already queried
    %so that no work is redone (TODO: Make this sparse?)
    
    %Randomly initialize nearest neighbor field
    NNF = randi(M, N, K);
    DNNF = zeros(N, K);
    MFCCsX = gpuArray(single(MFCCsX));
    MFCCsY = gpuArray(single(MFCCsY));
    for ii = 1:N
        if mod(ii, 50) == 0;
            fprintf(1, '.');
        end
        D1 = getBeatSyncSSM(MFCCsX, beatIdx1, BeatsPerWin, ii);
        for kk = 1:K
            D2 = getBeatSyncSSM(MFCCsY, beatIdx2, BeatsPerWin, NNF(ii, kk));
            L2Dist = bsxfun(@minus, D1, D2);
            DNNF(ii, kk) = sqrt(gather( sum(L2Dist(:).^2) ));
        end
    end
    for ii = 1:N
        for kk = 1:K
            Queried(ii, NNF(ii, kk)) = 1;
        end
    end
    
    fprintf(1, '\n');
    for iter = 1:NIters
        fprintf(1, 'iter = %i\n', iter);
        for ii = 1:N
            if mod(ii, 50) == 0
                fprintf(1, '.');
            end
            %STEP 1: Propagate
            idx = ii;%Index of current pixel
            di = -1;
            if mod(iter, 2) == 0 && SwitchOddEven %On even iterations propagate the other way
                idx = N - ii + 1;
                di = 1;
            end
            D1 = getBeatSyncSSM(MFCCsX, beatIdx1, BeatsPerWin, idx);
            if ii > 1
                indices = [NNF(ii, :) zeros(1, K)];
                dists = [DNNF(ii, :) inf*ones(1, K)];
                for kk = 1:K
                    otherM = NNF(idx + di, kk) - di;
                    if otherM < 1 || otherM > M %Bounds check
                        continue;
                    end
                    if Queried(idx, otherM) %Don't repeat work
                        continue;
                    end
                    Queried(idx, otherM) = 1;
                    indices(K+kk) = otherM;
                    D2 = getBeatSyncSSM(MFCCsY, beatIdx2, BeatsPerWin, otherM);
                    L2Dist = bsxfun(@minus, D1, D2);
                    dists(K+kk) = sqrt(gather( sum(L2Dist(:).^2) ));
                end
                %Pick the top K neighbors out of the K old ones and 
                %the K new ones
                [dists, distsorder] = sort(dists);
                indices = indices(distsorder);
                NNF(ii, :) = indices(1:K);
                DNNF(ii, :) = dists(1:K);
            end
            %STEP 2: Random search
            Ri = M*(2*rand(1) - 1);
            NR = floor(log(abs(Ri))/log(1.0/Alpha));
            radii = round(Ri*Alpha.^(0:NR-1));
            indices = [NNF(ii, :) zeros(1, K*NR)];
            dists = [DNNF(ii, :) inf*ones(1, K*NR)];
            %TODO: Make this parfor
            for rr = 1:NR
                for kk = 1:K
                    otherM = radii(rr) + NNF(idx, kk);
                    if otherM < 1 || otherM > M %Bounds check
                        continue;
                    end
                    if Queried(idx, otherM) %Don't repeat work
                        continue;
                    end
                    Queried(idx, otherM) = 1;
                    indices(K+(rr-1)*K+kk) = otherM;
                    D2 = getBeatSyncSSM(MFCCsY, beatIdx2, BeatsPerWin, otherM);
                    L2Dist = bsxfun(@minus, D1, D2);
                    dists(K+(rr-1)*K+kk) = sqrt(gather( sum(L2Dist(:).^2) ));
                end
            end
            %Pick the top K neighbors out of the K old ones and 
            %the K new ones
            [dists, distsorder] = sort(dists);
            indices = indices(distsorder);
            NNF(ii, :) = indices(1:K);
            DNNF(ii, :) = dists(1:K);
        end
        fprintf(1, 'Queries: %g\n', sum(Queried(:))/prod(size(Queried)));
    end
    Queries = sum(Queried(:));
    S1 = 1:N;
    D = sparse(repmat(S1(:), [K, 1]), NNF(:), ones(N*K, 1), N, M);
end