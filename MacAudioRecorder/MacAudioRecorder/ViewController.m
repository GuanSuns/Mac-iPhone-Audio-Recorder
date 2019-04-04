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
    useAudioUnit = false;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)btnStartRecord:(id)sender {
    if(useAudioUnit) {
        AudioUnitPlugin *audioUnitPlugin = [AudioUnitPlugin sharedInstance];
        [audioUnitPlugin StartAudioRecordAndPlay];
    } else {
        AudioPlugin * audioPlugin = [AudioPlugin sharedInstance];
        [audioPlugin audioPluginStartRecord];
    }
}

- (IBAction)btnStopRecord:(id)sender {
    if(useAudioUnit) {
        AudioUnitPlugin *audioUnitPlugin = [AudioUnitPlugin sharedInstance];
        [audioUnitPlugin StopAudioRecordAndPlay];
    } else {
        AudioPlugin * audioPlugin = [AudioPlugin sharedInstance];
        [audioPlugin audioPluginStopRecord];
    }
}

- (IBAction)btnPlayAudio:(id)sender {
    if(useAudioUnit) {
        AudioUnitPlugin *audioUnitPlugin = [AudioUnitPlugin sharedInstance];
        [audioUnitPlugin AvAudioPlayerPlayWaveFile];
    }
}

- (IBAction)btnStopAudio:(id)sender {
    if(useAudioUnit) {
        AudioUnitPlugin *audioUnitPlugin = [AudioUnitPlugin sharedInstance];
        [audioUnitPlugin AvAudioPlayerStopPlayWaveFile];
    }
}

@end
