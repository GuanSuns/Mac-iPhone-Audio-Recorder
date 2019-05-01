//
//  WavFileProcessor.m
//  MacAudioRecorder
//
//  Created by Lin Guan on 4/30/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import "WavFileProcessor.h"

void readWavToPCM(int16_t* ptrWrite, int16_t* wavData, int dataSize) {
    int nHeaderDataToSkip = (int)(sizeof(WAV_HEADER)/sizeof(int16_t));
    for(int i=0; i<nHeaderDataToSkip; i++) {
        wavData++;
    }
    
    for(int i=0; i<dataSize; i++) {
        *ptrWrite++ = *wavData++;
    }
}

