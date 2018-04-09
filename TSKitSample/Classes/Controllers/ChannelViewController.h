//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <UIKit/UIKit.h>

@import TSKit;

NS_ASSUME_NONNULL_BEGIN

@interface ChannelViewController : UITableViewController

@property (nonatomic, strong) TSClient *client;

- (void)addUser:(TSUser *)user;

- (void)removeUser:(TSUser *)user;

@end

NS_ASSUME_NONNULL_END
