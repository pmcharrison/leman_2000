Author: Peter Harrison

This repository provides a portable implementation of Leman's (2000) model of tonal contextuality.
The original software is from 2003 and only runs on legacy versions of MATLAB. 
It has always been a bit of a pain to get this software up and running again when 
we want to do new analyses with it. 
My strategy here is to wrap everything in a Docker container, meaning that 
no prior installation steps are required, other than installing Docker itself.

The implementation should work fine on Linux (Intel/AMD 64) as well as on standard Intel Macs.
Unfortunately it doesn't seem to work on M1 Macs.
I have not tested it yet on Windows.

## Installation

You need to install Docker if you don't have it already.

Then you need to pull the image:

```
docker pull ghcr.io/pmcharrison/leman_2000:latest
```

Now, suppose that you have an audio file called `my.wav` in your current directory.
You can generate an analysis for that audio file by running the following command:

```
sudo docker run \
    -v $PWD/my.wav:/input.wav \
    -v $PWD/output:/output \
    ghcr.io/pmcharrison/leman_2000:latest \
    input.wav output/analysis.json \
    0.1 4 \  # local and global decay parameters
    5        # detail level
```

For local and global decay parameters, you can also put comma separated lists, 
in which case the script will iterate over all pairs of those values.
For example, if I put `0.1,0.5 2.0,4.0`,
the model would compute outputs for 0.1 and 2.0, 0.1 and 4.0, 0.5 and 2.0, and finally 0.5 and 4.0.
The final parameter determines how much detail is saved in the output.
If you set it to 0, then the auditory nerve and periodicity pitch images won't be saved,
which will reduce the output file size quite a lot.

## Archive notes

To run within MATLAB (R2014b):
- Add jsonlab-2.0 to path (including subfolders)
- Add IPEMToolboc/IPEMToolbox to path (including subfolders)
- Example command: leman_2000('IPEMToolbox/IPEMToolbox/Demos/MECPatternExtraction/BartokScherzoSuiteOp14.wav', 'test.json', '0.1,1', '2,4', 5)

To compile the MATLAB package:
- Make sure your working directory is the top-level leman_2000 directory
- Click Apps > Application Compiler
- Enter 'leman_2000' as the application name (no quotes)
- Add 'leman_2000.m' as the application main file
- Under 'Files required for your application to run', add jsonlab-2.0, then add IPEMToolbox/IPEMToolbox
- Click 'Package'
- Wait until you see 'Packaging Complete'

To run the compiled MATLAB package:
- Example command: ./leman_2000/for_redistribution_files_only/run_leman_2000.sh ~/MATLAB/R2014b 'IPEMToolbox/IPEMToolbox/Demos/MECPatternExtraction/BartokScherzoSuiteOp14.wav' 'test.json' 0.1,1 2,4 5

To build the Docker image locally (note that by default this is done remotely in GitHub CI):

```
sudo docker build -t leman_2000 .
```

To run an analysis from the Docker image:

```
sudo docker run \
    -v $PWD/my.wav:/input.wav \
    -v $PWD/output:/output \
    leman_2000 \
    input.wav output/analysis.json \
    0.1 4 \  # local and global decay parameters
    5        # detail level
```

Note that the paths passsed to -v must be full paths, not relative paths.

~~~

Arguments for the underlying MATLAB implementation:

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
