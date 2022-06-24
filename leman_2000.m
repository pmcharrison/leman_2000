

%   Input:
%
%   in_file = the input file
%   out_file = output json file
%   local_decay_sec = local decay (seconds). Can be a single number or a
%                                               comma separated list
%   global_decay_sec = global decay (seconds). Can be a single number or a 
%                                               comma separated list
%   detail = detail level. If greater than 1, the output will include the
%   auditory nerve images and the periodicity pitch images.

%   Output:
%   
%   audio_length_sec = length of the input audio file (seconds)
%   num_channels = number of channels in the input audio file
%   sample_rate = sample rate of the input audio file
%
%   auditory_nerve.images = a matrix of size [N M] representing the auditory nerve image,
%            where N is the number of channels (currently 40) and
%                  M is the number of samples
%   auditory_nerve.image_sample_freq = sample freq of ANI (in Hz)
%   auditory_nerve.image_filter_freqs = center frequencies used by the auditory model (in Hz)
%
%   periodicity_pitch.signal = periodicity pitch: a matrix of size
%               inFrameWidth * length(inMatrix) / outSampleFreq 
%   periodicity_pitch.sample_freq = sampling rate, equal to inSampleFreq/inFrameStepSize (in Hz)
%   periodicity_pitch.pitch_periods = analyzed periods (in seconds)
%   periodicity_pitch.filtered_auditory_nerve_images = bandpass filtered 
%           auditory nerve images (at the original sample frequency)
%
%   local_global_comparison.local_decay_sec = local decay parameter (s)
%   local_global_comparison.global_decay_sec = global decay parameter (s)
%   local_global_comparison.running_correlation = vector of local-global correlations

function res = leman_2000(...
    in_file, ...
    out_file, ...
    local_decay_sec, ... % typically 0.1
    global_decay_sec, ... % typically 1.5
    detail) 

warning('off', 'MATLAB:warning:OnceAndAlwaysObsolete');
warning('off', 'MATLAB:warning:FrequencyOutputObsolete');
warning('off', 'MATLAB:audiovideo:wavread:functionToBeRemoved');
warning('off', 'MATLAB:audiovideo:wavwrite:functionToBeRemoved');

[in_dir, in_file_key, in_file_ext] = fileparts(in_file);
in_file_name = strcat(in_file_key, in_file_ext);
[s,fs] = IPEMReadSoundFile(in_file_name, in_dir);
dim = size(s);
num_channels = dim(1);

local_decay_sec = parse_array(local_decay_sec);
global_decay_sec = parse_array(global_decay_sec);

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

res = struct(...
    'audio_length_sec', audio_length_sec, ...
    'num_channels', num_channels, ...
    'sample_rate', fs);

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

combinations = combvec(local_decay_sec, global_decay_sec);
dim_combinations = size(combinations);
n_combinations = dim_combinations(2);

res.local_global_comparison = cell(n_combinations, 1);

if n_combinations > 0
    for i = 1:n_combinations
        disp(['Computing running correlation ', num2str(i), '/', num2str(n_combinations), '...']);
        
        local_decay_sec_ = combinations(1, i);
        global_decay_sec_ = combinations(2, i);
        
        [~,~,~,~,LocalGlobalComparison] = ...
            IPEMContextualityIndex(PP,PPFreq,PPPeriods,[],local_decay_sec_,global_decay_sec_,[],0);
        
        res.local_global_comparison(i, 1) = {struct(...
            'local_decay_sec', local_decay_sec_, ...
            'global_decay_sec', global_decay_sec_, ...
            'running_correlation', LocalGlobalComparison)};
    end
end

savejson('', res, out_file);
end

function array = parse_array(x)
if ischar(x)
    array = str2double(strsplit(x, ','));
else
    array = x;
end
end
