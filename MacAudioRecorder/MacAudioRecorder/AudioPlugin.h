//
//  AudioPlugin.h
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/3/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioPlugin : NSObject
{
    AVCaptureDeviceInput * audioInput;
    AVCaptureAudioDataOutput * audioOutput;
    AVCaptureConnection * audioConnection;
    AVCaptureSession * recordSession;
    BOOL isRecording;
    AVAssetWriter * internalAudioWriter;
}

+(AudioPlugin*) sharedInstance;
-(id) init;
-(void) audioPluginInitAudioModule;
-(void) audioPluginStartRecord;
-(void) audioPluginStopRecord;
- (void) setAudioMicInput;
- (void) setAudioOutput;
- (void) setAudioConnection;
- (AVCaptureSession *)recordSession;


@end

NS_ASSUME_NONNULL_END
