//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <UIKit/UIKit.h>

@interface UIViewController (TSViewController)

- (void)ts_askForPassword:(void (^)(NSString *password))completion;

- (void)ts_showAlert:(NSString *)title message:(NSString *)message;

@end