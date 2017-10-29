//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>
#import "TSClient.h"

@interface TSClient (Private)

typedef void (^TSClientErrorBlock)(NSString* message, NSUInteger errorCode, NSString *extraMessage);

#pragma mark - Protected

- (void)onConnectStatusChangedEvent:(NSDictionary *)parameters;

- (void)onNewChannelEvent:(NSDictionary *)parameters;

- (void)onNewChannelCreatedEvent:(NSDictionary *)parameters;

- (void)onDelChannelEvent:(NSDictionary *)parameters;

- (void)onClientMoveEvent:(NSDictionary *)parameters;

- (void)onClientMoveSubscriptionEvent:(NSDictionary *)parameters;

- (void)onClientMoveTimeoutEvent:(NSDictionary *)parameters;

- (void)onTalkStatusChangeEvent:(NSDictionary *)parameters;

- (void)onServerErrorEvent:(NSDictionary *)parameters;

@end