//
//  AudioUtils.hpp
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/14/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//


#ifndef AudioUtils_hpp
#define AudioUtils_hpp

#include <stdio.h>
#include <stdint.h>
#include <string.h>

// Convert audio data in float to int16
void tdav_codec_float_to_int16 (void *pInput, void* pOutput, uint8_t* pu1SampleSz, uint32_t* pu4TotalSz, bool bFloat);
// Convert audio data in int64 to float
void tdav_codec_int16_to_float (void *pInput, void* pOutput, uint8_t* pu1SampleSz, uint32_t* pu4TotalSz, bool bInt16);


#endif /* AudioUtils_hpp */
