//
//  AudioPlugin.m
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/3/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import "AudioPlugin.h"


/**************************************************************
 ** Data Structure and Variables for Internal Recorder
 **************************************************************/
dispatch_queue_t queue;       // queue for processing audio


@interface AudioPlugin()
@end

@implementation AudioPlugin
static AudioPlugin *_sharedInstance;

+(AudioPlugin*) sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"Hauoli - Creating AudioPlugin shared instance.");
        _sharedInstance = [[AudioPlugin alloc] init];
    });
    return _sharedInstance;
}

-(id)init
{
    self = [super init];
    if(self) {
        [self audioPluginInitAudioModule];
    }
    return self;
}

-(void) audioPluginInitAudioModule
{
    NSLog(@"Hauoli - Initialize AudioPlugin audio module.");
    recordSession = nil;
    audioInput = nil;
    audioOutput = nil;
    isRecording = NO;
    internalAudioWriter = nil;
}

- (AVCaptureSession *) recordSession
{
    NSLog(@"Hauoli - In function recordSession.");
    if(recordSession == nil) {
        recordSession = [[AVCaptureSession alloc] init];
        
        // add audio input (microphone)
        [self setAudioMicInput];
        if ([recordSession canAddInput:audioInput]) {
            [recordSession addInput:audioInput];
        }
        
        // add audio output
        [self setAudioOutput];
        if([recordSession canAddOutput:audioOutput]) {
            [recordSession addOutput:audioOutput];
        }
        
        // create audio connection
        [self setAudioConnection];
    }
    return recordSession;
}

// Create audio connection (must be called after initializing audio output)
- (void) setAudioConnection
{
    NSLog(@"Hauoli - In function setAudioConnection.");
    if(audioOutput != nil && audioConnection == nil) {
        audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
}


// Set audio output
- (void) setAudioOutput
{
    NSLog(@"Hauoli - In function setAudioOutput.");
    if(audioOutput == nil) {
        audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        queue = dispatch_queue_create("com.hauoli.dataqueue", NULL);
        [audioOutput setSampleBufferDelegate:self queue:queue];
    }
}


// Set audio input to microphone input
- (void) setAudioMicInput
{
    NSLog(@"Hauoli - In function setAudioMicInput.");
    if(audioInput == nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        audioInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"Hauoli - In setAudioMicInput, fail to get microphone input.");
        }
    }
}

// Initialize audio writer (must be called after setting up the audio input
- (void) initAudioWriter
{
    NSLog(@"Hauoli - In function initAudioWriter.");
    if(internalAudioWriter == nil) {
        NSError * error = nil;
        NSURL *url = [NSURL fileURLWithPath:@"/Users/lguan/Desktop/Hauoli/MacOSAudioRecorder/data/data.wav"];
        internalAudioWriter = [[AVAssetWriter alloc] initWithURL:url
                                  fileType:AVFileTypeWAVE
                                     error:&error];
        NSParameterAssert(internalAudioWriter);
        
        // Add the audio input
        AudioChannelLayout acl;
        bzero( &acl, sizeof(acl));
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        
        NSDictionary* audioOutputSettings = nil;
        audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                               [ NSNumber numberWithInt: kAudioFormatLinearPCM ], AVFormatIDKey,
                               [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                               [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                               [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                               [ NSData dataWithBytes: &acl length: sizeof(acl) ], AVChannelLayoutKey,
                               nil];
        internalAudioWriterInput = [AVAssetWriterInput
                             assetWriterInputWithMediaType: AVMediaTypeAudio
                             outputSettings: audioOutputSettings];
        internalAudioWriterInput.expectsMediaDataInRealTime = YES;
        
        [internalAudioWriter addInput:internalAudioWriterInput];
    }
}


- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog( @"Hauoli - Sample buffer is not ready. Skipping sample" );
        return;
    }
    
    if(isRecording == YES && connection == audioConnection) {
        
    }
    
    
}
@end
