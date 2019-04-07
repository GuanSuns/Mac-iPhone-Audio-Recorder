//
//  ViewController.m
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/3/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    usedTools = EnumPortAudio;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)btnStartRecord:(id)sender {
    if(usedTools == EnumAudioUnit) {
        AudioUnitPlugin *audioUnitPlugin = [AudioUnitPlugin sharedInstance];
        [audioUnitPlugin StartAudioRecordAndPlay];
    } else if (usedTools == EnumAVFoundation) {
        AudioPlugin * audioPlugin = [AudioPlugin sharedInstance];
        [audioPlugin audioPluginStartRecord];
    } else if (usedTools == EnumPortAudio) {
        PortAudioPlugin * portAudioPlugin = [PortAudioPlugin sharedInstance];
        [portAudioPlugin StartAudioRecordAndPlay];
    }
}

- (IBAction)btnStopRecord:(id)sender {
    if(usedTools == EnumAudioUnit) {
        AudioUnitPlugin *audioUnitPlugin = [AudioUnitPlugin sharedInstance];
        [audioUnitPlugin StopAudioRecordAndPlay];
    } else if (usedTools == EnumAVFoundation) {
        AudioPlugin * audioPlugin = [AudioPlugin sharedInstance];
        [audioPlugin audioPluginStopRecord];
    } else if (usedTools == EnumPortAudio) {
        PortAudioPlugin * portAudioPlugin = [PortAudioPlugin sharedInstance];
        [portAudioPlugin StopAudioRecordAndPlay];
    }
}

- (IBAction)btnPlayAudio:(id)sender {
    if(usedTools == EnumAudioUnit) {
        AudioUnitPlugin *audioUnitPlugin = [AudioUnitPlugin sharedInstance];
        [audioUnitPlugin AvAudioPlayerPlayWaveFile];
    }
}

- (IBAction)btnStopAudio:(id)sender {
    if(usedTools == EnumAudioUnit) {
        AudioUnitPlugin *audioUnitPlugin = [AudioUnitPlugin sharedInstance];
        [audioUnitPlugin AvAudioPlayerStopPlayWaveFile];
    }
}

@end
