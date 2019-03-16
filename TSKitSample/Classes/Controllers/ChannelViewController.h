//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <UIKit/UIKit.h>

@import TSKit;

NS_ASSUME_NONNULL_BEGIN

@class ChannelViewController;

@protocol ChannelViewControllerDelegate <NSObject>

-(void) channelViewController:(ChannelViewController*) controller didSelectUser:(TSUser *) user;

@end
@interface ChannelViewController : UITableViewController

@property (nonatomic, strong) TSClient *client;
@property (nonatomic, weak) id<ChannelViewControllerDelegate> delegate;

- (void)addUser:(TSUser *)user;

- (void)removeUser:(TSUser *)user;

-(void) reload;

@end

NS_ASSUME_NONNULL_END
