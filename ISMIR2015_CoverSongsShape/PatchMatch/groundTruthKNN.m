function [ DOut ] = groundTruthKNN( DOracle, K )
    N = size(DOracle, 1);
    M = size(DOracle, 2);
    S1 = 1:N;
    NNF = sort(DOracle, 2);
    NNF = NNF(:, 1:K);
    DOut = sparse(repmat(S1(:), [K, 1]), NNF(:), ones(N*K, 1), N, M);
end
