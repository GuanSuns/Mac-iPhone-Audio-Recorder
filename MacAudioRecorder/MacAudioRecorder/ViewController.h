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

@interface ViewController : NSViewController
{
    bool useAudioUnit;
}

- (IBAction)btnStartRecord:(id)sender;
- (IBAction)btnStopRecord:(id)sender;

@end

