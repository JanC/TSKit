//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "TSConnectionManager.h"
#import "TSClient+Private.h"
#import "NSError+TSError.h"

#import <teamspeak/clientlib.h>
#import <teamspeak/public_errors.h>
#import <teamspeak/public_definitions.h>

@interface TSConnectionManager ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, TSClient *> *connections;

@end

@implementation TSConnectionManager

+ (instancetype)sharedManager
{
    static TSConnectionManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _connections = [NSMutableDictionary dictionary];
        [self initializeLibrary];
    }

    return self;
}

- (void)registerClient:(TSClient *)client
{
    if (client.serverConnectionHandlerID == 0) {
        NSAssert(NO, @"Only valid clients can be registered");
        return;
    }
    self.connections[@(client.serverConnectionHandlerID)] = client;
}


#pragma mark - SDK C function callbacks

void onConnectStatusChangeEvent(uint64 serverConnectionHandlerID, int newStatus, unsigned int errorNumber)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"newStatus": @(newStatus),
                @"errorNumber": @(errorNumber) };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onConnectStatusChangedEvent:params];
        });
    }
}

void onNewChannelEvent(uint64 serverConnectionHandlerID, uint64 channelID, uint64 channelParentID)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"channelID": @(channelID),
                @"channelParentID": @(channelParentID) };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onNewChannelEvent:params];
        });
    }
}

void onNewChannelCreatedEvent(uint64 serverConnectionHandlerID, uint64 channelID, uint64 channelParentID, anyID invokerID, const char *invokerName, const char *invokerUniqueIdentifier)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"channelID": @(channelID),
                @"channelParentID": @(channelParentID),
                @"invokerID": @(invokerID),
                @"invokerName": invokerName ? [NSString stringWithUTF8String:invokerName] : @"",
                @"invokerUniqueIdentifier": invokerUniqueIdentifier ? [NSString stringWithUTF8String:invokerUniqueIdentifier] : @"" };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onNewChannelCreatedEvent:params];
        });
    }
}

void onDelChannelEvent(uint64 serverConnectionHandlerID, uint64 channelID, anyID invokerID, const char *invokerName, const char *invokerUniqueIdentifier)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"channelID": @(channelID),
                @"invokerID": @(invokerID),
                @"invokerName": invokerName ? [NSString stringWithUTF8String:invokerName] : @"",
                @"invokerUniqueIdentifier": invokerUniqueIdentifier ? [NSString stringWithUTF8String:invokerUniqueIdentifier] : @"" };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onDelChannelEvent:params];
        });
    }
}

void onClientMoveEvent(uint64 serverConnectionHandlerID, anyID clientID, uint64 oldChannelID, uint64 newChannelID, int visibility, const char *moveMessage)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"clientID": @(clientID),
                @"oldChannelID": @(oldChannelID),
                @"newChannelID": @(newChannelID),
                @"visibility": @(visibility),
                @"moveMessage": moveMessage ? [NSString stringWithUTF8String:moveMessage] : @"" };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onClientMoveEvent:params];
        });
    }
}

void onClientMoveSubscriptionEvent(uint64 serverConnectionHandlerID, anyID clientID, uint64 oldChannelID, uint64 newChannelID, int visibility)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"clientID": @(clientID),
                @"oldChannelID": @(oldChannelID),
                @"newChannelID": @(newChannelID),
                @"visibility": @(visibility) };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onClientMoveSubscriptionEvent:params];
        });
    }
}

void onClientMoveTimeoutEvent(uint64 serverConnectionHandlerID, anyID clientID, uint64 oldChannelID, uint64 newChannelID, int visibility, const char *timeoutMessage)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"clientID": @(clientID),
                @"oldChannelID": @(oldChannelID),
                @"newChannelID": @(newChannelID),
                @"visibility": @(visibility),
                @"timeoutMessage": timeoutMessage ? [NSString stringWithUTF8String:timeoutMessage] : @"" };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onClientMoveTimeoutEvent:params];
        });
    }
}

void onTalkStatusChangeEvent(uint64 serverConnectionHandlerID, int status, int isReceivedWhisper, anyID clientID)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"status": @(status),
                @"isReceivedWhisper": @(isReceivedWhisper),
                @"clientID": @(clientID) };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onTalkStatusChangeEvent:params];
        });
    }
}

void onServerErrorEvent(uint64 serverConnectionHandlerID, const char *errorMessage, unsigned int error, const char *returnCode, const char *extraMessage)
{
    @autoreleasepool {
        NSDictionary *params = @{ @"handlerID": @(serverConnectionHandlerID),
                @"errorMessage": @(errorMessage),
                @"error": @(error),
                @"returnCode": returnCode ? [NSString stringWithUTF8String:returnCode] : @"",
                @"extraMessage": extraMessage ? [NSString stringWithUTF8String:extraMessage] : @"" };

        dispatch_async(dispatch_get_main_queue(), ^{
            [[TSConnectionManager sharedManager] onServerErrorEvent:params];
        });
    }
}

#pragma mark - SDK callbacks on main thread

/*
 * Callback for connection status change.
 * Connection status switches through the states STATUS_DISCONNECTED, STATUS_CONNECTING, STATUS_CONNECTED and STATUS_CONNECTION_ESTABLISHED.
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   newStatus                 - New connection status, see the enum ConnectStatus in clientlib_publicdefinitions.h
 *   errorNumber               - Error code. Should be zero when connecting or actively disconnection.
 *                               Contains error state when losing connection.
 */
- (void)onConnectStatusChangedEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onConnectStatusChangedEvent:parameters];
}

/*
 * Callback for current channels being announced to the client after connecting to a server.
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   channelID                 - ID of the announced channel
 *   channelParentID           - ID of the parent channel
 */
- (void)onNewChannelEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onNewChannelEvent:parameters];
}

/*
 * Callback for just created channels.
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   channelID                 - ID of the announced channel
 *   channelParentID           - ID of the parent channel
 *   invokerID                 - ID of the client who created the channel
 *   invokerName               - Name of the client who created the channel
 */
- (void)onNewChannelCreatedEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onNewChannelCreatedEvent:parameters];
}

/*
 * Callback when a channel was deleted.
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   channelID                 - ID of the deleted channel
 *   invokerID                 - ID of the client who deleted the channel
 *   invokerName               - Name of the client who deleted the channel
 */
- (void)onDelChannelEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onDelChannelEvent:parameters];
}

/*
 * Called when a client joins, leaves or moves to another channel.
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   clientID                  - ID of the moved client
 *   oldChannelID              - ID of the old channel left by the client
 *   newChannelID              - ID of the new channel joined by the client
 *   visibility                - Visibility of the moved client. See the enum Visibility in clientlib_publicdefinitions.h
 *                               Values: ENTER_VISIBILITY, RETAIN_VISIBILITY, LEAVE_VISIBILITY
 */
- (void)onClientMoveEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onClientMoveEvent:parameters];
}

/*
 * Callback for other clients in current and subscribed channels being announced to the client.
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   clientID                  - ID of the announced client
 *   oldChannelID              - ID of the subscribed channel where the client left visibility
 *   newChannelID              - ID of the subscribed channel where the client entered visibility
 *   visibility                - Visibility of the announced client. See the enum Visibility in clientlib_publicdefinitions.h
 *                               Values: ENTER_VISIBILITY, RETAIN_VISIBILITY, LEAVE_VISIBILITY
 */
- (void)onClientMoveSubscriptionEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onClientMoveSubscriptionEvent:parameters];
}

/*
 * Called when a client drops his connection.
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   clientID                  - ID of the moved client
 *   oldChannelID              - ID of the channel the leaving client was previously member of
 *   newChannelID              - 0, as client is leaving
 *   visibility                - Always LEAVE_VISIBILITY
 *   timeoutMessage            - Optional message giving the reason for the timeout
 */
- (void)onClientMoveTimeoutEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onClientMoveTimeoutEvent:parameters];
}

/*
 * This event is called when a client starts or stops talking.
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   status                    - 1 if client starts talking, 0 if client stops talking
 *   isReceivedWhisper         - 1 if this event was caused by whispering, 0 if caused by normal talking
 *   clientID                  - ID of the client who announced the talk status change
 */
- (void)onTalkStatusChangeEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onTalkStatusChangeEvent:parameters];
}

/*
 * This event is called when the server sends an error to the client as the result of an asynchronous request.
 *
 *
 * Parameters:
 *   serverConnectionHandlerID - Server connection handler ID
 *   errorMessage              - String containing a verbose error message
 *   error                     - Error code as defined in public_errors.h
 *   returnCode                - Set by the client lib function call which caused this event
 *   extraMessage              - Can contain additional information about the error
 */
- (void)onServerErrorEvent:(NSDictionary *)parameters
{
    TSClient *client = self.connections[parameters[@"handlerID"]];
    [client onServerErrorEvent:parameters];
}



- (void)initializeLibrary
{

    /* Create struct for callback function pointers */
    struct ClientUIFunctions funcs;

    /* Initialize all callbacks with NULL */
    memset(&funcs, 0, sizeof(struct ClientUIFunctions));

    /* Now assign the used callback function pointers */
    funcs.onConnectStatusChangeEvent = onConnectStatusChangeEvent;
    funcs.onNewChannelEvent = onNewChannelEvent;
    funcs.onNewChannelCreatedEvent = onNewChannelCreatedEvent;
    funcs.onDelChannelEvent = onDelChannelEvent;
    funcs.onClientMoveEvent = onClientMoveEvent;
    funcs.onClientMoveSubscriptionEvent = onClientMoveSubscriptionEvent;
    funcs.onClientMoveTimeoutEvent = onClientMoveTimeoutEvent;
    funcs.onTalkStatusChangeEvent = onTalkStatusChangeEvent;
    funcs.onServerErrorEvent = onServerErrorEvent;

    /* Initialize client lib with callbacks */
    unsigned int error = ts3client_initClientLib(&funcs, 0, LogType_CONSOLE, NULL, NULL);
    if (error != ERROR_ok) {
        NSLog(@"initializeLibrary ERROR: %@", [NSError ts_errorMessageFromCode:error]);
    } else {
        NSLog(@"initializeLibrary OK");
    }

}


@end
