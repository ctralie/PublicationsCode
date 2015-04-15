%A slow implementation of generalized patch match in Matlab for testing purposes
%NNFunction is a function which takes two patches and a patch dimension
%NIters: Number of iterations (not many are needed before convergence)
%K: Number of nearest neighbors to consider in the nearest neighbor field
%(for reshaping purposes) and returns a distance
function [ NNF, Queries ] = patchMatch1DMatlab( Ds1, Ds2, NNFunction, NIters, K, Alpha )
    addpath('..');
    SwitchOddEven = 0;
    Queries = 0;
        
    N = size(Ds1, 1);
    M = size(Ds2, 1);
    
    Queried = zeros(N, M);%Keep track of distances that are already queried
    %so that no work is redone (TODO: Make this sparse?)
    queries = 0;
    
    %Randomly initialize nearest neighbor field
    NNF = randi(M, N, K);
    %Bias towards the diagonal
%     NNF = repmat((1:M)', [1 K]);
    DNNF = zeros(N, K);
    for ii = 1:N
        if N > 1000 && mod(ii, 1000) == 0
            fprintf(1, '.');
        end
        for kk = 1:K
            DNNF(ii, kk) = NNFunction(Ds1(ii, :), Ds2(NNF(ii, kk), :), dim);
            %Queried(ii, NNF(ii, kk)) = 1;
        end
    end
    for iter = 1:NIters
        fprintf(1, 'iter = %i\n', iter);
        for ii = 1:N
            if N > 1000 && mod(ii, 1000) == 0
                fprintf(1, '.');
            end
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
                    Queries = Queries + 1;
                    indices(K+kk) = otherM;
                    dists(K+kk) = NNFunction(Ds1(idx, :), Ds2(otherM, :));
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
                    Queries = Queries + 1;
                    indices(K+(rr-1)*K+kk) = otherM;
                    dists(K+(rr-1)*K+kk) = NNFunction(Ds1(idx, :), Ds2(otherM, :));
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
end
