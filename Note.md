## When I increase the sampling rate from 16000 to 48000, the replayed sound got cut.

I don't have much experience in audio wave/signal processing. I found this on a web page: have we leave the data uncompressed (PCM), it should stay at 48kHz (24bit). This reminds me of an operation in the code, in which the original author wrote functions to convert the recorded audio data in float to int\_16. So I guess that's why when yon increase sample rate, the replayed sound got cut.

I think the codes which do the data type conversion is somehow too complicated for me to understand. I can tell you which files you need to look at:

- Function that converts recorded data from float to int\_16:
	- AudioUnitPlugins/AudioUtils.cpp: **void tdav\_codec\_float\_to\_int16**
- Function that coverts recorded data from int\_16 to float (so that the recorded audio can be played)
	- AudioUnitPlugins/AudioUtils.cpp: **void tdav\_codec\_int16\_to\_float**


## Could you also check if the API supports higher sampling and multiple mic? 

The author of the demo project added a comment the original codes saying that on Mac OS，input and output are open by default. There seems no way for us to configure the input or output devices using code? However, we select the input and output manually in the Setting or in the App Audio MIDI Setup. I tried using the microphone on the my bluetooth headphone as input device. 

For using multiple mic, I am still trying. I can't find a way to do so currently.


## Ambient Noise Reduction

For ambient noise reduction, I think we also need to configure it in App instead of using codes. I will work on this tomorrow.

