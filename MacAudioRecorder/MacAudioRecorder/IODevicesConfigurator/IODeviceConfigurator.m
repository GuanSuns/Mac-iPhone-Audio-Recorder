//
//  IODeviceConfigurator.m
//  MacAudioRecorder
//
//  Created by Lin Guan on 5/1/19.
//  Copyright © 2019 Lin Guan. All rights reserved.
//

#import "IODeviceConfigurator.h"

// ===================================================
#pragma mark - Use Core Audio to set the format of output device
// ===================================================
bool coreAudioConfigIODevices() {
    AudioObjectPropertyAddress  propertyAddress;
    AudioObjectID               *deviceIDs;
    UInt32                      propertySize;
    NSInteger                   numDevices;
    
    
    propertyAddress.mSelector = kAudioHardwarePropertyDevices;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    
    // enumerate all current/valid devices
    if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize) == noErr)
    {
        numDevices = propertySize / sizeof(AudioDeviceID);
        NSLog(@"Hauoli - Number of devices: %d", (int)numDevices);
        deviceIDs = (AudioDeviceID *)calloc(numDevices, sizeof(AudioDeviceID));
        
        if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, deviceIDs) == noErr)
        {
            AudioObjectPropertyAddress      deviceAddress;
            char                            deviceName[64];
            char                            manufacturerName[64];
            
            // Print out all the output device info
            // numDevices should be 2 since Mac only allow configure the default IO devices
            for (NSInteger idx=0; idx<numDevices; idx++) {
                propertySize = sizeof(deviceName);
                deviceAddress.mSelector = kAudioDevicePropertyDeviceName;
                deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
                deviceAddress.mElement = kAudioObjectPropertyElementMaster;
                
                // Fetch device detail
                if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, deviceName) == noErr)
                {
                    propertySize = sizeof(manufacturerName);
                    deviceAddress.mSelector = kAudioDevicePropertyDeviceManufacturer;
                    deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
                    deviceAddress.mElement = kAudioObjectPropertyElementMaster;
                    
                    if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, manufacturerName) == noErr)
                    {
                        CFStringRef uidString;
                        
                        propertySize = sizeof(uidString);
                        deviceAddress.mSelector = kAudioDevicePropertyDeviceUID;
                        deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
                        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
                        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, &uidString) == noErr) {
                            
                            NSLog(@"IO device name: %s, manufacturer: %s, id: %@", deviceName, manufacturerName, uidString);
                            CFRelease(uidString);
                            
                            // Set the sample rate of the device
                            UInt32 size = sizeof(Float64);
                            Float64 sampleRate = IO_DEVICE_SAMPLE_RATE;
                            OSStatus err = noErr;
                            
                            AudioObjectPropertyAddress deviceSampleRateAddress = { kAudioDevicePropertyNominalSampleRate, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
                            err = AudioObjectSetPropertyData(deviceIDs[idx], &deviceSampleRateAddress, 0, NULL, size, &sampleRate);
                            
                            if(err != noErr) {
                                NSLog(@"Hauoli - Fail to set smaple rate of the IO device: %s.", deviceName);
                            }
                        }
                    }
                }
            }
        }
        
        free(deviceIDs);
    }
    return false;
}


// ===================================================
#pragma mark - Use PortAudio to list all IO devices
// ===================================================
void printSupportedStandardSampleRates( const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters )
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

void loadIODeviceInfo() {
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
            printSupportedStandardSampleRates( &inputParameters, NULL );
        }
        
        if( outputParameters.channelCount > 0 )
        {
            printf("Supported standard sample rates\n for half-duplex 16 bit %d channel output = \n", outputParameters.channelCount );
            printSupportedStandardSampleRates( NULL, &outputParameters );
        }
        
        if( inputParameters.channelCount > 0 && outputParameters.channelCount > 0 )
        {
            printf("Supported standard sample rates\n for full-duplex 16 bit %d channel input, %d channel output = \n", inputParameters.channelCount, outputParameters.channelCount );
            printSupportedStandardSampleRates( &inputParameters, &outputParameters );
        }
    }
    
    Pa_Terminate();
    printf("\n----------------------------\n\n");
}

