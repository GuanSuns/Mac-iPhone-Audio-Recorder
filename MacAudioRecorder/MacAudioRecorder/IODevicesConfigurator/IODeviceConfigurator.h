//
//  IODeviceConfigurator.h
//  MacAudioRecorder
//
//  Created by Lin Guan on 5/1/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#include <CoreAudio/CoreAudio.h>
#import <Foundation/Foundation.h>
#import <portaudio.h>

#ifndef IODeviceConfigurator_h
#define IODeviceConfigurator_h

#define IO_DEVICE_SAMPLE_RATE  (96000)

void printSupportedStandardSampleRates( const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters );
void loadIODeviceInfo(void);

bool coreAudioConfigIODevices(void);

#endif /* IODeviceConfigurator_h */
