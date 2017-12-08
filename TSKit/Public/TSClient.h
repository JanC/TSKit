//
//  TSClient.h
//  TSKit
//
//  Created by Jan Chaloupecky on 26.10.17.
//  Copyright © 2017 Tequila Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioIO;
@class TSClient;
@class TSChannel;
@class TSUser;
@class TSClientOptions;
@class TSHelper;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TSConnectionStatus) {
    ///There is no activity to the server, this is the default value
            TSConnectionStatusDisconnected,

    ///We are trying to connect, we haven't got a clientID yet, we haven't been accepted by the server
            TSConnectionStatusConnecting,

    ///The server has accepted us, we can talk and hear and we got a clientID, but we don't have the channels and clients yet, we can get server infos (welcome msg etc.)
            TSConnectionStatusConnected,

    /// we are CONNECTED and we are visible
            TSConnectionStatusEstablishing,

    ///we are CONNECTED and we have the client and channels available
            TSConnectionStatusEstablished,
};

/// Block to call when the password is supplied by a caller
typedef void (^TSClientAuthCallback)(NSString* password);

/// Block called when a channel requires a password
typedef void (^TSClientAuthPrompt)(TSClientAuthCallback authCallback);



@protocol TSClientDelegate <NSObject>

@optional

- (void)client:(TSClient *)client connectStatusChanged:(TSConnectionStatus)status;

- (void)client:(TSClient *)client user:(TSUser *)user talkStatusChanged:(BOOL)talking;

- (void)client:(TSClient *)client onConnectionError:(NSError *)error;

/// Called when a new channel is created and after initial channel list on connection
- (void)client:(TSClient *)client didReceivedChannel:(TSChannel *)channel;

/// Called when a channel is deleted by the server
- (void)client:(TSClient *)client didDeleteChannel:(NSUInteger)channelId;

@end

@interface TSClient : NSObject

@property (nonatomic, strong, readonly) TSChannel *currentChannel;

/// The current connection status
@property (nonatomic, assign, readonly) TSConnectionStatus currentStatus;

@property (nonatomic, assign, readonly) UInt64 serverConnectionHandlerID;

@property (nonatomic, weak, nullable) id <TSClientDelegate> delegate;

- (instancetype)initWithOptions:(TSClientOptions *)options;

- (void)connectToChannels:(nullable NSArray<NSString *>*)initialChannels completion:(void (^ _Nullable)(BOOL success, NSError *error))completion;

-(void)disconnect;

- (NSArray<TSChannel *> *)listChannels;

/**
 * Mutes the user and sets its 'muted' property in case of success
 * @param user The user to mute
 * @param mute The desired mute state
 * @param pError The optional error
 */
-(BOOL)muteUser:(TSUser*) user mute:(BOOL) mute error:(__autoreleasing NSError **)pError;

/**
 * Moves to a specified channel
 * @param channel The channel to move to,
 * @param authPrompt The authentication block called if the channel has a password.
 * @param completion Called when finished
 */
- (void)moveToChannel:(TSChannel *)channel authCallback:(_Nullable TSClientAuthPrompt)authPrompt completion:(void(^_Nullable)(BOOL success, NSError *error)) completion;

- (void)listUsersIn:(TSChannel *)channel completion:(void (^)(NSArray<TSUser *> *users, NSError *error))completion;


@end

NS_ASSUME_NONNULL_END
