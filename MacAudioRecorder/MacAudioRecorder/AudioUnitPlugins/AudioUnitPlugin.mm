//
//  AudioUnitPlugin.m
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/14/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import "AudioUnitPlugin.h"

/**************************************************************
 ** Helper function to check status code
 **************************************************************/
void checkStatus(int code, NSString* param = @""){
    if(code != 0 )
    {
        NSLog(@"Hauoli - CheckStatus error:%@: %d",  param, code );
    }
}

/**************************************************************
 ** Audio Unit Plugin Implementation
 **************************************************************/
@implementation AudioUnitPlugin

// ========================================
#pragma mark - SharedSInstance
// ========================================
static AudioUnitPlugin *_sharedInstance;

+(AudioUnitPlugin*) sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"Hauoli - Creating AudioUnitPlugin shared instance.");
        _sharedInstance = [[AudioUnitPlugin alloc] init];
    });
    return _sharedInstance;
}

// ========================================
#pragma mark - Initialization
// ========================================
- (id) init {
    self = [super init];
    
    [self initParameters];
    if( savemic )
    {
        mic = fopen("/tmp/mic.pcm", "wb");
        NSLog(@"Hauoli - Create PCM file: %d", mic != nullptr);
    }
    // Initialize the buffer to store microphone data
    mRecordData = [[NSMutableData alloc] init];
    
    // Initialize Voice Processing IO
    [self initVoiceProcessingIO];
    
    return self;
}

// ========================================
#pragma mark - Initialize related parameters
// ========================================
- (void) initParameters {
    kInputBus = 1;
    kOutputBus = 0;
    mDataLen=0;
    
    isPlayback = false;
    savemic = true;
}

// ===================================================
#pragma mark - Initialize voice processing input and output
// ===================================================
- (void) initVoiceProcessingIO
{
    NSLog(@"Hauoli - initVoiceProcessingIO.");
    
    [self initAudioComponent];
    [self initInputFormatAndProperty];
    [self initOutputFormatAndProperty];
    
    // Initialize audio Unit
    OSStatus status;
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    
    mPCMData = malloc(MAX_BUFFER_SIZE);
    mAudioLock = [[NSCondition alloc]init];
}

// ========================================
#pragma mark - Initialize audio component
// ========================================
- (void) initAudioComponent
{
    NSLog(@"Hauoli - initAudioComponent.");
    
    OSStatus status;
    // Describe audio component
    size_t bytesPerSample;
#if TARGET_OS_OSX
    bytesPerSample = sizeof(Float32);
#else
    bytesPerSample = sizeof(Int32);
#endif
    
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get input component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status, @"Get Audio Unit");
}

// =================================================
#pragma mark - Initialize input format and property
// =================================================
- (void) initInputFormatAndProperty
{
    NSLog(@"Hauoli - initInputFormatAndProperty.");
    OSStatus status;

#if TARGET_OS_IPHONE
    // On Mac OS，input and output are open by default and we can't change it. Thus, we don't need to set input and output for Mac OS
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status， @"EnableIO, input");
#endif
    
    // Describe format
    AudioStreamBasicDescription audioFormat = {0};
    
    audioFormat.mSampleRate = SAMPLE_RATE;  // Sampling Rate
    audioFormat.mFormatID = kAudioFormatLinearPCM;  // PCM
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked |kAudioFormatFlagIsNonInterleaved;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;  // 1 = mono, 2 = stereo
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerPacket = 2;
    audioFormat.mBytesPerFrame = 2;
    audioFormat.mReserved = 0;
    
    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    
    checkStatus( status, @"Set input streamFormat" );
    
    preferredBufferSize = (( 20 * audioFormat.mSampleRate) / 1000); // in bytes
    size = sizeof (preferredBufferSize);
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status, @"Set input callback");
    
    // check wheter set the streamFormat successfully
    size = sizeof(audioFormat);
    status = AudioUnitGetProperty( audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  &size);
    checkStatus(status, @"Check if set the input streamFormat successfully.");
}

// ===================================================
#pragma mark - Initialize output format and property
// ===================================================
- (void) initOutputFormatAndProperty
{
    NSLog(@"Hauoli - initOutputFormatAndProperty.");
    OSStatus status;
    
#if TARGET_OS_IPHONE
    // On Mac OS，input and output are open by default and we can't change it. Thus, we don't need to set input and output for Mac OS
    // Enable IO for playback
    UInt32 zero = 1; // Set the value to 0 to close playback
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &zero,
                                  sizeof(zero));
    checkStatus(status, @"EnableIO, output");
#endif
    
    // We can use kAudioFormatFlagIsSignedInteger (int16) to record audio，but can't paly it
    // Thus, we use kAudioFormatFlagIsFloat for the output (need to convert the format when playing the audio)
    AudioStreamBasicDescription audioFormatPlay = {0};
    audioFormatPlay.mSampleRate = SAMPLE_RATE;
    audioFormatPlay.mFormatID = kAudioFormatLinearPCM;
    audioFormatPlay.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked |kAudioFormatFlagIsNonInterleaved ;
    audioFormatPlay.mChannelsPerFrame = 1;
    audioFormatPlay.mFramesPerPacket = 1;
    audioFormatPlay.mBitsPerChannel = 32;
    audioFormatPlay.mBytesPerPacket = 4;
    audioFormatPlay.mBytesPerFrame = 4;
    audioFormatPlay.mReserved = 0;
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormatPlay,
                                  sizeof(audioFormatPlay));
    checkStatus(status, @"Set output streamFormat");
    
    
    // Set buffer size for both Mac OS and iOS (but in different ways)
#if TARGET_OS_OSX
    status = AudioUnitSetProperty ( audioUnit, kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global, 0, &preferredBufferSize, size);
    checkStatus(status, @"Set output BufferFrameSize");
    
    status = AudioUnitGetProperty ( audioUnit, kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global, 0, &preferredBufferSize, &size);
    NSLog(@"buffer size:%d",preferredBufferSize );
    checkStatus(status, @"Get output BufferFrameSize");
#else
    Float32 duration = ( 20.0 / 1000.f); // in seconds
    UInt32 dsize = sizeof (duration);
    status = AudioSessionSetProperty (kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof (duration), &duration);
    checkStatus(status, "Set output PreferredHardwareIOBufferDuration");
    
    status = AudioSessionGetProperty (kAudioSessionProperty_CurrentHardwareIOBufferDuration,&dsize, &duration );
    checkStatus(status,"Get output CurrentHardwareIOBufferDuration");
    NSLog(@"buffer time:%d",duration );
#endif
    
    // Set output callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status, @"Set output RenderCallback");
    
    // check wheter set the streamFormat successfully
    size = sizeof(audioFormatPlay);
    status = AudioUnitGetProperty( audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormatPlay,
                                  &size);
    checkStatus(status, @"Check if set the output streamFormat successfully.");
}

- (void) StartAudioRecordAndPlay{
    NSLog(@"Hauoli - AudioUnityPlugin in StartAudioRecordAndPlay.");
    AudioOutputUnitStart(audioUnit);
    return ;
}

- (void) StopAudioRecordAndPlay{
    NSLog(@"Hauoli - AudioUnityPlugin in StopAudioRecordAndPlay.");
    AudioOutputUnitStop(audioUnit);
    return ;
}

// ========================================
#pragma mark - callback functions
// ========================================
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    // Because of the way our audio format (setup below) is chosen:
    // we only need 1 buffer, since it is mono
    // Samples are 16 bits = 2 bytes.
    // 1 frame includes only 1 sample
    AudioUnitPlugin *ars = (__bridge AudioUnitPlugin*)inRefCon;
    
    AudioBuffer buffer;
    
    buffer.mNumberChannels = 1;
    buffer.mDataByteSize = inNumberFrames * 2;
    buffer.mData = NULL;
    
    // Put buffer in a AudioBufferList
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    // Then:
    // Obtain recorded samples
    OSStatus status;
    
    status = AudioUnitRender([ars audioUnit],
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    checkStatus(status);
    
    if( status == 0 )
    {
        if( ars->savemic && ars->mic != nullptr  )
        {
            fwrite( bufferList.mBuffers[0].mData, 1, bufferList.mBuffers[0].mDataByteSize, ars->mic );
        }
        
        if( ars->isPlayback) {
            [ars processAudio:&bufferList];
        }
    }
    
    return noErr;
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how much data is in the buffer.
    AudioUnitPlugin *ars = (__bridge AudioUnitPlugin*)inRefCon;
    
    for (int i=0; i < ioData->mNumberBuffers; i++) {
        // in practice we will only ever have 1 buffer, since audio format is mono
        AudioBuffer buffer = ioData->mBuffers[i];
        
        BOOL isFull = NO;
        [ars->mAudioLock lock];
        if( ars->mDataLen >=  buffer.mDataByteSize)
        {
            memcpy(buffer.mData,  ars->mPCMData, buffer.mDataByteSize);
            ars->mDataLen -= buffer.mDataByteSize;
            memmove( ars->mPCMData,  (char*)ars->mPCMData+buffer.mDataByteSize, ars->mDataLen);
            isFull = YES;
        }
        [ ars->mAudioLock unlock];
        if (!isFull) {
            memset(buffer.mData, 0, buffer.mDataByteSize);
        }
    }
    return noErr;
}


// ========================================
#pragma mark - internal functions
// ========================================
- (AudioComponentInstance) audioUnit{
    return audioUnit;
}

- (void *) audioBuffer{
    return mPCMData;
}

- (void) processAudio:(AudioBufferList *)bufferList{
    [mAudioLock lock];
    [mRecordData appendBytes: bufferList[0].mBuffers[0].mData length:bufferList[0].mBuffers[0].mDataByteSize];
    [mAudioLock unlock];
    
    
    // Paly the audio after 2 seconds
    if( [mRecordData length] > SAMPLE_RATE * 4  )
    {
        [self play: mRecordData];
        
        [mAudioLock lock];
        [mRecordData resetBytesInRange:NSMakeRange(0, [mRecordData length])];
        [mRecordData setLength:0];
        [mAudioLock unlock];
    }
}

- (void) play:(NSData *) data{
    if(mPCMData == NULL){
        return;
    }
    
    [mAudioLock lock];
    
    static float* buff = new float[ SAMPLE_RATE * 4 ];
    memset( buff, 0 , sizeof( float ) * SAMPLE_RATE * 4 );
    uint8_t samplesize = 2;
    uint32_t totalsize = [mRecordData length];
    
    tdav_codec_int16_to_float( (void*)[data bytes],  buff,  &samplesize, &totalsize,  1 );
    
    if (totalsize > 0 && totalsize + mDataLen < MAX_BUFFER_SIZE) {
        memcpy( (char*)mPCMData+mDataLen, buff, totalsize );
        mDataLen += totalsize;
    }
    
    [mAudioLock unlock];
}


@end
