/*
 * TeamSpeak 3 client sample
 *
 * Copyright (c) 2007-2013 TeamSpeak Systems GmbH
 */

#import "AudioIO.h"
#import "CAAudioBufferList.h"

@interface AudioIO ()

- (void) enableRecording;
- (void) enablePlayback;
- (void) initAudioFormat;
- (void) initCallbacks;
- (void) allocateInputBuffers:(UInt32)inNumberFrames;

- (void) setupRemoteIO;
- (void) setupAudioSession;

@end

static OSStatus	AudioInCallback(void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData)
{
	AudioIO *audioIO = (__bridge AudioIO *)inRefCon;
    
    if (audioIO.inputBufferList == NULL)
    {
        [audioIO allocateInputBuffers:inNumberFrames];
    }
    
    // fill buffer list with recorded samples
    OSStatus status = AudioUnitRender(audioIO.audioUnit, 
                                      ioActionFlags, 
                                      inTimeStamp, 
                                      inBusNumber, 
                                      inNumberFrames, 
                                      audioIO.inputBufferList);
    if (status != noErr)
    {
        return status;
    }
    
    // Inform our delegate we got new audio
    [audioIO.delegate audioIO:audioIO processAudioFromMicrophone:audioIO.inputBufferList];
			
	return noErr;
}

static OSStatus	AudioOutCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
	AudioIO *audioIO = (__bridge AudioIO *)inRefCon;
	
    [audioIO.delegate audioIO:audioIO processAudioToSpeaker:ioData];
			
	return noErr;
}

#pragma mark -
#pragma mark AudioIO

@implementation AudioIO

@synthesize audioUnit;
@synthesize delegate;
@synthesize started;
@synthesize inputBufferList;


-(instancetype) initWithAllowRecord:(BOOL) allowRecord
{
	if ((self = [super init]))
    {
        _allowRecord = allowRecord;
        _deviceID = [[NSUUID UUID] UUIDString];
        _deviceDisplayName = @kWaveDeviceDisplayName;
        
        _sampleRate = AUDIO_SAMPLE_RATE;
        _numChannels = AUDIO_NUM_CHANNELS;
        
        started = NO;
        
        [self setupAudioSession];
        [self setupRemoteIO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(routeChangeHandler:)
													 name:AVAudioSessionRouteChangeNotification
												   object:[AVAudioSession sharedInstance]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(interruptionHandler:)
													 name:AVAudioSessionInterruptionNotification
												   object:[AVAudioSession sharedInstance]];
	}
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    AudioComponentInstanceDispose(audioUnit);
    
    //AudioUnitUninitialize(audioUnit);
    
    // free input buffer list used to retrieve recorded data
    if (inputBufferList)
    {
        for (UInt32 i = 0; i < inputBufferList->mNumberBuffers; i++)
        {
            free (inputBufferList->mBuffers[i].mData);
        }
        CAAudioBufferList::Destroy(inputBufferList);
        inputBufferList = NULL;
    }
}

#pragma mark - AVAudioSession Notifications

- (void)routeChangeHandler:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    
    if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == reasonValue)
	{
		NSLog(@"AVAudioSessionRouteChangeNotification: New Device Available");
        
	}
	else if (AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reasonValue)
	{
		NSLog(@"AVAudioSessionRouteChangeNotification: Old Device Unavailable");
    }
    else
    {
        NSLog(@"AVAudioSessionRouteChangeNotification: %i", reasonValue);
    }
    
    if (started)
    {
        // This will invalidate the input buffer and allocate a new one, with adjusted frame capacity.
        // We might get a different amount of frames each time a new device becomes active.
        [self stop];
        [self start];
    }
		
}

- (void)interruptionHandler:(NSNotification *)notification
{
    // Handle interruptions in here, like an incoming call or a siri session
    
    UInt8 typeValue = [[notification.userInfo valueForKey: AVAudioSessionInterruptionTypeKey] intValue];
    
    if (AVAudioSessionInterruptionTypeBegan == typeValue)
    {
       	NSLog(@"AVAudioSession interruption began.");

        [self.delegate audioWillStop:self];
    }
    else if (AVAudioSessionInterruptionTypeEnded == typeValue) // For a phone call, may not get this.
    {
       	NSLog(@"AVAudioSession interruption ended.");
        
        [self.delegate audioWillStart:self];
    }
}

#pragma mark -

- (void)setupRemoteIO
{
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio unit
    OSStatus status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    if (status != noErr)
    {
        printf("AudioIO could not create new audio component: status = %i\n", status);
    }
    
    [self enableRecording];
    [self enablePlayback];
    [self initAudioFormat];
    [self initCallbacks];
    
    // initialize
    status = AudioUnitInitialize(audioUnit);
    if (status != noErr)
    {
        printf("AudioIO could not initialize audio unit: status = %i\n", status);
    }    
}

- (void)setupAudioSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *errRet = nil;
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers;// | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker;
    
    
    [session setCategory:self.allowRecord ? AVAudioSessionCategoryPlayAndRecord : AVAudioSessionCategoryPlayback withOptions:options error:&errRet];
   
    
    if (errRet)
        NSLog(@"Error in AudioIO::init::setCategory %@",[errRet localizedDescription]);
    
    [session setMode:self.allowRecord ? AVAudioSessionModeVoiceChat : AVAudioSessionModeSpokenAudio error:&errRet];
    
    if (errRet)
        NSLog(@"Error in AudioIO::interruptionHandler::setMode %@",[errRet localizedDescription]);
    
    // Try to set our preferred sample rate or the SDK will resample to 48kHz
    // and it's more efficient to let iOS do it.
    [session setPreferredSampleRate:AUDIO_SAMPLE_RATE error:&errRet];
    if (errRet)
        NSLog(@"Error in AudioIO::init::setPreferredSampleRate %@",[errRet localizedDescription]);
    
				
    [session setActive:YES error:&errRet];
    if (errRet)
        NSLog(@"Error in AudioIO::init::setActive %@",[errRet localizedDescription]);
    
    NSLog(@"setupAudoSession");
}

- (void)enableRecording
{
    
    if(!self.allowRecord) {
        return;
    }
    // Enable IO for recording
    UInt32 flag = 1;
    OSStatus status = AudioUnitSetProperty(audioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Input,
                                           AUDIO_INPUT_BUS,
                                           &flag,
                                           sizeof(flag));
    if (status != noErr)
    {
        printf("AudioIO enable_recording failed: status = %i\n", status);
    }
}

- (void)enablePlayback
{
    // enable IO for playback
    UInt32 flag = 1;
    OSStatus status = AudioUnitSetProperty(audioUnit, 
                                           kAudioOutputUnitProperty_EnableIO, 
                                           kAudioUnitScope_Output, 
                                           AUDIO_OUTPUT_BUS,
                                           &flag, 
                                           sizeof(flag));
    if (status != noErr)
    {
        printf("AudioIO enable_playback failed: status = %i\n", status);
    }
}

- (void)initAudioFormat
{
    // describe format
    FillOutASBDForLPCM(audioFormat, AUDIO_SAMPLE_RATE, AUDIO_NUM_CHANNELS, AUDIO_BIT_DEPTH, AUDIO_BIT_DEPTH, false, false, AUDIO_FORMAT_IS_NONINTERLEAVED);
    
    // Apply output format
    OSStatus status = AudioUnitSetProperty(audioUnit, 
                                           kAudioUnitProperty_StreamFormat, 
                                           kAudioUnitScope_Output, 
                                           AUDIO_INPUT_BUS, 
                                           &audioFormat, 
                                           sizeof(audioFormat));
    if (status != noErr)
    {
        printf("AudioIO init_audio_format could not set output format: status = %i\n", status);
    }
    
    // Apply input format
    status = AudioUnitSetProperty(audioUnit, 
                                  kAudioUnitProperty_StreamFormat, 
                                  kAudioUnitScope_Input, 
                                  AUDIO_OUTPUT_BUS, 
                                  &audioFormat, 
                                  sizeof(audioFormat));
    if (status != noErr)
    {
        printf("AudioIO init_audio_format could not set input format: status = %i\n", status);
    }
}

- (void)initCallbacks
{
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    
    callbackStruct.inputProc = AudioInCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    
    OSStatus status = AudioUnitSetProperty(audioUnit, 
                                           kAudioOutputUnitProperty_SetInputCallback, 
                                           kAudioUnitScope_Global, 
                                           AUDIO_INPUT_BUS, 
                                           &callbackStruct, 
                                           sizeof(callbackStruct));
    if (status != noErr)
    {
        printf("AudioIO init_callbacks could not set input callback: status = %i\n", status);
    }
    
    // Set output callback
    callbackStruct.inputProc = AudioOutCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    
    status = AudioUnitSetProperty(audioUnit, 
                                  kAudioUnitProperty_SetRenderCallback, 
                                  kAudioUnitScope_Global, 
                                  AUDIO_OUTPUT_BUS,
                                  &callbackStruct, 
                                  sizeof(callbackStruct));
    if (status != noErr)
    {
        printf("AudioIO init_callbacks could not set output callback: status = %i\n", status);
    }
}

- (void) allocateInputBuffers:(UInt32)inNumberFrames
{
    printf("AudioIO allocate_input_buffers: inNumberFrames = %i\n", inNumberFrames);
    
    UInt32 bufferSizeInBytes = inNumberFrames * (AUDIO_FORMAT_IS_NONINTERLEAVED ? AUDIO_BIT_DEPTH_IN_BYTES :  (AUDIO_BIT_DEPTH_IN_BYTES * AUDIO_NUM_CHANNELS));
    
    // allocate buffer list
    inputBufferList = CAAudioBufferList::Create(inNumberFrames);
    
    inputBufferList->mNumberBuffers = AUDIO_FORMAT_IS_NONINTERLEAVED ? AUDIO_NUM_CHANNELS : 1;
    
    for (UInt32 i = 0; i < inputBufferList->mNumberBuffers; i++)
    {
        printf("AudioIO allocate_input_buffers: index = %i, bufferSizeInBytes = %i\n", i, bufferSizeInBytes);
        inputBufferList->mBuffers[i].mNumberChannels = AUDIO_FORMAT_IS_NONINTERLEAVED ? 1 : AUDIO_NUM_CHANNELS;
        inputBufferList->mBuffers[i].mDataByteSize = bufferSizeInBytes;
        inputBufferList->mBuffers[i].mData = malloc(bufferSizeInBytes);
    }
}

#pragma mark -

- (void)start 
{
    // Try to set our preferred buffer duration to something small, to minimize input and output lag.
    NSError *errRet;
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:0.02 error:&errRet];
    if (errRet)
        NSLog(@"Error in AudioIO::setPreferredIOBufferDuration %@", [errRet localizedDescription]);
    
    OSStatus status = AudioOutputUnitStart(audioUnit);
    if (status != noErr)
    {
        NSLog(@"AudioIO start: An error occured, status = %i", status);
    }
    else
    {
        started = YES;
    }
}

- (void)stop 
{
    OSStatus status = AudioOutputUnitStop(audioUnit);
    
    if (status != noErr)
    {
        NSLog(@"AudioIO stop: An error occured, status = %i", status);
    }
    else
    {
        // Clear the input buffer list
        if (inputBufferList)
        {
            for (UInt32 i = 0; i < inputBufferList->mNumberBuffers; i++)
            {
                free (inputBufferList->mBuffers[i].mData);
            }
            CAAudioBufferList::Destroy(inputBufferList);
            inputBufferList = NULL;
        }
        started = NO;
    }
}

@end
