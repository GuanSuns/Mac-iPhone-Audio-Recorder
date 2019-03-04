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
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)btnStartRecord:(id)sender {
    AudioPlugin * audioPlugin = [AudioPlugin sharedInstance];
    [audioPlugin audioPluginStartRecord];
}

- (IBAction)btnStopRecord:(id)sender {
    AudioPlugin * audioPlugin = [AudioPlugin sharedInstance];
    [audioPlugin audioPluginStopRecord];
}
@end
