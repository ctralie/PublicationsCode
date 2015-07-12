function [Chroma, SampleDelays] = getChromaTempoWindow( X, Fs, tempoPeriod, windowsPerBeat, NChromaBins, AvgFactor )
    addpath('../coversongs/src/chroma-ansyn');
    
    if nargin < 5
        NChromaBins = 12;
    end

    %Make the window size about 50 milliseconds
    macroHopSize = round(Fs/(20*4));
    
    %Get as close as possible to 50 samples per window
    windowSamples = Fs*tempoPeriod;
    hopSize = round(windowSamples/windowsPerBeat);
    macroHopSize = round(macroHopSize/hopSize)*hopSize;
    NHops = macroHopSize/hopSize;%Number of offsets at which to compute chroma
    windowSize = macroHopSize*4;
    
    %Calculate chroma at all of the offsets and interleave them all
    %together
    C = cell(1, NHops);
    parfor ii = 1:NHops
        offset = 1+(ii-1)*hopSize;
        C{ii} = chromagram_IF(X(offset:end), Fs, windowSize, NChromaBins);
    end
    CSizes = cellfun(@(x) size(x, 2), C);
    Chroma = zeros(size(C{1}, 1), sum(CSizes));
    for ii = 1:length(C)
        Chroma(:, ii:length(C):end) = C{ii};
    end
    %Now perform averaging by the average factor to make the effective
    %window size of each window
    if nargin < 6
        AvgFactor = round(windowSamples/windowSize);
    end
    NextChroma = zeros(size(Chroma, 1), size(Chroma, 2) - AvgFactor + 1);
    for ii = 1:size(NextChroma, 2)
        NextChroma(:, ii) = mean(Chroma(:, ii:ii+AvgFactor-1), 2);
    end
    Chroma = NextChroma';
    SampleDelays = 1:size(Chroma, 1);
    SampleDelays = (SampleDelays-1)*hopSize/Fs;
end
