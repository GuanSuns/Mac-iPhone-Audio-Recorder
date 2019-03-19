//
//  AudioUtils.cpp
//  MacAudioRecorder
//
//  Created by Lin Guan on 3/14/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#include "AudioUtils.hpp"

// Convert audio data in float to int16
void tdav_codec_float_to_int16 (void *pInput, void* pOutput, uint8_t* pu1SampleSz, uint32_t* pu4TotalSz, bool bFloat)
{
    int16_t i2SampleNumTotal = *pu4TotalSz / *pu1SampleSz;  //
    int16_t *pi2Buf = (int16_t *)pOutput;
    if (!pInput || !pOutput) {
        return;
    }
    
    if (bFloat && *pu1SampleSz == 4) {
        float* pf4Buf = (float*)pInput;
        for (int i = 0; i < i2SampleNumTotal; i++) {
            pi2Buf[i] = (int16_t)(pf4Buf[i] * 32767 + 0.5); // float -> int16 + rounding
        }
        *pu4TotalSz /= 2;     // transfer to int16 byte size
        *pu1SampleSz /= 2;
    }
    if (!bFloat && *pu1SampleSz == 2) {
        memcpy (pOutput, pInput, *pu4TotalSz);
    }
    return;
}

// Convert audio data in int16 to float
void tdav_codec_int16_to_float (void *pInput, void* pOutput, uint8_t* pu1SampleSz, uint32_t* pu4TotalSz, bool bInt16)
{
    int16_t i2SampleNumTotal = *pu4TotalSz / *pu1SampleSz;
    float *pf4Buf = (float *)pOutput;
    if (!pInput || !pOutput) {
        return;
    }
    
    if ( bInt16 && *pu1SampleSz == 2) {
        int16_t* pi2Buf = (int16_t*)pInput;
        for (int i = 0; i < i2SampleNumTotal; i++) {
            pf4Buf[i] =    (float)pi2Buf[i] / 32767 ;  // int16 -> float
        }
        *pu4TotalSz *= 2;     // transfer to int16 byte size
        *pu1SampleSz *= 2;
    }
    if (!bInt16 && *pu1SampleSz == 4) {     // if it's float, copy the data directly
        memcpy (pOutput, pInput, *pu4TotalSz);
    }
    return;
}

