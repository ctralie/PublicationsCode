function [] = makeBeatsAudio( filePrefix, fileoutPrefix, btsin )
    bts.onsets = btsin;
    [X, Fs] = audioread(sprintf('../coversongs/covers32k/%s.mp3', filePrefix));
    blip = cos(2*pi*440*(1:200)/Fs);
    for ii = 1:length(bts.onsets)
        idx = round(bts.onsets(ii)*Fs);
        X(idx:idx+length(blip)-1) = blip;
    end
    audiowrite(sprintf('../coversongs/covers32k/%s.ogg', fileoutPrefix), X, Fs);
end

