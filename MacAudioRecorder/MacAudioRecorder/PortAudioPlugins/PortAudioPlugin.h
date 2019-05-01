//
//  PortAudioPlugin.h
//  MacAudioRecorder
//
//  Created by Lin Guan on 4/7/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <portaudio.h>
#include "WavFileProcessor.h"

NS_ASSUME_NONNULL_BEGIN

#define PORTAUDIO_SAMPLE_RATE  (96000)
#define NUM_CHANNELS    (1)
#define FRAMES_PER_BUFFER (512)
#define NUM_SECONDS     (20)
/* #define DITHER_FLAG     (paDitherOff) */
#define DITHER_FLAG     (0)
/** Set to 1 if you want to capture the recording to a file. */
#define WRITE_TO_FILE   (1)
/* Select sample format for recording: Int16 or Float32 */
#if 1
#define PA_SAMPLE_TYPE  paInt16
typedef int16_t SAMPLE;
#define SAMPLE_SILENCE  (0)
#define PRINTF_S_FORMAT "%d"
#elif 0
#define PA_SAMPLE_TYPE  paFloat32
typedef float SAMPLE;
#define SAMPLE_SILENCE  (0.0f)
#define PRINTF_S_FORMAT "%.8f"
#endif

typedef struct
{
    long         recordFrameIndex;
    long         maxFrameIndex;
    long         totalFrames;
    SAMPLE      *recordedSamples;
    long        playFrameIndex;
    int16_t      *playedSamples;
} paUserData;

/* -------------------------------------------------- */
/* -------------  Prototype of C functions  --------- */
/* -------------------------------------------------- */
void portAudioStopRecording(void);
void portAudioStartRecording(void);
int initPortAudio(void);
int initPaUserData(paUserData*);
int recordCallback( const void *, void *,
                   unsigned long,
                   const PaStreamCallbackTimeInfo*,
                   PaStreamCallbackFlags,
                   void *);
int playCallback( const void *, void *,
                 unsigned long,
                 const PaStreamCallbackTimeInfo *,
                 PaStreamCallbackFlags,
                 void *);


/* -------------------------------------------------- */
/* ------------  PortAudioPlugin Interfaces  -------- */
/* -------------------------------------------------- */
@interface PortAudioPlugin : NSObject

+ (PortAudioPlugin*) sharedInstance;
- (void) StartAudioRecordAndPlay;
- (void) StopAudioRecordAndPlay;

@end

NS_ASSUME_NONNULL_END
