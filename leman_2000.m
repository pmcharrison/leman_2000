% Output:
%   in_file = the input file
%   in_dir = the input directory

%   auditory_nerve_images = a matrix of size [N M] representing the auditory nerve image,
%            where N is the number of channels (currently 40) and
%                  M is the number of samples
%   auditory_nerve_image_sample_freq = sample freq of ANI (in Hz)
%   auditory_nerve_image_filter_freqs = center frequencies used by the auditory model (in Hz)
%   periodicity_pitch_signal = periodicity pitch: a matrix of size
%               inFrameWidth * length(inMatrix) / outSampleFreq 
%   periodicity_pitch_sample_freq = sampling rate, equal to inSampleFreq/inFrameStepSize (in Hz)
%   filtered_auditory_nerve_images = analyzed periods (in s)
%   outFANI = bandpass filtered auditory nerve images (at the original sample
%             frequency)
%   local_global_comparison = vector of local-global correlations

function res = leman_2000(...
    in_file, ...
    in_dir, ...
    out_file, ...
    local_decay_sec, ... % typically 0.1
    global_decay_sec, ... % typically 1.5
    detail) 

[s,fs] = IPEMReadSoundFile(in_file, in_dir);
dim = size(s);
num_channels = dim(1);

if num_channels == 2
    % Convert to mono
    s = (s(1,:) + s(2,:)) / 2;
end

% Get stimulus length
audio_length_sec = length(s) / fs;

% Calculate the auditory nerve image
[ANI,ANIFreq,ANIFilterFreqs] = IPEMCalcANI(s,fs);

% Calculate the periodicity-pitch image
[PP,PPFreq,PPPeriods,PPFANI] = IPEMPeriodicityPitch(ANI,ANIFreq);

% Calculate the contextuality index
[~,~,~,~,LocalGlobalComparison] = ...
    IPEMContextualityIndex(PP,PPFreq,PPPeriods,[],local_decay_sec,global_decay_sec,[],0);

res = struct(...
    'audio_length_sec', audio_length_sec, ...
    'num_channels', num_channels, ...
    'sample_rate', fs, ...
    'local_decay_sec', local_decay_sec, ...
    'global_decay_sec', global_decay_sec, ...
    'local_global_comparison', LocalGlobalComparison);

if detail > 1
    res.auditory_nerve = struct(...
        'images', ANI, ...
        'sample_freq', ANIFreq, ...
        'filter_freqs', ANIFilterFreqs);
    
    res.periodicity_pitch = struct(...
        'signal', PP, ...
        'sample_freq', PPFreq, ...
        'pitch_periods', PPPeriods, ...
        'filtered_auditory_nerve_images', PPFANI);
end

savejson('', res, out_file);
end
