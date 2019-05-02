//
//  IODeviceConfigurator.h
//  MacAudioRecorder
//
//  Created by Lin Guan on 5/1/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <portaudio.h>

#ifndef IODeviceConfigurator_h
#define IODeviceConfigurator_h

void printSupportedStandardSampleRates( const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters );
void loadIODeviceInfo(void);

#endif /* IODeviceConfigurator_h */
