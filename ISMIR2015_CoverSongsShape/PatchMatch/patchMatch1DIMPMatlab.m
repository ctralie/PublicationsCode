%A slow implementation of generalized patch match in Matlab for testing purposes
%NNFunction is a function which takes two patches and a patch dimension
%NIters: Number of iterations (not many are needed before convergence)
%K: Number of nearest neighbors to consider in the nearest neighbor field
%(for reshaping purposes) and returns a distance
function [ DOut, NNF, Queries ] = patchMatch1DIMPMatlab( DOracle, NIters, K, Alpha )
    addpath('..');
    SwitchOddEven = 0;

    N = size(DOracle, 1);
    M = size(DOracle, 2);
    
    Queried = zeros(N, M);%Keep track of distances that are already queried
    %so that no work is redone (TODO: Make this sparse?)    
    
    %Randomly initialize nearest neighbor field
    NNF = randi(M, N, K);
    DNNF = DOracle(NNF);
    
    for iter = 1:NIters
        for ii = 1:N
            %STEP 1: Propagate
            idx = ii;%Index of current pixel
            di = -1;
            if mod(iter, 2) == 0 && SwitchOddEven %On even iterations propagate the other way
                idx = N - ii + 1;
                di = 1;
            end
            if ii > 1
                indices = [NNF(ii, :) zeros(1, K)];
                dists = [DNNF(ii, :) inf*ones(1, K)];
                for kk = 1:K
                    otherM = NNF(idx + di, kk) - di;
                    if otherM < 1 || otherM > M %Bounds check
                        continue;
                    end
                    if Queried(ii, otherM) %Don't repeat work
                        continue;
                    end
                    Queried(ii, otherM) = 1;
                    indices(K+kk) = otherM;
                    dists(K+kk) = DOracle(idx, otherM);
                end
                %Pick the top K neighbors out of the K old ones and 
                %the K new ones
                [dists, distsorder] = sort(dists);
                indices = indices(distsorder);
                NNF(ii, :) = indices(1:K);
                DNNF(ii, :) = dists(1:K);
            end
            %STEP 2: Random search
            if Alpha == 0
                %Alpha = 0 means skip debiasing
                continue;
            end
            Ri = M*(2*rand(1) - 1);
            NR = floor(log(abs(Ri))/log(1.0/Alpha));
            radii = round(Ri*Alpha.^(0:NR-1));
            indices = [NNF(ii, :) zeros(1, K*NR)];
            dists = [DNNF(ii, :) inf*ones(1, K*NR)];
            for rr = 1:NR
                for kk = 1:K
                    otherM = radii(rr) + NNF(idx, kk);
                    if otherM < 1 || otherM > M %Bounds check
                        continue;
                    end
                    if Queried(ii, otherM) %Don't repeat work
                        continue;
                    end
                    Queried(ii, otherM) = 1;
                    indices(K+(rr-1)*K+kk) = otherM;
                    dists(K+(rr-1)*K+kk) = DOracle(idx, otherM);
                end
            end
            %Pick the top K neighbors out of the K old ones and 
            %the K new ones
            [dists, distsorder] = sort(dists);
            indices = indices(distsorder);
            NNF(ii, :) = indices(1:K);
            DNNF(ii, :) = dists(1:K);
        end
    end
    Queries = sum(Queried(:));
    S1 = 1:N;
    DOut = sparse(repmat(S1(:), [K, 1]), NNF(:), ones(N*K, 1), N, M);
end
