function [ D, beatIdx ] = getBeatSyncDistanceMatrices( X, SampleDelays, bts, dim, BeatsPerBlock )
    addpath('../../');
    CLEANEND = 1;
    N = length(bts)-BeatsPerBlock;
    
    D = zeros(N, dim*dim);
    
    beatIdx = zeros(1, length(bts));
    idx = 1;
    for ii = 1:N
        while(SampleDelays(idx) < bts(ii))
            idx = idx + 1;
        end
        beatIdx(ii) = idx;
    end
    
    %Point center and sphere-normalize point clouds
    validIdx = ones(1, N);
    parfor ii = 1:N
        Y = X(beatIdx(ii)+1:beatIdx(ii+BeatsPerBlock), :);
        if (isempty(Y))
            validIdx(ii) = 0;
            continue;
        end
        Y = bsxfun(@minus, mean(Y), Y);
        Norm = 1./(sqrt(sum(Y.*Y, 2)));
        Y = Y.*(repmat(Norm, [1 size(Y, 2)]));
        dotY = dot(Y, Y, 2);
        thisD = bsxfun(@plus, dotY, dotY') - 2*(Y*Y');
        thisD = imresize(thisD, [dim dim]);
        D(ii, :) = thisD(:);
    end
    if CLEANEND
        idx = find(validIdx == 0);
        D = D(1:idx-1, :);
    end
end