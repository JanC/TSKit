//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>

@class TSChannel;


typedef NS_ENUM(NSUInteger, TSChannelVisibility) {
    /// user moved and entered visibility. Cannot happen on own client.
    TSChannelVisibilityEnter,

    /// user moved between two known places. Can happen on own or other client.
    TSChannelVisibilitySwitch,

    /// user moved out of our sight. Cannot happen on own client.
    TSChannelVisibilityLeave,

    TSChannelVisibilityUnknown,
};

/**
 * Object representing the "move" of a team speak user when connecting, switching channels or disconnecting
 */
@interface TSChannelMove : NSObject

@property (nonatomic, strong) TSChannel *fromChannel;
@property (nonatomic, strong) TSChannel *toChannel;
@property (nonatomic, assign) TSChannelVisibility visibiliy;
@property (nonatomic, copy) NSString *message;

@end