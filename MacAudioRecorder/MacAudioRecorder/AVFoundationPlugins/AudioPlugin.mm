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

- (AVCaptureSession *) getRecordSession
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

- (void) audioPluginStartRecord
{
    NSLog(@"Hauoli - In function audioPluginStartRecord.");
    if( !isRecording && recordSession == nil)
    {
        NSLog(@"Hauoli - Start internal audio writer...");
        [self initAudioWriter];
        
        NSLog(@"Hauoli - Start video recording...");
        recordSession = [self getRecordSession];
        
        [recordSession startRunning] ;
        isRecording = YES;
    }
}

- (void) audioPluginStopRecord
{
    NSLog(@"Hauoli - In function audioPluginStopRecord.");
    if(isRecording && recordSession != nil) {
        isRecording = NO;
        
        [recordSession stopRunning] ;
        
        [internalAudioWriter finishWritingWithCompletionHandler:^(){
            NSLog (@"Hauoli - internalAudioWriter finished writing");
        }];
        
        NSLog(@"Hauoli - Audio recording stopped");
        // re-initialize all the modules
        [self audioPluginInitAudioModule];
    }
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

// Initialize audio writer (must be called after setting up the audio input)
- (void) initAudioWriter
{
    NSLog(@"Hauoli - In function initAudioWriter.");
    if(internalAudioWriter == nil) {
        NSError * error = nil;
        long timeStamp = (long)([[NSDate date] timeIntervalSince1970] * 1000);
        NSString * strTimestamp = [NSString stringWithFormat:@"%ld", timeStamp];
        NSString * fileSuffix = @"_data.wav";
        NSURL * url = [NSURL fileURLWithPath: [strTimestamp stringByAppendingString:fileSuffix]];
        NSLog(@"Hauoli - Audio writer will save data to file %@", [strTimestamp stringByAppendingString:fileSuffix]);
        
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
                               [ NSNumber numberWithFloat: 48000.0 ], AVSampleRateKey,
                               [ NSNumber numberWithBool: NO], AVLinearPCMIsFloatKey,
                               [ NSNumber numberWithBool: NO], AVLinearPCMIsNonInterleaved,
                               [ NSNumber numberWithInt: 16], AVLinearPCMBitDepthKey,
                               [ NSNumber numberWithBool: NO], AVLinearPCMIsBigEndianKey,
                               [ NSData dataWithBytes: &acl length: sizeof(acl) ], AVChannelLayoutKey,
                               nil];
        internalAudioWriterInput = [AVAssetWriterInput
                             assetWriterInputWithMediaType: AVMediaTypeAudio
                             outputSettings: audioOutputSettings];
        internalAudioWriterInput.expectsMediaDataInRealTime = YES;
        
        [internalAudioWriter addInput:internalAudioWriterInput];
    }
}

/**************************************************************
 ** Methods for writing the captured output to file
 **************************************************************/

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog( @"Hauoli - Sample buffer is not ready. Skipping sample" );
        return;
    }
    
    if(isRecording == YES) {
        lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (internalAudioWriter.status != AVAssetWriterStatusWriting ) {
            [internalAudioWriter startWriting];
            [internalAudioWriter startSessionAtSourceTime:lastSampleTime];
        }
        
        if(captureOutput == audioOutput) {
            [self newAudioSample:sampleBuffer];
        }
    }
    
    
}

- (void)newAudioSample:(CMSampleBufferRef)sampleBuffer
{
    // NSLog(@"Hauoli - In function newAudioSample");
    if (isRecording) {
        if (internalAudioWriter.status > AVAssetWriterStatusWriting) {
            NSLog(@"Hauoli - Warning: writer status is %ld", internalAudioWriter.status);
            if (internalAudioWriter.status == AVAssetWriterStatusFailed)
                NSLog(@"Hauoli - Error: %@", internalAudioWriter.error);
            return;
        }
        
        if (![internalAudioWriterInput appendSampleBuffer:sampleBuffer]) {
            NSLog(@"Hauoli - Unable to write to audio input");
        }
        // NSLog(@"Hauoli - Writed data to audio input");
    }
}
@end
