//
//  ViewController.h
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/3/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AVFoundationPlugins/AudioPlugin.h"
#import "AudioUnitPlugins/AudioUnitPlugin.h"
#import "PortAudioPlugins/PortAudioPlugins.hpp"

typedef enum {
    EnumAVFoundation,
    EnumAudioUnit,
    EnumPortAudio
} AudioTools;

@interface ViewController : NSViewController
{
    AudioTools usedTools;
}

- (IBAction)btnStartRecord:(id)sender;
- (IBAction)btnStopRecord:(id)sender;
- (IBAction)btnPlayAudio:(id)sender;
- (IBAction)btnStopAudio:(id)sender;

@end

