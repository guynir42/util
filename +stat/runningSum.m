function S = runningSum(S, M)

    if isempty(S)
        S = M;
    else
        S = S + M;
    end

end