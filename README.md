# Mac-iPhone-Audio-Recorder

## Core Audio
### Description
- Automatically set the format (sample rate) of IO devices to specific value (in function coreAudioConfigIODevices in file  IODevicesConfigurator/IODeviceConfigurator.h)


## PortAudio Plugin

### Description
- To start recording, click the Start Recording button on the GUI; to stop, click the Stop Recording button.
- The current codes are able to record audio while playing a previously-recorded pcm file (generated by App using 5000 Hz).
- The audio in the first 20 seconds will be saved in the pcm file /tmp/recorded.pcm
- You can change the configuration of input format in PortAudioPlugin.h. However, the setting of output format is fixed (48000 sample rate, int16, 1 channel), since it need to be consistent with the format of the played pcm file.
- The recorded pcm file will be played continuously and repeatedly. There seems to be a small gap when reaching the end of the pcm data. However, everything can be controlled by codes (you can see function playCallback). If we can generate audio using codes, there should be no gap in the loop.

### Input and output devices
- When the program starts, input and output devices info will be printed in the console.
- The codes that query input and output devices are in the function loadDeviceInfo in file ViewController.m
- I tried adding external microphones and speakers, but the number of devices returned by Pa\_GetDeviceCount stays the same, which means that PortAudio can only use the current input/output devices specified by the OS.
- Although PortAudio can only use the current input/output devices specified by the OS, it is able to get avaliable settings of the default input/output devices. For example, PortAudio is able to get all the avaliable Sample Rates and numbers of channels supported by the device.

### Tips on installing PortAudio on Mac
To use test it on Mac:

1. Check out my latest code: https://gitlab.com/Hauoli/mac-os-audio-recorder
2. Downlowd PortAudio on this website: http://www.portaudio.com/download.html
3. To import PortAudio into XCode, follow the instuctions in this Youtube Video: https://www.youtube.com/watch?v=PIswwa4UlRE

To use (build) PortAudio on the latest Macbook, we should use the command "./configure --disable-mac-universal && make" instead of "./configure && make" in the video.

In addition, you might also see the error "xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory ...". This command should be able to fix this error: "sudo xcode-select --switch /Library/Developer/CommandLineTools"
