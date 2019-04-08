//
//  ViewController.h
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/3/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <portaudio.h>
#import "AVFoundationPlugins/AudioPlugin.h"
#import "AudioUnitPlugins/AudioUnitPlugin.h"
#import "PortAudioPlugins/PortAudioPlugin.h"

typedef enum {
    EnumAVFoundation,
    EnumAudioUnit,
    EnumPortAudio
} AudioTools;

void PrintSupportedStandardSampleRates( const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters );

@interface ViewController : NSViewController
{
    AudioTools usedTools;
    
    IBOutlet NSPopUpButton *btnAudioTools;
    IBOutlet NSPopUpButton *btnInputDevices;
}

- (IBAction)btnStartRecord:(id)sender;
- (IBAction)btnStopRecord:(id)sender;
- (IBAction)btnPlayAudio:(id)sender;
- (IBAction)btnStopAudio:(id)sender;
- (IBAction)btnUpdateAudioTool:(id)sender;
- (IBAction)btnUpdateInputDevice:(id)sender;

@end

