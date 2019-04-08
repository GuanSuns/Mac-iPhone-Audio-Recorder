//
//  PortAudioPlugin.m
//  MacAudioRecorder
//
//  Created by Lin Guan on 4/7/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import "PortAudioPlugin.h"

PaStream *in_stream;
PaStream *out_stream;
paUserData userData;

// ===================================================
#pragma mark - Record Callback
// ===================================================
/* This routine will be called by the PortAudio engine when audio is needed.
 ** It may be called at interrupt level on some machines so don't do anything
 ** that could mess up the system like calling malloc() or free().
 */
int recordCallback( const void *inputBuffer, void *outputBuffer,
                   unsigned long framesCount,
                   const PaStreamCallbackTimeInfo* timeInfo,
                   PaStreamCallbackFlags statusFlags,
                   void *userData )
{
    // Save the recorded data to userData so that we can save it to file later
    paUserData *pUserData = (paUserData*)userData;
    if(WRITE_TO_FILE && (pUserData->recordFrameIndex + framesCount < pUserData->maxFrameIndex)) {
        const SAMPLE *ptrRead = (const SAMPLE*)inputBuffer;
        SAMPLE *ptrWrite = &pUserData->recordedSamples[pUserData->recordFrameIndex * NUM_CHANNELS];
        if( inputBuffer == NULL )
        {
            for( long i=0; i<framesCount; i++ )
            {
                *ptrWrite++ = SAMPLE_SILENCE;  /* left */
                if( NUM_CHANNELS == 2 ) *ptrWrite++ = SAMPLE_SILENCE;  /* right */
            }
        } else {
            for(long i=0; i<framesCount; i++ )
            {
                *ptrWrite++ = *ptrRead++;  /* left */
                if( NUM_CHANNELS == 2 ) *ptrWrite++ = *ptrRead++;  /* right */
            }
        }
        pUserData->recordFrameIndex += framesCount;
    }
    
    return paContinue;
}

// ===================================================
#pragma mark - Play Callback
// ===================================================
/* This routine will be called by the PortAudio engine when audio is needed.
 ** It may be called at interrupt level on some machines so don't do anything
 ** that could mess up the system like calling malloc() or free().
 */
int playCallback( const void *inputBuffer, void *outputBuffer,
                 unsigned long framesCount,
                 const PaStreamCallbackTimeInfo* timeInfo,
                 PaStreamCallbackFlags statusFlags,
                 void *userData )
{
    paUserData *pUserData = (paUserData*)userData;
    long totalFrames = 10*48000*1;
    long playFrameIndex = pUserData->playFrameIndex;
    
    int16_t * playedData = pUserData->playedSamples;
    int16_t *ptrWrite = (int16_t*)outputBuffer;
    
    if(playedData == NULL) {
        for(long i=0; i<framesCount; i++ ) {
            *ptrWrite++ = (int16_t) SAMPLE_SILENCE;
        }
        return paComplete;
    } else {
        // move the play data pointer to expected pos
        playedData = playedData + playFrameIndex;
        // write the data to output stream
        for(long i=0; i<framesCount; i++ ) {
            *ptrWrite++ = *playedData++;
            playFrameIndex++;
            
            if(playFrameIndex == totalFrames-1) {
                playFrameIndex = 0;
                playedData = pUserData->playedSamples;
            }
        }
        // save the new playFrameIndex
        pUserData->playFrameIndex = playFrameIndex;
    }
    
    return paContinue;
}

// ===================================================
#pragma mark - Initialization
// ===================================================
int initPortAudio(void)
{
    PaStreamParameters  inputParameters, outputParameters;
    PaError             err = paNoError;
    
    int initUserDataResult = initPaUserData(&userData);
    if(!initUserDataResult) {
        fprintf(stderr, "Hauoli - Fail to initialize userData.\n");
        fflush(stderr);
        return 0;
    }
    
    err = Pa_Initialize();
    if( err != paNoError ) {
        fprintf(stderr, "Hauoli - Fail to initialize PortAudio.\n");
        fflush(stderr);
        return 0;
    }
    
    /* ------------------------------------------------- */
    /* ---------------  Init Input Stream  ------------- */
    /* ------------------------------------------------- */
    inputParameters.device = Pa_GetDefaultInputDevice(); /* default input device */
    if (inputParameters.device == paNoDevice) {
        fprintf(stderr, "Hauoli - No default input device.\n");
        fflush(stderr);
        return 0;
    }
    inputParameters.channelCount = NUM_CHANNELS;
    inputParameters.sampleFormat = PA_SAMPLE_TYPE;
    inputParameters.suggestedLatency = Pa_GetDeviceInfo( inputParameters.device )->defaultLowInputLatency;
    inputParameters.hostApiSpecificStreamInfo = NULL;
    
    printf("Hauoli - Init input stream.\n");
    fflush(stdout);
    
    err = Pa_OpenStream(&in_stream,
                        &inputParameters,
                        NULL,                  /* &outputParameters, */
                        SAMPLE_RATE,
                        FRAMES_PER_BUFFER,
                        paClipOff,      /* we won't output out of range samples so don't bother clipping them */
                        recordCallback,
                        &userData);
    if( err != paNoError ) {
        fprintf(stderr, "Hauoli - Fail to open input stream.\n");
        fflush(stderr);
        return 0;
    }
    
    /* -------------------------------------------------- */
    /* ---------------  Init Output Stream  ------------- */
    /* -------------------------------------------------- */
    outputParameters.device = Pa_GetDefaultOutputDevice(); /* default output device */
    if (outputParameters.device == paNoDevice) {
        fprintf(stderr, "Hauoli - No default output device.\n");
        fflush(stderr);
        return 0;
    }
    outputParameters.channelCount = 1;
    outputParameters.sampleFormat =  paInt16;
    outputParameters.suggestedLatency = Pa_GetDeviceInfo( outputParameters.device )->defaultLowOutputLatency;
    outputParameters.hostApiSpecificStreamInfo = NULL;
    
    printf("Hauoli - Init output stream.\n");
    fflush(stdout);
    
    err = Pa_OpenStream( &out_stream,
                        NULL, /* no input */
                        &outputParameters,
                        48000,
                        FRAMES_PER_BUFFER,
                        paClipOff,      /* we won't output out of range samples so don't bother clipping them */
                        playCallback,
                        &userData );
    if( err != paNoError ) {
        fprintf(stderr, "Hauoli - Fail to open output stream.\n");
        fflush(stderr);
        return 0;
    }
    
    /* --------------------------------------------------- */
    /* ---------------  Start Output Stream  ------------- */
    /* --------------------------------------------------- */
    err = Pa_StartStream(out_stream);
    if (err != paNoError) {
        fprintf(stderr, "Hauoli - Fail to start output stream.\n");
        fflush(stderr);
        return 0;
    }
    
    return 1;
}

// ===================================================
#pragma mark - Start recording and playing
// ===================================================
void portAudioStartRecording(void)
{
    PaError err = paNoError;
    if(initPortAudio()) {
        err = Pa_StartStream(in_stream);
        if (err != paNoError) {
            fprintf(stderr, "Hauoli - Fail to start input stream.\n");
            fflush(stderr);
            
            portAudioStopRecording();
            return;
        }
        
        printf("Hauoli - Now recording, please speak into the microphone.\n");
        fflush(stdout);
    }
}

// ===================================================
#pragma mark - Stop recording and playing
// ===================================================
void portAudioStopRecording(void) {
    if(in_stream != NULL) {
        Pa_CloseStream(in_stream);
    }
    
    if(out_stream != NULL) {
        Pa_CloseStream(out_stream);
    }
    
    Pa_Terminate();
    
    /* Write recorded data to a file. */
#if WRITE_TO_FILE
    {
        FILE  *fid;
        fid = fopen("/tmp/recorded.pcm", "wb");
        if( fid == NULL )
        {
            printf("Hauoli - Could not open file.");
        } else if(userData.recordedSamples != NULL) {
            fwrite( userData.recordedSamples, NUM_CHANNELS * sizeof(SAMPLE), userData.totalFrames, fid );
            fclose( fid );
            printf("Hauoli - Wrote data to '/tmp/recorded.pcm'\n");
        }
    }
#endif
    
    if(userData.recordedSamples) {
        free( userData.recordedSamples);
        userData.recordedSamples = NULL;
    }
    if(userData.playedSamples) {
        free( userData.playedSamples);
        userData.playedSamples = NULL;
    }
    
    printf("Hauoli - Stop recording.\n");
    fflush(stdout);
}


// ===================================================
#pragma mark - Internal Functions
// ===================================================
int initPaUserData(paUserData * userData)
{
    long                totalFrames;
    long                numSamples;
    long                numBytes;
    
    // init user data (used to save audio to file)
    userData->maxFrameIndex = NUM_SECONDS * SAMPLE_RATE; /* Record for a few seconds. */
    totalFrames = userData->maxFrameIndex;
    userData->totalFrames = totalFrames;
    userData->recordFrameIndex = 0;
    numSamples = totalFrames * NUM_CHANNELS;
    numBytes = numSamples * sizeof(SAMPLE);
    userData->recordedSamples = (SAMPLE *) malloc(numBytes);
    
    if(userData->recordedSamples == NULL) {
        printf("Hauoli - Could not allocate record array.\n");
        fflush(stdout);
        return 0;
    }
    for(int i=0; i<numSamples; i++ ) {
        userData->recordedSamples[i] = 0;
    }
    
    return 1;
}

@implementation PortAudioPlugin

static PortAudioPlugin *_sharedInstance;

+(PortAudioPlugin*) sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"Hauoli - Creating PortAudioPlugin shared instance.");
        _sharedInstance = [[PortAudioPlugin alloc] init];
    });
    return _sharedInstance;
}

// ========================================
#pragma mark - Initialization
// ========================================
- (id) init {
    self = [super init];
    return self;
}

// ========================================
#pragma mark - Load Play Audio
// ========================================
- (void) LoadPlayedSample
{
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/played.pcm",[[NSBundle mainBundle] resourcePath]];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSData *dataBuffer = [NSData dataWithContentsOfURL:soundFileURL];
    
    int16_t *values = (int16_t *)[dataBuffer bytes];
    userData.playedSamples = (int16_t *) malloc(10*48000*1*sizeof(int16_t));
    if(userData.playedSamples == NULL) {
        printf("Hauoli - Could not allocate play array.\n");
        fflush(stdout);
        return;
    }
    
    int16_t* ptrWrite = userData.playedSamples;
    for(long i=0; i<10*48000*1; i++) {
        *ptrWrite++ = *values++;
    }
    
    userData.playFrameIndex = 0;
}

// ========================================
#pragma mark - Start
// ========================================
- (void) StartAudioRecordAndPlay
{
    [self LoadPlayedSample];
    portAudioStartRecording();
}

// ========================================
#pragma mark - Stop
// ========================================
- (void) StopAudioRecordAndPlay
{
    portAudioStopRecording();
}

@end
