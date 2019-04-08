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
    [self loadDeviceInfo];
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

- (IBAction)btnUpdateAudioTool:(id)sender {
    NSString * selectedTool = [btnAudioTools titleOfSelectedItem];
    [btnAudioTools setTitle:selectedTool];
    if([selectedTool isEqualToString:@"Port Audio"]) {
        usedTools = EnumPortAudio;
        [btnInputDevices setEnabled:true];
    } else if([selectedTool isEqualToString:@"Audio Unit"]) {
        usedTools = EnumAudioUnit;
        [btnInputDevices setEnabled:false];
    } else if([selectedTool isEqualToString:@"AVFoundation"]) {
        usedTools = EnumAVFoundation;
        [btnInputDevices setEnabled:false];
    }
}

- (IBAction)btnUpdateInputDevice:(id)sender {
}

- (void)loadDeviceInfo {
    PaError err = Pa_Initialize();
    if( err != paNoError ) {
        fprintf(stderr, "Hauoli - Fail to initialize PortAudio.\n");
        fflush(stderr);
        Pa_Terminate();
        return;
    }
    
    int numDevices;
    numDevices = Pa_GetDeviceCount();
    if( numDevices < 0 )
    {
        printf("Hauoli - ERROR: Pa_CountDevices returned 0x%x\n", numDevices);
        Pa_Terminate();
        return;
    }
    
    printf("\n\n\nNumber of devices = %d\n\n\n", numDevices );
    
    const PaDeviceInfo *deviceInfo;
    PaStreamParameters inputParameters, outputParameters;
    for( int i=0; i<numDevices; i++ )
    {
        deviceInfo = Pa_GetDeviceInfo( i );
        printf( "----------------------------------\n");
        printf( "------------ device %d -----------\n", i );
        printf( "----------------------------------\n");
        /* Mark global and API specific default devices */
        int defaultDisplayed = 0;
        if( i == Pa_GetDefaultInputDevice() )
        {
            printf("##########################\n");
            printf( "##### Default Input #####\n" );
            printf("##########################\n\n");
            defaultDisplayed = 1;
        } else if( i == Pa_GetHostApiInfo( deviceInfo->hostApi )->defaultInputDevice ) {
            const PaHostApiInfo *hostInfo = Pa_GetHostApiInfo( deviceInfo->hostApi );
            printf( "Default %s Input", hostInfo->name );
            defaultDisplayed = 1;
        }
        
        if( i == Pa_GetDefaultOutputDevice() )
        {
            printf( (defaultDisplayed ? "," : "") );
            printf("##########################\n");
            printf( "##### Default Output #####\n" );
            printf("##########################\n");
            defaultDisplayed = 1;
        } else if( i == Pa_GetHostApiInfo( deviceInfo->hostApi )->defaultOutputDevice ) {
            const PaHostApiInfo *hostInfo = Pa_GetHostApiInfo( deviceInfo->hostApi );
            printf( (defaultDisplayed ? "," : "") );
            printf( "Default %s Output", hostInfo->name );
            defaultDisplayed = 1;
        }
        
        /* print device info fields */
        printf( "Name                        = %s\n", deviceInfo->name );
        printf( "Host API                    = %s\n",  Pa_GetHostApiInfo( deviceInfo->hostApi )->name );
        printf( "Max input channels = %d", deviceInfo->maxInputChannels  );
        printf( ", Max output channels = %d\n", deviceInfo->maxOutputChannels  );
        printf( "Default low input latency   = %8.4f\n", deviceInfo->defaultLowInputLatency  );
        printf( "Default low output latency  = %8.4f\n", deviceInfo->defaultLowOutputLatency  );
        printf( "Default high input latency  = %8.4f\n", deviceInfo->defaultHighInputLatency  );
        printf( "Default high output latency = %8.4f\n", deviceInfo->defaultHighOutputLatency  );
        printf( "Default sample rate         = %8.2f\n", deviceInfo->defaultSampleRate );
        /* poll for standard sample rates */
        inputParameters.device = i;
        inputParameters.channelCount = deviceInfo->maxInputChannels;
        inputParameters.sampleFormat = paInt16;
        inputParameters.suggestedLatency = 0; /* ignored by Pa_IsFormatSupported() */
        inputParameters.hostApiSpecificStreamInfo = NULL;
        outputParameters.device = i;
        outputParameters.channelCount = deviceInfo->maxOutputChannels;
        outputParameters.sampleFormat = paInt16;
        outputParameters.suggestedLatency = 0; /* ignored by Pa_IsFormatSupported() */
        outputParameters.hostApiSpecificStreamInfo = NULL;
        if( inputParameters.channelCount > 0 )
        {
            printf("Supported standard sample rates\n for half-duplex 16 bit %d channel input = \n", inputParameters.channelCount );
            PrintSupportedStandardSampleRates( &inputParameters, NULL );
        }
        
        if( outputParameters.channelCount > 0 )
        {
            printf("Supported standard sample rates\n for half-duplex 16 bit %d channel output = \n", outputParameters.channelCount );
            PrintSupportedStandardSampleRates( NULL, &outputParameters );
        }
        
        if( inputParameters.channelCount > 0 && outputParameters.channelCount > 0 )
        {
            printf("Supported standard sample rates\n for full-duplex 16 bit %d channel input, %d channel output = \n", inputParameters.channelCount, outputParameters.channelCount );
            PrintSupportedStandardSampleRates( &inputParameters, &outputParameters );
        }
    }
    
    Pa_Terminate();
    printf("\n----------------------------\n\n");
}

@end

// ========================================
#pragma mark - C functions
// ========================================
void PrintSupportedStandardSampleRates( const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters )
{
    static double standardSampleRates[] = {
        8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0, 44100.0, 48000.0, 88200.0, 96000.0, 192000.0, -1 /* negative terminated  list */
    };
    int     i, printCount;
    PaError err;
    
    printCount = 0;
    for( i=0; standardSampleRates[i] > 0; i++ )
    {
        err = Pa_IsFormatSupported( inputParameters, outputParameters, standardSampleRates[i] );
        if( err == paFormatIsSupported )
        {
            if( printCount == 0 )
            {
                printf( "\t%8.2f", standardSampleRates[i] );
                printCount = 1;
            }
            else if( printCount == 4 )
            {
                printf( ",\n\t%8.2f", standardSampleRates[i] );
                printCount = 1;
            } else {
                printf( ", %8.2f", standardSampleRates[i] );
                ++printCount;
            }
        }
    }
    
    if( !printCount ) {
        printf( "None\n" );
    } else {
        printf( "\n" );
    }
}

