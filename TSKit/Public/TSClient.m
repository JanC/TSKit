//
//  TSClient.m
//  TSKit
//
//  Created by Jan Chaloupecky on 26.10.17.
//  Copyright © 2017 Tequila Apps. All rights reserved.
//

#import "TSClient.h"
#import "AudioIO.h"
#import "NSError+TSError.h"
#import "TSConnectionManager.h"
#import "TSChannel.h"
#import "TSUser.h"
#import "TSClientOptions.h"
#import "TSClient+Private.h"
#import "TSHelper.h"
#import "TSChannelMove.h"

#import <teamspeak/clientlib.h>
#import <teamspeak/public_errors.h>
#import <teamspeak/public_definitions.h>


@interface TSClient () <AudioIODelegate>

@property (nonatomic, strong) TSClientOptions *options;

@property (nonatomic, assign) UInt64 serverConnectionHandlerID;

@property (nonatomic, strong) AudioIO *audioIO;
@property (nonatomic, copy) NSString *identity;

@property (nonatomic, assign) BOOL captureActive;
@property (nonatomic, assign) BOOL playbackActive;


@property (nonatomic, strong, readwrite) TSChannel *currentChannel;
@property (nonatomic, assign, readwrite) TSConnectionStatus currentStatus;
@property (nonatomic, assign, readwrite) anyID ownClientID;

// Dictionary of blocks and "returnCodes" called by the onServerErrorEvent. See docs for "Return code"
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, TSClientErrorBlock> *ts3clientReturnCodesCallbacks;

@end

@implementation TSClient

- (instancetype)initWithOptions:(TSClientOptions *)options
{
    self = [super init];
    if (self) {
        self.options = options;
        self.ts3clientReturnCodesCallbacks = [NSMutableDictionary dictionary];
        self.audioIO = [[AudioIO alloc] initWithAllowRecord:!options.receiveOnly];
        self.audioIO.delegate = self;


        [TSConnectionManager sharedManager];
        [self spawnServerConnectionHandler];
        [self registerAudioDevice];

    }

    return self;
}

- (void)connect:(nullable NSArray<NSString *>*)initialChannels
     completion:(void (^ _Nullable)(BOOL success, NSError *error))completion
{
    if (!self.identity) {
        self.identity = [self.class createIdentity];
    }


    char **channels = NULL;

    NSInteger count = initialChannels.count;

    if (initialChannels) {
        channels = (char **) calloc((size_t)count + 1, sizeof(char *));

        for (NSInteger i = 0; i < count; i++) {
            NSString *nsString = initialChannels[i];
            char *cString = (char *) malloc([nsString lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1); // + 1 for \0
            strcpy(cString, nsString.UTF8String);
            channels[i] = cString;
        }

        channels[count] = "";
    }

    NSUInteger error = ts3client_startConnection(_serverConnectionHandlerID,
            self.identity.UTF8String,
            self.options.host.UTF8String,
            (unsigned int) self.options.port,
            self.options.nickName.UTF8String,
            (const char **) channels, "",
            self.options.password ? self.options.password.UTF8String : @"".UTF8String);

    if(channels) {
        for (NSInteger i = 0; i < count; i++) {
            if (channels[i]) {
                free(channels[i]);
            }
        }
        free(channels);
    }

    if (error != ERROR_ok) {
        NSLog(@"Error connecting to server: %@", [NSError ts_errorMessageFromCode:error]);
        if (completion) {
            completion(NO, [NSError ts_errorWithCode:error]);
        }
        return;
    }


    [self openAudio];

    if (completion) {
        completion(YES, nil);
    }



//    /* Set mode to voice activated */
//    [self setPreProcessorValue:@"true" forIdentifier:@"vad"];
//
//    /* Set the voice activation level in dB. You might want to experiment with these values */
//    [self setPreProcessorValue:@"-5" forIdentifier:@"voiceactivation_level"];

}

- (void)disconnect
{
    NSUInteger error = ts3client_stopConnection(_serverConnectionHandlerID, "leaving");
    if (error != ERROR_ok) {
        NSLog(@"Error connecting to server: %@", [NSError ts_errorMessageFromCode:error]);
    }
}

- (NSArray *)listChannels
{
    UInt64 *ids;
    int i;
    unsigned int error;

    NSLog(@"\nList of channels on virtual server %llu:\n", (unsigned long long) _serverConnectionHandlerID);
    if ((error = ts3client_getChannelList(_serverConnectionHandlerID, &ids)) != ERROR_ok) {  /* Get array of channel IDs */

        NSLog(@"Error getting channel list: %@\n", [NSError ts_errorMessageFromCode:error]);
        return @[];
    }
    if (!ids[0]) {
        NSLog(@"No channels\n\n");
        ts3client_freeMemory(ids);
        return @[];
    }

    NSMutableArray<TSChannel *> *channels = [NSMutableArray array];
    for (i = 0; ids[i]; i++) {
        [channels addObject:[TSHelper channelDetails:ids[i] connectionID:self.serverConnectionHandlerID]];
    }


    ts3client_freeMemory(ids);  /* Release array */

    return channels;
}

-(BOOL)muteUser:(TSUser*) user mute:(BOOL) mute error:(__autoreleasing NSError **)pError
{
    const anyID ids[2] = { user.uid, 0 };
    BOOL success = YES;
    NSUInteger error;
    if(mute) {
        if((error = ts3client_requestMuteClients(self.serverConnectionHandlerID, ids, NULL)) != ERROR_ok) {
            success = NO;
            if(pError != NULL) *pError = [NSError ts_errorWithCode:error];
        }
    } else {
        if((error = ts3client_requestUnmuteClients(self.serverConnectionHandlerID, ids, NULL)) != ERROR_ok) {
            success = NO;
            if(pError != NULL) *pError = [NSError ts_errorWithCode:error];
        }
    }
    if(success) {
        user.muted = mute;
    }
    return success;
}
- (void)moveToChannel:(TSChannel *)channel authCallback:(TSClientAuthPrompt)authPrompt completion:(void (^)(BOOL success, NSError *error))completion;
{

    __block NSUInteger error;
    /* Query channel ID from user */
    uint64 channelID = channel.uid;
    int hasPassword;

    /* Query own client ID */
    anyID clientID;
    if ((error = ts3client_getClientID(self.serverConnectionHandlerID, &clientID)) != ERROR_ok) {
        NSError *tsError = [NSError ts_errorWithCode:error];
        if (completion) {
            completion(NO, tsError);
        }
        return;
    }

    /* Using standard password mechanism */

    /* Check if channel has a password set */
    if ((error = ts3client_getChannelVariableAsInt(self.serverConnectionHandlerID, channelID, CHANNEL_FLAG_PASSWORD, &hasPassword)) != ERROR_ok) {
        NSError *tsError = [NSError ts_errorWithCode:error];
        NSLog(@"Failed to get password flag: %@", tsError);
        if (completion) {
            completion(NO, tsError);
        }
        return;
    }

    NSLog(@"Switching into channel %@", channel);


    __weak typeof(self) wself = self;
    void (^requestClientMoveBlock)(const char *) = ^void(const char *cpass) {

        // add a return code block to handle the result of this call
        NSString *returnCode = [[NSUUID UUID] UUIDString];
        wself.ts3clientReturnCodesCallbacks[returnCode] = ^(NSString *message, NSUInteger errorCode, NSString *extraMessage) {
            NSLog(@"Switching into channel: %@", [NSError ts_errorMessageFromCode:errorCode]);

            // success
            if (errorCode == ERROR_ok) {
                self.currentChannel = channel;
                if(completion) {
                    completion(YES, nil);
                }

                return;
            }
            // error
            if(completion) {
                completion(NO, [NSError ts_errorWithCode:errorCode]);
            }


        };

        // request the actual move
        if ((error = ts3client_requestClientMove(self.serverConnectionHandlerID, clientID, channelID, cpass, [returnCode cStringUsingEncoding:NSUTF8StringEncoding])) != ERROR_ok) {
            NSLog(@"Error moving client into channel channel: %@\n", [NSError ts_errorWithCode:error]);
            if (completion) {
                completion(NO, [NSError ts_errorWithCode:error]);
            }
            return;
        }

    };

    if (!hasPassword) {
        char pass[1];
        pass[0] = '\0';
        requestClientMoveBlock(pass);
        return;
    }

    // password but no auth block
    if (!authPrompt) {
        if (completion) {
            completion(NO, [NSError ts_errorWithDescription:@"Channel has password but no password was supplied"]);
        }
        return;
    }
    // prompt for pass
    authPrompt(^(NSString *password) {
        requestClientMoveBlock([password cStringUsingEncoding:NSUTF8StringEncoding]);
    });


}

- (void)listUsersIn:(TSChannel *)channel completion:(void (^)(NSArray<TSUser *> *users, NSError *error))completion
{
    anyID *ids;
    int i;
    unsigned int error;


    if ((error = ts3client_getChannelClientList(self.serverConnectionHandlerID, channel.uid, &ids)) != ERROR_ok) {  /* Get array of client IDs */
        completion(nil, [NSError ts_errorWithCode:error]);
        return;
    }
    if (!ids[0]) {
        NSLog(@"No clients");
        ts3client_freeMemory(ids);
        completion(nil, nil);
        return;
    }

    NSMutableArray *users = [NSMutableArray array];
    for (i = 0; ids[i]; i++) {
        TSUser *user = [TSHelper clientDetails:ids[i] connectionID:self.serverConnectionHandlerID];
        [users addObject:user];
    }

    NSLog(@"Clients in channel %llu on virtual server %llu:\n %@", (unsigned long long) channel.uid, (unsigned long long) self.serverConnectionHandlerID, users);
    completion(users, nil);

    ts3client_freeMemory(ids);
}


#pragma mark - TSLibrary


- (void)spawnServerConnectionHandler
{
    // Create a server connection handler
    unsigned int error = ts3client_spawnNewServerConnectionHandler(0, &_serverConnectionHandlerID);
    if (error != ERROR_ok) {
        NSLog(@"ts3client_spawnNewServerConnectionHandler ERROR");
        return;
    }
    [[TSConnectionManager sharedManager] registerClient:self];
}

+ (NSString *)createIdentity
{
    NSString *identity = nil;
    char *cstring;
    NSUInteger error = ts3client_createIdentity(&cstring);
    if (error == ERROR_ok) {
        identity = [NSString stringWithUTF8String:cstring];
        ts3client_freeMemory(cstring);
    } else {
        NSLog(@"Error creating identity: %@", [NSError ts_errorMessageFromCode:error]);
    }

    return identity;
}

#pragma mark - SDK callbacks on main thread

- (void)onConnectStatusChangedEvent:(NSDictionary *)parameters
{

    int newStatus = [parameters[@"newStatus"] intValue];
    NSUInteger errorNumber = [parameters[@"errorNumber"] unsignedIntValue];


    NSLog(@"onConnectStatusChangedEvent newStatus: %i error: %@", newStatus, [NSError ts_errorMessageFromCode:errorNumber]);
    /* Failed to connect ? */
    if (newStatus == STATUS_DISCONNECTED && errorNumber == ERROR_failed_connection_initialisation) {
        printf("Looks like there is no server running!\n");
    }

    if(newStatus == STATUS_CONNECTED) {

        NSUInteger error;
        /* Get own clientID as we need to call CLIENT_FLAG_TALKING with getClientSelfVariable for own client */
        if ((error = ts3client_getClientID(self.serverConnectionHandlerID, &_ownClientID)) != ERROR_ok) {
            NSLog(@"Getting own clientID: %@", [NSError ts_errorMessageFromCode:error]);
        }

        UInt64 ownChannelID;

        error = ts3client_getChannelOfClient(self.serverConnectionHandlerID, self.ownClientID, &ownChannelID);
        NSLog(@"Own channel %@", [NSError ts_errorMessageFromCode:error]);
        if(error == ERROR_ok) {
            self.currentChannel = [TSHelper channelDetails:ownChannelID connectionID:self.serverConnectionHandlerID];
        }
    }

    if (newStatus == STATUS_DISCONNECTED) {
        [self closeAudio];
    }

    self.currentStatus = (TSConnectionStatus)newStatus;
    [self.delegate client:self connectStatusChanged:self.currentStatus];

    if (errorNumber > 0) {

        id <TSClientDelegate> o = self.delegate;
        if ([o respondsToSelector:@selector(client:onConnectionError:)]) {
            [o client:self onConnectionError:[NSError ts_errorWithCode:errorNumber]];
        }
    }
}

- (void)onNewChannelEvent:(NSDictionary *)parameters
{
    NSUInteger channelID = [parameters[@"channelID"] unsignedIntValue];
//    int channelParentID = [parameters[@"channelParentID"] intValue];
    //NSLog(@"onNewChannelEvent channelID: %@ channelParentID: %i", @(channelID), channelParentID);

    id <TSClientDelegate> o = self.delegate;
    if ([o respondsToSelector:@selector(client:didReceivedChannel:)]) {
        [o client:self didReceivedChannel:[TSHelper channelDetails:channelID connectionID:self.serverConnectionHandlerID]];
    }
}


- (void)onNewChannelCreatedEvent:(NSDictionary *)parameters
{
    NSUInteger channelID = [parameters[@"channelID"] unsignedIntValue];
    NSString *invokerName = parameters[@"invokerName"];

    NSLog(@"onNewChannelCreatedEvent channelID: %@ invokerName: %@", @(channelID), invokerName);

    id <TSClientDelegate> o = self.delegate;
    if ([o respondsToSelector:@selector(client:didReceivedChannel:)]) {
        [o client:self didReceivedChannel:[TSHelper channelDetails:channelID connectionID:self.serverConnectionHandlerID]];
    }
}


- (void)onDelChannelEvent:(NSDictionary *)parameters
{
    NSUInteger channelID = [parameters[@"channelID"] unsignedIntValue];
    NSString *invokerName = parameters[@"invokerName"];

    NSLog(@"onDelChannelEvent channelID: %@ invokerName: %@", @(channelID), invokerName);

    id <TSClientDelegate> o = self.delegate;
    if ([o respondsToSelector:@selector(client:didDeleteChannel:)]) {
        [o client:self didDeleteChannel:channelID];
    }
}


- (void)onClientMoveEvent:(NSDictionary *)parameters
{
    NSUInteger clientID = [parameters[@"clientID"] unsignedIntValue];
    NSUInteger oldChannelID = [parameters[@"oldChannelID"] unsignedIntValue];
    NSUInteger newChannelID = [parameters[@"newChannelID"] unsignedIntValue];
    int visibility = [parameters[@"visibility"] intValue];

    TSUser *user = [TSHelper clientDetails:clientID connectionID:self.serverConnectionHandlerID];
    TSChannel *fromChannel = [TSHelper channelDetails:oldChannelID connectionID:self.serverConnectionHandlerID];
    TSChannel *toChannel = [TSHelper channelDetails:newChannelID connectionID:self.serverConnectionHandlerID];

    TSChannelVisibility channelVisibility = TSChannelVisibilityUnknown;
    switch (visibility) {
        case ENTER_VISIBILITY:
            channelVisibility = TSChannelVisibilityEnter;
            break;
        case RETAIN_VISIBILITY:
            channelVisibility = TSChannelVisibilitySwitch;
            break;
        case LEAVE_VISIBILITY:
            channelVisibility = TSChannelVisibilityLeave;
        default:
            break;
    }

    TSChannelMove *move = [[TSChannelMove alloc] init];
    move.visibiliy = channelVisibility;
    move.fromChannel = fromChannel;
    move.toChannel = toChannel;

    NSLog(@"onClientMoveEvent clientID: %lu oldChannelID: %lu newChannelID: %lu visibility: %d", (unsigned long)clientID, oldChannelID, newChannelID, visibility);

    id <TSClientDelegate> o = self.delegate;
    if ([o respondsToSelector:@selector(client:user:didMove:)]) {
        [o client:self user:user didMove:move];
    }
}


- (void)onClientMoveSubscriptionEvent:(NSDictionary *)parameters
{
    int clientID = [parameters[@"clientID"] intValue];
    int oldChannelID = [parameters[@"oldChannelID"] intValue];
    int newChannelID = [parameters[@"newChannelID"] intValue];
    int visibility = [parameters[@"visibility"] intValue];

    NSLog(@"onClientMoveSubscriptionEvent clientID: %i oldChannelID: %i newChannelID: %i visibility: %i", clientID, oldChannelID, newChannelID, visibility);
}


- (void)onClientMoveTimeoutEvent:(NSDictionary *)parameters
{
    int clientID = [parameters[@"clientID"] intValue];
    int oldChannelID = [parameters[@"oldChannelID"] intValue];
    int newChannelID = [parameters[@"newChannelID"] intValue];
    int visibility = [parameters[@"visibility"] intValue];

    NSLog(@"onClientMoveTimeoutEvent clientID: %i oldChannelID: %i newChannelID: %i visibility: %i", clientID, oldChannelID, newChannelID, visibility);
    // todo add and call a delegate
}


- (void)onTalkStatusChangeEvent:(NSDictionary *)parameters
{
    int status = [parameters[@"status"] intValue];
//    int isReceivedWhisper = [parameters[@"isReceivedWhisper"] intValue];
    int clientID = [parameters[@"clientID"] intValue];
    
    //NSLog(@"onTalkStatusChangeEvent status: %i isReceivedWhisper: %i clientID: %i", status, isReceivedWhisper, clientID);

    id <TSClientDelegate> o = self.delegate;
    if ([o respondsToSelector:@selector(client:user:talkStatusChanged:)]) {
        TSUser *user = [TSHelper clientDetails:clientID connectionID:self.serverConnectionHandlerID];
        [o client:self user:user talkStatusChanged:status != STATUS_NOT_TALKING];
    }
}

- (void)onServerErrorEvent:(NSDictionary *)parameters
{
    NSString *errorMessage = parameters[@"errorMessage"];
    NSUInteger errorCode = [parameters[@"error"] unsignedIntegerValue];
    NSString *returnCode = parameters[@"returnCode"];
    NSString *extraMessage = parameters[@"extraMessage"];
    //[NSError ts_errorWithCode:returnCode]
    NSLog(@"onServerErrorEvent errorMessage: %@ error: %@ returnCode: %@ extraMessage: %@", errorMessage, @(errorCode), returnCode, extraMessage);


    // handle an error message associated to a return code (call initiated by us)
    TSClientErrorBlock errorBlock = self.ts3clientReturnCodesCallbacks[returnCode];
    if (errorBlock) {
        errorBlock(errorMessage, errorCode, extraMessage);
        self.ts3clientReturnCodesCallbacks[returnCode] = nil;
        return;
    }

    // another server error, not related to a client calls

}

#pragma mark - AudioDelegate

- (void)audioIO:(AudioIO *)audioIO processAudioToSpeaker:(AudioBufferList *)ioData
{
    if (!_playbackActive) {
        return;
    }

    int numSamples = ioData->mBuffers[0].mDataByteSize / (AUDIO_BIT_DEPTH_IN_BYTES * AUDIO_NUM_CHANNELS);
    short *outData = (short *) (ioData->mBuffers[0].mData); // A single buffer contains interleaved data for AUDIO_NUM_CHANNELS channels


    /* Get playback data from the client lib */
    int error = ts3client_acquireCustomPlaybackData(self.audioIO.deviceID.UTF8String,
            outData,
            numSamples);
    if (error != ERROR_ok && error != ERROR_sound_no_data) {
        NSLog(@"Error acquiring playback data: %@", [NSError ts_errorMessageFromCode:error]);
    }
}

- (void)audioIO:(AudioIO *)audioIO processAudioFromMicrophone:(AudioBufferList *)ioData
{
    if (!_captureActive) {
        return;
    }

    int numSamples = ioData->mBuffers[0].mDataByteSize / (AUDIO_BIT_DEPTH_IN_BYTES * AUDIO_NUM_CHANNELS);
    short *inData = (short *) (ioData->mBuffers[0].mData); // A single buffer contains interleaved data for AUDIO_NUM_CHANNELS channels

    /* Send capture data to the client lib */
    int error = ts3client_processCustomCaptureData(self.audioIO.deviceID.UTF8String,
            inData,
            numSamples);
    if (error != ERROR_ok) {
        NSLog(@"Error processing capture data: %@", [NSError ts_errorMessageFromCode:error]);
    }
}

- (void)audioWillStart:(AudioIO *)audioIO
{
    if (!self.isDisconnected) {
        [self openAudio];
    }
}

- (void)audioWillStop:(AudioIO *)audioIO
{
    if (!self.isDisconnected) {
        [self closeAudio];
    }
}


- (BOOL)isConnected
{
    return self.connectStatus == STATUS_CONNECTION_ESTABLISHED;
}

- (BOOL)isDisconnected
{
    return self.connectStatus == STATUS_DISCONNECTED;
}

- (BOOL)isConnecting
{
    return !self.isConnected && !self.isDisconnected;
}

- (int)connectStatus
{
    int status;
    int error = ts3client_getConnectionStatus(_serverConnectionHandlerID, &status);
    if (error == ERROR_ok) {
        return status;
    }
    return STATUS_DISCONNECTED;
}

#pragma mark - Audio

#pragma mark - Audio Handling

- (void)registerAudioDevice
{
    NSLog(@"Registering custom sound device, sample rate = %f ***", AUDIO_SAMPLE_RATE);
    int error = ts3client_registerCustomDevice(self.audioIO.deviceID.UTF8String,
                                               self.audioIO.deviceDisplayName.UTF8String,
                                               self.audioIO.sampleRate,
                                               self.audioIO.numChannels,
                                               self.audioIO.sampleRate,
                                               self.audioIO.numChannels);
    if (error != ERROR_ok) {
        NSLog(@"Error registering custom sound device: %@", [NSError ts_errorMessageFromCode:error]);
    }
}

- (void)unregisterAudioDevice
{
    NSLog(@"Unregistering custom sound device");

    int error = ts3client_unregisterCustomDevice(self.audioIO.deviceID.UTF8String);
    if (error != ERROR_ok) {
        NSLog(@"Error unregistering custom sound device: %@", [NSError ts_errorMessageFromCode:error]);
    }
}

- (void)openAudio
{
    NSLog(@"Opening capture device for server connection handler %qu", _serverConnectionHandlerID);
    int error;

    if (!self.options.receiveOnly) {
        error = ts3client_openCaptureDevice(_serverConnectionHandlerID, "custom", self.audioIO.deviceID.UTF8String);
        if (error != ERROR_ok) {
            NSLog(@"Error opening capture device: %@", [NSError ts_errorMessageFromCode:error]);
        } else {
            self.captureActive = YES;
        }
    }

    NSLog(@"Opening playback device for server connection handler %qu", _serverConnectionHandlerID);

    //ts3client_getDefaultPlayBackMode(<#char** result#>)

    error = ts3client_openPlaybackDevice(_serverConnectionHandlerID, "custom", self.audioIO.deviceID.UTF8String);
    if (error != ERROR_ok) {
        NSLog(@"Error opening playback device: %@", [NSError ts_errorMessageFromCode:error]);
    } else {
        self.playbackActive = YES;
    }

    [self.audioIO start];
}

- (void)closeAudio
{
    if (self.captureActive) {
        NSLog(@"Closing capture device");

        int error = ts3client_closeCaptureDevice(_serverConnectionHandlerID);
        if (error != ERROR_ok) {
            NSLog(@"Error closing capture device: %@\n", [NSError ts_errorMessageFromCode:error]);
        } else {
            self.captureActive = NO;
        }
    }

    if (self.playbackActive) {
        NSLog(@"Closing playback device");

        int error = ts3client_closePlaybackDevice(_serverConnectionHandlerID);
        if (error != ERROR_ok) {
            printf("Error closing playback device: %d\n", error);
        } else {
            self.playbackActive = NO;
        }
    }

    [self.audioIO stop];
}

- (void)dealloc
{
//    [self unregisterAudioDevice];
//    [self destroyServerConnectionHandler];
//    [self destroyLibrary];
}


@end
