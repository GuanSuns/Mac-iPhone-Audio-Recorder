//
//  AudioUnitPlugin.h
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/14/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaToolbox/MediaToolbox.h>
#import "AudioUtils.hpp"

#define MAX_BUFFER_SIZE 409600
#define AUDIO_FRAME_SIZE 372
#define SAMPLE_RATE 48000

NS_ASSUME_NONNULL_BEGIN

@interface AudioUnitPlugin : NSObject
{
    AudioComponentInstance audioUnit;
    int kInputBus;
    int kOutputBus;
    UInt32 preferredBufferSize; // will be calculated based on the input audio format (in bytes)
    UInt32 size;

    NSCondition *mAudioLock;

    bool isPlayback; // whether to play the recorded audio after 2 seconds
    int mDataLen;   // the size of pcm waited to be played
    void * mPCMData; // the pcm data waited to be played
    NSMutableData* mRecordData; // put microphone data in buffer, wait 2 seconds and play it

    bool savemic;   // whether to save the microphone data into files (used to check if data collecting is correct)

    ExtAudioFileRef recordingfileref;
    FILE* mic;  // pcm data collected by the microphone
    AVAudioPlayer *audioPlayer;
}

+ (AudioUnitPlugin*) sharedInstance;
- (void) StartAudioRecordAndPlay;
- (void) StopAudioRecordAndPlay;

- (void) AvAudioPlayerPlayWaveFile;
- (void) AvAudioPlayerStopPlayWaveFile;

@end

NS_ASSUME_NONNULL_END
