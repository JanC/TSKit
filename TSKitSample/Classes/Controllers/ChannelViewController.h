//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <UIKit/UIKit.h>

@class TSClient;

NS_ASSUME_NONNULL_BEGIN

@interface ChannelViewController : UITableViewController

@property (nonatomic, strong) TSClient *client;

@end

NS_ASSUME_NONNULL_END