//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>

@class TSChannel;
@class TSUser;


@interface TSHelper : NSObject

#pragma mark - Channels

/// Gets the details of a channel id
+ (TSChannel *)channelDetails:(UInt64)channelID connectionID:(UInt64)connectionId;

+ (TSUser *)clientDetails:(UInt64)clientId connectionID:(UInt64)connectionHandlerId;

@end
